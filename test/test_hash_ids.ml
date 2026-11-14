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

(* @verifies data-forms#hash-ids[compute][*]=v1
   The test fails when the text that compute gives for the id prefix, the
   number of hex digits, and the bytes of a vector is not its hash id. *)
let compute_vectors =
  Vectors.group hash_ids_set ~name:"compute" ~rev:"v1" give_compute

let give_validate (vector : Vectors.vector) =
  match
    Hash_id.validate
      (form_of_input vector.input)
      (string_member "text" vector.input)
  with
  | Some _ -> `Assoc [ ("result", `String "valid") ]
  | None -> `Assoc [ ("result", `String "invalid") ]

(* @verifies data-forms#hash-ids[validate][*]=v1
   The test fails when validate gives a hash id for a text that the vector
   calls invalid, or no hash id for a text that the vector calls valid. *)
let validate_vectors =
  Vectors.group hash_ids_set ~name:"validate" ~rev:"v1" give_validate

let is_id_prefix text =
  let length = String.length text in
  length >= 2
  && text.[length - 1] = '-'
  && String.for_all
       (fun char -> char >= 'a' && char <= 'z')
       (String.sub text 0 (length - 1))

let prefix_gen =
  Gen.map
    (fun letters -> letters ^ "-")
    (Gen.string_size ~gen:(Gen.char_range 'a' 'z') (Gen.int_range 1 5))

let number_gen =
  Gen.oneof [ Gen.oneof_list [ 1; 2; 12; 63; 64 ]; Gen.int_range 1 64 ]

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

let candidate_gen =
  let open Gen in
  let* prefix = prefix_gen in
  let* number = number_gen in
  let* text_prefix =
    oneof
      [
        return prefix;
        prefix_gen;
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

let any_prefix_gen =
  Gen.oneof
    [
      prefix_gen;
      Gen.string_size
        ~gen:(Gen.oneof_list (List.of_seq (String.to_seq "az-AZ09_.\xc3\xa9 ")))
        (Gen.int_range 0 6);
    ]

let form_refuses_what_is_not_a_form =
  property ~count:1000
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

let vector_groups = [ compute_vectors; validate_vectors ]

let tests =
  Vectors.tests "data-forms.hash-ids" vector_groups
  @ [
      Vectors.covers "data-forms.hash-ids" hash_ids_set vector_groups;
      compute_gives_the_prefix_and_the_first_hex_digits;
      validate_takes_exactly_the_hash_id_form;
      computed_hash_ids_fit_their_form;
      form_refuses_what_is_not_a_form;
    ]
