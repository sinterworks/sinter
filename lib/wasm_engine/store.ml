(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type handle
type t = handle
type instance = { owner : t; index : int }

type import =
  | Export of instance * string
  | Global of { mutable_ : bool; value : int32 }
  | Trap

type source =
  | Source_trap
  | Source_export of int * string
  | Source_global of bool * int32

external create_stub : Engine.t -> int -> int -> int -> handle
  = "sinter_wasm_store_create_stub"

external instantiate_stub :
  handle -> Wasm_module.t -> source array -> (int, Instance.failure) result
  = "sinter_wasm_store_instantiate_stub"

external invoke_stub :
  handle ->
  int ->
  string ->
  Instance.Value.t array ->
  'a Instance.Result_type.t ->
  ('a, Instance.failure) result = "sinter_wasm_store_invoke_stub"

external grow_stub :
  handle -> int -> int -> string -> int -> (int, Instance.failure) result
  = "sinter_wasm_store_grow_stub"

external memory_size_stub :
  handle -> int -> string -> (int, Instance.failure) result
  = "sinter_wasm_store_memory_size_stub"

external read_stub :
  handle -> int -> string -> int -> int -> (string, Instance.failure) result
  = "sinter_wasm_store_read_stub"

external write_stub :
  handle -> int -> string -> int -> string -> (unit, Instance.failure) result
  = "sinter_wasm_store_write_stub"

external release : t -> unit = "sinter_wasm_store_release_stub"

let create engine (limits : Instance.limits) =
  create_stub engine limits.fuel limits.memory limits.table

let index store instance =
  if instance.owner != store then
    invalid_arg "Sinter_wasm_engine.Store: the instance is not of this store";
  instance.index

let source store = function
  | Export (instance, name) -> Source_export (index store instance, name)
  | Global { mutable_; value } -> Source_global (mutable_, value)
  | Trap -> Source_trap

let instantiate store m imports =
  let sources = Array.of_list (List.map (source store) imports) in
  Result.map
    (fun index -> { owner = store; index })
    (instantiate_stub store m sources)

let invoke store instance name arguments result_type =
  invoke_stub store (index store instance) name (Array.of_list arguments)
    result_type

let grow part store instance name delta =
  let index = index store instance in
  if delta < 0 then invalid_arg "Sinter_wasm_engine.Store: a negative growth";
  grow_stub store index part name delta

let grow_memory = grow 0
let grow_table = grow 1

let memory_size store instance name =
  memory_size_stub store (index store instance) name

let read store instance ~memory ~address ~length =
  read_stub store (index store instance) memory address length

let write store instance ~memory ~address bytes =
  write_stub store (index store instance) memory address bytes
