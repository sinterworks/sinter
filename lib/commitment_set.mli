(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The commitment-set hash of a plan. *)

type step = {
  scope : string list;  (** the effective scope of the step *)
  promises : (string * string) list;
      (** the promises of the step: the tag word and the tag target of each, for
          example [("req", "auth-lockout")] *)
}
(** The promises of one step, with the scope that they share. *)

val bytes : scope:string list -> step list -> string
(** [bytes ~scope steps] is the canonical bytes that the commitment-set hash
    covers, for a plan whose plan scope is [scope] and whose steps are [steps]:
    one object in the canonical form of RFC 8785, with no line feed, with the
    keys [groups] and [scope]. [groups] holds one object for each distinct
    effective scope that holds a promise, with the keys [promises] and [scope].
    [promises] holds one object for each promise of the steps with that scope,
    with the keys [target] and [word], in the order of the word and then the
    target, each in byte order. Each array of globs holds each glob once, in
    byte order. The groups are in the byte order of the canonical bytes of their
    scope. The order of [scope], of [steps], of the promises of a step, and of
    the globs of a step changes nothing, and nor does the step that holds a
    promise when two steps have one scope. A step with no promise adds nothing.

    The length of the result is at most a constant, plus a constant for each
    glob and for each promise, plus a constant times the bytes of the globs, the
    words, and the targets. A scope that many promises share stands once.

    @raise Invalid_argument
      if a glob of [scope], a glob of a step that holds a promise, a word, or a
      target is not valid UTF-8. A glob of a step with no promise is not read.
*)

val hash : scope:string list -> step list -> string
(** [hash ~scope steps] is the commitment-set hash: the 64 lowercase hexadecimal
    digits of the SHA-256 of {!bytes}[ ~scope steps].

    @raise Invalid_argument
      if a glob of [scope], a glob of a step that holds a promise, a word, or a
      target is not valid UTF-8. A glob of a step with no promise is not read.
    @raise Sinter_bridge.Error if the bridge stops on an internal fault. *)

(** {1 The sets of a plan} *)

type stated = {
  slug : string;  (** the slug of the step *)
  own : string list option;
      (** the globs of the own scope of the step; [None] when the step takes the
          plan scope *)
  stated_promises : (string * string) list;
      (** the word and the target of each promise of the step *)
}
(** One step of a commitment set. *)

type set = { plan_scope : string list; steps : stated list }
(** A commitment set: the current set of a plan, or the set of a
    [commitment-set] entry of the ledger. *)

val hash_of_set : set -> string
(** [hash_of_set set] is {!hash} of [set]: a step with no own scope takes the
    plan scope. It builds the plan scope once, however many steps take it.

    @raise Invalid_argument
      if a glob of the plan scope, a glob of a step that holds a promise, a
      word, or a target is not valid UTF-8.
    @raise Sinter_bridge.Error if the bridge stops on an internal fault. *)

type difference = {
  added : (string * string) list;
      (** the word and the target of each promise of the current set that no
          promise of the approved set matches *)
  removed : (string * string) list;
      (** the same for each promise of the approved set *)
  wider : string list;
      (** each glob, in byte order and once, that breaks the containment of a
          scope: a plain glob of the new scope that no plain glob of the
          approved scope contains, or a [!] glob of the approved scope that the
          new scope does not hold *)
}
(** Why a current set is not approved against an approved set. *)

val compare_sets : current:set -> approved:set -> difference option
(** [compare_sets ~current ~approved] is [None] when the three clauses of the
    comparison of commitment sets hold: the multiset of words and targets is
    equal in the two sets; the plan scope of [current] is contained in the plan
    scope of [approved]; and for each promise of [current] matched to a promise
    of [approved], the effective scope of its step is contained in the effective
    scope of the other step. A match is by word and target. Among promises with
    one word and target, the pairs with equal step slugs match first, and then
    the rest in the order of their slugs, on both sides; two with one slug go in
    the byte order of the canonical bytes of their scopes.

    A scope is contained when each plain glob of the new scope satisfies
    {!Glob.holds} against the plain globs of the approved scope, and each [!]
    glob of the approved scope stands verbatim in the new scope.

    It compares each distinct pair of scopes once, however many promises share
    them. The clauses are an answer for each input: no glob makes it raise,
    except a text that is not valid UTF-8.

    @raise Invalid_argument if a glob of a scope is not valid UTF-8. *)
