(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** SHA-256 hashes, as the specification [hashes] of the design [data-forms=v1]
    defines them.

    The hash of a byte sequence is the hex text of the digest of 32 bytes that
    SHA-256 of FIPS 180-4 gives for it: 64 hex digits, each one of the
    characters [0] to [9] and [a] to [f]. A byte sequence is an OCaml [string],
    and a text is its UTF-8 encoding. A program that links this library also
    links an implementation of the virtual library [digestif], such as
    [digestif.c]. *)

type t = private string
(** A hash: a text of exactly 64 hex digits. *)

val compute : string -> t
(** [compute bytes] is the hash of [bytes]. Every OCaml string has fewer than
    2^61 bytes, so every byte sequence of this type has a hash. *)

val validate : string -> t option
(** [validate text] is [Some text] when [text] fits the hash form: it is exactly
    64 hex digits and nothing else. It is [None] when [text] does not fit the
    hash form, such as when it holds an upper-case letter. *)
