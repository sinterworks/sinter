(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type comment = Tagged | Untagged
type piece = Text_piece of string | Placeholder of string

type node = {
  run : Text.run;
  comment : comment option;
  body : Text.run list option;
  decoration : bool;
  test : piece list list option;
}

type sigils = {
  line : string list;
  block : (string * string) list;
  inner : string list;
}

let code text place =
  match Text.get text place with Some u -> Uchar.to_int u | None -> -1

let is_wsp c = c = 0x20 || c = 0x09

let codes string =
  match Text.decode string with
  | Ok text -> List.init (Text.length text) (fun k -> code text (k + 1))
  | Error _ -> invalid_arg "codes"

let lines text = Lines.all (Lines.of_text text)

let in_line_ending text place =
  let body = Text.body text in
  let inside p = p > body.Text.from && p <= body.Text.until in
  inside place
  && (code text place = 0x0A
     || code text place = 0x0D
        && inside (place + 1)
        && code text (place + 1) = 0x0A)

let line_number text b =
  let all = lines text in
  let rec within k = function
    | [] -> None
    | { Text.from; until } :: rest ->
        if from <= b && b <= until then Some k else within (k + 1) rest
  in
  match within 1 all with
  | Some k -> k
  | None ->
      let rec ending k = function
        | [] -> List.length all + 1
        | { Text.until; _ } :: rest ->
            if
              until < b && in_line_ending text b
              && in_line_ending text (b + 1)
              && b = until + 1
            then k
            else ending (k + 1) rest
      in
      ending 1 all

let line_of_place text place =
  let rec find k = function
    | [] -> None
    | { Text.from; until } :: rest ->
        if from < place && place <= until then Some k else find (k + 1) rest
  in
  find 1 (lines text)

let in_run { Text.from; until } place = from < place && place <= until

let is_code_character text nodes place =
  let body = Text.body text in
  in_run body place
  && (not (is_wsp (code text place)))
  && (not (in_line_ending text place))
  && not
       (List.exists
          (fun node -> node.comment <> None && in_run node.run place)
          nodes)

let line_run text k = List.nth_opt (lines text) (k - 1)

let line_has_code text nodes k =
  match line_run text k with
  | None -> false
  | Some { Text.from; until } ->
      List.exists
        (fun p -> is_code_character text nodes p)
        (List.init (until - from) (fun i -> from + i + 1))

let run_lines text r =
  let all = lines text in
  let parts =
    List.filter_map
      (fun ({ Text.from; until } as line) ->
        let starts = max from r.Text.from and ends = min until r.Text.until in
        if from = until then
          if r.Text.from < from && from < r.Text.until then Some line else None
        else if starts < ends then Some { Text.from = starts; until = ends }
        else None)
      all
  in
  parts

let first_line text node = line_number text node.run.Text.from

let last_line text node =
  let { Text.from; until } = node.run in
  let rec back p =
    if p <= from then first_line text node
    else match line_of_place text p with Some k -> k | None -> back (p - 1)
  in
  back until

let encloses nodes i j =
  let a = List.nth nodes i and b = List.nth nodes j in
  i <> j
  && a.run.Text.from <= b.run.Text.from
  && a.run.Text.until >= b.run.Text.until
  && j > i

let indexed nodes = List.mapi (fun k node -> (k, node)) nodes

let outer_comments nodes =
  List.filter_map
    (fun (k, node) ->
      if
        node.comment <> None
        && not
             (List.exists
                (fun (i, other) -> other.comment <> None && encloses nodes i k)
                (indexed nodes))
      then Some k
      else None)
    (indexed nodes)

let only_space_between text a b =
  List.for_all
    (fun p ->
      let c = code text p in
      is_wsp c || in_line_ending text p)
    (List.init (max 0 (b - a)) (fun i -> a + i + 1))

let comment_runs text nodes =
  let order =
    List.stable_sort
      (fun i j ->
        compare (List.nth nodes i).run.Text.from
          (List.nth nodes j).run.Text.from)
      (outer_comments nodes)
  in
  let rec go previous runs = function
    | [] -> List.rev_map (fun (members, _) -> List.rev members) runs
    | k :: rest -> (
        let node = List.nth nodes k in
        let first = first_line text node in
        if line_has_code text nodes first then
          go (Some k) (([ k ], true) :: runs) rest
        else
          match (previous, runs) with
          | Some p, (members, false) :: older ->
              let before = List.nth nodes p in
              let last = last_line text before in
              if
                (first = last || first = last + 1)
                && node.run.Text.from >= before.run.Text.until
                && only_space_between text before.run.Text.until
                     node.run.Text.from
              then go (Some k) ((k :: members, false) :: older) rest
              else go (Some k) (([ k ], false) :: runs) rest
          | _ -> go (Some k) (([ k ], false) :: runs) rest)
  in
  go None [] order

let starts_with text from until sigil =
  let s = codes sigil in
  let n = List.length s in
  n <= until - from
  && List.for_all2
       (fun i c -> code text (from + i + 1) = c)
       (List.init n Fun.id) s

let ends_with text from until sigil =
  let n = List.length (codes sigil) in
  n <= until - from && starts_with text (until - n) until sigil

let longest text from until sigils =
  List.fold_left
    (fun best sigil ->
      if starts_with text from until sigil then
        match best with
        | Some b when List.length (codes b) >= List.length (codes sigil) -> best
        | _ -> Some sigil
      else best)
    None sigils

let length sigil = List.length (codes sigil)

let skip_wsp text from until =
  let rec go p =
    if p < until && is_wsp (code text (p + 1)) then go (p + 1) else p
  in
  go from

type kind = Line_comment | Block_comment of string | No_sigil

let comment_lines sigils text r =
  match run_lines text r with
  | [] -> []
  | first :: others ->
      let count = 1 + List.length others in
      let from = skip_wsp text first.Text.from first.Text.until in
      let until = first.Text.until in
      let kind, from =
        match
          longest text from until (sigils.line @ List.map fst sigils.block)
        with
        | None -> (No_sigil, from)
        | Some sigil ->
            if List.mem sigil sigils.line then
              (Line_comment, from + length sigil)
            else
              ( Block_comment (List.assoc sigil sigils.block),
                from + length sigil )
      in
      let until =
        match kind with
        | Block_comment closing
          when count = 1 && ends_with text from until closing ->
            until - length closing
        | _ -> until
      in
      let head = { Text.from; until } in
      let rest =
        List.mapi
          (fun i line ->
            let last = i = count - 2 in
            let from = skip_wsp text line.Text.from line.Text.until in
            let until = line.Text.until in
            match kind with
            | No_sigil -> { Text.from; until }
            | Line_comment ->
                let from =
                  match longest text from until sigils.line with
                  | Some s -> from + length s
                  | None -> from
                in
                { Text.from; until }
            | Block_comment closing ->
                let until =
                  if last && ends_with text from until closing then
                    until - length closing
                  else until
                in
                let from =
                  match longest text from until sigils.inner with
                  | Some s -> from + length s
                  | None -> from
                in
                { Text.from; until })
          others
      in
      head :: rest

let tag_text_lines sigils text nodes run =
  let tagged =
    List.filter (fun k -> (List.nth nodes k).comment = Some Tagged) run
  in
  if tagged = [] then None
  else
    Some
      (List.concat_map
         (fun k -> comment_lines sigils text (List.nth nodes k).run)
         tagged)

type line_kind = { tag : bool; continuation : bool; blank : bool }

let blocks kinds =
  let kinds = Array.of_list kinds in
  let n = Array.length kinds in
  let starts k =
    kinds.(k).tag
    && (k = 0 || not (kinds.(k - 1).tag || kinds.(k - 1).continuation))
  in
  let rec extend j =
    if j < n && (kinds.(j).tag || kinds.(j).continuation) then extend (j + 1)
    else j
  in
  let rec trail j =
    if j < n && (not kinds.(j).tag) && not kinds.(j).blank then trail (j + 1)
    else j
  in
  List.filter_map
    (fun k ->
      if starts k then
        let j = trail (extend (k + 1)) in
        Some (k + 1, j)
      else None)
    (List.init n Fun.id)

let comment_run_span nodes run =
  match (run, List.rev run) with
  | first :: _, last :: _ ->
      {
        Text.from = (List.nth nodes first).run.Text.from;
        until = (List.nth nodes last).run.Text.until;
      }
  | _ -> invalid_arg "comment_run_span"

let is_target node = node.body <> None || node.test <> None

let attachment text nodes run =
  let span = comment_run_span nodes run in
  let first_r = first_line text (List.nth nodes (List.hd run)) in
  let last_r =
    last_line text (List.nth nodes (List.nth run (List.length run - 1)))
  in
  let candidates =
    List.filter
      (fun (_, node) -> is_target node && node.run.Text.from >= span.Text.until)
      (indexed nodes)
  in
  match candidates with
  | [] -> None
  | _ ->
      let least =
        List.fold_left
          (fun m (_, n) -> min m n.run.Text.from)
          max_int candidates
      in
      let at_least =
        List.filter (fun (_, n) -> n.run.Text.from = least) candidates
      in
      let greatest =
        List.fold_left (fun m (_, n) -> max m n.run.Text.until) min_int at_least
      in
      let t, target =
        List.hd
          (List.filter (fun (_, n) -> n.run.Text.until = greatest) at_least)
      in
      let in_decoration p =
        List.exists (fun n -> n.decoration && in_run n.run p) nodes
      in
      let rule_2 =
        match line_run text first_r with
        | None -> true
        | Some { Text.from; until } ->
            List.for_all
              (fun p -> not (is_code_character text nodes p))
              (List.init
                 (max 0 (min until span.Text.from - from))
                 (fun i -> from + i + 1))
      in
      let between =
        List.init
          (max 0 (target.run.Text.from - span.Text.until))
          (fun i -> span.Text.until + i + 1)
      in
      let rule_3a =
        List.for_all
          (fun p -> (not (is_code_character text nodes p)) || in_decoration p)
          between
      in
      let first_t = line_number text target.run.Text.from in
      let line_ok k =
        match line_run text k with
        | None -> false
        | Some ({ Text.from; until } as line) ->
            List.exists
              (fun p -> is_code_character text nodes p && in_decoration p)
              (List.init (until - from) (fun i -> from + i + 1))
            || List.exists
                 (fun n ->
                   n.comment <> None
                   && List.exists
                        (fun l ->
                          l.Text.from >= line.Text.from
                          && l.Text.until <= line.Text.until
                          && (l.Text.from < l.Text.until
                             || line.Text.from = line.Text.until))
                        (run_lines text n.run))
                 nodes
      in
      let rule_3b =
        List.for_all line_ok
          (List.init (max 0 (first_t - last_r - 1)) (fun i -> last_r + i + 1))
      in
      if rule_2 && rule_3a && rule_3b then Some t else None

type test = {
  node : int;
  name : piece list list;
  code : Text.run;
  comments : Text.run list;
}

let tests text nodes =
  let runs = comment_runs text nodes in
  let attached =
    List.filter_map
      (fun run ->
        match attachment text nodes run with
        | Some t -> Some ((List.nth nodes t).run, comment_run_span nodes run)
        | None -> None)
      runs
  in
  let test_nodes =
    List.stable_sort
      (fun (_, a) (_, b) -> compare a.run.Text.from b.run.Text.from)
      (List.filter (fun (_, n) -> n.test <> None) (indexed nodes))
  in
  List.map
    (fun (k, n) ->
      {
        node = k;
        name = Option.value n.test ~default:[];
        code = n.run;
        comments =
          List.stable_sort
            (fun a b -> compare a.Text.from b.Text.from)
            (List.filter_map
               (fun (target, span) ->
                 if target = n.run then Some span else None)
               attached);
      })
    test_nodes
