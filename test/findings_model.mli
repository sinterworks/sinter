(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of lines, positions, spots, edit sets, and edited texts of the
    designs [text=v1] and [findings=v1], read directly, over texts as lists of
    characters. The time of each function can grow with the square of the length
    of its text or more. *)

type text = Uchar.t list
(** A text: its characters in order. *)

val body_start : text -> int
(** [body_start t] is the boundary where the body of [t] starts. *)

val lines : text -> (int * int) list
(** [lines t] is the lines of [t], each as the boundaries where it starts and
    ends, in the order of their line numbers. *)

val inside_line_ending : text -> int -> bool
(** [inside_line_ending t b] holds when a line ending of [t] starts before [b]
    and ends after it. *)

val position : text -> int -> int * int
(** [position t b] is the position of the boundary [b] of the body of [t], as a
    line number and a column. *)

val spot_boundaries : text -> int list
(** [spot_boundaries t] is the boundaries of the body of [t] that are not inside
    a line ending, in increasing order: the boundaries where the span of a spot
    can start or end. *)

val boundary_of_position : text -> int * int -> int option
(** [boundary_of_position t position] is the boundary of {!spot_boundaries}
    whose position is [position], or [None] when no such boundary has it. *)

val line_of_boundary : text -> int -> (int * int) option
(** [line_of_boundary t b] is the line of [t] of which [b] is a boundary, or
    [None] when [b] is a boundary of no line. *)

type content =
  | Utf_8 of text
  | Not_utf_8
      (** The content of a file of a tree: valid UTF-8, with its text, or not.
      *)

type tree = (text * content) list
(** A tree: each file a valid path and its content. *)

type description = {
  path : text;
  start : int * int;
  after : int * int;
  new_text : text;
}
(** An edit description. *)

type edit = { from : int; until : int; replacement : text }
(** An edit at one valid path: the boundaries where its span starts and ends,
    and its new text. *)

val edit_of : tree -> description -> edit option
(** [edit_of tree description] is the edit that [description] describes in
    [tree], or [None] when it describes no edit. *)

val describe : tree -> description list -> (text * edit list) list option
(** [describe tree descriptions] is the edit set that [descriptions] describes
    in [tree], as its edits grouped by valid path, in the order of the first
    description of each valid path, or [None] when [descriptions] describes no
    edit set in [tree]. *)

val is_edit_set : edit list -> bool
(** [is_edit_set edits] holds when the edits of one valid path, as a set, meet
    the condition of the term [edit-set]: for each two of them, exactly one of
    the two spans ends at or before the boundary where the other starts. *)

val edited_text : text -> edit list -> text
(** [edited_text t edits] is the edited text of [t] for [edits], all at its
    valid path, when they meet {!is_edit_set}: the runs of [t] between the
    spans, with each span replaced by its new text, in the order in which each
    span ends at or before the boundary where the next starts. *)

val is_subject : text -> bool
(** [is_subject t] holds when [t] is a subject of a finding: it matches the
    production [subject] of the term [ack-line] and holds no line feed. *)

val is_message : text -> bool
(** [is_message t] holds when [t] is a message: not empty, with no line feed and
    no carriage return. *)

(** {1 Conversions} *)

val of_string : string -> text
(** [of_string bytes] is the characters of the valid UTF-8 [bytes]. *)

val to_string : text -> string
(** [to_string t] is the UTF-8 encoding of [t]. *)

val of_text : Sinter_text.Text.t -> text
(** [of_text t] is the characters of [t]. *)

val to_text : text -> Sinter_text.Text.t
(** [to_text t] is the text of the characters [t]. *)

val print : text -> string
(** [print t] is [t] for messages, with each character outside printable ASCII
    as an escape. *)
