(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_spots
module Gen = QCheck2.Gen
module Path = Sinter_paths.Path
module Tree = Sinter_tree.Tree
module M = Findings_model
module S = Set_vectors

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let path_of string =
  match Path.of_text (M.to_text (M.of_string string)) with
  | Ok path -> path
  | Error _ -> invalid_arg "path_of"

let tree_of files =
  match
    Tree.of_files (List.map (fun (name, bytes) -> (path_of name, bytes)) files)
  with
  | Ok tree -> tree
  | Error _ -> invalid_arg "tree_of"

let edited_texts tree set =
  List.filter_map
    (fun (path, _) ->
      Option.map
        (fun text -> (Text.encode (Path.to_text path), text))
        (Edit_set.edited_text set path))
    (Tree.files tree)

let findings_set = S.read "findings"

let content_of = function
  | Sinter_json_lines.Json.String text -> Text.encode text
  | other ->
      Vector_json.of_hex (Text.encode (S.to_text (S.member "bytes" other)))

let position_of json : Lines.position =
  {
    line = S.to_int (S.member "line" json);
    column = S.to_int (S.member "column" json);
  }

let description_of json : Edit_description.t =
  {
    path = S.to_text (S.member "path" json);
    start = position_of (S.member "start" json);
    after = position_of (S.member "after" json);
    new_text = S.to_text (S.member "new-text" json);
  }

let give_edit_sets (vector : Sinter_test_vectors.Test_vector_set.vector) =
  let tree =
    tree_of
      (List.map
         (fun (name, content) -> (Text.encode name, content_of content))
         (S.members (S.member "files" vector.input)))
  in
  let descriptions =
    List.map description_of (S.elements (S.member "edits" vector.input))
  in
  match Edit_description.edit_set tree descriptions with
  | Error _ -> { S.result = Some "invalid"; values = S.object_ [] }
  | Ok set ->
      {
        S.result = Some "valid";
        values =
          S.object_
            [
              ( "edited-texts",
                S.object_
                  (List.map
                     (fun (name, text) -> (name, S.text text))
                     (edited_texts tree set)) );
            ];
      }

(* @verifies findings[edit-sets][*]=v1
   Each vector gives a tree and edit descriptions; the test fails when the
   validation gives another result, when an edited text differs from the
   values, or when a file of the tree that the values do not name gets an
   edited text. *)
let edit_set_vectors =
  S.group findings_set ~name:"edit-sets" ~rev:"v1" give_edit_sets

let text_pieces =
  [
    (4, Gen.return "a");
    (2, Gen.return "b");
    (2, Gen.return "\n");
    (1, Gen.return "\r");
    (2, Gen.return "\r\n");
    (1, Gen.return "\xc3\xa9");
    (1, Gen.return "\xef\xbb\xbf");
  ]

let text_gen =
  Gen.map
    (fun (bom, parts) ->
      M.of_string ((if bom then "\xef\xbb\xbf" else "") ^ String.concat "" parts))
    (Gen.pair Gen.bool
       (Gen.list_size (Gen.int_range 0 6) (Gen.oneof_weighted text_pieces)))

let new_text_gen =
  Gen.map M.of_string (Gen.oneof_list [ ""; "X"; "\n"; "\xc3\xa9"; "\r\n" ])

let model_tree_gen =
  Gen.map2
    (fun a b -> [ (M.of_string "a.md", M.Utf_8 a); (M.of_string "b.md", b) ])
    text_gen
    (Gen.oneof
       [ Gen.map (fun t -> M.Utf_8 t) text_gen; Gen.return M.Not_utf_8 ])

let bytes_of = function M.Utf_8 t -> M.to_string t | M.Not_utf_8 -> "a\xff"

let tree_of_model model =
  tree_of
    (List.map
       (fun (path, content) -> (M.to_string path, bytes_of content))
       model)

let boundary_pair_gen t =
  Gen.(
    oneof_list (M.spot_boundaries t) >>= fun a ->
    map (fun b -> (min a b, max a b)) (oneof_list (M.spot_boundaries t)))

let description_gen (model : M.tree) =
  Gen.(
    oneof_weighted
      [
        (5, return "a.md");
        (3, return "b.md");
        (1, return "c.md");
        (1, return "./a.md");
      ]
    >>= fun name ->
    let path = M.of_string name in
    let random =
      map3
        (fun s a new_text -> { M.path; start = s; after = a; new_text })
        (pair (int_range (-1) 4) (int_range (-1) 5))
        (pair (int_range (-1) 4) (int_range (-1) 5))
        new_text_gen
    in
    match List.assoc_opt path model with
    | Some (M.Utf_8 t) ->
        oneof_weighted
          [
            (1, random);
            ( 4,
              map2
                (fun (s, e) new_text ->
                  {
                    M.path;
                    start = M.position t s;
                    after = M.position t e;
                    new_text;
                  })
                (boundary_pair_gen t) new_text_gen );
          ]
    | _ -> random)

let case_gen =
  Gen.(
    model_tree_gen >>= fun model ->
    map
      (fun descriptions -> (model, descriptions))
      (list_size (int_range 0 4) (description_gen model)))

let print_description (d : M.description) =
  Printf.sprintf "%s %d:%d to %d:%d %S" (M.print d.path) (fst d.start)
    (snd d.start) (fst d.after) (snd d.after) (M.print d.new_text)

let print_case (model, descriptions) =
  String.concat "; "
    (List.map
       (fun (path, content) ->
         Printf.sprintf "%s=%s" (M.print path)
           (match content with
           | M.Utf_8 t -> M.print t
           | M.Not_utf_8 -> "<not UTF-8>"))
       model)
  ^ " | "
  ^ String.concat "; " (List.map print_description descriptions)

let to_description (d : M.description) : Edit_description.t =
  {
    path = M.to_text d.path;
    start = { line = fst d.start; column = snd d.start };
    after = { line = fst d.after; column = snd d.after };
    new_text = M.to_text d.new_text;
  }

let names = [ "a.md"; "b.md"; "c.md" ]

let edited_texts_follow_the_model model set expected =
  List.for_all
    (fun name ->
      let have = Edit_set.edited_text set (path_of name) in
      match (have, List.assoc_opt (M.of_string name) expected) with
      | None, None -> true
      | Some text, Some edits -> (
          match List.assoc_opt (M.of_string name) model with
          | Some (M.Utf_8 t) -> M.of_text text = M.edited_text t edits
          | _ -> false)
      | _ -> false)
    names

let fault_is_right tree (d : Edit_description.t) = function
  | Edit_description.Not_a_path error -> Path.of_text d.path = Error error
  | Edit_description.No_spot error -> (
      match Path.of_text d.path with
      | Error _ -> false
      | Ok path -> Spot.of_positions tree path d.start d.after = Error error)

let rec first_without_edit model number = function
  | [] -> None
  | d :: rest -> (
      match M.edit_of model d with
      | None -> Some (number, d)
      | Some _ -> first_without_edit model (number + 1) rest)

(* @verifies findings#{validate-edit-sets=v1, give-edited-texts=v1, omit-edited-texts=v1}
   For generated trees and sequences of edit descriptions, the test fails when
   the validation gives "valid" for a sequence that describes no edit set in
   the tree, or "invalid" for one that does, as a direct reading of the terms
   decides; when an edited text differs from that reading of the term
   edited-text; or when a valid path that no edit description names gets an
   edited text. *)
let edit_descriptions_follow_the_terms =
  property ~count:2000
    ~name:"edit_set gives the edit set that the descriptions describe"
    ~print:print_case case_gen (fun (model, descriptions) ->
      let tree = tree_of_model model in
      let given = List.map to_description descriptions in
      match
        (Edit_description.edit_set tree given, M.describe model descriptions)
      with
      | Ok set, Some expected ->
          Tree.equal (Edit_set.tree set) tree
          && edited_texts_follow_the_model model set expected
      | Error error, None -> (
          match (error, first_without_edit model 1 descriptions) with
          | Edit_description.Not_an_edit_set Edit_set.No_edit, _ ->
              descriptions = []
          | Edit_description.Not_an_edit { number; fault }, Some (first, _) ->
              number = first
              && fault_is_right tree (List.nth given (number - 1)) fault
          | Edit_description.Not_an_edit_set Edit_set.Conflicting_edits, None ->
              descriptions <> []
          | _ -> false)
      | _ -> false)

let rotate = function [] -> [] | first :: rest -> rest @ [ first ]

let order_of_descriptions_changes_nothing =
  property ~count:1000
    ~name:"a valid sequence in another order gives the same edited texts"
    ~print:print_case case_gen (fun (model, descriptions) ->
      let tree = tree_of_model model in
      let given = List.map to_description descriptions in
      let answer order =
        match Edit_description.edit_set tree order with
        | Ok set ->
            Some
              (List.map
                 (fun name ->
                   Option.map Text.encode
                     (Edit_set.edited_text set (path_of name)))
                 names)
        | Error _ -> None
      in
      let first = answer given in
      List.for_all
        (fun order -> answer order = first)
        [ List.rev given; rotate given; rotate (rotate given) ])

let edit_description_answers_any_positions =
  property ~count:1000 ~name:"edit gives an edit or a fault for any description"
    ~print:(fun (t, (a, b, c, d)) ->
      Printf.sprintf "%s %d:%d %d:%d" (M.print t) a b c d)
    Gen.(
      pair text_gen
        (quad
           (oneof [ int; int_range (-2) 4 ])
           (oneof [ int; int_range (-2) 6 ])
           (oneof [ int; int_range (-2) 4 ])
           (oneof [ int; int_range (-2) 6 ])))
    (fun (t, (l1, c1, l2, c2)) ->
      let tree = tree_of [ ("a.md", M.to_string t) ] in
      let description : Edit_description.t =
        {
          path = M.to_text (M.of_string "a.md");
          start = { line = l1; column = c1 };
          after = { line = l2; column = c2 };
          new_text = Text.empty;
        }
      in
      match Edit_description.edit tree description with
      | Ok edit ->
          M.edit_of
            [ (M.of_string "a.md", M.Utf_8 t) ]
            {
              path = M.of_string "a.md";
              start = (l1, c1);
              after = (l2, c2);
              new_text = [];
            }
          <> None
          && Text.equal (Edit.new_text edit) Text.empty
      | Error fault -> fault_is_right tree description fault)

let spot_edit tree name (from, until) new_text =
  match Spot.of_run tree (path_of name) { from; until } with
  | Error _ -> None
  | Ok spot -> (
      match Edit.make spot (M.to_text new_text) with
      | Ok edit -> Some edit
      | Error Edit.No_span -> None)

let edits_gen =
  Gen.(
    pair text_gen text_gen >>= fun (a, b) ->
    let one =
      oneof_weighted [ (3, return ("a.md", a)); (2, return ("b.md", b)) ]
      >>= fun (name, t) ->
      map3
        (fun span new_text other_tree -> (name, span, new_text, other_tree))
        (boundary_pair_gen t) new_text_gen
        (oneof_weighted [ (8, return 0); (1, return 1); (1, return 2) ])
    in
    map (fun edits -> (a, b, edits)) (list_size (int_range 0 4) one))

let print_edits (a, b, edits) =
  Printf.sprintf "a.md=%s b.md=%s | %s" (M.print a) (M.print b)
    (String.concat "; "
       (List.map
          (fun (name, (f, u), new_text, other) ->
            Printf.sprintf "%s %d to %d %S tree %d" name f u (M.print new_text)
              other)
          edits))

let build_edits (a, b, edits) =
  let all_other =
    edits <> [] && List.for_all (fun (_, _, _, which) -> which = 2) edits
  in
  let tree = tree_of [ ("a.md", M.to_string a); ("b.md", M.to_string b) ] in
  let same_content =
    tree_of [ ("b.md", M.to_string b); ("a.md", M.to_string a) ]
  in
  let other =
    tree_of [ ("a.md", M.to_string a); ("b.md", M.to_string b); ("c.md", "") ]
  in
  let trees = [| tree; same_content; other |] in
  ( (if all_other then other else tree),
    List.filter_map
      (fun (name, span, new_text, which) ->
        Option.map
          (fun edit -> (name, span, new_text, which, edit))
          (spot_edit trees.(which) name span new_text))
      edits )

(* @verifies findings#{give-edited-texts=v1, omit-edited-texts=v1}
   For generated edits in one tree, given in any order, the test fails when
   the edited text of a valid path differs from a direct reading of the term
   edited-text, or when a valid path of no edit gets an edited text. *)
let edit_sets_of_edits_follow_the_terms =
  property ~count:2000
    ~name:"of_edits gives the edit set of the edits, in any order"
    ~print:print_edits edits_gen (fun case ->
      let a, b, _ = case in
      let tree, built = build_edits case in
      let edits = List.map (fun (_, _, _, _, edit) -> edit) built in
      let model_edits name =
        List.filter_map
          (fun (n, (from, until), replacement, _, _) ->
            if n = name then Some { M.from; until; replacement } else None)
          built
      in
      let expected =
        if built = [] then Error Edit_set.No_edit
        else if
          List.exists (fun (_, _, _, which, _) -> which = 2) built
          && List.exists (fun (_, _, _, which, _) -> which <> 2) built
        then Error Edit_set.Different_trees
        else if
          List.for_all
            (fun name -> M.is_edit_set (model_edits name))
            [ "a.md"; "b.md" ]
        then Ok ()
        else Error Edit_set.Conflicting_edits
      in
      let check result =
        match (result, expected) with
        | Error have, Error want -> have = want
        | Ok set, Ok () ->
            Tree.equal (Edit_set.tree set) tree
            && List.for_all
                 (fun (name, t) ->
                   match
                     (model_edits name, Edit_set.edited_text set (path_of name))
                   with
                   | [], None -> true
                   | edits, Some text ->
                       edits <> [] && M.of_text text = M.edited_text t edits
                   | _ -> false)
                 [ ("a.md", a); ("b.md", b) ]
            && Edit_set.edited_text set (path_of "c.md") = None
        | _ -> false
      in
      check (Edit_set.of_edits edits)
      && check (Edit_set.of_edits (List.rev edits))
      && check (Edit_set.of_edits (rotate edits)))

let edits_come_in_their_order =
  property ~count:1000
    ~name:"edits gives each edit once, by path and then by span"
    ~print:print_edits edits_gen (fun case ->
      let _, built = build_edits case in
      let edits = List.map (fun (_, _, _, _, edit) -> edit) built in
      match Edit_set.of_edits edits with
      | Error _ -> true
      | Ok set ->
          let given = Edit_set.edits set in
          let key edit =
            Text.encode (Path.to_text (Spot.path (Edit.spot edit)))
          in
          let rec ordered = function
            | x :: (y :: _ as rest) ->
                (key x < key y
                || (key x = key y && (Edit.span y).from >= (Edit.span x).until)
                )
                && ordered rest
            | _ -> true
          in
          List.length given = List.length edits
          && List.for_all
               (fun edit -> List.exists (Edit.equal edit) given)
               edits
          && ordered given)

let equal_compares_trees_and_edits =
  property ~count:1000
    ~name:"equal holds for the same edits in an equal tree, in any order"
    ~print:print_edits edits_gen (fun case ->
      let _, built = build_edits case in
      let edits = List.map (fun (_, _, _, _, edit) -> edit) built in
      match (Edit_set.of_edits edits, Edit_set.of_edits (List.rev edits)) with
      | Ok x, Ok y -> (
          Edit_set.equal x y
          &&
          match built with
          | (_, _, _, _, edit) :: rest -> (
              let changed =
                match
                  Edit.make (Edit.spot edit)
                    (Text.concat
                       [ Edit.new_text edit; M.to_text (M.of_string "!") ])
                with
                | Ok changed -> changed
                | Error _ -> edit
              in
              match
                Edit_set.of_edits
                  (changed :: List.map (fun (_, _, _, _, e) -> e) rest)
              with
              | Ok z -> not (Edit_set.equal x z || Edit_set.equal z x)
              | Error _ -> false)
          | [] -> false)
      | Error _, Error _ -> true
      | _ -> false)

let edit_needs_a_span () =
  let tree = tree_of [ ("a.md", "abc") ] in
  (match Spot.of_file tree (path_of "a.md") with
  | Ok spot ->
      Alcotest.(check bool)
        "no edit of a spot without a span" true
        (Edit.make spot Text.empty = Error Edit.No_span)
  | Error _ -> Alcotest.fail "the tree has a.md");
  match Spot.of_run tree (path_of "a.md") { from = 1; until = 2 } with
  | Error _ -> Alcotest.fail "1 to 2 is a span"
  | Ok spot -> (
      let new_text = M.to_text (M.of_string "X") in
      match Edit.make spot new_text with
      | Error _ -> Alcotest.fail "a spot with a span gives an edit"
      | Ok edit ->
          Alcotest.(check bool)
            "the spot" true
            (Spot.equal (Edit.spot edit) spot);
          Alcotest.(check bool)
            "the span" true
            (Edit.span edit = { from = 1; until = 2 });
          Alcotest.(check bool)
            "the new text" true
            (Text.equal (Edit.new_text edit) new_text);
          Alcotest.(check bool)
            "another new text is another edit" false
            (match Edit.make spot Text.empty with
            | Ok other -> Edit.equal edit other
            | Error _ -> true);
          Alcotest.(check bool)
            "the same spot and new text is the same edit" true
            (match Edit.make spot (M.to_text (M.of_string "X")) with
            | Ok other -> Edit.equal edit other
            | Error _ -> false))

let no_description_is_no_edit_set () =
  Alcotest.(check bool)
    "the empty sequence" true
    (Edit_description.edit_set (tree_of [ ("a.md", "abc") ]) []
    = Error (Edit_description.Not_an_edit_set Edit_set.No_edit))

let vector_groups = [ edit_set_vectors ]

let tests =
  S.tests "findings" vector_groups
  @ [
      edit_descriptions_follow_the_terms;
      order_of_descriptions_changes_nothing;
      edit_description_answers_any_positions;
      edit_sets_of_edits_follow_the_terms;
      edits_come_in_their_order;
      equal_compares_trees_and_edits;
      Alcotest.test_case "an edit needs a spot with a span" `Quick
        edit_needs_a_span;
      Alcotest.test_case "no edit description describes no edit set" `Quick
        no_description_is_no_edit_set;
    ]
