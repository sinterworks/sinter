(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The input form of the writers: what a JSON text of RFC 8259 gives, as the
    group [write-json] of the specification [json-lines] of the design
    [data-forms=v1] reads it. A thing of this form can be a JSON value, or a
    thing that is not one, such as null, the number [1.5], or a string with a
    lone surrogate. Its numbers follow the number rule of the group
    [write-json], so a number with a fraction or an exponent can give an
    integer. It is not the reader of the JSON value of a byte sequence:
    {!Json.read_json_text} reads that, and gives no JSON value for a number with
    a fraction or an exponent. *)

(** A thing that a JSON text gives. *)
type t =
  | Null  (** the literal [null] *)
  | Boolean of bool  (** the literal [true] or [false] *)
  | Number of string
      (** a number: the characters of a JSON number of RFC 8259 as the JSON text
          writes it, such as ["1.0"], ["1e2"], or ["-0"] *)
  | String of int list
      (** a string: the UTF-16 code units that its characters and its escape
          sequences write, in their order *)
  | Array of t list  (** an array: its elements in their order *)
  | Object of (int list * t) list
      (** an object: its members in the order of the JSON text, each a key as
          its UTF-16 code units, and a value *)

val to_json_value : t -> Json.t option
(** [to_json_value thing] is the JSON value that [thing] is, or [None] when
    [thing] is not a JSON value. These rules give it:
    - [Null] is not a JSON value.
    - [Boolean b] is the boolean [b].
    - By the number rule of the group [write-json], [Number s] is an integer
      when, and only when, [s] matches the rule [number] of RFC 8259 and writes
      a whole number from [Json.min_integer] to [Json.max_integer], and that
      integer is the whole number that [s] writes. So ["1.0"] gives 1, ["1e2"]
      gives 100, and ["-0"] gives 0, and ["1.5"], ["9007199254740992"], and
      ["01"] give no JSON value.
    - [String units] is the string of the text whose UTF-16 code units are
      [units]. When no text has these code units, such as when [units] holds a
      number from 0xD800 to 0xDFFF that is not one of the two code units of a
      character, or a number outside 0 to 65,535, it is not a JSON value.
    - [Array elements] is the array of the JSON values of [elements], when each
      of them is a JSON value.
    - [Object members] is the object of the keys and the JSON values of
      [members], when each key is a text, each value is a JSON value, and no two
      keys are the same text.

    The function uses no stack space that grows with the depth of [thing]. *)
