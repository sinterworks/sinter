(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The parts of a text: the texts that its [/] characters separate. *)

type t = { text : Sinter_text.Text.t; bytes : string }
(** A part: its text, and the UTF-8 encoding of that text. *)

val split : Sinter_text.Text.t -> t list
(** [split text] is the parts of [text], in order: the text before the first
    [/], the text between each two [/] that follow each other, and the text
    after the last [/]. A text with no [/] has one part, itself. A text with [n]
    characters [/] has [n + 1] parts. The time is linear in the length of
    [text]. *)
