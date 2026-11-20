(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_grammars
module Gen = QCheck2.Gen

let text s =
  match Text.decode s with
  | Ok t -> t
  | Error _ -> invalid_arg "Test_parse_tree.text"

let word n = String.init 4 (fun k -> Char.chr ((n lsr (8 * k)) land 0xff))

type node = { depth : int; symbol : int; start : int; end_ : int }

let record ?(flags = 0) ?count nodes =
  let count = Option.value count ~default:(List.length nodes) in
  word count ^ word flags
  ^ String.concat ""
      (List.map
         (fun n -> word n.depth ^ word n.symbol ^ word n.start ^ word n.end_)
         nodes)

let node depth symbol start end_ = { depth; symbol; start; end_ }

let node_types =
  Array.map text [| "end"; "{"; "}"; "object"; "document"; "ERROR" |]

let error_text = function
  | Parse_tree.Wrong_length -> "wrong length"
  | Wrong_flags k -> Printf.sprintf "wrong flags %d" k
  | Wrong_depth k -> Printf.sprintf "wrong depth %d" k
  | Unknown_symbol k -> Printf.sprintf "unknown symbol %d" k
  | Wrong_bytes k -> Printf.sprintf "wrong bytes %d" k
  | Not_nested k -> Printf.sprintf "not nested %d" k
  | Not_in_order k -> Printf.sprintf "not in order %d" k

let decoded ?(node_types = node_types) subject r =
  match Parse_tree.decode ~node_types (text subject) r with
  | Ok t -> t
  | Error e -> Alcotest.failf "no tree: %s" (error_text e)

let fails what expected ?(node_types = node_types) subject r =
  match Parse_tree.decode ~node_types (text subject) r with
  | Ok _ -> Alcotest.failf "%s: a tree" what
  | Error e -> Alcotest.(check string) what (error_text expected) (error_text e)

let case name f = Alcotest.test_case name `Quick f

let raises_invalid_argument what f =
  match f () with
  | exception Invalid_argument _ -> ()
  | _ -> Alcotest.failf "%s did not raise Invalid_argument" what

let nth tree k =
  match Parse_tree.node tree k with
  | Some n -> n
  | None -> Alcotest.failf "no node %d" k

let index (n : Parse_tree.node) = (n :> int)
let indexes nodes = List.map index nodes
let run_text (r : Text.run) = Printf.sprintf "%d-%d" r.from r.until

let tree_of_braces_in_json =
  [ node 0 4 0 3; node 1 3 0 2; node 2 1 0 1; node 2 2 1 2 ]

let parse_text_cases =
  [
    case "the parse text adds a line feed when the text does not end with one"
      (fun () ->
        List.iter
          (fun (t, expected) ->
            Alcotest.(check string)
              (Printf.sprintf "%S" t) expected
              (Parse_tree.parse_text (text t)))
          [
            ("", "\n");
            ("\n", "\n");
            ("a", "a\n");
            ("a\n", "a\n");
            ("a\r", "a\r\n");
            ("a\r\n", "a\r\n");
            ("\n\n", "\n\n");
            ("\xef\xbb\xbf", "\xef\xbb\xbf\n");
            ("\xc3\xa9", "\xc3\xa9\n");
          ]);
  ]

let decode_cases =
  [
    case "a record gives its nodes in the order of the parse tree" (fun () ->
        let t = decoded "{}" (record tree_of_braces_in_json) in
        Alcotest.(check int) "node_count" 4 (Parse_tree.node_count t);
        Alcotest.(check int) "root" 0 (index (Parse_tree.root t));
        Alcotest.(check (list int))
          "children of the root" [ 1 ]
          (indexes (Parse_tree.children t (Parse_tree.root t)));
        Alcotest.(check (list int))
          "children of the object" [ 2; 3 ]
          (indexes (Parse_tree.children t (nth t 1)));
        Alcotest.(check (list int))
          "children of a leaf" []
          (indexes (Parse_tree.children t (nth t 3)));
        Alcotest.(check (list string))
          "node types"
          [ "document"; "object"; "{"; "}" ]
          (List.init 4 (fun k -> Text.encode (Parse_tree.node_type t (nth t k))));
        Alcotest.(check (list int))
          "start bytes" [ 0; 0; 0; 1 ]
          (List.init 4 (fun k -> Parse_tree.start_byte t (nth t k)));
        Alcotest.(check (list int))
          "end bytes" [ 3; 2; 1; 2 ]
          (List.init 4 (fun k -> Parse_tree.end_byte t (nth t k)));
        Alcotest.(check string)
          "the text" "{}"
          (Text.encode (Parse_tree.text t));
        Alcotest.(check bool) "no error" false (Parse_tree.root_has_error t));
    case "the flag 1 says that the root has an error" (fun () ->
        let t = decoded "{}" (record ~flags:1 tree_of_braces_in_json) in
        Alcotest.(check bool)
          "root_has_error" true
          (Parse_tree.root_has_error t));
    case "node gives None outside the nodes" (fun () ->
        let t = decoded "{}" (record tree_of_braces_in_json) in
        List.iter
          (fun k ->
            if Parse_tree.node t k <> None then Alcotest.failf "a node %d" k)
          [ -1; 4; max_int; min_int ]);
    case "a node of an index not below the node count raises Invalid_argument"
      (fun () ->
        let big = decoded "{}" (record tree_of_braces_in_json) in
        let small = decoded "{}" (record [ node 0 4 0 3 ]) in
        let n = nth big 3 in
        raises_invalid_argument "children" (fun () ->
            Parse_tree.children small n);
        raises_invalid_argument "node_type" (fun () ->
            Parse_tree.node_type small n);
        raises_invalid_argument "start_byte" (fun () ->
            Parse_tree.start_byte small n);
        raises_invalid_argument "end_byte" (fun () ->
            Parse_tree.end_byte small n);
        raises_invalid_argument "run" (fun () -> Parse_tree.run small n));
    case "a node of another tree gives the node of this tree at its index"
      (fun () ->
        let big = decoded "{}" (record tree_of_braces_in_json) in
        let other = decoded "{}" (record [ node 0 3 0 2; node 1 1 1 2 ]) in
        let n = nth big 1 in
        Alcotest.(check string)
          "node_type" "{"
          (Text.encode (Parse_tree.node_type other n));
        Alcotest.(check (list int))
          "start and end bytes" [ 1; 2 ]
          [ Parse_tree.start_byte other n; Parse_tree.end_byte other n ];
        Alcotest.(check (list int))
          "children" []
          (indexes (Parse_tree.children other n));
        Alcotest.(check string) "run" "1-2" (run_text (Parse_tree.run other n)));
    case "a record of a wrong length gives Wrong_length" (fun () ->
        let one = [ node 0 4 0 3 ] in
        List.iter
          (fun (what, r) -> fails what Wrong_length "{}" r)
          [
            ("no byte", "");
            ("seven bytes", String.make 7 '\x00');
            ("no node", record []);
            ("a count of 1 and no node", record ~count:1 []);
            ("a count of 2 and one node", record ~count:2 one);
            ("a count of 1 and two nodes", record ~count:1 (one @ one));
            ("a byte more", record one ^ "\x00");
            ("a byte less", String.sub (record one) 0 23);
            ("a huge count", record ~count:0xffff_ffff one);
          ]);
    case "flags other than 0 and 1 give Wrong_flags" (fun () ->
        fails "2" (Wrong_flags 2) "{}" (record ~flags:2 tree_of_braces_in_json);
        fails "2^32 - 1" (Wrong_flags 0xffff_ffff) "{}"
          (record ~flags:0xffff_ffff tree_of_braces_in_json));
    case
      "a depth that the order of the parse tree does not allow gives \
       Wrong_depth" (fun () ->
        fails "a root of depth 1" (Wrong_depth 0) "{}" (record [ node 1 4 0 3 ]);
        fails "a second root" (Wrong_depth 1) "{}"
          (record [ node 0 4 0 3; node 0 3 0 2 ]);
        fails "a child of a child that does not exist" (Wrong_depth 1) "{}"
          (record [ node 0 4 0 3; node 2 3 0 2 ]);
        fails "a jump of two levels" (Wrong_depth 3) "{}"
          (record [ node 0 4 0 3; node 1 3 0 2; node 2 1 0 1; node 4 2 1 2 ]));
    case "a symbol with no node type gives Unknown_symbol" (fun () ->
        fails "the length of node_types" (Unknown_symbol 2) "{}"
          (record [ node 0 4 0 3; node 1 3 0 2; node 2 6 0 1 ]);
        fails "65534" (Unknown_symbol 0) "{}" (record [ node 0 65534 0 3 ]));
    case "bytes that are not boundaries of the parse text give Wrong_bytes"
      (fun () ->
        fails "a start after the end" (Wrong_bytes 1) "{}"
          (record [ node 0 4 0 3; node 1 3 2 1 ]);
        fails "an end past the parse text" (Wrong_bytes 0) "{}"
          (record [ node 0 4 0 4 ]);
        fails "a start past the parse text" (Wrong_bytes 0) "{}"
          (record [ node 0 4 4 4 ]);
        fails "a start inside a character" (Wrong_bytes 1) "\xc3\xa9"
          (record [ node 0 4 0 3; node 1 3 1 2 ]);
        fails "an end inside a character" (Wrong_bytes 1) "\xc3\xa9"
          (record [ node 0 4 0 3; node 1 3 0 1 ]);
        fails "an end of 2^32 - 1" (Wrong_bytes 0) "{}"
          (record [ node 0 4 0 0xffff_ffff ]));
    case "the first reason in the order of the record wins" (fun () ->
        fails "bytes of node 0 before a depth of node 1" (Wrong_bytes 0) "{}"
          (record [ node 0 4 0 9; node 2 3 0 2 ]);
        fails "a symbol before the bytes of one node" (Unknown_symbol 0) "{}"
          (record [ node 0 9 0 9 ]);
        fails "a depth before a symbol of one node" (Wrong_depth 0) "{}"
          (record [ node 1 9 0 9 ]);
        fails "flags before the nodes" (Wrong_flags 7) "{}"
          (record ~flags:7 [ node 1 9 0 9 ]);
        fails "a length before the flags" Wrong_length "{}"
          (record ~flags:7 [ node 1 9 0 9 ] ^ "\x00"));
    case "a zero-width node at the end of the parse text is allowed" (fun () ->
        let t = decoded "{}" (record [ node 0 4 0 3; node 1 3 3 3 ]) in
        Alcotest.(check int) "start" 3 (Parse_tree.start_byte t (nth t 1)));
  ]

let run_cases =
  let run_of subject nodes k =
    let t = decoded subject (record nodes) in
    run_text (Parse_tree.run t (nth t k))
  in
  [
    case "the run of a node leaves out the line feed of the parse text"
      (fun () ->
        Alcotest.(check string)
          "the root of {}" "0-2"
          (run_of "{}" tree_of_braces_in_json 0);
        Alcotest.(check string)
          "the object" "0-2"
          (run_of "{}" tree_of_braces_in_json 1);
        Alcotest.(check string)
          "a node on the added line feed" "2-2"
          (run_of "{}" [ node 0 4 0 3; node 1 3 2 3 ] 1);
        Alcotest.(check string)
          "a text that ends with a line feed" "0-3"
          (run_of "{}\n" [ node 0 4 0 3 ] 0));
    case "the run of a node leaves out the byte order mark" (fun () ->
        let subject = "\xef\xbb\xbfab" in
        let nodes =
          [ node 0 4 0 6; node 1 3 0 3; node 1 3 3 4; node 1 3 5 6 ]
        in
        Alcotest.(check string) "the root" "1-3" (run_of subject nodes 0);
        Alcotest.(check string) "the mark" "1-1" (run_of subject nodes 1);
        Alcotest.(check string) "a" "1-2" (run_of subject nodes 2);
        Alcotest.(check string) "the line feed" "3-3" (run_of subject nodes 3));
    case "the run of a node counts characters, not bytes" (fun () ->
        let subject = "\xc3\xa9\xf0\x9f\x98\x80" in
        let nodes = [ node 0 4 0 7; node 1 3 0 2; node 1 3 2 6 ] in
        Alcotest.(check string) "the root" "0-2" (run_of subject nodes 0);
        Alcotest.(check string) "the e" "0-1" (run_of subject nodes 1);
        Alcotest.(check string) "the emoji" "1-2" (run_of subject nodes 2));
  ]

(* @verifies packs#{give-reading-results=v1, give-reading-node-values=v1}
   Each case checks condition 3 (a child's run in the text lies within its
   parent's run in the text) and condition 4 (each earlier sibling's run in the
   text ends at or before the start of each later sibling's run in the text) of
   the term parse-tree, including clamping at the byte order mark and the added
   line feed, and the order of errors in Parse_tree.decode. *)
let nesting_and_order_cases =
  [
    case "a child whose run lies outside its parent's run gives Not_nested"
      (fun () ->
        fails "child starts before parent" (Not_nested 1) "abcd"
          (record [ node 0 4 1 3; node 1 3 0 2 ]);
        fails "child ends after parent" (Not_nested 1) "abcd"
          (record [ node 0 4 0 2; node 1 3 1 3 ]);
        fails "child surrounds parent" (Not_nested 1) "abcd"
          (record [ node 0 4 1 2; node 1 3 0 3 ]);
        fails "empty child before parent" (Not_nested 1) "abcd"
          (record [ node 0 4 1 3; node 1 3 0 0 ]);
        fails "empty child after parent" (Not_nested 1) "abcd"
          (record [ node 0 4 0 1; node 1 3 2 2 ]);
        fails "grandchild starts before its parent" (Not_nested 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 1 3; node 2 1 0 2 ]);
        fails "grandchild ends after its parent" (Not_nested 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 0 2; node 2 1 1 3 ]);
        fails "child of second sibling outside second sibling" (Not_nested 3)
          "abcd"
          (record [ node 0 4 0 4; node 1 3 0 2; node 1 3 2 4; node 2 1 1 3 ]);
        fails "multi-byte child outside parent" (Not_nested 1)
          "\xc3\xa9\xf0\x9f\x98\x80"
          (record [ node 0 4 2 6; node 1 3 0 2 ]));
    case
      "a child whose run starts before the previous sibling's run ends gives \
       Not_in_order" (fun () ->
        fails "overlapping siblings" (Not_in_order 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 0 2; node 1 3 1 3 ]);
        fails "disjoint siblings in reverse order" (Not_in_order 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 2 4; node 1 3 0 1 ]);
        fails "multi-byte siblings in reverse order" (Not_in_order 2)
          "\xc3\xa9\xf0\x9f\x98\x80"
          (record [ node 0 4 0 7; node 1 3 2 6; node 1 3 0 2 ]);
        fails "identical non-empty siblings" (Not_in_order 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 1 3; node 1 3 1 3 ]);
        fails "second sibling inside first sibling" (Not_in_order 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 0 3; node 1 3 1 2 ]);
        fails "empty sibling inside previous sibling" (Not_in_order 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 0 3; node 1 3 2 2 ]);
        fails "empty sibling before previous empty sibling" (Not_in_order 2)
          "abcd"
          (record [ node 0 4 0 4; node 1 3 2 2; node 1 3 1 1 ]);
        fails "second sibling overlaps first sibling after a shorter grandchild"
          (Not_in_order 3) "abcd"
          (record [ node 0 4 0 4; node 1 3 0 3; node 2 1 0 1; node 1 3 2 4 ]);
        fails "third sibling overlaps second sibling" (Not_in_order 3) "abcd"
          (record [ node 0 4 0 4; node 1 3 0 1; node 1 3 1 3; node 1 3 2 4 ]);
        fails "grandchildren out of order" (Not_in_order 3) "abcd"
          (record [ node 0 4 0 4; node 1 3 0 4; node 2 1 2 4; node 2 2 1 2 ]));
    case
      "conditions 3 and 4 hold on the clamped runs in the text, not raw bytes"
      (fun () ->
        ignore (decoded "ab" (record [ node 0 4 0 2; node 1 3 0 3 ]));
        ignore (decoded "ab" (record [ node 0 4 2 2; node 1 3 2 3 ]));
        ignore
          (decoded "ab" (record [ node 0 4 0 3; node 1 3 0 3; node 1 3 2 3 ]));
        ignore
          (decoded "ab" (record [ node 0 4 0 3; node 1 3 2 3; node 1 3 2 2 ]));
        fails "a text ending in a line feed does not clamp the line feed"
          (Not_nested 1) "ab\n"
          (record [ node 0 4 0 2; node 1 3 0 3 ]);
        fails "siblings on a text ending in a line feed overlap"
          (Not_in_order 2) "ab\n"
          (record [ node 0 4 0 3; node 1 3 0 3; node 1 3 2 3 ]);
        ignore
          (decoded "\xef\xbb\xbfab" (record [ node 0 4 3 5; node 1 3 0 5 ]));
        ignore
          (decoded "\xef\xbb\xbfab" (record [ node 0 4 3 3; node 1 3 0 3 ]));
        ignore
          (decoded "\xef\xbb\xbfab"
             (record [ node 0 4 3 5; node 1 3 0 3; node 1 3 0 4 ]));
        ignore
          (decoded "\xef\xbb\xbfab"
             (record [ node 0 4 0 6; node 1 3 3 3; node 1 3 0 3 ]));
        ignore
          (decoded "" (record [ node 0 4 0 0; node 1 3 0 1; node 1 3 0 0 ]));
        ignore
          (decoded "\xef\xbb\xbf"
             (record [ node 0 4 3 3; node 1 3 0 4; node 1 3 0 3 ]));
        ignore
          (decoded "abcd"
             (record
                [
                  node 0 4 0 4;
                  node 1 3 0 0;
                  node 1 3 0 0;
                  node 1 3 0 2;
                  node 1 3 2 2;
                  node 1 3 2 4;
                  node 1 3 4 4;
                ]));
        ignore
          (decoded "abcd"
             (record
                [
                  node 0 4 0 4;
                  node 1 3 0 2;
                  node 2 1 0 2;
                  node 1 3 2 4;
                  node 2 2 2 3;
                ])));
    case "Not_nested and Not_in_order follow the check order and record order"
      (fun () ->
        fails "Wrong_bytes before Not_nested on one node" (Wrong_bytes 1) "abcd"
          (record [ node 0 4 1 3; node 1 3 2 0 ]);
        fails "Unknown_symbol before Not_nested on one node" (Unknown_symbol 1)
          "abcd"
          (record [ node 0 4 1 2; node 1 9 0 3 ]);
        fails "Wrong_depth before Not_nested on one node" (Wrong_depth 1) "abcd"
          (record [ node 0 4 1 2; node 2 3 0 3 ]);
        fails "Not_nested before Not_in_order when child starts before parent"
          (Not_nested 2) "abcd"
          (record [ node 0 4 1 3; node 1 3 2 3; node 1 3 0 2 ]);
        fails "Not_nested before Not_in_order when child ends after parent"
          (Not_nested 2) "abcd"
          (record [ node 0 4 0 3; node 1 3 1 3; node 1 3 2 4 ]);
        fails "Not_nested on an earlier node before errors on a later node"
          (Not_nested 1) "abcd"
          (record [ node 0 4 1 2; node 1 3 0 3; node 5 99 9 0 ]);
        fails "Not_in_order on an earlier node before errors on a later node"
          (Not_in_order 2) "abcd"
          (record [ node 0 4 0 4; node 1 3 1 3; node 1 3 0 2; node 5 99 9 0 ]));
  ]

let byte_offsets_of_parse_text_boundaries chars =
  let parse_chars =
    match List.rev chars with
    | u :: _ when Uchar.to_int u = 0x0a -> chars
    | _ -> chars @ [ Uchar.of_int 0x0a ]
  in
  let offsets =
    List.fold_left
      (fun acc u -> (List.hd acc + Uchar.utf_8_byte_length u) :: acc)
      [ 0 ] parse_chars
  in
  Array.of_list (List.rev offsets)

let gen_chars =
  let piece =
    Gen.oneof
      [
        Gen.oneof_list
          (List.map Uchar.of_int [ 0x61; 0x0a; 0x0d; 0xe9; 0x1f600 ]);
        Gen.map Uchar.of_int (Gen.int_range 0x20 0x7e);
      ]
  in
  Gen.(
    pair bool (list_size (int_range 0 8) piece) >|= fun (bom, cs) ->
    if bom then Uchar.of_int 0xfeff :: cs else cs)

let clamped_indices ~b ~l nb boundary =
  List.filter (fun idx -> max b (min idx l) = boundary) (List.init nb Fun.id)

let gen_raw_pair ~b ~l nb lo hi =
  let starts = clamped_indices ~b ~l nb lo in
  let ends = clamped_indices ~b ~l nb hi in
  let pairs =
    List.concat_map
      (fun s ->
        List.filter_map (fun e -> if s <= e then Some (s, e) else None) ends)
      starts
  in
  Gen.oneof_list pairs

let rec gen_ordered_runs count lo hi =
  if count = 0 then Gen.return []
  else
    Gen.(
      int_range lo hi >>= fun a ->
      int_range a hi >>= fun b ->
      gen_ordered_runs (count - 1) b hi >|= fun rest -> (a, b) :: rest)

let gen_well_formed_tree =
  Gen.(
    gen_chars >>= fun chars ->
    let bounds = byte_offsets_of_parse_text_boundaries chars in
    let nb = Array.length bounds in
    let b =
      if chars <> [] && Uchar.to_int (List.hd chars) = 0xfeff then 1 else 0
    in
    let l = List.length chars in
    let rec gen_subtree depth lo hi max_depth =
      int_range 0 (Array.length node_types - 1) >>= fun symbol ->
      gen_raw_pair ~b ~l nb lo hi >>= fun (si, ei) ->
      let me = node depth symbol bounds.(si) bounds.(ei) in
      if max_depth <= 0 then return [ me ]
      else
        int_range 0 3 >>= fun n_children ->
        gen_ordered_runs n_children lo hi >>= fun child_runs ->
        let rec build_children = function
          | [] -> return []
          | (clo, chi) :: rest ->
              gen_subtree (depth + 1) clo chi (max_depth - 1) >>= fun sub ->
              build_children rest >|= fun more -> sub @ more
        in
        build_children child_runs >|= fun children -> me :: children
    in
    int_range b l >>= fun rlo ->
    int_range rlo l >>= fun rhi ->
    int_range 0 3 >>= fun max_depth ->
    pair bool (gen_subtree 0 rlo rhi max_depth) >|= fun (flag, ns) ->
    (chars, flag, ns))

let gen_perturbed_tree =
  Gen.(
    gen_well_formed_tree >>= fun (chars, flag, ns) ->
    let bounds = byte_offsets_of_parse_text_boundaries chars in
    let nb = Array.length bounds in
    let count = List.length ns in
    int_range 0 (count - 1) >>= fun target ->
    int_range 0 (nb - 1) >>= fun a ->
    int_range a (nb - 1) >|= fun b ->
    let ns =
      List.mapi
        (fun i n ->
          if i = target then { n with start = bounds.(a); end_ = bounds.(b) }
          else n)
        ns
    in
    (chars, flag, ns))

let gen_mixed_tree =
  Gen.(
    oneof_weighted
      [
        (2, gen_well_formed_tree);
        (3, gen_perturbed_tree);
        ( 2,
          gen_chars >>= fun chars ->
          let bounds = byte_offsets_of_parse_text_boundaries chars in
          let nb = Array.length bounds in
          int_range 1 10 >>= fun count ->
          let rec nodes k prev acc =
            if k = count then return (List.rev acc)
            else
              (if k = 0 then oneof_weighted [ (8, return 0); (1, return 1) ]
               else
                 oneof_weighted
                   [ (8, int_range 1 (prev + 1)); (1, int_range 0 (prev + 2)) ])
              >>= fun depth ->
              oneof_weighted
                [
                  (8, int_range 0 (Array.length node_types - 1));
                  (1, return (Array.length node_types));
                ]
              >>= fun symbol ->
              oneof_weighted
                [
                  ( 8,
                    int_range 0 (nb - 1) >>= fun a ->
                    int_range a (nb - 1) >|= fun b -> (bounds.(a), bounds.(b))
                  );
                  ( 1,
                    int_range 0 (bounds.(nb - 1) + 1) >>= fun a ->
                    int_range 0 (bounds.(nb - 1) + 1) >|= fun b -> (a, b) );
                ]
              >>= fun (s, e) ->
              nodes (k + 1) (max 0 depth) (node depth symbol s e :: acc)
          in
          pair bool (nodes 0 0 []) >|= fun (flag, ns) -> (chars, flag, ns) );
      ])

let boundary_of_opt bounds byte =
  let n = Array.length bounds in
  let rec go k =
    if k = n then None else if bounds.(k) = byte then Some k else go (k + 1)
  in
  go 0

let reference_decode chars ns =
  let bounds = byte_offsets_of_parse_text_boundaries chars in
  let b =
    if chars <> [] && Uchar.to_int (List.hd chars) = 0xfeff then 1 else 0
  in
  let l = List.length chars in
  let n_types = Array.length node_types in
  let runs = Array.make (List.length ns) (0, 0) in
  let arr = Array.of_list ns in
  let rec check k =
    if k = Array.length arr then Ok ()
    else
      let cur = arr.(k) in
      let valid_depth =
        if k = 0 then cur.depth = 0
        else cur.depth >= 1 && cur.depth <= arr.(k - 1).depth + 1
      in
      if not valid_depth then Error (Parse_tree.Wrong_depth k)
      else if cur.symbol < 0 || cur.symbol >= n_types then
        Error (Unknown_symbol k)
      else
        match
          (boundary_of_opt bounds cur.start, boundary_of_opt bounds cur.end_)
        with
        | Some s, Some e when cur.start <= cur.end_ -> (
            let rf = max b (min s l) and ru = max b (min e l) in
            runs.(k) <- (rf, ru);
            if k = 0 then check (k + 1)
            else
              let rec find_parent j =
                if arr.(j).depth = cur.depth - 1 then j else find_parent (j - 1)
              in
              let p = find_parent (k - 1) in
              let pf, pu = runs.(p) in
              if rf < pf || ru > pu then Error (Not_nested k)
              else
                let rec find_prev_sibling j =
                  if j <= p then None
                  else if arr.(j).depth = cur.depth then Some j
                  else find_prev_sibling (j - 1)
                in
                match find_prev_sibling (k - 1) with
                | Some prev when rf < snd runs.(prev) -> Error (Not_in_order k)
                | _ -> check (k + 1))
        | _ -> Error (Wrong_bytes k)
  in
  check 0

let runs_follow_node_run_invariant tree =
  let count = Parse_tree.node_count tree in
  let rs = Array.init count (fun k -> Parse_tree.run tree (nth tree k)) in
  let rec check_pairs i =
    if i >= count then true
    else
      let rec inner j =
        if j >= count then true
        else
          let a = rs.(i) and b = rs.(j) in
          let ok =
            (a.from <= b.from && b.until <= a.until) || a.until <= b.from
          in
          ok && inner (j + 1)
      in
      inner (i + 1) && check_pairs (i + 1)
  in
  check_pairs 0

let print_tree (chars, flag, ns) =
  Printf.sprintf "%S %b [%s]"
    (Text.encode (Text.of_uchars chars))
    flag
    (String.concat "; "
       (List.map
          (fun n ->
            Printf.sprintf "%d %d %d %d" n.depth n.symbol n.start n.end_)
          ns))

let parent_of nodes k =
  let arr = Array.of_list nodes in
  let d = arr.(k).depth in
  let rec back j = if arr.(j).depth = d - 1 then j else back (j - 1) in
  back (k - 1)

let boundary_of bounds byte =
  let rec go k = if bounds.(k) = byte then k else go (k + 1) in
  go 0

let property_cases =
  [
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:500
         ~name:
           "a record of a tree gives back each node, its children, and its run"
         ~print:print_tree gen_well_formed_tree (fun (chars, flag, ns) ->
           let subject = Text.of_uchars chars in
           let r = record ~flags:(if flag then 1 else 0) ns in
           match Parse_tree.decode ~node_types subject r with
           | Error e -> QCheck2.Test.fail_reportf "no tree: %s" (error_text e)
           | Ok t ->
               let bounds = byte_offsets_of_parse_text_boundaries chars in
               let b =
                 if chars <> [] && Uchar.to_int (List.hd chars) = 0xfeff then 1
                 else 0
               in
               let l = List.length chars in
               let count = List.length ns in
               Parse_tree.node_count t = count
               && Parse_tree.root_has_error t = flag
               && List.for_all
                    (fun k ->
                      let n = List.nth ns k and tn = nth t k in
                      let expected_children =
                        List.filter
                          (fun j -> j > 0 && parent_of ns j = k)
                          (List.init count Fun.id)
                      in
                      let s = boundary_of bounds n.start
                      and e = boundary_of bounds n.end_ in
                      let run = Parse_tree.run t tn in
                      Text.equal
                        (Parse_tree.node_type t tn)
                        node_types.(n.symbol)
                      && Parse_tree.start_byte t tn = n.start
                      && Parse_tree.end_byte t tn = n.end_
                      && indexes (Parse_tree.children t tn) = expected_children
                      && run.from = max b (min s l)
                      && run.until = max b (min e l))
                    (List.init count Fun.id)
               && runs_follow_node_run_invariant t));
    (* @verifies packs#{give-reading-results=v1, give-reading-node-values=v1}
       For generated records with valid and invalid depths, symbols, byte
       offsets, parent-child nesting, and sibling order, Parse_tree.decode
       agrees with a direct reading of the four conditions of parse-tree and
       the error order of Parse_tree.decode, and every accepted tree obeys the
       pairwise nesting invariant of node-run. *)
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:2000
         ~name:
           "decode agrees with the four conditions of parse-tree and the check \
            order"
         ~print:print_tree gen_mixed_tree (fun (chars, flag, ns) ->
           let subject = Text.of_uchars chars in
           let r = record ~flags:(if flag then 1 else 0) ns in
           match
             (Parse_tree.decode ~node_types subject r, reference_decode chars ns)
           with
           | Ok t, Ok () -> runs_follow_node_run_invariant t
           | Error got, Error expected -> got = expected
           | Ok _, Error expected ->
               QCheck2.Test.fail_reportf "accepted tree, expected %s"
                 (error_text expected)
           | Error got, Ok () ->
               QCheck2.Test.fail_reportf "refused valid tree with %s"
                 (error_text got)));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:1000 ~name:"decode never raises on any record"
         ~print:(fun (r, s) -> Printf.sprintf "%S on %S" r s)
         Gen.(
           pair
             (oneof
                [
                  string_size (int_range 0 80);
                  map
                    (fun ws -> String.concat "" (List.map word ws))
                    (list_size (int_range 0 20)
                       (oneof [ int_range 0 8; int_range 0 0xffff_ffff ]));
                ])
             (oneof_list [ ""; "{}"; "\xc3\xa9"; "\xef\xbb\xbfa\n" ]))
         (fun (r, s) ->
           match Parse_tree.decode ~node_types (text s) r with
           | Ok _ | Error _ -> true));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:500
         ~name:"decode never raises on a record with a changed byte"
         ~print:(fun ((c, f, ns), k, v) ->
           Printf.sprintf "%s, byte %d to %d" (print_tree (c, f, ns)) k v)
         Gen.(triple gen_well_formed_tree (int_range 0 400) (int_range 0 255))
         (fun ((chars, flag, ns), k, v) ->
           let r = record ~flags:(if flag then 1 else 0) ns in
           let k = k mod String.length r in
           let r = String.mapi (fun i c -> if i = k then Char.chr v else c) r in
           match Parse_tree.decode ~node_types (Text.of_uchars chars) r with
           | Ok _ | Error _ -> true));
  ]

let growth_cases =
  [
    case "the work of decode grows as n log m" (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(1_000, 8_000)
          ~input:(fun n ->
            let subject = text (String.make n 'a') in
            let nodes =
              node 0 4 0 (n + 1)
              :: List.init (n - 1) (fun k -> node 1 3 k (k + 1))
            in
            (subject, record nodes))
          (fun (subject, r) -> Parse_tree.decode ~node_types subject r));
    case "the work of decode grows as n log m on a deep chain" (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(1_000, 8_000)
          ~input:(fun n ->
            let subject = text (String.make n 'a') in
            let nodes = List.init n (fun k -> node k 3 0 (n - k)) in
            (subject, record nodes))
          (fun (subject, r) -> Parse_tree.decode ~node_types subject r));
    case "the work of parse_text grows linearly" (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(1_000, 8_000)
          ~input:(fun n -> text (String.make n 'a'))
          Parse_tree.parse_text);
  ]

let tests =
  parse_text_cases @ decode_cases @ run_cases @ nesting_and_order_cases
  @ property_cases @ growth_cases
