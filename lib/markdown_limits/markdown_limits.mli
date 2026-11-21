(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The limits on the size, the bracket depth, and the container depth of a
    markdown file, as the decision record [commonmark-reader] decides them.

    A limit stops a text when the size, the bracket depth, or the container
    depth of the text is greater than the limit. A size or a depth equal to the
    limit does not stop the text. A size and a depth are at least 0, so a limit
    below 0 stops every text.

    A line of a byte sequence ends at a line feed, at a carriage return that no
    line feed follows, or at a carriage return and the line feed right after it.
    A blank line is a line of only spaces and tabs, or an empty line. *)

open Sinter_text

type t = { size : int; brackets : int; containers : int }
(** The limits that the calling code gives: the greatest size of a file, in
    bytes; the greatest bracket depth; and the greatest container depth. *)

(** The limit that stops a text. *)
type limit =
  | Size  (** the size of the text is greater than [size] *)
  | Brackets  (** the bracket depth of the text is greater than [brackets] *)
  | Containers
      (** the container depth of the text is greater than [containers] *)

type text
(** The lines of a text that no limit stopped. Only {!check} makes a value of
    this type. *)

val check : t -> Lines.t -> (text, limit) result
(** [check limits lines] is [Error l] when a limit of [limits] stops the text of
    [lines], and [l] is then the first such limit in the order {!Size},
    {!Brackets}, {!Containers}. Otherwise, it is [Ok text], and
    [lines text == lines]. The size of the text is the number of bytes of its
    UTF-8 encoding. The bracket depth and the container depth of the text are
    those of the UTF-8 encoding of its body, as {!bracket_depth} and
    {!container_depth} give them. *)

val lines : text -> Lines.t
(** [lines text] is the lines that {!check} accepted. *)

val bracket_depth : limit:int -> string -> int option
(** [bracket_depth ~limit bytes] is [Some d] when the bracket depth [d] of
    [bytes] is at most [limit], and [None] otherwise.

    The bracket depth follows these steps. The count reads [bytes] from the
    first byte to the last. It keeps a stack of entries, one for each [\[] that
    is still open. Each entry has a state: "open", "in code" up to a run of
    backticks of a given length, "in HTML", or "blocked". The bracket depth is
    the greatest number of entries on the stack.

    + A [\[], a [\]], or a [<] counts only when an even number of backslashes
      comes right before it.
    + At the end of each blank line, the stack becomes empty.
    + Each [\[] that counts goes on the stack, in the state "open". This
      includes a [\[] in a code span, a code block, or HTML.
    + A run of backticks is a longest sequence of backticks. At a run of
      backticks, let [l] be its length, less 1 when an odd number of backslashes
      comes right before it. First, each entry in the state "in code" up to a
      run of the length of this run goes back to "open". Then, each other entry
      in the state "open" goes to "in code" up to a run of length [l] when
      [l > 0] and a run of exactly [l] backticks starts after this run. An entry
      that this run put back to "open" stays "open" at this run. The length of a
      run that puts an entry back to "open" is its whole length, also when
      backslashes come before it.
    + At a [<] that counts, each entry in the state "open" changes as follows.
      When no [>] comes after the [<] in [bytes], it does not change. Otherwise,
      when a [!] or a [?] comes right after the [<], it goes to "blocked".
      Otherwise, let [g] be the first [>] after the [<]. When a line feed, a
      carriage return, a quotation mark (U+0022), an apostrophe (U+0027), a
      backtick, or another [<] comes between the [<] and [g], it goes to
      "blocked". Otherwise, it is "in HTML" up to [g], and "open" after [g].
    + A [\]] that counts takes the top entry off the stack only when that entry
      is "open". Any other [\]] does nothing.
    + An entry stays "blocked" until the stack becomes empty.

    The count stops as soon as the number of entries is greater than [limit].
    The time is linear in the length of [bytes] times one more than the lesser
    of [limit] and that length. The memory is linear in the lesser of [limit]
    and the length of [bytes], plus the number of the different lengths of the
    runs of backticks. *)

val container_depth : limit:int -> string -> int option
(** [container_depth ~limit bytes] is [Some d] when the container depth [d] of
    [bytes] is at most [limit], and [None] otherwise.

    The container depth follows these steps.

    + The columns of a line start at 0. Each byte takes one column, except a
      tab, which takes the columns up to the next multiple of 4.
    + The leading part of a line is its longest first part that consists of
      these pieces, read from left to right:

    - white space: a space or a tab;
    - a quote marker: a [>];
    - a bullet marker: a [-], a [+], or a [*] that a space, a tab, or the end of
      the line follows;
    - an ordered marker: 1 to 9 digits, then a [.] or a [)], that a space, a
      tab, or the end of the line follows.

    + A marker is a quote marker, a bullet marker, or an ordered marker. A list
      marker is a bullet marker or an ordered marker. The point [q] of a line is
      the first list marker of its leading part or, when its leading part has no
      list marker, the last quote marker of its leading part.
    + [w] is the number of the columns of the white space of the leading part
      before [q].
    + The depth of a line is 0 when its leading part has no marker. Otherwise,
      it is the number of the markers of its leading part, plus [w / 2] rounded
      down.
    + The container depth is the greatest depth of a line of [bytes], or 0 when
      [bytes] is empty.

    The count stops at the end of the first line whose depth is greater than
    [limit]. The time is linear in the length of [bytes]. The memory does not
    grow with the length of [bytes] or with the depth. *)
