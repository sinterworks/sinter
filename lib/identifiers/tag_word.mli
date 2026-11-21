(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The fifteen Sinter tag words of the design [identifiers=v1]. *)

type t =
  | Atom  (** [@atom] *)
  | Decision  (** [@decision] *)
  | Design  (** [@design] *)
  | Req  (** [@req] *)
  | Schema  (** [@schema] *)
  | Spec  (** [@spec] *)
  | Term  (** [@term] *)
  | Cites  (** [@cites] *)
  | Refines  (** [@refines] *)
  | Satisfies  (** [@satisfies] *)
  | Supersedes  (** [@supersedes] *)
  | Verifies  (** [@verifies] *)
  | Deprecated  (** [@deprecated] *)
  | Ack  (** [@ack] *)
  | Extern  (** [@extern] *)

val all : t list
(** [all] is the fifteen Sinter tag words, each once. *)

val to_string : t -> string
(** [to_string word] is the text of [word], with its [@], such as ["@req"]. *)

val of_string : string -> t option
(** [of_string text] is the Sinter tag word that is the same text as [text],
    with case, or [None] when [text] is no Sinter tag word. *)
