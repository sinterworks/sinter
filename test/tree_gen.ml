(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_identifiers
open Sinter_file_readers
open Sinter_readings
open Sinter_code_tag_texts
open Sinter_markdown_limits

let unlimited =
  Markdown_limits.{ size = max_int; brackets = max_int; containers = max_int }

module Gen = QCheck2.Gen
module R = Code_reference

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let path_of string =
  match Path.of_text (text_of string) with
  | Ok path -> path
  | Error _ -> invalid_arg "path_of"

let path_text path = Text.encode (Path.to_text path)

type code_file = {
  sigils : Code_reference.sigils;
  nodes : Code_reference.node list;
}

type case = { files : (string * string) list; code : (string * code_file) list }

let declarations =
  [
    "@design a=v1";
    "@design b=v1";
    "@design a/b=v1";
    "@design a.x=v1";
    "@spec x=v1";
    "@spec x=v2";
    "@spec a#x=v1";
    "@spec b#y=v1";
    "@spec a/b#z=v1";
    "@req r=v1";
    "@req a#r=v1";
    "@req q=v2 A description.";
    "@req a/b=v1";
    "@req d#s=v1";
    "@term t";
    "@term a#t=v1";
    "@term u=v1";
    "@decision a=v1";
    "@decision e=v1";
    "@finding-class fc=v1";
  ]

let other_tag_lines =
  [
    "@cites a#r=v1";
    "@cites {";
    "  #x=v1,";
    "}";
    "@verifies #r=v1";
    "@ack a abc";
    "@deprecated";
    "@req bad";
    "@extern spec:x";
    "  @req r=v1";
  ]

let prose =
  [
    "Text.";
    "More [x](sinter:#r=v1) text.";
    "[l](sinter:a#x=v1)";
    "<sinter:b#y=v1>";
    "Text with trailing space.  ";
  ]

let blanks = [ ""; "  "; "\t" ]

let tag_line_gen =
  Gen.oneof_weighted
    [
      (4, Gen.oneof_list declarations);
      (1, Gen.oneof_list other_tag_lines);
      (2, Gen.oneof_list prose);
    ]

let paragraph_gen = Gen.list_size (Gen.int_range 1 4) tag_line_gen

let block_gen =
  let open Gen in
  oneof_weighted
    [
      ( 3,
        oneof_list
          [
            "# A"; "## 1. B"; "### 1.1 C"; "## D"; "#### E [c](sinter:#t)"; "#";
          ]
        |> map (fun h -> [ h ]) );
      (5, paragraph_gen);
      ( 2,
        map2
          (fun bullet lines ->
            match lines with
            | first :: rest ->
                (bullet ^ first) :: List.map (fun l -> "  " ^ l) rest
            | [] -> [])
          (oneof_list [ "- "; "* "; "1. "; "- [x] "; "  - "; "    - " ])
          paragraph_gen );
      (1, map (fun l -> [ "> " ^ l ]) tag_line_gen);
      (1, map (fun l -> [ "    " ^ l ]) tag_line_gen);
      (1, map (fun l -> [ "```"; l; "```" ]) tag_line_gen);
      (1, map (fun l -> [ l; "---" ]) tag_line_gen);
      (3, map (fun b -> [ b ]) (oneof_list blanks));
    ]

let markdown_gen =
  let open Gen in
  let* front = oneof_weighted [ (5, return ""); (1, return "---\na: b\n---\n") ]
  and* blocks = list_size (int_range 0 10) block_gen
  and* ending = oneof_weighted [ (6, return "\n"); (1, return "\r\n") ]
  and* last = bool in
  let lines = List.concat blocks in
  let body = String.concat ending lines ^ if last then ending else "" in
  return (front ^ body)

let markdown_paths =
  [ "docs/a.md"; "docs/b.md"; "docs/x/c.md"; "README.md"; "a.md" ]

let vector_paths =
  [
    "docs/a.test-vectors.jsonl";
    "docs/a.x.test-vectors.jsonl";
    "docs/a/b.test-vectors.jsonl";
    "docs/b.y.test-vectors.jsonl";
    "docs/x/a.test-vectors.jsonl";
    "a.test-vectors.jsonl";
    "b.test-vectors.jsonl";
    "a.x.test-vectors.jsonl";
    "d.s.test-vectors.jsonl";
    "lib/d.test-vectors.jsonl";
  ]

let substitutions =
  [
    ( "@req a=v1",
      [
        "@req a=v1";
        "@term a#b";
        "@spec s=x";
        "@req r=v1";
        "@term t=1";
        "@design q";
      ] );
    ("@req b=v1", [ "@req b=v1"; "@spec x=1"; "@term t=1"; "@req a#r1" ]);
    ( "@spec d#s=v1",
      [
        "@spec d#s=v1";
        "@spec d#s=v1";
        "@spec d#s=v1";
        "@req d#r=v12";
        "@req d#r=v12";
        "@term d#t=v1";
        "@spec seg=v1";
        "@spec a#x=v1";
        "@design d=v1";
      ] );
    ( "@cites c=v1",
      [
        "@cites c=v1";
        "@req e#r=v1";
        "@spec s2=v1";
        "@design e=1";
        "@req a#r=v1";
        "@term a#t=1";
      ] );
    ( "@verifies x#y=v2",
      [
        "@verifies x#y=v2";
        "@spec a#x=v1 Txt";
        "@req a#r=v1 Text";
        "@design a=v1 Txt";
      ] );
  ]

let replace_all source token replacement =
  if String.length token <> String.length replacement then
    invalid_arg "replace_all";
  let n = String.length token in
  let buffer = Buffer.create (String.length source) in
  let rec go k =
    if k > String.length source - n then
      Buffer.add_string buffer (String.sub source k (String.length source - k))
    else if String.sub source k n = token then (
      Buffer.add_string buffer replacement;
      go (k + n))
    else (
      Buffer.add_char buffer source.[k];
      go (k + 1))
  in
  go 0;
  Buffer.contents buffer

let code_gen =
  let open Gen in
  let* case = oneof [ Code_gen.shaped; Code_gen.mixed ] in
  let* choices =
    flatten_list
      (List.map
         (fun (token, options) ->
           map (fun r -> (token, r)) (oneof_list options))
         substitutions)
  in
  let source =
    List.fold_left
      (fun source (token, replacement) -> replace_all source token replacement)
      case.Code_gen.source choices
  in
  return (source, { sigils = case.Code_gen.sigils; nodes = case.Code_gen.nodes })

type line_item =
  | Comments of string list
  | Line of string
  | Decoration
  | Definition of { test : bool; items : line_item list }

let comment_contents =
  [
    "@spec d#s=v1";
    "@spec d#s=v1";
    "@spec seg=v1";
    "@req d#r=v1";
    "@req r=v1";
    "@req q=v1 Text.";
    "@term d#t=v1";
    "@term t";
    "@design d=v1";
    "@cites d#s=v1";
    "@verifies #r=v1";
    "Text.";
    "";
  ]

let rec line_items_gen depth =
  let open Gen in
  list_size (int_range 0 5)
    (oneof_weighted
       ([
          ( 4,
            map
              (fun lines -> Comments lines)
              (list_size (int_range 1 3) (oneof_list comment_contents)) );
          (2, map (fun l -> Line l) (oneof_list [ "x();"; ""; "  " ]));
          (1, return Decoration);
        ]
       @
       if depth = 0 then []
       else
         [
           ( 2,
             map2
               (fun test items -> Definition { test; items })
               bool
               (line_items_gen (depth - 1)) );
         ]))

let render_lines items =
  let buffer = Buffer.create 64 in
  let nodes = ref [] in
  let emit node = nodes := node :: !nodes in
  let add s = Buffer.add_string buffer s in
  let at () = Buffer.length buffer in
  let rec item indent = function
    | Comments lines ->
        List.iter
          (fun line ->
            add indent;
            let from = at () in
            add ("// " ^ line);
            emit
              {
                R.run = { Text.from; until = at () };
                comment = Some R.Tagged;
                body = None;
                decoration = false;
                test = None;
              };
            add "\n")
          lines
    | Line l -> add (indent ^ l ^ "\n")
    | Decoration ->
        add indent;
        let from = at () in
        add "#[test]";
        emit
          {
            R.run = { Text.from; until = at () };
            comment = None;
            body = None;
            decoration = true;
            test = None;
          };
        add "\n"
    | Definition { test; items } ->
        add indent;
        let from = at () in
        add "fn f() ";
        let body_from = at () in
        add "{\n";
        let saved = !nodes in
        nodes := [];
        List.iter (item (indent ^ "  ")) items;
        let inner = !nodes in
        add indent;
        add "}";
        let until = at () in
        nodes :=
          inner
          @ {
              R.run = { Text.from; until };
              comment = None;
              body = Some [ { Text.from = body_from; until } ];
              decoration = false;
              test = (if test then Some [ [ R.Text_piece "f" ] ] else None);
            }
            :: saved;
        add "\n"
  in
  List.iter (item "") items;
  (Buffer.contents buffer, List.rev !nodes)

let line_code_gen =
  Gen.map
    (fun items ->
      let source, nodes = render_lines items in
      (source, { sigils = { R.line = [ "//" ]; block = []; inner = [] }; nodes }))
    (line_items_gen 2)

let subset ?(weight = 2) list =
  Gen.map
    (fun flags -> List.filteri (fun k _ -> List.nth flags k) list)
    (Gen.list_size
       (Gen.return (List.length list))
       (Gen.oneof_weighted [ (weight, Gen.return true); (3, Gen.return false) ]))

let case =
  let open Gen in
  let* markdown_paths = subset markdown_paths in
  let* markdown =
    flatten_list
      (List.map
         (fun path -> map (fun c -> (path, c)) markdown_gen)
         markdown_paths)
  in
  let* vectors = subset vector_paths in
  let* code_paths = subset ~weight:4 [ "lib/a.rs"; "lib/b.ml" ] in
  let* code =
    flatten_list
      (List.map
         (fun path ->
           map (fun c -> (path, c)) (oneof [ code_gen; line_code_gen ]))
         code_paths)
  in
  let* with_d = oneof_weighted [ (3, return true); (1, return false) ] in
  let d =
    if code <> [] && with_d then [ ("docs/d.md", "# D\n@design d=v1\n") ]
    else []
  in
  return
    {
      files =
        markdown @ d
        @ List.map (fun path -> (path, "{\"rev\":\"v1\"}\n")) vectors
        @ List.map (fun (path, (source, _)) -> (path, source)) code;
      code = List.map (fun (path, (_, file)) -> (path, file)) code;
    }

let print { files; code } =
  String.concat "\n"
    (List.map
       (fun (path, content) ->
         match List.assoc_opt path code with
         | Some file ->
             Printf.sprintf "%s:\n%s" path
               (Code_gen.print
                  {
                    Code_gen.sigils = file.sigils;
                    source = content;
                    nodes = file.nodes;
                  })
         | None -> Printf.sprintf "%s: %S" path content)
       files)

let sigils (s : R.sigils) =
  {
    Comment_sigils.line = List.map text_of s.line;
    block = List.map (fun (a, b) -> (text_of a, text_of b)) s.block;
    inner = List.map text_of s.inner;
  }

let piece = function
  | R.Text_piece t -> Reading.Text_piece (text_of t)
  | R.Placeholder t -> Reading.Placeholder (text_of t)

let node (n : R.node) =
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

let namespaces =
  match Binding.make [ ("gh", "[1-9][0-9]*") ] with
  | Ok binding -> binding
  | Error _ -> invalid_arg "namespaces"

let read (case : case) =
  let tree =
    match
      Tree.of_files
        (List.map (fun (path, bytes) -> (path_of path, bytes)) case.files)
    with
    | Ok tree -> tree
    | Error _ -> invalid_arg "build"
  in
  let readers =
    match
      File_readers.make
        [
          (File_readers.Markdown, [ text_of "*.md"; text_of "**/*.md" ]);
          (File_readers.Pack (), [ text_of "lib/*.rs"; text_of "lib/*.ml" ]);
        ]
    with
    | Ok readers -> readers
    | Error _ -> invalid_arg "build"
  in
  let pack () path _text =
    match List.assoc_opt (path_text path) case.code with
    | Some file ->
        (sigils file.sigils, Reading.Parsed (List.map node file.nodes))
    | None ->
        (sigils { R.line = []; block = []; inner = [] }, Reading.No_grammar)
  in
  let readables =
    List.filter_map
      (fun file ->
        match Readable_file.read unlimited pack file with
        | Ok readable -> Some (path_text (Read_file.path file), readable)
        | Error _ -> None)
      (Read_file.read_files readers namespaces tree)
  in
  (tree, readables)
