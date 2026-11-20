(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_tree
module Ids = Map.Make (String)

type t = { by_id : Finding_parts.t list Ids.t; order : Finding_parts.t list }
type error = Conflict of Finding_parts.t

let empty = { by_id = Ids.empty; order = [] }
let key id = Text.encode (Finding_id.to_text id)

let find set tree id =
  List.find_opt
    (fun finding -> Option.equal Tree.equal (Finding_parts.tree finding) tree)
    (Option.value ~default:[] (Ids.find_opt (key id) set.by_id))

(* @satisfies findings#give-consistent-findings=v1
   A new finding that is the same finding as one of the set, of one scope with
   it, joins only when each of its parts is the same. *)
let add finding set =
  let id = Finding_parts.id finding in
  match find set (Finding_parts.tree finding) id with
  | Some other ->
      if Finding_parts.equal other finding then Ok set
      else Error (Conflict other)
  | None ->
      Ok
        {
          by_id =
            Ids.update (key id)
              (fun same -> Some (finding :: Option.value ~default:[] same))
              set.by_id;
          order = finding :: set.order;
        }

let elements set = List.rev set.order
