(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_origins
open Sinter_identifiers
open Sinter_inline_citations

type kind =
  | Tag_line of {
      tag_text : Tag_text.t;
      first_line : int;
      last_line : int;
      result : Tag_line.line_result;
    }
  | Link of { source : Source.t; link : Inline_citation.link }

type t = { kind : kind; text : Source.t; start : int }

let rec after_spaces_and_tabs text place =
  match Option.map Uchar.to_int (Text.get text place) with
  | Some (0x20 | 0x09) -> after_spaces_and_tabs text (place + 1)
  | _ -> place

let tag_line_text tag_text first_line last_line =
  let text = Tag_text.text tag_text in
  let runs =
    List.filter_map
      (fun k ->
        Option.map
          (fun (run : Text.run) ->
            if k = first_line then run
            else
              { run with from = after_spaces_and_tabs text (run.from + 1) - 1 })
          (Tag_text.line tag_text k))
      (List.init (last_line - first_line + 1) (fun i -> first_line + i))
  in
  let source = Tag_text.source tag_text in
  Option.value ~default:source (Source.join source runs)

let of_tag_text binding tag_text =
  List.map
    (fun ({ first_line; last_line; result } : Tag_line.input) ->
      let text = tag_line_text tag_text first_line last_line in
      let start =
        match result with
        | Tag_line.Not_a_tag_line -> 0
        | _ -> after_spaces_and_tabs (Source.text text) 1 - 1
      in
      {
        kind = Tag_line { tag_text; first_line; last_line; result };
        text;
        start;
      })
    (Tag_line.read binding (Tag_text.text tag_text))

let of_links binding source =
  List.map
    (fun (link : Inline_citation.link) ->
      {
        kind = Link { source; link };
        text = Option.value ~default:source (Source.sub source link.run);
        start = 0;
      })
    (Inline_citation.read binding (Source.text source))

let kind input = input.kind

let accepted input =
  match input.kind with
  | Tag_line { result = Tag_line.Valid _; _ } -> true
  | Link { link = { result = Inline_citation.Valid _; _ }; _ } -> true
  | Tag_line _ | Link _ -> false

let text input = input.text

let origin_run input =
  Source.origin_run input.text
    { from = input.start; until = Text.length (Source.text input.text) }

let origin_position input =
  Option.bind (origin_run input) (fun (run : Text.run) ->
      Result.to_option
        (Lines.character_position (Source.file input.text) (run.from + 1)))

let file_lines lines input =
  match input.kind with
  | Tag_line { tag_text; first_line; last_line; _ } ->
      List.filter_map
        (fun k -> File_lines.of_tag_text_line lines tag_text k)
        (List.init (last_line - first_line + 1) (fun i -> first_line + i))
  | Link { source; link } ->
      File_lines.of_origin lines
        (Option.value ~default:[] (Source.origin source link.run))
