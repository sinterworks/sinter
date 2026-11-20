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

    When the program stops the instantiation or the invocation at a limit of
    [limits], the result is [Error (Instantiation_failed (Stopped _))] or
    [Error (Interface_failed (Stopped _))]: "invalid". A decision with other
    [limits] can give another result only for such a module. The function never
    raises, and it ends: the fuel of [limits] bounds the code that it runs. *)
