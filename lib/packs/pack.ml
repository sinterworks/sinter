(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Tree = Sinter_file_read.Tree
module Hash = Sinter_hashes.Hash
module Path = Sinter_paths.Path
module Strings = Map.Make (String)

type t = { root : string; entries : unit Tree.entry list }

type failure =
  | Unread of string list list
  | Not_read of Sinter_file_read.failure
  | Changed

type content_failure =
  | No_file
  | Unreadable_file of string list
  | Content_not_read of Sinter_file_read.failure

(* @satisfies conformance#report-missing-parts=v1
   Every use of a pack needs the folder entries of the root, so a root whose
   entries the walk could not take gives no pack and names the root as the
   missing part. *)
let read ~root =
  match Sinter_file_read.walk ~root with
  | Ok (Tree.Folder entries) -> Ok { root; entries }
  | Ok _ -> Error (Unread [ [] ])
  | Error failure -> Error (Not_read failure)

type place = File | Off | Unread_at of string list

let entry_file entries name =
  Option.map
    (fun (entry : unit Tree.entry) -> entry.file)
    (List.find_opt (fun (entry : unit Tree.entry) -> entry.name = name) entries)

let rec place entries prefix = function
  | [] -> Off
  | name :: rest -> (
      match (entry_file entries name, rest) with
      | Some (Tree.Folder entries), _ :: _ ->
          place entries (name :: prefix) rest
      | Some Tree.Unread_folder, _ :: _ -> Unread_at (List.rev (name :: prefix))
      | Some (Tree.Regular_file _), [] -> File
      | _ -> Off)

(* @satisfies packs#give-pack-file-contents=v1
   The content of the file with a valid path is the whole content of the
   regular file that the UTF-8 encodings of its file names name, only when the
   folder tree has a regular file there. *)
(* @satisfies conformance#report-missing-parts=v1
   The content of a file needs only the folders of its path and the file, so
   an unread folder off the path changes nothing, and an unread folder on the
   path, or a folder or file that the content read could not take, is the
   missing part that the failure names. *)
let content pack path =
  let names = List.map Text.encode (Path.file_names path) in
  match place pack.entries [] names with
  | Off -> Error No_file
  | Unread_at part -> Error (Unreadable_file part)
  | File -> (
      match Sinter_file_read.content ~root:pack.root names with
      | Ok (Ok bytes) -> Ok bytes
      | Ok (Error (Sinter_file_read.Cannot_take part)) ->
          Error (Unreadable_file part)
      | Ok (Error _) -> Error No_file
      | Error failure -> Error (Content_not_read failure))

type well_named = { pack : t; paths : string list }

exception Not_well_named

(* @satisfies packs#decide-well-named-packs=v1
   A name on the way to a regular file must be the name of a pack path, which
   is the UTF-8 encoding of a file name, and the path must keep to 255
   characters; otherwise the path stops being a pack path. *)
let extend prefix name =
  match prefix with
  | None -> None
  | Some path ->
      let candidate = if path = "" then name else path ^ "/" ^ name in
      if Names.is_name name && String.length candidate <= Names.max_length then
        Some candidate
      else None

type 'a found = {
  all : string list;
  values : (string * 'a) list;
  unread : (string list * bool) list;
}

(* @satisfies packs#{give-pack-files=v1, decide-well-named-packs=v1}
   Each regular file of the folder tree gives the valid path of one file, and no
   other file gives one; a regular file whose path is not a pack path makes the
   pack not well named. *)
(* @satisfies conformance#report-missing-parts=v1
   Each unread folder and each unread file is one missing part, kept once with
   its entry names from the root, in the order of the walk; an unread file
   still gives the path of a file. *)
let file_paths entries =
  let rec walk found = function
    | [] -> { found with unread = List.rev found.unread }
    | (_, _, []) :: stack -> walk found stack
    | (prefix, names, (entry : _ Tree.entry) :: rest) :: stack -> (
        let stack = (prefix, names, rest) :: stack in
        let path = extend prefix entry.name in
        let names' = entry.name :: names in
        let file path =
          match path with None -> raise Not_well_named | Some path -> path
        in
        match entry.file with
        | Tree.Regular_file value ->
            let path = file path in
            walk
              {
                found with
                all = path :: found.all;
                values = (path, value) :: found.values;
              }
              stack
        | Tree.Unread_file ->
            let path = file path in
            walk
              {
                found with
                all = path :: found.all;
                unread = (List.rev names', false) :: found.unread;
              }
              stack
        | Tree.Folder entries -> walk found ((path, names', entries) :: stack)
        | Tree.Unread_folder ->
            walk
              { found with unread = (List.rev names', true) :: found.unread }
              stack
        | Tree.Symbolic_link | Tree.Other_kind -> walk found stack)
  in
  walk { all = []; values = []; unread = [] } [ (Some "", [], entries) ]

(* @satisfies packs#decide-well-named-packs=v1
   Each path of the pack and each part of it before a [/] goes into one map
   under its ASCII case folding; a different path under the same folding makes
   the pack not well named. *)
let check_foldings paths =
  let rec add seen path =
    let folded = String.lowercase_ascii path in
    match Strings.find_opt folded seen with
    | Some original ->
        if String.equal original path then seen else raise Not_well_named
    | None -> (
        let seen = Strings.add folded path seen in
        match String.rindex_opt path '/' with
        | None -> seen
        | Some last -> add seen (String.sub path 0 last))
  in
  ignore (List.fold_left add Strings.empty paths)

(* @satisfies conformance#report-missing-parts=v1
   More files in a folder only add entry names, paths, and pairs of paths for
   the rules of a well-named pack, so a pack that is not well named with each
   unread folder taken as empty is not well named whatever those folders
   hold; otherwise the result needs each unread folder, and the error names
   each one. *)
let decide entries =
  match file_paths entries with
  | exception Not_well_named -> Ok None
  | found -> (
      match check_foldings found.all with
      | exception Not_well_named -> Ok None
      | () -> (
          match
            List.filter_map
              (fun (names, folder) -> if folder then Some names else None)
              found.unread
          with
          | [] -> Ok (Some (List.sort String.compare found.all))
          | parts -> Error parts))

let text_of_ascii bytes =
  Text.of_uchars
    (List.init (String.length bytes) (fun i -> Uchar.of_char bytes.[i]))

let valid_paths paths =
  List.filter_map
    (fun path -> Result.to_option (Path.of_text (text_of_ascii path)))
    paths

let well_named_files entries =
  Result.map (Option.map valid_paths) (decide entries)

let well_named pack =
  Result.map (Option.map (fun paths -> { pack; paths })) (decide pack.entries)

let pack named = named.pack
let files named = valid_paths named.paths

type listing = { text : string; hash : Hash.t }

let line (path, hash) =
  String.concat "" [ (hash : Hash.t :> string); "  "; path; "\n" ]

(* @satisfies packs#{give-pack-listings=v1, give-pack-hashes=v1}
   The listing holds one line for each file, in the order of the bytes of the
   valid paths, which is their code point order: the hash of the content, two
   spaces, the valid path, and a line feed; the pack hash is the hash of these
   bytes. A walk that fails, or that finds other files than the well-named
   pack has, gives no listing. *)
let listing named =
  match Sinter_file_read.walk_contents ~root:named.pack.root Hash.compute with
  | Error failure -> Error (Not_read failure)
  | Ok (Tree.Folder entries) -> (
      match file_paths entries with
      | exception Not_well_named -> Error Changed
      | { unread = _ :: _ as unread; _ } -> Error (Unread (List.map fst unread))
      | { values; _ } ->
          let files =
            List.sort (fun (a, _) (b, _) -> String.compare a b) values
          in
          if not (List.equal String.equal (List.map fst files) named.paths) then
            Error Changed
          else
            let text = String.concat "" (List.map line files) in
            Ok { text; hash = Hash.compute text })
  | Ok _ -> Error (Unread [ [] ])

let listing_text listing = listing.text
let hash listing = listing.hash
