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
let star = Uchar.of_char '*'
let bang = Uchar.of_char '!'

let is_glob_char c =
  not
    (List.mem (Uchar.to_int c)
       [ 0x2A; 0x2F; 0x3F; 0x5B; 0x5C; 0x5D; 0x7B; 0x7D ])

let rec stars_apart = function
  | a :: (b :: _ as rest) ->
      (not (Uchar.equal a star && Uchar.equal b star)) && stars_apart rest
  | _ -> true

let is_glob_segment segment =
  let is_star c = Uchar.equal c star in
  match segment with
  | [ a; b ] when is_star a && is_star b -> true
  | _ ->
      segment <> []
      && List.for_all (fun c -> is_star c || is_glob_char c) segment
      && stars_apart segment
      && (List.exists is_star segment || not (is_dots segment))

let pieces_of_glob text =
  match List.rev (split text) with
  | [] :: (_ :: _ as rest) -> (List.rev rest, true)
  | pieces -> (List.rev pieces, false)

let is_glob text =
  let pieces, _ = pieces_of_glob text in
  List.for_all is_glob_segment pieces

let double_star = [ star; star ]

let glob_segments text =
  let pieces, trailing = pieces_of_glob text in
  if trailing then pieces @ [ double_star ] else pieces

let rec name_fits name segment =
  match (segment, name) with
  | [], [] -> true
  | [], _ :: _ -> false
  | s :: segment_rest, _ when Uchar.equal s star -> (
      name_fits name segment_rest
      ||
      match name with
      | [] -> false
      | _ :: name_rest -> name_fits name_rest segment)
  | s :: segment_rest, c :: name_rest ->
      Uchar.equal s c && name_fits name_rest segment_rest
  | _ :: _, [] -> false

let rec take_groups names = function
  | [] -> names = []
  | [ segment ] when segment = double_star -> names <> []
  | segment :: rest when segment = double_star ->
      let rec any names =
        take_groups names rest
        || match names with [] -> false | _ :: names -> any names
      in
      any names
  | segment :: rest -> (
      match names with
      | name :: names -> name_fits name segment && take_groups names rest
      | [] -> false)

let fits ~path ~glob = take_groups (file_names path) (glob_segments glob)

let glob_text = function
  | c :: rest when Uchar.equal c bang -> rest
  | member -> member

let is_plain = function c :: _ when Uchar.equal c bang -> false | _ -> true

let is_valid_path_set members =
  List.for_all (fun member -> is_glob (glob_text member)) members
  && List.length (List.sort_uniq compare members) = List.length members
  && (members = [] || List.exists is_plain members)

let in_set ~path members =
  List.exists (fun m -> is_plain m && fits ~path ~glob:(glob_text m)) members
  && not
       (List.exists
          (fun m -> (not (is_plain m)) && fits ~path ~glob:(glob_text m))
          members)
