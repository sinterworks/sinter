(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module V = Vector_json

let is_digit char = char >= '0' && char <= '9'
let is_lower char = char >= 'a' && char <= 'z'
let is_upper char = char >= 'A' && char <= 'Z'
let is_alnum char = is_lower char || is_upper char || is_digit char

let is_label_char = function
  | '\x21' .. '\x22'
  | '\x24' .. '\x29'
  | '\x2b'
  | '\x2d' .. '\x2e'
  | '\x30' .. '\x3c'
  | '\x3e' .. '\x3f'
  | '\x41' .. '\x5a'
  | '\x5c'
  | '\x5e' .. '\x7a'
  | '\x7c' | '\x7e' ->
      true
  | _ -> false

let is_segment text =
  let length = String.length text in
  if length = 0 then false
  else
    let rec loop index expect_alnum =
      if index = length then not expect_alnum
      else
        let char = text.[index] in
        if is_alnum char then loop (index + 1) false
        else if (not expect_alnum) && (char = '-' || char = '_' || char = '.')
        then loop (index + 1) true
        else false
    in
    loop 0 true

let is_label text = String.length text >= 1 && String.for_all is_label_char text

let parse_form_pin text =
  let length = String.length text in
  if length < 4 || text.[0] <> '#' then None
  else
    match String.index_opt text '=' with
    | None -> None
    | Some eq ->
        let segment = String.sub text 1 (eq - 1) in
        let label = String.sub text (eq + 1) (length - eq - 1) in
        if is_segment segment && is_label label then Some (segment, label)
        else None

let is_form_pin text = Option.is_some (parse_form_pin text)

let is_group_name text =
  match String.split_on_char '-' text with
  | [] -> false
  | first :: _ as parts ->
      first <> ""
      && is_lower first.[0]
      && List.for_all
           (fun part ->
             part <> ""
             && String.for_all (fun char -> is_lower char || is_digit char) part)
           parts

let fields = function
  | V.Object members ->
      List.filter_map
        (function V.Text name, value -> Some (name, value) | _ -> None)
        members
  | _ -> []

let names object_ = List.sort String.compare (List.map fst (fields object_))

let string_member name object_ =
  match List.assoc_opt name (fields object_) with
  | Some (V.String (V.Text text)) -> Some text
  | _ -> None

let rec strictly_rising compare = function
  | a :: (b :: _ as rest) -> compare a b < 0 && strictly_rising compare rest
  | _ -> true

let has_needs object_ =
  match List.assoc_opt "needs" (fields object_) with
  | Some (V.Array (_ :: _ as items)) ->
      let texts =
        List.filter_map
          (function V.String (V.Text text) -> Some text | _ -> None)
          items
      in
      List.length texts = List.length items
      && List.for_all is_group_name texts
      && strictly_rising V.compare_keys texts
  | _ -> false

let vector_object_info = function
  | V.Object _ as object_ -> (
      let present = names object_ in
      let has name = List.mem name present in
      let allowed =
        [ "form"; "group"; "input"; "needs"; "note"; "result"; "values" ]
      in
      let valid_keys =
        List.for_all (fun name -> List.mem name allowed) present
        && has "form" && has "group" && has "input"
        && (has "result" || has "values")
        && ((not (has "result"))
           || Option.is_some (string_member "result" object_))
        && ((not (has "note")) || Option.is_some (string_member "note" object_))
        && ((not (has "needs")) || has_needs object_)
      in
      if not valid_keys then None
      else
        match (string_member "form" object_, string_member "group" object_) with
        | Some form, Some group when is_group_name group -> (
            match parse_form_pin form with
            | Some (schema_part, _) -> Some (group, schema_part)
            | None -> None)
        | _ -> None)
  | _ -> None

type error =
  | Unterminated of int
  | Not_canonical of int
  | Not_vector_object of int
  | Other_schema of int

let canonical_json_value line =
  match V.json_value_of_bytes line with
  | Some value when V.canonical value = Some line -> Some value
  | _ -> None

let read bytes =
  let length = String.length bytes in
  let rec loop start line_number schemas acc =
    if start = length then Ok (List.rev acc)
    else
      match String.index_from_opt bytes start '\n' with
      | None -> Error (Unterminated line_number)
      | Some nl -> (
          let line = String.sub bytes start (nl - start) in
          match canonical_json_value line with
          | None -> Error (Not_canonical line_number)
          | Some value -> (
              match vector_object_info value with
              | None -> Error (Not_vector_object line_number)
              | Some (group, schema_part) -> (
                  match List.assoc_opt group schemas with
                  | Some existing when existing <> schema_part ->
                      Error (Other_schema line_number)
                  | Some _ ->
                      loop (nl + 1) (line_number + 1) schemas (value :: acc)
                  | None ->
                      loop (nl + 1) (line_number + 1)
                        ((group, schema_part) :: schemas)
                        (value :: acc))))
  in
  loop 0 1 [] []

let write objects =
  String.concat ""
    (List.map
       (fun object_ ->
         match V.canonical object_ with
         | Some bytes -> bytes ^ "\n"
         | None -> invalid_arg "write")
       objects)
