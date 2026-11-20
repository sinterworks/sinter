(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Test-vector sets, as the specification [test-vectors] of the design
    [data-forms=v1] defines them.

    A byte sequence is an OCaml [string]. The lines of a byte sequence are its
    parts that each end with the byte 0x0A, in their order. When bytes follow
    the last 0x0A, those bytes are a last line that no 0x0A ends. When the byte
    sequence is not empty and holds no 0x0A, the whole byte sequence is one line
    that no 0x0A ends. Line 1 is the first line. A test-vector set is a byte
    sequence in which each line is a vector line: the canonical byte sequence of
    a vector object, then the byte 0x0A. In a test-vector set, all vector lines
    with the same group have the same schema part name in their form. The empty
    byte sequence is a test-vector set of zero vector lines. *)

open Sinter_text
open Sinter_json_lines

type vector = private {
  form : string;  (** the value of [form], a form pin *)
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
  vectors : vector list;  (** the objects of the vector lines, in their order *)
  objects : Json.t list;
      (** the objects of the vector lines, as JSON values, in their order *)
}
(** A test-vector set. The two fields describe the same lines: element [k] of
    [vectors] and element [k] of [objects] are the object of line [k + 1]. *)

(** Why a byte sequence is not a test-vector set. Each error names the number of
    the line that is not a vector line of a test-vector set. *)
type error =
  | Unterminated of int
      (** The line is the last line, and no byte 0x0A ends it. *)
  | Not_canonical of int
      (** The bytes of the line before its 0x0A are not the canonical byte
          sequence of a JSON value. *)
  | Not_vector_object of int
      (** The JSON value of the line is not a vector object. *)
  | Other_schema of int
      (** The schema part name of the form of the line differs from the schema
          part name of the form of an earlier line with the same group. *)

val read : string -> (t, error) result
(** [read bytes] is [Ok set] when [bytes] is a test-vector set, and [set] then
    holds its vector lines. Then the canonical byte sequences of the elements of
    [set.objects], each followed by the byte 0x0A, one after another, are
    [bytes].

    [read bytes] is [Error e] for every other byte sequence. [read] checks the
    lines in their order and stops at the first line that is not a vector line
    of a test-vector set. For that line, [e] is the first error of the type
    {!error}, in the order of its constructors, that applies to that line. The
    lines before that line, with their 0x0A bytes, are a test-vector set.

    [read] never raises. The time grows with the length of [bytes] times the
    logarithm of the number of its lines, and the function uses no stack space
    that grows with the depth of a JSON value in [bytes]. *)
