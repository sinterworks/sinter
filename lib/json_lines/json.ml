(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t =
  | String of Text.t
  | Integer of int
  | Boolean of bool
  | Array of t list
  | Object of (Text.t * t) list

let min_integer = -9007199254740991
let max_integer = 9007199254740991
let string text = String text

let integer number =
  if number < min_integer || number > max_integer then None
  else Some (Integer number)

let boolean b = Boolean b
let array elements = Array elements
let is_supplementary point = point >= 0x10000
let is_after_surrogates point = point >= 0xE000 && point < 0x10000

let compare_characters a b =
  if
    (is_supplementary a && is_after_surrogates b)
    || (is_after_surrogates a && is_supplementary b)
  then Int.compare b a
  else Int.compare a b

let compare_keys a b =
  let a = Text.encode a and b = Text.encode b in
  let length_a = String.length a and length_b = String.length b in
  let rec walk i j =
    if i >= length_a then if j >= length_b then 0 else -1
    else if j >= length_b then 1
    else
      let decoded_a = String.get_utf_8_uchar a i
      and decoded_b = String.get_utf_8_uchar b j in
      let point_a = Uchar.to_int (Uchar.utf_decode_uchar decoded_a)
      and point_b = Uchar.to_int (Uchar.utf_decode_uchar decoded_b) in
      if point_a = point_b then
        walk
          (i + Uchar.utf_decode_length decoded_a)
          (j + Uchar.utf_decode_length decoded_b)
      else compare_characters point_a point_b
  in
  walk 0 0

let object_ members =
  let sorted =
    List.stable_sort (fun (a, _) (b, _) -> compare_keys a b) members
  in
  let rec unique = function
    | (a, _) :: ((b, _) :: _ as rest) ->
        if compare_keys a b = 0 then false else unique rest
    | [ _ ] | [] -> true
  in
  if unique sorted then Some (Object sorted) else None

let hex_digits = "0123456789abcdef"

(* @satisfies data-forms#write-canonical-json=v1
   Writes each character of a string as its string form: the seven short
   escapes, `\u00` and two hex digits for the other characters from U+0000 to
   U+001F, and every other character as itself. *)
let add_string buffer text =
  Buffer.add_char buffer '"';
  String.iter
    (fun byte ->
      match byte with
      | '"' -> Buffer.add_string buffer "\\\""
      | '\\' -> Buffer.add_string buffer "\\\\"
      | '\b' -> Buffer.add_string buffer "\\b"
      | '\t' -> Buffer.add_string buffer "\\t"
      | '\n' -> Buffer.add_string buffer "\\n"
      | '\012' -> Buffer.add_string buffer "\\f"
      | '\r' -> Buffer.add_string buffer "\\r"
      | '\000' .. '\031' ->
          let code = Char.code byte in
          Buffer.add_string buffer "\\u00";
          Buffer.add_char buffer hex_digits.[code / 16];
          Buffer.add_char buffer hex_digits.[code mod 16]
      | _ -> Buffer.add_char buffer byte)
    (Text.encode text);
  Buffer.add_char buffer '"'

type task = Value of t | Key of Text.t | Char of char

let separated groups tail =
  match List.rev groups with
  | [] -> tail
  | last :: earlier ->
      List.fold_left
        (fun rest group -> group @ (Char ',' :: rest))
        (last @ tail) earlier

(* @satisfies data-forms#write-canonical-json=v1
   Writes integers as decimal numerals, booleans as `true` and `false`, and
   arrays and objects with `,` between elements and members in key order,
   with no other byte. *)
let canonical_byte_sequence value =
  let buffer =
    Buffer.create
      (64
      [@mutaml.skip
        "The size that a buffer starts with changes no byte that it holds."])
  in
  let rec run = function
    | [] -> Buffer.contents buffer
    | Char c :: rest ->
        Buffer.add_char buffer c;
        run rest
    | Key key :: rest ->
        add_string buffer key;
        Buffer.add_char buffer ':';
        run rest
    | Value (String text) :: rest ->
        add_string buffer text;
        run rest
    | Value (Integer number) :: rest ->
        Buffer.add_string buffer (Int.to_string number);
        run rest
    | Value (Boolean b) :: rest ->
        Buffer.add_string buffer (if b then "true" else "false");
        run rest
    | Value (Array elements) :: rest ->
        run
          (Char '['
          :: separated
               (List.map (fun element -> [ Value element ]) elements)
               (Char ']' :: rest))
    | Value (Object members) :: rest ->
        run
          (Char '{'
          :: separated
               (List.map (fun (key, value) -> [ Key key; Value value ]) members)
               (Char '}' :: rest))
  in
  run [ Value value ]

let equal a b =
  String.equal (canonical_byte_sequence a) (canonical_byte_sequence b)
