(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Small generated WebAssembly modules, as the text format of Core 2.0, far
    inside the limits that the tests pass to the program. A module has at most
    four functions besides the five of the interface, at most three parameters
    and three locals in each, at most two results, expressions nested at most
    three deep, one memory of at most four pages, at most two tables of at most
    four elements, at most three globals, and data segments of at most 16 bytes.
    Its code holds no loop, no call to the same function or to a later one, no
    [call_indirect], no growth of a memory or a table, and no instruction whose
    result depends on the bits of a NaN, so its code ends after a few hundred
    instructions, and the result of each instruction is the one that Core 2.0
    defines. Some modules break a condition of a valid adapter: an export is
    missing or of another type, or the module has an import. *)

val module_text : string QCheck2.Gen.t
(** [module_text] generates the text of a module. Each text parses with the
    reference interpreter; some of the modules are not valid. *)
