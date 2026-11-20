(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The form of slugs, as the design [identifiers=v1] defines it. *)

val is_slug : string -> bool
(** [is_slug s] is [true] when, and only when, the whole of [s] matches the
    production [slug]: one or more segments with [/] between each two of them,
    where a segment is one or more ASCII letters and ASCII digits, with one [-],
    [_], or [.] at most between two of them, such as ["billing/late-fee"]. The
    bytes of [s] are the UTF-8 encoding of the text that the function checks. *)
