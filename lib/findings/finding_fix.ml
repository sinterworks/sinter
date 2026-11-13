(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_tree
open Sinter_spots

type t = { message : Message.t; edit_sets : Edit_set.t list; tree : Tree.t }

type error =
  | No_edit_set
  | Different_trees
  | Repeated_edit_set of { first : int; second : int }

let rec repeated second earlier = function
  | [] -> None
  | set :: rest -> (
      match List.find_index (Edit_set.equal set) (List.rev earlier) with
      | Some index -> Some (Repeated_edit_set { first = index + 1; second })
      | None -> repeated (second + 1) (set :: earlier) rest)

(* @satisfies findings#limit-fix-edit-sets=v1
   A fix holds one or more edit sets, all in one tree, no two the same set, each
   with its number from 1 in the order of the list. *)
let make message edit_sets =
  match edit_sets with
  | [] -> Error No_edit_set
  | first :: _ -> (
      let tree = Edit_set.tree first in
      if
        not
          (List.for_all
             (fun set -> Tree.equal tree (Edit_set.tree set))
             edit_sets)
      then Error Different_trees
      else
        match repeated 1 [] edit_sets with
        | Some error -> Error error
        | None -> Ok { message; edit_sets; tree })

let message fix = fix.message
let edit_sets fix = fix.edit_sets
let tree fix = fix.tree

let equal a b =
  Message.equal a.message b.message
  && List.equal Edit_set.equal a.edit_sets b.edit_sets
