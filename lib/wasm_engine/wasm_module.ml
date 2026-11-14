(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t

module Value_type = struct
  type t = I32 | I64 | F32 | F64 | V128 | Funcref | Externref
end

type extern =
  | Function of { params : Value_type.t list; results : Value_type.t list }
  | Memory
  | Table
  | Global

type error = Not_compiled of string

external compile_stub : Engine.t -> string -> (t, string) result
  = "sinter_wasm_module_compile_stub"

external import_count : t -> int = "sinter_wasm_module_import_count_stub"

external exports : t -> (string * extern) list
  = "sinter_wasm_module_exports_stub"

let compile engine bytes =
  Result.map_error
    (fun message -> Not_compiled message)
    (compile_stub engine bytes)
