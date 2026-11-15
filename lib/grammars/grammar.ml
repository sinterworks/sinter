(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_wasm_engine
module Grammar_name = Sinter_pack_descriptor.Grammar_name

type t = {
  core : Core.t;
  name : Grammar_name.t;
  compiled : Wasm_module.t;
  information : Dylink.t;
  abi_version : int;
  node_types : Text.t array;
}

type invalid =
  | Not_a_module of string
  | No_memory_information of Dylink.error
  | Import_not_given of { module_name : string; name : string }
  | No_language_export
  | Wrong_start_export of string
  | Link_failed of Instance.failure
  | Abi_version of int
  | Not_parseable
  | Wrong_symbols of string
  | Symbol_name of int

type parse_failure =
  | Too_long
  | Failed of Instance.failure
  | No_tree
  | Wrong_record of string

let limits ~fuel ~memory ~table =
  Result.get_ok (Instance.limits ~fuel ~memory ~table)

let load_limits =
  limits ~fuel:10_000_000_000 ~memory:268_435_456 ~table:1_048_576

let measured text =
  let bytes = Parse_tree.parse_text text in
  (bytes, String.length bytes)

let parse_limits text =
  let _, bytes = measured text in
  limits
    ~fuel:(1_000_000_000 + (100_000 * bytes))
    ~memory:(268_435_456 + (1_024 * bytes))
    ~table:1_048_576

let core_functions =
  [
    "calloc";
    "free";
    "iswalnum";
    "iswalpha";
    "iswblank";
    "iswdigit";
    "iswlower";
    "iswpunct";
    "iswspace";
    "iswupper";
    "iswxdigit";
    "malloc";
    "memchr";
    "memcmp";
    "memcpy";
    "memmove";
    "memset";
    "realloc";
    "strcmp";
    "strlen";
    "strncat";
    "strncmp";
    "strncpy";
    "towlower";
    "towupper";
  ]

let start_exports =
  [ "__wasm_apply_data_relocs"; "_initialize"; "__wasm_call_ctors" ]

let language_export name = "tree_sitter_" ^ (name : Grammar_name.t :> string)
let core_memory = "memory"
let core_table = "__indirect_function_table"

let i32_global ~mutable_ =
  Wasm_module.Global_import { value_type = I32; mutable_ }

(* @satisfies packs#confine-grammars=v1
   The module of a grammar gets only the memory, the table, the global
   __stack_pointer, and the function exports of its own instance of the core,
   new constant globals, and a function that traps; each other import is
   refused, so its code reaches nothing of another instance. *)
let given core_exports (import : Wasm_module.import) =
  match (import.name, import.type_) with
  | "memory", Memory_import _ -> true
  | "__indirect_function_table", Table_import { element = Funcref; _ } -> true
  | ("__memory_base" | "__table_base"), type_ ->
      type_ = i32_global ~mutable_:false
  | "__stack_pointer", type_ -> type_ = i32_global ~mutable_:true
  | ( "__assert_fail",
      Function_import { params = [ I32; I32; I32; I32 ]; results = [] } ) ->
      true
  | name, Function_import { params; results } ->
      List.mem name core_functions
      && List.assoc_opt name core_exports
         = Some (Wasm_module.Function { params; results })
  | _ -> false

let nothing_to_nothing = Wasm_module.Function { params = []; results = [] }

let check_exports name compiled =
  let exports = Wasm_module.exports compiled in
  match List.assoc_opt (language_export name) exports with
  | Some (Function { params = []; results = [ I32 ] }) -> (
      match
        List.find_opt
          (fun start ->
            match List.assoc_opt start exports with
            | Some export -> export <> nothing_to_nothing
            | None -> false)
          start_exports
      with
      | Some start -> Error (Wrong_start_export start)
      | None -> Ok exports)
  | _ -> Error No_language_export

let check_module core name bytes =
  match Wasm_module.compile (Core.engine core) bytes with
  | Error (Not_compiled message) -> Error (Not_a_module message)
  | Ok compiled -> (
      match Dylink.read bytes with
      | Error error -> Error (No_memory_information error)
      | Ok information -> (
          let core_exports = Wasm_module.exports (Core.compiled core) in
          match
            List.find_opt
              (fun import -> not (given core_exports import))
              (Wasm_module.imports compiled)
          with
          | Some { module_name; name = import_name; _ } ->
              Error (Import_not_given { module_name; name = import_name })
          | None ->
              Result.map
                (fun exports -> (compiled, information, exports))
                (check_exports name compiled)))

let unsigned number = Int32.to_int number land 0xFFFF_FFFF
let ( let* ) = Result.bind

type linked = {
  store : Store.t;
  core_instance : Store.instance;
  language : int;
}

let call store instance name arguments =
  Result.map unsigned
    (Store.invoke store instance name
       (List.map
          (fun number -> Instance.Value.I32 (Int32.of_int number))
          arguments)
       Instance.Result_type.I32)

let stopped limit = Error (Instance.Stopped limit)
let page = 65_536

let own_bytes store core (information : Dylink.t) =
  if information.memory_alignment > 4 then stopped Memory
  else call store core "calloc" [ 1; information.memory_size ]

let own_elements store core (information : Dylink.t) =
  if information.table_alignment > 0 then stopped Table
  else Store.grow_table store core core_table information.table_size

let grow_to_minimums store core imports =
  List.fold_left
    (fun result (import : Wasm_module.import) ->
      let* () = result in
      match import.type_ with
      | Memory_import { minimum; _ } ->
          let* bytes = Store.memory_size store core core_memory in
          let pages = bytes / page in
          Result.map ignore
            (Store.grow_memory store core core_memory
               (max pages minimum - pages))
      | Table_import { minimum; _ } ->
          let* size = Store.grow_table store core core_table 0 in
          Result.map ignore
            (Store.grow_table store core core_table (max size minimum - size))
      | _ -> Ok ())
    (Ok ()) imports

let source core ~memory_base ~table_base (import : Wasm_module.import) =
  match import.name with
  | "__memory_base" ->
      Store.Global { mutable_ = false; value = Int32.of_int memory_base }
  | "__table_base" ->
      Store.Global { mutable_ = false; value = Int32.of_int table_base }
  | "__assert_fail" -> Store.Trap
  | name -> Store.Export (core, name)

let run_starts store grammar exports =
  let invoke name =
    if List.mem_assoc name exports then
      Store.invoke store grammar name [] Instance.Result_type.Nothing
    else Ok ()
  in
  let* () = invoke "__wasm_apply_data_relocs" in
  if List.mem_assoc "_initialize" exports then invoke "_initialize"
  else invoke "__wasm_call_ctors"

(* @satisfies packs#confine-grammars=v1
   Each instance of a grammar is a new store with a new instance of the core,
   to which the program links the module alone; no store, memory, table, or
   global is shared with another instance of a grammar or of an adapter. *)
let with_instance ~limits core compiled information exports name use =
  let store = Store.create (Core.engine core) limits in
  Fun.protect
    ~finally:(fun () -> Store.release store)
    (fun () ->
      let linked =
        let* core_instance = Store.instantiate store (Core.compiled core) [] in
        let* memory_base = own_bytes store core_instance information in
        let* table_base = own_elements store core_instance information in
        let imports = Wasm_module.imports compiled in
        let* () = grow_to_minimums store core_instance imports in
        let* grammar =
          Store.instantiate store compiled
            (List.map (source core_instance ~memory_base ~table_base) imports)
        in
        let* () = run_starts store grammar exports in
        let* language = call store grammar (language_export name) [] in
        Ok { store; core_instance; language }
      in
      use linked)

let read_inside store core ~address ~length =
  let* size = Store.memory_size store core core_memory in
  if length > size - address then Ok None
  else
    Result.map Option.some
      (Store.read store core ~memory:core_memory ~address ~length)

let read_record store core address ~length_of =
  let* first = call store core "sinter_word" [ address ] in
  read_inside store core ~address ~length:(length_of first)

let symbol_names record =
  let length = String.length record in
  let take at size =
    if size > length - at then None else Some (String.sub record at size)
  in
  let word at =
    Option.map (fun bytes -> unsigned (String.get_int32_le bytes 0)) (take at 4)
  in
  let rec lengths at count found =
    if count = 0 then Some (at, List.rev found)
    else
      Option.bind (word at) (fun name_length ->
          lengths (at + 4) (count - 1) (name_length :: found))
  in
  let rec names at found = function
    | [] -> if at = length then Some (List.rev found) else None
    | name_length :: rest ->
        Option.bind (take at name_length) (fun name ->
            names (at + name_length) (name :: found) rest)
  in
  Option.bind (word 4) (fun count ->
      Option.bind (lengths 8 count []) (fun (at, lengths) ->
          names at [] lengths))

let error_type =
  Text.of_uchars (List.map Uchar.of_char [ 'E'; 'R'; 'R'; 'O'; 'R' ])

let node_types_of names =
  let rec go index found = function
    | [] -> Ok (Array.of_list (List.rev (error_type :: found)))
    | name :: rest -> (
        match Text.decode name with
        | Ok text -> go (index + 1) (text :: found) rest
        | Error _ -> Error (Symbol_name index))
  in
  go 0 [] names

let describe linked =
  let { store; core_instance = core; language } = linked in
  let* abi = call store core "sinter_language_abi" [ language ] in
  if abi < 13 || abi > 15 then Ok (Error (Abi_version abi))
  else
    let* parser = call store core "sinter_parser" [ language ] in
    if parser = 0 then Ok (Error Not_parseable)
    else
      let* address = call store core "sinter_symbols" [ language ] in
      let* record = read_record store core address ~length_of:Fun.id in
      Ok
        (match record with
        | None ->
            Error
              (Wrong_symbols "the record of the names lies outside the memory")
        | Some record -> (
            match symbol_names record with
            | None ->
                Error
                  (Wrong_symbols "the record of the names is not well formed")
            | Some names ->
                Result.map
                  (fun node_types -> (abi, node_types))
                  (node_types_of names)))

let decide ?(limits = load_limits) core name bytes =
  let* compiled, information, exports = check_module core name bytes in
  with_instance ~limits core compiled information exports name (fun linked ->
      match Result.bind linked describe with
      | Error failure -> Error (Link_failed failure)
      | Ok (Error invalid) -> Error invalid
      | Ok (Ok (abi_version, node_types)) ->
          Ok { core; name; compiled; information; abi_version; node_types })

let grammar_name grammar = grammar.name
let abi_version grammar = grammar.abi_version
let node_types grammar = Array.copy grammar.node_types

let parse_tree grammar text bytes linked =
  let { store; core_instance = core; language } = linked in
  let* parser = call store core "sinter_parser" [ language ] in
  let length = String.length bytes in
  let* address = call store core "malloc" [ length ] in
  let* () = Store.write store core ~memory:core_memory ~address bytes in
  let* record = call store core "sinter_parse" [ parser; address; length ] in
  if record = 0 then Ok (Error No_tree)
  else
    let* found =
      read_record store core record ~length_of:(fun count -> 8 + (16 * count))
    in
    Ok
      (match found with
      | None ->
          Error (Wrong_record "the record of the tree lies outside the memory")
      | Some found -> (
          match Parse_tree.decode ~node_types:grammar.node_types text found with
          | Ok tree -> Ok tree
          | Error _ ->
              Error
                (Wrong_record
                   "the record is not a record of a parse tree of the text")))

let too_long bytes = bytes > 0xFFFF_FFFF

let parse ~limits grammar text =
  let bytes, length = measured text in
  if too_long length then Error Too_long
  else
    let exports = Wasm_module.exports grammar.compiled in
    with_instance ~limits grammar.core grammar.compiled grammar.information
      exports grammar.name (fun linked ->
        match Result.bind linked (parse_tree grammar text bytes) with
        | Error failure -> Error (Failed failure)
        | Ok result -> result)
