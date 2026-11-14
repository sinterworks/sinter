(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Pack paths, as the design [packs=v1] defines them.

    A pack path is a text of at most 255 characters that matches the production
    [pack-path]: one or more names, with [/] between each two of them. Each name
    holds only the characters from U+0020 to U+007E other than [/] and [\ ], is
    not empty, and is not [.] or [..]. *)

val is_pack_path : Sinter_text.Text.t -> bool
(** [is_pack_path text] is [true] when, and only when, [text] is a pack path. *)
