(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The reading of the text of a byte sequence that is valid UTF-8, by the ABNF
    grammar of TOML 1.1.0. *)

val document :
  max_depth:int option ->
  max_key_parts:int option ->
  string ->
  (Types.table, Types.failure) result
(** [document ~max_depth ~max_key_parts bytes] reads [bytes], which is valid
    UTF-8, as {!Sinter_toml.read} says, after its check of UTF-8. *)
