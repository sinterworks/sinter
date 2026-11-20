(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Marks of spots, as the design [findings=v1] defines them.

    Let S be a spot with a span in a tree, and let b be the boundary where the
    span of S starts. When b is a boundary of no line, S has no mark. Otherwise,
    let L be the line of which b is a boundary. A mark of S is a spot M in the
    tree of S and a message. M has the valid path of S, and it has a span, which
    starts and ends at boundaries of the span of S and at boundaries of L. *)

open Sinter_text
open Sinter_spots

type t
(** A mark of a spot. *)

type error =
  | No_span  (** the spot has no span *)
  | No_line
      (** the boundary where the span of the spot starts is a boundary of no
          line *)
  | Not_a_spot of Spot.error
      (** the tree of the spot has no spot with the valid path of the spot and
          the span [run], and {!Spot.of_run} gives this error *)
  | Outside
      (** the run does not start and end at boundaries of the span of the spot
          and at boundaries of the line *)

val make : Spot.t -> Text.run -> Message.t -> (t, error) result
(** [make spot run message] is [Ok mark] when the spot in the tree of [spot]
    with the valid path of [spot] and the span [run], with [message], is a mark
    of [spot], and [mark] is then that mark of [spot]. It is [Error] otherwise,
    with the first of these faults that holds: [No_span], [No_line],
    [Not_a_spot], [Outside]. *)

val marked : t -> Spot.t
(** [marked mark] is the spot of which [mark] is a mark. *)

val spot : t -> Spot.t
(** [spot mark] is the spot of [mark]. *)

val message : t -> Message.t
(** [message mark] is the message of [mark]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, the spots that [a] and [b] mark
    are equal, their spots are equal, as {!Spot.equal} decides, and their
    messages are the same text. *)
