(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_origins
open Sinter_identifiers
open Sinter_inline_citations
open Sinter_markdown_tag_texts
open Sinter_markdown_limits
open Sinter_tag_inputs

let unlimited =
  Markdown_limits.{ size = max_int; brackets = max_int; containers = max_int }

let within lines = Result.get_ok (Markdown_limits.check unlimited lines)

module Gen = QCheck2.Gen

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let binding =
  match Binding.make [ ("gh", "[1-9][0-9]*") ] with
  | Ok binding -> binding
  | Error _ -> invalid_arg "binding"

let ok what holds = holds || QCheck2.Test.fail_reportf "%s" what
let read string = Markdown_file.read (within (Lines.of_text (text_of string)))
let lf = Uchar.of_int 0x0A
let is_wsp u = Uchar.to_int u = 0x20 || Uchar.to_int u = 0x09

let chars text { Text.from; until } =
  List.init (until - from) (fun k ->
      match Text.get text (from + k + 1) with
      | Some u -> u
      | None -> invalid_arg "chars")

let places source { Text.from; until } =
  List.init (until - from) (fun k -> Source.place source (from + k + 1))

let rec drop_wsp = function
  | (u, _) :: rest when is_wsp u -> drop_wsp rest
  | other -> other

let line_of tag_text k =
  match Tag_text.line tag_text k with
  | Some run -> run
  | None -> invalid_arg "line_of"

let with_places tag_text run =
  List.combine
    (chars (Tag_text.text tag_text) run)
    (places (Tag_text.source tag_text) run)

let expected_text tag_text first last =
  with_places tag_text (line_of tag_text first)
  @ List.concat_map
      (fun k ->
        (lf, None) :: drop_wsp (with_places tag_text (line_of tag_text k)))
      (List.init (last - first) (fun k -> first + k + 1))

let actual source =
  let text = Source.text source in
  let all = { Text.from = 0; until = Text.length text } in
  List.combine (chars text all) (places source all)

let position lines place =
  match Lines.character_position lines place with
  | Ok position -> Some position
  | Error _ -> None

let tag_line_inputs_are_those_of_identifiers markdown =
  let lines = Source.file (Markdown_file.markdown_text markdown) in
  let file_lines = Markdown_file.file_lines markdown in
  List.for_all
    (fun tag_text ->
      let inputs = Input.of_tag_text binding tag_text in
      let expected = Tag_line.read binding (Tag_text.text tag_text) in
      ok "the number of tag line inputs"
        (List.length inputs = List.length expected)
      && List.for_all2
           (fun input (want : Tag_line.input) ->
             match Input.kind input with
             | Input.Link _ -> false
             | Input.Tag_line { tag_text = own; first_line; last_line; result }
               ->
                 let text = expected_text tag_text first_line last_line in
                 let at =
                   match (result, drop_wsp text, text) with
                   | Tag_line.Not_a_tag_line, _, (_, place) :: _ -> place
                   | Tag_line.Not_a_tag_line, _, [] -> None
                   | _, (_, place) :: _, _ -> place
                   | _, [], _ -> None
                 in
                 let greatest =
                   List.fold_left
                     (fun acc (_, place) ->
                       match place with Some p -> max acc p | None -> acc)
                     0 text
                 in
                 ok "the tag text"
                   (Text.equal (Tag_text.text own) (Tag_text.text tag_text))
                 && ok "the first line" (first_line = want.first_line)
                 && ok "the last line" (last_line = want.last_line)
                 && ok "the result" (result = want.result)
                 && (Input.accepted input
                    = match result with Tag_line.Valid _ -> true | _ -> false)
                 && ok "the text of the tag line"
                      (actual (Input.text input) = text)
                 && ok "the origin run of the tag line"
                      (Input.origin_run input
                      = Option.map
                          (fun p -> { Text.from = p - 1; until = greatest })
                          at)
                 && ok "the origin position of the tag line"
                      (Input.origin_position input
                      = Option.bind at (position lines))
                 && ok "the file lines of the tag line"
                      (Input.file_lines file_lines input
                      = List.filter_map
                          (fun k ->
                            File_lines.of_tag_text_line file_lines tag_text k)
                          (List.init
                             (last_line - first_line + 1)
                             (fun k -> first_line + k))))
           inputs expected)
    (Markdown_file.tag_texts markdown)

let overlaps line origin =
  line.Text.from < line.Text.until
  && List.exists
       (fun r -> line.Text.from < r.Text.until && r.Text.from < line.Text.until)
       origin

let link_inputs_are_those_of_identifiers markdown =
  let source = Markdown_file.markdown_text markdown in
  let file_lines = Markdown_file.file_lines markdown in
  let inputs = Input.of_links binding source in
  let expected = Inline_citation.read binding (Source.text source) in
  ok "the number of links" (List.length inputs = List.length expected)
  && List.for_all2
       (fun input (want : Inline_citation.link) ->
         match Input.kind input with
         | Input.Tag_line _ -> false
         | Input.Link { source = own; link } ->
             let origin =
               match Source.origin source want.run with
               | Some o -> o
               | None -> []
             in
             ok "the source of the link"
               (Text.equal (Source.text own) (Source.text source))
             && ok "the link" (link = want)
             && (Input.accepted input
                =
                match want.result with
                | Inline_citation.Valid _ -> true
                | _ -> false)
             && ok "the text of the link"
                  (actual (Input.text input)
                  = List.combine
                      (chars (Source.text source) want.run)
                      (places source want.run))
             && ok "the origin run of the link"
                  (Input.origin_run input = Source.origin_run source want.run)
             && ok "the origin position of the link"
                  (Input.origin_position input
                  = Source.origin_position source want.run)
             && ok "the file lines of the link"
                  (Input.file_lines file_lines input
                  = List.filter
                      (fun line -> overlaps line origin)
                      (File_lines.all file_lines)))
       inputs expected

let line_pieces =
  [
    "# A [a](sinter:a)";
    "## B [b](sinter:b=v2) <sinter:gh#7>";
    "@req a=v1";
    "  @req b=v1 [x](sinter:b#c=v1)";
    "@cites {a=v1,";
    "   b=v1}";
    "\t@req t=v1";
    " \t@cites {a=v1,";
    "\t b=v1}";
    "@cites a=v1 {";
    "@verifies x[g][*]=v1";
    "@deprecated";
    "@ack a e3b0 x";
    "@extern req r";
    "@bogus x";
    "@req";
    "Text <sinter:gh#12>.";
    "[t](sinter:a \"title\")";
    "![i](sinter:a)";
    "";
    "- @req l=v1";
    "- [x] @cites {a=v1,";
    "  b=v1}";
    "> [q](sinter:q)";
    "[r]: sinter:r";
    "[r]";
    "    [c](sinter:c)";
    "---";
  ]

let markdown_gen =
  Gen.map2
    (fun lines bom ->
      (if bom then "\xef\xbb\xbf" else "")
      ^ String.concat "" (List.map (fun (line, ending) -> line ^ ending) lines))
    (Gen.list_size (Gen.int_range 0 10)
       (Gen.pair
          (Gen.oneof_list line_pieces)
          (Gen.oneof_list [ "\n"; "\r\n"; "\r" ])))
    (Gen.oneof_weighted [ (1, Gen.pure true); (5, Gen.pure false) ])

let links_of_tag_texts_are_those_of_identifiers markdown =
  List.for_all
    (fun tag_text ->
      let source = Tag_text.source tag_text in
      let inputs = Input.of_links binding source in
      let expected = Inline_citation.read binding (Tag_text.text tag_text) in
      ok "the number of links of a tag text"
        (List.length inputs = List.length expected)
      && List.for_all2
           (fun input (want : Inline_citation.link) ->
             match Input.kind input with
             | Input.Tag_line _ -> false
             | Input.Link { link; _ } ->
                 ok "the link of a tag text" (link = want)
                 && ok "the origin run of a link of a tag text"
                      (Input.origin_run input
                      = Source.origin_run source want.run))
           inputs expected)
    (Markdown_file.tag_texts markdown)

let inputs_follow_identifiers =
  property ~count:2000
    ~name:
      "the inputs of a markdown file are those that Identifiers gives, with \
       their origins" ~print:(Printf.sprintf "%S") markdown_gen (fun file ->
      let markdown = read file in
      tag_line_inputs_are_those_of_identifiers markdown
      && link_inputs_are_those_of_identifiers markdown
      && links_of_tag_texts_are_those_of_identifiers markdown)

let vector_files () =
  let set = Vectors.read "documents" in
  List.iter
    (fun (vector : Vectors.vector) ->
      match vector.input with
      | `Assoc fields -> (
          match List.assoc_opt "files" fields with
          | Some (`Assoc files) ->
              List.iter
                (fun (path, value) ->
                  match value with
                  | `String content when Filename.check_suffix path ".md" ->
                      let markdown = read content in
                      Alcotest.(check bool)
                        (Printf.sprintf "vector %d, %s" vector.number path)
                        true
                        (tag_line_inputs_are_those_of_identifiers markdown
                        && link_inputs_are_those_of_identifiers markdown)
                  | _ -> ())
                files
          | _ -> ())
      | _ -> ())
    (Vectors.vectors set "markdown" @ Vectors.vectors set "code")

let first_input file =
  match Markdown_file.tag_texts (read file) with
  | tag_text :: _ -> (
      match Input.of_tag_text binding tag_text with
      | input :: _ -> input
      | [] -> Alcotest.fail "no input")
  | [] -> Alcotest.fail "no tag text"

let a_tag_line_starts_at_its_at_sign () =
  let input = first_input "# A\n   @req r=v1\n" in
  Alcotest.(check bool)
    "the origin position" true
    (Input.origin_position input = Some { Lines.line = 2; column = 4 });
  Alcotest.(check bool)
    "the origin run" true
    (Input.origin_run input = Some { Text.from = 7; until = 16 });
  Alcotest.(check bool) "accepted" true (Input.accepted input)

let a_citation_takes_its_continuation_lines () =
  let file = "# A\n@cites {a=v1,\n   b=v1}\nText.\n" in
  let markdown = read file in
  match Markdown_file.tag_texts markdown with
  | [ tag_text ] -> (
      match Input.of_tag_text binding tag_text with
      | [ citation; prose ] ->
          Alcotest.(check string)
            "the text of the citation" "@cites {a=v1,\nb=v1}"
            (Text.encode (Source.text (Input.text citation)));
          Alcotest.(check bool) "accepted" true (Input.accepted citation);
          Alcotest.(check bool)
            "its file lines" true
            (Input.file_lines (Markdown_file.file_lines markdown) citation
            = [ { Text.from = 4; until = 17 }; { Text.from = 18; until = 26 } ]
            );
          Alcotest.(check bool)
            "prose is not accepted" false (Input.accepted prose)
      | _ -> Alcotest.fail "two inputs")
  | _ -> Alcotest.fail "one tag text"

let links_follow_front_matter () =
  let file = "---\nx\n---\n# A [a](sinter:a=v1)\n" in
  let markdown = read file in
  match Input.of_links binding (Markdown_file.markdown_text markdown) with
  | [ input ] ->
      Alcotest.(check bool)
        "the origin position" true
        (Input.origin_position input = Some { Lines.line = 4; column = 5 });
      Alcotest.(check bool)
        "the origin run" true
        (Input.origin_run input = Some { Text.from = 14; until = 30 });
      Alcotest.(check bool) "accepted" true (Input.accepted input)
  | _ -> Alcotest.fail "one link"

let an_inline_citation_in_a_heading_is_an_input () =
  let markdown = read "# [a](sinter:a)\n" in
  match Input.of_links binding (Markdown_file.markdown_text markdown) with
  | [ input ] ->
      Alcotest.(check bool)
        "the origin position" true
        (Input.origin_position input = Some { Lines.line = 1; column = 3 })
  | _ -> Alcotest.fail "one link"

let tests =
  [
    inputs_follow_identifiers;
    Alcotest.test_case "the inputs of the vector files follow Identifiers"
      `Quick vector_files;
    Alcotest.test_case "a tag line starts at its @" `Quick
      a_tag_line_starts_at_its_at_sign;
    Alcotest.test_case "a citation takes its continuation lines" `Quick
      a_citation_takes_its_continuation_lines;
    Alcotest.test_case
      "the links of a markdown text come after its front matter" `Quick
      links_follow_front_matter;
    Alcotest.test_case "an inline citation in a heading is an input" `Quick
      an_inline_citation_in_a_heading_is_an_input;
  ]
