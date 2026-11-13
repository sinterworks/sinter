(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of the design [changes=v1], computed apart from the libraries
    under test, by a direct reading of each term on small inputs, and the forms
    in which the vectors of the design write their values. *)

(** {1 Branch names} *)

val is_branch_name : string -> bool
(** [is_branch_name text] holds when the text whose UTF-8 encoding is [text]
    meets each of the eight conditions of the term [branch-name]. *)

val branch_name_faults : string -> int list
(** [branch_name_faults text] is the numbers of the conditions of the term
    [branch-name] that the text whose UTF-8 encoding is [text] does not meet, in
    increasing order. *)

val branch_name_gen : string QCheck2.Gen.t
(** The UTF-8 encodings of texts of up to eight pieces, drawn from the
    characters and the runs at the edges of the conditions of the term
    [branch-name]. *)
