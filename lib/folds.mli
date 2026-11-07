(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(* @cites ledger-event-log *)
(* @cites last-judgment-wins *)

(** The folds of the ledger: the states that a check reads from its entries.
    Each fold is one pass over the entries in the order of their [seq]. A fold
    reads the entries and nothing else: not git's commit graph, the clock, the
    environment, or the network. A [void] entry counts for nothing and cancels
    nothing. A subject and a hash compare by their bytes. *)

type t
(** The folds of one sequence of entries. *)

val empty : t
(** The folds of no entry. *)

val of_entries : Ledger.entry list -> t
(** [of_entries entries] is the folds of [entries], which are in the order of
    their [seq] ({!Ledger.compare}), with each [seq] once, as {!Ledger.entries}
    gives them for a ledger that passed its checks. The work grows with the
    number of entries, and the bytes of each key are the bytes of one line. *)

type judged = {
  approval : Ledger.entry option;
      (** for a declaration and a step, the approval that counts: the latest
          approval that matches, when it is later than each decline that
          matches. For a plan, the latest approval that has its set, also when a
          live decline follows it. *)
  latest_live : Ledger.entry option;
      (** the latest live decline: the latest decline that matches, when no
          approval that matches follows it *)
  after : int;
      (** a decline that matches is live when its [seq] is above this number:
          the [seq] of the latest approval that matches, or 0 *)
}
(** The judgments on one text. Building it costs one lookup of each key,
    whatever the number of declines of the text. {!live} gives every live
    decline. *)

val declaration : t -> subject:string -> rev:int -> xh:string -> judged
(** [declaration folds ~subject ~rev ~xh] is the judgments on a declaration with
    the fact id [subject] and the current revision and extent hash [rev] and
    [xh]. An approval matches when it has this subject, [rev], and [xh]. A
    decline matches when it has this subject and its hash is [xh]. *)

val step : t -> subject:string -> hash:string -> judged
(** [step folds ~subject ~hash] is the judgments on a step with the fact id
    [subject] and the current step hash [hash]. An approval matches when it has
    this subject and its [csh] is [hash]. A decline matches when it has this
    subject and this hash. *)

val latest_approval_with_set :
  t -> subject:string -> (Ledger.entry * Ledger.entry) option
(** [latest_approval_with_set folds ~subject] is the latest approval of the plan
    with the fact id [subject] that has its set, and its set entry: the latest
    [commitment-set] entry below the approval whose [csh] is the [csh] of the
    approval and whose hash holds. An approval with a [rev] and an [xh] has no
    set. *)

val plan : t -> subject:string -> hash:string -> judged
(** [plan folds ~subject ~hash] is the judgments on the plan with the fact id
    [subject] and the current commitment-set hash [hash]. The approval that
    matches is {!latest_approval_with_set}, at any hash. A decline matches when
    it has this subject and this hash. *)

val live : t -> subject:string -> hash:string -> after:int -> Ledger.entry list
(** [live folds ~subject ~hash ~after] is each decline with this subject and
    hash whose [seq] is above [after], in the order of their [seq]. Its work
    grows with the length of the result. *)

val closing : t -> subject:string -> Ledger.entry option
(** [closing folds ~subject] is the first [completed] or [abandoned] entry whose
    subject is [subject]: the entry that closes the plan with that fact id. *)

val delivered : t -> subject:string -> hash:string -> bool
(** [delivered folds ~subject ~hash] is [true] when a [delivered] entry has the
    subject [subject] and the [csh] [hash]. *)

val started : t -> subject:string -> bool
(** [started folds ~subject] is [true] when a [delivered] entry has the subject
    [subject], with any [csh]. *)
