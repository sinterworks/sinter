(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Object_id = Sinter_git_objects.Object_id
module Ref_commit = Sinter_git_model.Ref_commit
module Ref_name = Sinter_ref_names.Ref_name
module Files = Sinter_repository_files
module Config = Sinter_git_config

type storage = Files | Reftable

type storage_error =
  | Not_version_1
  | Unknown_format of string option
  | Payload of string

let last settings key =
  List.fold_left
    (fun found (k, value) ->
      if Config.equal_key k key then Some value else found)
    None settings

(* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
   The ref storage format is the one that the last value of the setting
   extensions.refStorage of the file config names, files when no value is
   set; a format holds only with the repository format version 1, and no
   payload is read. *)
let storage settings =
  match last settings (Config.key ~section:"extensions" "refStorage") with
  | None -> Ok Files
  | Some value -> (
      match
        last settings (Config.key ~section:"core" "repositoryformatversion")
      with
      | Some (Some "1") -> (
          let payload format =
            Option.bind value (fun text ->
                let prefix = format ^ "://" in
                if String.starts_with ~prefix text then
                  Some
                    (String.sub text (String.length prefix)
                       (String.length text - String.length prefix))
                else None)
          in
          match (value, payload "files", payload "reftable") with
          | Some "files", _, _ | _, Some "", _ -> Ok Files
          | Some "reftable", _, _ | _, _, Some "" -> Ok Reftable
          | _, Some path, _ | _, _, Some path -> Error (Payload path)
          | _ -> Error (Unknown_format value))
      | _ -> Error Not_version_1)

type working_tree = Main | Linked of string

type limits = {
  max_loose_size : int;
  max_packed_size : int;
  max_tables_list_size : int;
  max_stack_size : int;
  max_names_size : int;
}

type error =
  | Unread of { pathname : string; failure : Files.failure }
  | Malformed_packed_refs of { pathname : string; error : Packed_refs.error }
  | Malformed_tables_list of { pathname : string; error : Reftable.list_error }
  | Malformed_table of { pathname : string; error : Reftable.error }

type 'e failure = Refs of error | Objects of 'e

let ( let* ) = Result.bind

module Make (R : Files.READER) = struct
  type t = {
    limits : limits;
    storage : storage;
    format : Object_id.format;
    git_folder : string;
    working_tree : working_tree;
    mutable packed : (Packed_refs.t, error) result option;
    mutable shared_stack : (Reftable.t list, error) result option;
    mutable own_stack : (Reftable.t list, error) result option;
  }

  let create limits storage format ~git_folder working_tree =
    if
      List.exists
        (fun limit -> limit < 0)
        [
          limits.max_loose_size;
          limits.max_packed_size;
          limits.max_tables_list_size;
          limits.max_stack_size;
          limits.max_names_size;
        ]
    then invalid_arg "Refs.create: a negative limit";
    {
      limits;
      storage;
      format;
      git_folder;
      working_tree;
      packed = None;
      shared_stack = None;
      own_stack = None;
    }

  let unread pathname failure = Error (Unread { pathname; failure })

  (* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
     The loose ref of a name is the regular file, with the target of its
     content, or the symbolic link, which is not followed and names the ref of
     its reference when that is a ref name, at the pathname of the name; any
     other file there, or none, is no loose ref. *)
  let loose refs pathname =
    match R.link_kind pathname with
    | Error Files.No_file | Ok (Files.Folder | Files.Other_kind) -> Ok None
    | Error failure -> unread pathname failure
    | Ok Files.Regular_file -> (
        match R.read ~max_size:refs.limits.max_loose_size pathname with
        | Ok content -> Ok (Some (Loose_ref.parse refs.format content))
        | Error failure -> unread pathname failure)
    | Ok Files.Symbolic_link -> (
        match R.link_text pathname with
        | Ok text ->
            Ok
              (Some
                 (if Ref_name.is_ref_name text then Loose_ref.Symbolic text
                  else Loose_ref.Broken))
        | Error failure -> unread pathname failure)

  let packed refs =
    match refs.packed with
    | Some packed -> packed
    | None ->
        let pathname = Filename.concat refs.git_folder "packed-refs" in
        let packed =
          let* content =
            match R.read ~max_size:refs.limits.max_packed_size pathname with
            | Error Files.No_file -> Ok ""
            | Error failure -> Error (Unread { pathname; failure })
            | Ok content -> Ok content
          in
          Result.map_error
            (fun error -> Malformed_packed_refs { pathname; error })
            (Packed_refs.parse refs.format content)
        in
        refs.packed <- Some packed;
        packed

  let is_own name =
    Ref_name.is_root_name name
    || List.exists
         (fun prefix -> String.starts_with ~prefix name)
         [ "refs/bisect/"; "refs/worktree/"; "refs/rewritten/" ]

  (* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
     The stack of a folder is its folder reftable: its file tables.list names
     its tables, each read whole and from the newest to the oldest, within the
     sizes that the limits leave for the stack. *)
  let read_stack refs folder =
    let folder = Filename.concat folder "reftable" in
    let list = Filename.concat folder "tables.list" in
    let* content =
      match R.read ~max_size:refs.limits.max_tables_list_size list with
      | Ok content -> Ok content
      | Error failure -> unread list failure
    in
    let* names =
      Result.map_error
        (fun error -> Malformed_tables_list { pathname = list; error })
        (Reftable.table_names content)
    in
    let rec tables stack_left names_left = function
      | [] -> Ok []
      | name :: older -> (
          let pathname = Filename.concat folder name in
          match R.read ~max_size:stack_left pathname with
          | Error failure -> unread pathname failure
          | Ok content -> (
              match
                Reftable.parse refs.format ~max_names:names_left content
              with
              | Error error -> Error (Malformed_table { pathname; error })
              | Ok table ->
                  let* rest =
                    tables
                      (stack_left - String.length content)
                      (names_left - Reftable.names_size table)
                      older
                  in
                  Ok (table :: rest)))
    in
    tables refs.limits.max_stack_size refs.limits.max_names_size
      (List.rev names)

  let stack refs ~own =
    match (own, refs.working_tree) with
    | true, Linked folder -> (
        match refs.own_stack with
        | Some stack -> stack
        | None ->
            let stack = read_stack refs folder in
            refs.own_stack <- Some stack;
            stack)
    | _ -> (
        match refs.shared_stack with
        | Some stack -> stack
        | None ->
            let stack = read_stack refs refs.git_folder in
            refs.shared_stack <- Some stack;
            stack)

  (* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
     In the reftable format, the ref of a name is the record of that name in
     the newest table of its stack that holds one, and no ref when that record
     deletes it; a symbolic record names a ref only when its target is a ref
     name. *)
  let reftable_lookup refs name =
    let* tables = stack refs ~own:(is_own name) in
    Ok
      (Option.bind
         (List.find_map (fun t -> Reftable.find t name) tables)
         (function
           | Reftable.Deletion -> None
           | Reftable.Object id -> Some (Loose_ref.Object id)
           | Reftable.Symbolic target ->
               Some
                 (if Ref_name.is_ref_name target then Loose_ref.Symbolic target
                  else Loose_ref.Broken)))

  (* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
     An own ref of a linked working tree, HEAD among them, is only a loose ref
     of the folder of that working tree; each other ref is a loose ref of the
     git folder or, when no loose ref has its name, the ref of that name in
     the file packed-refs. *)
  let files_lookup refs name =
    let folder =
      match refs.working_tree with
      | Linked folder when is_own name -> Some folder
      | Main | Linked _ -> None
    in
    match folder with
    | Some folder -> loose refs (Filename.concat folder name)
    | None -> (
        let* found = loose refs (Filename.concat refs.git_folder name) in
        match found with
        | Some target -> Ok (Some target)
        | None ->
            let* packed = packed refs in
            Ok
              (Option.map
                 (fun id -> Loose_ref.Object id)
                 (Packed_refs.find packed name)))

  let lookup refs name =
    if not (Ref_name.is_ref_name name) then Ok None
    else
      match refs.storage with
      | Files -> files_lookup refs name
      | Reftable -> reftable_lookup refs name

  let target ~is_commit = function
    | Loose_ref.Object id -> (
        match is_commit id with
        | Ok true -> Ok (Ref_commit.Commit id)
        | Ok false -> Ok Ref_commit.Other
        | Error e -> Error (Objects e))
    | Loose_ref.Symbolic name -> Ok (Ref_commit.Ref name)
    | Loose_ref.Broken -> Ok Ref_commit.Broken

  let refs refs ~is_commit name =
    match lookup refs name with
    | Error e -> Error (Refs e)
    | Ok None -> Ok None
    | Ok (Some found) -> Result.map Option.some (target ~is_commit found)
end

include Make (Sinter_repository_files)
