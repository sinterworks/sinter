(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Calls of the functions recognise and bind of an adapter, as the
    specification [adapters] of the design [packs=v1] defines them, with their
    results. *)

open Sinter_text
open Sinter_wasm_engine
open Sinter_adapter_protocol

(** A byte sequence that a call puts into the memory of its instance, or reads
    from it. *)
type part =
  | Request  (** the request *)
  | Report_content  (** the report content *)
  | Response  (** the response *)

(** Why a call failed before it gave a response. *)
type cause =
  | Too_long of part
      (** the request or the report content has 4,294,967,296 bytes or more *)
  | Not_valid of Adapter.invalid
      (** the adapter is not a valid adapter in the decision that the call uses
      *)
  | Failed of Instance.failure
      (** the instantiation or an invocation of the call failed *)
  | Zero_address of part
      (** [sinter_alloc] gave the address 0 for the request or the report
          content *)
  | Outside_memory of part
      (** the bytes of this part, from their address on, do not lie inside the
          memory of the instance *)

type 'result outcome = private {
  result : 'result;  (** the result of the call *)
  cause : cause option;
      (** why the call failed before it gave a response, when it did *)
}
(** The result of a call. [cause] is [Some _] exactly when the call failed
    before it gave a response; the result is then "failed" with no error text.
    The cause is for a person, and it is never the error text of the adapter.
    The result "failed" also comes for a stop at a limit of the program, as
    {!recognise} says, so a caller reads [cause] to tell a stop at a limit from
    another failure: a stop in a step of the call gives [Failed Stack_exhausted]
    or [Failed (Stopped _)], and a stop in the decision that the call uses gives
    [Not_valid (Instantiation_failed f)] or [Not_valid (Interface_failed f)],
    with [f] [Stack_exhausted] or [Stopped _]. *)

val too_long : int -> bool
(** [too_long length] is [true] exactly when a request or a report content of
    [length] bytes is too long for a call: when [length] is 4,294,967,296 or
    more. *)

(* @satisfies conformance#report-stops-at-limits=v1
   A stop at a limit of the program in a step of the call gives the cause
   [Failed] with the failure of that step, which names the limit. *)
val recognise :
  limits:Instance.limits ->
  Adapter.decision ->
  request:string ->
  content:string ->
  Response.recognition outcome
(** [recognise ~limits decision ~request ~content] is the result of the call of
    the function recognise of the adapter of [decision], with the request
    [request] and the report content [content]. The call fails when [request] or
    [content] is too long ({!too_long} of its number of bytes), or when
    [decision] is [Error]. Otherwise, in a new instance of the module of the
    adapter with no import under [limits], it runs only these steps, and it
    changes no byte of the memory [memory] other than by the writes of steps 2
    and 3:

    + the instantiation;
    + an invocation of [sinter_alloc] with the number of bytes of [request]; the
      call fails when the address that it gives is 0, or when that address and
      the number of bytes of [request] are more than the size of the memory;
      otherwise the call puts [request] at that address;
    + the same for [content];
    + an invocation of [sinter_recognise] with the two addresses and the two
      numbers of bytes; the call fails when the address (the high 32 bits) and
      the length (the low 32 bits) of the value that it gives are more than the
      size of the memory.

    Each address and each length is unsigned. The call fails when one of these
    fails. When the code of the instantiation or of an invocation exhausts its
    call stack, or the program stops it at a limit of [limits], the cause is
    [Failed Stack_exhausted] or [Failed (Stopped _)], and the result is
    "failed". A stop at fuel or an exhausted call stack ends code that can be
    code that never ends, and the program cannot tell such code from code that
    needs more fuel or more stack; a stop at memory or table elements can also
    come from code that never ends, such as a loop that grows a memory without
    end. So the program gives for each of them the result that a fault of the
    input gives, and the failure names the limit at which the program stopped.
    Otherwise its result is {!Response.recognise} of the response: the length
    bytes of the memory from the address on. The call releases its instance. The
    function ends: the fuel of [limits] bounds the code that it runs. It raises
    [Failure] only when the engine stops on an internal fault, and no other
    exception. *)

val bind :
  limits:Instance.limits ->
  Adapter.decision ->
  ids:Text.t list ->
  request:string ->
  content:string ->
  Response.binding_result outcome
(** [bind ~limits decision ~ids ~request ~content] is the result of the call of
    the function bind of the adapter of [decision] with the test entry ids
    [ids], as {!recognise} says, with [sinter_bind] in step 4. Its result is
    {!Response.bind}[ ~ids] of the response. *)

val recognise_request :
  limits:Instance.limits ->
  Adapter.decision ->
  runner:Sinter_pack_descriptor.Pack_name.t ->
  settings:Setting_values.t ->
  report:Text.t ->
  content:string ->
  Response.recognition outcome
(** [recognise_request ~limits decision ~runner ~settings ~report ~content] is
    {!recognise}[ ~limits decision ~request ~content], with the request
    {!Request.recognise}[ ~runner ~settings ~report]. *)

val bind_request :
  limits:Instance.limits ->
  Adapter.decision ->
  runner:Sinter_pack_descriptor.Pack_name.t ->
  settings:Setting_values.t ->
  report:Text.t ->
  root:Text.t ->
  Test_entry.t list ->
  content:string ->
  (Response.binding_result outcome, Request.error) result
(** [bind_request ~limits decision ~runner ~settings ~report ~root entries
     ~content] is {!bind}[ ~limits decision ~ids ~request ~content], with the
    request {!Request.bind}[ ~runner ~settings ~report ~root entries] and the
    test entry ids [ids] of [entries]. It is [Error] when {!Request.bind} is,
    and then it makes no call. *)
