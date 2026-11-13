(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_core

let rec value = function
  | `Null -> Json.Null
  | `Bool flag -> Json.Bool flag
  | `Int number -> Json.Int number
  | `String text -> Json.String text
  | `List items -> Json.Array (List.map value items)
  | `Assoc members ->
      Json.Object (List.map (fun (key, raw) -> (key, value raw)) members)
  | _ -> failwith "a line holds a number that is not an integer"

let line text =
  match value (Yojson.Safe.from_string text) with
  | Json.Object members -> (
      let members =
        List.filter (fun (key, _) -> not (String.equal key "id")) members
      in
      match Ledger.id_of (Json.Object members) with
      | Error _ -> failwith "a line does not print"
      | Ok id -> (
          match
            Json.to_string (Json.Object (("id", Json.String id) :: members))
          with
          | Ok printed -> printed
          | Error _ -> failwith "a line does not print"))
  | _ -> failwith "a line is not a JSON object"

let () =
  In_channel.fold_lines
    (fun () text -> print_endline (line text))
    () In_channel.stdin
