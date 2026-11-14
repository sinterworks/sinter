(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The comment sigils of the descriptor of a pack, as the term [comment-sigil]
    of the design [packs=v1] gives them, as plain values that a caller gives. *)

open Sinter_text

type t = {
  line : Text.t list;
      (** the line sigils, each of which opens a comment that ends at the end of
          its line, such as [//], in their order *)
  block : (Text.t * Text.t) list;
      (** the block pairs, each an opening sigil and a closing sigil, such as
          [/*] and [*/], in their order *)
  inner : Text.t list;
      (** the inner sigils, each of which can start a line of a block comment
          after its first line, such as [*], in their order *)
}
(** The comment sigils of one descriptor. Any texts are accepted. *)
