(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Test-vector file names, as the term [test-vector-file-name] of the design
    [data-forms=v1] defines them. *)

open Sinter_text

val of_design : Text.t -> Text.t
(** [of_design x] is the test-vector file name of the name [x] of a design
    alone: the text [x], then [.test-vectors.jsonl], such as
    [a.test-vectors.jsonl] for [a]. The time is linear in the length of [x]. *)

val of_specification : Text.t -> Text.t -> Text.t
(** [of_specification x y] is the test-vector file name of the name [x] of a
    design and the name [y] of a specification of that design: the text [x],
    then [.], then the text [y], then [.test-vectors.jsonl], such as
    [a.b.test-vectors.jsonl] for [a] and [b]. The time is linear in the lengths
    of [x] and [y]. *)
