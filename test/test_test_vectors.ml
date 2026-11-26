(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
open Sinter_test_vectors
module Gen = QCheck2.Gen
module V = Vector_json

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

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

let canonical_of_json value = V.canonical (V.of_basic (basic_of_json value))

let model_error : Test_vector_set.error -> Set_model.error = function
  | Test_vector_set.Unterminated line -> Set_model.Unterminated line
  | Test_vector_set.Not_canonical line -> Set_model.Not_canonical line
  | Test_vector_set.Not_vector_object line -> Set_model.Not_vector_object line
  | Test_vector_set.Other_schema line -> Set_model.Other_schema line

let line_of_error : Test_vector_set.error -> int = function
  | Test_vector_set.Unterminated line
  | Test_vector_set.Not_canonical line
  | Test_vector_set.Not_vector_object line
  | Test_vector_set.Other_schema line ->
      line

let print_error : Test_vector_set.error -> string = function
  | Test_vector_set.Unterminated line -> Printf.sprintf "Unterminated %d" line
  | Test_vector_set.Not_canonical line -> Printf.sprintf "Not_canonical %d" line
  | Test_vector_set.Not_vector_object line ->
      Printf.sprintf "Not_vector_object %d" line
  | Test_vector_set.Other_schema line -> Printf.sprintf "Other_schema %d" line

let error_testable =
  Alcotest.testable
    (fun formatter error ->
      Format.pp_print_string formatter (print_error error))
    ( = )

let test_vectors_set = Vectors.read "data-forms.test-vectors"

let give_read_set (vector : Vectors.vector) =
  let bytes =
    match vector.input with
    | `String digits -> V.of_hex digits
    | other -> Alcotest.failf "not a string: %s" (Yojson.Basic.to_string other)
  in
  match Test_vector_set.read bytes with
  | Ok set ->
      `Assoc
        [
          ("result", `String "valid");
          ( "values",
            `Assoc [ ("objects", `List (List.map basic_of_json set.objects)) ]
          );
        ]
  | Error _ -> `Assoc [ ("result", `String "invalid"); ("values", `Assoc []) ]

(* @verifies data-forms#test-vectors[read-set]
   Test_vector_set.read gives a result for every byte sequence; the test fails
   when that result, or the objects that read gives, differ from the result and
   the objects of a vector. *)
let read_set_vectors =
  Vectors.group test_vectors_set ~name:"read-set" ~form:"#read-set-vector=v1"
    give_read_set

let text value = V.String (V.Text value)

let alnum_chars =
  let chars = ref [] in
  for code = Char.code '0' to Char.code '9' do
    chars := Char.chr code :: !chars
  done;
  for code = Char.code 'A' to Char.code 'Z' do
    chars := Char.chr code :: !chars
  done;
  for code = Char.code 'a' to Char.code 'z' do
    chars := Char.chr code :: !chars
  done;
  List.rev !chars

let label_chars =
  let chars = ref [] in
  for code = 0 to 127 do
    let char = Char.chr code in
    if Set_model.is_label_char char then chars := char :: !chars
  done;
  List.rev !chars

let segment_piece_gen =
  Gen.string_size ~gen:(Gen.oneof_list alnum_chars) (Gen.int_range 1 4)

let segment_gen =
  let open Gen in
  let* first = segment_piece_gen in
  let* rest =
    list_size (int_range 0 3)
      (pair (oneof_list [ "-"; "_"; "." ]) segment_piece_gen)
  in
  return
    (String.concat ""
       (first :: List.map (fun (sep, piece) -> sep ^ piece) rest))

let label_gen =
  Gen.oneof
    [
      Gen.oneof_list [ "v1"; "v2"; "2026-11_rc+1"; "!\"$)+-.0<>?AZ\\^z|~" ];
      Gen.string_size ~gen:(Gen.oneof_list label_chars) (Gen.int_range 1 8);
    ]

let group_names =
  [| "a"; "b"; "c"; "g-2"; "a1"; "a-0"; "a-b"; "ab"; "read-set"; "z9-0x" |]

let group_name_gen = Gen.oneof_array group_names

let needs_gen =
  let open Gen in
  let* raw = list_size (int_range 1 4) group_name_gen in
  let sorted = List.sort_uniq V.compare_keys raw in
  return sorted

let make_vector_object ~form ~group ~input ~result ~values ~note ~needs =
  V.Object
    (List.filter_map Fun.id
       [
         Some (V.Text "form", text form);
         Some (V.Text "group", text group);
         Some (V.Text "input", input);
         Option.map
           (fun needs -> (V.Text "needs", V.Array (List.map text needs)))
           needs;
         Option.map (fun note -> (V.Text "note", text note)) note;
         Option.map (fun result -> (V.Text "result", text result)) result;
         Option.map (fun values -> (V.Text "values", values)) values;
       ])

let set_objects_gen =
  let open Gen in
  let* count = int_range 0 8 in
  let* shared_segment = segment_gen in
  let* group_segments =
    list_size
      (return (Array.length group_names))
      (oneof [ segment_gen; return shared_segment ])
  in
  let segment_for index = List.nth group_segments index in
  let line_gen =
    let* group_index = int_range 0 (Array.length group_names - 1) in
    let group = group_names.(group_index) in
    let segment = segment_for group_index in
    let* label = label_gen in
    let form = "#" ^ segment ^ "=" ^ label in
    let* input = V.value_gen in
    let* shape = int_range 0 2 in
    let* result =
      oneof_list [ "valid"; "invalid"; ""; "a \"quoted\" result" ]
    in
    let* values = V.value_gen in
    let* note = option V.text_gen in
    let* needs = option needs_gen in
    return
      (make_vector_object ~form ~group ~input
         ~result:(if shape = 1 then None else Some result)
         ~values:(if shape = 0 then None else Some values)
         ~note ~needs)
  in
  list_size (return count) line_gen

let print_objects objects = V.hex (Set_model.write objects)

let member name = function
  | V.Object members -> List.assoc_opt (V.Text name) members
  | _ -> None

let text_member name object_ =
  match member name object_ with
  | Some (V.String (V.Text value)) -> Some value
  | _ -> None

let vector_fits (vector : Test_vector_set.vector) object_ =
  let json_fits value thing = canonical_of_json value = V.canonical thing in
  let option_fits fits value thing =
    match (value, thing) with
    | Some value, Some thing -> fits value thing
    | None, None -> true
    | _ -> false
  in
  text_member "form" object_ = Some vector.form
  && text_member "group" object_ = Some vector.group
  && option_fits json_fits (Some vector.input) (member "input" object_)
  && option_fits json_fits vector.values (member "values" object_)
  && Option.map Text.encode vector.result = text_member "result" object_
  && Option.map Text.encode vector.note = text_member "note" object_
  &&
  match member "needs" object_ with
  | Some (V.Array names) ->
      List.map (fun name -> Some name) vector.needs
      = List.map
          (function V.String (V.Text name) -> Some name | _ -> None)
          names
  | None -> vector.needs = []
  | Some _ -> false

let set_matches_objects bytes (set : Test_vector_set.t) objects =
  let round_trip =
    String.concat ""
      (List.map
         (fun object_ -> Json.canonical_byte_sequence object_ ^ "\n")
         set.objects)
  in
  String.equal round_trip bytes
  && List.map canonical_of_json set.objects = List.map V.canonical objects
  && List.length set.vectors = List.length objects
  && List.for_all2 vector_fits set.vectors objects

let prefix_before_line bytes line_number =
  if line_number <= 1 then Some ""
  else
    let rec find_nl start remaining =
      match String.index_from_opt bytes start '\n' with
      | None -> None
      | Some nl ->
          if remaining = 1 then Some (String.sub bytes 0 (nl + 1))
          else find_nl (nl + 1) (remaining - 1)
    in
    find_nl 0 (line_number - 1)

let prefix_is_valid bytes err =
  let line_number = line_of_error err in
  match prefix_before_line bytes line_number with
  | None -> false
  | Some prefix -> (
      match Test_vector_set.read prefix with
      | Ok set -> List.length set.vectors = line_number - 1
      | Error _ -> false)

let read_matches_model bytes =
  match (Test_vector_set.read bytes, Set_model.read bytes) with
  | Ok set, Ok objects -> set_matches_objects bytes set objects
  | Error err, Error expected ->
      model_error err = expected && prefix_is_valid bytes err
  | _ -> false

(* @verifies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1, test-vector-set=v1}
   The test generates valid test-vector sets and fails when read rejects one,
   returns objects or vector fields that differ from the lines, or fails to
   reconstruct the input bytes from the returned objects. *)
let read_gives_the_objects_and_fields_of_each_set =
  property ~count:500
    ~name:
      "read gives the objects and fields of each test-vector set, in their \
       order"
    ~print:print_objects set_objects_gen (fun objects ->
      let bytes = Set_model.write objects in
      (match Set_model.read bytes with
        | Ok model_objects ->
            List.map V.canonical model_objects = List.map V.canonical objects
        | Error _ -> false)
      &&
      match Test_vector_set.read bytes with
      | Ok set -> set_matches_objects bytes set objects
      | Error _ -> false)

let line_corruption_gen objects =
  let lines = List.map (fun object_ -> Set_model.write [ object_ ]) objects in
  let count = List.length lines in
  let open Gen in
  let* first = int_range 0 (max 0 (count - 1)) in
  let* second = int_range 0 (max 0 (count - 1)) in
  let* kind = int_range 0 7 in
  let* replacement =
    oneof_list
      [
        "\n";
        "{}\n";
        "{\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"rev\":\"v1\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"n\":1,\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\r\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}";
        "\xef\xbb\xbf{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "[1]\n";
        "\"a\"\n";
        "1\n";
        "true\n";
        "{\"form\":1,\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"a=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a--b=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=*\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1=v2\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"A\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"1a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a-\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":true,\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"result\":[]}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"note\":{},\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":{},\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[],\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[true],\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"b\",\"a\"],\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a\",\"a\"],\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a-\"],\"result\":\"valid\"}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1}\n";
        "{\"form\":\"#a=v1\",\"group\":\"a\",\"result\":\"valid\"}\n";
        "{\"extra\":1,\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#other-schema=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"form\":\"#other-schema=v2\",\"group\":\"b\",\"input\":2,\"result\":\"invalid\"}\n";
        "{\"form\": \"#a=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
        "{\"group\":\"a\",\"form\":\"#a=v1\",\"input\":1,\"result\":\"valid\"}\n";
      ]
  in
  let indexed = List.mapi (fun index line -> (index, line)) lines in
  let mutated =
    if count = 0 then [ replacement ]
    else
      match kind with
      | 0 ->
          List.map
            (fun (index, line) ->
              if index = first then List.nth lines second
              else if index = second then List.nth lines first
              else line)
            indexed
      | 1 ->
          List.concat_map
            (fun (index, line) ->
              if index = first then [ line; line ] else [ line ])
            indexed
      | 2 ->
          List.filter_map
            (fun (index, line) -> if index = first then None else Some line)
            indexed
      | 3 ->
          List.concat_map
            (fun (index, line) ->
              if index = first then [ replacement; line ] else [ line ])
            indexed
      | 4 -> lines @ [ replacement ]
      | 5 ->
          List.map
            (fun (index, line) -> if index = first then replacement else line)
            indexed
      | 6 ->
          let target_group =
            Option.value
              (text_member "group" (List.nth objects first))
              ~default:"a"
          in
          let conflict =
            Set_model.write
              [
                make_vector_object ~form:"#conflict-schema-0=v9"
                  ~group:target_group ~input:(text "z") ~result:(Some "valid")
                  ~values:None ~note:None ~needs:None;
              ]
          in
          lines @ [ conflict ]
      | _ ->
          let joined = String.concat "" lines in
          if String.length joined > 0 then
            [ String.sub joined 0 (String.length joined - 1) ]
          else [ replacement ]
  in
  return (String.concat "" mutated)

let corrupted_set_gen =
  Gen.(
    set_objects_gen >>= fun objects ->
    oneof
      [ V.corrupt_gen (Set_model.write objects); line_corruption_gen objects ])

(* @verifies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1, test-vector-set=v1}
   The test changes generated test-vector sets by a byte or a line and fails
   when read disagrees with the model on validity, returned objects, the error
   constructor and line number, or when the lines before the line of the error
   are not a test-vector set. *)
let read_accepts_exactly_the_sets =
  property ~count:2000
    ~name:
      "read accepts a byte sequence when, and only when, it is a test-vector \
       set"
    ~print:V.hex corrupted_set_gen read_matches_model

(* @verifies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1}
   The test gives arbitrary bytes and bytes after a valid vector line and fails
   when read raises or disagrees with the model on validity, objects, or error. *)
let read_answers_any_bytes =
  property ~count:1000 ~name:"read gives a set or an error for any bytes"
    ~print:V.hex
    (Gen.oneof
       [
         Gen.string_size ~gen:Gen.char (Gen.int_range 0 60);
         Gen.map
           (fun tail ->
             "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":\"x\",\"result\":\"valid\"}\n"
             ^ tail)
           (Gen.string_size ~gen:V.byte_gen (Gen.int_range 0 60));
       ])
    read_matches_model

let single_line_with ~form ~group ?needs () =
  Set_model.write
    [
      make_vector_object ~form ~group ~input:(text "x") ~result:(Some "valid")
        ~values:None ~note:None ~needs;
    ]

let check_line_valid label_msg bytes =
  match Test_vector_set.read bytes with
  | Ok { vectors = [ _ ]; objects = [ _ ] } -> ()
  | Ok _ -> Alcotest.failf "%s: unexpected line count" label_msg
  | Error err ->
      Alcotest.failf "%s: expected Ok, got %s" label_msg (print_error err)

let check_line_error label_msg expected bytes =
  match Test_vector_set.read bytes with
  | Ok _ ->
      Alcotest.failf "%s: expected %s, got Ok" label_msg (print_error expected)
  | Error actual -> Alcotest.(check error_testable) label_msg expected actual

(* @verifies data-forms#test-vector-set=v1
   The test checks every ASCII character and non-ASCII UTF-8 in each position
   of segment and label and fails when read accepts a byte sequence whose form
   pin does not match the production form-pin or rejects a valid test-vector
   set. *)
let form_pin_boundaries () =
  let check_form form =
    let bytes = single_line_with ~form ~group:"a" () in
    if Set_model.is_form_pin form then
      match Test_vector_set.read bytes with
      | Ok { vectors = [ vector ]; objects = [ _ ] } ->
          Alcotest.(check string) "form field" form vector.form
      | Ok _ -> Alcotest.failf "valid form %S: unexpected line count" form
      | Error err ->
          Alcotest.failf "valid form %S: expected Ok, got %s" form
            (print_error err)
    else
      check_line_error
        (Printf.sprintf "invalid form %S" form)
        (Test_vector_set.Not_vector_object 1) bytes
  in
  for code = 0 to 127 do
    let s = String.make 1 (Char.chr code) in
    check_form ("#a=" ^ s);
    check_form ("#a=" ^ s ^ "x");
    check_form ("#a=x" ^ s ^ "y");
    check_form ("#a=x" ^ s);
    check_form ("#" ^ s ^ "=v1");
    check_form ("#" ^ s ^ "a=v1");
    check_form ("#a" ^ s ^ "b=v1");
    check_form ("#a" ^ s ^ "=v1")
  done;
  List.iter check_form
    [
      "";
      "#";
      "#=";
      "=v1";
      "a=v1";
      "#a";
      "#=v1";
      "#a=";
      "##a=v1";
      "#a=v1=v2";
      "#0=v1";
      "#9-0_A.z=v1";
      "#1a=v1";
      "#a=\"\\";
      "#a=\xc3\xa9";
      "#\xc3\xa9=v1";
      "#a=\xf0\x9f\x98\x80";
      "#a--b=v1";
      "#a-_b=v1";
      "#a-.b=v1";
      "#a_-b=v1";
      "#a__b=v1";
      "#a_.b=v1";
      "#a.-b=v1";
      "#a._b=v1";
      "#a..b=v1";
    ]

(* @verifies data-forms#test-vector-set=v1
   The test checks every ASCII character and non-ASCII UTF-8 in each position
   of a group name, in both group and needs, and fails when read accepts a byte
   sequence whose group name does not match the production group-name or rejects
   a valid test-vector set. *)
let group_name_boundaries () =
  let check_group group =
    let bytes = single_line_with ~form:"#a=v1" ~group () in
    if Set_model.is_group_name group then
      check_line_valid (Printf.sprintf "valid group %S" group) bytes
    else
      check_line_error
        (Printf.sprintf "invalid group %S" group)
        (Test_vector_set.Not_vector_object 1) bytes
  in
  let check_need need =
    let bytes = single_line_with ~form:"#a=v1" ~group:"a" ~needs:[ need ] () in
    if Set_model.is_group_name need then
      check_line_valid (Printf.sprintf "valid need %S" need) bytes
    else
      check_line_error
        (Printf.sprintf "invalid need %S" need)
        (Test_vector_set.Not_vector_object 1) bytes
  in
  for code = 0 to 127 do
    let s = String.make 1 (Char.chr code) in
    List.iter check_group [ s; s ^ "a"; "a" ^ s ^ "b"; "a" ^ s ];
    List.iter check_need [ s; s ^ "a"; "a" ^ s ^ "b"; "a" ^ s ]
  done;
  List.iter check_group
    [ ""; "a-0"; "a-9"; "a0-1b-9z"; "a--b"; "-a"; "a-"; "a_b"; "\xc3\xa9" ];
  List.iter check_need
    [ ""; "a-0"; "a-9"; "a0-1b-9z"; "a--b"; "-a"; "a-"; "a_b"; "\xc3\xa9" ]

(* @verifies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1, test-vector-set=v1}
   The test checks edge cases of empty sets, canonical encoding, vector objects,
   non-adjacent group schema consistency, and the error-order rules of read. *)
let error_precedence_and_edge_cases () =
  (match Test_vector_set.read "" with
  | Ok { vectors = []; objects = [] } -> ()
  | Ok _ -> Alcotest.fail "empty byte sequence gave non-empty set"
  | Error err ->
      Alcotest.failf "empty byte sequence failed with %s" (print_error err));
  let line_a1 =
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":\"x\",\"result\":\"valid\"}\n"
  in
  let line_a2 =
    "{\"form\":\"#a=v2\",\"group\":\"a\",\"input\":\"y\",\"result\":\"valid\"}\n"
  in
  let line_b =
    "{\"form\":\"#b=v1\",\"group\":\"b\",\"input\":\"z\",\"result\":\"valid\"}\n"
  in
  let line_a_other_no_nl =
    "{\"form\":\"#c=v1\",\"group\":\"a\",\"input\":\"w\",\"result\":\"valid\"}"
  in
  let line_a_other = line_a_other_no_nl ^ "\n" in
  (match Test_vector_set.read (line_a1 ^ line_b ^ line_a2) with
  | Ok { vectors; objects } ->
      Alcotest.(check int) "three vectors" 3 (List.length vectors);
      Alcotest.(check int) "three objects" 3 (List.length objects)
  | Error err ->
      Alcotest.failf "interleaved group with differing label failed: %s"
        (print_error err));
  check_line_error "non-adjacent schema part conflict"
    (Test_vector_set.Other_schema 3)
    (line_a1 ^ line_b ^ line_a_other);
  check_line_error "schema part name is case-sensitive"
    (Test_vector_set.Other_schema 2)
    (line_a1
   ^ "{\"form\":\"#A=v1\",\"group\":\"a\",\"input\":\"y\",\"result\":\"valid\"}\n"
    );
  check_line_error "schema part name prefix differs"
    (Test_vector_set.Other_schema 2)
    (line_a1
   ^ "{\"form\":\"#a-b=v1\",\"group\":\"a\",\"input\":\"y\",\"result\":\"valid\"}\n"
    );
  check_line_error "Unterminated beats Not_canonical on line 1"
    (Test_vector_set.Unterminated 1) "not json";
  check_line_error "Unterminated beats Not_vector_object on line 1"
    (Test_vector_set.Unterminated 1) "{}";
  check_line_error "Unterminated beats Other_schema on line 2"
    (Test_vector_set.Unterminated 2)
    (line_a1 ^ line_a_other_no_nl);
  check_line_error "Not_canonical beats Not_vector_object on line 1"
    (Test_vector_set.Not_canonical 1) "{\"form\": \"#a=v1\"}\n";
  check_line_error "Not_canonical beats Other_schema on line 2"
    (Test_vector_set.Not_canonical 2)
    (line_a1
   ^ "{\"form\": \"#c=v1\",\"group\":\"a\",\"input\":\"y\",\"result\":\"valid\"}\n"
    );
  check_line_error "Not_canonical on line 1 beats Unterminated on line 2"
    (Test_vector_set.Not_canonical 1) "not json\nunterminated";
  check_line_error "Not_vector_object on line 1 beats Unterminated on line 2"
    (Test_vector_set.Not_vector_object 1) "{}\nunterminated";
  check_line_error "Other_schema on line 2 beats Unterminated on line 3"
    (Test_vector_set.Other_schema 2)
    (line_a1 ^ line_a_other ^ "tail");
  check_line_error "Not_vector_object beats Other_schema on the same line"
    (Test_vector_set.Not_vector_object 2)
    (line_a1
   ^ "{\"extra\":1,\"form\":\"#c=v1\",\"group\":\"a\",\"input\":\"y\",\"result\":\"valid\"}\n"
    );
  check_line_error "unknown member before form"
    (Test_vector_set.Not_vector_object 1)
    "{\"a\":1,\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
  check_line_error "unknown member between group and input"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"h\":1,\"input\":1,\"result\":\"valid\"}\n";
  check_line_error "unknown member after values"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"values\":{},\"z\":1}\n";
  check_line_error "missing form" (Test_vector_set.Not_vector_object 1)
    "{\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n";
  check_line_error "missing group" (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"input\":1,\"result\":\"valid\"}\n";
  check_line_error "missing input" (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"result\":\"valid\"}\n";
  check_line_error "missing result and values"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1}\n";
  check_line_valid "needs key order across prefix, hyphen, digit, and letter"
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a\",\"a-0\",\"a0\",\"aa\"],\"result\":\"valid\"}\n";
  check_line_error "needs rejects digit before hyphen"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a0\",\"a-0\"],\"result\":\"valid\"}\n";
  check_line_error "needs rejects longer prefix before shorter"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a-0\",\"a\"],\"result\":\"valid\"}\n";
  check_line_error "canonical integer is Not_vector_object"
    (Test_vector_set.Not_vector_object 1) "1\n";
  check_line_error "canonical array is Not_vector_object"
    (Test_vector_set.Not_vector_object 1) "[1]\n";
  check_line_error "canonical string is Not_vector_object"
    (Test_vector_set.Not_vector_object 1) "\"a\"\n";
  check_line_error "canonical boolean is Not_vector_object"
    (Test_vector_set.Not_vector_object 1) "true\n";
  check_line_error "empty line is Not_canonical"
    (Test_vector_set.Not_canonical 1) "\n";
  check_line_error "invalid UTF-8 is Not_canonical"
    (Test_vector_set.Not_canonical 1) "\xff\n";
  check_line_error "negative zero is Not_canonical"
    (Test_vector_set.Not_canonical 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":-0,\"result\":\"valid\"}\n";
  check_line_error "non-canonical escape is Not_canonical"
    (Test_vector_set.Not_canonical 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":\"\\u0041\",\"result\":\"valid\"}\n";
  check_line_error "integer below min is Not_canonical"
    (Test_vector_set.Not_canonical 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":-9007199254740992,\"result\":\"valid\"}\n";
  check_line_valid "boundary integers and control/unicode characters"
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":[-9007199254740991,9007199254740991,\"\\u0000\\b\\t\\n\\f\\r\\u001f\xe2\x80\xa8\xe2\x80\xa9\"],\"result\":\"valid\"}\n";
  check_line_error "needs duplicate after first pair"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a\",\"b\",\"b\"],\"result\":\"valid\"}\n";
  check_line_error "needs out of order after first pair"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a\",\"c\",\"b\"],\"result\":\"valid\"}\n";
  check_line_error "needs non-string element after first element"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a\",1],\"result\":\"valid\"}\n";
  check_line_error "needs invalid group name after first element"
    (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":[\"a\",\"1b\"],\"result\":\"valid\"}\n";
  check_line_error "needs boolean" (Test_vector_set.Not_vector_object 1)
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"needs\":true,\"result\":\"valid\"}\n"

let depth = 100_000
let deep_input () = String.make depth '[' ^ "1" ^ String.make depth ']'

let deep_sets_need_no_deep_stack () =
  let head = "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":" in
  let tail = ",\"result\":\"valid\"}\n" in
  let deep_in_input = head ^ deep_input () ^ tail in
  let deep_in_values =
    "{\"form\":\"#a=v1\",\"group\":\"a\",\"input\":1,\"values\":"
    ^ deep_input () ^ "}\n"
  in
  let unclosed = head ^ String.make depth '[' ^ tail in
  let long_segment =
    "{\"form\":\"#" ^ String.make depth 'a'
    ^ "=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n"
  in
  let long_bad_segment =
    "{\"form\":\"#" ^ String.make depth 'a'
    ^ "!=v1\",\"group\":\"a\",\"input\":1,\"result\":\"valid\"}\n"
  in
  let long_group =
    "{\"form\":\"#a=v1\",\"group\":\"" ^ String.make depth 'a'
    ^ "\",\"input\":1,\"result\":\"valid\"}\n"
  in
  let ( read_in_input,
        read_in_values,
        read_unclosed,
        read_long_segment,
        read_long_bad_segment,
        read_long_group ) =
    Small_stack.run (fun () ->
        ( Test_vector_set.read deep_in_input,
          Test_vector_set.read deep_in_values,
          Test_vector_set.read unclosed,
          Test_vector_set.read long_segment,
          Test_vector_set.read long_bad_segment,
          Test_vector_set.read long_group ))
  in
  Alcotest.(check bool)
    "deep input" true
    (match read_in_input with
    | Ok { vectors = [ vector ]; _ } ->
        String.equal (Json.canonical_byte_sequence vector.input) (deep_input ())
    | _ -> false);
  Alcotest.(check bool)
    "deep values" true
    (match read_in_values with
    | Ok { vectors = [ { values = Some value; _ } ]; _ } ->
        String.equal (Json.canonical_byte_sequence value) (deep_input ())
    | _ -> false);
  Alcotest.(check bool)
    "unclosed deep set" true
    (read_unclosed = Error (Test_vector_set.Not_canonical 1));
  Alcotest.(check bool)
    "long segment" true
    (match read_long_segment with
    | Ok { vectors = [ vector ]; _ } ->
        String.equal vector.form ("#" ^ String.make depth 'a' ^ "=v1")
    | _ -> false);
  Alcotest.(check bool)
    "long invalid segment" true
    (read_long_bad_segment = Error (Test_vector_set.Not_vector_object 1));
  Alcotest.(check bool)
    "long group" true
    (match read_long_group with
    | Ok { vectors = [ vector ]; _ } ->
        String.equal vector.group (String.make depth 'a')
    | _ -> false)

let many_groups_set count =
  let buffer = Buffer.create (count * 80) in
  for index = 0 to count - 1 do
    Printf.bprintf buffer
      "{\"form\":\"#g-%d=v1\",\"group\":\"g-%d\",\"input\":%d,\"result\":\"valid\"}\n"
      index index index
  done;
  Buffer.contents buffer

let read_time_grows_near_linearly () =
  Time_growth.check ~bound:8.0 ~size:256 ~input:many_groups_set (fun bytes ->
      match Test_vector_set.read bytes with
      | Ok set -> set
      | Error err -> Alcotest.failf "generated set failed: %s" (print_error err))

let vector_groups = [ read_set_vectors ]

let tests =
  Vectors.tests "data-forms.test-vectors" vector_groups
  @ [
      Vectors.covers "data-forms.test-vectors" test_vectors_set vector_groups;
      Alcotest.test_case "read accepts a form only when it is a form pin" `Quick
        form_pin_boundaries;
      Alcotest.test_case
        "read accepts a group or a need only when it is a group name" `Quick
        group_name_boundaries;
      Alcotest.test_case
        "read decides the edges of each rule and gives the first error of the \
         first bad line"
        `Quick error_precedence_and_edge_cases;
      Alcotest.test_case "deep sets need no deep stack" `Quick
        deep_sets_need_no_deep_stack;
      Alcotest.test_case "reading grows near linearly with many groups" `Quick
        read_time_grows_near_linearly;
      read_gives_the_objects_and_fields_of_each_set;
      read_accepts_exactly_the_sets;
      read_answers_any_bytes;
    ]
