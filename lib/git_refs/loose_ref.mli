(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Loose refs in the files format that are regular files, from their contents,
    as the term [ref-commit] of the design [changes=v1] defines them. *)

(** What a ref points to or names, before the type of its git object is known.
*)
type target =
  | Object of Sinter_git_objects.Object_id.t
      (** the ref points to the git object with this object id *)
  | Symbolic of string  (** the ref names the ref with this ref name *)
  | Broken
      (** a broken loose ref: it points to no git object and names no ref *)

val parse : Sinter_git_objects.Object_id.format -> string -> target
(** [parse format content] is the target of a loose ref whose file holds
    [content]: [Object id] when [content] is the object id [id] in hex digits,
    in [format], then the byte 0x0A; [Symbolic name] when [content] is [ref: ],
    then a ref name [name] by {!Sinter_ref_names.Ref_name.is_ref_name}, then the
    byte 0x0A; and [Broken] for every other content, such as one with no final
    0x0A, with spaces before it, with bytes after it, with upper-case hex
    digits, or with a name that is not a ref name. *)
