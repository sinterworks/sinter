(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Spec versions, as the specification [descriptor] of the design [packs=v1]
    defines them.

    A spec version is a text that matches the production [spec-version]: two
    decimal numerals joined by [.], such as [1.0]. A decimal numeral is [0], or
    a digit from [1] to [9] followed by any number of digits. A text is an OCaml
    [string] that holds its UTF-8 encoding. *)

type t = private string
(** A spec version. *)

val of_string : string -> t option
(** [of_string text] is [Some text] when [text] is a spec version, and [None]
    when it is not. *)
