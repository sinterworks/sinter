(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_origins
open Sinter_identifiers
open Sinter_tag_inputs
open Sinter_markdown_tag_texts
open Sinter_readings
open Sinter_code_tag_texts
open Sinter_markdown_limits

module By_run = Map.Make (struct
  type t = int * int

  let compare = compare
end)

type content = Markdown of Markdown_file.t | Code of Code_file.t

type holder =
  | Section of Markdown_file.section
  | List_item of Markdown_file.list_item
  | Comment_run of Code_file.comment_run

type tag_text = {
  tag_text : Tag_text.t;
  holder : holder;
  inputs : Input.t list;
}

type t = {
  binding : Binding.t;
  path : Path.t;
  content : content;
  text : Lines.t;
  file_lines : File_lines.t;
  lines : Text.run array;
  numbers : int By_run.t;
  froms : int array;
  untils : int array;
  lowest : int array;
  highest : int array;
  not_blank : int array;
  tag_texts : tag_text list;
  links : Input.t list;
  first_code_character : int option;
}

let markdown_tag_texts file =
  let sections =
    List.filter_map
      (fun (section : Markdown_file.section) ->
        Option.map
          (fun (p : Markdown_file.paragraph) -> (p, Section section))
          section.first_paragraph)
      (Markdown_file.sections file)
  in
  let items =
    List.filter_map
      (fun (item : Markdown_file.list_item) ->
        Option.map
          (fun (p : Markdown_file.paragraph) -> (p, List_item item))
          item.first_paragraph)
      (Markdown_file.list_items file)
  in
  List.map snd
    (List.stable_sort
       (fun ((a : Markdown_file.paragraph), _)
            ((b : Markdown_file.paragraph), _) ->
         Int.compare a.lines.first b.lines.first)
       (List.map
          (fun ((p : Markdown_file.paragraph), holder) ->
            (p, (p.tag_text, holder)))
          (sections @ items)))

let code_tag_texts file =
  List.filter_map
    (fun (run : Code_file.comment_run) ->
      Option.map (fun tag_text -> (tag_text, Comment_run run)) run.tag_text)
    (Code_file.comment_runs file)

let first_code_character file =
  Seq.find
    (Code_file.is_code_character file)
    (Seq.init
       (Text.length (Lines.text (Reading.lines (Code_file.reading file))))
       succ)

let rec fill untils lowest highest lo hi =
  if lo >= hi then (max_int, min_int)
  else
    let mid = (lo + hi) / 2 in
    let low_left, high_left = fill untils lowest highest lo mid in
    let low_right, high_right = fill untils lowest highest (mid + 1) hi in
    lowest.(mid) <- min untils.(mid) (min low_left low_right);
    highest.(mid) <- max untils.(mid) (max high_left high_right);
    (lowest.(mid), highest.(mid))

let make binding path readable =
  let content, text, file_lines, pairs, links, first_code_character =
    match readable with
    | Readable_file.Markdown_file within ->
        let file = Markdown_file.read within in
        ( Markdown file,
          Markdown_limits.lines within,
          Markdown_file.file_lines file,
          markdown_tag_texts file,
          Input.of_links binding (Markdown_file.markdown_text file),
          None )
    | Readable_file.Code_file file ->
        let pairs = code_tag_texts file in
        ( Code file,
          Reading.lines (Code_file.reading file),
          Code_file.file_lines file,
          pairs,
          List.concat_map
            (fun (tag_text, _) ->
              Input.of_links binding (Tag_text.source tag_text))
            pairs,
          first_code_character file )
  in
  let lines = Array.of_list (File_lines.all file_lines) in
  let numbers, _ =
    Array.fold_right
      (fun (run : Text.run) (numbers, k) ->
        (By_run.add (run.from, run.until) k numbers, k - 1))
      lines
      (By_run.empty, Array.length lines)
  in
  let untils = Array.map (fun (run : Text.run) -> run.until) lines in
  let count = Array.length lines in
  let lowest = Array.copy untils and highest = Array.copy untils in
  ignore (fill untils lowest highest 0 count);
  let whole = Lines.text text in
  let not_blank = Array.make (count + 1) 0 in
  Array.iteri
    (fun k run ->
      not_blank.(k + 1) <-
        (if
           File_lines.is_blank
             (Option.value ~default:Text.empty (Text.sub whole run))
         then not_blank.(k)
         else k + 1))
    lines;
  {
    binding;
    path;
    content;
    text;
    file_lines;
    lines;
    numbers;
    froms = Array.map (fun (run : Text.run) -> run.from) lines;
    untils;
    lowest;
    highest;
    not_blank;
    tag_texts =
      List.map
        (fun (tag_text, holder) ->
          { tag_text; holder; inputs = Input.of_tag_text binding tag_text })
        pairs;
    links;
    first_code_character;
  }

let binding file = file.binding
let path file = file.path
let content file = file.content
let text file = file.text
let file_lines file = file.file_lines
let line_count file = Array.length file.lines

let line file k =
  if k >= 1 && k <= Array.length file.lines then Some file.lines.(k - 1)
  else None

let number file (run : Text.run) =
  By_run.find_opt (run.from, run.until) file.numbers

let all_lines file = Line_set.range 1 (Array.length file.lines)

let first_from froms boundary =
  let rec search lo hi =
    if lo >= hi then lo
    else
      let mid = (lo + hi) / 2 in
      if froms.(mid) < boundary then search (mid + 1) hi else search lo mid
  in
  search 0 (Array.length froms)

let within file (r : Text.run) =
  let first = first_from file.froms r.from
  and stop = first_from file.froms (r.until + 1) in
  let rec go lo hi found =
    if
      lo >= hi
      || (hi <= first)
         [@mutaml.skip "one more edge of the search gives the same result"]
      || (lo >= stop)
         [@mutaml.skip "one more edge of the search gives the same result"]
    then found
    else
      let mid = (lo + hi) / 2 in
      if file.lowest.(mid) > r.until then found
      else if
        (first <= lo)
        [@mutaml.skip "one more edge of the search gives the same result"]
        && (hi <= stop)
           [@mutaml.skip "one more edge of the search gives the same result"]
        && file.highest.(mid) <= r.until
      then Line_set.range (lo + 1) hi :: found
      else
        let found = go (mid + 1) hi found in
        let found =
          if mid >= first && file.untils.(mid) <= r.until then
            Line_set.range (mid + 1) (mid + 1) :: found
          else found
        in
        go lo mid found
  in
  Line_set.union (go 0 (Array.length file.untils) [])

let numbers file runs = Line_set.of_list (List.filter_map (number file) runs)

let last_not_blank file k =
  file.not_blank.(max 0 (min k (Array.length file.untils)))

let tag_texts file = file.tag_texts
let links file = file.links

let code_character_before file b =
  match file.first_code_character with Some p -> p <= b | None -> false
