(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = Atom | Decision | Design | Req | Schema | Spec | Term

(* @satisfies identifiers#{give-line-results=v1, give-link-results=v1, give-values=v1}
   A target starts with a kind word only when the text before its first `:`
   is one of the seven kind words, and the kind word is a value of the match
   that uses it. *)
let all = [ Atom; Decision; Design; Req; Schema; Spec; Term ]

let to_string = function
  | Atom -> "atom"
  | Decision -> "decision"
  | Design -> "design"
  | Req -> "req"
  | Schema -> "schema"
  | Spec -> "spec"
  | Term -> "term"

let of_string text =
  List.find_opt (fun w -> String.equal (to_string w) text) all
