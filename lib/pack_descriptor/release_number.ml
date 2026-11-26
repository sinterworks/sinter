(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = string

(* @satisfies packs#read-descriptor=v1
   A release number is exactly three decimal numerals joined by [.]. *)
let of_string text = if Forms.decimal_numerals 3 text then Some text else None
