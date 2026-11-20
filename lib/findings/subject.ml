(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = Text.t
type error = Empty | Blank_start | Blank_end | Line_feed of { place : int }

let blank c = Uchar.to_int c = 0x20 || Uchar.to_int c = 0x09

let of_text text =
  let rec check place =
    match Text.get text place with
    | Some c when Uchar.to_int c = 0x0A -> Error (Line_feed { place })
    | Some _ -> check (place + 1)
    | None -> Ok text
  in
  match (Text.get text 1, Text.get text (Text.length text)) with
  | Some first, _ when blank first -> Error Blank_start
  | _, Some last when blank last -> Error Blank_end
  | Some _, Some _ -> check 1
  | _ -> Error Empty

let to_text subject = subject
