(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Test-vector sets and version sequences, as the specification [test-vectors]
    of Data forms defines them, computed apart from the library. *)

val is_revision : string -> bool
(** [is_revision text] holds when [text] matches the production
    [test-vector-revision]. *)

val is_group_name : string -> bool
(** [is_group_name text] holds when [text] matches the production [group-name].
*)

val read : string -> Vector_json.t list option
(** [read bytes] is the objects of the set line, the group lines, and the vector
    lines of [bytes], in their order, when [bytes] is a test-vector set, and
    [None] otherwise. *)

val write : Vector_json.t list -> string
(** [write objects] is the canonical byte sequence of each of [objects], each
    then the byte 0x0A. It raises [Invalid_argument] when an object is not a
    JSON value. *)

type version = {
  objects : Vector_json.t list;
      (** the objects of the lines of the test-vector set of the version *)
  forms : (string * string) list;
      (** the text of the forms of each group, by group name *)
}
(** A version, as a vector of the group [validate-sequence] gives it. *)

val is_version_sequence : version list -> bool
(** [is_version_sequence versions] holds when [versions] is a version sequence.
    It raises [Invalid_argument] when one of [versions] holds no test-vector set
    or does not give the forms of each of its groups. *)

val version_gen : version QCheck2.Gen.t
(** Versions of small test-vector sets, with the groups [a] and [b], the numbers
    1 to 5, and two texts of forms. *)

val next_gen : version list -> version QCheck2.Gen.t
(** [next_gen earlier] gives versions [l] such that [earlier @ [l]] is a version
    sequence, when [earlier] is one and is not empty. *)

val sequence_gen : version list QCheck2.Gen.t
(** Version sequences of 1 to 5 versions, each made by [next_gen] from the
    versions before it. *)

val print_version : version -> string
(** [print_version version] is a JSON text of [version], for messages. *)
