(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Value = struct
  type t = I32 of int32 | I64 of int64
end

type limits = { fuel : int; memory : int; table : int }
type limit = Fuel | Memory | Table
type limits_error = Negative of limit

let limits ~fuel ~memory ~table =
  if fuel < 0 then Error (Negative Fuel)
  else if memory < 0 then Error (Negative Memory)
  else if table < 0 then Error (Negative Table)
  else Ok { fuel; memory; table }

type failure =
  | Trap of string
  | Stack_exhausted
  | Stopped of limit
  | Busy
  | Fault of string

type t

external create_stub : Wasm_module.t -> int -> int -> int -> (t, failure) result
  = "sinter_wasm_instance_create_stub"

module Result_type = struct
  type _ t = Nothing : unit t | I32 : int32 t | I64 : int64 t
end

external invoke_stub :
  t -> string -> Value.t array -> 'a Result_type.t -> ('a, failure) result
  = "sinter_wasm_instance_invoke_stub"

external memory_size : t -> string -> (int, failure) result
  = "sinter_wasm_instance_memory_size_stub"

external read :
  t -> memory:string -> address:int -> length:int -> (string, failure) result
  = "sinter_wasm_instance_read_stub"

external write :
  t -> memory:string -> address:int -> string -> (unit, failure) result
  = "sinter_wasm_instance_write_stub"

external release : t -> unit = "sinter_wasm_instance_release_stub"

let create m { fuel; memory; table } = create_stub m fuel memory table

let invoke instance name arguments result_type =
  invoke_stub instance name (Array.of_list arguments) result_type
