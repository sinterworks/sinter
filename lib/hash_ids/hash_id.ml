(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type form = { id_prefix : string; number_of_hex_digits : int }

type form_error =
  | Not_an_id_prefix of string
  | Number_of_hex_digits_out_of_range of int

let is_letter c = c >= 'a' && c <= 'z'

let is_id_prefix text =
  let length = String.length text in
  length >= 2
  && text.[length - 1] = '-'
  && String.for_all is_letter (String.sub text 0 (length - 1))

let form ~id_prefix ~number_of_hex_digits =
  if not (is_id_prefix id_prefix) then Error (Not_an_id_prefix id_prefix)
  else if number_of_hex_digits < 1 || number_of_hex_digits > 64 then
    Error (Number_of_hex_digits_out_of_range number_of_hex_digits)
  else Ok { id_prefix; number_of_hex_digits }

type t = string

(* @satisfies data-forms#compute-hash-id=v1
   The hash id is the id prefix, then the first n hex digits of the hash. *)
let compute form bytes =
  let hash = (Sinter_hashes.Hash.compute bytes :> string) in
  form.id_prefix ^ String.sub hash 0 form.number_of_hex_digits

(* @satisfies data-forms#validate-hash-id=v1
   The hex digits are the characters `0` to `9` and `a` to `f`, and no
   others. *)
let is_hex_digit c = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')

(* @satisfies data-forms#validate-hash-id=v1
   Valid exactly when the text is the id prefix, then exactly n characters
   that are each a hex digit. *)
let validate form text =
  let prefix_length = String.length form.id_prefix in
  if
    String.length text = prefix_length + form.number_of_hex_digits
    && String.starts_with ~prefix:form.id_prefix text
    && String.for_all is_hex_digit
         (String.sub text prefix_length form.number_of_hex_digits)
  then Some text
  else None
