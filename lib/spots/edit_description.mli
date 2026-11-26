(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Edit descriptions, as the design [findings=v1] defines them.

    An edit description is a text, its path; a first position; a second
    position; and a text, its new text. It describes an edit in a tree when the
    tree has the spot from its first position to its second position at its
    path: the edit is that spot, with the new text of the edit description. A
    finite sequence of edit descriptions describes an edit set in a tree when it
    has one or more edit descriptions, each of them describes an edit in that
    tree, no two of them describe the same edit, and these edits are the edits
    of an edit set in that tree. *)

open Sinter_text
open Sinter_paths
open Sinter_tree

type t = {
  path : Text.t;  (** the path *)
  start : Lines.position;  (** the first position *)
  after : Lines.position;  (** the second position *)
  new_text : Text.t;  (** the new text *)
}
(** An edit description. *)

type fault =
  | Not_a_path of Path.error
      (** the path is not a valid path, and {!Path.of_text} gives this error for
          it *)
  | No_spot of Spot.error
      (** the tree has no spot from the first position to the second position at
          the path, and {!Spot.of_positions} gives this error *)

type error =
  | Not_an_edit of { number : int; fault : fault }
      (** the edit description with the number [number], from 1 in the order of
          the sequence, describes no edit in the tree *)
  | Not_an_edit_set of Edit_set.error
      (** each edit description describes an edit in the tree, and the sequence
          describes no edit set; {!Edit_set.of_edits} gives this error for the
          edits *)

val edit : Tree.t -> t -> (Edit.t, fault) result
(** [edit tree description] is [Ok edit] when [description] describes an edit in
    [tree], and [edit] is then that edit. It is [Error] otherwise. *)

val edit_set : Tree.t -> t list -> (Edit_set.t, error) result
(** [edit_set tree descriptions] is [Ok set] when [descriptions] describes an
    edit set in [tree], and [set] is then that edit set. It is [Error]
    otherwise: [Not_an_edit_set No_edit] when [descriptions] is [[]];
    [Not_an_edit] for the edit description of the lowest number that describes
    no edit in [tree], when there is one; and [Not_an_edit_set] otherwise. *)
