(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The values of the integers and floats of TOML 1.1.0, from their digits.

    In this module, the digit value of a byte [c] is [Char.code c - 48] for the
    bytes [0] to [9], [Char.code c - 87] for the bytes [a] to [f], and
    [Char.code c - 55] for every other byte, which gives 10 to 15 for the bytes
    [A] to [F]. The functions read every byte by its digit value. *)

val digit_value : char -> int
(** [digit_value c] is the digit value of [c]. *)

val decimal_integer : negative:bool -> string -> int64 option
(** [decimal_integer ~negative digits] is the integer that [digits] writes in
    base 10, with a minus sign when [negative] is [true], when that integer is
    from [Int64.min_int] to [Int64.max_int]. It is [None] when the integer is
    outside that range. The integer of [""] is 0. *)

val radix_integer : base:int -> string -> int64 option
(** [radix_integer ~base digits] is the integer, 0 or more, that [digits] writes
    in base [base], when that integer is at most [Int64.max_int]. It is [None]
    when it is greater. The integer of [""] is 0. [base] is 2, 8, or 16. *)

val float :
  negative:bool ->
  digits:string ->
  fraction_length:int ->
  exponent:(bool * string) option ->
  float
(** [float ~negative ~digits ~fraction_length ~exponent] is the binary64 value
    of the number that a float of TOML 1.1.0 writes, for [digits] the digits of
    its integer part and of its fraction, one after the other, with no
    underscores, and [fraction_length] the number of digits of its fraction.
    [exponent] is [None] when the float has no exponent, and
    [Some (negative, digits)] for an exponent with the digits [digits] and a
    minus sign when [negative] is [true]. The digits are the bytes [0] to [9].

    The magnitude is the binary64 value that rounding to nearest, with ties to
    even, gives for the absolute value of that number, and it is
    [Float.infinity] when that rounding gives an infinity. The sign bit is 1
    when, and only when, [negative] is [true]. The time grows linearly with the
    length of [digits] and [exponent]. *)
