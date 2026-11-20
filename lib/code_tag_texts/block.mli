(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The blocks of a tag text, as the term [tag-text-block] of the design
    [documents=v1] defines them.

    A block starts at each line of the tag text that is a tag line and that is
    the first line of the tag text or comes right after a line that is neither a
    tag line nor a continuation line. The lines of the block are that line; each
    line right after it, one after another, that is a tag line or a continuation
    line; and then its trailing prose: each line right after these, one after
    another, that is not a tag line. *)

open Sinter_identifiers
open Sinter_origins

type t = { first_line : int; last_line : int }
(** A block: the lines of the tag text with the line numbers from [first_line]
    to [last_line]. *)

val of_tag_text : Binding.t -> Tag_text.t -> t list
(** [of_tag_text binding tag_text] is the blocks of [tag_text], in the order of
    their first lines. A line is a tag line when its first character after the
    spaces and tabs at its start is [@], and a continuation line when
    {!Tag_line.read} under [binding] puts it in an input after the first line of
    that input. No two blocks share a line. The time is linear in the length of
    the text of [tag_text]. *)
