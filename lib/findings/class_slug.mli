(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Finding classes, by the slugs that name them, as the designs [ontology=v1]
    and [identifiers=v1] define them.

    A finding class is a kind of finding, which a slug names. A slug is one or
    more segments with [/] between each two of them; a segment is one or more
    ASCII letters and ASCII digits, with one [-], [_], or [.] at most between
    two of them. *)

open Sinter_text

type t
(** The slug that names a finding class. *)

val of_text : Text.t -> t option
(** [of_text text] is [Some slug] when [text] is a slug, and [slug] then holds
    [text]. It is [None] otherwise. *)

val to_text : t -> Text.t
(** [to_text slug] is the text of [slug]. *)
