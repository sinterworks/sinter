(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_lines

type ledger = { newest_first : Entry.t list }

let ledger entries = { newest_first = List.rev entries }
let append ledger entry = { newest_first = entry :: ledger.newest_first }
let entries ledger = List.rev ledger.newest_first
let newest_first ledger = ledger.newest_first

type rule = ledger -> Entry.t -> bool
type t = Entry_kind.t -> rule option

let none _ = None

(* @satisfies ledger#pull-shared-entries=v1
   A void, and an entry of a kind with no rule, are accepted at no point. *)
let of_rules rules (kind : Entry_kind.t) =
  match kind with
  | Void -> None
  | Task | Plan | Approval | Decline | Done | Abandoned | Delivered ->
      rules kind

let accepted acceptance ledger entry =
  match acceptance (Entry.kind entry) with
  | Some rule -> rule ledger entry
  | None -> false
