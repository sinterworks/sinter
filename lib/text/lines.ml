(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = {
  text : Text.t;
  starts : int array;
  ends : int array;
  filled : int array;
}

type position = { line : int; column : int }
type place_error = Not_a_place | Byte_order_mark
type span_error = Not_a_run | Not_a_span

let line_feed = Uchar.of_int 0x0A
let carriage_return = Uchar.of_int 0x0D
let is text place c = Text.get text place = Some c

let of_text text =
  let body = Text.body text in
  let starts = ref [] and ends = ref [] in
  (* @satisfies text#{give-lines=v1, give-only-lines=v1} *)
  let rec scan start p =
    if p > body.until then
      begin if start < body.until then begin
        starts := start :: !starts;
        ends := body.until :: !ends
      end
      end
    else if is text p line_feed then begin
      let ending = if is text (p - 1) carriage_return then p - 2 else p - 1 in
      starts := start :: !starts;
      ends := ending :: !ends;
      scan p (p + 1)
    end
    else scan start (p + 1)
  in
  scan body.from body.from;
  let starts = Array.of_list (List.rev !starts)
  and ends = Array.of_list (List.rev !ends) in
  (* @satisfies text#give-span-ends=v1 *)
  let filled = Array.copy starts in
  Array.iteri
    (fun i s ->
      filled.(i) <- (if ends.(i) > s || i = 0 then i else filled.(i - 1)))
    starts;
  { text; starts; ends; filled }

let text lines = lines.text
let count lines = Array.length lines.starts
let run lines i = { Text.from = lines.starts.(i); until = lines.ends.(i) }
let all lines = List.init (count lines) (run lines)

(* @satisfies text#{give-numbered-lines=v1, give-only-lines=v1} *)
let line lines k =
  if k < 1 || k > count lines then None else Some (run lines (k - 1))

let last_start_at_or_before lines b =
  let rec search low high =
    if low >= high then low
    else
      let middle = (low + high + 1) / 2 in
      if lines.starts.(middle) <= b then search middle high
      else search low (middle - 1)
  in
  if count lines = 0 || lines.starts.(0) > b then -1
  else search 0 (count lines - 1)

(* @satisfies text#{give-character-positions=v1, give-span-starts=v1, give-span-ends=v1} *)
let boundary_position lines b =
  let i = last_start_at_or_before lines b in
  let beyond = { line = count lines + 1; column = 1 } in
  if i < 0 then beyond
  else if b <= lines.ends.(i) then
    { line = i + 1; column = b - lines.starts.(i) + 1 }
  else if b < Text.length lines.text then
    { line = i + 1; column = lines.ends.(i) - lines.starts.(i) + 1 }
  else beyond

(* @satisfies text#{give-character-positions=v1, omit-byte-order-mark-positions=v1} *)
let character_position lines place =
  if place < 1 || place > Text.length lines.text then Error Not_a_place
  else if place = 1 && Text.has_byte_order_mark lines.text then
    Error Byte_order_mark
  else Ok (boundary_position lines (place - 1))

(* @satisfies text#{give-span-ends=v1, give-positions-only-for-spans=v1} *)
let span lines (run : Text.run) =
  let length = Text.length lines.text in
  if run.from < 0 || run.until < run.from || run.until > length then
    Error Not_a_run
  else if run.from < (Text.body lines.text).from then Error Not_a_span
  else
    let start = boundary_position lines run.from in
    match last_start_at_or_before lines (run.until - 1) with
    | -1 -> Ok (start, start)
    | i ->
        let last = min run.until lines.ends.(lines.filled.(i)) in
        Ok (start, boundary_position lines (max run.from last))
