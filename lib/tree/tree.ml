(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
module Names = Map.Make (String)

type file = {
  path : Path.t;
  content : string;
  lines : (Lines.t, Text.decode_error) result option Atomic.t;
}

type t = file Names.t
type error = Repeated_path of Path.t
type text_error = No_file | Not_utf_8 of Text.decode_error

let empty = Names.empty
let name path = Text.encode (Path.to_text path)

let of_files files =
  let rec add tree = function
    | [] -> Ok tree
    | (path, content) :: rest ->
        let key = name path in
        if Names.mem key tree then Error (Repeated_path path)
        else
          add
            (Names.add key { path; content; lines = Atomic.make None } tree)
            rest
  in
  add Names.empty files

let files tree =
  List.map (fun (_, file) -> (file.path, file.content)) (Names.bindings tree)

let content tree path =
  Option.map (fun file -> file.content) (Names.find_opt (name path) tree)

let decoded file =
  (match Atomic.get file.lines with
  | Some lines -> lines
  | None ->
      let lines = Result.map Lines.of_text (Text.decode file.content) in
      Atomic.set file.lines (Some lines);
      lines)
  [@mutaml.skip
    "The stored lines are the lines that the other case makes from the same \
     content, so a case that never fires, or a store that never happens, gives \
     the same lines; only the time differs."]

let lines tree path =
  match Names.find_opt (name path) tree with
  | None -> Error No_file
  | Some file -> Result.map_error (fun e -> Not_utf_8 e) (decoded file)

let text tree path = Result.map Lines.text (lines tree path)

let equal a b =
  a == b || Names.equal (fun x y -> String.equal x.content y.content) a b
