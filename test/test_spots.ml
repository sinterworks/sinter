(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_spots
module Gen = QCheck2.Gen
module Path = Sinter_paths.Path
module Tree = Sinter_tree.Tree
module M = Findings_model
module S = Set_vectors

let property ?(count = 300) ~name ~print generator check =
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

let a_md = path_of "a.md"
let one_file t = tree_of [ ("a.md", M.to_string t) ]

let pieces =
  [
    (4, Gen.return "a");
    (2, Gen.return "b");
    (3, Gen.return "\n");
    (3, Gen.return "\r");
    (3, Gen.return "\r\n");
    (1, Gen.return "\xc3\xa9");
    (1, Gen.return "\xef\xbb\xbf");
  ]

let text_gen =
  Gen.map
    (fun (bom, parts) ->
      M.of_string ((if bom then "\xef\xbb\xbf" else "") ^ String.concat "" parts))
    (Gen.pair Gen.bool
       (Gen.list_size (Gen.int_range 0 7) (Gen.oneof_weighted pieces)))

let position_option = function
  | None -> "none"
  | Some (p : Lines.position) -> Printf.sprintf "%d:%d" p.line p.column

let to_position (line, column) : Lines.position = { line; column }

let spot_error = function
  | Spot.No_file -> "No_file"
  | Spot.Not_utf_8 -> "Not_utf_8"
  | Spot.Not_a_span -> "Not_a_span"
  | Spot.Inside_line_ending -> "Inside_line_ending"
  | Spot.No_boundary -> "No_boundary"
  | Spot.Reversed -> "Reversed"

let bounds t = List.init (List.length t + 3) (fun index -> index - 1)

let expected_of_run t from until =
  if from < 0 || until < from || until > List.length t then
    Error Spot.Not_a_span
  else if from < M.body_start t then Error Spot.Not_a_span
  else if M.inside_line_ending t from || M.inside_line_ending t until then
    Error Spot.Inside_line_ending
  else Ok (from, until)

(* @verifies findings#{give-start-positions=v1, give-positions-after-spots=v1}
   For every run of generated texts, the test compares the start position and
   the position after each spot with the positions of the boundaries where its
   span starts and ends, as the term position of text=v1 gives them; a wrong
   line number or column for either fails it. *)
let positions_of_spots_are_the_positions_of_their_boundaries =
  property ~name:"a spot has the positions of the boundaries of its span"
    ~print:M.print text_gen (fun t ->
      let tree = one_file t in
      List.for_all
        (fun from ->
          List.for_all
            (fun until ->
              match
                ( Spot.of_run tree a_md { from; until },
                  expected_of_run t from until )
              with
              | Error have, Error want -> have = want
              | Ok spot, Ok (from, until) ->
                  Spot.span spot = Some { Text.from; until }
                  && Spot.start_position spot
                     = Some (to_position (M.position t from))
                  && Spot.position_after spot
                     = Some (to_position (M.position t until))
                  && Text.encode (Path.to_text (Spot.path spot)) = "a.md"
                  && Tree.equal (Spot.tree spot) tree
                  && Option.map M.of_text (Spot.text spot) = Some t
              | _ -> false)
            (bounds t))
        (bounds t))

let line_before_line_ending_at t until =
  if until >= M.body_start t + 1 && Uchar.to_int (List.nth t (until - 1)) = 0x0A
  then
    let ending_start =
      if
        until - 1 >= M.body_start t + 1
        && Uchar.to_int (List.nth t (until - 2)) = 0x0D
      then until - 2
      else until - 1
    in
    List.find_map
      (fun (number, (_, e)) -> if e = ending_start then Some number else None)
      (List.mapi (fun index line -> (index + 1, line)) (M.lines t))
  else None

let position_after_differs_from_the_end_only_after_a_line_ending =
  property
    ~name:
      "the position after a spot is the end of its span, except after a line \
       ending" ~print:M.print text_gen (fun t ->
      let tree = one_file t in
      let lines = Lines.of_text (M.to_text t) in
      List.for_all
        (fun from ->
          List.for_all
            (fun until ->
              match Spot.of_run tree a_md { from; until } with
              | Error _ -> true
              | Ok spot -> (
                  match
                    ( Lines.span lines { from; until },
                      Spot.position_after spot,
                      Spot.start_position spot )
                  with
                  | Ok (start, stop), Some after, Some first -> (
                      first = start
                      &&
                      match line_before_line_ending_at t until with
                      | Some number when until > from ->
                          after = { line = number + 1; column = 1 }
                      | _ -> after = stop)
                  | _ -> false))
            (bounds t))
        (bounds t))

let position_gen t =
  let lines = List.length (M.lines t) in
  Gen.pair (Gen.int_range (-1) (lines + 2)) (Gen.int_range (-1) 6)

let positioned_gen =
  Gen.(
    text_gen >>= fun t ->
    map (fun (s, a) -> (t, s, a)) (pair (position_gen t) (position_gen t)))

let print_positioned (t, (l1, c1), (l2, c2)) =
  Printf.sprintf "%s; %d:%d to %d:%d" (M.print t) l1 c1 l2 c2

(* @verifies findings#{give-start-positions=v1, give-positions-after-spots=v1}
   For generated texts and positions, the spot from one position to another
   must be the spot whose span starts at the boundary of the first position and
   ends at the boundary of the second, as the terms give them; the test fails
   when such a spot gets other positions or a spot is given where none is. *)
let spot_from_one_position_to_another =
  property ~count:1000
    ~name:"of_positions gives the spot from one position to another"
    ~print:print_positioned positioned_gen (fun (t, start, after) ->
      let tree = one_file t in
      let have =
        Spot.of_positions tree a_md (to_position start) (to_position after)
      in
      match
        (M.boundary_of_position t start, M.boundary_of_position t after)
      with
      | None, _ | _, None -> have = Error Spot.No_boundary
      | Some s, Some e when s > e -> have = Error Spot.Reversed
      | Some s, Some e -> (
          match have with
          | Ok spot ->
              Spot.span spot = Some { Text.from = s; until = e }
              && Spot.start_position spot = Some (to_position start)
              && Spot.position_after spot = Some (to_position after)
          | Error _ -> false))

let positions_name_their_spot_again =
  property ~name:"the positions of a spot give that spot again" ~print:M.print
    text_gen (fun t ->
      let tree = one_file t in
      List.for_all
        (fun from ->
          List.for_all
            (fun until ->
              match Spot.of_run tree a_md { from; until } with
              | Error _ -> true
              | Ok spot -> (
                  match
                    (Spot.start_position spot, Spot.position_after spot)
                  with
                  | Some start, Some after -> (
                      match Spot.of_positions tree a_md start after with
                      | Ok again -> Spot.equal again spot
                      | Error _ -> false)
                  | _ -> false))
            (bounds t))
        (bounds t))

(* @verifies findings#omit-positions-without-spans=v1
   A spot without a span, in a file of valid UTF-8 or not, must give no start
   position and no position after it; the test fails when either is given. *)
let spot_without_a_span_has_no_positions =
  property ~name:"a spot without a span has no positions"
    ~print:(fun (t, bad) -> M.print t ^ if bad then " (not UTF-8)" else "")
    (Gen.pair text_gen Gen.bool)
    (fun (t, bad) ->
      let tree =
        tree_of
          [ ("a.md", if bad then M.to_string t ^ "\xff" else M.to_string t) ]
      in
      match Spot.of_file tree a_md with
      | Ok spot ->
          Spot.span spot = None
          && Spot.start_position spot = None
          && Spot.position_after spot = None
          && Spot.start_line spot = None
          && Option.is_some (Spot.text spot) = not bad
      | Error _ -> false)

let start_line_is_the_line_of_the_start =
  property ~name:"start_line is the line of the boundary where the span starts"
    ~print:M.print text_gen (fun t ->
      let tree = one_file t in
      List.for_all
        (fun from ->
          List.for_all
            (fun until ->
              match Spot.of_run tree a_md { from; until } with
              | Error _ -> true
              | Ok spot ->
                  Spot.start_line spot
                  = Option.map
                      (fun (from, until) -> { Text.from; until })
                      (M.line_of_boundary t from))
            (bounds t))
        (bounds t))

let a_file_without_text_has_no_spot_with_a_span () =
  let tree = tree_of [ ("a.md", "a\xffb"); ("b.md", "ab") ] in
  let check name want have =
    Alcotest.(check string)
      name want
      (match have with Ok _ -> "Ok" | Error e -> spot_error e)
  in
  check "of_run on content that is not UTF-8" "Not_utf_8"
    (Spot.of_run tree a_md { from = 0; until = 0 });
  check "of_positions on content that is not UTF-8" "Not_utf_8"
    (Spot.of_positions tree a_md { line = 1; column = 1 }
       { line = 1; column = 1 });
  check "of_file at no file" "No_file" (Spot.of_file tree (path_of "c.md"));
  check "of_run at no file" "No_file"
    (Spot.of_run tree (path_of "c.md") { from = 0; until = 0 });
  check "of_positions at no file" "No_file"
    (Spot.of_positions tree (path_of "c.md") { line = 1; column = 1 }
       { line = 1; column = 1 });
  check "of_run with no file before a run that is not a span" "No_file"
    (Spot.of_run tree (path_of "c.md") { from = 5; until = 1 });
  check "of_positions with no boundary for either" "No_boundary"
    (Spot.of_positions tree (path_of "b.md") { line = 9; column = 1 }
       { line = 1; column = 1 });
  check "of_file on content that is not UTF-8" "Ok" (Spot.of_file tree a_md)

let spot_gen =
  Gen.(
    triple
      (oneof_list [ "x"; "y" ])
      (oneof_list [ "a.md"; "b.md" ])
      (option (pair (int_range 0 2) (int_range 0 2))))

let print_spot (content, name, span) =
  Printf.sprintf "%s %s %s" content name
    (match span with
    | None -> "-"
    | Some (f, u) -> Printf.sprintf "%d to %d" f u)

let build (content, name, span) =
  let tree = tree_of [ ("a.md", content ^ "ab"); ("b.md", "ab") ] in
  match span with
  | None -> Spot.of_file tree (path_of name)
  | Some (from, until) -> Spot.of_run tree (path_of name) { from; until }

let equal_compares_tree_path_and_span =
  property ~count:500
    ~name:"equal compares the trees by content, the paths, and the spans"
    ~print:(fun (a, b) -> print_spot a ^ " / " ^ print_spot b)
    (Gen.pair spot_gen spot_gen)
    (fun (a, b) ->
      match (build a, build b) with
      | Ok x, Ok y ->
          let content_a, name_a, span_a = a and content_b, name_b, span_b = b in
          Bool.equal (Spot.equal x y)
            (content_a = content_b && name_a = name_b && span_a = span_b)
      | _ -> true)

let spots_set = S.read "findings"

let position_json (p : Lines.position) =
  S.object_ [ ("line", S.integer p.line); ("column", S.integer p.column) ]

let give_spot_positions (vector : Sinter_test_vectors.Test_vector_set.vector) =
  let t = S.to_text (S.member "text" vector.input) in
  let tree = tree_of [ ("a.md", Text.encode t) ] in
  let spot =
    match S.member_opt "span" vector.input with
    | None -> Spot.of_file tree a_md
    | Some run ->
        Spot.of_run tree a_md
          {
            from = S.to_int (S.member "from" run);
            until = S.to_int (S.member "to" run);
          }
  in
  match spot with
  | Error error -> Alcotest.failf "no spot: %s" (spot_error error)
  | Ok spot ->
      let given name = Option.map (fun p -> (name, position_json p)) in
      {
        S.result = None;
        values =
          S.object_
            (List.filter_map Fun.id
               [
                 given "start" (Spot.start_position spot);
                 given "after" (Spot.position_after spot);
               ]);
      }

(* @verifies findings[spot-positions][*]=v1
   Each vector gives a text and a span, or no span; the test fails when the
   spot gives a start position or a position after it other than the values,
   or gives one when the values are empty. *)
let spot_position_vectors =
  S.group spots_set ~name:"spot-positions" ~rev:"v1" give_spot_positions

let vector_groups = [ spot_position_vectors ]

let tests =
  S.tests "findings" vector_groups
  @ [
      positions_of_spots_are_the_positions_of_their_boundaries;
      position_after_differs_from_the_end_only_after_a_line_ending;
      spot_from_one_position_to_another;
      positions_name_their_spot_again;
      spot_without_a_span_has_no_positions;
      start_line_is_the_line_of_the_start;
      Alcotest.test_case "a file without a text has no spot with a span" `Quick
        a_file_without_text_has_no_spot_with_a_span;
      equal_compares_tree_path_and_span;
    ]
