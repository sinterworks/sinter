(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines
open Sinter_hash_ids

let number_of_hex_digits = 12

let form =
  match Hash_id.form ~id_prefix:"e-" ~number_of_hex_digits with
  | Ok form -> form
  | Error _ -> invalid_arg "Entry_id.form"

let of_line_object (line_object : Json_line.t) =
  let value = (line_object :> Json.t) in
  let rest =
    Option.value (Json.object_ (Member.without value [ "id" ])) ~default:value
  in
  Hash_id.compute form (Json.canonical_byte_sequence rest)

let is_entry_id text = Option.is_some (Hash_id.validate form text)
