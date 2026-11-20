(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Edit sets and edited texts, as the design [findings=v1] defines them.

    An edit set in a tree is a finite set of one or more edits in the tree in
    which, for each two edits whose spots have the same valid path, exactly one
    of the two spans ends at or before the boundary where the other span starts.
    For an edit set and a valid path [p] of one of its edits, the edited text of
    [p] is the text of the file at [p], in which the text of the span of each
    edit at [p] is replaced by the new text of that edit; the text before the
    first span, between each two spans, and after the last span stays as it was.
*)

open Sinter_text
open Sinter_paths
open Sinter_tree

type t
(** An edit set in a tree. The value holds that tree. *)

type error =
  | No_edit  (** the list holds no edit *)
  | Different_trees
      (** two edits of the list are edits in trees that are not equal as
          {!Tree.equal} decides *)
  | Conflicting_edits
      (** the spots of two edits of the list have the same valid path, and not
          exactly one of the two spans ends at or before the boundary where the
          other span starts *)

val of_edits : Edit.t list -> (t, error) result
(** [of_edits edits] is [Ok set] when the elements of [edits] are the edits of
    an edit set, and [set] is then that edit set. It is [Error] otherwise, with
    the first of these faults that holds: [No_edit], [Different_trees],
    [Conflicting_edits]. Two elements of [edits] that are equal edits are
    [Conflicting_edits]. The order of [edits] does not change the result. *)

val tree : t -> Tree.t
(** [tree set] is the tree of [set]. *)

val edits : t -> Edit.t list
(** [edits set] is the edits of [set], each once. An edit comes before each edit
    whose valid path is a text that comes later in the order of the code points,
    and before each edit of the same valid path whose span starts at or after
    the boundary where its own span ends. *)

val edited_text : t -> Path.t -> Text.t option
(** [edited_text set path] is the edited text of [path] for [set], or [None]
    when [path] is the valid path of no edit of [set]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the trees of [a] and [b] are
    equal as {!Tree.equal} decides, and each edit of either set is equal, as
    {!Edit.equal} decides, to an edit of the other. *)
