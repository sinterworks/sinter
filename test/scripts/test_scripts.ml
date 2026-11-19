(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let scripts = Filename.dirname (Sys.getcwd ())

let names =
  [
    "run-mutants.sh";
    "mutant-groups.sh";
    "run-mutant-share.sh";
    "join-mutant-reports.sh";
  ]

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

let fake_objinfo =
  {|#!/bin/sh
for file in "$@"; do
  if [ ! -f "$file.info" ]; then
    echo "ocamlobjinfo: cannot read $file" >&2
    exit 2
  fi
  cat "$file.info"
done
|}

let fake_suite =
  {|#!/bin/sh
here=$(dirname "$0")
if [ "${1:-}" = list ]; then
  if [ -f "$here/listing-fails" ]; then
    echo "the suite cannot start" >&2
    exit 3
  fi
  cat "$here/listing"
  exit 0
fi
{ pwd; printf '%s\n' "$@"; } >"$here/arguments"
|}

let fake_runner =
  {|#!/bin/sh
set -eu
{ printf '%s\n' "$@"; echo --; } >>"${FAKE_CALLS:-/dev/null}"
muts=
command=
while [ "$#" -gt 0 ]; do
  case $1 in
    --muts) muts=$2; shift 2 ;;
    --build-context | -j | --repeat | --test-env | --baseline-env | --changed-since | --timeout) shift 2 ;;
    *) command=$1; shift ;;
  esac
done
if [ -n "${FAKE_PRINT:-}" ]; then
  printf '%s\n' "$FAKE_PRINT"
fi
if [ "${FAKE_RUN_COMMAND:-}" = 1 ]; then
  sh -c "{ $command
}"
fi
if [ "${FAKE_NO_REPORT:-}" != 1 ]; then
  if [ -n "${FAKE_REPORT:-}" ]; then
    cp "$FAKE_REPORT" mutaml-report.json
  else
    echo '{"results": [], "skipped": []}' >mutaml-report.json
  fi
fi
if [ -n "${FAKE_STATUS:-}" ]; then
  exit "$FAKE_STATUS"
fi
|}

type compiled = {
  objects : string;
  name : string;
  source : string option;
  imports : string list;
}

type project = {
  units : compiled list;
  entries : string list;
  listed : string list;
  mutants : (string * int) list;
}

let library name imports =
  {
    objects = "lib/.lib.objs";
    name = "Lib__" ^ String.capitalize_ascii name;
    source = Some ("lib/" ^ name ^ ".ml");
    imports;
  }

let program objects name imports =
  {
    objects;
    name = "Dune__exe__" ^ name;
    source =
      Some ((Filename.dirname objects / String.uncapitalize_ascii name) ^ ".ml");
    imports;
  }

let test_unit name imports = program "test/.test_sinter.eobjs" name imports

let standard =
  {
    units =
      [
        {
          objects = "lib/.lib.objs";
          name = "Lib";
          source = None;
          imports =
            [ "Lib__A"; "Lib__B"; "Lib__C"; "Lib__D"; "Lib__E"; "Lib__F" ];
        };
        library "a" [];
        library "b" [ "Lib__C" ];
        library "c" [];
        library "d" [];
        library "e" [];
        library "f" [];
        program "bin/.main.eobjs" "Main"
          [ "Lib"; "Lib__D"; "Dune__exe__Shared" ];
        program "bin/.main.eobjs" "Shared" [ "Lib__F" ];
        {
          objects = "bin/.main.eobjs";
          name = "Dune__exe";
          source = None;
          imports = [ "Dune__exe__Main"; "Dune__exe__Shared" ];
        };
        program "bench/.generate.eobjs" "Generate" [];
        program "bench/.run.eobjs" "Run" [];
        {
          objects = "test/.test_sinter.eobjs";
          name = "Dune__exe";
          source = None;
          imports =
            [
              "Dune__exe__Test_a";
              "Dune__exe__Test_b";
              "Dune__exe__Shared";
              "Dune__exe__Test_cli";
              "Dune__exe__Runner";
            ];
        };
        test_unit "Test_a" [ "Lib"; "Lib__A" ];
        test_unit "Test_b" [ "Lib__B"; "Dune__exe__Shared" ];
        test_unit "Shared" [ "Lib__E" ];
        test_unit "Test_cli" [ "Dune__exe__Runner" ];
        test_unit "Runner" [];
        test_unit "Test_sinter"
          [ "Dune__exe__Test_a"; "Dune__exe__Test_b"; "Dune__exe__Test_cli" ];
      ];
    entries =
      [
        {|("alpha", Test_a.tests)|};
        {|("beta two", Test_b.tests)|};
        {|("cli", Test_cli.tests)|};
        {|( "mode",
        [ Alcotest.test_case "names" `Quick (fun () -> ()) ] )|};
      ];
    listed = [ "alpha"; "beta two"; "cli"; "mode" ];
    mutants =
      [
        ("bin/main", 1);
        ("lib/a", 3);
        ("lib/b", 1);
        ("lib/c", 1);
        ("lib/d", 1);
        ("lib/e", 1);
        ("lib/f", 1);
        ("lib/g", 2);
      ];
  }

let runner_source =
  "let binary = \"../bin/main.exe\"\nlet exempt = paths.exempt\n"

let suite_source entries =
  "let () =\n  Alcotest.run \"sinter\"\n    [\n"
  ^ String.concat "" (List.map (fun entry -> "      " ^ entry ^ ";\n") entries)
  ^ "    ]\n"

let listing groups =
  let width =
    List.fold_left (fun width name -> max width (String.length name)) 0 groups
  in
  "qcheck random seed: 1\n"
  ^ String.concat ""
      (List.concat_map
         (fun name ->
           List.init 2 (fun index ->
               Printf.sprintf "%s%s%3d   checks fact %d.\n" name
                 (String.make (width + 8 - String.length name) ' ')
                 index index))
         (List.sort compare groups))

let info compiled =
  let line name = "\t0123456789abcdef0123456789abcdef\t" ^ name ^ "\n" in
  String.concat ""
    ([
       "File _build/default/" ^ compiled.objects ^ "/native/"
       ^ String.uncapitalize_ascii compiled.name
       ^ ".cmx\n";
       "Name: " ^ compiled.name ^ "\n";
       "CRC of implementation: 0123456789abcdef0123456789abcdef\n";
       "Globals defined:\n";
       "\t" ^ compiled.name ^ "\n";
       "Interfaces imported:\n";
     ]
    @ List.map line ("Stdlib" :: compiled.name :: compiled.imports)
    @ [ "Implementations imported:\n"; line "Stdlib"; "Force link: no\n" ])

let mutant path number =
  Printf.sprintf
    {|{"number":%d,"binding":"f","kind":"bool-constant","original":"true","ordinal":%d,"repl":"false","loc":{"loc_start":{"pos_fname":"%s","pos_lnum":%d,"pos_bol":0,"pos_cnum":0},"loc_end":{"pos_fname":"%s","pos_lnum":%d,"pos_bol":0,"pos_cnum":4},"loc_ghost":false}}|}
    number number path (number + 1) path (number + 1)

let unit_path compiled =
  "_build/default" / compiled.objects / "native"
  / (String.uncapitalize_ascii compiled.name ^ ".cmx")

let lay_out root project =
  let build = root / "_build/default" in
  List.iter
    (fun compiled ->
      let cmx = root / unit_path compiled in
      write cmx "";
      write (cmx ^ ".info") (info compiled);
      Option.iter
        (fun path ->
          let text =
            if path = "test/test_sinter.ml" then suite_source project.entries
            else if path = "test/runner.ml" then runner_source
            else "let tests = []\n"
          in
          write (build / path) text)
        compiled.source)
    project.units;
  write (root / "test/test_sinter.ml") (suite_source project.entries);
  write ~mode:0o755 (build / "test/test_sinter.exe") fake_suite;
  write (build / "test/listing") (listing project.listed);
  let side = root / "_build/.mutaml/default" in
  write
    (side / "mutaml-mut-files.txt")
    (String.concat ""
       (List.map (fun (file, _) -> file ^ ".muts\n") project.mutants));
  List.iter
    (fun (file, count) ->
      write
        (side / (file ^ ".muts"))
        (Printf.sprintf {|{"mutants":[%s]}|}
           (String.concat ","
              (List.init count (fun number -> mutant (file ^ ".ml") number)))))
    project.mutants

type ran = { status : int; out : string; err : string }

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
  { status; out = read out_path; err = read err_path }

let in_project ?(change = Fun.id) f =
  let root = Filename.temp_dir "sinter-scripts" "" in
  Fun.protect
    ~finally:(fun () -> remove root)
    (fun () ->
      List.iter
        (fun name ->
          write ~mode:0o755 (root / "test" / name) (read (scripts / name)))
        names;
      write ~mode:0o755 (root / "fake/ocamlobjinfo") fake_objinfo;
      write ~mode:0o755 (root / "fake/mutaml-runner") fake_runner;
      lay_out root (change standard);
      f root)

let status = Alcotest.(check int) "the exit status"

let mentions what text =
  if not (contains ~sub:what text) then
    Alcotest.failf "the output does not mention %S:\n%s" what text

let map ran =
  status 0 ran.status;
  List.map
    (fun line ->
      match String.index_opt line '\t' with
      | Some at ->
          ( String.sub line 0 at,
            String.sub line (at + 1) (String.length line - at - 1) )
      | None -> Alcotest.failf "a line of the map has no tab: %S" line)
    (lines ran.out)

let selection root file =
  match List.assoc_opt file (map (run root "mutant-groups.sh" [])) with
  | Some filter -> filter
  | None -> Alcotest.failf "the map has no line for %s" file

let selects file expected () =
  in_project (fun root ->
      Alcotest.(check string) file expected (selection root file))

let without_group name project =
  {
    project with
    entries =
      List.filter
        (fun entry -> not (contains ~sub:("\"" ^ name ^ "\"") entry))
        project.entries;
    listed = List.filter (( <> ) name) project.listed;
  }

let renamed old_name new_name project =
  {
    project with
    entries =
      List.map
        (fun entry ->
          if contains ~sub:("\"" ^ old_name ^ "\"") entry then
            Printf.sprintf {|("%s", Test_a.tests)|} new_name
          else entry)
        project.entries;
    listed =
      List.map
        (fun name -> if name = old_name then new_name else name)
        project.listed;
  }

let with_runner_source text f =
  in_project (fun root ->
      write (root / "_build/default/test/runner.ml") text;
      f root)

let groups_tests =
  [
    Alcotest.test_case "a group reaches the modules that its test imports"
      `Quick
      (selects "lib/a.muts" "^(alpha|mode)$");
    Alcotest.test_case "a group reaches the modules that those modules import"
      `Quick
      (selects "lib/c.muts" "^(beta two|mode)$");
    Alcotest.test_case
      "a group does not reach a module that only the alias of its library names"
      `Quick
      (selects "lib/d.muts" "^(cli|mode)$");
    Alcotest.test_case
      "a module of the tests is told apart from a module of a program with the \
       same name"
      `Quick (fun () ->
        in_project (fun root ->
            Alcotest.(check string)
              "lib/e.muts" "^(beta two|mode)$"
              (selection root "lib/e.muts");
            Alcotest.(check string)
              "lib/f.muts" "^(cli|mode)$"
              (selection root "lib/f.muts")));
    Alcotest.test_case
      "a group that starts a program reaches the code of every program" `Quick
      (selects "bin/main.muts" "^(cli|mode)$");
    Alcotest.test_case "a group written out in the list reaches every file"
      `Quick
      (selects "lib/b.muts" "^(beta two|mode)$");
    Alcotest.test_case
      "a group whose module is not a module of the tests reaches every file"
      `Quick (fun () ->
        in_project
          ~change:(fun project ->
            {
              project with
              entries = {|("lib", Lib.tests)|} :: project.entries;
              listed = "lib" :: project.listed;
            })
          (fun root ->
            Alcotest.(check string)
              "lib/a.muts" "^(alpha|lib|mode)$"
              (selection root "lib/a.muts")));
    Alcotest.test_case "a mutation file with no compiled module gets every test"
      `Quick (fun () ->
        in_project (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            Alcotest.(check (option string))
              "lib/g.muts" (Some "all")
              (List.assoc_opt "lib/g.muts" (map ran));
            mentions "lib/g.ml" ran.err));
    Alcotest.test_case "a file that no group can reach gets every test" `Quick
      (fun () ->
        in_project
          ~change:(fun project ->
            let project = without_group "mode" project in
            {
              project with
              units = library "h" [] :: project.units;
              mutants = ("lib/h", 1) :: project.mutants;
            })
          (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            Alcotest.(check (option string))
              "lib/h.muts" (Some "all")
              (List.assoc_opt "lib/h.muts" (map ran));
            mentions "No test group can reach lib/h.ml" ran.err));
    Alcotest.test_case "a file that every group reaches gets every test" `Quick
      (fun () ->
        in_project
          ~change:(fun project ->
            without_group "cli" (without_group "beta two" project))
          (fun root ->
            Alcotest.(check string)
              "lib/a.muts" "all"
              (selection root "lib/a.muts")));
    Alcotest.test_case "the filter escapes the characters of a pattern" `Quick
      (fun () ->
        in_project ~change:(renamed "alpha" "a+b (c).") (fun root ->
            Alcotest.(check string)
              "lib/a.muts" {|^(a\+b \(c\)\.|mode)$|}
              (selection root "lib/a.muts")));
    Alcotest.test_case
      "a group that the suite lists and the source does not name stops the map"
      `Quick (fun () ->
        in_project
          ~change:(fun project ->
            { project with listed = "ghost" :: project.listed })
          (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "ghost (in the list of the suite only)" ran.err));
    Alcotest.test_case
      "a group that the source names and the suite does not list stops the map"
      `Quick (fun () ->
        in_project
          ~change:(fun project ->
            {
              project with
              entries = {|("ghost", Test_a.tests)|} :: project.entries;
            })
          (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "ghost (in the source only)" ran.err));
    Alcotest.test_case "a test that names an unknown program stops the map"
      `Quick (fun () ->
        with_runner_source "let other = \"../tools/other.exe\"\n" (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "test/runner.ml:1: other.exe" ran.err));
    Alcotest.test_case
      "a test that builds the name of a program from parts stops the map" `Quick
      (fun () ->
        with_runner_source "let binary = \"main\" ^ \".exe\"\n" (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "test/runner.ml:1: .exe" ran.err));
    Alcotest.test_case "a build without the modules of a program stops the map"
      `Quick (fun () ->
        in_project
          ~change:(fun project ->
            {
              project with
              units =
                List.filter
                  (fun compiled -> compiled.objects <> "bench/.run.eobjs")
                  project.units;
            })
          (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "run.exe" ran.err));
    Alcotest.test_case "a module that ocamlobjinfo cannot read stops the map"
      `Quick (fun () ->
        in_project (fun root ->
            Sys.remove ((root / unit_path (library "c" [])) ^ ".info");
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "ocamlobjinfo could not read" ran.err));
    Alcotest.test_case "a suite that cannot list its tests stops the map" `Quick
      (fun () ->
        in_project (fun root ->
            write (root / "_build/default/test/listing-fails") "";
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "the suite cannot start" ran.err));
    Alcotest.test_case
      "a group reaches the modules that a module without a source imports"
      `Quick (fun () ->
        in_project
          ~change:(fun project ->
            {
              project with
              units =
                {
                  objects = "test/.test_sinter.eobjs";
                  name = "Dune__exe__Generated";
                  source = None;
                  imports = [ "Lib__H" ];
                }
                :: library "h" []
                :: List.map
                     (fun compiled ->
                       if compiled.name = "Dune__exe__Test_a" then
                         {
                           compiled with
                           imports = "Dune__exe__Generated" :: compiled.imports;
                         }
                       else compiled)
                     project.units;
              mutants = ("lib/h", 1) :: project.mutants;
            })
          (fun root ->
            Alcotest.(check string)
              "lib/h.muts" "^(alpha|mode)$"
              (selection root "lib/h.muts")));
    Alcotest.test_case "two compiled modules with one name stop the map" `Quick
      (fun () ->
        in_project
          ~change:(fun project ->
            {
              project with
              units =
                {
                  objects = "lib2/.lib.objs";
                  name = "Lib__A";
                  source = None;
                  imports = [];
                }
                :: project.units;
            })
          (fun root ->
            let ran = run root "mutant-groups.sh" [] in
            status 1 ran.status;
            mentions "two compiled modules have the name Lib__A" ran.err));
    Alcotest.test_case "the map needs a build" `Quick (fun () ->
        in_project (fun root ->
            remove (root / "_build");
            status 2 (run root "mutant-groups.sh" []).status));
    Alcotest.test_case "the map takes no argument" `Quick (fun () ->
        in_project (fun root ->
            status 2 (run root "mutant-groups.sh" [ "lib/a.muts" ]).status));
  ]

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

let calls root = read (root / ".calls")
let calls_env root = [ ("FAKE_CALLS", root / ".calls") ]

let share_tests =
  [
    Alcotest.test_case "the runner gets the test groups of the file" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              run ~env:(calls_env root) root "run-mutant-share.sh"
                [ "-s"; "7"; "out.json"; "lib/a.muts" ]
            in
            status 0 ran.status;
            mentions "\ntest/run-mutants.sh test '^(alpha|mode)$'\n"
              (calls root);
            mentions
              "lib/a.muts (1 of 1) with the test command: test/run-mutants.sh \
               test '^(alpha|mode)$'"
              ran.out));
    Alcotest.test_case "a file that gets every test runs the whole suite" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              run ~env:(calls_env root) root "run-mutant-share.sh"
                [ "out.json"; "lib/g.muts" ]
            in
            status 0 ran.status;
            mentions "\ntest/run-mutants.sh\n--\n" (calls root)));
    Alcotest.test_case "the suite gets the filter as one argument" `Quick
      (fun () ->
        in_project ~change:(renamed "alpha" "it's a+b") (fun root ->
            let ran =
              run
                ~env:(("FAKE_RUN_COMMAND", "1") :: calls_env root)
                root "run-mutant-share.sh"
                [ "out.json"; "lib/a.muts" ]
            in
            status 0 ran.status;
            Alcotest.(check (list string))
              "the arguments"
              [ "test"; {|^(it's a\+b|mode)$|}; "--bail" ]
              (List.tl (suite_arguments root))));
    Alcotest.test_case "a map that cannot be made stops the share" `Quick
      (fun () ->
        in_project
          ~change:(fun project ->
            { project with listed = "ghost" :: project.listed })
          (fun root ->
            let ran =
              run ~env:(calls_env root) root "run-mutant-share.sh"
                [ "out.json"; "lib/a.muts" ]
            in
            if ran.status = 0 then Alcotest.fail "the share passed";
            Alcotest.(check bool)
              "the runner ran" false
              (Sys.file_exists (root / ".calls"))));
    Alcotest.test_case "a runner that fails stops the share" `Quick (fun () ->
        in_project (fun root ->
            let ran =
              run
                ~env:[ ("FAKE_STATUS", "2") ]
                root "run-mutant-share.sh"
                [ "out.json"; "lib/a.muts" ]
            in
            status 2 ran.status;
            mentions "failed with status 2" ran.out;
            Alcotest.(check bool)
              "the report" false
              (Sys.file_exists (root / "out.json"))));
    Alcotest.test_case "a runner that writes no report stops the share" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              run
                ~env:[ ("FAKE_NO_REPORT", "1") ]
                root "run-mutant-share.sh"
                [ "out.json"; "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "wrote no report" ran.out;
            Alcotest.(check bool)
              "the report" false
              (Sys.file_exists (root / "out.json"))));
    Alcotest.test_case "a runner that skips a file stops the share" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              run
                ~env:[ ("FAKE_PRINT", "Skipping lib/x.muts: gone") ]
                root "run-mutant-share.sh"
                [ "out.json"; "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "skipped a mutation file" ran.out));
    Alcotest.test_case "a file that the map does not name stops the share"
      `Quick (fun () ->
        in_project (fun root ->
            let ran =
              run ~env:(calls_env root) root "run-mutant-share.sh"
                [ "out.json"; "lib/z.muts" ]
            in
            status 1 ran.status;
            mentions "names no test group for lib/z.muts" ran.out;
            Alcotest.(check bool)
              "the runner ran" false
              (Sys.file_exists (root / ".calls"))));
    Alcotest.test_case "the changed lines go to the runner" `Quick (fun () ->
        in_project (fun root ->
            let ran =
              run ~env:(calls_env root) root "run-mutant-share.sh"
                [ "-c"; "base"; "out.json"; "lib/a.muts" ]
            in
            status 0 ran.status;
            mentions "\n--changed-since\nbase\n" (calls root)));
  ]

let () =
  Alcotest.run "scripts"
    [
      ("mutant groups", groups_tests);
      ("run mutants", run_mutants_tests);
      ("mutant share", share_tests);
    ]
