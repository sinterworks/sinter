(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_grammars
module W = Wasm_modules
module G = Grammar_modules
module Gen = QCheck2.Gen

let read_file path = In_channel.with_open_bin path In_channel.input_all
let json = lazy (read_file "fixtures/tree-sitter-json/tree-sitter-json.wasm")
let rust = lazy (read_file "fixtures/tree-sitter-rust/tree-sitter-rust.wasm")
let markdown = lazy (read_file "../lib/markdown/tree-sitter-markdown.wasm")

let error_text = function
  | Dylink.Not_a_module -> "not a module"
  | No_section -> "no section"
  | Several_sections -> "several sections"
  | Malformed_section -> "malformed section"
  | Other_subsection k -> Printf.sprintf "other subsection %d" k
  | No_memory_subsection -> "no memory subsection"
  | Several_memory_subsections -> "several memory subsections"
  | Malformed_memory_subsection -> "malformed memory subsection"

let info_text (i : Dylink.t) =
  Printf.sprintf "%d %d %d %d" i.memory_size i.memory_alignment i.table_size
    i.table_alignment

let result_text = function Ok i -> info_text i | Error e -> error_text e

let gives what expected bytes =
  Alcotest.(check string) what expected (result_text (Dylink.read bytes))

let fails what expected bytes =
  Alcotest.(check string)
    what (error_text expected)
    (result_text (Dylink.read bytes))

let case name f = Alcotest.test_case name `Quick f
let empty_module = W.module_ []
let type_section = W.section 1 (W.vec [ "\x60\x00\x00" ])

let mem ?(m = 1) ?(ma = 2) ?(t = 3) ?(ta = 4) () =
  G.memory_information ~memory_size:m ~memory_alignment:ma ~table_size:t
    ~table_alignment:ta

let with_sections sections = W.module_ sections

let tests =
  [
    case "the grammars of the repository have their memory information"
      (fun () ->
        gives "json" "2928 4 1 0" (Lazy.force json);
        gives "rust" "1086640 4 7 0" (Lazy.force rust);
        gives "markdown" "235832 4 6 0" (Lazy.force markdown));
    case "the four numbers come in the order of the fields" (fun () ->
        gives "the numbers" "1 2 3 4" (with_sections [ G.dylink [ mem () ] ]);
        gives "the largest numbers" "4294967295 4294967295 0 4294967295"
          (with_sections
             [
               G.dylink
                 [ mem ~m:4294967295 ~ma:4294967295 ~t:0 ~ta:4294967295 () ];
             ]));
    case
      "the section can stand after other sections, whose content is not checked"
      (fun () ->
        gives "after a type section" "1 2 3 4"
          (with_sections [ type_section; G.dylink [ mem () ] ]);
        gives "after a section of junk" "1 2 3 4"
          (with_sections [ W.section 10 "\xff\xff\xff"; G.dylink [ mem () ] ]);
        gives "among other custom sections" "1 2 3 4"
          (with_sections
             [
               G.custom_section "name" "\x00";
               G.dylink [ mem () ];
               G.custom_section "dylink" "\x01";
             ]));
    case "bytes that are not a module give Not_a_module" (fun () ->
        List.iter
          (fun bytes -> fails (Printf.sprintf "%S" bytes) Not_a_module bytes)
          [
            "";
            "\x00asm";
            "\x00asm\x02\x00\x00\x00";
            "\x00ASM\x01\x00\x00\x00";
            "\x00asm\x01\x00\x00";
            empty_module ^ "\x00";
            empty_module ^ "\x00\x05abc";
            empty_module ^ "\x00\x00";
            empty_module ^ "\x00\x02\x05a";
            empty_module ^ "\x01\x80\x80\x80\x80\x10";
            empty_module ^ "\x01\x80\x80\x80\x80\x80\x00";
            with_sections [ G.dylink [ mem () ] ] ^ "\x0a\x09\x00";
          ]);
    case "a broken section after the memory information gives Not_a_module"
      (fun () ->
        fails "a truncated section" Not_a_module
          (with_sections [ G.dylink [ mem () ] ] ^ "\x01\x05\x00"));
    case "a module with no section dylink.0 gives No_section" (fun () ->
        fails "no section" No_section empty_module;
        fails "a section dylink" No_section
          (with_sections [ G.custom_section "dylink" (mem ()) ]);
        fails "a section dylink.1" No_section
          (with_sections [ G.custom_section "dylink.1" (mem ()) ]));
    case "two sections dylink.0 give Several_sections, even when malformed"
      (fun () ->
        fails "two good sections" Several_sections
          (with_sections [ G.dylink [ mem () ]; G.dylink [ mem () ] ]);
        fails "two malformed sections" Several_sections
          (with_sections [ G.dylink [ "\x01\x09" ]; G.dylink [ "\x05" ] ]));
    case
      "a section that is not a sequence of subsections gives Malformed_section"
      (fun () ->
        List.iter
          (fun payload ->
            fails
              (Printf.sprintf "%S" payload)
              Malformed_section
              (with_sections [ G.dylink [ payload ] ]))
          [
            "\x01";
            "\x01\x05\x00";
            "\x01\x80\x80\x80\x80\x80\x01";
            mem () ^ "\x02";
          ]);
    case "a subsection of another type gives Other_subsection" (fun () ->
        fails "type 2 after type 1" (Other_subsection 2)
          (with_sections [ G.dylink [ mem (); "\x02\x01\x00" ] ]);
        fails "type 3 before type 1" (Other_subsection 3)
          (with_sections [ G.dylink [ "\x03\x00"; mem () ] ]);
        fails "type 0 alone" (Other_subsection 0)
          (with_sections [ G.dylink [ "\x00\x00" ] ]));
    case "a section with no subsection of type 1 gives No_memory_subsection"
      (fun () ->
        fails "an empty section" No_memory_subsection
          (with_sections [ G.dylink [] ]));
    case "two subsections of type 1 give Several_memory_subsections" (fun () ->
        fails "two" Several_memory_subsections
          (with_sections [ G.dylink [ mem (); mem () ] ]));
    case
      "a subsection of type 1 that is not four numbers gives \
       Malformed_memory_subsection" (fun () ->
        let sub payload = "\x01" ^ W.u32 (String.length payload) ^ payload in
        List.iter
          (fun payload ->
            fails
              (Printf.sprintf "%S" payload)
              Malformed_memory_subsection
              (with_sections [ G.dylink [ sub payload ] ]))
          [
            "";
            "\x01\x02\x03";
            "\x01\x02\x03\x04\x05";
            "\x01\x02\x03\x80";
            "\x01\x02\x03\x80\x80\x80\x80\x10";
            "\x80\x80\x80\x80\x80\x00\x02\x03\x04";
          ]);
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:1000 ~name:"read never raises on any bytes"
         ~print:W.hex
         Gen.(
           oneof
             [
               string_size (int_range 0 64);
               map (fun s -> empty_module ^ s) (string_size (int_range 0 64));
               map
                 (fun s -> with_sections [ G.custom_section "dylink.0" s ])
                 (string_size (int_range 0 32));
             ])
         (fun bytes -> match Dylink.read bytes with Ok _ | Error _ -> true));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:200
         ~name:"read never raises on a grammar with changed or cut bytes"
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
           let cut_bytes = String.sub bytes 0 (min n cut) in
           (match Dylink.read changed with Ok _ | Error _ -> true)
           && match Dylink.read cut_bytes with Ok _ | Error _ -> true));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:300
         ~name:"the numbers of any memory information read back"
         ~print:(fun (a, b, c, d) -> Printf.sprintf "%d %d %d %d" a b c d)
         Gen.(
           let n = oneof [ int_range 0 300; int_range 0 0xffff_ffff ] in
           quad n n n n)
         (fun (m, ma, t, ta) ->
           result_text
             (Dylink.read (with_sections [ G.dylink [ mem ~m ~ma ~t ~ta () ] ]))
           = Printf.sprintf "%d %d %d %d" m ma t ta));
    case "the work of read grows linearly with the number of sections"
      (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(500, 4_000)
          ~input:(fun n ->
            with_sections
              (List.init n (fun _ -> G.custom_section "x" "abc")
              @ [ G.dylink [ mem () ] ]))
          Dylink.read);
  ]
