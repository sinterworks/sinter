(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = { size : int; brackets : int; containers : int }
type limit = Size | Brackets | Containers
type text = Lines.t

let last_runs bytes first =
  let n = String.length bytes in
  let last =
    Hashtbl.create
      (16
      [@mutaml.skip
        "the size is only the first capacity of the table, and the table grows \
         as it needs, so each lookup gives the same result"])
  in
  let rec scan i =
    if i < n then
      if bytes.[i] = '`' then (
        let j = ref i in
        while !j < n && bytes.[!j] = '`' do
          incr j
        done;
        Hashtbl.replace last (!j - i) i;
        scan !j)
      else scan (i + 1)
  in
  scan first;
  last

type state = Open | In_code of int | In_html | Blocked

let brackets_from ~limit bytes first =
  let n = String.length bytes in
  let last = last_runs bytes first in
  let last_gt = String.rindex_opt bytes '>' in
  let stack = Dynarray.create () in
  let best = ref 0 and backslashes = ref 0 in
  let blank =
    ref
      (true
      [@mutaml.skip
        "the stack is empty until the first [ that counts, and that [ makes \
         its line not blank, so the first value changes nothing"])
  in
  let update f = Dynarray.iteri (fun k s -> Dynarray.set stack k (f s)) stack in
  let resolve outcome = update (function In_html -> outcome | s -> s) in
  let run i even =
    let j = ref i in
    while !j < n && bytes.[!j] = '`' do
      incr j
    done;
    let length = !j - i in
    let l = if even then length else length - 1 in
    let later =
      match Hashtbl.find_opt last l with Some s -> s > i | None -> false
    in
    update (function
      | In_code m when m = length -> Open
      | Open when later -> In_code l
      | s -> s);
    length
  in
  let html i =
    let next = bytes.[i + 1] in
    let outcome = if next = '!' || next = '?' then Blocked else In_html in
    update (function Open -> outcome | s -> s)
  in
  let gt_after i =
    match last_gt with
    | Some g -> (
        ((g > i) [@mutaml.skip "the byte at i is a <, so g is never i"]))
    | None -> false
  in
  let i = ref first in
  while !i < n && !best <= limit do
    let c = bytes.[!i] in
    let even = !backslashes land 1 = 0 in
    let step =
      match c with
      | '\n' | '\r' ->
          resolve Blocked;
          if c = '\n' || !i + 1 >= n || bytes.[!i + 1] <> '\n' then (
            if !blank then Dynarray.clear stack;
            blank := true);
          1
      | ' ' | '\t' -> 1
      | '[' ->
          blank := false;
          if even then (
            Dynarray.add_last stack Open;
            best := max !best (Dynarray.length stack));
          1
      | ']' ->
          blank := false;
          if even && Dynarray.find_last stack = Some Open then
            ignore (Dynarray.pop_last stack);
          1
      | '>' ->
          blank := false;
          resolve Open;
          1
      | '"' | '\'' ->
          blank := false;
          resolve Blocked;
          1
      | '`' ->
          blank := false;
          resolve Blocked;
          run !i even
      | '<' ->
          blank := false;
          resolve Blocked;
          if even && gt_after !i then html !i;
          1
      | _ ->
          blank := false;
          1
    in
    if c = '\\' then incr backslashes else backslashes := 0;
    i := !i + step
  done;
  if !best <= limit then Some !best else None

let is_digit c = c >= '0' && c <= '9'

let containers_from ~limit bytes first =
  let n = String.length bytes in
  let ends k = k >= n || bytes.[k] = '\n' || bytes.[k] = '\r' in
  let marker_end k = ends k || bytes.[k] = ' ' || bytes.[k] = '\t' in
  let rec ordered i j =
    if j < n && is_digit bytes.[j] && j - i < 9 then ordered i (j + 1)
    else if j < n && (bytes.[j] = '.' || bytes.[j] = ')') && marker_end (j + 1)
    then Some (j + 1)
    else None
  in
  let best = ref 0 and i = ref first in
  while
    (!i < n)
    [@mutaml.skip
      "a line that starts at the end of the bytes is empty, and its depth 0 \
       changes no result"]
    && !best <= limit
  do
    let column = ref 0 and white = ref 0 and markers = ref 0 in
    let depth = ref 0 and listed = ref false and leading = ref true in
    let marker next list =
      incr markers;
      depth := if !listed then !depth + 1 else !markers + (!white / 2);
      listed := !listed || list;
      column := !column + (next - !i);
      i := next
    in
    while not (ends !i) do
      if !leading then
        match bytes.[!i] with
        | (' ' | '\t') as c ->
            let width = if c = '\t' then 4 - (!column land 3) else 1 in
            white := !white + width;
            column := !column + width;
            incr i
        | '>' -> marker (!i + 1) false
        | ('-' | '+' | '*') when marker_end (!i + 1) -> marker (!i + 1) true
        | c when is_digit c -> (
            match ordered !i !i with
            | Some next -> marker next true
            | None -> leading := false)
        | _ -> leading := false
      else incr i
    done;
    best := max !best !depth;
    incr i
  done;
  if !best <= limit then Some !best else None

let bracket_depth ~limit bytes = brackets_from ~limit bytes 0
let container_depth ~limit bytes = containers_from ~limit bytes 0

(* @cites commonmark-reader *)
let check limits lines =
  let text = Lines.text lines in
  let bytes = Text.encode text in
  let first = if Text.has_byte_order_mark text then 3 else 0 in
  if String.length bytes > limits.size then Error Size
  else if brackets_from ~limit:limits.brackets bytes first = None then
    Error Brackets
  else if containers_from ~limit:limits.containers bytes first = None then
    Error Containers
  else Ok lines

let lines text = text
