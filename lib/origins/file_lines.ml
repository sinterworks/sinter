(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type kind = Markdown | Code
type t = { kind : kind; lines : Text.run array }

let by_boundaries (a : Text.run) (b : Text.run) =
  match compare a.from b.from with 0 -> compare a.until b.until | c -> c

let sorted kind runs =
  let lines = Array.of_list runs in
  Array.stable_sort by_boundaries lines;
  { kind; lines }

let of_markdown_lines lines = sorted Markdown lines

let of_tag_texts tag_texts =
  sorted Code (List.concat_map Tag_text.joined tag_texts)

let all file_lines = Array.to_list file_lines.lines

let first_index lines satisfies =
  let rec search low high =
    if low >= high then low
    else
      let middle = (low + high) / 2 in
      if satisfies lines.(middle) then search low middle
      else search (middle + 1) high
  in
  search 0 (Array.length lines)

let of_tag_text_line file_lines tag_text k =
  match Tag_text.joined_line tag_text k with
  | None -> None
  | Some (run : Text.run) -> (
      let lines = file_lines.lines in
      match file_lines.kind with
      | Code ->
          let i = first_index lines (fun line -> by_boundaries line run >= 0) in
          if i < Array.length lines && by_boundaries lines.(i) run = 0 then
            Some run
          else None
      | Markdown ->
          let i =
            first_index lines (fun (line : Text.run) -> line.from > run.from)
          in
          if i > 0 && lines.(i - 1).until >= run.until then Some lines.(i - 1)
          else None)

let of_origin file_lines origin =
  let lines = file_lines.lines in
  let count = Array.length lines in
  let rec take i (o : Text.run) acc =
    if i < count && lines.(i).from < o.until then
      let acc =
        match acc with
        | last :: _ when last = i -> acc
        | _ when lines.(i).from >= lines.(i).until -> acc
        | _ -> i :: acc
      in
      take (i + 1) o acc
    else acc
  in
  List.rev_map
    (fun i -> lines.(i))
    (List.fold_left
       (fun acc (o : Text.run) ->
         if o.from >= o.until then acc
         else
           take
             (first_index lines (fun (line : Text.run) -> line.until > o.from))
             o acc)
       [] origin)

let is_blank text =
  let rec scan place =
    match Text.get text place with
    | None -> true
    | Some c -> (
        match Uchar.to_int c with 0x20 | 0x09 -> scan (place + 1) | _ -> false)
  in
  scan 1
