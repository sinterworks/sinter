(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let uchars_of_string string =
  let rec go index acc =
    if index >= String.length string then List.rev acc
    else
      let decode = String.get_utf_8_uchar string index in
      go
        (index + Uchar.utf_decode_length decode)
        (Uchar.utf_decode_uchar decode :: acc)
  in
  go 0 []

let string_of_uchars uchars =
  let buffer = Buffer.create 16 in
  List.iter (Buffer.add_utf_8_uchar buffer) uchars;
  Buffer.contents buffer

let text_of string = Text.of_uchars (uchars_of_string string)

let uchars_of_text text =
  List.init (Text.length text) (fun index ->
      match Text.get text (index + 1) with
      | Some uchar -> uchar
      | None -> Alcotest.failf "no character at place %d" (index + 1))

let string_of_text text = string_of_uchars (uchars_of_text text)

let hex bytes =
  String.concat ""
    (List.map
       (fun char -> Printf.sprintf "%02x" (Char.code char))
       (List.of_seq (String.to_seq bytes)))

let of_hex digits =
  String.init
    (String.length digits / 2)
    (fun index ->
      Char.chr (int_of_string ("0x" ^ String.sub digits (2 * index) 2)))

let json_string = function
  | `String text -> text
  | other ->
      Alcotest.failf "not a JSON string: %s" (Yojson.Basic.to_string other)

let json_member name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other ->
      Alcotest.failf "not a JSON object: %s" (Yojson.Basic.to_string other)

let json_int value =
  match value with
  | `Int number -> number
  | other ->
      Alcotest.failf "not a JSON number: %s" (Yojson.Basic.to_string other)

let json_run value : Text.run =
  {
    from = json_int (json_member "from" value);
    until = json_int (json_member "to" value);
  }

let run_json (run : Text.run) =
  `Assoc [ ("from", `Int run.from); ("to", `Int run.until) ]

let position_json (position : Lines.position) =
  `Assoc [ ("line", `Int position.line); ("column", `Int position.column) ]

let text_set = Vectors.read "text"

let give_decode (vector : Vectors.vector) =
  match Text.decode (of_hex (json_string vector.input)) with
  | Ok text ->
      `Assoc
        [
          ("result", `String "valid");
          ("values", `Assoc [ ("text", `String (string_of_text text)) ]);
        ]
  | Error (Text.Invalid_utf_8 _) ->
      `Assoc [ ("result", `String "invalid"); ("values", `Assoc []) ]

let give_encode (vector : Vectors.vector) =
  let text = text_of (json_string vector.input) in
  `Assoc
    [ ("values", `Assoc [ ("encoding", `String (hex (Text.encode text))) ]) ]

let give_lines (vector : Vectors.vector) =
  let text = text_of (json_string vector.input) in
  let runs = Lines.all (Lines.of_text text) in
  let texts =
    List.map
      (fun run ->
        match Text.sub text run with
        | Some line -> `String (string_of_text line)
        | None -> `Null)
      runs
  in
  `Assoc
    [
      ( "values",
        `Assoc
          [ ("runs", `List (List.map run_json runs)); ("texts", `List texts) ]
      );
    ]

let give_character_position (vector : Vectors.vector) =
  let text = text_of (json_string (json_member "text" vector.input)) in
  let place = json_int (json_member "place" vector.input) in
  match Lines.character_position (Lines.of_text text) place with
  | Ok position ->
      `Assoc [ ("values", `Assoc [ ("position", position_json position) ]) ]
  | Error Lines.Byte_order_mark -> `Assoc [ ("values", `Assoc []) ]
  | Error Lines.Not_a_place -> `Assoc [ ("values", `String "not a place") ]

let give_span (vector : Vectors.vector) =
  let text = text_of (json_string (json_member "text" vector.input)) in
  let run = json_run (json_member "run" vector.input) in
  match Lines.span (Lines.of_text text) run with
  | Ok (start, stop) ->
      `Assoc
        [
          ( "values",
            `Assoc
              [ ("start", position_json start); ("end", position_json stop) ] );
        ]
  | Error Lines.Not_a_span -> `Assoc [ ("values", `Assoc []) ]
  | Error Lines.Not_a_run -> `Assoc [ ("values", `String "not a run") ]

(* @verifies text[decode][*]=v1 *)
let decode_vectors = Vectors.group text_set ~name:"decode" ~rev:"v1" give_decode

(* @verifies text[encode][*]=v1 *)
let encode_vectors = Vectors.group text_set ~name:"encode" ~rev:"v1" give_encode

(* @verifies text[lines][*]=v1 *)
let lines_vectors = Vectors.group text_set ~name:"lines" ~rev:"v1" give_lines

(* @verifies text[character-positions][*]=v1 *)
let character_position_vectors =
  Vectors.group text_set ~name:"character-positions" ~rev:"v1"
    give_character_position

(* @verifies text[spans][*]=v1 *)
let span_vectors = Vectors.group text_set ~name:"spans" ~rev:"v1" give_span

let invalid_place bytes =
  match Text.decode bytes with
  | Ok _ -> None
  | Error (Text.Invalid_utf_8 { place }) -> Some place

let decode_names_the_place_of_the_first_bad_byte () =
  List.iter
    (fun (bytes, place) ->
      Alcotest.(check (option int))
        (Printf.sprintf "the place in %s" (hex bytes))
        (Some place) (invalid_place bytes))
    [
      ("\xff", 1);
      ("a\xc3", 2);
      ("ab\xff", 3);
      ("\xc0\xaf", 1);
      ("a\xed\xa0\x80", 2);
      ("\xe0\x80\xaf", 1);
      ("\xf8\x88\x80\x80\x80", 1);
      ("\xe2\x82", 1);
      ("\xc3\xa9\x80", 3);
      ("\xf4\x90\x80\x80", 1);
    ]

let empty_is_the_text_of_no_characters () =
  Alcotest.(check (option string))
    "the empty run of the empty text" (Some "")
    (Option.map string_of_text (Text.sub Text.empty { from = 0; until = 0 }));
  Alcotest.(check int) "the length" 0 (Text.length Text.empty);
  Alcotest.(check string) "the encoding" "" (Text.encode Text.empty);
  Alcotest.(check bool)
    "the same text as of_uchars []" true
    (Text.equal Text.empty (Text.of_uchars []))

let get_gives_no_character_outside_the_places () =
  let text = text_of "ab" in
  Alcotest.(check (list (option int)))
    "the code points at places -1 to 3"
    [ None; None; Some 0x61; Some 0x62; None ]
    (List.map
       (fun place -> Option.map Uchar.to_int (Text.get text place))
       [ -1; 0; 1; 2; 3 ])

let sub_gives_no_text_for_a_pair_that_is_not_a_run () =
  let text = text_of "abc" in
  List.iter
    (fun (from, until) ->
      Alcotest.(check bool)
        (Printf.sprintf "no text for %d to %d" from until)
        true
        (Option.is_none (Text.sub text { from; until })))
    [ (-1, 1); (2, 1); (0, 4); (4, 4); (-1, -1) ];
  Alcotest.(check (option string))
    "the text of 1 to 3" (Some "bc")
    (Option.map string_of_text (Text.sub text { from = 1; until = 3 }));
  Alcotest.(check (option string))
    "the empty run at 3" (Some "")
    (Option.map string_of_text (Text.sub text { from = 3; until = 3 }))

let equal_tells_texts_apart () =
  let check name want a b =
    Alcotest.(check bool) name want (Text.equal (text_of a) (text_of b))
  in
  check "one text" true "ab" "ab";
  check "case matters" false "a" "A";
  check "normalization matters" false "\xc3\xa9" "e\xcc\x81";
  check "a longer text" false "ab" "abc";
  check "a byte order mark matters" false "\xef\xbb\xbfa" "a"

let body_starts_after_a_byte_order_mark () =
  let body string = Text.body (text_of string) in
  Alcotest.(check (list (pair int int)))
    "the bodies"
    [ (0, 0); (1, 1); (1, 2); (0, 2); (1, 2) ]
    (List.map
       (fun string ->
         let run = body string in
         (run.from, run.until))
       [
         "";
         "\xef\xbb\xbf";
         "\xef\xbb\xbfx";
         "x\xef\xbb\xbf";
         "\xef\xbb\xbf\xef\xbb\xbf";
       ]);
  Alcotest.(check (list bool))
    "which texts have a byte order mark"
    [ false; true; false; true ]
    (List.map
       (fun string -> Text.has_byte_order_mark (text_of string))
       [ ""; "\xef\xbb\xbf"; "x\xef\xbb\xbf"; "\xef\xbb\xbf\xef\xbb\xbf" ])

let lines_keep_their_text () =
  let text = text_of "a\nb" in
  Alcotest.(check bool)
    "the same text" true
    (Text.equal text (Lines.text (Lines.of_text text)))

let line_gives_no_run_outside_the_line_numbers () =
  let lines = Lines.of_text (text_of "a\n\nb\n") in
  Alcotest.(check int) "the count" 3 (Lines.count lines);
  Alcotest.(check (list (option (pair int int))))
    "the lines 0 to 4"
    [ None; Some (0, 1); Some (2, 2); Some (3, 4); None ]
    (List.map
       (fun number ->
         Option.map
           (fun (run : Text.run) -> (run.from, run.until))
           (Lines.line lines number))
       [ 0; 1; 2; 3; 4 ]);
  Alcotest.(check bool)
    "no line -1" true
    (Option.is_none (Lines.line lines (-1)))

let character_position_refuses_what_is_not_a_place () =
  let lines = Lines.of_text (text_of "ab") in
  List.iter
    (fun place ->
      Alcotest.(check bool)
        (Printf.sprintf "place %d" place)
        true
        (Lines.character_position lines place = Error Lines.Not_a_place))
    [ -1; 0; 3 ];
  Alcotest.(check bool)
    "no place in the empty text" true
    (Lines.character_position (Lines.of_text Text.empty) 1
    = Error Lines.Not_a_place)

let span_refuses_what_is_not_a_run () =
  let lines = Lines.of_text (text_of "ab") in
  List.iter
    (fun (from, until) ->
      Alcotest.(check bool)
        (Printf.sprintf "%d to %d" from until)
        true
        (Lines.span lines { from; until } = Error Lines.Not_a_run))
    [ (-1, 0); (2, 1); (0, 3); (3, 3) ];
  Alcotest.(check bool)
    "a text with a byte order mark refuses a pair past its end" true
    (Lines.span (Lines.of_text (text_of "\xef\xbb\xbf")) { from = 0; until = 2 }
    = Error Lines.Not_a_run)

let edge_uchar =
  Gen.map Uchar.of_int
    (Gen.oneof_list
       [
         0x61;
         0x62;
         0x20;
         0x09;
         0x0A;
         0x0A;
         0x0D;
         0x0D;
         0xFEFF;
         0x2028;
         0x85;
         0x0B;
         0xE9;
         0x1F600;
         0x0;
       ])

let any_uchar =
  Gen.map Uchar.of_int
    (Gen.oneof
       [
         Gen.int_range 0 0x7F;
         Gen.int_range 0x80 0x7FF;
         Gen.int_range 0x800 0xD7FF;
         Gen.int_range 0xE000 0xFFFF;
         Gen.int_range 0x10000 0x10FFFF;
         Gen.oneof_list
           [ 0xD7FF; 0xE000; 0xFFFF; 0x10000; 0x10FFFF; 0x7FF; 0x800 ];
       ])

let uchars_gen element =
  Gen.oneof
    [
      Gen.list_size (Gen.int_range 0 14) element;
      Gen.map
        (fun rest -> Uchar.of_int 0xFEFF :: rest)
        (Gen.list_size (Gen.int_range 0 14) element);
    ]

let print_uchars uchars =
  String.concat " "
    (List.map
       (fun uchar -> Printf.sprintf "U+%04X" (Uchar.to_int uchar))
       uchars)

let decode_gives_back_the_encoded_text =
  property ~name:"decode gives back the text that encode encodes"
    ~print:print_uchars (uchars_gen any_uchar) (fun uchars ->
      let text = Text.of_uchars uchars in
      match Text.decode (Text.encode text) with
      | Ok back -> Text.equal back text && uchars_of_text back = uchars
      | Error _ -> false)

(* @verifies text#give-utf-8-encodings=v1 *)
let encode_gives_the_bytes_of_each_character =
  property ~name:"encode gives the UTF-8 bytes of each character in order"
    ~print:print_uchars (uchars_gen any_uchar) (fun uchars ->
      String.equal
        (Text.encode (Text.of_uchars uchars))
        (string_of_uchars uchars))

let of_uchars_keeps_each_character =
  property ~name:"of_uchars keeps each character at its place"
    ~print:print_uchars (uchars_gen edge_uchar) (fun uchars ->
      let text = Text.of_uchars uchars in
      Text.length text = List.length uchars
      && uchars_of_text text = uchars
      && Option.is_none (Text.get text (List.length uchars + 1)))

let sub_gives_the_characters_of_the_run =
  property ~name:"sub gives the characters from from + 1 to until"
    ~print:(fun (uchars, (from, until)) ->
      Printf.sprintf "%s; %d to %d" (print_uchars uchars) from until)
    Gen.(
      pair (uchars_gen edge_uchar)
        (pair (int_range (-1) 16) (int_range (-1) 16)))
    (fun (uchars, (from, until)) ->
      let text = Text.of_uchars uchars in
      match Text.sub text { from; until } with
      | None -> not (0 <= from && from <= until && until <= List.length uchars)
      | Some run ->
          0 <= from && from <= until
          && until <= List.length uchars
          && uchars_of_text run
             = List.filteri
                 (fun index _ -> index >= from && index < until)
                 uchars)

let equal_holds_for_the_same_characters =
  property ~name:"equal holds when, and only when, the characters are the same"
    ~print:(fun (a, b) -> print_uchars a ^ " / " ^ print_uchars b)
    Gen.(
      pair
        (list_size (int_range 0 3) edge_uchar)
        (list_size (int_range 0 3) edge_uchar))
    (fun (a, b) ->
      Text.equal (Text.of_uchars a) (Text.of_uchars b)
      = List.equal Uchar.equal a b)

let concat_joins_the_characters_in_order =
  property ~name:"concat gives the characters of each text in order"
    ~print:(fun texts -> String.concat " | " (List.map print_uchars texts))
    Gen.(list_size (int_range 0 5) (uchars_gen edge_uchar))
    (fun texts ->
      let joined = Text.concat (List.map Text.of_uchars texts) in
      uchars_of_text joined = List.concat texts
      && Text.length joined = List.length (List.concat texts))

let concat_of_no_text_is_empty () =
  Alcotest.(check bool)
    "concat of no text" true
    (Text.equal (Text.concat []) Text.empty)

let any_bytes =
  Gen.oneof
    [
      Gen.string_size ~gen:Gen.char (Gen.int_range 0 12);
      Gen.string_size ~gen:(Gen.char_range '\x7f' '\xf5') (Gen.int_range 0 8);
      Gen.map
        (fun (uchars, (index, byte)) ->
          let bytes = string_of_uchars uchars in
          let index =
            if bytes = "" then 0 else index mod (String.length bytes + 1)
          in
          String.sub bytes 0 index ^ String.make 1 byte
          ^ String.sub bytes index (String.length bytes - index))
        Gen.(pair (list_size (int_range 0 6) any_uchar) (pair nat char));
    ]

(* @verifies text#{validate-utf-8=v1, give-texts-of-byte-sequences=v1, omit-texts-of-invalid-byte-sequences=v1} *)
let decode_answers_every_byte_sequence =
  property ~count:1000
    ~name:"decode accepts exactly the valid UTF-8 and names the first bad byte"
    ~print:hex any_bytes (fun bytes ->
      match Text.decode bytes with
      | Ok text ->
          String.is_valid_utf_8 bytes && String.equal (Text.encode text) bytes
      | Error (Text.Invalid_utf_8 { place }) ->
          (not (String.is_valid_utf_8 bytes))
          && place >= 1
          && place <= String.length bytes
          && String.is_valid_utf_8 (String.sub bytes 0 (place - 1))
          && not
               (Uchar.utf_decode_is_valid
                  (String.get_utf_8_uchar bytes (place - 1))))

let corrupted_encoding =
  Gen.map
    (fun ((uchars, at), damage) ->
      let pieces = List.map (fun uchar -> string_of_uchars [ uchar ]) uchars in
      let count = List.length pieces in
      let at = if count = 0 then 0 else at mod (count + 1) in
      let before = String.concat "" (List.filteri (fun i _ -> i < at) pieces) in
      let after = String.concat "" (List.filteri (fun i _ -> i >= at) pieces) in
      before ^ damage ^ after)
    Gen.(
      pair
        (pair (list_size (int_range 0 6) any_uchar) nat)
        (oneof_list
           [
             "\x80";
             "\xbf";
             "\xc0";
             "\xc1\xbf";
             "\xf5\x80\x80\x80";
             "\xff";
             "\xc3";
             "\xe2\x82";
             "\xf0\x9f\x98";
             "\xed\xa0\x80";
             "\xed\xbf\xbf";
             "\xe0\x9f\xbf";
             "\xf0\x8f\xbf\xbf";
             "\xf4\x90\x80\x80";
           ]))

let decode_refuses_corrupted_encodings =
  property ~count:500 ~name:"decode gives no text for a damaged encoding"
    ~print:hex corrupted_encoding (fun bytes ->
      match Text.decode bytes with Ok _ -> false | Error _ -> true)

let body_and_byte_order_mark_agree =
  property ~name:"the body starts at boundary 1 only after a byte order mark"
    ~print:print_uchars (uchars_gen edge_uchar) (fun uchars ->
      let text = Text.of_uchars uchars in
      let bom =
        match uchars with
        | first :: _ -> Uchar.to_int first = 0xFEFF
        | [] -> false
      in
      let body = Text.body text in
      Text.has_byte_order_mark text = bom
      && (body.from = if bom then 1 else 0)
      && body.until = List.length uchars)

let lf = Uchar.of_int 0x0A
let cr = Uchar.of_int 0x0D
let at uchars place = List.nth uchars (place - 1)

let lines_divide_the_body uchars =
  let text = Text.of_uchars uchars in
  let lines = Lines.of_text text in
  let runs = Lines.all lines in
  let body = Text.body text in
  let char place = at uchars place in
  let ending_after (run : Text.run) =
    if run.until < body.until && Uchar.equal (char (run.until + 1)) lf then
      Some 1
    else if
      run.until + 1 < body.until
      && Uchar.equal (char (run.until + 1)) cr
      && Uchar.equal (char (run.until + 2)) lf
    then Some 2
    else None
  in
  let no_line_feed (run : Text.run) =
    List.for_all
      (fun place -> not (Uchar.equal (char place) lf))
      (List.init (run.until - run.from) (fun index -> run.from + index + 1))
  in
  let not_ending_in_cr_before_lf (run : Text.run) =
    not
      (run.until > run.from
      && Uchar.equal (char run.until) cr
      && run.until < body.until
      && Uchar.equal (char (run.until + 1)) lf)
  in
  let rec walk from = function
    | [] -> from = body.until
    | (run : Text.run) :: rest -> (
        run.from = from && run.until >= run.from && no_line_feed run
        && not_ending_in_cr_before_lf run
        &&
        match ending_after run with
        | Some width -> walk (run.until + width) rest
        | None -> rest = [] && run.until = body.until && run.until > run.from)
  in
  Lines.count lines = List.length runs
  && walk body.from runs
  && List.for_all2
       (fun number run -> Lines.line lines number = Some run)
       (List.init (List.length runs) (fun index -> index + 1))
       runs
  && Option.is_none (Lines.line lines 0)
  && Option.is_none (Lines.line lines (List.length runs + 1))

(* @verifies text#{give-lines=v1, give-numbered-lines=v1, give-only-lines=v1} *)
let lines_cover_the_body_in_order =
  property ~count:1000
    ~name:"the lines and their line endings cover the body in order"
    ~print:print_uchars (uchars_gen edge_uchar) lines_divide_the_body

let boundary_position uchars runs boundary : Lines.position =
  let numbered = List.mapi (fun index run -> (index + 1, run)) runs in
  match
    List.find_opt
      (fun (_, (run : Text.run)) ->
        run.from <= boundary && boundary <= run.until)
      numbered
  with
  | Some (number, run) -> { line = number; column = boundary - run.from + 1 }
  | None -> (
      match
        List.find_opt
          (fun (_, (run : Text.run)) ->
            boundary = run.until + 1
            && boundary <= List.length uchars
            && Uchar.equal (at uchars boundary) cr)
          numbered
      with
      | Some (number, run) ->
          { line = number; column = run.until - run.from + 1 }
      | None -> { line = List.length runs + 1; column = 1 })

(* @verifies text#{give-character-positions=v1, omit-byte-order-mark-positions=v1} *)
let character_positions_follow_the_lines =
  property ~count:500
    ~name:"each place of the body has the position of the boundary before it"
    ~print:print_uchars (uchars_gen edge_uchar) (fun uchars ->
      let text = Text.of_uchars uchars in
      let lines = Lines.of_text text in
      let runs = Lines.all lines in
      let body = Text.body text in
      List.for_all
        (fun place ->
          let have = Lines.character_position lines place in
          if place < 1 || place > List.length uchars then
            have = Error Lines.Not_a_place
          else if place <= body.from then have = Error Lines.Byte_order_mark
          else have = Ok (boundary_position uchars runs (place - 1)))
        (List.init (List.length uchars + 3) (fun index -> index - 1)))

(* @verifies text#{give-span-starts=v1, give-span-ends=v1, give-positions-only-for-spans=v1} *)
let spans_follow_the_lines =
  property ~count:300
    ~name:"each run that starts in the body has the start and end of a span"
    ~print:print_uchars (uchars_gen edge_uchar) (fun uchars ->
      let text = Text.of_uchars uchars in
      let lines = Lines.of_text text in
      let runs = Lines.all lines in
      let body = Text.body text in
      let length = List.length uchars in
      let in_a_line place =
        List.exists
          (fun (run : Text.run) -> run.from < place && place <= run.until)
          runs
      in
      let check from until =
        let have = Lines.span lines { from; until } in
        if from < 0 || until < from || until > length then
          have = Error Lines.Not_a_run
        else if from < body.from then have = Error Lines.Not_a_span
        else
          let start = boundary_position uchars runs from in
          let last =
            List.find_opt in_a_line
              (List.rev
                 (List.init (until - from) (fun index -> from + index + 1)))
          in
          let stop =
            match last with
            | Some place -> boundary_position uchars runs place
            | None -> start
          in
          have = Ok (start, stop)
      in
      let bounds = List.init (length + 3) (fun index -> index - 1) in
      List.for_all (fun from -> List.for_all (check from) bounds) bounds)

let large_text_has_its_lines () =
  let line = String.make 99 'x' ^ "\n" in
  let string = String.concat "" (List.init 20000 (fun _ -> line)) in
  match Text.decode string with
  | Error _ -> Alcotest.fail "the text is valid UTF-8"
  | Ok text ->
      let lines = Lines.of_text text in
      Alcotest.(check int) "the count" 20000 (Lines.count lines);
      Alcotest.(check bool)
        "the position of the last character" true
        (Lines.character_position lines (Text.length text)
        = Ok { line = 20000; column = 100 })

let vector_groups =
  [
    decode_vectors;
    encode_vectors;
    lines_vectors;
    character_position_vectors;
    span_vectors;
  ]

let tests =
  Vectors.tests "text" vector_groups
  @ [
      Vectors.covers "text" text_set vector_groups;
      Alcotest.test_case "decode names the place of the first bad byte" `Quick
        decode_names_the_place_of_the_first_bad_byte;
      Alcotest.test_case "empty is the text of no characters" `Quick
        empty_is_the_text_of_no_characters;
      Alcotest.test_case "get gives no character outside the places" `Quick
        get_gives_no_character_outside_the_places;
      Alcotest.test_case "sub gives no text for a pair that is not a run" `Quick
        sub_gives_no_text_for_a_pair_that_is_not_a_run;
      Alcotest.test_case "equal tells texts apart" `Quick
        equal_tells_texts_apart;
      Alcotest.test_case "the body starts after a byte order mark" `Quick
        body_starts_after_a_byte_order_mark;
      Alcotest.test_case "the lines keep their text" `Quick
        lines_keep_their_text;
      Alcotest.test_case "line gives no run outside the line numbers" `Quick
        line_gives_no_run_outside_the_line_numbers;
      Alcotest.test_case "character_position refuses what is not a place" `Quick
        character_position_refuses_what_is_not_a_place;
      Alcotest.test_case "span refuses what is not a run" `Quick
        span_refuses_what_is_not_a_run;
      Alcotest.test_case "a large text has its lines and positions" `Quick
        large_text_has_its_lines;
      decode_gives_back_the_encoded_text;
      encode_gives_the_bytes_of_each_character;
      of_uchars_keeps_each_character;
      sub_gives_the_characters_of_the_run;
      equal_holds_for_the_same_characters;
      concat_joins_the_characters_in_order;
      Alcotest.test_case "concat of no text is the empty text" `Quick
        concat_of_no_text_is_empty;
      decode_answers_every_byte_sequence;
      decode_refuses_corrupted_encodings;
      body_and_byte_order_mark_agree;
      lines_cover_the_body_in_order;
      character_positions_follow_the_lines;
      spans_follow_the_lines;
    ]
