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
type limit = Descriptors | Memory | File_size | Pathname_length

type failure =
  | Stopped of { limit : limit; names : string list }
  | Failed of { names : string list; error : Unix.error }
  | Changed of string list

module Tree = struct
  type 'a file =
    | Folder of 'a entry list
    | Regular_file of 'a
    | Symbolic_link
    | Other_kind
    | Unread_folder
    | Unread_file

  and 'a entry = { name : string; file : 'a file }
end

type content_failure =
  | Not_entry_names
  | No_content_file
  | Content_symbolic_link
  | Not_regular
  | Cannot_take of string list

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
  val estale : int
end

module Walk (S : SYSTEM) = struct
  type miss = Absent | Link | Not_regular_file | Unread of string list

  type step =
    | Done of (string, miss) result
    | Enter of {
        folder : S.descr;
        path : string list;
        name : string;
        rest : string list;
      }

  type taken = Content of string | Not_regular_open | Call_error of Unix.error

  exception Stop of failure

  let stop names limit = raise (Stop (Stopped { limit; names }))
  let close descr = try S.close descr with Unix.Unix_error _ -> ()
  let closing descr f = Fun.protect ~finally:(fun () -> close descr) f

  let call f =
    match f () with
    | value -> Ok value
    | exception Unix.Unix_error (error, _, _) -> Error error
    | exception Out_of_memory -> Error Unix.ENOMEM

  (* @satisfies conformance#{report-missing-parts=v1, report-stops-at-limits=v1}
     A refused permission or an input or output error makes the content of the
     call a missing part, which the caller reports by its names; no free file
     descriptor, no memory, and a file too large to read whole stop the read at
     a limit of the program's own, at the names of the file of the call; every
     other error gives no result and is no report of a missing part. *)
  let missing names = function
    | Unix.EACCES | Unix.EPERM | Unix.EIO | Unix.ENXIO | Unix.ENODEV
    | Unix.ETIMEDOUT | Unix.ECONNABORTED | Unix.ECONNRESET | Unix.ENOTCONN
    | Unix.ENETDOWN | Unix.ENETRESET | Unix.ENETUNREACH | Unix.EHOSTUNREACH ->
        ()
    | Unix.EUNKNOWNERR code when code = S.estale -> ()
    | Unix.EMFILE | Unix.ENFILE -> stop names Descriptors
    | Unix.ENOMEM -> stop names Memory
    | Unix.EOVERFLOW -> stop names File_size
    | error -> raise (Stop (Failed { names; error }))

  let unread ~names ~part error =
    missing names error;
    Error (Unread part)

  (* @satisfies files#give-file-read-results=v1
     A name that is not there, or that the system or the file system does not
     accept as one entry name, names no folder entry; it is no failure of the
     system and no limit of the program's own. *)
  let rejects_name = function
    | Unix.ENOENT | Unix.ENAMETOOLONG | Unix.EINVAL -> true
    | Unix.EUNKNOWNERR code -> code = S.eilseq
    | _ -> false

  (* @satisfies files#{give-file-read-results=v1, read-only-named-files=v1, avoid-waits=v1}
     Bytes come only from the last file, and only when it is still a regular
     file once open, and the bytes are the whole content. *)
  (* @satisfies packs#read-only-pack-files=v1
     The content of a file is taken only when the open file is still a regular
     file. *)
  let read_file folder name =
    match call (fun () -> S.open_file folder name) with
    | Error error -> Call_error error
    | Ok file -> (
        closing file @@ fun () ->
        match call (fun () -> S.is_regular_file file) with
        | Error error -> Call_error error
        | Ok false -> Not_regular_open
        | Ok true -> (
            match call (fun () -> S.content file) with
            | Error error -> Call_error error
            | Ok bytes -> Content bytes))

  (* @satisfies files#{give-file-read-results=v1, follow-no-symbolic-links=v1, read-only-named-files=v1, avoid-waits=v1}
     For file name k, the cases of the file-read result apply in their order:
     no search permission for folder k, a name that folder k does not hold byte
     for byte in its listing, a symbolic link, a file that is not a folder
     before the last name, and a last name that is not a regular file each end
     the read before any open of that file; only a folder before the last name
     is entered. A folder whose entries, or a last file whose content, the
     system refuses or cannot give is a missing part, which gives "cannot
     read". *)
  let step folder path name rest =
    let names = path @ [ name ] in
    match call (fun () -> S.check_search folder) with
    | Error error -> Done (unread ~names:path ~part:path error)
    | Ok () -> (
        match call (fun () -> S.kind folder name) with
        | Error error when rejects_name error -> Done (Error Absent)
        | Error error -> Done (unread ~names ~part:path error)
        | Ok kind -> (
            match call (fun () -> S.listing folder) with
            | Error error -> Done (unread ~names:path ~part:path error)
            | Ok listing when not (List.mem name listing) -> Done (Error Absent)
            | Ok _ -> (
                match (kind, rest) with
                | Symbolic_link, _ -> Done (Error Link)
                | (Regular_file | Other_kind), _ :: _ -> Done (Error Absent)
                | (Folder | Other_kind), [] -> Done (Error Not_regular_file)
                | Regular_file, [] -> (
                    match read_file folder name with
                    | Content bytes -> Done (Ok bytes)
                    | Not_regular_open -> Done (Error Not_regular_file)
                    | Call_error error -> Done (unread ~names ~part:names error)
                    )
                | Folder, next :: rest -> (
                    match call (fun () -> S.open_folder folder name) with
                    | Error error -> Done (unread ~names ~part:names error)
                    | Ok folder ->
                        Enter { folder; path = names; name = next; rest }))))

  let rec descend folder path name rest =
    match closing folder (fun () -> step folder path name rest) with
    | Done result -> result
    | Enter { folder; path; name; rest } -> descend folder path name rest

  (* @satisfies conformance#report-stops-at-limits=v1
     A pathname of the root that is too long for the system stops the read at
     a limit of the program's own, at the root. *)
  let take root name rest =
    match call (fun () -> S.open_root root) with
    | Error Unix.ENAMETOOLONG -> stop [] Pathname_length
    | Error error -> unread ~names:[] ~part:[] error
    | Ok folder -> descend folder [] name rest

  (* @satisfies files#{give-invalid-for-non-paths=v1, give-file-text=v1, omit-texts-of-other-results=v1, read-only-named-files=v1, gain-no-privileges=v1}
     A text that is not a valid path gives "invalid" before any call of the
     system; a content that is not valid UTF-8 gives "not UTF-8", and only
     "found" carries a text, the text of the whole content; every call runs
     with the user IDs, the group IDs, and the privileges that the process
     has. *)
  (* @satisfies files#give-file-read-results=v1
     A read that stops at a limit of the program's own gives an error in place
     of an outcome, so it gives none of the results and no text; "cannot read",
     given once, is the report of the missing parts that the result needs. *)
  let read ~root text =
    match Sinter_paths.Path.of_text text with
    | Error _ -> Ok Invalid
    | Ok path -> (
        let names = List.map Text.encode (Sinter_paths.Path.file_names path) in
        match names with
        | [] -> Ok Invalid
        | name :: rest -> (
            match take root name rest with
            | exception Stop failure -> Error failure
            | Error Absent -> Ok No_file
            | Error Link -> Ok Symbolic_link
            | Error Not_regular_file -> Ok Not_a_regular_file
            | Error (Unread _) -> Ok Cannot_read
            | Ok bytes -> (
                match Text.decode bytes with
                | Ok text -> Ok (Found text)
                | Error (Text.Invalid_utf_8 _) -> Ok Not_utf_8
                | exception Out_of_memory ->
                    Error (Stopped { limit = Memory; names }))))

  let entry_name name =
    name <> "" && name <> "." && name <> ".."
    && not (String.exists (fun c -> c = '/' || c = '\000') name)

  let content ~root names =
    match names with
    | name :: rest when List.for_all entry_name names -> (
        match take root name rest with
        | exception Stop failure -> Error failure
        | Ok bytes -> Ok (Ok bytes)
        | Error Absent -> Ok (Error No_content_file)
        | Error Link -> Ok (Error Content_symbolic_link)
        | Error Not_regular_file -> Ok (Error Not_regular)
        | Error (Unread part) -> Ok (Error (Cannot_take part)))
    | _ -> Ok (Error Not_entry_names)

  type 'a frame = {
    descr : S.descr;
    name : string;
    names : string list;
    mutable pending : string list;
    mutable entries : 'a Tree.entry list;
  }

  (* @satisfies packs#{follow-no-pack-links=v1, read-only-pack-files=v1, avoid-pack-waits=v1}
     The kind of each name comes from [kind] before any open of its file; only
     a folder opens, by [open_folder], and only a regular file is handed to the
     reading of its content, so no symbolic link and no file of another kind
     opens. *)
  (* @satisfies conformance#report-missing-parts=v1
     A folder whose listing, or the kind of one of whose names, the system
     refuses or cannot give is one missing part, marked once at its place; the
     walk keeps none of its entries and goes on with the rest of the tree, so
     a caller can give each thing that does not need that part. *)
  let traverse ~root regular =
    let stack = ref [] in
    let rec loop frame below =
      match frame.pending with
      | [] -> pop below frame (Tree.Folder (List.rev frame.entries))
      | name :: rest -> (
          frame.pending <- rest;
          let names = name :: frame.names in
          match call (fun () -> S.kind frame.descr name) with
          | Error error ->
              missing (List.rev names) error;
              pop below frame Tree.Unread_folder
          | Ok Folder -> (
              match call (fun () -> S.open_folder frame.descr name) with
              | Error error ->
                  missing (List.rev names) error;
                  add frame below name Tree.Unread_folder
              | Ok descr -> enter descr name names (frame :: below))
          | Ok Regular_file ->
              add frame below name (regular frame.descr name names)
          | Ok Symbolic_link -> add frame below name Tree.Symbolic_link
          | Ok Other_kind -> add frame below name Tree.Other_kind)
    and pop below frame file =
      stack := below;
      close frame.descr;
      match below with
      | [] -> file
      | parent :: above -> add parent above frame.name file
    and add frame below name file =
      frame.entries <- { Tree.name; file } :: frame.entries;
      loop frame below
    and enter descr name names below =
      let frame = { descr; name; names; pending = []; entries = [] } in
      stack := frame :: below;
      match call (fun () -> S.listing descr) with
      | Error error ->
          missing (List.rev names) error;
          pop below frame Tree.Unread_folder
      | Ok listing ->
          frame.pending <-
            List.sort String.compare
              (List.filter (fun name -> name <> "." && name <> "..") listing);
          loop frame below
    in
    let close_all () =
      List.iter (fun frame -> close frame.descr) !stack;
      stack := []
    in
    Fun.protect ~finally:close_all @@ fun () ->
    match
      match call (fun () -> S.open_root root) with
      | Error Unix.ENAMETOOLONG -> stop [] Pathname_length
      | Error error ->
          missing [] error;
          Tree.Unread_folder
      | Ok descr -> enter descr "" [] []
    with
    | file -> Ok file
    | exception Stop failure -> Error failure

  let walk ~root = traverse ~root (fun _ _ _ -> Tree.Regular_file ())

  (* @satisfies conformance#report-missing-parts=v1
     A regular file whose content the system refuses or cannot give is one
     missing part, marked at its place, and the walk goes on. *)
  let walk_contents ~root value =
    traverse ~root (fun folder name names ->
        match read_file folder name with
        | Content bytes -> Tree.Regular_file (value bytes)
        | Call_error error ->
            missing (List.rev names) error;
            Tree.Unread_file
        | Not_regular_open -> raise (Stop (Changed (List.rev names))))
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
external estale : unit -> int = "sinter_file_read_estale" [@@noalloc]

module System = struct
  type descr = Unix.file_descr

  (* @satisfies conformance#report-missing-parts=v1
     A call that a signal interrupts runs again, so the content that a later
     attempt takes is no missing part. *)
  let rec again f x =
    try f x with Unix.Unix_error (Unix.EINTR, _, _) -> again f x

  let open_root = again open_root
  let open_folder folder = again (open_folder folder)
  let open_file folder = again (open_file folder)

  (* @satisfies files#give-file-read-results=v1
     The file type of a file gives the kind of that file: a file of the type
     directory is a folder, a file of the type regular file is a regular file,
     a file of the type symbolic link is a symbolic link, and a file of each
     other type is a file of another kind. *)
  let kind folder name =
    match again (kind_code folder) name with
    | 0 -> Folder
    | 1 -> Regular_file
    | 2 -> Symbolic_link
    | _ -> Other_kind

  let check_search = again check_search
  let listing = again listing

  (* @satisfies files#{give-file-read-results=v1, read-only-named-files=v1}
     The open last file counts as a regular file only when its file type is
     regular file. *)
  let is_regular_file file =
    (again Unix.LargeFile.fstat file).st_kind = Unix.S_REG

  (* @satisfies conformance#report-missing-parts=v1
     The content comes from reads of the system up to the end of the file, so
     a read that fails gives the error of the system, which tells a missing
     part from a stop at a limit of the program's own. *)
  let content file =
    let size = (again Unix.LargeFile.fstat file).st_size in
    let buffer =
      Buffer.create
        (Int64.to_int (Int64.min size (Int64.of_int Sys.max_string_length)))
    in
    let chunk =
      Bytes.create
        (65536
        [@mutaml.skip
          "Unix.read takes at most 65536 bytes in one call, so a larger chunk \
           makes the same reads, and the loop adds every byte that each read \
           gives"])
    in
    let rec fill () =
      match again (Unix.read file chunk 0) (Bytes.length chunk) with
      | 0 -> Buffer.contents buffer
      | count ->
          Buffer.add_subbytes buffer chunk 0 count;
          fill ()
    in
    fill ()

  let close = Unix.close
  let eilseq = eilseq ()
  let estale = estale ()
end

module Real = Walk (System)

let read = Real.read
let walk = Real.walk
let walk_contents = Real.walk_contents
let content = Real.content
