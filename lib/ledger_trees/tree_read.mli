(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The reading of git tree objects as ledger trees, with each git object read
    once in a session. *)

open Sinter_ledger_lines

(** The levels of a valid ledger tree: the git tree objects at which its entries
    stand. *)
type level =
  | Root  (** the git tree object itself *)
  | Folder  (** the git tree object at the byte path [entries] *)
  | Hex of string
      (** the git tree object at the byte path [entries/<hh>], with [<hh>] two
          hex digits *)

val fits : level -> 'id Ledger_objects.entry list -> bool
(** [fits level entries] is [true] when, and only when, a git tree object that
    lists [entries] meets condition 1 of the schema [valid-ledger-tree] at
    [level], given that each git tree object that its tree entries name does
    too: no name holds the byte 0x2F; no two entries have the same name; at
    [Folder] and [Hex], [entries] is not empty; and each entry is the tree entry
    [entries] at [Root], a tree entry whose name is two hex digits at [Folder],
    and a chunk at [entries/<hh>/<name>] whose mode writes the number of
    [100644] at [Hex hh]. *)

module Make (Id : Hashtbl.HashedType) : sig
  type 'e session
  (** The readers of a git repository, and the git objects read through them so
      far. A session is owned by one call of a function of the ledger, and it
      ends with that call. *)

  val session :
    ?entry_id:(Sinter_json_lines.Json_line.t -> string) ->
    (Id.t, 'e) Ledger_objects.objects ->
    'e session
  (** [session ~entry_id objects] is a session that has read no git object, and
      that reads the content of each chunk with {!Chunk_content.read}
      [~entry_id]. *)

  val commit : 'e session -> Id.t -> (Id.t Ledger_objects.commit, 'e) result
  (** [commit session id] is the commit [id], read once in [session]. *)

  val tree : 'e session -> Id.t -> (Id.t Ledger_objects.entry list, 'e) result
  (** [tree session id] is the entries of the git tree object [id], read once in
      [session]. *)

  val chunk : 'e session -> Id.t -> (Chunk_content.t, 'e) result
  (** [chunk session id] is the lines of the content of the blob [id], read once
      in [session]. *)

  type analysis = {
    newer : bool;  (** the git tree object is newer *)
    lines : string list;
        (** each byte sequence that is a line of the git tree object, once, in
            an order that this interface does not fix *)
    valid : Ledger_line.t list option;
        (** [Some lines] when the git tree object is a valid ledger tree, with
            [lines] its lines in increasing order of their [seq]; [None] when it
            is not *)
  }
  (** A git tree object as the schema [valid-ledger-tree] reads it. *)

  val analyse : 'e session -> Id.t -> (analysis, 'e) result
  (** [analyse session id] is the analysis of the git tree object [id]. It reads
      each ledger object of [id], also after it found that [id] is newer or is
      no valid ledger tree, and no other git object. The time is linear in the
      number of the git tree objects among the ledger objects, of their entries,
      and of the bytes of the blobs of the chunks, with the work of the git
      objects that [session] read before left out. *)

  val walk : 'e session -> Id.t -> (unit, 'e) result
  (** [walk session id] is [Ok ()] when [session] can read each ledger object of
      the git tree object [id]. Over one session, the time of all calls is
      linear in the number of the git tree objects that they reach, of their
      entries, and of the bytes of the blobs of the chunks. *)
end
