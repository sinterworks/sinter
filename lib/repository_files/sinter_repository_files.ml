(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type kind = Folder | Regular_file | Symbolic_link | Other_kind
type identity = { device : int; inode : int }
type status = { kind : kind; size : int; identity : identity }

type failure =
  | No_file
  | Not_a_regular_file
  | Not_a_folder
  | Not_a_symbolic_link
  | Too_large
  | Cannot_read

module type SYSTEM = sig
  type descr

  val stat : string -> kind
  val lstat : string -> kind
  val open_file : string -> descr
  val open_folder : string -> descr
  val fstat : descr -> status
  val read : descr -> offset:int -> bytes -> int -> int -> int
  val readlink : string -> string
  val listing : descr -> string list
  val close : descr -> unit
  val eilseq : int
end

module type READER = sig
  type handle

  val read : max_size:int -> string -> (string, failure) result
  val with_file : string -> (handle -> 'a) -> ('a, failure) result
  val size : handle -> int
  val identity : handle -> identity

  val read_range :
    handle -> offset:int -> length:int -> (string, failure) result

  val list : string -> (string list, failure) result
  val link_kind : string -> (kind, failure) result
  val link_text : string -> (string, failure) result
end

module Make (S : SYSTEM) = struct
  type handle = { descr : S.descr; status : status; mutable open_ : bool }

  let names_no_file = function
    | Unix.ENOENT | Unix.ENOTDIR | Unix.ENAMETOOLONG -> true
    | Unix.EUNKNOWNERR code -> code = S.eilseq
    | _ -> false

  let failure_of = function
    | Unix.Unix_error (error, _, _) when names_no_file error -> No_file
    | _ -> Cannot_read

  let system f =
    match f () with
    | value -> Ok value
    | exception (Unix.Unix_error _ as error) -> Error (failure_of error)

  let usable pathname = pathname <> "" && not (String.contains pathname '\000')

  let closing descr f =
    Fun.protect
      ~finally:(fun () -> try S.close descr with Unix.Unix_error _ -> ())
      f

  let open_regular pathname =
    if not (usable pathname) then Error No_file
    else
      match system (fun () -> S.stat pathname) with
      | Error failure -> Error failure
      | Ok (Folder | Symbolic_link | Other_kind) -> Error Not_a_regular_file
      | Ok Regular_file -> (
          match system (fun () -> S.open_file pathname) with
          | Error failure -> Error failure
          | Ok descr -> (
              match system (fun () -> S.fstat descr) with
              | Error failure ->
                  (try S.close descr with Unix.Unix_error _ -> ());
                  Error failure
              | Ok ({ kind = Regular_file; _ } as status) ->
                  Ok { descr; status; open_ = true }
              | Ok { kind = Folder | Symbolic_link | Other_kind; _ } ->
                  (try S.close descr with Unix.Unix_error _ -> ());
                  Error Not_a_regular_file))

  let check handle =
    if not handle.open_ then
      invalid_arg "Sinter_repository_files: the file is closed"

  let with_file pathname f =
    match open_regular pathname with
    | Error failure -> Error failure
    | Ok handle ->
        Ok
          (closing handle.descr (fun () ->
               Fun.protect
                 ~finally:(fun () -> handle.open_ <- false)
                 (fun () -> f handle)))

  let size handle =
    check handle;
    handle.status.size

  let identity handle =
    check handle;
    handle.status.identity

  let read_bytes handle ~offset ~length =
    let chunk =
      Bytes.create
        (min length
           (65536
           [@mutaml.skip
             "the chunk is only the room of one call of read; the loop reads \
              until it has length bytes or the end of the file, so any \
              positive size gives the same bytes"]))
    in
    let buffer = Buffer.create (Bytes.length chunk) in
    let rec fill filled =
      match
        S.read handle.descr ~offset:(offset + filled) chunk 0
          (min (Bytes.length chunk) (length - filled))
      with
      | 0 -> ()
      | count ->
          Buffer.add_subbytes buffer chunk 0 count;
          fill (filled + count)
    in
    match system (fun () -> fill 0) with
    | Ok () -> Ok (Buffer.contents buffer)
    | Error failure -> Error failure

  let read_range handle ~offset ~length =
    check handle;
    if offset < 0 || length < 0 then
      invalid_arg "Sinter_repository_files.read_range: a negative number"
    else read_bytes handle ~offset ~length

  let read_at_most max_size handle =
    if handle.status.size > max_size then Error Too_large
    else
      let length = if max_size = max_int then max_int else max_size + 1 in
      match read_bytes handle ~offset:0 ~length with
      | Ok content when String.length content > max_size -> Error Too_large
      | result -> result

  let read ~max_size pathname =
    if max_size < 0 then
      invalid_arg "Sinter_repository_files.read: a negative maximum size"
    else
      match with_file pathname (read_at_most max_size) with
      | Error failure | Ok (Error failure) -> Error failure
      | Ok (Ok content) -> Ok content

  let list pathname =
    if not (usable pathname) then Error No_file
    else
      match system (fun () -> S.stat pathname) with
      | Error failure -> Error failure
      | Ok (Regular_file | Symbolic_link | Other_kind) -> Error Not_a_folder
      | Ok Folder -> (
          match system (fun () -> S.open_folder pathname) with
          | Error failure -> Error failure
          | Ok descr ->
              closing descr (fun () ->
                  match system (fun () -> S.listing descr) with
                  | Error failure -> Error failure
                  | Ok names ->
                      Ok
                        (List.sort_uniq String.compare
                           (List.filter
                              (fun name -> name <> "." && name <> "..")
                              names))))

  let link_kind pathname =
    if not (usable pathname) then Error No_file
    else system (fun () -> S.lstat pathname)

  let link_text pathname =
    match link_kind pathname with
    | Error failure -> Error failure
    | Ok (Folder | Regular_file | Other_kind) -> Error Not_a_symbolic_link
    | Ok Symbolic_link -> system (fun () -> S.readlink pathname)
end

external open_folder : string -> Unix.file_descr
  = "sinter_repository_files_open_folder"

external listing : Unix.file_descr -> string list
  = "sinter_repository_files_list"

external eilseq : unit -> int = "sinter_repository_files_eilseq" [@@noalloc]

module System = struct
  type descr = Unix.file_descr

  let kind_of (kind : Unix.file_kind) =
    match kind with
    | Unix.S_DIR -> Folder
    | Unix.S_REG -> Regular_file
    | Unix.S_LNK -> Symbolic_link
    | Unix.S_CHR | Unix.S_BLK | Unix.S_FIFO | Unix.S_SOCK -> Other_kind

  let stat pathname = kind_of (Unix.stat pathname).st_kind
  let lstat pathname = kind_of (Unix.lstat pathname).st_kind

  (* @satisfies changes#leave-repositories-unchanged=v1
     A file opens for reading only, with no flag that creates or truncates a
     file, so the open creates and changes no file. *)
  let open_file pathname =
    Unix.openfile pathname
      [ Unix.O_RDONLY; Unix.O_NONBLOCK; Unix.O_NOCTTY; Unix.O_CLOEXEC ]
      (0
      [@mutaml.skip
        "openfile reads the permissions only when it creates a file, and the \
         flags hold no O_CREAT"])

  (* @satisfies changes#leave-repositories-unchanged=v1
     A folder opens for reading only, with no flag that creates a file, so the
     open creates and changes no file. *)
  let open_folder = open_folder

  let fstat descr =
    let status = Unix.fstat descr in
    {
      kind = kind_of status.st_kind;
      size = status.st_size;
      identity = { device = status.st_dev; inode = status.st_ino };
    }

  let read descr ~offset buffer start length =
    ignore (Unix.lseek descr offset Unix.SEEK_SET : int);
    Unix.read descr buffer start length

  let readlink = Unix.readlink
  let listing = listing
  let close = Unix.close
  let eilseq = eilseq ()
end

include Make (System)
