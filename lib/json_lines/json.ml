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

type frame = In_array of t list | In_object of (Text.t * t) list * Text.t

let is_digit byte = byte >= '0' && byte <= '9'
let byte_at bytes i = if i < String.length bytes then bytes.[i] else '\000'
let is_hex_digit byte = is_digit byte || (byte >= 'a' && byte <= 'f')

let hex_value byte =
  if is_digit byte then Char.code byte - Char.code '0'
  else Char.code byte - Char.code 'a' + 10

let has_short_form code =
  code = 0x08 || code = 0x09 || code = 0x0A || code = 0x0C || code = 0x0D

let read_string bytes start =
  let byte = byte_at bytes in
  let buffer =
    Buffer.create
      (16
      [@mutaml.skip
        "The size that a buffer starts with changes no byte that it holds."])
  in
  let rec go i =
    match byte i with
    | '"' -> (
        match Text.decode (Buffer.contents buffer) with
        | Ok text -> Some (text, i + 1)
        | Error _ -> None)
    | '\\' -> escape i (byte (i + 1))
    | '\000' .. '\031' -> None
    | other -> add other (i + 1)
  and escape i = function
    | '"' -> add '"' (i + 2)
    | '\\' -> add '\\' (i + 2)
    | 'b' -> add '\b' (i + 2)
    | 't' -> add '\t' (i + 2)
    | 'n' -> add '\n' (i + 2)
    | 'f' -> add '\012' (i + 2)
    | 'r' -> add '\r' (i + 2)
    | 'u' ->
        if
          byte (i + 2) = '0'
          && byte (i + 3) = '0'
          && (byte (i + 4) = '0' || byte (i + 4) = '1')
          && is_hex_digit (byte (i + 5))
        then
          let code =
            (16 * hex_value (byte (i + 4))) + hex_value (byte (i + 5))
          in
          if has_short_form code then None else add (Char.chr code) (i + 6)
        else None
    | _ -> None
  and add other next =
    Buffer.add_char buffer other;
    go next
  in
  go (start + 1)

let read_digits bytes ~negative start =
  let rec digits_end i =
    if is_digit (byte_at bytes i) then digits_end (i + 1) else i
  in
  let finish = digits_end start in
  match int_of_string_opt (String.sub bytes start (finish - start)) with
  | Some magnitude ->
      Option.map
        (fun value -> (value, finish))
        (integer (if negative then -magnitude else magnitude))
  | None -> None

let read_integer bytes start =
  let negative = byte_at bytes start = '-' in
  let digits_start = if negative then start + 1 else start in
  match byte_at bytes digits_start with
  | '0' -> if negative then None else Some (Integer 0, digits_start + 1)
  | '1' .. '9' -> read_digits bytes ~negative digits_start
  | _ -> None

let read_literal bytes start literal value =
  let length = String.length literal in
  if
    start + length <= String.length bytes
    && String.equal (String.sub bytes start length) literal
  then Some (value, start + length)
  else None

let read bytes =
  let length = String.length bytes in
  let at i byte = byte_at bytes i = byte in
  let rec value i stack =
    match byte_at bytes i with
    | '"' -> (
        match read_string bytes i with
        | Some (text, next) -> complete (String text) next stack
        | None -> None)
    | '-' | '0' .. '9' -> scalar (read_integer bytes i) stack
    | 't' -> scalar (read_literal bytes i "true" (Boolean true)) stack
    | 'f' -> scalar (read_literal bytes i "false" (Boolean false)) stack
    | '[' ->
        if at (i + 1) ']' then complete (Array []) (i + 2) stack
        else value (i + 1) (In_array [] :: stack)
    | '{' ->
        if at (i + 1) '}' then complete (Object []) (i + 2) stack
        else member (i + 1) None [] stack
    | _ -> None
  and scalar read stack =
    match read with Some (v, next) -> complete v next stack | None -> None
  and member i previous members stack =
    if not (at i '"') then None
    else
      match read_string bytes i with
      | None -> None
      | Some (key, next) ->
          let in_order =
            match previous with
            | None -> true
            | Some previous -> compare_keys previous key < 0
          in
          if in_order && at next ':' then
            value (next + 1) (In_object (members, key) :: stack)
          else None
  and complete v i stack =
    match stack with
    | [] -> if i = length then Some v else None
    | In_array elements :: rest ->
        if at i ',' then value (i + 1) (In_array (v :: elements) :: rest)
        else if at i ']' then
          complete (Array (List.rev (v :: elements))) (i + 1) rest
        else None
    | In_object (members, key) :: rest ->
        let members = (key, v) :: members in
        if at i ',' then member (i + 1) (Some key) members rest
        else if at i '}' then complete (Object (List.rev members)) (i + 1) rest
        else None
  in
  value 0 []

(* @satisfies data-forms#read-json-text=v1
   The white space of a JSON text is the space, the tab, the line feed, and
   the carriage return, and no other character. *)
let is_white_space byte =
  byte = ' ' || byte = '\t' || byte = '\n' || byte = '\r'

(* @satisfies data-forms#{read-json-text=v1, give-only-json-values=v1}
   A digit of a `\u` escape writes 0 to 9 with `0` to `9`, and 10 to 15 with
   `a` to `f` or `A` to `F`; no other character is such a digit. *)
let hex_digit_value byte =
  if is_digit byte then Some (Char.code byte - Char.code '0')
  else if byte >= 'a' && byte <= 'f' then
    Some (Char.code byte - Char.code 'a' + 10)
  else if byte >= 'A' && byte <= 'F' then
    Some (Char.code byte - Char.code 'A' + 10)
  else None

(* @satisfies data-forms#{read-json-text=v1, give-only-json-values=v1}
   A `\u` escape writes the number of exactly four such digits after it. *)
let four_hex_digits bytes start =
  let rec go i number =
    if i = start + 4 then Some number
    else
      match hex_digit_value (byte_at bytes i) with
      | Some digit -> go (i + 1) ((16 * number) + digit)
      | None -> None
  in
  go start 0

(* @satisfies data-forms#{read-json-text=v1, give-only-json-values=v1}
   A string stands for the text of its characters and escape sequences; a
   `\u` escape of a surrogate stands for a character only as the first of a
   high and low pair, and every other one makes the string stand for no
   text, as do bytes that are not valid UTF-8. *)
let read_json_string bytes start =
  let byte = byte_at bytes in
  let buffer =
    Buffer.create
      (16
      [@mutaml.skip
        "The size that a buffer starts with changes no byte that it holds."])
  in
  let add_code_point point next =
    Buffer.add_utf_8_uchar buffer (Uchar.of_int point);
    `Next next
  in
  let escape i =
    match byte (i + 1) with
    | '"' -> add_code_point 0x22 (i + 2)
    | '\\' -> add_code_point 0x5C (i + 2)
    | '/' -> add_code_point 0x2F (i + 2)
    | 'b' -> add_code_point 0x08 (i + 2)
    | 'f' -> add_code_point 0x0C (i + 2)
    | 'n' -> add_code_point 0x0A (i + 2)
    | 'r' -> add_code_point 0x0D (i + 2)
    | 't' -> add_code_point 0x09 (i + 2)
    | 'u' -> (
        match four_hex_digits bytes (i + 2) with
        | None -> `Stop
        | Some unit when unit < 0xD800 || unit > 0xDFFF ->
            add_code_point unit (i + 6)
        | Some high
          when high <= 0xDBFF && byte (i + 6) = '\\' && byte (i + 7) = 'u' -> (
            match four_hex_digits bytes (i + 8) with
            | Some low when low >= 0xDC00 && low <= 0xDFFF ->
                add_code_point
                  (0x10000 + ((high - 0xD800) * 0x400) + (low - 0xDC00))
                  (i + 12)
            | Some _ | None -> `Stop)
        | Some _ -> `Stop)
    | _ -> `Stop
  in
  let rec go i =
    match byte i with
    | '"' -> (
        match Text.decode (Buffer.contents buffer) with
        | Ok text -> Some (text, i + 1)
        | Error _ -> None)
    | '\\' -> ( match escape i with `Next next -> go next | `Stop -> None)
    | '\000' .. '\031' -> None
    | other ->
        Buffer.add_char buffer other;
        go (i + 1)
  in
  go (start + 1)

(* @satisfies data-forms#{read-json-text=v1, give-only-json-values=v1}
   A number gives an integer only when it has no fraction and no exponent
   and writes a whole number from -(2^53 - 1) to 2^53 - 1, and then the
   integer that it writes; `-0` gives 0. *)
let read_json_number bytes start =
  let negative = byte_at bytes start = '-' in
  let digits_start = if negative then start + 1 else start in
  match byte_at bytes digits_start with
  | '0' -> Some (Integer 0, digits_start + 1)
  | '1' .. '9' -> read_digits bytes ~negative digits_start
  | _ -> None

(* @satisfies data-forms#{read-json-text=v1, give-only-json-values=v1}
   Gives a JSON value, and so the result valid, only when the whole byte
   sequence is one value of RFC 8259 with white space around it and its
   structural characters, with no `null`, and with no object whose names
   stand for one text twice; the value is the JSON value of the bytes. *)
let read_json_text bytes =
  let length = String.length bytes in
  let rec skip i =
    if is_white_space (byte_at bytes i) then skip (i + 1) else i
  in
  let at i byte = byte_at bytes i = byte in
  let rec value i stack =
    match byte_at bytes i with
    | '"' -> scalar (read_json_string bytes i) (fun text -> String text) stack
    | '-' | '0' .. '9' -> scalar (read_json_number bytes i) Fun.id stack
    | 't' -> scalar (read_literal bytes i "true" (Boolean true)) Fun.id stack
    | 'f' -> scalar (read_literal bytes i "false" (Boolean false)) Fun.id stack
    | '[' ->
        let next = skip (i + 1) in
        if at next ']' then complete (Array []) (skip (next + 1)) stack
        else value next (In_array [] :: stack)
    | '{' ->
        let next = skip (i + 1) in
        if at next '}' then complete (Object []) (skip (next + 1)) stack
        else member next [] stack
    | _ -> None
  and scalar : 'a. ('a * int) option -> ('a -> t) -> frame list -> t option =
   fun read make stack ->
    match read with
    | Some (v, next) -> complete (make v) (skip next) stack
    | None -> None
  and member i members stack =
    if not (at i '"') then None
    else
      match read_json_string bytes i with
      | None -> None
      | Some (key, next) ->
          let colon = skip next in
          if at colon ':' then
            value (skip (colon + 1)) (In_object (members, key) :: stack)
          else None
  and complete v i stack =
    match stack with
    | [] -> if i = length then Some v else None
    | In_array elements :: rest ->
        if at i ',' then value (skip (i + 1)) (In_array (v :: elements) :: rest)
        else if at i ']' then
          complete (Array (List.rev (v :: elements))) (skip (i + 1)) rest
        else None
    | In_object (members, key) :: rest ->
        let members = (key, v) :: members in
        if at i ',' then member (skip (i + 1)) members rest
        else if at i '}' then
          match object_ (List.rev members) with
          | Some value -> complete value (skip (i + 1)) rest
          | None -> None
        else None
  in
  value (skip 0) []
