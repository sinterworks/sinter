(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree

type located = {
  run : Text.run;
  start : Lines.position;
  after : Lines.position;
  line : Text.run option;
}

type t = {
  tree : Tree.t;
  path : Path.t;
  text : Text.t option;
  span : located option;
}

type error =
  | No_file
  | Not_utf_8
  | Not_a_span
  | Inside_line_ending
  | No_boundary
  | Reversed

let of_file tree path =
  match Tree.text tree path with
  | Ok text -> Ok { tree; path; text = Some text; span = None }
  | Error (Not_utf_8 _) -> Ok { tree; path; text = None; span = None }
  | Error No_file -> Error No_file

let lines tree path =
  match Tree.lines tree path with
  | Ok lines -> Ok lines
  | Error No_file -> Error No_file
  | Error (Not_utf_8 _) -> Error Not_utf_8

let line_feed = Uchar.of_int 0x0A
let carriage_return = Uchar.of_int 0x0D

let inside_line_ending text boundary =
  Text.get text boundary = Some carriage_return
  && Text.get text (boundary + 1) = Some line_feed

let empty_run boundary = { Text.from = boundary; until = boundary }

(* @satisfies findings#{give-start-positions=v1, give-positions-after-spots=v1}
   The start position is the position of the boundary where the span starts,
   and the position after the spot is the position of the boundary where the
   span ends, each the start of the empty span at that boundary. *)
let locate lines (run : Text.run) =
  match
    ( Lines.span lines (empty_run run.from),
      Lines.span lines (empty_run run.until) )
  with
  | Ok (start, _), Ok (after, _) when run.from <= run.until ->
      Some { run; start; after; line = Lines.line lines start.line }
  | _ -> None

let of_run tree path run =
  Result.bind (lines tree path) (fun lines ->
      let text = Lines.text lines in
      match locate lines run with
      | None -> Error Not_a_span
      | Some located ->
          if
            inside_line_ending text run.from
            || inside_line_ending text run.until
          then Error Inside_line_ending
          else Ok { tree; path; text = Some text; span = Some located })

(* @satisfies findings#validate-edit-sets=v1
   An edit description describes an edit only when each of its positions is the
   position of a boundary where a span of a spot can start or end: a boundary of
   the line of the position at its column, or, past the last line, the boundary
   where the body ends when that boundary has the position. *)
let boundary lines (position : Lines.position) =
  match Lines.line lines position.line with
  | Some line ->
      if position.column >= 1 && position.column <= line.until - line.from + 1
      then Some (line.from + position.column - 1)
      else None
  | None -> (
      let last = Text.length (Lines.text lines) in
      match Lines.span lines (empty_run last) with
      | Ok (at, _) when at = position -> Some last
      | _ -> None)

let of_positions tree path start after =
  Result.bind (lines tree path) (fun lines ->
      match (boundary lines start, boundary lines after) with
      | Some from, Some until ->
          (* @satisfies findings#validate-edit-sets=v1
             An edit description whose second position names a boundary
             before the boundary of its first position describes no edit. *)
          if from <= until then of_run tree path { from; until }
          else Error Reversed
      | _ -> Error No_boundary)

let tree spot = spot.tree
let path spot = spot.path
let span spot = Option.map (fun located -> located.run) spot.span
let text spot = spot.text

(* @satisfies findings#omit-positions-without-spans=v1
   A spot without a span gives no start position. *)
let start_position spot = Option.map (fun located -> located.start) spot.span

(* @satisfies findings#omit-positions-without-spans=v1
   A spot without a span gives no position after it. *)
let position_after spot = Option.map (fun located -> located.after) spot.span
let start_line spot = Option.bind spot.span (fun located -> located.line)

let equal a b =
  Tree.equal a.tree b.tree
  && Text.equal (Path.to_text a.path) (Path.to_text b.path)
  && span a = span b
