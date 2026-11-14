(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Tree = Sinter_file_read.Tree
module Hash = Sinter_hashes.Hash
module Path = Sinter_paths.Path
module Strings = Map.Make (String)

type t = { root : string; entries : unit Tree.entry list }
type failure = Unreadable
type content_failure = No_file | Unreadable_file

let read ~root =
  match Sinter_file_read.walk ~root with
  | Ok entries -> Ok { root; entries }
  | Error (Sinter_file_read.Cannot_walk _) -> Error Unreadable

let entry_file entries name =
  Option.map
    (fun (entry : unit Tree.entry) -> entry.file)
    (List.find_opt (fun (entry : unit Tree.entry) -> entry.name = name) entries)

let holds entries names =
  let found =
    List.fold_left
      (fun file name ->
        match file with
        | Some (Tree.Folder entries) -> entry_file entries name
        | _ -> None)
      (Some (Tree.Folder entries)) names
  in
  match found with Some (Tree.Regular_file ()) -> true | _ -> false

(* @satisfies packs#give-pack-file-contents=v1
   The content of the file with a valid path is the whole content of the
   regular file that the UTF-8 encodings of its file names name, only when the
   folder tree has a regular file there. *)
let content pack path =
  let names = List.map Text.encode (Path.file_names path) in
  if not (holds pack.entries names) then Error No_file
  else
    match Sinter_file_read.content ~root:pack.root names with
    | Ok bytes -> Ok bytes
    | Error _ -> Error Unreadable_file

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

(* @satisfies packs#{give-pack-files=v1, decide-well-named-packs=v1}
   Each regular file of the folder tree gives the valid path of one file, and no
   other file gives one; a regular file whose path is not a pack path makes the
   pack not well named. *)
let file_paths entries =
  let rec walk files = function
    | [] -> files
    | (_, []) :: stack -> walk files stack
    | (prefix, (entry : _ Tree.entry) :: rest) :: stack -> (
        let stack = (prefix, rest) :: stack in
        let path = extend prefix entry.name in
        match entry.file with
        | Tree.Regular_file value -> (
            match path with
            | None -> raise Not_well_named
            | Some path -> walk ((path, value) :: files) stack)
        | Tree.Folder entries -> walk files ((path, entries) :: stack)
        | Tree.Symbolic_link | Tree.Other_kind -> walk files stack)
  in
  walk [] [ (Some "", entries) ]

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

let decide entries =
  match List.map fst (file_paths entries) with
  | exception Not_well_named -> None
  | paths -> (
      match check_foldings paths with
      | exception Not_well_named -> None
      | () -> Some (List.sort String.compare paths))

let text_of_ascii bytes =
  Text.of_uchars
    (List.init (String.length bytes) (fun i -> Uchar.of_char bytes.[i]))

let valid_paths paths =
  List.filter_map
    (fun path -> Result.to_option (Path.of_text (text_of_ascii path)))
    paths

let well_named_files entries = Option.map valid_paths (decide entries)

let well_named pack =
  Option.map (fun paths -> { pack; paths }) (decide pack.entries)

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
  | Error (Sinter_file_read.Cannot_walk _) -> Error Unreadable
  | Ok entries -> (
      match file_paths entries with
      | exception Not_well_named -> Error Unreadable
      | files ->
          let files =
            List.sort (fun (a, _) (b, _) -> String.compare a b) files
          in
          if not (List.equal String.equal (List.map fst files) named.paths) then
            Error Unreadable
          else
            let text = String.concat "" (List.map line files) in
            Ok { text; hash = Hash.compute text })

let listing_text listing = listing.text
let hash listing = listing.hash
