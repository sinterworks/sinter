(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Release numbers, as the specification [descriptor] of the design [packs=v1]
    defines them.

    A release number is a text that matches the production [release-number]:
    three decimal numerals joined by [.], such as [1.0.3]. A decimal numeral is
    [0], or a digit from [1] to [9] followed by any number of digits. A text is
    an OCaml [string] that holds its UTF-8 encoding. *)

type t = private string
(** A release number. *)

val of_string : string -> t option
(** [of_string text] is [Some text] when [text] is a release number, and [None]
    when it is not. *)
