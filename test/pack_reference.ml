(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let is_file_name name =
  String.is_valid_utf_8 name
  && (not (List.mem name [ ""; "."; ".." ]))
  && not (String.exists (fun c -> c = '\x00' || c = '/') name)

let files tree =
  let rec walk prefix (file : Files_tree.file) =
    match file.kind with
    | Folder entries ->
        List.concat_map
          (fun (name, (child : Files_tree.file)) ->
            if not (is_file_name name) then []
            else
              let path = if prefix = "" then name else prefix ^ "/" ^ name in
              match child.kind with
              | Regular pieces -> [ (path, Files_tree.bytes_of_pieces pieces) ]
              | Folder _ -> walk path child
              | Link _ | Pipe -> [])
          entries
    | Regular _ | Link _ | Pipe -> []
  in
  List.sort (fun (a, _) (b, _) -> String.compare a b) (walk "" tree)

let leading_runs path =
  let rec go index acc =
    match String.index_from_opt path index '/' with
    | None -> path :: acc
    | Some slash -> go (slash + 1) (String.sub path 0 slash :: acc)
  in
  go 0 []

let paths tree =
  List.sort_uniq String.compare
    (List.concat_map (fun (path, _) -> leading_runs path) (files tree))

let is_pack_path_char c = c >= '\x20' && c <= '\x7e' && c <> '/' && c <> '\\'

let is_pack_path_name name =
  name <> "" && name <> "." && name <> ".."
  && String.for_all (fun c -> c = '.' || is_pack_path_char c) name

let is_pack_path text =
  String.length text <= 255
  && List.for_all is_pack_path_name (String.split_on_char '/' text)

let rec has_regular_file (file : Files_tree.file) =
  match file.kind with
  | Regular _ -> true
  | Folder entries ->
      List.exists (fun (_, child) -> has_regular_file child) entries
  | Link _ | Pipe -> false

let rec entry_names_are_file_names (file : Files_tree.file) =
  match file.kind with
  | Folder entries ->
      List.for_all
        (fun (name, child) ->
          ((not (has_regular_file child)) || is_file_name name)
          && entry_names_are_file_names child)
        entries
  | Regular _ | Link _ | Pipe -> true

let well_named tree =
  let paths = paths tree in
  let folded =
    List.sort_uniq String.compare (List.map String.lowercase_ascii paths)
  in
  entry_names_are_file_names tree
  && List.for_all is_pack_path paths
  && List.length folded = List.length paths

let sha256 bytes = Digestif.SHA256.to_hex (Digestif.SHA256.digest_string bytes)

let listing tree =
  if well_named tree then
    Some
      (String.concat ""
         (List.map
            (fun (path, content) -> sha256 content ^ "  " ^ path ^ "\n")
            (files tree)))
  else None

let hash tree = Option.map sha256 (listing tree)
