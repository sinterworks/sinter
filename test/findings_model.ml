(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type text = Uchar.t list

let lf = Uchar.of_int 0x0A
let cr = Uchar.of_int 0x0D
let bom = Uchar.of_int 0xFEFF
let at t place = List.nth t (place - 1)

let body_start t =
  match t with first :: _ when Uchar.equal first bom -> 1 | _ -> 0

let line_endings t =
  let first = body_start t + 1 in
  List.filter_map
    (fun p ->
      if Uchar.equal (at t p) lf then
        if p - 1 >= first && Uchar.equal (at t (p - 1)) cr then Some (p - 2, p)
        else Some (p - 1, p)
      else None)
    (List.init (List.length t - first + 1) (fun index -> first + index))

let lines t =
  let endings = line_endings t in
  let finish = List.length t in
  let starts = body_start t :: List.map snd endings in
  List.filter_map
    (fun start ->
      let stop =
        match List.find_opt (fun (s, _) -> s >= start) endings with
        | Some (s, _) -> s
        | None -> finish
      in
      if stop = finish && stop = start then None else Some (start, stop))
    starts

let inside_line_ending t b =
  List.exists (fun (s, e) -> s < b && b < e) (line_endings t)

let position t b =
  let numbered = List.mapi (fun index line -> (index + 1, line)) (lines t) in
  match List.find_opt (fun (_, (s, e)) -> s <= b && b <= e) numbered with
  | Some (number, (s, _)) -> (number, b - s + 1)
  | None -> (
      match List.find_opt (fun (s, e) -> s < b && b < e) (line_endings t) with
      | Some (ending_start, _) -> (
          match
            List.find_opt (fun (_, (_, e)) -> e = ending_start) numbered
          with
          | Some (number, (s, e)) -> (number, e - s + 1)
          | None -> invalid_arg "Findings_model.position")
      | None -> (List.length numbered + 1, 1))

let spot_boundaries t =
  let first = body_start t in
  List.filter
    (fun b -> not (inside_line_ending t b))
    (List.init (List.length t - first + 1) (fun index -> first + index))

let boundary_of_position t wanted =
  List.find_opt (fun b -> position t b = wanted) (spot_boundaries t)

let line_of_boundary t b =
  List.find_opt (fun (s, e) -> s <= b && b <= e) (lines t)

type content = Utf_8 of text | Not_utf_8
type tree = (text * content) list

type description = {
  path : text;
  start : int * int;
  after : int * int;
  new_text : text;
}

type edit = { from : int; until : int; replacement : text }

let same_text a b = List.equal Uchar.equal a b

let is_edit_set edits =
  let indexed = List.mapi (fun index edit -> (index, edit)) edits in
  List.for_all
    (fun (i, a) ->
      List.for_all
        (fun (j, b) -> i = j || a.until <= b.from <> (b.until <= a.from))
        indexed)
    indexed

let edit_of tree description =
  match List.find_opt (fun (p, _) -> same_text p description.path) tree with
  | Some (_, Utf_8 t) when Paths_reference.is_path description.path -> (
      match
        ( boundary_of_position t description.start,
          boundary_of_position t description.after )
      with
      | Some from, Some until when from <= until ->
          Some { from; until; replacement = description.new_text }
      | _ -> None)
  | _ -> None

let describe tree descriptions =
  let edits =
    List.map
      (fun description ->
        Option.map
          (fun edit -> (description.path, edit))
          (edit_of tree description))
      descriptions
  in
  if descriptions = [] || List.exists Option.is_none edits then None
  else
    let edits = List.filter_map Fun.id edits in
    let same (p, a) (q, b) =
      same_text p q && a.from = b.from && a.until = b.until
      && same_text a.replacement b.replacement
    in
    let rec distinct = function
      | [] -> true
      | edit :: rest -> (not (List.exists (same edit) rest)) && distinct rest
    in
    if not (distinct edits) then None
    else
      let paths =
        List.fold_left
          (fun paths (p, _) ->
            if List.exists (same_text p) paths then paths else paths @ [ p ])
          [] edits
      in
      let grouped =
        List.map
          (fun p ->
            ( p,
              List.filter_map
                (fun (q, edit) -> if same_text p q then Some edit else None)
                edits ))
          paths
      in
      if List.for_all (fun (_, edits) -> is_edit_set edits) grouped then
        Some grouped
      else None

let run t from until =
  List.filteri (fun index _ -> from <= index && index < until) t

let edited_text t edits =
  let rec order remaining =
    match
      List.find_opt
        (fun (i, e) ->
          List.for_all (fun (j, f) -> i = j || e.until <= f.from) remaining)
        remaining
    with
    | None -> []
    | Some (i, first) ->
        first :: order (List.filter (fun (j, _) -> i <> j) remaining)
  in
  let rec build boundary = function
    | [] -> run t boundary (List.length t)
    | e :: rest -> run t boundary e.from @ e.replacement @ build e.until rest
  in
  build 0 (order (List.mapi (fun index edit -> (index, edit)) edits))

let is_non_wsp u =
  let c = Uchar.to_int u in
  c <> 0x09 && c <> 0x20

let is_subject t =
  (not (List.exists (Uchar.equal lf) t))
  &&
  match (t, List.rev t) with
  | first :: _, last :: _ -> is_non_wsp first && is_non_wsp last
  | _ -> false

let is_message t =
  t <> [] && not (List.exists (fun u -> Uchar.equal u lf || Uchar.equal u cr) t)

let of_string string =
  let rec go index acc =
    if index >= String.length string then List.rev acc
    else
      let decode = String.get_utf_8_uchar string index in
      go
        (index + Uchar.utf_decode_length decode)
        (Uchar.utf_decode_uchar decode :: acc)
  in
  go 0 []

let to_string t =
  let buffer = Buffer.create 16 in
  List.iter (Buffer.add_utf_8_uchar buffer) t;
  Buffer.contents buffer

let of_text t =
  List.init (Sinter_text.Text.length t) (fun index ->
      match Sinter_text.Text.get t (index + 1) with
      | Some u -> u
      | None -> invalid_arg "Findings_model.of_text")

let to_text t = Sinter_text.Text.of_uchars t

let print t =
  String.concat ""
    (List.map
       (fun u ->
         let c = Uchar.to_int u in
         if c >= 0x20 && c < 0x7F then String.make 1 (Char.chr c)
         else Printf.sprintf "<U+%04X>" c)
       t)
