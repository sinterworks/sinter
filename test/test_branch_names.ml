(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen
module Branch_name = Sinter_branch_names.Branch_name
module Model = Changes_model

let set = Vectors.read "changes"

let text_of bytes =
  match Text.decode bytes with
  | Ok text -> text
  | Error _ -> Alcotest.failf "%S is not valid UTF-8" bytes

let property ?(count = 1000) ~name generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print:(Printf.sprintf "%S") generator check)

let give_branch_name (vector : Vectors.vector) =
  let text =
    match vector.input with
    | `String text -> text
    | other -> Alcotest.failf "not a text: %s" (Yojson.Basic.to_string other)
  in
  `Assoc
    [
      ( "result",
        `String
          (match Branch_name.of_text (text_of text) with
          | Ok _ -> "valid"
          | Error _ -> "invalid") );
    ]

(* @verifies changes[branch-names][*]=v1
   Each vector gives a text and "valid" or "invalid"; the test fails when
   of_text accepts a text that a condition refuses, or refuses a branch name. *)
let branch_name_vectors =
  Vectors.group set ~name:"branch-names" ~rev:"v1" give_branch_name

let any_text_gen =
  Gen.map
    (fun points ->
      let buffer = Buffer.create 16 in
      List.iter
        (fun point -> Buffer.add_utf_8_uchar buffer (Uchar.of_int point))
        points;
      Buffer.contents buffer)
    (Gen.list_size (Gen.int_range 0 12)
       (Gen.oneof_weighted
          [
            (6, Gen.int_range 0 0x7F);
            (1, Gen.int_range 0x80 0xD7FF);
            (1, Gen.int_range 0xE000 0x10FFFF);
          ]))

(* @verifies changes#validate-branch-names=v1
   A text that meets the eight conditions, read one by one from the term, must
   give "valid", and every other text "invalid"; the test fails on any text of
   the edge pieces where the two differ. *)
let validation_follows_the_conditions =
  property ~name:"a text is a branch name when it meets the eight conditions"
    Model.branch_name_gen (fun text ->
      Bool.equal
        (Result.is_ok (Branch_name.of_text (text_of text)))
        (Model.is_branch_name text))

let validation_takes_any_text =
  property
    ~name:"of_text gives a result for any text and refuses as the term does"
    any_text_gen (fun text ->
      Bool.equal
        (Result.is_ok (Branch_name.of_text (text_of text)))
        (Model.is_branch_name text))

let error_names_the_lowest_condition =
  property ~name:"the error names the lowest condition that the text fails"
    Model.branch_name_gen (fun text ->
      match
        (Branch_name.of_text (text_of text), Model.branch_name_faults text)
      with
      | Ok _, [] -> true
      | Error (Branch_name.Condition k), lowest :: _ -> k = lowest
      | _ -> false)

let to_text_gives_the_text =
  property ~name:"to_text gives the text that of_text took"
    Model.branch_name_gen (fun text ->
      match Branch_name.of_text (text_of text) with
      | Ok name -> String.equal (Text.encode (Branch_name.to_text name)) text
      | Error _ -> true)

let each_condition_alone =
  List.map
    (fun (text, k) ->
      Alcotest.test_case (Printf.sprintf "%S fails condition %d alone" text k)
        `Quick (fun () ->
          Alcotest.(check (list int))
            "the model" [ k ]
            (Model.branch_name_faults text);
          match Branch_name.of_text (text_of text) with
          | Error (Branch_name.Condition got) ->
              Alcotest.(check int) "the condition" k got
          | Ok _ -> Alcotest.fail "of_text took the text"))
    [
      ("a//b", 1);
      ("a/.b", 2);
      ("a..b", 3);
      ("a.", 4);
      ("a\x7fb", 5);
      ("a~b", 6);
      ("HEAD", 7);
      ("refs/x", 8);
    ]

let vector_groups = [ branch_name_vectors ]

let tests =
  Vectors.tests "changes" vector_groups
  @ [
      validation_follows_the_conditions;
      validation_takes_any_text;
      error_names_the_lowest_condition;
      to_text_gives_the_text;
    ]
  @ each_condition_alone
