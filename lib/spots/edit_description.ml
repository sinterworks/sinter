(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths

type t = {
  path : Text.t;
  start : Lines.position;
  after : Lines.position;
  new_text : Text.t;
}

type fault = Not_a_path of Path.error | No_spot of Spot.error

type error =
  | Not_an_edit of { number : int; fault : fault }
  | Not_an_edit_set of Edit_set.error

let edit tree description =
  match Path.of_text description.path with
  (* @satisfies findings#validate-edit-sets=v1
     A path that is no valid path is the valid path of no file, so its edit
     description describes no edit. *)
  | Error error -> Error (Not_a_path error)
  | Ok path -> (
      match Spot.of_positions tree path description.start description.after with
      | Error error -> Error (No_spot error)
      | Ok spot ->
          Result.map_error
            (fun _ -> No_spot Not_a_span)
            (Edit.make spot description.new_text))

let edit_set tree descriptions =
  let rec edits number = function
    | [] -> Ok []
    | description :: rest -> (
        match edit tree description with
        | Error fault -> Error (Not_an_edit { number; fault })
        | Ok edit ->
            Result.map (fun others -> edit :: others) (edits (number + 1) rest))
  in
  Result.bind (edits 1 descriptions) (fun edits ->
      Result.map_error
        (fun error -> Not_an_edit_set error)
        (Edit_set.of_edits edits))
