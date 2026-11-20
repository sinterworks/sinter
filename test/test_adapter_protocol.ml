(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_adapter_protocol
module Gen = QCheck2.Gen
module D = Sinter_pack_descriptor.Descriptor
module V = Vector_json

let adapters_set = Vectors.read "packs.adapters"
let text_of = Test_packs.text_of

let member name = function
  | `Assoc members -> List.assoc_opt name members
  | _ -> None

let required name json =
  match member name json with
  | Some value -> value
  | None ->
      Alcotest.failf "no member %s in %s" name (Yojson.Basic.to_string json)

let string = function
  | `String text -> text
  | other -> Alcotest.failf "not a string: %s" (Yojson.Basic.to_string other)

let integer = function
  | `Int number -> number
  | other -> Alcotest.failf "not an integer: %s" (Yojson.Basic.to_string other)

let list = function
  | `List items -> items
  | other -> Alcotest.failf "not an array: %s" (Yojson.Basic.to_string other)

let setting_value = function
  | `String text -> D.String text
  | `Bool flag -> D.Boolean flag
  | `List items -> D.Strings (List.map string items)
  | other ->
      Alcotest.failf "not a setting value: %s" (Yojson.Basic.to_string other)

let settings_of json =
  match json with
  | `Assoc members -> (
      match
        Setting_values.of_list
          (List.map (fun (name, value) -> (name, setting_value value)) members)
      with
      | Ok values -> values
      | Error _ -> Alcotest.fail "the settings give no values")
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let runner_of text =
  match Sinter_pack_descriptor.Pack_name.of_string text with
  | Some name -> name
  | None -> Alcotest.failf "not a pack name: %S" text

let piece_of json =
  match json with
  | `Assoc [ ("text", `String text) ] -> Test_entry.Text_piece (text_of text)
  | `Assoc [ ("placeholder", `String text) ] ->
      Test_entry.Placeholder (text_of text)
  | other -> Alcotest.failf "not a piece: %s" (Yojson.Basic.to_string other)

let entry_of json =
  let path =
    match
      Sinter_paths.Path.of_text (text_of (string (required "path" json)))
    with
    | Ok path -> path
    | Error _ -> Alcotest.fail "not a valid path"
  in
  match
    Test_entry.make
      ~id:(text_of (string (required "id" json)))
      ~path
      ~line:(integer (required "line" json))
      ~eline:(integer (required "eline" json))
      ~kind:
        (match required "suite" json with
        | `Bool true -> Test_entry.Test_suite
        | _ -> Test_entry.Test_case)
      ~names:
        (List.map
           (fun name -> List.map piece_of (list name))
           (list (required "names" json)))
      ~labels:
        (List.map
           (fun label -> text_of (string label))
           (list (required "labels" json)))
  with
  | Ok entry -> entry
  | Error _ -> Alcotest.fail "the test entry is out of range"

let request_of input =
  let runner = runner_of (string (required "runner" input)) in
  let settings = settings_of (required "settings" input) in
  let report = text_of (string (required "report" input)) in
  match string (required "function" input) with
  | "recognise" -> Ok (Request.recognise ~runner ~settings ~report)
  | _ ->
      Request.bind ~runner ~settings ~report
        ~root:(text_of (string (required "root" input)))
        (List.map entry_of (list (required "tests" input)))

let give_request (vector : Vectors.vector) =
  match request_of vector.input with
  | Ok bytes -> `Assoc [ ("values", `Assoc [ ("request", `String bytes) ]) ]
  | Error (Request.Repeated_id id) ->
      Alcotest.failf "a repeated id: %s" (Text.encode id)

(* @verifies packs#adapters[requests][*]=v1
   The test makes the request of each vector from its runner, its settings,
   its report name, and, for bind, its root and its test entries, and compares
   its bytes with the request of the vector. *)
let request_vectors =
  Vectors.group adapters_set ~name:"requests" ~rev:"v1" give_request

let text = Text.encode

let result_form (result : Response.test_result) =
  `Assoc
    ([
       ("name", `String (text result.name));
       ( "status",
         `String
           (match result.status with
           | Pass -> "pass"
           | Fail -> "fail"
           | Error -> "error"
           | Skip -> "skip") );
     ]
    @ (match result.file with
      | Some file -> [ ("file", `String (text file)) ]
      | None -> [])
    @ (match result.line with
      | Some line -> [ ("line", `Int line) ]
      | None -> [])
    @ match result.ms with Some ms -> [ ("ms", `Int ms) ] | None -> [])

let failed_form = function
  | Some error -> ("failed", `Assoc [ ("error", `String (text error)) ])
  | None -> ("failed", `Assoc [])

let response_answer function_ bytes =
  match function_ with
  | Adapter_reference.Recognise -> (
      match Response.recognise bytes with
      | Recognised -> ("recognised", `Assoc [])
      | Not_recognised -> ("not recognised", `Assoc [])
      | Recognition_failed error -> failed_form error)
  | Adapter_reference.Bind ids -> (
      match Response.bind ~ids:(List.map text_of ids) bytes with
      | Bound { results; bindings; warnings } ->
          ( "bound",
            `Assoc
              [
                ( "bindings",
                  `List
                    (List.map
                       (fun (binding : Response.binding) ->
                         `Assoc
                           [
                             ("reason", `String (text binding.reason));
                             ("result", `Int binding.result);
                             ("test", `String (text binding.test));
                           ])
                       bindings) );
                ("results", `List (List.map result_form results));
                ( "warnings",
                  `List
                    (List.map (fun warning -> `String (text warning)) warnings)
                );
              ] )
      | Bind_failed error -> failed_form error)

let function_of input =
  match string (required "function" input) with
  | "recognise" -> Adapter_reference.Recognise
  | _ -> Adapter_reference.Bind (List.map string (list (required "ids" input)))

let give_response (vector : Vectors.vector) =
  let result, values =
    response_answer (function_of vector.input)
      (V.of_hex (string (required "response" vector.input)))
  in
  `Assoc [ ("result", `String result); ("values", values) ]

(* @verifies packs#adapters[responses][*]=v1
   The test reads the response of each vector for its function and its test
   entry ids, and compares the result, the test results, the binding objects,
   the warnings, and the error text with those of the vector. *)
let response_vectors =
  Vectors.group adapters_set ~name:"responses" ~rev:"v1" give_response

let pick = Gen.oneof_list

let tricky_text_gen =
  Gen.oneof_weighted
    [
      (4, pick [ "a"; "B"; "ab"; "t1"; "t2"; "math"; "" ]);
      ( 2,
        pick
          [
            "\xee\x80\x80";
            "\xf0\x9f\x98\x80";
            "\xc3\xa9";
            "\xe2\x80\xa8";
            "\xc2\x85";
          ] );
      (1, pick [ "a \"q\" \\"; "\x01\t\n\r\x1f\x7f"; "${n}"; "</script>" ]);
      (1, V.text_gen);
    ]

let distinct list = List.sort_uniq compare list

let settings_json_gen =
  Gen.map
    (fun pairs ->
      `Assoc
        (List.fold_left
           (fun kept (name, value) ->
             if List.mem_assoc name kept then kept else kept @ [ (name, value) ])
           [] pairs))
    (Gen.list_size (Gen.int_bound 4)
       (Gen.pair tricky_text_gen
          (Gen.oneof
             [
               Gen.map (fun text -> `String text) tricky_text_gen;
               Gen.map (fun flag -> `Bool flag) Gen.bool;
               Gen.map
                 (fun items ->
                   `List (List.map (fun text -> `String text) items))
                 (Gen.list_size (Gen.int_bound 3) tricky_text_gen);
             ])))

let piece_gen =
  Gen.map2
    (fun placeholder text ->
      `Assoc [ ((if placeholder then "placeholder" else "text"), `String text) ])
    Gen.bool tricky_text_gen

let entry_gen id =
  Gen.map4
    (fun (line, eline) suite names labels ->
      `Assoc
        [
          ("eline", `Int eline);
          ("id", `String id);
          ("labels", `List (List.map (fun label -> `String label) labels));
          ("line", `Int line);
          ("names", `List (List.map (fun name -> `List name) names));
          ("path", `String "src/m.test.ts");
          ("suite", `Bool suite);
        ])
    (Gen.pair
       (Gen.oneof [ Gen.int_range 0 20; Gen.return 9_007_199_254_740_991 ])
       (Gen.oneof [ Gen.int_range 0 20; Gen.return 9_007_199_254_740_991 ]))
    Gen.bool
    (Gen.list_size (Gen.int_bound 3)
       (Gen.list_size (Gen.int_bound 3) piece_gen))
    (Gen.list_size (Gen.int_bound 4)
       (pick [ "each"; "table"; "B"; "a"; "\xf0\x9f\x98\x80"; "\xee\x80\x80" ]))

let request_input_gen =
  Gen.bind
    (Gen.quad Gen.bool
       (pick [ "vitest"; "nextest"; "x"; "cargo-test" ])
       settings_json_gen
       (Gen.pair tricky_text_gen tricky_text_gen))
    (fun (recognise, runner, settings, (report, root)) ->
      let common =
        [
          ("report", `String report);
          ("runner", `String runner);
          ("settings", settings);
        ]
      in
      if recognise then
        Gen.return (`Assoc (("function", `String "recognise") :: common))
      else
        Gen.map
          (fun entries ->
            `Assoc
              ((("function", `String "bind") :: common)
              @ [ ("root", `String root); ("tests", `List entries) ]))
          (Gen.bind
             (Gen.map distinct
                (Gen.list_size (Gen.int_bound 5) tricky_text_gen))
             (fun ids -> Gen.flatten_list (List.map entry_gen ids))))

(* @verifies packs#give-requests=v1
   For generated runners, settings, report names, roots, and test entries
   with texts that need escapes, characters outside the Basic Multilingual
   Plane, and labels out of order, a request that differs from the canonical
   byte sequence of the request object fails the comparison. *)
let requests_follow_the_term =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:2000
       ~name:"a request is the canonical byte sequence of the request object"
       ~print:Yojson.Basic.to_string request_input_gen (fun input ->
         match request_of input with
         | Ok bytes -> String.equal bytes (Adapter_reference.request input)
         | Error _ -> false))

let repeated_id_gives_no_request () =
  let entry id =
    entry_of
      (`Assoc
         [
           ("eline", `Int 1);
           ("id", `String id);
           ("labels", `List []);
           ("line", `Int 1);
           ("names", `List []);
           ("path", `String "a.ts");
           ("suite", `Bool false);
         ])
  in
  let settings = settings_of (`Assoc []) in
  match
    Request.bind ~runner:(runner_of "x") ~settings ~report:(text_of "r")
      ~root:(text_of "/")
      [ entry "b"; entry "a"; entry "b"; entry "a" ]
  with
  | Error (Request.Repeated_id id) ->
      Alcotest.(check string) "the id" "a" (text id)
  | Ok _ -> Alcotest.fail "two entries with one id gave a request"

let lines_out_of_range () =
  let path =
    match Sinter_paths.Path.of_text (text_of "a.ts") with
    | Ok path -> path
    | Error _ -> Alcotest.fail "not a valid path"
  in
  let make line eline =
    Test_entry.make ~id:(text_of "t") ~path ~line ~eline
      ~kind:Test_entry.Test_case ~names:[] ~labels:[]
  in
  List.iter
    (fun (line, eline, expected) ->
      match (make line eline, expected) with
      | Ok _, None -> ()
      | Error (Test_entry.Line_out_of_range n), Some m when n = m -> ()
      | _ -> Alcotest.failf "the lines %d and %d" line eline)
    [
      (0, 0, None);
      (9_007_199_254_740_991, 9_007_199_254_740_991, None);
      (-1, 1, Some (-1));
      (1, -1, Some (-1));
      (9_007_199_254_740_992, 1, Some 9_007_199_254_740_992);
      (1, 9_007_199_254_740_992, Some 9_007_199_254_740_992);
      (-1, 9_007_199_254_740_992, Some (-1));
      (max_int, min_int, Some max_int);
    ]

let labels_are_a_set_in_code_point_order () =
  let path =
    match Sinter_paths.Path.of_text (text_of "a.ts") with
    | Ok path -> path
    | Error _ -> Alcotest.fail "not a valid path"
  in
  match
    Test_entry.make ~id:(text_of "t") ~path ~line:1 ~eline:2
      ~kind:Test_entry.Test_suite
      ~names:[ [ Test_entry.Text_piece (text_of "a") ] ]
      ~labels:
        (List.map text_of
           [ "\xf0\x9f\x98\x80"; "b"; "\xee\x80\x80"; "B"; "b"; "a" ])
  with
  | Ok entry ->
      Alcotest.(check (list string))
        "the labels"
        [ "B"; "a"; "b"; "\xee\x80\x80"; "\xf0\x9f\x98\x80" ]
        (List.map text entry.labels);
      Alcotest.(check int) "the first line" 1 entry.line;
      Alcotest.(check int) "the last line" 2 entry.eline;
      Alcotest.(check bool)
        "a test suite" true
        (entry.kind = Test_entry.Test_suite)
  | Error _ -> Alcotest.fail "no test entry"

let runner_of_descriptor settings =
  let bytes =
    Printf.sprintf
      "sinter-spec = \"1.0\"\n\
       name = \"x\"\n\
       version = \"0.1.0\"\n\
       license = \"MIT\"\n\
       name-separator = \".\"\n\
       [comments]\n\
       [[grammar]]\n\
       name = \"x\"\n\
       sha256 = \"%s\"\n\
       license = \"MIT\"\n\
       names = []\n\
       [runner.vitest]\n\
       match = {}\n\
       settings = %s\n"
      (String.make 64 '0') settings
  in
  match D.read bytes with
  | Ok descriptor -> (
      match D.runners descriptor with
      | [ runner ] -> runner
      | _ -> Alcotest.fail "not one runner")
  | Error _ -> Alcotest.failf "not a valid descriptor: %s" bytes

module T = Sinter_data_forms_toml.Data_forms_toml

let binding_value_gen =
  Gen.oneof
    [
      Gen.map (fun text -> T.String text) (pick [ "v"; ""; "\xc3\xa9"; "\xff" ]);
      Gen.map (fun flag -> T.Boolean flag) Gen.bool;
      Gen.map
        (fun items -> T.Array (List.map (fun text -> T.String text) items))
        (Gen.list_size (Gen.int_bound 2) (pick [ "x"; "\xff" ]));
      Gen.return (T.Array [ T.Boolean true ]);
      Gen.return (T.Integer 1L);
      Gen.return (T.Table []);
    ]

let binding_gen =
  Gen.list_size (Gen.int_bound 4)
    (Gen.pair (pick [ "s"; "b"; "l"; "other"; "\xff" ]) binding_value_gen)

let defaults =
  [ ("b", D.Boolean false); ("l", D.Strings [ "d" ]); ("s", D.String "d") ]

let type_fits (default : D.setting_value) (value : T.value) =
  match (default, value) with
  | D.String _, T.String _ | D.Boolean _, T.Boolean _ -> true
  | D.Strings _, T.Array items ->
      List.for_all (function T.String _ -> true | _ -> false) items
  | _ -> false

let texts_of_value = function
  | T.String text -> [ text ]
  | T.Array items ->
      List.concat_map (function T.String text -> [ text ] | _ -> []) items
  | _ -> []

let binding_reference binding =
  let rec check seen = function
    | [] -> None
    | (name, value) :: rest -> (
        match List.assoc_opt name defaults with
        | None -> Some (Setting_values.Not_a_setting name)
        | Some default ->
            if List.mem name seen then Some (Setting_values.Repeated_name name)
            else if not (type_fits default value) then
              Some (Setting_values.Wrong_type name)
            else if
              not (List.for_all String.is_valid_utf_8 (texts_of_value value))
            then Some (Setting_values.Not_utf_8 name)
            else check (name :: seen) rest)
  in
  match check [] binding with
  | Some error -> Error error
  | None ->
      Ok
        (List.map
           (fun (name, default) ->
             match List.assoc_opt name binding with
             | Some (T.String text) -> (name, D.String text)
             | Some (T.Boolean flag) -> (name, D.Boolean flag)
             | Some (T.Array items) ->
                 ( name,
                   D.Strings
                     (List.concat_map
                        (function T.String text -> [ text ] | _ -> [])
                        items) )
             | Some _ | None -> (name, default))
           defaults)

let print_binding binding =
  String.concat "; "
    (List.map
       (fun (name, value) ->
         String.escaped name ^ " = "
         ^ Yojson.Basic.to_string (Descriptor_reference.form_of_toml value))
       binding)

let bindings_follow_the_term =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:2000
       ~name:
         "a binding gives the value of each runner setting when it is valid, \
          and the first pair that breaks a rule when it is not"
       ~print:print_binding binding_gen (fun binding ->
         let runner =
           runner_of_descriptor "{ s = \"d\", b = false, l = [\"d\"] }"
         in
         match
           (Setting_values.bind runner binding, binding_reference binding)
         with
         | Ok values, Ok expected -> Setting_values.to_list values = expected
         | Error error, Error expected -> error = expected
         | _ -> false))

let of_list_follows_the_names () =
  (match
     Setting_values.of_list
       [
         ("\xf0\x9f\x98\x80", D.String "b");
         ("\xee\x80\x80", D.Boolean true);
         ("Z", D.Strings []);
       ]
   with
  | Ok values ->
      Alcotest.(check (list string))
        "the names in code point order"
        [ "Z"; "\xee\x80\x80"; "\xf0\x9f\x98\x80" ]
        (List.map fst (Setting_values.to_list values));
      Alcotest.(check string)
        "the JSON object"
        "{\"Z\":[],\"\xf0\x9f\x98\x80\":\"b\",\"\xee\x80\x80\":true}"
        (Sinter_json_lines.Json.canonical_byte_sequence
           (Setting_values.to_json values))
  | Error _ -> Alcotest.fail "no values");
  List.iter
    (fun (values, expected) ->
      match Setting_values.of_list values with
      | Error error when error = expected -> ()
      | _ -> Alcotest.fail "a list that gives no values gave values")
    [
      ( [ ("a", D.String "x"); ("a", D.Boolean true) ],
        Setting_values.Repeated_name "a" );
      ([ ("\xff", D.String "x") ], Setting_values.Not_utf_8 "\xff");
      ([ ("a", D.String "\xff") ], Setting_values.Not_utf_8 "a");
      ([ ("a", D.Strings [ "x"; "\xc3" ]) ], Setting_values.Not_utf_8 "a");
      ( [ ("a", D.String "\xff"); ("a", D.String "x") ],
        Setting_values.Not_utf_8 "a" );
    ]

let ids_gen =
  Gen.map distinct
    (Gen.list_size (Gen.int_bound 3)
       (pick [ "t1"; "t2"; "\xee\x80\x80"; "\xf0\x9f\x98\x80" ]))

let number_gen =
  Gen.oneof_weighted
    [
      (8, Gen.map (fun n -> V.Number (string_of_int n)) (Gen.int_range (-1) 3));
      ( 1,
        pick
          [
            V.Number "-0";
            V.Number "1.0";
            V.Number "1e3";
            V.Number "9007199254740992";
            V.Number "9007199254740991";
          ] );
    ]

let str text = V.String (V.Text text)

let scalar_gen =
  Gen.oneof
    [
      Gen.map str tricky_text_gen;
      number_gen;
      Gen.map (fun flag -> V.Bool flag) Gen.bool;
      Gen.return V.Null;
    ]

let field key value_gen weight =
  Gen.oneof_weighted
    [
      (weight, Gen.map (fun value -> [ (V.Text key, value) ]) value_gen);
      (1, Gen.return []);
    ]

let result_object_gen =
  Gen.map
    (fun parts -> V.Object (List.concat parts))
    (Gen.flatten_list
       [
         field "name"
           (Gen.oneof_weighted
              [ (8, Gen.map str tricky_text_gen); (1, scalar_gen) ])
           12;
         field "status"
           (Gen.oneof_weighted
              [
                (8, Gen.map str (pick [ "pass"; "fail"; "error"; "skip" ]));
                (1, Gen.map str (pick [ "passed"; "Pass"; "" ]));
                (1, scalar_gen);
              ])
           12;
         field "file"
           (Gen.oneof_weighted
              [ (8, Gen.map str tricky_text_gen); (1, scalar_gen) ])
           1;
         field "line"
           (Gen.oneof_weighted [ (8, number_gen); (1, scalar_gen) ])
           1;
         field "ms" (Gen.oneof_weighted [ (8, number_gen); (1, scalar_gen) ]) 1;
         Gen.oneof_weighted
           [ (12, Gen.return []); (1, Gen.return [ (V.Text "id", str "x") ]) ];
       ])

let binding_object_gen ids =
  Gen.map
    (fun parts -> V.Object (List.concat parts))
    (Gen.flatten_list
       [
         field "result"
           (Gen.oneof_weighted [ (8, number_gen); (1, scalar_gen) ])
           12;
         field "test"
           (Gen.oneof_weighted
              [
                (8, Gen.map str (pick (if ids = [] then [ "t1" ] else ids)));
                (1, Gen.map str (pick [ "t9"; "" ]));
                (1, scalar_gen);
              ])
           12;
         field "reason"
           (Gen.oneof_weighted
              [
                (8, Gen.map str (pick [ "r"; "a\rb"; ""; "\xe2\x80\xa8" ]));
                (1, Gen.map str (pick [ "a\nb"; "\n" ]));
                (1, scalar_gen);
              ])
           12;
         Gen.oneof_weighted
           [
             (12, Gen.return []);
             (1, Gen.return [ (V.Text "extra", V.Bool true) ]);
           ];
       ])

let array_or gen weight =
  Gen.oneof_weighted
    [
      ( weight,
        Gen.map
          (fun items -> V.Array items)
          (Gen.list_size (Gen.int_bound 4) gen) );
      (1, scalar_gen);
    ]

let bind_value_gen ids =
  Gen.map
    (fun parts -> V.Object (List.concat parts))
    (Gen.flatten_list
       [
         field "results" (array_or result_object_gen 12) 20;
         field "bindings" (array_or (binding_object_gen ids) 12) 20;
         field "warnings"
           (array_or
              (Gen.oneof_weighted
                 [ (8, Gen.map str tricky_text_gen); (1, scalar_gen) ])
              12)
           20;
         Gen.oneof_weighted
           [
             (20, Gen.return []); (1, Gen.return [ (V.Text "x", V.Number "1") ]);
           ];
       ])

let clean_bind_gen ids =
  Gen.bind
    (Gen.list_size (Gen.int_bound 4)
       (Gen.map4
          (fun name status file (line, ms) ->
            V.Object
              ([ (V.Text "name", str name); (V.Text "status", str status) ]
              @ (match file with
                | Some file -> [ (V.Text "file", str file) ]
                | None -> [])
              @ (match line with
                | Some line ->
                    [ (V.Text "line", V.Number (string_of_int line)) ]
                | None -> [])
              @
              match ms with
              | Some ms -> [ (V.Text "ms", V.Number (string_of_int ms)) ]
              | None -> []))
          tricky_text_gen
          (pick [ "pass"; "fail"; "error"; "skip" ])
          (Gen.option tricky_text_gen)
          (Gen.pair
             (Gen.option (Gen.int_range 1 9))
             (Gen.option (Gen.int_range 0 9)))))
    (fun results ->
      let count = List.length results in
      Gen.map2
        (fun pairs warnings ->
          V.Object
            [
              (V.Text "results", V.Array results);
              ( V.Text "bindings",
                V.Array
                  (List.map
                     (fun ((result, test), reason) ->
                       V.Object
                         [
                           (V.Text "result", V.Number (string_of_int result));
                           (V.Text "test", str test);
                           (V.Text "reason", str reason);
                         ])
                     pairs) );
              (V.Text "warnings", V.Array (List.map str warnings));
            ])
        (if count = 0 || ids = [] then Gen.return []
         else
           Gen.map
             (fun pairs ->
               List.fold_left
                 (fun kept ((pair, _) as binding) ->
                   if List.mem_assoc pair kept then kept else kept @ [ binding ])
                 [] pairs)
             (Gen.list_size (Gen.int_bound 4)
                (Gen.pair
                   (Gen.pair (Gen.int_bound (count - 1)) (pick ids))
                   (pick [ "r"; "a\rb"; ""; "\xe2\x80\xa8" ]))))
        (Gen.list_size (Gen.int_bound 2) tricky_text_gen))

let other_value_gen =
  Gen.oneof_weighted
    [
      ( 8,
        Gen.map
          (fun flag -> V.Object [ (V.Text "recognised", V.Bool flag) ])
          Gen.bool );
      ( 1,
        Gen.map
          (fun value -> V.Object [ (V.Text "error", value) ])
          (Gen.oneof [ Gen.map str tricky_text_gen; scalar_gen ]) );
      ( 1,
        Gen.map
          (fun value -> V.Object [ (V.Text "recognised", value) ])
          scalar_gen );
      ( 1,
        Gen.return
          (V.Object
             [ (V.Text "recognised", V.Bool true); (V.Text "x", V.Number "1") ])
      );
      ( 1,
        Gen.return
          (V.Object
             [ (V.Text "error", str "x"); (V.Text "recognised", V.Bool true) ])
      );
      ( 1,
        Gen.return
          (V.Object
             [
               (V.Text "recognised", V.Bool true);
               (V.Text "recognised", V.Bool true);
             ]) );
      ( 1,
        Gen.return
          (V.Object [ (V.Text "error", str "x"); (V.Text "error", str "x") ]) );
      (1, Gen.return (V.Array []));
      (1, scalar_gen);
    ]

let spelled thing =
  Gen.oneof_weighted
    [
      ( 3,
        Gen.return
          (match V.canonical thing with
          | Some bytes -> bytes
          | None -> V.print thing) );
      (3, V.spelling_gen thing);
      (1, Gen.bind (V.spelling_gen thing) V.corrupt_gen);
      (1, Gen.map (fun bytes -> "\xef\xbb\xbf" ^ bytes) (V.spelling_gen thing));
    ]

let response_gen =
  Gen.bind ids_gen (fun ids ->
      Gen.bind Gen.bool (fun recognise ->
          let function_ =
            if recognise then Adapter_reference.Recognise
            else Adapter_reference.Bind ids
          in
          Gen.map
            (fun bytes -> (function_, bytes))
            (Gen.bind
               (Gen.oneof_weighted
                  [
                    (3, bind_value_gen ids);
                    (2, clean_bind_gen ids);
                    (2, other_value_gen);
                  ])
               spelled)))

let print_response (function_, bytes) =
  (match function_ with
    | Adapter_reference.Recognise -> "recognise"
    | Adapter_reference.Bind ids -> "bind with " ^ String.concat ", " ids)
  ^ ": " ^ String.escaped bytes

(* @verifies packs#{
       give-call-results=v1, give-call-values=v1, omit-call-values=v1,
       omit-adapter-error-texts=v1,
   }
   For generated responses of recognise and bind, written with spaces,
   escapes, and members in any order, with a byte changed or a byte order
   mark in front, a result, a test result, a binding object, a warning, or an
   error text that differs from a direct reading of the term call-result fails
   the comparison, as does a value given with a result that does not carry
   it. *)
let responses_follow_the_term =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:5000
       ~name:
         "a response gives the result and the values of the term call-result"
       ~print:print_response response_gen (fun (function_, bytes) ->
         let result, values = response_answer function_ bytes in
         let expected_result, expected_values =
           Adapter_reference.response function_ bytes
         in
         String.equal result expected_result
         && Vectors.equal_json values expected_values))

let bound_share =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1 ~name:"the generated responses hold each result"
       (Gen.return ()) (fun () ->
         let responses =
           Gen.generate ~n:2000 ~rand:(Random.State.make [| 11 |]) response_gen
         in
         let results =
           List.map
             (fun (function_, bytes) ->
               fst (Adapter_reference.response function_ bytes))
             responses
         in
         let count result =
           List.length (List.filter (String.equal result) results)
         in
         List.for_all
           (fun result ->
             count result >= 20
             || QCheck2.Test.fail_reportf "%d %s" (count result) result)
           [ "recognised"; "not recognised"; "failed"; "bound" ]))

let deep_response depth =
  "{\"results\":[],\"bindings\":[],\"warnings\":[" ^ String.make depth '['
  ^ String.make depth ']' ^ "]}"

let deep_responses_need_no_deep_stack () =
  let bind, recognise =
    Test_file_read.with_small_stack (fun () ->
        let bytes = deep_response 100_000 in
        ( Response.bind ~ids:[] bytes,
          Response.recognise
            ("{\"error\":" ^ String.make 100_000 '[' ^ String.make 100_000 ']'
           ^ "}") ))
  in
  Alcotest.(check bool) "the result of bind" true (bind = Bind_failed None);
  Alcotest.(check bool)
    "the result of recognise" true
    (recognise = Recognition_failed None)

let wide_response count =
  let results =
    String.concat ","
      (List.init count (fun index ->
           Printf.sprintf "{\"name\":\"n%d\",\"status\":\"pass\",\"line\":%d}"
             index (index + 1)))
  in
  let bindings =
    String.concat ","
      (List.init count (fun index ->
           Printf.sprintf "{\"result\":%d,\"test\":\"t%d\",\"reason\":\"r\"}"
             index
             (count - 1 - index)))
  in
  ( List.init count (fun index -> text_of (Printf.sprintf "t%d" index)),
    "{\"results\":[" ^ results ^ "],\"bindings\":[" ^ bindings
    ^ "],\"warnings\":[]}" )

let best_time action =
  List.fold_left
    (fun best _ ->
      let start = Unix.gettimeofday () in
      ignore (Sys.opaque_identity (action ()));
      Float.min best (Unix.gettimeofday () -. start))
    infinity [ 1; 2; 3 ]

let bind_time_grows_with_n_log_n () =
  let small_ids, small = wide_response 5_000 in
  let large_ids, large = wide_response 50_000 in
  let check_bound ids bytes =
    match Response.bind ~ids bytes with
    | Bound { results; bindings; _ } ->
        List.length results = List.length bindings
    | Bind_failed _ -> false
  in
  Alcotest.(check bool)
    "the small response binds" true
    (check_bound small_ids small);
  Alcotest.(check bool)
    "the large response binds" true
    (check_bound large_ids large);
  let small_time = best_time (fun () -> Response.bind ~ids:small_ids small) in
  let large_time = best_time (fun () -> Response.bind ~ids:large_ids large) in
  let ratio = large_time /. Float.max small_time 1e-6 in
  if ratio > 40. then
    Alcotest.failf
      "ten times the input took %.1f times as long (%.4f s and %.4f s)" ratio
      small_time large_time

let many_bindings_need_no_deep_stack () =
  let ids, bytes = wide_response 20_000 in
  match
    Test_file_read.with_small_stack (fun () -> Response.bind ~ids bytes)
  with
  | Bound { bindings; _ } ->
      Alcotest.(check int) "the binding objects" 20_000 (List.length bindings)
  | Bind_failed _ -> Alcotest.fail "the response did not bind"

let tests =
  Vectors.tests "packs.adapters" [ request_vectors; response_vectors ]
  @ [
      requests_follow_the_term;
      Alcotest.test_case "two test entries with one id give no request" `Quick
        repeated_id_gives_no_request;
      Alcotest.test_case "a line out of range gives no test entry" `Quick
        lines_out_of_range;
      Alcotest.test_case "the test labels are a set in code point order" `Quick
        labels_are_a_set_in_code_point_order;
      bindings_follow_the_term;
      Alcotest.test_case "a list of setting values follows its names" `Quick
        of_list_follows_the_names;
      responses_follow_the_term;
      bound_share;
      Alcotest.test_case "a deep response needs no deep stack" `Quick
        deep_responses_need_no_deep_stack;
      Alcotest.test_case "many binding objects need no deep stack" `Quick
        many_bindings_need_no_deep_stack;
      Alcotest.test_case "the time of bind grows with n log n" `Quick
        bind_time_grows_with_n_log_n;
    ]
