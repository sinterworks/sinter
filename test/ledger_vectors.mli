(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The vectors of the design [ledger=v1], read from its sidecar file, the forms
    of their inputs and of their answers, and a check of the reference reading
    in {!Ledger_model} against every vector. *)

val set : Vectors.t
(** The vectors of [ledger]. *)

val member : string -> Yojson.Basic.t -> Yojson.Basic.t option
(** [member name json] is the member [name] of the object [json]. It fails the
    test when [json] is not an object. *)

val required : string -> Yojson.Basic.t -> Yojson.Basic.t
(** [required name json] is the member [name] of the object [json]. It fails the
    test when there is none. *)

val texts : string list -> Yojson.Basic.t
(** [texts list] is the JSON array of the strings [list]. *)

(** The ledger ref of a vector of the group [ledgers]. *)
type ref_input =
  | No_ref  (** the input has no member [ref] *)
  | Other of string  (** the ledger ref resolves to this git object *)
  | Entries of Ledger_model.entry list
      (** the git tree object of the ledger commit *)

val ref_of_input : Yojson.Basic.t -> ref_input
(** [ref_of_input input] is the ledger ref of the input of a vector of the group
    [ledgers]. *)

val ledger_answer : result:string -> ledger:string list option -> Yojson.Basic.t
(** [ledger_answer ~result ~ledger] is the answer of a vector of the group
    [ledgers]: the result, and the [id] of each ledger entry of the stored
    ledger, or [{}] for [None]. *)

val history_answer : string option -> Yojson.Basic.t
(** [history_answer result] is the answer of a vector of the group [histories]:
    the result, or the values [{}] when there is no result. *)

val pull_answer : (string list * string list) option -> Yojson.Basic.t
(** [pull_answer pull] is the answer of a vector of the group [pulls]: the [id]
    of each line of the pull commit and of each line that leaves, or [{}] when
    there is no pull. *)

val refused : Yojson.Basic.t -> string list
(** [refused input] is the member [refused] of the input of a vector of the
    group [pulls]. *)

val id_of_line : string -> string
(** [id_of_line line] is the [id] of the object of [line]. It fails the test
    when [line] has no object with a string [id]. *)

val reference_tests : unit Alcotest.test_case list
(** One test case for each group: {!Ledger_model} gives what each vector holds.
*)
