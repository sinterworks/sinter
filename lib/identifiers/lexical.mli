(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The productions of the design [identifiers=v1] that match runs of ASCII
    characters. Each function that takes a string [s] and an index [i] reads the
    bytes of [s] from [i], and gives the index right after the longest run that
    the production matches there, or [None] when it matches no run that starts
    at [i]. *)

val is_wsp : char -> bool
(** [is_wsp c] is [true] for a space and a tab. *)

val skip_wsp : string -> int -> int
(** [skip_wsp s i] is the index of the first byte at or after [i] that is not a
    space or a tab, or the length of [s]. *)

val segment : string -> int -> int option
(** The production [segment]. *)

val slug : string -> int -> int option
(** The production [slug]. *)

val label : string -> int -> int option
(** The production [label]. *)

val id_text : string -> int -> int option
(** The production [id-text]. *)

val group_name : string -> int -> int option
(** The production [group-name]. *)

val vector_number : string -> int -> int option
(** The production [vector-number]. *)

val tag_word : string -> int -> int
(** [tag_word s i] is the index right after the [@] at [i] and the longest run
    of ASCII letters, ASCII digits, and [-] after it. *)

val is_namespace_name : string -> bool
(** [is_namespace_name s] is [true] when the whole of [s] matches the production
    [namespace-name]. *)

val is_hash_prefix : string -> bool
(** [is_hash_prefix s] is [true] when the whole of [s] matches the production
    [hash-prefix]. *)
