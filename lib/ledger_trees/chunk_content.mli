(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The lines of the content of a chunk, as the terms [chunk] and [newer-line]
    and the schema [valid-ledger-tree] of the design [ledger=v1] give them. A
    content and a line are byte sequences, OCaml [string]s. *)

open Sinter_ledger_lines

type t = {
  lines : string list;
      (** the lines of the content, in their order: the byte sequences that
          remain when the content is cut right after each byte 0x0A, without an
          empty byte sequence at the end *)
  newer : bool;
      (** [true] when, and only when, one of [lines] is a newer line *)
  ledger_lines : Ledger_line.t list option;
      (** [Some ledger_lines] when [lines] is not empty and each of [lines] is a
          ledger line, with [ledger_lines] the ledger lines of [lines] in their
          order; [None] otherwise *)
}

val read : ?entry_id:(Sinter_json_lines.Json_line.t -> string) -> string -> t
(** [read ~entry_id content] is the lines of [content], with each ledger line as
    {!Ledger_line.of_line_object} [~entry_id] gives it. The time is linear in
    the length of [content], plus the time of [entry_id]. *)
