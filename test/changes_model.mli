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
