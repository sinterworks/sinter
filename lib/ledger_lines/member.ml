(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines
open Sinter_text

let members (value : Json.t) =
  match value with
  | Object members -> members
  | String _ | Integer _ | Boolean _ | Array _ -> []

let find value key =
  match Text.decode key with
  | Error _ -> None
  | Ok key ->
      List.find_map
        (fun (text, member) ->
          if Text.equal text key then Some member else None)
        (members value)

let without value keys =
  let keys =
    List.filter_map (fun key -> Result.to_option (Text.decode key)) keys
  in
  List.filter
    (fun (text, _) -> not (List.exists (Text.equal text) keys))
    (members value)
