(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of the design [documents=v1] for code files, read directly over a
    reading given as data: code characters, the lines of a run, runs of
    comments, comment lines, blocks of tag texts, attachment, and the tests of a
    read file. *)

open Sinter_text

type comment = Tagged | Untagged  (** whether a comment node is tagged *)

type piece =
  | Text_piece of string
  | Placeholder of string
      (** A piece of an own name, with its text as UTF-8. *)

type node = {
  run : Text.run;  (** the run of the node *)
  comment : comment option;  (** [Some] for a comment node *)
  body : Text.run list option;
      (** [Some] the runs of its body nodes, for a definition node *)
  decoration : bool;  (** [true] for a decoration node *)
  test : piece list list option;  (** [Some] its name path, for a test node *)
}
(** A node of a reading. The nodes of a reading are a list in the order of the
    parse tree; a node is named by its index in that list, from 0. *)

type sigils = {
  line : string list;  (** the line sigils *)
  block : (string * string) list;  (** the block pairs *)
  inner : string list;  (** the inner sigils *)
}
(** The comment sigils of a descriptor, as UTF-8. *)

val line_number : Text.t -> int -> int
(** [line_number text b] is the line number of the position of boundary [b] of
    the body of [text]. *)

val is_code_character : Text.t -> node list -> int -> bool
(** [is_code_character text nodes p] holds when the character at place [p] is a
    code character. *)

val first_line : Text.t -> node -> int
(** [first_line text n] is the first line number of the comment node [n]. *)

val last_line : Text.t -> node -> int
(** [last_line text n] is the last line number of the comment node [n]. *)

val run_lines : Text.t -> Text.run -> Text.run list
(** [run_lines text r] is the lines of the run [r]. *)

val comment_runs : Text.t -> node list -> int list list
(** [comment_runs text nodes] is the runs of comments, each the indexes of its
    comment nodes in their order, in the order in which the rules give them. *)

val comment_lines : sigils -> Text.t -> Text.run -> Text.run list
(** [comment_lines sigils text r] is the comment lines of a tagged comment node
    whose run is [r]. *)

val tag_text_lines :
  sigils -> Text.t -> node list -> int list -> Text.run list option
(** [tag_text_lines sigils text nodes run] is the runs that the tag text of the
    run of comments [run] joins, or [None] when it has no tagged comment node.
*)

type line_kind = { tag : bool; continuation : bool }
(** What a line of a tag text is. *)

val blocks : line_kind list -> (int * int) list
(** [blocks kinds] is the first and the last line number of each block of a tag
    text whose [k]-th line is of the kind at index [k - 1] of [kinds]. *)

val attachment : Text.t -> node list -> int list -> int option
(** [attachment text nodes run] is the index of the attachment target to which
    the run of comments [run] attaches, or [None] when it is unattached. *)

val comment_run_span : node list -> int list -> Text.run
(** [comment_run_span nodes run] is the run of the text from the boundary where
    the run of comments [run] starts to the boundary where it ends. *)

type test = {
  node : int;  (** the index of its test node *)
  name : piece list list;  (** its name *)
  code : Text.run;  (** its code *)
  comments : Text.run list;  (** each comment on it, as {!comment_run_span} *)
}
(** A test of a code file that can be read. *)

val tests : Text.t -> node list -> test list
(** [tests text nodes] is the tests of the file, in the order of the boundaries
    where their codes start, and then in the order of the parse tree. *)
