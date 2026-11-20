(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1} *)
let rules =
  { Grammar.vector_selection = false; any_revision = true; every_part = false }

let read binding target = Option.map fst (Grammar.single binding rules target)
