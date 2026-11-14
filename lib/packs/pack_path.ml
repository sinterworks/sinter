(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

let is_pack_path text =
  Text.length text <= Names.max_length
  && List.for_all Names.is_name (String.split_on_char '/' (Text.encode text))
