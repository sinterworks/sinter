(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_origins
open Sinter_tag_inputs
open Sinter_inline_citations
open Sinter_markdown_tag_texts
open Sinter_code_tag_texts
open Sinter_tree_inputs
module Gen = QCheck2.Gen
module Ints = Set.Make (Int)

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let print_ints list =
  "[" ^ String.concat "; " (List.map string_of_int list) ^ "]"

let ranges_gen =
  Gen.map
    (List.concat_map (fun (first, size) -> List.init size (fun k -> first + k)))
    (Gen.list_size (Gen.int_range 0 5)
       (Gen.pair (Gen.int_range (-3) 30) (Gen.int_range 0 8)))

let ints_gen =
  Gen.oneof
    [ Gen.list_size (Gen.int_range 0 12) (Gen.int_range (-3) 15); ranges_gen ]

let pair_print (a, b) = print_ints a ^ " " ^ print_ints b

let sets_agree =
  property ~count:1000
    ~name:"the operations of line sets are those of sets of numbers"
    ~print:pair_print (Gen.pair ints_gen ints_gen) (fun (a, b) ->
      let sa = Ints.of_list a and sb = Ints.of_list b in
      let la = Line_set.of_list a and lb = Line_set.of_list b in
      let agree set model =
        Line_set.elements set = Ints.elements model
        && Line_set.last set = Ints.max_elt_opt model
      in
      agree la sa
      && agree (Line_set.union [ la; lb; la ]) (Ints.union sa sb)
      && agree (Line_set.union [ la ]) sa
      && agree (Line_set.union []) Ints.empty
      && agree (Line_set.diff la lb) (Ints.diff sa sb)
      && agree (Line_set.diff lb la) (Ints.diff sb sa))

let ranges_are_their_numbers =
  property ~count:500 ~name:"a range has the numbers from its first to its last"
    ~print:(fun (a, b) -> Printf.sprintf "%d %d" a b)
    (Gen.pair (Gen.int_range (-3) 12) (Gen.int_range (-3) 12))
    (fun (first, last) ->
      Line_set.elements (Line_set.range first last)
      = List.filter
          (fun k -> first <= k && k <= last)
          (List.init 20 (fun k -> k - 4)))

let the_empty_set_has_no_element () =
  Alcotest.(check (list int)) "no element" [] (Line_set.elements Line_set.empty);
  Alcotest.(check (option int)) "no last" None (Line_set.last Line_set.empty)

let index_gen =
  Gen.pair
    (Gen.list_size (Gen.int_range 0 7)
       (Gen.pair Gen.bool
          (Gen.list_size (Gen.int_range 0 5) (Gen.int_range 1 6))))
    (Gen.list_size (Gen.int_range 0 3) (Gen.int_range 1 6))

let print_index (sets, thing) =
  String.concat " | "
    (List.map
       (fun (by_runs, set) ->
         (if by_runs then "runs " else "") ^ print_ints set)
       sets)
  ^ " thing " ^ print_ints thing

let runs_of numbers =
  List.fold_left
    (fun runs k ->
      match runs with
      | (first, last) :: rest when k = last + 1 -> (first, k) :: rest
      | _ -> (k, k) :: runs)
    []
    (Ints.elements (Ints.of_list numbers))

let line_set_of (by_runs, numbers) =
  if by_runs then
    Line_set.union
      (List.map
         (fun (first, last) -> Line_set.range first last)
         (runs_of numbers))
  else Line_set.of_list numbers

let naive_holders sets thing =
  List.filter_map
    (fun (k, set) ->
      if Ints.subset (Ints.of_list thing) (Ints.of_list set) then Some k
      else None)
    (List.mapi (fun k set -> (k, set)) sets)

let naive_innermost sets thing =
  let holders = naive_holders sets thing in
  let set k = Ints.of_list (List.nth sets k) in
  match
    List.filter
      (fun k -> List.for_all (fun o -> Ints.subset (set k) (set o)) holders)
      holders
  with
  | [ k ] -> Some k
  | _ -> None

let index_of sets =
  Line_set.Index.make (List.mapi (fun k set -> (k, line_set_of set)) sets)

let the_index_gives_the_holders =
  property ~count:2000 ~name:"the index gives the holders of a thing"
    ~print:print_index index_gen (fun (sets, thing) ->
      Line_set.Index.holders (index_of sets) (Line_set.of_list thing)
      = naive_holders (List.map snd sets) thing)

let the_index_gives_the_innermost_set =
  property ~count:2000 ~name:"the index gives the innermost set of a thing"
    ~print:print_index index_gen (fun (sets, thing) ->
      Line_set.Index.innermost (index_of sets) (Line_set.of_list thing)
      = naive_innermost (List.map snd sets) thing)

let the_index_gives_the_subsets =
  property ~count:2000
    ~name:"the index gives, for each set, the other sets that are its subsets"
    ~print:print_index index_gen (fun (sets, _) ->
      let set k = Ints.of_list (snd (List.nth sets k)) in
      let n = List.length sets in
      let expected =
        List.init n (fun a ->
            ( a,
              List.filter
                (fun b -> a <> b && Ints.subset (set b) (set a))
                (List.init n Fun.id) ))
      in
      Line_set.Index.subsets (index_of sets) = expected)

let position_gen =
  Gen.map2
    (fun line column -> { Lines.line; column })
    (Gen.int_range 1 4) (Gen.int_range 1 4)

let positions_follow_the_term =
  property ~count:1000 ~name:"positions are in the order of the term"
    ~print:(fun ((p : Lines.position), (q : Lines.position)) ->
      Printf.sprintf "%d:%d %d:%d" p.line p.column q.line q.column)
    (Gen.pair position_gen position_gen)
    (fun (p, q) ->
      let before (a : Lines.position) (b : Lines.position) =
        a.line < b.line || (a.line = b.line && a.column < b.column)
      in
      let c = Position_order.compare p q in
      c < 0 = before p q && c > 0 = before q p && c = 0 = (p = q))

let path_text path = Text.encode (Path.to_text path)

let files_of case =
  let _, readables = Tree_gen.read case in
  List.map
    (fun (path, readable) ->
      ( readable,
        Tree_file.make Tree_gen.namespaces (Tree_gen.path_of path) readable ))
    readables

let tag_line_key input =
  match Input.kind input with
  | Input.Tag_line { first_line; last_line; result; _ } ->
      `Tag (first_line, last_line, result, Input.origin_position input)
  | Input.Link { link; _ } ->
      `Link (link.Inline_citation.run, link.result, Input.origin_position input)

let same_inputs a b = List.map tag_line_key a = List.map tag_line_key b

let the_lines_of_a_tree_file_are_its_file_lines =
  property ~count:200 ~name:"a tree file numbers its file lines in their order"
    ~print:Tree_gen.print Tree_gen.case (fun case ->
      List.for_all
        (fun (_, file) ->
          let all = File_lines.all (Tree_file.file_lines file) in
          let text = Lines.text (Tree_file.text file) in
          let n = List.length all in
          let blank =
            Array.of_list
              (List.map
                 (fun run ->
                   Option.fold ~none:true ~some:File_lines.is_blank
                     (Text.sub text run))
                 all)
          in
          let rec last_not_blank k =
            if k < 1 then 0
            else if k > n then last_not_blank n
            else if not blank.(k - 1) then k
            else last_not_blank (k - 1)
          in
          Tree_file.line_count file = n
          && Line_set.elements (Tree_file.all_lines file) = List.init n succ
          && Tree_file.line file 0 = None
          && Tree_file.line file (n + 1) = None
          && List.for_all2
               (fun k run ->
                 Tree_file.line file k = Some run
                 && Tree_file.number file run
                    = Option.map
                        (fun i -> i + 1)
                        (List.find_index (fun r -> r = run) all)
                 && Tree_file.last_not_blank file k = last_not_blank k)
               (List.init n (fun k -> k + 1))
               all
          && Tree_file.number file { Text.from = -1; until = -1 } = None
          && Line_set.elements (Tree_file.numbers file all)
             = Ints.elements
                 (Ints.of_list (List.filter_map (Tree_file.number file) all))
          && List.for_all
               (fun k -> Tree_file.last_not_blank file k = last_not_blank k)
               [ -1; 0; n + 1; n + 5 ])
        (files_of case))

let within_follows_its_promise =
  property ~count:200 ~name:"a tree file gives the file lines within a run"
    ~print:Tree_gen.print Tree_gen.case (fun case ->
      List.for_all
        (fun (_, file) ->
          let all = File_lines.all (Tree_file.file_lines file) in
          let numbered = List.mapi (fun k run -> (k + 1, run)) all in
          let length = Text.length (Lines.text (Tree_file.text file)) in
          let edges =
            List.sort_uniq Int.compare
              (0 :: length
              :: List.concat_map
                   (fun { Text.from; until } ->
                     [ from; until; from + 1; until - 1 ])
                   all)
          in
          let runs =
            List.concat_map
              (fun from ->
                List.filter_map
                  (fun until ->
                    if from <= until then Some { Text.from; until } else None)
                  edges)
              edges
          in
          List.for_all
            (fun (r : Text.run) ->
              Line_set.elements (Tree_file.within file r)
              = List.filter_map
                  (fun (k, (line : Text.run)) ->
                    if line.from >= r.from && line.until <= r.until then Some k
                    else None)
                  numbered)
            runs)
        (files_of case))

let joined tag_text = Tag_text.joined tag_text

let tag_texts_and_inputs_follow_parts_1_and_2 =
  property ~count:200 ~name:"a tree file agrees with the reading of its file"
    ~print:Tree_gen.print Tree_gen.case (fun case ->
      List.for_all
        (fun (readable, file) ->
          let given = Tree_file.tag_texts file in
          let binding = Tree_file.binding file in
          List.for_all
            (fun (t : Tree_file.tag_text) ->
              same_inputs t.inputs (Input.of_tag_text binding t.tag_text))
            given
          &&
          match (readable, Tree_file.content file) with
          | Readable_file.Markdown_file _, Tree_file.Markdown md ->
              let paragraph_of = function
                | Tree_file.Section s -> s.Markdown_file.first_paragraph
                | Tree_file.List_item i -> i.Markdown_file.first_paragraph
                | Tree_file.Comment_run _ -> None
              in
              List.map (fun (t : Tree_file.tag_text) -> joined t.tag_text) given
              = List.map joined (Markdown_file.tag_texts md)
              && List.for_all
                   (fun (t : Tree_file.tag_text) ->
                     match paragraph_of t.holder with
                     | Some p -> joined p.tag_text = joined t.tag_text
                     | None -> false)
                   given
              && same_inputs (Tree_file.links file)
                   (Input.of_links binding (Markdown_file.markdown_text md))
              && not (Tree_file.code_character_before file max_int)
          | Readable_file.Code_file _, Tree_file.Code code ->
              let runs =
                List.filter
                  (fun (r : Code_file.comment_run) -> r.tag_text <> None)
                  (Code_file.comment_runs code)
              in
              List.length runs = List.length given
              && List.for_all2
                   (fun (r : Code_file.comment_run) (t : Tree_file.tag_text) ->
                     (match t.holder with
                       | Tree_file.Comment_run h -> h.run = r.run
                       | _ -> false)
                     && Option.map joined r.tag_text = Some (joined t.tag_text))
                   runs given
              && same_inputs (Tree_file.links file)
                   (List.concat_map
                      (fun (t : Tree_file.tag_text) ->
                        Input.of_links binding (Tag_text.source t.tag_text))
                      given)
              &&
              let length = Text.length (Lines.text (Tree_file.text file)) in
              List.for_all
                (fun b ->
                  Tree_file.code_character_before file b
                  = List.exists
                      (fun p -> Code_file.is_code_character code p)
                      (List.init (max 0 (min b length)) (fun k -> k + 1)))
                (List.init (length + 2) Fun.id)
          | _ -> false)
        (files_of case))

let a_tree_file_keeps_what_it_was_made_with () =
  match
    Tree_gen.read
      { Tree_gen.files = [ ("docs/a.md", "# A\n@design a=v1\n") ]; code = [] }
  with
  | _, [ (path, readable) ] ->
      let file =
        Tree_file.make Tree_gen.namespaces (Tree_gen.path_of path) readable
      in
      Alcotest.(check string)
        "the path" "docs/a.md"
        (path_text (Tree_file.path file));
      Alcotest.(check bool)
        "the binding" true
        (Tree_file.binding file == Tree_gen.namespaces);
      Alcotest.(check int) "two file lines" 2 (Tree_file.line_count file)
  | _ -> Alcotest.fail "one file that can be read"

let one_readable case =
  match Tree_gen.read case with
  | _, [ (path, readable) ] -> (Tree_gen.path_of path, readable)
  | _ -> Alcotest.fail "one file that can be read"

let tree_file_of (path, readable) =
  Tree_file.make Tree_gen.namespaces path readable

let markdown_sections n =
  let buffer = Buffer.create (n * 48) in
  Buffer.add_string buffer "# A\n@design a=v1\n\n";
  for k = 1 to n do
    Printf.bprintf buffer "## R %d\n@req a#r%d=v1\nText [see](#r%d).\n\n" k k k
  done;
  one_readable
    { Tree_gen.files = [ ("docs/a.md", Buffer.contents buffer) ]; code = [] }

let comment_lines n =
  let buffer = Buffer.create (n * 32) in
  let nodes = ref [] in
  for k = 1 to n do
    let from = Buffer.length buffer in
    Printf.bprintf buffer "// @req d#r%d=v1 [see](#r%d)" k k;
    nodes :=
      {
        Code_reference.run = { Text.from; until = Buffer.length buffer };
        comment = Some Code_reference.Tagged;
        body = None;
        decoration = false;
        test = None;
      }
      :: !nodes;
    Buffer.add_char buffer '\n'
  done;
  let from = Buffer.length buffer in
  Buffer.add_string buffer "fn f() {}";
  let until = Buffer.length buffer in
  Buffer.add_char buffer '\n';
  let definition =
    {
      Code_reference.run = { Text.from; until };
      comment = None;
      body = Some [ { Text.from = until - 2; until } ];
      decoration = false;
      test = None;
    }
  in
  one_readable
    {
      Tree_gen.files = [ ("lib/a.rs", Buffer.contents buffer) ];
      code =
        [
          ( "lib/a.rs",
            {
              Tree_gen.sigils =
                { Code_reference.line = [ "//" ]; block = []; inner = [] };
              nodes = List.rev (definition :: !nodes);
            } );
        ];
    }

let a_markdown_file_grows_linearly () =
  let file = tree_file_of (markdown_sections 3) in
  Alcotest.(check int) "its file lines" 15 (Tree_file.line_count file);
  Alcotest.(check int)
    "its tag texts" 4
    (List.length (Tree_file.tag_texts file));
  Alcotest.(check int) "its links" 3 (List.length (Tree_file.links file));
  Counted_work.check_growth ~margin:1.5 ~sizes:(500, 2000)
    ~input:markdown_sections tree_file_of

let a_code_file_grows_linearly () =
  let file = tree_file_of (comment_lines 3) in
  Alcotest.(check int) "its file lines" 3 (Tree_file.line_count file);
  Alcotest.(check int) "its links" 3 (List.length (Tree_file.links file));
  Alcotest.(check bool)
    "its code character at its end" true
    (Tree_file.code_character_before file 200
    && not (Tree_file.code_character_before file 80));
  Counted_work.check_growth ~margin:1.5 ~sizes:(500, 2000) ~input:comment_lines
    tree_file_of

let within_grows_as_its_result () =
  Counted_work.check_growth ~margin:1.5 ~sizes:(500, 2000)
    ~input:(fun n ->
      let file = tree_file_of (comment_lines n) in
      ( file,
        {
          Text.from = 0;
          until = Text.length (Lines.text (Tree_file.text file));
        } ))
    (fun (file, run) -> Tree_file.within file run);
  Time_growth.check ~bound:10. ~size:500
    ~input:(fun n -> tree_file_of (comment_lines n))
    (fun file ->
      List.map (Tree_file.within file)
        (File_lines.all (Tree_file.file_lines file)))

let nested_comments n =
  let buffer = Buffer.create (n * 24) in
  let froms =
    List.init n (fun k ->
        let from = Buffer.length buffer in
        Printf.bprintf buffer "/* @req d#r%d=v1 " (k + 1);
        from)
  in
  let until = Buffer.length buffer in
  Buffer.add_char buffer '\n';
  let ends =
    List.init n (fun _ ->
        Buffer.add_string buffer "x */";
        let at = Buffer.length buffer in
        Buffer.add_char buffer '\n';
        at)
  in
  let node from last =
    {
      Code_reference.run = { Text.from; until = last };
      comment = Some Code_reference.Tagged;
      body = None;
      decoration = false;
      test = None;
    }
  in
  ( until,
    tree_file_of
      (one_readable
         {
           Tree_gen.files = [ ("lib/a.rs", Buffer.contents buffer) ];
           code =
             [
               ( "lib/a.rs",
                 {
                   Tree_gen.sigils =
                     {
                       Code_reference.line = [];
                       block = [ ("/*", "*/") ];
                       inner = [];
                     };
                   nodes = List.map2 node froms (List.rev ends);
                 } );
             ];
         }) )

let within_grows_as_its_runs_over_nested_lines () =
  let until, file = nested_comments 3 in
  Alcotest.(check (list int))
    "the lines within the first line" [ 1 ]
    (Line_set.elements (Tree_file.within file { Text.from = 0; until }));
  Alcotest.(check (list int))
    "no line within a run that ends before them" []
    (Line_set.elements
       (Tree_file.within file { Text.from = 0; until = until - 1 }));
  Counted_work.check_growth ~exponent:0. ~margin:1.5 ~sizes:(50, 200)
    ~input:nested_comments (fun (until, file) ->
      Tree_file.within file { Text.from = 0; until });
  Time_growth.check ~bound:2. ~size:50 ~input:nested_comments
    (Time_growth.repeat 500_000 (fun (until, file) ->
         Tree_file.within file { Text.from = 0; until = until - 1 }))

let alternate n = List.init n (fun k -> 2 * k)

let line_sets_grow_as_their_runs () =
  let sets = Line_set.of_list (alternate 4) in
  Alcotest.(check (list int))
    "a set of single numbers" [ 0; 2; 4; 6 ] (Line_set.elements sets);
  let words = Counted_work.check_growth ~margin:1.5 ~sizes:(1000, 4000) in
  words ~input:alternate Line_set.of_list;
  words ~input:(fun n -> Line_set.of_list (alternate n)) Line_set.elements;
  words ~exponent:0. ~input:Fun.id (fun n -> Line_set.range 1 n);
  words
    ~input:(fun n -> List.map (fun k -> Line_set.range k k) (alternate n))
    Line_set.union;
  words
    ~input:(fun n ->
      ( Line_set.of_list (alternate n),
        Line_set.of_list (List.map succ (alternate n)) ))
    (fun (a, b) -> Line_set.diff a b);
  Time_growth.check ~bound:2.5 ~size:2000
    ~input:(fun n -> Line_set.of_list (alternate n))
    (Time_growth.repeat 100_000 Line_set.last)

let chain n =
  Line_set.Index.make
    (List.init n (fun k -> (k, Line_set.range (k + 1) ((2 * n) - k))))

let an_index_of_nested_sets_grows_as_its_result () =
  let index = chain 3 in
  Alcotest.(check (list int))
    "the holders of the middle" [ 0; 1; 2 ]
    (Line_set.Index.holders index (Line_set.range 3 4));
  Alcotest.(check (option int))
    "the innermost" (Some 2)
    (Line_set.Index.innermost index (Line_set.range 3 4));
  Time_growth.check ~bound:10. ~size:500 ~input:Fun.id chain;
  let middle n = (chain n, Line_set.range n n) in
  Time_growth.check ~bound:10. ~size:500 ~input:middle
    (Time_growth.repeat 10 (fun (index, thing) ->
         Line_set.Index.holders index thing));
  Time_growth.check ~bound:10. ~size:500 ~input:middle
    (Time_growth.repeat 10 (fun (index, thing) ->
         Line_set.Index.innermost index thing));
  Time_growth.check ~bound:40. ~size:100 ~input:chain Line_set.Index.subsets

let tests =
  [
    Alcotest.test_case
      "line sets of four times as many runs take at most the work of their \
       costs"
      `Quick line_sets_grow_as_their_runs;
    Alcotest.test_case
      "an index of four times as many nested sets takes at most the time of \
       its costs"
      `Quick an_index_of_nested_sets_grows_as_its_result;
    Alcotest.test_case
      "a markdown file of four times as many sections takes at most 6 times \
       the work"
      `Quick a_markdown_file_grows_linearly;
    Alcotest.test_case
      "a code file of four times as many comment lines takes at most 6 times \
       the work"
      `Quick a_code_file_grows_linearly;
    Alcotest.test_case
      "within, over four times as many file lines, keeps to its cost" `Quick
      within_grows_as_its_result;
    sets_agree;
    ranges_are_their_numbers;
    Alcotest.test_case
      "within, over four times as many nested file lines, keeps to its cost"
      `Quick within_grows_as_its_runs_over_nested_lines;
    Alcotest.test_case "the empty line set has no element" `Quick
      the_empty_set_has_no_element;
    the_index_gives_the_holders;
    the_index_gives_the_innermost_set;
    the_index_gives_the_subsets;
    positions_follow_the_term;
    the_lines_of_a_tree_file_are_its_file_lines;
    within_follows_its_promise;
    tag_texts_and_inputs_follow_parts_1_and_2;
    Alcotest.test_case "a tree file keeps what it was made with" `Quick
      a_tree_file_keeps_what_it_was_made_with;
  ]
