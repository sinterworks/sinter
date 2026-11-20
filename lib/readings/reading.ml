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
  | Not_nested of { node : int }
  | Body_not_nested of { node : int; body : int }
  | No_body_node of { node : int }
  | No_own_name of { node : int }

let in_body text (run : Text.run) =
  (Text.body text).from <= run.from
  && run.from <= run.until
  && run.until <= Text.length text

let rec close (run : Text.run) = function
  | (top : Text.run) :: rest when top.until <= run.from -> close run rest
  | stack -> stack

(* @satisfies packs#node-run=v1
   Of two nodes of a parse tree, the run of the later lies inside the run of
   the earlier, or starts at or after its end. The open runs form a stack, each
   inside the one below it, so a run nests with every run before it when, and
   only when, it lies inside the top that is left after the runs that end at or
   before its start close. *)
let nested stack (run : Text.run) =
  match close run stack with
  | (top : Text.run) :: _
    when not (top.from <= run.from && run.until <= top.until) ->
      None
  | stack -> Some (run :: stack)

let rec body_error text node stack body = function
  | [] -> None
  | run :: rest -> (
      if not (in_body text run) then Some (Body_not_a_run { node; body })
      else
        match nested stack run with
        | None -> Some (Body_not_nested { node; body })
        | Some stack -> body_error text node stack (body + 1) rest)

let node_error text number node =
  let body_error =
    match node.body with
    | Some [] -> Some (No_body_node { node = number })
    | Some runs -> body_error text number [] 1 runs
    | None -> None
  in
  match (body_error, node.test) with
  | Some error, _ -> Some error
  | None, Some [] -> Some (No_own_name { node = number })
  | None, _ -> None

(* @satisfies packs#parse-tree=v1
   A list of nodes whose runs break the order of the term node-run is no parse
   tree, so the check refuses it and gives no reading. *)
let check lines nodes =
  let text = Lines.text lines in
  let rec scan number stack = function
    | [] -> Ok { lines; nodes }
    | node :: rest -> (
        if not (in_body text node.run) then Error (Not_a_run { node = number })
        else
          match nested stack node.run with
          | None -> Error (Not_nested { node = number })
          | Some stack -> (
              match node_error text number node with
              | Some error -> Error error
              | None -> scan (number + 1) stack rest))
  in
  scan 1 [] nodes

let lines reading = reading.lines
let nodes reading = reading.nodes
