(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module W = Wasm_modules

let custom_section name payload = W.section 0 (W.name name ^ payload)

let memory_information ~memory_size ~memory_alignment ~table_size
    ~table_alignment =
  let payload =
    W.u32 memory_size ^ W.u32 memory_alignment ^ W.u32 table_size
    ^ W.u32 table_alignment
  in
  "\x01" ^ W.u32 (String.length payload) ^ payload

let dylink subsections =
  custom_section "dylink.0" (String.concat "" subsections)

let after_header sections bytes =
  String.sub bytes 0 8 ^ String.concat "" sections
  ^ String.sub bytes 8 (String.length bytes - 8)

type spec = {
  grammar_name : string;
  imports : string;
  fields : string;
  prelude : string;
  abi : string;
  postlude : string;
  module_name : string;
  memory_minimum : int;
  table_minimum : int;
  symbols : string list;
  aliases : int;
  lex : bool;
  lex_body : string;
  memory_size : int;
  memory_alignment : int;
  table_size : int;
  table_alignment : int;
}

let base =
  {
    grammar_name = "t";
    imports = "";
    fields = "";
    prelude = "";
    abi = "(i32.const 14)";
    postlude = "";
    module_name = "env";
    memory_minimum = 0;
    table_minimum = 0;
    symbols = [ "end" ];
    aliases = 0;
    lex = true;
    lex_body = "(i32.const 0)";
    memory_size = 1024;
    memory_alignment = 4;
    table_size = 1;
    table_alignment = 0;
  }

let le32 n = String.init 4 (fun k -> Char.chr ((n lsr (8 * k)) land 0xff))

let escaped bytes =
  String.concat ""
    (List.init (String.length bytes) (fun k ->
         Printf.sprintf "\\%02x" (Char.code bytes.[k])))

let text spec =
  let count = List.length spec.symbols in
  let struct_ =
    String.make 4 '\x00'
    ^ le32 (count - spec.aliases)
    ^ le32 spec.aliases
    ^ String.make (512 - 12) '\x00'
  in
  let names, offsets =
    List.fold_left
      (fun (bytes, offsets) name ->
        (bytes ^ name ^ "\x00", (512 + String.length bytes) :: offsets))
      ("", []) spec.symbols
  in
  let offsets = List.rev offsets in
  let store_name k offset =
    Printf.sprintf
      "(i32.store offset=%d (global.get $mb) (i32.add (global.get $mb) \
       (i32.const %d)))"
      (256 + (4 * k))
      offset
  in
  Printf.sprintf
    "(module (import \"%s\" \"memory\" (memory %d)) (import \"%s\" \
     \"__indirect_function_table\" (table %d funcref)) (import \"%s\" \
     \"__memory_base\" (global $mb i32)) (import \"%s\" \"__table_base\" \
     (global $tb i32)) %s (func $lex (param i32 i32) (result i32) %s) (elem \
     (global.get $tb) func $lex) (data (global.get $mb) \"%s\") %s (func \
     (export \"tree_sitter_%s\") (result i32) %s (i32.store (global.get $mb) \
     %s) (i32.store offset=56 (global.get $mb) (i32.add (global.get $mb) \
     (i32.const 256))) %s %s %s (global.get $mb)))"
    spec.module_name spec.memory_minimum spec.module_name spec.table_minimum
    spec.module_name spec.module_name spec.imports spec.lex_body
    (escaped (struct_ ^ names))
    spec.fields spec.grammar_name spec.prelude spec.abi
    (String.concat " " (List.mapi store_name offsets))
    (if spec.lex then "(i32.store offset=92 (global.get $mb) (global.get $tb))"
     else "")
    spec.postlude

let grammar spec =
  after_header
    [
      dylink
        [
          memory_information ~memory_size:spec.memory_size
            ~memory_alignment:spec.memory_alignment ~table_size:spec.table_size
            ~table_alignment:spec.table_alignment;
        ];
    ]
    (W.of_text (text spec))

let report expression =
  { base with abi = Printf.sprintf "(i32.add (i32.const 100) %s)" expression }

let function_import name params results =
  let part keyword types =
    if types = "" then "" else Printf.sprintf " (%s %s)" keyword types
  in
  Printf.sprintf "(import \"env\" \"%s\" (func $%s%s%s))" name name
    (part "param" params) (part "result" results)
