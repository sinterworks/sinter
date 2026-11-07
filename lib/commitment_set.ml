(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(* @cites commitment-set-form *)

type step = { scope : string list; promises : (string * string) list }

let canonical_bytes value =
  match Json.to_string value with
  | Ok text -> text
  | Error _ ->
      invalid_arg
        "Sinter_core.Commitment_set.hash: a glob, a word, or a target is not \
         UTF-8"

let globs globs =
  Json.Array
    (List.map
       (fun glob -> Json.String glob)
       (List.sort_uniq String.compare globs))

module Groups = Map.Make (String)

let promise_objects promises =
  Json.Array
    (List.map
       (fun (word, target) ->
         Json.Object
           [ ("target", Json.String target); ("word", Json.String word) ])
       (List.sort
          (fun (w1, t1) (w2, t2) ->
            match String.compare w1 w2 with 0 -> String.compare t1 t2 | n -> n)
          promises))

let groups steps =
  let by_scope =
    List.fold_left
      (fun groups { scope; promises } ->
        match promises with
        | [] -> groups
        | _ :: _ ->
            let scope = globs scope in
            Groups.update (canonical_bytes scope)
              (fun found ->
                let earlier =
                  match found with Some (_, earlier) -> earlier | None -> []
                in
                Some (scope, List.rev_append promises earlier))
              groups)
      Groups.empty steps
  in
  Json.Array
    (List.map
       (fun (_, (scope, promises)) ->
         Json.Object
           [ ("promises", promise_objects promises); ("scope", scope) ])
       (Groups.bindings by_scope))

let bytes ~scope steps =
  canonical_bytes
    (Json.Object [ ("groups", groups steps); ("scope", globs scope) ])

let hash ~scope steps = Sha256.hex (bytes ~scope steps)
