(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The messages of commits and their texts, as the terms [commit] and
    [message-text] of the design [changes=v1] define them. The content of a
    commit object is a byte sequence, an OCaml [string]. *)

val message : string -> string
(** [message content] is the message of a commit whose commit object has the
    content [content]: the bytes after the first two bytes 0x0A that follow one
    another, or the empty byte sequence when [content] holds no two such bytes.
    The time is linear in the length of [content]. *)

val text : string -> Sinter_text.Text.t option
(** [text content] is the text of the message of a commit whose commit object
    has the content [content]: [Some t] when {!message} of [content] is valid
    UTF-8, with [t] the text of it, a U+FEFF at its start and each carriage
    return kept; [None] when it is not valid UTF-8. The header [encoding] of the
    commit object has no effect. *)
