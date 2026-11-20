(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The TOML values of the specification [toml] of Data forms, apart from the
    libraries under test: their forms in the vectors, their equality, a writer
    of TOML 1.1.0 texts that give them, and generators. *)

type date = { year : int; month : int; day : int }
type time = { hour : int; minute : int; second : int; nanosecond : int }

type offset =
  | Minutes of int  (** a signed number of minutes, 0 for [Z] *)
  | Unknown_local  (** the offset [-00:00] *)

type value =
  | String of string  (** the UTF-8 encoding of the text *)
  | Integer of int64
  | Float of float
  | Boolean of bool
  | Local_date of date
  | Local_time of time
  | Local_date_time of date * time
  | Offset_date_time of date * time * offset
  | Array of value list
  | Table of (string * value) list
      (** the pairs, each the UTF-8 encoding of the text of a TOML key and its
          value, with no two texts the same *)

val equal : value -> value -> bool
(** [equal a b] holds when [a] and [b] are equal TOML values: of the same kind,
    with the same parts; tables with the same texts in any order; floats with
    the same bits, or both NaN. *)

val float_form : float -> string
(** [float_form x] is the string of the TOML float [x] in the vectors: [nan],
    [inf], [-inf], [-0], or the exact value in base 10. *)

val form : value -> Yojson.Basic.t
(** [form v] is the form of the TOML value [v] in the vectors. *)

val table_form : (string * value) list -> Yojson.Basic.t
(** [table_form pairs] is the form of the table of [pairs] in the vectors. *)

val print : value -> string
(** [print v] is a text of [v], for messages. *)

val of_toml_test : Yojson.Basic.t -> value option
(** [of_toml_test json] is the value that a JSON file of toml-test v2.2.0
    states, or [None] when [json] is not of that form. *)

val days_in_month : int -> int -> int
(** [days_in_month year month] is the number of days of [month] of [year] in the
    proleptic Gregorian calendar. *)

(** {1 A writer of TOML 1.1.0} *)

type span = { start_byte : int; end_byte : int }
(** A run of a document, as the byte offsets of its start and of its end. *)

type located = {
  location : Yojson.Basic.t list;
      (** the steps: [`String] for the text of a TOML key, [`Int] for an index
      *)
  span : span;  (** the run that the rule [val] matches *)
}
(** A value of TOML 1.1.0 of a written document, with the location of the TOML
    value that it gives. *)

type located_key = {
  key_location : Yojson.Basic.t list;
      (** the location to which the key leads, as the requirement
          [give-toml-spans] gives it *)
  key_span : span;  (** the run that the rule [key] matches *)
  parts : span list;
      (** the runs that the rule [simple-key] matches, one for each TOML key *)
}
(** The key of a key/value pair or of a table header of a written document. *)

type document = {
  bytes : string;  (** the document *)
  root : (string * value) list;  (** the root table that it gives *)
  values : located list;  (** each value of TOML 1.1.0 of the document *)
  keys : located_key list;
      (** each key of a key/value pair and of a table header of the document *)
  depth : int;
      (** the greatest depth of an array of TOML 1.1.0 or an inline table, or 0
          when the document holds none *)
  key_parts : int;  (** the greatest number of TOML keys of one key, or 0 *)
}

val position : string -> int -> int * int
(** [position bytes offset] is the line number and the column of the boundary
    right before the byte at [offset] of the valid UTF-8 [bytes], as Text and
    notation counts them: a byte order mark adds no column, and a column counts
    characters. [offset] is the offset of the first byte of a character, or the
    length of [bytes]. *)

val document_gen : document QCheck2.Gen.t
(** TOML documents, each with its root table: the tables written as table
    headers, as dotted keys, or as inline tables; arrays of tables as table
    headers or as arrays of inline tables, and some table headers after the
    headers of their sub-tables; keys bare or quoted; strings in the four forms
    of TOML 1.1.0 with escape sequences; integers in the four bases; floats,
    dates, and times in their spellings; with spaces, tabs, comments, blank
    lines, and CRLF line endings between the parts. *)

val write_value : value -> string QCheck2.Gen.t
(** [write_value v] gives values of TOML 1.1.0 that give [v]. [v] holds no
    table. *)

val key_gen : string QCheck2.Gen.t
(** Texts of TOML keys: bare letters, the empty text, and texts with quotes,
    backslashes, control characters, and characters beyond U+FFFF. *)

val write_key : string -> string QCheck2.Gen.t
(** [write_key text] gives TOML keys whose text is [text]. *)

val print_document : document -> string
(** [print_document d] is the bytes of [d] as an OCaml string literal. *)

(** {1 Inputs at the edges} *)

val nested_arrays : int -> string
(** [nested_arrays depth] is [a = ], then [depth] [\[], then [depth] [\]], then
    a line feed: an array of TOML 1.1.0 of the depth [depth] at its deepest. *)

val nested_inline_tables : int -> string
(** [nested_inline_tables depth] is [a = ], then [depth] inline tables nested by
    the key [b], the deepest one empty, then a line feed. *)

val dotted_key : int -> string
(** [dotted_key parts] is a key/value pair whose dotted key has [parts] TOML
    keys [a], with the value 1. *)

val dotted_header : int -> string
(** [dotted_header parts] is a table header whose key has [parts] TOML keys [a].
*)

val corrupt_gen : string -> string QCheck2.Gen.t
(** [corrupt_gen bytes] gives byte sequences that differ from [bytes] by one to
    three bytes inserted, removed, or replaced, with the bytes of the syntax of
    TOML and of UTF-8 more often than others. *)

val noise_gen : string QCheck2.Gen.t
(** Byte sequences of the characters of the syntax of TOML, bytes that are not
    UTF-8, and words such as [true], [inf], and dates. *)
