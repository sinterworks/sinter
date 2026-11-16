(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let canonical_id kind_word name =
  match kind_word with
  | None -> name
  | Some word -> Kind_word.to_string word ^ ":" ^ name

let part = function None -> "" | Some part_name -> "#" ^ part_name

let selection = function
  | None -> ""
  | Some (Target.Vector_number number) -> "[" ^ number ^ "]"
  | Some (Target.Group group) -> "[" ^ group ^ "][*]"
  | Some Target.Every_vector -> "[*]"

(* @satisfies identifiers#give-canonical-entries=v1
   The slug goes before an entry name that starts with `#`, the kind word
   that the caller gives replaces the kind word of the target, the revision
   is left out, and the vector selection or `#*` of an every-part target
   ends the form. *)
let entry ?slug ?kind_word target =
  let name, suffix =
    match target with
    | Target.Internal { slug; part_name; vector_selection; _ } ->
        ( Option.value slug ~default:"" ^ part part_name,
          selection vector_selection )
    | Target.Every_part { slug; _ } -> (slug, "#*")
    | Target.External { namespace_name; id; part_name; _ } ->
        (namespace_name ^ "/" ^ id ^ part part_name, "")
  in
  let name =
    match slug with
    | Some slug when String.starts_with ~prefix:"#" name -> slug ^ name
    | _ -> name
  in
  canonical_id kind_word name ^ suffix
