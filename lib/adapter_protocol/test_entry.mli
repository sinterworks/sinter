(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Test entries, as the specification [adapters] of the design [packs=v1]
    defines them: what a call of the function bind gives an adapter for one test
    node. *)

open Sinter_text

(** The kind of a test entry. *)
type kind = Test_case | Test_suite

(** A piece of a name. *)
type piece =
  | Text_piece of Text.t  (** text as the text of the file writes it *)
  | Placeholder of Text.t
      (** text that the test runner puts in the name when it runs the test *)

type t = private {
  id : Text.t;  (** the test entry id, which names the test entry in a call *)
  path : Sinter_paths.Path.t;
      (** the valid path at which the reading read the text *)
  line : int;  (** the first line *)
  eline : int;  (** the last line *)
  kind : kind;  (** test case or test suite *)
  names : piece list list;
      (** the name path: one sequence of pieces for each name, in order *)
  labels : Text.t list;  (** the test labels, each once, in code point order *)
}
(** A test entry. *)

(** Why the things of a test entry make no test entry. *)
type error =
  | Line_out_of_range of int
      (** a line is less than 0 or more than 9,007,199,254,740,991, the greatest
          integer of a JSON value *)

val make :
  id:Text.t ->
  path:Sinter_paths.Path.t ->
  line:int ->
  eline:int ->
  kind:kind ->
  names:piece list list ->
  labels:Text.t list ->
  (t, error) result
(** [make ~id ~path ~line ~eline ~kind ~names ~labels] is the test entry of
    these things, with the set of the texts of [labels] as its test labels. It
    is [Error (Line_out_of_range n)] when [line], then [eline], is a number [n]
    out of that range. *)
