(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let is_slug s = Lexical.slug s 0 = Some (String.length s)
