(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The eight kinds of ledger entry, as the term [ledger-entry] of the design
    [ontology=v1] gives them and the term [stored-ledger] of the design
    [ledger=v1] names them. A text is its UTF-8 encoding, an OCaml [string]. *)

(** A kind of ledger entry. *)
type t =
  | Task  (** the text [task] *)
  | Plan  (** the text [plan] *)
  | Approval  (** the text [approval] *)
  | Decline  (** the text [decline] *)
  | Done  (** the text [done] *)
  | Abandoned  (** the text [abandoned] *)
  | Delivered  (** the text [delivered] *)
  | Void  (** the text [void] *)

val of_string : string -> t option
(** [of_string text] is the kind whose text is [text], or [None] when [text] is
    none of the eight texts. Case matters: ["Task"] is no kind. *)

val to_string : t -> string
(** [to_string kind] is the text of [kind]. *)
