(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let folders =
  [
    "branch_names";
    "commit_graphs";
    "git_model";
    "line_maps";
    "repository_files";
    "wildmatch";
    "git_config";
    "git_objects";
    "git_refs";
    "ref_names";
    "git_object_store";
  ]

let ( / ) = Filename.concat

let sources () =
  List.concat_map
    (fun folder ->
      let dir = ".." / "lib" / folder in
      List.filter_map
        (fun name ->
          if
            List.exists
              (fun suffix -> Filename.check_suffix name suffix)
              [ ".ml"; ".mli"; ".c"; ".h" ]
            || name = "dune"
          then Some (dir / name)
          else None)
        (List.sort String.compare (Array.to_list (Sys.readdir dir))))
    folders

let read path = In_channel.with_open_bin path In_channel.input_all

let tokens ~dots text =
  let is_part c =
    (c >= 'a' && c <= 'z')
    || (c >= 'A' && c <= 'Z')
    || (c >= '0' && c <= '9')
    || c = '_' || c = '\''
    || (dots && c = '.')
  in
  let lines = String.split_on_char '\n' text in
  List.concat
    (List.mapi
       (fun index line ->
         let found = ref [] and start = ref (-1) in
         String.iteri
           (fun i c ->
             if is_part c then (if !start < 0 then start := i)
             else if !start >= 0 then (
               found :=
                 (index + 1, String.sub line !start (i - !start)) :: !found;
               start := -1))
           line;
         if !start >= 0 then
           found :=
             (index + 1, String.sub line !start (String.length line - !start))
             :: !found;
         List.rev !found)
       lines)

let ocaml_calls =
  [
    "Unix.fork";
    "Unix.create_process";
    "Unix.create_process_env";
    "Unix.open_process";
    "Unix.open_process_in";
    "Unix.open_process_out";
    "Unix.open_process_full";
    "Unix.open_process_args";
    "Unix.open_process_args_in";
    "Unix.open_process_args_out";
    "Unix.open_process_args_full";
    "Unix.execv";
    "Unix.execve";
    "Unix.execvp";
    "Unix.execvpe";
    "Unix.system";
    "Sys.command";
    "Unix.socket";
    "Unix.socketpair";
    "Unix.connect";
    "Unix.open_connection";
    "Unix.establish_server";
    "Unix.setuid";
    "Unix.setgid";
    "Unix.setgroups";
    "Unix.initgroups";
    "Unix.O_WRONLY";
    "Unix.O_RDWR";
    "Unix.O_CREAT";
    "Unix.O_TRUNC";
    "Unix.O_APPEND";
    "open_out";
    "open_out_bin";
    "open_out_gen";
    "Out_channel.open_bin";
    "Out_channel.open_text";
    "Out_channel.open_gen";
    "Out_channel.with_open_bin";
    "Out_channel.with_open_text";
    "Out_channel.with_open_gen";
    "Unix.unlink";
    "Unix.rename";
    "Unix.mkdir";
    "Unix.rmdir";
    "Unix.chmod";
    "Unix.fchmod";
    "Unix.chown";
    "Unix.fchown";
    "Unix.utimes";
    "Unix.truncate";
    "Unix.ftruncate";
    "Unix.symlink";
    "Unix.link";
    "Unix.write";
    "Unix.single_write";
    "Unix.write_substring";
    "Unix.lockf";
    "Unix.putenv";
    "Unix.environment";
    "Unix.getenv";
    "Sys.getenv";
    "Sys.getenv_opt";
    "Sys.remove";
    "Sys.rename";
    "Sys.mkdir";
    "Sys.rmdir";
    "Dynlink";
    "fork";
    "create_process";
    "create_process_env";
    "open_process_in";
    "execv";
    "execve";
    "execvp";
    "setuid";
    "setgid";
    "setgroups";
    "initgroups";
    "putenv";
  ]

let c_calls =
  [
    "fork";
    "vfork";
    "execl";
    "execle";
    "execlp";
    "execv";
    "execve";
    "execvp";
    "execvpe";
    "fexecve";
    "posix_spawn";
    "posix_spawnp";
    "system";
    "popen";
    "socket";
    "connect";
    "setuid";
    "setgid";
    "seteuid";
    "setegid";
    "setgroups";
    "setreuid";
    "setregid";
    "setresuid";
    "setresgid";
    "dlopen";
    "O_WRONLY";
    "O_RDWR";
    "O_CREAT";
    "O_TRUNC";
    "O_APPEND";
    "unlink";
    "unlinkat";
    "rename";
    "renameat";
    "mkdir";
    "mkdirat";
    "rmdir";
    "chmod";
    "fchmod";
    "fchmodat";
    "chown";
    "fchown";
    "lchown";
    "write";
    "pwrite";
    "writev";
    "ftruncate";
    "truncate";
    "utime";
    "utimes";
    "futimens";
    "utimensat";
    "link";
    "linkat";
    "symlink";
    "symlinkat";
    "getenv";
    "putenv";
    "setenv";
    "fopen";
    "flock";
  ]

let allowed_libraries =
  [
    "unix";
    "sinter_text";
    "sinter_paths";
    "sinter_tree";
    "sinter_branch_names";
    "sinter_commit_graphs";
    "sinter_line_maps";
    "sinter_git_model";
    "sinter_wildmatch";
    "sinter_repository_files";
    "sinter_git_objects";
    "sinter_ref_names";
    "sinter_git_object_store";
    "decompress.de";
    "decompress.zl";
    "digestif";
  ]

let found_calls path =
  let text = read path in
  if Filename.check_suffix path ".c" || Filename.check_suffix path ".h" then
    List.filter
      (fun (_, token) -> List.mem token c_calls)
      (tokens ~dots:false text)
  else if Filename.basename path = "dune" then
    let libraries =
      match String.index_opt text '(' with
      | None -> []
      | Some _ -> (
          let marker = "(libraries" in
          match
            List.find_opt
              (fun i -> String.sub text i (String.length marker) = marker)
              (List.init
                 (max 0 (String.length text - String.length marker))
                 Fun.id)
          with
          | None -> []
          | Some start ->
              let stop = String.index_from text start ')' in
              List.map
                (fun t -> (0, t))
                (List.filter
                   (fun t -> t <> "" && t <> "libraries")
                   (String.split_on_char ' '
                      (String.map
                         (function '\n' | '(' | ')' -> ' ' | c -> c)
                         (String.sub text start (stop - start))))))
    in
    List.filter
      (fun (_, library) -> not (List.mem library allowed_libraries))
      libraries
  else
    let tokens = tokens ~dots:true text in
    let flagged =
      List.filter (fun (_, token) -> List.mem token ocaml_calls) tokens
    in
    let rec opens = function
      | (line, "open") :: (_, ("Unix" | "UnixLabels")) :: rest ->
          (line, "open Unix") :: opens rest
      | (line, "module") :: (_, _) :: (_, ("Unix" | "UnixLabels")) :: rest ->
          (line, "an alias of Unix") :: opens rest
      | (line, "external") :: rest
        when not (String.ends_with ~suffix:"sinter_repository_files.ml" path) ->
          (line, "external") :: opens rest
      | _ :: rest -> opens rest
      | [] -> []
    in
    flagged @ opens tokens

(* @verifies changes#{gain-no-repository-privileges=v1, run-no-configured-programs=v1}
   The test searches the sources of the libraries of the chunk for each call of
   OCaml and of C that starts a process, runs a shell or a command, loads code,
   opens a socket, changes a user ID or a group ID, opens a file to write, or
   changes a file, and for each library outside the chunk's own and `unix`; a
   source that holds one fails the test. It cannot see a call made through
   another library, such as decompress, a call under a name that the search
   does not know, or what 2c adds. *)
let tests =
  [
    Alcotest.test_case
      "the libraries of the chunk hold no call that runs, writes, or changes \
       privileges"
      `Quick (fun () ->
        let paths = sources () in
        Alcotest.(check bool)
          "the sources are there" true
          (List.length paths >= 15);
        let found =
          List.concat_map
            (fun path ->
              List.map
                (fun (line, token) ->
                  Printf.sprintf "%s:%d: %s" path line token)
                (found_calls path))
            paths
        in
        Alcotest.(check (list string)) "the calls" [] found);
  ]
