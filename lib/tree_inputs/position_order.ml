(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

let compare (p : Lines.position) (q : Lines.position) =
  match Int.compare p.line q.line with
  | 0 -> Int.compare p.column q.column
  | c -> c
