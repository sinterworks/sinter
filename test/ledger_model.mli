(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of the design [ledger=v1], computed apart from the libraries under
    test, by a direct reading of each term on small inputs, the forms in which
    the vectors of the design write their inputs, and generators of ledgers and
    of damaged ledgers. A byte sequence is an OCaml [string]. *)

(** {1 Git tree objects} *)

type entry = {
  name : string;  (** the name, a byte sequence *)
  mode : string;
      (** the mode, a byte sequence, as the git tree object holds it *)
  entries : entry list;
      (** for a tree entry, the entries of the git tree object that it names, in
          their listed order; [[]] for each other entry *)
  content : string option;
      (** for a regular-file entry, the content of its blob, when the input
          gives one; [None] for each other entry *)
}
(** An entry of a git tree object. *)

val tree_of_json : Yojson.Basic.t -> entry list
(** [tree_of_json json] is the git tree object that [json] writes in the form of
    the Conformance section: an array of entries with [name], [mode], and
    [entries], [content], or [lines]. It fails the test for any other JSON
    value. *)

val lines_of_json : Yojson.Basic.t -> string list
(** [lines_of_json json] is the canonical lines of the line objects of the JSON
    array [json], in order: the form "a list of lines". It fails the test when
    an element is not a line object. *)

val tree_of_chunks : (string * string list) list -> entry list
(** [tree_of_chunks chunks] is a git tree object in the form of a valid ledger
    tree: for each [(mode, lines)] of [chunks], a chunk with the mode [mode]
    that holds [lines], in that order, at the chunk path that the [id] of the
    object of its first line gives, in a folder [entries/<hh>] that it shares
    with the other chunks of the same [<hh>]. It raises [Invalid_argument] when
    a chunk has no line or its first line has no [id] of the form [e-] and 32
    hex digits. *)

val tree_of_lines : string list -> entry list
(** [tree_of_lines lines] is [tree_of_chunks [("100644", lines)]], or the empty
    git tree object when [lines] is empty. *)

(** {1 Chunks and lines} *)

val is_id : string -> bool
(** [is_id text] holds when [text] is [e-] and then as many hex digits, [0] to
    [9] and [a] to [f], as an entry id has. *)

val is_chunk_path : string -> bool
(** [is_chunk_path text] holds when [text] matches the production [chunk-path]
    and its two hex digits after [entries/] are the two after [e-]. *)

val chunk_mode_is_valid : string -> bool
(** [chunk_mode_is_valid mode] holds when [mode] is one or more of the digits
    [0] to [7] and writes the number 100644 in base 8. *)

val chunks : entry list -> (string * entry) list
(** [chunks tree] is the chunks of [tree], each with its byte path, in the order
    of a walk of the listed entries, depth first. *)

val lines_of_content : string -> string list
(** [lines_of_content content] is the lines of a chunk with [content]. *)

val lines : entry list -> string list
(** [lines tree] is the lines of [tree], each as often as it stands. *)

val object_of_line : string -> Vector_json.t option
(** [object_of_line line] is the object of [line] when [line] is the canonical
    line of a line object. *)

val member : string -> Vector_json.t -> Vector_json.t option
(** [member key value] is the value of the member [key] of the object [value].
*)

val integer_member : string -> Vector_json.t -> int option
(** [integer_member key value] is the integer of the member [key]. *)

val string_member : string -> Vector_json.t -> string option
(** [string_member key value] is the UTF-8 encoding of the string of the member
    [key]. *)

val entry_id : Vector_json.t -> string
(** [entry_id obj] is the entry id of the object [obj]. *)

val is_ledger_line : string -> bool
(** [is_ledger_line line] holds when [line] is the canonical line of a line
    object that meets conditions 3 and 4 of the schema [valid-ledger-tree]. *)

val is_newer_line : string -> bool
(** [is_newer_line line] holds when the JSON value of [line] is an object whose
    member [v] is an integer greater than 1. *)

(** {1 Validity and stored ledgers} *)

val is_newer : entry list -> bool
(** [is_newer tree] holds when one of the lines of [tree] is a newer line. *)

val faults : entry list -> int list
(** [faults tree] is the numbers of the conditions 1 to 7 of the schema
    [valid-ledger-tree] that [tree] does not meet, in increasing order. *)

val is_valid_ledger_tree : entry list -> bool
(** [is_valid_ledger_tree tree] holds when [tree] is not newer and has no fault.
*)

type ledger_ref =
  | No_ref  (** the ledger ref does not exist *)
  | Not_a_commit
      (** the ledger ref resolves to a git object that is no commit *)
  | Commit_tree of entry list
      (** the ledger ref has a commit with this git tree object *)

type validity = Valid | Broken | Newer

val validity : ledger_ref -> validity
(** [validity ledger_ref] is the condition of the ledger. *)

val validity_text : validity -> string
(** [validity_text v] is ["valid"], ["broken"], or ["newer"]. *)

val kinds : string list
(** The eight kinds of ledger entry. *)

val stored_ledger : ledger_ref -> string list option
(** [stored_ledger ledger_ref] is the [id] of each ledger entry of the stored
    ledger, in order, when the ledger is valid, and [None] otherwise. *)

(** {1 Histories} *)

type commit = { parents : string list; tree : entry list }
(** A commit: its parents, in order, and its git tree object. *)

val graph_of_json : Yojson.Basic.t -> (string * commit) list
(** [graph_of_json json] is the commits of the member [commits] of a vector of
    the group [histories]. *)

val extends : (string * commit) list -> string -> string -> bool
(** [extends commits d c] holds when [d] extends [c]. Each commit that the chain
    of single parents of [d] meets is in [commits]. *)

val intact : (string * commit) list -> string -> bool
(** [intact commits c] holds when the history of a ledger whose ledger commit is
    [c] is intact. Each commit that [c] reaches is in [commits]. *)

(** {1 Pulls} *)

val accounts : string list -> string -> bool
(** [accounts lines line] holds when a git tree object with [lines] accounts for
    [line]. *)

type pull =
  | Refused
  | Pulled of { lines : string list; left : string list }
      (** What a pull gives: no pull, or the lines of the pull commit, those of
          s and then each line that stays, in that order, and the [id] of each
          line that leaves, in increasing order of [seq]. *)

val pull :
  clone:entry list option ->
  shared:entry list ->
  accept:(original:string -> before:string list -> string -> bool) ->
  pull
(** [pull ~clone ~shared ~accept] is the pull of a commit s with the git tree
    object [shared] over a clone whose ledger commit has [clone], or that has no
    ledger commit. [accept ~original ~before line] holds when the ledger entry
    of [line], the line that comes from the line [original] of the clone, is
    accepted after the lines [before], in increasing order of [seq]; it is asked
    only for a kind other than [void]. *)

(** {1 Generators} *)

val line_object_gen : seq:int -> Vector_json.t QCheck2.Gen.t
(** Objects of ledger lines with the [seq] [seq], [v] 1, and a right [id]: of
    each of the eight kinds and of an unknown kind, with common fields and
    members that no design names. *)

val line_gen : string QCheck2.Gen.t
(** Canonical lines of line objects: ledger lines, and lines one change away
    from one, at an edge of conditions 3 and 4 of the schema
    [valid-ledger-tree]. *)

val with_id : Vector_json.t -> Vector_json.t
(** [with_id obj] is [obj] with the member [id] set to its entry id. *)

val canonical_line : Vector_json.t -> string
(** [canonical_line obj] is the canonical line of the line object [obj]. *)

val ledger_lines_gen : string list QCheck2.Gen.t
(** The lines of a valid ledger of 0 to 12 lines, in a random order. *)

val layout_gen : string list -> entry list QCheck2.Gen.t
(** [layout_gen lines] gives git trees in the form of a valid ledger tree that
    hold [lines]: the lines cut into chunks in any way, each chunk with lines in
    any order, the entries of each git tree object in any order, and chunk modes
    of [100644] with or without leading zeros. *)

val damage_gen : entry list -> entry list QCheck2.Gen.t
(** [damage_gen tree] gives git trees that differ from [tree] by one change at
    an edge of a condition of the schema [valid-ledger-tree]: a mode, a name, an
    entry more or less, a byte of a line, a member of an object, a [v] or a
    [seq], or a newer line. *)

val newer_line : string
(** A newer line: the canonical line of a line object whose [v] is 2. *)

val task_line : ?name:string -> int -> string
(** [task_line ~name seq] is the canonical line of a task with the [name]
    [name], [t] by default, and the [seq] [seq], with its entry id. *)

val print_tree : entry list -> string
(** [print_tree tree] writes [tree] in the form of the Conformance section, for
    messages. *)
