(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Read files, as the terms [read-file] and [unreadable-file] of the design
    [documents=v1] define them.

    Under a valid binding of [file-readers], a read file of a tree is a file of
    the tree whose valid path has a reader, has no line feed, and has no space
    and no tab as its first character or as its last character. The reader of a
    read file is the reader of its valid path. A read file is a markdown file
    when its reader is the text [markdown], and a code file when its reader is a
    pack.

    A read file cannot be read when its content is not valid UTF-8, or when it
    is a code file and the reading of its text with its pack has the result "no
    grammar" or the result "parse failure". This module decides the first of
    these two conditions; the reading of a text with a pack is not in this
    module. *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_identifiers

type 'pack t
(** A read file of a tree, with its reader. *)

(* @satisfies documents#give-nothing-under-invalid-bindings=v1
   The read files come only from a valid binding of file-readers and a binding
   of external-namespaces that the program accepts, so under any other binding
   a program that uses this interface gives no read file. *)
val read_files : 'pack File_readers.t -> Binding.t -> Tree.t -> 'pack t list
(** [read_files readers namespaces tree] is the read files of [tree] under the
    binding [readers] of [file-readers] and the binding [namespaces] of
    [external-namespaces]: each read file once, and no other file. They are in
    the order of {!Tree.files}. The binding [namespaces] does not change the
    result. *)

val path : 'pack t -> Path.t
(** [path file] is the valid path of [file]. *)

val pair : 'pack t -> int
(** [pair file] is the number of the first pair of the binding of [file-readers]
    whose path set has the valid path of [file] in its set: the pair whose
    reader is the reader of [file]. *)

val reader : 'pack t -> 'pack File_readers.reader
(** [reader file] is the reader of [file]. *)

val lines : 'pack t -> (Lines.t, Text.decode_error) result
(** [lines file] is [Ok lines] when the content of [file] is valid UTF-8, and
    [lines] is then the lines of the text of [file], as {!Lines.of_text} gives
    them. It is [Error] when the content is not valid UTF-8, with the error that
    {!Text.decode} gives for it. So a markdown file can be read when, and only
    when, the result is [Ok]. *)
