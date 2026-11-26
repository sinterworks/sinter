(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Object_id = Sinter_git_objects.Object_id
module Ref_name = Sinter_ref_names.Ref_name
module Names = Map.Make (String)

type t = Object_id.t Names.t
type error = No_final_line_feed | Repeated_name of string

let ref_of_line format line =
  let width = 2 * Object_id.length format in
  if String.index_opt line ' ' = Some width then
    let name = String.sub line (width + 1) (String.length line - width - 1) in
    match Object_id.of_hex format (String.sub line 0 width) with
    | Some id when Ref_name.is_ref_name name -> Some (name, id)
    | _ -> None
  else None

(* @satisfies changes#give-ref-commits=v1
   Each line that is an object id in hex digits, a space, and a ref name gives
   the ref with that name, which points to that git object; no other line,
   such as a header line or a line of a peeled object, gives a ref. *)
let parse format content =
  if content <> "" && content.[String.length content - 1] <> '\n' then
    Error No_final_line_feed
  else
    let lines = String.split_on_char '\n' content in
    List.fold_left
      (fun refs line ->
        match (refs, ref_of_line format line) with
        | Error e, _ -> Error e
        | Ok refs, None -> Ok refs
        | Ok refs, Some (name, id) ->
            if Names.mem name refs then Error (Repeated_name name)
            else Ok (Names.add name id refs))
      (Ok Names.empty) lines

let find refs name = Names.find_opt name refs
