(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Extensions and intact histories, as the terms [ledger-extension] and
    [ledger-object] and the atom [intact-history] of the design [ledger=v1]
    define them.

    A commit d extends a commit c when, and only when, d is c, or d has exactly
    one parent, that parent extends c, and each line of the git tree object of
    that parent is a line of the git tree object of d. The history of a ledger
    is intact when, and only when, its ledger ref does not exist, or its ledger
    ref has a commit c that extends a commit that has no parent, and the git
    tree object of each commit that c reaches is a valid ledger tree. The
    history objects are the ledger objects of each commit that the ledger commit
    reaches, and the parents of each of these commits, as
    {!Ledger_objects.commit} gives them after the cut of the file [shallow]. *)

(** Whether the history of a ledger is intact. *)
type t =
  | Intact  (** the history is intact: the result "valid" *)
  | Not_intact  (** the history is not intact: the result "invalid" *)

module Make (Id : Hashtbl.HashedType) : sig
  val extends :
    (Id.t, 'e) Ledger_objects.objects -> Id.t -> Id.t -> (bool, 'e) result
  (** [extends objects d c] is [Ok true] when [d] extends [c], and [Ok false]
      when it does not, also when the single parents of [d] lead back to a
      commit that they already passed. It reads the commits from [d] along the
      chain of their single parents, and the ledger objects of each of them, up
      to [c] or up to the first commit that decides [false]; it is the first
      [Error e] that a reader gives on that way. The time is linear in the
      number of these commits times the work of {!Ledger_tree.Make.read} for one
      of them. *)

  val history :
    ?entry_id:(Sinter_json_lines.Json_line.t -> string) ->
    (Id.t, 'e) Ledger_objects.objects ->
    Id.t Ledger_objects.ledger_ref ->
    (t option, 'e) result
  (** [history ~entry_id objects ledger_ref] is whether the history of the
      ledger whose ledger ref is [ledger_ref] is intact: [Some Intact] or
      [Some Not_intact] when the ledger is not newer, and [None], neither
      result, when the ledger is newer. The [id] that condition 4 of the schema
      [valid-ledger-tree] asks of each line is [entry_id] of its object in place
      of its entry id; [entry_id] is
      {!Sinter_ledger_lines.Entry_id.of_line_object} when it is not given.
      [Absent] gives [Some Intact], and [No_commit] gives [Some Not_intact]. For
      [Commit c], it reads the history objects of the ledger, each once, and it
      is the first [Error e] that a reader gives among them: neither result when
      the git repository does not hold them. When the ledger is newer, it reads
      only the ledger objects of [c].

      It ends on every graph of parents, also when a commit reaches itself
      through its parents. When the single parents of [c] lead back to a commit
      that they already passed, and the ledger is not newer, it gives
      [Some Not_intact], or the first [Error e] that a reader gives among the
      history objects.

      Its result is the result that the atom [intact-history] gives, and it gets
      it without the check of each git tree object of the history alone: it
      compares each commit of the chain with its parent, and a git object that
      both name by one ['id] is one git object, as {!Ledger_objects.objects}
      says. So the time is linear in the sum of these: the number of the commits
      that [c] reaches; the entries of the distinct git tree objects among the
      history objects, and the bytes of the distinct blobs of their chunks, each
      read once; the lines of the git tree object of [c]; and, for each commit
      of the chain of single parents and its parent, the entries of the git tree
      objects of the two that are not one git object at the same byte path, and
      the lines of the chunks of the two that are not one blob at the same byte
      path. It does not grow with the number of commits times the number of
      lines when each commit changes few chunks, such as for a history with one
      commit for each line that it adds, in which each commit changes one chunk
      of a bounded size. The stack space does not grow with the number of
      commits or with the depth of the entries. *)
end
