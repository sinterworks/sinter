(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_origins
module Gen = QCheck2.Gen

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let pieces =
  [
    "a"; "b"; " "; "\t"; "@"; "\n"; "\r"; "\r\n"; "\xc3\xa9"; "\xf0\x9f\x98\x80";
  ]

let body_gen =
  Gen.map (String.concat "")
    (Gen.list_size (Gen.int_range 0 16) (Gen.oneof_list pieces))

let file_gen =
  Gen.map2
    (fun bom body -> if bom then "\xef\xbb\xbf" ^ body else body)
    Gen.bool body_gen

let run_gen length =
  Gen.map
    (fun (a, b) -> { Text.from = min a b; until = max a b })
    (Gen.pair (Gen.int_range 0 length) (Gen.int_range 0 length))

let any_run_gen length =
  Gen.map
    (fun (a, b) -> { Text.from = a; until = b })
    (Gen.pair
       (Gen.int_range (-1) (length + 1))
       (Gen.int_range (-1) (length + 1)))

let print_run { Text.from; until } = Printf.sprintf "%d-%d" from until
let print_runs runs = String.concat " " (List.map print_run runs)

let file_and_runs_gen =
  Gen.bind file_gen (fun file ->
      let length = Text.length (text_of file) in
      Gen.map
        (fun runs -> (file, runs))
        (Gen.list_size (Gen.int_range 0 5) (run_gen length)))

let print_file_and_runs (file, runs) =
  Printf.sprintf "%S [%s]" file (print_runs runs)

let is_run text { Text.from; until } =
  0 <= from && from <= until && until <= Text.length text

let lf = Uchar.of_int 0x0A

let places source =
  List.init
    (Text.length (Source.text source))
    (fun k -> Source.place source (k + 1))

let joined_places runs =
  let rec go = function
    | [] -> []
    | [ { Text.from; until } ] ->
        List.init (until - from) (fun k -> Some (from + k + 1))
    | { Text.from; until } :: rest ->
        List.init (until - from) (fun k -> Some (from + k + 1))
        @ (None :: go rest)
  in
  go runs

let joined_text text runs =
  let parts =
    List.map
      (fun run ->
        match Text.sub text run with Some t -> t | None -> Text.empty)
      runs
  in
  let rec go = function
    | [] -> []
    | [ part ] -> [ part ]
    | part :: rest -> part :: Text.of_uchars [ lf ] :: go rest
  in
  Text.concat (go parts)

let source_of file = Source.of_file (Lines.of_text (text_of file))

let of_file_gives_each_character_its_place =
  property ~name:"each character of the text of a file comes from its own place"
    ~print:(Printf.sprintf "%S") file_gen (fun file ->
      let text = text_of file in
      let source = source_of file in
      Text.equal (Source.text source) text
      && Text.equal (Lines.text (Source.file source)) text
      && places source = List.init (Text.length text) (fun k -> Some (k + 1))
      && Source.place source 0 = None
      && Source.place source (Text.length text + 1) = None)

let source_and_run_gen =
  Gen.bind file_and_runs_gen (fun (file, runs) ->
      match Source.join (source_of file) runs with
      | None -> Gen.pure (file, runs, { Text.from = 0; until = 0 })
      | Some joined ->
          Gen.map
            (fun run -> (file, runs, run))
            (run_gen (Text.length (Source.text joined))))

let print_source_and_run (file, runs, run) =
  Printf.sprintf "%S [%s] %s" file (print_runs runs) (print_run run)

let joined_of (file, runs) =
  match Source.join (source_of file) runs with
  | Some joined -> joined
  | None -> invalid_arg "joined_of"

let sub_keeps_the_places =
  property ~name:"a run of a source keeps the places of its characters"
    ~print:print_source_and_run source_and_run_gen (fun (file, runs, run) ->
      let joined = joined_of (file, runs) in
      match (Source.sub joined run, Text.sub (Source.text joined) run) with
      | Some sub, Some expected ->
          Text.equal (Source.text sub) expected
          && places sub
             = List.init (run.Text.until - run.Text.from) (fun k ->
                 Source.place joined (run.Text.from + k + 1))
      | _ -> false)

let sub_refuses_what_is_no_run =
  property ~name:"sub gives nothing for a pair of boundaries that is no run"
    ~print:(fun (file, run) -> Printf.sprintf "%S %s" file (print_run run))
    (Gen.bind file_gen (fun file ->
         Gen.map
           (fun run -> (file, run))
           (any_run_gen (Text.length (text_of file)))))
    (fun (file, run) ->
      let source = source_of file in
      Option.is_some (Source.sub source run) = is_run (text_of file) run)

let join_puts_line_feeds_from_no_place =
  property
    ~name:"join gives the runs with a line feed from no place between two"
    ~print:print_file_and_runs file_and_runs_gen (fun (file, runs) ->
      let text = text_of file in
      match Source.join (source_of file) runs with
      | None -> false
      | Some joined ->
          Text.equal (Source.text joined) (joined_text text runs)
          && places joined = joined_places runs
          && Text.equal (Lines.text (Source.file joined)) text)

let join_refuses_what_is_no_run =
  property ~name:"join gives nothing when an element is no run"
    ~print:(fun (file, runs) -> Printf.sprintf "%S [%s]" file (print_runs runs))
    (Gen.bind file_gen (fun file ->
         Gen.map
           (fun runs -> (file, runs))
           (Gen.list_size (Gen.int_range 0 4)
              (any_run_gen (Text.length (text_of file))))))
    (fun (file, runs) ->
      Option.is_some (Source.join (source_of file) runs)
      = List.for_all (is_run (text_of file)) runs)

let places_of_run source { Text.from; until } =
  List.filter_map
    (fun k -> Source.place source (from + k + 1))
    (List.init (until - from) Fun.id)

let expand runs =
  List.concat_map
    (fun { Text.from; until } ->
      List.init (until - from) (fun k -> from + k + 1))
    runs

let rec disjoint_rising = function
  | a :: (b :: _ as rest) ->
      a.Text.from < a.Text.until && a.Text.until < b.Text.from
      && disjoint_rising rest
  | [ a ] -> a.Text.from < a.Text.until
  | [] -> true

let origin_is_the_set_of_places =
  property ~count:1000
    ~name:"the origin of a run is the set of the places of its characters"
    ~print:print_source_and_run source_and_run_gen (fun (file, runs, run) ->
      let joined = joined_of (file, runs) in
      match Source.origin joined run with
      | None -> false
      | Some origin ->
          disjoint_rising origin
          && expand origin = List.sort_uniq compare (places_of_run joined run))

let origin_run_spans_the_origin =
  property ~count:1000
    ~name:"the origin run goes from the least to the greatest place"
    ~print:print_source_and_run source_and_run_gen (fun (file, runs, run) ->
      let joined = joined_of (file, runs) in
      let found = List.sort_uniq compare (places_of_run joined run) in
      match (Source.origin_run joined run, found) with
      | None, [] -> true
      | Some r, (least :: _ as all) ->
          r.Text.from = least - 1
          && r.Text.until = List.nth all (List.length all - 1)
      | _ -> false)

let origin_position_is_that_of_the_least_place =
  property ~count:1000
    ~name:"the origin position is the position of the least place of the origin"
    ~print:print_source_and_run source_and_run_gen (fun (file, runs, run) ->
      let joined = joined_of (file, runs) in
      let lines = Lines.of_text (text_of file) in
      match
        ( Source.origin_position joined run,
          List.sort_uniq compare (places_of_run joined run) )
      with
      | None, [] -> true
      | position, least :: _ -> (
          match Lines.character_position lines least with
          | Ok expected -> position = Some expected
          | Error _ -> position = None)
      | Some _, [] -> false)

let origins_refuse_what_is_no_run () =
  let source = source_of "ab" in
  let bad = { Text.from = 1; until = 3 } in
  Alcotest.(check bool) "no origin" true (Source.origin source bad = None);
  Alcotest.(check bool)
    "no origin run" true
    (Source.origin_run source bad = None);
  Alcotest.(check bool)
    "no origin position" true
    (Source.origin_position source bad = None)

let a_byte_order_mark_has_no_origin_position () =
  let source = source_of "\xef\xbb\xbfab" in
  Alcotest.(check bool)
    "no position" true
    (Source.origin_position source { Text.from = 0; until = 2 } = None);
  Alcotest.(check bool)
    "the next place has one" true
    (Source.origin_position source { Text.from = 1; until = 2 }
    = Some { Lines.line = 1; column = 1 })

let tag_text_runs_gen =
  Gen.bind file_gen (fun file ->
      let text = text_of file in
      let length = Text.length text in
      Gen.map
        (fun cuts ->
          let cuts = List.sort compare cuts in
          let rec pair = function
            | a :: b :: rest -> { Text.from = a; until = b } :: pair rest
            | _ -> []
          in
          (file, pair cuts))
        (Gen.list_size (Gen.int_range 0 8) (Gen.int_range 0 length)))

let holds_lf text run =
  match Text.sub text run with
  | None -> false
  | Some sub ->
      List.exists
        (fun k -> Text.get sub (k + 1) = Some lf)
        (List.init (Text.length sub) Fun.id)

let rec rising = function
  | a :: (b :: _ as rest) -> b.Text.from >= a.Text.until && rising rest
  | _ -> true

let make_refuses_exactly_the_bad_runs =
  property ~count:1000
    ~name:"make refuses a run that is no run, holds a line feed, or goes back"
    ~print:(fun (file, runs) -> Printf.sprintf "%S [%s]" file (print_runs runs))
    (Gen.bind file_gen (fun file ->
         Gen.map
           (fun runs -> (file, runs))
           (Gen.list_size (Gen.int_range 0 4)
              (any_run_gen (Text.length (text_of file))))))
    (fun (file, runs) ->
      let text = text_of file in
      let good =
        List.for_all (is_run text) runs
        && (not (List.exists (holds_lf text) runs))
        && rising runs
      in
      Option.is_some (Tag_text.make (Lines.of_text text) runs) = good)

let without_lf text runs = List.filter (fun run -> not (holds_lf text run)) runs

let tag_text_gen =
  Gen.map
    (fun (file, runs) -> (file, without_lf (text_of file) runs))
    tag_text_runs_gen

let tag_text_of (file, runs) =
  match Tag_text.make (Lines.of_text (text_of file)) runs with
  | Some tag_text -> tag_text
  | None -> invalid_arg "tag_text_of"

let tag_text_joins_its_runs =
  property ~count:1000 ~name:"a tag text is its runs joined by line feeds"
    ~print:print_file_and_runs tag_text_gen (fun (file, runs) ->
      let text = text_of file in
      let tag_text = tag_text_of (file, runs) in
      let source = Tag_text.source tag_text in
      Text.equal (Tag_text.text tag_text) (joined_text text runs)
      && Text.equal (Source.text source) (Tag_text.text tag_text)
      && places source = joined_places runs
      && Tag_text.joined tag_text = runs)

let tag_text_lines_are_the_lines_of_its_text =
  property ~count:1000 ~name:"the lines of a tag text are the lines of its text"
    ~print:print_file_and_runs tag_text_gen (fun (file, runs) ->
      let tag_text = tag_text_of (file, runs) in
      let lines = Lines.of_text (Tag_text.text tag_text) in
      let count = Tag_text.line_count tag_text in
      let expected_count =
        match List.rev runs with
        | last :: _ when last.Text.from = last.Text.until ->
            List.length runs - 1
        | _ -> List.length runs
      in
      let bom_first =
        Text.get (Tag_text.text tag_text) 1 = Some (Uchar.of_int 0xFEFF)
      in
      (bom_first || count = expected_count)
      && count = Lines.count lines
      && List.for_all
           (fun k -> Tag_text.line tag_text k = Lines.line lines k)
           (List.init (count + 2) Fun.id)
      && List.for_all
           (fun k ->
             Tag_text.joined_line tag_text k
             =
             if k >= 1 && k <= count then Some (List.nth runs (k - 1)) else None)
           (List.init (count + 2) Fun.id))

let cr = Uchar.of_int 0x0D
let bom = Uchar.of_int 0xFEFF

let tag_text_lines_come_from_their_runs =
  property ~count:1000
    ~name:
      "a line of a tag text is its run without a closing carriage return or a \
       byte order mark" ~print:print_file_and_runs tag_text_gen
    (fun (file, runs) ->
      let text = text_of file in
      let tag_text = tag_text_of (file, runs) in
      let source = Tag_text.source tag_text in
      let count = Tag_text.line_count tag_text in
      List.for_all
        (fun k ->
          let run = List.nth runs (k - 1) in
          let first = run.Text.from + 1 and last = run.Text.until in
          let first =
            if k = 1 && last >= first && Text.get text first = Some bom then
              first + 1
            else first
          in
          let last =
            if
              k < List.length runs
              && last >= first
              && Text.get text last = Some cr
            then last - 1
            else last
          in
          match Tag_text.line tag_text k with
          | None -> false
          | Some line ->
              places_of_run source line
              = List.init (max 0 (last - first + 1)) (fun i -> first + i))
        (List.init count (fun k -> k + 1)))

let file_lines_of_markdown_lines_are_those_lines =
  property ~name:"the file lines of a markdown file are its markdown lines"
    ~print:(Printf.sprintf "%S") file_gen (fun file ->
      let lines = Documents_reference.markdown_lines (text_of file) in
      File_lines.all (File_lines.of_markdown_lines lines) = lines)

let tag_texts_of_one_file_gen =
  Gen.bind file_gen (fun file ->
      let text = text_of file in
      let length = Text.length text in
      Gen.map
        (fun groups ->
          ( file,
            List.map
              (fun cuts ->
                let cuts = List.sort compare cuts in
                let rec pair = function
                  | a :: b :: rest -> { Text.from = a; until = b } :: pair rest
                  | _ -> []
                in
                without_lf text (pair cuts))
              groups ))
        (Gen.list_size (Gen.int_range 0 3)
           (Gen.list_size (Gen.int_range 0 6) (Gen.int_range 0 length))))

let print_groups (file, groups) =
  Printf.sprintf "%S %s" file (String.concat " | " (List.map print_runs groups))

let order a b =
  match compare a.Text.from b.Text.from with
  | 0 -> compare (a.Text.until - a.Text.from) (b.Text.until - b.Text.from)
  | c -> c

let file_lines_of_tag_texts_are_their_runs =
  property ~count:1000
    ~name:"the file lines of a code file are the runs that its tag texts join"
    ~print:print_groups tag_texts_of_one_file_gen (fun (file, groups) ->
      let tag_texts = List.map (fun runs -> tag_text_of (file, runs)) groups in
      let lines = File_lines.of_tag_texts tag_texts in
      let all = File_lines.all lines in
      List.sort order (List.concat groups) = List.sort order all
      && List.sort order all = all
      && List.for_all
           (fun tag_text ->
             List.for_all
               (fun k ->
                 File_lines.of_tag_text_line lines tag_text k
                 = Tag_text.joined_line tag_text k)
               (List.init (Tag_text.line_count tag_text + 2) Fun.id))
           tag_texts)

let overlaps line origin =
  line.Text.from < line.Text.until
  && List.exists
       (fun r -> line.Text.from < r.Text.until && r.Text.from < line.Text.until)
       origin

let file_lines_of_an_origin_have_a_place_of_it =
  property ~count:1000
    ~name:"the file lines of an origin are those with a place of it"
    ~print:print_file_and_runs file_and_runs_gen (fun (file, runs) ->
      let text = text_of file in
      let markdown =
        File_lines.of_markdown_lines (Documents_reference.markdown_lines text)
      in
      let origin =
        match Source.join (source_of file) runs with
        | None -> []
        | Some joined -> (
            match
              Source.origin joined
                { Text.from = 0; until = Text.length (Source.text joined) }
            with
            | Some origin -> origin
            | None -> [])
      in
      File_lines.of_origin markdown origin
      = List.filter (fun line -> overlaps line origin) (File_lines.all markdown))

let markdown_file_line_of_a_tag_text_line () =
  let file = "# A\r\n   @req a=v1\rText.\n" in
  let text = text_of file in
  let markdown =
    File_lines.of_markdown_lines (Documents_reference.markdown_lines text)
  in
  let tag_text =
    tag_text_of
      (file, [ { Text.from = 8; until = 17 }; { Text.from = 18; until = 23 } ])
  in
  Alcotest.(check bool)
    "the markdown line of line 1" true
    (File_lines.of_tag_text_line markdown tag_text 1
    = Some { Text.from = 5; until = 17 });
  Alcotest.(check bool)
    "the markdown line of line 2" true
    (File_lines.of_tag_text_line markdown tag_text 2
    = Some { Text.from = 18; until = 23 });
  Alcotest.(check bool)
    "no line 3" true
    (File_lines.of_tag_text_line markdown tag_text 3 = None)

let no_file_line_for_a_line_of_another_tag_text () =
  let file = "// a\n// b\n" in
  let mine = tag_text_of (file, [ { Text.from = 2; until = 4 } ]) in
  let other = tag_text_of (file, [ { Text.from = 7; until = 9 } ]) in
  let code = File_lines.of_tag_texts [ mine ] in
  Alcotest.(check bool)
    "no file line of code" true
    (File_lines.of_tag_text_line code other 1 = None);
  Alcotest.(check bool)
    "the file line of its own line" true
    (File_lines.of_tag_text_line code mine 1 = Some { Text.from = 2; until = 4 })

let no_markdown_line_before_the_first_one () =
  let file = "\xef\xbb\xbfab" in
  let markdown =
    File_lines.of_markdown_lines
      (Documents_reference.markdown_lines (text_of file))
  in
  let tag_text = tag_text_of (file, [ { Text.from = 0; until = 2 } ]) in
  Alcotest.(check bool)
    "no markdown line holds the run" true
    (File_lines.of_tag_text_line markdown tag_text 1 = None)

let an_empty_run_of_an_origin_has_no_file_line () =
  let file = "ab\ncd\n" in
  let markdown =
    File_lines.of_markdown_lines
      (Documents_reference.markdown_lines (text_of file))
  in
  Alcotest.(check bool)
    "no file line" true
    (File_lines.of_origin markdown [ { Text.from = 1; until = 1 } ] = [])

let blank_lines_have_only_spaces_and_tabs =
  property ~name:"a text is blank when it has only spaces and tabs"
    ~print:(Printf.sprintf "%S") body_gen (fun body ->
      let text = text_of body in
      File_lines.is_blank text
      = Documents_reference.is_blank text
          { Text.from = 0; until = Text.length text })

let tests =
  [
    of_file_gives_each_character_its_place;
    sub_keeps_the_places;
    sub_refuses_what_is_no_run;
    join_puts_line_feeds_from_no_place;
    join_refuses_what_is_no_run;
    origin_is_the_set_of_places;
    origin_run_spans_the_origin;
    origin_position_is_that_of_the_least_place;
    Alcotest.test_case "origins of a pair that is no run are nothing" `Quick
      origins_refuse_what_is_no_run;
    Alcotest.test_case "a byte order mark has no origin position" `Quick
      a_byte_order_mark_has_no_origin_position;
    make_refuses_exactly_the_bad_runs;
    tag_text_joins_its_runs;
    tag_text_lines_are_the_lines_of_its_text;
    tag_text_lines_come_from_their_runs;
    file_lines_of_markdown_lines_are_those_lines;
    file_lines_of_tag_texts_are_their_runs;
    file_lines_of_an_origin_have_a_place_of_it;
    Alcotest.test_case "the file line of a line of a markdown tag text" `Quick
      markdown_file_line_of_a_tag_text_line;
    blank_lines_have_only_spaces_and_tabs;
    Alcotest.test_case "a line of another tag text has no file line of code"
      `Quick no_file_line_for_a_line_of_another_tag_text;
    Alcotest.test_case "a run before the first markdown line has no file line"
      `Quick no_markdown_line_before_the_first_one;
    Alcotest.test_case "an empty run of an origin has no file line" `Quick
      an_empty_run_of_an_origin_has_no_file_line;
  ]
