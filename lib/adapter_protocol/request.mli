(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The requests of the calls of an adapter, as the specification [adapters] of
    the design [packs=v1] defines them.

    A request is the canonical byte sequence of a request object, as the design
    [data-forms=v1] defines canonical byte sequences, so the members of each
    object stand in key order. *)

open Sinter_text

(* @satisfies packs#give-requests=v1
   The request of each function is the only byte sequence that this module
   gives for its things, so a call that takes its request from here makes the
   call with that request. *)

val recognise :
  runner:Sinter_pack_descriptor.Pack_name.t ->
  settings:Setting_values.t ->
  report:Text.t ->
  string
(** [recognise ~runner ~settings ~report] is the request of the function
    recognise: the canonical byte sequence of the object with the members
    [interface], the integer 1; [runner], the name of the test runner;
    [settings], {!Setting_values.to_json}[ settings]; and [report], the report
    name. *)

(** Why the things of a call of bind make no request. *)
type error =
  | Repeated_id of Text.t  (** two test entries have this test entry id *)

val bind :
  runner:Sinter_pack_descriptor.Pack_name.t ->
  settings:Setting_values.t ->
  report:Text.t ->
  root:Text.t ->
  Test_entry.t list ->
  (string, error) result
(** [bind ~runner ~settings ~report ~root entries] is the request of the
    function bind: the members of {!recognise}, and [root], the root, and
    [tests], one object for each test entry, in the code point order of their
    test entry ids. The object of a test entry has the members [id], [path],
    [line], [eline], [suite] (true for a test suite), [names] (one array for
    each name, with an object [{"text": ...}] or [{"placeholder": ...}] for each
    piece), and [labels] (in code point order). It is [Error (Repeated_id id)]
    when two of [entries] have the test entry id [id], for the first such id in
    code point order. *)
