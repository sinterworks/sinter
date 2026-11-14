(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Descriptor = Sinter_pack_descriptor.Descriptor
module Toml = Sinter_data_forms_toml.Data_forms_toml
module Json = Sinter_json_lines.Json
module Names = Set.Make (String)
module Settings = Map.Make (String)

type t = { values : (string * Descriptor.setting_value) list; json : Json.t }

type error =
  | Not_a_setting of string
  | Repeated_name of string
  | Wrong_type of string
  | Not_utf_8 of string

let text bytes = Result.to_option (Text.decode bytes)

let json_value = function
  | Descriptor.String bytes -> Option.map Json.string (text bytes)
  | Descriptor.Boolean flag -> Some (Json.boolean flag)
  | Descriptor.Strings texts ->
      let rec all taken = function
        | [] -> Some (Json.array (List.rev taken))
        | bytes :: rest -> (
            match text bytes with
            | None -> None
            | Some text -> all (Json.string text :: taken) rest)
      in
      all [] texts

(* @satisfies packs#give-requests=v1
   The settings object has one member for each runner setting, whose key is its
   name and whose value is a string, a boolean, or an array of strings for the
   value of the setting. *)
let make values =
  let values = List.sort (fun (a, _) (b, _) -> String.compare a b) values in
  let rec members taken = function
    | [] -> Ok { values; json = Json_values.object_ (List.rev taken) }
    | (name, value) :: rest -> (
        match (text name, json_value value) with
        | Some key, Some json -> members ((key, json) :: taken) rest
        | _ -> Error (Not_utf_8 name))
  in
  members [] values

let of_list values =
  let rec check seen = function
    | [] -> make values
    | (name, value) :: rest ->
        if Names.mem name seen then Error (Repeated_name name)
        else if Option.is_none (text name) || Option.is_none (json_value value)
        then Error (Not_utf_8 name)
        else check (Names.add name seen) rest
  in
  check Names.empty values

let of_toml = function
  | Toml.String text -> Some (Descriptor.String text)
  | Toml.Boolean flag -> Some (Descriptor.Boolean flag)
  | Toml.Array values ->
      let rec all taken = function
        | [] -> Some (Descriptor.Strings (List.rev taken))
        | Toml.String text :: rest -> all (text :: taken) rest
        | _ :: _ -> None
      in
      all [] values
  | _ -> None

let same_type default value =
  match
    ((default : Descriptor.setting_value), (value : Descriptor.setting_value))
  with
  | String _, String _ | Boolean _, Boolean _ | Strings _, Strings _ -> true
  | _ -> false

(* @satisfies packs#give-requests=v1
   A pair must name a runner setting of the test runner, once, with a TOML
   value of its type; a runner setting with no pair keeps its default value. *)
let bind (runner : Descriptor.runner) binding =
  let defaults =
    List.fold_left
      (fun defaults (setting : Descriptor.runner_setting) ->
        Settings.add setting.setting_name setting.default defaults)
      Settings.empty runner.settings
  in
  let rec check seen values = function
    | [] -> make (Settings.bindings values)
    | (name, value) :: rest -> (
        match Settings.find_opt name defaults with
        | None -> Error (Not_a_setting name)
        | Some default -> (
            if Names.mem name seen then Error (Repeated_name name)
            else
              match of_toml value with
              | Some value when same_type default value -> (
                  match json_value value with
                  | None -> Error (Not_utf_8 name)
                  | Some _ ->
                      check (Names.add name seen)
                        (Settings.add name value values)
                        rest)
              | _ -> Error (Wrong_type name)))
  in
  check Names.empty defaults binding

let to_list settings = settings.values
let to_json settings = settings.json
