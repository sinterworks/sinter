(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Spots, their start positions, and the positions after them, as the design
    [findings=v1] defines them.

    A boundary of a text is inside a line ending when a line ending of the text
    starts before the boundary and ends after it: the boundary between the
    carriage return and the line feed of a line ending. A spot in a tree is the
    valid path of a file of the tree, alone, or, when the content of that file
    is valid UTF-8, together with a span of the text of that content that starts
    and ends at no boundary inside a line ending. The start position of a spot
    with a span is the position of the boundary where its span starts, and the
    position after the spot is the position of the boundary where its span ends.
    All boundaries, lines, and columns count characters, never bytes. *)

open Sinter_text
open Sinter_paths
open Sinter_tree

type t
(** A spot in a tree. The value holds that tree. *)

type error =
  | No_file  (** the tree has no file at the valid path *)
  | Not_utf_8
      (** the content of the file at the valid path is not valid UTF-8 *)
  | Not_a_span  (** the run is not a span of the text of the file *)
  | Inside_line_ending
      (** the run starts or ends at a boundary inside a line ending *)
  | No_boundary
      (** no boundary of the body of the text of the file, other than a boundary
          inside a line ending, has the position *)
  | Reversed
      (** the second position names a boundary before the boundary that the
          first position names *)

val of_file : Tree.t -> Path.t -> (t, error) result
(** [of_file tree path] is [Ok spot] when [tree] has a file at [path], and
    [spot] is then the spot in [tree] with the valid path [path] and no span. It
    is [Error No_file] otherwise. *)

val of_run : Tree.t -> Path.t -> Text.run -> (t, error) result
(** [of_run tree path run] is [Ok spot] when [tree] has a spot with the valid
    path [path] and the span [run], and [spot] is then that spot. It is [Error]
    otherwise, with the first of these faults that holds: [No_file],
    [Not_utf_8], [Not_a_span], [Inside_line_ending]. *)

val of_positions :
  Tree.t -> Path.t -> Lines.position -> Lines.position -> (t, error) result
(** [of_positions tree path start after] is the spot from [start] to [after] at
    [path] in [tree]: [Ok spot] when [tree] has a spot with the valid path
    [path], the start position [start], and the position after the spot [after],
    and [spot] is then that spot. It is [Error] otherwise, with the first of
    these faults that holds: [No_file], [Not_utf_8], [No_boundary] for [start]
    or for [after], [Reversed]. *)

val tree : t -> Tree.t
(** [tree spot] is the tree of [spot]. *)

val path : t -> Path.t
(** [path spot] is the valid path of [spot]. *)

val span : t -> Text.run option
(** [span spot] is the span of [spot], or [None] when [spot] has no span. *)

val text : t -> Text.t option
(** [text spot] is the text of the content of the file of [spot], or [None] when
    that content is not valid UTF-8. A spot with a span always has a text. *)

val start_position : t -> Lines.position option
(** [start_position spot] is the start position of [spot], or [None] when [spot]
    has no span. *)

val position_after : t -> Lines.position option
(** [position_after spot] is the position after [spot], or [None] when [spot]
    has no span. *)

val start_line : t -> Text.run option
(** [start_line spot] is the line of the text of the file of [spot] of which the
    boundary where the span of [spot] starts is a boundary. It is [None] when
    [spot] has no span, or when that boundary is a boundary of no line. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the trees of [a] and [b] are
    equal as {!Tree.equal} decides, their valid paths are the same text, and
    either both have no span or both have the same span. *)
