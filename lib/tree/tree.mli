(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Trees, as the design [ontology=v1] defines them.

    A tree is a set of files. A file of a tree is a valid path with a content,
    which is a byte sequence. No two files of a tree have the same valid path.
    The text of a file is the text of its content, when its content is valid
    UTF-8. A byte sequence is an OCaml [string]. Two valid paths are the same
    valid path when their texts are the same text. *)

open Sinter_text
open Sinter_paths

type t
(** A tree. A value never changes, and two domains can use one value at the same
    time. *)

type error =
  | Repeated_path of Path.t  (** two files of the list have this valid path *)

val empty : t
(** [empty] is the tree of no files. *)

val of_files : (Path.t * string) list -> (t, error) result
(** [of_files files] is [Ok tree] when no two elements of [files] have the same
    valid path, and [tree] then has one file for each element: the valid path
    and the content of that element. It is [Error] otherwise, with the valid
    path of the first element of [files] whose valid path is the valid path of
    an element before it. The order of [files] does not change the tree. *)

val files : t -> (Path.t * string) list
(** [files tree] is the files of [tree], each once, as pairs of the valid path
    and the content, in the order of the texts of their valid paths: a text
    comes before another text when its UTF-8 encoding comes before the UTF-8
    encoding of the other in the byte order, which is the order of the code
    points. *)

val content : t -> Path.t -> string option
(** [content tree path] is the content of the file of [tree] at [path], or
    [None] when [tree] has no file at [path]. *)

type text_error =
  | No_file  (** the tree has no file at the valid path *)
  | Not_utf_8 of Text.decode_error
      (** the content of the file is not valid UTF-8, and {!Text.decode} gives
          this error for it *)

val text : t -> Path.t -> (Text.t, text_error) result
(** [text tree path] is the text of the file of [tree] at [path]: [Ok text] when
    the content of that file is valid UTF-8, and [Error] when [tree] has no file
    at [path] or its content is not valid UTF-8. *)

val lines : t -> Path.t -> (Lines.t, text_error) result
(** [lines tree path] is the lines of the text of the file of [tree] at [path],
    as {!Lines.of_text} gives them, and [Lines.text] of the result is
    [text tree path]. It is [Error] in the same cases as {!text}, with the same
    error. The first call for a file of a value takes time linear in the length
    of its content; each later call for that file of that value takes time
    logarithmic in the number of files. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, [a] and [b] have the same valid
    paths, and the file at each valid path has the same content in both. *)
