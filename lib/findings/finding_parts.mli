(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Findings and their parts, as the design [findings=v1] defines them.

    A finding reports one condition at one part of a repository. Its parts are
    its tree, its finding class, its subject, its message, its spot, its mark,
    its related messages, its fix, and whether it is ackable. A finding of no
    tree has no spot and no fix. The spot of a finding is in its tree, its mark
    is a mark of its spot, and its fix is a fix in its tree. The related
    messages of a finding are a set: they have no order, and no two of them are
    the same. A finding is ackable when an acknowledgment of it by a person can
    have effect. *)

open Sinter_tree
open Sinter_spots

type t
(** A finding with all its parts. *)

type error =
  | Spot_outside_tree
      (** the finding has a spot, and it has no tree, or its spot is in a tree
          that is not equal to its tree as {!Tree.equal} decides *)
  | Mark_of_other_spot
      (** the finding has a mark, and it has no spot, or its mark is not a mark
          of a spot equal to its spot as {!Spot.equal} decides *)
  | Fix_outside_tree
      (** the finding has a fix, and it has no tree, or its fix is in a tree
          that is not equal to its tree *)

val make :
  tree:Tree.t option ->
  class_slug:Class_slug.t ->
  subject:Subject.t ->
  message:Message.t ->
  spot:Spot.t option ->
  mark:Mark.t option ->
  related:Related_message.t list ->
  fix:Finding_fix.t option ->
  ackable:bool ->
  (t, error) result
(** [make ~tree ~class_slug ~subject ~message ~spot ~mark ~related ~fix
     ~ackable] is [Ok finding] when these parts are the parts of a finding, and
    [finding] then has these parts: [None] is no tree, no spot, no mark, or no
    fix, and the related messages are the elements of [related], each once. It
    is [Error] otherwise, with the first of these faults that holds:
    [Spot_outside_tree], [Mark_of_other_spot], [Fix_outside_tree]. *)

(* @satisfies findings#{give-finding-parts=v1, omit-absent-finding-parts=v1}
   Each part comes only from the accessor of that part, which gives the part
   that the finding has, and None for a tree, a spot, a mark, or a fix that it
   does not have. *)
val tree : t -> Tree.t option
(** [tree finding] is the tree of [finding], or [None] for a finding of no tree.
*)

val class_slug : t -> Class_slug.t
(** [class_slug finding] is the slug that names the finding class of [finding].
*)

val subject : t -> Subject.t
(** [subject finding] is the subject of [finding]. *)

val id : t -> Finding_id.t
(** [id finding] is the identity of [finding], from its slug and its subject. *)

val message : t -> Message.t
(** [message finding] is the message of [finding]. *)

val spot : t -> Spot.t option
(** [spot finding] is the spot of [finding], or [None] when it has no spot. *)

val mark : t -> Mark.t option
(** [mark finding] is the mark of [finding], or [None] when it has no mark. *)

val related : t -> Related_message.t list
(** [related finding] is the related messages of [finding], each once, in the
    order of their first elements in the list that {!make} took. *)

val fix : t -> Finding_fix.t option
(** [fix finding] is the fix of [finding], or [None] when it has no fix. *)

val ackable : t -> bool
(** [ackable finding] is [true] when, and only when, [finding] is ackable. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, each part of [a] is the same as
    that part of [b]: both have no tree or equal trees; the same slug and the
    same subject; the same message; no spot or equal spots; no mark or equal
    marks; the same set of related messages, in any order; no fix or equal
    fixes; and the same answer for whether they are ackable. *)
