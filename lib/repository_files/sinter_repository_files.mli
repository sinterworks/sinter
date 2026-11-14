(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Reads of the repository files of a git repository, as the term
    [repository-file] of the design [changes=v1] defines them, by pathname.

    A pathname is a byte sequence, an OCaml [string], that the system resolves
    from the current folder of the process when it does not start with [/]. The
    system follows each symbolic link on a pathname, the last name included,
    except where {!READER.link_kind} and {!READER.link_text} say otherwise. *)

type kind =
  | Folder  (** a folder: a file of the type directory *)
  | Regular_file  (** a regular file *)
  | Symbolic_link  (** a symbolic link itself, not a file that it leads to *)
  | Other_kind
      (** a file of another kind, such as a pipe, a socket, or a device *)

type identity = { device : int; inode : int }
(** The identity of a file: the number of the device that holds it and its file
    serial number, as the system gives them. Two open files with the same
    identity are the same file. *)

type status = { kind : kind; size : int; identity : identity }
(** What the system gives for an open file: its kind, its size in bytes, and its
    identity. *)

type failure =
  | No_file
      (** no file is at the pathname: the system gives [ENOENT], [ENOTDIR],
          [ENAMETOOLONG], or the error that a file system gives for a name that
          it does not accept, or the pathname is empty or holds the byte 0x00 *)
  | Not_a_regular_file
      (** a read asked for a regular file, and the file is a folder or a file of
          another kind *)
  | Not_a_folder  (** a listing asked for a folder, and the file is not one *)
  | Not_a_symbolic_link
      (** {!READER.link_text} asked for a symbolic link, and the file is not one
      *)
  | Too_large
      (** a whole read found more bytes in the file than its maximum size; it
          gives no part of the content *)
  | Cannot_read
      (** the system gave another error, such as [EACCES] or [ELOOP] *)

(* @satisfies changes#{gain-no-repository-privileges=v1, run-no-configured-programs=v1}
   The reads reach the system only through these calls, and none of them
   changes a user ID, a group ID, or a privilege, starts a process, runs a
   shell, or loads code. *)

(** The calls of the system that the reads make. Each function, except [eilseq],
    raises [Unix.Unix_error] with the error that the system gives when the call
    fails. The pathname of each call holds no byte 0x00. *)
module type SYSTEM = sig
  type descr
  (** An open file or an open folder. *)

  val stat : string -> kind
  (** [stat pathname] is the kind of the file at [pathname], after each symbolic
      link on it, the last name included. *)

  val lstat : string -> kind
  (** [lstat pathname] is the kind of the file at [pathname], after each
      symbolic link on it before the last name; a last name that names a
      symbolic link gives [Symbolic_link]. *)

  val open_file : string -> descr
  (** [open_file pathname] opens the file at [pathname] for reading only, after
      each symbolic link on it, and waits for no other process and no device. *)

  val open_folder : string -> descr
  (** [open_folder pathname] opens the folder at [pathname] for reading only,
      after each symbolic link on it, waits for no other process and no device,
      and fails when the file is not a folder. *)

  val fstat : descr -> status
  (** [fstat descr] is the status of the open file [descr]. *)

  val read : descr -> offset:int -> bytes -> int -> int -> int
  (** [read descr ~offset buffer start length] reads up to [length] bytes of the
      open regular file [descr], from the byte at [offset] from its start, into
      [buffer] from the place [start], and gives the number of the bytes that it
      read. It gives [0] only at the end of the file and when [length] is [0].
  *)

  val readlink : string -> string
  (** [readlink pathname] is the reference of the symbolic link at [pathname],
      after each symbolic link on it before the last name. *)

  val listing : descr -> string list
  (** [listing folder] is the names of the listing of the open folder [folder],
      in any order, [.] and [..] maybe among them. *)

  val close : descr -> unit
  (** [close descr] closes [descr]. *)

  val eilseq : int
  (** The number of the error that the system gives, as [Unix.EUNKNOWNERR], when
      a file system does not accept a byte sequence as a name. *)
end

(** The reads. In each call: a read opens only a regular file, after it finds by
    [stat] that the file at the pathname is a regular file, and it reads no byte
    when the open file is not a regular file; a listing opens only a folder;
    nothing opens a file for writing, changes a file or an attribute of a file,
    or waits for another process or a device; and each descriptor that the
    system opens for the call is closed before the call returns, also when a
    call of the system raises. *)
module type READER = sig
  type handle
  (** An open regular file, valid only inside the function that {!with_file}
      gives it. *)

  val read : max_size:int -> string -> (string, failure) result
  (** [read ~max_size pathname] is the whole content of the regular file at
      [pathname]: every byte from its start to its end at the time of the read.
      It gives [Too_large], and no part of the content, when the file holds more
      than [max_size] bytes, and it then reads no more than [max_size] and one
      bytes of it. It raises [Invalid_argument] when [max_size] is negative. *)

  val with_file : string -> (handle -> 'a) -> ('a, failure) result
  (** [with_file pathname f] opens the regular file at [pathname], gives [f] the
      open file, and closes it when [f] returns or raises. An exception of [f]
      goes through, after the close. *)

  val size : handle -> int
  (** [size handle] is the size in bytes of the open file when it was opened. It
      raises [Invalid_argument] when [handle] is used after {!with_file}
      returns. *)

  val identity : handle -> identity
  (** [identity handle] is the identity of the open file when it was opened. It
      raises [Invalid_argument] when [handle] is used after {!with_file}
      returns. *)

  val read_range :
    handle -> offset:int -> length:int -> (string, failure) result
  (** [read_range handle ~offset ~length] is the bytes of the open file from the
      byte at [offset] from its start: [length] bytes, or fewer when the file
      ends before them. It raises [Invalid_argument] when [offset] or [length]
      is negative, or when [handle] is used after {!with_file} returns. *)

  val list : string -> (string list, failure) result
  (** [list pathname] is the names of the listing of the folder at [pathname],
      without [.] and [..], each once, in the order of {!String.compare}. *)

  val folder_identity : string -> (identity, failure) result
  (** [folder_identity pathname] is the identity of the folder at [pathname],
      after each symbolic link on it, the last name included. It gives
      [Not_a_folder] when the file is not a folder. It opens only a folder, as
      {!list} does, and it reads no name of the folder. *)

  val link_kind : string -> (kind, failure) result
  (** [link_kind pathname] is the kind of the file at [pathname], after each
      symbolic link on it before the last name: [Symbolic_link] when the last
      name names a symbolic link. It opens no file. *)

  val link_text : string -> (string, failure) result
  (** [link_text pathname] is the reference of the symbolic link at [pathname],
      the byte sequence that the link holds, after each symbolic link on it
      before the last name. It gives [Not_a_symbolic_link] when the file at
      [pathname] is not a symbolic link. It opens no file. It is the only
      function of this interface that takes the reference of a symbolic link as
      bytes. *)
end

(** The reads on the calls of a system. *)
module Make (_ : SYSTEM) : READER

include READER
(** The reads on the calls of the system of the process. *)
