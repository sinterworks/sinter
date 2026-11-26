(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Sets of findings with one set of parts for each finding, as the requirement
    [give-consistent-findings] of the design [findings=v1] asks.

    Two findings are of one scope when both have no tree, or both have trees
    that are equal as {!Sinter_tree.Tree.equal} decides. A finding set holds at
    most one finding for each identity and each scope. *)

open Sinter_tree

type t
(** A finding set. *)

type error =
  | Conflict of Finding_parts.t
      (** the set holds this finding, which is the same finding as the new
          finding, of one scope with it, and has a part that is not the same as
          that part of the new finding *)

val empty : t
(** [empty] is the finding set of no findings. *)

val add : Finding_parts.t -> t -> (t, error) result
(** [add finding set] is [Ok set'] when [set] holds no finding that is the same
    finding as [finding], of one scope with it, and with a part that is not the
    same, as {!Finding_parts.equal} decides. [set'] then holds the findings of
    [set], and [finding] when [set] holds no finding equal to it. It is
    [Error (Conflict other)] otherwise, where [other] is that finding of [set].
*)

val find : t -> Tree.t option -> Finding_id.t -> Finding_parts.t option
(** [find set tree id] is the finding of [set] with the identity [id] whose
    scope is that of [tree], or [None] when [set] holds no such finding. *)

val elements : t -> Finding_parts.t list
(** [elements set] is the findings of [set], each once, in the order in which
    {!add} first took them. *)
