(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t

external create_stub : int -> (t, string) result
  = "sinter_wasm_engine_create_stub"

type error = Not_made of string

let create ~stack =
  Result.map_error (fun message -> Not_made message) (create_stub stack)
