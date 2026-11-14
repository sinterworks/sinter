(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Json = Sinter_json_lines.Json

let object_ members =
  (match Json.object_ members with
  | Some value -> value
  | None -> invalid_arg "Json_values.object_: two members with one key")
  [@mutaml.skip
    "each caller gives keys that are different texts, so no input reaches the \
     case None, and a mutant that omits it acts as the original"]

let integer number =
  (match Json.integer number with
  | Some value -> value
  | None -> invalid_arg "Json_values.integer: a number out of range")
  [@mutaml.skip
    "each caller gives the integer 1 or a line in the range that \
     Test_entry.make checks, so no input reaches the case None, and a mutant \
     that omits it acts as the original"]
