(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t =
  | Task
  | Plan
  | Approval
  | Decline
  | Done
  | Abandoned
  | Delivered
  | Void

(* @satisfies ledger#give-stored-ledgers=v1
   A line holds a ledger entry only when its `kind` is one of exactly these
   eight texts; every other text gives no kind, so its line gives no ledger
   entry. *)
let of_string = function
  | "task" -> Some Task
  | "plan" -> Some Plan
  | "approval" -> Some Approval
  | "decline" -> Some Decline
  | "done" -> Some Done
  | "abandoned" -> Some Abandoned
  | "delivered" -> Some Delivered
  | "void" -> Some Void
  | _ -> None

let to_string = function
  | Task -> "task"
  | Plan -> "plan"
  | Approval -> "approval"
  | Decline -> "decline"
  | Done -> "done"
  | Abandoned -> "abandoned"
  | Delivered -> "delivered"
  | Void -> "void"
