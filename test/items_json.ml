(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree_inputs
open Sinter_tree_items

let position { Lines.line; column } =
  `Assoc [ ("column", `Int column); ("line", `Int line) ]

let run { Text.from; until } =
  `Assoc [ ("from", `Int from); ("to", `Int until) ]

let optional name = function Some value -> [ (name, value) ] | None -> []

let element ~kind ~name ~file ~at ~extent ~design ~specification ~vector_file =
  `Assoc
    ([
       ("kind", `String kind);
       ("name", `String name);
       ("file", `String file);
       ("at", position at);
       ("extent", `List (List.map run extent));
     ]
    @ optional "design" (Option.map (fun k -> `Int k) design)
    @ optional "specification" (Option.map (fun k -> `Int k) specification)
    @ optional "vector-file" (Option.map (fun p -> `String p) vector_file))

let kind_text = function
  | Declared_items.Design -> "design"
  | Specification -> "specification"
  | Requirement -> "requirement"
  | Term -> "term"
  | Decision_record -> "decision record"
  | Declared_finding_class -> "declared finding class"

let path_text path = Text.encode (Path.to_text path)

let of_declared declared =
  `List
    (List.map
       (fun item ->
         element
           ~kind:(kind_text (Declared_items.kind item))
           ~name:(Declared_items.name item)
           ~file:(path_text (Tree_file.path (Declared_items.file item)))
           ~at:(Declared_items.at item)
           ~extent:(Declared_items.extent item)
           ~design:
             (Option.map Declared_items.number (Declared_items.design item))
           ~specification:
             (Option.map Declared_items.number
                (Declared_items.specification item))
           ~vector_file:(Option.map path_text (Declared_items.vector_file item)))
       (Declared_items.items declared))

let of_reference items =
  `List
    (List.map
       (fun (item : Items_reference.item) ->
         element
           ~kind:(Items_reference.kind_text item.kind)
           ~name:item.name ~file:item.file ~at:item.at ~extent:item.extent
           ~design:item.design ~specification:item.specification
           ~vector_file:item.vector_file)
       items)
