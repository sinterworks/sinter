(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Grammar names, as the specification [descriptor] of the design [packs=v1]
    defines them.

    A grammar name is a text that matches the production [grammar-name]: a
    lower-case ASCII letter, then any number of lower-case ASCII letters, ASCII
    digits, and [_], such as [ocaml_interface]. A text is an OCaml [string] that
    holds its UTF-8 encoding. *)

type t = private string
(** A grammar name. *)

val of_string : string -> t option
(** [of_string text] is [Some text] when [text] is a grammar name, and [None]
    when it is not. *)
