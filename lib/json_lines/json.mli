(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** JSON values, key order, and canonical byte sequences, as the design
    [data-forms=v1] defines them.

    A JSON value is a string, an integer, a boolean, an array, or an object. It
    is never null, and it is never a number that is not an integer. An integer
    is a whole number from [-(2^53 - 1)] to [2^53 - 1]. A byte sequence is an
    OCaml [string]. *)

open Sinter_text

(* @satisfies data-forms#write-canonical-json=v1
   The writer takes only values of this type, and the type holds only JSON
   values, so the writer gives no byte sequence for a thing that is not one. *)

(** A JSON value. Every value of this type is a JSON value, and each JSON value
    has exactly one value of this type. *)
type t = private
  | String of Text.t  (** a string: a text *)
  | Integer of int  (** an integer, from [min_integer] to [max_integer] *)
  | Boolean of bool  (** a boolean *)
  | Array of t list  (** an array: its elements in their order *)
  | Object of (Text.t * t) list
      (** an object: its members, each a key and a value, in the key order of
          their keys, with no two members of the same key *)

val min_integer : int
(** [min_integer] is [-9007199254740991], the least integer. *)

val max_integer : int
(** [max_integer] is [9007199254740991], the greatest integer. *)

val string : Text.t -> t
(** [string text] is the string [text]. *)

val integer : int -> t option
(** [integer number] is the integer [number], or [None] when [number] is less
    than [min_integer] or greater than [max_integer]. *)

val boolean : bool -> t
(** [boolean b] is the boolean [b]. *)

val array : t list -> t
(** [array elements] is the array of [elements], in their order. *)

val object_ : (Text.t * t) list -> t option
(** [object_ members] is the object of [members], each a key and a value, or
    [None] when two of [members] have the same key. The order of [members] is no
    part of the object. *)

val compare_keys : Text.t -> Text.t -> int
(** [compare_keys a b] compares [a] and [b] in key order: by their UTF-16 code
    units, at the first index at which they differ, and a text before every
    longer text whose code units start with all of its code units. It is
    negative when [a] comes before [b], [0] when [a] and [b] are the same text,
    and positive when [b] comes before [a]. *)

val canonical_byte_sequence : t -> string
(** [canonical_byte_sequence value] is the canonical byte sequence of [value]:
    the UTF-8 encoding of its canonical form. The time is linear in the length
    of the result, and the function uses no stack space that grows with the
    depth of [value]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, [a] and [b] are the same JSON
    value. It uses no stack space that grows with the depth of [a] or [b]. *)

val read : string -> t option
(** [read bytes] is [Some value] when [bytes] is the canonical byte sequence of
    the JSON value [value], and [None] for every other byte sequence. It never
    raises. The time is linear in the length of [bytes], and the function uses
    no stack space that grows with the depth of the JSON value. *)

val read_json_text : string -> t option
(** [read_json_text bytes] is [Some value] when [bytes] has the JSON value
    [value], and [None] when [bytes] has no JSON value. A byte sequence has a
    JSON value when it is valid UTF-8, its text matches the rule [JSON-text] of
    RFC 8259, and the value of that JSON text gives a JSON value: no value is
    [null]; each number has no fraction and no exponent and writes a whole
    number from [min_integer] to [max_integer]; each escape sequence [\u] of a
    number from 0xD800 to 0xDBFF is right before an escape sequence [\u] of a
    number from 0xDC00 to 0xDFFF, with which it writes one character, and no
    other escape sequence [\u] writes a number from 0xD800 to 0xDFFF; and no
    object has two names that stand for the same text. The JSON text can hold
    spaces, tabs, line feeds, and carriage returns around its values, braces,
    brackets, colons, and commas. The function never raises, it sets no limit on
    the depth of arrays and objects, and it uses no stack space that grows with
    that depth. *)
