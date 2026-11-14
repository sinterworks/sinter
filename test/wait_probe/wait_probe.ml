(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Files = Sinter_repository_files
module Refs = Sinter_git_refs.Refs
module Id = Sinter_git_objects.Object_id

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
        (show (fun names -> String.concat "," names) (Files.list "s"))
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
  | _ ->
      prerr_endline
        "usage: wait_probe (files PATH | socket DIR | refs GIT_FOLDER NAME)";
      exit 2
