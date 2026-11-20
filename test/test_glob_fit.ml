(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Test_path
module Gen = QCheck2.Gen
module Glob = Sinter_paths.Glob

let is_valid_glob text = Result.is_ok (Glob.of_text text)

let valid_glob text =
  match Glob.of_text text with
  | Ok glob -> glob
  | Error _ -> Alcotest.fail "not a valid glob"

let fits ~path ~glob = Glob.fits (valid_glob glob) (valid_path path)

let give_glob (vector : Vectors.vector) =
  either (is_valid_glob (text_of (json_string vector.input))) "valid" "invalid"

let give_fit (vector : Vectors.vector) =
  let path = text_of (json_string (json_member "path" vector.input)) in
  let glob = text_of (json_string (json_member "glob" vector.input)) in
  either (fits ~path ~glob) "fits" "does not fit"

(* @verifies files[globs][*]=v1
   The vectors check "valid" and "invalid" for texts that match `glob` and
   texts that do not. *)
let glob_vectors = Vectors.group files_set ~name:"globs" ~rev:"v1" give_glob

(* @verifies files[fits][*]=v1
   The vectors check "fits" and "does not fit" for pairs of a valid path and
   a valid glob. *)
let fit_vectors = Vectors.group files_set ~name:"fits" ~rev:"v1" give_fit

let single_stars text =
  let buffer = Buffer.create (String.length text) in
  String.iteri
    (fun index char ->
      if not (char = '*' && index > 0 && text.[index - 1] = '*') then
        Buffer.add_char buffer char)
    text;
  Buffer.contents buffer

let segment_gen =
  Gen.oneof_weighted
    [
      (1, Gen.return "**");
      ( 6,
        Gen.map
          (fun segment ->
            let segment = single_stars segment in
            if segment = "." || segment = ".." then "*" else segment)
          (piece_gen
             [
               (4, Gen.return "a");
               (4, Gen.return "b");
               (4, Gen.return "*");
               (1, Gen.return ".");
               (1, Gen.return "\xc3\xa9");
             ]) );
    ]

let glob_gen =
  Gen.map2
    (fun glob trailing ->
      uchars_of_string (if trailing then glob ^ "/" else glob))
    (joined segment_gen (Gen.int_range 1 4))
    Gen.bool

(* @verifies files#validate-globs=v1
   A validation that gave "valid" for a generated text that does not match
   `glob`, or "invalid" for one that does, fails the comparison with a direct
   reading of the production. *)
let validation_of_globs_follows_the_production =
  property ~name:"a text is a valid glob when it matches glob" ~print:print_text
    text_gen (fun text ->
      Bool.equal (is_valid_glob (of_uchars text)) (Paths_reference.is_glob text))

let print_pair (path, glob) =
  Printf.sprintf "path %s, glob %s" (print_text path) (print_text glob)

(* @verifies files#decide-glob-fit=v1
   A decision that differed from glob-fit for a generated valid path and valid
   glob fails the comparison with a direct reading of the term. *)
let fit_follows_the_term =
  property ~count:2000 ~name:"a valid path fits a valid glob as glob-fit says"
    ~print:print_pair (Gen.pair path_gen glob_gen) (fun (path, glob) ->
      Bool.equal
        (fits ~path:(of_uchars path) ~glob:(of_uchars glob))
        (Paths_reference.fits ~path ~glob))

let letters alphabet length =
  Gen.string_size ~gen:(Gen.oneof_list alphabet) (Gen.int_range 1 length)

(* @verifies files#decide-glob-fit=v1
   A decision that differed from glob-fit for a generated file name and glob
   segment with `*`, over few letters so that pieces repeat and overlap,
   fails the comparison with a direct reading of the term. *)
let name_fit_follows_the_term =
  property ~count:5000 ~name:"a file name fits a glob segment as glob-fit says"
    ~print:print_pair
    (Gen.pair
       (Gen.map uchars_of_string (letters [ 'a'; 'b' ] 6))
       (Gen.map
          (fun segment -> uchars_of_string (single_stars segment))
          (letters [ 'a'; 'b'; '*' ] 7)))
    (fun (path, glob) ->
      Bool.equal
        (fits ~path:(of_uchars path) ~glob:(of_uchars glob))
        (Paths_reference.fits ~path ~glob))

let slash_is_double_star =
  property ~name:"a valid glob that ends with / fits as the same glob with /**"
    ~print:print_pair
    (Gen.pair path_gen
       (Gen.map uchars_of_string (joined segment_gen (Gen.int_range 1 4))))
    (fun (path, glob) ->
      let with_slash = glob @ uchars_of_string "/" in
      let with_stars = glob @ uchars_of_string "/**" in
      Bool.equal
        (fits ~path:(of_uchars path) ~glob:(of_uchars with_slash))
        (fits ~path:(of_uchars path) ~glob:(of_uchars with_stars)))

let glob_error =
  Alcotest.testable
    (fun formatter error ->
      Format.pp_print_string formatter
        (match error with
        | Glob.Empty_part k -> Printf.sprintf "Empty_part %d" k
        | Glob.Dot_part k -> Printf.sprintf "Dot_part %d" k
        | Glob.Forbidden_character k ->
            Printf.sprintf "Forbidden_character %d" k
        | Glob.Adjacent_stars k -> Printf.sprintf "Adjacent_stars %d" k))
    ( = )

let glob_names_the_first_part_with_a_fault () =
  List.iter
    (fun (text, error) ->
      Alcotest.(check (result unit glob_error))
        (String.escaped text) (Error error)
        (Result.map ignore (Glob.of_text (text_of text))))
    [
      ("", Glob.Empty_part 1);
      ("/a", Glob.Empty_part 1);
      ("/", Glob.Empty_part 1);
      ("a//", Glob.Empty_part 2);
      ("a//b", Glob.Empty_part 2);
      ("a/../b", Glob.Dot_part 2);
      ("a/./b", Glob.Dot_part 2);
      ("a/b?/c**", Glob.Forbidden_character 2);
      ("a/b**c?", Glob.Forbidden_character 2);
      ("a/b**c/d?", Glob.Adjacent_stars 2);
      ("***", Glob.Adjacent_stars 1);
      ("a/[b]", Glob.Forbidden_character 2);
      ("{a}", Glob.Forbidden_character 1);
      ("a\\b", Glob.Forbidden_character 1);
    ]

let glob_keeps_its_text_and_segments =
  property ~name:"a valid glob keeps its text, and gives its glob segments"
    ~print:print_text
    (Gen.oneof [ text_gen; glob_gen ])
    (fun text ->
      match Glob.of_text (of_uchars text) with
      | Error _ -> not (Paths_reference.is_glob text)
      | Ok glob ->
          Text.equal (Glob.to_text glob) (of_uchars text)
          && List.equal Text.equal (Glob.segments glob)
               (List.map of_uchars (Paths_reference.glob_segments text)))

let long_globs_have_results () =
  Alcotest.(check bool)
    "a glob of 100,000 segments" true
    (is_valid_glob
       (text_of (String.concat "/" (List.init 100_000 (fun _ -> "**")))));
  let stars = String.concat "/" (List.init 2_000 (fun _ -> "**")) ^ "/b" in
  let path = String.concat "/" (List.init 2_000 (fun _ -> "a")) in
  Alcotest.(check bool)
    "2,000 segments ** and 2,000 file names" false
    (fits ~path:(text_of path) ~glob:(text_of stars));
  Alcotest.(check bool)
    "a star segment of 5,000 characters" true
    (fits
       ~path:(text_of (String.make 5_000 'a'))
       ~glob:(text_of (String.concat "*" (List.init 2_500 (fun _ -> "a")))))

let vector_groups = [ glob_vectors; fit_vectors ]

let tests =
  Vectors.tests "files" vector_groups
  @ [
      validation_of_globs_follows_the_production;
      fit_follows_the_term;
      name_fit_follows_the_term;
      slash_is_double_star;
      Alcotest.test_case "a text that is no valid glob names its first bad part"
        `Quick glob_names_the_first_part_with_a_fault;
      glob_keeps_its_text_and_segments;
      Alcotest.test_case "long globs have results" `Quick
        long_globs_have_results;
    ]
