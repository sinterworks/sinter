(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Modules of grammars for the tests, built as the text format of the
    WebAssembly Core Specification 2.0 with a custom section [dylink.0], and the
    language of tree-sitter 0.27.2 that such a module gives.

    The language is the struct [TSLanguage] of [lib/src/parser.h] of tree-sitter
    0.27.2 on wasm32: the ABI version at byte 0, the symbol count at 4, the
    alias count at 8, the address of the array of the addresses of the symbol
    names at 56, and the lexing function, an index of the table, at 92. Every
    other field is 0. *)

(** {1 Custom sections} *)

val custom_section : string -> string -> string
(** [custom_section name payload] is a custom section (identifier 0) with the
    name [name] and the bytes [payload]. *)

val memory_information :
  memory_size:int ->
  memory_alignment:int ->
  table_size:int ->
  table_alignment:int ->
  string
(** [memory_information ~memory_size ~memory_alignment ~table_size
     ~table_alignment] is the subsection of the type 1 of [dylink.0]: the type
    byte, its size, and the four numbers as unsigned LEB128 numbers. *)

val dylink : string list -> string
(** [dylink subsections] is the custom section [dylink.0] whose payload is
    [subsections], in order. *)

val after_header : string list -> string -> string
(** [after_header sections bytes] is the module [bytes] with [sections] put
    right after its eight bytes of header, before its first section. *)

(** {1 Grammars} *)

type spec = {
  grammar_name : string;  (** [g] of the export [tree_sitter_<g>] *)
  imports : string;
      (** more imports, in the text format; the module always imports
          [env.memory], [env.__indirect_function_table], [env.__memory_base] as
          [$mb], and [env.__table_base] as [$tb] *)
  fields : string;
      (** more fields of the module, such as functions and exports, in the text
          format *)
  prelude : string;
      (** instructions that [tree_sitter_<g>] runs first, with an empty stack
          before and after *)
  abi : string;
      (** an expression of the type [i32] that gives the ABI version word, in
          the text format; it runs after [prelude] *)
  postlude : string;
      (** instructions that [tree_sitter_<g>] runs after it wrote the language,
          with an empty stack before and after *)
  module_name : string;  (** the module name of the four imports above *)
  memory_minimum : int;  (** the minimum of the type of [memory], in pages *)
  table_minimum : int;
      (** the minimum of the type of [__indirect_function_table] *)
  symbols : string list;
      (** the bytes of the name of each symbol, without the final NUL *)
  aliases : int;
      (** the last [aliases] names of [symbols] are aliases; the symbol count is
          the length of [symbols] less [aliases] *)
  lex : bool;
      (** the lexing function is the function [$lex] of the table; when [false],
          the field is 0 *)
  lex_body : string;
      (** the body of [$lex], of the type [[i32 i32] -> [i32]], in the text
          format *)
  memory_size : int;  (** of the memory information, at least 1,024 *)
  memory_alignment : int;
  table_size : int;  (** of the memory information, at least 1 *)
  table_alignment : int;
}
(** A grammar. The own bytes hold the language at offset 0, the array of the
    addresses of the names at 256, and the names at 512. *)

val base : spec
(** [base] is a usable grammar with the grammar name [t]: ABI version 14, one
    symbol [end], a lexing function that gives 0, no other import and no other
    field, the module name [env], minimums of 0, 1,024 own bytes aligned to 16,
    and one own element. *)

val text : spec -> string
(** [text spec] is the text format of the module of [spec], without its memory
    information. *)

val grammar : spec -> string
(** [grammar spec] is the bytes of the module of [spec], with its memory
    information as the first section. *)

val report : string -> spec
(** [report expression] is [base] whose ABI version word is 100 plus the value
    of the [i32] expression [expression]. *)

val function_import : string -> string -> string -> string
(** [function_import name params results] is an import of the function
    [env.<name>] as [$<name>], with the parameter types [params] and the result
    types [results] in the text format, such as ["i32 i32"]. *)
