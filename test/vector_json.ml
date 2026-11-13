(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen

type str = Text of string | No_text of int list

type t =
  | Null
  | Bool of bool
  | Number of string
  | String of str
  | Array of t list
  | Object of (str * t) list

let backslash = '\\'

let hex_value char =
  match char with
  | '0' .. '9' -> Some (Char.code char - Char.code '0')
  | 'a' .. 'f' -> Some (Char.code char - Char.code 'a' + 10)
  | 'A' .. 'F' -> Some (Char.code char - Char.code 'A' + 10)
  | _ -> None

let four_hex literal index =
  if index + 4 > String.length literal then None
  else
    let rec go offset acc =
      if offset = 4 then Some acc
      else
        match hex_value literal.[index + offset] with
        | Some digit -> go (offset + 1) ((acc * 16) + digit)
        | None -> None
    in
    go 0 0

let escape_at literal index =
  if
    index + 1 < String.length literal
    && literal.[index] = backslash
    && literal.[index + 1] = 'u'
  then four_hex literal (index + 2)
  else None

let units_of_utf_8 bytes =
  let length = String.length bytes in
  let byte index =
    if index < length then Char.code bytes.[index] land 0x3F
    else invalid_arg "units_of_utf_8"
  in
  let rec go index acc =
    if index >= length then List.rev acc
    else
      let lead = Char.code bytes.[index] in
      if lead < 0x80 then go (index + 1) (lead :: acc)
      else if lead land 0xE0 = 0xC0 then
        go (index + 2) ((((lead land 0x1F) lsl 6) lor byte (index + 1)) :: acc)
      else if lead land 0xF0 = 0xE0 then
        go (index + 3)
          (((lead land 0x0F) lsl 12)
           lor (byte (index + 1) lsl 6)
           lor byte (index + 2)
          :: acc)
      else
        let code =
          ((lead land 0x07) lsl 18)
          lor (byte (index + 1) lsl 12)
          lor (byte (index + 2) lsl 6)
          lor byte (index + 3)
        in
        go (index + 4)
          ((0xDC00 + ((code - 0x10000) mod 0x400))
          :: (0xD800 + ((code - 0x10000) / 0x400))
          :: acc)
  in
  go 0 []

let text_of_units units =
  let buffer = Buffer.create 16 in
  let rec go = function
    | [] -> Some (Buffer.contents buffer)
    | high :: low :: rest
      when high >= 0xD800 && high <= 0xDBFF && low >= 0xDC00 && low <= 0xDFFF ->
        Buffer.add_utf_8_uchar buffer
          (Uchar.of_int (0x10000 + ((high - 0xD800) * 0x400) + (low - 0xDC00)));
        go rest
    | unit :: rest
      when unit >= 0 && unit <= 0xFFFF && not (unit >= 0xD800 && unit <= 0xDFFF)
      ->
        Buffer.add_utf_8_uchar buffer (Uchar.of_int unit);
        go rest
    | _ -> None
  in
  go units

let str_of_units units =
  match text_of_units units with
  | Some text -> Text text
  | None -> No_text units

let decode_literal literal =
  let length = String.length literal in
  if length < 2 || literal.[0] <> '"' || literal.[length - 1] <> '"' then
    failwith ("not a string literal: " ^ literal);
  let body = String.sub literal 1 (length - 2) in
  let raw = Buffer.create 16 in
  let units = ref [] in
  let flush () =
    let bytes = Buffer.contents raw in
    if not (String.is_valid_utf_8 bytes) then
      failwith ("a string literal that is not UTF-8: " ^ literal);
    units := List.rev_append (units_of_utf_8 bytes) !units;
    Buffer.clear raw
  in
  let escaped unit = units := unit :: !units in
  let rec go index =
    if index < String.length body then
      if body.[index] <> backslash then (
        Buffer.add_char raw body.[index];
        go (index + 1))
      else (
        flush ();
        match body.[index + 1] with
        | ('"' | '\\' | '/') as char ->
            escaped (Char.code char);
            go (index + 2)
        | 'b' ->
            escaped 0x08;
            go (index + 2)
        | 'f' ->
            escaped 0x0C;
            go (index + 2)
        | 'n' ->
            escaped 0x0A;
            go (index + 2)
        | 'r' ->
            escaped 0x0D;
            go (index + 2)
        | 't' ->
            escaped 0x09;
            go (index + 2)
        | 'u' -> (
            match escape_at body index with
            | None -> failwith ("a bad escape sequence in " ^ literal)
            | Some unit ->
                escaped unit;
                go (index + 6))
        | _ -> failwith ("a bad escape sequence in " ^ literal))
  in
  go 0;
  flush ();
  str_of_units (List.rev !units)

let key name = str_of_units (units_of_utf_8 name)

let rec of_raw (raw : Yojson.Raw.t) =
  match raw with
  | `Null -> Null
  | `Bool value -> Bool value
  | `Intlit number | `Floatlit number -> Number number
  | `Stringlit literal -> String (decode_literal literal)
  | `List elements -> Array (List.map of_raw elements)
  | `Assoc members ->
      Object (List.map (fun (name, value) -> (key name, of_raw value)) members)

let read json_text =
  match Yojson.Raw.from_string json_text with
  | raw -> of_raw raw
  | exception Yojson.Json_error message ->
      failwith (Printf.sprintf "not a JSON text: %s: %s" message json_text)

let largest = 9007199254740991

let digits_from number start =
  let rec go index =
    if
      index < String.length number
      && number.[index] >= '0'
      && number.[index] <= '9'
    then go (index + 1)
    else index
  in
  go start

let integer number =
  let length = String.length number in
  let negative = length > 0 && number.[0] = '-' in
  let start = if negative then 1 else 0 in
  let int_end = digits_from number start in
  let int_part = String.sub number start (int_end - start) in
  let int_ok = int_part <> "" && (int_part = "0" || int_part.[0] <> '0') in
  let frac, after_frac =
    if int_end < length && number.[int_end] = '.' then
      let frac_end = digits_from number (int_end + 1) in
      (Some (String.sub number (int_end + 1) (frac_end - int_end - 1)), frac_end)
    else (None, int_end)
  in
  let exponent, after_exp =
    if
      after_frac < length
      && (number.[after_frac] = 'e' || number.[after_frac] = 'E')
    then
      let sign_at = after_frac + 1 in
      let sign, digits_at =
        if sign_at < length && (number.[sign_at] = '+' || number.[sign_at] = '-')
        then ((if number.[sign_at] = '-' then -1 else 1), sign_at + 1)
        else (1, sign_at)
      in
      let exp_end = digits_from number digits_at in
      let digits = String.sub number digits_at (exp_end - digits_at) in
      ( (if digits = "" then None
         else if String.length digits > 9 then Some (sign * 1_000_000_000)
         else Some (sign * int_of_string digits)),
        exp_end )
    else (Some 0, after_frac)
  in
  match (int_ok, frac, exponent) with
  | false, _, _ | _, Some "", _ | _, _, None -> None
  | true, _, Some _ when after_exp <> length -> None
  | true, frac, Some exponent ->
      let frac = Option.value frac ~default:"" in
      let digits = int_part ^ frac in
      let exponent = exponent - String.length frac in
      let rec strip_leading index =
        if index < String.length digits && digits.[index] = '0' then
          strip_leading (index + 1)
        else index
      in
      let first = strip_leading 0 in
      let digits = String.sub digits first (String.length digits - first) in
      if digits = "" then Some 0
      else
        let rec strip_trailing last exponent =
          if digits.[last] = '0' then strip_trailing (last - 1) (exponent + 1)
          else (String.sub digits 0 (last + 1), exponent)
        in
        let digits, exponent =
          strip_trailing (String.length digits - 1) exponent
        in
        if exponent < 0 || String.length digits + exponent > 16 then None
        else
          let magnitude = int_of_string (digits ^ String.make exponent '0') in
          if magnitude > largest then None
          else Some (if negative then -magnitude else magnitude)

let rec of_basic (json : Yojson.Basic.t) =
  match json with
  | `Null -> Null
  | `Bool value -> Bool value
  | `Int number -> Number (string_of_int number)
  | `Float number -> Number (Printf.sprintf "%.17g" number)
  | `String text ->
      String
        (if String.is_valid_utf_8 text then Text text
         else invalid_arg "of_basic")
  | `List elements -> Array (List.map of_basic elements)
  | `Assoc members ->
      Object
        (List.map
           (fun (name, value) ->
             if String.is_valid_utf_8 name then (Text name, of_basic value)
             else invalid_arg "of_basic")
           members)

let uchars text =
  let rec go index acc =
    if index >= String.length text then List.rev acc
    else
      let decode = String.get_utf_8_uchar text index in
      go
        (index + Uchar.utf_decode_length decode)
        (Uchar.utf_decode_uchar decode :: acc)
  in
  go 0 []

let utf_16_code_units text =
  List.concat_map
    (fun uchar ->
      let code = Uchar.to_int uchar in
      if code < 0x10000 then [ code ]
      else
        [
          0xD800 + ((code - 0x10000) / 0x400);
          0xDC00 + ((code - 0x10000) mod 0x400);
        ])
    (uchars text)

let units = function
  | Text text -> utf_16_code_units text
  | No_text units -> units

let compare_keys a b =
  List.compare Int.compare (utf_16_code_units a) (utf_16_code_units b)

let text_keys members =
  List.filter_map
    (function Text name, _ -> Some name | No_text _, _ -> None)
    members

let unique_keys members =
  let names = text_keys members in
  List.length names = List.length members
  && List.length (List.sort_uniq String.compare names) = List.length names

let rec is_json_value = function
  | Null -> false
  | Bool _ -> true
  | Number number -> Option.is_some (integer number)
  | String (Text _) -> true
  | String (No_text _) -> false
  | Array elements -> List.for_all is_json_value elements
  | Object members ->
      unique_keys members
      && List.for_all (fun (_, value) -> is_json_value value) members

let is_scalar = function
  | Bool _ | Number _ | String _ -> true
  | Null | Array _ | Object _ -> false

let is_flat_object = function
  | Object members -> List.for_all (fun (_, value) -> is_scalar value) members
  | _ -> false

let is_line_member = function
  | Array elements ->
      List.for_all is_scalar elements || List.for_all is_flat_object elements
  | value -> is_scalar value

let is_line_object thing =
  is_json_value thing
  &&
  match thing with
  | Object members ->
      List.for_all (fun (_, value) -> is_line_member value) members
  | _ -> false

let add_string_form buffer text =
  Buffer.add_char buffer '"';
  List.iter
    (fun uchar ->
      match Uchar.to_int uchar with
      | 0x22 -> Buffer.add_string buffer "\\\""
      | 0x5C -> Buffer.add_string buffer "\\\\"
      | 0x08 -> Buffer.add_string buffer "\\b"
      | 0x09 -> Buffer.add_string buffer "\\t"
      | 0x0A -> Buffer.add_string buffer "\\n"
      | 0x0C -> Buffer.add_string buffer "\\f"
      | 0x0D -> Buffer.add_string buffer "\\r"
      | code when code < 0x20 ->
          Buffer.add_char buffer backslash;
          Buffer.add_string buffer (Printf.sprintf "u00%02x" code)
      | _ -> Buffer.add_utf_8_uchar buffer uchar)
    (uchars text);
  Buffer.add_char buffer '"'

let rec add_canonical buffer = function
  | Bool true -> Buffer.add_string buffer "true"
  | Bool false -> Buffer.add_string buffer "false"
  | Number number -> (
      match integer number with
      | Some value -> Buffer.add_string buffer (string_of_int value)
      | None -> invalid_arg "add_canonical")
  | String (Text text) -> add_string_form buffer text
  | Array elements ->
      Buffer.add_char buffer '[';
      List.iteri
        (fun index element ->
          if index > 0 then Buffer.add_char buffer ',';
          add_canonical buffer element)
        elements;
      Buffer.add_char buffer ']'
  | Object members ->
      let members =
        List.filter_map
          (function
            | Text name, value -> Some (name, value) | No_text _, _ -> None)
          members
      in
      Buffer.add_char buffer '{';
      List.iteri
        (fun index (name, value) ->
          if index > 0 then Buffer.add_char buffer ',';
          add_string_form buffer name;
          Buffer.add_char buffer ':';
          add_canonical buffer value)
        (List.sort (fun (a, _) (b, _) -> compare_keys a b) members);
      Buffer.add_char buffer '}'
  | Null | String (No_text _) -> invalid_arg "add_canonical"

let canonical thing =
  if is_json_value thing then (
    let buffer = Buffer.create 64 in
    add_canonical buffer thing;
    Some (Buffer.contents buffer))
  else None

let canonical_line thing =
  if is_line_object thing then
    Option.map (fun bytes -> bytes ^ "\n") (canonical thing)
  else None

let rec to_basic : t -> Yojson.Basic.t = function
  | Bool value -> `Bool value
  | Number number -> (
      match integer number with
      | Some value -> `Int value
      | None -> invalid_arg "to_basic")
  | String (Text text) -> `String text
  | Array elements -> `List (List.map to_basic elements)
  | Object members ->
      `Assoc
        (List.map
           (function
             | Text name, value -> (name, to_basic value)
             | No_text _, _ -> invalid_arg "to_basic")
           members)
  | Null | String (No_text _) -> invalid_arg "to_basic"

let hex bytes =
  String.concat ""
    (List.map
       (fun char -> Printf.sprintf "%02x" (Char.code char))
       (List.of_seq (String.to_seq bytes)))

let of_hex digits =
  if String.length digits mod 2 <> 0 then invalid_arg "of_hex";
  String.init
    (String.length digits / 2)
    (fun index ->
      match
        (hex_value digits.[2 * index], hex_value digits.[(2 * index) + 1])
      with
      | Some high, Some low -> Char.chr ((high * 16) + low)
      | _ -> invalid_arg "of_hex")

let print_str = function
  | Text text -> Yojson.Basic.to_string (`String text)
  | No_text units ->
      "<no text: "
      ^ String.concat " " (List.map (Printf.sprintf "%04X") units)
      ^ ">"

let rec print = function
  | Null -> "null"
  | Bool value -> string_of_bool value
  | Number number -> number
  | String text -> print_str text
  | Array elements -> "[" ^ String.concat "," (List.map print elements) ^ "]"
  | Object members ->
      "{"
      ^ String.concat ","
          (List.map
             (fun (name, value) -> print_str name ^ ":" ^ print value)
             members)
      ^ "}"

let edge_codes =
  [
    0x00;
    0x0E;
    0x10;
    0x1A;
    0x1B;
    0x1E;
    0x103FF;
    0x10400;
    0x10401;
    0x08;
    0x09;
    0x0A;
    0x0B;
    0x0C;
    0x0D;
    0x1F;
    0x20;
    0x22;
    0x2F;
    0x41;
    0x5C;
    0x61;
    0x7F;
    0x80;
    0xE9;
    0x2028;
    0x2029;
    0xD7FF;
    0xE000;
    0xFDD0;
    0xFFFE;
    0xFFFF;
    0x10000;
    0x1F600;
    0x10FFFF;
  ]

let uchar_gen =
  Gen.oneof_weighted
    [
      (3, Gen.map Uchar.of_int (Gen.oneof_list edge_codes));
      (2, Gen.map Uchar.of_int (Gen.int_range 0x20 0x7E));
      ( 1,
        Gen.map
          (fun code ->
            Uchar.of_int (if code >= 0xD800 then code + 0x800 else code))
          (Gen.int_range 0 (0x10FFFF - 0x800)) );
    ]

let text_gen =
  Gen.map
    (fun uchars ->
      let buffer = Buffer.create 16 in
      List.iter (Buffer.add_utf_8_uchar buffer) uchars;
      Buffer.contents buffer)
    (Gen.list_size (Gen.int_range 0 6) uchar_gen)

let integer_gen =
  Gen.oneof
    [
      Gen.oneof_list [ 0; 1; -1; 9; 10; largest; -largest; largest - 1 ];
      Gen.int_range (-1000) 1000;
      Gen.int_range (-largest) largest;
    ]

let scalar_gen =
  Gen.oneof
    [
      Gen.map (fun text -> String (Text text)) text_gen;
      Gen.map (fun value -> Number (string_of_int value)) integer_gen;
      Gen.map (fun value -> Bool value) Gen.bool;
    ]

let dedup members =
  let rec go seen = function
    | [] -> []
    | ((Text name, _) as member) :: rest ->
        if List.mem name seen then go seen rest
        else member :: go (name :: seen) rest
    | member :: rest -> member :: go seen rest
  in
  go [] members

let members_gen value_gen =
  Gen.map dedup
    (Gen.list_size (Gen.int_range 0 4)
       (Gen.pair (Gen.map (fun text -> Text text) text_gen) value_gen))

let value_gen =
  Gen.sized_size (Gen.int_range 0 4)
  @@ Gen.fix (fun self depth ->
      if depth = 0 then scalar_gen
      else
        Gen.oneof_weighted
          [
            (2, scalar_gen);
            ( 1,
              Gen.map
                (fun elements -> Array elements)
                (Gen.list_size (Gen.int_range 0 4) (self (depth - 1))) );
            ( 1,
              Gen.map
                (fun members -> Object members)
                (members_gen (self (depth - 1))) );
          ])

let flat_object_gen =
  Gen.map (fun members -> Object members) (members_gen scalar_gen)

let line_member_gen =
  Gen.oneof
    [
      scalar_gen;
      Gen.map
        (fun elements -> Array elements)
        (Gen.list_size (Gen.int_range 0 4) scalar_gen);
      Gen.map
        (fun elements -> Array elements)
        (Gen.list_size (Gen.int_range 0 3) flat_object_gen);
    ]

let line_object_gen =
  Gen.map (fun members -> Object members) (members_gen line_member_gen)

let deep_gen =
  Gen.map
    (fun (depth, (kinds, leaf)) ->
      let rec wrap level value =
        if level = depth then value
        else
          let value =
            if kinds land (1 lsl (level mod 30)) = 0 then Array [ value ]
            else Object [ (Text "k", value) ]
          in
          wrap (level + 1) value
      in
      wrap 0 leaf)
    Gen.(pair (int_range 1_000 100_000) (pair nat scalar_gen))

let not_value_gen =
  Gen.oneof
    [
      Gen.return Null;
      Gen.map
        (fun number -> Number number)
        (Gen.oneof_list
           [
             "1.5";
             "-0.5";
             "9007199254740992";
             "-9007199254740992";
             "1e16";
             "0.1e1000";
             "1e-1";
             "1.0000000000000001";
             "9007199254740990.5";
             "1E400";
           ]);
      Gen.map
        (fun units -> String (No_text units))
        (Gen.oneof_list
           [
             [ 0xD800 ];
             [ 0xDFFF ];
             [ 0x61; 0xDC00 ];
             [ 0xDBFF; 0x41 ];
             [ 0xDC00; 0xD800 ];
             [ 0xDC00; 0xDC00 ];
             [ 0xD800; 0xE000 ];
           ]);
    ]

let spelled_integer_gen =
  Gen.map
    (fun number -> Number number)
    (Gen.oneof_list
       [
         "1.0";
         "1e2";
         "-0";
         "100e-2";
         "0.5e1";
         "9007199254740991.000";
         "1E+1";
         "-0.0";
       ])

let thing_gen =
  Gen.sized_size (Gen.int_range 0 4)
  @@ Gen.fix (fun self depth ->
      let leaf =
        Gen.oneof_weighted
          [ (4, scalar_gen); (1, not_value_gen); (1, spelled_integer_gen) ]
      in
      if depth = 0 then leaf
      else
        Gen.oneof_weighted
          [
            (2, leaf);
            ( 1,
              Gen.map
                (fun elements -> Array elements)
                (Gen.list_size (Gen.int_range 0 4) (self (depth - 1))) );
            ( 1,
              Gen.map
                (fun members -> Object members)
                (members_gen (self (depth - 1))) );
            ( 1,
              Gen.map
                (fun ((name, first), second) ->
                  Object [ (Text name, first); (Text name, second) ])
                (Gen.pair
                   (Gen.pair text_gen (self (depth - 1)))
                   (self (depth - 1))) );
            ( 1,
              Gen.map
                (fun value -> Object [ (No_text [ 0xDE00 ], value) ])
                (self (depth - 1)) );
          ])

let byte_gen =
  Gen.oneof
    [
      Gen.char;
      Gen.oneof_list
        [
          '"';
          '\\';
          ',';
          ':';
          '[';
          ']';
          '{';
          '}';
          '0';
          '1';
          '-';
          'e';
          '.';
          '\n';
          '\r';
          ' ';
          '\t';
          't';
          'u';
          'n';
          '\x7f';
          '\xc3';
          '\xed';
          '\xff';
        ];
    ]

let corrupt_gen bytes =
  let length = String.length bytes in
  let insert =
    Gen.map
      (fun (at, char) ->
        let at = at mod (length + 1) in
        String.sub bytes 0 at ^ String.make 1 char
        ^ String.sub bytes at (length - at))
      Gen.(pair nat byte_gen)
  in
  if length = 0 then insert
  else
    Gen.oneof
      [
        insert;
        Gen.map
          (fun at ->
            let at = at mod length in
            String.sub bytes 0 at ^ String.sub bytes (at + 1) (length - at - 1))
          Gen.nat;
        Gen.map
          (fun (at, char) ->
            let at = at mod length in
            String.mapi
              (fun index old -> if index = at then char else old)
              bytes)
          Gen.(pair nat byte_gen);
        Gen.map
          (fun (a, b) ->
            let a = a mod length and b = b mod length in
            String.mapi
              (fun index old ->
                if index = a then bytes.[b]
                else if index = b then bytes.[a]
                else old)
              bytes)
          Gen.(pair nat nat);
      ]
