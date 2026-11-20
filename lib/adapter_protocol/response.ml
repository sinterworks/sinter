(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Json = Sinter_json_lines.Json
module Ids = Set.Make (String)

module Pairs = Set.Make (struct
  type t = int * string

  let compare = compare
end)

module Status = struct
  type t = Pass | Fail | Error | Skip
end

type test_result = {
  name : Text.t;
  status : Status.t;
  file : Text.t option;
  line : int option;
  ms : int option;
}

type binding = { result : int; test : Text.t; reason : Text.t }

type bound = {
  results : test_result list;
  bindings : binding list;
  warnings : Text.t list;
}

type recognition =
  | Recognised
  | Not_recognised
  | Recognition_failed of Text.t option

type binding_result = Bound of bound | Bind_failed of Text.t option

let ( let* ) = Option.bind

let all f values =
  let rec go taken = function
    | [] -> Some (List.rev taken)
    | value :: rest -> (
        match f value with None -> None | Some y -> go (y :: taken) rest)
  in
  go [] values

let members = function
  | Json.Object members ->
      Some (List.map (fun (key, value) -> (Text.encode key, value)) members)
  | _ -> None

let only keys members = List.for_all (fun (key, _) -> List.mem key keys) members
let text = function Json.String text -> Some text | _ -> None

let optional members key f =
  match List.assoc_opt key members with
  | None -> Some None
  | Some value -> Option.map Option.some (f value)

let required members key f =
  let* value = List.assoc_opt key members in
  f value

(* @satisfies packs#omit-adapter-error-texts=v1
   A response gives an error text only when its JSON value is an object with
   exactly one member, [error], whose value is a string. *)
let error_text value =
  match members value with
  | Some [ ("error", Json.String text) ] -> Some text
  | _ -> None

(* @satisfies packs#give-call-results=v1
   A response of recognise gives "recognised" or "not recognised" only for an
   object with exactly the member [recognised] and a boolean value; each other
   response gives "failed". *)
let recognise response =
  match Json.read_json_text response with
  | None -> Recognition_failed None
  | Some value -> (
      match members value with
      | Some [ ("recognised", Json.Boolean true) ] -> Recognised
      | Some [ ("recognised", Json.Boolean false) ] -> Not_recognised
      | _ -> Recognition_failed (error_text value))

let status = function
  | "pass" -> Some Status.Pass
  | "fail" -> Some Status.Fail
  | "error" -> Some Status.Error
  | "skip" -> Some Status.Skip
  | _ -> None

let at_least least = function
  | Json.Integer number when number >= least -> Some number
  | _ -> None

(* @satisfies packs#{give-call-results=v1, give-call-values=v1}
   A result object has [name] and [status], can have [file], [line] of 1 or
   more, and [ms] of 0 or more, and no other member; it gives these values. *)
let test_result value =
  let* members = members value in
  if not (only [ "file"; "line"; "ms"; "name"; "status" ] members) then None
  else
    let* name = required members "name" text in
    let* status =
      required members "status" (fun value ->
          let* text = text value in
          status (Text.encode text))
    in
    let* file = optional members "file" text in
    let* line = optional members "line" (at_least 1) in
    let* ms = optional members "ms" (at_least 0) in
    Some { name; status; file; line; ms }

(* @satisfies packs#{give-call-results=v1, give-call-values=v1}
   A binding object has exactly [result], an index of a test result, [test], a
   test entry id of the call, and [reason], a string with no line feed; it
   gives these values. *)
let binding ~count ~ids value =
  let* members = members value in
  match members with
  | [
   ("reason", Json.String reason);
   ("result", Json.Integer result);
   ("test", Json.String test);
  ]
    when result >= 0 && result < count
         && Ids.mem (Text.encode test) ids
         && not (String.contains (Text.encode reason) '\n') ->
      Some { result; test; reason }
  | _ -> None

(* @satisfies packs#give-call-results=v1
   No two binding objects have the same test result and the same test entry
   id. *)
let distinct bindings =
  let rec go seen = function
    | [] -> true
    | binding :: rest ->
        let pair = (binding.result, Text.encode binding.test) in
        if Pairs.mem pair seen then false else go (Pairs.add pair seen) rest
  in
  go Pairs.empty bindings

(* @satisfies packs#{give-call-results=v1, give-call-values=v1}
   A response of bind gives "bound" only for an object with exactly
   [bindings], [results], and [warnings], each of its form, and then gives
   their values in their order; each other response gives "failed". *)
let bound ~ids value =
  match members value with
  | Some
      [
        ("bindings", Json.Array bindings);
        ("results", Json.Array results);
        ("warnings", Json.Array warnings);
      ] ->
      let* results = all test_result results in
      let count = List.length results in
      let* bindings = all (binding ~count ~ids) bindings in
      let* warnings = all text warnings in
      if distinct bindings then Some { results; bindings; warnings } else None
  | _ -> None

let bind ~ids response =
  let ids = Ids.of_list (List.map Text.encode ids) in
  match Json.read_json_text response with
  | None -> Bind_failed None
  | Some value -> (
      match bound ~ids value with
      | Some values -> Bound values
      | None -> Bind_failed (error_text value))
