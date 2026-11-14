(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Pack names, as the specification [descriptor] of the design [packs=v1]
    defines them.

    A pack name is a text that matches the production [pack-name]: a lower-case
    ASCII letter, then lower-case ASCII letters and ASCII digits, in groups that
    a single [-] joins, with no [-] at the start or the end and no two [-] side
    by side, such as [typescript] or [cargo-nextest]. A text is an OCaml
    [string] that holds its UTF-8 encoding. *)

type t = private string
(** A pack name. *)

val of_string : string -> t option
(** [of_string text] is [Some text] when [text] is a pack name, and [None] when
    it is not. *)
