(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_readings

type t = {
  file : Path.t;
  name : Reading.name_path;
  code : Text.run;
  comments : Text.run list;
}

module Runs = Map.Make (struct
  type t = int * int

  let compare = compare
end)

(* @satisfies documents#give-tests=v1
   The comments on a test are the runs of comments whose attachment target has
   the run of its test node. *)
let comments_by_target runs =
  let table =
    List.fold_left
      (fun table (run : Code_file.comment_run) ->
        match run.target with
        | Some (target : Reading.node) ->
            Runs.update
              (target.run.from, target.run.until)
              (fun runs -> Some (run.run :: Option.value ~default:[] runs))
              table
        | None -> table)
      Runs.empty (List.rev runs)
  in
  fun (code : Text.run) ->
    Option.value ~default:[] (Runs.find_opt (code.from, code.until) table)

(* @satisfies documents#give-tests=v1
   Each test node of a code file gives one test, with the file, its name path,
   and its run as its code; a markdown file gives none. *)
let of_file = function
  | Readable_file.Markdown_file _ -> []
  | Readable_file.Code_file file ->
      let comments_on = comments_by_target (Code_file.comment_runs file) in
      let tests =
        List.filter_map
          (fun (node : Reading.node) ->
            Option.map
              (fun name ->
                {
                  file = Code_file.path file;
                  name;
                  code = node.run;
                  comments = comments_on node.run;
                })
              node.test)
          (Reading.nodes (Code_file.reading file))
      in
      List.stable_sort
        (fun (a : t) (b : t) -> Int.compare a.code.from b.code.from)
        tests
