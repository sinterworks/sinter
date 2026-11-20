(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** File lines and blank lines, as the terms [file-line] and [blank-line] of the
    design [documents=v1] define them.

    The file lines of a read file that can be read are runs of its text: for a
    markdown file, its markdown lines; for a code file, the lines that its tag
    texts join. *)

open Sinter_text

type t
(** The file lines of one read file, in the order of the boundaries where they
    start. *)

val of_markdown_lines : Text.run list -> t
(** [of_markdown_lines lines] is the file lines of a markdown file whose
    markdown lines are [lines]. *)

val of_tag_texts : Tag_text.t list -> t
(** [of_tag_texts tag_texts] is the file lines of a code file whose tag texts
    are [tag_texts]: each run that one of them joins. *)

val all : t -> Text.run list
(** [all lines] is the file lines, in the order of the boundaries where they
    start; of two that start at one boundary, the empty one comes first. *)

val of_tag_text_line : t -> Tag_text.t -> int -> Text.run option
(** [of_tag_text_line lines tag_text k] is the file line of the line with the
    line number [k] of [tag_text], a tag text of the file:
    - for a code file, the run that this line comes from, as
      {!Tag_text.joined_line} gives it;
    - for a markdown file, the markdown line that starts at or before the
      boundary where that run starts, and that ends at or after the boundary
      where that run ends.

    It is [None] when [k] is not from 1 to [Tag_text.line_count tag_text], or
    when no file line is such a line. *)

val of_origin : t -> Text.run list -> Text.run list
(** [of_origin lines origin] is the file lines that have a place of [origin], a
    set of places of the text of the file given as runs of that text, as
    {!Source.origin} gives it. They are in the order of {!all}. *)

val is_blank : Text.t -> bool
(** [is_blank text] is [true] when, and only when, [text] has no character other
    than spaces and tabs: a line of any kind whose text is [text] is then a
    blank line. *)
