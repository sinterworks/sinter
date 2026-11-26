(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines
open Sinter_ledger_lines
open Sinter_ledger_trees

let size_hint =
  (16 [@mutaml.skip "a size hint of a hash table changes no result"])

type t = {
  lines : (string, unit) Hashtbl.t;
  dropped : (string, unit) Hashtbl.t;
}

let is_void (value : Json.t) =
  match Member.find value "kind" with
  | Some (String kind) -> String.equal (Sinter_text.Text.encode kind) "void"
  | Some (Integer _ | Boolean _ | Array _ | Object _) | None -> false

let of_tree tree =
  let lines = Ledger_tree.lines tree in
  let accounting =
    { lines = Hashtbl.create size_hint; dropped = Hashtbl.create size_hint }
  in
  List.iter
    (fun line ->
      Hashtbl.replace accounting.lines line ();
      match Json_line.read line with
      | Some line_object -> (
          let value = (line_object :> Json.t) in
          match Member.find value "dropped" with
          | Some dropped when is_void value ->
              Hashtbl.replace accounting.dropped
                (Json.canonical_byte_sequence dropped)
                ()
          | Some _ | None -> ())
      | None -> ())
    lines;
  accounting

(* @satisfies ledger#{refuse-unsafe-pulls=v1, pull-shared-entries=v1}
   A line is accounted for when the git tree object holds the same bytes, or
   holds a line object of the kind `void` whose `dropped` is the value of `id`
   of the JSON value of the line, also when the line is not canonical. *)
let accounts accounting line =
  Hashtbl.mem accounting.lines line
  ||
  match
    Option.bind (Json.read_json_text line) (fun value -> Member.find value "id")
  with
  | Some id -> Hashtbl.mem accounting.dropped (Json.canonical_byte_sequence id)
  | None -> false
