(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module T = Sinter_data_forms_toml.Data_forms_toml

let is_lower c = c >= 'a' && c <= 'z'
let is_digit c = c >= '0' && c <= '9'
let is_alpha c = is_lower c || (c >= 'A' && c <= 'Z')

let is_pack_name text =
  match String.split_on_char '-' text with
  | [] -> false
  | first :: rest ->
      first <> ""
      && is_lower first.[0]
      && String.for_all (fun c -> is_lower c || is_digit c) first
      && List.for_all
           (fun part ->
             part <> ""
             && String.for_all (fun c -> is_lower c || is_digit c) part)
           rest

let is_grammar_name text =
  text <> ""
  && is_lower text.[0]
  && String.for_all (fun c -> is_lower c || is_digit c || c = '_') text

let is_decimal_numeral text =
  text = "0" || (text <> "" && text.[0] <> '0' && String.for_all is_digit text)

let is_numerals count text =
  let parts = String.split_on_char '.' text in
  List.length parts = count && List.for_all is_decimal_numeral parts

let is_foreign_tag text =
  text <> ""
  && String.for_all (fun c -> is_alpha c || is_digit c || c = '-') text

let is_hash_form text =
  String.length text = 64
  && String.for_all (fun c -> is_digit c || (c >= 'a' && c <= 'f')) text

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

let is_glob text = Paths_reference.is_glob (uchars text)

let rec form_of_toml : T.value -> Yojson.Basic.t = function
  | String text -> `Assoc [ ("string", `String text) ]
  | Boolean flag -> `Assoc [ ("boolean", `Bool flag) ]
  | Array values -> `Assoc [ ("array", `List (List.map form_of_toml values)) ]
  | Table pairs ->
      `Assoc
        [
          ( "table",
            `Assoc
              (List.map (fun (key, value) -> (key, form_of_toml value)) pairs)
          );
        ]
  | Integer number -> `Assoc [ ("integer", `String (Int64.to_string number)) ]
  | Float number ->
      `Assoc
        [
          ( "float",
            `String
              (if Float.is_nan number then "nan"
               else Int64.to_string (Int64.bits_of_float number)) );
        ]
  | Local_date date -> `Assoc [ ("local-date", date_form date) ]
  | Local_time time -> `Assoc [ ("local-time", time_form time) ]
  | Local_date_time (date, time) ->
      `Assoc [ ("local-date-time", `List [ date_form date; time_form time ]) ]
  | Offset_date_time (date, time, offset) ->
      `Assoc
        [
          ( "offset-date-time",
            `List
              [
                date_form date;
                time_form time;
                (match offset with
                | Minutes minutes -> `Int minutes
                | Unknown_local -> `String "unknown");
              ] );
        ]

and date_form (date : Sinter_toml.date) =
  `List [ `Int date.year; `Int date.month; `Int date.day ]

and time_form (time : Sinter_toml.time) =
  `List
    [ `Int time.hour; `Int time.minute; `Int time.second; `Int time.nanosecond ]

exception Not_valid

let check condition = if not condition then raise Not_valid

let keys_within allowed (table : T.table) =
  check (List.for_all (fun (key, _) -> List.mem key allowed) table)

let string = function T.String text -> text | _ -> raise Not_valid
let table = function T.Table pairs -> pairs | _ -> raise Not_valid

let strings = function
  | T.Array values -> List.map string values
  | _ -> raise Not_valid

let required key (table : T.table) =
  match List.assoc_opt key table with
  | Some value -> value
  | None -> raise Not_valid

let texts list = `List (List.map (fun text -> `String text) list)

let grammar_form value =
  let pairs = table value in
  keys_within [ "name"; "sha256"; "license"; "names" ] pairs;
  let name = string (required "name" pairs) in
  let hash = string (required "sha256" pairs) in
  let license = string (required "license" pairs) in
  let globs = strings (required "names" pairs) in
  check (is_grammar_name name);
  check (is_hash_form hash);
  check (List.for_all is_glob globs);
  ( name,
    `Assoc
      [
        ("globs", texts globs);
        ("hash", `String hash);
        ("license", `String license);
        ("name", `String name);
      ],
    globs )

let setting_form (name, value) =
  (match value with
  | T.String _ | T.Boolean _ -> ()
  | T.Array values -> ignore (strings (T.Array values))
  | _ -> raise Not_valid);
  `Assoc [ ("default", form_of_toml value); ("name", `String name) ]

let runner_form (name, value) =
  check (is_pack_name name);
  let pairs = table value in
  keys_within [ "adapter"; "match"; "settings" ] pairs;
  let adapter = List.assoc_opt "adapter" pairs in
  let match_ = List.assoc_opt "match" pairs in
  check (Option.is_some adapter <> Option.is_some match_);
  let adapter_members =
    match adapter with
    | None -> []
    | Some value ->
        let adapter = table value in
        keys_within [ "sha256"; "license" ] adapter;
        let hash = string (required "sha256" adapter) in
        let license = string (required "license" adapter) in
        check (is_hash_form hash);
        [ ("adapter-hash", `String hash); ("adapter-license", `String license) ]
  in
  let match_members =
    match match_ with
    | None -> []
    | Some value ->
        ignore (table value);
        [ ("match", form_of_toml value) ]
  in
  let settings =
    match List.assoc_opt "settings" pairs with
    | None -> []
    | Some value ->
        List.sort (fun (a, _) (b, _) -> String.compare a b) (table value)
  in
  `Assoc
    (adapter_members @ match_members
    @ [
        ("name", `String name);
        ("settings", `List (List.map setting_form settings));
      ])

let read bytes =
  match T.read bytes with
  | T.Invalid | T.No_result -> raise Not_valid
  | T.Valid { root_table = root; _ } ->
      keys_within
        [
          "sinter-spec";
          "name";
          "version";
          "license";
          "name-separator";
          "foreign-tags";
          "comments";
          "grammar";
          "runner";
        ]
        root;
      let spec = string (required "sinter-spec" root) in
      let name = string (required "name" root) in
      let release = string (required "version" root) in
      let license = string (required "license" root) in
      let separator = string (required "name-separator" root) in
      check (is_numerals 2 spec);
      check (is_pack_name name);
      check (is_numerals 3 release);
      check (separator <> "");
      let tags =
        match List.assoc_opt "foreign-tags" root with
        | None -> []
        | Some value -> strings value
      in
      check (List.for_all is_foreign_tag tags);
      let comments = table (required "comments" root) in
      keys_within [ "line"; "block"; "inner" ] comments;
      let list key =
        match List.assoc_opt key comments with
        | None -> []
        | Some v -> strings v
      in
      let line = list "line" and inner = list "inner" in
      let block =
        match List.assoc_opt "block" comments with
        | None -> []
        | Some (T.Array pairs) ->
            List.map
              (fun pair ->
                match strings pair with
                | [ opening; closing ] -> (opening, closing)
                | _ -> raise Not_valid)
              pairs
        | Some _ -> raise Not_valid
      in
      let grammars =
        match required "grammar" root with
        | T.Array (_ :: _ as values) -> List.map grammar_form values
        | _ -> raise Not_valid
      in
      let names = List.map (fun (name, _, _) -> name) grammars in
      check
        (List.length (List.sort_uniq String.compare names) = List.length names);
      let runners =
        match List.assoc_opt "runner" root with
        | None -> []
        | Some value ->
            List.sort (fun (a, _) (b, _) -> String.compare a b) (table value)
      in
      let form =
        `Assoc
          [
            ( "block-pairs",
              `List
                (List.map
                   (fun (opening, closing) ->
                     `List [ `String opening; `String closing ])
                   block) );
            ("foreign-tag-words", texts (List.map (fun tag -> "@" ^ tag) tags));
            ("grammars", `List (List.map (fun (_, form, _) -> form) grammars));
            ("inner-sigils", texts inner);
            ("license", `String license);
            ("line-sigils", texts line);
            ("name", `String name);
            ("name-separator", `String separator);
            ("release", `String release);
            ("runners", `List (List.map runner_form runners));
            ("spec-version", `String spec);
          ]
      in
      (form, List.map (fun (name, _, globs) -> (name, globs)) grammars)

let values bytes =
  match read bytes with form, _ -> Some form | exception Not_valid -> None

let last_file_name path =
  match List.rev (String.split_on_char '/' path) with
  | last :: _ -> last
  | [] -> path

let file_grammar bytes ~path =
  if not (Paths_reference.is_path (uchars path)) then
    invalid_arg "Descriptor_reference.file_grammar: not a valid path";
  match read bytes with
  | exception Not_valid ->
      invalid_arg "Descriptor_reference.file_grammar: not a valid descriptor"
  | _, grammars ->
      let name = uchars (last_file_name path) in
      List.find_map
        (fun (grammar, globs) ->
          if
            List.exists
              (fun glob -> Paths_reference.fits ~path:name ~glob:(uchars glob))
              globs
          then Some grammar
          else None)
        grammars
