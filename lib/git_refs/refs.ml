(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Object_id = Sinter_git_objects.Object_id
module Ref_commit = Sinter_git_model.Ref_commit
module Ref_name = Sinter_ref_names.Ref_name
module Files = Sinter_repository_files

type storage = Files | Reftable
type working_tree = Main | Linked of string
type limits = { max_loose_size : int; max_packed_size : int }

type error =
  | Reftable_not_read
  | Unread of { pathname : string; failure : Files.failure }
  | Malformed_packed_refs of { pathname : string; error : Packed_refs.error }

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
  }

  let create limits storage format ~git_folder working_tree =
    if limits.max_loose_size < 0 || limits.max_packed_size < 0 then
      invalid_arg "Refs.create: a negative limit";
    { limits; storage; format; git_folder; working_tree; packed = None }

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
     An own ref of a linked working tree, HEAD among them, is only a loose ref
     of the folder of that working tree; each other ref is a loose ref of the
     git folder or, when no loose ref has its name, the ref of that name in
     the file packed-refs. *)
  let lookup refs name =
    match refs.storage with
    | Reftable -> Error Reftable_not_read
    | Files -> (
        if not (Ref_name.is_ref_name name) then Ok None
        else
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
                       (Packed_refs.find packed name))))

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
