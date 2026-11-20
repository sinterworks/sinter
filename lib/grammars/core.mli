(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The core of tree-sitter 0.27.2, its C library, as a WebAssembly module of
    the WebAssembly Core Specification 2.0, with Sinter's own allocation
    functions and the functions through which Sinter parses.

    The module has no import. It exports its memory [memory], its table
    [__indirect_function_table], which holds functions and can grow, its global
    [__stack_pointer], and the 25 functions that the module of a grammar may
    import from it (see {!Grammar}). Its C stack lies at the start of its memory
    and grows down towards address 0: in a new instance, the value of
    [__stack_pointer] is more than 0, and it is at most the address of each
    space that the allocation functions give. Its allocation functions give
    space whose address is a multiple of 16 and is not 0; when the memory cannot
    grow, and when [calloc] asks for 4,294,967,296 bytes or more in all, they
    trap, and give no address. *)

open Sinter_wasm_engine

type t
(** The module of the core, compiled by an engine. Two domains can use one value
    at the same time. *)

val compile : Engine.t -> (t, Wasm_module.error) result
(** [compile engine] is the module of the core, compiled by [engine]. The time
    is that of one compilation of the module. *)

val engine : t -> Engine.t
(** [engine core] is the engine that compiled [core]. *)

val compiled : t -> Wasm_module.t
(** [compiled core] is the compiled module of [core]. *)
