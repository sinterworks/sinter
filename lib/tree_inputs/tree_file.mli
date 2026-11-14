(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** A read file of a tree that can be read, with its file lines, its tag texts,
    and its inputs, as the terms [file-line], [tag-text], and [accepted-input]
    of the design [documents=v1] define them.

    The file lines have numbers from 1, in the order of {!File_lines.all}. A set
    of file lines is a {!Line_set.t} of these numbers. *)

open Sinter_text
open Sinter_paths
open Sinter_origins
open Sinter_identifiers
open Sinter_tag_inputs
open Sinter_markdown_tag_texts
open Sinter_code_tag_texts

type t
(** A read file that can be read, read under a binding of [external-namespaces].
*)

(** What the file is. *)
type content =
  | Markdown of Markdown_file.t  (** a markdown file *)
  | Code of Code_file.t  (** a code file, with the reading of its text *)

(** The part of the file whose first paragraph, or whose comment lines, a tag
    text joins. *)
type holder =
  | Section of Markdown_file.section
      (** a section, whose first paragraph the tag text joins *)
  | List_item of Markdown_file.list_item
      (** a list item, whose first paragraph the tag text joins *)
  | Comment_run of Code_file.comment_run
      (** a run of comments that has a tagged comment node, whose comment lines
          the tag text joins *)

type tag_text = {
  tag_text : Tag_text.t;  (** the tag text *)
  holder : holder;  (** what gives it *)
  inputs : Input.t list;
      (** the inputs that its lines make, as {!Input.of_tag_text} gives them, in
          the order of their line numbers *)
}
(** A tag text of the file. *)

val make : Binding.t -> Path.t -> Readable_file.t -> t
(** [make binding path file] is the read file [file] at the valid path [path],
    read under the binding [binding] of [external-namespaces]. For a markdown
    file, the time is that of {!Markdown_file.read}. For each file, the time is
    then linear in the length of the text and in the number of its file lines,
    and grows as n log n in the number n of its file lines. *)

val binding : t -> Binding.t
(** [binding file] is the binding of [external-namespaces] under which [file]
    was read. *)

val path : t -> Path.t
(** [path file] is the valid path of [file]. *)

val content : t -> content
(** [content file] is what [file] is. *)

val text : t -> Lines.t
(** [text file] is the lines of the text of [file]. *)

val file_lines : t -> File_lines.t
(** [file_lines file] is the file lines of [file], as
    {!Markdown_file.file_lines} or {!Code_file.file_lines} gives them. *)

val line_count : t -> int
(** [line_count file] is the number of the file lines of [file]. The time is
    constant. *)

val line : t -> int -> Text.run option
(** [line file k] is the file line with the number [k] of [file], or [None] when
    [k] is not from 1 to [line_count file]. For a markdown file, the file line
    with the number [k] is the markdown line with the number [k]. The time is
    constant. *)

val number : t -> Text.run -> int option
(** [number file run] is the number of the file line [run] of [file], or [None]
    when [run] is no file line of [file]. The time is logarithmic in the number
    of the file lines. *)

val numbers : t -> Text.run list -> Line_set.t
(** [numbers file runs] is the set of the numbers of the elements of [runs] that
    are file lines of [file]. *)

val all_lines : t -> Line_set.t
(** [all_lines file] is the set of the numbers of all the file lines of [file],
    from 1 to [line_count file]. *)

val within : t -> Text.run -> Line_set.t
(** [within file r] is the set of the numbers of the file lines of [file] whose
    runs start at or after the boundary where [r] starts and end at or before
    the boundary where [r] ends. Let n be the number of the file lines. The time
    grows as log n times the number of the runs of the result, and as log n
    times the number of the runs of the numbers of the file lines that start in
    [r] and end after it. *)

val last_not_blank : t -> int -> int
(** [last_not_blank file k] is the greatest number, from 1 to [k], of a file
    line of [file] that is not blank: whose text has a character other than
    spaces and tabs. It is 0 when there is no such number. The time is constant.
*)

val tag_texts : t -> tag_text list
(** [tag_texts file] is the tag texts of [file], each once. For a markdown file,
    they are in the order of the first markdown lines of their first paragraphs;
    for a code file, in the order of {!Code_file.comment_runs}. *)

val links : t -> Input.t list
(** [links file] is the inputs that the links and the images of [file] make, as
    {!Input.of_links} gives them: for a markdown file, those of its markdown
    text; for a code file, those of each of its tag texts, in the order of
    {!tag_texts}. *)

val code_character_before : t -> int -> bool
(** [code_character_before file b] is [true] when, and only when, [file] is a
    code file and a code character of [file] is at a place before the boundary
    [b]: a place from 1 to [b]. The time is constant. *)
