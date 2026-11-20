(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Chunk paths and the modes of chunks, as the terms [chunk-path] and
    [ledger-validity] of the design [ledger=v1] give them. A byte path and a
    mode are byte sequences, OCaml [string]s. *)

val chunk_id : string -> string option
(** [chunk_id bytes] is [Some id] when [bytes] is the UTF-8 encoding of a chunk
    path, a text [entries/<hh>/<id>.jsonl] in which [<id>] is an entry id as
    {!Sinter_ledger_lines.Entry_id.is_entry_id} gives it and [<hh>] is its two
    hex digits after [e-]; [id] is then [<id>], the chunk path after its first
    11 characters and without [.jsonl]. It is [None] otherwise. *)

val is_hex_folder : string -> bool
(** [is_hex_folder name] is [true] when, and only when, [name] is two hex
    digits. *)

val is_chunk_mode : string -> bool
(** [is_chunk_mode mode] is [true] when, and only when, [mode] is one or more of
    the digits [0] to [7] and writes, in base 8, the number that [100644]
    writes, such as [100644] and [0100644]. *)
