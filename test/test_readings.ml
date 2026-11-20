(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_readings
module Gen = QCheck2.Gen

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let lines_of string =
  match Text.decode string with
  | Ok text -> Lines.of_text text
  | Error _ -> invalid_arg "lines_of"

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let run from until = { Text.from; until }

let node ?comment ?body ?(decoration = false) ?test r =
  { Reading.run = r; comment; body; decoration; test }

let name = [ [ Reading.Text_piece (text_of "t") ] ]
let print_run { Text.from; until } = Printf.sprintf "%d-%d" from until

let print_node (n : Reading.node) =
  Printf.sprintf "%s%s%s%s%s" (print_run n.run)
    (match n.comment with
    | Some Reading.Tagged -> " tagged"
    | Some Reading.Untagged -> " untagged"
    | None -> "")
    (match n.body with
    | Some runs -> " body [" ^ String.concat "," (List.map print_run runs) ^ "]"
    | None -> "")
    (if n.decoration then " decoration" else "")
    (match n.test with
    | Some path -> Printf.sprintf " test of %d names" (List.length path)
    | None -> "")

let print_error = function
  | Reading.Not_a_run { node } -> Printf.sprintf "Not_a_run %d" node
  | Reading.Not_nested { node } -> Printf.sprintf "Not_nested %d" node
  | Reading.Body_not_a_run { node; body } ->
      Printf.sprintf "Body_not_a_run %d %d" node body
  | Reading.Body_not_nested { node; body } ->
      Printf.sprintf "Body_not_nested %d %d" node body
  | Reading.No_body_node { node } -> Printf.sprintf "No_body_node %d" node
  | Reading.No_own_name { node } -> Printf.sprintf "No_own_name %d" node

let check_result lines nodes =
  match Reading.check lines nodes with
  | Ok _ -> "ok"
  | Error error -> print_error error

let expect_error source nodes expected () =
  Alcotest.(check string)
    "the error" expected
    (check_result (lines_of source) nodes)

let a_reading_keeps_its_lines_and_nodes () =
  let lines = lines_of "// a\nfn f() {}\n" in
  let nodes =
    [
      node ~comment:Reading.Tagged (run 0 4);
      node ~body:[ run 13 15 ] ~test:name ~decoration:true (run 5 15);
      node ~comment:Reading.Untagged ~decoration:true (run 15 15);
    ]
  in
  match Reading.check lines nodes with
  | Ok reading ->
      Alcotest.(check bool) "the nodes" true (Reading.nodes reading = nodes);
      Alcotest.(check bool)
        "the text" true
        (Text.equal (Lines.text (Reading.lines reading)) (Lines.text lines))
  | Error error -> Alcotest.fail (print_error error)

let bom = "\xef\xbb\xbf// a\n"

(* @verifies packs#{give-reading-nodes=v1, give-reading-node-values=v1}
   A reading with the result "parsed" gives nodes whose runs and body-node runs
   lie in the body of the text and obey the nesting of parse-tree and node-run,
   at least one body node for each definition node, and a name path with at
   least one own name for each test node. Each case checks one condition or
   boundary shape and checks that Reading.check reports the lowest node number,
   the first failed check, and the lowest body-node number. *)
let simple_cases =
  [
    ( "a run that ends after the last boundary",
      "// a\n",
      [ node ~comment:Reading.Tagged (run 0 6) ],
      "Not_a_run 1" );
    ( "a run that ends before it starts",
      "// a\n",
      [ node ~comment:Reading.Tagged (run 3 2) ],
      "Not_a_run 1" );
    ( "a run that starts before boundary 0",
      "// a\n",
      [ node ~decoration:true (run (-1) 2) ],
      "Not_a_run 1" );
    ( "a run that starts before the body of a text with a byte order mark",
      bom,
      [ node ~comment:Reading.Tagged (run 0 5) ],
      "Not_a_run 1" );
    ( "a run that starts at the body of a text with a byte order mark",
      bom,
      [ node ~comment:Reading.Tagged (run 1 5) ],
      "ok" );
    ( "an empty run at the last boundary",
      "// a\n",
      [ node ~body:[ run 5 5 ] (run 5 5) ],
      "ok" );
    ( "a node that starts before an earlier node",
      "0123456789",
      [ node ~decoration:true (run 5 8); node ~decoration:true (run 0 3) ],
      "Not_nested 2" );
    ( "a parent after its child",
      "0123456789",
      [ node ~decoration:true (run 2 4); node ~decoration:true (run 0 8) ],
      "Not_nested 2" );
    ( "a node that starts before an earlier empty node",
      "0123456789",
      [ node ~decoration:true (run 5 5); node ~decoration:true (run 2 3) ],
      "Not_nested 2" );
    ( "a sibling that starts before an earlier sibling inside one ancestor",
      "0123456789",
      [
        node ~decoration:true (run 0 10);
        node ~decoration:true (run 5 8);
        node ~decoration:true (run 2 4);
      ],
      "Not_nested 3" );
    ( "a node that starts before an earlier empty child",
      "0123456789",
      [
        node ~decoration:true (run 0 10);
        node ~decoration:true (run 5 5);
        node ~decoration:true (run 3 4);
      ],
      "Not_nested 3" );
    ( "a node that repeats its parent after an empty child at the end",
      "0123456789",
      [
        node ~decoration:true (run 2 8);
        node ~decoration:true (run 8 8);
        node ~decoration:true (run 2 8);
      ],
      "Not_nested 3" );
    ( "a node that crosses an earlier node",
      "0123456789",
      [ node ~decoration:true (run 0 5); node ~decoration:true (run 3 8) ],
      "Not_nested 2" );
    ( "a longer node after a shorter node at one start boundary",
      "0123456789",
      [ node ~decoration:true (run 0 2); node ~decoration:true (run 0 9) ],
      "Not_nested 2" );
    ( "a node that crosses an ancestor after an earlier sibling ends",
      "0123456789ab",
      [
        node ~decoration:true (run 0 10);
        node ~decoration:true (run 2 5);
        node ~decoration:true (run 6 12);
      ],
      "Not_nested 3" );
    ( "a node that crosses a middle ancestor while inside the outer ancestor",
      "0123456789",
      [
        node ~decoration:true (run 0 10);
        node ~decoration:true (run 1 8);
        node ~decoration:true (run 2 5);
        node ~decoration:true (run 6 9);
      ],
      "Not_nested 4" );
    ( "a node that crosses the outer ancestor after two inner levels end",
      "0123456789ab",
      [
        node ~decoration:true (run 0 10);
        node ~decoration:true (run 1 8);
        node ~decoration:true (run 2 5);
        node ~decoration:true (run 9 12);
      ],
      "Not_nested 4" );
    ( "a node that crosses an ancestor after an empty sibling",
      "0123456789ab",
      [
        node ~decoration:true (run 0 10);
        node ~decoration:true (run 2 5);
        node ~decoration:true (run 5 5);
        node ~decoration:true (run 6 12);
      ],
      "Not_nested 4" );
    ( "a node with no role obeys parse-tree order",
      "0123456789",
      [ node (run 0 5); node (run 3 8) ],
      "Not_nested 2" );
    ( "two nodes with one run",
      "0123456789",
      [ node ~decoration:true (run 0 5); node ~decoration:true (run 0 5) ],
      "ok" );
    ( "two empty nodes at one boundary",
      "0123456789",
      [ node ~decoration:true (run 3 3); node ~decoration:true (run 3 3) ],
      "ok" );
    ( "an empty node before a non-empty node at one start boundary",
      "0123456789",
      [ node ~decoration:true (run 2 2); node ~decoration:true (run 2 5) ],
      "ok" );
    ( "an empty child at the start of its parent before a child with the run \
       of the parent",
      "0123456789",
      [
        node ~decoration:true (run 2 8);
        node ~decoration:true (run 2 2);
        node ~decoration:true (run 2 8);
      ],
      "ok" );
    ( "an empty node at the end boundary of an enclosing node",
      "0123456789",
      [ node ~decoration:true (run 2 5); node ~decoration:true (run 5 5) ],
      "ok" );
    ( "an empty child at the end of its parent before the next sibling",
      "0123456789",
      [
        node ~decoration:true (run 0 5);
        node ~decoration:true (run 5 5);
        node ~decoration:true (run 5 9);
      ],
      "ok" );
    ( "siblings that meet at one boundary after nested descendants",
      "0123456789ab",
      [
        node ~decoration:true (run 0 10);
        node ~decoration:true (run 1 8);
        node ~decoration:true (run 2 5);
        node ~decoration:true (run 8 10);
        node ~decoration:true (run 10 12);
      ],
      "ok" );
    ( "a body run that is no run of the text",
      "fn f() {}",
      [ node ~body:[ run 7 9; run 7 10 ] (run 0 9) ],
      "Body_not_a_run 1 2" );
    ( "a body run before the body of a text with a byte order mark",
      "\xef\xbb\xbffn f() {}",
      [ node ~body:[ run 0 3 ] (run 1 10) ],
      "Body_not_a_run 1 1" );
    ( "a body node that starts before an earlier body node",
      "0123456789",
      [ node ~body:[ run 5 8; run 0 3 ] (run 0 9) ],
      "Body_not_nested 1 2" );
    ( "a body node that crosses an earlier body node",
      "0123456789",
      [ node ~body:[ run 0 5; run 3 8 ] (run 0 9) ],
      "Body_not_nested 1 2" );
    ( "a longer body node after a shorter body node at one start boundary",
      "0123456789",
      [ node ~body:[ run 0 3; run 0 8 ] (run 0 9) ],
      "Body_not_nested 1 2" );
    ( "a body node that crosses an ancestor body node",
      "0123456789",
      [ node ~body:[ run 0 8; run 1 3; run 4 9 ] (run 0 9) ],
      "Body_not_nested 1 3" );
    ( "nested and adjacent body nodes in parse-tree order",
      "0123456789",
      [ node ~body:[ run 0 8; run 0 0; run 0 4; run 4 8; run 8 8 ] (run 0 9) ],
      "ok" );
    ( "two definition nodes check their body lists separately",
      "0123456789",
      [ node ~body:[ run 5 8 ] (run 0 5); node ~body:[ run 0 3 ] (run 5 9) ],
      "ok" );
    ( "a body run outside the run of its definition node",
      "x; fn f() {}",
      [ node ~body:[ run 0 2 ] (run 3 12) ],
      "ok" );
    ( "a definition node with no body node",
      "fn f() {}",
      [ node ~body:[] (run 0 9) ],
      "No_body_node 1" );
    ( "a test node whose name path has no own name",
      "it()",
      [ node ~test:[] (run 0 4) ],
      "No_own_name 1" );
    ( "a test node whose own name has no piece",
      "it()",
      [ node ~test:[ [] ] (run 0 4) ],
      "ok" );
    ( "the node of the lowest number that fails",
      "fn f() {}",
      [
        node ~decoration:true (run 0 2);
        node ~test:[] (run 3 9);
        node ~body:[] (run 3 9);
      ],
      "No_own_name 2" );
    ( "the first check that a node fails",
      "fn f() {}",
      [ node ~body:[ run 0 99 ] ~test:[] (run 0 99) ],
      "Not_a_run 1" );
    ( "the run check comes before the nesting check",
      "0123456789",
      [ node ~decoration:true (run 2 5); node ~decoration:true (run 0 99) ],
      "Not_a_run 2" );
    ( "the nesting check comes before the empty body check",
      "0123456789",
      [ node ~decoration:true (run 0 5); node ~body:[] (run 3 8) ],
      "Not_nested 2" );
    ( "the nesting check comes before the body run check",
      "0123456789",
      [ node ~decoration:true (run 0 5); node ~body:[ run 0 99 ] (run 3 8) ],
      "Not_nested 2" );
    ( "the nesting check comes before the test name check",
      "0123456789",
      [ node ~decoration:true (run 0 5); node ~test:[] (run 3 8) ],
      "Not_nested 2" );
    ( "an earlier node error comes before a later nesting error",
      "0123456789",
      [ node ~test:[] (run 0 5); node ~decoration:true (run 3 8) ],
      "No_own_name 1" );
    ( "the body check before the name check",
      "fn f() {}",
      [ node ~body:[ run 0 99 ] ~test:[] (run 0 9) ],
      "Body_not_a_run 1 1" );
    ( "the body node of the lowest number that fails",
      "fn f() {}",
      [ node ~body:[ run 0 2; run 5 99; run 0 99 ] (run 0 9) ],
      "Body_not_a_run 1 2" );
    ( "the body run check comes before the body nesting check for one body node",
      "0123456789",
      [ node ~body:[ run 2 5; run 0 99 ] (run 0 9) ],
      "Body_not_a_run 1 2" );
    ( "an earlier body nesting error comes before a later body run error",
      "0123456789",
      [ node ~body:[ run 0 5; run 3 8; run 0 99 ] (run 0 9) ],
      "Body_not_nested 1 2" );
  ]

let fails text r =
  let length = Text.length text and start = (Text.body text).Text.from in
  not
    (start <= r.Text.from
    && r.Text.from <= r.Text.until
    && r.Text.until <= length)

let nests_or_follows (a : Text.run) (b : Text.run) =
  (a.from <= b.from && b.until <= a.until) || a.until <= b.from

let first_body_failure text k runs =
  let rec go j earlier = function
    | [] -> None
    | r :: rest ->
        if fails text r then Some (Printf.sprintf "Body_not_a_run %d %d" k j)
        else if not (List.for_all (fun a -> nests_or_follows a r) earlier) then
          Some (Printf.sprintf "Body_not_nested %d %d" k j)
        else go (j + 1) (r :: earlier) rest
  in
  go 1 [] runs

let first_failure text nodes =
  let rec find k earlier = function
    | [] -> "ok"
    | (n : Reading.node) :: rest -> (
        if fails text n.run then Printf.sprintf "Not_a_run %d" k
        else if not (List.for_all (fun a -> nests_or_follows a n.run) earlier)
        then Printf.sprintf "Not_nested %d" k
        else
          let body_error =
            match n.body with
            | None -> None
            | Some [] -> Some (Printf.sprintf "No_body_node %d" k)
            | Some runs -> first_body_failure text k runs
          in
          match body_error with
          | Some error -> error
          | None -> (
              match n.test with
              | Some [] -> Printf.sprintf "No_own_name %d" k
              | _ -> find (k + 1) (n.run :: earlier) rest))
  in
  find 1 [] nodes

let sources =
  [ ""; "a"; "// a\n"; "\xef\xbb\xbf/* \xc3\xa9 */\r\nx"; "a\r\rb\n\n" ]

let any_run_gen length =
  Gen.map
    (fun (a, b) -> { Text.from = a; until = b })
    (Gen.pair
       (Gen.int_range (-2) (length + 2))
       (Gen.int_range (-2) (length + 2)))

let body_run_gen start length =
  Gen.map
    (fun (a, b) -> { Text.from = min a b; until = max a b })
    (Gen.pair (Gen.int_range start length) (Gen.int_range start length))

let node_gen run_gen =
  Gen.map
    (fun ((r, comment), (body, (decoration, test))) ->
      { Reading.run = r; comment; body; decoration; test })
    (Gen.pair
       (Gen.pair run_gen
          (Gen.option (Gen.oneof_list [ Reading.Tagged; Reading.Untagged ])))
       (Gen.pair
          (Gen.option (Gen.list_size (Gen.int_range 0 4) run_gen))
          (Gen.pair Gen.bool
             (Gen.option
                (Gen.list_size (Gen.int_range 0 2)
                   (Gen.list_size (Gen.int_range 0 2)
                      (Gen.oneof_list
                         [
                           Reading.Text_piece (text_of "a");
                           Reading.Placeholder (text_of "${n}");
                         ])))))))

let case_gen =
  Gen.bind (Gen.oneof_list sources) (fun source ->
      let text = text_of source in
      let length = Text.length text and start = (Text.body text).Text.from in
      let run_gen =
        Gen.oneof_weighted
          [ (1, any_run_gen length); (3, body_run_gen start length) ]
      in
      Gen.map
        (fun nodes -> (source, nodes))
        (Gen.list_size (Gen.int_range 0 8) (node_gen run_gen)))

let print_case (source, nodes) =
  Printf.sprintf "%S\n%s" source
    (String.concat "\n" (List.map print_node nodes))

(* @verifies packs#{give-reading-nodes=v1, give-reading-node-values=v1}
   For generated readings, Reading.check accepts a node list when and only when
   each run lies in the body of the text, the node runs and each body-node list
   obey the nesting of parse-tree and node-run, and the definition and test
   checks pass. A stack check that misses an ancestor crossing or reports
   another node or body number disagrees with the direct pairwise model of
   node-run. *)
let check_is_total_and_exact =
  property ~count:3000 ~name:"check gives each reading the result of its checks"
    ~print:print_case case_gen (fun (source, nodes) ->
      let lines = lines_of source in
      let expected = first_failure (Lines.text lines) nodes in
      match Reading.check lines nodes with
      | Ok reading -> expected = "ok" && Reading.nodes reading = nodes
      | Error error -> print_error error = expected)

let with_small_stack run =
  let before = Gc.get () in
  Gc.set { before with stack_limit = 1 lsl 16 };
  Fun.protect ~finally:(fun () -> Gc.set before) run

let nested_runs count =
  let rec go acc k =
    if k < 0 then acc else go (run k ((2 * count) - k) :: acc) (k - 1)
  in
  go [ run (2 * count) (2 * count) ] (count - 1)

let nested_nodes count =
  let rec go acc = function
    | [] -> acc
    | r :: rest -> go (node ~decoration:true r :: acc) rest
  in
  List.rev (go [] (nested_runs count))

let check_nested_input count =
  let lines = lines_of (String.make (2 * count) 'a') in
  (lines, nested_nodes count)

let check_nested_body_input count =
  let lines = lines_of (String.make (2 * count) 'a') in
  (lines, [ node ~body:(nested_runs count) (run 0 (2 * count)) ])

let check_ok (lines, nodes) =
  match Reading.check lines nodes with
  | Ok reading -> reading
  | Error error -> Alcotest.fail (print_error error)

let check_grows_linearly_in_nodes () =
  Counted_work.check_growth ~margin:1.5 ~sizes:(1_000, 16_000)
    ~input:check_nested_input check_ok;
  Timed_work.check_growth ~margin:3. ~runs:3 ~sizes:(25_000, 200_000)
    ~input:check_nested_input check_ok

let check_grows_linearly_in_body_nodes () =
  Counted_work.check_growth ~margin:1.5 ~sizes:(1_000, 16_000)
    ~input:check_nested_body_input check_ok;
  Timed_work.check_growth ~margin:3. ~runs:3 ~sizes:(25_000, 200_000)
    ~input:check_nested_body_input check_ok

let check_keeps_constant_stack_depth () =
  let depth = 200_000 in
  let lines, nodes = check_nested_input depth in
  let body_lines, body_nodes = check_nested_body_input depth in
  with_small_stack (fun () ->
      ignore (check_ok (lines, nodes));
      ignore (check_ok (body_lines, body_nodes)))

let tests =
  Alcotest.test_case "a checked reading keeps its lines and its nodes" `Quick
    a_reading_keeps_its_lines_and_nodes
  :: check_is_total_and_exact
  :: Alcotest.test_case "check grows linearly in the number of nested nodes"
       `Quick check_grows_linearly_in_nodes
  :: Alcotest.test_case
       "check grows linearly in the number of nested body nodes" `Quick
       check_grows_linearly_in_body_nodes
  :: Alcotest.test_case "check keeps constant stack depth on nested nodes"
       `Quick check_keeps_constant_stack_depth
  :: List.map
       (fun (name, source, nodes, expected) ->
         Alcotest.test_case name `Quick (expect_error source nodes expected))
       simple_cases
