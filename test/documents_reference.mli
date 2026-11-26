(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of the design [documents=v1] that need no reading of CommonMark
    blocks, read directly: markdown lines, front matter, markdown runs, blank
    lines, and read files. *)

open Sinter_text

val markdown_lines : Text.t -> Text.run list
(** [markdown_lines text] is the markdown lines of [text], in their order, as
    the term [markdown-line] gives them. *)

val front_matter : Text.t -> Text.run list option
(** [front_matter text] is the markdown lines of the front matter of the text of
    a markdown file, or [None] when the file has no front matter. *)

val markdown_run : Text.t -> Text.run
(** [markdown_run text] is the markdown run of the markdown file whose text is
    [text]. *)

val markdown_text_lines : Text.t -> Text.run list
(** [markdown_text_lines text] is the markdown lines of the markdown text of the
    markdown file whose text is [text], as runs of [text]. *)

val is_blank : Text.t -> Text.run -> bool
(** [is_blank text run] holds when the text of [run] has no character other than
    spaces and tabs. *)

val read_files :
  ('reader * string list) list ->
  (string * string) list ->
  (string * int) list option
(** [read_files binding files] is [None] when a path set of [binding] is not a
    valid path set. Otherwise it is the read files of the tree [files], each a
    valid path and its content, as the valid path of each read file and the
    number, from 1, of the first pair of [binding] whose path set has that valid
    path in its set, in the order of [files]. Every pack of [binding] counts as
    a valid pack. *)
