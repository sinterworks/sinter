(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen

type date = { year : int; month : int; day : int }
type time = { hour : int; minute : int; second : int; nanosecond : int }
type offset = Minutes of int | Unknown_local

type value =
  | String of string
  | Integer of int64
  | Float of float
  | Boolean of bool
  | Local_date of date
  | Local_time of time
  | Local_date_time of date * time
  | Offset_date_time of date * time * offset
  | Array of value list
  | Table of (string * value) list

let same_float a b =
  (Float.is_nan a && Float.is_nan b)
  || Int64.equal (Int64.bits_of_float a) (Int64.bits_of_float b)

let rec equal a b =
  match (a, b) with
  | String a, String b -> String.equal a b
  | Integer a, Integer b -> Int64.equal a b
  | Float a, Float b -> same_float a b
  | Boolean a, Boolean b -> Bool.equal a b
  | Local_date a, Local_date b -> a = b
  | Local_time a, Local_time b -> a = b
  | Local_date_time (d, t), Local_date_time (d', t') -> d = d' && t = t'
  | Offset_date_time (d, t, o), Offset_date_time (d', t', o') ->
      d = d' && t = t' && o = o'
  | Array a, Array b -> List.length a = List.length b && List.for_all2 equal a b
  | Table a, Table b ->
      List.length a = List.length b
      && List.for_all
           (fun (key, value) ->
             match List.assoc_opt key b with
             | Some other -> equal value other
             | None -> false)
           a
  | _ -> false

let trim_zeros text =
  let stop = ref (String.length text) in
  while !stop > 0 && text.[!stop - 1] = '0' do
    decr stop
  done;
  if !stop > 0 && text.[!stop - 1] = '.' then decr stop;
  String.sub text 0 !stop

let float_form x =
  if Float.is_nan x then "nan"
  else if Float.equal x Float.infinity then "inf"
  else if Float.equal x Float.neg_infinity then "-inf"
  else if Float.equal x 0. then if Float.sign_bit x then "-0" else "0"
  else trim_zeros (Printf.sprintf "%.1074f" x)

let date_text { year; month; day } =
  Printf.sprintf "%04d-%02d-%02d" year month day

let time_text { hour; minute; second; nanosecond } =
  let base = Printf.sprintf "%02d:%02d:%02d" hour minute second in
  if nanosecond = 0 then base
  else base ^ "." ^ trim_zeros (Printf.sprintf "%09d" nanosecond)

let offset_text = function
  | Unknown_local -> "-00:00"
  | Minutes 0 -> "+00:00"
  | Minutes minutes ->
      Printf.sprintf "%c%02d:%02d"
        (if minutes > 0 then '+' else '-')
        (abs minutes / 60)
        (abs minutes mod 60)

let rec form value =
  let member key json = `Assoc [ (key, json) ] in
  match value with
  | String text -> member "string" (`String text)
  | Integer number -> member "integer" (`String (Int64.to_string number))
  | Float number -> member "float" (`String (float_form number))
  | Boolean flag -> member "boolean" (`Bool flag)
  | Local_date date -> member "local-date" (`String (date_text date))
  | Local_time time -> member "local-time" (`String (time_text time))
  | Local_date_time (date, time) ->
      member "local-date-time" (`String (date_text date ^ "T" ^ time_text time))
  | Offset_date_time (date, time, offset) ->
      member "offset-date-time"
        (`String (date_text date ^ "T" ^ time_text time ^ offset_text offset))
  | Array values -> member "array" (`List (List.map form values))
  | Table pairs -> member "table" (table_form pairs)

and table_form pairs =
  `Assoc (List.map (fun (key, value) -> (key, form value)) pairs)

let print value = Yojson.Basic.to_string (form value)
let is_leap year = (year mod 4 = 0 && year mod 100 <> 0) || year mod 400 = 0

let days_in_month year month =
  match month with
  | 2 -> if is_leap year then 29 else 28
  | 4 | 6 | 9 | 11 -> 30
  | _ -> 31

let number text from length = int_of_string (String.sub text from length)

let read_time text from =
  let hour = number text from 2 and minute = number text (from + 3) 2 in
  let second = number text (from + 6) 2 in
  let after = from + 8 in
  let stop = ref after in
  if after < String.length text && text.[after] = '.' then (
    stop := after + 1;
    while
      !stop < String.length text && text.[!stop] >= '0' && text.[!stop] <= '9'
    do
      incr stop
    done);
  let nanosecond =
    if !stop = after then 0
    else
      let digits = String.sub text (after + 1) (!stop - after - 1) in
      let digits =
        if String.length digits >= 9 then String.sub digits 0 9
        else digits ^ String.make (9 - String.length digits) '0'
      in
      int_of_string digits
  in
  ({ hour; minute; second; nanosecond }, !stop)

let read_date text =
  { year = number text 0 4; month = number text 5 2; day = number text 8 2 }

let read_offset text from =
  match text.[from] with
  | 'Z' | 'z' -> Minutes 0
  | sign ->
      let minutes =
        (number text (from + 1) 2 * 60) + number text (from + 4) 2
      in
      if sign = '-' && minutes = 0 then Unknown_local
      else Minutes (if sign = '-' then -minutes else minutes)

let toml_test_float text =
  match text with
  | "nan" | "+nan" | "-nan" -> Some Float.nan
  | "inf" | "+inf" -> Some Float.infinity
  | "-inf" -> Some Float.neg_infinity
  | text -> float_of_string_opt text

let typed kind text =
  match kind with
  | "string" -> Some (String text)
  | "integer" -> Option.map (fun n -> Integer n) (Int64.of_string_opt text)
  | "float" -> Option.map (fun x -> Float x) (toml_test_float text)
  | "bool" -> (
      match text with
      | "true" -> Some (Boolean true)
      | "false" -> Some (Boolean false)
      | _ -> None)
  | "date-local" -> Some (Local_date (read_date text))
  | "time-local" -> Some (Local_time (fst (read_time text 0)))
  | "datetime-local" ->
      Some (Local_date_time (read_date text, fst (read_time text 11)))
  | "datetime" ->
      let time, stop = read_time text 11 in
      Some (Offset_date_time (read_date text, time, read_offset text stop))
  | _ -> None

let rec of_toml_test (json : Yojson.Basic.t) =
  match json with
  | `Assoc [ ("type", `String kind); ("value", `String text) ]
  | `Assoc [ ("value", `String text); ("type", `String kind) ] ->
      typed kind text
  | `Assoc members ->
      let rec go acc = function
        | [] -> Some (Table (List.rev acc))
        | (key, value) :: rest -> (
            match of_toml_test value with
            | Some value -> go ((key, value) :: acc) rest
            | None -> None)
      in
      go [] members
  | `List items ->
      let rec go acc = function
        | [] -> Some (Array (List.rev acc))
        | item :: rest -> (
            match of_toml_test item with
            | Some value -> go (value :: acc) rest
            | None -> None)
      in
      go [] items
  | _ -> None

let position bytes offset =
  let start =
    if String.length bytes >= 3 && String.sub bytes 0 3 = "\xEF\xBB\xBF" then 3
    else 0
  in
  let line = ref 1 and column = ref 1 in
  for index = start to offset - 1 do
    let byte = Char.code bytes.[index] in
    if byte = 0x0A then (
      incr line;
      column := 1)
    else if byte land 0xC0 <> 0x80 then incr column
  done;
  (!line, !column)

type span = { start_byte : int; end_byte : int }
type located = { location : Yojson.Basic.t list; span : span }

type located_key = {
  key_location : Yojson.Basic.t list;
  key_span : span;
  parts : span list;
}

type document = {
  bytes : string;
  root : (string * value) list;
  values : located list;
  keys : located_key list;
  depth : int;
  key_parts : int;
}

let int st bound = Random.State.int st bound
let chance st percent = Random.State.int st 100 < percent
let pick st items = List.nth items (int st (List.length items))

let utf_8 code =
  let buffer = Buffer.create 4 in
  Buffer.add_utf_8_uchar buffer (Uchar.of_int code);
  Buffer.contents buffer

let edge_codes =
  [
    0x00;
    0x08;
    0x09;
    0x0A;
    0x0D;
    0x1B;
    0x1F;
    0x22;
    0x27;
    0x5C;
    0x7F;
    0x80;
    0x85;
    0xE9;
    0x301;
    0x2028;
    0xD7FF;
    0xE000;
    0xFEFF;
    0xFFFD;
    0xFFFF;
    0x10000;
    0x1F600;
    0x10FFFF;
  ]

let char_code st =
  match int st 10 with
  | 0 | 1 -> pick st edge_codes
  | 2 -> 0x80 + int st (0xD800 - 0x80)
  | 3 -> 0xE000 + int st (0x110000 - 0xE000)
  | _ -> 0x20 + int st 0x5F

let codes_of text =
  let rec go index acc =
    if index >= String.length text then List.rev acc
    else
      let decode = String.get_utf_8_uchar text index in
      go
        (index + Uchar.utf_decode_length decode)
        (Uchar.to_int (Uchar.utf_decode_uchar decode) :: acc)
  in
  go 0 []

let text st =
  let length = match int st 4 with 0 -> 0 | 1 -> 1 | _ -> int st 8 in
  String.concat "" (List.init length (fun _ -> utf_8 (char_code st)))

let is_bare_char = function
  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '-' | '_' -> true
  | _ -> false

let is_bare text = text <> "" && String.for_all is_bare_char text

let bare_words =
  [ "a"; "b"; "key"; "1234"; "true"; "inf"; "nan"; "-"; "_"; "a-b_c"; "0x1" ]

let key_text st =
  match int st 6 with
  | 0 -> ""
  | 1 -> text st
  | 2 -> pick st bare_words
  | _ ->
      String.init
        (1 + int st 6)
        (fun _ -> pick st [ 'a'; 'b'; 'c'; 'x'; 'Z'; '0'; '9'; '-'; '_' ])

let hex_case st text =
  if chance st 50 then String.uppercase_ascii text else text

let escape_of st code =
  let named =
    match code with
    | 0x08 -> [ "\\b" ]
    | 0x09 -> [ "\\t" ]
    | 0x0A -> [ "\\n" ]
    | 0x0C -> [ "\\f" ]
    | 0x0D -> [ "\\r" ]
    | 0x1B -> [ "\\e" ]
    | 0x22 -> [ "\\\"" ]
    | 0x5C -> [ "\\\\" ]
    | _ -> []
  in
  let numeric =
    (if code <= 0xFF then [ "\\x" ^ hex_case st (Printf.sprintf "%02x" code) ]
     else [])
    @ (if code <= 0xFFFF then
         [ "\\u" ^ hex_case st (Printf.sprintf "%04x" code) ]
       else [])
    @ [ "\\U" ^ hex_case st (Printf.sprintf "%08x" code) ]
  in
  pick st (named @ numeric)

let must_escape code =
  (code < 0x20 && code <> 0x09) || code = 0x7F || code = 0x22 || code = 0x5C

let write_basic st text =
  let body =
    List.map
      (fun code ->
        if must_escape code || chance st 15 then escape_of st code
        else utf_8 code)
      (codes_of text)
  in
  "\"" ^ String.concat "" body ^ "\""

let is_literal_char code =
  code = 0x09 || (code >= 0x20 && code <= 0x7E && code <> 0x27) || code >= 0x80

let write_literal text = "'" ^ text ^ "'"
let newline st = if chance st 25 then "\r\n" else "\n"

let ws st =
  match int st 6 with 0 -> " " | 1 -> "\t" | 2 -> "  " | 3 -> " \t" | _ -> ""

let write_ml_basic st text =
  let codes = Array.of_list (codes_of text) in
  let count = Array.length codes in
  let buffer = Buffer.create 16 in
  Buffer.add_string buffer "\"\"\"";
  Buffer.add_string buffer (newline st);
  let index = ref 0 in
  while !index < count do
    let code = codes.(!index) in
    let piece, width =
      if
        code = 0x0D
        && !index + 1 < count
        && codes.(!index + 1) = 0x0A
        && chance st 60
      then ("\r\n", 2)
      else if code = 0x0A && chance st 70 then ("\n", 1)
      else if must_escape code || chance st 15 then (escape_of st code, 1)
      else (utf_8 code, 1)
    in
    let starts_with_space =
      match piece.[0] with ' ' | '\t' | '\n' | '\r' -> true | _ -> false
    in
    if (not starts_with_space) && chance st 15 then (
      Buffer.add_string buffer ("\\" ^ ws st ^ newline st);
      if chance st 50 then Buffer.add_string buffer (ws st ^ newline st ^ ws st));
    Buffer.add_string buffer piece;
    index := !index + width
  done;
  Buffer.add_string buffer "\"\"\"";
  Buffer.contents buffer

let ml_literal_ok codes =
  let rec go = function
    | [] -> true
    | 0x0D :: 0x0A :: rest -> go rest
    | 0x0A :: rest -> go rest
    | code :: rest -> is_literal_char code && go rest
  in
  go codes

let write_string st text =
  let codes = codes_of text in
  let literal_ok = List.for_all is_literal_char codes in
  let choices =
    [ `Basic; `Ml_basic ]
    @ (if literal_ok then [ `Literal ] else [])
    @ if ml_literal_ok codes then [ `Ml_literal ] else []
  in
  match pick st choices with
  | `Basic -> write_basic st text
  | `Ml_basic -> write_ml_basic st text
  | `Literal -> write_literal text
  | `Ml_literal -> "'''" ^ newline st ^ text ^ "'''"

let write_key_text st text =
  let codes = codes_of text in
  if is_bare text && chance st 75 then text
  else if List.for_all is_literal_char codes && chance st 40 then
    write_literal text
  else write_basic st text

let with_underscores st digits =
  let buffer = Buffer.create 24 in
  String.iteri
    (fun index char ->
      if index > 0 && chance st 10 then Buffer.add_char buffer '_';
      Buffer.add_char buffer char)
    digits;
  Buffer.contents buffer

let digits_in_base base number =
  if Int64.equal number 0L then "0"
  else
    let rec go n acc =
      if Int64.equal n 0L then acc
      else
        go (Int64.div n base)
          (String.make 1 "0123456789abcdef".[Int64.to_int (Int64.rem n base)]
          ^ acc)
    in
    go number ""

let write_integer st number =
  if Int64.compare number 0L >= 0 && chance st 40 then
    let base, prefix = pick st [ (16L, "0x"); (8L, "0o"); (2L, "0b") ] in
    let zeros = String.make (if chance st 20 then 1 + int st 3 else 0) '0' in
    prefix
    ^ with_underscores st (hex_case st (zeros ^ digits_in_base base number))
  else
    let text = Int64.to_string number in
    if text.[0] = '-' then
      "-" ^ with_underscores st (String.sub text 1 (String.length text - 1))
    else (if chance st 20 then "+" else "") ^ with_underscores st text

let write_float st number =
  if Float.is_nan number then pick st [ "nan"; "+nan"; "-nan" ]
  else if Float.equal number Float.infinity then pick st [ "inf"; "+inf" ]
  else if Float.equal number Float.neg_infinity then "-inf"
  else
    let sign =
      if Float.sign_bit number then "-" else if chance st 20 then "+" else ""
    in
    let magnitude = Printf.sprintf "%.17g" (Float.abs number) in
    let magnitude =
      if String.contains magnitude '.' || String.contains magnitude 'e' then
        magnitude
      else magnitude ^ if chance st 50 then ".0" else "e0"
    in
    let magnitude =
      if chance st 30 then String.map (function 'e' -> 'E' | c -> c) magnitude
      else magnitude
    in
    sign ^ magnitude

let write_date date = date_text date

let write_time st { hour; minute; second; nanosecond } =
  let base = Printf.sprintf "%02d:%02d" hour minute in
  if second = 0 && nanosecond = 0 && chance st 30 then base
  else
    let base = base ^ Printf.sprintf ":%02d" second in
    if nanosecond = 0 then
      if chance st 20 then base ^ "." ^ String.make (1 + int st 4) '0' else base
    else
      let digits = Printf.sprintf "%09d" nanosecond in
      let digits =
        match int st 3 with
        | 0 -> trim_zeros digits
        | 1 ->
            digits ^ String.init (int st 5) (fun _ -> Char.chr (48 + int st 10))
        | _ -> digits
      in
      let digits = if digits = "" then "0" else digits in
      base ^ "." ^ digits

let write_delimiter st = pick st [ "T"; "t"; " " ]

let write_offset st = function
  | Unknown_local -> "-00:00"
  | Minutes 0 -> pick st [ "Z"; "z"; "+00:00" ]
  | offset -> offset_text offset

let write_scalar st = function
  | String text -> write_string st text
  | Integer number -> write_integer st number
  | Float number -> write_float st number
  | Boolean flag -> if flag then "true" else "false"
  | Local_date date -> write_date date
  | Local_time time -> write_time st time
  | Local_date_time (date, time) ->
      write_date date ^ write_delimiter st ^ write_time st time
  | Offset_date_time (date, time, offset) ->
      write_date date ^ write_delimiter st ^ write_time st time
      ^ write_offset st offset
  | Array _ | Table _ -> invalid_arg "write_scalar"

let comment_codes =
  [ 0x09; 0x20; 0x23; 0x41; 0x7E; 0xE9; 0xFEFF; 0x1F600; 0x22; 0x5C ]

let comment st =
  "#"
  ^ String.concat ""
      (List.init (int st 5) (fun _ -> utf_8 (pick st comment_codes)))

let line_end st =
  (if chance st 30 then ws st ^ comment st else ws st) ^ newline st

let ws_comment_newline st =
  String.concat ""
    (List.init (int st 3) (fun _ ->
         match int st 3 with
         | 0 -> ws st
         | 1 -> newline st
         | _ -> ws st ^ comment st ^ newline st))

let int64_gen st =
  match int st 5 with
  | 0 ->
      pick st
        [ 0L; 1L; -1L; Int64.max_int; Int64.min_int; 255L; 1_000_000L; -17L ]
  | 1 -> Int64.of_int (int st 1000 - 500)
  | _ -> Random.State.bits64 st

let float_gen st =
  match int st 4 with
  | 0 ->
      pick st
        [
          0.;
          -0.;
          0.1;
          0.5;
          1.;
          -1.;
          1e300;
          Float.max_float;
          Float.min_float;
          4.9406564584124654e-324;
          9007199254740992.;
          1e22;
          Float.infinity;
          Float.neg_infinity;
          Float.nan;
          -2.5e-8;
        ]
  | 1 -> Float.of_int (int st 2000 - 1000) /. 8.
  | _ ->
      let bits = Random.State.bits64 st in
      Int64.float_of_bits bits

let date_gen st =
  let year =
    pick st [ 0; 1; 1600; 1900; 1979; 2000; 2024; 9999; int st 10000 ]
  in
  let month = 1 + int st 12 in
  let day =
    if chance st 30 then days_in_month year month
    else 1 + int st (days_in_month year month)
  in
  { year; month; day }

let time_gen st =
  {
    hour = int st 24;
    minute = int st 60;
    second = (if chance st 10 then 60 else int st 60);
    nanosecond =
      (match int st 4 with
      | 0 | 1 -> 0
      | 2 -> pick st [ 1; 500_000_000; 999_999_999; 123_456_789; 100 ]
      | _ -> int st 1_000_000_000);
  }

let offset_gen st =
  match int st 4 with
  | 0 -> Unknown_local
  | 1 -> Minutes 0
  | _ -> Minutes (int st 2879 - 1439)

let unique_keys st count =
  let rec go acc remaining tries =
    if remaining = 0 || tries = 0 then List.rev acc
    else
      let key = key_text st in
      if List.mem key acc then go acc remaining (tries - 1)
      else go (key :: acc) (remaining - 1) tries
  in
  go [] count 50

let rec value_gen st depth =
  match int st (if depth > 0 then 13 else 9) with
  | 0 | 1 -> String (text st)
  | 2 -> Integer (int64_gen st)
  | 3 -> Float (float_gen st)
  | 4 -> Boolean (chance st 50)
  | 5 -> Local_date (date_gen st)
  | 6 -> Local_time (time_gen st)
  | 7 -> Local_date_time (date_gen st, time_gen st)
  | 8 -> Offset_date_time (date_gen st, time_gen st, offset_gen st)
  | 9 | 10 -> Array (List.init (int st 4) (fun _ -> value_gen st (depth - 1)))
  | 11 ->
      Array
        (List.init (1 + int st 3) (fun _ -> Table (table_gen st (depth - 1))))
  | _ -> Table (table_gen st (depth - 1))

and table_gen ?(least = 0) st depth =
  List.map
    (fun key -> (key, value_gen st depth))
    (unique_keys st (least + int st 5))

type writer = {
  st : Random.State.t;
  buffer : Buffer.t;
  mutable values : located list;
  mutable keys : located_key list;
  mutable level : int;
  mutable deepest : int;
}

let add writer text = Buffer.add_string writer.buffer text
let here writer = Buffer.length writer.buffer

let record_value writer location start =
  writer.values <-
    { location; span = { start_byte = start; end_byte = here writer } }
    :: writer.values

let write_key writer texts =
  let start = here writer in
  let parts =
    List.mapi
      (fun index text ->
        if index > 0 then add writer (ws writer.st ^ "." ^ ws writer.st);
        let part_start = here writer in
        add writer (write_key_text writer.st text);
        { start_byte = part_start; end_byte = here writer })
      texts
  in
  ({ start_byte = start; end_byte = here writer }, parts)

let record_key writer key_location (key_span, parts) =
  writer.keys <- { key_location; key_span; parts } :: writer.keys

let step key = `String key
let is_table = function Table _ -> true | _ -> false

let is_array_of_tables = function
  | Array (_ :: _ as items) -> List.for_all is_table items
  | _ -> false

let rec write_inline writer location value =
  let start = here writer in
  let enter () =
    writer.level <- writer.level + 1;
    writer.deepest <- max writer.deepest writer.level
  in
  (match value with
  | Array items ->
      enter ();
      add writer "[";
      List.iteri
        (fun index item ->
          add writer (ws_comment_newline writer.st);
          write_inline writer (location @ [ `Int (index + 1) ]) item;
          add writer (ws_comment_newline writer.st);
          if index + 1 < List.length items || chance writer.st 30 then
            add writer ",")
        items;
      add writer (ws_comment_newline writer.st);
      add writer "]";
      writer.level <- writer.level - 1
  | Table pairs ->
      enter ();
      add writer "{";
      let count = List.length pairs in
      List.iteri
        (fun index (key, value) ->
          add writer (ws_comment_newline writer.st);
          write_inline_pair writer location [ key ] value;
          add writer (ws_comment_newline writer.st);
          if index + 1 < count || chance writer.st 30 then add writer ",")
        pairs;
      add writer (ws_comment_newline writer.st);
      add writer "}";
      writer.level <- writer.level - 1
  | scalar -> add writer (write_scalar writer.st scalar));
  record_value writer location start

and write_inline_pair writer holding keys value =
  match value with
  | Table (_ :: _ as pairs) when chance writer.st 40 ->
      List.iteri
        (fun index (key, value) ->
          if index > 0 then (
            add writer (ws_comment_newline writer.st);
            add writer ",";
            add writer (ws_comment_newline writer.st));
          write_inline_pair writer holding (keys @ [ key ]) value)
        pairs
  | _ ->
      let key = write_key writer keys in
      record_key writer (holding @ List.map step keys) key;
      add writer (ws writer.st ^ "=" ^ ws writer.st);
      write_inline writer (holding @ List.map step keys) value

let rec write_dotted writer holding keys value =
  match value with
  | Table (_ :: _ as pairs) when chance writer.st 50 ->
      List.iter
        (fun (key, value) -> write_dotted writer holding (keys @ [ key ]) value)
        pairs
  | _ ->
      add writer (ws writer.st);
      let key = write_key writer keys in
      record_key writer (holding @ List.map step keys) key;
      add writer (ws writer.st ^ "=" ^ ws writer.st);
      write_inline writer (holding @ List.map step keys) value;
      add writer (line_end writer.st)

let rec write_section writer ~header_keys ~location pairs =
  let headed = choose_headed writer pairs in
  write_pairs writer ~location pairs headed;
  write_headers writer ~header_keys ~location headed

and choose_headed writer pairs =
  List.filter
    (fun (_, value) ->
      (is_table value || is_array_of_tables value) && chance writer.st 60)
    pairs

and write_pairs writer ~location pairs headed =
  List.iter
    (fun (key, value) ->
      if not (List.mem_assoc key headed) then
        write_dotted writer location [ key ] value;
      if chance writer.st 15 then add writer (line_end writer.st))
    pairs

and write_headers writer ~header_keys ~location headed =
  List.iter
    (fun (key, value) ->
      let keys = header_keys @ [ key ] in
      match value with
      | Table pairs ->
          let skip =
            pairs <> []
            && List.for_all (fun (_, v) -> is_table v) pairs
            && chance writer.st 30
          in
          if skip then
            write_section_headed writer ~header_keys:keys
              ~location:(location @ [ step key ])
              pairs
          else
            write_header writer ~double:false keys
              (location @ [ step key ])
              pairs
      | Array items ->
          List.iteri
            (fun index item ->
              match item with
              | Table pairs ->
                  write_header writer ~double:true keys
                    (location @ [ step key; `Int (index + 1) ])
                    pairs
              | _ -> invalid_arg "write_headers")
            items
      | _ -> invalid_arg "write_headers")
    headed

and write_section_headed writer ~header_keys ~location pairs =
  List.iter
    (fun (key, value) ->
      match value with
      | Table sub ->
          write_header writer ~double:false (header_keys @ [ key ])
            (location @ [ step key ])
            sub
      | _ -> invalid_arg "write_section_headed")
    pairs

and write_header writer ~double keys location pairs =
  let header_line () =
    add writer (ws writer.st);
    add writer (if double then "[[" else "[");
    add writer (ws writer.st);
    let key = write_key writer keys in
    record_key writer location key;
    add writer (ws writer.st);
    add writer (if double then "]]" else "]");
    add writer (line_end writer.st)
  in
  let headed = choose_headed writer pairs in
  if (not double) && headed <> [] && chance writer.st 30 then begin
    write_headers writer ~header_keys:keys ~location headed;
    header_line ();
    write_pairs writer ~location pairs headed
  end
  else begin
    header_line ();
    write_pairs writer ~location pairs headed;
    write_headers writer ~header_keys:keys ~location headed
  end

let write_document st root =
  let writer =
    {
      st;
      buffer = Buffer.create 256;
      values = [];
      keys = [];
      level = 0;
      deepest = 0;
    }
  in
  if chance st 10 then add writer "\xEF\xBB\xBF";
  if chance st 20 then add writer (line_end st);
  write_section writer ~header_keys:[] ~location:[] root;
  let bytes = Buffer.contents writer.buffer in
  let bytes =
    if chance st 10 && String.ends_with ~suffix:"\n" bytes then
      String.sub bytes 0
        (String.length bytes
        - if String.ends_with ~suffix:"\r\n" bytes then 2 else 1)
    else bytes
  in
  let keys = List.rev writer.keys in
  {
    bytes;
    root;
    values = List.rev writer.values;
    keys;
    depth = writer.deepest;
    key_parts =
      List.fold_left (fun most key -> max most (List.length key.parts)) 0 keys;
  }

let document_gen =
  Gen.make_primitive
    ~gen:(fun st -> write_document st (table_gen ~least:1 st (1 + int st 4)))
    ~shrink:(fun _ -> Seq.empty)

let write_value value =
  Gen.make_primitive
    ~gen:(fun st ->
      let writer =
        {
          st;
          buffer = Buffer.create 64;
          values = [];
          keys = [];
          level = 0;
          deepest = 0;
        }
      in
      write_inline writer [] value;
      Buffer.contents writer.buffer)
    ~shrink:(fun _ -> Seq.empty)

let key_gen = Gen.make_primitive ~gen:key_text ~shrink:(fun _ -> Seq.empty)

let write_key text =
  Gen.make_primitive
    ~gen:(fun st -> write_key_text st text)
    ~shrink:(fun _ -> Seq.empty)

let print_document document = Printf.sprintf "%S" document.bytes

let nested_arrays depth =
  "a = " ^ String.make depth '[' ^ String.make depth ']' ^ "\n"

let nested_inline_tables depth =
  let buffer = Buffer.create (depth * 8) in
  Buffer.add_string buffer "a = ";
  for index = 1 to depth do
    Buffer.add_string buffer (if index < depth then "{ b = " else "{}")
  done;
  for _ = 2 to depth do
    Buffer.add_string buffer " }"
  done;
  Buffer.add_string buffer "\n";
  Buffer.contents buffer

let dotted_parts parts = String.concat "." (List.init parts (fun _ -> "a"))
let dotted_key parts = dotted_parts parts ^ " = 1\n"
let dotted_header parts = "[" ^ dotted_parts parts ^ "]\n"

let syntax_bytes =
  [
    "[";
    "]";
    "{";
    "}";
    "=";
    ".";
    ",";
    "\"";
    "'";
    "\\";
    "#";
    "\n";
    "\r";
    " ";
    "\t";
    "0";
    "a";
    "_";
    "-";
    "+";
    ":";
    "T";
    "Z";
    "\xEF\xBB\xBF";
    "\xC3";
    "\xA9";
    "\xFF";
    "\xED\xA0\x80";
    "\x00";
    "\x7F";
    "\"\"\"";
    "'''";
    "e";
    "inf";
    "nan";
    "true";
    "1979-05-27";
    "07:32:00";
    "\\u";
    "\\U0010FFFF";
    "[[";
    "]]";
  ]

let corrupt_gen bytes =
  Gen.make_primitive
    ~gen:(fun st ->
      let rec go bytes edits =
        if edits = 0 then bytes
        else
          let length = String.length bytes in
          let at = if length = 0 then 0 else int st (length + 1) in
          let piece =
            if chance st 70 then pick st syntax_bytes
            else String.make 1 (Char.chr (int st 256))
          in
          let bytes =
            match int st 3 with
            | 0 ->
                String.sub bytes 0 at ^ piece ^ String.sub bytes at (length - at)
            | 1 when at < length ->
                String.sub bytes 0 at
                ^ String.sub bytes (at + 1) (length - at - 1)
            | _ when at < length ->
                String.sub bytes 0 at ^ piece
                ^ String.sub bytes (at + 1) (length - at - 1)
            | _ -> bytes ^ piece
          in
          go bytes (edits - 1)
      in
      go bytes (1 + int st 3))
    ~shrink:(fun _ -> Seq.empty)

let noise_gen =
  Gen.make_primitive
    ~gen:(fun st ->
      String.concat ""
        (List.init (int st 40) (fun _ ->
             if chance st 80 then pick st syntax_bytes
             else String.make 1 (Char.chr (int st 256)))))
    ~shrink:(fun _ -> Seq.empty)
