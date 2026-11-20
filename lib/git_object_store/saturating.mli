(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The sizes of the size encodings of the page gitformat-pack, with a value
    above {!max_int} read as {!max_int}. *)

val add_bits : int -> bits:int -> shift:int -> int
(** [add_bits value ~bits ~shift] is [value] with the bits [bits] at the
    position [shift], [value lor (bits lsl shift)], or {!max_int} when that
    number is above {!max_int}, for a [value] that is {!max_int} or that has no
    bit at [shift] or above, and [bits] and [shift] that are 0 or above. *)
