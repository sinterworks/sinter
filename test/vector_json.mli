(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The JSON texts of the vectors of Data forms, read exactly, and the canonical
    forms that the design gives, computed apart from the library. *)

type str =
  | Text of string
      (** A string that gives a text: the UTF-8 encoding of the text. *)
  | No_text of int list
      (** A string that gives no text: its UTF-16 code units, which hold a
          number from 0xD800 to 0xDFFF that is not one of the two code units of
          a character. *)

(** What a JSON text gives, before the rules of the design decide whether it is
    a JSON value. *)
type t =
  | Null
  | Bool of bool
  | Number of string  (** the JSON number, as the JSON text writes it *)
  | String of str
  | Array of t list
  | Object of (str * t) list
      (** the members, in the order in which the JSON text writes them *)

val read : string -> t
(** [read json_text] is what the JSON text [json_text] gives. It raises
    [Failure] when [json_text] is not a JSON text that [Yojson.Raw] reads. *)

val integer : string -> int option
(** [integer number] is [Some k] when the JSON number [number], as RFC 8259
    writes it, writes a whole number [k] from -(2^53 - 1) to 2^53 - 1, and
    [None] for every other text. *)

val of_basic : Yojson.Basic.t -> t
(** [of_basic json] is [json] in the form [t]. It raises [Invalid_argument] when
    a string or a key of [json] is not valid UTF-8. *)

val units : str -> int list
(** [units string] is the UTF-16 code units of [string]. *)

val is_json_value : t -> bool
(** [is_json_value thing] holds when [thing] is a JSON value of the design: no
    null, each number an integer, each string a text, and no key twice in one
    object. *)

val is_line_object : t -> bool
(** [is_line_object thing] holds when [thing] is a JSON value and a line object
    of the design. *)

val utf_16_code_units : string -> int list
(** [utf_16_code_units text] is the UTF-16 code units of the text whose UTF-8
    encoding is [text]. *)

val compare_keys : string -> string -> int
(** [compare_keys a b] is negative when [a] comes before [b] in key order, 0
    when they are the same text, and positive otherwise. *)

val canonical : t -> string option
(** [canonical thing] is the canonical byte sequence of [thing] when it is a
    JSON value, and [None] otherwise. *)

val canonical_line : t -> string option
(** [canonical_line thing] is the canonical line of [thing] when it is a line
    object, and [None] otherwise. *)

val to_basic : t -> Yojson.Basic.t
(** [to_basic value] is the JSON value [value] as [Yojson.Basic.t]. It raises
    [Invalid_argument] when [value] is not a JSON value. *)

val hex : string -> string
(** [hex bytes] is the hex text of [bytes]. *)

val of_hex : string -> string
(** [of_hex digits] is the byte sequence whose hex text is [digits]. It raises
    [Invalid_argument] when [digits] is not a hex text. *)

val print : t -> string
(** [print thing] is a JSON text, for messages: it writes a string that gives no
    text as [<no text>]. *)

(** Generators of the inputs of the properties. *)

val text_gen : string QCheck2.Gen.t
(** Texts, with the characters at the edges of the rules: the characters that
    have string forms of their own, U+007F, U+2028, U+E000, U+FFFF, U+10000,
    U+1F600, and U+10FFFF. *)

val value_gen : t QCheck2.Gen.t
(** JSON values. *)

val deep_gen : t QCheck2.Gen.t
(** JSON values nested from 1,000 to 100,000 arrays or objects deep. *)

val line_object_gen : t QCheck2.Gen.t
(** Line objects. *)

val thing_gen : t QCheck2.Gen.t
(** JSON values and things that are not JSON values: a null, a number that is no
    integer, a string that gives no text, or a key twice, at any depth. *)

val corrupt_gen : string -> string QCheck2.Gen.t
(** [corrupt_gen bytes] gives byte sequences that differ from [bytes] by one
    byte inserted, removed, or replaced, or by two bytes swapped. *)
