(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Texts, byte sequences, and UTF-8, as the design [text=v1] defines them.

    A text is a finite sequence of characters, each a Unicode scalar value. The
    places of a text are the whole numbers from 1 to its length; the character
    at place [k] is its [k]-th character. Its boundaries are the whole numbers
    from 0 to its length: boundary 0 is before place 1, and boundary [k] is
    right after place [k]. A byte sequence is an OCaml [string], whose bytes are
    its places from 1 in order. *)

type t
(** A text. Every value is a finite sequence of Unicode scalar values. *)

type run = { from : int; until : int }
(** A pair of boundaries: [from] is the boundary where the run starts, and
    [until] is the boundary where it ends. The pair is a run of a text [t] when
    [0 <= from <= until <= length t]. The run then holds the characters at the
    places from [from + 1] to [until]. *)

type decode_error =
  | Invalid_utf_8 of { place : int }
      (** The byte sequence is not valid UTF-8. [place] is the place, from 1, of
          the first byte that no [UTF8-char] of RFC 3629 covers when the
          [UTF8-char] are matched in order from place 1: the bytes before
          [place] are valid UTF-8, and no [UTF8-char] matches bytes that start
          at [place]. *)

val decode : string -> (t, decode_error) result
(** [decode bytes] is [Ok text] when [bytes] is valid UTF-8, and [text] is then
    the text of the byte sequence: one character for each [UTF8-char], in order,
    with a U+FEFF at place 1 kept, each carriage return kept, and no Unicode
    normalization. It is [Error] when [bytes] is not valid UTF-8, and then no
    text. The time is linear in the length of [bytes]. *)

val encode : t -> string
(** [encode text] is the UTF-8 encoding of [text]: for each character in order,
    the bytes that encode it, and no other bytes. *)

val of_uchars : Uchar.t list -> t
(** [of_uchars characters] is the text of [characters], in order. *)

val empty : t
(** [empty] is the text of no characters. *)

val length : t -> int
(** [length text] is the number of characters of [text]. *)

val get : t -> int -> Uchar.t option
(** [get text place] is the character at [place], or [None] when [place] is not
    from 1 to [length text]. *)

val sub : t -> run -> t option
(** [sub text run] is the text of [run]: its characters in order. It is [None]
    when [run] is not a run of [text]. *)

val concat : t list -> t
(** [concat texts] is the text of the characters of each element of [texts], in
    order: the characters of the first element, then those of the second, and so
    on. It is {!empty} when [texts] is [[]]. The time is linear in the sum of
    the lengths of the elements. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, [a] and [b] have the same number
    of characters and the same character at each place. *)

val has_byte_order_mark : t -> bool
(** [has_byte_order_mark text] is [true] when, and only when, the character at
    place 1 of [text] is U+FEFF. *)

val body : t -> run
(** [body text] is the body of [text]: the run from boundary 1 when [text] has a
    byte order mark, and from boundary 0 otherwise, to boundary [length text].
*)
