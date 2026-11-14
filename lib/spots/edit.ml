(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = { spot : Spot.t; span : Text.run; new_text : Text.t }
type error = No_span

let make spot new_text =
  match Spot.span spot with
  | Some span -> Ok { spot; span; new_text }
  | None -> Error No_span

let spot edit = edit.spot
let span edit = edit.span
let new_text edit = edit.new_text
let equal a b = Spot.equal a.spot b.spot && Text.equal a.new_text b.new_text
