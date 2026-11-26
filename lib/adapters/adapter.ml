(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_wasm_engine

type t = Wasm_module.t

let compiled adapter = adapter

type invalid =
  | Not_a_module of string
  | Imports of int
  | Missing_export of string
  | Wrong_export of string
  | Instantiation_failed of Instance.failure
  | Interface_failed of Instance.failure
  | Interface_version of int32

type decision = (t, invalid) result

let ( let* ) = Result.bind
let four_i32 = Wasm_module.Value_type.[ I32; I32; I32; I32 ]

(* @satisfies packs#{validate-adapters=v1, adapter-module=v1}
   Condition 3 of an adapter module: the five names, with the kind and the
   type that an adapter module exports for each. *)
let interface =
  let open Wasm_module in
  [
    ("memory", Memory);
    ("sinter_interface", Function { params = []; results = [ I32 ] });
    ("sinter_alloc", Function { params = [ I32 ]; results = [ I32 ] });
    ("sinter_recognise", Function { params = four_i32; results = [ I64 ] });
    ("sinter_bind", Function { params = four_i32; results = [ I64 ] });
  ]

(* @satisfies packs#{validate-adapters=v1, adapter-module=v1}
   Condition 3 of an adapter module: each of the five names is an export of
   the module with its kind and its type; other exports do not count. *)
let check_export exports (name, wanted) =
  match List.assoc_opt name exports with
  | None -> Error (Missing_export name)
  | Some found when found = wanted -> Ok ()
  | Some _ -> Error (Wrong_export name)

let rec check_exports exports = function
  | [] -> Ok ()
  | export :: rest ->
      let* () = check_export exports export in
      check_exports exports rest

(* @satisfies packs#{validate-adapters=v1, adapter-module=v1}
   Conditions 1 and 2 of an adapter module: the byte sequence is a module of
   WebAssembly Core 2.0, and the module has no import. *)
let compile engine bytes =
  match Wasm_module.compile engine bytes with
  | Error (Wasm_module.Not_compiled message) -> Error (Not_a_module message)
  | Ok m ->
      let imports = Wasm_module.import_count m in
      if imports > 0 then Error (Imports imports) else Ok m

(* @satisfies packs#{validate-adapters=v1, isolate-adapters=v1}
   Condition 2 of a valid adapter: the decision makes a new instance of the
   module with no import, runs in it the instantiation and one invocation of
   sinter_interface, and nothing else, wants the i32 value 1, and releases the
   instance on every path. *)
let check_version m limits =
  match Instance.create m limits with
  | Error failure -> Error (Instantiation_failed failure)
  | Ok instance ->
      Fun.protect
        ~finally:(fun () -> Instance.release instance)
        (fun () ->
          match
            Instance.invoke instance "sinter_interface" []
              Instance.Result_type.I32
          with
          | Error failure -> Error (Interface_failed failure)
          | Ok 1l -> Ok ()
          | Ok version -> Error (Interface_version version))

let decide ~limits engine bytes =
  let* m = compile engine bytes in
  let* () = check_exports (Wasm_module.exports m) interface in
  let* () = check_version m limits in
  Ok m
