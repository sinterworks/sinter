(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_identifiers
open Sinter_origins

type t = { first_line : int; last_line : int }
type line = Tag | Continuation | Blank | Prose

let kinds binding tag_text =
  let text = Tag_text.text tag_text in
  let lines = Array.of_list (Lines.all (Lines.of_text text)) in
  let kinds =
    Array.map
      (fun run ->
        if
          File_lines.is_blank
            (Option.value ~default:Text.empty (Text.sub text run))
        then Blank
        else Prose)
      lines
  in
  List.iter
    (fun (input : Tag_line.input) ->
      for k = input.first_line + 1 to input.last_line do
        kinds.(k - 1) <- Continuation
      done;
      match input.result with
      | Tag_line.Not_a_tag_line -> ()
      | _ -> kinds.(input.first_line - 1) <- Tag)
    (Tag_line.read binding text);
  kinds

let of_tag_text binding tag_text =
  let kinds = kinds binding tag_text in
  let count = Array.length kinds in
  let rec stretch k tags =
    if k >= count then k
    else
      match kinds.(k) with
      | Tag when tags -> stretch (k + 1) true
      | Continuation -> stretch (k + 1) tags
      | Prose -> stretch (k + 1) false
      | Tag | Blank -> k
  in
  let rec blocks k acc =
    if k >= count then List.rev acc
    else if kinds.(k) = Tag then
      let last = stretch k true in
      blocks last ({ first_line = k + 1; last_line = last } :: acc)
    else blocks (k + 1) acc
  in
  blocks 0 []
