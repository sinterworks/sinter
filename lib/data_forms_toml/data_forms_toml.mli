(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The TOML documents of the specification [toml] of the design
    [data-forms=v1]: for a byte sequence, the result "valid" with the root table
    and the spans of the keys and the values, or the result "invalid". *)

(** A TOML value of the design. *)
type value =
  | String of string  (** a TOML string: the UTF-8 encoding of its text *)
  | Integer of int64  (** a TOML integer *)
  | Float of float  (** a TOML float, as a binary64 value *)
  | Boolean of bool  (** a TOML boolean *)
  | Local_date of Sinter_toml.date  (** a local date *)
  | Local_time of Sinter_toml.time
      (** a local time; its fraction of a second is [nanosecond] in units of
          10{^ -9} seconds *)
  | Local_date_time of Sinter_toml.date * Sinter_toml.time
      (** a local date-time *)
  | Offset_date_time of Sinter_toml.date * Sinter_toml.time * Sinter_toml.offset
      (** an offset date-time: its local date-time and its offset, a number of
          minutes or the unknown local offset *)
  | Array of value list  (** a TOML array: its TOML values, by index *)
  | Table of table  (** a table *)

and table = (string * value) list
(** A table: one pair for each text that the table holds, of that text, as its
    UTF-8 encoding, and the TOML value of the text. From {!read}, no two pairs
    have the same text, and the pairs are in the order of the bytes of their
    texts, which is the code point order of the texts. The order of the pairs
    has no meaning in the design. *)

(** A step of a location: the text of a TOML key, as its UTF-8 encoding, or the
    index of a TOML value in a TOML array, counted from 1. *)
type step = Text of string | Index of int

type location
(** A location: the steps that lead from the root table to a TOML value. *)

val steps : location -> step list
(** [steps location] is the steps of [location], in their order from the root
    table. The time grows with the number of steps. *)

(** What a span is the span of, at a location. *)
type subject =
  | Toml_value  (** the TOML value at the location *)
  | Key  (** the key of TOML 1.1.0 that leads to the location *)
  | Toml_key of int
      (** the TOML key with this index, from 1, of the key of TOML 1.1.0 that
          leads to the location *)

type span = {
  start : Sinter_text.Lines.position;
  end_ : Sinter_text.Lines.position;
}
(** The start and the end of a span of the text of the byte sequence, as Text
    and notation gives them: lines, line numbers, and columns of characters, in
    which a byte order mark has no position and adds no column. *)

type document = { root_table : table; spans : (subject * location * span) list }
(** What a conforming program gives with the result "valid": the root table, and
    each span of the document with what it is the span of, at a location.
    [spans] holds exactly the span pairs of the document, as the term
    [toml-span-pair] defines them: one element for each TOML value that has a
    span, for the key of each key/value pair and of each table header, and for
    each TOML key of these keys, and no other element. No two elements have the
    same subject and the same location. The order of the elements has no
    meaning. *)

type outcome =
  | Valid of document  (** the result "valid", with the document *)
  | Invalid  (** the result "invalid" *)
  | No_result
      (** no result: the reader stopped at a limit of the caller before it found
          whether the byte sequence is a TOML document *)

val read : ?max_depth:int -> ?max_key_parts:int -> string -> outcome
(** [read bytes] is [Valid document] when [bytes] is a TOML document, with its
    root table and its span pairs, and [Invalid] when it is not. A TOML document
    can have any depth of nesting and keys of any number of TOML keys.
    [max_depth] and [max_key_parts] are limits of the reader, as
    {!Sinter_toml.read} defines them. When the reader reaches one of them before
    it finds whether [bytes] is a TOML document, [read] is [No_result], and
    never [Invalid] for a TOML document. Without them, [read] is never
    [No_result].

    The function never raises an exception, and its stack space does not grow
    with the depth of nesting of [bytes]. *)
