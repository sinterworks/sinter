(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Lines and entries of the ledger for the tests: one builder for each kind of
    entry. Each builder gives the canonical line of one entry, with its id. *)

open Sinter_core

val commit_id : string
(** A commit of 40 digits, the value of [head] and of [merge]. *)

val hash : int -> string
(** [hash n] is a hash of 64 digits that differs for each [n]. *)

val common : ?kind:string -> ?seq:int -> unit -> (string * Json.t) list
(** [common ~kind ~seq ()] is the fields that every entry holds, with fixed
    values for the others. [kind] is ["approval"] and [seq] is [1] by default.
*)

val printed : Json.t -> string
(** [printed value] is the canonical form of [value]. It fails the test when
    [value] does not print. *)

val with_id : (string * Json.t) list -> (string * Json.t) list
(** [with_id fields] is [fields] with the member [id] of their line in front. It
    fails the test when the fields do not print. *)

val line_of : (string * Json.t) list -> string
(** [line_of fields] is the line of [with_id fields]. *)

val set_fields :
  ?seq:int ->
  csh:string ->
  (string option * string) list ->
  (string * string * string) list ->
  (string * Json.t) list
(** [set_fields ~csh scopes promises] is the fields of a [commitment-set] entry
    with the hash [csh]. Each scope is a step, or [None] for the plan scope, and
    a glob. Each promise is a step, a word, and a target. *)

val set_hash :
  (string option * string) list -> (string * string * string) list -> string
(** [set_hash scopes promises] is the hash of the set, as ledger section 6 reads
    it from these two arrays: the plan scope, and each promise with the globs
    that name its step, or the plan scope when none does. *)

val approval_of_text : seq:int -> string -> rev:int -> xh:string -> string
(** [approval_of_text ~seq subject ~rev ~xh] is the line of an approval of a
    declaration. *)

val approval_of_hash : seq:int -> string -> csh:string -> string
(** [approval_of_hash ~seq subject ~csh] is the line of an approval of a plan or
    a step. *)

val commitment_set :
  seq:int ->
  (string option * string) list ->
  (string * string * string) list ->
  string
(** [commitment_set ~seq scopes promises] is the line of a [commitment-set]
    entry whose [csh] is {!set_hash} [scopes promises]. *)

val decline : seq:int -> string -> hash:string -> reason:string -> string
(** [decline ~seq subject ~hash ~reason] is the line of a decline. *)

val delivered : seq:int -> string -> csh:string -> string
(** [delivered ~seq subject ~csh] is the line of a [delivered] entry. *)

val completed : seq:int -> ?approval:string -> string -> string
(** [completed ~seq subject] is the line of a [completed] entry. *)

val abandoned : seq:int -> string -> reason:string -> string
(** [abandoned ~seq subject ~reason] is the line of an [abandoned] entry. *)

val void : seq:int -> dropped:string -> reason:string -> string
(** [void ~seq ~dropped ~reason] is the line of a [void] entry. *)

val unknown : seq:int -> string -> string
(** [unknown ~seq kind] is the line of an entry of the kind [kind], with the
    common fields only. *)

val id_of_line : string -> string
(** [id_of_line line] is the id that [line] holds. It fails the test when the
    line does not read. *)

val entries : string list -> Ledger.entry list
(** [entries lines] is the entry of each line of a known kind, in the order of
    the lines. It leaves out each line of an unknown kind, as {!Ledger.entries}
    does. It fails the test when a line does not read. *)
