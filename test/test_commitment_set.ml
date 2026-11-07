(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_core
module Gen = QCheck2.Gen

let step scope promises = { Commitment_set.scope; promises }

let lockout =
  [
    step [ "src/auth/**" ]
      [ ("req", "auth-lockout"); ("verifies", "auth-lockout") ];
    step [ "src/**" ] [ ("decision", "lockout-policy") ];
  ]

let lockout_bytes =
  {|{"groups":[{"promises":[{"target":"lockout-policy","word":"decision"}],"scope":["src/**"]},{"promises":[{"target":"auth-lockout","word":"req"},{"target":"auth-lockout","word":"verifies"}],"scope":["src/auth/**"]}],"scope":["src/**"]}|}

let the_example_of_the_specification () =
  Alcotest.(check string)
    "the bytes" lockout_bytes
    (Commitment_set.bytes ~scope:[ "src/**" ] lockout);
  Alcotest.(check string)
    "the hash" (Sha256.hex lockout_bytes)
    (Commitment_set.hash ~scope:[ "src/**" ] lockout)

let an_empty_set () =
  Alcotest.(check string)
    "the bytes" {|{"groups":[],"scope":[]}|}
    (Commitment_set.bytes ~scope:[] [])

let a_step_with_no_promise_adds_nothing () =
  Alcotest.(check string)
    "the bytes" {|{"groups":[],"scope":[]}|}
    (Commitment_set.bytes ~scope:[] [ step [ "a" ] [] ])

let equal_promises_stay_two () =
  Alcotest.(check string)
    "the bytes"
    {|{"groups":[{"promises":[{"target":"t","word":"req"},{"target":"t","word":"req"}],"scope":["a"]}],"scope":[]}|}
    (Commitment_set.bytes ~scope:[]
       [ step [ "a" ] [ ("req", "t") ]; step [ "a"; "a" ] [ ("req", "t") ] ])

let promises_sort_by_word_and_target_in_each_group () =
  Alcotest.(check string)
    "the bytes"
    {|{"groups":[{"promises":[{"target":"t","word":"req"},{"target":"u","word":"req"},{"target":"a","word":"verifies"}],"scope":["a"]},{"promises":[{"target":"t","word":"req"}],"scope":["b"]}],"scope":["x","y"]}|}
    (Commitment_set.bytes ~scope:[ "y"; "x"; "y" ]
       [
         step [ "b" ] [ ("req", "t") ];
         step [ "a" ] [ ("verifies", "a"); ("req", "u"); ("req", "t") ];
       ])

let groups_sort_by_the_bytes_of_their_scope () =
  Alcotest.(check string)
    "the bytes"
    {|{"groups":[{"promises":[{"target":"t","word":"req"}],"scope":["a","c"]},{"promises":[{"target":"t","word":"req"}],"scope":["a-b"]},{"promises":[{"target":"t","word":"req"}],"scope":["b"]},{"promises":[{"target":"t","word":"req"}],"scope":[]}],"scope":[]}|}
    (Commitment_set.bytes ~scope:[]
       [
         step [] [ ("req", "t") ];
         step [ "b" ] [ ("req", "t") ];
         step [ "a-b" ] [ ("req", "t") ];
         step [ "c"; "a" ] [ ("req", "t") ];
       ])

let text_that_is_not_utf_8 () =
  let error =
    Invalid_argument
      "Sinter_core.Commitment_set.hash: a glob, a word, or a target is not \
       UTF-8"
  in
  Alcotest.check_raises "the hash" error (fun () ->
      ignore (Commitment_set.hash ~scope:[ "\xff" ] []));
  Alcotest.check_raises "the bytes" error (fun () ->
      ignore
        (Commitment_set.bytes ~scope:[] [ step [ "\xff" ] [ ("req", "t") ] ]));
  Alcotest.check_raises "a word" error (fun () ->
      ignore (Commitment_set.hash ~scope:[] [ step [] [ ("\xff", "t") ] ]));
  Alcotest.check_raises "a target" error (fun () ->
      ignore (Commitment_set.hash ~scope:[] [ step [] [ ("req", "\xff") ] ]))

let a_glob_of_a_step_with_no_promise_is_not_read () =
  Alcotest.(check string)
    "the bytes" {|{"groups":[],"scope":[]}|}
    (Commitment_set.bytes ~scope:[] [ step [ "\xff" ] [] ])

let text =
  Gen.oneof
    [
      Gen.oneof_list [ "a"; "b"; "c"; "src/**"; "a\"b"; "\\" ];
      Generators.utf_8_string;
    ]

let steps =
  Gen.(
    pair
      (list_size (int_range 0 4) text)
      (list_size (int_range 0 4)
         (map2 step
            (list_size (int_range 0 3) text)
            (list_size (int_range 0 3) (pair text text)))))

let print (scope, steps) =
  Printf.sprintf "scope [%s], %d steps" (String.concat "; " scope)
    (List.length steps)

let property name check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:300 ~name ~print steps check)

let order_changes_nothing =
  property "the order of the scope, the steps, and the globs changes nothing"
    (fun (scope, steps) ->
      String.equal
        (Commitment_set.hash ~scope steps)
        (Commitment_set.hash ~scope:(List.rev scope)
           (List.rev_map
              (fun (s : Commitment_set.step) ->
                step (List.rev s.scope) (List.rev s.promises))
              steps)))

module Triples = Map.Make (struct
  type t = string * string * string list

  let compare = compare
end)

let triples steps =
  List.fold_left
    (fun found (s : Commitment_set.step) ->
      let scope = List.sort_uniq String.compare s.scope in
      List.fold_left
        (fun found (word, target) ->
          Triples.update (word, target, scope)
            (fun count -> Some (1 + Option.value count ~default:0))
            found)
        found s.promises)
    Triples.empty steps

let equal_sets_give_one_hash =
  property "two steps with one scope merge, and the order of steps is free"
    (fun (scope, steps) ->
      let merged =
        List.map
          (fun ((word, target, globs), count) ->
            step globs (List.init count (fun _ -> (word, target))))
          (Triples.bindings (triples steps))
      in
      String.equal
        (Commitment_set.hash ~scope steps)
        (Commitment_set.hash ~scope merged))

let the_bytes_tell_apart_each_multiset_of_triples =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:300
       ~name:"two sets with two multisets of promises give two sets of bytes"
       ~print:(fun ((_, a), (_, b)) ->
         Printf.sprintf "%d and %d steps" (List.length a) (List.length b))
       Gen.(pair steps steps)
       (fun ((scope_a, a), (scope_b, b)) ->
         let same_set =
           Triples.equal Int.equal (triples a) (triples b)
           && List.sort_uniq String.compare scope_a
              = List.sort_uniq String.compare scope_b
         in
         Bool.equal same_set
           (String.equal
              (Commitment_set.bytes ~scope:scope_a a)
              (Commitment_set.bytes ~scope:scope_b b))))

let the_bytes_grow_with_the_input =
  property "the bytes hold each scope once, not once for each promise"
    (fun (scope, steps) ->
      let text = List.map (fun t -> String.length t + 8) in
      let size =
        List.fold_left ( + ) 0 (text scope)
        + List.fold_left
            (fun total (s : Commitment_set.step) ->
              total
              + List.fold_left ( + ) 0 (text s.scope)
              + List.fold_left
                  (fun total (word, target) ->
                    total + String.length word + String.length target)
                  0 s.promises
              + (40 * List.length s.promises))
            0 steps
      in
      String.length (Commitment_set.bytes ~scope steps) <= 24 + (6 * size))

let the_hash_is_the_hash_of_the_bytes =
  property "the hash is the SHA-256 of the bytes" (fun (scope, steps) ->
      String.equal
        (Commitment_set.hash ~scope steps)
        (Sha256.hex (Commitment_set.bytes ~scope steps)))

let stated ?own slug promises =
  { Commitment_set.slug; own; stated_promises = promises }

let set ?(plan_scope = [ "src/**" ]) steps =
  { Commitment_set.plan_scope; steps }

let the_hash_of_a_set_lets_a_step_take_the_plan_scope () =
  Alcotest.(check string)
    "the same hash"
    (Commitment_set.hash ~scope:[ "src/**" ] lockout)
    (Commitment_set.hash_of_set
       (set
          [
            stated "lock" ~own:[ "src/auth/**" ]
              [ ("req", "auth-lockout"); ("verifies", "auth-lockout") ];
            stated "record" [ ("decision", "lockout-policy") ];
          ]))

let difference =
  Alcotest.testable
    (fun formatter (d : Commitment_set.difference) ->
      let pairs list =
        String.concat ", " (List.map (fun (w, t) -> w ^ ":" ^ t) list)
      in
      Format.fprintf formatter "added [%s], removed [%s], wider [%s]"
        (pairs d.added) (pairs d.removed)
        (String.concat ", " d.wider))
    ( = )

let check_compared name expected ~current ~approved =
  Alcotest.(check (option difference))
    name expected
    (Commitment_set.compare_sets ~current ~approved)

let wider globs =
  Some { Commitment_set.added = []; removed = []; wider = globs }

let approved_with_exclusion = [ "src/**"; "!src/secret/**" ]

let the_rows_of_the_exclusions =
  [
    ("src/**", [ "src/**" ], wider [ "!src/secret/**" ]);
    ( "one more exclusion",
      [ "src/**"; "!src/secret/**"; "!src/vendor/**" ],
      None );
    ("narrower", [ "src/api/**"; "!src/secret/**" ], None);
    ("narrower with no exclusion", [ "src/api/**" ], wider [ "!src/secret/**" ]);
  ]

let exclusions_of_a_plan_scope () =
  List.iter
    (fun (name, scope, expected) ->
      check_compared name expected ~current:(set ~plan_scope:scope [])
        ~approved:(set ~plan_scope:approved_with_exclusion []))
    the_rows_of_the_exclusions

let exclusions_of_a_step_scope () =
  List.iter
    (fun (name, scope, expected) ->
      check_compared name expected
        ~current:(set [ stated "s" ~own:scope [ ("req", "a") ] ])
        ~approved:
          (set [ stated "s" ~own:approved_with_exclusion [ ("req", "a") ] ]))
    the_rows_of_the_exclusions

let an_equal_set_has_no_difference () =
  let same = set [ stated "s" ~own:[ "src/a/**" ] [ ("req", "a") ] ] in
  check_compared "equal" None ~current:same ~approved:same

let a_promise_added_or_removed_is_a_difference () =
  let one = set [ stated "s" [ ("req", "a") ] ]
  and two = set [ stated "s" [ ("req", "a"); ("req", "b") ] ] in
  check_compared "added"
    (Some { added = [ ("req", "b") ]; removed = []; wider = [] })
    ~current:two ~approved:one;
  check_compared "removed"
    (Some { added = []; removed = [ ("req", "b") ]; wider = [] })
    ~current:one ~approved:two

let the_count_of_a_promise_counts () =
  let one = set [ stated "s" [ ("req", "a") ] ]
  and two = set [ stated "s" [ ("req", "a") ]; stated "t" [ ("req", "a") ] ] in
  check_compared "a second copy"
    (Some { added = [ ("req", "a") ]; removed = []; wider = [] })
    ~current:two ~approved:one;
  check_compared "a second copy gone"
    (Some { added = []; removed = [ ("req", "a") ]; wider = [] })
    ~current:one ~approved:two

let a_wider_plan_scope_is_a_difference () =
  check_compared "wider" (wider [ "lib/**" ])
    ~current:(set ~plan_scope:[ "src/**"; "lib/**" ] [])
    ~approved:(set [])

let a_rename_of_a_step_is_free () =
  check_compared "free" None
    ~current:(set [ stated "new" ~own:[ "src/a/**" ] [ ("req", "a") ] ])
    ~approved:(set [ stated "old" ~own:[ "src/a/**" ] [ ("req", "a") ] ])

let a_narrower_scope_is_free_and_a_wider_one_is_not () =
  let approved = set [ stated "s" ~own:[ "src/a/**" ] [ ("req", "a") ] ] in
  check_compared "narrower" None
    ~current:(set [ stated "s" ~own:[ "src/a/b/**" ] [ ("req", "a") ] ])
    ~approved;
  check_compared "wider" (wider [ "src/**" ])
    ~current:(set [ stated "s" ~own:[ "src/**" ] [ ("req", "a") ] ])
    ~approved

let a_step_takes_the_plan_scope_on_each_side () =
  check_compared "the step leaves its own scope" (wider [ "src/**" ])
    ~current:(set [ stated "s" [ ("req", "a") ] ])
    ~approved:(set [ stated "s" ~own:[ "src/a/**" ] [ ("req", "a") ] ]);
  check_compared "the step takes an own scope inside" None
    ~current:(set [ stated "s" ~own:[ "src/a/**" ] [ ("req", "a") ] ])
    ~approved:(set [ stated "s" [ ("req", "a") ] ])

let equal_slugs_match_first () =
  let approved =
    set
      [
        stated "b" ~own:[ "b/**" ] [ ("req", "a") ];
        stated "c" ~own:[ "c/**" ] [ ("req", "a") ];
      ]
  in
  check_compared "c stays c, and the new step takes the place of b" None
    ~current:
      (set
         [
           stated "a" ~own:[ "b/**" ] [ ("req", "a") ];
           stated "c" ~own:[ "c/**" ] [ ("req", "a") ];
         ])
    ~approved

let an_equal_slug_matches_before_the_order_of_the_rest () =
  check_compared "z with z, and a with zz" None
    ~current:
      (set
         [
           stated "a" ~own:[ "x/**" ] [ ("req", "a") ];
           stated "z" ~own:[ "y/**" ] [ ("req", "a") ];
         ])
    ~approved:
      (set
         [
           stated "z" ~own:[ "y/**" ] [ ("req", "a") ];
           stated "zz" ~own:[ "x/**" ] [ ("req", "a") ];
         ])

let the_rest_match_in_the_order_of_their_slugs () =
  let approved =
    set
      [
        stated "m" ~own:[ "m/**" ] [ ("req", "a") ];
        stated "n" ~own:[ "n/**" ] [ ("req", "a") ];
      ]
  in
  check_compared "x with m and y with n" None
    ~current:
      (set
         [
           stated "y" ~own:[ "n/**" ] [ ("req", "a") ];
           stated "x" ~own:[ "m/**" ] [ ("req", "a") ];
         ])
    ~approved;
  check_compared "x with m and y with n, and the scopes cross"
    (wider [ "m/**"; "n/**" ])
    ~current:
      (set
         [
           stated "x" ~own:[ "n/**" ] [ ("req", "a") ];
           stated "y" ~own:[ "m/**" ] [ ("req", "a") ];
         ])
    ~approved

let two_steps_with_one_slug_match_by_their_scope () =
  let steps first second =
    set
      [
        stated "s" ~own:[ first ] [ ("req", "a") ];
        stated "s" ~own:[ second ] [ ("req", "a") ];
      ]
  in
  check_compared "the order of the steps changes nothing" None
    ~current:(steps "b/**" "a/**") ~approved:(steps "a/**" "b/**")

let the_comparison_stops_at_no_promise_of_the_other_side () =
  check_compared "added and wider together"
    (Some
       {
         added = [ ("req", "b") ];
         removed = [ ("req", "c") ];
         wider = [ "lib/**"; "src/**" ];
       })
    ~current:
      (set ~plan_scope:[ "src/**"; "lib/**" ]
         [ stated "s" [ ("req", "a"); ("req", "b") ] ])
    ~approved:
      (set ~plan_scope:[ "docs/**" ]
         [ stated "s" ~own:[ "docs/**" ] [ ("req", "a"); ("req", "c") ] ])

let a_set_compares_at_no_cost_for_each_promise () =
  let globs side = List.init 300 (Printf.sprintf "%s/%04d.md" side) in
  let current = globs "new" and approved = globs "old" in
  let promises count =
    List.init count (fun n -> ("req", Printf.sprintf "t%d" n))
  in
  let compared count =
    ( set [ stated "s" ~own:current (promises count) ],
      set [ stated "s" ~own:approved (promises count) ] )
  in
  Counted_work.check_growth ~exponent:0. ~margin:3. ~sizes:(10, 400)
    ~input:compared (fun (current, approved) ->
      Commitment_set.compare_sets ~current ~approved)

let a_wide_scope_of_many_promises_is_reported_once () =
  let compared count =
    let globs = List.init count (Printf.sprintf "new/%05d.md") in
    let promises = List.init count (fun n -> ("req", Printf.sprintf "t%d" n)) in
    ( set [ stated "s" ~own:globs promises ],
      set [ stated "s" ~own:[ "old/**" ] promises ] )
  in
  Counted_work.check_growth ~margin:3. ~sizes:(100, 1_600) ~input:compared
    (fun (current, approved) -> Commitment_set.compare_sets ~current ~approved)

let a_set_compares_verbatim_globs_at_no_quadratic_cost () =
  let compared count =
    let globs = List.init count (Printf.sprintf "dir/%05d.md") in
    (set ~plan_scope:globs [], set ~plan_scope:globs [])
  in
  Counted_work.check_growth ~margin:3. ~sizes:(200, 3_200) ~input:compared
    (fun (current, approved) -> Commitment_set.compare_sets ~current ~approved)

let many_steps_with_the_plan_scope_build_it_once () =
  let compared count =
    let globs = List.init 1_000 (Printf.sprintf "dir/%05d.md") in
    let steps =
      List.init count (fun n ->
          stated (Printf.sprintf "s%d" n) [ ("req", Printf.sprintf "t%d" n) ])
    in
    set ~plan_scope:globs steps
  in
  Counted_work.check_growth ~exponent:0. ~margin:3. ~sizes:(10, 400)
    ~input:compared Commitment_set.hash_of_set

let a_set_gen =
  let open Gen in
  let glob = oneof_list [ "a/**"; "a/b/**"; "b/**"; "!a/x/**"; "c.md"; "**" ] in
  let step =
    map3
      (fun slug own promises -> stated slug ?own promises)
      (oneof_list [ "s"; "t"; "u" ])
      (option (list_size (int_range 0 3) glob))
      (list_size (int_range 0 3)
         (pair (oneof_list [ "req"; "cites" ]) (oneof_list [ "a"; "b" ])))
  in
  map2
    (fun plan_scope steps -> set ~plan_scope steps)
    (list_size (int_range 0 3) glob)
    (list_size (int_range 0 3) step)

let print_set (s : Commitment_set.set) =
  Printf.sprintf "plan scope [%s], %d steps"
    (String.concat ", " s.plan_scope)
    (List.length s.steps)

let a_set_is_approved_against_itself =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:300 ~name:"a set is approved against itself"
       ~print:print_set a_set_gen (fun s ->
         Option.is_none (Commitment_set.compare_sets ~current:s ~approved:s)))

let the_counts_of_promises_agree_with_the_difference =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:300
       ~name:"added less removed is the change in the number of promises"
       ~print:(fun (a, b) -> print_set a ^ "; " ^ print_set b)
       (Gen.pair a_set_gen a_set_gen)
       (fun (current, approved) ->
         let count (s : Commitment_set.set) =
           List.fold_left
             (fun total (step : Commitment_set.stated) ->
               total + List.length step.stated_promises)
             0 s.steps
         in
         match Commitment_set.compare_sets ~current ~approved with
         | None -> count current = count approved
         | Some d ->
             List.length d.added - List.length d.removed
             = count current - count approved))

let tests =
  [
    Alcotest.test_case "the example of the specification" `Quick
      the_example_of_the_specification;
    Alcotest.test_case "an empty set" `Quick an_empty_set;
    Alcotest.test_case "a step with no promise adds nothing" `Quick
      a_step_with_no_promise_adds_nothing;
    Alcotest.test_case "equal promises stay two" `Quick equal_promises_stay_two;
    Alcotest.test_case "promises sort by word and target in each group" `Quick
      promises_sort_by_word_and_target_in_each_group;
    Alcotest.test_case "groups sort by the bytes of their scope" `Quick
      groups_sort_by_the_bytes_of_their_scope;
    Alcotest.test_case "a text that is not UTF-8" `Quick text_that_is_not_utf_8;
    Alcotest.test_case "a glob of a step with no promise is not read" `Quick
      a_glob_of_a_step_with_no_promise_is_not_read;
    Alcotest.test_case "the hash of a set lets a step take the plan scope"
      `Quick the_hash_of_a_set_lets_a_step_take_the_plan_scope;
    Alcotest.test_case "exclusions of a plan scope" `Quick
      exclusions_of_a_plan_scope;
    Alcotest.test_case "exclusions of a step scope" `Quick
      exclusions_of_a_step_scope;
    Alcotest.test_case "an equal set has no difference" `Quick
      an_equal_set_has_no_difference;
    Alcotest.test_case "a promise added or removed is a difference" `Quick
      a_promise_added_or_removed_is_a_difference;
    Alcotest.test_case "the count of a promise counts" `Quick
      the_count_of_a_promise_counts;
    Alcotest.test_case "a wider plan scope is a difference" `Quick
      a_wider_plan_scope_is_a_difference;
    Alcotest.test_case "a rename of a step is free" `Quick
      a_rename_of_a_step_is_free;
    Alcotest.test_case "a narrower scope is free and a wider one is not" `Quick
      a_narrower_scope_is_free_and_a_wider_one_is_not;
    Alcotest.test_case "a step takes the plan scope on each side" `Quick
      a_step_takes_the_plan_scope_on_each_side;
    Alcotest.test_case "equal slugs match first" `Quick equal_slugs_match_first;
    Alcotest.test_case "an equal slug matches before the order of the rest"
      `Quick an_equal_slug_matches_before_the_order_of_the_rest;
    Alcotest.test_case "the rest match in the order of their slugs" `Quick
      the_rest_match_in_the_order_of_their_slugs;
    Alcotest.test_case "two steps with one slug match by their scope" `Quick
      two_steps_with_one_slug_match_by_their_scope;
    Alcotest.test_case "the comparison stops at no promise of the other side"
      `Quick the_comparison_stops_at_no_promise_of_the_other_side;
    Alcotest.test_case "a set compares at no cost for each promise" `Quick
      a_set_compares_at_no_cost_for_each_promise;
    Alcotest.test_case "a wide scope of many promises is reported once" `Quick
      a_wide_scope_of_many_promises_is_reported_once;
    Alcotest.test_case "a set compares verbatim globs at no quadratic cost"
      `Quick a_set_compares_verbatim_globs_at_no_quadratic_cost;
    Alcotest.test_case "many steps with the plan scope build it once" `Quick
      many_steps_with_the_plan_scope_build_it_once;
    a_set_is_approved_against_itself;
    the_counts_of_promises_agree_with_the_difference;
    order_changes_nothing;
    equal_sets_give_one_hash;
    the_bytes_tell_apart_each_multiset_of_triples;
    the_bytes_grow_with_the_input;
    the_hash_is_the_hash_of_the_bytes;
  ]
