(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The members of JSON objects, found by their keys. A key is a text, given
    here as its UTF-8 encoding, an OCaml [string]. *)

open Sinter_json_lines

val find : Json.t -> string -> Json.t option
(** [find value key] is [Some v] when [value] is an object with a member whose
    key is the text that [key] encodes, and [v] is the value of that member. It
    is [None] when [value] is not an object, or has no such member. The time is
    linear in the number of members of [value] and the length of [key]. *)

val without : Json.t -> string list -> (Sinter_text.Text.t * Json.t) list
(** [without value keys] is the members of [value], in their order, other than
    those whose keys are the texts that [keys] encode. It is [[]] when [value]
    is not an object. *)
