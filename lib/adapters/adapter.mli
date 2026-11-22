(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Decisions whether a byte sequence is a valid adapter, as the specification
    [adapters] of the design [packs=v1] defines valid adapters. *)

open Sinter_wasm_engine

type t
(** A byte sequence that is a valid adapter in one decision, with its compiled
    module. Only {!decide} makes one. *)

(** Why a byte sequence is not a valid adapter in a decision. *)
type invalid =
  | Not_a_module of string
      (** it is not a WebAssembly module, or the engine stopped its decoding or
          its validation at a limit of its own; with the message of the engine
          for a person *)
  | Imports of int  (** the module has this number of imports, 1 or more *)
  | Missing_export of string  (** the module does not export this name *)
  | Wrong_export of string
      (** the module exports this name, but not as a memory for [memory], or not
          as a function of its type for the four functions *)
  | Instantiation_failed of Instance.failure
      (** the instantiation in the instance of the decision failed *)
  | Interface_failed of Instance.failure
      (** the invocation of [sinter_interface] failed *)
  | Interface_version of int32
      (** [sinter_interface] gave this [i32] value, which is not 1 *)

val compiled : t -> Wasm_module.t
(** [compiled adapter] is the module of [adapter]. *)

type decision = (t, invalid) result
(** The result of one decision: [Ok] for "valid" and [Error] for "invalid". *)

(* @satisfies text#report-stops-at-limits=v1
   A stop at a limit of the program in the decision gives the failure of the
   instantiation or of the invocation of sinter_interface, which names the step,
   with the limit. *)
val decide : limits:Instance.limits -> Engine.t -> string -> decision
(** [decide ~limits engine bytes] decides whether [bytes] is a valid adapter. It
    is [Ok] when [bytes] is a WebAssembly module of the WebAssembly Core
    Specification 2.0 with no import, that exports [memory] as a memory,
    [sinter_interface] as a function of the type [[] -> [i32]], [sinter_alloc]
    as a function of the type [[i32] -> [i32]], and [sinter_recognise] and
    [sinter_bind] as functions of the type [[i32 i32 i32 i32] -> [i64]], and
    when, in a new instance of the module with no import under [limits], the
    instantiation and then one invocation of [sinter_interface] do not fail and
    the invocation gives 1. The decision runs nothing else in that instance, and
    releases it. It is [Error] in each other case, with the first condition that
    does not hold, in the order above.

    When the code of the instantiation or of the invocation exhausts its call
    stack, or the program stops it at a limit of [limits], the result is
    [Error (Instantiation_failed f)] or [Error (Interface_failed f)], with [f]
    [Stack_exhausted] or [Stopped _]: "invalid". A stop at fuel or an exhausted
    call stack ends code that can be code that never ends, and the program
    cannot tell such code from code that needs more fuel or more stack; a stop
    at memory or table elements can also come from code that never ends, such as
    a loop that grows a memory without end. So the program gives for each of
    them the result that a fault of the input gives, and the failure names the
    limit and the step at which the program stopped. A decision with other
    [limits] can give another result only for such a module. The function never
    raises, and it ends: the fuel of [limits] bounds the code that it runs. *)
