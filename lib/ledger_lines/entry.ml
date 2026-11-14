(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = { line : Ledger_line.t; kind : Entry_kind.t }

let of_line line =
  Option.map
    (fun kind -> { line; kind })
    (Entry_kind.of_string (Ledger_line.kind line))

let id entry = Ledger_line.id entry.line
let kind entry = entry.kind
let seq entry = Ledger_line.seq entry.line

let void_field entry key =
  match entry.kind with
  | Void ->
      Member.find
        (Ledger_line.line_object entry.line :> Sinter_json_lines.Json.t)
        key
  | Task | Plan | Approval | Decline | Done | Abandoned | Delivered -> None

let dropped entry = void_field entry "dropped"
let reason entry = void_field entry "reason"
let line entry = entry.line
let line_object entry = Ledger_line.line_object entry.line
