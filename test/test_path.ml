(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen
module Path = Sinter_paths.Path

let is_valid_path text = Result.is_ok (Path.of_text text)

let valid_path text =
  match Path.of_text text with
  | Ok path -> path
  | Error _ -> Alcotest.fail "not a valid path"

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let uchars_of_string string =
  let rec go index acc =
    if index >= String.length string then List.rev acc
    else
      let decode = String.get_utf_8_uchar string index in
      go
        (index + Uchar.utf_decode_length decode)
        (Uchar.utf_decode_uchar decode :: acc)
  in
  go 0 []

let string_of_uchars uchars =
  let buffer = Buffer.create 16 in
  List.iter (Buffer.add_utf_8_uchar buffer) uchars;
  Buffer.contents buffer

let text_of string = Text.of_uchars (uchars_of_string string)

let json_string = function
  | `String text -> text
  | other ->
      Alcotest.failf "not a JSON string: %s" (Yojson.Basic.to_string other)

let json_member name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other ->
      Alcotest.failf "not a JSON object: %s" (Yojson.Basic.to_string other)

let result text = `Assoc [ ("result", `String text) ]
let either flag yes no = result (if flag then yes else no)
let files_set = Vectors.read "files"

let give_path (vector : Vectors.vector) =
  either (is_valid_path (text_of (json_string vector.input))) "valid" "invalid"

(* @verifies files[paths][*]=v1
   The vectors check "valid" and "invalid" for texts that match `path` and
   texts that do not. *)
let path_vectors = Vectors.group files_set ~name:"paths" ~rev:"v1" give_path

let interesting =
  [
    "a";
    "b";
    "A";
    ".";
    "/";
    "*";
    "!";
    "?";
    "[";
    "]";
    "{";
    "}";
    "\\";
    "\000";
    " ";
    "\xc3\xa9";
    "e\xcc\x81";
    "\xf0\x9f\x92\xa1";
    "\x7f";
    "\x01";
  ]

let character = Gen.map uchars_of_string (Gen.oneof_list interesting)
let text_gen = Gen.map List.concat (Gen.list_size (Gen.int_bound 10) character)
let print_text uchars = String.escaped (string_of_uchars uchars)

let piece_gen pieces =
  Gen.map (String.concat "")
    (Gen.list_size (Gen.int_range 1 5) (Gen.oneof_weighted pieces))

let name_gen =
  Gen.map
    (fun name -> if name = "." || name = ".." then "..." else name)
    (piece_gen
       [
         (5, Gen.return "a");
         (5, Gen.return "b");
         (1, Gen.return ".");
         (1, Gen.return "\xc3\xa9");
         (1, Gen.return "A");
       ])

let joined element count =
  Gen.map (String.concat "/") (Gen.list_size count element)

let path_gen = Gen.map uchars_of_string (joined name_gen (Gen.int_range 1 5))
let of_uchars = Text.of_uchars

(* @verifies files#validate-paths=v1
   A validation that gave "valid" for a generated text that does not match
   `path`, or "invalid" for one that does, fails the comparison with a direct
   reading of the production. *)
let validation_of_paths_follows_the_production =
  property ~name:"a text is a valid path when it matches path" ~print:print_text
    text_gen (fun text ->
      Bool.equal (is_valid_path (of_uchars text)) (Paths_reference.is_path text))

let path_error =
  Alcotest.testable
    (fun formatter error ->
      Format.pp_print_string formatter
        (match error with
        | Path.Empty_part k -> Printf.sprintf "Empty_part %d" k
        | Path.Dot_part k -> Printf.sprintf "Dot_part %d" k
        | Path.Null_character k -> Printf.sprintf "Null_character %d" k))
    ( = )

let path_names_the_first_part_that_is_no_file_name () =
  List.iter
    (fun (text, error) ->
      Alcotest.(check (result unit path_error))
        (String.escaped text) (Error error)
        (Result.map ignore (Path.of_text (text_of text))))
    [
      ("", Path.Empty_part 1);
      ("/a", Path.Empty_part 1);
      ("a/", Path.Empty_part 2);
      ("a//b", Path.Empty_part 2);
      ("a/./b/", Path.Dot_part 2);
      ("a/b/..", Path.Dot_part 3);
      ("a\000/..", Path.Null_character 1);
      ("a/b\000/", Path.Null_character 2);
    ]

let path_keeps_its_text_and_file_names =
  property ~name:"a valid path keeps its text, and its file names are its parts"
    ~print:print_text text_gen (fun text ->
      match Path.of_text (of_uchars text) with
      | Error _ -> not (Paths_reference.is_path text)
      | Ok path ->
          Text.equal (Path.to_text path) (of_uchars text)
          && List.equal Text.equal (Path.file_names path)
               (List.map of_uchars (Paths_reference.file_names text)))

let long_paths_have_results () =
  let names = String.concat "/" (List.init 100_000 (fun _ -> "a")) in
  let long_name = String.make 1_000_000 'a' in
  Alcotest.(check bool)
    "100,000 file names" true
    (is_valid_path (text_of names));
  Alcotest.(check bool)
    "one file name of 1,000,000 characters" true
    (is_valid_path (text_of long_name))

let vector_groups = [ path_vectors ]

let tests =
  Vectors.tests "files" vector_groups
  @ [
      validation_of_paths_follows_the_production;
      Alcotest.test_case "a text that is no valid path names its first bad part"
        `Quick path_names_the_first_part_that_is_no_file_name;
      path_keeps_its_text_and_file_names;
      Alcotest.test_case "long paths have results" `Quick
        long_paths_have_results;
    ]
