(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The character tests and the decimal numerals that the productions of the
    descriptor use. *)

val lower : char -> bool
(** [lower c] is [true] when [c] is a lower-case ASCII letter. *)

val digit : char -> bool
(** [digit c] is [true] when [c] is an ASCII digit. *)

val decimal_numerals : int -> string -> bool
(** [decimal_numerals count text] is [true] when [text] is [count] decimal
    numerals joined by [.]: each one [0], or a digit from [1] to [9] followed by
    any number of digits. *)
