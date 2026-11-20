(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The git objects of a git repository, as the readers of the ledger take them:
    git tree objects with their entries, commits with their parents and their
    git tree objects, the contents of blobs, and the ledger ref, as the designs
    [changes=v1] and [ledger=v1] define them.

    The caller names each git object by a value of a type of its own, ['id],
    such as an object id. A name, a mode, and a content are byte sequences,
    OCaml [string]s. *)

type 'id entry = {
  name : string;  (** the name of the entry, as the git tree object holds it *)
  mode : string;
      (** the mode of the entry, the bytes that the git tree object holds before
          the byte 0x20, such as [100644] or [40000] *)
  id : 'id;  (** the git object that the entry names *)
}
(** An entry of a git tree object. A git tree object is the list of its entries,
    in the order in which it lists them, each as often as it lists it, with each
    name as it stands, repeated names and names that hold the byte 0x2F
    included. The mode alone gives the type of an entry, as
    [Sinter_git_model.Commit_files.kind] gives it. *)

type 'id commit = {
  parents : 'id list;
      (** the parents of the commit, in their order, each as often as the commit
          has it, after the cut of the file [shallow]: the git objects that the
          commit object names on the lines of its header that start with
          [parent], when the file [shallow] of the git folder does not name the
          commit, and [[]] when it names the commit, as
          [Sinter_commit_graphs.Commit_graph.Make.parents] gives them *)
  tree : 'id;  (** the git tree object of the commit *)
}
(** A commit. *)

type ('id, 'e) objects = {
  commit : 'id -> ('id commit, 'e) result;
      (** [Ok commit] for a commit that the git repository holds, and [Error e]
          when it cannot be read, such as when the git repository does not hold
          it *)
  tree : 'id -> ('id entry list, 'e) result;
      (** [Ok entries] for a git tree object that the git repository holds, and
          [Error e] when it cannot be read, such as when the git repository does
          not hold it, or when the git object is not a git tree object *)
  blob : 'id -> (string, 'e) result;
      (** [Ok content] for a blob that the git repository holds, and [Error e]
          when it cannot be read, such as when the git repository does not hold
          it, or when the git object is not a blob *)
}
(** The readers of the git objects of a git repository. Each reader gives one
    result for one ['id]: the functions of the ledger read each git object at
    most once in one call, and take the result as that git object for every
    later use in that call. So, for an ['id], a reader gives the same result in
    every call. When a reader gives [Error e], a function of the ledger gives
    the first such [Error e] that it meets, and no other result: the git
    repository does not hold its ledger objects, or its history objects. So a
    git repository in which a tree entry names a git object that is not a git
    tree object, or a chunk names a git object that is not a blob, does not hold
    its ledger objects, as the term [ledger-object] says. *)

(** The ledger ref of a git repository, the ref [refs/sinter/ledger], as the
    term [ledger-ref] gives it. *)
type 'id ledger_ref =
  | Absent  (** the ledger ref does not exist *)
  | No_commit
      (** the ledger ref exists and does not resolve to a commit: it resolves to
          a git object that is not a commit, such as a tag object, or it is a
          broken loose ref, names a ref that does not exist, or names a ref that
          it already named on the way *)
  | Commit of 'id
      (** the ledger ref resolves to this commit, the ledger commit *)
