(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** JSON values whose form the caller has checked. *)

val object_ :
  (Sinter_text.Text.t * Sinter_json_lines.Json.t) list ->
  Sinter_json_lines.Json.t
(** [object_ members] is the JSON object of [members]. The keys of [members]
    must be different texts; it raises [Invalid_argument] when two are the same
    text. *)

val integer : int -> Sinter_json_lines.Json.t
(** [integer number] is the JSON integer [number]. [number] must be from
    {!Sinter_json_lines.Json.min_integer} to
    {!Sinter_json_lines.Json.max_integer}; it raises [Invalid_argument] when it
    is not. *)
