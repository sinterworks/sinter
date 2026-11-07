(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_core
module Lines = Ledger_lines

let markdown = "[scan]\npacks.markdown.files = [\"**/*.md\"]\n"

let manifest extra =
  match Manifest.of_string (markdown ^ extra) with
  | Ok manifest -> manifest
  | Error _ -> Alcotest.fail "the manifest has errors"

let reader =
  lazy
    (match Markdown.create (Sinter_bridge.create ()) with
    | Ok reader -> reader
    | Error _ -> failwith "the reader does not start")

let document text =
  match Markdown.read (Lazy.force reader) text with
  | Ok document -> document
  | Error _ -> Alcotest.fail "the document does not read"

let facts ?(extra = "") ?(lines = []) files =
  Facts.make
    ~ledger:(Folds.of_entries (Lines.entries lines))
    (manifest extra)
    (List.map (fun (path, text) -> (path, document text)) files)

let string_field name record =
  match List.assoc_opt name record with
  | Some (Jsonl.Scalar (Jsonl.String text)) -> Some text
  | _ -> None

let bool_field name record =
  match List.assoc_opt name record with
  | Some (Jsonl.Scalar (Jsonl.Bool flag)) -> Some flag
  | _ -> None

let record id facts =
  match
    List.find_opt
      (fun record -> string_field "id" record = Some id)
      (Facts.records facts)
  with
  | Some record -> record
  | None -> Alcotest.fail ("no record has the id " ^ id)

let check_flag name field id facts expected =
  Alcotest.(check (option bool))
    name (Some expected)
    (bool_field field (record id facts))

let check_approval name id facts expected =
  Alcotest.(check (option string))
    name expected
    (string_field "approval" (record id facts))

let a_req = "# A\n\n@req a\nThe text of a.\n"
let a_file = [ ("docs/a.md", a_req) ]

let xh_of files id =
  match string_field "xh" (record id (facts files)) with
  | Some xh -> xh
  | None -> Alcotest.fail "the record has no xh"

let xh = lazy (xh_of a_file "req:a")
let needs_req = "[proof]\nreq = \"approval\"\n"

let approve ?(rev = 1) ~seq () =
  Lines.approval_of_text ~seq "req:a" ~rev ~xh:(Lazy.force xh)

let refuse ?(reason = "no") ~seq () =
  Lines.decline ~seq "req:a" ~hash:(Lazy.force xh) ~reason

let an_approval_approves_a_declaration_of_a_kind_that_needs_one () =
  let line = approve ~seq:1 () in
  let facts = facts ~extra:needs_req ~lines:[ line ] a_file in
  check_flag "approved" "approved" "req:a" facts true;
  check_flag "not declined" "declined" "req:a" facts false;
  check_approval "the approval" "req:a" facts (Some (Lines.id_of_line line));
  Alcotest.(check bool) "is_approved" true (Facts.is_approved facts 0)

let no_approval_leaves_it_not_approved () =
  let facts = facts ~extra:needs_req a_file in
  check_flag "not approved" "approved" "req:a" facts false;
  check_approval "no approval" "req:a" facts None;
  Alcotest.(check bool) "is_approved" false (Facts.is_approved facts 0)

let a_decline_after_the_approval_removes_it_and_declines () =
  let facts =
    facts ~extra:needs_req ~lines:[ approve ~seq:1 (); refuse ~seq:2 () ] a_file
  in
  check_flag "not approved" "approved" "req:a" facts false;
  check_flag "declined" "declined" "req:a" facts true;
  check_approval "no approval counts" "req:a" facts None

let a_bare_revision_bump_needs_a_new_approval () =
  let bumped = [ ("docs/a.md", "# A\n\n@req a v2\nThe text of a.\n") ] in
  let lines = [ refuse ~seq:1 (); approve ~seq:2 () ] in
  let facts = facts ~extra:needs_req ~lines bumped in
  check_flag "not approved" "approved" "req:a" facts false;
  check_flag "the decline is live again" "declined" "req:a" facts true

let a_kind_that_needs_no_approval_counts_as_approved () =
  let facts = facts ~lines:[ refuse ~seq:1 () ] a_file in
  check_flag "approved" "approved" "req:a" facts true;
  check_flag "still declined" "declined" "req:a" facts true;
  Alcotest.(check bool) "is_approved" true (Facts.is_approved facts 0)

let a_kind_that_needs_no_approval_names_no_approval () =
  check_approval "no approval field" "req:a"
    (facts ~lines:[ approve ~seq:1 () ] a_file)
    None

let a_rule_counts_as_approved () =
  let facts =
    facts ~extra:needs_req [ ("docs/r.md", "# R\n\n@rule r\nThe text of r.\n") ]
  in
  Alcotest.(check bool) "is_approved" true (Facts.is_approved facts 0)

let chain =
  [
    ( "docs/a.md",
      "# A\n\n@decision a\nOld.\n\n# B\n\n@decision b\n@supersedes a v1\nNew.\n"
    );
  ]

let needs_decision = "[proof]\ndecision = \"approval\"\n"
let b_xh = lazy (xh_of chain "decision:b")

let index_of facts id =
  match
    List.find_index
      (fun declaration -> String.equal (Facts.declaration_id declaration) id)
      (Facts.declarations facts)
  with
  | Some index -> index
  | None -> Alcotest.fail "no such declaration"

let edge_id = "supersedes:decision:b->a"

let an_unapproved_source_retires_nothing () =
  let facts = facts ~extra:needs_decision chain in
  Alcotest.(check bool)
    "a is in force" true
    (Facts.is_in_force facts (index_of facts "decision:a"));
  check_flag "the edge is not effective" "effective" edge_id facts false

let an_approved_source_retires_its_target () =
  let line =
    Lines.approval_of_text ~seq:1 "decision:b" ~rev:1 ~xh:(Lazy.force b_xh)
  in
  let facts = facts ~extra:needs_decision ~lines:[ line ] chain in
  Alcotest.(check bool)
    "a is retired" false
    (Facts.is_in_force facts (index_of facts "decision:a"));
  check_flag "the edge is effective" "effective" edge_id facts true;
  Alcotest.(check (list string))
    "b is the successor" [ "decision:b" ]
    (List.map
       (fun index ->
         Facts.declaration_id (List.nth (Facts.declarations facts) index))
       (Facts.successors facts (index_of facts "decision:a")))

let a_decline_of_the_source_stops_the_retirement () =
  let hash = Lazy.force b_xh in
  let lines =
    [
      Lines.approval_of_text ~seq:1 "decision:b" ~rev:1 ~xh:hash;
      Lines.decline ~seq:2 "decision:b" ~hash ~reason:"no";
    ]
  in
  let facts = facts ~extra:needs_decision ~lines chain in
  Alcotest.(check bool)
    "a is in force again" true
    (Facts.is_in_force facts (index_of facts "decision:a"))

let decline_records facts =
  List.filter
    (fun record -> string_field "kind" record = Some "decline")
    (Facts.records facts)

let a_live_decline_gives_one_record_with_its_fields () =
  let line = refuse ~seq:1 ~reason:"too\nbroad" () in
  let id = Lines.id_of_line line in
  let facts = facts ~lines:[ line ] a_file in
  Alcotest.(check (list string))
    "the record"
    [
      Printf.sprintf
        "{\"by\":\"a@example.com\",\"entry\":\"%s\",\"hash\":\"%s\",\"id\":\"decline:%s\",\"kind\":\"decline\",\"reason\":\"too\\nbroad\",\"subject\":\"req:a\",\"ts\":\"2026-10-31T14:05:09Z\",\"v\":1}"
        id (Lazy.force xh) id;
    ]
    (List.map Jsonl.to_string (decline_records facts))

let a_decline_that_is_not_live_gives_no_record () =
  let at_another_text =
    Lines.decline ~seq:1 "req:a" ~hash:(Lines.hash 9) ~reason:"no"
  in
  let of_another_subject =
    Lines.decline ~seq:2 "req:b" ~hash:(Lazy.force xh) ~reason:"no"
  in
  let ended = [ refuse ~seq:3 (); approve ~seq:4 () ] in
  Alcotest.(check int)
    "no record" 0
    (List.length
       (decline_records
          (facts ~lines:(at_another_text :: of_another_subject :: ended) a_file)))

let two_declarations_with_one_id_give_one_record () =
  let line = refuse ~seq:1 () in
  Alcotest.(check int)
    "one record" 1
    (List.length
       (decline_records
          (facts ~lines:[ line ] (a_file @ [ ("docs/z.md", a_req) ]))))

let decline_records_sort_by_id_and_stand_after_the_located_records () =
  let lines = [ refuse ~seq:1 ~reason:"a" (); refuse ~seq:2 ~reason:"b" () ] in
  let ids = List.sort String.compare (List.map Lines.id_of_line lines) in
  let kinds =
    List.filter_map (string_field "kind") (Facts.records (facts ~lines a_file))
  in
  Alcotest.(check (list string))
    "the kinds"
    [ "req"; "decline"; "decline" ]
    kinds;
  Alcotest.(check (list (option string)))
    "the ids"
    (List.map (fun id -> Some id) ids)
    (List.map (string_field "entry") (decline_records (facts ~lines a_file)))

let many_edges_and_many_declines_cost_no_product () =
  let input count =
    let text =
      "# B\n\n@decision b\n"
      ^ String.concat ""
          (List.init count (fun n -> Printf.sprintf "@supersedes x%d v1\n" n))
      ^ "New.\n"
    in
    let hash = xh_of [ ("docs/b.md", text) ] "decision:b" in
    let lines =
      List.init count (fun n ->
          Lines.decline ~seq:(n + 1) "decision:b" ~hash ~reason:"no")
    in
    facts ~extra:needs_decision ~lines [ ("docs/b.md", text) ]
  in
  Counted_work.check_growth ~margin:3. ~sizes:(40, 640) ~input Facts.records

let duplicate_declarations_read_their_declines_once () =
  let input count =
    let files =
      List.init count (fun n -> (Printf.sprintf "docs/a%d.md" n, a_req))
    in
    let lines =
      List.init count (fun n ->
          Lines.decline ~seq:(n + 1) "req:a" ~hash:(Lazy.force xh) ~reason:"no")
    in
    facts ~lines files
  in
  Counted_work.check_growth ~margin:3. ~sizes:(40, 640) ~input Facts.records

let a_decline_that_an_approval_of_one_copy_ends_stays_for_the_other () =
  let bumped = "# A\n\n@req a v2\nThe text of a.\n" in
  let early = refuse ~seq:1 ~reason:"early" () in
  let late = refuse ~seq:3 ~reason:"late" () in
  let lines = [ early; approve ~seq:2 (); late ] in
  Alcotest.(check (list string))
    "both declines live for the copy at v2"
    (List.sort String.compare (List.map Lines.id_of_line [ early; late ]))
    (List.filter_map (string_field "entry")
       (decline_records (facts ~lines (a_file @ [ ("docs/z.md", bumped) ]))))

let identities_leave_out_declines () =
  Alcotest.(check (list string))
    "the kinds" [ "req" ]
    (List.map
       (fun (identity : Facts.identity) -> identity.kind)
       (Facts.identities (facts ~lines:[ refuse ~seq:1 () ] a_file)))

let case name test = Alcotest.test_case name `Quick test

let tests =
  [
    case "an approval approves a declaration of a kind that needs one"
      an_approval_approves_a_declaration_of_a_kind_that_needs_one;
    case "no approval leaves it not approved" no_approval_leaves_it_not_approved;
    case "a decline after the approval removes it and declines"
      a_decline_after_the_approval_removes_it_and_declines;
    case "a bare revision bump needs a new approval"
      a_bare_revision_bump_needs_a_new_approval;
    case "a kind that needs no approval counts as approved"
      a_kind_that_needs_no_approval_counts_as_approved;
    case "a kind that needs no approval names no approval"
      a_kind_that_needs_no_approval_names_no_approval;
    case "a rule counts as approved" a_rule_counts_as_approved;
    case "an unapproved source retires nothing"
      an_unapproved_source_retires_nothing;
    case "an approved source retires its target"
      an_approved_source_retires_its_target;
    case "a decline of the source stops the retirement"
      a_decline_of_the_source_stops_the_retirement;
    case "a live decline gives one record with its fields"
      a_live_decline_gives_one_record_with_its_fields;
    case "a decline that is not live gives no record"
      a_decline_that_is_not_live_gives_no_record;
    case "two declarations with one id give one record"
      two_declarations_with_one_id_give_one_record;
    case "decline records sort by id and stand after the located records"
      decline_records_sort_by_id_and_stand_after_the_located_records;
    case "many edges and many declines cost no product"
      many_edges_and_many_declines_cost_no_product;
    case "duplicate declarations read their declines once"
      duplicate_declarations_read_their_declines_once;
    case "a decline that an approval of one copy ends stays for the other"
      a_decline_that_an_approval_of_one_copy_ends_stays_for_the_other;
    case "identities leave out declines" identities_leave_out_declines;
  ]
