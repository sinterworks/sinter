(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Acceptance rules and accepted ledger entries, as the term [accepted-entry]
    of the design [ledger=v1] defines them.

    The acceptance rule of a kind of ledger entry is the condition, which a
    design gives for that kind, under which a ledger entry of that kind can
    stand at a point of a ledger. A ledger entry is accepted at a point when,
    and only when, the acceptance rule of its kind holds for it there. A ledger
    entry of the kind [void], and a ledger entry of a kind for which no rule is
    given, are accepted at no point. No design gives an acceptance rule yet, so
    {!none} is the acceptance of every kind today. *)

open Sinter_ledger_lines

type ledger
(** A ledger: a sequence of ledger entries. A point at the end of a ledger is
    the point after its last ledger entry, or the only point of an empty ledger.
*)

val ledger : Entry.t list -> ledger
(** [ledger entries] is the ledger of [entries], in their order. *)

val append : ledger -> Entry.t -> ledger
(** [append ledger entry] is [ledger], then [entry]. The time is constant. *)

val entries : ledger -> Entry.t list
(** [entries ledger] is the ledger entries of [ledger], in their order. The time
    is linear in their number. *)

val newest_first : ledger -> Entry.t list
(** [newest_first ledger] is the ledger entries of [ledger], from the last to
    the first. The time is constant. *)

type rule = ledger -> Entry.t -> bool
(** An acceptance rule: [rule ledger entry] is [true] when, and only when, the
    rule holds for [entry] at the end of [ledger]. *)

type t
(** The acceptance rules of the kinds of ledger entry. *)

val none : t
(** [none] gives no kind an acceptance rule, so it accepts no ledger entry at
    any point. *)

val of_rules : (Entry_kind.t -> rule option) -> t
(** [of_rules rules] gives each kind [k] the rule [r] when [rules k] is
    [Some r], and no rule when it is [None]. It gives the kind [Void] no rule,
    whatever [rules Void] is. *)

val accepted : t -> ledger -> Entry.t -> bool
(** [accepted acceptance ledger entry] is [true] when, and only when, [entry] is
    accepted at the end of [ledger]: its kind has a rule in [acceptance], and
    that rule holds for [entry] at the end of [ledger]. It is [false] for each
    entry of the kind [Void]. Its time is the time of the rule. *)
