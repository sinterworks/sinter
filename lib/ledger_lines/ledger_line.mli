(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The lines that a valid ledger tree can hold, as conditions 4, 5, and 6 of
    the term [ledger-validity] of the design [ledger=v1] give them.

    A ledger line is the canonical line of a line object, the object of the
    line, that has the member [id] with a string, the member [kind] with a
    string, the member [v] with the integer 1, and the member [seq] with an
    integer of 1 or more, and whose [id] is its entry id ({!Entry_id}). A text
    is its UTF-8 encoding, an OCaml [string]. *)

open Sinter_json_lines

type t
(** A ledger line. *)

val of_line_object : Json_line.t -> t option
(** [of_line_object line_object] is the ledger line whose object is
    [line_object], or [None] when [line_object] is not the object of a ledger
    line. The time is linear in the length of the canonical line of
    [line_object]. *)

val bytes : t -> string
(** [bytes line] is the canonical line of the object of [line]: its canonical
    byte sequence, then the byte 0x0A. *)

val line_object : t -> Json_line.t
(** [line_object line] is the object of [line], with every member that it has.
*)

val id : t -> string
(** [id line] is the value of the member [id] of the object of [line]: its entry
    id. *)

val kind : t -> string
(** [kind line] is the value of the member [kind] of the object of [line]. *)

val seq : t -> int
(** [seq line] is the value of the member [seq] of the object of [line], 1 or
    more. *)
