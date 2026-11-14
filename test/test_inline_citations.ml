(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_identifiers
open Test_identifier_patterns
open Test_identifier_lines
open Sinter_inline_citations
module Gen = QCheck2.Gen

let link_json (link : Inline_citation.link) =
  match link.result with
  | Inline_citation.Not_an_inline_citation ->
      `Assoc [ ("result", str "not an inline citation"); ("values", `Assoc []) ]
  | Inline_citation.Invalid ->
      `Assoc [ ("result", str "invalid"); ("values", `Assoc []) ]
  | Inline_citation.Valid { target; link_text } ->
      `Assoc
        [
          ("result", str "valid");
          ( "values",
            `Assoc (("link-text", str link_text) :: target_values target) );
        ]

let link_results binding string =
  List.map link_json (Inline_citation.read binding (text_of string))

let give_inline (vector : Vectors.vector) =
  let binding, text = read_input vector in
  let not_tag =
    List.for_all
      (fun (input : Tag_line.input) -> input.result = Tag_line.Not_a_tag_line)
      (Tag_line.read binding (text_of text))
  in
  let links = `Assoc [ ("links", `List (link_results binding text)) ] in
  if not_tag then `Assoc [ ("values", links) ]
  else `Assoc [ ("values", links); ("tag lines", `Bool true) ]

let give_rejected_binding (vector : Vectors.vector) =
  match Binding.make (pairs_of_json (json_member "binding" vector.input)) with
  | Error _ ->
      `Assoc
        [
          ("result", str "invalid"); ("values", `Assoc [ ("inputs", `List []) ]);
        ]
  | Ok binding ->
      let text = json_string (json_member "text" vector.input) in
      `Assoc
        [
          ("result", str "valid");
          ( "values",
            `Assoc
              [
                ( "inputs",
                  `List (line_inputs binding text @ link_results binding text)
                );
              ] );
        ]

(* @verifies identifiers[inline-citations][*]=v1 *)
let inline_citation_vectors =
  Vectors.group set ~name:"inline-citations" ~rev:"v1" give_inline

(* @verifies identifiers[rejected-bindings][*]=v1 *)
let rejected_binding_vectors =
  Vectors.group set ~name:"rejected-bindings" ~rev:"v1" give_rejected_binding

let markdown_valid ?(target = []) text =
  `Assoc
    [
      ("result", str "valid");
      ("values", `Assoc (("link-text", str text) :: target));
    ]

let docs ?(revision = "v1") text =
  markdown_valid text ~target:[ slug "docs"; rev revision ]

let invalid_link = `Assoc [ ("result", str "invalid"); ("values", `Assoc []) ]

let not_citation =
  `Assoc [ ("result", str "not an inline citation"); ("values", `Assoc []) ]

let markdown_cases =
  [
    ("1. [x](sinter:docs=v1)", [ docs "x" ]);
    ("   ## [x](sinter:docs=v1)", [ docs "x" ]);
    ("[x](sinter:docs=v1)\n===", [ docs "x" ]);
    ( "# [a](sinter:docs=v1) and [b](sinter:docs=v2)",
      [ docs "a"; docs ~revision:"v2" "b" ] );
    ("~~~\n[x](sinter:docs=v1)\n~~~", []);
    ("    [x](sinter:docs=v1)", []);
    ("<!-- [x](sinter:docs=v1) -->", []);
    ("[x\\](sinter:docs=v1)", []);
    ("[x][r]\n\n[r]: sinter:docs=v1", [ docs "x" ]);
    ("[x]\n\n[x]: <sinter:docs=v1>", [ docs "x" ]);
    ("[x]\n\n[x]: sinter:docs=v1 \"title\"", [ docs "x" ]);
    ("[x]\n\n[x]: sinter:docs\\=v1", [ docs "x" ]);
    ("[x][missing]", []);
    ("> [x][r]\n\n[r]: sinter:docs=v1", [ docs "x" ]);
    ("[x](  sinter:docs=v1  )", [ docs "x" ]);
    ("[x]()", [ not_citation ]);
    ("[x](https://example.com)", [ not_citation ]);
    ("[x](sinter)", [ not_citation ]);
    ("[a](sinter:docs=v1) [b](https://example.com)", [ docs "a"; not_citation ]);
    ("![y](https://example.com) [a](sinter:docs=v1)", [ not_citation; docs "a" ]);
    ("[![ ](x)](sinter:docs=v1)", [ invalid_link; not_citation ]);
    ("[![a](x)](sinter:docs=v1)", [ docs "![a](x)"; not_citation ]);
    ("[`x`](sinter:docs=v1)", [ docs "`x`" ]);
    ("[&amp;](sinter:docs=v1)", [ docs "&amp;" ]);
    ("[\\ ](sinter:docs=v1)", [ docs "\\ " ]);
    ("[&#32;](sinter:docs=v1)", [ invalid_link ]);
    ("[&#9;](sinter:docs=v1)", [ invalid_link ]);
    ("[&#xA0;&#x3000;](sinter:docs=v1)", [ invalid_link ]);
    ("[\xe1\xa0\x8e](sinter:docs=v1)", [ docs "\xe1\xa0\x8e" ]);
    ("[\xe2\x80\x8bx](sinter:docs=v1)", [ docs "\xe2\x80\x8bx" ]);
    ("[*the*](sinter:docs=v1)", [ docs "*the*" ]);
    ("[** **](sinter:docs=v1)", [ docs "** **" ]);
    ("[_ _](sinter:docs=v1)", [ docs "_ _" ]);
    ("[<b>x</b>](sinter:docs=v1)", [ docs "<b>x</b>" ]);
    ("[a [b] c](sinter:docs=v1)", [ docs "a [b] c" ]);
    ("[a\\]b](sinter:docs=v1)", [ docs "a\\]b" ]);
    ("[x](sinter:docs=v1\\))", [ docs ~revision:"v1)" "x" ]);
    ("<Sinter:docs=v1>", [ not_citation ]);
    ("<sinter:docs=v1>", [ docs "sinter:docs=v1" ]);
    ("<sinter:docs=*>", [ docs ~revision:"*" "sinter:docs=*" ]);
    ("- [the\n  limit](sinter:docs=v1)", [ docs "the\nlimit" ]);
    ("> > [a\n> > b](sinter:docs=v1)", [ docs "a\nb" ]);
    ("[a\n\tb](sinter:docs=v1)", [ docs "a\nb" ]);
    ("> [a\r> b](sinter:docs=v1)", [ docs "a\nb" ]);
    ("[a\r\nb](sinter:docs=v1)", [ docs "a\nb" ]);
    ("- [a\n      >b](sinter:docs=v1)", [ docs "a\n>b" ]);
    ("> [a\n>     >b](sinter:docs=v1)", [ docs "a\n>b" ]);
    ("[`a\n    >b`](sinter:docs=v1)", [ docs "`a\n>b`" ]);
    ("> [`a\n> b`](sinter:docs=v1)", [ docs "`a\nb`" ]);
    ("> [<b\n> c>x](sinter:docs=v1)", [ docs "<b\nc>x" ]);
    ("[<b\n    >x](sinter:docs=v1)", [ docs "<b\n>x" ]);
    ("[*a\n    >b*](sinter:docs=v1)", [ docs "*a\n>b*" ]);
    ("[a [b] *c*](sinter:docs=v1)", [ docs "a [b] *c*" ]);
    ("> [a\n>b](sinter:docs=v1)", [ docs "a\nb" ]);
    ("[*a\n    > b*](sinter:docs=v1)", [ docs "*a\n> b*" ]);
    ("[a <b\n    >c](sinter:docs=v1)", [ docs "a <b\n>c" ]);
    ("[a ![i](y\n) b](sinter:docs=v1)", [ docs "a ![i](y\n) b"; not_citation ]);
    ("[**a**](sinter:docs=v1)", [ docs "**a**" ]);
    ("[*&#x200B;*](sinter:docs=v1)", [ invalid_link ]);
    ("[**&#x200B;**](sinter:docs=v1)", [ invalid_link ]);
    ("[**a\n    >b**](sinter:docs=v1)", [ docs "**a\n>b**" ]);
    ("**[x](sinter:docs=v1)**", [ docs "x" ]);
    ("[x]() [a\n    >b](sinter:docs=v1)", [ not_citation; docs "a\n>b" ]);
    ( String.concat "\n" (List.init 40 (fun k -> Printf.sprintf "*w%d*" k))
      ^ "\n[x\n    >y](sinter:docs=v1)",
      [ docs "x\n>y" ] );
    ( "[x\n    >y](sinter:docs=v1)\n"
      ^ String.concat "\n" (List.init 40 (fun k -> Printf.sprintf "*w%d*" k)),
      [ docs "x\n>y" ] );
    (">\t> [a\n>\t> b](sinter:docs=v1)", [ docs "a\nb" ]);
    ("![[x](sinter:docs=v1)](u)", [ not_citation; docs "x" ]);
    ("[a\n    > b](sinter:docs=v1)", [ docs "a\n> b" ]);
    ("\xef\xbb\xbf[x](sinter:docs=v1)", [ docs "x" ]);
    ("a\xef\xbb\xbf[x](sinter:docs=v1)", [ docs "x" ]);
    ("|[x](sinter:docs=v1)|", [ docs "x" ]);
    ( "[x](sinter:req:docs=v1)",
      [ markdown_valid "x" ~target:[ kind "req"; slug "docs"; rev "v1" ] ] );
    ("[x](sinter:docs=v1 'title')", [ docs "x" ]);
    ( "[x](sinter:a/b#c=*)",
      [ markdown_valid "x" ~target:[ slug "a/b"; ns "a"; part "c"; rev "*" ] ]
    );
    ( "[x](sinter:rfc/8259#s)",
      [ markdown_valid "x" ~target:(ext "rfc" "8259" @ [ part "s" ]) ] );
    ("[x](sinter:gh/0)", [ invalid_link ]);
    ("[x](sinter:req:)", [ invalid_link ]);
  ]

(* @verifies identifiers#{give-results=v1, give-values=v1} *)
let markdown_examples =
  check_cases "the text"
    (fun string -> `List (link_results standard_binding string))
    markdown_cases

let blank_characters =
  [
    "\t";
    "\n";
    "\x0c";
    " ";
    "\xc2\xa0";
    "\xe1\x9a\x80";
    "\xe2\x80\x80";
    "\xe2\x80\x81";
    "\xe2\x80\x82";
    "\xe2\x80\x83";
    "\xe2\x80\x84";
    "\xe2\x80\x85";
    "\xe2\x80\x86";
    "\xe2\x80\x87";
    "\xe2\x80\x88";
    "\xe2\x80\x89";
    "\xe2\x80\x8a";
    "\xe2\x80\xaf";
    "\xe2\x81\x9f";
    "\xe3\x80\x80";
    "\xe2\x80\x8b";
    "\xe2\x80\x8c";
    "\xe2\x80\x8d";
    "\xe2\x81\xa0";
    "\xef\xbb\xbf";
  ]

let reference character =
  let code = Uchar.to_int (List.hd (uchars_of_string character)) in
  Printf.sprintf "&#x%X;" code

(* @verifies identifiers#reject-blank-link-text=v1 *)
let blank_link_text_is_invalid () =
  List.iter
    (fun character ->
      let markdown =
        Printf.sprintf "[%s](sinter:docs=v1)" (reference character)
      in
      check_json markdown (`List [ invalid_link ])
        (`List (link_results standard_binding markdown));
      let markdown =
        Printf.sprintf "[%sx%s](sinter:docs=v1)" (reference character)
          (reference character)
      in
      check_json markdown
        (`List
           [
             docs
               (Printf.sprintf "%sx%s" (reference character)
                  (reference character));
           ])
        (`List (link_results standard_binding markdown)))
    blank_characters

(* @verifies identifiers#accept-inputs=v1 *)
let other_characters_are_not_blank () =
  List.iter
    (fun code ->
      let markdown = Printf.sprintf "[&#x%X;](sinter:docs=v1)" code in
      check_json markdown
        (`List [ docs (Printf.sprintf "&#x%X;" code) ])
        (`List (link_results standard_binding markdown)))
    [
      0x0B;
      0x85;
      0x08;
      0x0E;
      0x1F;
      0x21;
      0x9F;
      0xA1;
      0x167F;
      0x1681;
      0x1FFF;
      0x202E;
      0x2030;
      0x205E;
      0x2FFF;
      0x3001;
      0xFEFE;
      0x200E;
      0x2029;
      0x2062;
      0xFFFD;
      0x1F600;
    ]

let link_runs_cover_the_link_in_the_text () =
  let runs string =
    List.map
      (fun (link : Inline_citation.link) -> (link.run.from, link.run.until))
      (Inline_citation.read standard_binding (text_of string))
  in
  Alcotest.(check (list (pair int int)))
    "an inline link"
    [ (0, 19) ]
    (runs "[x](sinter:docs=v1)");
  Alcotest.(check (list (pair int int)))
    "after a byte order mark and wide characters"
    [ (4, 23) ]
    (runs "\xef\xbb\xbf\xc3\xa9\xf0\x9f\x98\x80 [x](sinter:docs=v1)");
  Alcotest.(check (list (pair int int)))
    "an image, a link, and an autolink in link text"
    [ (0, 11); (12, 51); (13, 34) ]
    (runs "![y](https) [<https://example.com>](sinter:docs=v1)");
  Alcotest.(check (list (pair int int)))
    "a reference link"
    [ (0, 6) ]
    (runs "[x][r]\n\n[r]: sinter:docs=v1");
  Alcotest.(check (list (pair int int)))
    "a reference link with an image over two lines in its link text"
    [ (0, 17); (3, 11) ]
    (runs "[a ![i](y\n) b][r]\n\n[r]: sinter:docs=v1");
  Alcotest.(check (list (pair int int)))
    "after a U+0000 and with one inside"
    [ (1, 21) ]
    (runs "\x00[\x00x](sinter:docs=v1)");
  Alcotest.(check (list (pair int int)))
    "on the second line after a byte order mark"
    [ (4, 23) ]
    (runs "\xef\xbb\xbfa\r\n[x](sinter:docs=v1)");
  Alcotest.(check (list (pair int int)))
    "a link over two lines in a block quote"
    [ (2, 26) ]
    (runs "> [a\r\n> b](sinter:docs=v1)")

(* @verifies identifiers#use-one-binding=v1 *)
let inline_targets_read_their_values () =
  let read binding target =
    match Inline_target.read binding target with
    | Some target -> `Assoc (target_values target)
    | None -> `Null
  in
  List.iter
    (fun (binding, target, want) ->
      check_json target want (read binding target))
    [
      ( standard_binding,
        "req:packs#size=v2",
        `Assoc [ kind "req"; slug "packs"; part "size"; rev "v2" ] );
      (standard_binding, "a/b=*", `Assoc [ slug "a/b"; ns "a"; rev "*" ]);
      (standard_binding, "#size=v1", `Assoc [ part "size"; rev "v1" ]);
      ( standard_binding,
        "spec:rfc/8259#s",
        `Assoc ((kind "spec" :: ext "rfc" "8259") @ [ part "s" ]) );
      (standard_binding, "gh/42=v1", `Null);
      (standard_binding, "gh/0", `Null);
      (Binding.empty, "gh/42=v1", `Assoc [ slug "gh/42"; ns "gh"; rev "v1" ]);
      (standard_binding, "docs[12]=v1", `Null);
      (standard_binding, "docs=v1#*", `Null);
      (standard_binding, "{docs=v1}", `Null);
      (standard_binding, "docs#{a=v1}", `Null);
      (standard_binding, "docs", `Null);
      (standard_binding, "", `Null);
      (standard_binding, "sinter:docs=v1", `Null);
    ]

let one_binding_reads_each_link () =
  let jira =
    match Binding.make [ ("jira", "[A-Z]+-[1-9][0-9]*") ] with
    | Ok binding -> binding
    | Error _ -> Alcotest.fail "the binding is valid"
  in
  check_json "an inline citation under the empty binding"
    (`List [ markdown_valid "x" ~target:[ slug "gh/42"; ns "gh"; rev "v2" ] ])
    (`List (link_results Binding.empty "[x](sinter:gh/42=v2)"));
  check_json "an inline citation under the jira binding"
    (`List [ markdown_valid "x" ~target:(ext "jira" "A-1") ])
    (`List (link_results jira "[x](sinter:jira/A-1)"))

let large_documents_are_read () =
  let nested depth =
    String.make depth '[' ^ "x" ^ String.make depth ']' ^ "(sinter:docs=v1)"
  in
  List.iter
    (fun depth ->
      check_json
        (Printf.sprintf "%d nested brackets" depth)
        (`List
           [
             docs
               (String.make (depth - 1) '[' ^ "x" ^ String.make (depth - 1) ']');
           ])
        (`List (link_results standard_binding (nested depth))))
    [ 1; 2; 8; 14 ];
  let quotes = String.make 5000 '>' ^ " [x](sinter:docs=v1)" in
  Alcotest.(check int)
    "one link in deep block quotes" 1
    (List.length (Inline_citation.read standard_binding (text_of quotes)));
  let many =
    String.concat " " (List.init 20000 (fun _ -> "[x](sinter:docs=v1)"))
  in
  Alcotest.(check int)
    "many links" 20000
    (List.length (Inline_citation.read standard_binding (text_of many)));
  let stars = String.concat "" (List.init 20000 (fun _ -> "*a_ ")) in
  Alcotest.(check int)
    "no link in unmatched emphasis" 0
    (List.length (Inline_citation.read standard_binding (text_of stars)))

let line_texts_hold_no_link () =
  List.iter
    (fun group ->
      List.iter
        (fun (vector : Vectors.vector) ->
          let binding, text = read_input vector in
          Alcotest.(check int)
            (Printf.sprintf "the links of vector %d" vector.number)
            0
            (List.length (Inline_citation.read binding (text_of text))))
        (Vectors.vectors set group))
    [
      "other-lines";
      "declarations";
      "citations";
      "status-tags";
      "directives";
      "continuation-lines";
    ]

let inline_gen =
  let open Gen in
  let* target, values =
    single_gen { selections = false; star = true; every_part = false } 0
  in
  let* label = one_of [ "x"; "the limit"; "*a*"; "`b`"; "a\nb"; "\xc3\xa9" ] in
  let* form = int_range 0 2 in
  let* escape = bool in
  let punctuation = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" in
  let escaped =
    concat
      (List.map
         (fun c ->
           if
             (escape || String.contains "()<>\\" c)
             && String.contains punctuation c
           then "\\" ^ String.make 1 c
           else String.make 1 c)
         (List.of_seq (String.to_seq target)))
  in
  let form =
    if form = 2 && (String.contains target '<' || String.contains target '>')
    then 0
    else form
  in
  let destination = "sinter:" ^ target in
  let link_text = label in
  let markdown, link_text =
    match form with
    | 0 -> (Printf.sprintf "[%s](sinter:%s)" label escaped, link_text)
    | 1 -> (Printf.sprintf "[%s][r]\n\n[r]: sinter:%s" label escaped, link_text)
    | _ -> (Printf.sprintf "<%s>" destination, destination)
  in
  return
    ( markdown,
      [
        `Assoc
          [
            ("result", str "valid");
            ("values", `Assoc (("link-text", str link_text) :: values));
          ];
      ] )

let read_links text = `List (link_results standard_binding text)

(* @verifies identifiers#{give-values=v1, accept-inputs=v1} *)
let inline_citations_give_their_values =
  property ~count:300
    ~name:"an inline citation made from the grammar gives its values"
    ~print:print_case inline_gen (same read_links)

let markdown_token_gen =
  one_of
    [
      "[";
      "]";
      "(";
      ")";
      "<";
      ">";
      "!";
      "*";
      "_";
      "`";
      "\\";
      "\n";
      "\r";
      " ";
      "  ";
      "sinter:";
      "docs=v1";
      "gh/42";
      "#";
      "=";
      "&amp;";
      "&#35;";
      "\x00";
      "\xef\xbb\xbf";
      "> ";
      "- ";
      "# ";
      "    ";
      "https://e";
      "x";
      ":";
      "\"t\"";
      "[r]: ";
      "[r]";
      "\xc2\xa0";
      "```";
      "<!--";
      "-->";
    ]

let markdown_gen =
  Gen.map concat
    (Gen.list_size (Gen.int_range 0 30)
       (Gen.oneof [ markdown_token_gen; markdown_token_gen; any_character_gen ]))

let link_invariants string =
  let text = text_of string in
  let body = Text.body text in
  let links = Inline_citation.read standard_binding text in
  let rec ordered = function
    | (a : Inline_citation.link) :: (b :: _ as rest) ->
        a.run.from <= b.run.from && ordered rest
    | _ -> true
  in
  ordered links
  && List.for_all
       (fun (link : Inline_citation.link) ->
         link.run.from >= body.from
         && (match Text.sub text link.run with
           | None -> false
           | Some run ->
               let source = Text.encode run in
               let length = String.length source in
               length >= 2
               && List.mem source.[0] [ '['; '!'; '<' ]
               && List.mem source.[length - 1] [ ')'; ']'; '>' ])
         &&
         match link.result with
         | Inline_citation.Valid { target = Target.Every_part _; _ } -> false
         | Inline_citation.Valid
             { target = Target.Internal { vector_selection = Some _; _ }; _ } ->
             false
         | _ -> true)
       links

let links_cover_runs_in_order =
  property ~count:2000
    ~name:
      "each link of a markdown document covers a run of its text, in the order \
       of their starts"
    ~print:(Printf.sprintf "%S") markdown_gen link_invariants

let damaged_links_keep_the_invariants =
  property ~count:1000
    ~name:"a damaged inline citation still gives links that cover runs in order"
    ~print:(Printf.sprintf "%S") (corrupted inline_gen) link_invariants

let vector_groups = [ inline_citation_vectors; rejected_binding_vectors ]

let tests =
  Vectors.tests "identifiers" vector_groups
  @ [
      Vectors.covers "identifiers" set
        (Test_identifier_patterns.vector_groups
       @ Test_identifier_lines.vector_groups @ vector_groups);
      Alcotest.test_case "the texts of the line vectors hold no link" `Quick
        line_texts_hold_no_link;
      Alcotest.test_case "links in CommonMark blocks and inlines" `Quick
        markdown_examples;
      Alcotest.test_case "blank link text is invalid" `Quick
        blank_link_text_is_invalid;
      Alcotest.test_case "other characters are not blank" `Quick
        other_characters_are_not_blank;
      Alcotest.test_case "the run of a link covers it in the text" `Quick
        link_runs_cover_the_link_in_the_text;
      Alcotest.test_case "an inline target gives its values" `Quick
        inline_targets_read_their_values;
      Alcotest.test_case "the binding decides which link targets are external"
        `Quick one_binding_reads_each_link;
      Alcotest.test_case "large documents are read" `Quick
        large_documents_are_read;
      inline_citations_give_their_values;
      links_cover_runs_in_order;
      damaged_links_keep_the_invariants;
    ]
