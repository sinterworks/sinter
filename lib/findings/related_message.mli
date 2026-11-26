(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Related messages, as the design [findings=v1] defines them.

    A related message of a finding is a message, alone or together with a spot
    in a tree, which can be another tree than the tree of the finding, that
    helps to explain the finding. Two related messages are the same when they
    have the same message and either no spot or the same spot in the same tree.
*)

open Sinter_spots

type t
(** A related message. *)

val make : Message.t -> Spot.t option -> t
(** [make message spot] is the related message of [message], with [spot] when
    [spot] is not [None]. The tree of the spot is the tree of the spot. *)

val message : t -> Message.t
(** [message related] is the message of [related]. *)

val spot : t -> Spot.t option
(** [spot related] is the spot of [related], or [None] when it has no spot. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the messages of [a] and [b] are
    the same text, and either both have no spot or their spots are equal as
    {!Spot.equal} decides. *)
