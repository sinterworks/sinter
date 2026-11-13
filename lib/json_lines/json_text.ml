(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t =
  | Null
  | Boolean of bool
  | Number of string
  | String of int list
  | Array of t list
  | Object of (int list * t) list

let is_digit c = c >= '0' && c <= '9'
let char_at s i = if i < String.length s then s.[i] else '\000'

let digits_end s start =
  let rec go i = if is_digit (char_at s i) then go (i + 1) else i in
  go start

let after_integer s start =
  match char_at s start with
  | '0' -> Some (start + 1)
  | '1' .. '9' -> Some (digits_end s start)
  | _ -> None

let after_fraction s position =
  if char_at s position = '.' then
    let fraction_end = digits_end s (position + 1) in
    if fraction_end > position + 1 then Some fraction_end else None
  else Some position

let exponent_digits_start s position =
  match char_at s (position + 1) with
  | '-' | '+' -> position + 2
  | _ -> position + 1

let after_exponent s position =
  match char_at s position with
  | 'e' | 'E' ->
      let digits_start = exponent_digits_start s position in
      let exponent_end = digits_end s digits_start in
      if exponent_end > digits_start then Some exponent_end else None
  | _ -> Some position

let strip_leading_zeros digits =
  let rec go i = if char_at digits i = '0' then go (i + 1) else i in
  let start = go 0 in
  String.sub digits start (String.length digits - start)

let strip_trailing_zeros digits =
  let rec last i = if digits.[i] = '0' then last (i - 1) else i in
  String.sub digits 0 (last (String.length digits - 1) + 1)

let exponent s exponent_start exponent_end =
  if exponent_start = exponent_end then Some 0
  else
    let digits_start = exponent_digits_start s exponent_start in
    match
      int_of_string_opt
        (String.sub s digits_start (exponent_end - digits_start))
    with
    | Some magnitude ->
        Some
          (if char_at s (exponent_start + 1) = '-' then -magnitude
           else magnitude)
    | None -> None

(* @satisfies data-forms#write-canonical-json=v1
   The digits and the exponent give an integer only when the number is whole,
   with no nonzero digit after the point, and from -(2^53 - 1) to 2^53 - 1;
   any other number has no canonical byte sequence. *)
let integer_of_parts ~negative ~digits ~fraction ~exponent =
  let digits = strip_leading_zeros digits in
  if digits = "" then Json.integer 0
  else
    let significant = strip_trailing_zeros digits in
    let needed =
      String.length fraction - (String.length digits - String.length significant)
    in
    let rec scale value power =
      if power = needed then Json.integer (if negative then -value else value)
      else if value > Json.max_integer / 10 then None
      else scale (value * 10) (power - 1)
    in
    match (exponent, int_of_string_opt significant) with
    | Some exponent, Some value when exponent >= needed -> scale value exponent
    | _ -> None

(* @satisfies data-forms#write-canonical-json=v1
   Gives an integer only for a JSON number of RFC 8259 that writes one, so the
   writer gives no byte sequence for any other number. *)
let integer_of_number s =
  let negative = char_at s 0 = '-' in
  let integer_start = if negative then 1 else 0 in
  match after_integer s integer_start with
  | None -> None
  | Some integer_end -> (
      match after_fraction s integer_end with
      | None -> None
      | Some fraction_end -> (
          match after_exponent s fraction_end with
          | Some exponent_end when exponent_end = String.length s ->
              let fraction =
                if fraction_end = integer_end then ""
                else
                  String.sub s (integer_end + 1) (fraction_end - integer_end - 1)
              in
              integer_of_parts ~negative
                ~digits:
                  (String.sub s integer_start (integer_end - integer_start)
                  ^ fraction)
                ~fraction
                ~exponent:(exponent s fraction_end exponent_end)
          | Some _ | None -> None))

(* @satisfies data-forms#write-canonical-json=v1
   Gives a text only when the code units are those of characters; a lone
   surrogate gives no text, so the string has no canonical byte sequence. *)
let text_of_units units =
  let rec go characters = function
    | [] -> Some (Sinter_text.Text.of_uchars (List.rev characters))
    | high :: rest when high >= 0xD800 && high <= 0xDBFF -> (
        match rest with
        | low :: rest when low >= 0xDC00 && low <= 0xDFFF ->
            go
              (Uchar.of_int
                 (0x10000 + ((high - 0xD800) * 0x400) + (low - 0xDC00))
              :: characters)
              rest
        | _ -> None)
    | unit :: rest
      when unit >= 0 && unit <= 0xFFFF && (unit < 0xDC00 || unit > 0xDFFF) ->
        go (Uchar.of_int unit :: characters) rest
    | _ -> None
  in
  go [] units

(* @satisfies data-forms#write-canonical-json=v1
   Null, and an array or object that holds a thing that is not a JSON value or
   two members with one key, give no JSON value and so no byte sequence. *)
let rec convert thing k =
  match thing with
  | Null -> None
  | Boolean b -> k (Json.boolean b)
  | Number s -> Option.bind (integer_of_number s) k
  | String units ->
      Option.bind (text_of_units units) (fun text -> k (Json.string text))
  | Array elements ->
      convert_elements elements [] (fun values -> k (Json.array values))
  | Object members ->
      convert_members members [] (fun members ->
          Option.bind (Json.object_ members) k)

and convert_elements elements values k =
  match elements with
  | [] -> k (List.rev values)
  | element :: rest ->
      convert element (fun value -> convert_elements rest (value :: values) k)

and convert_members members converted k =
  match members with
  | [] -> k (List.rev converted)
  | (key, element) :: rest -> (
      match text_of_units key with
      | None -> None
      | Some key ->
          convert element (fun value ->
              convert_members rest ((key, value) :: converted) k))

let to_json_value thing = convert thing Option.some
