(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths

let lf = Uchar.of_int 0x0A
let cr = Uchar.of_int 0x0D
let at text place = Text.get text place

let is_char text place c =
  match at text place with Some u -> Uchar.equal u c | None -> false

let ending_at text boundary =
  let place = boundary + 1 in
  if is_char text place lf then Some 1
  else if is_char text place cr then
    if is_char text (place + 1) lf then Some 2 else Some 1
  else None

let markdown_lines text =
  let { Text.from = start; until = stop } = Text.body text in
  let rec scan line_start boundary acc =
    if boundary >= stop then
      if boundary > line_start then
        List.rev ({ Text.from = line_start; until = boundary } :: acc)
      else List.rev acc
    else
      match ending_at text boundary with
      | Some size ->
          scan (boundary + size) (boundary + size)
            ({ Text.from = line_start; until = boundary } :: acc)
      | None -> scan line_start (boundary + 1) acc
  in
  scan start start []

let chars text { Text.from; until } =
  List.init (until - from) (fun k ->
      match at text (from + k + 1) with
      | Some u -> Uchar.to_int u
      | None -> invalid_arg "chars")

let is_wsp c = c = 0x20 || c = 0x09

let front_matter_kind text run =
  match chars text run with
  | a :: b :: c :: rest
    when a = b && b = c && (a = 0x2B || a = 0x2D) && List.for_all is_wsp rest ->
      Some a
  | _ -> None

let front_matter text =
  match markdown_lines text with
  | [] -> None
  | first :: later -> (
      match front_matter_kind text first with
      | None -> None
      | Some kind ->
          let rec find acc = function
            | [] -> None
            | line :: rest ->
                if front_matter_kind text line = Some kind then
                  Some (List.rev (line :: acc))
                else find (line :: acc) rest
          in
          find [ first ] later)

let markdown_run text =
  let length = Text.length text in
  match front_matter text with
  | None -> { Text.from = 0; until = length }
  | Some lines ->
      let last = List.nth lines (List.length lines - 1) in
      let start =
        match ending_at text last.Text.until with
        | Some size -> last.Text.until + size
        | None -> length
      in
      { Text.from = start; until = length }

let markdown_text_lines text =
  let run = markdown_run text in
  List.filter
    (fun line -> line.Text.from >= run.Text.from)
    (markdown_lines text)

let is_blank text run = List.for_all is_wsp (chars text run)

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let path_set texts =
  match Path_set.of_texts (List.map text_of texts) with
  | Error _ -> None
  | Ok set -> (
      match Path_set.validate set with Ok () -> Some set | Error _ -> None)

let read_files binding files =
  let sets = List.map (fun (_, texts) -> path_set texts) binding in
  if List.exists Option.is_none sets then None
  else
    let sets = List.filter_map Fun.id sets in
    let reader path =
      let rec first k = function
        | [] -> None
        | set :: rest ->
            if Path_set.mem set path then Some k else first (k + 1) rest
      in
      first 1 sets
    in
    let edge c = is_wsp (Char.code c) in
    Some
      (List.filter_map
         (fun (path, _) ->
           let n = String.length path in
           if
             String.contains path '\n' || n = 0
             || edge path.[0]
             || edge path.[n - 1]
           then None
           else
             match Path.of_text (text_of path) with
             | Error _ -> None
             | Ok valid -> Option.map (fun k -> (path, k)) (reader valid))
         files)
