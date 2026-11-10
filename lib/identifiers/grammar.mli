(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Single targets, as the design [identifiers=v1] defines them for the citation
    entries of each citation word and for the target of an inline citation. *)

type rules = {
  vector_selection : bool;  (** a vector selection can follow the name *)
  any_revision : bool;  (** the revision can be [*] as well as a label *)
  every_part : bool;  (** the target can be an every-part target *)
}
(** What a single target of one kind of input allows. *)

type key = string option * string option * string option
(** The entry name of a citation entry, and the text of its vector selection
    when it has one. The entry name is in two parts: its slug, or its external
    id; and the part name after its [#]. Two keys are equal when, and only when,
    the entry names are the same text and the vector selections are the same
    text or both absent. *)

type scope = { kind_word : Kind_word.t option; slug : string option }
(** The kind word and the slug before the [#{] of a scoped list. *)

val kind_word : string -> (Kind_word.t * int) option
(** [kind_word s] is the kind word at the start of [s] and the index right after
    the [:] that follows it, when the text of [s] before its first [:] is a kind
    word. *)

val is_external : Binding.t -> string -> bool
(** [is_external binding s] is [true] when the head of the target [s] starts
    with the namespace name of an external namespace of [binding], followed by
    [/] or by the end of the head. *)

val single : Binding.t -> rules -> string -> (Target.t * key) option
(** [single binding rules s] is the values and the key of the single target [s]
    under [binding] when the whole of [s] matches the form that [rules] allow;
    an external target matches only as an external id whose namespace name is in
    [binding] and whose id fits its id pattern. It is [None] otherwise. *)

val scope : Binding.t -> string -> scope option
(** [scope binding prefix] is the kind word and the slug of [prefix], the text
    of a scoped list before its [#{], when [prefix] is an optional kind word and
    [:], then an optional slug, and the citation entries for which the parts of
    the scoped list stand are not external targets under [binding]. A part of
    such a list never matches the form of an external id, so it is [None]
    otherwise. *)

val part : rules -> scope -> string -> (Target.t * key) option
(** [part rules scope text] is the values and the key of the single target for
    which the part [text] of a scoped list with [scope] stands, when the whole
    of [text] is a part name, then a vector selection when [rules] allow one,
    then [=] and a revision that [rules] allow. It is [None] otherwise. *)
