(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let scripts = Filename.dirname (Sys.getcwd ())

let names =
  [
    "run-mutants.sh";
    "mutant-groups.sh";
    "run-mutant-share.sh";
    "join-mutant-reports.sh";
    "mutant-count.sh";
    "mutant-canary.sh";
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
  elif [ -n "${FAKE_OUTCOMES:-}" ]; then
    kind=selected
    if [ "$command" = test/run-mutants.sh ]; then
      kind=every
    fi
    jq -c --arg kind "$kind" --arg drop "${FAKE_DROP:-}" \
      --arg extra "${FAKE_EXTRA:-}" --rawfile outcomes "$FAKE_OUTCOMES" '
      ($outcomes | split("\n") | map(select(length > 0) | split(" "))
       | map({key: "\(.[0]) \(.[1]) \(.[2])", value: (.[3] | tonumber)})
       | from_entries) as $status
      | {results: ([.mutants[]
          | select($kind == "every" or "\(.loc.loc_start.pos_fname) \(.number)" != $drop)
          | {status: ($status["\($kind) \(.loc.loc_start.pos_fname) \(.number)"] // 0),
             mutant: .}]
          + (if $extra == "1" and $kind == "every"
             then [{status: 0, mutant: (.mutants[0] | .number = 99)}]
             else [] end)),
         skipped: []}' "$muts" >mutaml-report.json
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

let count_tests =
  [
    Alcotest.test_case "the count of a full pass is every mutant" `Quick
      (fun () ->
        in_project (fun root ->
            let ran = run root "mutant-count.sh" [] in
            status 0 ran.status;
            Alcotest.(check string) "the count" "11\n" ran.out));
    Alcotest.test_case
      "the count of the changed lines is the mutants that the runner tests"
      `Quick (fun () ->
        in_project (fun root ->
            let report = root / "report.json" in
            write report
              (Printf.sprintf
                 {|{"results":[{"status":0,"mutant":%s},{"status":0,"mutant":%s,"not_run":true},{"status":0,"mutant":%s,"not_run":false}],"skipped":[]}|}
                 (mutant "lib/a.ml" 0) (mutant "lib/a.ml" 1)
                 (mutant "lib/a.ml" 2));
            let ran =
              run
                ~env:(("FAKE_REPORT", report) :: calls_env root)
                root "mutant-count.sh" [ "-c"; "base" ]
            in
            status 0 ran.status;
            Alcotest.(check string) "the count" "2\n" ran.out;
            mentions "\n--changed-since\nbase\ntrue\n--\n" ("\n" ^ calls root)));
    Alcotest.test_case "a runner that fails stops the count" `Quick (fun () ->
        in_project (fun root ->
            let ran =
              run
                ~env:[ ("FAKE_STATUS", "1") ]
                root "mutant-count.sh" [ "-c"; "base" ]
            in
            status 1 ran.status));
    Alcotest.test_case "a runner that writes no report stops the count" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              run
                ~env:[ ("FAKE_NO_REPORT", "1") ]
                root "mutant-count.sh" [ "-c"; "base" ]
            in
            status 1 ran.status));
    Alcotest.test_case "a runner that skips a file stops the count" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              run
                ~env:[ ("FAKE_PRINT", "Skipping lib/x.muts: gone") ]
                root "mutant-count.sh" [ "-c"; "base" ]
            in
            status 1 ran.status;
            mentions "Skipping lib/x.muts" ran.err));
    Alcotest.test_case "the count needs a build" `Quick (fun () ->
        in_project (fun root ->
            remove (root / "_build");
            status 2 (run root "mutant-count.sh" []).status));
  ]

let outcomes root text =
  let path = root / "outcomes" in
  write path text;
  ("FAKE_OUTCOMES", path) :: calls_env root

let canary ?(env = []) root args =
  run ~env root "mutant-canary.sh" ([ "-s"; "2026" ] @ args)

let drawn ran =
  let rec named = function
    | line :: rest when String.starts_with ~prefix:"  " line ->
        String.trim line :: named rest
    | _ -> []
  in
  let rec after = function
    | "The canary tests these mutants with every test:" :: rest -> named rest
    | _ :: rest -> after rest
    | [] -> Alcotest.fail "the canary named no mutant"
  in
  after (lines ran.out)

let canary_tests =
  [
    Alcotest.test_case "the canary passes when the two tests agree" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:
                  (outcomes root
                     "every lib/a.ml 0 1\n\
                      selected lib/a.ml 0 1\n\
                      every lib/a.ml 1 124\n\
                      selected lib/a.ml 1 124\n")
                root
                [ "-n"; "3"; "lib/a.muts" ]
            in
            status 0 ran.status;
            mentions "The canary passed" ran.out));
    Alcotest.test_case
      "the canary fails when every test kills a mutant and its groups do not"
      `Quick (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:(outcomes root "every lib/a.ml 0 1\n")
                root
                [ "-n"; "3"; "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "lib/a.ml mutant 0\tkilled\tsurvived" ran.out));
    Alcotest.test_case
      "the canary fails when the groups kill a mutant and every test does not"
      `Quick (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:(outcomes root "selected lib/a.ml 2 124\n")
                root
                [ "-n"; "3"; "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "lib/a.ml mutant 2\tsurvived\tkilled" ran.out));
    Alcotest.test_case "the canary fails when a report lacks a mutant" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:(("FAKE_DROP", "lib/a.ml 1") :: outcomes root "")
                root
                [ "-n"; "3"; "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "lib/a.ml mutant 1\tsurvived\tmissing" ran.out));
    Alcotest.test_case "the canary fails when a report holds an extra mutant"
      `Quick (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:(("FAKE_EXTRA", "1") :: outcomes root "")
                root
                [ "-n"; "3"; "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "lib/a.ml mutant 99\tsurvived\tmissing" ran.out));
    Alcotest.test_case "the canary fails when the runner skips a file" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:
                  (("FAKE_PRINT", "Skipping lib/x.muts: gone")
                  :: outcomes root "")
                root
                [ "-n"; "1"; "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "skipped the mutants" ran.out));
    Alcotest.test_case "the canary fails when the runner fails" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:(("FAKE_STATUS", "1") :: outcomes root "")
                root [ "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "could not test its mutants" ran.out));
    Alcotest.test_case "the canary fails when the runner writes no report"
      `Quick (fun () ->
        in_project (fun root ->
            let ran =
              canary
                ~env:(("FAKE_NO_REPORT", "1") :: outcomes root "")
                root [ "lib/a.muts" ]
            in
            status 1 ran.status;
            mentions "could not test its mutants" ran.out));
    Alcotest.test_case
      "a file that the map does not name stops the canary before running" `Quick
      (fun () ->
        in_project (fun root ->
            write
              (root / "_build/.mutaml/default/lib/z.muts")
              (Printf.sprintf {|{"mutants":[%s]}|} (mutant "lib/z.ml" 0));
            let ran =
              canary ~env:(calls_env root) root [ "-n"; "1"; "lib/z.muts" ]
            in
            status 1 ran.status;
            mentions "names no test group for lib/z.muts" ran.out;
            Alcotest.(check bool)
              "the runner ran" false
              (Sys.file_exists (root / ".calls"))));
    Alcotest.test_case "the groups of a file give its test command" `Quick
      (fun () ->
        in_project (fun root ->
            let ran =
              canary ~env:(outcomes root "") root [ "-n"; "1"; "lib/a.muts" ]
            in
            status 0 ran.status;
            mentions "\ntest/run-mutants.sh test '^(alpha|mode)$'\n--\n"
              (calls root);
            mentions "\ntest/run-mutants.sh\n--\n" (calls root)));
    Alcotest.test_case "the canary draws as many different mutants as asked"
      `Quick (fun () ->
        in_project (fun root ->
            let ran =
              canary ~env:(outcomes root "") root
                [ "-n"; "4"; "lib/a.muts"; "lib/g.muts" ]
            in
            status 0 ran.status;
            Alcotest.(check int)
              "the mutants" 4
              (List.length (List.sort_uniq compare (drawn ran)))));
    Alcotest.test_case "the same number makes the same draw" `Quick (fun () ->
        in_project (fun root ->
            let draw () =
              drawn
                (canary ~env:(outcomes root "") root
                   [ "-n"; "2"; "lib/a.muts"; "lib/g.muts" ])
            in
            let first = draw () in
            Alcotest.(check (list string)) "the draw" first (draw ())));
    Alcotest.test_case "a draw larger than the mutants takes every mutant"
      `Quick (fun () ->
        in_project (fun root ->
            let ran =
              canary ~env:(outcomes root "") root [ "-n"; "9"; "lib/a.muts" ]
            in
            status 0 ran.status;
            Alcotest.(check (list string))
              "the mutants"
              [ "lib/a.muts\t0"; "lib/a.muts\t1"; "lib/a.muts\t2" ]
              (List.sort compare (drawn ran))));
    Alcotest.test_case "files without a mutant leave the canary nothing to test"
      `Quick (fun () ->
        in_project
          ~change:(fun project ->
            {
              project with
              mutants =
                List.map
                  (fun (file, count) ->
                    if file = "lib/a" then (file, 0) else (file, count))
                  project.mutants;
            })
          (fun root ->
            let ran = canary ~env:(outcomes root "") root [ "lib/a.muts" ] in
            status 0 ran.status;
            mentions "nothing to test" ran.out));
    Alcotest.test_case "a draw of no mutant is refused" `Quick (fun () ->
        in_project (fun root ->
            status 2 (canary root [ "-n"; "0"; "lib/a.muts" ]).status));
    Alcotest.test_case "a file that is not a mutation file is refused" `Quick
      (fun () ->
        in_project (fun root ->
            status 2 (canary root [ "lib/none.muts" ]).status));
  ]

let cargo_build_repo_root = Filename.dirname scripts

let fake_cargo =
  {|#!/bin/sh
set -eu
log=${FAKE_CARGO_LOG:-/dev/null}
sub=$1
shift
target=
pkg=
while [ "$#" -gt 0 ]; do
  case $1 in
    --target-dir) target=$2; shift 2 ;;
    -p) pkg=$2; shift 2 ;;
    --) shift; break ;;
    *) shift ;;
  esac
done
printf '%s target=%s pkg=%s cwd=%s\n' "$sub" "$target" "$pkg" "$(pwd -P)" >>"$log"
if [ -n "${FAKE_CARGO_SLEEP:-}" ] && [ "$sub" = "rustc" ]; then
  sleep "$FAKE_CARGO_SLEEP"
fi
if [ -n "${FAKE_CARGO_MUTATE_SRC:-}" ] && [ "$sub" = "rustc" ]; then
  printf '\n// mutated during build\n' >>src/lib.rs
fi
if [ "$sub" = "clean" ]; then
  if [ ! -f "$target/CACHEDIR.TAG" ]; then
    echo "error: missing CACHEDIR.TAG" >&2
    exit 101
  fi
  rm -f "$target"/release/lib*.a "$target"/release/crate.marker
  exit 0
fi
if [ "$sub" = "rustc" ]; then
  if [ ! -d "$target" ]; then
    mkdir -p "$target"
    printf 'Signature: 8a477f597d28d172789f06886806bc55\n' >"$target/CACHEDIR.TAG"
  fi
  mkdir -p "$target/release/deps"
  if [ ! -f "$target/release/deps/dep.rlib" ]; then
    printf 'dep-from:%s\n' "$(cat Cargo.lock 2>/dev/null || echo none)" >"$target/release/deps/dep.rlib"
  fi
  archive_name=${FAKE_ARCHIVE_NAME:-libsinter_bridge.a}
  if [ ! -f "$target/release/crate.marker" ] ||
      [ src/lib.rs -nt "$target/release/crate.marker" ] ||
      [ -n "${FAKE_CARGO_FLAG:-}" ]; then
    {
      printf 'src=%s\n' "$(cat src/lib.rs)"
      printf 'dep=%s\n' "$(cat "$target/release/deps/dep.rlib")"
      printf 'flag=%s\n' "${FAKE_CARGO_FLAG:-}"
    } >"$target/release/$archive_name"
    : >"$target/release/crate.marker"
  fi
  printf 'note: native-static-libs: -liconv -lSystem -lc -lm\n' >&2
  exit 0
fi
exit 1
|}

let fake_cmake = {|#!/bin/sh
exit 0
|}

let write_crate ?(pkg = "sinter-bridge") ?(lib = "sinter_bridge")
    ?(lock = "lock-v1\n") ?(toolchain = "channel = \"1.99.1\"\n")
    ?(src = "pub fn value() -> u32 { 1 }\n") dir =
  write (dir / "Cargo.toml")
    (Printf.sprintf "[package]\nname = \"%s\"\n\n[lib]\nname = \"%s\"\n" pkg lib);
  write (dir / "Cargo.lock") lock;
  write (dir / "rust-toolchain.toml") toolchain;
  write (dir / "src/lib.rs") src

let find_in_path name =
  let dirs =
    String.split_on_char ':'
      (Option.value (Sys.getenv_opt "PATH") ~default:"/usr/bin:/bin:/sbin")
  in
  List.find_map
    (fun dir ->
      let candidate = dir / name in
      if dir <> "" && Sys.file_exists candidate then Some candidate else None)
    dirs

let make_restricted_bin ~omit root dir_name =
  let bin = root / dir_name in
  make_dir bin;
  let tools =
    [
      "sh";
      "find";
      "sort";
      "awk";
      "sed";
      "tr";
      "grep";
      "cut";
      "mkdir";
      "rm";
      "mv";
      "cp";
      "cat";
      "touch";
      "ls";
      "basename";
      "dirname";
      "pwd";
      "uname";
      "readlink";
      "sha256sum";
      "shasum";
      "perl";
      "flock";
    ]
  in
  List.iter
    (fun name ->
      if not (List.mem name omit) then
        Option.iter
          (fun target -> Unix.symlink target (bin / name))
          (find_in_path name))
    tools;
  bin

let cargo_env ?(env = []) root =
  let path =
    (root / "fake") ^ ":"
    ^ Option.value (Sys.getenv_opt "PATH") ~default:"/usr/bin:/bin"
  in
  let excluded =
    [
      "PATH=";
      "HOME=";
      "CARGO_TARGET_DIR=";
      "XDG_CACHE_HOME=";
      "CARGO_BUILD_TARGET=";
      "FAKE_";
    ]
  in
  let inherited =
    Array.to_list (Unix.environment ())
    |> List.filter (fun binding ->
        not
          (List.exists
             (fun prefix -> String.starts_with ~prefix binding)
             excluded))
  in
  let defaults = [ ("HOME", root / "home") ] in
  let merged =
    List.filter (fun (k, _) -> not (List.mem_assoc k env)) defaults @ env
  in
  let path_binding =
    if List.mem_assoc "PATH" merged then [] else [ "PATH=" ^ path ]
  in
  Array.of_list
    (path_binding @ List.map (fun (k, v) -> k ^ "=" ^ v) merged @ inherited)

let run_cargo_script ?(env = []) root script args =
  (match List.rev args with
  | flags :: archive :: _ when List.length args >= 4 ->
      make_dir (Filename.dirname archive);
      make_dir (Filename.dirname flags)
  | _ -> ());
  let out_path = root / ".out" and err_path = root / ".err" in
  let open_output path =
    Unix.openfile path [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ] 0o644
  in
  let out = open_output out_path and err = open_output err_path in
  let argv =
    Array.of_list
      ("/bin/sh" :: "-c" :: {|cd "$0" && exec sh "$@"|} :: root :: script
     :: args)
  in
  let pid =
    Unix.create_process_env "/bin/sh" argv (cargo_env ~env root) Unix.stdin out
      err
  in
  Unix.close out;
  Unix.close err;
  let status =
    match snd (Unix.waitpid [] pid) with
    | Unix.WEXITED code -> code
    | Unix.WSIGNALED _ | Unix.WSTOPPED _ -> -1
  in
  { status; out = read out_path; err = read err_path }

let in_cargo_project f =
  let root = Filename.temp_dir "sinter-cargo-build" "" in
  Fun.protect
    ~finally:(fun () -> remove root)
    (fun () ->
      write ~mode:0o755
        (root / "lib/cargo-build.sh")
        (read (cargo_build_repo_root / "lib/cargo-build.sh"));
      write ~mode:0o755
        (root / "lib/bridge/build.sh")
        (read (cargo_build_repo_root / "lib/bridge/build.sh"));
      write ~mode:0o755 (root / "fake/cargo") fake_cargo;
      write ~mode:0o755 (root / "fake/cmake") fake_cmake;
      make_dir (root / "home");
      f root)

let trimmed s = String.trim s

let cargo_build_tests =
  [
    Alcotest.test_case
      "two checkouts with the same content get the same target directory" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            write_crate a;
            write_crate b;
            let env = [ ("CARGO_TARGET_DIR", root / "cache") ] in
            let r1 =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [ "--target-dir"; a ]
            in
            let r2 =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [ "--target-dir"; b ]
            in
            status 0 r1.status;
            status 0 r2.status;
            Alcotest.(check string)
              "same target" (trimmed r1.out) (trimmed r2.out)));
    Alcotest.test_case
      "an edit changes the target directory and top-level target does not"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            write_crate a;
            write_crate b;
            write (b / "target/debug/junk") "ignored";
            let env = [ ("CARGO_TARGET_DIR", root / "cache") ] in
            let dir_of p =
              let r =
                run_cargo_script ~env root "lib/bridge/build.sh"
                  [ "--target-dir"; p ]
              in
              status 0 r.status;
              trimmed r.out
            in
            let d_a = dir_of a in
            Alcotest.(check string) "top-level target ignored" d_a (dir_of b);
            write (b / "src/target/mod.rs") "pub fn nested() {}\n";
            Alcotest.(check bool)
              "nested src/target counted" true
              (d_a <> dir_of b)));
    Alcotest.test_case
      "a symbolic link to a directory inside the crate is rejected" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and outside = root / "outside" in
            write_crate a;
            write (outside / "extra.rs") "pub fn extra() {}\n";
            Unix.symlink outside (a / "linked");
            let env = [ ("CARGO_TARGET_DIR", root / "cache") ] in
            let r =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [ "--target-dir"; a ]
            in
            status 1 r.status;
            mentions "symbolic link to a directory" r.err));
    Alcotest.test_case
      "missing sha256sum and shasum fails without touching the parent folder"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and cache = root / "cache" in
            write_crate a;
            write (cache / "keepme/file") "stay\n";
            write (cache / "0123456789abcdef0123456789abcdef/last-used") "";
            let bin =
              make_restricted_bin ~omit:[ "sha256sum"; "shasum" ] root
                "bin-no-sha"
            in
            let env =
              [
                ("PATH", (root / "fake") ^ ":" ^ bin);
                ("CARGO_TARGET_DIR", cache);
              ]
            in
            let r_dir =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [ "--target-dir"; a ]
            in
            status 1 r_dir.status;
            mentions "sha256sum or shasum" r_dir.err;
            let r_build =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [
                  a;
                  "fallback";
                  root / "out/libsinter_bridge.a";
                  root / "out/link_flags.sexp";
                ]
            in
            status 1 r_build.status;
            mentions "sha256sum or shasum" r_build.err;
            Alcotest.(check bool)
              "unrelated folder kept" true
              (Sys.file_exists (cache / "keepme/file"));
            Alcotest.(check bool)
              "existing build folder kept" true
              (Sys.file_exists
                 (cache / "0123456789abcdef0123456789abcdef/last-used"))));
    Alcotest.test_case "a failing sha256sum exits with an error message" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and cache = root / "cache" in
            write_crate a;
            let bin =
              make_restricted_bin ~omit:[ "sha256sum"; "shasum" ] root
                "bin-bad-sha"
            in
            write ~mode:0o755 (bin / "sha256sum") "#!/bin/sh\nexit 1\n";
            let env =
              [
                ("PATH", (root / "fake") ^ ":" ^ bin);
                ("CARGO_TARGET_DIR", cache);
              ]
            in
            let r =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [ "--target-dir"; a ]
            in
            status 1 r.status;
            mentions "sha256sum failed" r.err));
    Alcotest.test_case "an empty build parent directory or / is refused" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" in
            write_crate a;
            let r_root =
              run_cargo_script
                ~env:[ ("CARGO_TARGET_DIR", "/") ]
                root "lib/bridge/build.sh" [ "--target-dir"; a ]
            in
            status 1 r_root.status;
            mentions "Refusing to use /" r_root.err;
            let r_empty =
              run_cargo_script
                ~env:[ ("HOME", "") ]
                root "lib/bridge/build.sh"
                [
                  a;
                  "";
                  root / "out/libsinter_bridge.a";
                  root / "out/link_flags.sexp";
                ]
            in
            status 1 r_empty.status;
            mentions "build directory is empty" r_empty.err));
    Alcotest.test_case "missing perl and flock fails with an error message"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and cache = root / "cache" in
            write_crate a;
            let bin =
              make_restricted_bin ~omit:[ "perl"; "flock" ] root "bin-no-lock"
            in
            let env =
              [
                ("PATH", (root / "fake") ^ ":" ^ bin);
                ("CARGO_TARGET_DIR", cache);
              ]
            in
            let r =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [
                  a;
                  "fallback";
                  root / "out/libsinter_bridge.a";
                  root / "out/link_flags.sexp";
                ]
            in
            status 1 r.status;
            mentions "perl or flock" r.err));
    Alcotest.test_case
      "CARGO_TARGET_DIR, XDG_CACHE_HOME, and HOME choose the parent directory"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" in
            write_crate a;
            let dir_with env =
              let r =
                run_cargo_script ~env root "lib/bridge/build.sh"
                  [ "--target-dir"; a ]
              in
              status 0 r.status;
              trimmed r.out
            in
            let d_ctd =
              dir_with
                [
                  ("CARGO_TARGET_DIR", root / "explicit");
                  ("XDG_CACHE_HOME", root / "xdg");
                ]
            in
            let d_xdg = dir_with [ ("XDG_CACHE_HOME", root / "xdg") ] in
            let d_home = dir_with [] in
            Alcotest.(check bool)
              "CARGO_TARGET_DIR wins" true
              (String.starts_with ~prefix:(root / "explicit/") d_ctd);
            Alcotest.(check bool)
              "XDG_CACHE_HOME second" true
              (String.starts_with
                 ~prefix:(root / "xdg/sinter-bridge-build/")
                 d_xdg);
            Alcotest.(check bool)
              "HOME third" true
              (String.starts_with
                 ~prefix:(root / "home/.cache/sinter-bridge-build/")
                 d_home)));
    Alcotest.test_case
      "a second checkout with identical content shares the folder and runs \
       cargo"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            let cache = root / "cache" and log = root / "cargo.log" in
            write_crate a;
            write_crate b;
            let env extra =
              [ ("CARGO_TARGET_DIR", cache); ("FAKE_CARGO_LOG", log) ] @ extra
            in
            let r1 =
              run_cargo_script ~env:(env []) root "lib/bridge/build.sh"
                [
                  a;
                  "fallback";
                  root / "out-a/libsinter_bridge.a";
                  root / "out-a/link_flags.sexp";
                ]
            in
            status 0 r1.status;
            let r2 =
              run_cargo_script
                ~env:(env [ ("FAKE_CARGO_FLAG", "cfg-marker") ])
                root "lib/bridge/build.sh"
                [
                  b;
                  "fallback";
                  root / "out-b/libsinter_bridge.a";
                  root / "out-b/link_flags.sexp";
                ]
            in
            status 0 r2.status;
            Alcotest.(check int)
              "cargo ran twice" 2
              (List.length (lines (read log)));
            Alcotest.(check bool)
              "second build sees new flag through cargo" true
              (contains ~sub:"flag=cfg-marker"
                 (read (root / "out-b/libsinter_bridge.a")));
            Alcotest.(check string)
              "flags filtered" "(-liconv -lm )\n"
              (read (root / "out-b/link_flags.sexp"))));
    Alcotest.test_case
      "an older checkout of other content gets its own library from a seeded \
       folder"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            let cache = root / "cache" and log = root / "cargo.log" in
            write_crate ~src:"MARKER_A\n" a;
            write_crate ~src:"MARKER_B\n" b;
            let future = Unix.gettimeofday () +. 120.0 in
            Unix.utimes (b / "src/lib.rs") future future;
            let env =
              [ ("CARGO_TARGET_DIR", cache); ("FAKE_CARGO_LOG", log) ]
            in
            let rb =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [
                  b;
                  "fallback";
                  root / "out-b/libsinter_bridge.a";
                  root / "out-b/link_flags.sexp";
                ]
            in
            status 0 rb.status;
            let ra =
              run_cargo_script ~env root "lib/bridge/build.sh"
                [
                  a;
                  "fallback";
                  root / "out-a/libsinter_bridge.a";
                  root / "out-a/link_flags.sexp";
                ]
            in
            status 0 ra.status;
            let arch_a = read (root / "out-a/libsinter_bridge.a") in
            let arch_b = read (root / "out-b/libsinter_bridge.a") in
            Alcotest.(check bool)
              "B has MARKER_B" true
              (contains ~sub:"MARKER_B" arch_b);
            Alcotest.(check bool)
              "A has MARKER_A" true
              (contains ~sub:"MARKER_A" arch_a);
            Alcotest.(check bool)
              "A does not have MARKER_B" false
              (contains ~sub:"MARKER_B" arch_a);
            let calls = lines (read log) in
            Alcotest.(check bool)
              "clean ran on seeded folder" true
              (List.exists
                 (fun line ->
                   contains ~sub:"clean " line
                   && contains ~sub:"pkg=sinter-bridge" line)
                 calls)));
    Alcotest.test_case
      "a newer checkout of other content gets its own library from a seeded \
       folder"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            let cache = root / "cache" and log = root / "cargo.log" in
            write_crate ~src:"MARKER_A\n" a;
            write_crate ~src:"MARKER_B\n" b;
            let env =
              [ ("CARGO_TARGET_DIR", cache); ("FAKE_CARGO_LOG", log) ]
            in
            status 0
              (run_cargo_script ~env root "lib/bridge/build.sh"
                 [
                   a;
                   "fallback";
                   root / "out-a/libsinter_bridge.a";
                   root / "out-a/link_flags.sexp";
                 ])
                .status;
            status 0
              (run_cargo_script ~env root "lib/bridge/build.sh"
                 [
                   b;
                   "fallback";
                   root / "out-b/libsinter_bridge.a";
                   root / "out-b/link_flags.sexp";
                 ])
                .status;
            Alcotest.(check bool)
              "A has MARKER_A" true
              (contains ~sub:"MARKER_A"
                 (read (root / "out-a/libsinter_bridge.a")));
            Alcotest.(check bool)
              "B has MARKER_B" true
              (contains ~sub:"MARKER_B"
                 (read (root / "out-b/libsinter_bridge.a")));
            Alcotest.(check bool)
              "clean ran on seeded folder" true
              (contains ~sub:"clean " (read log))));
    Alcotest.test_case
      "a Cargo.lock change seeds from the newest folder of the same package"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            let cache = root / "cache" and log = root / "cargo.log" in
            write_crate ~lock:"lock-v1\n" ~src:"A\n" a;
            write_crate ~lock:"lock-v2\n" ~src:"B\n" b;
            let env =
              [ ("CARGO_TARGET_DIR", cache); ("FAKE_CARGO_LOG", log) ]
            in
            status 0
              (run_cargo_script ~env root "lib/bridge/build.sh"
                 [
                   a;
                   "fallback";
                   root / "out-a/libsinter_bridge.a";
                   root / "out-a/link_flags.sexp";
                 ])
                .status;
            status 0
              (run_cargo_script ~env root "lib/bridge/build.sh"
                 [
                   b;
                   "fallback";
                   root / "out-b/libsinter_bridge.a";
                   root / "out-b/link_flags.sexp";
                 ])
                .status;
            Alcotest.(check bool)
              "B seeded dependencies from A" true
              (contains ~sub:"dep=dep-from:lock-v1"
                 (read (root / "out-b/libsinter_bridge.a")));
            Alcotest.(check bool)
              "clean ran on seeded folder" true
              (contains ~sub:"clean " (read log))));
    Alcotest.test_case
      "a crate edit during a build fails and discards the target folder" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" in
            let cache = root / "cache" in
            write_crate a;
            let env = [ ("CARGO_TARGET_DIR", cache) ] in
            let target =
              let r =
                run_cargo_script ~env root "lib/bridge/build.sh"
                  [ "--target-dir"; a ]
              in
              status 0 r.status;
              trimmed r.out
            in
            let build =
              run_cargo_script
                ~env:
                  [
                    ("CARGO_TARGET_DIR", cache); ("FAKE_CARGO_MUTATE_SRC", "1");
                  ]
                root "lib/bridge/build.sh"
                [
                  a;
                  "fallback";
                  root / "out/libsinter_bridge.a";
                  root / "out/link_flags.sexp";
                ]
            in
            status 1 build.status;
            mentions "changed during the build" build.err;
            Alcotest.(check bool)
              "contaminated target removed" false (Sys.file_exists target)));
    Alcotest.test_case
      "a leftover building mark forces a package clean before cargo runs" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" in
            let cache = root / "cache" in
            write_crate ~src:"MARKER_A\n" a;
            let env = [ ("CARGO_TARGET_DIR", cache) ] in
            status 0
              (run_cargo_script ~env root "lib/bridge/build.sh"
                 [
                   a;
                   "fallback";
                   root / "out1/libsinter_bridge.a";
                   root / "out1/link_flags.sexp";
                 ])
                .status;
            let target =
              let r =
                run_cargo_script ~env root "lib/bridge/build.sh"
                  [ "--target-dir"; a ]
              in
              status 0 r.status;
              trimmed r.out
            in
            let key = Filename.basename target in
            write (target / "release/libsinter_bridge.a") "STALE_OTHER\n";
            let future = Unix.gettimeofday () +. 120.0 in
            Unix.utimes (target / "release/crate.marker") future future;
            let building = cache / ".locks" / (key ^ ".building") in
            write building "";
            status 0
              (run_cargo_script ~env root "lib/bridge/build.sh"
                 [
                   a;
                   "fallback";
                   root / "out2/libsinter_bridge.a";
                   root / "out2/link_flags.sexp";
                 ])
                .status;
            let arch = read (root / "out2/libsinter_bridge.a") in
            Alcotest.(check bool)
              "rebuilt with MARKER_A" true
              (contains ~sub:"MARKER_A" arch);
            Alcotest.(check bool)
              "stale archive gone" false
              (contains ~sub:"STALE_OTHER" arch);
            Alcotest.(check bool)
              "building mark removed" false (Sys.file_exists building)));
    Alcotest.test_case
      "pruning removes marked folders unused for 7 days and spares recent, \
       locked, unrelated, and symlink entries"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" in
            let cache = root / "cache" in
            write_crate a;
            let now = Unix.gettimeofday () in
            let eight_days = now -. (8.0 *. 86400.0) in
            let six_days = now -. (6.0 *. 86400.0) in
            let stale_dir = cache / "0123456789abcdef0123456789abcdef" in
            let legacy_dir = cache / "fedcba9876543210" in
            let killed_dir = cache / "11111111111111111111111111111111" in
            let unrelated_dir = cache / "22222222222222222222222222222222" in
            let link_target = root / "external-target" in
            let hex_link = cache / "33333333333333333333333333333333" in
            let recent_dir = cache / "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" in
            let locked_dir = cache / "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" in
            let orphan_stage =
              cache / ".stage-cccccccccccccccccccccccccccccccc-99999"
            in
            let active_stage =
              cache / ".stage-dddddddddddddddddddddddddddddddd-99998"
            in
            write (stale_dir / "last-used") "";
            Unix.utimes (stale_dir / "last-used") eight_days eight_days;
            write (legacy_dir / "checkout") "/gone\n";
            Unix.utimes (legacy_dir / "checkout") eight_days eight_days;
            write
              (killed_dir / "CACHEDIR.TAG")
              "Signature: 8a477f597d28d172789f06886806bc55\n";
            Unix.utimes (killed_dir / "CACHEDIR.TAG") eight_days eight_days;
            write (unrelated_dir / "notes.txt") "keep me\n";
            Unix.utimes (unrelated_dir / "notes.txt") eight_days eight_days;
            Unix.utimes unrelated_dir eight_days eight_days;
            write (link_target / "last-used") "";
            Unix.utimes (link_target / "last-used") eight_days eight_days;
            Unix.symlink link_target hex_link;
            write (recent_dir / "last-used") "";
            Unix.utimes (recent_dir / "last-used") six_days six_days;
            write (locked_dir / "last-used") "";
            Unix.utimes (locked_dir / "last-used") eight_days eight_days;
            write (orphan_stage / "junk") "";
            write (active_stage / "junk") "";
            make_dir (cache / ".locks");
            let hold_lock lock_path flag_path =
              let holder =
                {|use Fcntl qw(:flock);
open(my $fh, "+>>", $ARGV[0]) or die $!;
flock($fh, LOCK_SH) or die $!;
open(my $f, ">", $ARGV[1]) or die $!;
close($f);
sleep 30;
|}
              in
              let pid =
                Unix.create_process "perl"
                  [| "perl"; "-e"; holder; lock_path; flag_path |]
                  Unix.stdin Unix.stdout Unix.stderr
              in
              let rec wait_ready n =
                if Sys.file_exists flag_path then ()
                else if n = 0 then failwith "lock holder did not start"
                else (
                  Unix.sleepf 0.02;
                  wait_ready (n - 1))
              in
              wait_ready 100;
              pid
            in
            let p1 =
              hold_lock
                (cache / ".locks/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.lock")
                (root / ".lock1")
            in
            let p2 =
              hold_lock
                (cache / ".locks/dddddddddddddddddddddddddddddddd.lock")
                (root / ".lock2")
            in
            let kill_holder pid =
              (try Unix.kill pid Sys.sigkill with _ -> ());
              ignore (Unix.waitpid [] pid)
            in
            Fun.protect
              ~finally:(fun () ->
                kill_holder p1;
                kill_holder p2)
              (fun () ->
                let env = [ ("CARGO_TARGET_DIR", cache) ] in
                let r =
                  run_cargo_script ~env root "lib/bridge/build.sh"
                    [
                      a;
                      "fallback";
                      root / "out/libsinter_bridge.a";
                      root / "out/link_flags.sexp";
                    ]
                in
                status 0 r.status;
                Alcotest.(check bool)
                  "stale removed" false
                  (Sys.file_exists stale_dir);
                Alcotest.(check bool)
                  "legacy stale removed" false
                  (Sys.file_exists legacy_dir);
                Alcotest.(check bool)
                  "killed build with CACHEDIR.TAG removed" false
                  (Sys.file_exists killed_dir);
                Alcotest.(check bool)
                  "unrelated hex folder kept" true
                  (Sys.file_exists (unrelated_dir / "notes.txt"));
                Alcotest.(check bool)
                  "hex symlink kept" true
                  (match Unix.lstat hex_link with
                  | { Unix.st_kind = Unix.S_LNK; _ } -> true
                  | _ -> false
                  | exception Unix.Unix_error _ -> false);
                Alcotest.(check bool)
                  "symlink target kept" true
                  (Sys.file_exists (link_target / "last-used"));
                Alcotest.(check bool)
                  "recent kept" true
                  (Sys.file_exists recent_dir);
                Alcotest.(check bool)
                  "locked stale kept" true
                  (Sys.file_exists locked_dir);
                Alcotest.(check bool)
                  "orphan stage removed" false
                  (Sys.file_exists orphan_stage);
                Alcotest.(check bool)
                  "locked stage kept" true
                  (Sys.file_exists active_stage));
            let env = [ ("CARGO_TARGET_DIR", cache) ] in
            status 0
              (run_cargo_script ~env root "lib/bridge/build.sh"
                 [
                   a;
                   "fallback";
                   root / "out2/libsinter_bridge.a";
                   root / "out2/link_flags.sexp";
                 ])
                .status;
            Alcotest.(check bool)
              "unlocked stale removed" false
              (Sys.file_exists locked_dir);
            Alcotest.(check bool)
              "unlocked stage removed" false
              (Sys.file_exists active_stage)));
    Alcotest.test_case
      "concurrent builds of identical content serialize cleanly" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            let cache = root / "cache" and log = root / "cargo.log" in
            write_crate ~src:"CONCURRENT_SAME\n" a;
            write_crate ~src:"CONCURRENT_SAME\n" b;
            let env =
              cargo_env
                ~env:
                  [
                    ("CARGO_TARGET_DIR", cache);
                    ("FAKE_CARGO_LOG", log);
                    ("FAKE_CARGO_SLEEP", "0.3");
                  ]
                root
            in
            let spawn crate out_dir =
              make_dir out_dir;
              let out =
                Unix.openfile (out_dir / "stdout")
                  [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ]
                  0o644
              in
              let err =
                Unix.openfile (out_dir / "stderr")
                  [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ]
                  0o644
              in
              let argv =
                Array.of_list
                  [
                    "/bin/sh";
                    "-c";
                    {|cd "$0" && exec sh "$@"|};
                    root;
                    "lib/bridge/build.sh";
                    crate;
                    "fallback";
                    out_dir / "libsinter_bridge.a";
                    out_dir / "link_flags.sexp";
                  ]
              in
              let pid =
                Unix.create_process_env "/bin/sh" argv env Unix.stdin out err
              in
              Unix.close out;
              Unix.close err;
              pid
            in
            let p1 = spawn a (root / "out-1") in
            let p2 = spawn b (root / "out-2") in
            let wait_ok pid =
              match snd (Unix.waitpid [] pid) with
              | Unix.WEXITED 0 -> ()
              | _ -> Alcotest.fail "concurrent build failed"
            in
            wait_ok p1;
            wait_ok p2;
            Alcotest.(check bool)
              "first got content" true
              (contains ~sub:"CONCURRENT_SAME"
                 (read (root / "out-1/libsinter_bridge.a")));
            Alcotest.(check bool)
              "second got content" true
              (contains ~sub:"CONCURRENT_SAME"
                 (read (root / "out-2/libsinter_bridge.a")))));
    Alcotest.test_case
      "concurrent builds of different content seed and build without \
       interference"
      `Quick (fun () ->
        in_cargo_project (fun root ->
            let base_c = root / "co-base/bridge" in
            let a = root / "co-a/bridge" and b = root / "co-b/bridge" in
            let cache = root / "cache" in
            write_crate ~src:"BASE\n" base_c;
            write_crate ~src:"DIFF_A\n" a;
            write_crate ~src:"DIFF_B\n" b;
            status 0
              (run_cargo_script
                 ~env:[ ("CARGO_TARGET_DIR", cache) ]
                 root "lib/bridge/build.sh"
                 [
                   base_c;
                   "fallback";
                   root / "out-base/libsinter_bridge.a";
                   root / "out-base/link_flags.sexp";
                 ])
                .status;
            let env =
              cargo_env
                ~env:
                  [ ("CARGO_TARGET_DIR", cache); ("FAKE_CARGO_SLEEP", "0.2") ]
                root
            in
            let spawn crate out_dir =
              make_dir out_dir;
              let out =
                Unix.openfile (out_dir / "stdout")
                  [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ]
                  0o644
              in
              let err =
                Unix.openfile (out_dir / "stderr")
                  [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ]
                  0o644
              in
              let argv =
                Array.of_list
                  [
                    "/bin/sh";
                    "-c";
                    {|cd "$0" && exec sh "$@"|};
                    root;
                    "lib/bridge/build.sh";
                    crate;
                    "fallback";
                    out_dir / "libsinter_bridge.a";
                    out_dir / "link_flags.sexp";
                  ]
              in
              let pid =
                Unix.create_process_env "/bin/sh" argv env Unix.stdin out err
              in
              Unix.close out;
              Unix.close err;
              pid
            in
            let p1 = spawn a (root / "out-a") in
            let p2 = spawn b (root / "out-b") in
            let wait_ok pid =
              match snd (Unix.waitpid [] pid) with
              | Unix.WEXITED 0 -> ()
              | _ -> Alcotest.fail "concurrent build failed"
            in
            wait_ok p1;
            wait_ok p2;
            Alcotest.(check bool)
              "A got DIFF_A" true
              (contains ~sub:"DIFF_A"
                 (read (root / "out-a/libsinter_bridge.a")));
            Alcotest.(check bool)
              "B got DIFF_B" true
              (contains ~sub:"DIFF_B"
                 (read (root / "out-b/libsinter_bridge.a")))));
    Alcotest.test_case
      "a second crate shares the parent folder without cross-seeding" `Quick
      (fun () ->
        in_cargo_project (fun root ->
            let bridge = root / "bridge" and wasm = root / "wasm_engine" in
            let log = root / "cargo.log" in
            write_crate ~lock:"bridge-lock\n" ~src:"BRIDGE\n" bridge;
            write_crate ~pkg:"sinter-wasm-engine" ~lib:"sinter_wasm_engine"
              ~lock:"wasm-lock\n" ~src:"WASM_ENGINE\n" wasm;
            let env extra =
              [ ("XDG_CACHE_HOME", root / "xdg"); ("FAKE_CARGO_LOG", log) ]
              @ extra
            in
            status 0
              (run_cargo_script ~env:(env []) root "lib/bridge/build.sh"
                 [
                   bridge;
                   "fallback";
                   root / "out-bridge/libsinter_bridge.a";
                   root / "out-bridge/link_flags.sexp";
                 ])
                .status;
            let dir =
              run_cargo_script ~env:(env []) root "lib/cargo-build.sh"
                [ "--target-dir"; wasm ]
            in
            status 0 dir.status;
            Alcotest.(check bool)
              "uses shared sinter-bridge-build parent" true
              (String.starts_with
                 ~prefix:(root / "xdg/sinter-bridge-build/")
                 (trimmed dir.out));
            let build =
              run_cargo_script
                ~env:(env [ ("FAKE_ARCHIVE_NAME", "libsinter_wasm_engine.a") ])
                root "lib/cargo-build.sh"
                [
                  wasm;
                  "fallback";
                  root / "out-wasm/libsinter_wasm_engine.a";
                  root / "out-wasm/link_flags.sexp";
                ]
            in
            status 0 build.status;
            let arch = read (root / "out-wasm/libsinter_wasm_engine.a") in
            Alcotest.(check bool)
              "built wasm engine archive" true
              (contains ~sub:"WASM_ENGINE" arch);
            Alcotest.(check bool)
              "did not cross-seed bridge deps" true
              (contains ~sub:"dep=dep-from:wasm-lock" arch);
            Alcotest.(check bool)
              "clean did not run without matching package seed" false
              (contains ~sub:"clean " (read log))));
  ]

let () =
  Alcotest.run "scripts"
    [
      ("mutant groups", groups_tests);
      ("run mutants", run_mutants_tests);
      ("mutant share", share_tests);
      ("mutant count", count_tests);
      ("mutant canary", canary_tests);
      ("cargo build", cargo_build_tests);
    ]
