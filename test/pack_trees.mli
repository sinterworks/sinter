(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The needs of the vectors of [packs.test-vectors.jsonl], found by probing the
    file system of the temporary folder, and generated folder trees of packs. *)

val needs : (string * bool) list Lazy.t
(** [needs] is each need name of section 8 of the design [packs=v1], with [true]
    when {!Files_tree.run} stores a probe tree that has that need, and [false]
    when it cannot. *)

val tree_gen : Files_tree.file QCheck2.Gen.t
(** Folder trees of packs, of a depth of at most 4, whose entry names come only
    from the classes of names whose needs hold: names that differ only in case,
    names with spaces, tabs, line feeds, backslashes, and U+007F, names of 255
    bytes, names that are not valid UTF-8, names of dots, and names that are
    pack paths. The trees hold regular files, which are sometimes empty and
    sometimes not valid UTF-8, folders, empty folders, symbolic links, and FIFO
    special files. No two entry names of one folder are the same text after
    ASCII case folding when the need [case-distinct-names] does not hold. *)

val unstored_tree_gen : Files_tree.file QCheck2.Gen.t
(** Folder trees as {!tree_gen} gives them, but with the names of every class,
    whatever the needs, and also with names of 254, 256, and 300 bytes, for a
    use that stores no folder tree. *)

val deep_tree : int -> Files_tree.file
(** [deep_tree depth] is a folder tree of [depth] nested folders [a], with a
    regular file [f] in the deepest one. *)

val print : Files_tree.file -> string
(** [print tree] is [tree] written for a message. *)
