(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The files of the tree of a commit, as the term [commit-file] of the design
    [changes=v1] defines them, from the entries of its git tree object.

    An entry of a git tree object has a name, a byte sequence; a mode, a byte
    sequence; and a git object. A byte sequence is an OCaml [string]. The caller
    names blobs by a type of its own, ['blob]. *)

(** The four types of an entry. *)
type kind =
  | Tree_entry  (** it names a git tree object, which lists more entries *)
  | Regular_file_entry  (** it names the blob of a regular file *)
  | Symbolic_link_entry  (** it names the blob of a symbolic link *)
  | Submodule_entry  (** it names a commit of another git repository *)

val kind : string -> kind
(** [kind mode] is the type of an entry whose mode is the byte sequence [mode].
    When [mode] is one or more of the bytes 0x30 to 0x37, the digits [0] to [7],
    it writes a whole number in base 8; with t the whole-number quotient of that
    number divided by 4096, the entry is a tree entry when t is 4, a
    regular-file entry when t is 8, a symbolic-link entry when t is 10, and a
    submodule entry for each other t. Leading zeros and any number of digits are
    allowed. When [mode] is empty or holds any other byte, the entry is a
    submodule entry. *)

(** An entry of a git tree object, of the type that {!kind} gives for its mode.
*)
type 'blob entry =
  | Tree of { name : string; entries : 'blob entry list }
      (** a tree entry, with the entries of the git tree object that it names *)
  | Regular_file of { name : string; blob : 'blob }
      (** a regular-file entry, with the blob that it names *)
  | Other of { name : string }
      (** a symbolic-link entry or a submodule entry *)

val files : 'blob entry list -> (Sinter_paths.Path.t * 'blob) list
(** [files entries] is the files of the tree of a commit whose git tree object
    lists [entries], each as its valid path and the blob of its content, each
    once, in an order that this interface does not fix. The byte path of an
    entry is its name, after the byte path of the tree entry that lists it and
    the byte [/] when a tree entry lists it. A regular-file entry gives a file
    when its byte path is the UTF-8 encoding of a valid path p, and no other
    entry has the same byte path; the file has the valid path p. No other entry
    gives a file. The time is linear in the total length of the names of the
    entries and of the valid paths of the files that it gives, and the stack
    space does not grow with the depth of the entries. *)

val file : 'blob entry list -> Sinter_paths.Path.t -> 'blob option
(** [file entries path] is the file with the valid path [path] of the tree of a
    commit whose git tree object lists [entries]: [Some blob], the blob of its
    content, when {!files} of [entries] holds a file with the valid path [path],
    and [None] when that tree has no file with the valid path [path]. The stack
    space does not grow with the depth of the entries. *)
