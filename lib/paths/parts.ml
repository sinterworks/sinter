(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = { text : Text.t; bytes : string }

let split text =
  List.filter_map
    (fun bytes ->
      Result.to_option
        (Result.map (fun text -> { text; bytes }) (Text.decode bytes)))
    (String.split_on_char '/' (Text.encode text))
