(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The commit of the default branch, as the term [default-branch-commit] of the
    design [changes=v1] defines it.

    Under a binding of the parameter [default-branch-name] that is a branch name
    b, the three refs of the default branch are, in this order: the upstream of
    b; the ref [refs/heads/] followed by b; and the ref [refs/remotes/origin/]
    followed by b. *)

val commit :
  upstream:(Sinter_branch_names.Branch_name.t -> (string option, 'e) result) ->
  refs:('id, 'e) Ref_commit.refs ->
  Sinter_text.Text.t ->
  ('id option, 'e) result
(** [commit ~upstream ~refs binding] is the commit of the default branch under
    the binding [binding] of [default-branch-name], in the git repository whose
    refs are [refs]. [upstream b] is the name of the upstream of the branch name
    [b], or [None] when [b] has no upstream, or [Error e] when it cannot be
    read. The result is [Some c] when the first of the three refs that exists
    has the commit [c], as {!Ref_commit.commit} gives it. It is [None] when
    [binding] is not a branch name, when none of the three refs exists, or when
    the first of them that exists has no commit. The names of the refs are the
    UTF-8 encodings of their texts. *)
