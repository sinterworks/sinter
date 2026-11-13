(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_line_maps

let key path = Text.encode (Path.to_text path)

let with_hunks found path old_content new_content =
  let map = Line_map.compute old_content new_content in
  if Line_map.hunks map = [] then found else (path, map) :: found

let rec join found olds news =
  match (olds, news) with
  | [], [] -> List.rev found
  | (path, content) :: olds, [] ->
      join (with_hunks found path (Some content) None) olds []
  | [], (path, content) :: news ->
      join (with_hunks found path None (Some content)) [] news
  | (old_path, old_content) :: older, (new_path, new_content) :: newer ->
      let order = String.compare (key old_path) (key new_path) in
      if order < 0 then
        join (with_hunks found old_path (Some old_content) None) older news
      else if order > 0 then
        join (with_hunks found new_path None (Some new_content)) olds newer
      else if String.equal old_content new_content then join found older newer
      else
        join
          (with_hunks found old_path (Some old_content) (Some new_content))
          older newer

(* @satisfies changes#give-change-diffs=v1
   With no base, the change has no diff. With a base, each valid path of
   either tree gives the hunks of one line map of it between the tree of the
   base and the tree of the last commit, and a valid path whose file is the
   same in both trees gives none. *)
let of_trees ~base last =
  Option.map (fun base -> join [] (Tree.files base) (Tree.files last)) base
