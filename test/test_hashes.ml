(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_hashes
module Gen = QCheck2.Gen
module V = Vector_json

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let hashes_set = Vectors.read "data-forms.hashes"

let input_text (vector : Vectors.vector) =
  match vector.input with
  | `String text -> text
  | other ->
      Alcotest.failf "not a JSON string: %s" (Yojson.Basic.to_string other)

let give_compute (vector : Vectors.vector) =
  `Assoc
    [
      ( "values",
        `Assoc
          [
            ( "hash",
              `String (Hash.compute (V.of_hex (input_text vector)) :> string) );
          ] );
    ]

(* @verifies data-forms#hashes[compute][*]=v1
   The test gives the bytes of each vector to compute and fails when the
   text that compute gives is not the hash of the vector. *)
let compute_vectors =
  Vectors.group hashes_set ~name:"compute" ~rev:"v1" give_compute

let give_validate (vector : Vectors.vector) =
  match Hash.validate (input_text vector) with
  | Some _ -> `Assoc [ ("result", `String "valid") ]
  | None -> `Assoc [ ("result", `String "invalid") ]

(* @verifies data-forms#hashes[validate][*]=v1
   The test fails when validate gives a hash for a text that the vector
   calls invalid, or no hash for a text that the vector calls valid. *)
let validate_vectors =
  Vectors.group hashes_set ~name:"validate" ~rev:"v1" give_validate

let bytes_gen =
  Gen.oneof
    [
      Gen.string_size ~gen:Gen.char (Gen.int_range 0 300);
      Gen.string_size ~gen:Gen.char
        (Gen.oneof_list [ 55; 56; 57; 63; 64; 65; 119; 120; 128 ]);
    ]

(* @verifies data-forms#compute-hash=v1
   The test compares compute with the SHA-256 of the crate sha2 on generated
   byte sequences, so a text other than the hex text of the digest fails it. *)
let compute_gives_the_sha_256_hash =
  property ~count:500 ~name:"compute gives the hex text of the SHA-256 digest"
    ~print:V.hex bytes_gen (fun bytes ->
      String.equal (Hash.compute bytes :> string) (Sinter_core.Sha256.hex bytes))

(* @verifies data-forms#compute-hash=v1
   The test fails when compute gives a text other than the published hash
   of one million `a`, a byte sequence of many blocks. *)
let compute_gives_the_published_hash_of_one_million_a () =
  Alcotest.(check string)
    "one million a"
    "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
    (Hash.compute (String.make 1_000_000 'a') :> string)

let fits_the_hash_form text =
  String.length text = 64
  && String.for_all
       (fun char ->
         (char >= '0' && char <= '9') || (char >= 'a' && char <= 'f'))
       text

let near_hash_gen =
  let digit =
    Gen.oneof
      [
        Gen.oneof_list (List.of_seq (String.to_seq "0123456789abcdef"));
        Gen.oneof_list
          (List.of_seq (String.to_seq "ABCDEFgG/:`@ \n-xz\x00\xc3\xa9\xff"));
      ]
  in
  Gen.oneof
    [
      Gen.string_size ~gen:digit (Gen.int_range 62 66);
      Gen.map
        (fun (text, (at, char)) ->
          String.mapi
            (fun index old -> if index = at mod 64 then char else old)
            text)
        Gen.(
          pair
            (string_size
               ~gen:
                 (oneof_list (List.of_seq (String.to_seq "0123456789abcdef")))
               (return 64))
            (pair nat digit));
      Gen.string_size ~gen:Gen.char (Gen.int_range 0 70);
    ]

(* @verifies data-forms#validate-hash=v1
   The test fails when validate gives a hash for a generated text that does
   not fit the hash form, or no hash for one that fits it. *)
let validate_takes_exactly_the_hash_form =
  property ~count:2000
    ~name:
      "validate gives a hash when, and only when, the text fits the hash form"
    ~print:String.escaped near_hash_gen (fun text ->
      match Hash.validate text with
      | Some hash ->
          fits_the_hash_form text && String.equal (hash :> string) text
      | None -> not (fits_the_hash_form text))

let computed_hashes_fit_the_hash_form =
  property ~name:"each hash that compute gives fits the hash form" ~print:V.hex
    bytes_gen (fun bytes ->
      let hash = (Hash.compute bytes :> string) in
      fits_the_hash_form hash && Hash.validate hash <> None)

let vector_groups = [ compute_vectors; validate_vectors ]

let tests =
  Vectors.tests "data-forms.hashes" vector_groups
  @ [
      Vectors.covers "data-forms.hashes" hashes_set vector_groups;
      Alcotest.test_case "compute gives the published hash of one million a"
        `Quick compute_gives_the_published_hash_of_one_million_a;
      compute_gives_the_sha_256_hash;
      validate_takes_exactly_the_hash_form;
      computed_hashes_fit_the_hash_form;
    ]
