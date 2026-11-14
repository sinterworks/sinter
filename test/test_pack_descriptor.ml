(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_pack_descriptor
module Gen = QCheck2.Gen
module D = Descriptor

let descriptor_set = Vectors.read "packs.descriptor"

let of_hex = function
  | `String digits -> Vector_json.of_hex digits
  | other ->
      Alcotest.failf "not a byte sequence: %s" (Yojson.Basic.to_string other)

let texts list = `List (List.map (fun text -> `String text) list)

let setting_form = function
  | D.String text -> `Assoc [ ("string", `String text) ]
  | D.Boolean flag -> `Assoc [ ("boolean", `Bool flag) ]
  | D.Strings list ->
      `Assoc
        [
          ( "array",
            `List
              (List.map (fun text -> `Assoc [ ("string", `String text) ]) list)
          );
        ]

let runner_form (runner : D.runner) =
  let source =
    match runner.source with
    | D.Adapter { hash; license } ->
        [
          ("adapter-hash", `String (hash :> string));
          ("adapter-license", `String license);
        ]
    | D.Match table ->
        [ ("match", Descriptor_reference.form_of_toml (Table table)) ]
  in
  `Assoc
    (source
    @ [
        ("name", `String (runner.runner_name :> string));
        ( "settings",
          `List
            (List.map
               (fun (setting : D.runner_setting) ->
                 `Assoc
                   [
                     ("default", setting_form setting.default);
                     ("name", `String setting.setting_name);
                   ])
               runner.settings) );
      ])

let grammar_form (grammar : D.grammar) =
  `Assoc
    [
      ( "globs",
        `List
          (List.map
             (fun glob ->
               `String
                 (Sinter_text.Text.encode (Sinter_paths.Glob.to_text glob)))
             grammar.globs) );
      ("hash", `String (grammar.hash :> string));
      ("license", `String grammar.license);
      ("name", `String (grammar.grammar_name :> string));
    ]

let values_form descriptor =
  `Assoc
    [
      ( "block-pairs",
        `List
          (List.map
             (fun (opening, closing) ->
               `List [ `String opening; `String closing ])
             (D.block_pairs descriptor)) );
      ("foreign-tag-words", texts (D.foreign_tag_words descriptor));
      ("grammars", `List (List.map grammar_form (D.grammars descriptor)));
      ("inner-sigils", texts (D.inner_sigils descriptor));
      ("license", `String (D.license descriptor));
      ("line-sigils", texts (D.line_sigils descriptor));
      ("name", `String (D.name descriptor :> string));
      ("name-separator", `String (D.name_separator descriptor));
      ("release", `String (D.release descriptor :> string));
      ("runners", `List (List.map runner_form (D.runners descriptor)));
      ("spec-version", `String (D.spec_version descriptor :> string));
    ]

let read_form bytes =
  match D.read bytes with
  | Ok descriptor -> Some (values_form descriptor)
  | Error _ -> None

let give_descriptor (vector : Vectors.vector) =
  match read_form (of_hex vector.input) with
  | Some values -> `Assoc [ ("result", `String "valid"); ("values", values) ]
  | None -> `Assoc [ ("result", `String "invalid"); ("values", `Assoc []) ]

(* @verifies packs#descriptor[descriptors][*]=v1
   The test reads each byte sequence of the group and compares the result, and
   each value of a valid descriptor, with those of the vector, so a wrong
   decision on a rule, a wrong or missing value, or a value of an absent
   adapter or match table fails it. *)
let descriptor_vectors =
  Vectors.group descriptor_set ~name:"descriptors" ~rev:"v1" give_descriptor

let member name = function
  | `Assoc members -> (
      match List.assoc_opt name members with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let path_of text =
  match Sinter_paths.Path.of_text (Test_packs.text_of text) with
  | Ok path -> path
  | Error _ -> Alcotest.failf "not a valid path: %S" text

let give_file_grammar (vector : Vectors.vector) =
  let bytes = of_hex (member "descriptor" vector.input) in
  let path =
    match member "path" vector.input with
    | `String text -> path_of text
    | _ -> Alcotest.fail "the path is not a string"
  in
  match D.read bytes with
  | Error _ -> Alcotest.fail "the descriptor is not valid"
  | Ok descriptor -> (
      match D.file_grammar descriptor path with
      | Some grammar ->
          `Assoc
            [
              ( "values",
                `Assoc [ ("grammar", `String (grammar.grammar_name :> string)) ]
              );
            ]
      | None -> `Assoc [ ("values", `Assoc []) ])

(* @verifies packs#descriptor[file-grammars][*]=v1
   The test gives each valid path of the group with its valid descriptor and
   compares the file grammar, or its absence, with the vector. *)
let file_grammar_vectors =
  Vectors.group descriptor_set ~name:"file-grammars" ~rev:"v1" give_file_grammar

let vector_groups = [ descriptor_vectors; file_grammar_vectors ]

let toml_string text =
  let buffer = Buffer.create (String.length text + 2) in
  Buffer.add_char buffer '"';
  String.iter
    (fun c ->
      match c with
      | '"' -> Buffer.add_string buffer "\\\""
      | '\\' -> Buffer.add_string buffer "\\\\"
      | c when Char.code c < 0x20 || c = '\x7f' ->
          Buffer.add_string buffer (Printf.sprintf "\\u%04X" (Char.code c))
      | c -> Buffer.add_char buffer c)
    text;
  Buffer.add_char buffer '"';
  Buffer.contents buffer

let toml_strings list =
  "[" ^ String.concat ", " (List.map toml_string list) ^ "]"

let maybe gen =
  Gen.oneof_weighted [ (1, Gen.return None); (3, Gen.map Option.some gen) ]

let pick = Gen.oneof_list

let pair_gen key value_gen =
  Gen.map (Option.map (fun value -> key ^ " = " ^ value)) (maybe value_gen)

let string_value list = Gen.map toml_string (pick list)
let zeros = String.make 64 '0'

let hash_gen bad =
  Gen.oneof_weighted
    [
      (8, Gen.return zeros);
      ( 3,
        Gen.return
          "778025db5a8be0e70f8ccc3671e486dfeddd048c25d9e8a70c26de2e1bf6f97d" );
      ( bad,
        pick [ String.make 64 'A'; String.make 63 '0'; String.make 65 '0'; "" ]
      );
    ]

let globs_gen bad =
  Gen.list_size (Gen.int_bound 3)
    (Gen.oneof_weighted
       [
         ( 10,
           pick
             [
               "*.x";
               "*";
               "**";
               "Makefile";
               "*.ts";
               "*.tsx";
               "a*b";
               "*.\xc3\xa9";
             ] );
         (bad, pick [ "src/*.x"; "*.[ch]"; "a//b"; ""; "x/" ]);
       ])

let grammar_table_gen bad =
  Gen.map
    (fun (pairs, extra) ->
      String.concat "\n" (List.filter_map Fun.id pairs @ extra))
    (Gen.pair
       (Gen.flatten_list
          [
            Gen.oneof_weighted
              [
                ( 12,
                  Gen.map
                    (fun v -> Some ("name = " ^ v))
                    (string_value [ "x"; "y"; "ocaml_interface"; "tsx" ]) );
                ( bad,
                  Gen.map
                    (fun v -> Some ("name = " ^ v))
                    (string_value [ "Rust"; "c-sharp"; ""; "_x" ]) );
                (bad, Gen.return None);
              ];
            Gen.oneof_weighted
              [
                ( 12,
                  Gen.map
                    (fun v -> Some ("sha256 = " ^ toml_string v))
                    (hash_gen bad) );
                (bad, Gen.return None);
              ];
            Gen.oneof_weighted
              [
                ( 12,
                  Gen.map
                    (fun v -> Some ("license = " ^ v))
                    (string_value [ "MIT"; ""; "Apache-2.0 OR MIT" ]) );
                (bad, Gen.return (Some "license = 1"));
                (bad, Gen.return None);
              ];
            Gen.oneof_weighted
              [
                ( 12,
                  Gen.map
                    (fun v -> Some ("names = " ^ toml_strings v))
                    (globs_gen bad) );
                (bad, Gen.return (Some "names = \"*.x\""));
                (bad, Gen.return None);
              ];
          ])
       (Gen.oneof_weighted
          [ (12, Gen.return []); (bad, Gen.return [ "file = \"x.wasm\"" ]) ]))

let setting_value_gen bad =
  Gen.oneof_weighted
    [
      (3, Gen.map toml_string (pick [ "t"; ""; "a\"b"; "\xc3\xa9" ]));
      (2, pick [ "true"; "false" ]);
      ( 3,
        Gen.map toml_strings
          (Gen.list_size (Gen.int_bound 3)
             (pick [ "a"; "testsuites@name=vitest tests"; "" ])) );
      (bad, pick [ "1"; "[\"a\", true]"; "{}"; "1.5"; "1979-05-27" ]);
    ]

let setting_name_gen =
  pick
    [
      "recognise";
      "Z";
      "dirs";
      "strict";
      "tag";
      "\xee\x80\x80";
      "\xf0\x9f\x98\x80";
      "a b";
      "";
    ]

let settings_gen bad =
  Gen.map
    (fun pairs ->
      let rec unique seen = function
        | [] -> []
        | (name, value) :: rest ->
            if List.mem name seen then unique seen rest
            else
              (toml_string name ^ " = " ^ value) :: unique (name :: seen) rest
      in
      "{ " ^ String.concat ", " (unique [] pairs) ^ " }")
    (Gen.list_size (Gen.int_bound 4)
       (Gen.pair setting_name_gen (setting_value_gen bad)))

let match_gen =
  pick
    [
      "{}";
      "{ x = { y = [true] } }";
      "{ path = [\"name\"], suite-separator = \" > \" }";
      "{ n = 1, f = 1.5, d = 1979-05-27, t = 07:32:00, o = \
       1979-05-27T07:32:00Z, l = 1979-05-27T07:32:00 }";
      "{ nan = nan, inf = -inf, z = -0.0 }";
    ]

let adapter_gen bad =
  Gen.oneof_weighted
    [
      ( 8,
        Gen.map2
          (fun hash license ->
            Printf.sprintf "{ sha256 = %s, license = %s }" (toml_string hash)
              (toml_string license))
          (hash_gen bad)
          (pick [ "MIT"; "Apache-2.0 OR MIT"; "" ]) );
      (bad, Gen.return ("{ sha256 = \"" ^ zeros ^ "\" }"));
      ( bad,
        Gen.return
          (Printf.sprintf "{ sha256 = \"%s\", license = \"MIT\", url = \"x\" }"
             zeros) );
      (bad, Gen.return "\"x\"");
    ]

let runner_gen bad =
  Gen.map4
    (fun name source settings extra ->
      let source =
        match source with
        | `Adapter adapter -> [ "adapter = " ^ adapter ]
        | `Match table -> [ "match = " ^ table ]
        | `Both (adapter, table) ->
            [ "adapter = " ^ adapter; "match = " ^ table ]
        | `Neither -> []
      in
      let members =
        source
        @ (match settings with
          | None -> []
          | Some table -> [ "settings = " ^ table ])
        @ extra
      in
      (name, "{ " ^ String.concat ", " members ^ " }"))
    (Gen.oneof_weighted
       [
         (10, pick [ "vitest"; "nextest"; "cargo-test"; "a1" ]);
         (bad, pick [ "Vitest"; "a--b"; "1a"; "\xc3\xa9" ]);
       ])
    (Gen.oneof_weighted
       [
         (5, Gen.map (fun adapter -> `Adapter adapter) (adapter_gen bad));
         (5, Gen.map (fun table -> `Match table) match_gen);
         ( bad,
           Gen.map2
             (fun adapter table -> `Both (adapter, table))
             (adapter_gen bad) match_gen );
         (bad, Gen.return `Neither);
       ])
    (maybe
       (Gen.oneof_weighted [ (8, settings_gen bad); (bad, Gen.return "[]") ]))
    (Gen.oneof_weighted
       [ (12, Gen.return []); (bad, Gen.return [ "other = 1" ]) ])

let runners_gen bad =
  Gen.map
    (fun runners ->
      let rec unique seen = function
        | [] -> []
        | (name, table) :: rest ->
            if List.mem name seen then unique seen rest
            else
              (toml_string name ^ " = " ^ table) :: unique (name :: seen) rest
      in
      "runner = { " ^ String.concat ", " (unique [] runners) ^ " }")
    (Gen.list_size (Gen.int_bound 3) (runner_gen bad))

let comments_gen bad =
  Gen.map
    (fun pairs ->
      "[comments]\n" ^ String.concat "\n" (List.filter_map Fun.id pairs))
    (Gen.flatten_list
       [
         pair_gen "line"
           (Gen.oneof_weighted
              [
                ( 8,
                  Gen.map toml_strings
                    (Gen.list_size (Gen.int_bound 3)
                       (pick [ "//"; "#"; ""; "--"; "\xc3\xa9" ])) );
                (bad, Gen.return "\"//\"");
              ]);
         pair_gen "block"
           (Gen.oneof_weighted
              [
                ( 8,
                  Gen.map
                    (fun pairs ->
                      "["
                      ^ String.concat ", " (List.map toml_strings pairs)
                      ^ "]")
                    (Gen.list_size (Gen.int_bound 3)
                       (Gen.oneof_weighted
                          [
                            ( 8,
                              pick
                                [
                                  [ "/*"; "*/" ];
                                  [ "/**"; "*/" ];
                                  [ "(*"; "*)" ];
                                  [ ""; "" ];
                                ] );
                            (bad, pick [ [ "/*" ]; [ "/*"; "*/"; "*" ]; [] ]);
                          ])) );
                (bad, Gen.return "[\"/*\", \"*/\"]");
              ]);
         pair_gen "inner"
           (Gen.map toml_strings
              (Gen.list_size (Gen.int_bound 2) (pick [ "*"; "" ])));
         Gen.oneof_weighted
           [ (12, Gen.return None); (bad, Gen.return (Some "doc = [\"///\"]")) ];
       ])

let descriptor_text_gen bad =
  Gen.map
    (fun ( (spec, name, version, license),
           (separator, tags, extra),
           (comments, grammars, runners) ) ->
      let root =
        List.filter_map Fun.id
          [ spec; name; version; license; separator; tags; extra; runners ]
      in
      let name_line table = List.hd (String.split_on_char '\n' table) in
      let grammars =
        if bad > 0 then grammars
        else
          List.fold_left
            (fun kept table ->
              if
                List.exists
                  (fun other -> name_line other = name_line table)
                  kept
              then kept
              else kept @ [ table ])
            [] grammars
      in
      String.concat "\n" root ^ "\n\n"
      ^ (match comments with Some comments -> comments ^ "\n\n" | None -> "")
      ^ String.concat "\n\n"
          (List.map (fun table -> "[[grammar]]\n" ^ table) grammars)
      ^ "\n")
    (Gen.triple
       (Gen.quad
          (Gen.oneof_weighted
             [
               ( 10,
                 Gen.map
                   (fun v -> Some ("sinter-spec = " ^ v))
                   (string_value [ "1.0"; "0.0"; "10.20" ]) );
               ( bad,
                 Gen.map
                   (fun v -> Some ("sinter-spec = " ^ v))
                   (pick [ "1.0"; "\"1.0.0\""; "\"01.0\""; "\"1\"" ]) );
               (bad, Gen.return None);
             ])
          (Gen.oneof_weighted
             [
               ( 10,
                 Gen.map
                   (fun v -> Some ("name = " ^ v))
                   (string_value [ "x"; "a-b2"; "typescript" ]) );
               ( bad,
                 Gen.map
                   (fun v -> Some ("name = " ^ v))
                   (string_value [ "Type"; "a--b"; "2a"; "a-"; "" ]) );
               (bad, Gen.return None);
             ])
          (Gen.oneof_weighted
             [
               ( 10,
                 Gen.map
                   (fun v -> Some ("version = " ^ v))
                   (string_value [ "0.1.0"; "10.20.30"; "0.0.0" ]) );
               ( bad,
                 Gen.map
                   (fun v -> Some ("version = " ^ v))
                   (string_value [ "1.0"; "1.00.0"; "1.0.0.0" ]) );
               (bad, Gen.return None);
             ])
          (Gen.oneof_weighted
             [
               ( 10,
                 Gen.map
                   (fun v -> Some ("license = " ^ v))
                   (string_value [ "MIT"; ""; "Apache-2.0" ]) );
               (bad, Gen.return (Some "license = true"));
               (bad, Gen.return None);
             ]))
       (Gen.triple
          (Gen.oneof_weighted
             [
               ( 10,
                 Gen.map
                   (fun v -> Some ("name-separator = " ^ v))
                   (string_value [ "."; "::"; " > " ]) );
               ( bad,
                 Gen.map
                   (fun v -> Some ("name-separator = " ^ v))
                   (string_value [ "" ]) );
               (bad, Gen.return None);
             ])
          (maybe
             (Gen.map
                (fun tags -> "foreign-tags = " ^ toml_strings tags)
                (Gen.list_size (Gen.int_bound 3)
                   (Gen.oneof_weighted
                      [
                        (8, pick [ "param"; "see-also"; "Param2"; "returns" ]);
                        (bad, pick [ "@param"; ""; "a.b"; "\xc3\xa9" ]);
                      ]))))
          (Gen.oneof_weighted
             [ (12, Gen.return None); (bad, Gen.return (Some "extra = 1")) ]))
       (Gen.triple
          (Gen.oneof_weighted
             [
               (12, Gen.map Option.some (comments_gen bad));
               (bad, Gen.return None);
             ])
          (Gen.oneof_weighted
             [
               (12, Gen.list_size (Gen.int_range 1 3) (grammar_table_gen bad));
               (bad, Gen.return []);
             ])
          (maybe (runners_gen bad))))

let descriptor_text_gen =
  Gen.oneof [ descriptor_text_gen 0; descriptor_text_gen 1 ]

let byte_change_gen bytes =
  let length = String.length bytes in
  Gen.oneof
    [
      Gen.map2
        (fun index byte ->
          let index = index mod (length + 1) in
          String.sub bytes 0 index ^ String.make 1 byte
          ^ String.sub bytes index (length - index))
        Gen.nat Vector_json.byte_gen;
      Gen.map
        (fun index ->
          if length = 0 then bytes
          else
            let index = index mod length in
            String.sub bytes 0 index
            ^ String.sub bytes (index + 1) (length - index - 1))
        Gen.nat;
      Gen.map2
        (fun index byte ->
          if length = 0 then bytes
          else
            let index = index mod length in
            String.mapi (fun place c -> if place = index then byte else c) bytes)
        Gen.nat Vector_json.byte_gen;
    ]

let input_gen =
  Gen.oneof_weighted
    [
      (6, descriptor_text_gen);
      (3, Gen.bind descriptor_text_gen byte_change_gen);
      (1, Gen.string_size ~gen:Vector_json.byte_gen (Gen.int_bound 40));
    ]

let read_holds bytes =
  let expected = Descriptor_reference.values bytes in
  match (D.read bytes, expected) with
  | Ok descriptor, Some form -> Yojson.Basic.equal (values_form descriptor) form
  | Error D.Not_a_toml_document, None -> (
      match Sinter_data_forms_toml.Data_forms_toml.read bytes with
      | Invalid -> true
      | Valid _ | No_result -> false)
  | Error D.Breaks_a_rule, None -> (
      match Sinter_data_forms_toml.Data_forms_toml.read bytes with
      | Valid _ -> true
      | Invalid | No_result -> false)
  | Ok _, None | Error _, Some _ -> false

(* @verifies packs#{
       read-descriptor=v1, give-descriptor-values=v1,
       omit-invalid-descriptor-values=v1, omit-absent-adapter-values=v1,
       omit-absent-match-tables=v1,
   }
   For generated descriptors that break each rule of a valid descriptor, and
   for byte sequences with a byte changed, a result or a value that differs
   from a direct reading of the ten rules fails the comparison, as does a
   value given for a byte sequence that is not a valid descriptor, an adapter
   hash for a test runner with a match table, or a match table for a test
   runner with an adapter. *)
let descriptors_follow_the_rules =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:3000
       ~name:
         "a generated byte sequence gives the result and the values of a \
          direct reading of the rules of a valid descriptor"
       ~print:String.escaped input_gen read_holds)

let valid_share =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1
       ~name:"the generated descriptors hold valid ones and invalid ones"
       (Gen.return ()) (fun () ->
         let inputs =
           Gen.generate ~n:500
             ~rand:(Random.State.make [| 7 |])
             descriptor_text_gen
         in
         let valid =
           List.length
             (List.filter
                (fun bytes ->
                  Option.is_some (Descriptor_reference.values bytes))
                inputs)
         in
         (valid >= 50 && valid <= 450)
         || QCheck2.Test.fail_reportf "%d of 500 are valid" valid))

let path_text_gen =
  Gen.map2
    (fun folders name -> String.concat "/" (folders @ [ name ]))
    (Gen.list_size (Gen.int_bound 2) (pick [ "src"; "a"; "x.ts" ]))
    (pick
       [
         "a.x";
         "a.ts";
         "A.TS";
         "App.tsx";
         "x.tsx.bak";
         "Makefile";
         "a\xc3\xa9";
         "a.\xc3\xa9";
         "ab";
         "...";
         ".x";
       ])

(* @verifies packs#{give-file-grammars=v1, omit-file-grammars=v1}
   For generated valid descriptors and valid paths, a grammar other than the
   first one in order whose file-name glob the last file name fits, or a
   grammar for a path that no file-name glob fits, fails the comparison. *)
let file_grammars_follow_the_globs =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:2000
       ~name:
         "the file grammar of a valid path is that of a direct reading of the \
          term"
       ~print:(fun (bytes, path) -> path ^ " with " ^ String.escaped bytes)
       (Gen.pair descriptor_text_gen path_text_gen)
       (fun (bytes, path) ->
         match D.read bytes with
         | Error _ -> QCheck2.assume_fail ()
         | Ok descriptor ->
             Option.map
               (fun (grammar : D.grammar) -> (grammar.grammar_name :> string))
               (D.file_grammar descriptor (path_of path))
             = Descriptor_reference.file_grammar bytes ~path))

let nested depth =
  String.concat "" (List.init depth (fun _ -> "{ a = "))
  ^ "[" ^ String.make depth '[' ^ String.make depth ']' ^ "]"
  ^ String.concat "" (List.init depth (fun _ -> " }"))

let deep_descriptor depth =
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
     match = %s\n"
    zeros (nested depth)

let deep_match_tables_need_no_deep_stack () =
  let read, depth_of_match =
    Test_file_read.with_small_stack (fun () ->
        let bytes = deep_descriptor 3000 in
        match D.read bytes with
        | Ok descriptor -> (
            match D.runners descriptor with
            | [ { source = D.Match table; _ } ] ->
                let rec depth
                    (value : Sinter_data_forms_toml.Data_forms_toml.value) count
                    =
                  match value with
                  | Table [ (_, value) ] | Array [ value ] ->
                      depth value (count + 1)
                  | _ -> count
                in
                (true, depth (Table table) 0)
            | _ -> (true, -1))
        | Error _ -> (false, 0))
  in
  Alcotest.(check bool) "the descriptor is valid" true read;
  Alcotest.(check int) "the depth of the match table" 6000 depth_of_match

let name_text_gen =
  Gen.oneof_weighted
    [
      ( 6,
        Gen.string_size
          ~gen:
            (pick
               [ 'a'; 'z'; 'A'; '0'; '9'; '-'; '_'; '.'; ' '; '\xc3'; '\xa9' ])
          (Gen.int_range 0 8) );
      ( 2,
        pick
          [
            "a";
            "a-b";
            "a1-2b";
            "0";
            "0.0";
            "1.2.3";
            "10.0";
            "01.0";
            "1.0.0.0";
            "1..0";
            ".1.0";
          ] );
    ]

let names_follow_the_productions =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:3000
       ~name:
         "a text is a pack name, a grammar name, a release number, or a spec \
          version when, and only when, it matches the production"
       ~print:String.escaped name_text_gen (fun text ->
         Option.is_some (Pack_name.of_string text)
         = Descriptor_reference.is_pack_name text
         && Option.is_some (Grammar_name.of_string text)
            = Descriptor_reference.is_grammar_name text
         && Option.is_some (Release_number.of_string text)
            = Descriptor_reference.is_numerals 3 text
         && Option.is_some (Spec_version.of_string text)
            = Descriptor_reference.is_numerals 2 text
         && List.for_all
              (function Some name -> name = text | None -> true)
              [
                Option.map
                  (fun (name : Pack_name.t) -> (name :> string))
                  (Pack_name.of_string text);
                Option.map
                  (fun (name : Grammar_name.t) -> (name :> string))
                  (Grammar_name.of_string text);
                Option.map
                  (fun (name : Release_number.t) -> (name :> string))
                  (Release_number.of_string text);
                Option.map
                  (fun (name : Spec_version.t) -> (name :> string))
                  (Spec_version.of_string text);
              ]))

let many_grammars_need_no_deep_stack () =
  let grammars =
    String.concat ""
      (List.init 20_000 (fun index ->
           Printf.sprintf
             "[[grammar]]\n\
              name = \"g%d\"\n\
              sha256 = \"%s\"\n\
              license = \"MIT\"\n\
              names = []\n"
             index zeros))
  in
  let bytes =
    "sinter-spec = \"1.0\"\n\
     name = \"x\"\n\
     version = \"0.1.0\"\n\
     license = \"MIT\"\n\
     name-separator = \".\"\n\
     [comments]\n" ^ grammars
  in
  match Test_file_read.with_small_stack (fun () -> D.read bytes) with
  | Ok descriptor ->
      Alcotest.(check int)
        "the grammars" 20_000
        (List.length (D.grammars descriptor))
  | Error _ -> Alcotest.fail "the descriptor is not valid"

let tests =
  Vectors.tests "packs.descriptor" vector_groups
  @ [
      Vectors.covers "packs.descriptor" descriptor_set vector_groups;
      descriptors_follow_the_rules;
      valid_share;
      file_grammars_follow_the_globs;
      Alcotest.test_case "many grammars need no deep stack" `Quick
        many_grammars_need_no_deep_stack;
      Alcotest.test_case "a deep match table needs no deep stack" `Quick
        deep_match_tables_need_no_deep_stack;
      names_follow_the_productions;
    ]
