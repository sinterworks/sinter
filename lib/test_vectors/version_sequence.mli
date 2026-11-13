(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Version sequences of test-vector sets, as the specification [test-vectors]
    of the design [data-forms=v1] defines them.

    A version is a test-vector set together with a text for each of its groups:
    the text of the forms of that group in that version. A version sequence is a
    finite sequence of versions, from the earliest to the latest, in which the
    numbers and the revisions change by the rules of the design from each
    version to the next. *)

open Sinter_text

type version
(** A version: a test-vector set and one forms text for each of its groups. *)

(** Why a set and a list of forms make no version. *)
type forms_error =
  | Extra_forms of string
      (** The forms name a group that is not a group of the set, or name a group
          a second time. *)
  | Missing_forms of string
      (** The forms name no text for this group of the set. *)

val version :
  Test_vector_set.t -> (string * Text.t) list -> (version, forms_error) result
(** [version set forms] is the version of [set] in which the text of the forms
    of each group [g] is the text that [forms] pairs with [g]. It is
    [Error (Extra_forms g)] for the first element [(g, _)] of [forms], in order,
    whose [g] is not a group of [set] or is the [g] of an earlier element. When
    there is no such element, it is [Error (Missing_forms g)] for the first
    group [g] of [set], in the order of its group lines, that no element of
    [forms] names. *)

val validate : version list -> bool
(** [validate versions] is [true] when [versions], from the earliest to the
    latest, is a version sequence, and [false] when it is not. The empty list
    and a list of one version are version sequences. *)
