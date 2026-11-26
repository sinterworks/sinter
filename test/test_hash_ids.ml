(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_hash_ids
module Gen = QCheck2.Gen
module V = Vector_json

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let hash_ids_set = Vectors.read "data-forms.hash-ids"

let member name (json : Yojson.Basic.t) =
  match json with
  | `Assoc members -> (
      match List.assoc_opt name members with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let string_member name json =
  match member name json with
  | `String text -> text
  | other -> Alcotest.failf "not a string: %s" (Yojson.Basic.to_string other)

let int_member name json =
  match member name json with
  | `Int number -> number
  | other -> Alcotest.failf "not an integer: %s" (Yojson.Basic.to_string other)

let form_of id_prefix number_of_hex_digits =
  match Hash_id.form ~id_prefix ~number_of_hex_digits with
  | Ok form -> form
  | Error _ ->
      Alcotest.failf "no form for %S and %d" id_prefix number_of_hex_digits

let form_of_input input =
  form_of
    (string_member "id-prefix" input)
    (int_member "number-of-hex-digits" input)

let give_compute (vector : Vectors.vector) =
  let hash_id =
    Hash_id.compute
      (form_of_input vector.input)
      (V.of_hex (string_member "byte-sequence" vector.input))
  in
  `Assoc [ ("values", `Assoc [ ("hash-id", `String (hash_id :> string)) ]) ]

(* @verifies data-forms#hash-ids[compute]
   The test fails when the text that compute gives for the id prefix, the
   number of hex digits, and the bytes of a vector is not its hash id. *)
let compute_vectors =
  Vectors.group hash_ids_set ~name:"compute" ~form:"#compute-hash-id-vector=v1"
    give_compute

let give_validate (vector : Vectors.vector) =
  match
    Hash_id.validate
      (form_of_input vector.input)
      (string_member "text" vector.input)
  with
  | Some _ -> `Assoc [ ("result", `String "valid") ]
  | None -> `Assoc [ ("result", `String "invalid") ]

(* @verifies data-forms#hash-ids[validate]
   The test fails when validate gives a hash id for a text that the vector
   calls invalid, or no hash id for a text that the vector calls valid. *)
let validate_vectors =
  Vectors.group hash_ids_set ~name:"validate"
    ~form:"#validate-hash-id-vector=v1" give_validate

let is_id_prefix text =
  let length = String.length text in
  if length < 2 || text.[length - 1] <> ':' then false
  else
    let body = String.sub text 0 (length - 1) in
    let parts = String.split_on_char '-' body in
    List.for_all
      (fun part ->
        String.length part >= 1
        && String.for_all (fun char -> char >= 'a' && char <= 'z') part)
      parts

let word_gen = Gen.string_size ~gen:(Gen.char_range 'a' 'z') (Gen.int_range 1 6)

let prefix_gen =
  Gen.map
    (fun words -> String.concat "-" words ^ ":")
    (Gen.list_size (Gen.int_range 1 4) word_gen)

let number_gen =
  Gen.oneof [ Gen.oneof_list [ 1; 2; 12; 32; 63; 64 ]; Gen.int_range 1 64 ]

let print_form (prefix, number) = Printf.sprintf "%S, %d" prefix number

(* @verifies data-forms#compute-hash-id=v1
   The test fails when compute gives a text other than the id prefix and
   then the first hex digits of the SHA-256 hash, for each number from 1
   to 64. *)
let compute_gives_the_prefix_and_the_first_hex_digits =
  property ~count:500
    ~name:"compute gives the id prefix, then the first hex digits of the hash"
    ~print:(fun (form, bytes) -> print_form form ^ ", " ^ V.hex bytes)
    Gen.(
      pair
        (pair prefix_gen number_gen)
        (string_size ~gen:char (int_range 0 100)))
    (fun ((prefix, number), bytes) ->
      String.equal
        (Hash_id.compute (form_of prefix number) bytes :> string)
        (prefix ^ String.sub (Sinter_core.Sha256.hex bytes) 0 number))

(* @verifies data-forms#compute-hash-id=v1
   The test fails when compute gives different hash digits for the same byte
   sequence under two different id prefixes. *)
let compute_hash_does_not_depend_on_id_prefix =
  property ~count:300
    ~name:"the hash of the byte sequence does not depend on the id prefix"
    ~print:(fun ((p1, p2), (number, bytes)) ->
      Printf.sprintf "%S, %S, %d, %s" p1 p2 number (V.hex bytes))
    Gen.(
      pair
        (pair prefix_gen prefix_gen)
        (pair number_gen (string_size ~gen:char (int_range 0 100))))
    (fun ((p1, p2), (number, bytes)) ->
      let id1 = (Hash_id.compute (form_of p1 number) bytes :> string)
      and id2 = (Hash_id.compute (form_of p2 number) bytes :> string) in
      let h1 = String.sub id1 (String.length p1) number
      and h2 = String.sub id2 (String.length p2) number in
      String.equal h1 h2)

let fits prefix number text =
  let length = String.length prefix in
  String.length text = length + number
  && String.equal (String.sub text 0 length) prefix
  && String.for_all
       (fun char ->
         (char >= '0' && char <= '9') || (char >= 'a' && char <= 'f'))
       (String.sub text length number)

let digit_gen =
  Gen.oneof
    [
      Gen.oneof_list (List.of_seq (String.to_seq "0123456789abcdef"));
      Gen.oneof_list (List.of_seq (String.to_seq "ABFgz-/:`@\x00\xc3\xa9\xff"));
    ]

let hyphen_ending prefix = String.sub prefix 0 (String.length prefix - 1) ^ "-"

let candidate_gen =
  let open Gen in
  let* prefix = prefix_gen in
  let* number = number_gen in
  let* text_prefix =
    oneof
      [
        return prefix;
        prefix_gen;
        return (hyphen_ending prefix);
        return "";
        return (String.uppercase_ascii prefix);
      ]
  in
  let* length =
    oneof [ return number; int_range (max 0 (number - 1)) (number + 1) ]
  in
  let* digits = string_size ~gen:digit_gen (return length) in
  let* clean =
    string_size
      ~gen:(oneof_list (List.of_seq (String.to_seq "0123456789abcdef")))
      (return length)
  in
  let* use_clean = bool in
  return ((prefix, number), text_prefix ^ if use_clean then clean else digits)

(* @verifies data-forms#validate-hash-id=v1
   The test fails when validate gives a hash id for a generated text that
   does not fit the hash-id form, or no hash id for one that fits it. *)
let validate_takes_exactly_the_hash_id_form =
  property ~count:2000
    ~name:
      "validate gives a hash id when, and only when, the text fits the hash-id \
       form"
    ~print:(fun (form, text) -> print_form form ^ ", " ^ String.escaped text)
    candidate_gen
    (fun ((prefix, number), text) ->
      match Hash_id.validate (form_of prefix number) text with
      | Some hash_id ->
          fits prefix number text && String.equal (hash_id :> string) text
      | None -> not (fits prefix number text))

let computed_hash_ids_fit_their_form =
  property ~name:"each hash id that compute gives fits its hash-id form"
    ~print:(fun (form, bytes) -> print_form form ^ ", " ^ V.hex bytes)
    Gen.(
      pair (pair prefix_gen number_gen) (string_size ~gen:char (int_range 0 40)))
    (fun ((prefix, number), bytes) ->
      let form = form_of prefix number in
      let hash_id = (Hash_id.compute form bytes :> string) in
      fits prefix number hash_id && Hash_id.validate form hash_id <> None)

let invalid_prefix_cases =
  [
    "";
    ":";
    "-";
    "e-";
    "req-";
    "task-def-";
    "req";
    "task-def";
    "-a:";
    "-:";
    "a-:";
    "req-:";
    "a--b:";
    "task--def:";
    "a:b:";
    "req::";
    ":req:";
    "A:";
    "Req:";
    "task-Def:";
    "a1:";
    "1a:";
    "a-1:";
    "`:";
    "{:";
    "a_b:";
    "a b:";
    "a.b:";
    "a\x00b:";
    "\xc3\xa9:";
  ]

let valid_prefix_cases =
  [ "a:"; "z:"; "req:"; "task-def:"; "vector-group-def:"; "a-b-c-d:" ]

let any_prefix_gen =
  Gen.oneof
    [
      prefix_gen;
      Gen.oneof_list invalid_prefix_cases;
      Gen.string_size
        ~gen:
          (Gen.oneof_list (List.of_seq (String.to_seq "az-:AZ09_`{.\xc3\xa9 ")))
        (Gen.int_range 0 10);
    ]

let form_refuses_what_is_not_a_form =
  property ~count:2000
    ~name:
      "form refuses a text that is not an id prefix, then a number outside 1 \
       to 64"
    ~print:print_form
    Gen.(
      pair any_prefix_gen
        (oneof [ int_range (-3) 67; oneof_list [ min_int; max_int ] ]))
    (fun (prefix, number) ->
      match Hash_id.form ~id_prefix:prefix ~number_of_hex_digits:number with
      | Ok _ -> is_id_prefix prefix && number >= 1 && number <= 64
      | Error (Hash_id.Not_an_id_prefix text) ->
          String.equal text prefix && not (is_id_prefix prefix)
      | Error (Hash_id.Number_of_hex_digits_out_of_range given) ->
          given = number && is_id_prefix prefix && (number < 1 || number > 64))

let form_accepts_valid_id_prefixes () =
  List.iter
    (fun id_prefix ->
      List.iter
        (fun number_of_hex_digits ->
          match Hash_id.form ~id_prefix ~number_of_hex_digits with
          | Ok _ -> ()
          | Error _ ->
              Alcotest.failf "expected valid form for %S and %d" id_prefix
                number_of_hex_digits)
        [ 1; 12; 32; 64 ])
    valid_prefix_cases

let form_refuses_invalid_id_prefixes () =
  List.iter
    (fun id_prefix ->
      List.iter
        (fun number_of_hex_digits ->
          match Hash_id.form ~id_prefix ~number_of_hex_digits with
          | Error (Hash_id.Not_an_id_prefix got) ->
              Alcotest.(check string) "reported prefix" id_prefix got
          | Error (Hash_id.Number_of_hex_digits_out_of_range _) ->
              Alcotest.failf "expected Not_an_id_prefix first for %S and %d"
                id_prefix number_of_hex_digits
          | Ok _ ->
              Alcotest.failf "expected Not_an_id_prefix for %S and %d" id_prefix
                number_of_hex_digits)
        [ 12; 0; 65 ])
    invalid_prefix_cases

let form_refuses_counts_out_of_range () =
  List.iter
    (fun number_of_hex_digits ->
      match Hash_id.form ~id_prefix:"req:" ~number_of_hex_digits with
      | Error (Hash_id.Number_of_hex_digits_out_of_range got) ->
          Alcotest.(check int) "reported count" number_of_hex_digits got
      | _ ->
          Alcotest.failf "expected Number_of_hex_digits_out_of_range for %d"
            number_of_hex_digits)
    [ min_int; -1; 0; 65; max_int ]

let vector_groups = [ compute_vectors; validate_vectors ]

let tests =
  Vectors.tests "data-forms.hash-ids" vector_groups
  @ [
      Vectors.covers "data-forms.hash-ids" hash_ids_set vector_groups;
      compute_gives_the_prefix_and_the_first_hex_digits;
      compute_hash_does_not_depend_on_id_prefix;
      validate_takes_exactly_the_hash_id_form;
      computed_hash_ids_fit_their_form;
      form_refuses_what_is_not_a_form;
      Alcotest.test_case
        "form gives a form for each valid id prefix and a count from 1 to 64"
        `Quick form_accepts_valid_id_prefixes;
      Alcotest.test_case
        "form gives Not_an_id_prefix for a text that is not an id prefix, also \
         with a count out of range"
        `Quick form_refuses_invalid_id_prefixes;
      Alcotest.test_case
        "form gives Number_of_hex_digits_out_of_range for a count outside 1 to \
         64"
        `Quick form_refuses_counts_out_of_range;
    ]
