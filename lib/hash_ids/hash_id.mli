(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Hash ids, as the specification [hash-ids] of the design [data-forms=v1]
    defines them.

    An id prefix is one or more of the letters [a] to [z], then [-], such as
    ["e-"]. For an id prefix p and a number n of hex digits from 1 to 64, the
    hash id of a byte sequence is p, then the first n hex digits of the hash of
    the byte sequence. A text fits the hash-id form with p and n when it is p,
    then exactly n hex digits. A byte sequence is an OCaml [string], and a text
    is its UTF-8 encoding. *)

type form
(** An id prefix and a number of hex digits from 1 to 64. *)

(** Why an id prefix and a number of hex digits make no form. *)
type form_error =
  | Not_an_id_prefix of string
      (** The text is not an id prefix: one or more of the letters [a] to [z],
          then [-]. *)
  | Number_of_hex_digits_out_of_range of int
      (** The number is less than 1 or greater than 64. *)

val form :
  id_prefix:string -> number_of_hex_digits:int -> (form, form_error) result
(** [form ~id_prefix ~number_of_hex_digits] is the form of [id_prefix] and
    [number_of_hex_digits]. It is [Error (Not_an_id_prefix id_prefix)] when
    [id_prefix] is not an id prefix, and otherwise
    [Error (Number_of_hex_digits_out_of_range number_of_hex_digits)] when
    [number_of_hex_digits] is less than 1 or greater than 64. *)

type t = private string
(** A hash id. *)

val compute : form -> string -> t
(** [compute form bytes] is the hash id of [bytes] with the id prefix and the
    number of hex digits of [form]. *)

val validate : form -> string -> t option
(** [validate form text] is [Some text] when [text] fits the hash-id form with
    the id prefix and the number of hex digits of [form], and [None] when it
    does not. *)
