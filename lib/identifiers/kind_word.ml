(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = Decision | Design | Finding_class | Req | Spec | Term

let all = [ Decision; Design; Finding_class; Req; Spec; Term ]

let to_string = function
  | Decision -> "decision"
  | Design -> "design"
  | Finding_class -> "finding-class"
  | Req -> "req"
  | Spec -> "spec"
  | Term -> "term"

let of_string text =
  List.find_opt (fun w -> String.equal (to_string w) text) all
