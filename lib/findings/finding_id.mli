(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Finding ids and the identity of findings, as the design [findings=v1]
    defines them.

    The finding id of a finding is the text [finding:], then the slug that names
    the finding class of the finding, then [:], then the subject of the finding.
    Two findings are the same finding when, and only when, the slugs that name
    their finding classes are the same text and their subjects are the same
    text, in any tree and in any execution of a program. *)

open Sinter_text

type t
(** The identity of a finding: the slug that names its finding class, and its
    subject. *)

val make : Class_slug.t -> Subject.t -> t
(** [make slug subject] is the identity of the findings of the finding class
    that [slug] names with the subject [subject]. *)

val class_slug : t -> Class_slug.t
(** [class_slug id] is the slug of [id]. *)

val subject : t -> Subject.t
(** [subject id] is the subject of [id]. *)

val to_text : t -> Text.t
(** [to_text id] is the finding id: the text [finding:], then the text of the
    slug of [id], then [:], then the text of the subject of [id]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the slugs of [a] and [b] are the
    same text and their subjects are the same text: when findings with the
    identities [a] and [b] are the same finding. *)
