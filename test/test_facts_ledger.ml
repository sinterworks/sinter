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

let plan_text =
  "# P\n\n\
   @plan p@abc123\n\
   @scope src/**\n\n\
   ## Lock\n\n\
   @scope src/a/**\n\
   @req a\n\n\
   ## Tidy\n\n\
   @scope src/b/**\n\
   Remove the dead code.\n"

let plan_files = [ (".plans/p.md", plan_text) ]
let plan_id = "plan:p@abc123"
let lock_id = "step:p@abc123/lock"
let tidy_id = "step:p@abc123/tidy"
let needs_plan = "[proof]\nplan = \"approval\"\n"

let scopes =
  [ (None, "src/**"); (Some "lock", "src/a/**"); (Some "tidy", "src/b/**") ]

let promises = [ ("lock", "req", "a") ]

let field_of files id name =
  match string_field name (record id (facts files)) with
  | Some text -> text
  | None -> Alcotest.fail ("the record has no " ^ name)

let csh = lazy (field_of plan_files plan_id "csh")
let tidy_hash = lazy (field_of plan_files tidy_id "csh")
let the_set ~seq = Lines.commitment_set ~seq scopes promises

let approve_plan ~seq =
  Lines.approval_of_hash ~seq plan_id ~csh:(Lazy.force csh)

let the_plan facts = List.hd (Facts.plans facts)

let the_hash_of_the_plan_is_the_hash_of_its_entry () =
  Alcotest.(check string)
    "the two agree" (Lazy.force csh)
    (Lines.set_hash scopes promises)

let the_approval_of_the_plan_approves_it_and_its_steps () =
  let approval = approve_plan ~seq:2 in
  let facts =
    facts ~extra:needs_plan ~lines:[ the_set ~seq:1; approval ] plan_files
  in
  check_flag "the plan" "approved" plan_id facts true;
  check_flag "the step with a promise" "approved" lock_id facts true;
  check_flag "the step without a promise" "approved" tidy_id facts true;
  check_approval "the plan names it" plan_id facts
    (Some (Lines.id_of_line approval));
  Alcotest.(check bool)
    "no difference" true
    (Option.is_none (Facts.plan_difference facts (the_plan facts)))

let no_ledger_leaves_the_plan_not_approved () =
  let facts = facts ~extra:needs_plan plan_files in
  check_flag "the plan" "approved" plan_id facts false;
  check_flag "the step" "approved" lock_id facts false;
  check_approval "no approval" plan_id facts None

let an_approval_without_its_set_counts_for_nothing () =
  let facts =
    facts ~extra:needs_plan ~lines:[ approve_plan ~seq:1 ] plan_files
  in
  check_flag "the plan" "approved" plan_id facts false;
  check_approval "no approval" plan_id facts None

let a_plan_with_no_need_of_approval_still_names_its_approval () =
  let approval = approve_plan ~seq:2 in
  let facts = facts ~lines:[ the_set ~seq:1; approval ] plan_files in
  check_flag "approved" "approved" plan_id facts true;
  check_approval "the approval" plan_id facts (Some (Lines.id_of_line approval))

let a_plan_with_no_need_of_approval_makes_no_comparison () =
  let other = [ (None, "lib/**") ] in
  let lines =
    [
      Lines.commitment_set ~seq:1 other [];
      Lines.approval_of_hash ~seq:2 plan_id ~csh:(Lines.set_hash other []);
    ]
  in
  let facts = facts ~lines plan_files in
  Alcotest.(check bool)
    "no difference" true
    (Option.is_none (Facts.plan_difference facts (the_plan facts)))

let a_change_of_the_set_needs_a_new_approval () =
  let other = [ (None, "lib/**") ] in
  let lines =
    [
      Lines.commitment_set ~seq:1 other [];
      Lines.approval_of_hash ~seq:2 plan_id ~csh:(Lines.set_hash other []);
    ]
  in
  let facts = facts ~extra:needs_plan ~lines plan_files in
  check_flag "not approved" "approved" plan_id facts false;
  Alcotest.(check bool)
    "the approval stays named" true
    (Option.is_some (string_field "approval" (record plan_id facts)));
  match Facts.plan_difference facts (the_plan facts) with
  | Some difference ->
      Alcotest.(check (list (pair string string)))
        "added"
        [ ("req", "a") ]
        difference.added;
      Alcotest.(check (list string)) "wider" [ "src/**" ] difference.wider
  | None -> Alcotest.fail "the sets differ"

let a_free_amendment_keeps_the_approval () =
  let narrower =
    [
      ( ".plans/p.md",
        "# P\n\n\
         @plan p@abc123\n\
         @scope src/**\n\n\
         ## Lock it\n\n\
         @scope src/a/b/**\n\
         @req a\n" );
    ]
  in
  let facts =
    facts ~extra:needs_plan
      ~lines:[ the_set ~seq:1; approve_plan ~seq:2 ]
      narrower
  in
  check_flag "still approved" "approved" plan_id facts true

let a_live_decline_of_a_plan_blocks_approval_when_it_needs_one () =
  let hash = Lazy.force csh in
  let lines =
    [
      the_set ~seq:1;
      approve_plan ~seq:2;
      Lines.decline ~seq:3 plan_id ~hash ~reason:"no";
    ]
  in
  let needing = facts ~extra:needs_plan ~lines plan_files in
  check_flag "not approved" "approved" plan_id needing false;
  check_flag "declined" "declined" plan_id needing true;
  Alcotest.(check bool)
    "the sets agree" true
    (Option.is_none (Facts.plan_difference needing (the_plan needing)));
  let free = facts ~lines plan_files in
  check_flag "approved with no need" "approved" plan_id free true;
  check_flag "still declined" "declined" plan_id free true

let a_plan_declined_then_approved_at_another_set_then_back_is_approved () =
  let hash = Lazy.force csh in
  let wider_scopes = [ (None, "**"); (Some "lock", "src/**") ] in
  let wider_hash = Lines.set_hash wider_scopes promises in
  let lines =
    [
      Lines.decline ~seq:1 plan_id ~hash ~reason:"no";
      Lines.commitment_set ~seq:2 wider_scopes promises;
      Lines.approval_of_hash ~seq:3 plan_id ~csh:wider_hash;
    ]
  in
  let facts = facts ~extra:needs_plan ~lines plan_files in
  check_flag "approved" "approved" plan_id facts true;
  check_flag "not declined" "declined" plan_id facts false

let a_free_amendment_moves_the_hash_and_ends_a_decline () =
  let moved =
    [
      ( ".plans/p.md",
        "# P\n\n\
         @plan p@abc123\n\
         @scope src/**\n\n\
         ## Lock\n\n\
         @scope src/a/b/**\n\
         @req a\n" );
    ]
  in
  let lines =
    [ Lines.decline ~seq:1 plan_id ~hash:(Lazy.force csh) ~reason:"no" ]
  in
  check_flag "not declined at the new hash" "declined" plan_id
    (facts ~lines moved) false

let step_lines ~seq =
  Lines.approval_of_hash ~seq tidy_id ~csh:(Lazy.force tidy_hash)

let step_approval = "[proof]\nstep = \"approval\"\n"

let a_step_without_promises_takes_its_own_approval () =
  let approval = step_lines ~seq:1 in
  let facts = facts ~extra:step_approval ~lines:[ approval ] plan_files in
  check_flag "approved" "approved" tidy_id facts true;
  check_flag "done" "done" tidy_id facts true;
  check_approval "the approval" tidy_id facts (Some (Lines.id_of_line approval))

let a_decline_of_the_step_removes_its_approval () =
  let refusal =
    Lines.decline ~seq:2 tidy_id ~hash:(Lazy.force tidy_hash) ~reason:"no"
  in
  let facts =
    facts ~extra:step_approval ~lines:[ step_lines ~seq:1; refusal ] plan_files
  in
  check_flag "not approved" "approved" tidy_id facts false;
  check_flag "not done" "done" tidy_id facts false;
  check_flag "declined" "declined" tidy_id facts true;
  check_approval "none counts" tidy_id facts None

let a_step_with_promises_takes_the_plan_and_reports_a_decline () =
  let hash = field_of plan_files lock_id "csh" in
  let refusal = Lines.decline ~seq:1 lock_id ~hash ~reason:"no" in
  let facts = facts ~lines:[ refusal ] plan_files in
  check_flag "approved with the plan" "approved" lock_id facts true;
  check_flag "declined" "declined" lock_id facts true

let an_approval_of_a_step_under_another_proof_is_still_named () =
  let approval = step_lines ~seq:1 in
  check_approval "the approval" tidy_id
    (facts ~lines:[ approval ] plan_files)
    (Some (Lines.id_of_line approval))

let the_declines_of_plans_and_steps_give_records () =
  let hash = field_of plan_files lock_id "csh" in
  let lines =
    [
      Lines.decline ~seq:1 plan_id ~hash:(Lazy.force csh) ~reason:"plan";
      Lines.decline ~seq:2 lock_id ~hash ~reason:"step";
    ]
  in
  Alcotest.(check (list (option string)))
    "the reasons, in the order of the ids"
    (List.map
       (fun (_, reason) -> Some reason)
       (List.sort compare
          (List.map2
             (fun line reason -> (Lines.id_of_line line, reason))
             lines [ "plan"; "step" ])))
    (List.map (string_field "reason")
       (decline_records (facts ~lines plan_files)))

let a_judgment_of_a_plan_of_other_facts_is_refused () =
  let one = facts plan_files and other = facts plan_files in
  Alcotest.check_raises "the plan is not one of these facts"
    (Invalid_argument "Facts.plan_judgment: the plan is not one of these facts")
    (fun () -> ignore (Facts.plan_judgment one (the_plan other)))

let closed_plan = [ Lines.completed ~seq:1 plan_id ]
let abandoned_plan = [ Lines.abandoned ~seq:1 plan_id ~reason:"stop" ]

let a_completed_plan_is_closed_and_its_record_stays () =
  let facts = facts ~lines:closed_plan plan_files in
  check_flag "open" "open" plan_id facts false;
  Alcotest.(check bool) "is_open" false (Facts.is_open facts (the_plan facts));
  Alcotest.(check int) "no open plan" 0 (List.length (Facts.open_plans facts));
  Alcotest.(check (list string))
    "the closed files" [ ".plans/p.md" ]
    (Facts.closed_plan_files facts);
  check_flag "the step still prints" "approved" lock_id facts true;
  Alcotest.(check (option string))
    "the promise still prints" (Some "promise")
    (string_field "kind"
       (record (lock_id |> fun step -> "promise:" ^ step ^ ":req:a") facts))

let an_abandoned_plan_is_closed () =
  let facts = facts ~lines:abandoned_plan plan_files in
  check_flag "open" "open" plan_id facts false

let a_plan_without_a_closing_is_open () =
  let facts = facts plan_files in
  check_flag "open" "open" plan_id facts true;
  Alcotest.(check int) "one open plan" 1 (List.length (Facts.open_plans facts));
  Alcotest.(check (list string))
    "no closed file" []
    (Facts.closed_plan_files facts)

let a_closing_of_another_form_leaves_the_plan_open () =
  check_flag "open" "open" plan_id
    (facts ~lines:[ Lines.completed ~seq:1 "plan:p" ] plan_files)
    true;
  let no_id = [ (".plans/q.md", "# Q\n\n@plan q\n@scope q/**\n") ] in
  check_flag "a plan with no id closes by its slug" "open" "plan:q"
    (facts ~lines:[ Lines.completed ~seq:1 "plan:q" ] no_id)
    false

let a_closed_plan_gives_no_scope () =
  let covers files lines path = Facts.covers (facts ~lines files) path in
  Alcotest.(check bool)
    "an open plan covers" true
    (covers plan_files [] "src/a/x.ml");
  Alcotest.(check bool)
    "a closed plan does not" false
    (covers plan_files closed_plan "src/a/x.ml");
  Alcotest.(check (list string))
    "covering" []
    (Facts.covering (facts ~lines:closed_plan plan_files) "src/a/x.ml");
  Alcotest.(check (list string))
    "covered" []
    (Facts.covered (facts ~lines:closed_plan plan_files) [ "src/a/x.ml" ])

let a_closed_plan_names_no_step () =
  let line =
    match Delivery_line.make ~plan:"p@abc123" ~step:"lock" ~hash:"abcdef" with
    | Some line -> line
    | None -> Alcotest.fail "the line does not build"
  in
  Alcotest.(check bool)
    "open" true
    (Option.is_some (Facts.named (facts plan_files) line));
  Alcotest.(check bool)
    "closed" true
    (Option.is_none (Facts.named (facts ~lines:closed_plan plan_files) line))

let base_commit = "0123456789abcdef0123456789abcdef01234567"

let class_names findings =
  List.sort_uniq String.compare
    (List.map
       (fun (finding : Finding.t) -> Finding_class.name finding.finding_class)
       findings)

let of_plans facts =
  List.filter
    (fun (finding : Finding.t) ->
      match finding.place with
      | Some { path; _ } -> String.starts_with ~prefix:".plans/" path
      | None -> false)
    (Findings.of_facts facts ~base:base_commit ~not_text:[])

let troubled_plan =
  [
    ( ".plans/r.md",
      "# R\n\n\
       @plan r\n\
       @scope src/**\n\n\
       ## Twice\n\n\
       @scope src/a/**\n\
       @decision twice\n\n\
       ## Twice\n\n\
       @scope src/b/**\n\
       @decision again\n\n\
       ## Outside\n\n\
       @scope lib/**\n\
       @decision outside\n\n\
       ## Far\n\n\
       @scope src/f/**\n\
       @req far\n\n\
       ## Half\n\n\
       @scope docs/**\n\
       @decision here\n\
       @decision missing\n\n\
       ## Shared one\n\n\
       @scope src/s/**\n\
       @decision shared\n\n\
       ## Shared two\n\n\
       @scope src/s/**\n\
       @decision shared\n\n\
       ## Bad\n\n\
       @scope src/x/**\n\
       @decision -bad\n\n\
       ## Tidy\n\n\
       @scope src/t/**\n" );
    ("docs/here.md", "# H\n\n@decision here\n");
    ("other/far.md", "# F\n\n@req far\n");
  ]

let plan_classes =
  [
    "duplicate";
    "invalid-target";
    "merged-incomplete";
    "missing-plan-id";
    "promise-out-of-scope";
    "scope-outside-plan";
    "scope-overlap";
    "step-without-promises";
    "unverified-promise";
  ]

let proof_promises = "[proof]\nstep = \"promises\"\n"

let an_open_plan_gives_each_finding_of_a_plan () =
  Alcotest.(check (list string))
    "the classes" plan_classes
    (class_names (of_plans (facts ~extra:proof_promises troubled_plan)))

let a_closed_plan_gives_none_of_them () =
  Alcotest.(check (list string))
    "no class" []
    (class_names
       (of_plans
          (facts ~extra:proof_promises
             ~lines:[ Lines.completed ~seq:1 "plan:r" ]
             troubled_plan)))

let two_plans_with_one_full_form_stay_a_duplicate_when_closed () =
  let files =
    [
      (".plans/a.md", "# A\n\n@plan p@abc123\n");
      (".plans/b.md", "# B\n\n@plan p@abc123\n");
    ]
  in
  let duplicates lines =
    List.length
      (List.filter
         (fun (finding : Finding.t) ->
           finding.finding_class = Finding_class.Duplicate)
         (of_plans (facts ~lines files)))
  in
  Alcotest.(check int) "open" 1 (duplicates []);
  Alcotest.(check int)
    "closed" 1
    (duplicates [ Lines.completed ~seq:1 plan_id ])

let two_plans_with_one_slug_are_a_duplicate_only_while_open () =
  let files =
    [
      (".plans/a.md", "# A\n\n@plan p@abc123\n");
      (".plans/b.md", "# B\n\n@plan p@def456\n");
    ]
  in
  let duplicates lines =
    List.length
      (List.filter
         (fun (finding : Finding.t) ->
           finding.finding_class = Finding_class.Duplicate)
         (of_plans (facts ~lines files)))
  in
  Alcotest.(check int) "both open" 1 (duplicates []);
  Alcotest.(check int)
    "one closed" 0
    (duplicates [ Lines.completed ~seq:1 plan_id ])

let compared_classes ~lines ~message base tree =
  let base = facts ~lines base and tree = facts ~lines tree in
  class_names
    (Adjudicator.classes ~base
       ~deliveries:(Delivery_line.read ~commit:base_commit message)
       tree [])

let base_of_diff =
  [
    ( ".plans/r.md",
      "# R\n\n\
       @plan r@abc123\n\n\
       ## Gone\n\n\
       @scope docs/**\n\
       @decision kept\n\n\
       ## Later\n\n\
       @scope src/**\n\
       @decision later\n" );
    ("docs/kept.md", "# K\n\n@decision kept\n");
    ("docs/old.md", "# O\n\n@decision old\n");
  ]

let tree_of_diff =
  [
    ( ".plans/r.md",
      "# R\n\n\
       @plan r@abc123\n\n\
       ## Now\n\n\
       @scope docs/**\n\
       @decision kept\n\
       @decision old\n\n\
       ## Later\n\n\
       @scope src/**\n\
       @decision later\n\n\
       ## Refactor\n\n\
       @scope lib/**\n\n\
       ## Unmet\n\n\
       @scope tools/**\n\
       @decision nowhere\n" );
    ("docs/kept.md", "# K\n\n@decision kept\n");
    ("docs/old.md", "# O\n\n@decision old\n");
    ("src/later.md", "# L\n\n@decision later\n");
  ]

let delivery_lines =
  lazy
    (let plan = the_plan (facts tree_of_diff) in
     String.concat "\n"
       (List.filter_map
          (fun (step : Facts.step) ->
            if List.mem step.slug [ "refactor"; "unmet" ] then
              Option.map Delivery_line.to_string (Facts.delivery plan step)
            else None)
          plan.steps))

let an_open_plan_gives_each_finding_of_a_change () =
  Alcotest.(check (list string))
    "the classes"
    [
      "delivery-on-unmet-step";
      "delivery-without-change";
      "missing-delivery";
      "promise-collision";
      "renamed-step";
    ]
    (compared_classes ~lines:[]
       ~message:(Lazy.force delivery_lines)
       base_of_diff tree_of_diff)

let a_closed_plan_leaves_only_a_stale_delivery_line () =
  Alcotest.(check (list string))
    "the classes" [ "stale-delivery" ]
    (compared_classes
       ~lines:[ Lines.completed ~seq:1 "plan:r@abc123" ]
       ~message:(Lazy.force delivery_lines)
       base_of_diff tree_of_diff)

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
    case "the hash of the plan is the hash of its entry"
      the_hash_of_the_plan_is_the_hash_of_its_entry;
    case "the approval of the plan approves it and its steps"
      the_approval_of_the_plan_approves_it_and_its_steps;
    case "no ledger leaves the plan not approved"
      no_ledger_leaves_the_plan_not_approved;
    case "an approval without its set counts for nothing"
      an_approval_without_its_set_counts_for_nothing;
    case "a plan with no need of approval still names its approval"
      a_plan_with_no_need_of_approval_still_names_its_approval;
    case "a plan with no need of approval makes no comparison"
      a_plan_with_no_need_of_approval_makes_no_comparison;
    case "a change of the set needs a new approval"
      a_change_of_the_set_needs_a_new_approval;
    case "a free amendment keeps the approval"
      a_free_amendment_keeps_the_approval;
    case "a live decline of a plan blocks approval when it needs one"
      a_live_decline_of_a_plan_blocks_approval_when_it_needs_one;
    case "a plan declined then approved at another set then back is approved"
      a_plan_declined_then_approved_at_another_set_then_back_is_approved;
    case "a free amendment moves the hash and ends a decline"
      a_free_amendment_moves_the_hash_and_ends_a_decline;
    case "a step without promises takes its own approval"
      a_step_without_promises_takes_its_own_approval;
    case "a decline of the step removes its approval"
      a_decline_of_the_step_removes_its_approval;
    case "a step with promises takes the plan and reports a decline"
      a_step_with_promises_takes_the_plan_and_reports_a_decline;
    case "an approval of a step under another proof is still named"
      an_approval_of_a_step_under_another_proof_is_still_named;
    case "the declines of plans and steps give records"
      the_declines_of_plans_and_steps_give_records;
    case "a judgment of a plan of other facts is refused"
      a_judgment_of_a_plan_of_other_facts_is_refused;
    case "a completed plan is closed and its record stays"
      a_completed_plan_is_closed_and_its_record_stays;
    case "an abandoned plan is closed" an_abandoned_plan_is_closed;
    case "a plan without a closing is open" a_plan_without_a_closing_is_open;
    case "a closing of another form leaves the plan open"
      a_closing_of_another_form_leaves_the_plan_open;
    case "a closed plan gives no scope" a_closed_plan_gives_no_scope;
    case "a closed plan names no step" a_closed_plan_names_no_step;
    case "an open plan gives each finding of a plan"
      an_open_plan_gives_each_finding_of_a_plan;
    case "a closed plan gives none of them" a_closed_plan_gives_none_of_them;
    case "two plans with one full form stay a duplicate when closed"
      two_plans_with_one_full_form_stay_a_duplicate_when_closed;
    case "two plans with one slug are a duplicate only while open"
      two_plans_with_one_slug_are_a_duplicate_only_while_open;
    case "an open plan gives each finding of a change"
      an_open_plan_gives_each_finding_of_a_change;
    case "a closed plan leaves only a stale delivery line"
      a_closed_plan_leaves_only_a_stale_delivery_line;
  ]
