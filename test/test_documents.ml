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
open Sinter_tree_inputs
open Sinter_tree_items

let unlimited =
  Markdown_limits.{ size = max_int; brackets = max_int; containers = max_int }

module Gen = QCheck2.Gen

let property ?(count = 300) ~name ~print generator check =
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

let path_text path = Text.encode (Path.to_text path)

let member name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let string = function
  | `String text -> text
  | other -> Alcotest.failf "not a string: %s" (Yojson.Basic.to_string other)

let list = function
  | `List items -> items
  | other -> Alcotest.failf "not an array: %s" (Yojson.Basic.to_string other)

let fields = function
  | `Assoc fields -> fields
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let content = function
  | `String text -> text
  | `Assoc [ ("bytes", `String digits) ] -> Vector_json.of_hex digits
  | other -> Alcotest.failf "not a content: %s" (Yojson.Basic.to_string other)

let files input =
  List.map
    (fun (path, value) -> (path, content value))
    (fields (member "files" input))

let tree input =
  match
    Tree.of_files
      (List.map (fun (path, bytes) -> (path_of path, bytes)) (files input))
  with
  | Ok tree -> tree
  | Error _ -> Alcotest.fail "a vector repeats a valid path"

let path_set json = List.map (fun member -> text_of (string member)) (list json)

let reader_pairs ~group input =
  List.map
    (fun pair ->
      if String.equal group "markdown" then
        (File_readers.Markdown, path_set pair)
      else
        let reader =
          match member "reader" pair with
          | `String "markdown" -> File_readers.Markdown
          | `Assoc _ as pack -> File_readers.Pack pack
          | other ->
              Alcotest.failf "not a reader: %s" (Yojson.Basic.to_string other)
        in
        (reader, path_set (member "paths" pair)))
    (list (member "file-readers" input))

let namespaces input =
  Binding.make
    (List.map
       (fun pair ->
         ( string (member "namespace-name" pair),
           string (member "id-pattern" pair) ))
       (list (member "external-namespaces" input)))

type 'pack given = {
  read_files : 'pack Read_file.t list;
  tests : File_test.t list;
  declared : Declared_items.t;
}

let read_files_member given =
  `Assoc
    (List.map
       (fun file ->
         (path_text (Read_file.path file), `Int (Read_file.pair file)))
       given.read_files)

let texts json = List.map (fun s -> text_of (string s)) (list json)

let sigils pack =
  {
    Comment_sigils.line = texts (member "line" pack);
    block =
      List.map
        (fun pair ->
          match list pair with
          | [ opening; closing ] ->
              (text_of (string opening), text_of (string closing))
          | _ -> Alcotest.fail "a block pair is two texts")
        (list (member "block" pack));
    inner = texts (member "inner" pack);
  }

let run_of json =
  match (member "from" json, member "to" json) with
  | `Int from, `Int until -> { Text.from; until }
  | _ -> Alcotest.fail "not a run"

let json_of_run { Text.from; until } =
  `Assoc [ ("from", `Int from); ("to", `Int until) ]

let piece_of = function
  | `Assoc [ ("text", `String t) ] -> Reading.Text_piece (text_of t)
  | `Assoc [ ("placeholder", `String t) ] -> Reading.Placeholder (text_of t)
  | other -> Alcotest.failf "not a piece: %s" (Yojson.Basic.to_string other)

let json_of_piece = function
  | Reading.Text_piece t -> `Assoc [ ("text", `String (Text.encode t)) ]
  | Reading.Placeholder t -> `Assoc [ ("placeholder", `String (Text.encode t)) ]

let node_of json =
  let field name = List.assoc_opt name (fields json) in
  {
    Reading.run = run_of (member "run" json);
    comment =
      (match field "comment" with
      | Some (`String "tagged") -> Some Reading.Tagged
      | Some (`String "untagged") -> Some Reading.Untagged
      | None -> None
      | Some other ->
          Alcotest.failf "not a comment: %s" (Yojson.Basic.to_string other));
    body = Option.map (fun runs -> List.map run_of (list runs)) (field "body");
    decoration = field "decoration" = Some (`Bool true);
    test =
      Option.map
        (fun path ->
          List.map (fun own -> List.map piece_of (list own)) (list path))
        (field "test");
  }

let reading_of pack path =
  match List.assoc_opt (path_text path) (fields (member "readings" pack)) with
  | None -> Alcotest.failf "no reading of %s" (path_text path)
  | Some reading -> (
      match member "result" reading with
      | `String "no grammar" -> Reading.No_grammar
      | `String "parse failure" -> Reading.Parse_failure
      | `String "parsed" ->
          Reading.Parsed (List.map node_of (list (member "nodes" reading)))
      | other ->
          Alcotest.failf "not a result: %s" (Yojson.Basic.to_string other))

let pack_reading pack path _text = (sigils pack, reading_of pack path)

let tests_member given =
  `List
    (List.map
       (fun (test : File_test.t) ->
         `Assoc
           [
             ("file", `String (path_text test.file));
             ( "name",
               `List
                 (List.map
                    (fun own -> `List (List.map json_of_piece own))
                    test.name) );
             ("code", json_of_run test.code);
             ("comments", `List (List.map json_of_run test.comments));
           ])
       given.tests)

let not_given_members = [ "extent-hash"; "hash-text" ]

let with_stated_members stated given =
  let stated =
    match List.assoc_opt "items" stated with
    | Some (`List items) -> items
    | _ -> []
  in
  `List
    (List.mapi
       (fun k element ->
         match (element, List.nth_opt stated k) with
         | `Assoc members, Some (`Assoc s) ->
             `Assoc
               (members
               @ List.filter
                   (fun (name, _) -> List.mem name not_given_members)
                   s)
         | _ -> element)
       (list given))

let members stated =
  let items given =
    with_stated_members stated (Items_json.of_declared given.declared)
  in
  function
  | "code" ->
      [
        ("read-files", read_files_member);
        ("tests", tests_member);
        ("items", items);
      ]
  | _ -> [ ("read-files", read_files_member); ("items", items) ]

let tree_files binding read_files =
  List.filter_map
    (fun file ->
      match Readable_file.read unlimited pack_reading file with
      | Ok readable ->
          Some (Tree_file.make binding (Read_file.path file) readable)
      | Error _ -> None)
    read_files

let file_tests read_files =
  List.concat_map
    (fun file ->
      match Readable_file.read unlimited pack_reading file with
      | Ok readable -> File_test.of_file readable
      | Error (Readable_file.Cannot_be_read _) -> []
      | Error (Readable_file.Invalid_reading _) ->
          Alcotest.fail "a vector gives a reading that fails the checks")
    read_files

let give (vector : Vectors.vector) =
  let input = vector.input in
  let values =
    match
      ( File_readers.make (reader_pairs ~group:vector.group input),
        namespaces input )
    with
    | Ok readers, Ok binding ->
        let tree = tree input in
        let read_files = Read_file.read_files readers binding tree in
        let declared =
          match Declared_items.make tree (tree_files binding read_files) with
          | Ok declared -> declared
          | Error _ -> Alcotest.fail "two read files have one valid path"
        in
        let given = { read_files; tests = file_tests read_files; declared } in
        let stated =
          match vector.values with Some (`Assoc fields) -> fields | _ -> []
        in
        let members = members stated vector.group in
        let not_given =
          List.filter
            (fun (name, _) -> not (List.mem_assoc name members))
            stated
        in
        `Assoc
          (not_given @ List.map (fun (name, give) -> (name, give given)) members)
    | _ -> `Assoc []
  in
  `Assoc [ ("values", values) ]

let set = Vectors.read "documents"

(* @verifies documents[markdown]
   The test compares the read files that the program gives, and the declared
   items, each with its kind, name, file, origin position, extent, design,
   specification, and vector file, in the order of the member, with the
   members read-files and items of each vector of the group, and checks that
   the program gives none of them under bindings that are not valid, by the
   values {}. The program gives no extent hash or hash text, so the test
   checks it on no member of these. *)
let markdown_vectors =
  Vectors.group set ~name:"markdown" ~form:"#markdown-vector=v1" give

(* @verifies documents[code]
   The test compares the read files that the program gives, each with the pair
   of its reader, and the tests of the read files, each with its file, name,
   code, and comments, and the declared items, each with its kind, name, file,
   origin position, extent, design, specification, and vector file, in the
   order of each member, with the members read-files, tests, and items of each
   vector of the group. The program gives no extent hash, hash text, or code
   hash, so the test checks it on no member of these. *)
let code_vectors = Vectors.group set ~name:"code" ~form:"#code-vector=v1" give
let vector_groups = [ code_vectors; markdown_vectors ]

let proposed_vectors =
  List.mapi
    (fun index line ->
      let json = Yojson.Basic.from_string line in
      let field name = List.assoc_opt name (fields json) in
      ( (match field "note" with Some (`String note) -> note | _ -> ""),
        {
          Vectors.line = index + 1;
          group = string (member "group" json);
          input = member "input" json;
          result = None;
          values = field "values";
          needs = [];
        } ))
    (List.filter
       (fun line -> line <> "")
       (String.split_on_char '\n'
          (In_channel.with_open_bin "fixtures/documents-proposed.jsonl"
             In_channel.input_all)))

(* @verifies documents#give-vector-files=v1
   Each case is a tree for which the term vector-file gives a vector file, or
   none, that no vector of the file checks: a design at the root; a
   specification of no design; a specification of a markdown file and one of
   a code file, each in another folder than its design; two designs with one
   name in two folders, and in one folder; and a requirement and a term. A
   wrong vector path, or a vector file given where the term gives none, makes
   the member items differ. *)
let proposed_vectors_pass =
  List.map
    (fun (note, (vector : Vectors.vector)) ->
      Alcotest.test_case note `Quick (fun () ->
          let given = member "values" (give vector) in
          match vector.values with
          | Some stated ->
              if not (Vectors.equal_json stated given) then
                Alcotest.failf "line %d\nstated %s\ngiven %s" vector.line
                  (Yojson.Basic.to_string stated)
                  (Yojson.Basic.to_string given)
          | None -> Alcotest.fail "a proposed vector has values"))
    proposed_vectors

let member_texts =
  [
    "docs/";
    "docs/**/*.md";
    "*.md";
    "**";
    "!docs/old/";
    "!*.md";
    "a";
    "docs/**.md";
    "a/**/";
    "";
    "!";
  ]

let path_names =
  [
    "a";
    "a.md";
    "b.md";
    "docs/a.md";
    "docs/old/b.md";
    " c.md";
    "c.md ";
    "\tc.md";
    "c.md\t";
    "docs/ x.md";
    "d\ne.md";
    "e.md\n";
    "\ne.md";
    "docs/c\r.md";
    "\xc3\xa9.md";
    "docs/old/\xc3\xa9";
  ]

let contents = [ ""; "# A\n"; "\xff"; "a\r\nb"; "\xef\xbb\xbf@req a=v1\n" ]

let pair_gen =
  Gen.pair (Gen.int_range 0 2)
    (Gen.list_size (Gen.int_range 0 3) (Gen.oneof_list member_texts))

let binding_gen = Gen.list_size (Gen.int_range 0 4) pair_gen

let files_gen =
  Gen.map
    (fun files ->
      List.fold_left
        (fun kept (path, bytes) ->
          if List.mem_assoc path kept then kept else kept @ [ (path, bytes) ])
        [] files)
    (Gen.list_size (Gen.int_range 0 8)
       (Gen.pair (Gen.oneof_list path_names) (Gen.oneof_list contents)))

let print_case (binding, files) =
  Printf.sprintf "binding [%s]; files [%s]"
    (String.concat "; "
       (List.map
          (fun (reader, texts) ->
            Printf.sprintf "%d: %s" reader
              (String.concat " " (List.map (Printf.sprintf "%S") texts)))
          binding))
    (String.concat "; "
       (List.map (fun (path, bytes) -> Printf.sprintf "%S %S" path bytes) files))

let reader_of k = if k = 0 then File_readers.Markdown else File_readers.Pack k

let make binding =
  File_readers.make
    (List.map
       (fun (reader, texts) -> (reader_of reader, List.map text_of texts))
       binding)

let sorted_files files =
  List.map
    (fun (path, bytes) -> (path_text path, bytes))
    (Tree.files
       (match
          Tree.of_files
            (List.map (fun (path, bytes) -> (path_of path, bytes)) files)
        with
       | Ok tree -> tree
       | Error _ -> invalid_arg "sorted_files"))

let tree_of files =
  match
    Tree.of_files (List.map (fun (path, bytes) -> (path_of path, bytes)) files)
  with
  | Ok tree -> tree
  | Error _ -> invalid_arg "tree_of"

(* @verifies documents#give-read-files=v1
   For generated trees and bindings, a read file given twice, a read file
   missing, a file given that is not a read file, or a reader other than that
   of the first pair whose path set has the path, differs from a direct
   reading of the schema file-readers and the terms file-reader and
   read-file. *)
let read_files_follow_the_terms =
  property ~count:1000 ~name:"the read files are those of the terms"
    ~print:print_case (Gen.pair binding_gen files_gen) (fun (binding, files) ->
      match
        ( make binding,
          Documents_reference.read_files binding (sorted_files files) )
      with
      | Error _, None -> true
      | Ok _, None | Error _, Some _ -> false
      | Ok readers, Some expected ->
          let given =
            Read_file.read_files readers Binding.empty (tree_of files)
          in
          let other =
            match Binding.make [ ("gh", "[1-9][0-9]*") ] with
            | Ok binding -> Read_file.read_files readers binding (tree_of files)
            | Error _ -> []
          in
          List.map (fun file -> Read_file.path file) other
          = List.map (fun file -> Read_file.path file) given
          && List.map
               (fun file ->
                 (path_text (Read_file.path file), Read_file.pair file))
               given
             = expected
          && List.for_all
               (fun file ->
                 let k = Read_file.pair file in
                 Read_file.reader file
                 = reader_of (fst (List.nth binding (k - 1))))
               given)

(* @verifies documents#{file-readers=v1, give-nothing-under-invalid-bindings=v1}
   A binding of file-readers with a path set that is not valid does not meet
   the schema file-readers and would give a value from which read files follow;
   the test checks that File_readers.make refuses every such binding at its
   first invalid pair. *)
let no_binding_from_invalid_path_sets =
  property ~count:1000
    ~name:"a binding with a path set that is not valid is refused"
    ~print:print_case (Gen.pair binding_gen files_gen) (fun (binding, _) ->
      let valid texts =
        Documents_reference.read_files [ ((), texts) ] [] <> None
      in
      let globs texts =
        Result.is_ok (Path_set.of_texts (List.map text_of texts))
      in
      let first_bad =
        let rec find k = function
          | [] -> None
          | (_, texts) :: rest ->
              if valid texts then find (k + 1) rest else Some (k, globs texts)
        in
        find 1 binding
      in
      match (make binding, first_bad) with
      | Ok _, None -> true
      | Error (File_readers.Invalid_glob { pair; _ }), Some (k, false)
      | Error (File_readers.Invalid_path_set { pair; _ }), Some (k, true) ->
          pair = k
      | _ -> false)

let reader_is_that_of_the_first_pair =
  property ~count:1000
    ~name:
      "the reader of a valid path is that of the first pair whose set has it"
    ~print:print_case (Gen.pair binding_gen files_gen) (fun (binding, files) ->
      match make binding with
      | Error _ -> true
      | Ok readers ->
          List.for_all
            (fun (path, _) ->
              let valid = path_of path in
              let rec first k = function
                | [] -> None
                | (_, set) :: rest ->
                    if Path_set.mem set valid then Some k
                    else first (k + 1) rest
              in
              File_readers.reader readers valid
              = Option.map
                  (fun k -> (k, reader_of (fst (List.nth binding (k - 1)))))
                  (first 1 (File_readers.pairs readers)))
            files)

let errors_carry_what_path_sets_give =
  property ~count:1000
    ~name:"an error of make carries the error or the fault of its path set"
    ~print:print_case (Gen.pair binding_gen files_gen) (fun (binding, _) ->
      let of_pair k = List.map text_of (snd (List.nth binding (k - 1))) in
      match make binding with
      | Ok _ -> true
      | Error (File_readers.Invalid_glob { pair; error }) -> (
          match Path_set.of_texts (of_pair pair) with
          | Error found -> found = error
          | Ok _ -> false)
      | Error (File_readers.Invalid_path_set { pair; fault }) -> (
          match Path_set.of_texts (of_pair pair) with
          | Ok set -> Path_set.validate set = Error fault
          | Error _ -> false))

let pairs_keep_the_binding () =
  match
    File_readers.make
      [
        (File_readers.Pack 7, [ text_of "lib/" ]);
        (File_readers.Markdown, [ text_of "docs/"; text_of "!docs/old/" ]);
      ]
  with
  | Error _ -> Alcotest.fail "the binding is valid"
  | Ok readers ->
      let pairs = File_readers.pairs readers in
      Alcotest.(check int) "two pairs" 2 (List.length pairs);
      Alcotest.(check bool)
        "the readers in order" true
        (List.map fst pairs = [ File_readers.Pack 7; File_readers.Markdown ]);
      List.iter2
        (fun (_, set) (path, inside) ->
          Alcotest.(check bool) path inside (Path_set.mem set (path_of path)))
        pairs
        [ ("lib/a.ml", true); ("docs/old/a.md", false) ];
      Alcotest.(check bool)
        "the reader of a path" true
        (File_readers.reader readers (path_of "docs/a.md")
        = Some (2, File_readers.Markdown));
      Alcotest.(check bool)
        "a path with no reader" true
        (File_readers.reader readers (path_of "docs/old/a.md") = None)

let an_empty_binding_reads_no_file () =
  match File_readers.make [] with
  | Error _ -> Alcotest.fail "the empty binding is valid"
  | Ok readers ->
      Alcotest.(check int)
        "no read file" 0
        (List.length
           (Read_file.read_files readers Binding.empty
              (tree_of [ ("a.md", "# A\n") ])))

let read_files_give_their_lines () =
  match File_readers.make [ (File_readers.Markdown, [ text_of "**" ]) ] with
  | Error _ -> Alcotest.fail "the binding is valid"
  | Ok readers -> (
      let tree =
        tree_of [ ("b.md", "\xff"); ("a.md", "\xef\xbb\xbf# A\r\n") ]
      in
      match Read_file.read_files readers Binding.empty tree with
      | [ a; b ] -> (
          Alcotest.(check string)
            "the first path" "a.md"
            (path_text (Read_file.path a));
          (match Read_file.lines a with
          | Ok lines ->
              Alcotest.(check bool)
                "the lines of its text" true
                (Text.equal (Lines.text lines) (text_of "\xef\xbb\xbf# A\r\n"));
              Alcotest.(check int) "one line" 1 (Lines.count lines)
          | Error _ -> Alcotest.fail "the content is valid UTF-8");
          match Read_file.lines b with
          | Error (Text.Invalid_utf_8 { place }) ->
              Alcotest.(check int) "the place of the fault" 1 place
          | Ok _ -> Alcotest.fail "the content is not valid UTF-8")
      | _ -> Alcotest.fail "two read files")

let tests =
  Vectors.tests "documents" vector_groups
  @ [ Vectors.covers "documents" set vector_groups ]
  @ proposed_vectors_pass
  @ [
      read_files_follow_the_terms;
      no_binding_from_invalid_path_sets;
      errors_carry_what_path_sets_give;
      reader_is_that_of_the_first_pair;
      Alcotest.test_case "pairs keep the readers and path sets of a binding"
        `Quick pairs_keep_the_binding;
      Alcotest.test_case "the empty binding reads no file" `Quick
        an_empty_binding_reads_no_file;
      Alcotest.test_case "a read file gives the lines of its text" `Quick
        read_files_give_their_lines;
    ]
