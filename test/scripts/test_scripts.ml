(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let scripts = Filename.dirname (Sys.getcwd ())
let names = [ "run-mutants.sh" ]
let ( / ) = Filename.concat

let rec make_dir path =
  if not (Sys.file_exists path) then (
    make_dir (Filename.dirname path);
    Unix.mkdir path 0o755)

let write ?(mode = 0o644) path text =
  make_dir (Filename.dirname path);
  Out_channel.with_open_bin path (fun channel ->
      Out_channel.output_string channel text);
  Unix.chmod path mode

let read path = In_channel.with_open_bin path In_channel.input_all

let rec remove path =
  match (Unix.lstat path).Unix.st_kind with
  | Unix.S_DIR ->
      Array.iter (fun name -> remove (path / name)) (Sys.readdir path);
      Unix.rmdir path
  | _ -> Sys.remove path
  | exception Unix.Unix_error (Unix.ENOENT, _, _) -> ()

let lines text =
  String.split_on_char '\n' text |> List.filter (fun line -> line <> "")

let contains ~sub text =
  let n = String.length sub and m = String.length text in
  let rec from i = i + n <= m && (String.sub text i n = sub || from (i + 1)) in
  from 0

let fake_suite =
  {|#!/bin/sh
here=$(dirname "$0")
{ pwd; printf '%s\n' "$@"; } >"$here/arguments"
|}

type ran = { status : int; err : string }

let run ?(env = []) root script args =
  let out_path = root / ".out" and err_path = root / ".err" in
  let open_output path =
    Unix.openfile path [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ] 0o644
  in
  let out = open_output out_path and err = open_output err_path in
  let path =
    (root / "fake") ^ ":"
    ^ Option.value (Sys.getenv_opt "PATH") ~default:"/usr/bin:/bin"
  in
  let inherited =
    Array.to_list (Unix.environment ())
    |> List.filter (fun binding ->
        not
          (List.exists
             (fun prefix -> String.starts_with ~prefix binding)
             [ "PATH="; "MUTAML_MUTANT="; "FAKE_" ]))
  in
  let environment =
    Array.of_list
      ((("PATH=" ^ path) :: List.map (fun (n, v) -> n ^ "=" ^ v) env)
      @ inherited)
  in
  let argv =
    Array.of_list
      ("/bin/sh" :: "-c" :: {|cd "$0" && exec sh "$@"|} :: root
     :: ("test" / script) :: args)
  in
  let pid =
    Unix.create_process_env "/bin/sh" argv environment Unix.stdin out err
  in
  Unix.close out;
  Unix.close err;
  let status =
    match snd (Unix.waitpid [] pid) with
    | Unix.WEXITED code -> code
    | Unix.WSIGNALED _ | Unix.WSTOPPED _ -> -1
  in
  { status; err = read err_path }

let in_project f =
  let root = Filename.temp_dir "sinter-scripts" "" in
  Fun.protect
    ~finally:(fun () -> remove root)
    (fun () ->
      List.iter
        (fun name ->
          write ~mode:0o755 (root / "test" / name) (read (scripts / name)))
        names;
      write ~mode:0o755
        (root / "_build/default/test/test_sinter.exe")
        fake_suite;
      f root)

let status = Alcotest.(check int) "the exit status"

let mentions what text =
  if not (contains ~sub:what text) then
    Alcotest.failf "the output does not mention %S:\n%s" what text

let suite_arguments root = lines (read (root / "_build/default/test/arguments"))

let run_mutants_tests =
  [
    Alcotest.test_case
      "the arguments come before the option that stops at the first failure"
      `Quick (fun () ->
        in_project (fun root ->
            status 0
              (run root "run-mutants.sh" [ "test"; "^(alpha|mode)$" ]).status;
            match suite_arguments root with
            | folder :: arguments ->
                if not (String.ends_with ~suffix:"_build/default/test" folder)
                then Alcotest.failf "the suite ran in %s" folder;
                Alcotest.(check (list string))
                  "the arguments"
                  [ "test"; "^(alpha|mode)$"; "--bail" ]
                  arguments
            | [] -> Alcotest.fail "the suite did not run"));
    Alcotest.test_case "the suite runs the test groups that the filter names"
      `Quick (fun () ->
        let root = Filename.temp_dir "sinter-scripts" "" in
        Fun.protect
          ~finally:(fun () -> remove root)
          (fun () ->
            write ~mode:0o755
              (root / "test/run-mutants.sh")
              (read (scripts / "run-mutants.sh"));
            make_dir (root / "_build");
            make_dir (root / "results");
            Unix.symlink (Filename.dirname scripts) (root / "_build/default");
            status 0
              (run root "run-mutants.sh"
                 [ "test"; "^(version)$"; "-o"; root / "results" ])
                .status));
    Alcotest.test_case "the command needs a built suite" `Quick (fun () ->
        in_project (fun root ->
            Sys.remove (root / "_build/default/test/test_sinter.exe");
            let ran = run root "run-mutants.sh" [] in
            status 2 ran.status;
            mentions "no test suite" ran.err));
  ]

let () = Alcotest.run "scripts" [ ("run mutants", run_mutants_tests) ]
