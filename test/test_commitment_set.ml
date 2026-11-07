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
    order_changes_nothing;
    equal_sets_give_one_hash;
    the_bytes_tell_apart_each_multiset_of_triples;
    the_bytes_grow_with_the_input;
    the_hash_is_the_hash_of_the_bytes;
  ]
