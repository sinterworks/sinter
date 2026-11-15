(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Git tree objects as a ledger reads them, valid, broken, and newer ledgers,
    and stored ledgers, as the terms [chunk], [newer-line], [ledger-object],
    [ledger-validity], and [stored-ledger] of the design [ledger=v1] define
    them.

    A chunk of a git tree object is a regular-file entry, at any depth, whose
    byte path is the UTF-8 encoding of a chunk path, such as
    [entries/5b/e-5b1c0a9d2e11.jsonl], whatever its mode. The lines of a chunk
    are the byte sequences that remain when the content of its blob is cut right
    after each byte 0x0A, without an empty byte sequence at the end. The lines
    of a git tree object are the lines of its chunks. A git tree object is newer
    when one of its lines is a newer line: a line whose JSON value is an object
    whose member [v] is an integer greater than 1. A valid ledger tree is a git
    tree object that is not newer and that meets the nine conditions of the term
    [ledger-validity]; each of its lines is then a ledger line
    ({!Sinter_ledger_lines.Ledger_line}). A line is a byte sequence, an OCaml
    [string]. *)

open Sinter_ledger_lines

(** A git tree object as a ledger reads it. *)
type t = private
  | Newer_tree of { lines : string list }  (** the git tree object is newer *)
  | Valid_tree of { lines : Ledger_line.t list; entries : Entry.t list }
      (** the git tree object is a valid ledger tree: [lines] is its lines, in
          increasing order of their [seq], and [entries] is the ledger entries
          of these lines, in the same order *)
  | Other_tree of { lines : string list }
      (** the git tree object is neither newer nor a valid ledger tree *)
(** In [Newer_tree] and [Other_tree], [lines] holds each byte sequence that is a
    line of the git tree object once, in an order that this interface does not
    fix, also when it stands in more than one chunk. *)

val lines : t -> string list
(** [lines tree] is each byte sequence that is a line of [tree], once: the bytes
    of each of the lines of a [Valid_tree], in the order of their [seq], and the
    [lines] of the other two. *)

(** The stored ledger of a git repository whose ledger is valid. *)
module Stored_ledger : sig
  type t
  (** A stored ledger. The only values of this type are those that
      {!Make.validity} gives for a valid ledger. *)

  val entries : t -> Entry.t list
  (** [entries stored_ledger] is the ledger entries of [stored_ledger], in
      increasing order of their [seq]: the ledger entries of the lines of the
      git tree object of the ledger commit, or [[]] when the ledger ref does not
      exist. *)
end

(* @satisfies ledger#give-states-only-from-valid-ledgers=v1
   A stored ledger, from which states come, exists only inside `Valid`, so a
   broken ledger, a newer ledger, and a git repository that does not hold its
   ledger objects give none. *)

(** The condition of the ledger of a git repository that holds its ledger
    objects. *)
type validity =
  | Valid of Stored_ledger.t
      (** the ledger is valid: the ledger ref does not exist, or the git tree
          object of the ledger commit is a valid ledger tree *)
  | Broken
      (** the ledger is broken: the ledger ref exists and has no commit, or the
          git tree object of the ledger commit is neither newer nor a valid
          ledger tree *)
  | Newer
      (** the ledger is newer: the git tree object of the ledger commit is newer
      *)

module Make (Id : Hashtbl.HashedType) : sig
  val read :
    ?entry_id:(Sinter_json_lines.Json_line.t -> string) ->
    (Id.t, 'e) Ledger_objects.objects ->
    Id.t ->
    (t, 'e) result
  (** [read ~entry_id objects tree] is the git tree object [tree] as a ledger
      reads it, where the [id] that condition 6 of the term [ledger-validity]
      asks of each line is [entry_id] of its object in place of its entry id;
      [entry_id] is {!Sinter_ledger_lines.Entry_id.of_line_object} when it is
      not given. It reads each ledger object of [tree], once: [tree], each git
      tree object that a tree entry names, at any depth, and the blob of each
      chunk. It reads no other git object. It is the first [Error e] that a
      reader gives, also when [tree] is already known to be newer or no valid
      ledger tree. The time is linear in the number of these git tree objects,
      of their entries, and of the bytes of these blobs, also when many byte
      paths lead to one git tree object, and the stack space does not grow with
      the depth of the entries. *)

  val validity :
    ?entry_id:(Sinter_json_lines.Json_line.t -> string) ->
    (Id.t, 'e) Ledger_objects.objects ->
    Id.t Ledger_objects.ledger_ref ->
    (validity, 'e) result
  (** [validity ~entry_id objects ledger_ref] is the condition of the ledger
      whose ledger ref is [ledger_ref]: [Valid] with the stored ledger,
      [Broken], or [Newer], with [entry_id] as in {!read}. For [Commit c], it
      reads the commit [c] and then as {!read} reads the git tree object of [c],
      and its time is that of {!read}; for [Absent] and [No_commit], it reads
      nothing. It is the first [Error e] that a reader gives: no result and no
      ledger entry when the git repository does not hold its ledger objects. *)
end
