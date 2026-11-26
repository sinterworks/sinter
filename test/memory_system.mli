(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** A system in memory for the reads of {!Sinter_repository_files}, which
    records every call.

    A pathname is resolved name by name from the root [/]: a pathname that does
    not start with [/] starts at the root too. Each symbolic link on the way is
    followed, from the folder that holds it, and [..] goes to the folder above
    the folder reached so far. *)

type node =
  | File of string  (** a regular file with its content *)
  | Sparse of int * (int * string) list
      (** [Sparse (size, pieces)] is a regular file of [size] bytes: each
          [(offset, bytes)] of [pieces] puts [bytes] at [offset], and every
          other byte is 0x00 *)
  | Failing of string * int * int
      (** [Failing (content, low, high)] is a regular file with [content], where
          a read of any byte from [low] to [high - 1] fails with [EIO] *)
  | Shrunk of string * int
      (** [Shrunk (content, size)] is a regular file whose status gives [size]
          bytes, and whose reads give [content], as a file that another process
          has shortened *)
  | Folder  (** a folder; its entries are the nodes under its pathname *)
  | Link of string  (** a symbolic link with its reference *)
  | Fifo  (** a file of another kind *)

type t
(** A system and its record of calls. *)

val create : (string * node) list -> t
(** [create nodes] is a system that holds [nodes], each at its absolute
    pathname, and each folder in front of a pathname. *)

val add : t -> string -> node -> unit
(** [add system pathname node] puts [node] at [pathname], with the folders in
    front of it. *)

val remove : t -> string -> unit
(** [remove system pathname] takes the node at [pathname] away, with every node
    under it. *)

val system : t -> (module Sinter_repository_files.SYSTEM)
(** [system t] is the calls of [t]. *)

type call =
  | Stat of string
  | Lstat of string
  | Open_file of string
  | Open_folder of string
  | Read of string * int * int
      (** the pathname that opened the file, the offset, and the bytes given *)
  | Readlink of string
  | Listing of string

val calls : t -> call list
(** [calls t] is each call that [t] answered, in order. *)

val clear : t -> unit
(** [clear t] forgets the calls. *)

val open_descriptors : t -> int
(** [open_descriptors t] is the number of descriptors that are open now. *)

val pathname_of_call : call -> string
(** [pathname_of_call call] is the pathname of [call]. *)

val bytes_given : t -> int
(** [bytes_given t] is the sum of the bytes that the reads of the calls gave. *)

val largest_read : t -> int
(** [largest_read t] is the most bytes that one read call gave. *)
