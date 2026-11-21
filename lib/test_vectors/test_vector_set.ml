(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
module Schemas = Map.Make (String)

type vector = {
  form : string;
  group : string;
  input : Json.t;
  result : Text.t option;
  values : Json.t option;
  note : Text.t option;
  needs : string list;
}

type t = { vectors : vector list; objects : Json.t list }

type error =
  | Unterminated of int
  | Not_canonical of int
  | Not_vector_object of int
  | Other_schema of int

let is_digit c = c >= '0' && c <= '9'
let is_lower c = c >= 'a' && c <= 'z'
let is_upper c = c >= 'A' && c <= 'Z'
let is_lower_or_digit c = is_lower c || is_digit c
let is_alnum c = is_lower c || is_upper c || is_digit c

(* @satisfies data-forms#read-test-vector-set=v1
   A group name starts with a lower-case letter, and its parts between `-` are
   each one or more lower-case letters or digits. *)
let is_group_name text =
  String.length text > 0
  && is_lower text.[0]
  && List.for_all
       (fun part -> part <> "" && String.for_all is_lower_or_digit part)
       (String.split_on_char '-' text)

(* @satisfies data-forms#read-test-vector-set=v1
   A segment of a form pin is runs of one or more letters or digits, with one
   `-`, `_`, or `.` between each two runs. *)
let is_segment text =
  List.for_all
    (fun run -> run <> "" && String.for_all is_alnum run)
    (String.split_on_char '-'
       (String.map (function '_' | '.' -> '-' | c -> c) text))

(* @satisfies data-forms#read-test-vector-set=v1
   A byte of the label of a form pin is a printable ASCII byte other than `#`,
   `*`, `,`, `/`, `=`, `@`, `[`, `]`, `{`, and `}`. *)
let is_label_byte c =
  c >= '!' && c <= '~' && not (String.contains "#*,/=@[]{}" c)

(* @satisfies data-forms#read-test-vector-set=v1
   A form pin is `#`, then a segment, then `=`, then one or more label bytes.
   No label byte is `=`, so the first `=` ends the segment. The schema part
   name is the segment. *)
let schema_part_name form =
  let n = String.length form in
  if n = 0 || form.[0] <> '#' then None
  else
    match String.index_opt form '=' with
    | None -> None
    | Some equals ->
        let segment = String.sub form 1 (equals - 1)
        and label = String.sub form (equals + 1) (n - equals - 1) in
        if
          is_segment segment && label <> ""
          && String.for_all is_label_byte label
        then Some segment
        else None

let string_of (value : Json.t) =
  match value with
  | String text -> Some text
  | Integer _ | Boolean _ | Array _ | Object _ -> None

let group_name_of value =
  match Option.map Text.encode (string_of value) with
  | Some text when is_group_name text -> Some text
  | Some _ | None -> None

let form_of value =
  Option.bind
    (Option.map Text.encode (string_of value))
    (fun text ->
      Option.map (fun schema -> (text, schema)) (schema_part_name text))

(* @satisfies data-forms#read-test-vector-set=v1
   The value of `needs` is an array of one or more group names, each after the
   one before it in key order. Group names hold only ASCII bytes, so the order
   of their bytes is their key order. *)
let needs_of (value : Json.t) =
  let rec names last found = function
    | [] -> Some (List.rev found)
    | element :: rest -> (
        match group_name_of element with
        | Some name when String.compare last name < 0 ->
            names name (name :: found) rest
        | Some _ | None -> None)
  in
  match value with
  | Array (_ :: _ as elements) -> names "" [] elements
  | Array [] | String _ | Integer _ | Boolean _ | Object _ -> None

let optional find value =
  match value with
  | None -> Some None
  | Some value -> Option.map Option.some (find value)

(* @satisfies data-forms#read-test-vector-set=v1
   A vector object has `form`, `group`, and `input`, has `result` or `values`
   or both, can have `needs` and `note`, and has no other member. The members
   of an object stand in key order, so one pass over them in that order finds
   each member and rejects every other key. *)
let vector_object (value : Json.t) =
  match value with
  | String _ | Integer _ | Boolean _ | Array _ -> None
  | Object members -> (
      let members =
        List.map (fun (key, value) -> (Text.encode key, value)) members
      in
      let take key = function
        | (found, value) :: rest when String.equal found key ->
            (Some value, rest)
        | rest -> (None, rest)
      in
      let form, rest = take "form" members in
      let group, rest = take "group" rest in
      let input, rest = take "input" rest in
      let needs, rest = take "needs" rest in
      let note, rest = take "note" rest in
      let result, rest = take "result" rest in
      let values, rest = take "values" rest in
      match
        ( rest,
          Option.bind form form_of,
          Option.bind group group_name_of,
          input,
          optional needs_of needs,
          optional string_of note,
          optional string_of result )
      with
      | ( [],
          Some (form, schema),
          Some group,
          Some input,
          Some needs,
          Some note,
          Some result ) ->
          if Option.is_none result && Option.is_none values then None
          else
            Some
              ( {
                  form;
                  group;
                  input;
                  result;
                  values;
                  note;
                  needs = Option.value needs ~default:[];
                },
                schema )
      | _ -> None)

(* @satisfies data-forms#read-test-vector-set=v1
   All vector lines with the same group have the same schema part name in their
   form. *)
let same_schema schemas group schema =
  match Schemas.find_opt group schemas with
  | None -> Some (Schemas.add group schema schemas)
  | Some earlier when String.equal earlier schema -> Some schemas
  | Some _ -> None

(* @satisfies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1}
   read gives a set only when each line is the canonical byte sequence of a
   vector object, then 0x0A, and the lines of each group share one schema part
   name; the set then holds the object of each line once, in the order of the
   lines. *)
let read bytes =
  let rec lines number schemas vectors objects = function
    | [ "" ] | [] ->
        Ok { vectors = List.rev vectors; objects = List.rev objects }
    | [ _ ] -> Error (Unterminated number)
    | line :: rest -> (
        match Json.read line with
        | None -> Error (Not_canonical number)
        | Some value -> (
            match vector_object value with
            | None -> Error (Not_vector_object number)
            | Some (vector, schema) -> (
                match same_schema schemas vector.group schema with
                | None -> Error (Other_schema number)
                | Some schemas ->
                    lines (number + 1) schemas (vector :: vectors)
                      (value :: objects) rest)))
  in
  lines 1 Schemas.empty [] [] (String.split_on_char '\n' bytes)
