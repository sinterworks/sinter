(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Commit_files = Sinter_git_model.Commit_files

type entry = { mode : string; name : string; id : Object_id.t }
type error = Malformed_entry of int

(* @satisfies changes#{give-commit-files=v1, give-commit-file-at-path=v1}
   An entry is its mode up to the first byte 0x20, its name up to the next
   byte 0x00, and the bytes of the object id; each entry is kept as the
   content lists it, with its bytes, its place, and its repeats. *)
let parse format content =
  let total = String.length content in
  let width = Object_id.length format in
  let rec entries offset found =
    if offset = total then Ok (List.rev found)
    else
      match String.index_from_opt content offset ' ' with
      | None -> Error (Malformed_entry offset)
      | Some space -> (
          match String.index_from_opt content space '\000' with
          | None -> Error (Malformed_entry offset)
          | Some zero -> (
              let id =
                if zero + 1 + width <= total then
                  Object_id.of_bytes format
                    (String.sub content (zero + 1) width)
                else None
              in
              match id with
              | None -> Error (Malformed_entry offset)
              | Some id ->
                  let mode = String.sub content offset (space - offset) in
                  let name =
                    String.sub content (space + 1) (zero - space - 1)
                  in
                  entries (zero + 1 + width) ({ mode; name; id } :: found)))
  in
  entries 0 []

type 'e build_error =
  | Unread of 'e
  | Malformed of { tree : Object_id.t; error : error }
  | Cycle of Object_id.t
  | Too_many_entries

module Keys = Map.Make (struct
  type t = Object_id.t * int

  let compare (id, offset) (id', offset') =
    match Object_id.compare id id' with
    | 0 -> Int.compare offset offset'
    | order -> order
end)

type choice = Skip | Keep | Keep_empty | Descend of int

type frame = {
  key : Object_id.t * int;
  label : string;
  mutable rest : entry list;
  mutable built : Object_id.t Commit_files.entry list;
  mutable count : int;
}

let entries ?path ~max_entries ~read format tree =
  if max_entries < 0 then
    invalid_arg "Tree_content.entries: a negative maximum number of entries";
  let target =
    Option.map
      (fun path -> Sinter_text.Text.encode (Sinter_paths.Path.to_text path))
      path
  in
  let rec same target offset name k =
    k = String.length name
    || (name.[k] = target.[offset + k] && same target offset name (k + 1))
  in
  (* @satisfies changes#give-commit-file-at-path=v1
     For the file at p, only the entries whose byte path is the encoding of p
     and the tree entries whose byte path and a "/" start it can give an entry
     with the byte path of p, so the others are left out and no other tree is
     read. *)
  let choose offset (raw : entry) =
    let kind = Commit_files.kind raw.mode in
    match target with
    | None -> (
        match kind with Commit_files.Tree_entry -> Descend offset | _ -> Keep)
    | Some target ->
        let stop = offset + String.length raw.name in
        if stop > String.length target || not (same target offset raw.name 0)
        then Skip
        else if stop = String.length target then
          match kind with Commit_files.Tree_entry -> Keep_empty | _ -> Keep
        else if kind = Commit_files.Tree_entry && target.[stop] = '/' then
          Descend (stop + 1)
        else Skip
  in
  let done_ = ref Keys.empty in
  let started = ref Keys.empty in
  let start id label offset =
    match read id with
    | Error e -> Error (Unread e)
    | Ok content -> (
        match parse format content with
        | Error error -> Error (Malformed { tree = id; error })
        | Ok rest ->
            let key = (id, offset) in
            started := Keys.add key () !started;
            Ok { key; label; rest; built = []; count = 0 })
  in
  let leaf (raw : entry) =
    match Commit_files.kind raw.mode with
    | Commit_files.Regular_file_entry ->
        Commit_files.Regular_file { name = raw.name; blob = raw.id }
    | _ -> Commit_files.Other { name = raw.name }
  in
  let add frame entry size =
    frame.built <- entry :: frame.built;
    frame.count <- frame.count + size;
    frame.count <= max_entries
  in
  let rec run frame stack =
    match frame.rest with
    | [] -> (
        let finished = List.rev frame.built in
        done_ := Keys.add frame.key (finished, frame.count) !done_;
        match stack with
        | [] -> Ok finished
        | parent :: stack ->
            next parent stack
              (Commit_files.Tree { name = frame.label; entries = finished })
              (1 + frame.count))
    | raw :: rest -> (
        frame.rest <- rest;
        match choose (snd frame.key) raw with
        | Skip -> run frame stack
        | Keep -> next frame stack (leaf raw) 1
        | Keep_empty ->
            next frame stack
              (Commit_files.Tree { name = raw.name; entries = [] })
              1
        | Descend offset -> (
            let key = (raw.id, offset) in
            match Keys.find_opt key !done_ with
            | Some (entries, count) ->
                next frame stack
                  (Commit_files.Tree { name = raw.name; entries })
                  (1 + count)
            | None -> (
                if Keys.mem key !started then Error (Cycle raw.id)
                else
                  match start raw.id raw.name offset with
                  | Error e -> Error e
                  | Ok child -> run child (frame :: stack))))
  and next frame stack entry size =
    if add frame entry size then run frame stack else Error Too_many_entries
  in
  match start tree "" 0 with Error e -> Error e | Ok root -> run root []
