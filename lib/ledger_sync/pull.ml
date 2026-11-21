(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
open Sinter_ledger_lines
open Sinter_ledger_trees

type t =
  | Refused
  | Pulled of { added : Ledger_line.t list; left : string list }

let key text =
  Text.of_uchars
    (List.init (String.length text) (fun index -> Uchar.of_char text.[index]))

let seq_key = key "seq"
let id_key = key "id"

(* @satisfies ledger#pull-shared-entries=v1
   The line that comes from a line with the `seq` p keeps each member of its
   object other than `seq` and `id`, takes the `seq` p, and takes the entry id
   of that object as its `id`. *)
let comes_from line seq =
  let members =
    Member.without (Ledger_line.line_object line :> Json.t) [ "seq"; "id" ]
  in
  let ( let* ) = Option.bind in
  let* seq = Json.integer seq in
  let* without_id =
    Option.bind (Json.object_ ((seq_key, seq) :: members)) Json_line.of_json
  in
  let* id =
    Result.to_option
      (Text.decode (Entry_id.of_line_object without_id :> string))
  in
  let id = Json.string id in
  let* line_object =
    Option.bind
      (Json.object_ ((id_key, id) :: (seq_key, seq) :: members))
      Json_line.of_json
  in
  Ledger_line.of_line_object line_object

(* @satisfies ledger#{pull-shared-entries=v1, report-leaving-entries=v1}
   In increasing order of `seq`, each provisional line stays when the line that
   comes from it with the next `seq` after the lines of s and the lines that
   stayed has an entry that the acceptance rules accept at the end of that
   ledger, which no void is; every other provisional line leaves, and its `id`
   is given once. *)
let move acceptance ~shared_lines ~shared_entries provisional =
  let count = List.length shared_lines in
  let rec next ledger stayed added left = function
    | [] -> Pulled { added = List.rev added; left = List.rev left }
    | line :: lines -> (
        match
          Option.bind (comes_from line (count + stayed + 1)) Entry.of_line
        with
        | Some entry when Acceptance.accepted acceptance ledger entry ->
            next
              (Acceptance.append ledger entry)
              (stayed + 1)
              (Entry.line entry :: added)
              left lines
        | Some _ | None ->
            next ledger stayed added (Ledger_line.id line :: left) lines)
  in
  next (Acceptance.ledger shared_entries) 0 [] [] provisional

(* @satisfies ledger#refuse-unsafe-pulls=v1
   A pull goes ahead when A has no ledger commit, when s accounts for each line
   of a, or when the ledger of A is valid, s is a valid ledger tree, and each
   provisional line has one of the eight kinds; it is refused otherwise. *)
let pull acceptance ~clone ~shared =
  match clone with
  | None -> Pulled { added = []; left = [] }
  | Some clone -> (
      let accounting = Accounting.of_tree shared in
      let open_line line = not (Accounting.accounts accounting line) in
      if not (List.exists open_line (Ledger_tree.lines clone)) then
        Pulled { added = []; left = [] }
      else
        match (clone, shared) with
        | ( Valid_tree { lines; _ },
            Valid_tree { lines = shared_lines; entries = shared_entries } ) ->
            let provisional =
              List.filter (fun line -> open_line (Ledger_line.bytes line)) lines
            in
            if
              List.for_all
                (fun line ->
                  Option.is_some (Entry_kind.of_string (Ledger_line.kind line)))
                provisional
            then move acceptance ~shared_lines ~shared_entries provisional
            else Refused
        | (Newer_tree _ | Valid_tree _ | Other_tree _), _ -> Refused)
