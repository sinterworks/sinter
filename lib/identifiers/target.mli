(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The values of a single target: a citation entry, or the target of an inline
    citation, as the design [identifiers=v1] defines them. Each text here is the
    UTF-8 encoding of a run of the text of the tag line, or of the destination
    of the inline citation. *)

(* @satisfies identifiers#give-no-other-values=v1 *)

(** A vector selection. *)
type vector_selection =
  | Vector_number of string  (** the vector number, such as ["12"] in [[12]] *)
  | Group of string
      (** the group name and every vector, such as ["offsets"] in [[offsets][*]]
      *)
  | Every_vector  (** every vector: [[*]] *)

(* @satisfies identifiers#give-no-other-values=v1 *)
type t =
  | Internal of {
      kind_word : Kind_word.t option;
      slug : string option;
      part_name : string option;
      vector_selection : vector_selection option;
      revision : string;
    }
      (** A name with its revision. [slug] and [part_name] are the slug and the
          part name of the name: a slug alone, a full name, or [#] and a part
          name, so at least one of them is present. [revision] is a label or
          ["*"]. *)
  | Every_part of { slug : string; revision : string }
      (** An every-part target, such as [docs=v3#*]: every part of the slug, at
          the revision, which is a label. *)
  | External of {
      kind_word : Kind_word.t option;
      namespace_name : string;
      id : string;
      part_name : string option;
    }
      (** An external id, such as [rfc/8259#section-6]: its namespace name, its
          id, and the part name after its [#] when there is one. *)

val custom_namespace : string -> string option
(** [custom_namespace slug] is the text of [slug] before its last [/], such as
    ["billing"] for ["billing/auth"], or [None] when [slug] holds no [/]. *)
