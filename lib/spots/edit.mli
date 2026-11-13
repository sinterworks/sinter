(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Edits, as the design [findings=v1] defines them.

    An edit in a tree is a spot in the tree that has a span, together with a
    text, the new text of the edit. The span of the edit is the span of its
    spot. *)

open Sinter_text

type t
(** An edit. *)

type error = No_span  (** the spot has no span *)

val make : Spot.t -> Text.t -> (t, error) result
(** [make spot new_text] is [Ok edit] when [spot] has a span, and [edit] is then
    the edit of [spot] with the new text [new_text]. It is [Error No_span]
    otherwise. *)

val spot : t -> Spot.t
(** [spot edit] is the spot of [edit]. *)

val span : t -> Text.run
(** [span edit] is the span of [edit]. *)

val new_text : t -> Text.t
(** [new_text edit] is the new text of [edit]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the spots of [a] and [b] are
    equal as {!Spot.equal} decides, and their new texts are the same text. *)
