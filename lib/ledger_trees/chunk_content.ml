(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines
open Sinter_ledger_lines

type t = {
  lines : string list;
  newer : bool;
  ledger_lines : Ledger_line.t list option;
}

(* @satisfies ledger#validate-ledgers=v1
   The content is cut right after each byte 0x0A; a last part without 0x0A is
   a line, and nothing after the last 0x0A is a line. *)
let cut content =
  let length = String.length content in
  let rec from start lines =
    if start >= length then List.rev lines
    else
      match String.index_from_opt content start '\n' with
      | Some stop ->
          from (stop + 1) (String.sub content start (stop - start + 1) :: lines)
      | None -> List.rev (String.sub content start (length - start) :: lines)
  in
  from 0 []

(* @satisfies ledger#validate-ledgers=v1
   A newer line is a line whose JSON value is an object whose `v` is an
   integer greater than 1, whether or not the line is a canonical line. *)
let is_newer (value : Json.t option) =
  match Option.bind value (fun value -> Member.find value "v") with
  | Some (Integer version) -> version > 1
  | Some (String _ | Boolean _ | Array _ | Object _) | None -> false

let read_line line =
  match Json_line.read line with
  | Some line_object ->
      ( is_newer (Some (line_object :> Json.t)),
        Ledger_line.of_line_object line_object )
  | None -> (is_newer (Json.read_json_text line), None)

let read content =
  let lines = cut content in
  let read_lines = List.map read_line lines in
  let ledger_lines = List.filter_map snd read_lines in
  {
    lines;
    newer = List.exists fst read_lines;
    ledger_lines =
      (if lines <> [] && List.compare_lengths ledger_lines lines = 0 then
         Some ledger_lines
       else None);
  }
