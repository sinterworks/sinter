(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
module Names = Set.Make (String)

type revision = string

(* @satisfies data-forms#validate-version-sequences=v1
   One revision is higher than another exactly when its decimal numeral has
   more digits, or as many digits and a greater digit at the first difference. *)
let compare_revisions r s =
  let lengths = Int.compare (String.length r) (String.length s) in
  if lengths <> 0 then lengths else String.compare r s

type group = { name : string; revision : revision }

type vector = {
  number : int;
  revision : revision;
  group : string;
  input : Json.t;
  result : Text.t option;
  values : Json.t option;
  note : Text.t option;
  needs : string list;
}

type t = {
  revision : revision;
  groups : group list;
  vectors : vector list;
  objects : Json.t list;
}

let is_digit c = c >= '0' && c <= '9'
let is_letter c = c >= 'a' && c <= 'z'

(* @satisfies data-forms#read-test-vector-set=v1
   A revision is `v`, then a decimal numeral that does not start with `0`. *)
let is_revision text =
  String.length text >= 2
  && text.[0] = 'v'
  && text.[1] <> '0'
  && String.for_all is_digit (String.sub text 1 (String.length text - 1))

let is_letter_or_digit c = is_letter c || is_digit c

(* @satisfies data-forms#read-test-vector-set=v1
   A group name starts with a letter, and its parts between `-` are each one
   or more letters or digits. *)
let is_group_name text =
  String.length text > 0
  && is_letter text.[0]
  && List.for_all
       (fun part -> part <> "" && String.for_all is_letter_or_digit part)
       (String.split_on_char '-' text)

let members (value : Json.t) =
  match value with
  | Object members ->
      Some (List.map (fun (key, value) -> (Text.encode key, value)) members)
  | String _ | Integer _ | Boolean _ | Array _ -> None

let text_of (value : Json.t) =
  match value with
  | String text -> Some text
  | Integer _ | Boolean _ | Array _ | Object _ -> None

let string_of value = Option.map Text.encode (text_of value)

let revision_of value =
  match string_of value with
  | Some text when is_revision text -> Some text
  | Some _ | None -> None

let group_name_of value =
  match string_of value with
  | Some text when is_group_name text -> Some text
  | Some _ | None -> None

let set_object value =
  match members value with
  | Some [ ("rev", rev) ] -> revision_of rev
  | Some _ | None -> None

let group_object value : group option =
  match members value with
  | Some [ ("group", group); ("rev", rev) ] -> (
      match (group_name_of group, revision_of rev) with
      | Some name, Some revision -> Some { name; revision }
      | _ -> None)
  | Some _ | None -> None

(* @satisfies data-forms#read-test-vector-set=v1
   The value of `needs` is an array of one or more group names, each after
   the one before it in key order. *)
let needs_of (value : Json.t) =
  match value with
  | Array (_ :: _ as elements) ->
      let names = List.filter_map group_name_of elements in
      let rec rising = function
        | a :: (b :: _ as rest) -> String.compare a b < 0 && rising rest
        | [ _ ] | [] -> true
      in
      if List.length names = List.length elements && rising names then
        Some names
      else None
  | Array [] | String _ | Integer _ | Boolean _ | Object _ -> None

let optional find key members =
  match List.assoc_opt key members with
  | None -> Some None
  | Some value -> Option.map Option.some (find value)

(* @satisfies data-forms#read-test-vector-set=v1
   A vector object has `n`, `rev`, `group`, and `input`, `result` or `values`
   or both, can have `note` and `needs`, and has no other member. *)
let vector_object value =
  match members value with
  | None -> None
  | Some members -> (
      let known =
        [ "group"; "input"; "n"; "needs"; "note"; "result"; "rev"; "values" ]
      in
      let required find key = Option.bind (List.assoc_opt key members) find in
      match
        ( List.for_all (fun (key, _) -> List.mem key known) members,
          required
            (fun (n : Json.t) ->
              match n with Integer n when n >= 1 -> Some n | _ -> None)
            "n",
          required revision_of "rev",
          required group_name_of "group",
          required Option.some "input",
          optional text_of "result" members,
          optional Option.some "values" members,
          optional text_of "note" members,
          optional needs_of "needs" members )
      with
      | ( true,
          Some number,
          Some revision,
          Some group,
          Some input,
          Some result,
          Some values,
          Some note,
          Some needs ) ->
          if Option.is_none result && Option.is_none values then None
          else
            Some
              {
                number;
                revision;
                group;
                input;
                result;
                values;
                note;
                needs = Option.value needs ~default:[];
              }
      | _ -> None)

let rec read_objects objects = function
  | [ "" ] -> Some (List.rev objects)
  | [] -> None
  | line :: rest -> (
      match Json.read line with
      | Some value -> read_objects (value :: objects) rest
      | None -> None)

let rec read_groups groups = function
  | value :: rest as lines -> (
      match group_object value with
      | Some group -> read_groups (group :: groups) rest
      | None -> (List.rev groups, lines))
  | [] -> (List.rev groups, [])

let rec read_vectors vectors = function
  | [] -> Some (List.rev vectors)
  | value :: rest -> (
      match vector_object value with
      | Some vector -> read_vectors (vector :: vectors) rest
      | None -> None)

(* @satisfies data-forms#read-test-vector-set=v1
   The groups of the group lines stand in rising key order, so no group line
   repeats a group. *)
let rec rising_names = function
  | (a : group) :: (b :: _ as rest) ->
      String.compare a.name b.name < 0 && rising_names rest
  | [ _ ] | [] -> true

(* @satisfies data-forms#read-test-vector-set=v1
   Each vector line has a greater number than the vector line before it. *)
let rec rising_numbers = function
  | (a : vector) :: (b :: _ as rest) ->
      a.number < b.number && rising_numbers rest
  | [ _ ] | [] -> true

(* @satisfies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1}
   Gives a set, and so the result valid, only for one set line, then group
   lines in rising order of their groups, one for each group of the vector
   lines, then vector lines in rising order of their numbers; and then the
   objects of all these lines, each once and in their order. *)
let read bytes =
  match read_objects [] (String.split_on_char '\n' bytes) with
  | None | Some [] -> None
  | Some (set :: rest as objects) -> (
      match set_object set with
      | None -> None
      | Some revision -> (
          let groups, rest = read_groups [] rest in
          match read_vectors [] rest with
          | None -> None
          | Some vectors ->
              let group_names =
                Names.of_list
                  (List.map (fun (group : group) -> group.name) groups)
              and vector_groups =
                Names.of_list
                  (List.map (fun (vector : vector) -> vector.group) vectors)
              in
              if
                rising_names groups && rising_numbers vectors
                && Names.equal group_names vector_groups
              then Some { revision; groups; vectors; objects }
              else None))
