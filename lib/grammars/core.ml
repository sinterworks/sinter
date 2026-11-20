(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_wasm_engine

type t = { engine : Engine.t; compiled : Wasm_module.t }

let compile engine =
  Result.map
    (fun compiled -> { engine; compiled })
    (Wasm_module.compile engine Core_bytes.core)

let engine core = core.engine
let compiled core = core.compiled
