(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The conformance vectors of a design, read from its sidecar file
    [../docs/designs/<design>.test-vectors.jsonl]. *)

type vector = {
  number : int;  (** the member [n] *)
  group : string;  (** the member [group] *)
  input : Yojson.Basic.t;  (** the member [input] *)
  result : string option;  (** the member [result], when the line has it *)
  values : Yojson.Basic.t option;
      (** the member [values], when the line has it *)
  needs : string list;
      (** the strings of the member [needs], or [[]] when the line has no member
          [needs] *)
}
(** One vector line. *)

type t
(** The lines of one sidecar file. *)

val read : string -> t
(** [read design] reads the sidecar file of [design], such as ["text"]. It
    splits the file on LF only. It raises [Failure] with the number of the line
    when the file does not end with a line feed, when a line is not a JSON
    object, when the first line is not the set line, when a group line follows a
    vector line, when two group lines name one group, when a vector line lacks
    [n], [rev], [group], or [input], when a vector line has neither [result] nor
    [values], when a vector line has a member other than [n], [rev], [group],
    [input], [result], [values], [note], and [needs], when a group line has a
    member other than [group] and [rev], when [needs] is not an array of
    strings, when [n] does not rise from one vector line to the next, or when a
    vector line names a group that no group line names. *)

val revision : t -> string
(** [revision set] is the revision on the set line of [set]. *)

val count : t -> int
(** [count set] is the number of vector lines of [set]. *)

val group_names : t -> string list
(** [group_names set] is the names of the group lines of [set], in their order.
*)

val equal_json : Yojson.Basic.t -> Yojson.Basic.t -> bool
(** [equal_json a b] holds when [a] and [b] are the same JSON value, with the
    members of each object in any order. *)

type group_test
(** The test of one vector group. *)

val group :
  t ->
  name:string ->
  rev:string ->
  ?needs:(string * bool) list ->
  ?skipped:(int * string list) list ->
  (vector -> Yojson.Basic.t) ->
  group_test
(** [group set ~name ~rev ~needs ~skipped give] is the test of the group [name]
    of [set]. [needs] is the need names that the Conformance part gives, each
    with [true] when the test can make its need hold on this machine and [false]
    when it cannot; by default it is empty. A string of the member [needs] of a
    vector that [needs] does not hold stands for no need. The test skips each
    vector of the group that has a need that the test cannot make hold, and
    prints the number of the vector and each such need name. [skipped] is the
    skips that this machine must make: each the number of a vector and its need
    names that the test cannot make hold, in the order of the numbers; by
    default it is empty. For each other vector of the group, [give vector] is
    what the code under test gives for [vector.input], in the form of the
    vector: an object with the member [result], when the group has results, and
    the member [values]. A member that the vector line lacks is left out of the
    comparison. The test fails when the group line of [name] has a revision
    other than [rev], when the group holds no vector, when the skips differ from
    [skipped], or when [give] gives another JSON value for one or more of the
    vectors; the message names each such vector, what it holds, and what [give]
    gave, or the exception that [give] raised. *)

val vectors : t -> string -> vector list
(** [vectors set name] is the vectors of the group [name] of [set], in the order
    of their numbers. *)

val tests : string -> group_test list -> unit Alcotest.test_case list
(** [tests design groups] is one test case for each of [groups]. [design] names
    the test cases. *)

val covers : string -> t -> group_test list -> unit Alcotest.test_case
(** [covers design set groups] is a test case that fails unless [groups] holds
    exactly one test for each group line of [set]. *)
