(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

let line_feed = Uchar.of_int 0x0A
let carriage_return = Uchar.of_int 0x0D

let of_text text =
  let body = Text.body text in
  let line start until acc = ({ from = start; until } : Text.run) :: acc in
  let rec scan start boundary acc =
    match Text.get text (boundary + 1) with
    | None ->
        List.rev (if start < boundary then line start boundary acc else acc)
    | Some c when Uchar.equal c line_feed ->
        scan (boundary + 1) (boundary + 1) (line start boundary acc)
    | Some c when Uchar.equal c carriage_return ->
        let next =
          if Text.get text (boundary + 2) = Some line_feed then boundary + 2
          else boundary + 1
        in
        scan next next (line start boundary acc)
    | Some _ -> scan start (boundary + 1) acc
  in
  scan body.from body.from []
