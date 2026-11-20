(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Messages, as the design [findings=v1] defines them.

    A message is a text for people that is not empty and that holds no line feed
    and no carriage return. The program that gives a message chooses its words.
*)

open Sinter_text

type t
(** A message. *)

type error =
  | Empty  (** the text is empty *)
  | Line_break of { place : int }
      (** the text holds a line feed or a carriage return at [place] *)

val of_text : Text.t -> (t, error) result
(** [of_text text] is [Ok message] when [text] is a message, and [message] then
    holds [text]. It is [Error Empty] when [text] is empty, and otherwise
    [Error (Line_break {place})] for the lowest place of [text] that holds a
    line feed or a carriage return. *)

val to_text : t -> Text.t
(** [to_text message] is the text of [message]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the texts of [a] and [b] are the
    same text. *)
