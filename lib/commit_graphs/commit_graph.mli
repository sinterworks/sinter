(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Commits and their parents, as the design [changes=v1] defines them: reach,
    ranges and their parents-first order, merge bases, the change of a commit
    and its base, first-parent lines, and landing commits.

    The caller names each commit by a value of a type of its own, such as an
    object id, and gives the parents of a commit through a function. A commit c
    reaches itself, each of its parents, each parent of each of them, and so on;
    the ancestry of c is the set of the commits that c reaches. The range from a
    commit s to a commit h is the set of the commits that h reaches and that s
    does not reach; the range from no commit to h is the ancestry of h.

    Each function reads the parents of a commit only through the function that
    the caller gives, and only for commits that the walk of its result reaches.
    The time of each function is linear in the number of the commits whose
    parents it reads and of their parents, and no function uses stack space that
    grows with the number of commits. Each function ends on every graph, also on
    a graph in which a commit reaches itself through its parents. *)

module Make (Id : Hashtbl.HashedType) : sig
  type 'e graph = Id.t -> (Id.t list, 'e) result
  (** A graph gives, for a commit, its parents in their order, each as often as
      the commit has it: [Ok parents]. It gives [Error e] when the parents of
      the commit cannot be read. The functions below give the first such
      [Error e] that they meet, and no result. *)

  val parents : named:Id.t list -> shallow:bool -> Id.t list
  (** [parents ~named ~shallow] is the parents of a commit whose commit object
      names the commits [named], in that order. It is [named] when [shallow] is
      [false], and [[]] when [shallow] is [true], for a commit that the file
      [shallow] of the git folder names. *)

  val reaches : 'e graph -> Id.t -> Id.t -> (bool, 'e) result
  (** [reaches graph c c'] is [Ok true] when [c] reaches [c'], and [Ok false]
      when it does not. *)

  val range : 'e graph -> from:Id.t option -> Id.t -> (Id.t list, 'e) result
  (** [range graph ~from:s h] is the commits of the range from [s] to [h], or
      from no commit to [h] when [s] is [None], each once, in the parents-first
      order of the range: the order in which this walk finishes them. To walk a
      commit c of the range is to start c, then to take each parent of c in the
      order of the parents and to walk it when it is in the range and is not
      started, and then to finish c. The walk walks [h] when [h] is in the
      range. So each commit comes after each of its parents in the range. *)

  val merge_bases : 'e graph -> Id.t -> Id.t -> (Id.t list, 'e) result
  (** [merge_bases graph a b] is the merge bases of [a] and [b], each once, in
      an order that this interface does not fix. A common ancestor of [a] and
      [b] is a commit that each of the two reaches, and a merge base is a common
      ancestor that no other common ancestor reaches. *)

  val change :
    'e graph -> default:Id.t option -> Id.t -> (Id.t list option, 'e) result
  (** [change graph ~default h] is the commits of the change of [h] when
      [default] is the commit of the default branch: [Some commits], with
      [commits] as {!range} gives them for the range from [default] to [h]. It
      is [None], no change, when [default] is [None], for a default branch that
      has no commit. *)

  val change_base :
    'e graph -> default:Id.t option -> Id.t -> (Id.t option, 'e) result
  (** [change_base graph ~default h] is the base of the change of [h] when
      [default] is the commit of the default branch: [Some b] when [h] and
      [default] have exactly one merge base [b], and [None] when they have none
      or more than one, or when [default] is [None]. *)

  type 'e line_error =
    | Unread of 'e  (** the graph gave this error *)
    | First_parent_cycle of Id.t
        (** the first parents lead back to this commit, so the commit has no
            first-parent line *)

  val first_parent_line : 'e graph -> Id.t -> (Id.t list, 'e line_error) result
  (** [first_parent_line graph c] is the first-parent line of [c]: [c], its
      first parent, the first parent of that commit, and so on, up to a commit
      that has no parent, in that order. *)

  val landing_commit :
    'e graph -> line_of:Id.t -> Id.t -> (Id.t option, 'e line_error) result
  (** [landing_commit graph ~line_of:d c] is the landing commit of [c] on the
      first-parent line of [d]: [Some m] when [d] reaches [c], with [m] the
      commit of that first-parent line that reaches [c] and that has no parent
      or whose first parent does not reach [c]. It is [None] when [d] does not
      reach [c]. It is [Error] when the first-parent line of [d] is an error. *)
end
