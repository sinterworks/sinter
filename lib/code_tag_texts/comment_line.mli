(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The lines of a run and the comment lines of a comment node, as the terms
    [run-line] and [comment-line] of the design [documents=v1] define them. Each
    line here is a run of the text of the file. *)

open Sinter_text

val run_lines : Lines.t -> Text.run -> Text.run list option
(** [run_lines lines r] is the lines of the run [r] of the text
    [Lines.text lines], in the order of the boundaries where they start:
    - for each line of the text that has a place of [r], the run from the
      greater of the boundaries where [r] and that line start to the lesser of
      the boundaries where [r] and that line end;
    - each empty line of the text whose boundary comes after the boundary where
      [r] starts and before the boundary where [r] ends.

    It is [None] when [r] is not a run of the text. The time is logarithmic in
    the number of the lines of the text, and linear in the number of the lines
    of [r]. *)

val of_node : Comment_sigils.t -> Lines.t -> Text.run -> Text.run list option
(** [of_node sigils lines r] is the comment lines of a tagged comment node whose
    run is [r], a run of the text [Lines.text lines], with the comment sigils
    [sigils]: the lines of [r], as {!run_lines} gives them, each made shorter as
    the term [comment-line] says. To remove a text from the start or from the
    end of a line is to make the line start after it or end before it.
    - On the first line, remove the spaces and tabs at its start, and then the
      longest text, among the line sigils and the opening sigils, that the rest
      starts with. The node is a line comment when that text is a line sigil; a
      block comment of the first block pair whose opening sigil is that text,
      when that text is an opening sigil and no line sigil; and a comment with
      no sigil when the rest starts with no line sigil and no opening sigil.
      When the first line is also the last line and the node is a block comment,
      then remove the closing sigil of its block pair from the end of what
      remains, when what remains ends with it.
    - On each other line of a block comment, remove the spaces and tabs at its
      start; on the last line, then remove the closing sigil of its block pair
      from its end, when what remains ends with it; then remove the longest
      inner sigil that what remains starts with, when it starts with one.
    - On each other line of a line comment, remove the spaces and tabs at its
      start, and then the longest line sigil that what remains starts with, when
      it starts with one.
    - On each other line of a comment with no sigil, remove the spaces and tabs
      at its start.

    So each comment line is a run inside a line of [r], and the comment lines
    are in the order of the lines of [r], one for each. It is [None] when [r] is
    not a run of the text. *)
