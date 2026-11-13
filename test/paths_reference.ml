(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let slash = Uchar.of_char '/'
let dot = Uchar.of_char '.'

let split text =
  let rec go current acc = function
    | [] -> List.rev (List.rev current :: acc)
    | c :: rest when Uchar.equal c slash -> go [] (List.rev current :: acc) rest
    | c :: rest -> go (c :: current) acc rest
  in
  go [] [] text

let all_dots name = List.for_all (Uchar.equal dot) name
let is_dots name = name <> [] && all_dots name && List.length name <= 2

let is_file_name name =
  name <> []
  && (not (is_dots name))
  && List.for_all (fun c -> Uchar.to_int c <> 0) name

let is_path text = List.for_all is_file_name (split text)
let file_names = split
