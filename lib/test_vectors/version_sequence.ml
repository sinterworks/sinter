(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
module Names = Map.Make (String)
module Numbers = Map.Make (Int)
module Vector_set = Test_vector_set

type version = { set : Vector_set.t; forms : Text.t Names.t }
type forms_error = Extra_forms of string | Missing_forms of string

let version (set : Vector_set.t) forms =
  let groups =
    List.fold_left
      (fun groups (group : Vector_set.group) -> Names.add group.name () groups)
      Names.empty set.groups
  in
  let rec collect named = function
    | [] -> (
        match
          List.find_opt
            (fun (group : Vector_set.group) -> not (Names.mem group.name named))
            set.groups
        with
        | Some group -> Error (Missing_forms group.name)
        | None -> Ok { set; forms = named })
    | (group, text) :: rest ->
        if Names.mem group groups && not (Names.mem group named) then
          collect (Names.add group text named) rest
        else Error (Extra_forms group)
  in
  collect Names.empty forms

(* @satisfies data-forms#validate-version-sequences=v1
   A vector line changes when `group`, `input`, `result`, or `values` differs
   in presence or in canonical bytes, or when the forms texts of its groups
   differ; a change of `note` or `needs` alone is no change. *)
let changes earlier later (e : Vector_set.vector) (l : Vector_set.vector) =
  (not (String.equal e.group l.group))
  || (not (Json.equal e.input l.input))
  || (not (Option.equal Text.equal e.result l.result))
  || (not (Option.equal Json.equal e.values l.values))
  || not
       (Option.equal Text.equal
          (Names.find_opt e.group earlier.forms)
          (Names.find_opt l.group later.forms))

(* @satisfies data-forms#validate-version-sequences=v1
   A revision that must rise is higher than the one before it, and every
   other revision is the same. *)
let rises_when rises before after =
  let order = Vector_set.compare_revisions after before in
  if rises then order > 0 else order = 0

let by_number (set : Vector_set.t) =
  List.fold_left
    (fun vectors (vector : Vector_set.vector) ->
      Numbers.add vector.number vector vectors)
    Numbers.empty set.vectors

let in_group group vectors (vector : Vector_set.vector) =
  match Numbers.find_opt vector.number vectors with
  | Some (other : Vector_set.vector) -> String.equal other.group group
  | None -> false

(* @satisfies data-forms#validate-version-sequences=v1
   Checks the five rules of a version and the one before it: new numbers above
   every earlier number, and the revisions of vectors, of groups, and of the
   set, each higher exactly when what it covers changes, joins, or leaves. *)
let follows ~greatest_number ~past_revisions earlier later =
  let earlier_vectors = by_number earlier.set
  and later_vectors = by_number later.set in
  let changes_or_joins (l : Vector_set.vector) =
    match Numbers.find_opt l.number earlier_vectors with
    | Some e -> changes earlier later e l
    | None -> true
  in
  let numbers_rise =
    List.for_all
      (fun (l : Vector_set.vector) ->
        Numbers.mem l.number earlier_vectors || l.number > greatest_number)
      later.set.vectors
  in
  let vector_revisions =
    List.for_all
      (fun (l : Vector_set.vector) ->
        match Numbers.find_opt l.number earlier_vectors with
        | Some e -> rises_when (changes earlier later e l) e.revision l.revision
        | None -> true)
      later.set.vectors
  in
  let touched =
    List.fold_left
      (fun touched (e : Vector_set.vector) ->
        if in_group e.group later_vectors e then touched
        else Names.add e.group () touched)
      (List.fold_left
         (fun touched (l : Vector_set.vector) ->
           if changes_or_joins l then Names.add l.group () touched else touched)
         Names.empty later.set.vectors)
      earlier.set.vectors
  in
  let earlier_groups =
    List.fold_left
      (fun groups (e : Vector_set.group) -> Names.add e.name e.revision groups)
      Names.empty earlier.set.groups
  in
  let group_revisions =
    List.for_all
      (fun (l : Vector_set.group) ->
        match Names.find_opt l.name earlier_groups with
        | Some revision ->
            rises_when (Names.mem l.name touched) revision l.revision
        | None -> (
            match Names.find_opt l.name past_revisions with
            | Some past -> Vector_set.compare_revisions l.revision past > 0
            | None -> true))
      later.set.groups
  in
  let set_rises =
    List.exists changes_or_joins later.set.vectors
    || List.exists
         (fun (e : Vector_set.vector) ->
           not (Numbers.mem e.number later_vectors))
         earlier.set.vectors
  in
  numbers_rise && vector_revisions && group_revisions
  && rises_when set_rises earlier.set.revision later.set.revision

let record (greatest_number, past_revisions) version =
  ( List.fold_left
      (fun greatest (vector : Vector_set.vector) -> max greatest vector.number)
      greatest_number version.set.vectors,
    List.fold_left
      (fun past (group : Vector_set.group) ->
        Names.add group.name group.revision past)
      past_revisions version.set.groups )

(* @satisfies data-forms#validate-version-sequences=v1
   Applies the rules to each version after the first and the version right
   before it, with the greatest number and the latest revision of each group
   of all versions before it. *)
let validate versions =
  let rec go history earlier = function
    | [] -> true
    | later :: rest ->
        let greatest_number, past_revisions = history in
        follows ~greatest_number ~past_revisions earlier later
        && go (record history later) later rest
  in
  match versions with
  | [] -> true
  | first :: rest -> go (record (0, Names.empty) first) first rest
