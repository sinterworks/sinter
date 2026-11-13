(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The conformance vectors of a design, read from its sidecar file
    [../docs/designs/<design>.test-vectors.jsonl] with
    [Sinter_test_vectors.Test_vector_set.read], and run group by group. *)

open Sinter_text
open Sinter_json_lines
open Sinter_test_vectors

type t
(** The test-vector set of one sidecar file. *)

val read : string -> t
(** [read design] reads the sidecar file of [design], such as ["findings"]. It
    raises [Failure] when the file is not a test-vector set. *)

val revision : t -> string
(** [revision set] is the revision of the set line of [set]. *)

val vectors : t -> string -> Test_vector_set.vector list
(** [vectors set name] is the vectors of the group [name], in their order. *)

(** {1 JSON values for the answers} *)

val string : string -> Json.t
(** [string bytes] is the JSON string of the text whose UTF-8 encoding is
    [bytes]. It raises [Invalid_argument] when [bytes] is not valid UTF-8. *)

val text : Text.t -> Json.t
(** [text t] is the JSON string of [t]. *)

val integer : int -> Json.t
(** [integer k] is the JSON number of [k]. It raises [Invalid_argument] when [k]
    is not a JSON integer. *)

val object_ : (string * Json.t) list -> Json.t
(** [object_ members] is the object of [members]. It raises [Invalid_argument]
    when two members have one key. *)

val member : string -> Json.t -> Json.t
(** [member key value] is the value of the member [key] of the object [value].
    It fails the test when [value] is not an object or has no such member. *)

val member_opt : string -> Json.t -> Json.t option
(** [member_opt key value] is the value of the member [key] of the object
    [value], or [None] when it has none. It fails the test when [value] is not
    an object. *)

val members : Json.t -> (Text.t * Json.t) list
(** [members value] is the members of the object [value]. It fails the test when
    [value] is not an object. *)

val elements : Json.t -> Json.t list
(** [elements value] is the elements of the array [value]. It fails the test
    when [value] is not an array. *)

val to_text : Json.t -> Text.t
(** [to_text value] is the text of the JSON string [value]. It fails the test
    when [value] is not a string. *)

val to_int : Json.t -> int
(** [to_int value] is the whole number of the JSON number [value]. It fails the
    test when [value] is not an integer. *)

val print : Json.t -> string
(** [print value] is the canonical byte sequence of [value], for messages. *)

(** {1 Groups} *)

type answer = { result : string option; values : Json.t }
(** What the code under test gives for the input of a vector: the result, when
    the group has results and the code gives one, and the values. *)

type group_test
(** The test of one vector group. *)

val group :
  t ->
  name:string ->
  rev:string ->
  (Test_vector_set.vector -> answer) ->
  group_test
(** [group set ~name ~rev give] is the test of the group [name] of [set]. The
    test fails when the group line of [name] has a revision other than [rev],
    when the group holds no vector, or when, for one or more vectors, [give]
    gives a result other than the member [result] of the vector, values that are
    not the JSON value of the member [values], or raises. A member that the
    vector line lacks is left out of the comparison. The message names each such
    vector, what it holds, and what [give] gave. *)

val tests : string -> group_test list -> unit Alcotest.test_case list
(** [tests design groups] is one test case for each of [groups]. *)

val covers : string -> t -> group_test list -> unit Alcotest.test_case
(** [covers design set groups] is a test case that fails unless [groups] holds
    exactly one test for each group line of [set]. *)
