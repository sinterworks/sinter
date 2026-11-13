(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

exception Stop of Types.failure

type reader = {
  bytes : string;
  length : int;
  mutable pos : int;
  max_depth : int option;
  max_key_parts : int option;
}

let fail error offset = raise (Stop (Invalid { error; offset }))
let syntax reader = fail Types.Syntax reader.pos
let reach limit offset = raise (Stop (Limit_reached { limit; offset }))
let at_end reader = reader.pos >= reader.length

let byte_at reader index =
  if index < reader.length then reader.bytes.[index] else '\000'

let peek reader = byte_at reader reader.pos
let advance reader count = reader.pos <- reader.pos + count

let new_buffer () =
  Buffer.create
    (16
    [@mutaml.skip
      "The first size of a buffer changes nothing that the buffer holds: a \
       buffer grows as its contents need."])

let is_digit c = c >= '0' && c <= '9'

let is_hex_digit c =
  is_digit c || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')

(* @satisfies data-forms#read-toml=v1
   A bare key holds only the letters A to Z and a to z, the digits, `-`, and
   `_`, by the rule unquoted-key. *)
let is_bare_key_byte c =
  (c >= 'A' && c <= 'Z')
  || (c >= 'a' && c <= 'z')
  || is_digit c || c = '-' || c = '_'

let starts_simple_key c = is_bare_key_byte c || c = '"' || c = '\''

(* @satisfies data-forms#read-toml=v1
   A comment and a string hold no control character other than the tab, and
   no U+007F, by the rule non-eol; each byte from 0x80 is part of a character
   of valid UTF-8, which these rules allow. *)
let is_non_eol c = c = '\t' || (c >= ' ' && c <> '\x7f')
let is_literal_byte c = is_non_eol c && c <> '\''

let skip_whitespace reader =
  while peek reader = ' ' || peek reader = '\t' do
    advance reader 1
  done

let skip_comment reader =
  if peek reader = '#' then begin
    while is_non_eol (peek reader) do
      advance reader 1
    done
  end

(* @satisfies data-forms#read-toml=v1
   A newline is a line feed, or a carriage return right before a line feed;
   a carriage return is allowed nowhere else outside a string. *)
let newline_length reader =
  match peek reader with
  | '\n' -> 1
  | '\r' when byte_at reader (reader.pos + 1) = '\n' -> 2
  | _ -> 0

let rec skip_whitespace_comments_newlines reader =
  skip_whitespace reader;
  skip_comment reader;
  let length = newline_length reader in
  if length > 0 then begin
    advance reader length;
    skip_whitespace_comments_newlines reader
  end

let expect reader word =
  String.iter
    (fun c -> if peek reader = c then advance reader 1 else syntax reader)
    word

let hex_value reader count =
  let rec sum count total =
    if count = 0 then total
    else
      let c = peek reader in
      if is_hex_digit c then begin
        advance reader 1;
        sum (count - 1) ((total * 16) + Number.digit_value c)
      end
      else syntax reader
  in
  sum count 0

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   An escape sequence resolves to its character, and an escape whose digits
   write no code point of a character, a surrogate or a number above
   0x10FFFF, is a value error in a string and a key error in a quoted key. *)
let escape reader buffer =
  let start = reader.pos in
  advance reader 1;
  let add c =
    advance reader 1;
    Buffer.add_char buffer c
  in
  let add_code_point count =
    advance reader 1;
    let code = hex_value reader count in
    if Uchar.is_valid code then
      Buffer.add_utf_8_uchar buffer (Uchar.of_int code)
    else fail Types.Escape_not_a_character start
  in
  match peek reader with
  | '"' -> add '"'
  | '\\' -> add '\\'
  | 'b' -> add '\b'
  | 'e' -> add '\x1b'
  | 'f' -> add '\x0c'
  | 'n' -> add '\n'
  | 'r' -> add '\r'
  | 't' -> add '\t'
  | 'x' -> add_code_point 2
  | 'u' -> add_code_point 4
  | 'U' -> add_code_point 8
  | _ -> syntax reader

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A basic string runs to its next quotation mark that no backslash escapes,
   holds no newline, and gives its characters with its escape sequences
   resolved. *)
let basic_string reader =
  let buffer = new_buffer () in
  advance reader 1;
  let rec run () =
    match peek reader with
    | '"' -> advance reader 1
    | '\\' ->
        escape reader buffer;
        run ()
    | c when is_non_eol c ->
        Buffer.add_char buffer c;
        advance reader 1;
        run ()
    | _ -> syntax reader
  in
  run ();
  Buffer.contents buffer

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A literal string runs to its next apostrophe, holds no newline, and gives its
   characters as they are. *)
let literal_string reader =
  advance reader 1;
  let start = reader.pos in
  while is_literal_byte (peek reader) do
    advance reader 1
  done;
  if peek reader = '\'' then begin
    advance reader 1;
    String.sub reader.bytes start (reader.pos - 1 - start)
  end
  else syntax reader

let quote_run reader quote =
  let rec count index =
    if byte_at reader index = quote then count (index + 1)
    else index - reader.pos
  in
  count reader.pos

(* @satisfies data-forms#give-only-root-tables=v1
   In a multi-line basic string, a backslash that is the last character on its
   line apart from tabs and spaces drops with the tabs, spaces, and newlines
   after it up to the next other character. *)
let multi_line_backslash reader buffer =
  let rec after_spaces index =
    match byte_at reader index with
    | ' ' | '\t' -> after_spaces (index + 1)
    | _ -> index
  in
  let index = after_spaces (reader.pos + 1) in
  let saved = reader.pos in
  reader.pos <- index;
  if newline_length reader > 0 then begin
    let rec trim () =
      skip_whitespace reader;
      let length = newline_length reader in
      if length > 0 then begin
        advance reader length;
        trim ()
      end
    in
    trim ()
  end
  else begin
    reader.pos <- saved;
    escape reader buffer
  end

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A multi-line string drops the newline right after its opening delimiter,
   keeps each other newline as the document writes it, a line feed or a
   carriage return and a line feed, and ends at the first run of three to five
   quotes, of which all but the last three belong to the string. *)
let multi_line_string reader quote ~escapes =
  let buffer = new_buffer () in
  advance reader 3;
  advance reader (newline_length reader);
  let rec run () =
    let c = peek reader in
    if c = quote then begin
      let count = quote_run reader quote in
      if count < 3 then begin
        Buffer.add_string buffer (String.make count quote);
        advance reader count;
        run ()
      end
      else begin
        let kept = min (count - 3) 2 in
        Buffer.add_string buffer (String.make kept quote);
        advance reader (kept + 3)
      end
    end
    else if c = '\\' && escapes then begin
      multi_line_backslash reader buffer;
      run ()
    end
    else
      let length = newline_length reader in
      if length > 0 then begin
        Buffer.add_string buffer (String.sub reader.bytes reader.pos length);
        advance reader length;
        run ()
      end
      else if is_non_eol c then begin
        Buffer.add_char buffer c;
        advance reader 1;
        run ()
      end
      else syntax reader
  in
  run ();
  Buffer.contents buffer

let multi_line_basic reader = multi_line_string reader '"' ~escapes:true
let multi_line_literal reader = multi_line_string reader '\'' ~escapes:false

let starts_triple reader quote =
  byte_at reader (reader.pos + 1) = quote
  && byte_at reader (reader.pos + 2) = quote

type part = { text : string; span : Types.span }

let simple_key reader =
  let start = reader.pos in
  let text =
    match peek reader with
    | '"' -> basic_string reader
    | '\'' -> literal_string reader
    | c when is_bare_key_byte c ->
        while is_bare_key_byte (peek reader) do
          advance reader 1
        done;
        String.sub reader.bytes start (reader.pos - start)
    | _ -> syntax reader
  in
  { text; span = { start; stop = reader.pos } }

type key = { first : string; rest : string list; key : Types.key }

let check_key_parts reader count =
  match reader.max_key_parts with
  | Some limit when count > limit ->
      if starts_simple_key (peek reader) then reach Types.Key_parts reader.pos
      else syntax reader
  | Some _ | None -> ()

(* @satisfies data-forms#give-only-toml-spans=v1
   The span of a key runs from the first byte of its first TOML key to the
   last byte of its last one, with the spaces and dots between them, and each
   TOML key has its own span with its quotes. *)
let key reader =
  let start = reader.pos in
  check_key_parts reader 1;
  let first = simple_key reader in
  let rec more count rev_rest =
    skip_whitespace reader;
    if peek reader = '.' then begin
      advance reader 1;
      skip_whitespace reader;
      check_key_parts reader (count + 1);
      more (count + 1) (simple_key reader :: rev_rest)
    end
    else rev_rest
  in
  let rev_rest = more 1 [] in
  let rest = List.rev rev_rest in
  let last = match rev_rest with last :: _ -> last | [] -> first in
  {
    first = first.text;
    rest = List.map (fun part -> part.text) rest;
    key =
      {
        whole = { start; stop = last.span.stop };
        parts = List.map (fun part -> part.span) (first :: rest);
      };
  }

(* @satisfies data-forms#read-toml=v1
   A run of digits starts with a digit, and each `_` stands between two
   digits. *)
let digits_with_underscores reader is_radix_digit buffer =
  if not (is_radix_digit (peek reader)) then syntax reader;
  let rec run () =
    match peek reader with
    | c when is_radix_digit c ->
        Buffer.add_char buffer c;
        advance reader 1;
        run ()
    | '_' when is_radix_digit (byte_at reader (reader.pos + 1)) ->
        advance reader 1;
        run ()
    | _ -> ()
  in
  run ()

let radix_integer reader start base is_radix_digit =
  advance reader 2;
  let buffer = new_buffer () in
  digits_with_underscores reader is_radix_digit buffer;
  match Number.radix_integer ~base (Buffer.contents buffer) with
  | Some value -> Types.Integer value
  | None -> fail Types.Integer_out_of_range start

(* @satisfies data-forms#read-toml=v1
   An integer of TOML 1.1.0 outside -2^63 to 2^63 - 1 and a float of
   TOML 1.1.0 that rounds to an infinity are value errors. *)
let number reader =
  let start = reader.pos in
  let negative = peek reader = '-' in
  if negative || peek reader = '+' then advance reader 1;
  let signed = reader.pos > start in
  match (peek reader, byte_at reader (reader.pos + 1)) with
  | '0', 'x' when not signed -> radix_integer reader start 16 is_hex_digit
  | '0', 'o' when not signed ->
      radix_integer reader start 8 (fun c -> c >= '0' && c <= '7')
  | '0', 'b' when not signed ->
      radix_integer reader start 2 (fun c -> c = '0' || c = '1')
  | _ -> (
      let digits = new_buffer () in
      if peek reader = '0' then advance reader 1
      else digits_with_underscores reader is_digit digits;
      let whole_length = Buffer.length digits in
      if peek reader = '.' then begin
        advance reader 1;
        digits_with_underscores reader is_digit digits
      end;
      let fraction_length = Buffer.length digits - whole_length in
      let exponent =
        if peek reader = 'e' || peek reader = 'E' then begin
          advance reader 1;
          let negative = peek reader = '-' in
          if negative || peek reader = '+' then advance reader 1;
          let exponent = new_buffer () in
          digits_with_underscores reader is_digit exponent;
          Some (negative, Buffer.contents exponent)
        end
        else None
      in
      if fraction_length > 0 || Option.is_some exponent then
        let value =
          Number.float ~negative ~digits:(Buffer.contents digits)
            ~fraction_length ~exponent
        in
        if Float.is_finite value then Types.Float value
        else fail Types.Float_out_of_range start
      else
        match Number.decimal_integer ~negative (Buffer.contents digits) with
        | Some value -> Types.Integer value
        | None -> fail Types.Integer_out_of_range start)

(* @satisfies data-forms#give-only-root-tables=v1
   The floats inf and +inf give positive infinity and -inf negative infinity;
   nan, +nan, and -nan give a NaN, by the rule toml-special-float. *)
let special_float reader negative =
  match peek reader with
  | 'i' ->
      expect reader "inf";
      Types.Float (if negative then Float.neg_infinity else Float.infinity)
  | _ ->
      expect reader "nan";
      Types.Float (if negative then Float.neg Float.nan else Float.nan)

let two_digits reader =
  let first = peek reader in
  let second = byte_at reader (reader.pos + 1) in
  if not (is_digit first) then syntax reader;
  advance reader 1;
  if not (is_digit second) then syntax reader;
  advance reader 1;
  ((Char.code first - 48) * 10) + Char.code second - 48

let four_digits reader =
  let high = two_digits reader in
  (high * 100) + two_digits reader

(* @satisfies data-forms#give-only-root-tables=v1
   The fraction of a second keeps its first nine digits, by the rule
   toml-second-fraction, and an omitted second or fraction is 0, by the rule
   toml-omitted-second. *)
let nanoseconds reader =
  let rec run count total =
    let c = peek reader in
    if is_digit c then begin
      advance reader 1;
      if count < 9 then run (count + 1) ((total * 10) + Char.code c - 48)
      else run count total
    end
    else if count = 0 then syntax reader
    else
      let rec scale count total =
        if count < 9 then scale (count + 1) (total * 10) else total
      in
      scale count total
  in
  run 0 0

let partial_time reader : Types.time =
  let hour = two_digits reader in
  expect reader ":";
  let minute = two_digits reader in
  if peek reader = ':' then begin
    advance reader 1;
    let second = two_digits reader in
    let nanosecond =
      if peek reader = '.' then begin
        advance reader 1;
        nanoseconds reader
      end
      else 0
    in
    { hour; minute; second; nanosecond }
  end
  else { hour; minute; second = 0; nanosecond = 0 }

(* @satisfies data-forms#give-only-root-tables=v1
   The offset -00:00 gives the unknown local offset, Z and z give the offset 0,
   and each other offset gives its signed number of minutes, by the rule
   toml-offset. *)
let offset reader start =
  match peek reader with
  | 'Z' | 'z' ->
      advance reader 1;
      Some (Types.Minutes 0)
  | ('+' | '-') as sign ->
      advance reader 1;
      let hours = two_digits reader in
      expect reader ":";
      let minutes = two_digits reader in
      if not (Calendar.offset_is_valid ~hours ~minutes) then
        fail Types.Date_time_out_of_range start;
      let total = (hours * 60) + minutes in
      if sign = '+' then Some (Types.Minutes total)
      else if total = 0 then Some Types.Unknown_local
      else Some (Types.Minutes (-total))
  | _ -> None

let starts_time reader index =
  is_digit (byte_at reader index) && byte_at reader (index + 2) = ':'

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A date-time matches the rules local-time, local-date, local-date-time, and
   offset-date-time, with `T`, `t`, or a space before the time; a space with no
   time after it ends a local date. *)
let date_time reader =
  let start = reader.pos in
  let check valid = if not valid then fail Types.Date_time_out_of_range start in
  if starts_time reader start then begin
    let time = partial_time reader in
    check (Calendar.time_is_valid time);
    Types.Local_time time
  end
  else begin
    let year = four_digits reader in
    expect reader "-";
    let month = two_digits reader in
    expect reader "-";
    let day = two_digits reader in
    let date : Types.date = { year; month; day } in
    check (Calendar.date_is_valid date);
    let delimiter = peek reader in
    if
      delimiter = 'T' || delimiter = 't'
      || (delimiter = ' ' && starts_time reader (reader.pos + 1))
    then begin
      advance reader 1;
      let time = partial_time reader in
      check (Calendar.time_is_valid time);
      match offset reader start with
      | Some offset -> Types.Offset_date_time (date, time, offset)
      | None -> Types.Local_date_time (date, time)
    end
    else Types.Local_date date
  end

let starts_date reader =
  is_digit (byte_at reader (reader.pos + 3))
  && byte_at reader (reader.pos + 4) = '-'

let scalar reader =
  match peek reader with
  | '"' ->
      if starts_triple reader '"' then Types.String (multi_line_basic reader)
      else Types.String (basic_string reader)
  | '\'' ->
      if starts_triple reader '\'' then Types.String (multi_line_literal reader)
      else Types.String (literal_string reader)
  | 't' ->
      expect reader "true";
      Types.Boolean true
  | 'f' ->
      expect reader "false";
      Types.Boolean false
  | 'i' | 'n' -> special_float reader false
  | ('+' | '-') as sign
    when byte_at reader (reader.pos + 1) = 'i'
         || byte_at reader (reader.pos + 1) = 'n' ->
      advance reader 1;
      special_float reader (sign = '-')
  | '0' .. '9' when starts_date reader || starts_time reader reader.pos ->
      date_time reader
  | '0' .. '9' | '+' | '-' -> number reader
  | _ -> syntax reader

type inline = { start : int; depth : int; table : Tree.table }

type frame =
  | In_array of { start : int; depth : int; mutable rev : Tree.node list }
  | In_pair of { inline : inline; slot : Tree.slot; key : Types.key }

let depth_of = function
  | [] -> 0
  | In_array array :: _ -> array.depth
  | In_pair pair :: _ -> pair.inline.depth

let open_depth reader stack =
  let depth = depth_of stack + 1 in
  (match reader.max_depth with
  | Some limit when depth > limit -> reach Types.Depth reader.pos
  | Some _ | None -> ());
  depth

let span_from reader start : Types.span = { start; stop = reader.pos }

let walk_failure (key : key) = function
  | Ok slot -> slot
  | Error error -> fail error key.key.whole.start

(* @satisfies data-forms#read-toml=v1
   Between a key and its value, only spaces and tabs stand around `=`, so a
   newline there makes the text not match the rule keyval. *)
let key_value_separator reader =
  expect reader "=";
  skip_whitespace reader

(* @satisfies data-forms#{
       read-toml=v1, give-only-root-tables=v1, give-only-toml-spans=v1,
   }
   Arrays and inline tables match the rules array and inline-table of
   TOML 1.1.0, with comments and newlines only where those rules allow them;
   each array holds its values in order; and each value of TOML 1.1.0 gets the
   span from its first byte to its last, with the quotes of a string, the
   brackets of an array, and the braces of an inline table. *)
let value reader =
  let rec start_value stack =
    match peek reader with
    | '[' ->
        let depth = open_depth reader stack in
        let start = reader.pos in
        advance reader 1;
        skip_whitespace_comments_newlines reader;
        if peek reader = ']' then begin
          advance reader 1;
          deliver stack (Tree.array [] (span_from reader start))
        end
        else start_value (In_array { start; depth; rev = [] } :: stack)
    | '{' ->
        let depth = open_depth reader stack in
        let inline = { start = reader.pos; depth; table = Tree.inline () } in
        advance reader 1;
        skip_whitespace_comments_newlines reader;
        if peek reader = '}' then close_inline inline stack
        else start_pair inline stack
    | _ ->
        let start = reader.pos in
        let value = scalar reader in
        deliver stack (Tree.scalar value (span_from reader start))
  and start_pair inline stack =
    let key = key reader in
    let slot =
      walk_failure key (Tree.walk_pair inline.table key.first key.rest)
    in
    key_value_separator reader;
    start_value (In_pair { inline; slot; key = key.key } :: stack)
  and close_inline inline stack =
    advance reader 1;
    deliver stack
      (Tree.table_value inline.table (span_from reader inline.start))
  and deliver stack node =
    match stack with
    | [] -> node
    | In_array array :: below ->
        array.rev <- node :: array.rev;
        skip_whitespace_comments_newlines reader;
        let close () =
          advance reader 1;
          deliver below
            (Tree.array (List.rev array.rev) (span_from reader array.start))
        in
        if peek reader = ',' then begin
          advance reader 1;
          skip_whitespace_comments_newlines reader;
          if peek reader = ']' then close () else start_value stack
        end
        else if peek reader = ']' then close ()
        else syntax reader
    | In_pair pair :: below ->
        Tree.fill pair.slot pair.key node;
        skip_whitespace_comments_newlines reader;
        if peek reader = ',' then begin
          advance reader 1;
          skip_whitespace_comments_newlines reader;
          if peek reader = '}' then close_inline pair.inline below
          else start_pair pair.inline below
        end
        else if peek reader = '}' then close_inline pair.inline below
        else syntax reader
  in
  start_value []

let key_value reader holding =
  let key = key reader in
  let slot = walk_failure key (Tree.walk_pair holding key.first key.rest) in
  key_value_separator reader;
  Tree.fill slot key.key (value reader)

(* @satisfies data-forms#read-toml=v1
   A table header is `[` or `[[`, spaces and tabs, a key, spaces and tabs, and
   `]` or `]]`, with no space inside the double brackets. *)
let table_header reader root =
  let array = byte_at reader (reader.pos + 1) = '[' in
  advance reader (if array then 2 else 1);
  skip_whitespace reader;
  let key = key reader in
  let table =
    match Tree.walk_header root key.first key.rest ~array key.key with
    | Ok table -> table
    | Error error -> fail error key.key.whole.start
  in
  expect reader (if array then "]]" else "]");
  table

(* @satisfies data-forms#read-toml=v1
   After an expression, only spaces, tabs, a comment, and a newline or the end
   of the text may follow. *)
let end_of_line reader =
  skip_whitespace reader;
  skip_comment reader;
  if not (at_end reader) then begin
    let length = newline_length reader in
    if length = 0 then syntax reader;
    advance reader length
  end

(* @satisfies data-forms#read-toml=v1
   When the byte sequence starts with the bytes 0xEF, 0xBB, 0xBF, TOML 1.1.0
   reads the body of its text, after the byte order mark, by the rule
   toml-byte-order-mark. *)
let body_start bytes =
  if String.starts_with ~prefix:"\xef\xbb\xbf" bytes then 3 else 0

let document ~max_depth ~max_key_parts bytes =
  let reader =
    {
      bytes;
      length = String.length bytes;
      pos = body_start bytes;
      max_depth;
      max_key_parts;
    }
  in
  let root = Tree.root () in
  let rec lines holding =
    if at_end reader then Ok (Tree.freeze root)
    else begin
      skip_whitespace reader;
      let holding =
        match peek reader with
        | '[' -> table_header reader root
        | '#' | '\n' | '\r' -> holding
        | _ when at_end reader -> holding
        | _ ->
            key_value reader holding;
            holding
      in
      end_of_line reader;
      lines holding
    end
  in
  try lines root with Stop failure -> Error failure
