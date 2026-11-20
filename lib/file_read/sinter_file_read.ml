(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(* @cites file-read-calls *)

open Sinter_text

type outcome =
  | Invalid
  | Found of Text.t
  | No_file
  | Symbolic_link
  | Not_a_regular_file
  | Not_utf_8
  | Cannot_read

type kind = Folder | Regular_file | Symbolic_link | Other_kind

module Tree = struct
  type 'a file =
    | Folder of 'a entry list
    | Regular_file of 'a
    | Symbolic_link
    | Other_kind

  and 'a entry = { name : string; file : 'a file }
end

type walk_failure = Cannot_walk of string list

type content_failure =
  | Not_entry_names
  | No_content_file
  | Content_symbolic_link
  | Not_regular
  | Cannot_take

module type SYSTEM = sig
  type descr

  val open_root : string -> descr
  val open_folder : descr -> string -> descr
  val open_file : descr -> string -> descr
  val kind : descr -> string -> kind
  val check_search : descr -> unit
  val listing : descr -> string list
  val is_regular_file : descr -> bool
  val content : descr -> string
  val close : descr -> unit
  val eilseq : int
end

module Walk (S : SYSTEM) = struct
  type miss = Absent | Link | Not_regular_file | Unreadable

  type step =
    | Done of (string, miss) result
    | Enter of { folder : S.descr; name : string; rest : string list }

  let close descr =
    try S.close descr with Unix.Unix_error _ | Sys_error _ -> ()

  let closing descr f = Fun.protect ~finally:(fun () -> close descr) f

  (* @satisfies files#give-file-read-results=v1
     A name that is not there, or that the system or the file system does not
     accept as an entry name, names no folder entry; it is no failure of the
     system. *)
  let rejects_name = function
    | Unix.ENOENT | Unix.ENAMETOOLONG | Unix.EINVAL -> true
    | Unix.EUNKNOWNERR code -> code = S.eilseq
    | _ -> false

  (* @satisfies files#{give-file-read-results=v1, read-only-named-files=v1, avoid-waits=v1}
     Bytes come only from the last file, and only when it is still a regular
     file once open: no read permission gives "cannot read", and the bytes are
     the whole content. *)
  (* @satisfies packs#read-only-pack-files=v1
     The content of a file is taken only when the open file is still a regular
     file. *)
  let read_file folder name =
    match S.open_file folder name with
    | exception (Unix.Unix_error _ | Sys_error _) -> Error Unreadable
    | file -> (
        closing file @@ fun () ->
        match S.is_regular_file file with
        | exception (Unix.Unix_error _ | Sys_error _) -> Error Unreadable
        | false -> Error Not_regular_file
        | true -> (
            match S.content file with
            | exception (Unix.Unix_error _ | Sys_error _) -> Error Unreadable
            | bytes -> Ok bytes))

  (* @satisfies files#{give-file-read-results=v1, follow-no-symbolic-links=v1, read-only-named-files=v1, avoid-waits=v1}
     For file name k, the cases of the file-read result apply in their order:
     no search permission for folder k, a name that folder k does not hold byte
     for byte in its listing, a symbolic link, a file that is not a folder
     before the last name, and a last name that is not a regular file each end
     the read before any open of that file; only a folder before the last name
     is entered. *)
  let step folder name rest =
    match S.check_search folder with
    | exception (Unix.Unix_error _ | Sys_error _) -> Done (Error Unreadable)
    | () -> (
        match S.kind folder name with
        | exception Unix.Unix_error (error, _, _) ->
            Done (Error (if rejects_name error then Absent else Unreadable))
        | exception Sys_error _ -> Done (Error Unreadable)
        | kind -> (
            match List.mem name (S.listing folder) with
            | exception (Unix.Unix_error _ | Sys_error _) ->
                Done (Error Unreadable)
            | false -> Done (Error Absent)
            | true -> (
                match (kind, rest) with
                | Symbolic_link, _ -> Done (Error Link)
                | (Regular_file | Other_kind), _ :: _ -> Done (Error Absent)
                | (Folder | Other_kind), [] -> Done (Error Not_regular_file)
                | Regular_file, [] -> Done (read_file folder name)
                | Folder, next :: rest -> (
                    match S.open_folder folder name with
                    | exception (Unix.Unix_error _ | Sys_error _) ->
                        Done (Error Unreadable)
                    | folder -> Enter { folder; name = next; rest }))))

  let rec descend folder name rest =
    match closing folder (fun () -> step folder name rest) with
    | Done result -> result
    | Enter { folder; name; rest } -> descend folder name rest

  let take root name rest =
    match S.open_root root with
    | exception (Unix.Unix_error _ | Sys_error _) -> Error Unreadable
    | folder -> descend folder name rest

  (* @satisfies files#{give-invalid-for-non-paths=v1, give-file-text=v1, omit-texts-of-other-results=v1, read-only-named-files=v1, gain-no-privileges=v1}
     A text that is not a valid path gives "invalid" before any call of the
     system; a content that is not valid UTF-8 gives "not UTF-8", and only
     "found" carries a text, the text of the whole content; every call runs
     with the user IDs, the group IDs, and the privileges that the process
     has. *)
  let read ~root text =
    match Sinter_paths.Path.of_text text with
    | Error _ -> Invalid
    | Ok path -> (
        match List.map Text.encode (Sinter_paths.Path.file_names path) with
        | [] -> Invalid
        | name :: rest -> (
            match take root name rest with
            | Error Absent -> No_file
            | Error Link -> Symbolic_link
            | Error Not_regular_file -> Not_a_regular_file
            | Error Unreadable -> Cannot_read
            | Ok bytes -> (
                match Text.decode bytes with
                | Ok text -> Found text
                | Error (Text.Invalid_utf_8 _) -> Not_utf_8)))

  let entry_name name =
    name <> "" && name <> "." && name <> ".."
    && not (String.exists (fun c -> c = '/' || c = '\000') name)

  let content ~root names =
    match names with
    | name :: rest when List.for_all entry_name names -> (
        match take root name rest with
        | Ok bytes -> Ok bytes
        | Error Absent -> Error No_content_file
        | Error Link -> Error Content_symbolic_link
        | Error Not_regular_file -> Error Not_regular
        | Error Unreadable -> Error Cannot_take)
    | _ -> Error Not_entry_names

  type 'a frame = {
    descr : S.descr;
    name : string;
    names : string list;
    mutable pending : string list;
    mutable entries : 'a Tree.entry list;
  }

  exception Failed of string list

  let folder_entry_names descr names =
    match S.listing descr with
    | exception (Unix.Unix_error _ | Sys_error _) ->
        raise (Failed (List.rev names))
    | listing ->
        List.sort String.compare
          (List.filter (fun name -> name <> "." && name <> "..") listing)

  (* @satisfies packs#{follow-no-pack-links=v1, read-only-pack-files=v1, avoid-pack-waits=v1}
     The kind of each name comes from [kind] before any open of its file; only
     a folder opens, by [open_folder], and only a regular file is handed to the
     reading of its content, so no symbolic link and no file of another kind
     opens. *)
  let traverse ~root regular =
    let stack = ref [] in
    let push descr name names =
      let frame = { descr; name; names; pending = []; entries = [] } in
      stack := frame :: !stack;
      frame.pending <- folder_entry_names descr names
    in
    let rec loop () =
      match !stack with
      | [] -> []
      | frame :: below -> (
          match frame.pending with
          | [] -> (
              stack := below;
              close frame.descr;
              let entries = List.rev frame.entries in
              match below with
              | [] -> entries
              | parent :: _ ->
                  parent.entries <-
                    { Tree.name = frame.name; file = Tree.Folder entries }
                    :: parent.entries;
                  loop ())
          | name :: rest -> (
              frame.pending <- rest;
              let names = name :: frame.names in
              let failed () = raise (Failed (List.rev names)) in
              let add file =
                frame.entries <- { Tree.name; file } :: frame.entries;
                loop ()
              in
              match S.kind frame.descr name with
              | exception (Unix.Unix_error _ | Sys_error _) -> failed ()
              | Folder -> (
                  match S.open_folder frame.descr name with
                  | exception (Unix.Unix_error _ | Sys_error _) -> failed ()
                  | descr ->
                      push descr name names;
                      loop ())
              | Regular_file ->
                  add (Tree.Regular_file (regular frame.descr name failed))
              | Symbolic_link -> add Tree.Symbolic_link
              | Other_kind -> add Tree.Other_kind))
    in
    let close_all () =
      List.iter (fun frame -> close frame.descr) !stack;
      stack := []
    in
    Fun.protect ~finally:close_all @@ fun () ->
    match S.open_root root with
    | exception (Unix.Unix_error _ | Sys_error _) -> Error (Cannot_walk [])
    | descr -> (
        match
          push descr "" [];
          loop ()
        with
        | entries -> Ok entries
        | exception Failed names -> Error (Cannot_walk names))

  let walk ~root = traverse ~root (fun _ _ _ -> ())

  let walk_contents ~root value =
    traverse ~root (fun folder name failed ->
        match read_file folder name with
        | Ok bytes -> value bytes
        | Error _ -> failed ())
end

external open_root : string -> Unix.file_descr = "sinter_file_read_open_root"

(* @satisfies files#{follow-no-symbolic-links=v1, keep-folder-trees-unchanged=v1}
   A folder opens for reading only, relative to the folder before it, and the
   open fails when the name is a symbolic link. *)
(* @satisfies packs#{follow-no-pack-links=v1, keep-packs-unchanged=v1}
   A folder of a pack opens for reading only, relative to the folder that
   holds it, and the open fails when the name is a symbolic link. *)
external open_folder : Unix.file_descr -> string -> Unix.file_descr
  = "sinter_file_read_open_folder"

(* @satisfies files#{follow-no-symbolic-links=v1, avoid-waits=v1, keep-folder-trees-unchanged=v1}
   The last file opens for reading only, fails when it is a symbolic link,
   and does not wait for another process to open a pipe. *)
(* @satisfies packs#{follow-no-pack-links=v1, avoid-pack-waits=v1, keep-packs-unchanged=v1}
   A regular file of a pack opens for reading only, fails when it is a
   symbolic link, and does not wait for another process to open a pipe. *)
external open_file : Unix.file_descr -> string -> Unix.file_descr
  = "sinter_file_read_open_file"

(* @satisfies files#follow-no-symbolic-links=v1
   The file type of a name comes from the name itself, not from the file that
   a symbolic link leads to. *)
(* @satisfies packs#follow-no-pack-links=v1
   The kind of a file of a pack comes from the name itself, not from the file
   that a symbolic link leads to. *)
external kind_code : Unix.file_descr -> string -> int
  = "sinter_file_read_kind_at"

external check_search : Unix.file_descr -> unit
  = "sinter_file_read_check_search"

external listing : Unix.file_descr -> string list = "sinter_file_read_list"
external eilseq : unit -> int = "sinter_file_read_eilseq" [@@noalloc]

module System = struct
  type descr = Unix.file_descr

  let open_root = open_root
  let open_folder = open_folder
  let open_file = open_file

  (* @satisfies files#give-file-read-results=v1
     The file type of a file gives its kind: a directory is a folder, a
     regular file is a regular file, a symbolic link is a symbolic link, and
     each other type is a file of another kind. *)
  let kind folder name =
    match kind_code folder name with
    | 0 -> Folder
    | 1 -> Regular_file
    | 2 -> Symbolic_link
    | _ -> Other_kind

  let check_search = check_search
  let listing = listing

  (* @satisfies files#{give-file-read-results=v1, read-only-named-files=v1}
     The open last file counts as a regular file only when its file type is
     regular file. *)
  let is_regular_file file = (Unix.fstat file).st_kind = Unix.S_REG
  let content file = In_channel.input_all (Unix.in_channel_of_descr file)
  let close = Unix.close
  let eilseq = eilseq ()
end

module Real = Walk (System)

let read = Real.read
let walk = Real.walk
let walk_contents = Real.walk_contents
let content = Real.content
