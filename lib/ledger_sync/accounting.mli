(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Accounted lines, as the term [accounted-line] of the design [ledger=v1]
    defines it.

    A git tree object accounts for a line of a chunk when, and only when, one of
    its lines is that line, or the object of one of its lines has the member
    [kind] with the value [void] and the member [dropped] with the value of the
    member [id] of the JSON value of that line. A line is a byte sequence, an
    OCaml [string]. *)

open Sinter_ledger_trees

type t
(** The lines of a git tree object, and the values of [dropped] of its voids. *)

val of_tree : Ledger_tree.t -> t
(** [of_tree tree] is the lines and the values of [dropped] of [tree], whether
    [tree] is newer, a valid ledger tree, or neither. The time is linear in the
    length of the lines of [tree]. *)

val accounts : t -> string -> bool
(** [accounts accounting line] is [true] when, and only when, the git tree
    object of [accounting] accounts for [line], whatever bytes [line] holds. The
    time is linear in the length of [line]. *)
