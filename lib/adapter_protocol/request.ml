(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Json = Sinter_json_lines.Json

type error = Repeated_id of Text.t

let text_of_ascii bytes =
  Text.of_uchars
    (List.init (String.length bytes) (fun i -> Uchar.of_char bytes.[i]))

let key bytes = text_of_ascii bytes

let common ~runner ~settings ~report =
  [
    (key "interface", Json_values.integer 1);
    ( key "runner",
      Json.string
        (text_of_ascii (runner : Sinter_pack_descriptor.Pack_name.t :> string))
    );
    (key "settings", Setting_values.to_json settings);
    (key "report", Json.string report);
  ]

(* @satisfies packs#give-requests=v1
   The request of recognise is the canonical byte sequence of the object of
   [interface] 1, the runner, its settings, and the report name, and of no
   other member. *)
let recognise ~runner ~settings ~report =
  Json.canonical_byte_sequence
    (Json_values.object_ (common ~runner ~settings ~report))

let piece = function
  | Test_entry.Text_piece text ->
      Json_values.object_ [ (key "text", Json.string text) ]
  | Test_entry.Placeholder text ->
      Json_values.object_ [ (key "placeholder", Json.string text) ]

(* @satisfies packs#give-requests=v1
   The object of a test entry holds its id, path, lines, kind as [suite], name
   path as arrays of piece objects, and test labels in code point order, and no
   other member. *)
let entry (entry : Test_entry.t) =
  Json_values.object_
    [
      (key "id", Json.string entry.id);
      (key "path", Json.string (Sinter_paths.Path.to_text entry.path));
      (key "line", Json_values.integer entry.line);
      (key "eline", Json_values.integer entry.eline);
      ( key "suite",
        Json.boolean
          (match entry.kind with
          | Test_entry.Test_suite -> true
          | Test_entry.Test_case -> false) );
      ( key "names",
        Json.array
          (List.map (fun name -> Json.array (List.map piece name)) entry.names)
      );
      (key "labels", Json.array (List.map Json.string entry.labels));
    ]

let code_point_order (a : Test_entry.t) (b : Test_entry.t) =
  String.compare (Text.encode a.id) (Text.encode b.id)

let rec repeated = function
  | (a : Test_entry.t) :: ((b : Test_entry.t) :: _ as rest) ->
      if Text.equal a.id b.id then Some a.id else repeated rest
  | _ -> None

(* @satisfies packs#give-requests=v1
   The request of bind adds the root and the test entries, in the code point
   order of their ids, which must each be a different text. *)
let bind ~runner ~settings ~report ~root entries =
  let entries = List.stable_sort code_point_order entries in
  match repeated entries with
  | Some id -> Error (Repeated_id id)
  | None ->
      Ok
        (Json.canonical_byte_sequence
           (Json_values.object_
              (common ~runner ~settings ~report
              @ [
                  (key "root", Json.string root);
                  (key "tests", Json.array (List.map entry entries));
                ])))
