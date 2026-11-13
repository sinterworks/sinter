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
  type step =
    | Done of outcome
    | Enter of { folder : S.descr; name : string; rest : string list }

  let closing descr f =
    Fun.protect
      ~finally:(fun () ->
        try S.close descr with Unix.Unix_error _ | Sys_error _ -> ())
      f

  (* @satisfies files#give-file-read-results=v1
     A name that is not there, or that the system or the file system does not
     accept as an entry name, names no folder entry; it is no failure of the
     system. *)
  let rejects_name = function
    | Unix.ENOENT | Unix.ENAMETOOLONG | Unix.EINVAL -> true
    | Unix.EUNKNOWNERR code -> code = S.eilseq
    | _ -> false

  (* @satisfies files#{give-file-read-results=v1, give-file-text=v1, omit-texts-of-other-results=v1, read-only-named-files=v1, avoid-waits=v1}
     Bytes come only from the last file, and only when it is still a regular
     file once open: no read permission gives "cannot read", a content that is
     not valid UTF-8 gives "not UTF-8", and only "found" carries a text, the
     text of the whole content. *)
  let read_file folder name =
    match S.open_file folder name with
    | exception (Unix.Unix_error _ | Sys_error _) -> Cannot_read
    | file -> (
        closing file @@ fun () ->
        match S.is_regular_file file with
        | exception (Unix.Unix_error _ | Sys_error _) -> Cannot_read
        | false -> Not_a_regular_file
        | true -> (
            match S.content file with
            | exception (Unix.Unix_error _ | Sys_error _) -> Cannot_read
            | bytes -> (
                match Text.decode bytes with
                | Ok text -> Found text
                | Error (Text.Invalid_utf_8 _) -> Not_utf_8)))

  (* @satisfies files#{give-file-read-results=v1, follow-no-symbolic-links=v1, read-only-named-files=v1, avoid-waits=v1}
     For file name k, the cases of the file-read result apply in their order:
     no search permission for folder k, a name that folder k does not hold byte
     for byte in its listing, a symbolic link, a file that is not a folder
     before the last name, and a last name that is not a regular file each end
     the read before any open of that file; only a folder before the last name
     is entered. *)
  let step folder name rest =
    match S.check_search folder with
    | exception (Unix.Unix_error _ | Sys_error _) -> Done Cannot_read
    | () -> (
        match S.kind folder name with
        | exception Unix.Unix_error (error, _, _) ->
            Done (if rejects_name error then No_file else Cannot_read)
        | exception Sys_error _ -> Done Cannot_read
        | kind -> (
            match List.mem name (S.listing folder) with
            | exception (Unix.Unix_error _ | Sys_error _) -> Done Cannot_read
            | false -> Done No_file
            | true -> (
                match (kind, rest) with
                | Symbolic_link, _ -> Done Symbolic_link
                | (Regular_file | Other_kind), _ :: _ -> Done No_file
                | (Folder | Other_kind), [] -> Done Not_a_regular_file
                | Regular_file, [] -> Done (read_file folder name)
                | Folder, next :: rest -> (
                    match S.open_folder folder name with
                    | exception (Unix.Unix_error _ | Sys_error _) ->
                        Done Cannot_read
                    | folder -> Enter { folder; name = next; rest }))))

  let rec walk folder name rest =
    match closing folder (fun () -> step folder name rest) with
    | Done outcome -> outcome
    | Enter { folder; name; rest } -> walk folder name rest

  (* @satisfies files#{give-invalid-for-non-paths=v1, read-only-named-files=v1, gain-no-privileges=v1}
     A text that is not a valid path gives "invalid" before any call of the
     system; every call runs with the user IDs, the group IDs, and the
     privileges that the process has. *)
  let read ~root text =
    match Sinter_paths.Path.of_text text with
    | Error _ -> Invalid
    | Ok path -> (
        match List.map Text.encode (Sinter_paths.Path.file_names path) with
        | [] -> Invalid
        | name :: rest -> (
            match S.open_root root with
            | exception (Unix.Unix_error _ | Sys_error _) -> Cannot_read
            | folder -> walk folder name rest))
end

external open_root : string -> Unix.file_descr = "sinter_file_read_open_root"

(* @satisfies files#{follow-no-symbolic-links=v1, keep-folder-trees-unchanged=v1}
   A folder opens for reading only, relative to the folder before it, and the
   open fails when the name is a symbolic link. *)
external open_folder : Unix.file_descr -> string -> Unix.file_descr
  = "sinter_file_read_open_folder"

(* @satisfies files#{follow-no-symbolic-links=v1, avoid-waits=v1, keep-folder-trees-unchanged=v1}
   The last file opens for reading only, fails when it is a symbolic link,
   and does not wait for another process to open a pipe. *)
external open_file : Unix.file_descr -> string -> Unix.file_descr
  = "sinter_file_read_open_file"

(* @satisfies files#follow-no-symbolic-links=v1
   The file type of a name comes from the name itself, not from the file that
   a symbolic link leads to. *)
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

let read =
  let module W = Walk (System) in
  W.read
