(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = string

(* @satisfies packs#read-descriptor=v1
   A spec version is exactly two decimal numerals joined by [.]. *)
let of_string text = if Forms.decimal_numerals 2 text then Some text else None
