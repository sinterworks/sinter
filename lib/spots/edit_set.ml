(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree

type t = { tree : Tree.t; edits : Edit.t list }
type error = No_edit | Different_trees | Conflicting_edits

let name edit = Text.encode (Path.to_text (Spot.path (Edit.spot edit)))

let order a b =
  let sa = Edit.span a and sb = Edit.span b in
  compare (name a, sa.from, sa.until) (name b, sb.from, sb.until)

(* @satisfies findings#validate-edit-sets=v1
   Two edits at the same valid path go together in an edit set only when
   exactly one of the two spans ends at or before the boundary where the other
   starts. *)
let apart a b =
  let sa = Edit.span a and sb = Edit.span b in
  sa.until <= sb.from <> (sb.until <= sa.from)

let rec ordered = function
  | a :: (b :: _ as rest) -> (name a <> name b || apart a b) && ordered rest
  | _ -> true

let of_edits = function
  | [] -> Error No_edit
  | first :: _ as edits ->
      let tree = Spot.tree (Edit.spot first) in
      if
        not
          (List.for_all
             (fun edit -> Tree.equal tree (Spot.tree (Edit.spot edit)))
             edits)
      then Error Different_trees
      else
        let edits = List.stable_sort order edits in
        if ordered edits then Ok { tree; edits } else Error Conflicting_edits

let tree set = set.tree
let edits set = set.edits

(* @satisfies findings#give-edited-texts=v1
   The edited text is the run of the text before the first span, then for each
   edit in order its new text and the run up to the next span or to the last
   boundary. *)
let splice text edits =
  let run from until =
    Option.value ~default:Text.empty (Text.sub text { from; until })
  in
  let rec pieces from = function
    | [] -> [ run from (Text.length text) ]
    | edit :: rest ->
        let span = Edit.span edit in
        run from span.from :: Edit.new_text edit :: pieces span.until rest
  in
  Text.concat (pieces 0 edits)

(* @satisfies findings#omit-edited-texts=v1
   A valid path of no edit of the set has no edited text. *)
let edited_text set path =
  let key = Text.encode (Path.to_text path) in
  match List.filter (fun edit -> name edit = key) set.edits with
  | [] -> None
  | first :: _ as edits ->
      Option.map (fun text -> splice text edits) (Spot.text (Edit.spot first))

let equal a b =
  Tree.equal a.tree b.tree && List.equal Edit.equal a.edits b.edits
