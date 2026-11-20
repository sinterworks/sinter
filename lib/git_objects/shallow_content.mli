(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The commits that the file [shallow] of a git folder names, from its content,
    as the term [commit] of the design [changes=v1] gives them. *)

type error =
  | Malformed_line of int
      (** this line, from 1, is not an object id in hex digits then the byte
          0x0A, or it is the last bytes of the content with no byte 0x0A after
          them *)

val parse : Object_id.format -> string -> (Object_id.t list, error) result
(** [parse format content] is the object ids that the content [content] of the
    file [shallow] names, with object ids in [format], in the order of its
    lines, when each line is an object id in hex digits then the byte 0x0A. The
    empty content gives [Ok []]. It gives [Error] with the first line that is
    not in this form. The time is linear in the length of [content]. *)
