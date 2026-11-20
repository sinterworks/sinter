(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = Text.t
type error = Empty | Line_break of { place : int }

let line_feed = Uchar.of_int 0x0A
let carriage_return = Uchar.of_int 0x0D

let of_text text =
  let rec check place =
    match Text.get text place with
    | Some c when Uchar.equal c line_feed || Uchar.equal c carriage_return ->
        Error (Line_break { place })
    | Some _ -> check (place + 1)
    | None -> Ok text
  in
  if Text.length text = 0 then Error Empty else check 1

let to_text message = message
let equal = Text.equal
