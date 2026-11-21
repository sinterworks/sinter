(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Inputs and accepted inputs, as the term [accepted-input] of the design
    [documents=v1] defines them, with their origins, origin positions, and file
    lines.

    A conforming program of the design Identifiers reads each tag text of a read
    file that can be read, and the markdown text of each markdown file that can
    be read, under a binding of [external-namespaces]. The inputs of the tree
    are each line of each tag text, other than a continuation line, with its
    continuation lines when it is a citation; each link of the markdown document
    of the markdown text of each markdown file; and each link of the markdown
    document of each tag text of each code file. An accepted input is an input
    with the result "valid". *)

open Sinter_text
open Sinter_origins
open Sinter_identifiers
open Sinter_inline_citations

type t
(** An input of a tree, with the tag text or the source that has it. *)

(** What an input is. *)
type kind =
  | Tag_line of {
      tag_text : Tag_text.t;  (** the tag text that has the line *)
      first_line : int;
          (** the line number, in the text of [tag_text], of the line *)
      last_line : int;
          (** the line number, in the text of [tag_text], of its last
              continuation line, or [first_line] when it has none *)
      result : Tag_line.line_result;
          (** the result and the values that {!Tag_line.read} gives for it *)
    }  (** a line of a tag text, with its continuation lines *)
  | Link of {
      source : Source.t;  (** the source whose markdown document has it *)
      link : Inline_citation.link;
          (** the run, in the text of [source], and the result that
              {!Inline_citation.read} gives for it *)
    }
      (** a link, or an image, of the markdown document of the text of [source]
      *)

val of_tag_text : Binding.t -> Tag_text.t -> t list
(** [of_tag_text binding tag_text] is the inputs that the lines of [tag_text]
    make under [binding]: one for each line of its text that is not a
    continuation line, in the order of their line numbers. *)

val of_links : Binding.t -> Source.t -> t list
(** [of_links binding source] is the inputs that the links of the markdown
    document of the text of [source] make under [binding], in the order of
    {!Inline_citation.read}: for a markdown file, [source] is its markdown text;
    for a code file, it is the source of one of its tag texts. The list also has
    one element for each image of that markdown document, whose result is
    [Inline_citation.Not_an_inline_citation]; an image is not an input of the
    tree. *)

val kind : t -> kind
(** [kind input] is what [input] is. *)

val accepted : t -> bool
(** [accepted input] is [true] when, and only when, the result of [input] is
    "valid": [Tag_line.Valid] or [Inline_citation.Valid]. *)

val text : t -> Source.t
(** [text input] is, for a line of a tag text, the text of the tag line as the
    term [tag-line-text] of the design [identifiers=v1] gives it: the text of
    its line and, for each of its continuation lines, a line feed and the text
    of that line without the spaces and tabs at its start. For a link, it is the
    run of the link in the text of its source. Each character of the result
    comes from the place that this character of the tag text or of the source
    comes from, and each line feed before a continuation line comes from no
    place. *)

val origin_run : t -> Text.run option
(** [origin_run input] is the run, in the text of the file, of the text of
    [input], as the term [origin] gives it. For a tag line, it starts at the
    boundary right before the place that the first [@] of its line comes from.
    For each other input, it is {!Source.origin_run} of the whole text of
    [input]. It is [None] when no character of the text of [input] comes from a
    place. *)

val origin_position : t -> Lines.position option
(** [origin_position input] is the origin position of the text of [input]: for a
    tag line, the position of the place that the first [@] of its line comes
    from; for each other input, the position of the least place of the origin of
    its text, which for a link is the place of its first character, [\[] or [<].
    It is [None] when {!origin_run} is [None]. *)

val file_lines : File_lines.t -> t -> Text.run list
(** [file_lines lines input] is the file lines of the text of [input], where
    [lines] is the file lines of the file of [input]. For a line of a tag text,
    they are the file lines of the lines of the tag text from [first_line] to
    [last_line], as {!File_lines.of_tag_text_line} gives them. For a link, they
    are the file lines that have a place of its origin. They are in the order of
    {!File_lines.all}. *)
