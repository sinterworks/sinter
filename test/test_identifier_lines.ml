(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_identifiers
open Test_identifier_patterns
module Gen = QCheck2.Gen

let uchars_of_string string =
  let rec go index acc =
    if index >= String.length string then List.rev acc
    else
      let decode = String.get_utf_8_uchar string index in
      go
        (index + Uchar.utf_decode_length decode)
        (Uchar.utf_decode_uchar decode :: acc)
  in
  go 0 []

let text_of string = Text.of_uchars (uchars_of_string string)
let optional name = function Some text -> [ (name, str text) ] | None -> []

let slug_values slug =
  ("slug", str slug)
  :: optional "custom-namespace" (Target.custom_namespace slug)

let optional_slug = function Some slug -> slug_values slug | None -> []

let kind_values = function
  | Some word -> [ ("kind-word", str (Kind_word.to_string word)) ]
  | None -> []

let selection_values = function
  | None -> []
  | Some (Target.Vector_number number) -> [ ("vector-number", str number) ]
  | Some (Target.Group name) ->
      [ ("group-name", str name); ("every-vector", `Bool true) ]
  | Some Target.Every_vector -> [ ("every-vector", `Bool true) ]

let target_values = function
  | Target.Internal { kind_word; slug; part_name; vector_selection; revision }
    ->
      kind_values kind_word @ optional_slug slug
      @ optional "part-name" part_name
      @ selection_values vector_selection
      @ [ ("revision", str revision) ]
  | Target.Every_part { slug; revision } ->
      slug_values slug
      @ [ ("every-part", `Bool true); ("revision", str revision) ]
  | Target.External { kind_word; namespace_name; id; part_name } ->
      kind_values kind_word
      @ [ ("namespace-name", str namespace_name); ("id", str id) ]
      @ optional "part-name" part_name

let tag_values tag =
  let word = ("tag-word", str (Tag_word.to_string (Tag_line.tag_word tag))) in
  let kind name = ("type-of-tag-line", str name) in
  let description text = ("inline-description", str text) in
  match tag with
  | Tag_line.Declaration { slug; part_name; revision; inline_description; _ } ->
      [ word; kind "declaration"; description inline_description ]
      @ slug_values slug
      @ optional "part-name" part_name
      @ optional "revision" revision
  | Tag_line.Citation { entries; inline_description; _ } ->
      [
        word;
        kind "citation";
        description inline_description;
        ( "entries",
          `List (List.map (fun entry -> `Assoc (target_values entry)) entries)
        );
      ]
  | Tag_line.Status_tag { inline_description; _ } ->
      [ word; kind "status tag"; description inline_description ]
  | Tag_line.Extern { kind_word; part_name; inline_description } ->
      [
        word;
        kind "directive";
        ("kind-word", str (Kind_word.to_string kind_word));
        ("part-name", str part_name);
        description inline_description;
      ]
  | Tag_line.Ack { slug; subject; hash_prefix } ->
      [ word; kind "directive" ]
      @ slug_values slug
      @ [ ("subject", str subject); ("hash-prefix", str hash_prefix) ]

let line_result_json = function
  | Tag_line.Not_a_tag_line ->
      `Assoc [ ("result", str "not a tag line"); ("values", `Assoc []) ]
  | Tag_line.Other_tag_word word ->
      `Assoc
        [
          ("result", str "other tag word");
          ("values", `Assoc [ ("tag-word", str word) ]);
        ]
  | Tag_line.Invalid word ->
      `Assoc
        [
          ("result", str "invalid");
          ("values", `Assoc [ ("tag-word", str (Tag_word.to_string word)) ]);
        ]
  | Tag_line.Valid tag ->
      `Assoc [ ("result", str "valid"); ("values", `Assoc (tag_values tag)) ]

let standard_binding =
  match Binding.make [ ("gh", "[1-9][0-9]*"); ("rfc", "[1-9][0-9]*") ] with
  | Ok binding -> binding
  | Error _ -> Alcotest.fail "the binding of the vectors is valid"

let line_inputs binding string =
  List.map
    (fun (input : Tag_line.input) -> line_result_json input.result)
    (Tag_line.read binding (text_of string))

let read_input (vector : Vectors.vector) =
  match Binding.make (pairs_of_json (json_member "binding" vector.input)) with
  | Ok binding -> (binding, json_string (json_member "text" vector.input))
  | Error _ -> Alcotest.fail "the binding of the vector is valid"

let give_line (vector : Vectors.vector) =
  let binding, text = read_input vector in
  match line_inputs binding text with
  | [ input ] -> input
  | inputs -> `Assoc [ ("inputs", `List inputs) ]

let give_continuation (vector : Vectors.vector) =
  let binding, text = read_input vector in
  `Assoc [ ("values", `Assoc [ ("inputs", `List (line_inputs binding text)) ]) ]

(* @verifies identifiers[other-lines][*]=v1 *)
let other_line_vectors =
  Vectors.group set ~name:"other-lines" ~rev:"v1" give_line

(* @verifies identifiers[declarations][*]=v1 *)
let declaration_vectors =
  Vectors.group set ~name:"declarations" ~rev:"v1" give_line

(* @verifies identifiers[citations][*]=v1 *)
let citation_vectors = Vectors.group set ~name:"citations" ~rev:"v1" give_line

(* @verifies identifiers[status-tags][*]=v1 *)
let status_tag_vectors =
  Vectors.group set ~name:"status-tags" ~rev:"v1" give_line

(* @verifies identifiers[directives][*]=v1 *)
let directive_vectors = Vectors.group set ~name:"directives" ~rev:"v1" give_line

(* @verifies identifiers[continuation-lines][*]=v1 *)
let continuation_line_vectors =
  Vectors.group set ~name:"continuation-lines" ~rev:"v1" give_continuation

let check_json name want have =
  if not (Vectors.equal_json want have) then
    Alcotest.failf "%s\n  want: %s\n  have: %s" name
      (Yojson.Basic.to_string want)
      (Yojson.Basic.to_string have)

let check_cases name read cases () =
  let failures =
    List.filter_map
      (fun (input, want) ->
        let want = `List want in
        match read input with
        | have when Vectors.equal_json want have -> None
        | have ->
            Some
              (Printf.sprintf "%s %S\n  want: %s\n  have: %s" name input
                 (Yojson.Basic.to_string want)
                 (Yojson.Basic.to_string have))
        | exception error ->
            Some
              (Printf.sprintf "%s %S raised %s" name input
                 (Printexc.to_string error)))
      cases
  in
  if failures <> [] then
    Alcotest.failf "%d of %d cases fail:\n%s" (List.length failures)
      (List.length cases)
      (String.concat "\n" failures)

let line_valid kind tag values =
  `Assoc
    [
      ("result", str "valid");
      ( "values",
        `Assoc
          (("tag-word", str tag) :: ("type-of-tag-line", str kind) :: values) );
    ]

let line_invalid tag =
  `Assoc
    [ ("result", str "invalid"); ("values", `Assoc [ ("tag-word", str tag) ]) ]

let other tag =
  `Assoc
    [
      ("result", str "other tag word");
      ("values", `Assoc [ ("tag-word", str tag) ]);
    ]

let not_tag = `Assoc [ ("result", str "not a tag line"); ("values", `Assoc []) ]
let desc text = ("inline-description", str text)
let decl tag values = line_valid "declaration" tag values
let status tag text = line_valid "status tag" tag [ desc text ]

let cites ?(tag = "@cites") ?(text = "") entries =
  line_valid "citation" tag
    [
      desc text;
      ("entries", `List (List.map (fun entry -> `Assoc entry) entries));
    ]

let slug text = ("slug", str text)
let rev text = ("revision", str text)
let part text = ("part-name", str text)
let ns text = ("custom-namespace", str text)
let kind text = ("kind-word", str text)
let ext name id = [ ("namespace-name", str name); ("id", str id) ]
let every_vector = ("every-vector", `Bool true)
let every_part = ("every-part", `Bool true)

let ack slug_text subject hash =
  line_valid "directive" "@ack"
    (slug_values slug_text
    @ [ ("subject", str subject); ("hash-prefix", str hash) ])

let line_cases =
  [
    ("@cites  docs=v1", [ cites [ [ slug "docs"; rev "v1" ] ] ]);
    ("@req a=v1 ", [ decl "@req" [ slug "a"; rev "v1"; desc "" ] ]);
    ("@req a=v1 b  c ", [ decl "@req" [ slug "a"; rev "v1"; desc "b  c " ] ]);
    ("   ", [ not_tag ]);
    ("", []);
    ("x@req a=v1", [ not_tag ]);
    ("@req a.b_c-d=v1", [ decl "@req" [ slug "a.b_c-d"; rev "v1"; desc "" ] ]);
    ("@req a#b=v1", [ decl "@req" [ slug "a"; part "b"; rev "v1"; desc "" ] ]);
    ( "@req a/b#c.d=v1",
      [ decl "@req" [ slug "a/b"; ns "a"; part "c.d"; rev "v1"; desc "" ] ] );
    ("@decision a#b=v1", [ line_invalid "@decision" ]);
    ("@finding-class a#b=v1", [ line_invalid "@finding-class" ]);
    ( "@design a.b/c=v1",
      [ decl "@design" [ slug "a.b/c"; ns "a.b"; rev "v1"; desc "" ] ] );
    ( "@spec a/b#c=v1",
      [ decl "@spec" [ slug "a/b"; ns "a"; part "c"; rev "v1"; desc "" ] ] );
    ("@term a/b", [ decl "@term" [ slug "a/b"; ns "a"; desc "" ] ]);
    ("@term a=v1 b", [ decl "@term" [ slug "a"; rev "v1"; desc "b" ] ]);
    ("@req a=v1#x", [ line_invalid "@req" ]);
    ("@req a=v}1", [ line_invalid "@req" ]);
    ("@req a=v#1", [ line_invalid "@req" ]);
    ("@req a==v1", [ line_invalid "@req" ]);
    ("@req a=v1\r", [ line_invalid "@req" ]);
    ("@req a=v1\r\n", [ decl "@req" [ slug "a"; rev "v1"; desc "" ] ]);
    ( "@req a=v1 \xef\xbb\xbf",
      [ decl "@req" [ slug "a"; rev "v1"; desc "\xef\xbb\xbf" ] ] );
    ("x\n\xef\xbb\xbf@req a=v1", [ not_tag; not_tag ]);
    ("@req_x a=v1", [ line_invalid "@req" ]);
    ("@cites=", [ line_invalid "@cites" ]);
    ("@", [ other "@" ]);
    ("@@req a=v1", [ other "@" ]);
    ("@REQ a=v1", [ other "@REQ" ]);
    ( "a\n@req a=v1\n\n@x",
      [
        not_tag;
        decl "@req" [ slug "a"; rev "v1"; desc "" ];
        not_tag;
        other "@x";
      ] );
    ("a\r\n@deferred\r\n", [ not_tag; status "@deferred" "" ]);
    ("@cites GH/42", [ line_invalid "@cites" ]);
    ("@cites x/gh/42=v1", [ cites [ [ slug "x/gh/42"; ns "x/gh"; rev "v1" ] ] ]);
    ("@cites req:gh/42", [ cites [ kind "req" :: ext "gh" "42" ] ]);
    ("@cites req:gh=v1", [ line_invalid "@cites" ]);
    ("@cites gh/x", [ line_invalid "@cites" ]);
    ("@cites gh/42 x", [ cites ~text:"x" [ ext "gh" "42" ] ]);
    ( "@verifies gh/42#x",
      [ cites ~tag:"@verifies" [ ext "gh" "42" @ [ part "x" ] ] ] );
    ("@supersedes gh/42", [ cites ~tag:"@supersedes" [ ext "gh" "42" ] ]);
    ("@satisfies rfc/1", [ cites ~tag:"@satisfies" [ ext "rfc" "1" ] ]);
    ("@cites gh/42 gh/43", [ cites ~text:"gh/43" [ ext "gh" "42" ] ]);
    ( "@cites {#a=v1, gh/42#a}",
      [ cites [ [ part "a"; rev "v1" ]; ext "gh" "42" @ [ part "a" ] ] ] );
    ( "@cites {#a=v1,#a[1]=v1,#a[x][*]=v1,#a[*]=v1}",
      [
        cites
          [
            [ part "a"; rev "v1" ];
            [ part "a"; ("vector-number", str "1"); rev "v1" ];
            [ part "a"; ("group-name", str "x"); every_vector; rev "v1" ];
            [ part "a"; every_vector; rev "v1" ];
          ];
      ] );
    ("@cites {#a=v1, #a=*}", [ line_invalid "@cites" ]);
    ("@cites {a=v1, a=v2}", [ line_invalid "@cites" ]);
    ("@cites { docs=v1 , }", [ cites [ [ slug "docs"; rev "v1" ] ] ]);
    ( "@cites {docs=v1}  desc",
      [ cites ~text:"desc" [ [ slug "docs"; rev "v1" ] ] ] );
    ( "@cites {docs=v1}\tdesc",
      [ cites ~text:"desc" [ [ slug "docs"; rev "v1" ] ] ] );
    ("@cites docs=v1 ,", [ cites ~text:"," [ [ slug "docs"; rev "v1" ] ] ]);
    ("@cites #{a=v1} x", [ cites ~text:"x" [ [ part "a"; rev "v1" ] ] ]);
    ( "@cites spec:a/b#{c=v1}",
      [ cites [ [ kind "spec"; slug "a/b"; ns "a"; part "c"; rev "v1" ] ] ] );
    ("@cites {a=v1},{b=v1}", [ line_invalid "@cites" ]);
    ("@supersedes #a=v1#*", [ line_invalid "@supersedes" ]);
    ("@supersedes a#b=v1#*", [ line_invalid "@supersedes" ]);
    ("@supersedes docs=v3#", [ line_invalid "@supersedes" ]);
    ("@satisfies docs=v3#*", [ line_invalid "@satisfies" ]);
    ("@cites {a#, b=v1}", [ line_invalid "@cites" ]);
    ("@verifies {a=v1, b=*}", [ line_invalid "@verifies" ]);
    ("@satisfies #a[1]=v1", [ line_invalid "@satisfies" ]);
    ( "@cites decision:a=v1",
      [ cites [ [ kind "decision"; slug "a"; rev "v1" ] ] ] );
    ("@cites design:a=v1", [ cites [ [ kind "design"; slug "a"; rev "v1" ] ] ]);
    ("@cites term:a=v1", [ cites [ [ kind "term"; slug "a"; rev "v1" ] ] ]);
    ( "@cites a[1]=v1",
      [ cites [ [ slug "a"; ("vector-number", str "1"); rev "v1" ] ] ] );
    ("@cites a[1]", [ line_invalid "@cites" ]);
    ("@cites a[ 1]=v1", [ line_invalid "@cites" ]);
    ( "@extern decision:x",
      [
        line_valid "directive" "@extern" [ kind "decision"; part "x"; desc "" ];
      ] );
    ( "@extern term:a.b-c_d",
      [
        line_valid "directive" "@extern"
          [ kind "term"; part "a.b-c_d"; desc "" ];
      ] );
    ("@extern spec:gh/42", [ line_invalid "@extern" ]);
    ("@extern spec:#x", [ line_invalid "@extern" ]);
    ("@extern  ", [ line_invalid "@extern" ]);
    ("@ack a 3f2a9c1g", [ line_invalid "@ack" ]);
    ("@ack", [ line_invalid "@ack" ]);
    ("@ack\ta\tx\t3f2a9c1d", [ ack "a" "x" "3f2a9c1d" ]);
    ("@ack a 0123456", [ line_invalid "@ack" ]);
    ("@deferred  ", [ status "@deferred" "" ]);
    ("@deprecated:", [ line_invalid "@deprecated" ]);
  ]

let continuation_cases =
  [
    ( "@cites {#a=v1,\n  #b=v1} desc",
      [ cites ~text:"desc" [ [ part "a"; rev "v1" ]; [ part "b"; rev "v1" ] ] ]
    );
    ( "@cites {#a=v1,\n#b=v1}\n@req c=v1",
      [
        cites [ [ part "a"; rev "v1" ]; [ part "b"; rev "v1" ] ];
        decl "@req" [ slug "c"; rev "v1"; desc "" ];
      ] );
    ("@extern {\nx}", [ line_invalid "@extern"; not_tag ]);
    ("@cites\t{\n#a=v1}", [ cites [ [ part "a"; rev "v1" ] ] ]);
    ( "@cites {#a=v1,\n#b=v1}\nx",
      [ cites [ [ part "a"; rev "v1" ]; [ part "b"; rev "v1" ] ]; not_tag ] );
    ( "@cites {#a=v1, #b=v1\n}",
      [ cites [ [ part "a"; rev "v1" ]; [ part "b"; rev "v1" ] ] ] );
    ("@cites {\n\t\n#a=v1}", [ line_invalid "@cites"; not_tag; not_tag ]);
    ("@cites {\n#a=v1,\n#a=v2}", [ line_invalid "@cites" ]);
    ("@cites {\n{#a=v1}}", [ line_invalid "@cites" ]);
  ]

let line_ranges_of_continued_citations () =
  let ranges string =
    List.map
      (fun (input : Tag_line.input) -> (input.first_line, input.last_line))
      (Tag_line.read standard_binding (text_of string))
  in
  Alcotest.(check (list (pair int int)))
    "a citation over three lines, then a line"
    [ (1, 3); (4, 4) ]
    (ranges "@cites {#a=v1,\n#b=v1,\n}\nx");
  Alcotest.(check (list (pair int int)))
    "a citation that no line closes keeps its continuation lines"
    [ (1, 2) ]
    (ranges "@cites {#a=v1,\n#b=v1");
  Alcotest.(check (list (pair int int)))
    "a blank line ends the citation"
    [ (1, 1); (2, 2); (3, 3) ]
    (ranges "@cites {\n\n#a=v1}");
  Alcotest.(check (list (pair int int)))
    "the lines after a byte order mark"
    [ (1, 2); (3, 3) ]
    (ranges "\xef\xbb\xbf@cites {\n#a=v1}\n@req b=v1")

(* @verifies identifiers#reject-unmatched-inputs=v1 *)
let line_examples =
  check_cases "the text"
    (fun string -> `List (line_inputs standard_binding string))
    line_cases

let continuation_examples =
  check_cases "the text"
    (fun string -> `List (line_inputs standard_binding string))
    continuation_cases

(* @verifies identifiers#{use-one-binding=v1, reject-repeated-entries=v1} *)
let one_binding_reads_each_text () =
  let jira =
    match Binding.make [ ("jira", "[A-Z]+-[1-9][0-9]*") ] with
    | Ok binding -> binding
    | Error _ -> Alcotest.fail "the binding is valid"
  in
  let check name binding string want =
    check_json name (`List want) (`List (line_inputs binding string))
  in
  check "gh/42 is external under the standard binding" standard_binding
    "@cites gh/42"
    [ cites [ ext "gh" "42" ] ];
  check "gh/42 is a slug under the empty binding" Binding.empty "@cites gh/42"
    [ line_invalid "@cites" ];
  check "gh/42=v1 is a slug under the empty binding" Binding.empty
    "@cites gh/42=v1"
    [ cites [ [ slug "gh/42"; ns "gh"; rev "v1" ] ] ];
  check "gh/42=v1 is a slug under another binding" jira "@cites gh/42=v1"
    [ cites [ [ slug "gh/42"; ns "gh"; rev "v1" ] ] ];
  check "jira/PROJ-1 is external under its binding" jira "@cites jira/PROJ-1"
    [ cites [ ext "jira" "PROJ-1" ] ];
  (match Binding.make [ ("a", "[1-9]"); ("b", "[1-9]") ] with
  | Error _ -> Alcotest.fail "the binding is valid"
  | Ok two ->
      check "two external ids that differ only in their namespace" two
        "@cites {a/1, b/1}"
        [ cites [ ext "a" "1"; ext "b" "1" ] ]);
  (match Binding.make [ ("x", "[!\"$%&'()*+.0-9:;<>?A-Z_`a-z|~-]+") ] with
  | Error _ -> Alcotest.fail "the binding is valid"
  | Ok wide ->
      check "an id of every printable character that an id allows" wide
        "@cites x/!\"$%&'()*+-.09:;<>?AZ_`az|~"
        [ cites [ ext "x" "!\"$%&'()*+-.09:;<>?AZ_`az|~" ] ];
      check "an id with a backslash fits no id pattern" wide "@cites x/a\\b"
        [ line_invalid "@cites" ];
      check "an id with a caret fits no id pattern" wide "@cites x/a^b"
        [ line_invalid "@cites" ]);
  check "jira/proj-1 does not fit" jira "@cites jira/proj-1"
    [ line_invalid "@cites" ];
  check "@design gh=v1 is valid under the empty binding" Binding.empty
    "@design gh=v1"
    [ decl "@design" [ slug "gh"; rev "v1"; desc "" ] ]

let words () =
  Alcotest.(check (list string))
    "the kind words"
    [ "decision"; "design"; "finding-class"; "req"; "spec"; "term" ]
    (List.sort String.compare (List.map Kind_word.to_string Kind_word.all));
  Alcotest.(check (list string))
    "the Sinter tag words"
    (List.sort String.compare
       [
         "@decision";
         "@design";
         "@finding-class";
         "@req";
         "@spec";
         "@term";
         "@cites";
         "@refines";
         "@satisfies";
         "@supersedes";
         "@verifies";
         "@deferred";
         "@deprecated";
         "@rejected";
         "@ack";
         "@extern";
       ])
    (List.sort String.compare (List.map Tag_word.to_string Tag_word.all));
  List.iter
    (fun word ->
      Alcotest.(check bool)
        (Kind_word.to_string word) true
        (Kind_word.of_string (Kind_word.to_string word) = Some word))
    Kind_word.all;
  List.iter
    (fun word ->
      Alcotest.(check bool)
        (Tag_word.to_string word) true
        (Tag_word.of_string (Tag_word.to_string word) = Some word))
    Tag_word.all;
  List.iter
    (fun text ->
      Alcotest.(check bool) text true (Kind_word.of_string text = None))
    [ "Req"; "req "; ""; "plan"; "reqs"; ":req" ];
  List.iter
    (fun text ->
      Alcotest.(check bool) text true (Tag_word.of_string text = None))
    [ "@Req"; "req"; "@"; ""; "@reqs"; "@req " ]

let custom_namespaces () =
  Alcotest.(check (list (option string)))
    "the custom namespaces"
    [ None; Some "billing"; Some "a/b"; None ]
    (List.map Target.custom_namespace [ "packs"; "billing/auth"; "a/b/c"; "" ])

let large_texts_are_read () =
  let entries = List.init 20000 (fun index -> Printf.sprintf "#p%d=v1" index) in
  let citation = "@cites {" ^ String.concat ",\n" entries ^ "}" in
  (match Tag_line.read standard_binding (text_of citation) with
  | [
   {
     result = Tag_line.Valid (Tag_line.Citation { entries = read; _ });
     first_line;
     last_line;
   };
  ] ->
      Alcotest.(check int) "the entries" 20000 (List.length read);
      Alcotest.(check (pair int int))
        "the lines" (1, 20000) (first_line, last_line)
  | _ -> Alcotest.fail "one valid citation");
  let long = "@req a=v1 " ^ String.make 1_000_000 'x' in
  Alcotest.(check int)
    "one input for a long line" 1
    (List.length (Tag_line.read standard_binding (text_of long)));
  let lines = String.concat "\n" (List.init 50000 (fun _ -> "@cites {")) in
  Alcotest.(check int)
    "one input for each line that opens a list" 50000
    (List.length (Tag_line.read standard_binding (text_of lines)))

let word_gen alphabet size =
  Gen.map concat (Gen.list_size size (one_of (chars alphabet)))

let alnum_run = word_gen "abcxyzABZ0189" (Gen.int_range 1 2)

let segment_gen =
  Gen.map2
    (fun first rest -> concat (first :: rest))
    alnum_run
    (Gen.list_size (Gen.int_range 0 2)
       (Gen.map2 ( ^ ) (one_of [ "-"; "_"; "." ]) alnum_run))

let unique_segment index =
  Gen.map (fun segment -> Printf.sprintf "%s-n%d" segment index) segment_gen

let slug_gen index =
  Gen.map2
    (fun path last -> String.concat "/" (path @ [ last ]))
    (Gen.list_size (Gen.int_range 0 2) segment_gen)
    (unique_segment index)

let label_gen =
  word_gen "!\"$%&'()+-.0123456789:;<>?ABZ\\^_`az|~" (Gen.int_range 1 4)

let gap_gen = one_of [ " "; "\t"; "  "; " \t" ]
let indent_gen = one_of [ ""; ""; " "; "\t"; "   " ]

let description_gen =
  Gen.oneof
    [
      Gen.return "";
      Gen.map2 ( ^ )
        (one_of [ "x"; "@"; "{"; "}"; "\xc3\xa9"; "#"; "="; "\xc2\xa0"; "," ])
        (Gen.map concat
           (Gen.list_size (Gen.int_range 0 5)
              (one_of [ "a"; " "; "\t"; "{"; "@b"; "\xe2\x80\xa8"; ","; "}" ])));
    ]

let ending_gen description =
  if description = "" then one_of [ ""; " "; "\t " ]
  else Gen.map (fun gap -> gap ^ description) gap_gen

let valid_line kind word values =
  `Assoc
    [
      ("result", str "valid");
      ( "values",
        `Assoc
          (("tag-word", str word) :: ("type-of-tag-line", str kind) :: values)
      );
    ]

let declaration_gen =
  let open Gen in
  let* word =
    one_of
      [ "@decision"; "@design"; "@finding-class"; "@req"; "@spec"; "@term" ]
  in
  let* indent = indent_gen and* gap = gap_gen and* slug = slug_gen 1 in
  let* part = unique_segment 2 and* label = label_gen and* shape = bool in
  let* with_revision = bool and* segment = unique_segment 3 in
  let* description = description_gen in
  let* ending = ending_gen description in
  let name, name_values =
    match word with
    | "@spec" when shape -> (segment, [ ("slug", str segment) ])
    | ("@spec" | "@req" | "@term") when not shape ->
        (slug ^ "#" ^ part, slug_values slug @ [ ("part-name", str part) ])
    | _ -> (slug, slug_values slug)
  in
  let revision =
    if word = "@term" && not with_revision then None else Some label
  in
  let target =
    match revision with Some label -> name ^ "=" ^ label | None -> name
  in
  let values =
    name_values
    @ (match revision with
      | Some label -> [ ("revision", str label) ]
      | None -> [])
    @ [ desc description ]
  in
  return
    ( indent ^ word ^ gap ^ target ^ ending,
      [ valid_line "declaration" word values ] )

let kind_gen =
  one_of
    [ None; Some "decision"; Some "req"; Some "spec"; Some "finding-class" ]

let kind_prefix = function Some word -> word ^ ":" | None -> ""

let kind_text_values = function
  | Some word -> [ ("kind-word", str word) ]
  | None -> []

let selection_gen allowed index =
  if not allowed then Gen.return ("", [])
  else
    one_of
      [
        ("", []);
        ( Printf.sprintf "[%d]" (index + 1),
          [ ("vector-number", str (string_of_int (index + 1))) ] );
        ("[*]", [ ("every-vector", `Bool true) ]);
        ( "[grp-1][*]",
          [ ("group-name", str "grp-1"); ("every-vector", `Bool true) ] );
      ]

let revision_gen star =
  if star then Gen.oneof [ label_gen; Gen.return "*" ] else label_gen

let list_space_gen = one_of [ ""; ""; " "; "\t"; "\n"; "\n  "; " \n\t" ]

type rules = { selections : bool; star : bool; every_part : bool }

let rules_of = function
  | "@cites" -> { selections = true; star = true; every_part = false }
  | "@verifies" -> { selections = true; star = false; every_part = false }
  | "@supersedes" -> { selections = false; star = false; every_part = true }
  | _ -> { selections = false; star = false; every_part = false }

let single_gen rules index =
  let open Gen in
  let* kind = kind_gen
  and* slug = slug_gen index
  and* part = unique_segment index in
  let* selection, selection_values = selection_gen rules.selections index in
  let* revision = revision_gen rules.star and* label = label_gen in
  let* form = int_range 0 (if rules.every_part then 4 else 3) in
  let* external_part = bool in
  let with_kind name values =
    ( kind_prefix kind ^ name ^ selection ^ "=" ^ revision,
      kind_text_values kind @ values @ selection_values
      @ [ ("revision", str revision) ] )
  in
  return
    (match form with
    | 0 -> with_kind slug (slug_values slug)
    | 1 ->
        with_kind
          (slug ^ "#" ^ part)
          (slug_values slug @ [ ("part-name", str part) ])
    | 2 -> with_kind ("#" ^ part) [ ("part-name", str part) ]
    | 3 ->
        let id = string_of_int (index + 1) in
        let suffix, part_values =
          if external_part then ("#" ^ part, [ ("part-name", str part) ])
          else ("", [])
        in
        ( kind_prefix kind ^ "gh/" ^ id ^ suffix,
          kind_text_values kind
          @ [ ("namespace-name", str "gh"); ("id", str id) ]
          @ part_values )
    | _ ->
        ( slug ^ "=" ^ label ^ "#*",
          slug_values slug
          @ [ ("every-part", `Bool true); ("revision", str label) ] ))

let scoped_gen rules index =
  let open Gen in
  let* kind = kind_gen and* slug = slug_gen index and* with_slug = bool in
  let* count = int_range 1 3
  and* trailing = bool
  and* spaces = list_size (int_range 8 8) list_space_gen in
  let space k = List.nth spaces k in
  let* parts =
    flatten_list
      (List.init count (fun k ->
           let* part = unique_segment (1000 + (index * 10) + k) in
           let* selection, selection_values =
             selection_gen rules.selections k
           in
           let* revision = revision_gen rules.star in
           return
             ( part ^ selection ^ "=" ^ revision,
               (("part-name", str part) :: selection_values)
               @ [ ("revision", str revision) ] )))
  in
  let head = kind_prefix kind ^ if with_slug then slug else "" in
  let prefix =
    kind_text_values kind @ if with_slug then slug_values slug else []
  in
  let body = String.concat (space 1 ^ "," ^ space 2) (List.map fst parts) in
  return
    ( head ^ "#{" ^ space 0 ^ body
      ^ (if trailing then space 3 ^ "," else "")
      ^ space 4 ^ "}",
      List.map (fun (_, values) -> prefix @ values) parts )

let element_gen rules index =
  Gen.oneof
    [
      Gen.map
        (fun (text, values) -> (text, [ values ]))
        (single_gen rules index);
      Gen.map
        (fun (text, values) -> (text, values))
        (single_gen rules index |> Gen.map (fun (t, v) -> (t, [ v ])));
      scoped_gen rules index;
    ]

let citation_gen =
  let open Gen in
  let* word =
    one_of [ "@cites"; "@verifies"; "@refines"; "@satisfies"; "@supersedes" ]
  in
  let rules = rules_of word in
  let* indent = indent_gen and* gap = gap_gen and* shape = int_range 0 2 in
  let* count = int_range 1 4 and* trailing = bool in
  let* spaces = list_size (int_range 8 8) list_space_gen in
  let space k = List.nth spaces k in
  let* description = description_gen in
  let* ending = ending_gen description in
  let* target, entries =
    match shape with
    | 0 -> map (fun (text, values) -> (text, [ values ])) (single_gen rules 0)
    | 1 -> scoped_gen rules 0
    | _ ->
        let* elements =
          flatten_list (List.init count (fun k -> element_gen rules k))
        in
        return
          ( "{" ^ space 0
            ^ String.concat (space 1 ^ "," ^ space 2) (List.map fst elements)
            ^ (if trailing then space 3 ^ "," else "")
            ^ space 4 ^ "}",
            List.concat_map snd elements )
  in
  return
    ( indent ^ word ^ gap ^ target ^ ending,
      [
        valid_line "citation" word
          [
            desc description;
            ("entries", `List (List.map (fun values -> `Assoc values) entries));
          ];
      ] )

let print_case (text, want) =
  Printf.sprintf "%S\nwant: %s" text (Yojson.Basic.to_string (`List want))

let same read (text, want) =
  let have = read text in
  Vectors.equal_json (`List want) have
  ||
  (Printf.eprintf "have: %s\n" (Yojson.Basic.to_string have);
   false)

let read_lines text = `List (line_inputs standard_binding text)

(* @verifies identifiers#{give-values=v1, accept-inputs=v1} *)
let declarations_give_their_values =
  property ~count:500
    ~name:"a declaration made from the grammar gives its values"
    ~print:print_case declaration_gen (same read_lines)

(* @verifies identifiers#{give-values=v1, accept-inputs=v1} *)
let citations_give_their_values =
  property ~count:500
    ~name:"a citation made from the grammar gives the values of each entry"
    ~print:print_case citation_gen (same read_lines)

let line_token_gen =
  one_of
    [
      "@req";
      "@cites";
      "@ack";
      "@term";
      "@supersedes";
      "@extern";
      "@deferred";
      "@";
      "@x-1";
      " ";
      "\t";
      "\n";
      "\n";
      "\r\n";
      "\r";
      "{";
      "}";
      ",";
      "#";
      "=";
      "v1";
      "a";
      "gh/42";
      "[1]";
      "[*]";
      ":";
      "req:";
      "#*";
      "\xc2\xa0";
      "\xef\xbb\xbf";
      "3f2a9c1d";
      "/";
      "*";
      "\xe2\x80\xa8";
      "\x00";
    ]

let any_character_gen =
  Gen.map
    (fun code ->
      let buffer = Buffer.create 4 in
      Buffer.add_utf_8_uchar buffer (Uchar.of_int code);
      Buffer.contents buffer)
    (Gen.oneof
       [
         Gen.int_range 0 0x7F;
         Gen.int_range 0x80 0xD7FF;
         Gen.int_range 0xE000 0x10FFFF;
       ])

let line_text_gen =
  Gen.map concat
    (Gen.list_size (Gen.int_range 0 24)
       (Gen.oneof [ line_token_gen; line_token_gen; any_character_gen ]))

let is_citation_word word =
  List.mem word Tag_word.[ Cites; Refines; Satisfies; Supersedes; Verifies ]

let tag_word_of line =
  let length = String.length line in
  let rec skip index =
    if index < length && (line.[index] = ' ' || line.[index] = '\t') then
      skip (index + 1)
    else index
  in
  let start = skip 0 in
  if start >= length || line.[start] <> '@' then None
  else
    let rec stop index =
      if
        index < length
        &&
        match line.[index] with
        | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' -> true
        | _ -> false
      then stop (index + 1)
      else index
    in
    Some (String.sub line start (stop (start + 1) - start))

let rec substring text part from =
  if String.length part = 0 then true
  else if from + String.length part > String.length text then false
  else
    String.equal (String.sub text from (String.length part)) part
    || substring text part (from + 1)

let tag_texts = function
  | Tag_line.Declaration { slug; part_name; revision; inline_description; _ } ->
      slug :: inline_description
      :: (Option.to_list part_name @ Option.to_list revision)
  | Tag_line.Citation { entries; inline_description; _ } ->
      inline_description
      :: List.concat_map
           (function
             | Target.Internal
                 { slug; part_name; vector_selection; revision; _ } -> (
                 (revision :: Option.to_list slug)
                 @ Option.to_list part_name
                 @
                 match vector_selection with
                 | Some (Target.Vector_number text) | Some (Target.Group text)
                   ->
                     [ text ]
                 | _ -> [])
             | Target.Every_part { slug; revision } -> [ slug; revision ]
             | Target.External { namespace_name; id; part_name; _ } ->
                 namespace_name :: id :: Option.to_list part_name)
           entries
  | Tag_line.Status_tag { inline_description; _ } -> [ inline_description ]
  | Tag_line.Extern { part_name; inline_description; _ } ->
      [ part_name; inline_description ]
  | Tag_line.Ack { slug; subject; hash_prefix } ->
      [ slug; subject; hash_prefix ]

let line_invariants string =
  let text = text_of string in
  let lines = Lines.of_text text in
  let line_text number =
    match Lines.line lines number with
    | Some run -> (
        match Text.sub text run with
        | Some line -> Text.encode line
        | None -> "")
    | None -> ""
  in
  List.for_all
    (fun binding ->
      let inputs = Tag_line.read binding text in
      let rec covers next = function
        | [] -> next = Lines.count lines + 1
        | (input : Tag_line.input) :: rest ->
            input.first_line = next
            && input.last_line >= input.first_line
            && covers (input.last_line + 1) rest
      in
      covers 1 inputs
      && List.for_all
           (fun (input : Tag_line.input) ->
             let word = tag_word_of (line_text input.first_line) in
             let several = input.last_line > input.first_line in
             match (input.result, word) with
             | Tag_line.Not_a_tag_line, None -> not several
             | Tag_line.Other_tag_word have, Some want ->
                 String.equal have want
                 && Tag_word.of_string want = None
                 && not several
             | Tag_line.Invalid have, Some want ->
                 String.equal (Tag_word.to_string have) want
                 && ((not several) || is_citation_word have)
             | Tag_line.Valid tag, Some want ->
                 let have = Tag_line.tag_word tag in
                 String.equal (Tag_word.to_string have) want
                 && ((not several) || is_citation_word have)
                 && List.for_all
                      (fun part -> substring string part 0)
                      (tag_texts tag)
             | _ -> false)
           inputs)
    [ standard_binding; Binding.empty ]

let corrupted source =
  Gen.(
    source >>= fun (text, _) ->
    triple
      (int_bound (String.length text))
      (int_range 0 2)
      (one_of
         [
           "{";
           "}";
           ",";
           " ";
           "\n";
           "@";
           "=";
           "#";
           "[";
           "]";
           "*";
           "\xc3\xa9";
           ":";
         ])
    >|= fun (at, how, piece) ->
    let before = String.sub text 0 at in
    let after = String.sub text at (String.length text - at) in
    let rest =
      if after = "" then "" else String.sub after 1 (String.length after - 1)
    in
    let damaged =
      match how with
      | 0 -> before ^ piece ^ after
      | 1 -> before ^ rest
      | _ -> before ^ piece ^ rest
    in
    if String.is_valid_utf_8 damaged then damaged else text)

(* @verifies identifiers#{give-results=v1, give-tag-words=v1, give-no-results-for-non-inputs=v1} *)
let lines_make_one_input_each =
  property ~count:2000
    ~name:
      "the inputs of a text cover its lines in order, and each gives the \
       result of its tag word"
    ~print:(Printf.sprintf "%S") line_text_gen line_invariants

let damaged_tag_lines_keep_the_invariants =
  property ~count:2000
    ~name:
      "a damaged declaration or citation still gives one input for each line \
       or citation"
    ~print:(Printf.sprintf "%S")
    (Gen.oneof [ corrupted declaration_gen; corrupted citation_gen ])
    line_invariants

let vector_groups =
  [
    other_line_vectors;
    declaration_vectors;
    citation_vectors;
    status_tag_vectors;
    directive_vectors;
    continuation_line_vectors;
  ]

let tests =
  Vectors.tests "identifiers" vector_groups
  @ [
      Alcotest.test_case "tag lines give their results and values" `Quick
        line_examples;
      Alcotest.test_case "citations continue over lines" `Quick
        continuation_examples;
      Alcotest.test_case "a continued citation is one input over its lines"
        `Quick line_ranges_of_continued_citations;
      Alcotest.test_case "the binding decides which targets are external" `Quick
        one_binding_reads_each_text;
      Alcotest.test_case "the kind words and the Sinter tag words" `Quick words;
      Alcotest.test_case "the custom namespace of a slug" `Quick
        custom_namespaces;
      Alcotest.test_case "large texts are read" `Quick large_texts_are_read;
      declarations_give_their_values;
      citations_give_their_values;
      lines_make_one_input_each;
      damaged_tag_lines_keep_the_invariants;
    ]
