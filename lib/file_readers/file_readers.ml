(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_paths

type 'pack reader = Markdown | Pack of 'pack
type 'pack t = ('pack reader * Path_set.t) list

type error =
  | Invalid_glob of { pair : int; error : Path_set.glob_error }
  | Invalid_path_set of { pair : int; fault : Path_set.fault }

let make pairs =
  let rec check k acc = function
    | [] -> Ok (List.rev acc)
    | (reader, members) :: rest -> (
        match Path_set.of_texts members with
        | Error error -> Error (Invalid_glob { pair = k; error })
        | Ok set -> (
            match Path_set.validate set with
            | Error fault -> Error (Invalid_path_set { pair = k; fault })
            | Ok () -> check (k + 1) ((reader, set) :: acc) rest))
  in
  check 1 [] pairs

let pairs binding = binding

(* @satisfies documents#give-read-files=v1
   The reader of a valid path is the reader of the first pair, in the order of
   the binding, whose path set has the valid path in its set. *)
let reader binding path =
  let rec first k = function
    | [] -> None
    | (reader, set) :: rest ->
        if Path_set.mem set path then Some (k, reader) else first (k + 1) rest
  in
  first 1 binding
