(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let digit_value c =
  match c with
  | '0' .. '9' -> Char.code c - 48
  | 'a' .. 'f' -> Char.code c - 87
  | _ -> Char.code c - 55

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A decimal integer of TOML 1.1.0 gives the whole number that it writes, and
   no value below -2^63 or above 2^63 - 1; the sum runs below zero, so that
   -2^63 itself fits. *)
let decimal_integer ~negative digits =
  let lowest_before_step = Int64.div Int64.min_int 10L in
  let rec sum index total =
    if index = String.length digits then Some total
    else
      let digit = Int64.of_int (digit_value digits.[index]) in
      if total < lowest_before_step then None
      else
        let shifted = Int64.mul total 10L in
        if shifted < Int64.add Int64.min_int digit then None
        else sum (index + 1) (Int64.sub shifted digit)
  in
  match sum 0 0L with
  | None -> None
  | Some total when negative -> Some total
  | Some total when total = Int64.min_int -> None
  | Some total -> Some (Int64.neg total)

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A hexadecimal, octal, or binary integer of TOML 1.1.0 gives the whole
   number that it writes, and no value above 2^63 - 1, where a conversion that
   wraps would give a negative one. *)
let radix_integer ~base digits =
  let base64 = Int64.of_int base in
  let rec sum index total =
    if index = String.length digits then Some total
    else
      let digit = Int64.of_int (digit_value digits.[index]) in
      if total > Int64.div (Int64.sub Int64.max_int digit) base64 then None
      else sum (index + 1) (Int64.add (Int64.mul total base64) digit)
  in
  sum 0 0L

let exponent_ceiling = Sys.max_string_length + Sys.max_string_length

let exponent_value digits =
  String.fold_left
    (fun total c -> min exponent_ceiling ((total * 10) + digit_value c))
    0 digits

let significant_ceiling =
  (800
  [@mutaml.skip
    "Every number of kept digits of 768 or more gives the same float: no \
     halfway point between two binary64 values has more than 768 significant \
     digits, so a cut with a nonzero last digit after them stays on the same \
     side of each halfway point."])

let first_nonzero digits =
  let rec find index =
    if index = String.length digits || digits.[index] <> '0' then index
    else find (index + 1)
  in
  find 0

let last_nonzero digits =
  let rec find index =
    if digits.[index] <> '0' then index else find (index - 1)
  in
  find (String.length digits - 1)

(* @satisfies data-forms#give-only-root-tables=v1
   The magnitude is the binary64 value nearest to the number, ties to even,
   by the rule toml-float-value: the significant digits go to the correctly
   rounded conversion of the C library, cut to 801 digits whose last is a
   nonzero digit when there are more, which keeps the number between the
   same two binary64 values and halfway points. *)
let magnitude ~digits ~fraction_length ~exponent =
  let first = first_nonzero digits in
  if first = String.length digits then 0.0
  else
    let last = last_nonzero digits in
    let significant = String.sub digits first (last - first + 1) in
    let count = String.length significant in
    let written =
      match exponent with
      | None -> 0
      | Some (false, exponent_digits) -> exponent_value exponent_digits
      | Some (true, exponent_digits) -> -exponent_value exponent_digits
    in
    let scale = written - fraction_length + (String.length digits - 1 - last) in
    let kept = min count significant_ceiling in
    let sticky = if kept < count then "1" else "" in
    float_of_string
      (String.sub significant 0 kept
      ^ sticky ^ "e"
      ^ string_of_int (scale + count - kept - String.length sticky))

(* @satisfies data-forms#give-only-root-tables=v1
   The sign bit of the float is 1 when, and only when, the float of TOML 1.1.0
   starts with a minus sign, so -0.0 and -1e-400 give negative zero. *)
let float ~negative ~digits ~fraction_length ~exponent =
  let value = magnitude ~digits ~fraction_length ~exponent in
  if negative then Float.neg value else value
