(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Valid paths, as the design [files=v1] defines them.

    A valid path is a text that matches the production [path]: one or more file
    names, with [/] between each two of them. A file name is a text that is not
    empty, that holds no [/] and no U+0000, and that is not [.] or [..]. The
    parts of a text are the texts that its [/] characters separate, in order,
    with numbers from 1: part 1 is the text before the first [/], and the last
    part is the text after the last [/]. *)

type t
(** A valid path. *)

type error =
  | Empty_part of int
      (** part [k] is the empty text: the text is empty, starts with [/], ends
          with [/], or holds two [/] together *)
  | Dot_part of int  (** part [k] is [.] or [..] *)
  | Null_character of int  (** part [k] holds U+0000 *)

val of_text : Sinter_text.Text.t -> (t, error) result
(** [of_text text] is [Ok path] when [text] is a valid path, and [path] then
    holds [text]. It is [Error] when [text] is not a valid path, with the fault
    of the part with the lowest number that is not a file name. The time is
    linear in the length of [text]. *)

val to_text : t -> Sinter_text.Text.t
(** [to_text path] is the text of [path]. *)

val file_names : t -> Sinter_text.Text.t list
(** [file_names path] is the file names of [path], in the order of their
    numbers: the parts of the text of [path]. *)
