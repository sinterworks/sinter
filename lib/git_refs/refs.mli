(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The refs of a git repository and of a working tree of it, HEAD among them,
    as the terms [ref-commit] and [head-commit] of the design [changes=v1]
    define them, read from the repository files. *)

(** The ref storage format that the file [config] of the git folder gives. *)
type storage =
  | Files  (** the files format, also when the file gives no format *)
  | Reftable  (** the reftable format *)

(** The working tree whose refs are read. *)
type working_tree =
  | Main
      (** the main working tree, whose folder is the git folder; also for the
          refs of the git repository itself *)
  | Linked of string
      (** another working tree, whose folder is at this pathname *)

type limits = {
  max_loose_size : int;
      (** the maximum size in bytes of the file of a loose ref *)
  max_packed_size : int;
      (** the maximum size in bytes of the file [packed-refs] *)
}
(** The limits of the reads of refs. A file larger than its limit gives [Unread]
    with [Too_large]: no target, and no part of one. *)

type error =
  | Reftable_not_read
      (** the ref storage format is [Reftable], which this interface does not
          read yet *)
  | Unread of { pathname : string; failure : Sinter_repository_files.failure }
      (** the read of the file at [pathname] failed *)
  | Malformed_packed_refs of { pathname : string; error : Packed_refs.error }
      (** the file [packed-refs] at [pathname] is not in its form *)

type 'e failure =
  | Refs of error  (** the refs gave this error *)
  | Objects of 'e
      (** the function that gives the type of a git object gave this error *)

(** The refs on the reads of a reader of repository files. *)
module Make (_ : Sinter_repository_files.READER) : sig
  type t
  (** The refs of a working tree of a git repository. A value reads the file
      [packed-refs] at most once, at the first lookup that needs it, and keeps
      what it read for as long as the value lives. *)

  val create :
    limits ->
    storage ->
    Sinter_git_objects.Object_id.format ->
    git_folder:string ->
    working_tree ->
    t
  (** [create limits storage format ~git_folder working_tree] is the refs of the
      working tree [working_tree] of the git repository whose git folder is at
      the pathname [git_folder], in the ref storage format [storage] and with
      object ids in [format]. The reads have the limits [limits]. It reads no
      file. It raises [Invalid_argument] when a limit is negative. *)

  val lookup : t -> string -> (Loose_ref.target option, error) result
  (** [lookup refs name] is the ref with the ref name [name]: [Some target] when
      it exists, and [None] when it does not. A [name] that is not a ref name by
      {!Sinter_ref_names.Ref_name.is_ref_name} names no ref, and no pathname is
      made from it. In the files format:

      - the own refs of the working tree are the refs whose names are root names
        by {!Sinter_ref_names.Ref_name.is_root_name}, [HEAD] among them, or
        start with [refs/bisect/], [refs/worktree/], or [refs/rewritten/]; an
        own ref of a [Linked] working tree is read from the folder of that
        working tree, and each other ref from the git folder;
      - the refs that a folder holds are its loose refs and, for the git folder,
        the refs of its file [packed-refs];
      - the loose ref of a name is the regular file or the symbolic link at the
        pathname of the name in the folder: a regular file has the target that
        {!Loose_ref.parse} gives for its content; a symbolic link, which is not
        followed, names the ref whose name is the reference of the link when
        that reference is a ref name, and is a broken loose ref otherwise; a
        folder, a file of another kind, or no file is no loose ref, and the file
        is not opened;
      - with no loose ref, the ref is the ref of that name in the file
        [packed-refs] of the git folder, when the folder is the git folder and
        that file holds one, or none.

      A folder on the pathname before its last name may be a symbolic link, and
      it is followed. *)

  val refs :
    t ->
    is_commit:(Sinter_git_objects.Object_id.t -> (bool, 'e) result) ->
    ( Sinter_git_objects.Object_id.t,
      'e failure )
    Sinter_git_model.Ref_commit.refs
  (** [refs refs ~is_commit] is the refs as {!Sinter_git_model.Ref_commit} takes
      them, where [is_commit id] is [true] when the git object [id] is a commit
      of the git repository: an [Object id] is [Commit id] when [is_commit id]
      is [true] and [Other] when it is [false]; a [Symbolic name] is [Ref name];
      and [Broken] is [Broken]. The head commit of the working tree is the
      commit of the ref [HEAD]. *)
end

include module type of Make (Sinter_repository_files)
(** The refs on the reads of the system of the process. *)
