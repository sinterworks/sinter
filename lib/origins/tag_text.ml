(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = { source : Source.t; joined : Text.run array; lines : Lines.t }

let line_feed = Uchar.of_int 0x0A

let has_line_feed text (run : Text.run) =
  let rec scan place =
    place <= run.until
    && (Text.get text place = Some line_feed || scan (place + 1))
  in
  scan (run.from + 1)

let rec ordered (previous : Text.run option) = function
  | [] -> true
  | (run : Text.run) :: rest -> (
      match previous with
      | Some p when run.from < p.until -> false
      | _ -> ordered (Some run) rest)

let make file runs =
  let text = Lines.text file in
  if
    ordered None runs
    && List.for_all
         (fun (run : Text.run) ->
           Option.is_some (Text.sub text run) && not (has_line_feed text run))
         runs
  then
    Option.map
      (fun source ->
        {
          source;
          joined = Array.of_list runs;
          lines = Lines.of_text (Source.text source);
        })
      (Source.join (Source.of_file file) runs)
  else None

let text tag_text = Source.text tag_text.source
let source tag_text = tag_text.source
let joined tag_text = Array.to_list tag_text.joined
let line_count tag_text = Lines.count tag_text.lines
let line tag_text k = Lines.line tag_text.lines k

let joined_line tag_text k =
  if k >= 1 && k <= line_count tag_text then Some tag_text.joined.(k - 1)
  else None
