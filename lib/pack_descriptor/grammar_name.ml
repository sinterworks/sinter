(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = string

(* @satisfies packs#read-descriptor=v1
   A grammar name is a lower-case letter, then lower-case letters, digits, and
   [_]. *)
let of_string text =
  if
    text <> ""
    && Forms.lower text.[0]
    && String.for_all (fun c -> Forms.lower c || Forms.digit c || c = '_') text
  then Some text
  else None
