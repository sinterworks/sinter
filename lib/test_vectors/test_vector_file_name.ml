(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

let ascii s =
  Text.of_uchars (List.map Uchar.of_char (List.of_seq (String.to_seq s)))

let suffix = ascii ".test-vectors.jsonl"
let of_design x = Text.concat [ x; suffix ]
let of_specification x y = Text.concat [ x; ascii "."; y; suffix ]
