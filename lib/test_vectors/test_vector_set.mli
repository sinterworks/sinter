(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Test-vector sets, as the specification [test-vectors] of the design
    [data-forms=v1] defines them.

    A test-vector set is a byte sequence of one set line, then zero or more
    group lines, then zero or more vector lines. Each line is the canonical byte
    sequence of an object, then the byte 0x0A. The group lines are one for each
    group of the vector lines, in the key order of their groups, and the numbers
    of the vector lines rise from each vector line to the next. A byte sequence
    is an OCaml [string]. *)

open Sinter_text
open Sinter_json_lines

type revision = private string
(** A test-vector revision: [v], then the decimal numeral of a whole number of 1
    or more, such as ["v2"]. *)

val compare_revisions : revision -> revision -> int
(** [compare_revisions r s] is negative when the number of [r] is less than the
    number of [s], [0] when the two numbers are the same, and positive when the
    number of [r] is greater. A number can have any count of digits. *)

type group = { name : string; revision : revision }
(** The object of a group line: [name] is the value of [group], a group name,
    and [revision] is the value of [rev]. *)

type vector = {
  number : int;  (** the value of [n], an integer of 1 or more *)
  revision : revision;  (** the value of [rev] *)
  group : string;  (** the value of [group], a group name *)
  input : Json.t;  (** the value of [input] *)
  result : Text.t option;
      (** the value of [result], or [None] when the object has no member
          [result] *)
  values : Json.t option;
      (** the value of [values], or [None] when the object has no member
          [values] *)
  note : Text.t option;
      (** the value of [note], or [None] when the object has no member [note] *)
  needs : string list;
      (** the strings of the value of [needs], in their order: one or more group
          names in rising key order, or [[]] when the object has no member
          [needs] *)
}
(** The object of a vector line. [result] or [values] is not [None], or both are
    not. *)

type t = private {
  revision : revision;  (** the value of [rev] of the set line *)
  groups : group list;  (** the objects of the group lines, in their order *)
  vectors : vector list;  (** the objects of the vector lines, in their order *)
  objects : Json.t list;
      (** the objects of the set line, the group lines, and the vector lines, in
          their order *)
}
(** A test-vector set. The fields describe the same lines: [objects] is the
    object of the set line, then one object for each element of [groups], then
    one object for each element of [vectors]. *)

val read : string -> t option
(** [read bytes] is [Some set] when [bytes] is a test-vector set, and [set] then
    holds its lines. It is [None] for every other byte sequence. It never
    raises. The time grows with the length of [bytes] times the logarithm of the
    number of its lines, and the function uses no stack space that grows with
    the depth of a JSON value in [bytes]. *)
