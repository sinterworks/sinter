(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The entries of git tree objects, from their contents, as the term
    [commit-file] of the design [changes=v1] defines them.

    The content of a git tree object is a byte sequence, an OCaml [string]: a
    list of entries, one after the other. Each entry is its mode, a byte
    sequence that holds no byte 0x20, then the byte 0x20, its name, a byte
    sequence that holds no byte 0x00, then the byte 0x00, and the object id of
    its git object as bytes, {!Object_id.length} bytes long. *)

type entry = {
  mode : string;  (** the mode, as its bytes *)
  name : string;  (** the name, as its bytes *)
  id : Object_id.t;  (** the object id of the git object of the entry *)
}

type error =
  | Malformed_entry of int
      (** the entry that starts at this offset, from 0, has no byte 0x20 after
          its mode, no byte 0x00 after its name, or fewer bytes of an object id
          than the object format gives *)

val parse : Object_id.format -> string -> (entry list, error) result
(** [parse format content] is the entries of the git tree object whose content
    is [content], with object ids in [format], in the order of the content, each
    entry once for each time that the content lists it, two entries with the
    same name included. Each mode and each name is kept byte for byte. The empty
    content gives [Ok []]. It gives [Error] for the first entry that is not in
    its form. The time is linear in the length of [content]. *)

type 'e build_error =
  | Unread of 'e  (** the read of a git tree object gave this error *)
  | Malformed of { tree : Object_id.t; error : error }
      (** {!parse} gave [error] for the content of the git tree object [tree] *)
  | Cycle of Object_id.t
      (** the git tree object with this object id lists, in turn, a tree entry
          that names it *)
  | Too_many_entries
      (** the result would hold more entries than the maximum, each entry
          counted once for each place at which it is in the result *)

val entries :
  ?path:Sinter_paths.Path.t ->
  max_entries:int ->
  read:(Object_id.t -> (string, 'e) result) ->
  Object_id.format ->
  Object_id.t ->
  (Object_id.t Sinter_git_model.Commit_files.entry list, 'e build_error) result
(** [entries ~max_entries ~read format tree] is the entries of the git tree
    object [tree], as {!Sinter_git_model.Commit_files} takes them, with object
    ids in [format]. [read id] is the content of the git tree object [id]. Each
    entry has its type from {!Sinter_git_model.Commit_files.kind} of its mode: a
    tree entry holds the entries of the git tree object that it names, in turn;
    a regular-file entry holds the object id of its blob; each other entry holds
    only its name. The entries keep the order of each content, and repeated
    names.

    Without [path], it calls [read] once for [tree] and once for each other git
    tree object that the tree entries name, in turn.

    With [path], it reads only the git tree objects of the tree entries whose
    byte path, then the byte 0x2F, starts the UTF-8 encoding of [path], and it
    keeps only these tree entries and the entries whose byte path is that
    encoding; a tree entry of that byte path holds no entries. When the result
    without [path] is [Ok all] and the result with [path] is [Ok some],
    [Commit_files.file some path] is [Commit_files.file all path]. The reads
    with [path] end also when a tree lists, in turn, a tree entry that names it.

    It gives [Too_many_entries], and no part of the result, when the result
    would hold more than [max_entries] entries, counted as {!Too_many_entries}
    says. It raises [Invalid_argument] when [max_entries] is negative.

    It gives the first error that it meets in the order of the entries. The
    stack space does not grow with the depth of the trees. *)
