(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The commits of refs and the head commit of a working tree, as the terms
    [ref-commit] and [head-commit] of the design [changes=v1] define them.

    A ref has a name, a byte sequence such as [refs/heads/main], an OCaml
    [string]. A ref points to a git object, names another ref, as a symbolic ref
    does, or, as a broken loose ref, does neither. A ref exists when the git
    repository, or the working tree, holds a ref with that name, whatever it
    points to or names. The caller names commits by a type of its own, ['id]. *)

(** What a ref points to or names. *)
type 'id target =
  | Commit of 'id
      (** the ref points to a git object that is a commit of the git repository
      *)
  | Other
      (** the ref points to a git object that is not a commit of the git
          repository *)
  | Broken
      (** the ref is a broken loose ref: it points to no git object, and it
          names no ref *)
  | Ref of string  (** the ref names the ref with this name *)

type ('id, 'e) refs = string -> ('id target option, 'e) result
(** The refs of a git repository, or of a working tree of it: for a name,
    [Ok (Some target)] when a ref with that name exists, [Ok None] when none
    exists, and [Error e] when the refs cannot be read. The functions below give
    the first such [Error e] that they meet, and no result. *)

val commit : ('id, 'e) refs -> string -> ('id option, 'e) result
(** [commit refs name] is the commit of the ref [name]: [Some c] when the ref
    exists and resolves, through the refs that it names in turn, to the commit
    [c]. It is [None] when the ref does not exist, when it or a ref that it
    names in turn points to a git object that is not a commit, is a broken loose
    ref, names a ref that does not exist, or names a ref that it already named
    on the way. *)

val head_commit : ('id, 'e) refs -> 'id target -> ('id option, 'e) result
(** [head_commit refs head] is the head commit of a working tree whose HEAD is
    [head]: [Some c] when HEAD resolves to the commit [c] as {!commit} resolves
    a ref, such as when HEAD names a branch that points to [c], or when HEAD is
    detached and points to [c]. It is [None] when HEAD has no commit, such as
    when it names a branch that does not exist. *)
