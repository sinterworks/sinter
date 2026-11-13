(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
module Gen = QCheck2.Gen
module V = Vector_json

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let rec library_thing : V.t -> Json_text.t = function
  | V.Null -> Json_text.Null
  | V.Bool value -> Json_text.Boolean value
  | V.Number number -> Json_text.Number number
  | V.String string -> Json_text.String (V.units string)
  | V.Array elements -> Json_text.Array (List.map library_thing elements)
  | V.Object members ->
      Json_text.Object
        (List.map
           (fun (name, value) -> (V.units name, library_thing value))
           members)

let rec basic_of_json : Json.t -> Yojson.Basic.t = function
  | Json.String text -> `String (Text.encode text)
  | Json.Integer number -> `Int number
  | Json.Boolean value -> `Bool value
  | Json.Array elements -> `List (List.map basic_of_json elements)
  | Json.Object members ->
      `Assoc
        (List.map
           (fun (name, value) -> (Text.encode name, basic_of_json value))
           members)

let vector_of_json value = V.of_basic (basic_of_json value)

let text_of bytes =
  match Text.decode bytes with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let json_value thing =
  match Json_text.to_json_value (library_thing thing) with
  | Some value -> value
  | None -> Alcotest.failf "not a JSON value: %s" (V.print thing)

let print_bytes bytes = V.hex bytes
let json_lines_set = Vectors.read "data-forms.json-lines"

let input_text (vector : Vectors.vector) =
  match vector.input with
  | `String text -> text
  | other ->
      Alcotest.failf "not a JSON string: %s" (Yojson.Basic.to_string other)

let give_write_json (vector : Vectors.vector) =
  let values =
    match
      Json_text.to_json_value (library_thing (V.read (input_text vector)))
    with
    | Some value ->
        `Assoc
          [
            ( "canonical-byte-sequence",
              `String (V.hex (Json.canonical_byte_sequence value)) );
          ]
    | None -> `Assoc []
  in
  `Assoc [ ("values", values) ]

(* @verifies data-forms#json-lines[write-json][*]=v1
   The test fails when a JSON value of a vector gets a byte sequence other
   than its canonical byte sequence, or when a thing that is not a JSON
   value, and so has no canonical byte sequence, gets one. *)
let write_json_vectors =
  Vectors.group json_lines_set ~name:"write-json" ~rev:"v1" give_write_json

(* @verifies data-forms#write-canonical-json=v1
   The test fails when the canonical byte sequence of a generated JSON value
   differs from the one that the rules of the canonical form give. *)
let canonical_byte_sequences_follow_the_rules =
  property ~name:"the canonical byte sequence of a JSON value follows the rules"
    ~print:V.print V.value_gen (fun thing ->
      Some (Json.canonical_byte_sequence (json_value thing)) = V.canonical thing)

(* @verifies data-forms#write-canonical-json=v1
   The test fails when a generated thing that is not a JSON value, and so
   has no canonical byte sequence, gets a byte sequence, or when a JSON
   value gets one other than its canonical byte sequence. *)
let only_json_values_have_canonical_byte_sequences =
  property ~count:1000
    ~name:
      "a thing has a canonical byte sequence when, and only when, it is a JSON \
       value" ~print:V.print V.thing_gen (fun thing ->
      Option.map Json.canonical_byte_sequence
        (Json_text.to_json_value (library_thing thing))
      = V.canonical thing)

let number_literal_gen =
  let open Gen in
  let digits = string_size ~gen:(char_range '0' '9') (int_range 0 20) in
  let piece choices = oneof_list choices in
  map
    (fun (((sign, int_part), (dot, frac)), ((e, esign), exp)) ->
      String.concat "" [ sign; int_part; dot; frac; e; esign; exp ])
    (pair
       (pair
          (pair (piece [ ""; "-"; "+" ]) digits)
          (pair (piece [ ""; "."; "" ]) digits))
       (pair
          (pair (piece [ ""; "e"; "E"; "" ]) (piece [ ""; "+"; "-" ]))
          digits))

let number_rule_gives_the_whole_numbers =
  property ~count:2000
    ~name:
      "a number is an integer when, and only when, RFC 8259 writes a whole \
       number in range with it" ~print:Fun.id number_literal_gen (fun literal ->
      let have =
        match Json_text.to_json_value (Json_text.Number literal) with
        | Some (Json.Integer number) -> Some number
        | Some _ -> Some min_int
        | None -> None
      in
      have = V.integer literal)

let numbers_that_are_not_json_numbers_give_nothing () =
  List.iter
    (fun literal ->
      Alcotest.(check bool)
        (Printf.sprintf "%S gives no JSON value" literal)
        true
        (Option.is_none (Json_text.to_json_value (Json_text.Number literal))))
    [
      "";
      "01";
      "+1";
      ".5";
      "1.";
      "1e";
      "0x10";
      "--1";
      "1 ";
      " 1";
      "NaN";
      "Infinity";
      "-";
      "1e+";
      "0e";
      "0E+";
      "-0.0e-";
      "1.e1";
      "١";
    ]

(* @verifies data-forms#write-canonical-json=v1
   Numbers outside the range of integers, or with a nonzero digit after the
   point, give no JSON value and so no canonical byte sequence; the test
   fails when one of them gets a JSON value, and so a byte sequence. *)
let numbers_give_the_whole_numbers_that_they_write () =
  List.iter
    (fun (literal, number) ->
      Alcotest.(check bool)
        (Printf.sprintf "%S gives %s" literal
           (match number with
           | Some number -> string_of_int number
           | None -> "no JSON value"))
        true
        (match (Json_text.to_json_value (Json_text.Number literal), number) with
        | Some (Json.Integer given), Some number -> given = number
        | None, None -> true
        | _ -> false))
    [
      ("5E00", Some 5);
      ("1E-0000000000000000000", Some 1);
      ("10e-1", Some 1);
      ("-0e0", Some 0);
      ("1.000e3", Some 1000);
      ("0.0001e4", Some 1);
      ("-90071992547409.91e2", Some (-9007199254740991));
      ("9007199254740990", Some 9007199254740990);
      ("-9007199254740990", Some (-9007199254740990));
      ("90071992547409900e-1", Some 9007199254740990);
      ("900719925474099e1", Some 9007199254740990);
      ("90071992547409920e-1", None);
      ("900719925474099.2e1", None);
      ("10e4611686018427387903", None);
      ("1e-4611686018427387904", None);
      ("0.9007199254740991e16", Some 9007199254740991);
      ("100e-3", None);
    ]

(* @verifies data-forms#write-canonical-json=v1
   Code units that hold a lone surrogate, or a number outside 0 to 65,535,
   write no text, so the string is no JSON value and has no canonical byte
   sequence; the test fails when it gets a JSON value, and so a byte
   sequence. *)
let code_units_outside_utf_16_give_nothing () =
  List.iter
    (fun units ->
      Alcotest.(check bool)
        (Printf.sprintf "%s gives no JSON value"
           (String.concat " " (List.map string_of_int units)))
        true
        (Option.is_none (Json_text.to_json_value (Json_text.String units))
        && Option.is_none
             (Json_text.to_json_value
                (Json_text.Object [ (units, Json_text.Boolean true) ]))))
    [
      [ -1 ];
      [ 0x10000 ];
      [ 0x61; 70000 ];
      [ 0xD800 ];
      [ 0xDC00; 0xD800 ];
      [ 0xDBFF; 0x41 ];
    ]

let sign number = compare number 0

let key_order_compares_utf_16_code_units =
  property ~count:1000
    ~name:"compare_keys orders texts by their UTF-16 code units"
    ~print:(fun (a, b) -> V.hex a ^ " / " ^ V.hex b)
    Gen.(pair V.text_gen V.text_gen)
    (fun (a, b) ->
      sign (Json.compare_keys (text_of a) (text_of b))
      = sign (V.compare_keys a b))

let key_order_is_a_total_order =
  property ~count:1000 ~name:"compare_keys is a total order"
    ~print:(fun (a, (b, c)) -> String.concat " / " (List.map V.hex [ a; b; c ]))
    Gen.(pair V.text_gen (pair V.text_gen V.text_gen))
    (fun (a, (b, c)) ->
      let compare x y = sign (Json.compare_keys (text_of x) (text_of y)) in
      compare a b = -compare b a
      && compare a b = 0 = String.equal a b
      && compare a a = 0
      && ((not (compare a b <= 0 && compare b c <= 0)) || compare a c <= 0))

let block_code_point_gen =
  Gen.oneof
    [
      Gen.map2
        (fun block offset -> 0x10000 + (block * 0x400) + offset)
        (Gen.int_range 0 63)
        (Gen.oneof_list [ 0; 1; 0x3FE; 0x3FF ]);
      Gen.oneof_list [ 0xD7FF; 0xE000; 0xFFFF; 0x10FFFF; 0x61 ];
    ]

let text_of_points points =
  let buffer = Buffer.create 8 in
  List.iter
    (fun point -> Buffer.add_utf_8_uchar buffer (Uchar.of_int point))
    points;
  Buffer.contents buffer

let key_order_holds_at_the_ends_of_blocks =
  property ~count:2000
    ~name:
      "compare_keys orders code points at the ends of each block of surrogates"
    ~print:(fun (a, b) ->
      String.concat " / "
        (List.map
           (fun points ->
             String.concat " " (List.map (Printf.sprintf "U+%04X") points))
           [ a; b ]))
    Gen.(
      pair
        (list_size (int_range 1 2) block_code_point_gen)
        (list_size (int_range 1 2) block_code_point_gen))
    (fun (a, b) ->
      let a = text_of_points a and b = text_of_points b in
      sign (Json.compare_keys (text_of a) (text_of b))
      = sign (V.compare_keys a b))

let surrogate_keys_come_before_high_keys () =
  let smile = text_of "\xf0\x9f\x98\x80"
  and private_use = text_of "\xee\x80\x80" in
  Alcotest.(check bool)
    "U+1F600 comes before U+E000" true
    (Json.compare_keys smile private_use < 0);
  Alcotest.(check bool)
    "a comes before ab" true
    (Json.compare_keys (text_of "a") (text_of "ab") < 0)

let members_gen =
  Gen.(
    list_size (int_range 0 5)
      (pair (oneof [ V.text_gen; oneof_list [ "a"; "b"; "" ] ]) (int_range 0 3)))

let object_keeps_the_members_in_key_order =
  property ~count:1000
    ~name:"object_ refuses a repeated key and holds the members in key order"
    ~print:(fun members ->
      String.concat ", "
        (List.map
           (fun (name, value) -> Printf.sprintf "%s:%d" (V.hex name) value)
           members))
    members_gen
    (fun members ->
      let library =
        List.map
          (fun (name, value) -> (text_of name, Json.boolean (value mod 2 = 0)))
          members
      in
      let names = List.map fst members in
      let unique =
        List.length (List.sort_uniq String.compare names) = List.length names
      in
      match Json.object_ library with
      | None -> not unique
      | Some (Json.Object held) ->
          let held_names = List.map (fun (name, _) -> Text.encode name) held in
          unique
          && List.sort String.compare held_names
             = List.sort String.compare names
          && List.for_all
               (fun (name, value) ->
                 List.exists
                   (fun (held_name, held_value) ->
                     String.equal (Text.encode held_name) name
                     && Json.equal held_value
                          (Json.boolean (List.assoc name members mod 2 = 0)))
                   held
                 && ignore value = ())
               members
          && List.for_all2
               (fun a b -> V.compare_keys a b < 0)
               (List.filteri
                  (fun index _ -> index < List.length held_names - 1)
                  held_names)
               (List.filteri (fun index _ -> index > 0) held_names)
      | Some _ -> false)

let integer_gen =
  Gen.oneof
    [
      Gen.oneof_list
        [
          Json.max_integer;
          Json.min_integer;
          Json.max_integer + 1;
          Json.min_integer - 1;
          0;
          max_int;
          min_int;
        ];
      Gen.int;
      Gen.int_range (-1000) 1000;
    ]

let integer_refuses_numbers_out_of_range =
  property ~count:1000
    ~name:"integer gives the integer when, and only when, it is in range"
    ~print:string_of_int integer_gen (fun number ->
      match Json.integer number with
      | Some (Json.Integer held) ->
          held = number
          && number >= -9007199254740991
          && number <= 9007199254740991
      | Some _ -> false
      | None -> number < -9007199254740991 || number > 9007199254740991)

let the_bounds_are_the_bounds_of_the_design () =
  Alcotest.(check int) "max_integer" 9007199254740991 Json.max_integer;
  Alcotest.(check int) "min_integer" (-9007199254740991) Json.min_integer

let constructors_give_their_values () =
  let check name want have =
    Alcotest.(check string) name want (Json.canonical_byte_sequence have)
  in
  check "string" "\"a\\n\"" (Json.string (text_of "a\n"));
  check "boolean" "false" (Json.boolean false);
  check "array" "[true,[]]" (Json.array [ Json.boolean true; Json.array [] ]);
  check "integer" "-5"
    (match Json.integer (-5) with
    | Some value -> value
    | None -> Alcotest.fail "no integer")

let pair_gen =
  Gen.oneof
    [
      Gen.map (fun value -> (value, value)) V.value_gen;
      Gen.pair V.value_gen V.value_gen;
      Gen.map
        (fun value ->
          ( value,
            match value with
            | V.Object members -> V.Object (List.rev members)
            | V.Array elements -> V.Array (List.rev elements)
            | other -> other ))
        V.value_gen;
    ]

let equal_holds_for_the_same_json_value =
  property ~count:1000
    ~name:
      "equal holds when, and only when, the canonical byte sequences are the \
       same"
    ~print:(fun (a, b) -> V.print a ^ " / " ^ V.print b)
    pair_gen
    (fun (a, b) ->
      Json.equal (json_value a) (json_value b) = (V.canonical a = V.canonical b))

let depth = 100_000

let deep_parts () =
  let kinds = Array.init depth (fun level -> level mod 3 = 1) in
  let prefix = Buffer.create (depth * 5) and suffix = Buffer.create depth in
  for level = depth - 1 downto 0 do
    Buffer.add_string prefix (if kinds.(level) then "{\"k\":" else "[")
  done;
  for level = 0 to depth - 1 do
    Buffer.add_char suffix (if kinds.(level) then '}' else ']')
  done;
  (kinds, Buffer.contents prefix, Buffer.contents suffix)

let deep_json () =
  let kinds, prefix, suffix = deep_parts () in
  let value = ref (Json.boolean true)
  and thing = ref (Json_text.Boolean true) in
  Array.iter
    (fun is_object ->
      if is_object then (
        (value :=
           match Json.object_ [ (text_of "k", !value) ] with
           | Some value -> value
           | None -> Alcotest.fail "no object");
        thing := Json_text.Object [ ([ 0x6B ], !thing) ])
      else (
        value := Json.array [ !value ];
        thing := Json_text.Array [ !thing ]))
    kinds;
  (!value, !thing, prefix ^ "true" ^ suffix)

let deep_values_need_no_deep_stack () =
  let value, thing, bytes = deep_json () in
  let other, _, _ = deep_json () in
  let written, equal, converted =
    Small_stack.run (fun () ->
        ( Json.canonical_byte_sequence value,
          Json.equal value other,
          Option.map Json.canonical_byte_sequence
            (Json_text.to_json_value thing) ))
  in
  Alcotest.(check bool)
    "the canonical byte sequence" true
    (String.equal written bytes);
  Alcotest.(check bool) "equal" true equal;
  Alcotest.(check bool) "to_json_value" true (converted = Some bytes)

let tests_of_json =
  [
    Alcotest.test_case "numbers that are not JSON numbers give no JSON value"
      `Quick numbers_that_are_not_json_numbers_give_nothing;
    Alcotest.test_case "code units of no text give no JSON value" `Quick
      code_units_outside_utf_16_give_nothing;
    Alcotest.test_case "numbers give the whole numbers that they write" `Quick
      numbers_give_the_whole_numbers_that_they_write;
    Alcotest.test_case "surrogate keys come before keys from U+E000" `Quick
      surrogate_keys_come_before_high_keys;
    Alcotest.test_case "the bounds of the integers are those of the design"
      `Quick the_bounds_are_the_bounds_of_the_design;
    Alcotest.test_case "the constructors give their values" `Quick
      constructors_give_their_values;
    Alcotest.test_case "deep values need no deep stack" `Quick
      deep_values_need_no_deep_stack;
    canonical_byte_sequences_follow_the_rules;
    only_json_values_have_canonical_byte_sequences;
    number_rule_gives_the_whole_numbers;
    key_order_compares_utf_16_code_units;
    key_order_is_a_total_order;
    key_order_holds_at_the_ends_of_blocks;
    object_keeps_the_members_in_key_order;
    integer_refuses_numbers_out_of_range;
    equal_holds_for_the_same_json_value;
  ]

let vector_groups = [ write_json_vectors ]
let tests = Vectors.tests "data-forms.json-lines" vector_groups @ tests_of_json
