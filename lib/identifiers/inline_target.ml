(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(* @satisfies identifiers#{inline-destination=v1, give-link-results=v1}
   The target of an inline citation allows the revision `*`, a content id,
   and no vector selection. *)
let rules = { Grammar.vector_selection = false; any_revision = true }
let read binding target = Option.map fst (Grammar.single binding rules target)
