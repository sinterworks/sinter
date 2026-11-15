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

type import_type =
  | Function_import of {
      params : Value_type.t list;
      results : Value_type.t list;
    }
  | Memory_import of { minimum : int; maximum : int option }
  | Table_import of {
      element : Value_type.t;
      minimum : int;
      maximum : int option;
    }
  | Global_import of { value_type : Value_type.t; mutable_ : bool }

type import = { module_name : string; name : string; type_ : import_type }

external imports : t -> import list = "sinter_wasm_module_imports_stub"

external exports : t -> (string * extern) list
  = "sinter_wasm_module_exports_stub"

let compile engine bytes =
  Result.map_error
    (fun message -> Not_compiled message)
    (compile_stub engine bytes)
