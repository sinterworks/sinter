(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Id patterns, and the fit of an id to an id pattern, as the design
    [identifiers=v1] defines them.

    The bytes of an id pattern and of an id are read as the UTF-8 encoding of a
    text. A string that is not valid UTF-8 is not the UTF-8 encoding of any text
    that matches the production [pattern], and no id that it encodes fits an id
    pattern. *)

type t
(** A valid id pattern at which the program stops at no limit of its own. It
    matches the production [pattern], and none of the conditions of {!error} and
    {!limit} holds for it. *)

(** Why an id pattern is not a valid id pattern. When several conditions hold,
    the error is one of them. *)
type error =
  | Unmatched  (** the id pattern does not match the production [pattern] *)
  | Reversed_range
      (** the id pattern uses a [range] whose first character comes after its
          last character in code point order *)
  | Reversed_bounds
      (** the id pattern uses a quantifier [{n,m}] in which [n] exceeds [m] *)
  | Empty_id_fits  (** the empty id fits the id pattern *)

(** A limit of the program on an id pattern. No rule of the design
    [identifiers=v1] makes an id pattern that passes one of these limits not
    valid. *)
type limit =
  | Too_long  (** the id pattern holds more than 1,000 characters *)
  | Large_count  (** the id pattern uses a [count] whose number exceeds 255 *)
  | Oversized
      (** the size of the id pattern exceeds 1,000. The size counts the literals
          and the character classes of the id pattern when each quantifier is
          written out as copies of its element: [{n}] counts as [n] copies,
          [{n,m}] as [m] copies, [{n,}] as [n] copies and one more, and [?],
          [*], and [+] as one copy; every quantifier counts as one copy at
          least, also [{0}] and [{0,0}]. A subpattern counts as the sum of the
          sizes of its branches. With the floor of one copy, the program builds
          for each id pattern that it accepts an automaton whose number of
          states is at most a constant times the size. So {!of_string} stays
          linear in the length of the text, and {!fits} keeps its bound. *)

(** Why {!of_string} gives no id pattern. *)
type rejection =
  | Invalid of error
      (** the id pattern is not a valid id pattern: the result "invalid" *)
  | Stopped of limit
      (** the program stops at this limit of its own on the id pattern: no
          result "valid" or "invalid" *)

val of_string : string -> (t, rejection) result
(** [of_string text] is [Ok pattern] when [text] is a valid id pattern at which
    the program stops at no limit of its own. It is [Error (Invalid e)] when
    [text] is not a valid id pattern, with a condition [e] that holds for it,
    and [Error (Stopped l)] when the program stops at the limit [l] on [text].
    When [text] is not a valid id pattern and passes a limit, the result is one
    of these two errors. The time is linear in the length of [text]. *)

val to_string : t -> string
(** [to_string pattern] is the text that {!of_string} took. *)

val fits : t -> string -> bool
(** [fits pattern id] is [true] when, and only when, the whole of [id] has the
    form that [pattern] gives. The time is at most the product of the length of
    [id] and the size of [pattern], with a constant factor. *)
