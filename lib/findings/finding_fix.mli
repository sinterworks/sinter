(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Fixes, as the design [findings=v1] defines them.

    A fix in a tree is a message, which says what the fix does, and a finite
    sequence of one or more edit sets in that tree, in which no two edit sets
    are the same set. The edit sets of a fix have numbers from 1, in their
    order. To make a fix is to make the edits of exactly one of its edit sets.

    Whether an edit set of a fix corrects a finding, or adds an acknowledgment
    of it, depends on the condition of the finding class of the finding, and
    this module does not check it. *)

open Sinter_tree
open Sinter_spots

type t
(** A fix in a tree. *)

type error =
  | No_edit_set  (** the list holds no edit set *)
  | Different_trees
      (** two edit sets of the list are in trees that are not equal as
          {!Tree.equal} decides *)
  | Repeated_edit_set of { first : int; second : int }
      (** the edit sets with the numbers [first] and [second] are the same set
          as {!Edit_set.equal} decides, and [first < second] *)

val make : Message.t -> Edit_set.t list -> (t, error) result
(** [make message sets] is [Ok fix] when [sets] is a sequence of one or more
    edit sets in one tree, no two the same set, and [fix] is then the fix with
    the message [message] and the edit sets of [sets], each with its number from
    1 in the order of [sets]. It is [Error] otherwise, with the first of these
    faults that holds: [No_edit_set], [Different_trees], and [Repeated_edit_set]
    for the lowest [second], and then the lowest [first]. *)

val message : t -> Message.t
(** [message fix] is the message of [fix]. *)

val edit_sets : t -> Edit_set.t list
(** [edit_sets fix] is the edit sets of [fix], in the order of their numbers:
    the [k]-th element has the number [k]. *)

val tree : t -> Tree.t
(** [tree fix] is the tree of [fix]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the messages of [a] and [b] are
    the same text, they have the same number of edit sets, and the edit sets
    with each number are equal as {!Edit_set.equal} decides. *)
