(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type segment = { start : int; first_place : int; length : int }
type t = { text : Text.t; file : Lines.t; segments : segment array }

let line_feed = Text.of_uchars [ Uchar.of_int 0x0A ]

let is_run text (run : Text.run) =
  0 <= run.from && run.from <= run.until && run.until <= Text.length text

let of_file file =
  let text = Lines.text file in
  let length = Text.length text in
  {
    text;
    file;
    segments =
      (if length = 0 then [||] else [| { start = 0; first_place = 1; length } |]);
  }

let first_index segments satisfies =
  let rec search low high =
    if low >= high then low
    else
      let middle = (low + high) / 2 in
      if satisfies segments.(middle) then search low middle
      else search (middle + 1) high
  in
  search 0 (Array.length segments)

let ending_after boundary s = s.start + s.length > boundary

let pieces source (run : Text.run) =
  if run.from < run.until then
    let first = first_index source.segments (ending_after run.from)
    and stop = first_index source.segments (fun s -> s.start >= run.until) in
    List.init (stop - first) (fun i ->
        let s = source.segments.(first + i) in
        let from = max s.start run.from
        and until = min (s.start + s.length) run.until in
        {
          start = from - run.from;
          first_place = s.first_place + (from - s.start);
          length = until - from;
        })
  else []

let sub source run =
  match Text.sub source.text run with
  | None -> None
  | Some text ->
      Some
        {
          text;
          file = source.file;
          segments = Array.of_list (pieces source run);
        }

let join source runs =
  let rec build offset texts segments = function
    | [] ->
        Some
          {
            text = Text.concat (List.rev texts);
            file = source.file;
            segments = Array.of_list (List.rev segments);
          }
    | (run : Text.run) :: rest -> (
        match Text.sub source.text run with
        | None -> None
        | Some text ->
            let offset, texts =
              match texts with
              | [] -> (offset, texts)
              | _ -> (offset + 1, line_feed :: texts)
            in
            let shifted =
              List.map
                (fun s -> { s with start = s.start + offset })
                (pieces source run)
            in
            build
              (offset + Text.length text)
              (text :: texts)
              (List.rev_append shifted segments)
              rest)
  in
  build 0 [] [] runs

let text source = source.text
let file source = source.file

let place source k =
  let i = first_index source.segments (ending_after (k - 1)) in
  if i < Array.length source.segments && source.segments.(i).start <= k - 1 then
    let s = source.segments.(i) in
    Some (s.first_place + (k - 1 - s.start))
  else None

let merge runs =
  let sorted =
    List.sort (fun (a : Text.run) (b : Text.run) -> compare a.from b.from) runs
  in
  let rec go acc = function
    | [] -> List.rev acc
    | (r : Text.run) :: rest -> (
        match acc with
        | (last : Text.run) :: acc' when r.from <= last.until ->
            go ({ last with until = max last.until r.until } :: acc') rest
        | _ -> go (r :: acc) rest)
  in
  go [] sorted

let origin source run =
  if is_run source.text run then
    Some
      (merge
         (List.map
            (fun s ->
              ({
                 from = s.first_place - 1;
                 until = s.first_place - 1 + s.length;
               }
                : Text.run))
            (pieces source run)))
  else None

let origin_run source run =
  match origin source run with
  | None | Some [] -> None
  | Some (first :: rest) ->
      let last = List.fold_left (fun _ r -> r) first rest in
      Some ({ from = first.from; until = last.until } : Text.run)

let origin_position source run =
  match origin_run source run with
  | None -> None
  | Some r ->
      Result.to_option (Lines.character_position source.file (r.from + 1))
