(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** A reader of TOML 1.1.0 documents.

    {!read} takes a byte sequence, an OCaml [string]. When the byte sequence is
    a TOML document, it gives the root table of the document: its values, the
    order of its keys in the document, and the byte span of each value and each
    key. When the byte sequence is not a TOML document, it gives the kind of the
    fault and a byte offset. It can also stop at a limit that the caller sets on
    the depth of nesting and on the number of parts of a key, to protect a
    program from hostile input.

    A byte offset is a whole number from 0 to the length of the byte sequence:
    offset [k] is the place right before the byte at index [k], and the offset
    that equals the length is the place after the last byte. Offsets count every
    byte of the byte sequence, the bytes of a byte order mark at its start
    included.

    The reader follows the specification of TOML 1.1.0 and its ABNF grammar. At
    each point where TOML 1.1.0 lets an implementation choose, the reader makes
    the choice that the description of each type below states. *)

type span = Types.span = { start : int; stop : int }
(** A span of a byte sequence: [start] is the offset where the span starts, and
    [stop] is the offset where it ends, so the span holds the bytes at the
    indexes from [start] to [stop - 1]. From {!read}, [start <= stop]. *)

type key = Types.key = { whole : span; parts : span list }
(** A key of a key/value pair or of a table header, as the document writes it.
    [whole] is the span of the whole key: from the first byte of its first part
    to the last byte of its last part, with the spaces, tabs, and dots between
    the parts of a dotted key. [parts] is the span of each part, in the order of
    the document: for the dotted key [a."b".c], the spans of [a], ["b"], and
    [c]. A part is a bare key, or a quoted key with its quotes. [parts] has one
    element or more. *)

type date = Types.date = { year : int; month : int; day : int }
(** A date of the proleptic Gregorian calendar, as RFC 3339 gives it. From
    {!read}, [year] is from 0 to 9999, [month] is from 1 to 12, and [day] is
    from 1 to the number of days of that month in that year. *)

type time = Types.time = {
  hour : int;
  minute : int;
  second : int;
  nanosecond : int;
}
(** A time of day. From {!read}, [hour] is from 0 to 23, [minute] is from 0 to
    59, [second] is from 0 to 60, and [nanosecond] is from 0 to 999,999,999. The
    reader accepts the second 60 on every date and at every hour and minute.
    When the document gives no second, [second] is 0. [nanosecond] is the number
    that the first nine digits of the fraction of the second give, in units of
    10{^ -9} seconds; the reader ignores further digits, and a time with no
    fraction has [nanosecond = 0]. So [12:30], [12:30:00], and [12:30:00.000]
    give the same time, [12:30:00.5] gives [nanosecond = 500_000_000], and
    [00:00:00.1234567891] gives [nanosecond = 123_456_789]. *)

type offset = Types.offset =
  | Minutes of int
      (** a known offset from UTC: the local time minus UTC, in minutes, from
          -1439 to 1439. [Z], [z], and [+00:00] give [Minutes 0], and [-07:00]
          gives [Minutes (-420)]. *)
  | Unknown_local
      (** the unknown local offset of RFC 3339, section 4.3, which the document
          writes as [-00:00] *)

(** A value of a TOML document. *)
type value = Types.value =
  | String of string
      (** a string: the UTF-8 encoding of its text after the escape sequences
          resolve. A newline right after the opening delimiter of a multi-line
          string is not part of the text, and in a multi-line basic string, a
          backslash at the end of a line is not part of the text, with the
          spaces, tabs, and newlines after it up to the next other character.
          Each other newline stays as the document writes it: a line feed, or a
          carriage return and a line feed. *)
  | Integer of int64
      (** an integer, from [Int64.min_int] to [Int64.max_int]. A document
          integer outside that range makes the byte sequence invalid. *)
  | Float of float
      (** a float. For a float that is not [inf] or [nan] with or without a
          sign, the value is the binary64 value that rounding to nearest, with
          ties to even, gives for the number that the document writes, and its
          sign bit is 1 when, and only when, the document writes [-] first. So
          [-0.0] and [-1e-400] give negative zero. A float that rounds to an
          infinity, such as [1e400], makes the byte sequence invalid. [inf] and
          [+inf] give [Float.infinity], and [-inf] gives [Float.neg_infinity].
          [nan], [+nan], and [-nan] give a NaN whose sign bit is 1 when, and
          only when, the document writes [-] first. *)
  | Boolean of bool  (** [true] or [false] *)
  | Offset_date_time of date * time * offset
      (** an offset date-time: the date and the time that the document writes
          before the offset, and the offset. No conversion to UTC takes place.
      *)
  | Local_date_time of date * time  (** a local date-time *)
  | Local_date of date  (** a local date *)
  | Local_time of time  (** a local time *)
  | Array of item list
      (** an array: its elements in their order. An array that the document
          writes with brackets and an array that table headers of an array of
          tables make are both [Array]. *)
  | Table of table  (** a table *)

and item = Types.item = { value : value; span : span option; key : key option }
(** A value of a document, at one place in the tree of the root table.

    [span] is the span of the value as the document writes it, with the quotes
    of a string, the brackets of an array, and the braces of an inline table,
    and with no space or tab before or after it. It is [None] for a table that a
    table header makes, a table that a dotted key makes on its way, and an array
    that table headers of an array of tables make: the document writes no value
    for these.

    [key] is the key that leads to this item:
    - for the value of a key/value pair, the key of that key/value pair;
    - for the table that a table header names, the key of that table header: for
      [[a.b]], the table at [b] in the table at [a]; for [[[a]]], the table that
      the header adds to the array at [a];
    - [None] for every other item, such as an element of an array that the
      document writes with brackets, and a table that a dotted key or a table
      header makes on its way to its last part. *)

and table = (string * item) list
(** A table: one pair for each key of the table, of the UTF-8 encoding of the
    text of the key after its escape sequences resolve, and the item of that
    key. No two pairs have the same text. Each key comes from one key/value pair
    or table header of the document, the one that adds the key to the table,
    also when it only makes a table on its way to its last part. The pairs are
    in the order of these key/value pairs and table headers in the document. *)

(** The kind of fault in a byte sequence that is not a TOML document. *)
type error = Types.error =
  | Not_utf_8
      (** The byte sequence is not valid UTF-8. The offset is the place of the
          first byte that does not start a UTF-8 encoding of a character
          completed by the bytes after it. *)
  | Syntax
      (** The text does not match the ABNF grammar of TOML 1.1.0. The offset is
          the place where the reader found that the text does not match. *)
  | Integer_out_of_range
      (** An integer is less than [Int64.min_int] or greater than
          [Int64.max_int]. The offset is the start of the integer. *)
  | Float_out_of_range
      (** A float rounds to an infinity. The offset is the start of the float.
      *)
  | Date_time_out_of_range
      (** A month, a day, an hour, a minute, a second, or an offset of a date or
          time is outside the range of RFC 3339, with the second 60 allowed at
          every minute. The offset is the start of the date or time. *)
  | Escape_not_a_character
      (** An escape sequence [\u] or [\U] in a string or a quoted key writes a
          number from 0xD800 to 0xDFFF or greater than 0x10FFFF, which is not
          the code point of a character. The offset is the place of its
          backslash. *)
  | Duplicate_key
      (** A key/value pair gives a value to a key that its table already holds.
          The offset is the start of the key of the key/value pair. *)
  | Table_defined_twice
      (** A table header names a table that an earlier table header or an
          earlier dotted key already defines. The offset is the start of the key
          of the table header. *)
  | Not_a_table
      (** A part of a key before the last part leads to a value that is not a
          table and not an array of tables made by table headers, or the key of
          a table header without double brackets leads to such a value. The
          offset is the start of the key. *)
  | Not_an_array_of_tables
      (** The key of a table header with double brackets leads to a value that
          is not an array that table headers of an array of tables make, and
          that is not the table of an inline table, which gives
          [Inline_table_closed]. The offset is the start of the key. *)
  | Inline_table_closed
      (** A key/value pair adds a key to the table of an inline table, or to a
          table in it, outside the braces of that inline table; or a part of the
          key of a table header, the last part included, leads to the table of
          an inline table or to a table in it, as in [a = {}] then [[a]], and
          [x = {}] then [[[x]]]. The offset is the start of the key. *)
  | Dotted_key_into_named_table
      (** A part of a dotted key, before its last part, leads to a table that an
          earlier table header names. The offset is the start of the key. *)

(** A limit that the caller of {!read} set. *)
type limit = Types.limit =
  | Depth
      (** An array or an inline table has a depth greater than [max_depth]. The
          depth of an array or an inline table that is in no array and no inline
          table is 1; the depth of one that is an element of an array, or a
          value in an inline table, is 1 more than the depth of that array or
          inline table. Tables that table headers and dotted keys make have no
          depth. The offset is the place of the [\[] or [{] of the first such
          array or inline table. *)
  | Key_parts
      (** A key of a key/value pair or of a table header has more parts than
          [max_key_parts]: a bare key and a quoted key are each one part, and a
          dotted key has one part for each bare or quoted key that it joins with
          dots. The offset is the start of the first part past the limit. *)

type failure = Types.failure =
  | Invalid of { error : error; offset : int }
      (** The byte sequence is not a TOML document. *)
  | Limit_reached of { limit : limit; offset : int }
      (** The reader stopped at a limit before it found whether the byte
          sequence is a TOML document. This says nothing about whether it is
          one. *)

val read :
  ?max_depth:int -> ?max_key_parts:int -> string -> (table, failure) result
(** [read bytes] is [Ok root] when [bytes] is a TOML document of TOML 1.1.0,
    with [root] its root table. When the byte sequence starts with the bytes
    0xEF 0xBB 0xBF, the reader reads the text after the U+FEFF that they encode.
    It is [Error (Invalid _)] when [bytes] is not a TOML document, and the
    reader found that before it reached a limit. It is [Error (Limit_reached _)]
    when the reader reached a limit first.

    Without [max_depth], no depth reaches a limit, and without [max_key_parts],
    no number of parts reaches a limit; [read] then gives [Ok _] or
    [Error (Invalid _)] for every byte sequence, however deep its nesting and
    however long its keys. With either, each array, inline table, and key that
    does not pass it reads as it does without the limit, so the reader never
    gives [Invalid] for a TOML document.

    The reader first checks that the whole byte sequence is valid UTF-8, and
    gives [Invalid { error = Not_utf_8; _ }] when it is not. Then it reads the
    text from its start and stops at the first fault or limit that it finds, and
    the failure names that one. Of a [Syntax] fault and a limit, it finds first
    the one with the smaller offset. It finds a fault of another kind before it
    reads the byte after the smallest value or key that holds the fault: for a
    fault of a key/value pair or a table header, after the last byte of its key.

    The function never raises an exception. For [n] the length of [bytes], the
    time grows no faster than [n log n]. The stack space that it uses does not
    grow with the depth of nesting. *)
