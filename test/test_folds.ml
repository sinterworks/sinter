(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_core
module Gen = QCheck2.Gen
module Lines = Ledger_lines

let subject = "req:a"
let plan = "plan:p@abc123"
let step = "step:p@abc123/s"
let x = Lines.hash 1
let y = Lines.hash 2
let folds_of lines = Folds.of_entries (Lines.entries lines)
let id = Lines.id_of_line
let ids = List.map (fun (entry : Ledger.entry) -> entry.id)

let check_judged name ~approval ~live
    ((folds, key, hash), (judged : Folds.judged)) =
  Alcotest.(check (option string))
    (name ^ ": the approval") (Option.map id approval)
    (Option.map (fun (entry : Ledger.entry) -> entry.id) judged.approval);
  Alcotest.(check (option string))
    (name ^ ": the latest live decline")
    (Option.map id (List.nth_opt (List.rev live) 0))
    (Option.map (fun (entry : Ledger.entry) -> entry.id) judged.latest_live);
  Alcotest.(check (list string))
    (name ^ ": the live declines")
    (List.map id live)
    (ids (Folds.live folds ~subject:key ~hash ~after:judged.after))

let declaration ?(subject = subject) ?(rev = 1) ?(xh = x) lines =
  let folds = folds_of lines in
  ((folds, subject, xh), Folds.declaration folds ~subject ~rev ~xh)

let step_judged ?(hash = x) lines =
  let folds = folds_of lines in
  ((folds, step, hash), Folds.step folds ~subject:step ~hash)

let approve ~seq = Lines.approval_of_text ~seq subject ~rev:1 ~xh:x
let decline ~seq = Lines.decline ~seq subject ~hash:x ~reason:"no"

let no_entry_gives_no_judgment () =
  check_judged "the empty folds" ~approval:None ~live:[]
    ( (Folds.empty, subject, x),
      Folds.declaration Folds.empty ~subject ~rev:1 ~xh:x );
  check_judged "the empty folds" ~approval:None ~live:[]
    ((Folds.empty, step, x), Folds.step Folds.empty ~subject:step ~hash:x);
  Alcotest.(check bool)
    "no approval with a set" true
    (Option.is_none (Folds.latest_approval_with_set Folds.empty ~subject:plan));
  Alcotest.(check bool)
    "no decline" true
    (Option.is_none (Folds.plan Folds.empty ~subject:plan ~hash:x).latest_live);
  Alcotest.(check bool)
    "no closing" true
    (Option.is_none (Folds.closing Folds.empty ~subject:plan));
  Alcotest.(check bool)
    "not delivered" false
    (Folds.delivered Folds.empty ~subject:step ~hash:x);
  Alcotest.(check bool)
    "not started" false
    (Folds.started Folds.empty ~subject:step)

let the_latest_approval_of_the_triple_counts () =
  let first = approve ~seq:1 and second = approve ~seq:2 in
  check_judged "two approvals" ~approval:(Some second) ~live:[]
    (declaration [ first; second ])

let a_decline_after_the_approval_removes_it () =
  let approval = approve ~seq:1 and refusal = decline ~seq:2 in
  check_judged "the decline is latest" ~approval:None ~live:[ refusal ]
    (declaration [ approval; refusal ])

let an_approval_after_the_decline_ends_it () =
  let refusal = decline ~seq:1 and approval = approve ~seq:2 in
  check_judged "the approval is latest" ~approval:(Some approval) ~live:[]
    (declaration [ refusal; approval ])

let two_declines_after_the_approval_are_both_live () =
  let one = decline ~seq:2 and two = decline ~seq:3 in
  check_judged "both stay" ~approval:None ~live:[ one; two ]
    (declaration [ approve ~seq:1; one; two ])

let only_the_declines_after_the_approval_are_live () =
  let late = decline ~seq:3 in
  check_judged "the early one ended" ~approval:None ~live:[ late ]
    (declaration [ decline ~seq:1; approve ~seq:2; late ])

let a_bare_revision_bump_removes_the_approval () =
  check_judged "the triple differs" ~approval:None ~live:[]
    (declaration ~rev:2 [ approve ~seq:1 ])

let a_bare_revision_bump_makes_a_decline_live_again () =
  let refusal = decline ~seq:1 in
  let lines = [ refusal; approve ~seq:2 ] in
  check_judged "before the bump"
    ~approval:(Some (List.nth lines 1))
    ~live:[] (declaration lines);
  check_judged "after the bump" ~approval:None ~live:[ refusal ]
    (declaration ~rev:2 lines)

let a_judgment_at_another_text_counts_for_nothing () =
  let approval = approve ~seq:2 in
  check_judged "a decline at another hash ends nothing"
    ~approval:(Some approval) ~live:[]
    (declaration
       [ Lines.decline ~seq:1 subject ~hash:y ~reason:"no"; approval ]);
  let refusal = decline ~seq:1 in
  check_judged "an approval at another hash ends nothing" ~approval:None
    ~live:[ refusal ]
    (declaration
       [ refusal; Lines.approval_of_text ~seq:2 subject ~rev:1 ~xh:y ])

let the_subject_matches_by_all_its_bytes () =
  check_judged "another kind" ~approval:None ~live:[]
    (declaration ~subject:"design:a" [ approve ~seq:1; decline ~seq:2 ])

let a_step_takes_the_same_rule () =
  let approval = Lines.approval_of_hash ~seq:1 step ~csh:x in
  let refusal = Lines.decline ~seq:2 step ~hash:x ~reason:"no" in
  let again = Lines.approval_of_hash ~seq:3 step ~csh:x in
  check_judged "approved" ~approval:(Some approval) ~live:[]
    (step_judged [ approval ]);
  check_judged "refused" ~approval:None ~live:[ refusal ]
    (step_judged [ approval; refusal ]);
  check_judged "approved again" ~approval:(Some again) ~live:[]
    (step_judged [ approval; refusal; again ]);
  check_judged "another hash" ~approval:None ~live:[]
    (step_judged ~hash:y [ approval; refusal; again ])

let scopes = [ (None, "src/**") ]
let promises = [ ("s", "req", "a") ]
let csh = Lines.set_hash scopes promises
let set ~seq = Lines.commitment_set ~seq scopes promises

let wrong_set ~seq =
  Lines.line_of
    (Lines.set_fields ~seq ~csh scopes (("s", "req", "b") :: promises))

let approve_plan ~seq = Lines.approval_of_hash ~seq plan ~csh

let check_with_set name expected lines =
  Alcotest.(check (option (pair string string)))
    name
    (Option.map (fun (approval, set) -> (id approval, id set)) expected)
    (Option.map
       (fun ((approval : Ledger.entry), (set : Ledger.entry)) ->
         (approval.id, set.id))
       (Folds.latest_approval_with_set (folds_of lines) ~subject:plan))

let an_approval_takes_the_latest_set_below_it () =
  let one = set ~seq:1
  and two = set ~seq:2
  and approval = approve_plan ~seq:3 in
  check_with_set "the latest set" (Some (approval, two)) [ one; two; approval ];
  check_with_set "a later set changes nothing"
    (Some (approval, one))
    [ one; approval; set ~seq:3 ]

let an_approval_with_no_set_below_it_counts_for_nothing () =
  check_with_set "the set comes later" None [ approve_plan ~seq:1; set ~seq:2 ];
  check_with_set "no set" None [ approve_plan ~seq:1 ]

let a_set_whose_hash_does_not_hold_gives_no_set () =
  let good = set ~seq:1
  and bad = wrong_set ~seq:2
  and approval = approve_plan ~seq:3 in
  check_with_set "only a bad set" None [ wrong_set ~seq:1; approve_plan ~seq:2 ];
  check_with_set "the good set stays"
    (Some (approval, good))
    [ good; bad; approval ]

let an_approval_of_a_plan_with_rev_and_xh_has_no_set () =
  check_with_set "no set" None
    [ set ~seq:1; Lines.approval_of_text ~seq:2 plan ~rev:1 ~xh:csh ]

let the_latest_approval_with_a_set_decides () =
  let other_scopes = [ (None, "lib/**") ] in
  let other = Lines.set_hash other_scopes promises in
  let wide = approve_plan ~seq:2 in
  let narrow_set = Lines.commitment_set ~seq:3 other_scopes promises in
  let narrow = Lines.approval_of_hash ~seq:4 plan ~csh:other in
  check_with_set "the later one"
    (Some (narrow, narrow_set))
    [ set ~seq:1; wide; narrow_set; narrow ];
  let first_set = set ~seq:1 in
  check_with_set "an approval with no set is passed over"
    (Some (wide, first_set))
    [ first_set; wide; Lines.approval_of_hash ~seq:3 plan ~csh:other ]

let check_plan_declines name expected ~hash lines =
  let folds = folds_of lines in
  let judged = Folds.plan folds ~subject:plan ~hash in
  Alcotest.(check (list string))
    name (List.map id expected)
    (ids (Folds.live folds ~subject:plan ~hash ~after:judged.after));
  Alcotest.(check (option string))
    (name ^ ": the latest")
    (Option.map id (List.nth_opt (List.rev expected) 0))
    (Option.map (fun (entry : Ledger.entry) -> entry.id) judged.latest_live)

let a_plan_decline_is_live_with_no_approval () =
  let refusal = Lines.decline ~seq:1 plan ~hash:csh ~reason:"no" in
  check_plan_declines "live" [ refusal ] ~hash:csh [ refusal ]

let an_approval_without_its_set_ends_no_plan_decline () =
  let refusal = Lines.decline ~seq:1 plan ~hash:csh ~reason:"no" in
  check_plan_declines "live" [ refusal ] ~hash:csh
    [ refusal; approve_plan ~seq:2 ]

let the_latest_approval_with_a_set_ends_each_earlier_plan_decline () =
  let refusal = Lines.decline ~seq:1 plan ~hash:x ~reason:"no" in
  let lines = [ refusal; set ~seq:2; approve_plan ~seq:3 ] in
  check_plan_declines "ended at another hash too" [] ~hash:x lines

let a_plan_decline_after_the_approval_is_live () =
  let refusal = Lines.decline ~seq:3 plan ~hash:csh ~reason:"no" in
  check_plan_declines "live" [ refusal ] ~hash:csh
    [ set ~seq:1; approve_plan ~seq:2; refusal ]

let a_live_decline_of_a_plan_leaves_its_latest_approval_named () =
  let approval = approve_plan ~seq:2 in
  let judged =
    Folds.plan
      (folds_of
         [
           set ~seq:1;
           approval;
           Lines.decline ~seq:3 plan ~hash:csh ~reason:"no";
         ])
      ~subject:plan ~hash:csh
  in
  Alcotest.(check (option string))
    "the approval"
    (Some (id approval))
    (Option.map (fun (entry : Ledger.entry) -> entry.id) judged.approval)

let a_plan_decline_at_another_hash_is_not_live () =
  let refusal = Lines.decline ~seq:1 plan ~hash:x ~reason:"no" in
  check_plan_declines "another hash" [] ~hash:y [ refusal ]

let check_closing name expected lines =
  Alcotest.(check (option string))
    name (Option.map id expected)
    (Option.map
       (fun (entry : Ledger.entry) -> entry.id)
       (Folds.closing (folds_of lines) ~subject:plan))

let the_first_closing_closes_the_plan () =
  let first = Lines.completed ~seq:1 plan in
  check_closing "completed, then abandoned" (Some first)
    [ first; Lines.abandoned ~seq:2 plan ~reason:"late" ];
  let first = Lines.abandoned ~seq:1 plan ~reason:"stop" in
  check_closing "abandoned, then completed" (Some first)
    [ first; Lines.completed ~seq:2 plan ]

let a_closing_of_another_form_closes_nothing () =
  check_closing "no plan id" None [ Lines.completed ~seq:1 "plan:p" ]

let a_delivered_entry_matches_its_hash_and_starts_at_any_hash () =
  let folds = folds_of [ Lines.delivered ~seq:1 step ~csh:x ] in
  Alcotest.(check bool)
    "at x" true
    (Folds.delivered folds ~subject:step ~hash:x);
  Alcotest.(check bool)
    "at y" false
    (Folds.delivered folds ~subject:step ~hash:y);
  Alcotest.(check bool)
    "another step" false
    (Folds.delivered folds ~subject:"step:p@abc123/t" ~hash:x);
  Alcotest.(check bool) "started" true (Folds.started folds ~subject:step);
  Alcotest.(check bool)
    "another step is not started" false
    (Folds.started folds ~subject:"step:p@abc123/t")

let live_leaves_out_a_decline_at_after_and_takes_one_above () =
  let early = decline ~seq:2 and late = decline ~seq:4 in
  let folds = folds_of [ approve ~seq:1; early; approve ~seq:3; late ] in
  let live after =
    List.map
      (fun (entry : Ledger.entry) -> entry.id)
      (Folds.live folds ~subject ~hash:x ~after)
  in
  Alcotest.(check (list string)) "after the late seq" [] (live 4);
  Alcotest.(check (list string)) "after the early seq" [ id late ] (live 2);
  Alcotest.(check (list string))
    "one below the early seq"
    [ id early; id late ]
    (live 1);
  Alcotest.(check (list string)) "one below the late seq" [ id late ] (live 3)

let a_void_entry_cancels_nothing () =
  let approval = approve ~seq:1 in
  check_judged "the approval stays" ~approval:(Some approval) ~live:[]
    (declaration
       [ approval; Lines.void ~seq:2 ~dropped:(id approval) ~reason:"gone" ])

let subjects = [ "req:a"; "req:b"; "plan:p"; "step:p/s" ]
let revs = [ 1; 2 ]

let sets =
  List.map
    (fun glob ->
      let scopes = [ (None, glob) ] and promises = [ ("s", "req", "a") ] in
      (scopes, promises, Lines.set_hash scopes promises))
    [ "a/**"; "b/**" ]

let hashes = Lines.hash 1 :: Lines.hash 2 :: List.map (fun (_, _, h) -> h) sets

type made =
  | Text of string * int * string
  | Hash of string * string
  | Good_set of int
  | Bad_set of int
  | Refusal of string * string
  | Delivery of string * string
  | Completion of string
  | Abandon of string
  | Dropped
  | Unknown_kind

let made_gen =
  let open Gen in
  let subject = oneof_list subjects
  and hash = oneof_list hashes
  and rev = oneof_list revs
  and set = int_range 0 (List.length sets - 1) in
  oneof_weighted
    [
      (3, map3 (fun s r h -> Text (s, r, h)) subject rev hash);
      (4, map2 (fun s h -> Hash (s, h)) subject hash);
      (3, map (fun n -> Good_set n) set);
      (1, map (fun n -> Bad_set n) set);
      (4, map2 (fun s h -> Refusal (s, h)) subject hash);
      (2, map2 (fun s h -> Delivery (s, h)) subject hash);
      (1, map (fun s -> Completion s) subject);
      (1, map (fun s -> Abandon s) subject);
      (1, pure Dropped);
      (1, pure Unknown_kind);
    ]

let line_of_made seq = function
  | Text (subject, rev, xh) -> Lines.approval_of_text ~seq subject ~rev ~xh
  | Hash (subject, csh) -> Lines.approval_of_hash ~seq subject ~csh
  | Good_set n ->
      let scopes, promises, _ = List.nth sets n in
      Lines.commitment_set ~seq scopes promises
  | Bad_set n ->
      let scopes, promises, csh = List.nth sets n in
      Lines.line_of
        (Lines.set_fields ~seq ~csh scopes (("t", "req", "z") :: promises))
  | Refusal (subject, hash) -> Lines.decline ~seq subject ~hash ~reason:"no"
  | Delivery (subject, csh) -> Lines.delivered ~seq subject ~csh
  | Completion subject -> Lines.completed ~seq subject
  | Abandon subject -> Lines.abandoned ~seq subject ~reason:"stop"
  | Dropped -> Lines.void ~seq ~dropped:"e-000000000000" ~reason:"gone"
  | Unknown_kind -> Lines.unknown ~seq "future"

let numbered made =
  List.mapi
    (fun index item -> (index + 1, item, line_of_made (index + 1) item))
    made

let latest = function
  | [] -> None
  | items -> Some (List.fold_left max min_int items)

let seqs select items =
  List.filter_map
    (fun (seq, item, _) -> if select item then Some seq else None)
    items

let line_at items seq =
  List.find_map
    (fun (at, _, line) -> if at = seq then Some (id line) else None)
    items

let model_judged items ~approved ~declined =
  let approvals = seqs approved items and declines = seqs declined items in
  let last = latest approvals in
  let live =
    List.filter (fun d -> not (List.exists (fun a -> a > d) approvals)) declines
  in
  ( (if live = [] then Option.bind last (line_at items) else None),
    List.filter_map (line_at items) live )

let model_declaration items subject rev xh =
  model_judged items
    ~approved:(function
      | Text (s, r, h) -> s = subject && r = rev && h = xh | _ -> false)
    ~declined:(function Refusal (s, h) -> s = subject && h = xh | _ -> false)

let model_step items subject hash =
  model_judged items
    ~approved:(function Hash (s, h) -> s = subject && h = hash | _ -> false)
    ~declined:(function
      | Refusal (s, h) -> s = subject && h = hash | _ -> false)

let set_hash_of n =
  let _, _, h = List.nth sets n in
  h

let model_set_entry items approval_seq csh =
  latest
    (seqs
       (function Good_set n -> set_hash_of n = csh | _ -> false)
       (List.filter (fun (seq, _, _) -> seq < approval_seq) items))

let model_with_set items subject =
  let found =
    List.filter_map
      (fun (seq, item, _) ->
        match item with
        | Hash (s, csh) when s = subject ->
            Option.map (fun set -> (seq, set)) (model_set_entry items seq csh)
        | _ -> None)
      items
  in
  match List.rev found with
  | [] -> None
  | (approval, set) :: _ -> Some (approval, set)

let model_plan_declines items subject hash =
  let after =
    match model_with_set items subject with
    | Some (approval, _) -> approval
    | None -> 0
  in
  List.filter_map (line_at items)
    (List.filter
       (fun seq -> seq > after)
       (seqs
          (function Refusal (s, h) -> s = subject && h = hash | _ -> false)
          items))

let model_closing items subject =
  Option.bind
    (List.nth_opt
       (seqs
          (function Completion s | Abandon s -> s = subject | _ -> false)
          items)
       0)
    (line_at items)

let model_observed items =
  List.concat_map
    (fun subject ->
      Option.to_list (model_closing items subject)
      @ (match model_with_set items subject with
        | Some (approval, set) ->
            List.filter_map (line_at items) [ approval; set ]
        | None -> [])
      @ List.concat_map
          (fun hash ->
            let declaration =
              List.concat_map
                (fun rev ->
                  let approval, live =
                    model_declaration items subject rev hash
                  in
                  Option.to_list approval @ live)
                revs
            and approval, live = model_step items subject hash in
            declaration @ Option.to_list approval @ live
            @ model_plan_declines items subject hash
            @
            if
              List.exists
                (fun (_, item, _) -> item = Delivery (subject, hash))
                items
            then [ "delivered" ]
            else [])
          hashes
      @
      if
        List.exists
          (fun (_, item, _) ->
            match item with Delivery (s, _) -> s = subject | _ -> false)
          items
      then [ "started" ]
      else [])
    subjects

let observed folds =
  let judged ~subject ~hash (judged : Folds.judged) =
    Option.to_list
      (Option.map (fun (entry : Ledger.entry) -> entry.id) judged.approval)
    @ ids (Folds.live folds ~subject ~hash ~after:judged.after)
  in
  List.concat_map
    (fun subject ->
      Option.to_list
        (Option.map
           (fun (entry : Ledger.entry) -> entry.id)
           (Folds.closing folds ~subject))
      @ (match Folds.latest_approval_with_set folds ~subject with
        | Some ((approval : Ledger.entry), (set : Ledger.entry)) ->
            [ approval.id; set.id ]
        | None -> [])
      @ List.concat_map
          (fun hash ->
            List.concat_map
              (fun rev ->
                judged ~subject ~hash
                  (Folds.declaration folds ~subject ~rev ~xh:hash))
              revs
            @ judged ~subject ~hash (Folds.step folds ~subject ~hash)
            @ ids
                (Folds.live folds ~subject ~hash
                   ~after:(Folds.plan folds ~subject ~hash).after)
            @
            if Folds.delivered folds ~subject ~hash then [ "delivered" ] else [])
          hashes
      @ if Folds.started folds ~subject then [ "started" ] else [])
    subjects

let lines_of items = List.map (fun (_, _, line) -> line) items
let sequence = Gen.(list_size (int_range 0 25) made_gen)

let property ?(count = 200) name check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name
       ~print:(fun made -> Printf.sprintf "%d entries" (List.length made))
       sequence check)

let many_lookups_cost_the_same_with_many_declines () =
  let declines count =
    Folds.of_entries
      (Lines.entries
         (approve ~seq:1 :: List.init count (fun n -> decline ~seq:(n + 2))))
  in
  Counted_work.check_growth ~exponent:0. ~margin:1.5 ~sizes:(10, 400)
    ~input:declines (fun folds ->
      for _ = 1 to 1_000 do
        ignore (Folds.declaration folds ~subject ~rev:1 ~xh:x);
        ignore (Folds.step folds ~subject ~hash:x);
        ignore (Folds.plan folds ~subject ~hash:x)
      done)

let the_folds_agree_with_the_model =
  property "the folds agree with the text of each section" (fun made ->
      let items = numbered made in
      List.equal String.equal (model_observed items)
        (observed (folds_of (lines_of items))))

let void_and_unknown_kinds_change_nothing =
  property "void entries and unknown kinds change nothing" (fun made ->
      let items = numbered made in
      let kept =
        List.filter
          (fun (_, item, _) ->
            match item with Dropped | Unknown_kind -> false | _ -> true)
          items
      in
      List.equal String.equal
        (observed (folds_of (lines_of items)))
        (observed (folds_of (lines_of kept))))

let each_prefix_agrees =
  property ~count:60 "each prefix of the entries agrees with the model"
    (fun made ->
      let items = numbered made in
      List.for_all
        (fun length ->
          let prefix = List.filteri (fun index _ -> index < length) items in
          List.equal String.equal (model_observed prefix)
            (observed (folds_of (lines_of prefix))))
        (List.init (List.length items + 1) Fun.id))

let chunked_read lines chunks =
  let repo = Git_fixture.init () in
  let rec split = function
    | [] -> []
    | lines ->
        let first = List.filteri (fun index _ -> index < chunks) lines
        and rest = List.filteri (fun index _ -> index >= chunks) lines in
        first :: split rest
  in
  let files =
    List.map
      (fun chunk ->
        let first = id (List.hd chunk) in
        Git_fixture.File
          ( Printf.sprintf "entries/%s/%s.jsonl" (String.sub first 2 2) first,
            String.concat "" (List.map (fun line -> line ^ "\n") chunk) ))
      (split lines)
  in
  Git_fixture.import repo
    [ Git_fixture.commit ~ref:Ledger.ref_name ~mark:1 ~message:"l" files ];
  match Git.open_repo ~env:(Git_fixture.env repo) (Git_fixture.root repo) with
  | Error _ -> Alcotest.fail "the repository does not open"
  | Ok git -> (
      match Ledger.read git Ledger.Tip with
      | Ok (Some ledger) -> Ledger.entries ledger
      | Ok None | Error _ -> Alcotest.fail "the ledger does not read")

let two_chunkings_give_one_result =
  property ~count:10 "two chunkings of one sequence give one result"
    (fun made ->
      let lines = lines_of (numbered made) in
      lines = []
      || List.equal String.equal
           (observed (Folds.of_entries (chunked_read lines 1)))
           (observed (Folds.of_entries (chunked_read lines 50))))

let case name test = Alcotest.test_case name `Quick test

let tests =
  [
    case "no entry gives no judgment" no_entry_gives_no_judgment;
    case "the latest approval of the triple counts"
      the_latest_approval_of_the_triple_counts;
    case "a decline after the approval removes it"
      a_decline_after_the_approval_removes_it;
    case "an approval after the decline ends it"
      an_approval_after_the_decline_ends_it;
    case "two declines after the approval are both live"
      two_declines_after_the_approval_are_both_live;
    case "only the declines after the approval are live"
      only_the_declines_after_the_approval_are_live;
    case "a bare revision bump removes the approval"
      a_bare_revision_bump_removes_the_approval;
    case "a bare revision bump makes a decline live again"
      a_bare_revision_bump_makes_a_decline_live_again;
    case "a judgment at another text counts for nothing"
      a_judgment_at_another_text_counts_for_nothing;
    case "the subject matches by all its bytes"
      the_subject_matches_by_all_its_bytes;
    case "a step takes the same rule" a_step_takes_the_same_rule;
    case "an approval takes the latest set below it"
      an_approval_takes_the_latest_set_below_it;
    case "an approval with no set below it counts for nothing"
      an_approval_with_no_set_below_it_counts_for_nothing;
    case "a set whose hash does not hold gives no set"
      a_set_whose_hash_does_not_hold_gives_no_set;
    case "an approval of a plan with rev and xh has no set"
      an_approval_of_a_plan_with_rev_and_xh_has_no_set;
    case "the latest approval with a set decides"
      the_latest_approval_with_a_set_decides;
    case "a plan decline is live with no approval"
      a_plan_decline_is_live_with_no_approval;
    case "an approval without its set ends no plan decline"
      an_approval_without_its_set_ends_no_plan_decline;
    case "the latest approval with a set ends each earlier plan decline"
      the_latest_approval_with_a_set_ends_each_earlier_plan_decline;
    case "a plan decline after the approval is live"
      a_plan_decline_after_the_approval_is_live;
    case "a live decline of a plan leaves its latest approval named"
      a_live_decline_of_a_plan_leaves_its_latest_approval_named;
    case "a plan decline at another hash is not live"
      a_plan_decline_at_another_hash_is_not_live;
    case "the first closing closes the plan" the_first_closing_closes_the_plan;
    case "a closing of another form closes nothing"
      a_closing_of_another_form_closes_nothing;
    case "a delivered entry matches its hash and starts at any hash"
      a_delivered_entry_matches_its_hash_and_starts_at_any_hash;
    case "a void entry cancels nothing" a_void_entry_cancels_nothing;
    case "live leaves out a decline at after and takes one above"
      live_leaves_out_a_decline_at_after_and_takes_one_above;
    case "many lookups cost the same with many declines"
      many_lookups_cost_the_same_with_many_declines;
    the_folds_agree_with_the_model;
    void_and_unknown_kinds_change_nothing;
    each_prefix_agrees;
    two_chunkings_give_one_result;
  ]
