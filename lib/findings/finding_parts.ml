(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_tree
open Sinter_spots

type t = {
  tree : Tree.t option;
  id : Finding_id.t;
  message : Message.t;
  spot : Spot.t option;
  mark : Mark.t option;
  related : Related_message.t list;
  fix : Finding_fix.t option;
  ackable : bool;
}

type error = Spot_outside_tree | Mark_of_other_spot | Fix_outside_tree

let in_tree tree other =
  match tree with Some tree -> Tree.equal tree other | None -> false

let once related =
  List.rev
    (List.fold_left
       (fun kept message ->
         if List.exists (Related_message.equal message) kept then kept
         else message :: kept)
       [] related)

(* @satisfies findings#{omit-absent-finding-parts=v1, limit-fix-edit-sets=v1}
   A finding of no tree has no spot and no fix; a spot or a fix outside the
   tree of the finding, and a mark of another spot, are refused. *)
let check ~tree ~spot ~mark ~fix =
  match (spot, mark, fix) with
  | Some spot, _, _ when not (in_tree tree (Spot.tree spot)) ->
      Error Spot_outside_tree
  | _, Some mark, _
    when not (Option.equal Spot.equal (Some (Mark.marked mark)) spot) ->
      Error Mark_of_other_spot
  | _, _, Some fix when not (in_tree tree (Finding_fix.tree fix)) ->
      Error Fix_outside_tree
  | _ -> Ok ()

let make ~tree ~class_slug ~subject ~message ~spot ~mark ~related ~fix ~ackable
    =
  Result.map
    (fun () ->
      {
        tree;
        id = Finding_id.make class_slug subject;
        message;
        spot;
        mark;
        related = once related;
        fix;
        ackable;
      })
    (check ~tree ~spot ~mark ~fix)

let tree finding = finding.tree
let id finding = finding.id
let class_slug finding = Finding_id.class_slug finding.id
let subject finding = Finding_id.subject finding.id
let message finding = finding.message
let spot finding = finding.spot
let mark finding = finding.mark
let related finding = finding.related
let fix finding = finding.fix
let ackable finding = finding.ackable

let same_set a b =
  List.length a = List.length b
  && List.for_all (fun x -> List.exists (Related_message.equal x) b) a

let equal a b =
  Option.equal Tree.equal a.tree b.tree
  && Finding_id.equal a.id b.id
  && Message.equal a.message b.message
  && Option.equal Spot.equal a.spot b.spot
  && Option.equal Mark.equal a.mark b.mark
  && same_set a.related b.related
  && Option.equal Finding_fix.equal a.fix b.fix
  && Bool.equal a.ackable b.ackable
