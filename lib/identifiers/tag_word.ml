(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t =
  | Atom
  | Decision
  | Design
  | Req
  | Schema
  | Spec
  | Term
  | Cites
  | Refines
  | Satisfies
  | Supersedes
  | Verifies
  | Deprecated
  | Ack
  | Extern

(* @satisfies identifiers#give-line-results=v1
   A line gets the result "other tag word" unless its tag word is the same
   text as one of the fifteen Sinter tag words, and each of those words sets
   the schema of its kind of tag line. *)
let all =
  [
    Atom;
    Decision;
    Design;
    Req;
    Schema;
    Spec;
    Term;
    Cites;
    Refines;
    Satisfies;
    Supersedes;
    Verifies;
    Deprecated;
    Ack;
    Extern;
  ]

let to_string = function
  | Atom -> "@atom"
  | Decision -> "@decision"
  | Design -> "@design"
  | Req -> "@req"
  | Schema -> "@schema"
  | Spec -> "@spec"
  | Term -> "@term"
  | Cites -> "@cites"
  | Refines -> "@refines"
  | Satisfies -> "@satisfies"
  | Supersedes -> "@supersedes"
  | Verifies -> "@verifies"
  | Deprecated -> "@deprecated"
  | Ack -> "@ack"
  | Extern -> "@extern"

let of_string text =
  List.find_opt (fun w -> String.equal (to_string w) text) all
