(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let canonical_id kind_word name =
  match kind_word with
  | None -> name
  | Some word -> Kind_word.to_string word ^ ":" ^ name

let part = function None -> "" | Some part_name -> "#" ^ part_name

let selection = function
  | Target.Revision _ -> ""
  | Target.Vector_selection (Target.Group group) -> "[" ^ group ^ "]"
  | Target.Vector_selection Target.Every_vector -> "[*]"

let named ?slug ?kind_word name suffix =
  let name =
    match slug with
    | Some slug when String.starts_with ~prefix:"#" name -> slug ^ name
    | _ -> name
  in
  canonical_id kind_word name ^ suffix

(* @satisfies identifiers#give-canonical-entries=v1
   The canonical form of a content id is that content id. For every other
   target, the slug goes before an entry name that starts with `#`, the kind
   word that the caller gives replaces the kind word of the target, the
   revision is left out, and the vector selection ends the form. *)
let entry ?slug ?kind_word target =
  match target with
  | Target.Internal { slug = own; part_name; suffix; _ } ->
      named ?slug ?kind_word
        (Option.value own ~default:"" ^ part part_name)
        (selection suffix)
  | Target.External { namespace_name; id; part_name; _ } ->
      named ?slug ?kind_word (namespace_name ^ "/" ^ id ^ part part_name) ""
  | Target.Content_id content_id -> content_id
