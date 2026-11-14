(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Id patterns, and the fit of an id to an id pattern, as the design
    [identifiers=v1] defines them.

    The bytes of an id pattern and of an id are read as the UTF-8 encoding of a
    text. A string that is not valid UTF-8 is not the UTF-8 encoding of any text
    that matches the production [pattern], and no id that it encodes fits an id
    pattern. *)

type t
(** An id pattern that the program accepts: it matches the production [pattern],
    and none of the conditions of {!error} holds for it. *)

(** Why an id pattern is invalid. When several conditions hold, the error is one
    of them. *)
type error =
  | Too_long  (** the id pattern holds more than 1,000 characters *)
  | Unmatched  (** the id pattern does not match the production [pattern] *)
  | Reversed_range
      (** the id pattern uses a [range] whose first character comes after its
          last character in code point order *)
  | Large_count  (** the id pattern uses a [count] whose number exceeds 255 *)
  | Reversed_bounds
      (** the id pattern uses a quantifier [{n,m}] in which [n] exceeds [m] *)
  | Oversized  (** the size of the id pattern exceeds 1,000 *)
  | Empty_id_fits  (** the empty id fits the id pattern *)

val of_string : string -> (t, error) result
(** [of_string text] is [Ok pattern] when the program accepts [text] as an id
    pattern, and [Error] with a condition that rejects it otherwise. The time is
    linear in the length of [text]. *)

val to_string : t -> string
(** [to_string pattern] is the text that {!of_string} took. *)

val fits : t -> string -> bool
(** [fits pattern id] is [true] when, and only when, the whole of [id] has the
    form that [pattern] gives. The time is at most the product of the length of
    [id] and the size of [pattern], with a constant factor. *)
