(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

let start_line lines boundary =
  match Lines.span lines { from = boundary; until = boundary } with
  | Ok (start, _) -> start.line
  | Error _ -> 1

let run_lines lines (r : Text.run) =
  let text = Lines.text lines in
  match Text.sub text r with
  | None -> None
  | Some _ ->
      let last = start_line lines r.until in
      let rec collect k acc =
        match Lines.line lines k with
        | Some (line : Text.run) when k <= last ->
            let from = max r.from line.from
            and until = min r.until line.until in
            let acc =
              if from < until then { Text.from; until } :: acc
              else if
                line.from = line.until && r.from < line.from
                && line.from < r.until
              then line :: acc
              else acc
            in
            collect (k + 1) acc
        | _ -> List.rev acc
      in
      Some (collect (start_line lines r.from) [])

let is_space_or_tab c = Uchar.to_int c = 0x20 || Uchar.to_int c = 0x09

let skip_spaces text (run : Text.run) =
  let rec skip from =
    match Text.get text (from + 1) with
    | Some c when from < run.until && is_space_or_tab c -> skip (from + 1)
    | _ -> from
  in
  { run with from = skip run.from }

let starts_with text (run : Text.run) sigil =
  let n = Text.length sigil in
  n <= run.until - run.from
  &&
  let rec same k =
    k > n || (Text.get text (run.from + k) = Text.get sigil k && same (k + 1))
  in
  same 1

let ends_with text (run : Text.run) sigil =
  let n = Text.length sigil in
  n <= run.until - run.from
  &&
  let rec same k =
    k > n
    || (Text.get text (run.until - n + k) = Text.get sigil k && same (k + 1))
  in
  same 1

let longest text run candidates =
  List.fold_left
    (fun best (sigil, value) ->
      if starts_with text run sigil then
        match best with
        | Some (b, _) when Text.length b >= Text.length sigil -> best
        | _ -> Some (sigil, value)
      else best)
    None candidates

let drop_start (run : Text.run) sigil =
  { run with from = run.from + Text.length sigil }

let drop_end text (run : Text.run) closing =
  if ends_with text run closing then
    { run with until = run.until - Text.length closing }
  else run

type kind = Line_comment | Block_comment of Text.t | No_sigil

let first_line (sigils : Comment_sigils.t) text run =
  let run = skip_spaces text run in
  let candidates =
    List.map (fun sigil -> (sigil, Line_comment)) sigils.line
    @ List.map
        (fun (opening, closing) -> (opening, Block_comment closing))
        sigils.block
  in
  match longest text run candidates with
  | None -> (No_sigil, run)
  | Some (sigil, kind) -> (kind, drop_start run sigil)

type other = Done of Text.run | Bare of Text.run

let drop_longest text run sigils =
  Option.map
    (fun (sigil, ()) -> drop_start run sigil)
    (longest text run (List.map (fun sigil -> (sigil, ())) sigils))

let other_line (sigils : Comment_sigils.t) text ~last kind run =
  match kind with
  | Block_comment closing -> (
      let run = if last then drop_end text run closing else run in
      match drop_longest text (skip_spaces text run) sigils.inner with
      | Some rest -> Done rest
      | None -> Bare run)
  | Line_comment ->
      let run = skip_spaces text run in
      Done (Option.value ~default:run (drop_longest text run sigils.line))
  | No_sigil -> Bare run

let length (run : Text.run) = run.until - run.from

let common_start text (a : Text.run) (b : Text.run) limit =
  let rec common k =
    if
      k < limit
      && Text.get text (a.from + k + 1) = Text.get text (b.from + k + 1)
    then common (k + 1)
    else k
  in
  common 0

let margin text bare =
  List.fold_left
    (fun margin (run : Text.run) ->
      let indent = { run with until = (skip_spaces text run).from } in
      if indent.until = run.until then margin
      else
        match margin with
        | None -> Some indent
        | Some (m : Text.run) ->
            let common =
              common_start text m indent (min (length m) (length indent))
            in
            Some { m with until = m.from + common })
    None bare

(* @satisfies documents#give-extents=v1
   A bare line loses only the margin that the bare lines of its comment node
   share, or its spaces and tabs when it does not start with that margin, so
   its file line starts at its own indentation past the margin. *)
let unbare text others =
  let bare =
    List.filter_map (function Bare r -> Some r | Done _ -> None) others
  in
  let margin = margin text bare in
  List.map
    (function
      | Done run -> run
      | Bare run -> (
          match margin with
          | None -> run
          | Some m ->
              if
                common_start text m run (min (length m) (length run)) = length m
              then { run with from = run.from + length m }
              else skip_spaces text run))
    others

let of_node sigils lines r =
  let text = Lines.text lines in
  Option.map
    (function
      | [] -> []
      | first :: rest ->
          let kind, first = first_line sigils text first in
          let first =
            match (kind, rest) with
            | Block_comment closing, [] -> drop_end text first closing
            | _ -> first
          in
          let rec others = function
            | [] -> []
            | [ line ] -> [ other_line sigils text ~last:true kind line ]
            | line :: more ->
                other_line sigils text ~last:false kind line :: others more
          in
          first :: unbare text (others rest))
    (run_lines lines r)
