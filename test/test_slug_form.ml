(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Slug_form = Sinter_identifiers.Slug_form

let property ?(count = 1000) ~name ~print generator check =
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

let is_alnum u =
  let c = Uchar.to_int u in
  (c >= 0x30 && c <= 0x39)
  || (c >= 0x41 && c <= 0x5A)
  || (c >= 0x61 && c <= 0x7A)

let is_joiner u =
  let c = Uchar.to_int u in
  c = 0x2D || c = 0x5F || c = 0x2E

let rec split_on_slash current acc = function
  | [] -> List.rev (List.rev current :: acc)
  | u :: rest when Uchar.to_int u = 0x2F ->
      split_on_slash [] (List.rev current :: acc) rest
  | u :: rest -> split_on_slash (u :: current) acc rest

let is_segment t =
  let rec after_alnum = function
    | [] -> true
    | u :: rest when is_alnum u -> after_alnum rest
    | u :: next :: rest when is_joiner u && is_alnum next -> after_alnum rest
    | _ -> false
  in
  match t with u :: rest when is_alnum u -> after_alnum rest | _ -> false

let is_slug_text t = List.for_all is_segment (split_on_slash [] [] t)

let pieces =
  [
    (6, Gen.return "a");
    (3, Gen.return "Z");
    (3, Gen.return "0");
    (2, Gen.return "-");
    (2, Gen.return "_");
    (2, Gen.return ".");
    (2, Gen.return "/");
    (1, Gen.return ":");
    (1, Gen.return " ");
    (1, Gen.return "#");
    (1, Gen.return "\xc3\xa9");
    (1, Gen.return "\x00");
  ]

let text_gen =
  Gen.map (String.concat "")
    (Gen.list_size (Gen.int_range 0 8) (Gen.oneof_weighted pieces))

let is_slug_follows_the_production =
  property ~name:"is_slug holds when, and only when, the text matches slug"
    ~print:String.escaped text_gen (fun text ->
      Bool.equal (Slug_form.is_slug text) (is_slug_text (uchars_of_string text)))

let bytes_gen = Gen.string_size ~gen:Gen.char (Gen.int_range 0 8)

let is_slug_refuses_bytes_that_are_not_ascii =
  property ~name:"is_slug refuses every byte sequence with a byte above 0x7F"
    ~print:String.escaped bytes_gen (fun bytes ->
      (not (String.exists (fun c -> Char.code c > 0x7F) bytes))
      || not (Slug_form.is_slug bytes))

let examples () =
  List.iter
    (fun (text, expected) ->
      Alcotest.(check bool)
        (String.escaped text) expected (Slug_form.is_slug text))
    [
      ("late-fee", true);
      ("billing/late-fee", true);
      ("Late-Fee", true);
      ("a.b_c-d", true);
      ("", false);
      ("a--b", false);
      ("-a", false);
      ("a/", false);
      ("/a", false);
      ("a//b", false);
      ("a:b", false);
    ]

let tests =
  [
    is_slug_follows_the_production;
    is_slug_refuses_bytes_that_are_not_ascii;
    Alcotest.test_case "is_slug answers the examples of the production" `Quick
      examples;
  ]
