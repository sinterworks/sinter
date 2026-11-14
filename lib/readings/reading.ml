(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type piece = Text_piece of Text.t | Placeholder of Text.t
type own_name = piece list
type name_path = own_name list
type comment = Tagged | Untagged

type node = {
  run : Text.run;
  comment : comment option;
  body : Text.run list option;
  decoration : bool;
  test : name_path option;
}

type result = No_grammar | Parse_failure | Parsed of node list
type t = { lines : Lines.t; nodes : node list }

type error =
  | Not_a_run of { node : int }
  | Body_not_a_run of { node : int; body : int }
  | No_body_node of { node : int }
  | No_own_name of { node : int }

let in_body text (run : Text.run) =
  (Text.body text).from <= run.from
  && run.from <= run.until
  && run.until <= Text.length text

let rec first_outside text number = function
  | [] -> None
  | run :: rest ->
      if in_body text run then first_outside text (number + 1) rest
      else Some number

let node_error text number node =
  if not (in_body text node.run) then Some (Not_a_run { node = number })
  else
    let body_error =
      match node.body with
      | Some [] -> Some (No_body_node { node = number })
      | Some runs ->
          Option.map
            (fun body -> Body_not_a_run { node = number; body })
            (first_outside text 1 runs)
      | None -> None
    in
    match (body_error, node.test) with
    | Some error, _ -> Some error
    | None, Some [] -> Some (No_own_name { node = number })
    | None, _ -> None

let check lines nodes =
  let text = Lines.text lines in
  let rec scan number = function
    | [] -> Ok { lines; nodes }
    | node :: rest -> (
        match node_error text number node with
        | Some error -> Error error
        | None -> scan (number + 1) rest)
  in
  scan 1 nodes

let lines reading = reading.lines
let nodes reading = reading.nodes
