(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines

type t = {
  bytes : string;
  line_object : Json_line.t;
  id : string;
  kind : string;
  seq : int;
}

let text (value : Json.t option) =
  match value with
  | Some (String text) -> Some (Sinter_text.Text.encode text)
  | Some (Integer _ | Boolean _ | Array _ | Object _) | None -> None

let integer (value : Json.t option) =
  match value with
  | Some (Integer number) -> Some number
  | Some (String _ | Boolean _ | Array _ | Object _) | None -> None

(* @satisfies ledger#validate-ledgers=v1
   Conditions 5 and 6 of a valid ledger tree: `id` and `kind` are strings, `v`
   is the integer 1, `seq` is an integer of 1 or more, and `id` is the entry id
   of the object. *)
let of_line_object (line_object : Json_line.t) =
  let value = (line_object :> Json.t) in
  match
    ( text (Member.find value "id"),
      text (Member.find value "kind"),
      integer (Member.find value "v"),
      integer (Member.find value "seq") )
  with
  | Some id, Some kind, Some 1, Some seq
    when seq >= 1
         && String.equal id (Entry_id.of_line_object line_object :> string) ->
      Some
        {
          bytes = Json_line.canonical_line line_object;
          line_object;
          id;
          kind;
          seq;
        }
  | _ -> None

let bytes line = line.bytes
let line_object line = line.line_object
let id line = line.id
let kind line = line.kind
let seq line = line.seq
