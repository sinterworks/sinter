(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_wasm_engine
open Sinter_adapter_protocol

type part = Request | Report_content | Response

type cause =
  | Too_long of part
  | Not_valid of Adapter.invalid
  | Failed of Instance.failure
  | Zero_address of part
  | Outside_memory of part

type 'result outcome = { result : 'result; cause : cause option }

let ( let* ) = Result.bind
let memory = "memory"

(* @satisfies packs#give-call-results=v1
   A call fails when its request or its report content has 4,294,967,296
   bytes or more. *)
let too_long length = length >= 4_294_967_296

let check_length part bytes =
  if too_long (String.length bytes) then Error (Too_long part) else Ok ()

let unsigned bits = Int32.to_int bits land 0xFFFF_FFFF
let step result = Result.map_error (fun failure -> Failed failure) result

(* @satisfies packs#give-call-results=v1
   Steps 2 and 3: sinter_alloc gets the number of bytes as the bits of an
   i32; the call fails when the address that it gives is 0, or when the bytes
   from that address do not lie inside the memory, and otherwise the bytes go
   into the memory from that address on, unchanged. *)
let place instance part bytes =
  let length = String.length bytes in
  let* bits =
    step
      (Instance.invoke instance "sinter_alloc"
         [ Instance.Value.I32 (Int32.of_int length) ]
         Instance.Result_type.I32)
  in
  let address = unsigned bits in
  let* size = step (Instance.memory_size instance memory) in
  if address = 0 then Error (Zero_address part)
  else if address + length > size then Error (Outside_memory part)
  else
    let* () = step (Instance.write instance ~memory ~address bytes) in
    Ok address

(* @satisfies packs#give-call-results=v1
   Steps 4 and 5: the function gets the two addresses and the two lengths; of
   the i64 that it gives, the high 32 bits are the address and the low 32 bits
   the length of the response, which must lie inside the memory. *)
let respond instance export ~request ~content =
  let* request_address = place instance Request request in
  let* content_address = place instance Report_content content in
  let arguments =
    List.map
      (fun number -> Instance.Value.I32 (Int32.of_int number))
      [
        request_address;
        String.length request;
        content_address;
        String.length content;
      ]
  in
  let* bits =
    step (Instance.invoke instance export arguments Instance.Result_type.I64)
  in
  let address = Int64.to_int (Int64.shift_right_logical bits 32) in
  let length = Int64.to_int (Int64.logand bits 0xFFFF_FFFFL) in
  let* size = step (Instance.memory_size instance memory) in
  if address + length > size then Error (Outside_memory Response)
  else step (Instance.read instance ~memory ~address ~length)

(* @satisfies packs#isolate-adapters=v1
   The steps of a call run in a new instance of the module with no import,
   which is not the instance of the decision; the instance is released on
   every path. *)
let run limits decision export ~request ~content =
  let* () = check_length Request request in
  let* () = check_length Report_content content in
  let* adapter = Result.map_error (fun invalid -> Not_valid invalid) decision in
  let* instance = step (Instance.create (Adapter.compiled adapter) limits) in
  Fun.protect
    ~finally:(fun () -> Instance.release instance)
    (fun () -> respond instance export ~request ~content)

(* @satisfies packs#{give-call-results=v1, give-call-values=v1, omit-call-values=v1, omit-adapter-error-texts=v1}
   A failure before a response gives "failed" with no error text and no
   values; a response goes to the reading of the response, and the result and
   the values come only from it. *)
let outcome ~failed ~read = function
  | Error cause -> { result = failed; cause = Some cause }
  | Ok response -> { result = read response; cause = None }

let recognise ~limits decision ~request ~content =
  outcome ~failed:(Response.Recognition_failed None) ~read:Response.recognise
    (run limits decision "sinter_recognise" ~request ~content)

let bind ~limits decision ~ids ~request ~content =
  outcome ~failed:(Response.Bind_failed None) ~read:(Response.bind ~ids)
    (run limits decision "sinter_bind" ~request ~content)

(* @satisfies packs#give-requests=v1
   The request of the call is the request of recognise for the runner, its
   settings, and the report name, unchanged. *)
let recognise_request ~limits decision ~runner ~settings ~report ~content =
  recognise ~limits decision
    ~request:(Request.recognise ~runner ~settings ~report)
    ~content

(* @satisfies packs#give-requests=v1
   The request of the call is the request of bind for these things, unchanged,
   and the test entry ids of the call are those of the entries. *)
let bind_request ~limits decision ~runner ~settings ~report ~root entries
    ~content =
  Result.map
    (fun request ->
      bind ~limits decision
        ~ids:(List.map (fun (entry : Test_entry.t) -> entry.id) entries)
        ~request ~content)
    (Request.bind ~runner ~settings ~report ~root entries)
