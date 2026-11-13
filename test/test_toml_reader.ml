(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module T = Sinter_toml
module M = Toml_model
module Gen = QCheck2.Gen

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let rec model (value : T.value) : M.value =
  match value with
  | T.String text -> M.String text
  | T.Integer number -> M.Integer number
  | T.Float number -> M.Float number
  | T.Boolean flag -> M.Boolean flag
  | T.Local_date date -> M.Local_date (model_date date)
  | T.Local_time time -> M.Local_time (model_time time)
  | T.Local_date_time (date, time) ->
      M.Local_date_time (model_date date, model_time time)
  | T.Offset_date_time (date, time, offset) ->
      M.Offset_date_time (model_date date, model_time time, model_offset offset)
  | T.Array items ->
      M.Array (List.map (fun (item : T.item) -> model item.value) items)
  | T.Table table -> M.Table (model_table table)

and model_table table =
  List.map (fun (key, (item : T.item)) -> (key, model item.value)) table

and model_date (date : T.date) =
  { M.year = date.year; month = date.month; day = date.day }

and model_time (time : T.time) =
  {
    M.hour = time.hour;
    minute = time.minute;
    second = time.second;
    nanosecond = time.nanosecond;
  }

and model_offset = function
  | T.Minutes minutes -> M.Minutes minutes
  | T.Unknown_local -> M.Unknown_local

let failure_text = function
  | Ok _ -> "Ok"
  | Error (T.Invalid { error; offset }) ->
      let kind =
        match error with
        | T.Not_utf_8 -> "Not_utf_8"
        | T.Syntax -> "Syntax"
        | T.Integer_out_of_range -> "Integer_out_of_range"
        | T.Float_out_of_range -> "Float_out_of_range"
        | T.Date_time_out_of_range -> "Date_time_out_of_range"
        | T.Escape_not_a_character -> "Escape_not_a_character"
        | T.Duplicate_key -> "Duplicate_key"
        | T.Table_defined_twice -> "Table_defined_twice"
        | T.Not_a_table -> "Not_a_table"
        | T.Not_an_array_of_tables -> "Not_an_array_of_tables"
        | T.Inline_table_closed -> "Inline_table_closed"
        | T.Dotted_key_into_named_table -> "Dotted_key_into_named_table"
      in
      Printf.sprintf "%s at %d" kind offset
  | Error (T.Limit_reached { limit; offset }) ->
      Printf.sprintf "%s at %d"
        (match limit with T.Depth -> "Depth" | T.Key_parts -> "Key_parts")
        offset

let suite = "fixtures/toml-test"

let read_fixture path =
  In_channel.with_open_bin (Filename.concat suite path) In_channel.input_all

let toml_1_1 =
  lazy
    (read_fixture "files-toml-1.1.0"
    |> String.split_on_char '\n'
    |> List.filter (fun line -> Filename.check_suffix line ".toml"))

let cases prefix =
  List.filter (String.starts_with ~prefix) (Lazy.force toml_1_1)

let expected_value path =
  M.of_toml_test
    (Yojson.Basic.from_string
       (read_fixture (Filename.chop_suffix path ".toml" ^ ".json")))

let valid_case_fault read path =
  match (read (read_fixture path), expected_value path) with
  | _, None -> Some "the JSON file is not of the form of toml-test"
  | Error why, Some _ -> Some ("rejected: " ^ why)
  | Ok got, Some expected ->
      if M.equal got expected then None else Some ("gives " ^ M.print got)

let invalid_case_fault read path =
  match read (read_fixture path) with
  | Ok got -> Some ("accepted: " ^ M.print got)
  | Error _ -> None

let check_cases ~count paths fault () =
  Alcotest.(check int) "the number of cases" count (List.length paths);
  match
    List.filter_map
      (fun path -> Option.map (fun why -> path ^ ": " ^ why) (fault path))
      paths
  with
  | [] -> ()
  | faults -> Alcotest.fail (String.concat "\n" faults)

let reader bytes =
  match T.read bytes with
  | Ok table -> Ok (M.Table (model_table table))
  | Error (T.Invalid _) as failure -> Error (failure_text failure)
  | Error (T.Limit_reached _) as failure ->
      Ok (M.String ("<" ^ failure_text failure ^ ">"))

let every_valid_case_gives_its_value =
  Alcotest.test_case "each valid case of toml-test gives the value of its JSON"
    `Quick (fun () ->
      check_cases ~count:214 (cases "valid/") (valid_case_fault reader) ())

let every_invalid_case_is_invalid =
  Alcotest.test_case "each invalid case of toml-test gives Invalid" `Quick
    (fun () ->
      check_cases ~count:467 (cases "invalid/") (invalid_case_fault reader) ())

let halfway_low = "1.00000000000000011102230246251565404236316680908203125"

let below halfway =
  String.sub halfway 0 (String.length halfway - 1) ^ "4" ^ String.make 1000 '9'

let value_cases : (string * M.value option) list =
  [
    ("a = 99999999999999999999999999999999", None);
    ("a = " ^ below halfway_low, Some (M.Float 1.));
    ("a = 1 #9-", Some (M.Integer 1L));
    ("a = 1#99-", Some (M.Integer 1L));
    ("a = 12#9-", Some (M.Integer 12L));
    ("a = 0#:x", Some (M.Integer 0L));
    ("a = 0\nx9-c-9 = 1", Some (M.Integer 0L));
  ]

let value_of_a = function
  | M.Table pairs -> List.assoc_opt "a" pairs
  | _ -> None

let case_fault read (input, expected) =
  let got = read (input ^ "\n") in
  let ok =
    match (got, expected) with
    | None, None -> true
    | Some table, Some value -> (
        match value_of_a table with
        | Some got -> M.equal got value
        | None -> false)
    | _ -> false
  in
  if ok then None
  else
    Some
      (Printf.sprintf "%S: expected %s, got %s" input
         (Option.fold ~none:"invalid" ~some:M.print expected)
         (Option.fold ~none:"invalid" ~some:M.print got))

let check_value_cases read () =
  match List.filter_map (case_fault read) value_cases with
  | [] -> ()
  | faults -> Alcotest.fail (String.concat "\n" faults)

let reader_gives_each_edge_case =
  Alcotest.test_case "read gives the value or Invalid of each edge case" `Quick
    (check_value_cases (fun bytes -> Result.to_option (reader bytes)))

let parent_and_text (key : M.located_key) =
  let count = List.length key.parts in
  let positions =
    List.filteri
      (fun _ (_, step) -> match step with `String _ -> true | _ -> false)
      (List.mapi (fun index step -> (index, step)) key.key_location)
  in
  let own =
    List.filteri
      (fun index _ -> index >= List.length positions - count)
      positions
  in
  List.map2
    (fun (index, step) (part : M.span) ->
      let text = match step with `String text -> text | _ -> "" in
      ( List.filteri (fun i _ -> i < index) key.key_location,
        text,
        part.start_byte ))
    own key.parts

let ordered_keys (document : M.document) location =
  let firsts = Hashtbl.create 16 in
  List.iter
    (fun key ->
      List.iter
        (fun (parent, text, start) ->
          if parent = location then
            match Hashtbl.find_opt firsts text with
            | Some first when first <= start -> ()
            | _ -> Hashtbl.replace firsts text start)
        (parent_and_text key))
    document.keys;
  Hashtbl.fold (fun text start acc -> (start, text) :: acc) firsts []
  |> List.sort compare |> List.map snd

let rec order_faults document location (table : T.table) =
  let keys = List.map fst table in
  let expected = ordered_keys document location in
  (if keys = expected then []
   else
     [
       Printf.sprintf "at %s: keys %s, expected %s"
         (Yojson.Basic.to_string (`List location))
         (String.concat "," keys)
         (String.concat "," expected);
     ])
  @ List.concat_map
      (fun (key, (item : T.item)) ->
        item_order_faults document (location @ [ `String key ]) item.value)
      table

and item_order_faults document location = function
  | T.Table table -> order_faults document location table
  | T.Array items ->
      List.concat
        (List.mapi
           (fun index (item : T.item) ->
             item_order_faults document
               (location @ [ `Int (index + 1) ])
               item.value)
           items)
  | _ -> []

let reads_generated_documents =
  property ~count:1000
    ~name:"read gives the root table of each generated document"
    ~print:M.print_document M.document_gen (fun document ->
      match T.read document.bytes with
      | Ok table ->
          let got = M.Table (model_table table) in
          M.equal got (M.Table document.root)
          || QCheck2.Test.fail_reportf "gives %s" (M.print got)
      | Error _ as failure ->
          QCheck2.Test.fail_reportf "gives %s" (failure_text failure))

let keeps_the_order_of_the_document =
  property ~count:500
    ~name:"read gives the keys of each table in the order of the document"
    ~print:M.print_document M.document_gen (fun document ->
      match T.read document.bytes with
      | Ok table -> (
          match order_faults document [] table with
          | [] -> true
          | faults -> QCheck2.Test.fail_reportf "%s" (String.concat "\n" faults)
          )
      | Error _ as failure ->
          QCheck2.Test.fail_reportf "gives %s" (failure_text failure))

let rec collect location (item : T.item) (values, keys) =
  let values =
    match item.span with
    | Some span -> (location, span) :: values
    | None -> values
  and keys =
    match item.key with Some key -> (location, key) :: keys | None -> keys
  in
  match item.value with
  | T.Table table ->
      List.fold_left
        (fun acc (key, item) -> collect (location @ [ `String key ]) item acc)
        (values, keys) table
  | T.Array items ->
      snd
        (List.fold_left
           (fun (index, acc) item ->
             (index + 1, collect (location @ [ `Int index ]) item acc))
           (1, (values, keys))
           items)
  | _ -> (values, keys)

let byte_span (span : M.span) =
  { T.start = span.start_byte; stop = span.end_byte }

let gives_the_byte_spans =
  property ~count:1000
    ~name:"read gives the byte span of each value and each key, and no other"
    ~print:M.print_document M.document_gen (fun document ->
      match T.read document.bytes with
      | Ok table ->
          let values, keys =
            List.fold_left
              (fun acc (key, item) -> collect [ `String key ] item acc)
              ([], []) table
          in
          let expected_values =
            List.map
              (fun (value : M.located) ->
                (value.location, byte_span value.span))
              document.values
          and expected_keys =
            List.map
              (fun (key : M.located_key) ->
                ( key.key_location,
                  {
                    T.whole = byte_span key.key_span;
                    parts = List.map byte_span key.parts;
                  } ))
              document.keys
          in
          (List.sort compare values = List.sort compare expected_values
          || QCheck2.Test.fail_reportf "the spans of the values differ")
          && (List.sort compare keys = List.sort compare expected_keys
             || QCheck2.Test.fail_reportf "the spans of the keys differ")
      | Error _ as failure ->
          QCheck2.Test.fail_reportf "gives %s" (failure_text failure))

let offset_fits bytes = function
  | Ok _ -> true
  | Error (T.Invalid { offset; _ }) | Error (T.Limit_reached { offset; _ }) ->
      offset >= 0 && offset <= String.length bytes

let total bytes =
  offset_fits bytes (T.read bytes)
  && offset_fits bytes (T.read ~max_depth:2 ~max_key_parts:2 bytes)
  && offset_fits bytes (T.read ~max_depth:0 ~max_key_parts:0 bytes)

let corrupted_gen =
  Gen.(M.document_gen >>= fun document -> M.corrupt_gen document.bytes)

let reads_corrupted_documents =
  property ~count:3000
    ~name:
      "read gives a value, or a failure in the bytes, for corrupted documents"
    ~print:(Printf.sprintf "%S") corrupted_gen total

let reads_noise =
  property ~count:3000
    ~name:"read gives a value, or a failure in the bytes, for any bytes"
    ~print:(Printf.sprintf "%S")
    (Gen.oneof
       [ M.noise_gen; Gen.string_size ~gen:Gen.char (Gen.int_range 0 64) ])
    total

let reads_deep_nesting_with_a_small_stack () =
  let ok bytes = match T.read bytes with Ok _ -> true | Error _ -> false in
  Alcotest.(check (list bool))
    "each document reads" [ true; true; true; true ]
    (Small_stack.run (fun () ->
         List.map ok
           [
             M.nested_arrays 1_000_000;
             M.nested_inline_tables 300_000;
             M.dotted_key 200_000;
             M.dotted_header 200_000;
           ]))

let rejects_unclosed_deep_nesting_with_a_small_stack () =
  let invalid bytes =
    match T.read bytes with Error (T.Invalid _) -> true | _ -> false
  in
  Alcotest.(check (list bool))
    "each byte sequence is invalid" [ true; true ]
    (Small_stack.run (fun () ->
         List.map invalid
           [
             "a = " ^ String.make 1_000_000 '[';
             "a = " ^ String.concat "" (List.init 300_000 (fun _ -> "{ b = "));
           ]))

let fault_cases =
  [
    ("a = 1\n\xFF", "Not_utf_8 at 6");
    ("a = \"\xC3\"", "Not_utf_8 at 5");
    ("a = \"\xED\xA0\x80\"", "Not_utf_8 at 5");
    ("a = \"\xF4\x90\x80\x80\"", "Not_utf_8 at 5");
    ("a = \"\xC0\xAF\"", "Not_utf_8 at 5");
    ("a = = 1\n\xFF", "Not_utf_8 at 8");
    ("a = 9223372036854775808", "Integer_out_of_range at 4");
    ("x = [1, 0x8000000000000000]", "Integer_out_of_range at 8");
    ("a = 1e400", "Float_out_of_range at 4");
    ("a = [1, -1e400]", "Float_out_of_range at 8");
    ("d = 1979-02-30", "Date_time_out_of_range at 4");
    ("a = 1979-05-27T07:32:00+24:00", "Date_time_out_of_range at 4");
    ("t = 12:00:61", "Date_time_out_of_range at 4");
    ("s = \"ab\\uD800\"", "Escape_not_a_character at 7");
    ("s = \"\"\"ab\\U00110000\"\"\"", "Escape_not_a_character at 9");
    ("a.\"\\uD800\" = 1", "Escape_not_a_character at 3");
    ("[a.\"\\uDC00\"]", "Escape_not_a_character at 4");
    ("a = 1\na = 2", "Duplicate_key at 6");
    ("a = { b = 1, b = 2 }", "Duplicate_key at 13");
    ("[a.b.c]\n[a]\nb = 1", "Duplicate_key at 12");
    ("[a]\n[a]", "Table_defined_twice at 5");
    ("[a]\n[ a ]", "Table_defined_twice at 6");
    ("a = 1\na.b = 2", "Not_a_table at 6");
    ("a = 1\n[a]", "Not_a_table at 7");
    ("a = [1]\n[a.b.c]", "Not_a_table at 9");
    ("a = []\n[[a]]", "Not_an_array_of_tables at 9");
    ("[a]\n[[a]]", "Not_an_array_of_tables at 6");
    ("a = { b = 1 }\na.c = 2", "Inline_table_closed at 14");
    ("x = { b.c = 1 }\n[x.b.d]", "Inline_table_closed at 17");
    ("a = {}\n[a]", "Inline_table_closed at 8");
    ("x = {}\n[[x]]", "Inline_table_closed at 9");
    ("[a.b.c]\nz = 9\n[a]\nb.c.x = 1", "Dotted_key_into_named_table at 18");
    ("[[a.b]]\n[a]\nb.y = 2", "Dotted_key_into_named_table at 12");
  ]

let gives_each_fault_with_its_offset () =
  List.iter
    (fun (bytes, expected) ->
      Alcotest.(check string)
        (Printf.sprintf "%S" bytes)
        expected
        (failure_text (T.read bytes)))
    fault_cases

let is_syntax = function
  | Error (T.Invalid { error = T.Syntax; _ }) -> true
  | _ -> false

let syntax_faults =
  [
    "a = 1 2";
    "a =";
    "a = [\n";
    "a = \"b\n";
    "[a\n";
    "a = 1\rb = 2";
    "= 1";
    "a = 1,";
    "[a]]";
    "[[a]";
    "a = {";
    "a = { b = 1 c = 2 }";
    "a = [1 2]";
    "a = [,]";
    "a = { , }";
    "\xEF\xBB\xBF\xEF\xBB\xBFa = 1";
    "a = 1\xEF\xBB\xBF";
    "a = \"\\q\"";
    "a.. b = 1";
    "a = tru";
    "a = 1979-05-27T07:32:00Zx";
    "a = 12: 5:00";
    "a = 12:00: 5";
    "a = 1979- 5-27";
    "a = 1979-05- 7";
    "a = 1979-05-27T07:32:00+ 7:00";
    "a = 1979-05-27T07:32:00+07: 0";
  ]

let gives_syntax_faults () =
  List.iter
    (fun bytes ->
      Alcotest.(check bool)
        (Printf.sprintf "%S gives Syntax" bytes)
        true
        (is_syntax (T.read bytes)))
    syntax_faults

let limit_cases =
  [
    (Some 2, None, "a = [[[x", "Depth at 6");
    (Some 2, None, "a = [[ x [[[", "Syntax");
    (Some 1, None, "a = { b = { } }", "Depth at 10");
    (Some 2, None, "a = [{ b = [1] }]", "Depth at 11");
    ( Some 2,
      None,
      "a = 9223372036854775808\nb = [[[1]]]",
      "Integer_out_of_range at 4" );
    (Some 2, None, "b = [[[1]]]\na = 9223372036854775808", "Depth at 6");
    (Some 1, None, "a = 1\na = [[1]]", "Duplicate_key at 6");
    (Some 1, None, "a = [1, [2], 1e400]", "Depth at 8");
    (Some 2, None, "a = [1, [2], 1e400]", "Float_out_of_range at 13");
    (None, Some 2, "a.a.a = 1", "Key_parts at 4");
    (None, Some 2, "[a.a.a]", "Key_parts at 5");
    (None, Some 2, "[[a . a . \"a\"]]", "Key_parts at 10");
    (None, Some 2, "x = { a.a.a = 1 }", "Key_parts at 10");
    (None, Some 2, "a = 1\na.a = 2", "Not_a_table at 6");
    (Some 0, None, "a = []", "Depth at 4");
    (None, Some 0, "a = 1", "Key_parts at 0");
    (Some 0, Some 1, "a = 1", "Ok");
  ]

let gives_each_limit () =
  List.iter
    (fun (max_depth, max_key_parts, bytes, expected) ->
      let got = T.read ?max_depth ?max_key_parts bytes in
      let name =
        Printf.sprintf "%S with max_depth %s and max_key_parts %s" bytes
          (Option.fold ~none:"-" ~some:string_of_int max_depth)
          (Option.fold ~none:"-" ~some:string_of_int max_key_parts)
      in
      if expected = "Syntax" then
        Alcotest.(check bool) name true (is_syntax got)
      else Alcotest.(check string) name expected (failure_text got))
    limit_cases

let limits_gen =
  Gen.(pair M.document_gen (pair (int_range 0 5) (int_range 0 5)))

let print_limits ((document : M.document), (depth, parts)) =
  Printf.sprintf "%s, max_depth %d, max_key_parts %d"
    (M.print_document document)
    depth parts

let reads_below_the_limits =
  property ~count:1000
    ~name:
      "read with limits gives the table of read without them, or the limit \
       that a depth or a key passes" ~print:print_limits limits_gen
    (fun ((document : M.document), (max_depth, max_key_parts)) ->
      let past_depth = document.depth > max_depth
      and past_parts = document.key_parts > max_key_parts in
      match T.read ~max_depth ~max_key_parts document.bytes with
      | Error (T.Limit_reached { limit = T.Depth; _ }) -> past_depth
      | Error (T.Limit_reached { limit = T.Key_parts; _ }) -> past_parts
      | Ok table -> (
          (not (past_depth || past_parts))
          &&
          match T.read document.bytes with
          | Ok other ->
              M.equal
                (M.Table (model_table table))
                (M.Table (model_table other))
          | Error _ -> false)
      | Error (T.Invalid _) -> false)

let empty_documents =
  [ "\xEF\xBB\xBF\n"; "\n"; "\r\n"; " \t"; "# a"; "\n\n# a\n" ]

let gives_an_empty_root_table () =
  List.iter
    (fun bytes ->
      Alcotest.(check string)
        (Printf.sprintf "%S" bytes)
        "Ok {\"table\":{}}"
        (match T.read bytes with
        | Ok table -> "Ok " ^ M.print (M.Table (model_table table))
        | Error _ as failure -> failure_text failure))
    empty_documents

let gives_the_sign_of_nan () =
  let sign_of bytes =
    match T.read bytes with
    | Ok [ (_, { T.value = T.Float x; _ }) ] when Float.is_nan x ->
        Some (Float.sign_bit x)
    | _ -> None
  in
  Alcotest.(check (list (option bool)))
    "the sign bits"
    [ Some false; Some false; Some true ]
    (List.map sign_of [ "a = nan"; "a = +nan"; "a = -nan" ])

let growth_inputs =
  [
    ("nested arrays", M.nested_arrays);
    ("nested inline tables", M.nested_inline_tables);
    ("a dotted key", M.dotted_key);
    ("a table header with a dotted key", M.dotted_header);
    ( "many key/value pairs",
      fun n ->
        String.concat ""
          (List.init n (fun i -> Printf.sprintf "k%d = %d\n" i i)) );
    ( "many table headers",
      fun n -> String.concat "" (List.init n (Printf.sprintf "[t%d]\nx = 1\n"))
    );
    ( "an array of tables",
      fun n -> String.concat "" (List.init n (fun _ -> "[[a]]\nb.c = 1\n")) );
    ( "a long array",
      fun n -> "a = [" ^ String.concat ", " (List.init n string_of_int) ^ "]\n"
    );
    ("a long string", fun n -> "a = \"" ^ String.make n 'x' ^ "\"\n");
    ("a long comment", fun n -> "# " ^ String.make n 'x' ^ "\na = 1\n");
  ]

let grows_no_faster_than_n_log_n () =
  List.iter
    (fun (name, input) ->
      match
        Counted_work.growth ~margin:2.5 ~sizes:(1_000, 16_000) ~input
          (fun bytes -> T.read bytes)
      with
      | Ok () -> ()
      | Error message -> Alcotest.failf "%s: %s" name message)
    growth_inputs

let tests =
  [
    every_valid_case_gives_its_value;
    every_invalid_case_is_invalid;
    reader_gives_each_edge_case;
    reads_generated_documents;
    keeps_the_order_of_the_document;
    gives_the_byte_spans;
    reads_corrupted_documents;
    reads_noise;
    Alcotest.test_case
      "read reads deep nesting and long keys with a small stack" `Quick
      reads_deep_nesting_with_a_small_stack;
    Alcotest.test_case
      "read gives Invalid for deep nesting that never closes, with a small \
       stack"
      `Quick rejects_unclosed_deep_nesting_with_a_small_stack;
    Alcotest.test_case "read gives each fault with its offset" `Quick
      gives_each_fault_with_its_offset;
    Alcotest.test_case "read gives Syntax for texts that do not match toml"
      `Quick gives_syntax_faults;
    Alcotest.test_case "read gives the first limit or fault that it reaches"
      `Quick gives_each_limit;
    reads_below_the_limits;
    Alcotest.test_case
      "read gives an empty root table for documents with no key/value pair"
      `Quick gives_an_empty_root_table;
    Alcotest.test_case "read gives the sign bit of NaN that the document writes"
      `Quick gives_the_sign_of_nan;
    Alcotest.test_case "the work of read grows no faster than n log n" `Quick
      grows_no_faster_than_n_log_n;
  ]
