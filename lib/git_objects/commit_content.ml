(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = { tree : Object_id.t; named : Object_id.t list }
type error = Malformed_tree_line | Malformed_parent_line of int

let starts_at content offset prefix =
  let rec same k =
    k = String.length prefix
    || (content.[offset + k] = prefix.[k] && same (k + 1))
  in
  offset + String.length prefix <= String.length content && same 0

let id_line format content offset prefix =
  let start = offset + String.length prefix in
  let stop = start + (2 * Object_id.length format) in
  if stop < String.length content && content.[stop] = '\n' then
    Option.map
      (fun id -> (id, stop + 1))
      (Object_id.of_hex format (String.sub content start (stop - start)))
  else None

(* @satisfies changes#give-commit-parents=v1
   Line 2 and each line after it name a parent for as long as each of them
   starts with "parent" and a space; the first line that does not ends the
   parent lines, and no later line names a parent. *)
let rec parent_lines format content offset line named =
  if starts_at content offset "parent " then
    match id_line format content offset "parent " with
    | None -> Error (Malformed_parent_line line)
    | Some (id, next) ->
        parent_lines format content next (line + 1) (id :: named)
  else Ok (List.rev named)

let parse format content =
  if not (starts_at content 0 "tree ") then Error Malformed_tree_line
  else
    match id_line format content 0 "tree " with
    | None -> Error Malformed_tree_line
    | Some (tree, next) ->
        Result.map
          (fun named -> { tree; named })
          (parent_lines format content next 2 [])
