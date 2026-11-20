(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Ref names, as the term [ref-name] of the design [changes=v1] defines them.

    A ref name is a text, given here as its UTF-8 encoding, an OCaml [string]. A
    byte sequence that is not valid UTF-8, or whose text is not a ref name,
    names no ref. *)

val is_root_name : string -> bool
(** [is_root_name name] is [true] when, and only when, [name] is [HEAD]; or one
    or more of the bytes [A] to [Z] and [_] that end with [_HEAD]; or one of
    [AUTO_MERGE], [BISECT_EXPECTED_REV], [NOTES_MERGE_PARTIAL],
    [NOTES_MERGE_REF], and [MERGE_AUTOSTASH]. *)

val is_ref_name : string -> bool
(** [is_ref_name name] is [true] when, and only when, [name] is valid UTF-8 and
    its text meets each of these rules:

    + it starts with [refs/], or it is a root name by {!is_root_name};
    + it does not end with [/], and it does not hold [//];
    + it does not hold [/.] or [.lock/], and it does not end with [.lock];
    + it does not hold [..] or [@{];
    + it does not end with [.];
    + it holds no character whose code point is from 0 to 31, and none whose
      code point is 127;
    + it holds no space and none of the characters [~], [^], [:], [?], [*],
      [\[], and [\ ].

    So a ref name, as a pathname inside a folder, has no empty part, no part [.]
    or [..], and no byte 0x00, and it does not start with [/]. *)
