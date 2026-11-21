(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The vectors of the groups [parent-lines], [tree-objects], and [upstreams] of
    the design [changes=v1], 194 to 236, as the branch docs/backfill-2 of the
    design holds them, read from [fixtures/changes-proposed/vectors.jsonl] until
    the design that this chunk builds on holds them. Each line is a vector line
    in the form of section 6 of the design. *)

val test :
  string -> (Yojson.Basic.t -> Yojson.Basic.t) -> unit Alcotest.test_case
(** [test group give] is a test case that fails unless the file holds a vector
    of [group], and [give input] is the member [values] of each vector of
    [group], with the members of each object in any order. The message names
    each vector that differs, what it holds, and what [give] gave, or the
    exception that [give] raised. *)
