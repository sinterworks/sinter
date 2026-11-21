(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Test-vector sets, as the specification [test-vectors] of Data forms defines
    them, computed apart from the library. *)

val is_label_char : char -> bool
(** [is_label_char c] holds when [c] matches one character of the production
    [label] of [form-pin]. *)

val is_form_pin : string -> bool
(** [is_form_pin text] holds when [text] matches the production [form-pin]. *)

val is_group_name : string -> bool
(** [is_group_name text] holds when [text] matches the production [group-name].
*)

(** Why a byte sequence is not a test-vector set, matching the error precedence
    of [Test_vector_set.read]. *)
type error =
  | Unterminated of int
  | Not_canonical of int
  | Not_vector_object of int
  | Other_schema of int

val read : string -> (Vector_json.t list, error) result
(** [read bytes] is [Ok objects], the objects of the vector lines of [bytes] in
    their order, when [bytes] is a test-vector set, and [Error e] for the first
    failing line and first applicable constructor of [error] otherwise. *)

val write : Vector_json.t list -> string
(** [write objects] is the canonical byte sequence of each of [objects], each
    followed by the byte 0x0A. It raises [Invalid_argument] when an object is
    not a JSON value. *)
