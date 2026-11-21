(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = Text.t

let of_text text =
  if Sinter_identifiers.Slug_form.is_slug (Text.encode text) then Some text
  else None

let to_text slug = slug
