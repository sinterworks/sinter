(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(* @satisfies identifiers#give-link-results=v1
   The target of an inline citation allows the revision `*` and allows no
   vector selection and no every-part target. *)
let rules =
  { Grammar.vector_selection = false; any_revision = true; every_part = false }

let read binding target = Option.map fst (Grammar.single binding rules target)
