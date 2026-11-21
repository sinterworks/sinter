(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The file [packed-refs] of a git folder, from its content, as the term
    [ref-commit] of the design [changes=v1] gives it. *)

type t
(** The refs of a file [packed-refs]. *)

type error =
  | No_final_line_feed
      (** the content does not end with the byte 0x0A, so its last byte sequence
          has no 0x0A after it *)
  | Repeated_name of string  (** two lines give a ref with this ref name *)

val parse : Sinter_git_objects.Object_id.format -> string -> (t, error) result
(** [parse format content] is the refs of a file [packed-refs] whose content is
    [content], with object ids in [format]. The content is byte sequences, the
    lines, each followed by the byte 0x0A. A line that is an object id in hex
    digits, a space, and a ref name by {!Sinter_ref_names.Ref_name.is_ref_name}
    gives the ref with that ref name, which points to the git object with that
    object id. No other line gives a ref: not a first line that starts with [#],
    not a line that starts with [^], which gives the peeled object of the ref
    before it, and not a line in no such form. The empty content holds no ref.
*)

val find : t -> string -> Sinter_git_objects.Object_id.t option
(** [find refs name] is the object id to which the ref [name] of [refs] points,
    or [None] when [refs] holds no ref with that name. *)
