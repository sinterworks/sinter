(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_spots

type t = { marked : Spot.t; spot : Spot.t; message : Message.t }
type error = No_span | No_line | Not_a_spot of Spot.error | Outside

let inside (span : Text.run) (line : Text.run) (run : Text.run) =
  run.from >= span.from && run.until <= span.until && run.until <= line.until

(* @satisfies findings#omit-absent-finding-parts=v1
   A spot without a span, or whose span starts at a boundary of no line, has no
   mark, and no spot whose span leaves the span of the spot or that line is a
   mark of it. *)
let make marked (run : Text.run) message =
  match (Spot.span marked, Spot.start_line marked) with
  | None, _ -> Error No_span
  | Some _, None -> Error No_line
  | Some span, Some line -> (
      match Spot.of_run (Spot.tree marked) (Spot.path marked) run with
      | Error error -> Error (Not_a_spot error)
      | Ok spot ->
          if inside span line run then Ok { marked; spot; message }
          else Error Outside)

let marked mark = mark.marked
let spot mark = mark.spot
let message mark = mark.message

let equal a b =
  Spot.equal a.marked b.marked
  && Spot.equal a.spot b.spot
  && Message.equal a.message b.message
