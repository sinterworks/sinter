(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_test_vectors
module Gen = QCheck2.Gen

let text_of bytes =
  match Text.decode bytes with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let text_gen =
  Gen.map
    (fun pieces -> text_of (String.concat "" pieces))
    (Gen.list_size (Gen.int_range 0 6)
       (Gen.oneof_list
          [
            "a"; "b"; "-"; "."; "/"; "#"; "\xc3\xa9"; " "; "\n"; "\xef\xbb\xbf";
          ]))

let print text = Printf.sprintf "%S" (Text.encode text)

let the_examples_of_the_term () =
  Alcotest.(check string)
    "a design alone" "a.test-vectors.jsonl"
    (Text.encode (Test_vector_file_name.of_design (text_of "a")));
  Alcotest.(check string)
    "a design and a specification" "a.b.test-vectors.jsonl"
    (Text.encode
       (Test_vector_file_name.of_specification (text_of "a") (text_of "b")))

let property ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:300 ~name ~print generator check)

let a_design_alone_is_its_name_and_the_suffix =
  property ~name:"the file name of a design is x and .test-vectors.jsonl" ~print
    text_gen (fun x ->
      Text.equal
        (Test_vector_file_name.of_design x)
        (Text.concat [ x; text_of ".test-vectors.jsonl" ]))

let a_specification_is_both_names_and_the_suffix =
  property ~name:"the file name of x and y is x, ., y, and .test-vectors.jsonl"
    ~print:(fun (x, y) -> print x ^ " " ^ print y)
    (Gen.pair text_gen text_gen)
    (fun (x, y) ->
      Text.equal
        (Test_vector_file_name.of_specification x y)
        (Text.concat [ x; text_of "."; y; text_of ".test-vectors.jsonl" ]))

let long_name n = text_of (String.make n 'a')

let the_file_names_grow_as_the_names () =
  Counted_work.check_growth ~margin:1.5 ~sizes:(1000, 4000) ~input:long_name
    Test_vector_file_name.of_design;
  Counted_work.check_growth ~margin:1.5 ~sizes:(1000, 4000)
    ~input:(fun n -> (long_name n, long_name n))
    (fun (x, y) -> Test_vector_file_name.of_specification x y)

let tests =
  [
    Alcotest.test_case "names four times as long take at most 6 times the work"
      `Quick the_file_names_grow_as_the_names;
    Alcotest.test_case "the file names of the examples of the term" `Quick
      the_examples_of_the_term;
    a_design_alone_is_its_name_and_the_suffix;
    a_specification_is_both_names_and_the_suffix;
  ]
