(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_origins
open Sinter_markdown_tag_texts
module Gen = QCheck2.Gen
module Reference = Documents_reference

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let encode text run =
  match Text.sub text run with
  | Some sub -> Text.encode sub
  | None -> invalid_arg "encode"

let read string = Markdown_file.read (Lines.of_text (text_of string))

let line_pieces =
  [
    "# A";
    "## B";
    "   ### C ###";
    "#A";
    "#";
    "####### G";
    "@req a=v1";
    "@design d=v1";
    "@cites {a=v1,";
    "  b=v1}";
    "Text.";
    "";
    "  ";
    "\t";
    "- @req l=v1";
    "- [x] @req b=v1";
    "- [X]\t@req c=v1";
    "- [ ] x";
    "- [y] z";
    "-";
    "  - @req n=v1";
    "    - deep";
    "  more";
    "1. one";
    "2) two";
    "* star";
    "> q";
    "> - y";
    ">";
    "    code";
    "```";
    "~~~";
    "---";
    "+++";
    "--- \t";
    "===";
    "***";
    "- - -";
    "[x]: /u";
    "[x]: /u 'title";
    "<div>";
    "</div>";
    "<!-- c";
    "-->";
    "\t@req t=v1";
    "[a](sinter:a)";
    "<sinter:a>";
    "\xc3\xa9 \xf0\x9f\x98\x80";
    "|a|b|";
    "*@req e=v1*";
  ]

let endings = [ "\n"; "\r\n"; "\r" ]

let markdown_gen =
  Gen.map3
    (fun bom lines last ->
      let body =
        String.concat "" (List.map (fun (line, ending) -> line ^ ending) lines)
        ^ last
      in
      if bom then "\xef\xbb\xbf" ^ body else body)
    (Gen.oneof_weighted [ (1, Gen.pure true); (5, Gen.pure false) ])
    (Gen.list_size (Gen.int_range 0 14)
       (Gen.pair (Gen.oneof_list line_pieces) (Gen.oneof_list endings)))
    (Gen.oneof_list [ ""; "Text."; "@req z=v1"; "\r" ])

let print = Printf.sprintf "%S"

let vector_files =
  let set = Vectors.read "documents" in
  List.concat_map
    (fun group ->
      List.concat_map
        (fun (vector : Vectors.vector) ->
          match vector.input with
          | `Assoc fields -> (
              match List.assoc_opt "files" fields with
              | Some (`Assoc files) ->
                  List.filter_map
                    (fun (_, value) ->
                      match value with
                      | `String content -> Some content
                      | _ -> None)
                    files
              | _ -> [])
          | _ -> [])
        (Vectors.vectors set group))
    [ "markdown"; "code" ]

let markdown_lines_follow_the_term =
  property ~count:2000 ~name:"the markdown lines are those of the term" ~print
    markdown_gen (fun file ->
      let text = text_of file in
      Markdown_lines.of_text text = Reference.markdown_lines text)

let number_of lines run =
  let rec find k = function
    | [] -> invalid_arg "number_of"
    | line :: rest -> if line = run then k else find (k + 1) rest
  in
  find 1 lines

let front_matter_follows_the_term =
  property ~count:2000
    ~name:"the front matter and the markdown run are those of the term" ~print
    (Gen.oneof
       [
         markdown_gen;
         Gen.map2
           (fun open_ rest -> open_ ^ rest)
           (Gen.oneof_list
              [ "---\n"; "+++\r\n"; "--- \t\r"; "---"; "\xef\xbb\xbf+++\n" ])
           markdown_gen;
       ])
    (fun file ->
      let text = text_of file in
      let markdown = Markdown_file.read (Lines.of_text text) in
      let lines = Reference.markdown_lines text in
      let expected =
        Option.map
          (fun runs ->
            {
              Markdown_file.first = number_of lines (List.hd runs);
              last = number_of lines (List.nth runs (List.length runs - 1));
            })
          (Reference.front_matter text)
      in
      let run = Reference.markdown_run text in
      let text_lines = Reference.markdown_text_lines text in
      Markdown_file.lines markdown = lines
      && Markdown_file.front_matter markdown = expected
      && Markdown_file.markdown_run markdown = run
      && Markdown_file.first_markdown_text_line markdown
         =
         match text_lines with
         | [] -> List.length lines + 1
         | first :: _ -> number_of lines first)

let markdown_text_comes_from_the_markdown_run =
  property
    ~name:
      "the k-th character of the markdown text comes from the k-th place of \
       the markdown run" ~print markdown_gen (fun file ->
      let text = text_of file in
      let markdown = Markdown_file.read (Lines.of_text text) in
      let run = Reference.markdown_run text in
      let source = Markdown_file.markdown_text markdown in
      let length = run.Text.until - run.Text.from in
      Text.encode (Source.text source) = encode text run
      && List.init length (fun k -> Source.place source (k + 1))
         = List.init length (fun k -> Some (run.Text.from + k + 1)))

let is_wsp c = c = ' ' || c = '\t'

let line_text markdown k =
  let text = Lines.text (Source.file (Markdown_file.markdown_text markdown)) in
  encode text (List.nth (Markdown_file.lines markdown) (k - 1))

let opens_atx line level =
  let n = String.length line in
  let rec spaces i =
    if i < n && i < 3 && line.[i] = ' ' then spaces (i + 1) else i
  in
  let i = spaces 0 in
  let rec hashes j = if j < n && line.[j] = '#' then hashes (j + 1) else j in
  let j = hashes i in
  j - i = level && (j = n || is_wsp line.[j])

let setext_underline line char =
  let n = String.length line in
  let rec spaces i =
    if i < n && i < 3 && line.[i] = ' ' then spaces (i + 1) else i
  in
  let i = spaces 0 in
  let rec marks j = if j < n && line.[j] = char then marks (j + 1) else j in
  let j = marks i in
  let rec rest k = k = n || (is_wsp line.[k] && rest (k + 1)) in
  j > i && rest j

let is_blank_text line = String.for_all is_wsp line

let opens_setext markdown (h : Markdown_file.heading) =
  let count = List.length (Markdown_file.lines markdown) in
  let char =
    if h.level = 1 then Some '=' else if h.level = 2 then Some '-' else None
  in
  let rec underline k =
    k <= count
    &&
    let line = line_text markdown k in
    match char with
    | Some c when setext_underline line c -> true
    | _ -> (not (is_blank_text line)) && underline (k + 1)
  in
  char <> None
  && (not (is_blank_text (line_text markdown h.line)))
  && underline (h.line + 1)

let range_ok markdown { Markdown_file.first; last } =
  1 <= first && first <= last
  && last <= List.length (Markdown_file.lines markdown)

let section_ranges markdown =
  let count = List.length (Markdown_file.lines markdown) in
  let start = Markdown_file.first_markdown_text_line markdown in
  let headings =
    List.filter_map
      (fun (section : Markdown_file.section) -> section.heading)
      (Markdown_file.sections markdown)
  in
  let level0 =
    let last =
      match headings with
      | [] -> count
      | first :: _ -> first.Markdown_file.line - 1
    in
    if last >= start then Some { Markdown_file.first = start; last } else None
  in
  let rec of_headings = function
    | [] -> []
    | (h : Markdown_file.heading) :: rest ->
        let last =
          match
            List.find_opt
              (fun (n : Markdown_file.heading) -> n.level <= h.level)
              rest
          with
          | Some next -> next.line - 1
          | None -> count
        in
        Some { Markdown_file.first = h.line; last } :: of_headings rest
  in
  level0 :: of_headings headings

let rec increasing = function
  | a :: (b :: _ as rest) -> a < b && increasing rest
  | _ -> true

let sections_follow_their_headings markdown =
  let sections = Markdown_file.sections markdown in
  let start = Markdown_file.first_markdown_text_line markdown in
  match sections with
  | [] -> false
  | level0 :: headed ->
      level0.heading = None
      && List.for_all
           (fun (s : Markdown_file.section) -> s.heading <> None)
           headed
      && List.for_all
           (fun (s : Markdown_file.section) ->
             match s.heading with
             | None -> false
             | Some h ->
                 h.line >= start && 1 <= h.level && h.level <= 6
                 && (opens_atx (line_text markdown h.line) h.level
                    || opens_setext markdown h))
           headed
      && increasing
           (List.filter_map
              (fun (s : Markdown_file.section) ->
                Option.map (fun (h : Markdown_file.heading) -> h.line) s.heading)
              headed)
      && List.map (fun (s : Markdown_file.section) -> s.lines) sections
         = section_ranges markdown

let text_of_file markdown =
  Lines.text (Source.file (Markdown_file.markdown_text markdown))

let paragraph_lines_follow_the_term ~list_item markdown
    (paragraph : Markdown_file.paragraph) =
  let text = text_of_file markdown in
  let lines = Array.of_list (Markdown_file.lines markdown) in
  let joined = Array.of_list (Tag_text.joined paragraph.tag_text) in
  let { Markdown_file.first; last } = paragraph.lines in
  let first_line_ok line run =
    let before = { Text.from = line.Text.from; until = run.Text.from } in
    let own = encode text run in
    run.Text.until = line.Text.until
    && run.Text.from >= line.Text.from
    && (list_item || Reference.is_blank text before)
    && ((list_item && own = "") || (own <> "" && not (is_wsp own.[0])))
  in
  range_ok markdown paragraph.lines
  && Array.length joined = last - first + 1
  && List.for_all
       (fun k ->
         let line = lines.(first + k - 1) in
         let run = joined.(k) in
         (not (Reference.is_blank text line))
         && if k = 0 then first_line_ok line run else run = line)
       (List.init (last - first + 1) Fun.id)

let within (outer : Markdown_file.range) (inner : Markdown_file.range) =
  outer.first <= inner.first && inner.last <= outer.last

let first_paragraphs_lie_in_their_parts markdown =
  let start = Markdown_file.first_markdown_text_line markdown in
  List.for_all
    (fun (s : Markdown_file.section) ->
      match (s.first_paragraph, s.lines) with
      | None, _ -> true
      | Some _, None -> false
      | Some p, Some lines ->
          within lines p.lines
          && (match s.heading with
            | Some h -> p.lines.first > h.line
            | None -> p.lines.first >= start)
          && paragraph_lines_follow_the_term ~list_item:false markdown p)
    (Markdown_file.sections markdown)
  && List.for_all
       (fun (item : Markdown_file.list_item) ->
         range_ok markdown item.lines
         && item.lines.first >= start
         &&
         match item.first_paragraph with
         | None -> true
         | Some p ->
             within item.lines p.lines
             && paragraph_lines_follow_the_term ~list_item:true markdown p)
       (Markdown_file.list_items markdown)

let list_items_in_order markdown =
  let firsts =
    List.map
      (fun (item : Markdown_file.list_item) -> item.lines.first)
      (Markdown_file.list_items markdown)
  in
  List.sort compare firsts = firsts

let tag_texts_are_the_first_paragraphs markdown =
  let paragraphs =
    List.filter_map
      (fun (s : Markdown_file.section) -> s.first_paragraph)
      (Markdown_file.sections markdown)
    @ List.filter_map
        (fun (item : Markdown_file.list_item) -> item.first_paragraph)
        (Markdown_file.list_items markdown)
  in
  let expected =
    List.map
      (fun (p : Markdown_file.paragraph) -> Tag_text.joined p.tag_text)
      (List.sort
         (fun (a : Markdown_file.paragraph) b ->
           compare a.lines.first b.lines.first)
         paragraphs)
  in
  List.map Tag_text.joined (Markdown_file.tag_texts markdown) = expected

let lf = Uchar.of_int 0x0A

let origins_are_the_places_of_the_characters markdown =
  let text = text_of_file markdown in
  List.for_all
    (fun tag_text ->
      let source = Tag_text.source tag_text in
      let own = Tag_text.text tag_text in
      let joined = Tag_text.joined tag_text in
      let separators =
        let rec go at = function
          | [] | [ _ ] -> []
          | run :: rest ->
              let k = at + (run.Text.until - run.Text.from) + 1 in
              k :: go k rest
        in
        go 0 joined
      in
      let places =
        List.init (Text.length own) (fun k ->
            (k + 1, Source.place source (k + 1)))
      in
      List.for_all
        (fun (k, place) ->
          match place with
          | None -> List.mem k separators && Text.get own k = Some lf
          | Some p ->
              (not (List.mem k separators)) && Text.get text p = Text.get own k)
        places
      && increasing (List.filter_map snd places))
    (Markdown_file.tag_texts markdown)

let file_lines_are_the_markdown_lines markdown =
  let lines = Array.of_list (Markdown_file.lines markdown) in
  let file_lines = Markdown_file.file_lines markdown in
  let paragraphs =
    List.filter_map
      (fun (s : Markdown_file.section) -> s.first_paragraph)
      (Markdown_file.sections markdown)
    @ List.filter_map
        (fun (item : Markdown_file.list_item) -> item.first_paragraph)
        (Markdown_file.list_items markdown)
  in
  File_lines.all file_lines = Array.to_list lines
  && List.for_all
       (fun (p : Markdown_file.paragraph) ->
         List.for_all
           (fun k ->
             File_lines.of_tag_text_line file_lines p.tag_text k
             = Some lines.(p.lines.first + k - 2))
           (List.init (Tag_text.line_count p.tag_text) (fun k -> k + 1)))
       paragraphs

let structure_holds file =
  let markdown = read file in
  sections_follow_their_headings markdown
  && first_paragraphs_lie_in_their_parts markdown
  && list_items_in_order markdown
  && tag_texts_are_the_first_paragraphs markdown
  && origins_are_the_places_of_the_characters markdown
  && file_lines_are_the_markdown_lines markdown

let structure_holds_for_generated_files =
  property ~count:3000
    ~name:
      "sections, list items, paragraph lines, tag texts, and origins keep the \
       terms"
    ~print markdown_gen structure_holds

let structure_holds_for_the_vector_files () =
  List.iter
    (fun file ->
      if Result.is_ok (Text.decode file) then
        Alcotest.(check bool)
          (Printf.sprintf "the file %S" file)
          true (structure_holds file))
    vector_files

let tag_lines file =
  let markdown = read file in
  let text = text_of_file markdown in
  List.map
    (fun tag_text -> List.map (encode text) (Tag_text.joined tag_text))
    (Markdown_file.tag_texts markdown)

let headings file =
  List.filter_map
    (fun (s : Markdown_file.section) ->
      Option.map
        (fun (h : Markdown_file.heading) -> (h.line, h.level))
        s.heading)
    (Markdown_file.sections (read file))

let check_tag_texts name file expected () =
  Alcotest.(check (list (list string))) name expected (tag_lines file)

let billing =
  "# Billing\n\
   @design billing=v4\n\
   Specifies the invoices that a billing service sends.\n\n\
   ## 1. Invoices\n\
   @spec invoice=v2\n\
   An invoice asks a customer to pay a sum of money.\n\n\
   ### 1.1 Amount limit\n\
   @req limit-amount=v2\n\
   A conforming program must reject an invoice whose amount is more than \
   10,000 euros.\n"

let cases =
  [
    ( "the example of the design has three tag texts",
      billing,
      [
        [
          "@design billing=v4";
          "Specifies the invoices that a billing service sends.";
        ];
        [
          "@spec invoice=v2";
          "An invoice asks a customer to pay a sum of money.";
        ];
        [
          "@req limit-amount=v2";
          "A conforming program must reject an invoice whose amount is more \
           than 10,000 euros.";
        ];
      ] );
    ( "the first paragraph of the section of level 0 is the first block",
      "@design top=v1\nIntro.\n\n# Part\nMore.\n",
      [ [ "@design top=v1"; "Intro." ]; [ "More." ] ] );
    ("a setext heading is no paragraph", "# A\n@req r=v1\nText.\n---\n", []);
    ("a setext heading of = is no paragraph", "# A\n@req r=v1\n===\n", []);
    ("an indented code block is no paragraph", "# A\n    @req r=v1\n", []);
    ( "a fenced code block is no paragraph",
      "# A\n```\n@req r=v1\n```\nText.\n",
      [] );
    ("an HTML block is no paragraph", "# A\n<div>\n@req r=v1\n</div>\n", []);
    ("a link reference definition is a block", "# A\n[x]: /u\n@req r=v1\n", []);
    ("a block quote is no paragraph", "# A\n> @req r=v1\n", []);
    ("a list item in a block quote is no list item", "> - @req a=v1\n", []);
    ( "the other lines of a paragraph of a list item are whole markdown lines",
      "- @req a=v1\n  Text.\n",
      [ [ "@req a=v1"; "  Text." ] ] );
    ( "a lazy line is a line of the paragraph",
      "- @req a=v1\nlazy\n",
      [ [ "@req a=v1"; "lazy" ] ] );
    ( "a task marker leaves the first line",
      "- [x] @req b=v1\n",
      [ [ "@req b=v1" ] ] );
    ( "a task marker takes all its spaces",
      "- [X]  @req b=v1\n",
      [ [ "@req b=v1" ] ] );
    ("a task marker takes a tab", "- [ ]\t@req b=v1\n", [ [ "@req b=v1" ] ]);
    ("a y is no task marker", "- [y] a\n", [ [ "[y] a" ] ]);
    ( "a task marker needs a space or a tab after it",
      "- [x]@req\n",
      [ [ "[x]@req" ] ] );
    ( "only one task marker leaves the first line",
      "- [x] [ ] a\n",
      [ [ "[ ] a" ] ] );
    ( "each list item at each depth gives a tag text",
      "- a\n  - @req b=v1\n",
      [ [ "a" ]; [ "@req b=v1" ] ] );
    ( "a list item can start with a blank line",
      "-\n  @req a=v1\n",
      [ [ "@req a=v1" ] ] );
    ( "a second paragraph of a list item gives no tag text",
      "- a\n\n  @req b=v1\n",
      [ [ "a" ] ] );
    ("a heading in a list item is no paragraph", "- # B\n  @req r=v1\n", []);
    ( "two ordered lists give two list items",
      "1. @req a=v1\n2) @req b=v1\n",
      [ [ "@req a=v1" ]; [ "@req b=v1" ] ] );
    ( "a section with a paragraph and a list gives two tag texts",
      "# A\nIntro.\n\n- @req a=v1\n",
      [ [ "Intro." ]; [ "@req a=v1" ] ] );
    ( "a lazy line of a second list item",
      "- a\n- b\nc\n",
      [ [ "a" ]; [ "b"; "c" ] ] );
    ( "a # with no space opens no heading",
      "#A\n@req a=v1\n",
      [ [ "#A"; "@req a=v1" ] ] );
    ( "the first line starts after the indentation",
      "# A\n   @req r=v1\n",
      [ [ "@req r=v1" ] ] );
    ( "an indented line continues a paragraph",
      "# A\nText\n    @req a=v1\n",
      [ [ "Text"; "    @req a=v1" ] ] );
    ( "a carriage return and a line feed end a line",
      "# A\r\n@req a=v1\r\nText.\r\n",
      [ [ "@req a=v1"; "Text." ] ] );
    ( "a lone carriage return ends a line",
      "# A\r@req a=v1\rText.\r",
      [ [ "@req a=v1"; "Text." ] ] );
    ( "a byte order mark is on no line",
      "\xef\xbb\xbf# A\n@req a=v1\n",
      [ [ "@req a=v1" ] ] );
    ( "front matter of --- is no block",
      "---\ntitle: x\n---\n@design a=v1\n",
      [ [ "@design a=v1" ] ] );
    ( "front matter of +++ is no block",
      "+++\na = 1\n+++\n# A\nText.\n",
      [ [ "Text." ] ] );
    ( "a front-matter line can end with spaces and tabs",
      "---  \t\nx\n--- \n@design a=v1\n",
      [ [ "@design a=v1" ] ] );
    ( "front matter needs the same three characters",
      "---\nx\n+++\n@design a=v1\n",
      [] );
    ("four - make no front-matter line", "----\nx\n----\n", []);
    ("a space before --- makes no front-matter line", " ---\nx\n---\n", []);
    ( "front matter can follow a byte order mark",
      "\xef\xbb\xbf---\nx\n---\nA\n",
      [ [ "A" ] ] );
    ( "front matter can end lines with lone carriage returns",
      "---\rx\r---\rA",
      [ [ "A" ] ] );
    ("front matter can be the whole file", "---\nx\n---", []);
    ("a heading in a block quote opens no section", "> # B\n@req a=v1\n", []);
    ( "the first paragraph after a setext heading is a tag text",
      "Title\n=====\n@req a=v1\nText.\n",
      [ [ "@req a=v1"; "Text." ] ] );
    ( "a setext heading is no first paragraph of the section of level 0",
      "@design s=v1\n---\nText.\n",
      [ [ "Text." ] ] );
    ("a heading ends a paragraph", "# A\n@req a=v1\n# B\n", [ [ "@req a=v1" ] ]);
    ( "a heading can be indented and closed",
      "   ## B ##\nText.\n",
      [ [ "Text." ] ] );
    ("seven # open no heading", "####### X\n", [ [ "####### X" ] ]);
    ("an empty heading opens a section", "#\nText.\n", [ [ "Text." ] ]);
    ("a lazy line belongs to a block quote", "> a\nb\n", []);
    ("a thematic break ends a paragraph", "# A\nText\n***\n", [ [ "Text" ] ]);
    ( "- - - is a thematic break and no setext underline",
      "# A\nText\n- - -\n",
      [ [ "Text" ] ] );
    ( "a tag text keeps the characters of inlines",
      "# A\n*@req a=v1*\n",
      [ [ "*@req a=v1*" ] ] );
    ( "a code block in a list item is no paragraph",
      "- ```\n  @req a=v1\n  ```\n",
      [] );
    ( "four spaces after a list marker are its own",
      "-    @req a=v1\n",
      [ [ "@req a=v1" ] ] );
    ( "five spaces after a list marker start a code block",
      "-     @req a=v1\n",
      [] );
    ( "a task marker can leave an empty first line",
      "- [x] \n  @req a=v1\n",
      [ [ ""; "  @req a=v1" ] ] );
    ( "a task marker at the end of a line needs a space or a tab",
      "- [x]\n",
      [ [ "[x]" ] ] );
    ( "a section has no task marker",
      "# A\n[x] @req a=v1\n",
      [ [ "[x] @req a=v1" ] ] );
  ]

let case_tests =
  List.map
    (fun (name, file, expected) ->
      Alcotest.test_case name `Quick (check_tag_texts name file expected))
    cases

let first_line_starts_at_the_content () =
  match Markdown_file.tag_texts (read "# A\n   @req r=v1\n") with
  | [ tag_text ] ->
      Alcotest.(check bool)
        "the run of the first line" true
        (Tag_text.joined tag_text = [ { Text.from = 7; until = 16 } ])
  | _ -> Alcotest.fail "one tag text"

let sections_of_nested_headings () =
  let markdown = read "# A\n## B\n### C\n# D\n" in
  Alcotest.(check (list (pair int int)))
    "the headings"
    [ (1, 1); (2, 2); (3, 3); (4, 1) ]
    (headings "# A\n## B\n### C\n# D\n");
  Alcotest.(check bool)
    "the lines of the sections" true
    (List.map
       (fun (s : Markdown_file.section) -> s.lines)
       (Markdown_file.sections markdown)
    = [
        None;
        Some { Markdown_file.first = 1; last = 3 };
        Some { first = 2; last = 3 };
        Some { first = 3; last = 3 };
        Some { first = 4; last = 4 };
      ])

let section_lines file =
  List.map
    (fun (s : Markdown_file.section) ->
      Option.map (fun { Markdown_file.first; last } -> (first, last)) s.lines)
    (Markdown_file.sections (read file))

let setext_cases =
  [
    ( "an underline of = gives level 1",
      "Title\n=====\nText.\n",
      [ (1, 1) ],
      [ None; Some (1, 3) ] );
    ( "an underline of - gives level 2",
      "Intro.\n\nTitle\n---\nText.\n",
      [ (3, 2) ],
      [ Some (1, 2); Some (3, 5) ] );
    ( "a heading of two lines opens its section at its first line",
      "# A\nB\nC\n---\nD\n",
      [ (1, 1); (2, 2) ],
      [ None; Some (1, 5); Some (2, 5) ] );
    ( "a setext heading of level 2 ends a section of level 3",
      "### A\nx\n\nB\n---\n#### C\n",
      [ (1, 3); (4, 2); (6, 4) ],
      [ None; Some (1, 3); Some (4, 6); Some (6, 6) ] );
    ( "a setext heading of level 1 ends a section of level 2",
      "## A\nB\n=\nC\n",
      [ (1, 2); (2, 1) ],
      [ None; Some (1, 1); Some (2, 4) ] );
    ( "setext and ATX headings of one level end each other",
      "A\n===\n# B\nC\n===\n",
      [ (1, 1); (3, 1); (4, 1) ],
      [ None; Some (1, 2); Some (3, 3); Some (4, 5) ] );
    ( "an underline can be indented by three spaces and end with spaces",
      "A\n   === \t\n",
      [ (1, 1) ],
      [ None; Some (1, 2) ] );
    ( "an underline indented by four spaces is text",
      "A\n    ===\n",
      [],
      [ Some (1, 2) ] );
    ("an underline with a space inside is text", "A\n= =\n", [], [ Some (1, 2) ]);
    ( "--- after a blank line is a thematic break",
      "A\n\n---\n",
      [],
      [ Some (1, 3) ] );
    ( "a setext heading in a list item opens no section",
      "- a\n  ---\n",
      [],
      [ Some (1, 2) ] );
    ( "--- under a block quote is a thematic break",
      "> a\n---\n",
      [],
      [ Some (1, 2) ] );
    ( "--- under a list item is a thematic break",
      "- a\n---\n",
      [],
      [ Some (1, 2) ] );
    ( "a setext heading after front matter",
      "---\nx: 1\n---\nA\n=\n",
      [ (4, 1) ],
      [ None; Some (4, 5) ] );
  ]

let setext_case (name, file, expected_headings, expected_lines) =
  Alcotest.test_case name `Quick (fun () ->
      Alcotest.(check (list (pair int int)))
        "the lines and levels of the headings" expected_headings (headings file);
      Alcotest.(check (list (option (pair int int))))
        "the lines of the sections" expected_lines (section_lines file))

let setext_headings n =
  "# A\n"
  ^ String.concat ""
      (List.init n (fun k ->
           if k mod 2 = 0 then "T\n---\n@req a=v1\n" else "U\nV\n=\nText.\n"))

let sections_of_setext_headings_grow_linearly () =
  let sections file = Markdown_file.sections (read file) in
  Counted_work.check_growth ~margin:1.5 ~sizes:(500, 2000)
    ~input:setext_headings sections;
  Time_growth.check ~bound:10. ~size:500 ~input:setext_headings sections

let headings_in_containers_open_no_section () =
  Alcotest.(check (list (pair int int)))
    "no heading in a list item or a block quote"
    [ (4, 1) ]
    (headings "- # B\n> # C\n\n# D\n")

let front_matter_lines () =
  let markdown = read "---\ntitle: x\n---\n@design a=v1\n" in
  Alcotest.(check bool)
    "the front matter" true
    (Markdown_file.front_matter markdown
    = Some { Markdown_file.first = 1; last = 3 });
  Alcotest.(check int)
    "the first line of the markdown text" 4
    (Markdown_file.first_markdown_text_line markdown);
  Alcotest.(check bool)
    "the markdown run" true
    (Markdown_file.markdown_run markdown = { Text.from = 17; until = 30 });
  Alcotest.(check bool)
    "the section of level 0" true
    (List.map
       (fun (s : Markdown_file.section) -> s.lines)
       (Markdown_file.sections markdown)
    = [ Some { Markdown_file.first = 4; last = 4 } ])

let a_whole_front_matter_leaves_an_empty_markdown_text () =
  let markdown = read "---\nx\n---" in
  Alcotest.(check bool)
    "the markdown run is empty" true
    (Markdown_file.markdown_run markdown = { Text.from = 9; until = 9 });
  Alcotest.(check int)
    "no line of the markdown text" 4
    (Markdown_file.first_markdown_text_line markdown);
  Alcotest.(check bool)
    "the section of level 0 is empty" true
    (List.map
       (fun (s : Markdown_file.section) -> s.lines)
       (Markdown_file.sections markdown)
    = [ None ])

let list_items_of_nested_lists () =
  let markdown = read "- a\n  - @req b=v1\n- c\n" in
  Alcotest.(check (list int))
    "the first lines, the outer one first" [ 1; 2; 3 ]
    (List.map
       (fun (item : Markdown_file.list_item) -> item.lines.first)
       (Markdown_file.list_items markdown));
  Alcotest.(check bool)
    "the outer item holds the inner one" true
    (match Markdown_file.list_items markdown with
    | outer :: inner :: _ ->
        within outer.lines inner.lines && outer.lines.last >= 2
    | _ -> false)

let an_outer_list_item_comes_first () =
  match Markdown_file.list_items (read "- - @req a=v1\n") with
  | [ outer; inner ] ->
      Alcotest.(check int) "one first line" outer.lines.first inner.lines.first;
      Alcotest.(check bool)
        "the outer item has no first paragraph" true
        (outer.first_paragraph = None);
      Alcotest.(check bool)
        "the inner item has one" true
        (inner.first_paragraph <> None)
  | _ -> Alcotest.fail "two list items"

let item_lines file =
  List.map
    (fun (item : Markdown_file.list_item) ->
      (item.lines.first, item.lines.last))
    (Markdown_file.list_items (read file))

let list_items_take_the_lines_of_their_blocks () =
  List.iter
    (fun (file, expected) ->
      Alcotest.(check (list (pair int int))) file expected (item_lines file))
    [
      ("- a\n  ```\n  x\n  ```\n", [ (1, 4) ]);
      ("- a\n  > b\n  > c\n", [ (1, 3) ]);
      ("- a\n  # H\n", [ (1, 2) ]);
      ("- a\n  <div>\n  x\n", [ (1, 3) ]);
      ("- a\n\n  [x]: /u\n", [ (1, 3) ]);
      ("- a\n  ***\n", [ (1, 2) ]);
      ("- a\n\n      code\n", [ (1, 3) ]);
      ("- a\n  - b\n    - c\n", [ (1, 3); (2, 3); (3, 3) ]);
    ]

let a_section_paragraph_takes_its_lines () =
  match Markdown_file.sections (read billing) with
  | [ _; a; b; c ] ->
      List.iter2
        (fun (s : Markdown_file.section) expected ->
          Alcotest.(check bool)
            "the lines of the paragraph" true
            (Option.map
               (fun (p : Markdown_file.paragraph) -> p.lines)
               s.first_paragraph
            = Some expected))
        [ a; b; c ]
        [
          { Markdown_file.first = 2; last = 3 };
          { first = 6; last = 7 };
          { first = 10; last = 11 };
        ]
  | _ -> Alcotest.fail "four sections"

let deep_files =
  [
    ( "20,000 nested block quotes",
      String.concat "" (List.init 20_000 (fun _ -> "> ")) ^ "@req a=v1\n" );
    ( "1,000 nested list items",
      String.concat ""
        (List.init 1_000 (fun k -> String.make (2 * k) ' ' ^ "- a\n")) );
    ("12 nested brackets", String.make 12 '[' ^ "@req a=v1" ^ String.make 12 ']');
    ("50,000 stars", String.make 50_000 '*' ^ "a" ^ String.make 50_000 '*');
    ("a line of 1,000,000 characters", "# A\n" ^ String.make 1_000_000 'a');
    ( "50,000 list items with task markers",
      String.concat "" (List.init 50_000 (fun _ -> "- [x] @req a=v1\n")) );
    ("100,000 carriage returns", String.make 100_000 '\r');
    ("10,000 backticks", String.make 10_000 '`');
  ]

let deep_file_reads file () =
  let markdown = read file in
  Alcotest.(check bool)
    "the origins and the file lines keep the terms" true
    (origins_are_the_places_of_the_characters markdown
    && file_lines_are_the_markdown_lines markdown)

let byte_gen =
  Gen.oneof_weighted
    [
      ( 4,
        Gen.oneof_list
          [
            '#';
            '-';
            '>';
            ' ';
            '\t';
            '\n';
            '\r';
            '[';
            ']';
            'x';
            '@';
            '`';
            '*';
            '+';
            '<';
          ] );
      (1, Gen.char);
    ]

let corrupt_gen =
  Gen.bind markdown_gen (fun file ->
      let n = String.length file in
      Gen.map2
        (fun at byte ->
          if n = 0 then String.make 1 byte
          else
            let at = at mod n in
            String.sub file 0 at ^ String.make 1 byte
            ^ String.sub file at (n - at))
        Gen.nat byte_gen)

let corrupted_files_read =
  property ~count:2000
    ~name:"a file with a byte inserted keeps the terms when it is valid UTF-8"
    ~print corrupt_gen (fun file ->
      match Text.decode file with
      | Ok _ -> structure_holds file
      | Error _ -> true)

let tests =
  [
    markdown_lines_follow_the_term;
    front_matter_follows_the_term;
    markdown_text_comes_from_the_markdown_run;
    structure_holds_for_generated_files;
    Alcotest.test_case "the vector files keep the terms" `Quick
      structure_holds_for_the_vector_files;
    Alcotest.test_case "the first line of a paragraph starts at its content"
      `Quick first_line_starts_at_the_content;
    Alcotest.test_case "sections of nested headings" `Quick
      sections_of_nested_headings;
    Alcotest.test_case
      "a heading in a list item or a block quote opens no section" `Quick
      headings_in_containers_open_no_section;
    Alcotest.test_case "the sections of setext headings grow linearly" `Quick
      sections_of_setext_headings_grow_linearly;
    Alcotest.test_case "the lines of front matter" `Quick front_matter_lines;
    Alcotest.test_case "front matter that is the whole file" `Quick
      a_whole_front_matter_leaves_an_empty_markdown_text;
    Alcotest.test_case "list items of nested lists" `Quick
      list_items_of_nested_lists;
    Alcotest.test_case
      "of two list items on one line, the outer one comes first" `Quick
      an_outer_list_item_comes_first;
    Alcotest.test_case
      "a list item takes the lines of the blocks that it contains" `Quick
      list_items_take_the_lines_of_their_blocks;
    Alcotest.test_case "the first paragraph of a section takes its lines" `Quick
      a_section_paragraph_takes_its_lines;
    corrupted_files_read;
  ]
  @ case_tests
  @ List.map setext_case setext_cases
  @ List.map
      (fun (name, file) ->
        Alcotest.test_case
          ("a file of " ^ name ^ " reads")
          `Slow (deep_file_reads file))
      deep_files
