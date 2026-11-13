(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The diff of the change of a commit, as the term [change-diff] of the design
    [changes=v1] defines it. *)

val of_trees :
  base:Sinter_tree.Tree.t option ->
  Sinter_tree.Tree.t ->
  (Sinter_paths.Path.t * Sinter_line_maps.Line_map.t) list option
(** [of_trees ~base last] is a diff of the change of a commit h whose tree is
    [last]. [base] is the tree of the base of the change of h, or [None] when
    the change of h has no base. The result is [None], no diff, when [base] is
    [None]. Otherwise it is [Some paths]: for each valid path that has one hunk
    or more between the tree [base], as the old tree, and the tree [last], as
    the new tree, the valid path and a line map of it between the two trees,
    from which {!Sinter_line_maps.Line_map.hunks} gives its hunks, in code point
    order of the texts of the valid paths. Each other valid path has no hunk. *)
