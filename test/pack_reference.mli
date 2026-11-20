(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of packs of the design [packs=v1], read directly, over the folder
    trees of {!Files_tree}: the files of a pack, its paths, whether it is well
    named, its pack listing, and its pack hash. A byte sequence and a text are
    OCaml strings; a text is its UTF-8 encoding. *)

val files : Files_tree.file -> (string * string) list
(** [files tree] is the files of the pack whose folder tree is [tree]: for each
    valid path whose last file name names a regular file, that valid path and
    the content of that regular file, in the code point order of the valid
    paths. *)

val paths : Files_tree.file -> string list
(** [paths tree] is the paths of the pack whose folder tree is [tree]: the valid
    paths of its files and the run of each of them before each [/], each once,
    in code point order. *)

val is_pack_path : string -> bool
(** [is_pack_path text] holds when [text] is a pack path. *)

val well_named : Files_tree.file -> bool
(** [well_named tree] holds when the pack whose folder tree is [tree] is well
    named. *)

val listing : Files_tree.file -> string option
(** [listing tree] is the pack listing of the pack whose folder tree is [tree],
    or [None] when the pack is not well named. *)

val hash : Files_tree.file -> string option
(** [hash tree] is the pack hash of the pack whose folder tree is [tree], or
    [None] when the pack is not well named. *)
