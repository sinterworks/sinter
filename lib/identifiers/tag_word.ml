(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t =
  | Decision
  | Design
  | Finding_class
  | Req
  | Spec
  | Term
  | Cites
  | Refines
  | Satisfies
  | Supersedes
  | Verifies
  | Deferred
  | Deprecated
  | Rejected
  | Ack
  | Extern

let all =
  [
    Decision;
    Design;
    Finding_class;
    Req;
    Spec;
    Term;
    Cites;
    Refines;
    Satisfies;
    Supersedes;
    Verifies;
    Deferred;
    Deprecated;
    Rejected;
    Ack;
    Extern;
  ]

let to_string = function
  | Decision -> "@decision"
  | Design -> "@design"
  | Finding_class -> "@finding-class"
  | Req -> "@req"
  | Spec -> "@spec"
  | Term -> "@term"
  | Cites -> "@cites"
  | Refines -> "@refines"
  | Satisfies -> "@satisfies"
  | Supersedes -> "@supersedes"
  | Verifies -> "@verifies"
  | Deferred -> "@deferred"
  | Deprecated -> "@deprecated"
  | Rejected -> "@rejected"
  | Ack -> "@ack"
  | Extern -> "@extern"

let of_string text =
  List.find_opt (fun w -> String.equal (to_string w) text) all
