(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Toml = Sinter_data_forms_toml.Data_forms_toml
module Hash = Sinter_hashes.Hash
module Glob = Sinter_paths.Glob
module Path = Sinter_paths.Path

type setting_value =
  | String of string
  | Boolean of bool
  | Strings of string list

type runner_setting = { setting_name : string; default : setting_value }

type runner_source =
  | Adapter of { hash : Hash.t; license : string }
  | Match of Toml.table

type runner = {
  runner_name : Pack_name.t;
  source : runner_source;
  settings : runner_setting list;
}

type grammar = {
  grammar_name : Grammar_name.t;
  hash : Hash.t;
  license : string;
  globs : Glob.t list;
}

type t = {
  spec_version : Spec_version.t;
  name : Pack_name.t;
  release : Release_number.t;
  license : string;
  name_separator : string;
  foreign_tag_words : string list;
  line_sigils : string list;
  block_pairs : (string * string) list;
  inner_sigils : string list;
  grammars : grammar list;
  runners : runner list;
}

type error = Not_a_toml_document | Breaks_a_rule

let ( let* ) = Option.bind

let all f values =
  let rec go taken = function
    | [] -> Some (List.rev taken)
    | value :: rest -> (
        match f value with None -> None | Some y -> go (y :: taken) rest)
  in
  go [] values

let only keys table = List.for_all (fun (key, _) -> List.mem key keys) table
let string = function Toml.String text -> Some text | _ -> None
let table = function Toml.Table table -> Some table | _ -> None
let array = function Toml.Array values -> Some values | _ -> None

let strings value =
  let* values = array value in
  all string values

let required table key = List.assoc_opt key table

let optional table key ~absent f =
  match List.assoc_opt key table with
  | None -> Some absent
  | Some value -> f value

let checked check text = if check text then Some text else None

(* @satisfies packs#read-descriptor=v1
   A foreign tag word is written without its [@], as one or more ASCII
   letters, ASCII digits, and [-]. *)
let foreign_tag text =
  if
    text <> ""
    && String.for_all
         (function
           | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' -> true | _ -> false)
         text
  then Some ("@" ^ text)
  else None

let block_pair value =
  match array value with
  | Some [ opening; closing ] ->
      let* opening = string opening in
      let* closing = string closing in
      Some (opening, closing)
  | _ -> None

(* @satisfies packs#read-descriptor=v1
   Each name of the array [names] must be a valid glob. *)
let glob text =
  Option.bind
    (Result.to_option (Text.decode text))
    (fun text -> Result.to_option (Glob.of_text text))

(* @satisfies packs#{read-descriptor=v1, give-descriptor-values=v1}
   A table of [grammar] holds exactly [name], [sha256], [license], and
   [names], of their forms, and gives them as the name, the hash, the license,
   and the globs, in order. *)
let grammar value =
  let* entries = table value in
  if not (only [ "name"; "sha256"; "license"; "names" ] entries) then None
  else
    let* name = required entries "name" in
    let* name = string name in
    let* grammar_name = Grammar_name.of_string name in
    let* hash = required entries "sha256" in
    let* hash = string hash in
    let* hash = Hash.validate hash in
    let* license = required entries "license" in
    let* license = string license in
    let* names = required entries "names" in
    let* names = strings names in
    let* globs = all glob names in
    Some { grammar_name; hash; license; globs }

(* @satisfies packs#read-descriptor=v1
   No two grammars of a descriptor have one name. *)
let distinct_names grammars =
  let names =
    List.sort String.compare
      (List.map (fun grammar -> (grammar.grammar_name :> string)) grammars)
  in
  let rec distinct = function
    | a :: (b :: _ as rest) -> if a = b then false else distinct rest
    | _ -> true
  in
  distinct names

(* @satisfies packs#{read-descriptor=v1, give-descriptor-values=v1}
   A default value is a TOML string, a TOML boolean, or a TOML array of TOML
   strings, and gives the type of its runner setting. *)
let setting (setting_name, value) =
  let* default =
    match value with
    | Toml.String text -> Some (String text)
    | Toml.Boolean flag -> Some (Boolean flag)
    | Toml.Array _ ->
        let* texts = strings value in
        Some (Strings texts)
    | _ -> None
  in
  Some { setting_name; default }

(* @satisfies packs#{read-descriptor=v1, give-descriptor-values=v1, omit-absent-adapter-values=v1, omit-absent-match-tables=v1}
   The table of a test runner holds exactly one of [adapter] and [match], and
   can hold [settings]; an adapter gives only its hash and its license, and
   only [match] gives a match table. *)
let runner (name, value) =
  let* runner_name = Pack_name.of_string name in
  let* entries = table value in
  if not (only [ "adapter"; "match"; "settings" ] entries) then None
  else
    let* source =
      match
        (List.assoc_opt "adapter" entries, List.assoc_opt "match" entries)
      with
      | Some adapter, None ->
          let* adapter = table adapter in
          if not (only [ "sha256"; "license" ] adapter) then None
          else
            let* hash = required adapter "sha256" in
            let* hash = string hash in
            let* hash = Hash.validate hash in
            let* license = required adapter "license" in
            let* license = string license in
            Some (Adapter { hash; license })
      | None, Some table_of_match ->
          let* table_of_match = table table_of_match in
          Some (Match table_of_match)
      | _ -> None
    in
    let* settings =
      optional entries "settings" ~absent:[] (fun value ->
          let* pairs = table value in
          all setting pairs)
    in
    Some { runner_name; source; settings }

let root_keys =
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

(* @satisfies packs#{read-descriptor=v1, give-descriptor-values=v1}
   The root table holds the required keys and no key that the descriptor does
   not define, each of its form, and gives the texts of its strings and the
   lists of its arrays in their order. *)
let descriptor root =
  if not (only root_keys root) then None
  else
    let* spec_version = required root "sinter-spec" in
    let* spec_version = string spec_version in
    let* spec_version = Spec_version.of_string spec_version in
    let* name = required root "name" in
    let* name = string name in
    let* name = Pack_name.of_string name in
    let* release = required root "version" in
    let* release = string release in
    let* release = Release_number.of_string release in
    let* license = required root "license" in
    let* license = string license in
    let* name_separator = required root "name-separator" in
    let* name_separator = string name_separator in
    let* name_separator = checked (fun text -> text <> "") name_separator in
    let* foreign_tag_words =
      optional root "foreign-tags" ~absent:[] (fun value ->
          let* texts = strings value in
          all foreign_tag texts)
    in
    let* comments = required root "comments" in
    let* comments = table comments in
    let* () =
      if only [ "line"; "block"; "inner" ] comments then Some () else None
    in
    let* line_sigils = optional comments "line" ~absent:[] strings in
    let* block_pairs =
      optional comments "block" ~absent:[] (fun value ->
          let* pairs = array value in
          all block_pair pairs)
    in
    let* inner_sigils = optional comments "inner" ~absent:[] strings in
    let* grammars = required root "grammar" in
    let* grammars = array grammars in
    let* grammars = all grammar grammars in
    let* grammars =
      checked
        (fun grammars -> grammars <> [] && distinct_names grammars)
        grammars
    in
    let* runners =
      optional root "runner" ~absent:[] (fun value ->
          let* pairs = table value in
          all runner pairs)
    in
    Some
      {
        spec_version;
        name;
        release;
        license;
        name_separator;
        foreign_tag_words;
        line_sigils;
        block_pairs;
        inner_sigils;
        grammars;
        runners;
      }

(* @satisfies packs#read-descriptor=v1
   A byte sequence that is not a TOML document is not a valid descriptor, and
   a TOML document is one only when its root table meets every rule. *)
let read bytes =
  match Toml.read bytes with
  | Toml.Valid document -> (
      match descriptor document.root_table with
      | Some descriptor -> Ok descriptor
      | None -> Error Breaks_a_rule)
  | Toml.Invalid | Toml.No_result -> Error Not_a_toml_document

let spec_version descriptor = descriptor.spec_version
let name descriptor = descriptor.name
let release descriptor = descriptor.release
let license (descriptor : t) = descriptor.license
let name_separator descriptor = descriptor.name_separator
let foreign_tag_words descriptor = descriptor.foreign_tag_words
let line_sigils descriptor = descriptor.line_sigils
let block_pairs descriptor = descriptor.block_pairs
let inner_sigils descriptor = descriptor.inner_sigils
let grammars descriptor = descriptor.grammars
let runners descriptor = descriptor.runners

(* @satisfies packs#{give-file-grammars=v1, omit-file-grammars=v1}
   The file grammar is the first grammar, in order, with a glob that the last
   file name fits as a valid path of one file name; with no such glob there is
   no grammar. *)
let file_grammar descriptor path =
  let last = List.nth_opt (List.rev (Path.file_names path)) 0 in
  Option.bind
    (Option.bind last (fun last -> Result.to_option (Path.of_text last)))
    (fun last ->
      List.find_opt
        (fun grammar ->
          List.exists (fun glob -> Glob.fits glob last) grammar.globs)
        descriptor.grammars)
