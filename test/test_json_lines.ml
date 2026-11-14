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

let oracle_read bytes =
  match V.read bytes with
  | thing when V.canonical thing = Some bytes -> Some thing
  | _ -> None
  | exception _ -> None

let oracle_read_line bytes =
  let length = String.length bytes in
  if length = 0 || bytes.[length - 1] <> '\n' then None
  else
    match oracle_read (String.sub bytes 0 (length - 1)) with
    | Some thing when V.is_line_object thing -> Some thing
    | _ -> None

let same_value value thing =
  V.canonical (vector_of_json value) = V.canonical thing

let read_gives_back_each_json_value =
  property
    ~name:"read gives back each JSON value from its canonical byte sequence"
    ~print:V.print V.value_gen (fun thing ->
      match Json.read (Json.canonical_byte_sequence (json_value thing)) with
      | Some value -> same_value value thing
      | None -> false)

let canonical_corruption_gen =
  Gen.(
    V.value_gen >>= fun thing ->
    match V.canonical thing with
    | Some bytes -> V.corrupt_gen bytes
    | None -> return "")

let read_accepts_exactly_canonical_byte_sequences =
  property ~count:2000
    ~name:"read accepts a byte sequence when, and only when, it is canonical"
    ~print:print_bytes canonical_corruption_gen (fun bytes ->
      match (Json.read bytes, oracle_read bytes) with
      | Some value, Some thing ->
          same_value value thing
          && String.equal (Json.canonical_byte_sequence value) bytes
      | None, None -> true
      | _ -> false)

let any_bytes_gen =
  Gen.oneof
    [
      Gen.string_size ~gen:Gen.char (Gen.int_range 0 24);
      Gen.string_size ~gen:V.byte_gen (Gen.int_range 0 24);
    ]

let read_answers_any_bytes =
  property ~count:2000 ~name:"read gives a value or nothing for any bytes"
    ~print:print_bytes any_bytes_gen (fun bytes ->
      match Json.read bytes with
      | Some value -> String.equal (Json.canonical_byte_sequence value) bytes
      | None -> Option.is_none (oracle_read bytes))

let deep_bytes_need_no_deep_stack () =
  let value, _, bytes = deep_json () in
  let _, prefix, _ = deep_parts () in
  let read, unclosed =
    Small_stack.run (fun () -> (Json.read bytes, Json.read (prefix ^ "true")))
  in
  Alcotest.(check bool)
    "the deep value" true
    (match read with Some read -> Json.equal read value | None -> false);
  Alcotest.(check bool) "the unclosed value" true (Option.is_none unclosed)

let escapes_of_control_characters_follow_the_string_forms () =
  List.iter
    (fun (code, format) ->
      let bytes =
        "\"" ^ String.make 1 '\\' ^ "u" ^ Printf.sprintf format code ^ "\""
      in
      let have = Json.read bytes and want = oracle_read bytes in
      Alcotest.(check bool)
        (Printf.sprintf "read of %s" bytes)
        true
        (match (have, want) with
        | Some value, Some thing -> same_value value thing
        | None, None -> true
        | _ -> false))
    (List.concat_map
       (fun code -> [ (code, format_of_string "%04x"); (code, "%04X") ])
       (List.init 0x21 Fun.id))

let prefix_gen =
  Gen.(
    V.value_gen >>= fun thing ->
    match V.canonical thing with
    | Some bytes ->
        map
          (fun cut -> String.sub bytes 0 (cut mod (String.length bytes + 1)))
          nat
    | None -> return "")

let read_answers_each_prefix =
  property ~count:2000
    ~name:
      "read gives a value or nothing for each prefix of a canonical byte \
       sequence" ~print:print_bytes prefix_gen (fun bytes ->
      match (Json.read bytes, oracle_read bytes) with
      | Some value, Some thing -> same_value value thing
      | None, None -> true
      | _ -> false)

let number_text_gen =
  Gen.map2
    (fun sign digits -> sign ^ digits)
    (Gen.oneof_list [ ""; "-" ])
    (Gen.string_size ~gen:(Gen.char_range '0' '9') (Gen.int_range 1 25))

let read_answers_each_number =
  property ~count:1000
    ~name:
      "read gives an integer for a decimal numeral when, and only when, it is \
       canonical" ~print:Fun.id number_text_gen (fun bytes ->
      match (Json.read bytes, oracle_read bytes) with
      | Some value, Some thing -> same_value value thing
      | None, None -> true
      | _ -> false)

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
    Alcotest.test_case "deep byte sequences need no deep stack" `Quick
      deep_bytes_need_no_deep_stack;
    read_gives_back_each_json_value;
    read_accepts_exactly_canonical_byte_sequences;
    read_answers_any_bytes;
    Alcotest.test_case "escapes of control characters follow the string forms"
      `Quick escapes_of_control_characters_follow_the_string_forms;
    read_answers_each_prefix;
    read_answers_each_number;
  ]

let give_write_line (vector : Vectors.vector) =
  let values =
    match
      Option.bind
        (Json_text.to_json_value (library_thing (V.read (input_text vector))))
        Json_line.of_json
    with
    | Some line_object ->
        `Assoc
          [
            ( "canonical-line",
              `String (V.hex (Json_line.canonical_line line_object)) );
          ]
    | None -> `Assoc []
  in
  `Assoc [ ("values", values) ]

(* @verifies data-forms#json-lines[write-line][*]=v1
   The test fails when a line object of a vector gets a byte sequence other
   than its canonical line, or when a thing that is not a line object, and
   so has no canonical line, gets one. *)
let write_line_vectors =
  Vectors.group json_lines_set ~name:"write-line" ~rev:"v1" give_write_line

let give_read_line (vector : Vectors.vector) =
  match Json_line.read (V.of_hex (input_text vector)) with
  | Some line_object ->
      `Assoc
        [
          ("result", `String "valid");
          ( "values",
            `Assoc [ ("line-object", basic_of_json (line_object :> Json.t)) ] );
        ]
  | None -> `Assoc [ ("result", `String "invalid"); ("values", `Assoc []) ]

(* @verifies data-forms#json-lines[read-line][*]=v1
   read gives a result for every byte sequence; the test fails when that
   result, or the line object that read gives, differs from the result
   and the line object of a vector. *)
let read_line_vectors =
  Vectors.group json_lines_set ~name:"read-line" ~rev:"v1" give_read_line

let line thing =
  Option.bind (Json_text.to_json_value (library_thing thing)) Json_line.of_json

(* @verifies data-forms#write-canonical-line=v1
   The test fails when a generated thing that is not a line object, and so
   has no canonical line, gets a byte sequence, or when a line object gets
   one other than its canonical line. *)
let only_line_objects_have_canonical_lines =
  property ~count:1000
    ~name:
      "a thing has a canonical line when, and only when, it is a line object"
    ~print:V.print
    (Gen.oneof [ V.thing_gen; V.line_object_gen ])
    (fun thing ->
      Option.map Json_line.canonical_line (line thing) = V.canonical_line thing)

let of_json_keeps_the_value =
  property ~name:"of_json gives back the line object that it takes"
    ~print:V.print V.line_object_gen (fun thing ->
      match line thing with
      | Some line_object ->
          Json.equal (line_object :> Json.t) (json_value thing)
      | None -> false)

(* @verifies data-forms#{read-canonical-line=v1, give-only-line-objects=v1}
   read gives a result for every byte sequence; the test fails when it
   gives "invalid" for the canonical line of a generated line object, or a
   line object other than that one. *)
let read_gives_back_each_line_object =
  property ~name:"read gives back each line object from its canonical line"
    ~print:V.print V.line_object_gen (fun thing ->
      match V.canonical_line thing with
      | Some bytes -> (
          match Json_line.read bytes with
          | Some line_object -> same_value (line_object :> Json.t) thing
          | None -> false)
      | None -> false)

let line_corruption_gen =
  Gen.(
    V.line_object_gen >>= fun thing ->
    match V.canonical_line thing with
    | Some bytes -> V.corrupt_gen bytes
    | None -> return "")

(* @verifies data-forms#{read-canonical-line=v1, give-only-line-objects=v1}
   The test changes canonical lines by one byte, and fails when read gives
   "valid" and a line object for a byte sequence that is not a canonical
   line, "invalid" for one that is, or a line object whose canonical line
   the byte sequence is not. *)
let read_accepts_exactly_canonical_lines =
  property ~count:2000
    ~name:
      "read accepts a byte sequence when, and only when, it is a canonical line"
    ~print:print_bytes line_corruption_gen (fun bytes ->
      match (Json_line.read bytes, oracle_read_line bytes) with
      | Some line_object, Some thing ->
          same_value (line_object :> Json.t) thing
          && String.equal (Json_line.canonical_line line_object) bytes
      | None, None -> true
      | _ -> false)

(* @verifies data-forms#{read-canonical-line=v1, give-only-line-objects=v1}
   The test gives any bytes and fails when read gives a line object whose
   canonical line the byte sequence is not, or "invalid" for a byte
   sequence that is a canonical line. *)
let read_line_answers_any_bytes =
  property ~count:2000
    ~name:"read of a line gives a line object or nothing for any bytes"
    ~print:print_bytes any_bytes_gen (fun bytes ->
      match Json_line.read bytes with
      | Some line_object ->
          String.equal (Json_line.canonical_line line_object) bytes
      | None -> Option.is_none (oracle_read_line bytes))

let deep_lines_need_no_deep_stack () =
  let value, _, bytes = deep_json () in
  let _, prefix, _ = deep_parts () in
  let line_of_value, read_deep, read_unclosed =
    Small_stack.run (fun () ->
        ( Json_line.of_json value,
          Json_line.read ("{\"a\":" ^ bytes ^ "}\n"),
          Json_line.read ("{\"a\":" ^ prefix) ))
  in
  Alcotest.(check bool) "of_json" true (Option.is_none line_of_value);
  Alcotest.(check bool) "the deep line" true (Option.is_none read_deep);
  Alcotest.(check bool) "the unclosed line" true (Option.is_none read_unclosed)

let tests_of_lines =
  [
    Alcotest.test_case "deep lines need no deep stack" `Quick
      deep_lines_need_no_deep_stack;
    only_line_objects_have_canonical_lines;
    of_json_keeps_the_value;
    read_gives_back_each_line_object;
    read_accepts_exactly_canonical_lines;
    read_line_answers_any_bytes;
  ]

let give_read_json (vector : Vectors.vector) =
  match Json.read_json_text (V.of_hex (input_text vector)) with
  | Some value ->
      `Assoc
        [
          ("result", `String "valid");
          ("values", `Assoc [ ("json-value", basic_of_json value) ]);
        ]
  | None -> `Assoc [ ("result", `String "invalid"); ("values", `Assoc []) ]

(* @verifies data-forms#json-lines[read-json][*]=v1
   read_json_text gives a result for every byte sequence; the test fails
   when that result, or the JSON value that it gives, differs from the
   result and the JSON value of a vector. *)
let read_json_vectors =
  Vectors.group json_lines_set ~name:"read-json" ~rev:"v1" give_read_json

let read_json_agrees bytes =
  match (Json.read_json_text bytes, V.json_value_of_bytes bytes) with
  | Some value, Some thing -> same_value value thing
  | None, None -> true
  | _ -> false

let spelled_value_gen = Gen.(V.value_gen >>= V.spelling_gen)

(* @verifies data-forms#{read-json-text=v1, give-only-json-values=v1}
   The test writes generated JSON values as JSON texts with spaces, escape
   sequences, and members in any order, and fails when read_json_text
   gives "invalid" for them, or a JSON value other than the one written. *)
let read_json_text_gives_back_each_json_value =
  property ~count:1000
    ~name:"read_json_text gives back each JSON value from a JSON text of it"
    ~print:(fun (_, text) -> print_bytes text)
    Gen.(
      V.value_gen >>= fun thing ->
      map (fun text -> (thing, text)) (V.spelling_gen thing))
    (fun (thing, text) ->
      match Json.read_json_text text with
      | Some value -> same_value value thing
      | None -> false)

let spelled_thing_gen =
  Gen.oneof
    [
      Gen.(V.thing_gen >>= V.spelling_gen);
      Gen.(spelled_value_gen >>= V.corrupt_gen);
      Gen.(V.thing_gen >>= V.spelling_gen >>= V.corrupt_gen);
    ]

(* @verifies data-forms#{read-json-text=v1, give-only-json-values=v1}
   The test gives JSON texts of things that are not JSON values, and JSON
   texts changed by one byte, and fails when read_json_text gives "valid"
   for a byte sequence that has no JSON value, "invalid" for one that has
   one, or a JSON value other than the JSON value of the byte sequence. *)
let read_json_text_takes_exactly_the_json_values =
  property ~count:2000
    ~name:
      "read_json_text gives a JSON value when, and only when, the byte \
       sequence has one"
    ~print:print_bytes spelled_thing_gen read_json_agrees

(* @verifies data-forms#{read-json-text=v1, give-only-json-values=v1}
   The test gives any bytes and fails when read_json_text gives "valid" for
   a byte sequence that has no JSON value, "invalid" for one that has one,
   or a JSON value other than the JSON value of the byte sequence. *)
let read_json_text_answers_any_bytes =
  property ~count:1000
    ~name:"read_json_text gives a value or nothing for any bytes"
    ~print:print_bytes any_bytes_gen read_json_agrees

(* @verifies data-forms#{read-json-text=v1, give-only-json-values=v1}
   The test gives numbers of up to 25 digits, and fails when read_json_text
   gives "valid" for a number outside the range of integers, "invalid" for
   one inside it, or another integer. *)
let read_json_text_answers_each_number =
  property ~count:1000
    ~name:
      "read_json_text gives an integer for a number when, and only when, it \
       writes one"
    ~print:Fun.id number_text_gen read_json_agrees

let deep_json_texts_need_no_deep_stack () =
  let value, _, bytes = deep_json () in
  let _, prefix, _ = deep_parts () in
  let spaced =
    String.concat ""
      (List.map
         (function
           | ('[' | '{' | ':') as char -> String.make 1 char ^ " \t"
           | (']' | '}') as char -> "\n" ^ String.make 1 char
           | char -> String.make 1 char)
         (List.of_seq (String.to_seq bytes)))
  in
  let read, read_spaced, unclosed =
    Small_stack.run (fun () ->
        ( Json.read_json_text bytes,
          Json.read_json_text ("\n" ^ spaced ^ "\r\n"),
          Json.read_json_text (prefix ^ "true") ))
  in
  let is_value = function
    | Some read -> Json.equal read value
    | None -> false
  in
  Alcotest.(check bool) "the deep value" true (is_value read);
  Alcotest.(check bool) "the deep value with spaces" true (is_value read_spaced);
  Alcotest.(check bool) "the unclosed value" true (Option.is_none unclosed)

let tests_of_json_texts =
  [
    Alcotest.test_case "deep JSON texts need no deep stack" `Quick
      deep_json_texts_need_no_deep_stack;
    read_json_text_gives_back_each_json_value;
    read_json_text_takes_exactly_the_json_values;
    read_json_text_answers_any_bytes;
    read_json_text_answers_each_number;
  ]

let vector_groups =
  [
    write_json_vectors; write_line_vectors; read_line_vectors; read_json_vectors;
  ]

let tests =
  Vectors.tests "data-forms.json-lines" vector_groups
  @ [ Vectors.covers "data-forms.json-lines" json_lines_set vector_groups ]
  @ tests_of_json @ tests_of_lines @ tests_of_json_texts
