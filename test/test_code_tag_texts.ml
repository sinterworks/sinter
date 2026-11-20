(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_identifiers
open Sinter_origins
open Sinter_tag_inputs
open Sinter_file_readers
open Sinter_readings
open Sinter_code_tag_texts
module Gen = QCheck2.Gen
module R = Code_reference

let property ?(count = 400) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let path_of string =
  match Path.of_text (text_of string) with
  | Ok path -> path
  | Error _ -> invalid_arg "path_of"

let run from until = { Text.from; until }
let print_run { Text.from; until } = Printf.sprintf "%d-%d" from until
let print_runs runs = "[" ^ String.concat " " (List.map print_run runs) ^ "]"

let piece = function
  | R.Text_piece t -> Reading.Text_piece (text_of t)
  | R.Placeholder t -> Reading.Placeholder (text_of t)

let reading_node (n : R.node) =
  {
    Reading.run = n.run;
    comment =
      Option.map
        (function R.Tagged -> Reading.Tagged | R.Untagged -> Reading.Untagged)
        n.comment;
    body = n.body;
    decoration = n.decoration;
    test = Option.map (List.map (List.map piece)) n.test;
  }

let comment_sigils (s : R.sigils) =
  {
    Comment_sigils.line = List.map text_of s.line;
    block = List.map (fun (a, b) -> (text_of a, text_of b)) s.block;
    inner = List.map text_of s.inner;
  }

let line_sigils = { R.line = [ "//" ]; block = []; inner = [] }

let c_sigils =
  {
    R.line = [ "//"; "///" ];
    block = [ ("/*", "*/"); ("/**", "*/") ];
    inner = [ "*" ];
  }

let ml_sigils = { R.line = []; block = [ ("(*", "*)") ]; inner = [] }

let code_file ?(path = "lib/a.rs") sigils source nodes =
  let lines = Lines.of_text (text_of source) in
  match Reading.check lines (List.map reading_node nodes) with
  | Ok reading -> Code_file.make (path_of path) (comment_sigils sigils) reading
  | Error _ -> Alcotest.fail "the reading of the case fails the checks"

let of_case (case : Code_gen.case) =
  code_file case.sigils case.source case.nodes

let find source ?(after = 0) sub =
  let n = String.length sub in
  let rec go k =
    if k + n > String.length source then invalid_arg ("find " ^ sub)
    else if String.sub source k n = sub then k
    else go (k + 1)
  in
  let k = go after in
  run k (k + n)

let blank =
  {
    R.run = run 0 0;
    comment = None;
    body = None;
    decoration = false;
    test = None;
  }

let tagged r = { blank with R.run = r; comment = Some R.Tagged }
let untagged r = { blank with R.run = r; comment = Some R.Untagged }
let decoration r = { blank with R.run = r; decoration = true }

let definition ?body r =
  { blank with R.run = r; body = Some (Option.value body ~default:[ r ]) }

let test_node ?(name = [ [ R.Text_piece "t" ] ]) r =
  { blank with R.run = r; test = Some name }

let reference_case (case : Code_gen.case) = (text_of case.source, case.nodes)
let shaped_or_mixed = Gen.oneof [ Code_gen.shaped; Code_gen.mixed ]

let code_characters_follow_the_term =
  property ~name:"the code characters are those of the term"
    ~print:Code_gen.print shaped_or_mixed (fun case ->
      let file = of_case case in
      let text, nodes = reference_case case in
      List.for_all
        (fun p ->
          Code_file.is_code_character file p = R.is_code_character text nodes p)
        (List.init (Text.length text + 3) (fun k -> k - 1)))

let code_character_cases () =
  let source = "\xef\xbb\xbfa \tb\r\nc\rd\n/* e */ \xc3\xa9" in
  let comment = find source "/* e */" in
  let comment = run (comment.Text.from - 2) (comment.Text.until - 2) in
  let file = code_file c_sigils source [ untagged comment ] in
  let expected =
    [
      (1, false, "the byte order mark");
      (2, true, "a letter");
      (3, false, "a space");
      (4, false, "a tab");
      (5, true, "a letter");
      (6, false, "the carriage return of a line ending");
      (7, false, "the line feed of a line ending");
      (8, true, "a letter");
      (9, true, "a lone carriage return");
      (10, true, "a letter");
      (11, false, "a line feed");
      (12, false, "a character of an untagged comment node");
      (18, false, "the last character of a comment node");
      (20, true, "a character that is not ASCII");
      (0, false, "no place");
      (21, false, "no place after the text");
    ]
  in
  List.iter
    (fun (p, value, what) ->
      Alcotest.(check bool) what value (Code_file.is_code_character file p))
    expected

let lines_of_runs_follow_the_term =
  property ~name:"the lines of a run are those of the term"
    ~print:(fun (case, r) -> Code_gen.print case ^ "\nrun " ^ print_run r)
    (Gen.bind shaped_or_mixed (fun case ->
         let length = Text.length (text_of case.Code_gen.source) in
         Gen.map
           (fun (a, b) -> (case, run a b))
           (Gen.pair
              (Gen.int_range (-1) (length + 1))
              (Gen.int_range (-1) (length + 1)))))
    (fun ((case : Code_gen.case), r) ->
      let text = text_of case.source in
      let lines = Lines.of_text text in
      let is_run =
        0 <= r.from && r.from <= r.until && r.until <= Text.length text
      in
      match Comment_line.run_lines lines r with
      | None -> not is_run
      | Some given -> is_run && given = R.run_lines text r)

let run_line_cases () =
  let lines = Lines.of_text (text_of "ab\n\ncd\r\nef\n") in
  let check what r expected =
    Alcotest.(check (option string))
      what (Some expected)
      (Option.map print_runs (Comment_line.run_lines lines r))
  in
  check "a run inside one line" (run 1 2) "[1-2]";
  check "a run over three lines with an empty line inside" (run 1 6)
    "[1-2 3-3 4-6]";
  check "a run that starts at an empty line" (run 3 6) "[4-6]";
  check "a run that holds a line ending only" (run 2 3) "[]";
  check "a run that holds the carriage return of a line ending" (run 6 7) "[]";
  check "an empty run" (run 1 1) "[]";
  check "the whole text" (run 0 11) "[0-2 3-3 4-6 8-10]";
  Alcotest.(check bool)
    "no run of the text" true
    (Comment_line.run_lines lines (run 4 13) = None);
  Alcotest.(check (option string))
    "a run from boundary 0 of a text with a byte order mark" (Some "[1-3 4-5]")
    (Option.map print_runs
       (Comment_line.run_lines
          (Lines.of_text (text_of "\xef\xbb\xbfab\ncd"))
          (run 0 5)))

let comment_lines_follow_the_term =
  property ~name:"the comment lines of a comment node are those of the term"
    ~print:Code_gen.print shaped_or_mixed (fun case ->
      let text = text_of case.source in
      let lines = Lines.of_text text in
      List.for_all
        (fun (n : R.node) ->
          Comment_line.of_node (comment_sigils case.sigils) lines n.run
          = Some (R.comment_lines case.sigils text n.run))
        case.nodes)

let comment_lines_lie_in_the_lines_of_the_run =
  property ~name:"each comment line lies in its line of the run, one for each"
    ~print:Code_gen.print shaped_or_mixed (fun case ->
      let text = text_of case.source in
      let lines = Lines.of_text text in
      List.for_all
        (fun (n : R.node) ->
          match
            ( Comment_line.of_node (comment_sigils case.sigils) lines n.run,
              Comment_line.run_lines lines n.run )
          with
          | Some comment_lines, Some run_lines ->
              List.length comment_lines = List.length run_lines
              && List.for_all2
                   (fun (c : Text.run) (l : Text.run) ->
                     l.from <= c.from && c.from <= c.until && c.until <= l.until)
                   comment_lines run_lines
          | _ -> false)
        case.nodes)

let comment_line_texts sigils source sub =
  let text = text_of source in
  let lines = Lines.of_text text in
  match
    Comment_line.of_node (comment_sigils sigils) lines (find source sub)
  with
  | Some runs ->
      List.map
        (fun r ->
          match Text.sub text r with
          | Some t -> Text.encode t
          | None -> Alcotest.fail "no run")
        runs
  | None -> Alcotest.fail "no comment lines"

let comment_line_cases () =
  let check what sigils source sub expected =
    Alcotest.(check (list string))
      what expected
      (comment_line_texts sigils source sub)
  in
  check "a block comment with an inner sigil, as in section 2.3" c_sigils
    "/* @req a=v1\n * A text.\n */\n" "/* @req a=v1\n * A text.\n */"
    [ " @req a=v1"; " A text."; "" ];
  check "the longest opening sigil" c_sigils "/**\n * @spec d#s=v1\n */\n"
    "/**\n * @spec d#s=v1\n */"
    [ ""; " @spec d#s=v1"; "" ];
  check "the longest line sigil" c_sigils "/// @req a=v1\n" "/// @req a=v1"
    [ " @req a=v1" ];
  check "a block comment on one line" c_sigils "x(); /* @req b=v1 */\n"
    "/* @req b=v1 */" [ " @req b=v1 " ];
  check "a line comment over several lines loses its sigil on each" line_sigils
    "// a\n  // b\n\t//c\n" "// a\n  // b\n\t//c" [ " a"; " b"; "c" ];
  check "a later line of a line comment with no sigil keeps its text"
    line_sigils "// a\n  b\n" "// a\n  b" [ " a"; "b" ];
  check "a comment with no sigil loses only spaces and tabs" c_sigils
    "\"\"\"\n  @req a=v1\n\tText.\n\"\"\""
    "\"\"\"\n  @req a=v1\n\tText.\n\"\"\""
    [ "\"\"\""; "@req a=v1"; "Text."; "\"\"\"" ];
  check "an OCaml comment keeps the indentation after its first line" ml_sigils
    "(* @spec x=v1\n   Text. *)\n" "(* @spec x=v1\n   Text. *)"
    [ " @spec x=v1"; "Text. " ];
  check "the closing sigil goes before the inner sigil" c_sigils "/* a\n **/\n"
    "/* a\n **/" [ " a"; "" ];
  check "the inner sigil only at the start of a later line" c_sigils
    "/* a * b\n * c * d */\n" "/* a * b\n * c * d */" [ " a * b"; " c * d " ];
  check "a closing sigil that does not end the last line stays" c_sigils
    "/* a */ b\n" "/* a */ b" [ " a */ b" ];
  check "a closing sigil on a line that is not the last stays" c_sigils
    "/* a */\n b */\n" "/* a */\n b */" [ " a */"; "b " ];
  check "an empty line inside a block comment" c_sigils "/* a\n\n b */\n"
    "/* a\n\n b */" [ " a"; ""; "b " ];
  check "a last line that ends with only a part of the closing sigil keeps it"
    c_sigils "/* a *b\n" "/* a *b" [ " a *b" ];
  check "a last line that does not end with a closing sigil of one character"
    { R.line = []; block = [ ("{", "}") ]; inner = [] }
    "{ a\n b ]\n" "{ a\n b ]" [ " a"; "b ]" ];
  check "a line sigil that is also an opening sigil makes a line comment"
    { R.line = [ "--" ]; block = [ ("--", "--") ]; inner = [ "|" ] }
    "-- a --\n" "-- a --" [ " a --" ];
  check "the first block pair whose opening sigil matches gives the closing"
    { R.line = []; block = [ ("{", "}"); ("{", "]") ]; inner = [] }
    "{ a ]\n b }" "{ a ]\n b }" [ " a ]"; "b " ];
  check "the carriage return of a line ending is on no comment line" line_sigils
    "// a\r\n// b\r\n" "// a\r\n// b" [ " a"; " b" ];
  check "a lone carriage return stays on its comment line" line_sigils
    "// a\rb\n" "// a\rb" [ " a\rb" ];
  Alcotest.(check bool)
    "no comment lines for a run that is no run of the text" true
    (Comment_line.of_node (comment_sigils c_sigils)
       (Lines.of_text (text_of "/* a */"))
       (run 2 9)
    = None);
  Alcotest.(check (option (list string)))
    "an empty run has no comment line" (Some [])
    (Option.map (List.map print_run)
       (Comment_line.of_node (comment_sigils c_sigils)
          (Lines.of_text (text_of "/* a */"))
          (run 3 3)))

let reference_runs (case : Code_gen.case) =
  let text, nodes = reference_case case in
  List.map
    (fun members ->
      let first = List.nth nodes (List.hd members) in
      let last = List.nth nodes (List.nth members (List.length members - 1)) in
      ( R.comment_run_span nodes members,
        R.line_number text first.run.from,
        R.last_line text last,
        List.map (fun k -> reading_node (List.nth nodes k)) members,
        R.tag_text_lines case.sigils text nodes members,
        Option.map
          (fun k -> reading_node (List.nth nodes k))
          (R.attachment text nodes members) ))
    (R.comment_runs text nodes)

let given_runs file =
  List.map
    (fun (r : Code_file.comment_run) ->
      ( r.run,
        r.first_line,
        r.last_line,
        r.comment_nodes,
        Option.map Tag_text.joined r.tag_text,
        r.target ))
    (Code_file.comment_runs file)

let print_given runs =
  String.concat "\n"
    (List.map
       (fun (r, first, last, members, tag_text, target) ->
         Printf.sprintf "run %s lines %d-%d of %d nodes, tag text %s, target %s"
           (print_run r) first last (List.length members)
           (match tag_text with Some runs -> print_runs runs | None -> "none")
           (match target with
           | Some (n : Reading.node) -> print_run n.run
           | None -> "none"))
       runs)

let runs_of_comments_follow_the_terms =
  property ~count:800
    ~name:
      "the runs of comments, their tag texts, and their targets are those of \
       the terms" ~print:Code_gen.print shaped_or_mixed (fun case ->
      let given = given_runs (of_case case)
      and expected = reference_runs case in
      given = expected
      || QCheck2.Test.fail_reportf "given\n%s\nexpected\n%s" (print_given given)
           (print_given expected))

let tag_texts_are_those_of_the_runs =
  property
    ~name:"the tag texts are those of the runs of comments, in their order"
    ~print:Code_gen.print shaped_or_mixed (fun case ->
      let file = of_case case in
      let from_runs =
        List.filter_map
          (fun (r : Code_file.comment_run) -> r.tag_text)
          (Code_file.comment_runs file)
      in
      List.map Tag_text.joined (Code_file.tag_texts file)
      = List.map Tag_text.joined from_runs)

let tag_text_is_the_comment_lines_joined =
  property
    ~name:
      "the text of a tag text is its comment lines, each two joined by a line \
       feed" ~print:Code_gen.print shaped_or_mixed (fun case ->
      let file = of_case case in
      let text = text_of case.source in
      List.for_all
        (fun tag_text ->
          let parts =
            List.map
              (fun r ->
                match Text.sub text r with
                | Some t -> Text.encode t
                | None -> "?")
              (Tag_text.joined tag_text)
          in
          Text.encode (Tag_text.text tag_text) = String.concat "\n" parts)
        (Code_file.tag_texts file))

let file_lines_are_the_joined_lines =
  property ~name:"the file lines are the lines that the tag texts join"
    ~print:Code_gen.print shaped_or_mixed (fun case ->
      let file = of_case case in
      let set runs =
        List.sort_uniq
          (fun (a : Text.run) (b : Text.run) ->
            compare (a.from, a.until) (b.from, b.until))
          runs
      in
      set (File_lines.all (Code_file.file_lines file))
      = set (List.concat_map Tag_text.joined (Code_file.tag_texts file)))

let a_file_keeps_its_path_and_reading () =
  let source = "// a\n" in
  let file =
    code_file ~path:"src/x.ml" line_sigils source [ tagged (run 0 4) ]
  in
  Alcotest.(check string)
    "the path" "src/x.ml"
    (Text.encode (Path.to_text (Code_file.path file)));
  Alcotest.(check string)
    "the text" source
    (Text.encode (Lines.text (Reading.lines (Code_file.reading file))));
  Alcotest.(check int)
    "the nodes" 1
    (List.length (Reading.nodes (Code_file.reading file)))

let summary file =
  List.map
    (fun (r : Code_file.comment_run) ->
      ( print_run r.run,
        Option.map (fun (n : Reading.node) -> print_run n.run) r.target ))
    (Code_file.comment_runs file)

let expect what sigils source nodes expected () =
  Alcotest.(check (list (pair string (option string))))
    what expected
    (summary (code_file sigils source nodes))

let rust_test =
  "// @verifies billing#limit-amount=v2\n\
   #[test]\n\
   fn rejects_large_amounts() {\n\
  \    assert!(check(10_001).is_err());\n\
   }\n"

let rust_nodes source =
  let fn = run (find source "fn ").from (String.length source - 1) in
  [
    tagged (find source "// @verifies billing#limit-amount=v2");
    decoration (find source "#[test]");
    {
      (definition ~body:[ run (find source "{").from fn.until ] fn) with
      test = Some [ [ R.Text_piece "rejects_large_amounts" ] ];
    };
  ]

let attachment_cases =
  let src1 = rust_test in
  let src2 = "// @verifies x#y=v2\n\n#[test]\nfn t() {}\n" in
  let src3 = "// a\n\n// b\nf();\n" in
  let src4 = "// a\nf();\n// b\n" in
  let src5 = "/* a */ /* b */\n// c\nfn f() {}\n" in
  let src6 = "x = 1; // a\n// b\nfn f() {}\n" in
  let src7 = "// a\nx; fn f() {}\n" in
  let src8 = "// a\n#[t] x\nfn f() {}\n" in
  let src9 =
    "// @verifies x#y=v2\n#[test]\n// @satisfies a#b=v1\nfn t() {}\n"
  in
  let src10 = "// @verifies x#y=v2\n#[test]\n/* a\n\n b */\nfn t() {}\n" in
  let src11 = "// a\n#[test] // b\nfn t() {}\n" in
  let src12 = "// a\n#[test]\n" in
  let src13 = "// a\n" in
  let src13b = "fn f() {}\n// a\n" in
  let src14 = "module M {\n  // a\n  fn f() {}\n}\n" in
  let src15 = "// a\r\n#[x]\r\nfn f() {}\r\n" in
  let src16 = "/* @req a=v1\n */\r \n// @req b=v1\nfn f() {}\n" in
  let src17 = "// a\n// b\nfn f() {}\n" in
  let src19 = "// a\n#[x(\n   \n)]\nfn f() {}\n" in
  let src20 = "// a\n#[t]\n/* b\n\n c */\nfn f() {}\n" in
  let src21 = "// a\n#[t]\n/* x *//* y\n\n z */\nfn f() {}\n" in
  let src22 = "// a\n#[x\n  ]\nfn f() {}\n" in
  let src18 =
    "class A:\n    \"\"\"@spec a=v1\"\"\"\n\n    def f(self): pass\n"
  in
  [
    ( "a run of comments attaches to a test node after a decoration, as in \
       section 2.3",
      line_sigils,
      src1,
      rust_nodes src1,
      [ ("0-36", Some (print_run (List.nth (rust_nodes src1) 2).run)) ] );
    ( "a blank line between the comment and the decoration leaves the run \
       unattached",
      line_sigils,
      src2,
      [
        tagged (find src2 "// @verifies x#y=v2");
        decoration (find src2 "#[test]");
        test_node (find src2 "fn t() {}");
      ],
      [ ("0-19", None) ] );
    ( "an empty line ends a run of comments",
      line_sigils,
      src3,
      [ tagged (find src3 "// a"); tagged (find src3 "// b") ],
      [ ("0-4", None); ("6-10", None) ] );
    ( "a line with code characters ends a run of comments",
      line_sigils,
      src4,
      [ tagged (find src4 "// a"); tagged (find src4 "// b") ],
      [ ("0-4", None); ("10-14", None) ] );
    ( "a comment node that starts on the last line of the one before joins its \
       run",
      c_sigils,
      src5,
      [
        tagged (find src5 "/* a */");
        tagged (find src5 "/* b */");
        tagged (find src5 "// c");
        definition (find src5 "fn f() {}");
      ],
      [ ("0-20", Some "21-30") ] );
    ( "a comment node after code is a run of comments by itself and attaches \
       to nothing",
      line_sigils,
      src6,
      [
        tagged (find src6 "// a");
        tagged (find src6 "// b");
        definition (find src6 "fn f() {}");
      ],
      [ ("7-11", None); ("12-16", Some "17-26") ] );
    ( "a code character between the run and its target leaves it unattached",
      line_sigils,
      src7,
      [ tagged (find src7 "// a"); definition (find src7 "fn f() {}") ],
      [ ("0-4", None) ] );
    ( "a code character in no decoration on a line between leaves it unattached",
      line_sigils,
      src8,
      [
        tagged (find src8 "// a");
        decoration (find src8 "#[t]");
        definition (find src8 "fn f() {}");
      ],
      [ ("0-4", None) ] );
    ( "two runs of comments attach to one target, as in the term attachment",
      line_sigils,
      src9,
      [
        tagged (find src9 "// @verifies x#y=v2");
        decoration (find src9 "#[test]");
        tagged (find src9 "// @satisfies a#b=v1");
        test_node (find src9 "fn t() {}");
      ],
      [ ("0-19", Some "49-58"); ("28-48", Some "49-58") ] );
    ( "a line of a comment node between counts, also its empty line",
      c_sigils,
      src10,
      [
        tagged (find src10 "// @verifies x#y=v2");
        decoration (find src10 "#[test]");
        untagged (find src10 "/* a\n\n b */");
        test_node (find src10 "fn t() {}");
      ],
      [ ("0-19", Some "40-49"); ("28-39", Some "40-49") ] );
    ( "a comment after a decoration on its line does not attach (a known limit)",
      line_sigils,
      src11,
      [
        tagged (find src11 "// a");
        decoration (find src11 "#[test]");
        tagged (find src11 "// b");
        test_node (find src11 "fn t() {}");
      ],
      [ ("0-4", Some "18-27"); ("13-17", None) ] );
    ( "a run that only decorations follow attaches to nothing",
      line_sigils,
      src12,
      [ tagged (find src12 "// a"); decoration (find src12 "#[test]") ],
      [ ("0-4", None) ] );
    ( "a run at the end of the file attaches to nothing",
      line_sigils,
      src13b,
      [ definition (find src13b "fn f() {}"); tagged (find src13b "// a") ],
      [ ("10-14", None) ] );
    ( "a target with an empty run at the end of the file takes the run before it",
      line_sigils,
      src13,
      [ tagged (find src13 "// a"); definition (run 5 5) ],
      [ ("0-4", Some "5-5") ] );
    ( "a run inside a definition attaches to the next target inside it",
      line_sigils,
      src14,
      [
        definition (run 0 (String.length src14 - 1));
        tagged (find src14 "// a");
        definition (find src14 "fn f() {}");
      ],
      [ ("13-17", Some "20-29") ] );
    ( "line endings with carriage returns stand between a run and its target",
      line_sigils,
      src15,
      [
        tagged (find src15 "// a");
        decoration (find src15 "#[x]");
        definition (find src15 "fn f() {}");
      ],
      [ ("0-4", Some "12-21") ] );
    ( "a lone carriage return between two comment nodes ends a run of comments",
      c_sigils,
      src16,
      [
        tagged (find src16 "/* @req a=v1\n */");
        tagged (find src16 "// @req b=v1");
        definition (find src16 "fn f() {}");
      ],
      [
        (print_run (find src16 "/* @req a=v1\n */"), None);
        ( print_run (find src16 "// @req b=v1"),
          Some (print_run (find src16 "fn f() {}")) );
      ] );
    ( "a line of only spaces inside a decoration between leaves the run \
       unattached",
      line_sigils,
      src19,
      [
        tagged (find src19 "// a");
        decoration (find src19 "#[x(\n   \n)]");
        definition (find src19 "fn f() {}");
      ],
      [ ("0-4", None) ] );
    ( "an empty line inside a block comment between counts, also with an empty \
       comment node on it",
      c_sigils,
      src20,
      [
        tagged (find src20 "// a");
        decoration (find src20 "#[t]");
        untagged (find src20 "/* b\n\n c */");
        tagged
          (let b = (find src20 "/* b").until + 1 in
           run b b);
        definition (find src20 "fn f() {}");
      ],
      [
        ("0-4", Some (print_run (find src20 "fn f() {}")));
        ( print_run (find src20 "/* b\n\n c */"),
          Some (print_run (find src20 "fn f() {}")) );
      ] );
    ( "an empty comment node on an empty line right before its target attaches",
      line_sigils,
      "\nfn f() {}\n",
      [ tagged (run 0 0); definition (run 1 10) ],
      [ ("0-0", Some "1-10") ] );
    ( "a comment node right after another, with an empty line inside it, \
       counts between",
      c_sigils,
      src21,
      [
        tagged (find src21 "// a");
        decoration (find src21 "#[t]");
        untagged (find src21 "/* x */");
        untagged (find src21 "/* y\n\n z */");
        definition (find src21 "fn f() {}");
      ],
      [
        ("0-4", Some (print_run (find src21 "fn f() {}")));
        ( print_run
            (run (find src21 "/* x */").from (find src21 "/* y\n\n z */").until),
          Some (print_run (find src21 "fn f() {}")) );
      ] );
    ( "a line whose last place alone is a code character of a decoration counts",
      line_sigils,
      src22,
      [
        tagged (find src22 "// a");
        decoration (find src22 "#[x\n  ]");
        definition (find src22 "fn f() {}");
      ],
      [ ("0-4", Some (print_run (find src22 "fn f() {}"))) ] );
    ( "a docstring inside a class attaches to no target (a known limit)",
      { R.line = [ "#" ]; block = []; inner = [] },
      src18,
      [
        definition (run 0 (String.length src18 - 1));
        tagged (find src18 "\"\"\"@spec a=v1\"\"\"");
        definition (find src18 "def f(self): pass");
      ],
      [ (print_run (find src18 "\"\"\"@spec a=v1\"\"\""), None) ] );
    ( "of targets that start at one boundary, the one that ends last",
      line_sigils,
      src17,
      [
        tagged (find src17 "// a");
        tagged (find src17 "// b");
        test_node (run 10 19);
        definition (run 10 12);
      ],
      [ ("0-9", Some "10-19") ] );
  ]

let roles_cases =
  let src1 = "// a\nfn f() {}\n" in
  let src2 = "// a\n#[test]\nfn t() {}\n" in
  let src3 = "// a\n/* b */\nfn f() {}\n" in
  [
    ( "a comment node that is also a target does not take its own run",
      c_sigils,
      src1,
      [
        { (tagged (find src1 "// a")) with body = Some [ find src1 "// a" ] };
        definition (find src1 "fn f() {}");
      ],
      [ ("0-4", Some "5-14") ] );
    ( "an empty comment node that is also a target, at the end of its run, \
       takes that run",
      c_sigils,
      src1,
      [
        tagged (find src1 "// a");
        { (tagged (run 4 4)) with test = Some [ [] ] };
        definition (find src1 "fn f() {}");
      ],
      [ ("0-4", Some "4-4") ] );
    ( "a comment node that is also a decoration node acts as a comment node",
      c_sigils,
      src3,
      [
        tagged (find src3 "// a");
        { (untagged (find src3 "/* b */")) with decoration = true };
        definition (find src3 "fn f() {}");
      ],
      [ ("0-12", Some "13-22") ] );
    ( "a decoration node that is also a test node takes the run before it",
      line_sigils,
      src2,
      [
        tagged (find src2 "// a");
        { (decoration (find src2 "#[test]")) with test = Some [ [] ] };
        definition (find src2 "fn t() {}");
      ],
      [ ("0-4", Some "5-12") ] );
  ]

let many_comment_nodes () =
  let count = 300_000 in
  let source =
    String.concat "" (List.init count (fun _ -> "//\n")) ^ "fn f() {}\n"
  in
  let nodes =
    List.init count (fun k -> tagged (run (3 * k) ((3 * k) + 2)))
    @ [ definition (run (3 * count) ((3 * count) + 9)) ]
  in
  match Code_file.comment_runs (code_file line_sigils source nodes) with
  | [ r ] ->
      Alcotest.(check int)
        "one run of all the comment nodes" count
        (List.length r.comment_nodes);
      Alcotest.(check bool) "it attaches" true (r.target <> None)
  | runs -> Alcotest.failf "%d runs of comments" (List.length runs)

let first_target_in_the_list () =
  let source = "// a\nfn f() {}\n" in
  let first =
    test_node ~name:[ [ R.Text_piece "a" ] ] (find source "fn f() {}")
  in
  let second =
    test_node ~name:[ [ R.Text_piece "b" ] ] (find source "fn f() {}")
  in
  let file =
    code_file line_sigils source [ tagged (find source "// a"); first; second ]
  in
  match Code_file.comment_runs file with
  | [ { target = Some target; _ } ] ->
      Alcotest.(check bool)
        "the first test node" true
        (target = reading_node first)
  | _ -> Alcotest.fail "one run of comments with a target"

let enclosed_and_empty_cases () =
  let source = "(* @spec d#s=v1\n   (* @req inner=v1 *)\n   Text. *)\n" in
  let outer =
    find source "(* @spec d#s=v1\n   (* @req inner=v1 *)\n   Text. *)"
  in
  let inner = find source "(* @req inner=v1 *)" in
  let file = code_file ml_sigils source [ tagged outer; tagged inner ] in
  (match Code_file.comment_runs file with
  | [ r ] ->
      Alcotest.(check int)
        "the outer node alone" 1
        (List.length r.comment_nodes);
      Alcotest.(check (option string))
        "the tag text holds the lines of the outer node"
        (Some " @spec d#s=v1\n(* @req inner=v1 *)\nText. ")
        (Option.map (fun t -> Text.encode (Tag_text.text t)) r.tag_text)
  | _ -> Alcotest.fail "one run of comments");
  let source = "// a\n" in
  let file =
    code_file line_sigils source [ untagged (run 0 4); tagged (run 5 5) ]
  in
  match Code_file.comment_runs file with
  | [ r ] ->
      Alcotest.(check (option string))
        "a tagged comment node with an empty run gives an empty tag text"
        (Some "")
        (Option.map (fun t -> Text.encode (Tag_text.text t)) r.tag_text);
      Alcotest.(check (option (list string)))
        "that tag text joins no line" (Some [])
        (Option.map
           (fun t -> List.map print_run (Tag_text.joined t))
           r.tag_text)
  | _ -> Alcotest.fail "one run of comments"

let untagged_nodes_give_no_lines () =
  let source = "// @req a=v1\n// not tagged\n// @req b=v1\n" in
  let nodes =
    [
      tagged (find source "// @req a=v1");
      untagged (find source "// not tagged");
      tagged (find source "// @req b=v1");
    ]
  in
  let file = code_file line_sigils source nodes in
  (match Code_file.comment_runs file with
  | [ r ] ->
      Alcotest.(check int) "three nodes" 3 (List.length r.comment_nodes);
      Alcotest.(check (option string))
        "the lines of the tagged nodes" (Some " @req a=v1\n @req b=v1")
        (Option.map (fun t -> Text.encode (Tag_text.text t)) r.tag_text)
  | _ -> Alcotest.fail "one run of comments");
  let file =
    code_file line_sigils "// a\nfn f() {}\n"
      [ untagged (run 0 4); definition (run 5 14) ]
  in
  match Code_file.comment_runs file with
  | [ r ] ->
      Alcotest.(check bool) "no tag text" true (r.tag_text = None);
      Alcotest.(check bool) "it still attaches" true (r.target <> None);
      Alcotest.(check int)
        "no tag text of the file" 0
        (List.length (Code_file.tag_texts file))
  | _ -> Alcotest.fail "one run of comments"

let last_line_of_a_node_with_its_line_feed () =
  let source = "// a\n\n// b\n" in
  let file =
    code_file line_sigils source
      [ tagged (run 0 5); tagged (find source "// b") ]
  in
  Alcotest.(check (list (triple string int int)))
    "the runs and their line numbers"
    [ ("0-5", 1, 1); ("6-10", 3, 3) ]
    (List.map
       (fun (r : Code_file.comment_run) ->
         (print_run r.run, r.first_line, r.last_line))
       (Code_file.comment_runs file))

let origins_of_code_tag_texts () =
  let source = "let x = 1\n(* @req x=v1 *)\n" in
  let file =
    code_file ml_sigils source [ tagged (find source "(* @req x=v1 *)") ]
  in
  match Code_file.tag_texts file with
  | [ tag_text ] -> (
      match Input.of_tag_text Binding.empty tag_text with
      | [ input ] ->
          Alcotest.(check (option (pair int int)))
            "the origin position is that of the @"
            (Some (2, 4))
            (Option.map
               (fun { Lines.line; column } -> (line, column))
               (Input.origin_position input))
      | _ -> Alcotest.fail "one input")
  | _ -> Alcotest.fail "one tag text"

let a_link_over_two_comment_lines () =
  let source = "// See [the\n// guide](sinter:a=v1).\nfn f() {}\n" in
  let file =
    code_file line_sigils source
      [
        tagged (find source "// See [the");
        tagged (find source "// guide](sinter:a=v1).");
      ]
  in
  match Code_file.tag_texts file with
  | [ tag_text ] -> (
      match
        List.filter Input.accepted
          (Input.of_links Binding.empty (Tag_text.source tag_text))
      with
      | [ input ] ->
          Alcotest.(check (option string))
            "the origin run goes from the [ to the )"
            (Some
               (print_run
                  (run (find source "[the").from (find source "a=v1)").until)))
            (Option.map print_run (Input.origin_run input))
      | _ -> Alcotest.fail "one accepted link")
  | _ -> Alcotest.fail "one tag text"

let tag_line_contents =
  [
    "@req a=v1";
    " @req b=v1";
    "@param x";
    "@";
    "@cites {";
    "    c=v1,";
    "}";
    "@cites d=v1, e=v1";
    "Text.";
    "More text.";
    "";
    "  ";
    "\t";
    "x @req a=v1";
  ]

let block_case_gen =
  Gen.list_size (Gen.int_range 0 10) (Gen.oneof_list tag_line_contents)

let tag_text_of_lines lines =
  let source = String.concat "\n" lines in
  let file = Lines.of_text (text_of source) in
  let runs =
    if lines = [] then []
    else
      let rec go acc start = function
        | [] -> List.rev acc
        | line :: rest ->
            let n = Text.length (text_of line) in
            go (run start (start + n) :: acc) (start + n + 1) rest
      in
      go [] 0 lines
  in
  match Tag_text.make file runs with
  | Some tag_text -> tag_text
  | None -> invalid_arg "tag_text_of_lines"

let reference_blocks tag_text =
  let text = Tag_text.text tag_text in
  let count = Tag_text.line_count tag_text in
  let inputs = Tag_line.read Binding.empty text in
  let lines = Lines.of_text text in
  let kinds =
    List.init count (fun i ->
        let k = i + 1 in
        let line_text =
          match Lines.line lines k with
          | Some r -> Option.value (Text.sub text r) ~default:Text.empty
          | None -> Text.empty
        in
        let s = Text.encode line_text in
        let rec first j =
          if j < String.length s && (s.[j] = ' ' || s.[j] = '\t') then
            first (j + 1)
          else j
        in
        let j = first 0 in
        {
          R.tag = j < String.length s && s.[j] = '@';
          continuation =
            List.exists
              (fun (input : Tag_line.input) ->
                input.first_line < k && k <= input.last_line)
              inputs;
          blank = File_lines.is_blank line_text;
        })
  in
  R.blocks kinds

let blocks_follow_the_term =
  property ~count:1000 ~name:"the blocks of a tag text are those of the term"
    ~print:(fun lines ->
      String.concat " | " (List.map (Printf.sprintf "%S") lines))
    block_case_gen
    (fun lines ->
      let tag_text = tag_text_of_lines lines in
      List.map
        (fun { Block.first_line; last_line } -> (first_line, last_line))
        (Block.of_tag_text Binding.empty tag_text)
      = reference_blocks tag_text)

let no_two_blocks_share_a_line =
  property ~count:500 ~name:"no two blocks share a line, and they are in order"
    ~print:(fun lines ->
      String.concat " | " (List.map (Printf.sprintf "%S") lines))
    block_case_gen
    (fun lines ->
      let blocks = Block.of_tag_text Binding.empty (tag_text_of_lines lines) in
      let rec ok = function
        | (a : Block.t) :: (b :: _ as rest) ->
            a.first_line <= a.last_line && a.last_line < b.first_line && ok rest
        | [ a ] -> a.first_line <= a.last_line
        | [] -> true
      in
      ok blocks)

let block_cases () =
  let check what lines expected =
    Alcotest.(check (list (pair int int)))
      what expected
      (List.map
         (fun { Block.first_line; last_line } -> (first_line, last_line))
         (Block.of_tag_text Binding.empty (tag_text_of_lines lines)))
  in
  check "tag lines and their trailing prose up to a blank line"
    [ "@req a=v1"; "@req b=v1"; "Text."; "More."; ""; "After." ]
    [ (1, 4) ];
  check "a line before the first tag line is in no block"
    [ "Intro."; "@req a=v1"; "Text." ]
    [ (2, 3) ];
  check "a line after a blank line after a block is in no block"
    [ "@req a=v1"; ""; "Later." ]
    [ (1, 1) ];
  check "a tag line after trailing prose starts a new block (a known limit)"
    [ "@req a=v1"; "Text."; "@req b=v1"; "More." ]
    [ (1, 2); (3, 4) ];
  check "any tag word makes a tag line" [ "@param x"; "Text." ] [ (1, 2) ];
  check "a tag line after the continuation lines of a citation is in its block"
    [ "@cites {"; "    b=v1,"; "}"; "@req c=v1" ]
    [ (1, 4) ];
  check "a tag line after a blank line starts a block"
    [ "@req a=v1"; ""; "@req b=v1" ]
    [ (1, 1); (3, 3) ];
  check "a line with spaces only ends trailing prose"
    [ "@req a=v1"; "Text."; "  "; "More." ]
    [ (1, 2) ];
  check "a tag line with spaces before its @" [ "  @req a=v1"; "Text." ]
    [ (1, 2) ];
  check "no block in an empty tag text" [] []

let read_one ?(path = "lib/a.rs") ?(markdown = false) bytes pack =
  let calls = ref [] in
  let pack () p text =
    calls := (Text.encode (Path.to_text p), Text.encode text) :: !calls;
    pack ()
  in
  let readers =
    match
      File_readers.make
        [
          ( (if markdown then File_readers.Markdown else File_readers.Pack ()),
            [ text_of "**" ] );
        ]
    with
    | Ok readers -> readers
    | Error _ -> Alcotest.fail "a valid binding"
  in
  let tree =
    match Tree.of_files [ (path_of path, bytes) ] with
    | Ok tree -> tree
    | Error _ -> Alcotest.fail "a tree"
  in
  match Read_file.read_files readers Binding.empty tree with
  | [ file ] ->
      let result = Readable_file.read pack file in
      (result, List.rev !calls)
  | _ -> Alcotest.fail "one read file"

let unreadable what = function
  | Error (Readable_file.Cannot_be_read reason), _ -> what reason
  | _ -> false

let readable_file_cases () =
  let sigils = comment_sigils line_sigils in
  let result, calls =
    read_one "// a\n" (fun () -> (sigils, Reading.No_grammar))
  in
  Alcotest.(check bool)
    "no grammar: it cannot be read" true
    (unreadable (( = ) Readable_file.No_grammar) (result, calls));
  Alcotest.(check (list (pair string string)))
    "the pack reads the text at the valid path"
    [ ("lib/a.rs", "// a\n") ]
    calls;
  Alcotest.(check bool)
    "parse failure: it cannot be read" true
    (unreadable
       (( = ) Readable_file.Parse_failure)
       (read_one "// a\n" (fun () -> (sigils, Reading.Parse_failure))));
  let result, calls =
    read_one "// \xff\n" (fun () -> (sigils, Reading.Parsed []))
  in
  Alcotest.(check bool)
    "content that is not valid UTF-8 cannot be read" true
    (match result with
    | Error
        (Readable_file.Cannot_be_read
           (Readable_file.Not_utf_8 (Text.Invalid_utf_8 { place }))) ->
        place = 4
    | _ -> false);
  Alcotest.(check int)
    "the pack does not read such a file" 0 (List.length calls);
  let result, calls =
    read_one "// a\n" (fun () ->
        (sigils, Reading.Parsed [ reading_node (tagged (run 0 9)) ]))
  in
  Alcotest.(check bool)
    "a reading that fails the checks" true
    (match result with
    | Error (Readable_file.Invalid_reading (Reading.Not_a_run { node = 1 })) ->
        true
    | _ -> false);
  Alcotest.(check int) "one call" 1 (List.length calls);
  let result, calls =
    read_one ~markdown:true "# A\n" (fun () -> Alcotest.fail "no pack")
  in
  Alcotest.(check bool)
    "a markdown file can be read, with its lines" true
    (match result with
    | Ok (Readable_file.Markdown_file lines) ->
        Text.encode (Lines.text lines) = "# A\n"
    | _ -> false);
  Alcotest.(check int)
    "the pack is not called for a markdown file" 0 (List.length calls);
  Alcotest.(check bool)
    "a markdown file that is not valid UTF-8 cannot be read" true
    (match
       read_one ~markdown:true "\xff" (fun () -> Alcotest.fail "no pack")
     with
    | Error (Readable_file.Cannot_be_read (Readable_file.Not_utf_8 _)), [] ->
        true
    | _ -> false);
  let result, _ =
    read_one "// a\nfn f() {}\n" (fun () ->
        ( sigils,
          Reading.Parsed
            [
              reading_node (tagged (run 0 4));
              reading_node (definition (run 5 14));
            ] ))
  in
  match result with
  | Ok (Readable_file.Code_file file) ->
      Alcotest.(check string)
        "a code file can be read, with its path" "lib/a.rs"
        (Text.encode (Path.to_text (Code_file.path file)));
      Alcotest.(check int)
        "and its runs of comments" 1
        (List.length (Code_file.comment_runs file))
  | _ -> Alcotest.fail "a code file that can be read"

let contents_gen =
  Gen.oneof
    [
      Gen.map (fun (case : Code_gen.case) -> case.source) shaped_or_mixed;
      Gen.oneof_list [ ""; "\xff"; "a\xc3"; "\xef\xbb\xbf"; "// a\r" ];
    ]

let reading_gen length =
  Gen.oneof
    [
      Gen.return Reading.No_grammar;
      Gen.return Reading.Parse_failure;
      Gen.map
        (fun runs ->
          Reading.Parsed
            (List.map
               (fun (a, b, tagged) ->
                 reading_node
                   (if tagged then
                      { blank with R.run = run a b; comment = Some R.Tagged }
                    else { blank with R.run = run a b; decoration = true }))
               runs))
        (Gen.list_size (Gen.int_range 0 4)
           (Gen.triple
              (Gen.int_range (-1) (length + 1))
              (Gen.int_range (-1) (length + 1))
              Gen.bool));
    ]

let read_is_total =
  property ~count:500
    ~name:"read gives each read file a file or an error as the terms say"
    ~print:(fun (bytes, markdown, _) ->
      Printf.sprintf "%S markdown %b" bytes markdown)
    (Gen.bind contents_gen (fun bytes ->
         Gen.map
           (fun (markdown, result) -> (bytes, markdown, result))
           (Gen.pair Gen.bool (reading_gen (String.length bytes)))))
    (fun (bytes, markdown, result) ->
      let outcome, calls =
        read_one ~markdown bytes (fun () ->
            (comment_sigils line_sigils, result))
      in
      match (Text.decode bytes, markdown, result, outcome) with
      | ( Error e,
          _,
          _,
          Error (Readable_file.Cannot_be_read (Readable_file.Not_utf_8 e')) ) ->
          e = e' && calls = []
      | Ok _, true, _, Ok (Readable_file.Markdown_file _) -> calls = []
      | ( Ok _,
          false,
          Reading.No_grammar,
          Error (Readable_file.Cannot_be_read Readable_file.No_grammar) )
      | ( Ok _,
          false,
          Reading.Parse_failure,
          Error (Readable_file.Cannot_be_read Readable_file.Parse_failure) ) ->
          List.length calls = 1
      | Ok text, false, Reading.Parsed nodes, Ok (Readable_file.Code_file _) ->
          List.length calls = 1
          && Result.is_ok (Reading.check (Lines.of_text text) nodes)
      | ( Ok text,
          false,
          Reading.Parsed nodes,
          Error (Readable_file.Invalid_reading e) ) ->
          List.length calls = 1
          && Reading.check (Lines.of_text text) nodes = Error e
      | _ -> false)

let print_name path =
  String.concat " / "
    (List.map
       (fun own ->
         String.concat ""
           (List.map
              (function
                | Reading.Text_piece t -> Text.encode t
                | Reading.Placeholder t -> "<" ^ Text.encode t ^ ">")
              own))
       path)

let given_tests source sigils nodes =
  let outcome, _ =
    read_one source (fun () ->
        (comment_sigils sigils, Reading.Parsed (List.map reading_node nodes)))
  in
  match outcome with
  | Ok file ->
      List.map
        (fun (t : File_test.t) ->
          ( Text.encode (Path.to_text t.file),
            print_name t.name,
            print_run t.code,
            List.map print_run t.comments ))
        (File_test.of_file file)
  | Error _ -> Alcotest.fail "a code file that can be read"

(* @verifies documents#give-tests=v1
   For generated code files and readings, a test missing or given twice, a
   test with a name, a code, or a file other than its test node gives, a
   comment on a test missing, or a run of comments given as a comment that
   does not attach to a target with the run of the test node, differs from a
   direct reading of the terms file-test and attachment. *)
let tests_follow_the_terms =
  property ~count:800 ~name:"the tests of a code file are those of the terms"
    ~print:Code_gen.print shaped_or_mixed (fun case ->
      let text, nodes = reference_case case in
      let expected =
        List.map
          (fun (t : R.test) ->
            ( "lib/a.rs",
              print_name (List.map (List.map piece) t.name),
              print_run t.code,
              List.map print_run t.comments ))
          (R.tests text nodes)
      in
      let given = given_tests case.source case.sigils case.nodes in
      given = expected
      || QCheck2.Test.fail_reportf "given %d tests, expected %d"
           (List.length given) (List.length expected))

(* @verifies documents#give-tests=v1
   Each case gives a test node of a shape that no vector holds: two test nodes
   with one run, two tests whose codes start at one boundary, and a test whose
   own name has no piece. A test missing or
   given twice, or a comment on a test missing or not given with each test of
   its target's run, makes a case fail. *)
let test_cases () =
  let check what source sigils nodes expected =
    Alcotest.(check (list (pair (pair string string) (list string))))
      what expected
      (List.map
         (fun (_, name, code, comments) -> ((name, code), comments))
         (given_tests source sigils nodes))
  in
  let source = "// a\nfn t() {}\n" in
  check "two test nodes with one run are two tests, and each has the comment"
    source line_sigils
    [
      tagged (run 0 4);
      test_node ~name:[ [ R.Text_piece "s" ] ] (run 5 14);
      test_node ~name:[ [ R.Text_piece "s" ]; [ R.Text_piece "c" ] ] (run 5 14);
    ]
    [ (("s", "5-14"), [ "0-4" ]); (("s / c", "5-14"), [ "0-4" ]) ];
  check
    "of tests whose codes start at one boundary, the first in the list first"
    "describe(it())\n" line_sigils
    [
      test_node ~name:[ [ R.Text_piece "s" ] ] (run 0 14);
      test_node ~name:[ [ R.Text_piece "s" ]; [ R.Text_piece "c" ] ] (run 0 4);
    ]
    [ (("s", "0-14"), []); (("s / c", "0-4"), []) ];
  check "a test whose own name has no piece" "it()\n" line_sigils
    [ test_node ~name:[ [] ] (run 0 4) ]
    [ (("", "0-4"), []) ]

let tests_of_files_that_are_no_code_files () =
  Alcotest.(check int)
    "a markdown file has no test" 0
    (match
       read_one ~markdown:true "# A\n" (fun () -> Alcotest.fail "no pack")
     with
    | Ok file, _ -> List.length (File_test.of_file file)
    | _ -> -1);
  let result, _ =
    read_one "it()\n" (fun () ->
        ( comment_sigils line_sigils,
          Reading.Parsed [ reading_node (test_node (run 0 4)) ] ))
  in
  match result with
  | Ok file -> (
      match File_test.of_file file with
      | [ t ] ->
          Alcotest.(check string)
            "the file of the test" "lib/a.rs"
            (Text.encode (Path.to_text t.file))
      | _ -> Alcotest.fail "one test")
  | Error _ -> Alcotest.fail "a code file"

let tests =
  [
    code_characters_follow_the_term;
    Alcotest.test_case "code characters" `Quick code_character_cases;
    lines_of_runs_follow_the_term;
    Alcotest.test_case "the lines of runs" `Quick run_line_cases;
    comment_lines_follow_the_term;
    comment_lines_lie_in_the_lines_of_the_run;
    Alcotest.test_case "comment lines of each shape of comment" `Quick
      comment_line_cases;
    runs_of_comments_follow_the_terms;
    tag_texts_are_those_of_the_runs;
    tag_text_is_the_comment_lines_joined;
    file_lines_are_the_joined_lines;
    Alcotest.test_case "a code file keeps its path and its reading" `Quick
      a_file_keeps_its_path_and_reading;
    Alcotest.test_case "a code file with 300,000 comment nodes" `Quick
      many_comment_nodes;
    Alcotest.test_case
      "of targets with one run, the first in the list is the target" `Quick
      first_target_in_the_list;
    Alcotest.test_case
      "an enclosed comment node, and an empty tagged comment node" `Quick
      enclosed_and_empty_cases;
    Alcotest.test_case "untagged comment nodes give no comment line" `Quick
      untagged_nodes_give_no_lines;
    Alcotest.test_case
      "the last line number of a node whose run has its line feed" `Quick
      last_line_of_a_node_with_its_line_feed;
    Alcotest.test_case "the origin position of a tag line in a comment is its @"
      `Quick origins_of_code_tag_texts;
    Alcotest.test_case "a link over two comment lines" `Quick
      a_link_over_two_comment_lines;
    blocks_follow_the_term;
    no_two_blocks_share_a_line;
    Alcotest.test_case "blocks of tag texts" `Quick block_cases;
    Alcotest.test_case "files that can be read and files that cannot" `Quick
      readable_file_cases;
    read_is_total;
    tests_follow_the_terms;
    Alcotest.test_case "the tests of code files" `Quick test_cases;
    Alcotest.test_case "the tests of a markdown file and the file of a test"
      `Quick tests_of_files_that_are_no_code_files;
  ]
  @ List.map
      (fun (name, sigils, source, nodes, expected) ->
        Alcotest.test_case name `Quick
          (expect name sigils source nodes expected))
      (attachment_cases @ roles_cases)
