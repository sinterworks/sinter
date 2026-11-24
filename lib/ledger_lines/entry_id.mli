(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Entry ids, as the term [entry-id] of the design [ledger=v1] defines them.

    The entry id of an object is the text [e-], then the first 32 hex digits of
    the hash of the canonical byte sequence of the object that has each member
    of that object other than the member [id], and no other member. This form
    holds until the code follows the revised design [ledger], in which an entry
    id is a hash id with the kind of the object as its id prefix. *)

open Sinter_json_lines

val of_line_object : Json_line.t -> string
(** [of_line_object line_object] is the entry id of [line_object]. Its value
    does not depend on the member [id] of [line_object]. The time is linear in
    the length of the canonical byte sequence of [line_object]. *)

val is_entry_id : string -> bool
(** [is_entry_id text] is [true] when, and only when, [text] has the form of an
    entry id: [e-], then exactly as many hex digits as an entry id has, each one
    of [0] to [9] and [a] to [f]. *)
