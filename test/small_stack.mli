(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Runs of a function with a small stack. *)

val run : (unit -> 'a) -> 'a
(** [run f] is [f ()], run in a new domain whose stack holds at most 32,768
    words, while the calling domain waits. It raises [Stack_overflow] when [f]
    needs more stack, and each exception that [f] raises. *)
