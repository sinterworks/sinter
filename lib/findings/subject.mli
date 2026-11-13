(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Subjects of findings, as the design [findings=v1] defines them.

    The subject of a finding is a text that names what the finding is about. It
    matches the production [subject] of the form of [@ack] lines of the design
    [identifiers=v1], and it holds no line feed. So it is not empty, and its
    first and its last character are not a space or a tab. A carriage return and
    U+0000 are characters that a subject can hold. *)

open Sinter_text

type t
(** A subject of a finding. *)

type error =
  | Empty  (** the text is empty *)
  | Blank_start  (** the first character of the text is a space or a tab *)
  | Blank_end  (** the last character of the text is a space or a tab *)
  | Line_feed of { place : int }  (** the text holds a line feed at [place] *)

val of_text : Text.t -> (t, error) result
(** [of_text text] is [Ok subject] when [text] is a subject of a finding, and
    [subject] then holds [text]. It is [Error] otherwise, with the first of
    these faults that holds: [Empty], [Blank_start], [Blank_end], and
    [Line_feed] for the lowest place of [text] that holds a line feed. *)

val to_text : t -> Text.t
(** [to_text subject] is the text of [subject]. *)
