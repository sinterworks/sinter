(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The folder trees of the group [file-reads] of the design [files=v1]: their
    JSON form, and a runner that makes a folder tree on the file system, checks
    that the file system stores it, makes a file read in it, checks that the
    file read changed no file, and removes it. *)

type permissions = { read : bool; search : bool; write : bool }
(** The permissions of the program for a file, as the members [read], [search],
    and [write] of a file object give them. [search] is [true] for a file other
    than a folder. *)

type kind =
  | Folder of (string * file) list
      (** The folder entries, as pairs of an entry name, a byte sequence, and
          the file of the folder entry. *)
  | Regular of (string * int) list
      (** The content, as pieces: each a byte sequence and the number of times
          it stands in a row. *)
  | Link of string  (** The reference, a byte sequence. *)
  | Pipe  (** A FIFO special file. *)

and file = { kind : kind; permissions : permissions; owned_by_other : bool }
(** A file object. *)

val of_json : Yojson.Basic.t -> file
(** [of_json json] is the file object [json]. It raises [Failure] when [json] is
    not a file object of the form of section 5.2 of the design. *)

val regular : string -> file
(** [regular content] is a regular file with [content] and every permission. *)

val folder : (string * file) list -> file
(** [folder entries] is a folder with [entries] and every permission. *)

val bytes_of_pieces : (string * int) list -> string
(** [bytes_of_pieces pieces] is the byte sequence of [pieces]. *)

val text_of_pieces : Yojson.Basic.t -> string
(** [text_of_pieces json] is the UTF-8 encoding of the text of the pieces of a
    text [json]. It raises [Failure] when [json] is not pieces of a text. *)

val of_hex : string -> string
(** [of_hex digits] is the byte sequence of the hex digits [digits]. It raises
    [Failure] when [digits] is not a byte sequence in the form of the design. *)

type change = string
(** A change to a file of the folder tree, in words, with the entry names of the
    file. *)

type 'a outcome =
  | Not_stored of string
      (** No file system stores the folder tree as its file object gives it; the
          text says why. *)
  | Read of { value : 'a; changes : change list }
      (** The file system stored the folder tree; [value] is what the file read
          gave, and [changes] is each change to a file of the folder tree from
          before the file read to after it, other than of the time of last
          access. *)

val run : ?limit:int -> file -> (string -> 'a) -> 'a outcome
(** [run tree read] makes the folder tree [tree] under a new temporary folder,
    checks that the file system stores it, and then gives [read root], where
    [root] is the absolute pathname of its root. It then removes the folder
    tree, also when [read] raises, and raises the same exception.

    When the process has the effective user ID 0, [run] gives each file of
    [tree] to the user [nobody], except each file with [owned_by_other], and
    [read] runs in a child process that has the user ID and the group ID of
    [nobody], and no other group ID. [read] must then give a value that
    [Marshal] can write, and an exception in it comes back as [Failure] with its
    text.

    [read] that has given no value after [limit] seconds, 10 by default, raises
    [Failure]. *)

val effective_root : unit -> bool
(** [effective_root ()] is [true] when the process has the effective user ID 0.
*)

val system : unit -> string
(** [system ()] is ["macos"] when [uname -s] gives [Darwin], and ["linux"]
    otherwise. *)
