(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths

type kind =
  | Tree_entry
  | Regular_file_entry
  | Symbolic_link_entry
  | Submodule_entry

let octal mode =
  String.for_all (function '0' .. '7' -> true | _ -> false) mode

let writes quotient value =
  String.ends_with ~suffix:value quotient
  && String.for_all (Char.equal '0')
       (String.sub quotient 0 (String.length quotient - String.length value))

(* @satisfies changes#give-commit-files=v1
   A mode of one or more of the bytes 0x30 to 0x37 writes a whole number in
   base 8, and its quotient by 4096, which is 8 to the power 4, is written by
   the bytes before the last four; the value that they write, whatever their
   leading zeros, gives the type of the entry. Every other mode gives a
   submodule entry. *)
let kind mode =
  let quotient = String.sub mode 0 (Int.max 0 (String.length mode - 4)) in
  if not (octal mode) then Submodule_entry
  else if writes quotient "4" then Tree_entry
  else if writes quotient "10" then Regular_file_entry
  else if writes quotient "12" then Symbolic_link_entry
  else Submodule_entry

type 'blob entry =
  | Tree of { name : string; entries : 'blob entry list }
  | Regular_file of { name : string; blob : 'blob }
  | Other of { name : string }

let name_of = function
  | Tree { name; _ } | Regular_file { name; _ } | Other { name } -> name

module Parts = Map.Make (String)

type node = {
  part : string;
  above : node option;
  mutable below : node Parts.t;
  named : bool;
  mutable entries : int;
}

let file_name part =
  match Text.decode part with
  | Error _ -> false
  | Ok text -> Result.is_ok (Path.of_text text)

let node part above named =
  { part; above; below = Parts.empty; named; entries = 0 }

let child parent part =
  match Parts.find_opt part parent.below with
  | Some found -> found
  | None ->
      let made = node part (Some parent) (parent.named && file_name part) in
      parent.below <- Parts.add part made parent.below;
      made

let rec byte_path node parts =
  match node.above with
  | None -> String.concat "/" parts
  | Some above -> byte_path above (node.part :: parts)

let valid_path bytes =
  match Text.decode bytes with
  | Error _ -> None
  | Ok text -> Result.to_option (Path.of_text text)

(* @satisfies changes#give-commit-files=v1
   Each entry has the byte path of the entries on the way to it, joined by
   the byte `/`, and one node stands for each byte path, as the sequence of
   its parts between the bytes `/`. A node is named when each of its parts is
   the UTF-8 encoding of a file name, which makes its byte path the UTF-8
   encoding of a valid path; a regular-file entry gives a file only when its
   node is named and no other entry has that node. *)
let files entries =
  let root = node "" None true in
  let regular = ref [] in
  let pending = Stack.create () in
  Stack.push (root, entries) pending;
  while not (Stack.is_empty pending) do
    let parent, listed = Stack.pop pending in
    List.iter
      (fun entry ->
        let place =
          List.fold_left child parent (String.split_on_char '/' (name_of entry))
        in
        place.entries <- place.entries + 1;
        match entry with
        | Tree { entries; _ } -> Stack.push (place, entries) pending
        | Regular_file { blob; _ } -> regular := (place, blob) :: !regular
        | Other _ -> ())
      listed
  done;
  List.filter_map
    (fun (place, blob) ->
      if place.entries = 1 && place.named then
        Option.map
          (fun valid -> (valid, blob))
          (valid_path (byte_path place []))
      else None)
    !regular

let after ~prefix bytes =
  if String.starts_with ~prefix bytes then
    Some
      (String.sub bytes (String.length prefix)
         (String.length bytes - String.length prefix))
  else None

(* @satisfies changes#give-commit-file-at-path=v1
   The entries whose byte path is the UTF-8 encoding of the valid path are
   found through the tree entries whose byte path, with the byte `/` after
   it, starts that encoding. The tree has a file with the valid path only
   when exactly one entry has that byte path and it is a regular-file entry,
   and the file then has the blob of that entry. *)
let file entries path =
  let found = ref [] in
  let pending = Stack.create () in
  Stack.push (entries, Text.encode (Path.to_text path)) pending;
  while not (Stack.is_empty pending) do
    let listed, rest = Stack.pop pending in
    List.iter
      (fun entry ->
        if String.equal (name_of entry) rest then found := entry :: !found
        else
          match entry with
          | Tree { name; entries } ->
              Option.iter
                (fun rest -> Stack.push (entries, rest) pending)
                (after ~prefix:(name ^ "/") rest)
          | Regular_file _ | Other _ -> ())
      listed
  done;
  match !found with [ Regular_file { blob; _ } ] -> Some blob | _ -> None
