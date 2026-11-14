(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Model = Ledger_model

let set = Vectors.read "ledger"

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let required name json =
  match member name json with
  | Some value -> value
  | None -> Alcotest.failf "no member %s" name

let texts list = `List (List.map (fun text -> `String text) list)

type ref_input = No_ref | Other of string | Entries of Model.entry list

let ref_of_input input =
  match member "ref" input with
  | None -> No_ref
  | Some (`Assoc [ ("entries", tree) ]) -> Entries (Model.tree_of_json tree)
  | Some (`Assoc [ ("other", `String name) ]) -> Other name
  | Some other -> Alcotest.failf "not a ref: %s" (Yojson.Basic.to_string other)

let ledger_answer ~result ~ledger =
  `Assoc
    [
      ("result", `String result);
      ( "values",
        match ledger with
        | Some ids -> `Assoc [ ("ledger", texts ids) ]
        | None -> `Assoc [] );
    ]

let history_answer = function
  | Some result -> `Assoc [ ("result", `String result) ]
  | None -> `Assoc [ ("values", `Assoc []) ]

let pull_answer = function
  | Some (lines, left) ->
      `Assoc
        [ ("values", `Assoc [ ("lines", texts lines); ("left", texts left) ]) ]
  | None -> `Assoc [ ("values", `Assoc []) ]

let refused input = Changes_model.names_of_json (required "refused" input)

let id_of_line line =
  match Option.bind (Model.object_of_line line) (Model.string_member "id") with
  | Some id -> id
  | None -> Alcotest.failf "a line with no string id: %s" line

let model_ref = function
  | No_ref -> Model.No_ref
  | Other _ -> Model.Not_a_commit
  | Entries tree -> Model.Commit_tree tree

let give_model_ledger (vector : Vectors.vector) =
  let r = model_ref (ref_of_input vector.input) in
  ledger_answer
    ~result:(Model.validity_text (Model.validity r))
    ~ledger:(Model.stored_ledger r)

let give_model_history (vector : Vectors.vector) =
  let commits = Model.graph_of_json (required "commits" vector.input) in
  let c =
    match required "commit" vector.input with
    | `String c -> c
    | other -> Alcotest.failf "not a commit: %s" (Yojson.Basic.to_string other)
  in
  let tree = (List.assoc c commits).tree in
  history_answer
    (if Model.is_newer tree then None
     else Some (if Model.intact commits c then "valid" else "invalid"))

let give_model_pull (vector : Vectors.vector) =
  let clone = Model.lines_of_json (required "clone" vector.input) in
  let shared = Model.lines_of_json (required "shared" vector.input) in
  let refused = refused vector.input in
  pull_answer
    (match
       Model.pull
         ~clone:(Some (Model.tree_of_lines clone))
         ~shared:(Model.tree_of_lines shared)
         ~accept:(fun ~original ~before:_ _ ->
           not (List.mem (id_of_line original) refused))
     with
    | Model.Refused -> None
    | Model.Pulled { lines; left } -> Some (List.map id_of_line lines, left))

let reference_tests =
  Vectors.tests "the reference reading of ledger"
    [
      Vectors.group set ~name:"ledgers" ~rev:"v1" give_model_ledger;
      Vectors.group set ~name:"histories" ~rev:"v1" give_model_history;
      Vectors.group set ~name:"pulls" ~rev:"v1" give_model_pull;
    ]
