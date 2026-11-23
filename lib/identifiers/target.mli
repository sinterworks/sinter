(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The values of a single target: a citation entry, or the target of an inline
    citation, as the design [identifiers=v1] defines them. Each text here is the
    UTF-8 encoding of a run of the text of the tag line, or of the destination
    of the inline citation. *)

(* @satisfies identifiers#give-no-other-values=v1
   A vector selection gives a group name or every vector, and nothing else. *)

(** A vector selection. *)
type vector_selection =
  | Group of string  (** the group name, such as ["offsets"] in [[offsets]] *)
  | Every_vector  (** every vector: [[*]] *)

(** What follows the name of a single target that is not external. *)
type suffix =
  | Revision of string  (** [=] and the revision: a label, or ["*"] *)
  | Vector_selection of vector_selection
      (** a vector selection, in place of [=] and a revision *)

(* @satisfies identifiers#give-no-other-values=v1
   Each case holds only the values that the match of its form gives. *)
type t =
  | Internal of {
      kind_word : Kind_word.t option;
      slug : string option;
      part_name : string option;
      suffix : suffix;
    }
      (** A name with a revision or a vector selection. [slug] and [part_name]
          are the slug and the part name of the name: a slug alone, a full name,
          or [#] and a part name, so at least one of them is present. *)
  | External of {
      kind_word : Kind_word.t option;
      namespace_name : string;
      id : string;
      part_name : string option;
    }
      (** An external id, such as [rfc/8259#section-6]: its namespace name, its
          id, and the part name after its [#] when there is one. *)
  | Content_id of string
      (** A content id, such as [req:0123456789abcdef0123456789abcdef]: an
          object kind word, [:], and 32 hex digits. The text is the whole
          content id, which is also its entry name. *)

val custom_namespace : string -> string option
(** [custom_namespace slug] is the text of [slug] before its last [/], such as
    ["billing"] for ["billing/auth"], or [None] when [slug] holds no [/]. *)
