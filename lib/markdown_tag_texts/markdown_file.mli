(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The front matter, markdown text, sections, list items, first paragraphs,
    paragraph lines, tag texts, and file lines of a markdown file that can be
    read, as the terms [front-matter], [markdown-section], [markdown-list-item],
    [paragraph-line], [tag-text], and [file-line] of the design [documents=v1]
    define them.

    The markdown document of the file is the markdown document of its markdown
    text, and its blocks are those that CommonMark 0.31.2 parses. A blank line
    is no block, and a link reference definition is a block. A block of the
    document itself is a block that no block quote, no list, and no list item
    contains.

    The markdown lines of the text of the file have numbers from 1, in their
    order. A line range names the markdown lines from the number [first] to the
    number [last], with [first <= last]. *)

open Sinter_text
open Sinter_origins
open Sinter_markdown_limits

type t
(** A markdown file that can be read. *)

type range = { first : int; last : int }
(** The markdown lines from the number [first] to the number [last]. *)

type paragraph = {
  lines : range;  (** the markdown lines that the paragraph takes *)
  tag_text : Tag_text.t;
      (** the tag text that joins the lines of the paragraph: the [k]-th run
          that it joins is the [k]-th line of the paragraph, which comes from
          the markdown line with the number [lines.first + k - 1] *)
}
(** A first paragraph of a section or of a list item. The first line of the
    paragraph is the run of its first markdown line that starts at the place of
    the first character, among the characters of that markdown line that
    CommonMark 0.31.2 gives to the content of the paragraph, that is not a space
    or a tab, and that ends where that markdown line ends. For the first
    paragraph of a list item, when this run starts with a run whose text matches
    the production [task-marker], the first line is the part of this run after
    the longest such run. Each other line is the whole markdown line. *)

type heading = {
  line : int;
      (** the number of the first markdown line that the heading takes *)
  level : int;
      (** for an ATX heading, the number of [#] of its opening sequence, from 1
          to 6; for a setext heading, 1 when its underline is of [=] and 2 when
          it is of [-] *)
}
(** An ATX heading or a setext heading of CommonMark 0.31.2 that is a block of
    the document itself: a heading that opens a section. *)

type section = {
  heading : heading option;
      (** the heading that opens the section, or [None] for the section of level
          0 *)
  lines : range option;
      (** the markdown lines of the section, or [None] when the section is
          empty, which only the section of level 0 can be *)
  first_paragraph : paragraph option;
      (** the first block of the document itself after the heading, or the first
          block of the document itself for the section of level 0, when that
          block is a paragraph *)
}
(** A section. The section of a heading is the markdown lines from its line to
    the markdown line right before the line of the next heading that opens a
    section and whose level is the same as its level or less, or to the last
    markdown line of the markdown text when no such heading comes after it. The
    section of level 0 is the markdown lines of the markdown text before the
    line of the first heading that opens a section, or all of these markdown
    lines when no heading opens a section. *)

type list_item = {
  lines : range;
      (** the markdown lines of the list item: from the first markdown line that
          it takes to the last markdown line of the last block that it contains,
          or to its first markdown line when it contains no block *)
  first_paragraph : paragraph option;
      (** the first block that the list item contains and that no block quote,
          no list, and no list item inside the list item contains, when that
          block is a paragraph *)
}
(** A list item of CommonMark 0.31.2 of the markdown document, at any depth of
    lists, that no block quote contains. The markdown lines of a list item end
    at the last markdown line of the last block that it contains: a blank line
    after that block is not one of its markdown lines. *)

val read : Markdown_limits.text -> t
(** [read text] reads the markdown file whose text is
    [Lines.text (Markdown_limits.lines text)]. No limit stopped that text, so
    its size, its bracket depth, and its container depth are at most the limits
    that {!Markdown_limits.check} got. The parse of CommonMark 0.31.2 by
    [cmarkit] 0.4.0 then takes the time and the memory that the decision record
    [commonmark-reader] states for these limits. Apart from that parse, the time
    is linear in the length of the text. *)

val lines : t -> Text.run list
(** [lines file] is the markdown lines of the text of [file], in the order of
    their numbers, as {!Markdown_lines.of_text} gives them. *)

val front_matter : t -> range option
(** [front_matter file] is the front matter of [file], or [None] when [file] has
    none. A front-matter line is a markdown line whose text matches the
    production [front-matter-line]. The file has front matter when its first
    markdown line is a front-matter line and a later markdown line is a
    front-matter line whose first three characters are those of the first
    markdown line. The front matter is then the markdown lines from the first
    one to the first such later one. *)

val markdown_run : t -> Text.run
(** [markdown_run file] is the markdown run of [file]. It starts at boundary 0
    when [file] has no front matter. Otherwise, it starts at the boundary where
    the markdown line ending right after the last line of the front matter ends,
    or at the last boundary of the text when no markdown line ending comes after
    that line. It ends at the last boundary of the text. *)

val markdown_text : t -> Source.t
(** [markdown_text file] is the markdown text of [file], the text of its
    markdown run, as a source: its [k]-th character comes from the [k]-th place
    of the markdown run. *)

val first_markdown_text_line : t -> int
(** [first_markdown_text_line file] is the number of the first markdown line of
    the markdown text: the first markdown line of the text of [file] that starts
    at or after the boundary where the markdown run starts. It is 1 more than
    the number of the last markdown line when no markdown line starts there. *)

val sections : t -> section list
(** [sections file] is the sections of [file]: first the section of level 0, and
    then the section of each heading that opens a section, in the order of the
    lines of these headings. *)

val list_items : t -> list_item list
(** [list_items file] is the list items of [file], in the order of their first
    markdown lines; of two that start on one markdown line, the outer one comes
    first. *)

val tag_texts : t -> Tag_text.t list
(** [tag_texts file] is the tag texts of [file], one for each first paragraph of
    a section and each first paragraph of a list item, in the order of the first
    markdown lines of these paragraphs. The file has no other tag text. *)

val file_lines : t -> File_lines.t
(** [file_lines file] is the file lines of [file]: its markdown lines, as
    {!File_lines.of_markdown_lines} gives them. *)
