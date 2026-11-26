(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines

let prefix = "e-"
let number_of_hex_digits = 32

let of_line_object (line_object : Json_line.t) =
  let value = (line_object :> Json.t) in
  let rest =
    Option.value (Json.object_ (Member.without value [ "id" ])) ~default:value
  in
  let hash =
    (Sinter_hashes.Hash.compute (Json.canonical_byte_sequence rest) :> string)
  in
  prefix ^ String.sub hash 0 number_of_hex_digits

let is_hex_digit c = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')

let is_entry_id text =
  let prefix_length = String.length prefix in
  String.length text = prefix_length + number_of_hex_digits
  && String.starts_with ~prefix text
  && String.for_all is_hex_digit
       (String.sub text prefix_length number_of_hex_digits)
