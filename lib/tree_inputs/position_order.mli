(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The order of positions, as the term [position-order] of the design
    [documents=v1] defines it. *)

open Sinter_text

val compare : Lines.position -> Lines.position -> int
(** [compare p q] is negative when [p] comes before [q], positive when [q] comes
    before [p], and [0] when neither comes before the other. A position comes
    before another position when, and only when, its line number is less than
    the line number of the other, or the two line numbers are the same and its
    column is less than the column of the other. *)
