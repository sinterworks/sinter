(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type kind = Test_case | Test_suite
type piece = Text_piece of Text.t | Placeholder of Text.t

type t = {
  id : Text.t;
  path : Sinter_paths.Path.t;
  line : int;
  eline : int;
  kind : kind;
  names : piece list list;
  labels : Text.t list;
}

type error = Line_out_of_range of int

let in_range number =
  number >= 0 && number <= Sinter_json_lines.Json.max_integer

let code_point_order a b = String.compare (Text.encode a) (Text.encode b)

let make ~id ~path ~line ~eline ~kind ~names ~labels =
  if not (in_range line) then Error (Line_out_of_range line)
  else if not (in_range eline) then Error (Line_out_of_range eline)
  else
    Ok
      {
        id;
        path;
        line;
        eline;
        kind;
        names;
        labels = List.sort_uniq code_point_order labels;
      }
