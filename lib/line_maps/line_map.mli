(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Line texts, line maps, hunks, and new line numbers, as the terms
    [line-text], [line-map], [hunk], and [new-line-number] of the design
    [changes=v1] define them.

    One valid path p has a file in an old tree, or none, and a file in a new
    tree, or none. A content is the byte sequence of such a file, an OCaml
    [string]. The line texts of p in a tree are the texts of the lines of the
    text of its content, as {!Sinter_text.Lines} gives them, when the tree has a
    file with p and its content is valid UTF-8; otherwise p has no line text in
    that tree. Let m be the number of the line texts of p in the old tree, and n
    the number in the new tree. A line map is a set of pairs (i, j), with i from
    1 to m and j from 1 to n, such that old line text i and new line text j are
    the same text, the pairs keep the same order in both trees, and no such set
    has more pairs. *)

(* @satisfies changes#use-one-line-map=v1
   The hunks and the new line numbers of a valid path are functions of one
   value of this type, which holds one line map, so they come from the same
   line map. *)

type t
(** A line map of one valid path between an old tree and a new tree, with the
    contents of the file of that valid path in the two trees. The hunks, the new
    line numbers, and the line texts that a value gives all come from that one
    line map. *)

type hunk = {
  old_start : int;  (** the line number of the first line that it removes *)
  removed : int;  (** the number of the lines that it removes *)
  new_start : int;  (** the line number of the first line that it adds *)
  added : int;  (** the number of the lines that it adds *)
}
(** A hunk. When it removes no line, [old_start] is the old line number of the
    pair right after it, or m + 1 when no pair follows it. When it adds no line,
    [new_start] is the new line number of the pair right after it, or n + 1 when
    no pair follows it. *)

val compute : string option -> string option -> t
(** [compute old new] is a line map of the valid path between the old tree and
    the new tree. [old] is the content of the file of the old tree with the
    valid path, or [None] when the old tree has no such file, and [new] is the
    same for the new tree. When several line maps exist, the result is one of
    them. Let D be the number of the lines that the hunks of the result remove
    and add together. The time is at most proportional to the lengths of the two
    contents times the logarithm of m + n, plus (m + n) times D, and the memory
    is linear in the lengths of the two contents. *)

val pairs : t -> (int * int) list
(** [pairs map] is the pairs (i, j) of the line map, in increasing order of i.
    The order of the j is then increasing too. *)

val hunks : t -> hunk list
(** [hunks map] is the hunks of the valid path for the line map, in increasing
    order of their old starts:
    - each run of old lines and new lines between two pairs that follow one
      another, before the first pair, or after the last pair, of which at least
      one line is not in a pair, is one hunk, which removes those old lines and
      adds those new lines;
    - when the runs give no hunk, there is one hunk with the old start 1, no
      line removed, the new start 1, and no line added, when one tree has a file
      with the valid path and the other has none, or when both have one, their
      contents are not the same byte sequence, and one of the two contents is
      not valid UTF-8;
    - there is no other hunk.

    The hunks of every line map of the same contents remove m less the number of
    pairs lines together, and add n less that number. *)

val new_line_number : t -> int -> int option
(** [new_line_number map i] is [Some j] when the line map holds the pair (i, j),
    and [None] when no pair of the line map has the first number [i], as for an
    old line that a hunk removes, or for an [i] that is not from 1 to m. *)

val old_line : t -> int -> Sinter_text.Text.t option
(** [old_line map i] is old line text [i]: the text of the line of the old
    content whose line number is [i]. It is [None] when [i] is not from 1 to m.
    The lines that a hunk removes are the old line texts from [old_start], as
    many as [removed]. *)

val new_line : t -> int -> Sinter_text.Text.t option
(** [new_line map j] is new line text [j], as {!old_line} is for the old
    content. The lines that a hunk adds are the new line texts from [new_start],
    as many as [added]. *)
