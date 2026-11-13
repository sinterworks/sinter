(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

include Types

let first_invalid_byte bytes =
  let rec check index =
    if index >= String.length bytes then None
    else
      let decode = String.get_utf_8_uchar bytes index in
      if Uchar.utf_decode_is_valid decode then
        check (index + Uchar.utf_decode_length decode)
      else Some index
  in
  check 0

(* @satisfies data-forms#read-toml=v1
   A byte sequence that is not valid UTF-8 is not a TOML document, by the rule
   toml-encoding, and the reader replaces no byte. *)
let read bytes =
  match first_invalid_byte bytes with
  | Some offset -> Error (Invalid { error = Not_utf_8; offset })
  | None -> Parser.document bytes
