(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The lines of a text, their line numbers, and the positions of its characters
    and spans, as the design [text=v1] defines them.

    A line ending is a line feed of the body, with the carriage return right
    before it when the body holds one there. The line endings divide the body
    into runs, and the lines are these runs, except a last run that is empty. No
    other character ends a line. *)

type t
(** The lines of one text. The value holds the text. *)

type position = { line : int; column : int }
(** A position: a line number and a column, both from 1. *)

type place_error =
  | Not_a_place  (** the place is not from 1 to the length of the text *)
  | Byte_order_mark
      (** the place is place 1 of a text that has a byte order mark: the
          character there has no position *)

type span_error =
  | Not_a_run  (** the pair of boundaries is not a run of the text *)
  | Not_a_span
      (** the run is a run of the text and not a span: it starts at boundary 0
          of a text that has a byte order mark *)

val of_text : Text.t -> t
(** [of_text text] finds the lines of [text]. The time is linear in the length
    of [text]. *)

val text : t -> Text.t
(** [text lines] is the text that {!of_text} took. *)

val count : t -> int
(** [count lines] is the number of lines of the text. *)

val all : t -> Text.run list
(** [all lines] is the lines of the text, as runs, in the order of their line
    numbers: the [k]-th element is the line with the line number [k]. It is [[]]
    when the text has no line. *)

val line : t -> int -> Text.run option
(** [line lines k] is the line with the line number [k], or [None] when [k] is
    not from 1 to [count lines]. *)

val character_position : t -> int -> (position, place_error) result
(** [character_position lines place] is the position of the character at
    [place]. The time is logarithmic in the number of lines. *)

val span : t -> Text.run -> (position * position, span_error) result
(** [span lines run] is the start and the end of [run] when [run] is a span of
    the text. The start is the position of the boundary where the span starts.
    The end is the position of boundary [k], where [k] is the last place of the
    span that is a place of a line; when no place of the span is a place of a
    line, the end is the start. The time is logarithmic in the number of lines.
*)
