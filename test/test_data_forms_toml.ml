(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module D = Sinter_data_forms_toml.Data_forms_toml
module M = Toml_model
module V = Vector_json

let rec model (value : D.value) : M.value =
  match value with
  | D.String text -> M.String text
  | D.Integer number -> M.Integer number
  | D.Float number -> M.Float number
  | D.Boolean flag -> M.Boolean flag
  | D.Local_date date -> M.Local_date (model_date date)
  | D.Local_time time -> M.Local_time (model_time time)
  | D.Local_date_time (date, time) ->
      M.Local_date_time (model_date date, model_time time)
  | D.Offset_date_time (date, time, offset) ->
      M.Offset_date_time (model_date date, model_time time, model_offset offset)
  | D.Array values -> M.Array (List.map model values)
  | D.Table table -> M.Table (model_table table)

and model_table table = List.map (fun (key, value) -> (key, model value)) table

and model_date (date : Sinter_toml.date) =
  { M.year = date.year; month = date.month; day = date.day }

and model_time (time : Sinter_toml.time) =
  {
    M.hour = time.hour;
    minute = time.minute;
    second = time.second;
    nanosecond = time.nanosecond;
  }

and model_offset = function
  | Sinter_toml.Minutes minutes -> M.Minutes minutes
  | Sinter_toml.Unknown_local -> M.Unknown_local

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let toml_set = Vectors.read "data-forms.toml"

let input_bytes (vector : Vectors.vector) =
  match vector.input with
  | `String hex -> V.of_hex hex
  | other ->
      Alcotest.failf "not a JSON string: %s" (Yojson.Basic.to_string other)

let position_form (position : Sinter_text.Lines.position) =
  `Assoc [ ("column", `Int position.column); ("line", `Int position.line) ]

let location_form location =
  `List
    (List.map
       (function D.Text text -> `String text | D.Index index -> `Int index)
       (D.steps location))

let subject_members = function
  | D.Toml_value -> [ ("of", `String "toml-value") ]
  | D.Key -> [ ("of", `String "key") ]
  | D.Toml_key index -> [ ("index", `Int index); ("of", `String "toml-key") ]

let span_form (subject, location, (span : D.span)) : Yojson.Basic.t =
  `Assoc
    (subject_members subject
    @ [
        ("location", location_form location);
        ("start", position_form span.start);
        ("end", position_form span.end_);
      ])

let span_forms (document : D.document) = List.map span_form document.spans

let member name (json : Yojson.Basic.t) =
  match json with `Assoc members -> List.assoc_opt name members | _ -> None

let same_subject (wanted : Yojson.Basic.t) (span : Yojson.Basic.t) =
  List.for_all
    (fun name ->
      Option.equal Vectors.equal_json (member name wanted) (member name span))
    [ "of"; "location"; "index" ]

let valid values = `Assoc [ ("result", `String "valid"); ("values", values) ]
let invalid = `Assoc [ ("result", `String "invalid"); ("values", `Assoc []) ]
let no_result = `Assoc [ ("no-result", `Bool true) ]

let give_root_table (vector : Vectors.vector) =
  match D.read (input_bytes vector) with
  | D.No_result -> no_result
  | D.Invalid -> invalid
  | D.Valid document ->
      valid
        (`Assoc
           [ ("root-table", M.table_form (model_table document.root_table)) ])

(* @verifies data-forms#toml[give-root-table][*]=v1
   The test gives the bytes of each vector to the adapter and fails unless it
   gives "valid" and a root table whose form is the form of the vector. *)
let give_root_table_vectors =
  Vectors.group toml_set ~name:"give-root-table" ~rev:"v1" give_root_table

(* @verifies data-forms#toml[reject-byte-sequence][*]=v1
   The test fails when the adapter gives "valid" and a table for a byte
   sequence that the vector calls invalid. *)
let reject_byte_sequence_vectors =
  Vectors.group toml_set ~name:"reject-byte-sequence" ~rev:"v1" give_root_table

let give_span (vector : Vectors.vector) =
  match (D.read (input_bytes vector), vector.values) with
  | D.No_result, _ -> no_result
  | D.Invalid, _ -> invalid
  | D.Valid document, Some wanted -> (
      match List.filter (same_subject wanted) (span_forms document) with
      | [ span ] -> valid span
      | spans -> valid (`List spans))
  | D.Valid _, None -> Alcotest.fail "a vector of give-span has no values"

(* @verifies data-forms#toml[give-span][*]=v1
   The test fails when the adapter gives, for the subject and the location
   of the vector, a span whose start or end differs from the vector, or a
   result other than "valid". *)
let give_span_vectors =
  Vectors.group toml_set ~name:"give-span" ~rev:"v1" give_span

let give_omit_span (vector : Vectors.vector) =
  match D.read (input_bytes vector) with
  | D.No_result -> no_result
  | D.Invalid -> invalid
  | D.Valid document -> (
      let location =
        match Option.bind vector.values (member "no-span-at") with
        | Some location -> location
        | None -> Alcotest.fail "a vector of omit-span has no no-span-at"
      in
      let wanted =
        `Assoc [ ("location", location); ("of", `String "toml-value") ]
      in
      match List.filter (same_subject wanted) (span_forms document) with
      | [] -> valid (`Assoc [ ("no-span-at", location) ])
      | spans -> valid (`Assoc [ ("spans", `List spans) ]))

(* @verifies data-forms#toml[omit-span][*]=v1
   The test fails when the adapter gives a span of a TOML value at the
   location of the vector, which has no span. *)
let omit_span_vectors =
  Vectors.group toml_set ~name:"omit-span" ~rev:"v1" give_omit_span

let adapter bytes =
  match D.read bytes with
  | D.Valid document -> Some (M.Table (model_table document.root_table))
  | D.Invalid | D.No_result -> None

(* @verifies data-forms#{read-toml=v1, give-only-root-tables=v1}
   The test gives byte sequences at the edges of the reading rules and of
   the syntax of TOML 1.1.0 that no vector holds, and fails when the adapter
   gives "invalid" for a TOML document or "valid" for another byte sequence,
   or a root table that differs from the root table of the document. *)
let gives_each_edge_case =
  Alcotest.test_case
    "read gives the result and the root table of each edge case" `Quick
    (fun () ->
      match
        List.filter_map
          (Test_toml_reader.case_fault adapter)
          Test_toml_reader.value_cases
      with
      | [] -> ()
      | faults -> Alcotest.fail (String.concat "\n" faults))

let toml_test_reader bytes =
  match D.read bytes with
  | D.Valid document -> Ok (M.Table (model_table document.root_table))
  | D.Invalid -> Error "invalid"
  | D.No_result -> Ok (M.String "<no result>")

(* @verifies data-forms#{read-toml=v1, give-only-root-tables=v1}
   The test fails when the adapter gives "invalid" for a valid case of the
   official TOML test suite, or a root table other than the value of its
   JSON file. *)
let every_valid_case_of_toml_test_is_valid =
  Alcotest.test_case
    "each valid case of toml-test is valid, with its root table" `Quick
    (fun () ->
      Test_toml_reader.check_cases ~count:214
        (Test_toml_reader.cases "valid/")
        (Test_toml_reader.valid_case_fault toml_test_reader)
        ())

(* @verifies data-forms#read-toml=v1
   The test fails when the adapter gives "valid" for an invalid case of the
   official TOML test suite. *)
let every_invalid_case_of_toml_test_is_invalid =
  Alcotest.test_case "each invalid case of toml-test is invalid" `Quick
    (fun () ->
      Test_toml_reader.check_cases ~count:467
        (Test_toml_reader.cases "invalid/")
        (Test_toml_reader.invalid_case_fault toml_test_reader)
        ())

let location_json steps : Yojson.Basic.t = `List steps

let expected_spans (document : M.document) =
  let position offset =
    let line, column = M.position document.bytes offset in
    `Assoc [ ("column", `Int column); ("line", `Int line) ]
  in
  let pair members location (span : M.span) : Yojson.Basic.t =
    `Assoc
      (members
      @ [
          ("location", location_json location);
          ("start", position span.start_byte);
          ("end", position span.end_byte);
        ])
  in
  List.map
    (fun (value : M.located) ->
      pair [ ("of", `String "toml-value") ] value.location value.span)
    document.values
  @ List.concat_map
      (fun (key : M.located_key) ->
        pair [ ("of", `String "key") ] key.key_location key.key_span
        :: List.mapi
             (fun index part ->
               pair
                 [ ("index", `Int (index + 1)); ("of", `String "toml-key") ]
                 key.key_location part)
             key.parts)
      document.keys

let canonical json = Yojson.Basic.to_string (Yojson.Basic.sort json)

(* @verifies data-forms#{read-toml=v1, give-only-root-tables=v1}
   The test writes generated root tables as TOML documents in many syntaxes
   and fails when the adapter gives "invalid" for one, or a root table that
   is not equal to the root table that was written. *)
let reads_generated_documents =
  property ~count:1000
    ~name:"read gives valid and the root table of each generated document"
    ~print:M.print_document M.document_gen (fun document ->
      match D.read document.bytes with
      | D.Valid got ->
          let got = M.Table (model_table got.root_table) in
          M.equal got (M.Table document.root)
          || QCheck2.Test.fail_reportf "gives %s" (M.print got)
      | D.Invalid -> QCheck2.Test.fail_reportf "gives invalid"
      | D.No_result -> QCheck2.Test.fail_reportf "gives no result")

(* @verifies data-forms#give-only-toml-spans=v1
   The test computes the span pairs of each generated document from the
   bytes that the writer wrote for each value and each key, and fails when
   the adapter gives a span pair that is not one of them, or a line number
   or a column that is not the one of its start or its end. *)
let gives_only_span_pairs =
  property ~count:1000
    ~name:"read gives each span pair of a generated document, and no other"
    ~print:M.print_document M.document_gen (fun document ->
      match D.read document.bytes with
      | D.Valid got ->
          let got = List.sort compare (List.map canonical (span_forms got))
          and expected =
            List.sort compare (List.map canonical (expected_spans document))
          in
          got = expected
          || QCheck2.Test.fail_reportf "gives\n%s\nexpected\n%s"
               (String.concat "\n" got)
               (String.concat "\n" expected)
      | D.Invalid -> QCheck2.Test.fail_reportf "gives invalid"
      | D.No_result -> QCheck2.Test.fail_reportf "gives no result")

let gives_a_result_for_outside_data =
  property ~count:3000
    ~name:"read gives valid or invalid for corrupted documents and any bytes"
    ~print:(Printf.sprintf "%S")
    (QCheck2.Gen.oneof
       [ Test_toml_reader.corrupted_gen; M.noise_gen; QCheck2.Gen.string ])
    (fun bytes ->
      match D.read bytes with
      | D.Valid _ | D.Invalid -> true
      | D.No_result -> false)

(* @verifies data-forms#{read-toml=v1, give-only-root-tables=v1}
   The test fails when the adapter gives "invalid", or a root table of
   another depth, for documents nested far deeper than any vector. *)
let reads_deep_nesting_with_a_small_stack () =
  let depth_of_arrays = function
    | D.Valid { root_table = [ ("a", value) ]; _ } ->
        let rec go depth = function
          | D.Array [] -> Some depth
          | D.Array [ inner ] -> go (depth + 1) inner
          | _ -> None
        in
        go 1 value
    | _ -> None
  in
  let valid bytes =
    match D.read bytes with
    | D.Valid _ -> true
    | D.Invalid | D.No_result -> false
  in
  let arrays, others =
    Small_stack.run (fun () ->
        ( depth_of_arrays (D.read (M.nested_arrays 1_000_000)),
          List.map valid
            [
              M.nested_inline_tables 300_000;
              M.dotted_key 200_000;
              M.dotted_header 200_000;
            ] ))
  in
  Alcotest.(check (option int))
    "the depth of the arrays" (Some 1_000_000) arrays;
  Alcotest.(check (list bool)) "the other documents" [ true; true; true ] others

let rec tables_are_sorted = function
  | D.Table pairs ->
      let texts = List.map fst pairs in
      List.sort_uniq String.compare texts = texts
      && List.for_all (fun (_, value) -> tables_are_sorted value) pairs
  | D.Array values -> List.for_all tables_are_sorted values
  | _ -> true

let gives_tables_in_the_order_of_their_texts =
  property ~count:500
    ~name:
      "read gives the pairs of each table in the order of the bytes of their \
       texts, each text once" ~print:M.print_document M.document_gen
    (fun document ->
      match D.read document.bytes with
      | D.Valid got -> tables_are_sorted (D.Table got.root_table)
      | D.Invalid | D.No_result -> QCheck2.Test.fail_reportf "gives no table")

let limits_gen =
  QCheck2.Gen.(pair M.document_gen (pair (int_range 0 5) (int_range 0 5)))

(* @verifies data-forms#read-toml=v1
   The test reads generated TOML documents with the limits of the reader and
   fails when the adapter gives "invalid" for one, or gives a result other
   than the result without limits. *)
let gives_no_result_past_a_limit =
  property ~count:1000
    ~name:
      "read with limits gives valid as without them, or no result when a depth \
       or a key passes them, and never invalid"
    ~print:Test_toml_reader.print_limits limits_gen
    (fun ((document : M.document), (max_depth, max_key_parts)) ->
      let past =
        document.depth > max_depth || document.key_parts > max_key_parts
      in
      match D.read ~max_depth ~max_key_parts document.bytes with
      | D.No_result -> past
      | D.Invalid -> false
      | D.Valid got -> (
          (not past)
          &&
          match D.read document.bytes with
          | D.Valid other ->
              M.equal
                (M.Table (model_table got.root_table))
                (M.Table (model_table other.root_table))
              && List.sort compare (List.map canonical (span_forms got))
                 = List.sort compare (List.map canonical (span_forms other))
          | D.Invalid | D.No_result -> false))

let gives_no_result_only_at_a_limit () =
  let outcome ?max_depth ?max_key_parts bytes =
    match D.read ?max_depth ?max_key_parts bytes with
    | D.Valid _ -> "valid"
    | D.Invalid -> "invalid"
    | D.No_result -> "no result"
  in
  Alcotest.(check (list string))
    "the outcomes"
    [ "no result"; "valid"; "no result"; "valid"; "invalid"; "no result" ]
    [
      outcome ~max_depth:1 "a = [[1]]\n";
      outcome ~max_depth:2 "a = [[1]]\n";
      outcome ~max_key_parts:1 "a.b = 1\n";
      outcome ~max_key_parts:2 "a.b = 1\n";
      outcome ~max_depth:1 "a = 1\na = [[1]]\n";
      outcome ~max_depth:1 "a = [[1]]\na = 1\n";
    ]

let vector_groups =
  [
    give_root_table_vectors;
    reject_byte_sequence_vectors;
    give_span_vectors;
    omit_span_vectors;
  ]

let tests =
  Vectors.tests "data-forms.toml" vector_groups
  @ [
      Vectors.covers "data-forms.toml" toml_set vector_groups;
      gives_each_edge_case;
      every_valid_case_of_toml_test_is_valid;
      every_invalid_case_of_toml_test_is_invalid;
      reads_generated_documents;
      gives_only_span_pairs;
      gives_a_result_for_outside_data;
      gives_tables_in_the_order_of_their_texts;
      gives_no_result_past_a_limit;
      Alcotest.test_case "read gives no result only at a limit of the reader"
        `Quick gives_no_result_only_at_a_limit;
      Alcotest.test_case
        "read gives valid for deep nesting and long keys, with a small stack"
        `Quick reads_deep_nesting_with_a_small_stack;
    ]
