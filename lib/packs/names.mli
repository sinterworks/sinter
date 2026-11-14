(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The names of pack paths, as byte sequences. *)

val max_length : int
(** [max_length] is 255, the greatest number of characters of a pack path. *)

val is_name : string -> bool
(** [is_name bytes] is [true] when, and only when, [bytes] is the UTF-8 encoding
    of a text that matches the production [pack-path-name]: it is not empty, it
    is not [.] or [..], and each of its bytes is from 0x20 to 0x7E and is not
    the byte of [/] or of [\ ]. *)
