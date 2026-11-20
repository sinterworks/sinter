(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module V = Vector_json

let member name = function
  | `Assoc members -> List.assoc_opt name members
  | _ -> None

let required name json =
  match member name json with
  | Some value -> value
  | None -> invalid_arg ("Adapter_reference.request: no member " ^ name)

let sorted_strings = function
  | `List items ->
      `List
        (List.sort_uniq compare
           (List.map
              (function
                | `String text -> text
                | _ -> invalid_arg "Adapter_reference.request: a label")
              items)
        |> List.map (fun text -> `String text))
  | _ -> invalid_arg "Adapter_reference.request: labels"

let entry = function
  | `Assoc members ->
      `Assoc
        (List.map
           (fun (name, value) ->
             if name = "labels" then (name, sorted_strings value)
             else (name, value))
           members)
  | _ -> invalid_arg "Adapter_reference.request: a test entry"

let id_of json =
  match member "id" json with
  | Some (`String id) -> id
  | _ -> invalid_arg "Adapter_reference.request: an id"

let request input =
  let common =
    [
      ("interface", `Int 1);
      ("report", required "report" input);
      ("runner", required "runner" input);
      ("settings", required "settings" input);
    ]
  in
  let members =
    match required "function" input with
    | `String "recognise" -> common
    | `String "bind" ->
        let tests =
          match required "tests" input with
          | `List entries ->
              List.sort
                (fun a b -> String.compare (id_of a) (id_of b))
                (List.map entry entries)
          | _ -> invalid_arg "Adapter_reference.request: tests"
        in
        common @ [ ("root", required "root" input); ("tests", `List tests) ]
    | _ -> invalid_arg "Adapter_reference.request: function"
  in
  match V.canonical (V.of_basic (`Assoc members)) with
  | Some bytes -> bytes
  | None -> invalid_arg "Adapter_reference.request: not a JSON value"

type function_ = Recognise | Bind of string list

let text = function V.String (V.Text text) -> Some text | _ -> None
let integer = function V.Number number -> V.integer number | _ -> None

let exactly names members =
  List.length members = List.length names
  && List.for_all
       (fun (key, _) ->
         match key with
         | V.Text key -> List.mem key names
         | V.No_text _ -> false)
       members

let find name members =
  List.find_map
    (function V.Text key, value when key = name -> Some value | _ -> None)
    members

exception Failed

let get = function Some value -> value | None -> raise Failed
let check condition = if not condition then raise Failed

let result_object = function
  | V.Object members ->
      List.iter
        (fun (key, _) ->
          check
            (List.mem key
               [
                 V.Text "name";
                 V.Text "status";
                 V.Text "file";
                 V.Text "line";
                 V.Text "ms";
               ]))
        members;
      let name = get (text (get (find "name" members))) in
      let status = get (text (get (find "status" members))) in
      check (List.mem status [ "pass"; "fail"; "error"; "skip" ]);
      let optional key convert check_value =
        match find key members with
        | None -> []
        | Some value ->
            let value = get (convert value) in
            check (check_value value);
            [ (key, value) ]
      in
      let file =
        List.map
          (fun (key, value) -> (key, `String value))
          (optional "file" text (fun _ -> true))
      in
      let line =
        List.map
          (fun (key, value) -> (key, `Int value))
          (optional "line" integer (fun value -> value >= 1))
      in
      let ms =
        List.map
          (fun (key, value) -> (key, `Int value))
          (optional "ms" integer (fun value -> value >= 0))
      in
      `Assoc
        ([ ("name", `String name); ("status", `String status) ]
        @ file @ line @ ms)
  | _ -> raise Failed

let binding_object ~results ~ids = function
  | V.Object members ->
      check (exactly [ "result"; "test"; "reason" ] members);
      let result = get (integer (get (find "result" members))) in
      let test = get (text (get (find "test" members))) in
      let reason = get (text (get (find "reason" members))) in
      check (result >= 0 && result < results);
      check (List.mem test ids);
      check (not (String.contains reason '\n'));
      (result, test, reason)
  | _ -> raise Failed

let bound ids members =
  check (exactly [ "results"; "bindings"; "warnings" ] members);
  let results =
    match get (find "results" members) with
    | V.Array elements -> List.map result_object elements
    | _ -> raise Failed
  in
  let bindings =
    match get (find "bindings" members) with
    | V.Array elements ->
        List.map (binding_object ~results:(List.length results) ~ids) elements
    | _ -> raise Failed
  in
  let pairs = List.map (fun (result, test, _) -> (result, test)) bindings in
  check (List.length (List.sort_uniq compare pairs) = List.length pairs);
  let warnings =
    match get (find "warnings" members) with
    | V.Array elements -> List.map (fun element -> get (text element)) elements
    | _ -> raise Failed
  in
  `Assoc
    [
      ( "bindings",
        `List
          (List.map
             (fun (result, test, reason) ->
               `Assoc
                 [
                   ("reason", `String reason);
                   ("result", `Int result);
                   ("test", `String test);
                 ])
             bindings) );
      ("results", `List results);
      ("warnings", `List (List.map (fun warning -> `String warning) warnings));
    ]

let error_text = function
  | Some (V.Object [ (V.Text "error", V.String (V.Text text)) ]) -> Some text
  | _ -> None

let failed value =
  match error_text value with
  | Some text -> ("failed", `Assoc [ ("error", `String text) ])
  | None -> ("failed", `Assoc [])

let response function_ bytes =
  let value = V.json_value_of_bytes bytes in
  match (function_, value) with
  | Recognise, Some (V.Object [ (V.Text "recognised", V.Bool true) ]) ->
      ("recognised", `Assoc [])
  | Recognise, Some (V.Object [ (V.Text "recognised", V.Bool false) ]) ->
      ("not recognised", `Assoc [])
  | Recognise, _ -> failed value
  | Bind ids, Some (V.Object members) -> (
      match bound ids members with
      | values -> ("bound", values)
      | exception Failed -> failed value)
  | Bind _, _ -> failed value
