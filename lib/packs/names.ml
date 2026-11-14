(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let max_length = 255
let name_byte c = c >= ' ' && c <= '~' && c <> '/' && c <> '\\'

let is_name name =
  name <> "" && name <> "." && name <> ".." && String.for_all name_byte name
