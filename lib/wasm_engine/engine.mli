(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** An engine of exactly the WebAssembly Core Specification 2.0.

    An engine compiles a byte sequence as a module of the binary format of that
    specification, with its validation, and runs the code of the instances of
    its modules as that specification defines. It accepts no module that needs a
    feature of a later proposal, such as several memories, tail calls, 64-bit
    memories, exceptions, or garbage-collected types, and no module in the text
    format.

    An engine lives as long as a value reaches it, or one of its modules. Two
    domains can use one engine at the same time. *)

type t
(** An engine. *)

(** Why an engine was not made. *)
type error =
  | Not_made of string
      (** the engine refused its configuration, with its message for a person *)

val create : stack:int -> (t, error) result
(** [create ~stack] is a new engine. The code of each instance of its modules
    has [stack] bytes of call stack; an invocation whose code needs more
    exhausts the call stack (see {!Instance.failure}), whatever stack the thread
    of the caller has. It is [Error (Not_made _)] when [stack] is less than 1,
    when [stack] is more than the engine supports, or when the engine cannot be
    made on this machine. *)
