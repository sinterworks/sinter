(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let lower c = c >= 'a' && c <= 'z'
let digit c = c >= '0' && c <= '9'

let decimal_numeral text =
  match text with
  | "0" -> true
  | _ -> text <> "" && text.[0] <> '0' && String.for_all digit text

let decimal_numerals count text =
  let parts = String.split_on_char '.' text in
  List.length parts = count && List.for_all decimal_numeral parts
