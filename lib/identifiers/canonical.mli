(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The canonical forms of citation entries and of the targets of inline
    citations, as the design [identifiers=v1] defines them. *)

val entry : ?slug:string -> ?kind_word:Kind_word.t -> Target.t -> string
(** [entry ?slug ?kind_word target] is the canonical form of [target] with the
    slug [slug], or the empty text when [slug] is absent, and with the kind word
    [kind_word], or the empty text when [kind_word] is absent. [target] is the
    values of a citation entry that {!Tag_line.read} gives, or of the target of
    an inline citation that [Inline_citation.read] gives.

    The canonical form is [kind_word] and [:] when [kind_word] is present, then
    the entry name of [target], with [slug] before it when the entry name starts
    with [#], then the vector selection of [target], or [#*] for an every-part
    target. It holds no revision, and the kind word of [target] has no effect.
    [slug] is taken as a text: a text that is not a slug goes into the result in
    the same place as a slug does.

    The time is linear in the length of the result. *)
