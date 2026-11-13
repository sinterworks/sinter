(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of the design [changes=v1], computed apart from the libraries
    under test, by a direct reading of each term on small inputs, and the forms
    in which the vectors of the design write their values. *)

(** {1 Branch names} *)

val is_branch_name : string -> bool
(** [is_branch_name text] holds when the text whose UTF-8 encoding is [text]
    meets each of the eight conditions of the term [branch-name]. *)

val branch_name_faults : string -> int list
(** [branch_name_faults text] is the numbers of the conditions of the term
    [branch-name] that the text whose UTF-8 encoding is [text] does not meet, in
    increasing order. *)

val branch_name_gen : string QCheck2.Gen.t
(** The UTF-8 encodings of texts of up to eight pieces, drawn from the
    characters and the runs at the edges of the conditions of the term
    [branch-name]. *)

(** {1 The forms of the vectors} *)

val bytes_of_json : Yojson.Basic.t -> string
(** [bytes_of_json json] is the byte sequence that [json] writes: the UTF-8
    encoding of a JSON string, or the bytes of the member [bytes] of an object,
    in hex digits. It fails the test for any other JSON value. *)

(** {1 Lines, line maps, and hunks} *)

val line_texts : string option -> string list option
(** [line_texts content] is the UTF-8 encodings of the line texts of a file with
    [content], or [None] when there is no file or [content] is not valid UTF-8.
*)

val is_map : string list -> string list -> (int * int) list -> bool
(** [is_map old_lines new_lines pairs] holds when [pairs] is a map between the
    two sequences of line texts, as the term [line-map] defines a map: each pair
    is in range, pairs lines with the same text, and the pairs are in the same
    order in both numbers, with no number twice. *)

val longest_by_search : string list -> string list -> int
(** [longest_by_search old_lines new_lines] is the greatest number of pairs of a
    map, found by a search of every map. The time is exponential: use it on up
    to about eight lines. *)

val longest_by_table : string list -> string list -> int
(** [longest_by_table old_lines new_lines] is the greatest number of pairs of a
    map, by the table of the longest common subsequences of the prefixes. *)

type hunk = { old_start : int; removed : int; new_start : int; added : int }
(** The four whole numbers of a hunk. *)

val hunks :
  old_content:string option ->
  new_content:string option ->
  (int * int) list ->
  hunk list
(** [hunks ~old_content ~new_content pairs] is the hunks of a valid path between
    a tree whose file has [old_content] and a tree whose file has [new_content]
    ([None] for no file), for the line map [pairs], by the rules of the term
    [hunk], in increasing order of their old starts. *)

val content_gen : string option QCheck2.Gen.t
(** Contents of a file, or no file: lines over a small alphabet, with line
    feeds, carriage returns and line feeds, a carriage return alone, a byte
    order mark, an empty content, a last line with no line ending, and contents
    that are not valid UTF-8. *)

val print_content : string option -> string
(** [print_content content] writes [content] for messages. *)

val a_line_map : string list -> string list -> (int * int) list
(** [a_line_map old_lines new_lines] is one line map between the two sequences
    of line texts, in increasing order, by the table of {!longest_by_table}. *)

(** {1 Commit graphs} *)

val names_of_json : Yojson.Basic.t -> string list
(** [names_of_json json] is the strings of the JSON array [json], in order. It
    fails the test for any other JSON value. *)

type graph = (string * string list) list
(** A commit graph: each commit with its parents, in their order. *)

val graph_of_json : Yojson.Basic.t -> graph
(** [graph_of_json json] is the commit graph that [json] writes. *)

val parents : graph -> string -> string list
(** [parents graph c] is the parents of [c] in [graph], or [[]] when [graph]
    does not hold [c]. *)

val ancestry : graph -> string -> string list
(** [ancestry graph c] is the smallest set that holds [c] and each parent of
    each commit that it holds, in code point order. *)

val reaches : graph -> string -> string -> bool
(** [reaches graph c c'] holds when [ancestry graph c] holds [c']. *)

val range : graph -> from:string option -> string -> string list
(** [range graph ~from h] is the commits that [h] reaches and that [from] does
    not reach, in code point order. *)

val parents_first : graph -> from:string option -> string -> string list
(** [parents_first graph ~from h] is the order in which the walk of the term
    [parents-first-order] finishes the commits of the range. *)

val merge_bases : graph -> string -> string -> string list
(** [merge_bases graph a b] is the common ancestors of [a] and [b] that no other
    common ancestor reaches, in code point order. *)

val first_parent_line : graph -> string -> string list option
(** [first_parent_line graph c] is [c], its first parent, and so on, up to a
    commit with no parent, or [None] when the first parents come back to a
    commit. *)

val landing_commit : graph -> line_of:string -> string -> string option
(** [landing_commit graph ~line_of:d c] is each commit of the first-parent line
    of [d] that reaches [c] and that has no parent or whose first parent does
    not reach [c], when there is exactly one; [None] when [d] does not reach
    [c]. It fails the test when [d] reaches [c] and the count is not one. *)

val graph_gen : graph QCheck2.Gen.t
(** Commit graphs of 1 to 12 commits named [c0], [c1], and so on, in which each
    parent of [ck] is a commit [cj] with [j < k]. A commit has 0 to 3 parents,
    and a parent can be named twice. *)

val cyclic_graph_gen : graph QCheck2.Gen.t
(** Commit graphs as {!graph_gen} gives them, except that each parent can be any
    commit of the graph, so that a commit can reach itself through its parents.
*)

val print_graph : graph -> string
(** [print_graph graph] writes [graph] as a JSON object, for messages. *)

(** {1 Refs, messages, and the files of commits} *)

type target =
  | Commit of string
  | Names of string
  | Other of string
  | Broken
      (** What a ref holds: a commit, the name of another ref, a git object that
          is not a commit, or, for a broken loose ref, none of these. *)

val ref_commit : (string * target) list -> string -> string option
(** [ref_commit refs name] is the commit to which the ref [name] resolves
    through [refs], or [None] when it resolves to no commit: it does not exist,
    it names a ref that resolves to no commit, it points to another git object,
    it is a broken loose ref, or the refs that it names in turn come back to a
    ref. *)

val default_branch_commit :
  binding:string ->
  upstream:string option option ->
  local:string option option ->
  remote:string option option ->
  string option
(** [default_branch_commit ~binding ~upstream ~local ~remote] is the commit of
    the default branch by the term [default-branch-commit]: each ref is [None]
    when it does not exist, and [Some commit] when it exists, with [commit]
    [None] when it has no commit. *)

val message : string -> string
(** [message content] is the message of a commit object with [content]: the
    bytes after the first two bytes 0x0A that follow one another, or the empty
    byte sequence. *)

val message_text : string -> string option
(** [message_text content] is the text of the message of a commit object with
    [content], as its UTF-8 encoding, or [None] when the message is not valid
    UTF-8. *)

type entry = { name : string; mode : string; entries : entry list }
(** An entry of a git tree object: its name, the digits of its mode, and, for a
    tree entry, the entries of the git tree object that it names. *)

(** The four types of an entry. *)
type kind =
  | Tree_kind
  | Regular_file_kind
  | Symbolic_link_kind
  | Submodule_kind

val entry_kind : string -> kind
(** [entry_kind mode] is the type of an entry with the mode [mode], by the term
    [commit-file]: when [mode] is one or more of the bytes 0x30 to 0x37, the
    type that the whole-number quotient of its number divided by 4096 gives (4,
    8, 10, or another); a submodule entry when [mode] is empty or holds another
    byte. *)

val entry_byte_paths : entry list -> string list
(** [entry_byte_paths entries] is the byte path of each entry of a git tree
    object that lists [entries], the entries of its tree entries included, each
    as often as an entry has it. *)

val commit_files : entry list -> string list
(** [commit_files entries] is the valid paths of the files of the tree of a
    commit whose git tree object lists [entries], in code point order, by the
    term [commit-file]. *)

val entries_gen : entry list QCheck2.Gen.t
(** Entries of a git tree object, nested up to three deep, with names that
    repeat, names that are no file names, names that hold [/] or are not valid
    UTF-8, modes of each type, with and without a leading 0, an empty mode, and
    modes that hold a byte that is no digit of base 8. *)

val print_entries : entry list -> string
(** [print_entries entries] writes [entries] for messages. *)
