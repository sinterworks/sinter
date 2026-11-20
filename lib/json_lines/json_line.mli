(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Line objects and canonical lines, as the specification [json-lines] of the
    design [data-forms=v1] defines them.

    A scalar is a string, an integer, or a boolean. A flat object is an object
    in which the value of each member is a scalar. A line object is an object in
    which the value of each member is a scalar, an array in which each element
    is a scalar, or an array in which each element is a flat object. The
    canonical line of a line object is its canonical byte sequence, then the
    byte 0x0A. *)

type t = private Json.t
(** A line object. Every value of this type is a line object. *)

val of_json : Json.t -> t option
(** [of_json value] is [Some value] when [value] is a line object, and [None]
    when it is not. It uses no stack space that grows with the depth of [value].
*)

val canonical_line : t -> string
(** [canonical_line line_object] is the canonical line of [line_object]. *)

val read : string -> t option
(** [read bytes] is [Some line_object] when [bytes] is the canonical line of
    [line_object], and [None] for every other byte sequence. It never raises.
    The time is linear in the length of [bytes], and the function uses no stack
    space that grows with the depth of the JSON value that [bytes] holds. *)
