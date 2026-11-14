(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Files = Sinter_repository_files

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
  | _ ->
      prerr_endline "usage: wait_probe (files PATH | socket DIR)";
      exit 2
