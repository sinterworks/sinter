(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_lines

let ( let* ) = Result.bind

type t =
  | Newer_tree of { lines : string list }
  | Valid_tree of { lines : Ledger_line.t list; entries : Entry.t list }
  | Other_tree of { lines : string list }

let lines = function
  | Newer_tree { lines } | Other_tree { lines } -> lines
  | Valid_tree { lines; _ } -> List.map Ledger_line.bytes lines

module Stored_ledger = struct
  type t = Entry.t list

  let entries stored_ledger = stored_ledger
end

type validity = Valid of Stored_ledger.t | Broken | Newer

module Make (Id : Hashtbl.HashedType) = struct
  module Read = Tree_read.Make (Id)

  (* @satisfies ledger#validate-ledgers=v1
     A newer git tree object is newer whatever else it holds; otherwise it is a
     valid ledger tree when the seven conditions of the schema
     `valid-ledger-tree` hold, and neither when one fails. *)
  let of_analysis (analysis : Read.analysis) =
    if analysis.newer then Newer_tree { lines = analysis.lines }
    else
      match analysis.valid with
      | Some lines ->
          Valid_tree { lines; entries = List.filter_map Entry.of_line lines }
      | None -> Other_tree { lines = analysis.lines }

  let read ?entry_id objects tree =
    Result.map of_analysis (Read.analyse (Read.session ?entry_id objects) tree)

  (* @satisfies ledger#{validate-ledgers=v1, give-stored-ledgers=v1}
     An absent ledger ref gives a valid ledger with no entry; a ledger ref with
     no commit is broken; otherwise the git tree object of the ledger commit
     decides, and only a valid ledger tree gives its entries. *)
  let validity ?entry_id objects (ledger_ref : Id.t Ledger_objects.ledger_ref) =
    match ledger_ref with
    | Absent -> Ok (Valid [])
    | No_commit -> Ok Broken
    | Commit commit -> (
        let session = Read.session ?entry_id objects in
        let* commit = Read.commit session commit in
        let* analysis = Read.analyse session commit.tree in
        match of_analysis analysis with
        | Newer_tree _ -> Ok Newer
        | Valid_tree { entries; _ } -> Ok (Valid entries)
        | Other_tree _ -> Ok Broken)
end
