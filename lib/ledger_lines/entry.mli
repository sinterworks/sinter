(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Ledger entries, as the terms [entry-field] and [stored-ledger] of the design
    [ledger=v1] give them.

    The ledger entry of a ledger line ({!Ledger_line}) whose [kind] is one of
    the eight texts of {!Entry_kind} is the ledger entry of that kind whose
    object is the object of that line. A ledger line of any other kind has no
    ledger entry. A text is its UTF-8 encoding, an OCaml [string]. *)

open Sinter_json_lines

type t
(** A ledger entry. *)

val of_line : Ledger_line.t -> t option
(** [of_line line] is the ledger entry of [line], or [None] when the [kind] of
    [line] is none of the eight kinds. *)

(* @satisfies ledger#ignore-unknown-members=v1
   The functions below give, of the members of the object of an entry, only
   `id`, `kind`, `seq`, and the fields `dropped` and `reason` of the kind
   `void`; every other member reaches a caller only through `line_object` and
   `line`, so no result of these libraries that is built from entries depends
   on it. *)

val id : t -> string
(** [id entry] is the value of the member [id] of the object of [entry]: its
    entry id. *)

val kind : t -> Entry_kind.t
(** [kind entry] is the kind of [entry]. *)

val seq : t -> int
(** [seq entry] is the value of the member [seq] of the object of [entry], which
    gives its place in the order of a stored ledger. *)

val dropped : t -> Json.t option
(** [dropped entry] is the value of the member [dropped] of the object of
    [entry] when [entry] has the kind [Void] and its object has that member, and
    [None] otherwise. *)

val reason : t -> Json.t option
(** [reason entry] is the value of the member [reason] of the object of [entry]
    when [entry] has the kind [Void] and its object has that member, and [None]
    otherwise. *)

val line : t -> Ledger_line.t
(** [line entry] is the ledger line whose ledger entry [entry] is. *)

val line_object : t -> Json_line.t
(** [line_object entry] is the object of [entry], with every member that it has,
    such as [by], [ts], and the members that no design names. *)
