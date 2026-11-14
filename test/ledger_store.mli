(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Git repositories in memory for the tests of the ledger: commits, git tree
    objects, and blobs, each named by an id of its content, as git names its
    objects, so that two commits that hold the same git tree object or the same
    blob name it by one id. A commit is named by a name that the test gives. *)

open Sinter_ledger_trees

type t
(** A git repository in memory, with a count of the reads of each git object. *)

val create : unit -> t
(** [create ()] is a git repository with no git object. *)

val add_tree : t -> Ledger_model.entry list -> string
(** [add_tree store tree] adds [tree], its git tree objects, and the blobs of
    its entries that give a content, and is the id of [tree]. An entry that is
    neither a tree entry nor a chunk names a blob of its own; an entry that
    gives no content names a blob that the git repository does not hold. The
    same [tree] gives the same id each time. *)

val add_commit : t -> string -> Ledger_model.commit -> unit
(** [add_commit store name commit] adds the commit [name], with the parents and
    the git tree object of [commit]. *)

val add_tree_object : t -> string Ledger_objects.entry list -> string
(** [add_tree_object store entries] adds the git tree object that lists
    [entries], and is its id. *)

val set_tree : t -> string -> string Ledger_objects.entry list -> unit
(** [set_tree store id entries] adds a git tree object with the id [id] that
    lists [entries], whatever its content, such as a git tree object that names
    itself. *)

val add_blob : t -> string -> string
(** [add_blob store content] adds a blob with [content] for a chunk, and is its
    id. *)

val add_commit_object : t -> string -> string list -> string -> unit
(** [add_commit_object store name parents tree] adds the commit [name] with
    [parents] and the git tree object [tree]. It records no ledger object ids.
*)

val of_history : (string * Ledger_model.commit) list -> t
(** [of_history commits] is a git repository that holds each of [commits]. *)

val ledger_object_ids : t -> string -> string list
(** [ledger_object_ids store commit] is the ids of the ledger objects of the
    commit [commit]: the commit, its git tree object, each git tree object that
    a tree entry names at any depth, and the blob of each chunk. *)

val other_blob_ids : t -> string -> string list
(** [other_blob_ids store commit] is the ids of the blobs of the entries of the
    git tree object of [commit] that are not chunks. *)

val objects :
  ?fail:(string -> bool) -> t -> (string, string) Ledger_objects.objects
(** [objects ~fail store] is the readers of [store]. A reader gives [Error] for
    an id for which [fail] holds, and for an id that [store] does not hold as a
    git object of its type. Each call counts one read of the id. *)

val most_reads : t -> int
(** [most_reads store] is the greatest count of reads of one id since {!create},
    or 0. *)

val read_ids : t -> string list
(** [read_ids store] is the ids that a reader of [store] was asked for since
    {!create}, each once. *)
