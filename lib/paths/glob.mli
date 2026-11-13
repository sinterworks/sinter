(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Valid globs, and the valid paths that fit them, as the design [files=v1]
    defines them.

    A valid glob is a text that matches the production [glob]: one or more glob
    segments, with [/] between each two of them, and maybe a [/] at the end. A
    glob segment is [**], or a text that is not empty, that holds no [/], [?],
    [{], [}], a square bracket, or a backslash, that holds no two [*] together,
    and that is not [.] or [..]. The parts of a text are the texts that its [/]
    characters separate, in order, with numbers from 1: part 1 is the text
    before the first [/], and the last part is the text after the last [/]. *)

type t
(** A valid glob. *)

type error =
  | Empty_part of int
      (** part [k] is the empty text, and it is part 1 or not the last part: the
          text is empty, starts with [/], or holds two [/] together *)
  | Dot_part of int  (** part [k] is [.] or [..] *)
  | Forbidden_character of int
      (** part [k] holds [?], [{], [}], a square bracket, or a backslash *)
  | Adjacent_stars of int
      (** part [k] holds two [*] together and is not [**]; it holds none of the
          characters of [Forbidden_character] *)

val of_text : Sinter_text.Text.t -> (t, error) result
(** [of_text text] is [Ok glob] when [text] is a valid glob, and [glob] then
    holds [text]. It is [Error] when [text] is not a valid glob, with the fault
    of the part with the lowest number that has a fault. The time is linear in
    the length of [text]. *)

val to_text : t -> Sinter_text.Text.t
(** [to_text glob] is the text of [glob]. *)

val segments : t -> Sinter_text.Text.t list
(** [segments glob] is the glob segments of [glob], in the order of their
    numbers: the parts of the text of [glob], except that the empty last part of
    a text that ends with [/] is the glob segment [**]. *)

val fits : t -> Path.t -> bool
(** [fits glob path] is [true] when [path] fits [glob], and [false] when [path]
    does not fit [glob]. The time is at most proportional to the length of the
    text of [glob] times the length of the text of [path]. *)
