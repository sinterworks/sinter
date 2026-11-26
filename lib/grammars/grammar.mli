(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Usable grammars, as the term [usable-grammar] of the design [packs=v1]
    defines them, and the parse trees of texts with them, each in an instance of
    a grammar of its own.

    An instance of a grammar is a new store (see {!Sinter_wasm_engine.Store})
    that holds a new instance of the core of tree-sitter (see {!Core}) and,
    linked to it, a new instance of the module of the grammar. The program makes
    one for each decision whether a byte sequence is a usable grammar and one
    for each parse, and releases it at the end. So the code of a grammar reaches
    only the memory, the table, the globals, and the functions of its own
    instance of the core, and never those of another instance of a grammar or of
    an instance of an adapter.

    The imports that the program gives the module of a grammar, by their names,
    whatever their module names, are these, and no other:

    - [memory] and [__indirect_function_table]: the memory and the table of the
      core;
    - [__memory_base] and [__table_base]: new constant globals of the type
      [i32], with the places of the own bytes and of the own elements of the
      module, which the program takes from the memory and the table of the core
      as the memory information of the module asks (see {!Dylink});
    - [__stack_pointer]: the global [__stack_pointer] of the core, so that the
      module uses the C stack of the core;
    - the 25 functions that tree-sitter gives the module of a grammar: [calloc],
      [free], [iswalnum], [iswalpha], [iswblank], [iswdigit], [iswlower],
      [iswpunct], [iswspace], [iswupper], [iswxdigit], [malloc], [memchr],
      [memcmp], [memcpy], [memmove], [memset], [realloc], [strcmp], [strlen],
      [strncat], [strncmp], [strncpy], [towlower], and [towupper]: the function
      exports of the core of the same names, each with its type;
    - [__assert_fail]: a function of the type [[i32 i32 i32 i32] -> []] that
      traps.

    A module that imports another name, or one of these names as another kind or
    with another type, is not a usable grammar for the program. *)

open Sinter_text
open Sinter_wasm_engine

type t
(** A byte sequence that is a usable grammar, with its grammar name, its
    compiled module, its memory information, and the names of the symbols of its
    language. Only {!decide} makes one. Two domains can use one value at the
    same time; each parse has an instance of a grammar of its own. *)

(** Why a byte sequence is not a usable grammar for the program. *)
type invalid =
  | Not_a_module of string
      (** the byte sequence is not a WebAssembly module, or the engine stopped
          its decoding or its validation at a limit of its own; with the message
          of the engine for a person *)
  | No_memory_information of Dylink.error
      (** the module of the byte sequence has no memory information that the
          program can use *)
  | Import_not_given of { module_name : string; name : string }
      (** the module of the byte sequence has this import, which the program
          does not give, as its name, its kind, or its type says *)
  | No_language_export
      (** the module of the byte sequence does not export [tree_sitter_]
          followed by the grammar name as a function of the type [[] -> [i32]]
      *)
  | Wrong_start_export of string
      (** the module of the byte sequence exports [__wasm_apply_data_relocs],
          [_initialize], or [__wasm_call_ctors], this name, as another thing
          than a function of the type [[] -> []] *)
  | Link_failed of Instance.failure
      (** an instantiation, a growth of the memory or of the table of the core,
          or an invocation failed in the instance of the decision *)
  | Abi_version of int
      (** the language that the module gives has this ABI version, which is not
          from 13 to 15: the 32-bit word of the ABI version of the language,
          unchanged, as an unsigned number *)
  | Not_parseable
      (** the core does not take the language that the module gives for a parse:
          the language has no lexing function *)
  | Wrong_symbols of string
      (** the core gave no list of the names of the symbols of the language that
          the program can read; with a reason for a person *)
  | Symbol_name of int
      (** the name of the symbol with this number, the lowest such number, is
          not valid UTF-8 *)

val load_limits : Instance.limits
(** [load_limits] is the default of [limits] for {!decide}: 10,000,000,000 units
    of fuel, 268,435,456 bytes (256 MiB) of memory, and 1,048,576 table
    elements. *)

(* @satisfies conformance#report-stops-at-limits=v1
   A stop at a limit of the program in the decision gives [Link_failed] with
   the failure that names the limit; a number of own bytes or own elements,
   with the room for its alignment, above 4,294,967,295 gives
   [Link_failed (Stopped Memory)] or [Link_failed (Stopped Table)]. *)
val decide :
  ?limits:Instance.limits ->
  Core.t ->
  Sinter_pack_descriptor.Grammar_name.t ->
  string ->
  (t, invalid) result
(** [decide ?limits core g bytes] decides whether [bytes] is a usable grammar
    with the grammar name [g], in a new instance of a grammar of [core] under
    [limits]. It is [Ok] when all of these conditions hold, and else [Error]
    with the first condition that does not hold. The order of the conditions is
    the order of the constructors of {!invalid}.

    + [bytes] is a WebAssembly module.
    + The module has memory information.
    + The program gives each import of the module.
    + The module exports [tree_sitter_] followed by [g] as a function of the
      type [[] -> [i32]].
    + Each of the exports [__wasm_apply_data_relocs], [_initialize], and
      [__wasm_call_ctors] that the module has is a function of the type
      [[] -> []].
    + In the instance, these steps do not fail, in this order: the link of the
      module; the invocation of [__wasm_apply_data_relocs] when the module
      exports it; the invocation of [_initialize] when the module exports it, or
      else of [__wasm_call_ctors] when the module exports it; the invocation of
      the function [tree_sitter_] followed by [g], which gives a language of
      tree-sitter.
    + The language has an ABI version from 13 to 15.
    + The core takes the language for a parse.
    + The core gives the names of the symbols of the language, its aliases
      included, in a record that the program can read.
    + The name of each symbol is valid UTF-8.

    In the instance of a grammar, the program takes the own bytes of the module
    from the memory of the core, inside one space that the allocation functions
    of the core give for the number of own bytes plus 2 to the power of the
    memory alignment of the module, minus 1: they lie inside that space, they
    start at [__memory_base], the first multiple of 2 to the power of the memory
    alignment at or after the start of that space, and each of them is 0 when
    the program instantiates the module. It takes the own elements of the module
    from new null elements at the end of the table of the core, as many as the
    number of own elements plus 2 to the power of the table alignment of the
    module, minus 1: they lie inside those new elements, and they start at
    [__table_base], the first multiple of 2 to the power of the table alignment
    at or after the number of elements that the table had before. The allocation
    functions of the core take a number of bytes of at most 4,294,967,295, and a
    table holds at most 4,294,967,295 elements. So when the number of bytes of
    that space is more than 4,294,967,295, the result is
    [Error (Link_failed (Stopped Memory))]. When the number of those new
    elements is more than 4,294,967,295, the result is
    [Error (Link_failed (Stopped Table))]. Then, before the instantiation, it
    grows the memory of the core to the minimum of the type of the import
    [memory] when the memory has fewer pages, and the table of the core to the
    minimum of the type of the import [__indirect_function_table] when the table
    has fewer elements; it does not grow them otherwise. An access of the code
    outside the memory or the table traps, and gives [Link_failed (Trap _)]: so
    does a language whose list of the names of its symbols lies outside the
    memory.

    When the code exhausts its call stack, or the program stops the code at a
    limit of [limits], the result is [Error (Link_failed f)], with [f]
    [Stack_exhausted] or [Stopped _]: "invalid". A stop at fuel or an exhausted
    call stack ends code that can be code that never ends, and the program
    cannot tell such code from code that needs more fuel or more stack; a stop
    at memory or table elements can also come from code that never ends, such as
    a loop that grows a memory without end. So the program gives for each of
    them the result that a fault of the input gives, and the failure names the
    limit at which the program stopped. A decision with other [limits] can give
    another result only for such a byte sequence. The default of [limits] is
    {!load_limits}. The function returns after at most the fuel of [limits] in
    the code that it runs. The time is that of one compilation of [bytes], plus
    that of the code that it runs, plus a time linear in the length of [bytes]
    and in the number of the symbols and the bytes of their names.

    @raise Failure when the engine stops on an internal fault. *)

val grammar_name : t -> Sinter_pack_descriptor.Grammar_name.t
(** [grammar_name grammar] is the grammar name of [grammar]. *)

val abi_version : t -> int
(** [abi_version grammar] is the ABI version of the language of [grammar], from
    13 to 15. *)

val node_types : t -> Text.t array
(** [node_types grammar] is the text of the name of each symbol of the language
    of [grammar], its aliases included, at the index of the number of the
    symbol, and then the text [ERROR], the node type of an [ERROR] node, at the
    index of the number of symbols. The parse trees of [grammar] give each node
    its node type through these indexes (see {!Parse_tree.decode}). The array is
    new at each call. *)

(** Why a parse gave no parse tree. *)
type parse_failure =
  | Too_long
      (** the parse text has 4,294,967,296 bytes or more in its UTF-8 encoding
      *)
  | Failed of Instance.failure
      (** an instantiation, a growth, or an invocation failed in the instance of
          the parse *)
  | No_tree  (** the parsing of tree-sitter gave no parse tree *)
  | Wrong_record of string
      (** the record of the parse tree that the core gave is not a record of a
          parse tree of the text; with a reason for a person *)

val parse_limits : Text.t -> Instance.limits
(** [parse_limits text] is limits for {!parse} of [text]. Let m be the number of
    bytes of the parse text of [text]. The limits are 1,000,000,000 plus 100,000
    times m units of fuel (see {!Sinter_wasm_engine.Instance.limits}),
    268,435,456 plus 1,024 times m bytes of memory, and 1,048,576 table
    elements. The time is linear in the length of [text]. *)

val too_long : int -> bool
(** [too_long bytes] is [true] exactly when a parse text of [bytes] bytes is too
    long for {!parse}: when [bytes] is 4,294,967,296 or more. *)

(* @satisfies conformance#report-stops-at-limits=v1
   A stop at a limit of the program in a parse gives [Failed] with the failure
   that names the limit. *)
val parse :
  limits:Instance.limits -> t -> Text.t -> (Parse_tree.t, parse_failure) result
(** [parse ~limits grammar text] is the parse tree of [text] with [grammar]: the
    tree that the parsing of tree-sitter gives for the language of [grammar] and
    the UTF-8 encoding of the parse text of [text], in a new instance of a
    grammar of the module of [grammar] under [limits], in which the program
    links the module and invokes its functions as {!decide} does. It is
    [Error Too_long] when the number of bytes of the parse text is {!too_long},
    and [Error] when the parsing gives no parse tree, and when the
    instantiation, the link, or an invocation fails in that instance. An
    exhausted call stack or a stop at a limit of [limits] gives
    [Error (Failed Stack_exhausted)] or [Error (Failed (Stopped _))], which
    names the limit, and no parse tree. {!parse_limits} gives limits for a text.
    The function returns after at most the fuel of [limits] in the code that it
    runs. Apart from the time of the code that the parse runs, the time of the
    function is in O(m + n log m) for a parse text of m bytes and a parse tree
    of n nodes (see {!Parse_tree.decode}).

    @raise Failure when the engine stops on an internal fault. *)
