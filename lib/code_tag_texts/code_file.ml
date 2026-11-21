(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_origins
open Sinter_readings

type comment_run = {
  run : Text.run;
  first_line : int;
  last_line : int;
  comment_nodes : Reading.node list;
  tag_text : Tag_text.t option;
  target : Reading.node option;
}

type t = {
  path : Path.t;
  reading : Reading.t;
  code_characters : bool array;
  comment_runs : comment_run list;
  tag_texts : Tag_text.t list;
  file_lines : File_lines.t;
}

type facts = {
  lines : Lines.t;
  line_of_place : int array;
  line_of_boundary : int array;
  code : bool array;
  code_before : int array;
  undecorated_before : int array;
  other_before : int array;
  last_line_place : int array;
  bad_lines_before : int array;
}

let running size delta =
  let depth = ref 0 in
  Array.init size (fun b ->
      depth := !depth + delta.(b);
      !depth)

let opened size runs =
  let delta = Array.make size 0 in
  List.iter
    (fun (run : Text.run) ->
      delta.(run.from) <- delta.(run.from) + 1;
      delta.(run.until) <- delta.(run.until) - 1)
    runs;
  running size delta

let counts holds elements =
  let count =
    ref
      (0
      [@mutaml.skip
        "only the differences of two counts are read, and a common start value \
         cancels in each difference"])
  in
  Array.map
    (fun element ->
      if holds element then incr count;
      !count)
    elements

let space = Uchar.of_int 0x20
let tab = Uchar.of_int 0x09
let carriage_return = Uchar.of_int 0x0D

let facts reading =
  let lines = Reading.lines reading in
  let text = Lines.text lines in
  let n = Text.length text in
  let size =
    (n + 1)
    [@mutaml.skip
      "each array has one element for each boundary from 0 to the length of \
       the text; a larger array has elements that no code reads"]
  in
  let nodes = Reading.nodes reading in
  let runs_of keep =
    List.filter_map
      (fun (node : Reading.node) -> if keep node then Some node.run else None)
      nodes
  in
  let comment_runs = runs_of (fun node -> Option.is_some node.comment) in
  let comments_open = opened size comment_runs in
  let decorations_open = opened size (runs_of (fun node -> node.decoration)) in
  let in_comment p = comments_open.(p - 1) > 0 in
  let in_decoration p = decorations_open.(p - 1) > 0 in
  let line_runs = Array.of_list (Lines.all lines) in
  let count = Array.length line_runs in
  let line_of_place = Array.make size 0 in
  let line_of_boundary = Array.make size (count + 1) in
  Array.iteri
    (fun i (line : Text.run) ->
      for p = line.from + 1 to line.until do
        line_of_place.(p) <- i + 1
      done;
      for b = line.from to line.until do
        line_of_boundary.(b) <- i + 1
      done;
      if Text.get text (line.until + 1) = Some carriage_return then
        line_of_boundary.(line.until + 1) <- i + 1)
    line_runs;
  let blank p =
    let c = Text.get text p in
    c = Some space || c = Some tab
  in
  let places = Array.init size Fun.id in
  let code =
    Array.map
      (fun p -> line_of_place.(p) <> 0 && (not (in_comment p)) && not (blank p))
      places
  in
  let inside = Array.make size 0 in
  List.iter
    (fun (run : Text.run) ->
      if run.from < run.until then begin
        inside.(run.from + 1) <- inside.(run.from + 1) + 1;
        inside.(run.until) <- inside.(run.until) - 1
      end)
    comment_runs;
  let strictly_inside = running size inside in
  let has places_of (line : Text.run) =
    let rec scan p = p <= line.until && (places_of p || scan (p + 1)) in
    scan (line.from + 1)
  in
  let line_is_bad (line : Text.run) =
    not
      (has (fun p -> code.(p) && in_decoration p) line
      || has in_comment line
      || (line.from = line.until && strictly_inside.(line.from) > 0))
  in
  let last = ref 0 in
  let last_line_place =
    Array.map
      (fun p ->
        if line_of_place.(p) <> 0 then last := p;
        !last)
      places
  in
  {
    lines;
    line_of_place;
    line_of_boundary;
    code;
    code_before = counts (fun p -> code.(p)) places;
    undecorated_before =
      counts (fun p -> code.(p) && not (in_decoration p)) places;
    other_before =
      counts (fun p -> not (blank p || line_of_place.(p) = 0)) places;
    last_line_place;
    bad_lines_before = counts line_is_bad line_runs;
  }

let line_number facts boundary = facts.line_of_boundary.(boundary)

let line_has_code facts k =
  match Lines.line facts.lines k with
  | Some (line : Text.run) ->
      facts.code_before.(line.until) - facts.code_before.(line.from) > 0
  | None -> false

let first_line_of facts (node : Reading.node) = line_number facts node.run.from

let last_line_of facts (node : Reading.node) =
  let p = facts.last_line_place.(node.run.until) in
  if p > node.run.from then facts.line_of_place.(p)
  else first_line_of facts node

(* @satisfies documents#give-tests=v1
   An outer comment node is a comment node that no other comment node
   encloses, as the term comment-run gives it. In the order of the term
   node-run of the design packs=v1, a comment node before a comment node B
   encloses B when, and only when, its run ends at or after the end of the run
   of B, so the greatest end so far decides each node, in one pass in the order
   of the list. *)
let outer_nodes = function
  | [] -> []
  | (first : Reading.node) :: rest ->
      List.fold_left
        (fun (outer, last) (node : Reading.node) ->
          if last >= node.run.until then (outer, last)
          else (node :: outer, node.run.until))
        ([ first ], first.run.until)
        rest
      |> fst |> List.rev

type open_run = {
  first_node : Reading.node;
  nodes : Reading.node list;
  closed : bool;
  first : int;
  last : int;
  previous : Reading.node;
}

let only_blanks facts (a : Text.run) (b : Text.run) =
  a.until <= b.from
  && facts.other_before.(b.from) - facts.other_before.(a.until) = 0

(* @satisfies documents#give-tests=v1
   The rules of the term comment-run group the outer comment nodes: a node on a
   line with a code character stands alone, and another node joins the run
   before it only across spaces, tabs, and line endings, on the same line or on
   the next one. *)
let group facts outer =
  let finish acc = function None -> acc | Some run -> run :: acc in
  let rec go current acc = function
    | [] -> List.rev (finish acc current)
    | (node : Reading.node) :: rest -> (
        let first = first_line_of facts node
        and last = last_line_of facts node in
        let fresh closed =
          {
            first_node = node;
            nodes = [ node ];
            closed;
            first;
            last;
            previous = node;
          }
        in
        if line_has_code facts first then
          go (Some (fresh true)) (finish acc current) rest
        else
          match current with
          | Some run
            when (not run.closed)
                 && (first = run.last || first = run.last + 1)
                 && only_blanks facts run.previous.run node.run ->
              go
                (Some
                   { run with nodes = node :: run.nodes; last; previous = node })
                acc rest
          | _ -> go (Some (fresh false)) (finish acc current) rest)
  in
  go None [] outer

let targets reading =
  List.filter
    (fun (node : Reading.node) ->
      Option.is_some node.body || Option.is_some node.test)
    (Reading.nodes reading)
  |> List.stable_sort (fun (a : Reading.node) (b : Reading.node) ->
      match Int.compare a.run.from b.run.from with
      | 0 -> Int.compare b.run.until a.run.until
      | order -> order)
  |> Array.of_list

let first_target targets boundary =
  let rec search low high =
    if low >= high then low
    else
      let middle = (low + high) / 2 in
      if (targets.(middle) : Reading.node).run.from >= boundary then
        search low middle
      else search (middle + 1) high
  in
  let i = search 0 (Array.length targets) in
  if i < Array.length targets then Some targets.(i) else None

(* @satisfies documents#give-tests=v1
   A run of comments attaches to the first attachment target after it only when
   no code character stands before it on its first line, and only decorations
   stand, by their code characters and by each line, between the two. *)
let attachment facts targets (run : Text.run) ~first ~last =
  match first_target targets run.until with
  | None -> None
  | Some (target : Reading.node) ->
      let before_run =
        match Lines.line facts.lines first with
        | Some (line : Text.run) ->
            facts.code_before.(run.from) - facts.code_before.(line.from) > 0
        | None -> false
      in
      let target_line = line_number facts target.run.from in
      let lines_between =
        let low = last + 1 and high = target_line - 1 in
        if low > high then 0
        else
          facts.bad_lines_before.(high - 1) - facts.bad_lines_before.(low - 2)
      in
      if
        (not before_run)
        && facts.undecorated_before.(target.run.from)
           - facts.undecorated_before.(run.until)
           = 0
        && lines_between = 0
      then Some target
      else None

let make path sigils reading =
  let facts = facts reading in
  let lines = facts.lines in
  let comments =
    List.filter
      (fun (node : Reading.node) -> Option.is_some node.comment)
      (Reading.nodes reading)
  in
  let targets = targets reading in
  let comment_runs =
    List.map
      (fun open_run ->
        let comment_nodes = List.rev open_run.nodes in
        let run =
          {
            Text.from = open_run.first_node.run.from;
            until = open_run.previous.run.until;
          }
        in
        let tagged =
          List.filter
            (fun (node : Reading.node) -> node.comment = Some Reading.Tagged)
            comment_nodes
        in
        let tag_text =
          if tagged = [] then None
          else
            Tag_text.make lines
              (List.concat_map
                 (fun (node : Reading.node) ->
                   Option.value ~default:[]
                     (Comment_line.of_node sigils lines node.run))
                 tagged)
        in
        {
          run;
          first_line = open_run.first;
          last_line = open_run.last;
          comment_nodes;
          tag_text;
          target =
            attachment facts targets run ~first:open_run.first
              ~last:open_run.last;
        })
      (group facts (outer_nodes comments))
  in
  let tag_texts = List.filter_map (fun run -> run.tag_text) comment_runs in
  {
    path;
    reading;
    code_characters = Array.sub facts.code 1 (Array.length facts.code - 1);
    comment_runs;
    tag_texts;
    file_lines = File_lines.of_tag_texts tag_texts;
  }

let path file = file.path
let reading file = file.reading

let is_code_character file p =
  p >= 1
  && p <= Array.length file.code_characters
  && file.code_characters.(p - 1)

let comment_runs file = file.comment_runs
let tag_texts file = file.tag_texts
let file_lines file = file.file_lines
