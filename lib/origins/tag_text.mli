(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Tag texts, as the term [tag-text] of the design [documents=v1] defines them:
    texts that join runs of the text of a read file.

    A tag text that joins runs is the text of these runs, in their order, with a
    line feed between each two of them. The lines that it joins are these runs.
    The [k]-th line of the tag text comes from the [k]-th line that it joins.
    Which runs a tag text joins is decided elsewhere: the lines of a first
    paragraph for a markdown file, and the comment lines of a run of comments
    for a code file. *)

open Sinter_text

type t
(** A tag text of one read file, with the runs of the text of the file that it
    joins. *)

val make : Lines.t -> Text.run list -> t option
(** [make lines runs] is the tag text that joins [runs], runs of the text of the
    read file [Lines.text lines]. It is [None] when an element of [runs] is not
    a run of that text, holds a line feed, or starts before the boundary where
    the element before it ends. *)

val text : t -> Text.t
(** [text tag_text] is the text of [tag_text]. *)

val source : t -> Source.t
(** [source tag_text] is the text of [tag_text] as a source, as {!Source.join}
    gives it for the joined runs: each line feed between two joined runs comes
    from no place, and each other character comes from its place in the text of
    the file. *)

val joined : t -> Text.run list
(** [joined tag_text] is the runs that [tag_text] joins, in their order, as runs
    of the text of the file. *)

val line_count : t -> int
(** [line_count tag_text] is the number of the lines of the text of [tag_text],
    as {!Lines.count} gives it. When the text of [tag_text] does not start with
    U+FEFF, it is the number of the runs that [tag_text] joins, or one less when
    the last of these runs is empty. *)

val line : t -> int -> Text.run option
(** [line tag_text k] is the line with the line number [k] of the text of
    [tag_text], as a run of that text, or [None] when [k] is not from 1 to
    [line_count tag_text]. Its characters come from the characters of the [k]-th
    run that [tag_text] joins, in order: all of them, except a carriage return
    at the end of that run when a run comes after it, and a U+FEFF at the start
    of that run when [k] is 1. *)

val joined_line : t -> int -> Text.run option
(** [joined_line tag_text k] is the [k]-th run that [tag_text] joins: the line
    of the text of the file that the line with the line number [k] of the text
    of [tag_text] comes from. It is [None] when [k] is not from 1 to
    [line_count tag_text]. *)
