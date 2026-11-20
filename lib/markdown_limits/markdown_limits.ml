(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = { size : int; brackets : int; containers : int }
type limit = Size | Brackets | Containers
type text = Lines.t

let last_runs bytes first =
  let n = String.length bytes in
  let last = Hashtbl.create 16 in
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

let opened = 0
let in_code = 1
let in_html = 2
let blocked = 3

let brackets_from ~limit bytes first =
  let n = String.length bytes in
  let last = last_runs bytes first in
  let last_gt = Option.value ~default:(-1) (String.rindex_opt bytes '>') in
  let size = ref (max 1 (min 64 limit)) in
  let state = ref (Array.make !size opened)
  and code = ref (Array.make !size 0) in
  let top = ref 0 and pending = ref 0 and best = ref 0 in
  let backslashes = ref 0 and blank = ref true in
  let push () =
    if !top = !size then (
      let grow a =
        let b = Array.make (2 * !size) 0 in
        Array.blit a 0 b 0 !size;
        b
      in
      state := grow !state;
      code := grow !code;
      size := 2 * !size);
    !state.(!top) <- opened;
    incr top;
    best := max !best !top
  in
  let resolve outcome =
    if !pending > 0 then (
      for k = 0 to !top - 1 do
        if !state.(k) = in_html then !state.(k) <- outcome
      done;
      pending := 0)
  in
  let run i even =
    let j = ref i in
    while !j < n && bytes.[!j] = '`' do
      incr j
    done;
    let length = !j - i in
    let l = if even then length else length - 1 in
    let later =
      l > 0
      && match Hashtbl.find_opt last l with Some s -> s > i | None -> false
    in
    for k = 0 to !top - 1 do
      if !state.(k) = in_code then (
        if !code.(k) = length then !state.(k) <- opened)
      else if !state.(k) = opened && later then (
        !state.(k) <- in_code;
        !code.(k) <- l)
    done;
    length
  in
  let html i =
    let next = if i + 1 < n then bytes.[i + 1] else ' ' in
    let outcome = if next = '!' || next = '?' then blocked else in_html in
    for k = 0 to !top - 1 do
      if !state.(k) = opened then (
        !state.(k) <- outcome;
        if outcome = in_html then incr pending)
    done
  in
  let i = ref first in
  while !i < n && !best <= limit do
    let c = bytes.[!i] in
    let even = !backslashes land 1 = 0 in
    let step =
      match c with
      | '\n' | '\r' ->
          resolve blocked;
          if c = '\n' || !i + 1 >= n || bytes.[!i + 1] <> '\n' then (
            if !blank then (
              top := 0;
              pending := 0);
            blank := true);
          1
      | ' ' | '\t' -> 1
      | '[' ->
          blank := false;
          if even then push ();
          1
      | ']' ->
          blank := false;
          if even && !top > 0 && !state.(!top - 1) = opened then decr top;
          1
      | '>' ->
          blank := false;
          resolve opened;
          1
      | '"' | '\'' ->
          blank := false;
          resolve blocked;
          1
      | '`' ->
          blank := false;
          resolve blocked;
          run !i even
      | '<' ->
          blank := false;
          resolve blocked;
          if even && last_gt > !i then html !i;
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
    else if
      j > i && j < n
      && (bytes.[j] = '.' || bytes.[j] = ')')
      && marker_end (j + 1)
    then Some (j + 1)
    else None
  in
  let best = ref 0 and i = ref first in
  while !i < n && !best <= limit do
    let column = ref 0 and white = ref 0 and markers = ref 0 in
    let w = ref 0 and listed = ref false and leading = ref true in
    let list_marker next =
      if not !listed then (
        w := !white;
        listed := true);
      incr markers;
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
        | '>' ->
            if not !listed then w := !white;
            incr markers;
            incr column;
            incr i
        | ('-' | '+' | '*') when marker_end (!i + 1) -> list_marker (!i + 1)
        | c when is_digit c -> (
            match ordered !i !i with
            | Some next -> list_marker next
            | None -> leading := false)
        | _ -> leading := false
      else incr i
    done;
    if !markers > 0 then best := max !best (!markers + (!w / 2));
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
