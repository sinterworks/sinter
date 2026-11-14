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
  | Reading.Body_not_a_run { node; body } ->
      Printf.sprintf "Body_not_a_run %d %d" node body
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
    ( "a body run that is no run of the text",
      "fn f() {}",
      [ node ~body:[ run 7 9; run 7 10 ] (run 0 9) ],
      "Body_not_a_run 1 2" );
    ( "a body run before the body of a text with a byte order mark",
      "\xef\xbb\xbffn f() {}",
      [ node ~body:[ run 0 3 ] (run 1 10) ],
      "Body_not_a_run 1 1" );
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
        node ~test:[] (run 0 9);
        node ~body:[] (run 0 9);
      ],
      "No_own_name 2" );
    ( "the first check that a node fails",
      "fn f() {}",
      [ node ~body:[ run 0 99 ] ~test:[] (run 0 99) ],
      "Not_a_run 1" );
    ( "the body check before the name check",
      "fn f() {}",
      [ node ~body:[ run 0 99 ] ~test:[] (run 0 9) ],
      "Body_not_a_run 1 1" );
    ( "the body node of the lowest number that fails",
      "fn f() {}",
      [ node ~body:[ run 0 2; run 5 99; run 0 99 ] (run 0 9) ],
      "Body_not_a_run 1 2" );
  ]

let fails text r =
  let length = Text.length text and start = (Text.body text).Text.from in
  not
    (start <= r.Text.from
    && r.Text.from <= r.Text.until
    && r.Text.until <= length)

let first_failure text nodes =
  let rec find k = function
    | [] -> "ok"
    | (n : Reading.node) :: rest -> (
        if fails text n.run then Printf.sprintf "Not_a_run %d" k
        else
          match n.body with
          | Some [] -> Printf.sprintf "No_body_node %d" k
          | Some runs when List.exists (fails text) runs ->
              let rec index j = function
                | r :: rest -> if fails text r then j else index (j + 1) rest
                | [] -> 0
              in
              Printf.sprintf "Body_not_a_run %d %d" k (index 1 runs)
          | _ -> (
              match n.test with
              | Some [] -> Printf.sprintf "No_own_name %d" k
              | _ -> find (k + 1) rest))
  in
  find 1 nodes

let sources =
  [ ""; "a"; "// a\n"; "\xef\xbb\xbf/* \xc3\xa9 */\r\nx"; "a\r\rb\n\n" ]

let any_run_gen length =
  Gen.map
    (fun (a, b) -> { Text.from = a; until = b })
    (Gen.pair
       (Gen.int_range (-2) (length + 2))
       (Gen.int_range (-2) (length + 2)))

let node_gen length =
  let run_gen = any_run_gen length in
  Gen.map
    (fun ((r, comment), (body, (decoration, test))) ->
      let decoration =
        decoration || (comment = None && body = None && test = None)
      in
      { Reading.run = r; comment; body; decoration; test })
    (Gen.pair
       (Gen.pair run_gen
          (Gen.option (Gen.oneof_list [ Reading.Tagged; Reading.Untagged ])))
       (Gen.pair
          (Gen.option (Gen.list_size (Gen.int_range 0 3) run_gen))
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
      let length = Text.length (text_of source) in
      Gen.map
        (fun nodes -> (source, nodes))
        (Gen.list_size (Gen.int_range 0 6) (node_gen length)))

let print_case (source, nodes) =
  Printf.sprintf "%S\n%s" source
    (String.concat "\n" (List.map print_node nodes))

let tree_order (nodes : Reading.node list) =
  let rec ok = function
    | [] -> true
    | (a : Reading.node) :: rest ->
        List.for_all
          (fun (b : Reading.node) ->
            a.run.from <= b.run.from
            && (b.run.until <= a.run.until || a.run.until <= b.run.from))
          rest
        && ok rest
  in
  ok nodes

let check_is_total_and_exact =
  property ~count:2000
    ~name:"check gives each reading the result of its three checks"
    ~print:print_case case_gen (fun (source, nodes) ->
      let lines = lines_of source in
      let expected = first_failure (Lines.text lines) nodes in
      match Reading.check lines nodes with
      | Ok reading ->
          (expected = "ok" || not (tree_order nodes))
          && Reading.nodes reading = nodes
      | Error error -> print_error error = expected)

let tests =
  Alcotest.test_case "a checked reading keeps its lines and its nodes" `Quick
    a_reading_keeps_its_lines_and_nodes
  :: check_is_total_and_exact
  :: List.map
       (fun (name, source, nodes, expected) ->
         Alcotest.test_case name `Quick (expect_error source nodes expected))
       simple_cases
