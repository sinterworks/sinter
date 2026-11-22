(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree

type 'pack t = {
  path : Path.t;
  pair : int;
  reader : 'pack File_readers.reader;
  lines : (Lines.t, Text.decode_error) result;
}

(* @satisfies documents#give-read-files=v1
   A file with a reader is a read file only when its valid path has no line
   feed, and no space and no tab as its first or its last character. *)
let readable_path path =
  let bytes = Text.encode (Path.to_text path) in
  let at_an_end blank =
    String.starts_with ~prefix:blank bytes
    || String.ends_with ~suffix:blank bytes
  in
  not (String.contains bytes '\n' || at_an_end " " || at_an_end "\t")

(* @satisfies documents#give-read-files=v1
   Each file of the tree is looked at once, so each read file comes once, and
   a file is kept only when its valid path has a reader and meets the rule of
   readable_path, so no other file comes. *)
let read_files readers tree =
  List.filter_map
    (fun (path, content) ->
      match File_readers.reader readers path with
      | Some (pair, reader) when readable_path path ->
          let lines = Result.map Lines.of_text (Text.decode content) in
          Some { path; pair; reader; lines }
      | _ -> None)
    (Tree.files tree)

let path file = file.path
let pair file = file.pair
let reader file = file.reader
let lines file = file.lines
