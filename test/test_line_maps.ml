(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen
module Line_map = Sinter_line_maps.Line_map
module Model = Changes_model

let set = Vectors.read "changes"

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let old_lines map =
  let rec go i acc =
    match Line_map.old_line map i with
    | Some line -> go (i + 1) (Text.encode line :: acc)
    | None -> List.rev acc
  in
  go 1 []

let new_lines map =
  let rec go j acc =
    match Line_map.new_line map j with
    | Some line -> go (j + 1) (Text.encode line :: acc)
    | None -> List.rev acc
  in
  go 1 []

let map_of_new_line_numbers map =
  List.filter_map
    (fun i -> Option.map (fun j -> (i, j)) (Line_map.new_line_number map i))
    (List.init (List.length (old_lines map)) (fun k -> k + 1))

let model_hunk (hunk : Line_map.hunk) =
  {
    Model.old_start = hunk.old_start;
    removed = hunk.removed;
    new_start = hunk.new_start;
    added = hunk.added;
  }

let hunk_json (hunk : Line_map.hunk) =
  `Assoc
    [
      ("added", `Int hunk.added);
      ("new-start", `Int hunk.new_start);
      ("old-start", `Int hunk.old_start);
      ("removed", `Int hunk.removed);
    ]

let sum field hunks = List.fold_left (fun total h -> total + field h) 0 hunks

let give_hunks (vector : Vectors.vector) =
  let content name =
    Option.map Model.bytes_of_json (member name vector.input)
  in
  let map = Line_map.compute (content "old") (content "new") in
  let hunks = Line_map.hunks map in
  let one_map =
    match vector.values with
    | Some values -> Option.is_some (member "hunks" values)
    | None -> false
  in
  `Assoc
    [
      ( "values",
        `Assoc
          ([
             ("added", `Int (sum (fun (h : Line_map.hunk) -> h.added) hunks));
             ("removed", `Int (sum (fun (h : Line_map.hunk) -> h.removed) hunks));
           ]
          @
          if one_map then
            [
              ("hunks", `List (List.map hunk_json hunks));
              ( "map",
                `List
                  (List.map
                     (fun (i, j) -> `List [ `Int i; `Int j ])
                     (map_of_new_line_numbers map)) );
            ]
          else []) );
    ]

(* @verifies changes[hunks][*]=v1
   For each pair of contents, the test compares the lines that the hunks remove
   and add together, and, where the line map is the only one, each hunk and the
   new line number of each old line; a wrong map or a wrong hunk changes one of
   them. *)
let hunk_vectors = Vectors.group set ~name:"hunks" ~rev:"v1" give_hunks

let print_pair (old_content, new_content) =
  Printf.sprintf "old: %s, new: %s"
    (Model.print_content old_content)
    (Model.print_content new_content)

let property ?(count = 1000) ~name generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print:print_pair generator check)

let contents_gen = Gen.pair Model.content_gen Model.content_gen
let texts content = Option.value ~default:[] (Model.line_texts content)

let is_a_line_map ~search old_content new_content pairs =
  let o = texts old_content and n = texts new_content in
  Model.is_map o n pairs
  && List.length pairs
     =
     if search then Model.longest_by_search o n else Model.longest_by_table o n

let lines_of_hunks_hold old_content new_content map =
  let o = Array.of_list (texts old_content) in
  let n = Array.of_list (texts new_content) in
  List.for_all
    (fun (hunk : Line_map.hunk) ->
      List.for_all
        (fun k ->
          let i = hunk.old_start + k in
          Option.map Text.encode (Line_map.old_line map i) = Some o.(i - 1))
        (List.init hunk.removed Fun.id)
      && List.for_all
           (fun k ->
             let j = hunk.new_start + k in
             Option.map Text.encode (Line_map.new_line map j) = Some n.(j - 1))
           (List.init hunk.added Fun.id))
    (Line_map.hunks map)

(* @verifies changes#give-hunks=v1
   The pairs must be a map of equal lines in the same order with no longer map
   by a search of every map, the hunks must be those that the term gives for
   it, and the lines of each hunk the old and new lines at its starts; a
   shorter map, a wrong start or count, or a missing hunk with no line fails. *)
let hunks_follow_a_line_map =
  property ~name:"the hunks are the hunks of a line map" contents_gen
    (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      let pairs = Line_map.pairs map in
      is_a_line_map ~search:true old_content new_content pairs
      && List.map model_hunk (Line_map.hunks map)
         = Model.hunks ~old_content ~new_content pairs
      && lines_of_hunks_hold old_content new_content map)

(* @verifies changes#give-new-line-numbers=v1
   Each old line must get the new line number of its pair in a line map, and
   no number when no pair holds it; a number for a removed line, a wrong
   number, or a map that is not longest fails. *)
let new_line_numbers_follow_a_line_map =
  property ~name:"the new line numbers are those of a line map" contents_gen
    (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      let pairs = map_of_new_line_numbers map in
      is_a_line_map ~search:true old_content new_content pairs
      && List.for_all
           (fun i -> Line_map.new_line_number map i = List.assoc_opt i pairs)
           (List.init (List.length (texts old_content)) (fun k -> k + 1)))

(* @verifies changes#use-one-line-map=v1
   The hunks must be the hunks that the term gives for the map that the new
   line numbers show, and the pairs must be that map; hunks of one map with
   line numbers of another map fail. *)
let hunks_and_line_numbers_share_one_map =
  property ~name:"the hunks and the new line numbers come from one line map"
    contents_gen (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      let shown = map_of_new_line_numbers map in
      shown = Line_map.pairs map
      && List.map model_hunk (Line_map.hunks map)
         = Model.hunks ~old_content ~new_content shown)

let repeats_gen =
  let line = Gen.oneof_list [ "a"; "b"; "c"; "" ] in
  let content =
    Gen.map
      (fun lines ->
        Some (String.concat "" (List.map (fun l -> l ^ "\n") lines)))
      (Gen.list_size (Gen.int_range 0 60) line)
  in
  Gen.pair content content

let longest_on_longer_texts =
  property ~count:300
    ~name:"the pairs are a longest map on texts of up to 60 repeated lines"
    repeats_gen (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      is_a_line_map ~search:false old_content new_content (Line_map.pairs map))

let apply map =
  let old_a = Array.of_list (old_lines map) in
  let hunks = Line_map.hunks map in
  let rec go i hunks acc =
    match hunks with
    | (h : Line_map.hunk) :: rest when h.old_start = i ->
        let added =
          List.init h.added (fun k ->
              match Line_map.new_line map (h.new_start + k) with
              | Some line -> Text.encode line
              | None -> Alcotest.fail "a hunk adds a line that is not there")
        in
        go (i + h.removed) rest (List.rev_append added acc)
    | _ ->
        if i > Array.length old_a then List.rev acc
        else go (i + 1) hunks (old_a.(i - 1) :: acc)
  in
  go 1 hunks []

let hunks_give_the_new_lines =
  property ~name:"the old lines with the hunks applied are the new lines"
    contents_gen (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      apply map = texts new_content && new_lines map = texts new_content)

let counts_are_those_of_every_line_map =
  property ~name:"the hunks remove m less the pairs and add n less the pairs"
    contents_gen (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      let hunks = Line_map.hunks map in
      let o = texts old_content and n = texts new_content in
      let l = Model.longest_by_search o n in
      sum (fun (h : Line_map.hunk) -> h.removed) hunks = List.length o - l
      && sum (fun (h : Line_map.hunk) -> h.added) hunks = List.length n - l)

let pairs_rise =
  property ~name:"the pairs rise in both numbers" contents_gen
    (fun (old_content, new_content) ->
      let rec rising = function
        | (i, j) :: ((i', j') :: _ as rest) -> i < i' && j < j' && rising rest
        | _ -> true
      in
      rising (Line_map.pairs (Line_map.compute old_content new_content)))

let hunks_rise =
  property ~name:"the hunks come in increasing order of their old starts"
    contents_gen (fun (old_content, new_content) ->
      let rec rising = function
        | (a : Line_map.hunk) :: ((b : Line_map.hunk) :: _ as rest) ->
            a.old_start < b.old_start && rising rest
        | _ -> true
      in
      rising (Line_map.hunks (Line_map.compute old_content new_content)))

let lines_outside_the_texts_are_none =
  property ~name:"no line and no new line number outside the texts" contents_gen
    (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      let m = List.length (texts old_content) in
      let n = List.length (texts new_content) in
      List.for_all
        (fun i ->
          Line_map.old_line map i = None
          && Line_map.new_line_number map i = None)
        [ min_int; -1; 0; m + 1; m + 2; max_int ]
      && List.for_all
           (fun j -> Line_map.new_line map j = None)
           [ min_int; -1; 0; n + 1; max_int ]
      && List.length (old_lines map) = m
      && List.length (new_lines map) = n)

let raw_gen =
  Gen.map
    (fun bytes -> Some bytes)
    (Gen.string_size
       ~gen:
         (Gen.oneof_list
            [
              'a';
              'b';
              '\n';
              '\r';
              '\xef';
              '\xbb';
              '\xbf';
              '\xff';
              '\xc3';
              '\xa9';
              '\x00';
            ])
       (Gen.int_range 0 20))

let compute_takes_any_bytes =
  property ~count:2000 ~name:"compute gives a line map for any bytes"
    (Gen.pair raw_gen raw_gen) (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      is_a_line_map ~search:true old_content new_content (Line_map.pairs map)
      && List.map model_hunk (Line_map.hunks map)
         = Model.hunks ~old_content ~new_content (Line_map.pairs map))

let corrupt_gen =
  Gen.(
    Model.content_gen >>= function
    | None -> return (None, None)
    | Some content ->
        map
          (fun corrupted -> (Some content, Some corrupted))
          (Vector_json.corrupt_gen content))

let compute_takes_corrupted_contents =
  property ~count:2000 ~name:"compute gives a line map for corrupted contents"
    corrupt_gen (fun (old_content, new_content) ->
      let map = Line_map.compute old_content new_content in
      is_a_line_map ~search:true old_content new_content (Line_map.pairs map)
      && List.map model_hunk (Line_map.hunks map)
         = Model.hunks ~old_content ~new_content (Line_map.pairs map))

let numbered prefix count =
  List.init count (fun k -> Printf.sprintf "%s %d\n" prefix k)

(* @verifies changes#give-hunks=v1
   A file of 100,000 distinct lines with ten lines changed has one line map,
   which leaves out exactly those ten lines on each side; a program that limits
   the size, or gives a shorter map, gives other hunks. *)
let hunks_of_a_large_edited_file () =
  let size = 100_000 in
  let edited = List.init 10 (fun k -> (k * 9_973) + 17) in
  let old_lines = numbered "line" size in
  let new_lines =
    List.mapi
      (fun i line ->
        if List.mem i edited then Printf.sprintf "changed %d\n" i else line)
      old_lines
  in
  let map =
    Line_map.compute
      (Some (String.concat "" old_lines))
      (Some (String.concat "" new_lines))
  in
  Alcotest.(check (list (pair int int)))
    "the hunks"
    (List.map (fun i -> (i + 1, i + 1)) edited)
    (List.map
       (fun (h : Line_map.hunk) ->
         Alcotest.(check (pair int int))
           "one line each" (1, 1) (h.removed, h.added);
         (h.old_start, h.new_start))
       (Line_map.hunks map));
  Alcotest.(check int)
    "the pairs" (size - 10)
    (List.length (Line_map.pairs map))

let around_one_common_line prefix =
  let half = 50_000 in
  String.concat ""
    (numbered prefix half @ [ "common\n" ]
    @ List.init half (fun k -> Printf.sprintf "%s %d\n" prefix (half + k)))

(* @verifies changes#give-hunks=v1
   Two files of 100,001 lines that share only their middle line have one line
   map, which pairs the two middle lines; a program that limits the size, or
   gives a shorter map, gives other hunks. *)
let hunks_of_large_files_with_one_common_line () =
  let map =
    Line_map.compute
      (Some (around_one_common_line "old"))
      (Some (around_one_common_line "new"))
  in
  Alcotest.(check (list (pair int int)))
    "the pairs"
    [ (50_001, 50_001) ]
    (Line_map.pairs map);
  Alcotest.(check (list (list int)))
    "the hunks"
    [ [ 1; 50_000; 1; 50_000 ]; [ 50_002; 50_000; 50_002; 50_000 ] ]
    (List.map
       (fun (h : Line_map.hunk) ->
         [ h.old_start; h.removed; h.new_start; h.added ])
       (Line_map.hunks map))

let vector_groups = [ hunk_vectors ]

let tests =
  Vectors.tests "changes" vector_groups
  @ [
      hunks_follow_a_line_map;
      new_line_numbers_follow_a_line_map;
      hunks_and_line_numbers_share_one_map;
      longest_on_longer_texts;
      hunks_give_the_new_lines;
      counts_are_those_of_every_line_map;
      pairs_rise;
      hunks_rise;
      lines_outside_the_texts_are_none;
      compute_takes_any_bytes;
      compute_takes_corrupted_contents;
      Alcotest.test_case "the hunks of a large edited file" `Quick
        hunks_of_a_large_edited_file;
      Alcotest.test_case "the hunks of large files with one common line" `Quick
        hunks_of_large_files_with_one_common_line;
    ]
