(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_wasm_engine
open Sinter_grammars
module W = Wasm_modules
module G = Grammar_modules
module Gen = QCheck2.Gen

let read_file path = In_channel.with_open_bin path In_channel.input_all
let json = lazy (read_file "fixtures/tree-sitter-json/tree-sitter-json.wasm")
let rust = lazy (read_file "fixtures/tree-sitter-rust/tree-sitter-rust.wasm")
let markdown = lazy (read_file "../lib/markdown/tree-sitter-markdown.wasm")

let engine =
  lazy
    (match Engine.create ~stack:1_048_576 with
    | Ok engine -> engine
    | Error (Not_made message) -> Alcotest.failf "no engine: %s" message)

let core =
  lazy
    (match Core.compile (Lazy.force engine) with
    | Ok core -> core
    | Error (Not_compiled message) ->
        Alcotest.failf "the core did not compile: %s" message)

let text s =
  match Text.decode s with
  | Ok t -> t
  | Error _ -> invalid_arg "Test_grammars.text"

let name s =
  match Sinter_pack_descriptor.Grammar_name.of_string s with
  | Some g -> g
  | None -> invalid_arg "Test_grammars.name"

let limits ~fuel ~memory ~table =
  match Instance.limits ~fuel ~memory ~table with
  | Ok limits -> limits
  | Error (Negative _) -> invalid_arg "Test_grammars.limits"

let failure_text = function
  | Instance.Trap message -> "trap: " ^ message
  | Stack_exhausted -> "stack exhausted"
  | Stopped Fuel -> "stopped for fuel"
  | Stopped Memory -> "stopped for memory"
  | Stopped Table -> "stopped for table"
  | Busy -> "busy"
  | Fault message -> "fault: " ^ message

let invalid_text = function
  | Grammar.Not_a_module _ -> "not a module"
  | No_memory_information _ -> "no memory information"
  | Import_not_given { module_name; name } ->
      Printf.sprintf "import not given: %s.%s" module_name name
  | No_language_export -> "no language export"
  | Wrong_start_export n -> "wrong start export " ^ n
  | Link_failed f -> "link failed: " ^ failure_text f
  | Abi_version n -> Printf.sprintf "ABI version %d" n
  | Not_parseable -> "not parseable"
  | Wrong_symbols m -> "wrong symbols: " ^ m
  | Symbol_name k -> Printf.sprintf "symbol name %d" k

let parse_failure_text = function
  | Grammar.Too_long -> "too long"
  | Failed f -> "failed: " ^ failure_text f
  | No_tree -> "no tree"
  | Wrong_record m -> "wrong record: " ^ m

let decide ?limits ?(g = "t") bytes =
  Grammar.decide ?limits (Lazy.force core) (name g) bytes

let usable ?limits g bytes =
  match decide ?limits ~g bytes with
  | Ok grammar -> grammar
  | Error e -> Alcotest.failf "not usable: %s" (invalid_text e)

let refused what ?limits ?g expected bytes =
  match decide ?limits ?g bytes with
  | Ok _ -> Alcotest.failf "%s: usable" what
  | Error e ->
      Alcotest.(check string) what (invalid_text expected) (invalid_text e)

let refused_by what ?limits ?g accept bytes =
  match decide ?limits ?g bytes with
  | Ok _ -> Alcotest.failf "%s: usable" what
  | Error e ->
      if not (accept e) then Alcotest.failf "%s: %s" what (invalid_text e)

let link_failed = function Grammar.Link_failed _ -> true | _ -> false
let traps = function Grammar.Link_failed (Trap _) -> true | _ -> false

let gives_no_address = function
  | Grammar.Link_failed (Trap _ | Stopped Memory) -> true
  | _ -> false

let reported ?limits spec =
  match decide ?limits (G.grammar spec) with
  | Error (Abi_version n) -> n - 100
  | Ok _ -> Alcotest.fail "the grammar gave a usable language"
  | Error e -> Alcotest.failf "no report: %s" (invalid_text e)

let case name f = Alcotest.test_case name `Quick f
let slow name f = Alcotest.test_case name `Slow f

let raises_invalid_argument what f =
  match f () with
  | exception Invalid_argument _ -> ()
  | _ -> Alcotest.failf "%s did not raise Invalid_argument" what

let given_functions_with_types_on_wasm32 =
  [
    ("calloc", "i32 i32", "i32");
    ("free", "i32", "");
    ("iswalnum", "i32", "i32");
    ("iswalpha", "i32", "i32");
    ("iswblank", "i32", "i32");
    ("iswdigit", "i32", "i32");
    ("iswlower", "i32", "i32");
    ("iswpunct", "i32", "i32");
    ("iswspace", "i32", "i32");
    ("iswupper", "i32", "i32");
    ("iswxdigit", "i32", "i32");
    ("malloc", "i32", "i32");
    ("memchr", "i32 i32 i32", "i32");
    ("memcmp", "i32 i32 i32", "i32");
    ("memcpy", "i32 i32 i32", "i32");
    ("memmove", "i32 i32 i32", "i32");
    ("memset", "i32 i32 i32", "i32");
    ("realloc", "i32 i32", "i32");
    ("strcmp", "i32 i32", "i32");
    ("strlen", "i32", "i32");
    ("strncat", "i32 i32 i32", "i32");
    ("strncmp", "i32 i32 i32", "i32");
    ("strncpy", "i32 i32 i32", "i32");
    ("towlower", "i32", "i32");
    ("towupper", "i32", "i32");
  ]

let value_types s =
  List.map
    (function
      | "i32" -> Wasm_module.Value_type.I32
      | _ -> invalid_arg "Test_grammars.value_types")
    (if s = "" then [] else String.split_on_char ' ' s)

let core_cases =
  [
    (* @verifies packs#isolate-grammars=v1
       The core of tree-sitter imports nothing, so code that runs inside an
       instance of a grammar cannot reach files, process output, a network, a
       clock, or processes through the core. *)
    case "the core has no import" (fun () ->
        Alcotest.(check int)
          "imports" 0
          (Wasm_module.import_count (Core.compiled (Lazy.force core))));
    case
      "the core exports its memory, its table, its stack pointer, and the 25 \
       functions" (fun () ->
        let exports = Wasm_module.exports (Core.compiled (Lazy.force core)) in
        let has what name expected =
          match List.assoc_opt name exports with
          | Some e when e = expected -> ()
          | _ -> Alcotest.failf "no %s %s" what name
        in
        has "memory" "memory" Wasm_module.Memory;
        has "table" "__indirect_function_table" Wasm_module.Table;
        has "global" "__stack_pointer" Wasm_module.Global;
        List.iter
          (fun (f, params, results) ->
            has "function" f
              (Wasm_module.Function
                 { params = value_types params; results = value_types results }))
          given_functions_with_types_on_wasm32);
    case "the engine of the core is the engine that compiled it" (fun () ->
        if Core.engine (Lazy.force core) != Lazy.force engine then
          Alcotest.fail "another engine");
    case
      "the stack pointer of a new core is more than 0 and at most each address \
       that the allocation gives" (fun () ->
        let spec =
          {
            (G.report
               "(i32.add (i32.mul (i32.const 2) (i32.le_u (global.get $sp) \
                (call $malloc (i32.const 16)))) (i32.and (i32.gt_u (global.get \
                $sp) (i32.const 0)) (i32.le_u (global.get $sp) (global.get \
                $mb))))")
            with
            imports =
              "(import \"env\" \"__stack_pointer\" (global $sp (mut i32))) "
              ^ G.function_import "malloc" "i32" "i32";
          }
        in
        Alcotest.(check int) "both conditions" 3 (reported spec));
    case
      "the allocation functions give addresses that are multiples of 16 and \
       not 0" (fun () ->
        let check_of call =
          Printf.sprintf "(i32.add (i32.and %s (i32.const 15)) (i32.eqz %s))"
            call call
        in
        let calls =
          List.map
            (fun n -> Printf.sprintf "(call $malloc (i32.const %d))" n)
            [ 1; 3; 16; 17; 100; 5000; 70000 ]
          @ [
              "(call $calloc (i32.const 3) (i32.const 5))";
              "(call $realloc (call $malloc (i32.const 5)) (i32.const 300))";
              "(call $realloc (i32.const 0) (i32.const 7))";
            ]
        in
        let sum =
          List.fold_left
            (fun acc c -> Printf.sprintf "(i32.add %s %s)" acc (check_of c))
            "(i32.const 0)" calls
        in
        let spec =
          {
            (G.report sum) with
            imports =
              G.function_import "malloc" "i32" "i32"
              ^ G.function_import "calloc" "i32 i32" "i32"
              ^ G.function_import "realloc" "i32 i32" "i32";
          }
        in
        Alcotest.(check int) "misaligned or null addresses" 0 (reported spec));
    case "an allocation that the memory cannot hold gives no address" (fun () ->
        let spec size =
          {
            (G.report
               (Printf.sprintf "(i32.eqz (call $malloc (i32.const %d)))" size))
            with
            imports = G.function_import "malloc" "i32" "i32";
          }
        in
        refused_by "16 MiB in 8 MiB"
          ~limits:(limits ~fuel:1_000_000_000 ~memory:(8 lsl 20) ~table:100_000)
          gives_no_address
          (G.grammar (spec (16 lsl 20)));
        refused_by "2^32 - 16 bytes" gives_no_address (G.grammar (spec (-16))));
    case "calloc of a size that overflows gives no address" (fun () ->
        let spec =
          {
            (G.report
               "(i32.eqz (call $calloc (i32.const 65536) (i32.const 65537)))")
            with
            imports = G.function_import "calloc" "i32 i32" "i32";
          }
        in
        refused_by "65536 times 65537" gives_no_address (G.grammar spec));
  ]

let trees_of_tree_sitter_0_26_13 =
  [
    ( "json",
      "{\"a\": [1, true]}",
      false,
      [
        (0, "document", 0, 17);
        (1, "object", 0, 16);
        (2, "{", 0, 1);
        (2, "pair", 1, 15);
        (3, "string", 1, 4);
        (4, "\"", 1, 2);
        (4, "string_content", 2, 3);
        (4, "\"", 3, 4);
        (3, ":", 4, 5);
        (3, "array", 6, 15);
        (4, "[", 6, 7);
        (4, "number", 7, 8);
        (4, ",", 8, 9);
        (4, "true", 10, 14);
        (4, "]", 14, 15);
        (2, "}", 15, 16);
      ] );
    ( "json",
      "[]\n",
      false,
      [
        (0, "document", 0, 3); (1, "array", 0, 2); (2, "[", 0, 1); (2, "]", 1, 2);
      ] );
    ( "json",
      "{\"a\": }",
      true,
      [
        (0, "document", 0, 8);
        (1, "object", 0, 7);
        (2, "{", 0, 1);
        (2, "pair", 1, 5);
        (3, "string", 1, 4);
        (4, "\"", 1, 2);
        (4, "string_content", 2, 3);
        (4, "\"", 3, 4);
        (3, ":", 4, 5);
        (3, "number", 5, 5);
        (2, "}", 6, 7);
      ] );
    ("json", "", false, [ (0, "document", 1, 1) ]);
    ( "json",
      "\xef\xbb\xbf[1]",
      false,
      [
        (0, "document", 3, 7);
        (1, "array", 3, 6);
        (2, "[", 3, 4);
        (2, "number", 4, 5);
        (2, "]", 5, 6);
      ] );
    ( "json",
      "  [1,\n2]\r\n",
      false,
      [
        (0, "document", 2, 10);
        (1, "array", 2, 8);
        (2, "[", 2, 3);
        (2, "number", 3, 4);
        (2, ",", 4, 5);
        (2, "number", 6, 7);
        (2, "]", 7, 8);
      ] );
    ( "json",
      "[\"\xc3\xa9\xf0\x9f\x98\x80\"]",
      false,
      [
        (0, "document", 0, 11);
        (1, "array", 0, 10);
        (2, "[", 0, 1);
        (2, "string", 1, 9);
        (3, "\"", 1, 2);
        (3, "string_content", 2, 8);
        (3, "\"", 8, 9);
        (2, "]", 9, 10);
      ] );
    ( "rust",
      "fn main() {}",
      false,
      [
        (0, "source_file", 0, 13);
        (1, "function_item", 0, 12);
        (2, "fn", 0, 2);
        (2, "identifier", 3, 7);
        (2, "parameters", 7, 9);
        (3, "(", 7, 8);
        (3, ")", 8, 9);
        (2, "block", 10, 12);
        (3, "{", 10, 11);
        (3, "}", 11, 12);
      ] );
    ( "rust",
      "// c\nfn f(x: u8) -> u8 { x }\n",
      false,
      [
        (0, "source_file", 0, 29);
        (1, "line_comment", 0, 4);
        (2, "//", 0, 2);
        (1, "function_item", 5, 28);
        (2, "fn", 5, 7);
        (2, "identifier", 8, 9);
        (2, "parameters", 9, 16);
        (3, "(", 9, 10);
        (3, "parameter", 10, 15);
        (4, "identifier", 10, 11);
        (4, ":", 11, 12);
        (4, "primitive_type", 13, 15);
        (3, ")", 15, 16);
        (2, "->", 17, 19);
        (2, "primitive_type", 20, 22);
        (2, "block", 23, 28);
        (3, "{", 23, 24);
        (3, "identifier", 25, 26);
        (3, "}", 27, 28);
      ] );
    ( "markdown",
      "# Title\n\nText.\n",
      false,
      [
        (0, "document", 0, 15);
        (1, "section", 0, 15);
        (2, "atx_heading", 0, 8);
        (3, "atx_h1_marker", 0, 1);
        (3, "inline", 2, 7);
        (2, "paragraph", 9, 15);
        (3, "inline", 9, 14);
        (4, ".", 13, 14);
      ] );
    ( "markdown",
      "- a\n- b",
      false,
      [
        (0, "document", 0, 8);
        (1, "section", 0, 8);
        (2, "list", 0, 8);
        (3, "list_item", 0, 4);
        (4, "list_marker_minus", 0, 2);
        (4, "paragraph", 2, 4);
        (5, "inline", 2, 3);
        (3, "list_item", 4, 8);
        (4, "list_marker_minus", 4, 6);
        (4, "paragraph", 6, 8);
        (5, "inline", 6, 7);
      ] );
    ("markdown", "", false, [ (0, "document", 0, 1); (1, "section", 0, 1) ]);
  ]

let error_trees_of_tree_sitter_0_26_13 =
  [
    ( "json",
      "[1 2]",
      [
        (0, "document");
        (1, "array");
        (2, "[");
        (2, "ERROR");
        (3, "number");
        (2, "number");
        (2, "]");
      ] );
    ("rust", "fn (", [ (0, "source_file"); (1, "ERROR"); (2, "fn"); (2, "(") ]);
  ]

let grammars =
  lazy
    [
      ("json", usable "json" (Lazy.force json));
      ("rust", usable "rust" (Lazy.force rust));
      ("markdown", usable "markdown" (Lazy.force markdown));
    ]

let grammar g = List.assoc g (Lazy.force grammars)

let parsed ?limits g subject =
  let limits =
    match limits with
    | Some limits -> limits
    | None -> Grammar.parse_limits (text subject)
  in
  match Grammar.parse ~limits (grammar g) (text subject) with
  | Ok tree -> tree
  | Error e ->
      Alcotest.failf "%s: no tree of %S: %s" g subject (parse_failure_text e)

let walk tree =
  let rec go depth n =
    (depth, n) :: List.concat_map (go (depth + 1)) (Parse_tree.children tree n)
  in
  go 0 (Parse_tree.root tree)

let nodes_of tree =
  List.map
    (fun (d, n) ->
      ( d,
        Text.encode (Parse_tree.node_type tree n),
        Parse_tree.start_byte tree n,
        Parse_tree.end_byte tree n ))
    (walk tree)

let node_text (d, t, s, e) = Printf.sprintf "%d %s %d %d" d t s e

let grammar_cases =
  [
    case "the grammars of the repository are usable, with their ABI versions"
      (fun () ->
        List.iter
          (fun (g, v) ->
            Alcotest.(check int)
              (g ^ " ABI") v
              (Grammar.abi_version (grammar g));
            Alcotest.(check string)
              (g ^ " name") g
              (Grammar.grammar_name (grammar g) :> string))
          [ ("json", 14); ("rust", 15); ("markdown", 15) ]);
    case "a grammar is not usable with another grammar name" (fun () ->
        refused "json as rust" ~g:"rust" No_language_export (Lazy.force json));
    case "the node types of a grammar hold the names of its symbols, then ERROR"
      (fun () ->
        let types = Grammar.node_types (grammar "json") in
        let names = Array.to_list (Array.map Text.encode types) in
        List.iter
          (fun n ->
            if not (List.mem n names) then Alcotest.failf "no node type %s" n)
          [ "document"; "object"; "pair"; "string"; "number"; "true"; "{" ];
        Alcotest.(check string)
          "the last node type" "ERROR"
          (Text.encode types.(Array.length types - 1)));
    case "node_types gives a new array at each call" (fun () ->
        let g = grammar "json" in
        let first = Grammar.node_types g in
        let saved = Text.encode first.(0) in
        first.(0) <- text "changed";
        Alcotest.(check string)
          "the first node type" saved
          (Text.encode (Grammar.node_types g).(0)));
    case "each text gives the tree that tree-sitter's parsing gives" (fun () ->
        List.iter
          (fun (g, subject, error, expected) ->
            let tree = parsed g subject in
            Alcotest.(check (list string))
              (Printf.sprintf "%s %S" g subject)
              (List.map node_text expected)
              (List.map node_text (nodes_of tree));
            Alcotest.(check bool)
              (Printf.sprintf "the error of %S" subject)
              error
              (Parse_tree.root_has_error tree);
            Alcotest.(check string)
              "the text" subject
              (Text.encode (Parse_tree.text tree)))
          trees_of_tree_sitter_0_26_13);
    case "an ERROR node has the node type ERROR, and its root has an error"
      (fun () ->
        List.iter
          (fun (g, subject, expected) ->
            let tree = parsed g subject in
            Alcotest.(check (list string))
              (Printf.sprintf "%s %S" g subject)
              (List.map (fun (d, t) -> Printf.sprintf "%d %s" d t) expected)
              (List.map
                 (fun (d, t, _, _) -> Printf.sprintf "%d %s" d t)
                 (nodes_of tree));
            Alcotest.(check bool)
              "root_has_error" true
              (Parse_tree.root_has_error tree))
          error_trees_of_tree_sitter_0_26_13);
    case "the run of a node is in the text, without the mark and the line feed"
      (fun () ->
        let run_of g subject k =
          let tree = parsed g subject in
          match Parse_tree.node tree k with
          | None -> Alcotest.failf "no node %d" k
          | Some n ->
              let r = Parse_tree.run tree n in
              Printf.sprintf "%d-%d" r.from r.until
        in
        Alcotest.(check string)
          "the root of a text with a mark" "1-4"
          (run_of "json" "\xef\xbb\xbf[1]" 0);
        Alcotest.(check string)
          "the root of {...}" "0-16"
          (run_of "json" "{\"a\": [1, true]}" 0);
        Alcotest.(check string)
          "the root of the empty text" "0-0" (run_of "json" "" 0);
        Alcotest.(check string)
          "a string of two characters" "2-4"
          (run_of "json" "[\"\xc3\xa9\xf0\x9f\x98\x80\"]" 5);
        Alcotest.(check string)
          "the root of a text with a line feed" "2-10"
          (run_of "json" "  [1,\n2]\r\n" 0));
    case "two parses of one text give the same tree" (fun () ->
        let subject = "# A\n\n- b\n- c\n\n```\nx\n```\n" in
        let a = nodes_of (parsed "markdown" subject) in
        let b = nodes_of (parsed "markdown" subject) in
        Alcotest.(check (list string))
          "the trees" (List.map node_text a) (List.map node_text b));
  ]

let symbol_cases =
  [
    case "a built grammar of ABI 13, 14, or 15 is usable" (fun () ->
        List.iter
          (fun v ->
            let g =
              usable "t"
                (G.grammar
                   { G.base with abi = Printf.sprintf "(i32.const %d)" v })
            in
            Alcotest.(check int) "the ABI version" v (Grammar.abi_version g))
          [ 13; 14; 15 ]);
    case "an ABI version out of 13 to 15 is refused with that version"
      (fun () ->
        List.iter
          (fun (word, v) ->
            refused
              (Printf.sprintf "ABI %d" v)
              (Abi_version v)
              (G.grammar
                 { G.base with abi = Printf.sprintf "(i32.const %d)" word }))
          [
            (0, 0);
            (12, 12);
            (16, 16);
            (-1, 4294967295);
            (-2147483648, 2147483648);
          ]);
    case "a language with no lexing function is not parseable" (fun () ->
        refused "no lexing function" Not_parseable
          (G.grammar { G.base with lex = false }));
    case "a grammar that breaks the lengths of its record of names is refused"
      (fun () ->
        let x = 8192 in
        let at offset =
          Printf.sprintf "(i32.add (global.get $mb) (i32.const %d))" offset
        in
        let broken ~name_1 =
          G.grammar
            {
              G.base with
              imports = G.function_import "free" "i32" "";
              symbols = [ String.make 5000 'a'; "" ];
              memory_size = 16384;
              postlude =
                Printf.sprintf
                  "(memory.fill %s (i32.const 98) (i32.const %d)) (i32.store \
                   %s (i32.const 35)) (i32.store %s (i32.const 8192)) (call \
                   $free %s) (call $free %s) (i32.store offset=260 (global.get \
                   $mb) %s)"
                  (at (x + 8))
                  name_1
                  (at (x - 16))
                  (at (x - 12))
                  (at x) (at x)
                  (at (x + 8));
            }
        in
        let wrong = function Grammar.Wrong_symbols _ -> true | _ -> false in
        refused_by "lengths that run past the end" wrong (broken ~name_1:0);
        refused_by "lengths that end before the end" wrong (broken ~name_1:3000));
    case "a grammar whose record of the names ends past the memory is refused"
      (fun () ->
        let x =
          "(i32.sub (i32.mul (memory.size) (i32.const 65536)) (i32.const 5024))"
        in
        let at offset = Printf.sprintf "(i32.add %s (i32.const %d))" x offset in
        refused_by "a record of the names past the memory"
          (function Grammar.Wrong_symbols _ -> true | _ -> false)
          (G.grammar
             {
               G.base with
               imports = G.function_import "free" "i32" "";
               symbols = [ "a"; "b" ];
               postlude =
                 Printf.sprintf
                   "(memory.fill %s (i32.const 97) (i32.const 5000)) \
                    (i32.store8 %s (i32.const 0)) (i32.store %s (i32.const \
                    36)) (i32.store %s (i32.const 16384)) (call $free %s) \
                    (call $free %s) (i32.store offset=256 (global.get $mb) %s) \
                    (i32.store offset=260 (global.get $mb) %s)"
                   (at 8) (at 5008) (at (-16)) (at (-12)) x x (at 8) (at 8);
             }));
    case
      "a grammar whose record of the names ends at the end of the memory is \
       usable" (fun () ->
        let x =
          "(i32.sub (i32.mul (memory.size) (i32.const 65536)) (i32.const 5012))"
        in
        let at offset = Printf.sprintf "(i32.add %s (i32.const %d))" x offset in
        let g =
          usable "t"
            (G.grammar
               {
                 G.base with
                 imports = G.function_import "free" "i32" "";
                 symbols = [ String.make 5000 'a' ];
                 memory_size = 8192;
                 postlude =
                   Printf.sprintf
                     "(i32.store %s (i32.const 35)) (i32.store %s (i32.const \
                      8192)) (call $free %s) (call $free %s)"
                     (at (-16)) (at (-12)) x x;
               })
        in
        Alcotest.(check int)
          "node types" 2
          (Array.length (Grammar.node_types g)));
    case "a grammar whose symbol names are all empty is usable" (fun () ->
        let g = usable "t" (G.grammar { G.base with symbols = [ ""; "" ] }) in
        Alcotest.(check (list string))
          "node types" [ ""; ""; "ERROR" ]
          (List.map Text.encode (Array.to_list (Grammar.node_types g))));
    case
      "the node types of a built grammar are its names, its aliases, and ERROR"
      (fun () ->
        let g =
          usable "t"
            (G.grammar
               {
                 G.base with
                 symbols = [ "end"; "\xc3\xa9"; "al" ];
                 aliases = 1;
               })
        in
        Alcotest.(check (list string))
          "node types"
          [ "end"; "\xc3\xa9"; "al"; "ERROR" ]
          (Array.to_list (Array.map Text.encode (Grammar.node_types g))));
    case "a symbol name that is not valid UTF-8 is refused with its number"
      (fun () ->
        refused "the second symbol" (Symbol_name 1)
          (G.grammar { G.base with symbols = [ "end"; "a\xffb" ] });
        refused "an alias" (Symbol_name 2)
          (G.grammar
             { G.base with symbols = [ "end"; "a"; "\xc3" ]; aliases = 1 });
        refused "the lowest of two" (Symbol_name 0)
          (G.grammar { G.base with symbols = [ "\xed\xa0\x80"; "\xfe" ] }));
    case "a list of names outside the memory traps" (fun () ->
        refused_by "names at 2^32 - 256" traps
          (G.grammar
             {
               G.base with
               postlude =
                 "(i32.store offset=56 (global.get $mb) (i32.const -256))";
             });
        refused_by "a name at 2^32 - 4" traps
          (G.grammar
             {
               G.base with
               postlude =
                 "(i32.store offset=256 (global.get $mb) (i32.const -4))";
             }));
  ]

let with_no_own_bytes text =
  G.after_header
    [
      G.dylink
        [
          G.memory_information ~memory_size:0 ~memory_alignment:0 ~table_size:0
            ~table_alignment:0;
        ];
    ]
    (W.of_text text)

let module_cases =
  [
    case "bytes that are not a WebAssembly module are refused" (fun () ->
        List.iter
          (fun bytes ->
            refused_by
              (Printf.sprintf "%S" bytes)
              (function Grammar.Not_a_module _ -> true | _ -> false)
              bytes)
          [
            "";
            "not wasm";
            "\x00asm\x01\x00\x00\x00\x01\x05\x00";
            G.after_header
              [
                G.dylink
                  [
                    G.memory_information ~memory_size:0 ~memory_alignment:0
                      ~table_size:0 ~table_alignment:0;
                  ];
              ]
              (W.module_ [ W.section 3 (W.vec [ "\x05" ]) ]);
          ]);
    case "a module with no memory information is refused" (fun () ->
        refused_by "no dylink.0"
          (function
            | Grammar.No_memory_information Dylink.No_section -> true
            | _ -> false)
          (W.of_text (G.text G.base));
        refused_by "a subsection of type 2"
          (function
            | Grammar.No_memory_information (Dylink.Other_subsection 2) -> true
            | _ -> false)
          (G.after_header
             [
               G.dylink
                 [
                   G.memory_information ~memory_size:1024 ~memory_alignment:4
                     ~table_size:1 ~table_alignment:0;
                   "\x02\x00";
                 ];
             ]
             (W.of_text (G.text G.base))));
    case "the memory information is checked before the imports" (fun () ->
        refused_by "no dylink.0 and an import not given"
          (function Grammar.No_memory_information _ -> true | _ -> false)
          (W.of_text
             (G.text
                {
                  G.base with
                  imports = G.function_import "fopen" "i32 i32" "i32";
                })));
    case "a grammar that imports each name that the program gives is usable"
      (fun () ->
        let imports =
          String.concat ""
            (List.map
               (fun (f, p, r) -> G.function_import f p r)
               given_functions_with_types_on_wasm32)
          ^ "(import \"env\" \"__stack_pointer\" (global $sp (mut i32)))"
          ^ G.function_import "__assert_fail" "i32 i32 i32 i32" ""
        in
        ignore (usable "t" (G.grammar { G.base with imports })));
    case "the module name of an import does not matter" (fun () ->
        ignore
          (usable "t"
             (G.grammar
                {
                  G.base with
                  module_name = "x";
                  imports =
                    "(import \"y\" \"malloc\" (func (param i32) (result i32)))";
                })));
    (* @verifies packs#isolate-grammars=v1
       A grammar module that imports a host or WASI function such as fopen,
       proc_exit, or wasi.fd_write, or imports a permitted name with another
       kind or type, is refused before instantiation. *)
    case "an import that the program does not give is refused" (fun () ->
        List.iter
          (fun (imports, module_name, n) ->
            refused n
              (Import_not_given { module_name; name = n })
              (G.grammar { G.base with imports }))
          [
            (G.function_import "fopen" "i32 i32" "i32", "env", "fopen");
            (G.function_import "abort" "" "", "env", "abort");
            (G.function_import "proc_exit" "i32" "", "env", "proc_exit");
            ( "(import \"wasi\" \"fd_write\" (func (param i32 i32 i32 i32) \
               (result i32)))",
              "wasi",
              "fd_write" );
            (G.function_import "malloc" "i32 i32" "i32", "env", "malloc");
            (G.function_import "free" "i32" "i32", "env", "free");
            ( "(import \"env\" \"__stack_pointer\" (global i32))",
              "env",
              "__stack_pointer" );
            ( "(import \"env\" \"__stack_pointer\" (global (mut i64)))",
              "env",
              "__stack_pointer" );
            ("(import \"env\" \"strlen\" (global i32))", "env", "strlen");
            ( "(import \"env\" \"__heap_base\" (global i32))",
              "env",
              "__heap_base" );
            (G.function_import "__assert_fail" "i32" "", "env", "__assert_fail");
          ]);
    case "an import of a linker name of another kind or type is refused"
      (fun () ->
        refused "a mutable memory base"
          (Import_not_given { module_name = "env"; name = "__memory_base" })
          (with_no_own_bytes
             "(module (import \"env\" \"memory\" (memory 0)) (import \"env\" \
              \"__memory_base\" (global (mut i32))) (func (export \
              \"tree_sitter_t\") (result i32) (i32.const 0)))");
        refused "a table base of i64"
          (Import_not_given { module_name = "env"; name = "__table_base" })
          (with_no_own_bytes
             "(module (import \"env\" \"memory\" (memory 0)) (import \"env\" \
              \"__table_base\" (global i64)) (func (export \"tree_sitter_t\") \
              (result i32) (i32.const 0)))");
        refused "a table of externref"
          (Import_not_given
             { module_name = "env"; name = "__indirect_function_table" })
          (with_no_own_bytes
             "(module (import \"env\" \"memory\" (memory 0)) (import \"env\" \
              \"__indirect_function_table\" (table 0 externref)) (func (export \
              \"tree_sitter_t\") (result i32) (i32.const 0)))");
        refused "a memory as a function"
          (Import_not_given { module_name = "env"; name = "memory" })
          (with_no_own_bytes
             "(module (import \"env\" \"memory\" (func)) (func (export \
              \"tree_sitter_t\") (result i32) (i32.const 0)))"));
    case "a grammar with no language export of its name and type is refused"
      (fun () ->
        refused "another name" ~g:"u" No_language_export (G.grammar G.base);
        refused "a function of another type" ~g:"v" No_language_export
          (G.grammar
             {
               G.base with
               fields =
                 "(func (export \"tree_sitter_v\") (param i32) (result i32) \
                  (i32.const 0))";
             });
        refused "a global" ~g:"v" No_language_export
          (G.grammar
             {
               G.base with
               fields = "(global (export \"tree_sitter_v\") i32 (i32.const 0))";
             }));
    case "a start export of another type is refused with its name" (fun () ->
        List.iter
          (fun (export, field) ->
            refused export (Wrong_start_export export)
              (G.grammar { G.base with fields = field }))
          [
            ( "_initialize",
              "(func (export \"_initialize\") (result i32) (i32.const 0))" );
            ( "__wasm_apply_data_relocs",
              "(func (export \"__wasm_apply_data_relocs\") (param i32))" );
            ( "__wasm_call_ctors",
              "(global (export \"__wasm_call_ctors\") i32 (i32.const 0))" );
          ]);
    case "the start exports run in their order, before the language export"
      (fun () ->
        let step name digit =
          Printf.sprintf
            "(func (export \"%s\") (global.set $order (i32.add (i32.mul \
             (global.get $order) (i32.const 10)) (i32.const %d))))"
            name digit
        in
        let report exports =
          reported
            {
              (G.report "(global.get $order)") with
              fields =
                "(global $order (mut i32) (i32.const 0)) "
                ^ String.concat " "
                    (List.map
                       (fun n ->
                         step n
                           (match n with
                           | "__wasm_apply_data_relocs" -> 1
                           | "_initialize" -> 2
                           | _ -> 3))
                       exports);
            }
        in
        Alcotest.(check int)
          "all three" 12
          (report
             [ "__wasm_call_ctors"; "_initialize"; "__wasm_apply_data_relocs" ]);
        Alcotest.(check int)
          "relocations and constructors" 13
          (report [ "__wasm_call_ctors"; "__wasm_apply_data_relocs" ]);
        Alcotest.(check int) "constructors" 3 (report [ "__wasm_call_ctors" ]);
        Alcotest.(check int) "initialize" 2 (report [ "_initialize" ]);
        Alcotest.(check int) "none" 0 (report []));
    case "a trap in the link gives Link_failed" (fun () ->
        refused_by "a start function" traps
          (G.grammar
             { G.base with fields = "(func $s unreachable) (start $s)" });
        refused_by "a constructor" traps
          (G.grammar
             {
               G.base with
               fields = "(func (export \"__wasm_call_ctors\") unreachable)";
             });
        refused_by "the language export" traps
          (G.grammar { G.base with prelude = "unreachable" });
        refused_by "__assert_fail" traps
          (G.grammar
             {
               G.base with
               imports = G.function_import "__assert_fail" "i32 i32 i32 i32" "";
               prelude =
                 "(call $__assert_fail (i32.const 0) (i32.const 0) (i32.const \
                  0) (i32.const 0))";
             });
        refused_by "an access past the memory" traps
          (G.grammar
             { G.base with prelude = "(drop (i32.load (i32.const -4)))" }));
  ]

let own_cases =
  [
    case "the own bytes start at a multiple of their alignment" (fun () ->
        List.iter
          (fun a ->
            Alcotest.(check int)
              (Printf.sprintf "alignment 2^%d" a)
              0
              (reported
                 {
                   (G.report
                      (Printf.sprintf
                         "(i32.and (global.get $mb) (i32.const %d))"
                         ((1 lsl a) - 1)))
                   with
                   memory_alignment = a;
                 }))
          [ 0; 2; 4 ]);
    case "the own bytes lie inside the memory and are 0" (fun () ->
        let sum =
          "(func $sum (param $a i32) (param $n i32) (result i32) (local $s \
           i32) (block $done (loop $l (br_if $done (i32.eqz (local.get $n))) \
           (local.set $s (i32.or (local.get $s) (i32.load8_u (local.get $a)))) \
           (local.set $a (i32.add (local.get $a) (i32.const 1))) (local.set $n \
           (i32.sub (local.get $n) (i32.const 1))) (br $l))) (local.get $s))"
        in
        Alcotest.(check int)
          "the bytes after the data" 0
          (reported
             {
               (G.report
                  "(call $sum (i32.add (global.get $mb) (i32.const 1024)) \
                   (i32.const 2998976))")
               with
               fields = sum;
               memory_size = 3_000_000;
             }));
    case "the own elements lie inside the table and are null" (fun () ->
        Alcotest.(check int)
          "inside the table and null" 2
          (reported
             {
               (G.report
                  "(i32.add (ref.is_null (table.get 0 (i32.add (global.get \
                   $tb) (i32.const 8)))) (i32.ge_u (table.size 0) (i32.add \
                   (global.get $tb) (i32.const 9))))")
               with
               table_size = 9;
             }));
    case "the own elements end at the end of the table" (fun () ->
        List.iter
          (fun (size, alignment) ->
            Alcotest.(check int)
              (Printf.sprintf "%d elements aligned to 2^%d" size alignment)
              size
              (reported
                 {
                   (G.report "(i32.sub (table.size 0) (global.get $tb))") with
                   table_size = size;
                   table_alignment = alignment;
                 }))
          [ (1, 0); (3, 0); (9, 0) ]);
    case "the memory and the table grow to the minimums of their imports"
      (fun () ->
        Alcotest.(check int)
          "300 pages and 5,000 elements" 2
          (reported
             {
               (G.report
                  "(i32.add (i32.ge_u (memory.size) (i32.const 300)) (i32.ge_u \
                   (table.size 0) (i32.const 5000)))")
               with
               memory_minimum = 300;
               table_minimum = 5000;
             }));
    case
      "the memory and the table grow to the minimums of their imports, and no \
       more" (fun () ->
        let memory m =
          reported { (G.report "(memory.size)") with memory_minimum = m }
        and table m =
          reported { (G.report "(table.size 0)") with table_minimum = m }
        in
        let pages = memory 0 and elements = table 0 in
        Alcotest.(check (list int))
          "pages for the minimums 0, now - 1, now, now + 3"
          [ pages; pages; pages; pages + 3 ]
          (List.map memory [ 0; pages - 1; pages; pages + 3 ]);
        Alcotest.(check (list int))
          "elements for the minimums 0, now - 1, now, now + 5"
          [ elements; elements; elements; elements + 5 ]
          (List.map table [ 0; elements - 1; elements; elements + 5 ]));
  ]

(* @verifies conformance#report-stops-at-limits=v1
   A grammar with a memory alignment of 5 or more or a table alignment of 1 or
   more is usable and places its own bytes and own elements at multiples of
   their alignments; when the required bytes or elements with alignment room
   exceed the instance limits or 4,294,967,295, the decision stops with
   Link_failed (Stopped Memory) or Link_failed (Stopped Table). *)
let own_stop_cases =
  [
    case
      "a memory alignment of 5 or more places the own bytes at a multiple of \
       its alignment" (fun () ->
        List.iter
          (fun a ->
            let mask = (1 lsl a) - 1 in
            let size = 64 in
            Alcotest.(check int)
              (Printf.sprintf "memory alignment 2^%d" a)
              0
              (reported
                 {
                   (G.report
                      (Printf.sprintf
                         "(i32.or (i32.and (global.get $mb) (i32.const %d)) \
                          (i32.or (i32.eqz (global.get $mb)) (i32.gt_u \
                          (i32.add (global.get $mb) (i32.const %d)) (i32.mul \
                          (memory.size) (i32.const 65536)))))"
                         mask size))
                   with
                   memory_size = size;
                   memory_alignment = a;
                 }))
          [ 0; 1; 4; 5; 6; 10 ]);
    case
      "a table alignment of 1 or more places the own elements at the first \
       multiple of its alignment" (fun () ->
        let before =
          reported
            {
              (G.report "(global.get $tb)") with
              table_size = 1;
              table_alignment = 0;
            }
        in
        List.iter
          (fun a ->
            let align = 1 lsl a in
            let mask = align - 1 in
            let expected_base = (before + mask) land lnot mask in
            let size = 5 in
            Alcotest.(check int)
              (Printf.sprintf "table base for alignment 2^%d" a)
              expected_base
              (reported
                 {
                   (G.report "(global.get $tb)") with
                   table_size = size;
                   table_alignment = a;
                 });
            Alcotest.(check int)
              (Printf.sprintf "table own elements for alignment 2^%d" a)
              2
              (reported
                 {
                   (G.report
                      (Printf.sprintf
                         "(i32.add (ref.is_null (table.get 0 (i32.add \
                          (global.get $tb) (i32.const %d)))) (i32.ge_u \
                          (table.size 0) (i32.add (global.get $tb) (i32.const \
                          %d))))"
                         (size - 1) size))
                   with
                   table_size = size;
                   table_alignment = a;
                 }))
          [ 1; 2; 3; 4 ]);
    case
      "an alignment whose room passes the limits or 2^32 - 1 stops at memory \
       or table" (fun () ->
        let small = limits ~fuel:50_000_000 ~memory:(8 lsl 20) ~table:1_000 in
        refused "memory alignment 24 under 8 MiB" ~limits:small
          (Grammar.Link_failed (Stopped Memory))
          (G.grammar { G.base with memory_alignment = 24 });
        refused "table alignment 12 under 1,000 elements" ~limits:small
          (Link_failed (Stopped Table))
          (G.grammar { G.base with table_alignment = 12 });
        let big = limits ~fuel:max_int ~memory:max_int ~table:max_int in
        List.iter
          (fun (what, expected, spec) ->
            List.iter
              (fun limits -> refused what ?limits expected (G.grammar spec))
              [ None; Some big ])
          [
            ( "memory size 1 with alignment 32",
              Grammar.Link_failed (Stopped Memory),
              { G.base with memory_size = 1; memory_alignment = 32 } );
            ( "memory size 0 with alignment 33",
              Link_failed (Stopped Memory),
              { G.base with memory_size = 0; memory_alignment = 33 } );
            ( "memory size 2^32 - 1 with alignment 1",
              Link_failed (Stopped Memory),
              { G.base with memory_size = 0xFFFF_FFFF; memory_alignment = 1 } );
            ( "memory alignment 40",
              Link_failed (Stopped Memory),
              { G.base with memory_alignment = 40 } );
            ( "memory alignment 2^32 - 1",
              Link_failed (Stopped Memory),
              { G.base with memory_alignment = 0xFFFF_FFFF } );
            ( "table size 1 with alignment 32",
              Link_failed (Stopped Table),
              { G.base with table_size = 1; table_alignment = 32 } );
            ( "table size 0 with alignment 33",
              Link_failed (Stopped Table),
              { G.base with table_size = 0; table_alignment = 33 } );
            ( "table size 2^32 - 1 with alignment 1",
              Link_failed (Stopped Table),
              { G.base with table_size = 0xFFFF_FFFF; table_alignment = 1 } );
            ( "table alignment 61",
              Link_failed (Stopped Table),
              { G.base with table_alignment = 61 } );
            ( "table alignment 62",
              Link_failed (Stopped Table),
              { G.base with table_alignment = 62 } );
            ( "table alignment 2^32 - 1",
              Link_failed (Stopped Table),
              { G.base with table_alignment = 0xFFFF_FFFF } );
          ]);
    case "own bytes of 2^32 - 1 in all give no address and trap" (fun () ->
        refused_by "own bytes and alignment of 2^32 - 1" traps
          (G.grammar
             { G.base with memory_size = 0xFFFF_FFFE; memory_alignment = 0 }));
  ]

let small_limits = limits ~fuel:50_000_000 ~memory:(8 lsl 20) ~table:100_000

(* @verifies packs#end-grammar-code=v1
   @verifies conformance#report-stops-at-limits=v1
   Grammar code that loops without end or that exhausts fuel, memory, or
   table limits during loading stops at the instance limits and names the
   limit that stopped it. *)
let limit_cases =
  [
    case "the default limits of a decision" (fun () ->
        let l = Grammar.load_limits in
        Alcotest.(check (list int))
          "fuel, memory, table"
          [ 10_000_000_000; 268_435_456; 1_048_576 ]
          [ l.fuel; l.memory; l.table ]);
    case
      "the limits of a parse are the stated amounts plus the stated factors \
       for each byte of the parse text" (fun () ->
        let fields (l : Instance.limits) = [ l.fuel; l.memory; l.table ] in
        let at t = fields (Grammar.parse_limits (text t)) in
        let one = at "" and step = [ 100_000; 1_024; 0 ] in
        Alcotest.(check (list int))
          "a parse text of 1 byte"
          [ 1_000_000_000 + 100_000; 268_435_456 + 1_024; 1_048_576 ]
          one;
        List.iter
          (fun t ->
            let bytes = String.length (Parse_tree.parse_text (text t)) in
            Alcotest.(check (list int))
              (Printf.sprintf "%S" t)
              (List.map2
                 (fun base unit -> base + (unit * (bytes - 1)))
                 one step)
              (at t))
          [
            "\n";
            "ab";
            "a\n";
            "\xc3\xa9";
            "\xf0\x9f\x98\x80xyz";
            String.make 1_000 'x';
          ]);
    case "a parse text of 2^32 bytes or more is too long" (fun () ->
        Alcotest.(check (list bool))
          "2^32 - 1, 2^32, 2^32 + 1" [ false; true; true ]
          (List.map Grammar.too_long
             [ 0xFFFF_FFFF; 0x1_0000_0000; 0x1_0000_0001 ]));
    case "code that does not end stops at the fuel" (fun () ->
        refused "a loop" ~limits:small_limits (Link_failed (Stopped Fuel))
          (G.grammar { G.base with prelude = "(loop $l (br $l))" }));
    case "a growth past a limit stops, and never gives -1" (fun () ->
        refused "memory.grow" ~limits:small_limits
          (Link_failed (Stopped Memory))
          (G.grammar (G.report "(memory.grow (i32.const 1000))"));
        refused "memory.grow past 65,536 pages"
          ~limits:(limits ~fuel:50_000_000 ~memory:max_int ~table:100_000)
          (Link_failed (Stopped Memory))
          (G.grammar (G.report "(memory.grow (i32.const 65536))"));
        refused "table.grow"
          ~limits:(limits ~fuel:50_000_000 ~memory:(64 lsl 20) ~table:1_000)
          (Link_failed (Stopped Table))
          (G.grammar
             (G.report "(table.grow 0 (ref.null func) (i32.const 5000))")));
    case "the grammars of the repository stop under small limits" (fun () ->
        refused "json, 1,000 fuel"
          ~limits:(limits ~fuel:1_000 ~memory:(256 lsl 20) ~table:100_000)
          ~g:"json" (Link_failed (Stopped Fuel)) (Lazy.force json);
        refused "rust, 1 MiB of memory"
          ~limits:(limits ~fuel:1_000_000_000 ~memory:(1 lsl 20) ~table:100_000)
          ~g:"rust" (Link_failed (Stopped Memory)) (Lazy.force rust);
        refused "markdown, 3 table elements"
          ~limits:(limits ~fuel:1_000_000_000 ~memory:(256 lsl 20) ~table:3)
          ~g:"markdown" (Link_failed (Stopped Table)) (Lazy.force markdown));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:40
         ~name:"other limits change a decision only to a stop"
         ~print:(fun (f, m, t) ->
           Printf.sprintf "fuel %d, memory %d, table %d" f m t)
         Gen.(
           triple (int_range 0 50_000_000)
             (int_range 0 (16 lsl 20))
             (int_range 0 200))
         (fun (fuel, memory, table) ->
           let l = limits ~fuel ~memory ~table in
           match decide ~limits:l ~g:"json" (Lazy.force json) with
           | Ok _ | Error (Link_failed (Stopped _)) -> true
           | Error e -> QCheck2.Test.fail_reportf "%s" (invalid_text e)));
  ]

let corrupt_cases =
  [
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:60
         ~name:"decide never raises on a grammar with changed or cut bytes"
         ~print:(fun (k, b, cut) ->
           Printf.sprintf "byte %d to %d, cut %d" k b cut)
         Gen.(triple (int_range 0 2999) (int_range 0 255) (int_range 0 3000))
         (fun (k, b, cut) ->
           let bytes = Lazy.force json in
           let n = String.length bytes in
           let changed =
             String.mapi
               (fun i c -> if i = k mod n then Char.chr b else c)
               bytes
           in
           let decided bytes =
             match decide ~limits:small_limits ~g:"json" bytes with
             | Ok _ | Error _ -> true
           in
           decided changed && decided (String.sub bytes 0 (min n cut))));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:200 ~name:"decide never raises on any bytes"
         ~print:W.hex
         Gen.(
           oneof
             [
               string_size (int_range 0 64);
               map (fun s -> W.module_ [] ^ s) (string_size (int_range 0 64));
             ])
         (fun bytes -> match decide bytes with Ok _ | Error _ -> true));
  ]

let gen_json_three_deep =
  Gen.(
    sized_size (int_range 0 3)
    @@ fix (fun self depth ->
        let leaf =
          oneof_list
            [
              "1";
              "-2.5e3";
              "true";
              "false";
              "null";
              "\"a\"";
              "\"\xc3\xa9\"";
              "\"\\n\"";
            ]
        in
        if depth = 0 then leaf
        else
          oneof
            [
              leaf;
              map
                (fun xs -> "[" ^ String.concat ", " xs ^ "]")
                (list_size (int_range 0 3) (self (depth - 1)));
              map
                (fun xs ->
                  "{"
                  ^ String.concat ","
                      (List.mapi
                         (fun k x -> Printf.sprintf "\"k%d\": %s" k x)
                         xs)
                  ^ "}")
                (list_size (int_range 0 3) (self (depth - 1)));
            ]))

let gen_any_text =
  Gen.(
    map
      (fun cs -> Text.encode (Text.of_uchars cs))
      (list_size (int_range 0 30)
         (oneof
            [
              oneof_list
                (List.map Uchar.of_int
                   [
                     0x7b;
                     0x7d;
                     0x5b;
                     0x5d;
                     0x22;
                     0x3a;
                     0x2c;
                     0x31;
                     0x0a;
                     0x20;
                     0xfeff;
                     0xe9;
                   ]);
              map Uchar.of_int (int_range 0 0xd7ff);
            ])))

let tree_facts tree subject =
  let bytes = String.length (Parse_tree.parse_text (text subject)) in
  let types = Grammar.node_types (grammar "json") in
  List.for_all
    (fun (_, n) ->
      let s = Parse_tree.start_byte tree n and e = Parse_tree.end_byte tree n in
      0 <= s && s <= e && e <= bytes
      && Array.exists (Text.equal (Parse_tree.node_type tree n)) types)
    (walk tree)
  && List.length (walk tree) = Parse_tree.node_count tree

(* @verifies packs#{give-reading-results=v1, omit-nodes-of-unparsed-readings=v1, end-grammar-code=v1}
   @verifies conformance#report-stops-at-limits=v1
   A parse that tree-sitter cancels gives No_tree and no nodes. A parse in
   which grammar code or the core instance traps gives Failed (Trap _) and no
   nodes. A parse that stops at fuel, memory, or table limits ends within the
   instance limits, gives Failed (Stopped _) with the limit that stopped it,
   and gives no nodes. *)
let parse_cases =
  [
    case "a parse that the parsing of tree-sitter cancels gives No_tree"
      (fun () ->
        let g =
          usable "t"
            (G.grammar
               {
                 G.base with
                 table_size = 2;
                 fields =
                   "(func $cancel (param i32) (result i32) (i32.const 1)) \
                    (elem (global.get $tb) func $lex $cancel)";
                 lex_body =
                   "(i32.store (i32.add (local.get 0) (i32.const 1328)) \
                    (i32.add (global.get $tb) (i32.const 1))) (i32.const 0)";
               })
        in
        match Grammar.parse ~limits:small_limits g (text "abc") with
        | Error No_tree -> ()
        | Error e -> Alcotest.fail (parse_failure_text e)
        | Ok _ -> Alcotest.fail "a tree");
    case "a parse in which the code of the grammar traps gives no tree"
      (fun () ->
        let g =
          usable "t" (G.grammar { G.base with lex_body = "unreachable" })
        in
        match Grammar.parse ~limits:small_limits g (text "abc") with
        | Error (Failed (Trap _ | Stopped Fuel)) -> ()
        | Error e -> Alcotest.fail (parse_failure_text e)
        | Ok _ -> Alcotest.fail "a tree");
    case "a parse in which the core instance traps gives no tree" (fun () ->
        let g =
          usable "t"
            (G.grammar
               {
                 G.base with
                 imports = G.function_import "malloc" "i32" "i32";
                 lex_body =
                   "(drop (call $malloc (i32.const -16))) (i32.const 0)";
               })
        in
        match Grammar.parse ~limits:small_limits g (text "abc") with
        | Error (Failed (Trap _)) -> ()
        | Error e -> Alcotest.fail (parse_failure_text e)
        | Ok _ -> Alcotest.fail "a tree");
    case "two domains parse with one grammar at the same time" (fun () ->
        let g = grammar "json" in
        let subject = "[1, {\"b\": null}, \"\xc3\xa9\"]" in
        let expected = List.map node_text (nodes_of (parsed "json" subject)) in
        let work () =
          List.init 10 (fun _ ->
              match
                Grammar.parse
                  ~limits:(Grammar.parse_limits (text subject))
                  g (text subject)
              with
              | Ok t -> List.map node_text (nodes_of t)
              | Error e -> [ parse_failure_text e ])
        in
        let other = Domain.spawn work in
        let mine = work () in
        List.iter
          (fun t -> Alcotest.(check (list string)) "the tree" expected t)
          (mine @ Domain.join other));
    case "two domains decide with one core at the same time" (fun () ->
        let work () =
          List.init 5 (fun _ ->
              match decide ~g:"json" (Lazy.force json) with
              | Ok g -> Grammar.abi_version g
              | Error e -> Alcotest.fail (invalid_text e))
        in
        let other = Domain.spawn work in
        let all = work () @ Domain.join other in
        if List.exists (( <> ) 14) all then Alcotest.fail "another ABI version");
    case "a parse under small limits stops" (fun () ->
        let g = grammar "json" in
        List.iter
          (fun (what, l, expected) ->
            match Grammar.parse ~limits:l g (text "[1, 2, 3]") with
            | Error (Failed (Stopped s)) when s = expected -> ()
            | Error e -> Alcotest.failf "%s: %s" what (parse_failure_text e)
            | Ok _ -> Alcotest.failf "%s: a tree" what)
          [
            ( "fuel",
              limits ~fuel:1_000 ~memory:(256 lsl 20) ~table:100_000,
              Instance.Fuel );
            ( "memory",
              limits ~fuel:1_000_000_000 ~memory:(1 lsl 20) ~table:100_000,
              Memory );
            ( "table",
              limits ~fuel:1_000_000_000 ~memory:(256 lsl 20) ~table:2,
              Table );
          ]);
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:100
         ~name:
           "a JSON text gives a tree with no error, of the node types of the \
            grammar"
         ~print:(fun s -> Printf.sprintf "%S" s)
         gen_json_three_deep
         (fun subject ->
           match
             Grammar.parse
               ~limits:(Grammar.parse_limits (text subject))
               (grammar "json") (text subject)
           with
           | Error e -> QCheck2.Test.fail_reportf "%s" (parse_failure_text e)
           | Ok tree ->
               (not (Parse_tree.root_has_error tree)) && tree_facts tree subject));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:150
         ~name:"any text gives a tree whose ERROR nodes give the root an error"
         ~print:(fun s -> Printf.sprintf "%S" s)
         gen_any_text
         (fun subject ->
           match
             Grammar.parse
               ~limits:(Grammar.parse_limits (text subject))
               (grammar "json") (text subject)
           with
           | Error e -> QCheck2.Test.fail_reportf "%s" (parse_failure_text e)
           | Ok tree ->
               let has_error_node =
                 List.exists
                   (fun (_, n) ->
                     Text.encode (Parse_tree.node_type tree n) = "ERROR")
                   (walk tree)
               in
               tree_facts tree subject
               && ((not has_error_node) || Parse_tree.root_has_error tree)));
  ]

(* @verifies packs#confine-grammars=v1
   A grammar whose code wipes the whole memory, the whole table, and the stack
   pointer of the instance in which it runs, or that leaves a mark in its
   memory, changes nothing that another decision or another parse sees: a
   program that ran two grammars in one instance, or that kept an instance for
   a later use, would give another tree or another mark here. *)
let confine_cases =
  let vandal =
    G.grammar
      {
        G.base with
        imports = "(import \"env\" \"__stack_pointer\" (global $sp (mut i32)))";
        prelude =
          "(memory.fill (i32.const 0) (i32.const 255) (i32.mul (memory.size) \
           (i32.const 65536))) (table.fill 0 (i32.const 0) (ref.null func) \
           (table.size 0)) (global.set $sp (i32.const 0)) unreachable";
      }
  in
  let marker =
    G.grammar
      ( G.report
          "(i32.load8_u (i32.sub (i32.mul (memory.size) (i32.const 65536)) \
           (i32.const 1)))"
      |> fun spec ->
        {
          spec with
          postlude =
            "(i32.store8 (i32.sub (i32.mul (memory.size) (i32.const 65536)) \
             (i32.const 1)) (i32.const 42))";
        } )
  in
  [
    case "a grammar that wipes its instance changes no other parse" (fun () ->
        let subject = "{\"a\": [1, true]}" in
        let before = List.map node_text (nodes_of (parsed "json" subject)) in
        refused_by "the vandal" traps vandal;
        let after = List.map node_text (nodes_of (parsed "json" subject)) in
        Alcotest.(check (list string)) "the tree" before after;
        refused_by "the vandal again" traps vandal;
        ignore (usable "json" (Lazy.force json)));
    case "a mark that a grammar leaves is in no later instance" (fun () ->
        let mark () =
          match decide marker with
          | Error (Abi_version n) -> n - 100
          | Ok _ -> Alcotest.fail "usable"
          | Error e -> Alcotest.fail (invalid_text e)
        in
        let first = mark () in
        if first = 42 then Alcotest.fail "a mark before any mark";
        ignore (parsed "json" "[1]");
        Alcotest.(check int) "the second decision" first (mark ());
        refused_by "the vandal" traps vandal;
        Alcotest.(check int) "the third decision" first (mark ()));
  ]

let least_fuel g subject =
  let base = Grammar.parse_limits (text subject) in
  let enough fuel =
    match
      Grammar.parse
        ~limits:(limits ~fuel ~memory:base.memory ~table:base.table)
        g (text subject)
    with
    | Ok _ -> true
    | Error (Failed (Stopped Fuel)) -> false
    | Error e -> Alcotest.failf "the parse: %s" (parse_failure_text e)
  in
  let rec search low high =
    if high - low <= 1 then high
    else
      let mid = (low + high) / 2 in
      if enough mid then search low mid else search mid high
  in
  search 0 base.fuel

let growth_cases =
  [
    slow "the fuel of a parse grows linearly with the text" (fun () ->
        let g = grammar "json" in
        let input n =
          "[" ^ String.concat "," (List.init n (fun _ -> "[1]")) ^ "]"
        in
        let small = least_fuel g (input 500)
        and large = least_fuel g (input 2_000) in
        if large > 2 * 4 * small then
          Alcotest.failf "fuel %d for 500 items and %d for 2,000" small large);
    case "the work of a parse grows linearly with the text" (fun () ->
        let g = grammar "json" in
        Counted_work.check_growth ~margin:2.0 ~sizes:(500, 4_000)
          ~input:(fun n ->
            text ("[" ^ String.concat "," (List.init n (fun _ -> "[1]")) ^ "]"))
          (fun subject ->
            Grammar.parse ~limits:(Grammar.parse_limits subject) g subject));
    case "the work of a decision grows linearly with the bytes of the module"
      (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(200, 1_600)
          ~input:(fun n ->
            G.after_header
              (List.init n (fun _ -> G.custom_section "x" "abcdefgh"))
              (G.grammar G.base))
          (fun bytes -> decide bytes));
    case "the work of a decision grows linearly with the number of symbols"
      (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(8, 64)
          ~input:(fun n ->
            G.grammar
              { G.base with symbols = List.init n (Printf.sprintf "s%d") })
          (fun bytes -> decide bytes));
  ]

let tests =
  core_cases @ grammar_cases @ symbol_cases @ module_cases @ own_cases
  @ own_stop_cases @ limit_cases @ corrupt_cases @ parse_cases @ confine_cases
  @ growth_cases
