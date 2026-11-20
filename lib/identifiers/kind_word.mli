(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The seven kind words of the design [identifiers=v1]. *)

type t =
  | Atom  (** [atom] *)
  | Decision  (** [decision] *)
  | Design  (** [design] *)
  | Req  (** [req] *)
  | Schema  (** [schema] *)
  | Spec  (** [spec] *)
  | Term  (** [term] *)

val all : t list
(** [all] is the seven kind words, each once. *)

val to_string : t -> string
(** [to_string word] is the text of [word], such as ["req"]. *)

val of_string : string -> t option
(** [of_string text] is the kind word that is the same text as [text], with
    case, or [None] when [text] is no kind word. *)
