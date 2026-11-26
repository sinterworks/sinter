(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = {
  line : Text.t list;
  block : (Text.t * Text.t) list;
  inner : Text.t list;
}
