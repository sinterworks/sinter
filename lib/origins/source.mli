(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Sources: texts each of whose characters comes from one place of the text of
    a read file, or from no place, with the origins and the origin positions of
    their runs, as the terms [origin] and [origin-position] of the design
    [documents=v1] define them.

    The text of a read file, a tag text, the markdown text of a markdown file,
    and the text of a tag line are each a source. The origin of a run of a
    source is the set of the places of the text of the file that the characters
    of the run come from. *)

open Sinter_text

type t
(** A text, the text of one read file, and for each character of the text the
    place of the text of the file that it comes from, or no place. *)

val of_file : Lines.t -> t
(** [of_file lines] is the text of a read file, [Lines.text lines], as a source:
    each of its characters comes from its own place. *)

val sub : t -> Text.run -> t option
(** [sub source run] is the text of [run] of the text of [source], as a source:
    its [k]-th character comes from the place that the character at place
    [run.from + k] of [source] comes from, or from no place when that character
    comes from no place. It is [None] when [run] is not a run of the text of
    [source]. *)

val join : t -> Text.run list -> t option
(** [join source runs] is the text of the elements of [runs], in order, with a
    line feed between each two of them, as a source. Each such line feed comes
    from no place. Each other character is a character of a run of [runs], and
    it comes from the place that this character of [source] comes from, or from
    no place when that character comes from no place. When [runs] is [[]], the
    text of the result is the empty text. The result is [None] when an element
    of [runs] is not a run of the text of [source]. *)

val text : t -> Text.t
(** [text source] is the text of [source]. *)

val file : t -> Lines.t
(** [file source] is the lines of the text of the read file of [source]. *)

val place : t -> int -> int option
(** [place source k] is [Some p] when the character at place [k] of the text of
    [source] comes from place [p] of the text of the file. It is [None] when
    that character comes from no place, or when [k] is not a place of the text
    of [source]. *)

val origin : t -> Text.run -> Text.run list option
(** [origin source run] is the origin of [run], as runs of the text of the file:
    the runs that are not empty, in increasing order of their boundaries, such
    that a place is in one of them when, and only when, it is in the origin, and
    no two of them touch or overlap. It is [Some []] when no character of [run]
    comes from a place, and [None] when [run] is not a run of the text of
    [source]. *)

val origin_run : t -> Text.run -> Text.run option
(** [origin_run source run] is the run of the text of the file from the boundary
    right before the least place of the origin of [run] to the boundary right
    after the greatest place of that origin. It is [None] when the origin is
    empty, or when [run] is not a run of the text of [source]. *)

val origin_position : t -> Text.run -> Lines.position option
(** [origin_position source run] is the origin position of [run]: the position,
    in the text of the file, of the least place of the origin of [run]. It is
    [None] when the origin is empty, when [run] is not a run of the text of
    [source], or when that place has no position. *)
