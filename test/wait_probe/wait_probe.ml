(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Files = Sinter_repository_files
module Refs = Sinter_git_refs.Refs
module Id = Sinter_git_objects.Object_id
module Store = Sinter_git_object_store.Object_store

let failure_name = function
  | Files.No_file -> "no file"
  | Files.Not_a_regular_file -> "not a regular file"
  | Files.Not_a_folder -> "not a folder"
  | Files.Not_a_symbolic_link -> "not a symbolic link"
  | Files.Too_large -> "too large"
  | Files.Cannot_read -> "cannot read"

let kind_name = function
  | Files.Folder -> "folder"
  | Files.Regular_file -> "regular file"
  | Files.Symbolic_link -> "symbolic link"
  | Files.Other_kind -> "other kind"

let show f = function
  | Ok value -> "Ok " ^ f value
  | Error failure -> "Error " ^ failure_name failure

let refs_error = function
  | Refs.Unread { pathname; failure } ->
      Printf.sprintf "unread %s: %s"
        (Filename.basename pathname)
        (failure_name failure)
  | _ -> "another error"

let target = function
  | Sinter_git_refs.Loose_ref.Object id -> "object " ^ Id.to_hex id
  | Sinter_git_refs.Loose_ref.Symbolic name -> "symbolic " ^ name
  | Sinter_git_refs.Loose_ref.Broken -> "broken"

let () =
  match Array.to_list Sys.argv with
  | [ _; "files"; path ] ->
      List.iter print_endline
        [
          show (Printf.sprintf "%S") (Files.read ~max_size:(1 lsl 30) path);
          show Fun.id (Files.with_file path (fun _ -> "opened"));
          show (fun names -> String.concat "," names) (Files.list path);
          show (fun _ -> "identity") (Files.folder_identity path);
          show kind_name (Files.link_kind path);
          show (Printf.sprintf "%S") (Files.link_text path);
        ]
  | [ _; "socket"; dir ] ->
      Sys.chdir dir;
      let socket = Unix.socket Unix.PF_UNIX Unix.SOCK_STREAM 0 in
      Unix.bind socket (Unix.ADDR_UNIX "s");
      print_endline
        (show (Printf.sprintf "%S") (Files.read ~max_size:(1 lsl 30) "s"));
      print_endline
        (show (fun names -> String.concat "," names) (Files.list "s"));
      print_endline (show (fun _ -> "identity") (Files.folder_identity "s"))
  | [ _; "refs"; git_folder; name ] ->
      let refs =
        Refs.create
          { Refs.max_loose_size = 1 lsl 20; max_packed_size = 1 lsl 30 }
          Refs.Files Id.Sha1 ~git_folder Refs.Main
      in
      List.iter
        (fun name ->
          print_endline
            (match Refs.lookup refs name with
            | Ok (Some t) -> target t
            | Ok None -> "none"
            | Error error -> refs_error error))
        [ name; "HEAD" ]
  | [ _; "objects"; git_folder; format; hex; max_deltas; max_databases ] ->
      let format = if format = "sha256" then Id.Sha256 else Id.Sha1 in
      let limits =
        {
          Store.max_content_size = 1 lsl 24;
          max_deltas = int_of_string max_deltas;
          max_databases = int_of_string max_databases;
          max_packs = 1000;
          max_alternates_size = 1 lsl 16;
        }
      in
      let store = Store.create limits format ~git_folder in
      print_endline
        (match Id.of_hex format hex with
        | None -> "not an id"
        | Some id -> (
            match Store.find store id with
            | Ok { held = Some obj; damage } ->
                Printf.sprintf "held %d %d"
                  (String.length obj.content)
                  (List.length damage)
            | Ok { held = None; damage } ->
                Printf.sprintf "not held %d" (List.length damage)
            | Error (Store.Unread { pathname; failure }) ->
                Printf.sprintf "unread %s: %s" pathname (failure_name failure)
            | Error _ -> "another failure"))
  | _ ->
      prerr_endline
        "usage: wait_probe (files PATH | socket DIR | refs GIT_FOLDER NAME | \
         objects GIT_FOLDER FORMAT HEX MAX_DELTAS MAX_DATABASES)";
      exit 2
