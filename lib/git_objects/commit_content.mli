(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The tree and the named commits of a commit object, from its content, as the
    term [commit] of the design [changes=v1] defines them.

    The content of a commit object is a byte sequence, an OCaml [string]: lines
    of a header, each ended by the byte 0x0A, then, when there is one, an empty
    line and the message. Line 1 is [tree], the byte 0x20, and the object id of
    the git tree object of the commit in hex digits. With k the greatest whole
    number such that each of the lines 2 to k + 1 starts with [parent] and the
    byte 0x20, the parent lines are these lines. Each parent line is [parent],
    the byte 0x20, and an object id in hex digits. No other line names a parent.
*)

type t = {
  tree : Object_id.t;  (** the object id of the git tree object of the commit *)
  named : Object_id.t list;
      (** the object ids of the parent lines, in the order of the lines, each as
          often as a line names it *)
}

type error =
  | Malformed_tree_line
      (** line 1 is not [tree], the byte 0x20, the object id in hex digits, and
          the byte 0x0A *)
  | Malformed_parent_line of int
      (** this line, from 2, is a parent line that is not [parent], the byte
          0x20, an object id in hex digits, and the byte 0x0A *)

val parse : Object_id.format -> string -> (t, error) result
(** [parse format content] is the tree and the named commits of the commit
    object whose content is [content], with object ids in [format]. It reads
    only line 1 and the parent lines. It gives [Error] when one of these lines
    is not in its form, with the first such line. The time is linear in the
    length of the lines that it reads. *)
