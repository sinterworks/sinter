(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Config = Sinter_git_config
module Branch_name = Sinter_branch_names.Branch_name
module Ref_commit = Sinter_git_model.Ref_commit
module Default_branch = Sinter_git_model.Default_branch
module Text = Sinter_text.Text

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f

let show_value = function
  | None -> "<no =>"
  | Some bytes -> Printf.sprintf "%S" bytes

let show_values values =
  "[" ^ String.concat "; " (List.map show_value values) ^ "]"

let key text =
  match (String.index_opt text '.', String.rindex_opt text '.') with
  | Some first, Some last when first < last ->
      Config.key ~section:(String.sub text 0 first)
        ~subsection:(String.sub text (first + 1) (last - first - 1))
        (String.sub text (last + 1) (String.length text - last - 1))
  | Some first, _ ->
      Config.key ~section:(String.sub text 0 first)
        (String.sub text (first + 1) (String.length text - first - 1))
  | None, _ -> Alcotest.failf "not a key: %s" text

let error_name = function
  | Config.Syntax { pathname; line } ->
      Printf.sprintf "syntax %s:%d" pathname line
  | Config.Unreadable_file pathname -> "unreadable " ^ pathname
  | Config.Environment name -> "environment " ^ name
  | Config.Unread_pathname { pathname; value } ->
      Printf.sprintf "unread pathname %s %s"
        (Option.value pathname ~default:"<environment>")
        (show_value value)
  | Config.Relative_without_file value ->
      "relative without file " ^ show_value value
  | Config.Not_a_boolean _ -> "not a boolean"
  | Config.Include_cycle pathname -> "include cycle " ^ pathname
  | Config.Remote_url_in_conditional_include pathname ->
      "remote url in conditional include " ^ pathname
  | Config.Remote_url_without_value -> "remote url without value"
  | Config.Limit_exceeded -> "limit exceeded"

type world = {
  files : (string * Config.file) list;
  env : (string * string) list;
}

let content ?identity text = Config.Content { content = text; identity }
let git_folder = "/r/.git"
let config_path = git_folder ^ "/config"

let run_with ?limits ?(git_directories = [ git_folder ]) ?branch ?working_tree
    world =
  let limits =
    Option.value limits
      ~default:{ Config.max_files = 1_000; max_values = 100_000 }
  in
  let reads = ref [] in
  let read pathname =
    reads := pathname :: !reads;
    match List.assoc_opt pathname world.files with
    | Some file -> file
    | None -> Config.No_file
  in
  let environment name = List.assoc_opt name world.env in
  let result =
    match working_tree with
    | None ->
        Config.of_repository ~limits ~environment ~read ~git_directories ~branch
          git_folder
    | Some working_tree_folder ->
        Config.of_working_tree ~limits ~environment ~read ~git_folder
          ~git_directories ~branch working_tree_folder
  in
  (result, List.rev !reads)

let configuration_of ?git_directories ?branch ?working_tree world =
  match fst (run_with ?git_directories ?branch ?working_tree world) with
  | Ok configuration -> configuration
  | Error error -> Alcotest.failf "the configuration: %s" (error_name error)

let configuration = configuration_of

let check_values name expected configuration text =
  Alcotest.(check string)
    name (show_values expected)
    (show_values (Config.values configuration (key text)))

let check_error name expected world =
  Alcotest.(check string)
    name expected
    (match fst (run_with world) with
    | Ok _ -> "no error"
    | Error error -> error_name error)

let only_config text = { files = [ (config_path, content text) ]; env = [] }

let parsed text =
  match Config.parse text with
  | Ok settings -> settings
  | Error { line } -> Alcotest.failf "syntax error at line %d of %S" line text

let check_parse name expected text =
  let settings = parsed text in
  Alcotest.(check int)
    (name ^ ": the number") (List.length expected) (List.length settings);
  List.iter2
    (fun (k, v) (key', value) ->
      Alcotest.(check bool)
        (name ^ ": the key " ^ k)
        true
        (Config.equal_key (key k) key');
      Alcotest.(check string)
        (name ^ ": the value of " ^ k)
        (show_value v) (show_value value))
    expected settings

let check_syntax_error name line text =
  Alcotest.(check string)
    name
    (Printf.sprintf "line %d" line)
    (match Config.parse text with
    | Ok _ -> "no error"
    | Error { line } -> Printf.sprintf "line %d" line)

let key_tests =
  [
    case "a key does not depend on the case of its section and its name"
      (fun () ->
        Alcotest.(check bool)
          "section" true
          (Config.equal_key
             (Config.key ~section:"Core" "FileMode")
             (Config.key ~section:"core" "filemode"));
        Alcotest.(check bool)
          "subsection" false
          (Config.equal_key
             (Config.key ~section:"branch" ~subsection:"Main" "remote")
             (Config.key ~section:"branch" ~subsection:"main" "remote"));
        Alcotest.(check bool)
          "a section with a dot" true
          (Config.equal_key
             (Config.key ~section:"Branch.main" "remote")
             (Config.key ~section:"branch" ~subsection:"main" "remote"));
        Alcotest.(check bool)
          "another name" false
          (Config.equal_key
             (Config.key ~section:"core" "a")
             (Config.key ~section:"core" "b")));
  ]

let syntax_tests =
  [
    case "sections, subsections, and the old form of a subsection" (fun () ->
        check_parse "sections"
          [
            ("core.filemode", Some "false");
            ("branch.Main.remote", Some "up");
            ("branch.main.merge", Some "refs/heads/main");
            ("a.b.c.d", Some "x");
          ]
          "[core]\n\
           \tfilemode = false\n\
           [branch \"Main\"]\n\
           remote = up\n\
           [branch.MAIN]\n\
           merge = refs/heads/main\n\
           [a.b \"c\"]\n\
           d = x\n");
    case "whitespace around a value goes, and whitespace inside it stays"
      (fun () ->
        check_parse "whitespace"
          [
            ("s.a", Some "x  \t y");
            ("s.b", Some "");
            ("s.c", None);
            ("s.d", Some "1");
          ]
          "[s]\n  a  =  x  \t y \t\nb =\n\tc\nd=1");
    case "separate runs of whitespace inside a value each stay" (fun () ->
        check_parse "runs"
          [ ("s.a", Some "x y  z"); ("s.b", Some "x") ]
          "[s]\na = x y  z\nb = \\\n   x\n");
    case "a comment after a name gives the name with no =" (fun () ->
        check_parse "comments"
          [ ("s.a", None); ("s.b", None); ("s.c", Some "1") ]
          "[s]\na ; c = 2\nb # d = 3\nc = 1\n");
    case "comments end a line outside double quotes" (fun () ->
        check_parse "comments"
          [ ("s.a", Some "x"); ("s.b", Some "y # z ; w"); ("s.c", Some "v") ]
          "# a comment\n\
           ; another\n\
           [s] ; here\n\
           a = x # c\n\
           b = \"y # z ; w\"\n\n\
           c = v;c\n");
    case "double quotes keep the whitespace between them" (fun () ->
        check_parse "quotes"
          [ ("s.a", Some " x "); ("s.b", Some "x y z"); ("s.c", Some "") ]
          "[s]\na = \" x \"\nb = x\" y \"z\nc = \"\"\n");
    case "the escapes give their bytes" (fun () ->
        check_parse "escapes"
          [ ("s.a", Some "q\"b\\n\nt\tb\b") ]
          "[s]\na = q\\\"b\\\\n\\nt\\tb\\b\n");
    case "a backslash at the end of a line joins it to the next" (fun () ->
        check_parse "joined"
          [ ("s.a", Some "xy"); ("s.b", Some "z") ]
          "[s]\na = x\\\ny\nb = z\n");
    case "a setting can follow a header on its line" (fun () ->
        check_parse "after a header"
          [ ("s.a", Some "1"); ("t.u.b", Some "2") ]
          "[s] a = 1\n[t \"u\"] b = 2\n");
    case "a subsection keeps its bytes, and a backslash takes the next byte"
      (fun () ->
        check_parse "subsection"
          [
            ("r.a\"b.x", Some "1");
            ("r.atb.y", Some "2");
            ("r.a b\xff.z", Some "3");
          ]
          "[r \"a\\\"b\"]\n\
           x = 1\n\
           [r \"a\\tb\"]\n\
           y = 2\n\
           [r \"a b\xff\"]\n\
           z = 3\n");
    case "the content is not in the syntax at the first bad line" (fun () ->
        List.iter
          (fun (text, line) ->
            check_syntax_error (Printf.sprintf "%S" text) line text)
          [
            ("a = 1\n", 1);
            ("[s]\na = \"x\n", 2);
            ("[s]\na = x\\q\n", 2);
            ("[s]\na = x\000\n", 2);
            ("[s]\na = x\\", 2);
            ("[s]\n1a = x\n", 2);
            ("[s]\na_b = x\n", 2);
            ("[s\n", 1);
            ("[s_t]\n", 1);
            ("[]\n", 1);
            ("[s]\n\n[t \"x\ny\"]\n", 3);
            ("[s]\n= x\n", 2);
            ("[s \"x\"y]\n", 1);
            ("[s \"x\" ]\n", 1);
            ("[s \"x\"", 1);
            ("[s x]\n", 1);
            ("[s xb\"]\n", 1);
            ("[s \"x", 1);
            ("[s \"x\\", 1);
            ("[s \"x\\\n\"]", 1);
            ("[s]\na = x\\\ny\n1 = z\n", 4);
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A section header with an empty section name and a subsection must give
       the settings of git 2.54.0: `[.a]`, `[ "a"]`, and `[\t"a"]` give `.a.b`;
       `[ ""]` and `[.]` give `..b`; `[]`, `["a"]`, `[ ]`, and `[ "a" ]` are
       errors. *)
    case "an empty section with a subsection is a section" (fun () ->
        check_parse "headers"
          [
            (".a.b", Some "1");
            (".a.b", Some "2");
            (".a.b", Some "3");
            ("..b", Some "4");
            ("..b", Some "5");
            (".A.b", Some "6");
            (".a.b.b", Some "7");
            (".a.b", Some "8");
          ]
          "[.a]\n\
           b = 1\n\
           [ \"a\"]\n\
           b = 2\n\
           [\t\"a\"]\n\
           b = 3\n\
           [ \"\"]\n\
           b = 4\n\
           [.]\n\
           b = 5\n\
           [ \"A\"]\n\
           b = 6\n\
           [.a \"b\"]\n\
           b = 7\n\
           [.A]\n\
           b = 8\n";
        List.iter
          (fun text -> check_syntax_error (Printf.sprintf "%S" text) 1 text)
          [ "[]\n"; "[\"a\"]\n"; "[ ]\n"; "[ \"a\" ]\n" ]);
    property
      ~name:"a file of settings in quotes gives back its settings in order"
      ~print:(fun settings ->
        String.concat "; "
          (List.map
             (fun (s, sub, n, v) -> Printf.sprintf "%S %S %S %S" s sub n v)
             settings))
      Gen.(
        list_size (int_range 0 6)
          (quad
             (string_size
                ~gen:(oneof_list (List.of_seq (String.to_seq "aZ9-.")))
                (int_range 1 4))
             (string_size
                ~gen:(oneof_list [ 'a'; ' '; '"'; '\\'; '.'; '\xff'; 'T' ])
                (int_range 0 4))
             (map2 ( ^ )
                (oneof_list [ "a"; "Z" ])
                (string_size
                   ~gen:(oneof_list [ 'b'; '9'; '-' ])
                   (int_range 0 3)))
             (string_size
                ~gen:
                  (oneof_list
                     [
                       'x';
                       ' ';
                       '\t';
                       '"';
                       '\\';
                       '\n';
                       '\b';
                       '#';
                       ';';
                       '\xc3';
                       '=';
                     ])
                (int_range 0 6))))
      (fun settings ->
        let escape_sub s =
          String.concat ""
            (List.map
               (function
                 | '"' -> "\\\"" | '\\' -> "\\\\" | c -> String.make 1 c)
               (List.of_seq (String.to_seq s)))
        in
        let escape_value s =
          String.concat ""
            (List.map
               (function
                 | '"' -> "\\\""
                 | '\\' -> "\\\\"
                 | '\n' -> "\\n"
                 | '\t' -> "\\t"
                 | '\b' -> "\\b"
                 | c -> String.make 1 c)
               (List.of_seq (String.to_seq s)))
        in
        let text =
          String.concat ""
            (List.map
               (fun (section, subsection, name, value) ->
                 Printf.sprintf "[%s \"%s\"]\n\t%s = \"%s\"\n" section
                   (escape_sub subsection) name (escape_value value))
               settings)
        in
        match Config.parse text with
        | Error _ -> false
        | Ok parsed ->
            List.length parsed = List.length settings
            && List.for_all2
                 (fun (section, subsection, name, value) (k, v) ->
                   Config.equal_key k (Config.key ~section ~subsection name)
                   && v = Some value)
                 settings parsed);
    property ~count:2000 ~name:"a parse takes any bytes and never raises"
      ~print:(Printf.sprintf "%S")
      Gen.(
        string_size
          ~gen:
            (oneof
               [
                 char;
                 oneof_list [ '['; ']'; '"'; '\\'; '\n'; '='; 'a'; ' '; '#' ];
               ])
          (int_range 0 60))
      (fun text -> match Config.parse text with Ok _ | Error _ -> true);
  ]

let boolean_tests =
  [
    case "the booleans of the page" (fun () ->
        List.iter
          (fun (value, expected) ->
            Alcotest.(check (option bool))
              (show_value value) expected (Config.boolean value))
          [
            (None, Some true);
            (Some "yes", Some true);
            (Some "On", Some true);
            (Some "TRUE", Some true);
            (Some "1", Some true);
            (Some "no", Some false);
            (Some "OFF", Some false);
            (Some "False", Some false);
            (Some "0", Some false);
            (Some "", Some false);
            (Some "2", Some true);
            (Some " true", None);
            (Some "y", None);
          ]);
  ]

let integer_boolean_tests =
  [
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A value of a boolean setting, such as `extensions.worktreeConfig`, must
       be the boolean that git 2.54.0 gives it: an integer in 32 bits, in base
       16, 8, or 10, with a unit `k`, `m`, or `g`, is true when it is not 0, and
       each value that git refuses gives no boolean. *)
    case "an integer is a boolean, true when it is not 0" (fun () ->
        List.iter
          (fun (text, expected) ->
            Alcotest.(check (option bool))
              (Printf.sprintf "%S" text) expected
              (Config.boolean (Some text)))
          (([
              "2";
              "-1";
              "+1";
              "007";
              "0x1";
              "0X1f";
              "1k";
              "1K";
              "1m";
              "1M";
              "1g";
              "1G";
              " 1";
              "\t1";
              "\n1";
              "\0111";
              "\0121";
              "\r1";
              " \t1";
              "2147483647";
              "-2147483648";
              "2097151k";
              "-2097152k";
              "-2g";
              "-1k";
              "0x7fffffff";
              "0x1k";
              "0x1g";
              "017777777777";
              "0x1A";
              "0X1F";
              "2047m";
              "-2048m";
            ]
           |> List.map (fun text -> (text, Some true)))
          @ ([ "00"; "0k"; "0g"; "-0"; "+0"; "0x0"; "000"; " 0"; "\0110" ]
            |> List.map (fun text -> (text, Some false)))
          @ ([
               "08";
               "09";
               "0x";
               "0xk";
               "00x1";
               "1kb";
               "1kk";
               "1t";
               "k";
               "-k";
               "-";
               "1.0";
               "1 ";
               "+ 1";
               "- 1";
               " ";
               " true";
               "true ";
               "1 k";
               "0 x1";
               "2147483648";
               "-2147483649";
               "2097152k";
               "-2097153k";
               "2g";
               "0x80000000";
               "020000000000";
               "99999999999999999999";
               "-99999999999999999999";
               "\0271";
               "2048m";
               "-2049m";
               "1a";
               "1A";
               "\0081";
               "\0141";
               "maybe";
             ]
            |> List.map (fun text -> (text, None)))));
  ]

let pathname_tests =
  [
    case "the pathnames of the page" (fun () ->
        let show = function
          | Ok (Config.Pathname p) -> "pathname " ^ p
          | Ok Config.Names_no_file -> "no file"
          | Error Config.No_home -> "no home"
          | Error Config.Unread_form -> "unread form"
          | Error Config.No_value -> "no value"
        in
        List.iter
          (fun (home, value, expected) ->
            Alcotest.(check string)
              (show_value value) expected
              (show (Config.pathname ~home value)))
          [
            (Some "/h", Some "~/x/y", "pathname /h/x/y");
            (None, Some "~/x", "no home");
            (Some "/h", Some "~user/x", "unread form");
            (Some "/h", Some "~", "unread form");
            (Some "/h", Some ":(optional)/x", "no file");
            (Some "/h", Some "%(prefix)/etc/x", "no file");
            (Some "/h", Some "./%(prefix)/x", "pathname ./%(prefix)/x");
            (Some "/h", Some "rel/x", "pathname rel/x");
            (Some "/h", Some "/abs", "pathname /abs");
            (Some "/h", None, "no value");
          ]);
  ]

(* The files of a git configuration. *)

let order_tests =
  [
    case "the values come from the files in the order of the page" (fun () ->
        let world =
          {
            files =
              [
                ("/sys", content "[s]\na = system\n");
                ("/x/git/config", content "[s]\na = xdg\n");
                ("/h/.gitconfig", content "[s]\na = home\n");
                (config_path, content "[s]\na = repository\n");
              ];
            env =
              [
                ("GIT_CONFIG_SYSTEM", "/sys");
                ("XDG_CONFIG_HOME", "/x");
                ("HOME", "/h");
                ("GIT_CONFIG_COUNT", "2");
                ("GIT_CONFIG_KEY_0", "s.a");
                ("GIT_CONFIG_VALUE_0", "count 0");
                ("GIT_CONFIG_KEY_1", "S.A");
                ("GIT_CONFIG_VALUE_1", "");
              ];
          }
        in
        let configuration = configuration world in
        check_values "values"
          [
            Some "system";
            Some "xdg";
            Some "home";
            Some "repository";
            Some "count 0";
            Some "";
          ]
          configuration "s.a";
        Alcotest.(check string)
          "last" (show_value (Some ""))
          (match Config.last configuration (key "s.a") with
          | Some value -> show_value value
          | None -> "none");
        Alcotest.(check bool)
          "no last" true
          (Config.last configuration (key "s.b") = None));
  ]

let reads world = snd (run_with world)

(* @verifies changes#read-only-repository-files=v1
   For each environment of the test, the reader of the git configuration must
   ask for exactly the files of the git configuration, in their order: the
   system file of rule 1 of the term `git-configuration` or none, the global
   files, the file `config`, and the files that they include; a read of
   `/etc/gitconfig` under `GIT_CONFIG_NOSYSTEM`, of the file that `GIT_CONFIG`
   names, or of a global file that `GIT_CONFIG_GLOBAL` replaces, fails the
   test. The files of the git configuration are repository files, item 1 of
   the list of the requirement. The test sees the pathnames only: not what the
   caller's read takes. *)
let read_tests =
  [
    case "the reads are exactly the files of the git configuration" (fun () ->
        let base = only_config "[s]\na = 1\n" in
        List.iter
          (fun (name, env, expected) ->
            Alcotest.(check (list string))
              name expected
              (reads { base with env }))
          [
            ("no variable", [], [ "/etc/gitconfig"; config_path ]);
            ( "GIT_CONFIG_NOSYSTEM",
              [ ("GIT_CONFIG_NOSYSTEM", "true"); ("GIT_CONFIG_SYSTEM", "/sys") ],
              [ config_path ] );
            ( "GIT_CONFIG_NOSYSTEM false",
              [ ("GIT_CONFIG_NOSYSTEM", "0") ],
              [ "/etc/gitconfig"; config_path ] );
            ( "GIT_CONFIG_NOSYSTEM 2",
              [ ("GIT_CONFIG_NOSYSTEM", "2") ],
              [ config_path ] );
            ( "GIT_CONFIG_NOSYSTEM 00",
              [ ("GIT_CONFIG_NOSYSTEM", "00") ],
              [ "/etc/gitconfig"; config_path ] );
            ( "GIT_CONFIG_SYSTEM",
              [ ("GIT_CONFIG_SYSTEM", "/sys") ],
              [ "/sys"; config_path ] );
            ( "HOME",
              [ ("HOME", "/h") ],
              [
                "/etc/gitconfig";
                "/h/.config/git/config";
                "/h/.gitconfig";
                config_path;
              ] );
            ( "an empty XDG_CONFIG_HOME",
              [ ("HOME", "/h"); ("XDG_CONFIG_HOME", "") ],
              [
                "/etc/gitconfig";
                "/h/.config/git/config";
                "/h/.gitconfig";
                config_path;
              ] );
            ( "XDG_CONFIG_HOME",
              [ ("HOME", "/h"); ("XDG_CONFIG_HOME", "/x") ],
              [
                "/etc/gitconfig"; "/x/git/config"; "/h/.gitconfig"; config_path;
              ] );
            ( "XDG_CONFIG_HOME without HOME",
              [ ("XDG_CONFIG_HOME", "/x") ],
              [ "/etc/gitconfig"; "/x/git/config"; config_path ] );
            ( "GIT_CONFIG_GLOBAL",
              [ ("HOME", "/h"); ("GIT_CONFIG_GLOBAL", "/g") ],
              [ "/etc/gitconfig"; "/g"; config_path ] );
            ( "an empty GIT_CONFIG_GLOBAL",
              [ ("HOME", "/h"); ("GIT_CONFIG_GLOBAL", "") ],
              [ "/etc/gitconfig"; config_path ] );
            ( "GIT_CONFIG",
              [ ("GIT_CONFIG", "/other"); ("GIT_CONFIG_NOSYSTEM", "1") ],
              [ config_path ] );
          ]);
    case "the reads of the includes are the files that the includes name"
      (fun () ->
        let world =
          {
            files =
              [
                ( config_path,
                  content
                    "[include]\npath = a.inc\npath = /abs.inc\npath = ~/h.inc\n"
                );
                ("/r/.git/a.inc", content "[include]\npath = sub/b.inc\n");
                ("/r/.git/sub/b.inc", content "[s]\nb = 1\n");
              ];
            env =
              [
                ("GIT_CONFIG_NOSYSTEM", "1");
                ("GIT_CONFIG_GLOBAL", "");
                ("HOME", "/h");
              ];
          }
        in
        Alcotest.(check (list string))
          "reads"
          [
            config_path;
            "/r/.git/a.inc";
            "/r/.git/sub/b.inc";
            "/abs.inc";
            "/h/h.inc";
          ]
          (reads world));
  ]

let no_system = [ ("GIT_CONFIG_NOSYSTEM", "1") ]

let environment_tests =
  [
    case "a variable of the environment without a meaning is an error"
      (fun () ->
        let base = only_config "" in
        List.iter
          (fun (env, expected) ->
            check_error expected ("environment " ^ expected) { base with env })
          [
            ([ ("GIT_CONFIG_NOSYSTEM", "maybe") ], "GIT_CONFIG_NOSYSTEM");
            ([ ("GIT_CONFIG_NOSYSTEM", "08") ], "GIT_CONFIG_NOSYSTEM");
            (no_system @ [ ("GIT_CONFIG_COUNT", "x") ], "GIT_CONFIG_COUNT");
            (no_system @ [ ("GIT_CONFIG_COUNT", "-1") ], "GIT_CONFIG_COUNT");
            (no_system @ [ ("GIT_CONFIG_COUNT", "1") ], "GIT_CONFIG_KEY_0");
            ( no_system
              @ [ ("GIT_CONFIG_COUNT", "1"); ("GIT_CONFIG_KEY_0", "s.a") ],
              "GIT_CONFIG_VALUE_0" );
            ( no_system
              @ [
                  ("GIT_CONFIG_COUNT", "1");
                  ("GIT_CONFIG_KEY_0", "nokey");
                  ("GIT_CONFIG_VALUE_0", "v");
                ],
              "GIT_CONFIG_KEY_0" );
          ]);
    case "an empty GIT_CONFIG_COUNT gives no setting" (fun () ->
        let configuration =
          configuration
            {
              (only_config "") with
              env =
                no_system
                @ [
                    ("GIT_CONFIG_COUNT", "");
                    ("GIT_CONFIG_KEY_0", "s.a");
                    ("GIT_CONFIG_VALUE_0", "v");
                  ];
            }
        in
        check_values "none" [] configuration "s.a");
  ]

let more_environment_tests =
  let env_world pairs =
    {
      (only_config "") with
      env =
        no_system
        @ [ ("GIT_CONFIG_COUNT", string_of_int (List.length pairs)) ]
        @ List.concat
            (List.mapi
               (fun n (k, v) ->
                 [
                   ("GIT_CONFIG_KEY_" ^ string_of_int n, k);
                   ("GIT_CONFIG_VALUE_" ^ string_of_int n, v);
                 ])
               pairs);
    }
  in
  [
    case "a relative gitdir from the environment names its value" (fun () ->
        Alcotest.(check string)
          "relative"
          ("relative without file " ^ show_value (Some "./x/"))
          (match
             fst
               (run_with
                  (env_world [ ("includeIf.gitdir:./x/.path", "/yes.inc") ]))
           with
          | Ok _ -> "no error"
          | Error error -> error_name error));
    case "an include from the environment is no conditional include" (fun () ->
        let world = env_world [ ("include.path", "/abs.inc") ] in
        let world =
          {
            world with
            files =
              ("/abs.inc", content "[remote \"o\"]\nurl = /a\n") :: world.files;
          }
        in
        check_values "url" [ Some "/a" ] (configuration world) "remote.o.url");
    case "a count of ten takes ten pairs" (fun () ->
        let pairs = List.init 10 (fun n -> ("s0.a9", string_of_int n)) in
        check_values "ten"
          (List.init 10 (fun n -> Some (string_of_int n)))
          (configuration (env_world pairs))
          "s0.a9");
    case "a key of the environment is a section, a subsection, and a name"
      (fun () ->
        let configuration =
          configuration
            (env_world
               [
                 ("S.A", "1");
                 ("s.Sub.Name", "2");
                 ("s.a.b.c", "3");
                 ("s-1.b-2", "4");
               ])
        in
        check_values "no subsection" [ Some "1" ] configuration "s.a";
        check_values "a subsection" [ Some "2" ] configuration "s.Sub.name";
        check_values "a subsection with a dot" [ Some "3" ] configuration
          "s.a.b.c";
        check_values "names with - and digits" [ Some "4" ] configuration
          "s-1.b-2";
        List.iter
          (fun bad ->
            Alcotest.(check string)
              bad "environment GIT_CONFIG_KEY_0"
              (match fst (run_with (env_world [ (bad, "v") ])) with
              | Ok _ -> "no error"
              | Error error -> error_name error))
          [
            "nodot";
            ".a";
            "a.";
            "a.1b";
            "a_b.c";
            "a.b_c";
            "a.x\ny.c";
            "a.b.";
            ".b";
            ".";
            "..";
            "a.b.1";
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A key of `GIT_CONFIG_KEY_<n>` with an empty section must be a key when it
       has a subsection, as git 2.54.0 reads `.a.b`, `..b`, and `.A.b`, and
       `.b`, `.`, and `..` must be errors. *)
    case "a key with an empty section and a subsection is a key" (fun () ->
        let configuration =
          configuration
            (env_world [ (".a.b", "1"); ("..b", "2"); (".A.b", "3") ])
        in
        check_values "an empty section" [ Some "1" ] configuration ".a.b";
        check_values "an empty subsection" [ Some "2" ] configuration "..b";
        check_values "the case of the subsection" [ Some "3" ] configuration
          ".A.b");
    case "a remote URL outside a conditional include is a setting" (fun () ->
        let configuration =
          configuration
            {
              files =
                [
                  ("/g", content "[remote \"o\"]\nurl = /a\n");
                  ("/etc/gitconfig", content "[remote \"p\"]\nurl = /b\n");
                ];
              env =
                [
                  ("GIT_CONFIG_GLOBAL", "/g");
                  ("GIT_CONFIG_COUNT", "1");
                  ("GIT_CONFIG_KEY_0", "remote.q.url");
                  ("GIT_CONFIG_VALUE_0", "/c");
                ];
            }
        in
        check_values "global" [ Some "/a" ] configuration "remote.o.url";
        check_values "system" [ Some "/b" ] configuration "remote.p.url";
        check_values "environment" [ Some "/c" ] configuration "remote.q.url");
  ]

let file_tests =
  [
    case "a system or global file that cannot be read holds no setting"
      (fun () ->
        let configuration =
          configuration
            {
              files =
                [
                  ("/etc/gitconfig", Config.Unreadable);
                  ("/h/.gitconfig", Config.Unreadable);
                  (config_path, content "[s]\na = 1\n");
                ];
              env = [ ("HOME", "/h") ];
            }
        in
        check_values "values" [ Some "1" ] configuration "s.a");
    case "a file config that cannot be read is an error" (fun () ->
        check_error "unreadable"
          ("unreadable " ^ config_path)
          { files = [ (config_path, Config.Unreadable) ]; env = no_system });
    case "a missing file config holds no setting" (fun () ->
        let configuration = configuration { files = []; env = no_system } in
        check_values "values" [] configuration "s.a");
    case "a file that is not in the syntax is an error with its line" (fun () ->
        check_error "syntax"
          ("syntax " ^ config_path ^ ":2")
          { (only_config "[s]\n1 = x\n") with env = no_system };
        check_error "syntax of the system file" "syntax /etc/gitconfig:1"
          { files = [ ("/etc/gitconfig", content "x\n") ]; env = [] });
  ]

let include_world ?(env = no_system) files = { files; env }

let limit_tests =
  let world =
    include_world
      [
        (config_path, content "[s]\na = 1\n[include]\npath = x.inc\n");
        ("/r/.git/x.inc", content "[s]\na = 2\nb = 3\n");
      ]
  in
  let run max_files max_values =
    match fst (run_with ~limits:{ Config.max_files; max_values } world) with
    | Ok configuration -> show_values (Config.values configuration (key "s.a"))
    | Error error -> error_name error
  in
  [
    case "a read past a limit gives no configuration, and one inside gives all"
      (fun () ->
        Alcotest.(check string)
          "2 files and 4 values"
          (show_values [ Some "1"; Some "2" ])
          (run 2 4);
        Alcotest.(check string) "1 file" "limit exceeded" (run 1 4);
        Alcotest.(check string) "3 values" "limit exceeded" (run 2 3);
        Alcotest.(check string) "0 files" "limit exceeded" (run 0 4));
    case "each read of a file counts, the same file read twice included"
      (fun () ->
        let world =
          include_world
            [
              (config_path, content "[include]\npath = x.inc\npath = x.inc\n");
              ("/r/.git/x.inc", content "[s]\na = 1\n");
            ]
        in
        let run max_files =
          match
            fst (run_with ~limits:{ Config.max_files; max_values = 100 } world)
          with
          | Ok configuration ->
              show_values (Config.values configuration (key "s.a"))
          | Error error -> error_name error
        in
        Alcotest.(check string)
          "3 files"
          (show_values [ Some "1"; Some "1" ])
          (run 3);
        Alcotest.(check string) "2 files" "limit exceeded" (run 2));
    case "a negative limit raises Invalid_argument" (fun () ->
        List.iter
          (fun limits ->
            match run_with ~limits world with
            | _ -> Alcotest.fail "no exception"
            | exception Invalid_argument _ -> ())
          [
            { Config.max_files = -1; max_values = 10 };
            { Config.max_files = 10; max_values = -1 };
          ]);
  ]

let include_tests =
  [
    case "an include gives the settings of its file at its place" (fun () ->
        let configuration =
          configuration
            (include_world
               [
                 ( config_path,
                   content "[s]\na = 1\n[include]\npath = x.inc\n[s]\na = 3\n"
                 );
                 ("/r/.git/x.inc", content "[s]\na = 2\n");
               ])
        in
        check_values "values"
          [ Some "1"; Some "2"; Some "3" ]
          configuration "s.a");
    case "an include of a missing file or of %(prefix)/ includes nothing"
      (fun () ->
        let configuration =
          configuration
            (include_world
               [
                 ( config_path,
                   content
                     "[include]\n\
                      path = gone.inc\n\
                      path = %(prefix)/etc/x\n\
                      path = :(optional)/etc/x\n\
                      [s]\n\
                      a = 1\n" );
                 ("/etc/x", content "[s]\na = 0\n");
               ])
        in
        check_values "values" [ Some "1" ] configuration "s.a");
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. An empty value of `include.path`, or of the path of a met condition, must
       name the folder of the file that holds it, as git 2.54.0 reads it, so
       that the configuration is an error; from the environment, it must be a
       relative include with no file. *)
    case "an empty include names the folder of its file" (fun () ->
        List.iter
          (fun text ->
            check_error text "unreadable /r/.git/"
              (include_world
                 [
                   (config_path, content text); ("/r/.git/", Config.Unreadable);
                 ]))
          [
            "[include]\npath =\n";
            "[include]\npath = \"\"\n";
            "[include]\npath =   \n";
            "[includeIf \"gitdir:/r/.git\"]\npath =\n";
          ];
        check_error "the folder ." "unreadable /r/.git/."
          (include_world
             [
               (config_path, content "[include]\npath = .\n");
               ("/r/.git/.", Config.Unreadable);
             ]);
        check_error "a condition that is not met" "no error"
          (include_world
             [
               (config_path, content "[includeIf \"gitdir:/x/\"]\npath =\n");
               ("/r/.git/", Config.Unreadable);
             ]);
        check_error "from the environment"
          ("relative without file " ^ show_value (Some ""))
          (include_world
             ~env:
               (no_system
               @ [
                   ("GIT_CONFIG_COUNT", "1");
                   ("GIT_CONFIG_KEY_0", "include.path");
                   ("GIT_CONFIG_VALUE_0", "");
                 ])
             [ (config_path, content "") ]));
    case "an include whose pathname has an unread form is an error" (fun () ->
        List.iter
          (fun value ->
            check_error value
              (Printf.sprintf "unread pathname %s %s" config_path
                 (show_value (Some value)))
              (include_world
                 [
                   (config_path, content ("[include]\npath = " ^ value ^ "\n"));
                 ]))
          [ "~user/x"; "~"; "~user" ];
        check_error "no HOME"
          (Printf.sprintf "unread pathname %s %s" config_path
             (show_value (Some "~/x")))
          (include_world [ (config_path, content "[include]\npath = ~/x\n") ]);
        check_error "no value"
          (Printf.sprintf "unread pathname %s %s" config_path (show_value None))
          (include_world [ (config_path, content "[include]\npath\n") ]));
    case "an included file that cannot be read is an error" (fun () ->
        check_error "unreadable" "unreadable /r/.git/x.inc"
          (include_world
             [
               (config_path, content "[include]\npath = x.inc\n");
               ("/r/.git/x.inc", Config.Unreadable);
             ]));
    case "an include of a file that includes it, in turn, is a cycle" (fun () ->
        let result world =
          match fst (run_with world) with
          | Ok _ -> "no error"
          | Error (Config.Include_cycle _) -> "cycle"
          | Error error -> error_name error
        in
        Alcotest.(check string)
          "by pathname" "cycle"
          (result
             (include_world
                [
                  (config_path, content "[include]\npath = a.inc\n");
                  ("/r/.git/a.inc", content "[include]\npath = b.inc\n");
                  ("/r/.git/b.inc", content "[include]\npath = a.inc\n");
                ]));
        Alcotest.(check string)
          "itself" "cycle"
          (result
             (include_world
                [ (config_path, content "[include]\npath = config\n") ]));
        Alcotest.(check string)
          "by identity" "cycle"
          (result
             (include_world
                [
                  ( config_path,
                    content ~identity:(1, 1) "[include]\npath = a.inc\n" );
                  ( "/r/.git/a.inc",
                    content ~identity:(1, 2) "[include]\npath = link.inc\n" );
                  ( "/r/.git/link.inc",
                    content ~identity:(1, 2) "[include]\npath = a.inc\n" );
                ]));
        Alcotest.(check string)
          "the same file twice, with no cycle" "no error"
          (result
             (include_world
                [
                  ( config_path,
                    content "[include]\npath = a.inc\npath = a.inc\n" );
                  ("/r/.git/a.inc", content "[s]\na = 1\n");
                ]));
        Alcotest.(check string)
          "the same file twice, by identity, with no cycle" "no error"
          (result
             (include_world
                [
                  ( config_path,
                    content ~identity:(1, 1)
                      "[include]\npath = a.inc\npath = a.inc\n" );
                  ("/r/.git/a.inc", content ~identity:(1, 2) "[s]\na = 1\n");
                ])));
    case "a relative include from the environment is an error" (fun () ->
        check_error "relative"
          ("relative without file " ^ show_value (Some "x.inc"))
          (include_world
             ~env:
               (no_system
               @ [
                   ("GIT_CONFIG_COUNT", "1");
                   ("GIT_CONFIG_KEY_0", "include.path");
                   ("GIT_CONFIG_VALUE_0", "x.inc");
                 ])
             [ (config_path, content "") ]);
        let configuration =
          configuration
            (include_world
               ~env:
                 (no_system
                 @ [
                     ("GIT_CONFIG_COUNT", "1");
                     ("GIT_CONFIG_KEY_0", "include.path");
                     ("GIT_CONFIG_VALUE_0", "/abs.inc");
                   ])
               [ ("/abs.inc", content "[s]\na = 1\n") ])
        in
        check_values "absolute" [ Some "1" ] configuration "s.a");
  ]

let conditional ?(git_directories = [ git_folder ]) ?(env = no_system) ?branch
    ?working_tree condition =
  let world =
    include_world ~env
      [
        ( config_path,
          content
            (Printf.sprintf "[includeIf \"%s\"]\npath = /yes.inc\n" condition)
        );
        ("/yes.inc", content "[s]\nmet = 1\n");
      ]
  in
  match fst (run_with ~git_directories ?branch ?working_tree world) with
  | Ok configuration ->
      if Config.values configuration (key "s.met") = [] then "not met"
      else "met"
  | Error error -> error_name error

let condition_tests =
  [
    case "a condition gitdir matches the git directories" (fun () ->
        List.iter
          (fun (condition, directories, expected) ->
            Alcotest.(check string)
              condition expected
              (conditional ~git_directories:directories condition))
          [
            ("gitdir:/r/.git", [ git_folder ], "met");
            ("gitdir:/r/.git", [ "/x//r/.git" ], "not met");
            ("gitdir:/r/", [ git_folder ], "met");
            ("gitdir:/r", [ git_folder ], "not met");
            ("gitdir:r/.git", [ git_folder ], "met");
            ("gitdir:.git", [ git_folder ], "met");
            ("gitdir:/R/.git", [ git_folder ], "not met");
            ("gitdir/i:/R/.GIT", [ git_folder ], "met");
            ("gitdir:/s/*/.git", [ git_folder; "/s/t/.git" ], "met");
            ("gitdir:/s/**", [ git_folder ], "not met");
            ("gitdir:./", [ git_folder ], "not met");
            ("gitdir:./", [ git_folder ^ "/x" ], "met");
            ("gitdir:./x/", [ git_folder ], "not met");
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `HOME` is set and not empty, the `~` at the start
       of a pattern `~/...` of a condition `gitdir:` or `gitdir/i:` becomes the
       value of `HOME`. When `HOME` is not set, that condition is not met, and
       the read gives no error. *)
    case "a condition gitdir with ~/ takes HOME" (fun () ->
        Alcotest.(check string)
          "home" "met"
          (conditional ~git_directories:[ "/h/w/.git" ]
             ~env:(no_system @ [ ("HOME", "/h") ])
             "gitdir:~/w/");
        Alcotest.(check string)
          "gitdir/i" "met"
          (conditional ~git_directories:[ "/h/w/.git" ]
             ~env:(no_system @ [ ("HOME", "/h") ])
             "gitdir/i:~/W/");
        Alcotest.(check string)
          "HOME is /" "not met"
          (conditional ~env:(no_system @ [ ("HOME", "/") ]) "gitdir:~/x/");
        Alcotest.(check string) "no home" "not met" (conditional "gitdir:~/w/"));
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. In a git repository without a working tree, a condition
       `onbranch:` matches the branch name that the HEAD of the git folder
       names, with `**` after a pattern that ends with `/`. When HEAD names no
       branch, the condition is not met. *)
    case "a condition onbranch matches the branch of a git repository"
      (fun () ->
        List.iter
          (fun (condition, branch, expected) ->
            Alcotest.(check string)
              condition expected
              (conditional ?branch condition))
          [
            ("onbranch:main", Some "main", "met");
            ("onbranch:main", Some "other", "not met");
            ("onbranch:MAIN", Some "main", "not met");
            ("onbranch:feat/", Some "feat/a/b", "met");
            ("onbranch:feat/", Some "feat", "not met");
            ("onbranch:feat/*", Some "feat/a/b", "not met");
            ("onbranch:feat/*", Some "feat/a", "met");
            ("onbranch:**", Some "main", "met");
            ("onbranch:", Some "main", "not met");
            ("onbranch:main", None, "not met");
            ("onbranch:**", None, "not met");
            ("onbranch:*", None, "not met");
          ]);
    case "a condition onbranch matches the branch of a working tree" (fun () ->
        List.iter
          (fun (condition, branch, expected) ->
            Alcotest.(check string)
              condition expected
              (conditional ~working_tree:git_folder ?branch condition))
          [
            ("onbranch:main", Some "main", "met");
            ("onbranch:main", Some "other", "not met");
            ("onbranch:feat/", Some "feat/a/b", "met");
            ("onbranch:feat/*", Some "feat/a/b", "not met");
            ("onbranch:main", None, "not met");
          ]);
    case "a condition hasconfig matches the URLs of the remotes" (fun () ->
        let run files =
          match fst (run_with (include_world files)) with
          | Ok configuration ->
              if Config.values configuration (key "s.met") = [] then "not met"
              else "met"
          | Error error -> error_name error
        in
        Alcotest.(check string)
          "a later URL" "met"
          (run
             [
               ( config_path,
                 content
                   "[includeIf \
                    \"hasconfig:remote.*.url:https://example.invalid/**\"]\n\
                    path = /yes.inc\n\
                    [remote \"o\"]\n\
                    url = https://example.invalid/a/b\n" );
               ("/yes.inc", content "[s]\nmet = 1\n");
             ]);
        Alcotest.(check string)
          "no URL that matches" "not met"
          (run
             [
               ( config_path,
                 content
                   "[includeIf \
                    \"hasconfig:remote.*.url:https://example.invalid/**\"]\n\
                    path = /yes.inc\n\
                    [remote \"o\"]\n\
                    url = https://other.invalid/a\n" );
               ("/yes.inc", content "[s]\nmet = 1\n");
             ]);
        Alcotest.(check string)
          "a URL in the included file"
          "remote url in conditional include /yes.inc"
          (run
             [
               ( config_path,
                 content
                   "[includeIf \
                    \"hasconfig:remote.*.url:https://example.invalid/**\"]\n\
                    path = /yes.inc\n\
                    [remote \"o\"]\n\
                    url = https://example.invalid/a\n" );
               ("/yes.inc", content "[remote \"p\"]\nurl = x\n");
             ]);
        let met_by remotes =
          run
            [
              ( config_path,
                content
                  ("[includeIf \"hasconfig:remote.*.url:x\"]\npath = /yes.inc\n"
                 ^ remotes) );
              ("/yes.inc", content "[s]\nmet = 1\n");
            ]
        in
        Alcotest.(check string)
          "a remote with an empty name" "met"
          (met_by "[remote \"\"]\nurl = x\n");
        Alcotest.(check string)
          "the old form of a subsection" "met"
          (met_by "[remote.o]\nurl = x\n");
        Alcotest.(check string)
          "a remote with a long name" "met"
          (met_by "[remote \"a.b.c\"]\nurl = x\n");
        List.iter
          (fun remotes ->
            Alcotest.(check string) remotes "not met" (met_by remotes))
          [
            "[remote]\nurl = x\n";
            "[remotes \"o\"]\nurl = x\n";
            "[remote \"o\"]\nurls = x\n";
            "[remote \"o\"]\npushurl = x\n";
            "[xremote \"o\"]\nurl = x\n";
            "[s]\nurl = x\n";
          ];
        Alcotest.(check string)
          "a URL with no value" "remote url without value"
          (run
             [
               ( config_path,
                 content
                   "[includeIf \"hasconfig:remote.*.url:x\"]\n\
                    path = /yes.inc\n\
                    [remote \"o\"]\n\
                    url\n" );
             ]));
    case "a condition that the page does not give includes no file" (fun () ->
        List.iter
          (fun condition ->
            Alcotest.(check string) condition "not met" (conditional condition);
            Alcotest.(check string)
              ("in a working tree: " ^ condition)
              "not met"
              (conditional ~working_tree:git_folder ~branch:"main" condition))
          [
            "worktree:/w";
            "worktree/i:/w";
            "foo:x";
            "gitdir";
            "onbranch";
            "hasconfig:remote.*.pushurl:x";
            "";
            "GITDIR:/r/.git";
          ]);
  ]

let more_condition_tests =
  [
    case
      "a section includeIf with no condition, or a path elsewhere, is a setting"
      (fun () ->
        let configuration =
          configuration
            (include_world
               [
                 ( config_path,
                   content
                     "[includeIf]\npath = /yes.inc\n[s]\npath = /yes.inc\n" );
                 ("/yes.inc", content "[s]\nmet = 1\n");
               ])
        in
        check_values "no include" [] configuration "s.met";
        check_values "a key that only ends with .path" []
          (configuration_of
             (include_world
                [
                  ( config_path,
                    content "[aaaaaaaaa \"gitdir:/r/.git\"]\npath = /yes.inc\n"
                  );
                  ("/yes.inc", content "[s]\nmet = 1\n");
                ]))
          "s.met";
        check_values "a setting" [ Some "/yes.inc" ] configuration
          "includeif.path");
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When a file or the environment that the read reads has
       a setting under a condition `hasconfig:remote.*.url:`, met or not, a
       remote URL (with or without a value) in a file that a met condition of
       any kind includes, in turn, must make the configuration an error, as
       git 2.54.0 refuses it. With no such setting, or in a file of a plain
       include, the remote URL must be a setting. In a file of an unmet
       condition other than `hasconfig:remote.*.url:`, the include must give no
       error. *)
    case "with a condition hasconfig, a URL under any met condition is an error"
      (fun () ->
        let hasconfig = "[includeIf \"hasconfig:remote.*.url:other\"]\n" in
        let gitdir = "[includeIf \"gitdir:/r/.git\"]\npath = /url.inc\n" in
        let run ?(env = no_system) ?working_tree ?branch config files =
          match
            fst
              (run_with ?working_tree ?branch
                 (include_world ~env
                    ([
                       (config_path, content config);
                       ("/url.inc", content "[remote \"o\"]\nurl = /u\n");
                       ("/url-none.inc", content "[remote \"o\"]\nurl\n");
                       ("/hit.inc", content "[s]\nhit = 1\n");
                     ]
                    @ files)))
          with
          | Ok _ -> "no error"
          | Error error -> error_name error
        in
        let refused name = "remote url in conditional include " ^ name in
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ("no condition hasconfig", "no error", run gitdir []);
            ( "a condition after",
              refused "/url.inc",
              run (gitdir ^ hasconfig ^ "path = /hit.inc\n") [] );
            ( "a condition before",
              refused "/url.inc",
              run (hasconfig ^ "path = /hit.inc\n" ^ gitdir) [] );
            ( "a condition gitdir/i",
              refused "/url.inc",
              run
                ("[includeIf \"gitdir/i:/R/.GIT\"]\npath = /url.inc\n"
               ^ hasconfig ^ "path = /hit.inc\n")
                [] );
            ( "a condition onbranch",
              refused "/url.inc",
              run ~working_tree:git_folder ~branch:"main"
                ("[includeIf \"onbranch:**\"]\npath = /url.inc\n" ^ hasconfig
               ^ "path = /hit.inc\n")
                [] );
            ( "a plain include in the file of the condition",
              refused "/url.inc",
              run
                ("[includeIf \"gitdir:/r/.git\"]\npath = /via.inc\n" ^ hasconfig
               ^ "path = /hit.inc\n")
                [ ("/via.inc", content "[include]\npath = /url.inc\n") ] );
            ( "a condition in the file of a plain include",
              refused "/url.inc",
              run
                ("[include]\npath = /via.inc\n" ^ hasconfig
               ^ "path = /hit.inc\n")
                [ ("/via.inc", content gitdir) ] );
            ( "a URL with no value",
              refused "/url-none.inc",
              run
                ("[includeIf \"gitdir:/r/.git\"]\npath = /url-none.inc\n"
               ^ hasconfig ^ "path = /hit.inc\n")
                [] );
            ( "a setting other than path under the condition",
              refused "/url.inc",
              run (gitdir ^ hasconfig ^ "foo = bar\n") [] );
            ( "a setting with no value under the condition",
              refused "/url.inc",
              run (gitdir ^ hasconfig ^ "foo\n") [] );
            ( "a condition from the environment",
              refused "/url.inc",
              run
                ~env:
                  (no_system
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ( "GIT_CONFIG_KEY_0",
                        "includeIf.hasconfig:remote.*.url:other.path" );
                      ("GIT_CONFIG_VALUE_0", "/hit.inc");
                    ])
                gitdir [] );
            ( "a section of the condition with no setting",
              "no error",
              run (gitdir ^ hasconfig) [] );
            ( "a condition only in a file that is not included",
              "no error",
              run
                ("[includeIf \"gitdir:/x/\"]\npath = /cond.inc\n" ^ gitdir)
                [ ("/cond.inc", content (hasconfig ^ "path = /hit.inc\n")) ] );
            ( "a condition gitdir that is not met",
              "no error",
              run
                ("[includeIf \"gitdir:/x/\"]\npath = /url.inc\n" ^ hasconfig
               ^ "path = /hit.inc\n")
                [] );
            ( "a plain include",
              "no error",
              run
                ("[include]\npath = /url.inc\n" ^ hasconfig
               ^ "path = /hit.inc\n")
                [] );
            ( "a key that starts like the condition only",
              "no error",
              run
                (gitdir
               ^ "[includeIf \"hasconfig:remote.*\"]\npath = /hit.inc\n")
                [] );
            ( "a condition with no colon after url",
              "no error",
              run
                (gitdir
               ^ "[includeIf \"hasconfig:remote.*.urlx\"]\npath = /hit.inc\n")
                [] );
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When the configuration has a setting under a condition
       `hasconfig:remote.*.url:`, a remote URL in a global file, in the file
       `config.worktree`, or in the file of a plain `include.path` from the
       environment must be a setting, as git 2.54.0 reads those files. None of
       those files comes from a conditional include. *)
    case
      "with a condition hasconfig, a URL outside conditional includes is a \
       setting" (fun () ->
        let hasconfig =
          "[includeIf \"hasconfig:remote.*.url:other\"]\npath = /hit.inc\n"
        in
        let url = content "[remote \"o\"]\nurl = /u\n" in
        let urls ?(env = []) ?working_tree config files =
          match
            fst
              (run_with ?working_tree
                 (include_world ~env:(no_system @ env)
                    ((config_path, content config) :: files)))
          with
          | Ok configuration ->
              show_values (Config.values configuration (key "remote.o.url"))
          | Error error -> error_name error
        in
        List.iter
          (fun (name, actual) ->
            Alcotest.(check string) name (show_values [ Some "/u" ]) actual)
          [
            ( "a global file",
              urls
                ~env:[ ("GIT_CONFIG_GLOBAL", "/global.gitconfig") ]
                hasconfig
                [ ("/global.gitconfig", url) ] );
            ( "the file config.worktree",
              urls ~working_tree:git_folder
                ("[extensions]\nworktreeConfig = true\n" ^ hasconfig)
                [ (git_folder ^ "/config.worktree", url) ] );
            ( "a plain include from the environment",
              urls
                ~env:
                  [
                    ("GIT_CONFIG_COUNT", "1");
                    ("GIT_CONFIG_KEY_0", "include.path");
                    ("GIT_CONFIG_VALUE_0", "/url.inc");
                  ]
                hasconfig
                [ ("/url.inc", url) ] );
          ]);
    case "a limit of no value takes a configuration with no value" (fun () ->
        Alcotest.(check string)
          "empty" "ok"
          (match
             fst
               (run_with
                  ~limits:{ Config.max_files = 10; max_values = 0 }
                  (include_world [ (config_path, content "# nothing\n") ]))
           with
          | Ok _ -> "ok"
          | Error error -> error_name error));
  ]

let unmet_hasconfig_tests =
  let unmet = "[includeIf \"hasconfig:remote.*.url:nothing\"]\n" in
  let url_file = content "[remote \"o\"]\nurl = /u\n" in
  let plain_file = content "[s]\nv = 1\n" in
  let syntax_file = content "[s\n" in
  let run_result ?limits ?(env = no_system) ?git_directories ?working_tree
      ?branch files =
    match
      fst
        (run_with ?limits ?git_directories ?working_tree ?branch
           (include_world ~env files))
    with
    | Ok _ -> "no error"
    | Error error -> error_name error
  in
  let refused path = "remote url in conditional include " ^ path in
  [
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A setting `includeIf.hasconfig:remote.*.url:<pattern>.path`
       whose condition is not met must include the file that its value names,
       as git 2.54.0 reads that file. An error of that value (an unread
       pathname, or a relative pathname from the environment) or of that file
       (an unreadable file, a syntax error, an empty value that names a folder,
       or an include cycle) must be the error of the configuration. A missing
       file, or a value that names no file, must give no error. A variable
       other than `path` under that condition must include no file. The
       settings of that file must not be settings of the configuration. *)
    case "a condition hasconfig that is not met reads its file for errors"
      (fun () ->
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "unreadable file",
              "unreadable /bad.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /bad.inc\n"));
                  ("/bad.inc", Config.Unreadable);
                ] );
            ( "syntax error",
              "syntax /syntax.inc:1",
              run_result
                [
                  (config_path, content (unmet ^ "path = /syntax.inc\n"));
                  ("/syntax.inc", syntax_file);
                ] );
            ( "empty path naming folder",
              "unreadable /r/.git/",
              run_result
                [
                  (config_path, content (unmet ^ "path =\n"));
                  ("/r/.git/", Config.Unreadable);
                ] );
            ( "path without value",
              Printf.sprintf "unread pathname %s %s" config_path
                (show_value None),
              run_result [ (config_path, content (unmet ^ "path\n")) ] );
            ( "tilde path without HOME",
              Printf.sprintf "unread pathname %s %s" config_path
                (show_value (Some "~/x.inc")),
              run_result [ (config_path, content (unmet ^ "path = ~/x.inc\n")) ]
            );
            ( "relative path from environment",
              "relative without file " ^ show_value (Some "x.inc"),
              run_result
                ~env:
                  (no_system
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ( "GIT_CONFIG_KEY_0",
                        "includeIf.hasconfig:remote.*.url:nothing.path" );
                      ("GIT_CONFIG_VALUE_0", "x.inc");
                    ])
                [ (config_path, content "") ] );
            ( "self include cycle",
              "include cycle " ^ config_path,
              run_result [ (config_path, content (unmet ^ "path = config\n")) ]
            );
            ( "uppercase variable PATH",
              "unreadable /bad.inc",
              run_result
                [
                  (config_path, content (unmet ^ "PATH = /bad.inc\n"));
                  ("/bad.inc", Config.Unreadable);
                ] );
            ( "missing file before syntax error",
              "syntax /syntax.inc:1",
              run_result
                [
                  ( config_path,
                    content (unmet ^ "path = /missing.inc\npath = /syntax.inc\n")
                  );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "missing file gives no error",
              "no error",
              run_result
                [ (config_path, content (unmet ^ "path = /missing.inc\n")) ] );
            ( "prefix and optional forms give no error",
              "no error",
              run_result
                [
                  ( config_path,
                    content
                      (unmet
                     ^ "path = %(prefix)/etc/x\npath = :(optional)/etc/x\n") );
                  ("/etc/x", Config.Unreadable);
                ] );
            ( "a variable other than path includes no file",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "foo = /bad.inc\n"));
                  ("/bad.inc", Config.Unreadable);
                ] );
          ];
        let world =
          include_world
            [
              ( config_path,
                content
                  ("[s]\nv = 0\n" ^ unmet ^ "path = /plain.inc\n[s]\nv = 2\n")
              );
              ("/plain.inc", plain_file);
            ]
        in
        let result, read_paths = run_with world in
        let config =
          match result with
          | Ok configuration -> configuration
          | Error error -> Alcotest.failf "plain file: %s" (error_name error)
        in
        Alcotest.(check bool)
          "the reader reads the file of the unmet condition" true
          (List.mem "/plain.inc" read_paths);
        check_values "settings of the unmet file do not apply"
          [ Some "0"; Some "2" ] config "s.v");
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A setting `remote.<name>.url` in a file that an unmet
       condition `hasconfig:remote.*.url:` includes must give
       `Remote_url_in_conditional_include` with the pathname of that file, as
       git 2.54.0 refuses that setting, whether the condition comes from the
       file `config`, a system file, a global file, the file `config.worktree`,
       or the environment. A setting `remote.url` or `remote.<name>.pushurl` is
       not such a setting. The result must be the first error of the files in
       their order. *)
    case "a condition hasconfig that is not met refuses a remote URL" (fun () ->
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "in file config",
              refused "/url.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /url.inc\n"));
                  ("/url.inc", url_file);
                ] );
            ( "a pattern that matches only the URL of the included file",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      "[includeIf \"hasconfig:remote.*.url:/u\"]\n\
                       path = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "uppercase REMOTE and URL",
              refused "/upper.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /upper.inc\n"));
                  ("/upper.inc", content "[REMOTE \"o\"]\nURL = /u\n");
                ] );
            ( "old subsection syntax",
              refused "/old.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /old.inc\n"));
                  ("/old.inc", content "[remote.o]\nurl = /u\n");
                ] );
            ( "empty remote name",
              refused "/empty.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /empty.inc\n"));
                  ("/empty.inc", content "[remote \"\"]\nurl = /u\n");
                ] );
            ( "remote without subsection is no remote URL",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "path = /nosub.inc\n"));
                  ("/nosub.inc", content "[remote]\nurl = /u\n");
                ] );
            ( "pushurl is no remote URL",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "path = /pushurl.inc\n"));
                  ("/pushurl.inc", content "[remote \"o\"]\npushurl = /u\n");
                ] );
            ( "in global file with another remote in config",
              refused "/url.inc",
              run_result
                ~env:(no_system @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content (unmet ^ "path = /url.inc\n"));
                  (config_path, content "[remote \"p\"]\nurl = /v\n");
                  ("/url.inc", url_file);
                ] );
            ( "unreadable include from global file",
              "unreadable /dir.inc",
              run_result
                ~env:(no_system @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content (unmet ^ "path = /dir.inc\n"));
                  (config_path, content "");
                  ("/dir.inc", Config.Unreadable);
                ] );
            ( "in system file",
              refused "/url.inc",
              run_result
                ~env:[ ("GIT_CONFIG_SYSTEM", "/sys") ]
                [
                  ("/sys", content (unmet ^ "path = /url.inc\n"));
                  (config_path, content "");
                  ("/url.inc", url_file);
                ] );
            ( "in config.worktree",
              refused "/url.inc",
              run_result ~working_tree:git_folder
                [
                  (config_path, content "[extensions]\nworktreeConfig = true\n");
                  ( git_folder ^ "/config.worktree",
                    content (unmet ^ "path = /url.inc\n") );
                  ("/url.inc", url_file);
                ] );
            ( "from environment",
              refused "/url.inc",
              run_result
                ~env:
                  (no_system
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ( "GIT_CONFIG_KEY_0",
                        "includeIf.hasconfig:remote.*.url:nothing.path" );
                      ("GIT_CONFIG_VALUE_0", "/url.inc");
                    ])
                [ (config_path, content ""); ("/url.inc", url_file) ] );
            ( "same file in plain include and unmet hasconfig",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      ("[include]\npath = /url.inc\n" ^ unmet
                     ^ "path = /url.inc\n") );
                  ("/url.inc", url_file);
                ] );
            ( "URL before syntax error under unmet hasconfig",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content (unmet ^ "path = /url.inc\npath = /syntax.inc\n") );
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "syntax error before URL under unmet hasconfig",
              "syntax /syntax.inc:1",
              run_result
                [
                  ( config_path,
                    content (unmet ^ "path = /syntax.inc\npath = /url.inc\n") );
                  ("/syntax.inc", syntax_file);
                  ("/url.inc", url_file);
                ] );
            ( "missing file before URL under unmet hasconfig",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content (unmet ^ "path = /missing.inc\npath = /url.inc\n")
                  );
                  ("/url.inc", url_file);
                ] );
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. The settings of a file that an unmet condition
       `hasconfig:remote.*.url:` includes must not be settings of the
       configuration, as git 2.54.0 reads that file, whether the condition
       comes from a global file, the file `config.worktree`, or the
       environment. The settings of the other files must stay settings of the
       configuration. *)
    case "a condition hasconfig that is not met gives no setting in any source"
      (fun () ->
        let global_cfg =
          configuration_of
            (include_world
               ~env:(no_system @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
               [
                 ("/global", content (unmet ^ "path = /plain.inc\n"));
                 (config_path, content "[remote \"p\"]\nurl = /v\n");
                 ("/plain.inc", plain_file);
               ])
        in
        check_values "global unmet file gives no setting" [] global_cfg "s.v";
        check_values "config remote stays" [ Some "/v" ] global_cfg
          "remote.p.url";
        let worktree_cfg =
          configuration_of ~working_tree:git_folder
            (include_world
               [
                 (config_path, content "[extensions]\nworktreeConfig = true\n");
                 ( git_folder ^ "/config.worktree",
                   content (unmet ^ "path = /plain.inc\n[s]\nw = 2\n") );
                 ("/plain.inc", plain_file);
               ])
        in
        check_values "worktree unmet file gives no setting" [] worktree_cfg
          "s.v";
        check_values "worktree own setting stays" [ Some "2" ] worktree_cfg
          "s.w";
        let env_cfg =
          configuration_of
            (include_world
               ~env:
                 (no_system
                 @ [
                     ("GIT_CONFIG_COUNT", "1");
                     ( "GIT_CONFIG_KEY_0",
                       "includeIf.hasconfig:remote.*.url:nothing.path" );
                     ("GIT_CONFIG_VALUE_0", "/plain.inc");
                   ])
               [
                 (config_path, content "[s]\na = 0\n");
                 ("/plain.inc", plain_file);
               ])
        in
        check_values "env unmet file gives no setting" [] env_cfg "s.v";
        check_values "config setting stays" [ Some "0" ] env_cfg "s.a");
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A file that an unmet condition `hasconfig:remote.*.url:`
       includes must include other files by the usual rules, as git 2.54.0
       reads them. In that file, a plain include, a met condition, and a
       condition `hasconfig:remote.*.url:`, met or not, must include their
       files under the same rule: a read error is the error of the
       configuration, a remote URL gives `Remote_url_in_conditional_include`,
       and no setting is a setting of the configuration. Any other condition
       that is not met must include no file. An unmet condition
       `hasconfig:remote.*.url:` in a file of a plain include or of a met
       condition must include its file under the same rule. The settings of the
       other files must stay settings of the configuration. *)
    case "a file under an unmet condition hasconfig follows nested includes"
      (fun () ->
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "plain include to URL",
              refused "/url.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ("/via.inc", content "[include]\npath = /url.inc\n");
                  ("/url.inc", url_file);
                ] );
            ( "plain include to syntax error",
              "syntax /syntax.inc:1",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ("/via.inc", content "[include]\npath = /syntax.inc\n");
                  ("/syntax.inc", syntax_file);
                ] );
            ( "relative path to relative plain include with URL",
              refused "/r/.git/sub/rel_url.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = sub/mid.inc\n"));
                  ( "/r/.git/sub/mid.inc",
                    content "[include]\npath = rel_url.inc\n" );
                  ("/r/.git/sub/rel_url.inc", url_file);
                ] );
            ( "nested unmet hasconfig to unreadable folder",
              "unreadable /dir.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"hasconfig:remote.*.url:still-nothing\"]\n\
                       path = /dir.inc\n" );
                  ("/dir.inc", Config.Unreadable);
                ] );
            ( "nested unmet hasconfig to URL",
              refused "/url.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"hasconfig:remote.*.url:still-nothing\"]\n\
                       path = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "nested met hasconfig to URL",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      ("[remote \"p\"]\nurl = /v\n" ^ unmet
                     ^ "path = /via.inc\n") );
                  ( "/via.inc",
                    content
                      "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                       path = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "met gitdir to URL",
              refused "/url.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"gitdir:/r/.git\"]\npath = /url.inc\n"
                  );
                  ("/url.inc", url_file);
                ] );
            ( "met gitdir to syntax error",
              "syntax /syntax.inc:1",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"gitdir:/r/.git\"]\npath = /syntax.inc\n" );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "met gitdir/i to URL",
              refused "/url.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"gitdir/i:/R/.GIT\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "met relative gitdir:./ to URL",
              refused "/url.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /r/via.inc\n"));
                  ( "/r/via.inc",
                    content "[includeIf \"gitdir:./\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "unmet gitdir to URL",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"gitdir:/nothing/\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "unmet gitdir to syntax error",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"gitdir:/nothing/\"]\npath = /syntax.inc\n"
                  );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "unmet gitdir/i to URL",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"gitdir/i:/NOTHING/\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "met onbranch to URL",
              refused "/url.inc",
              run_result ~working_tree:git_folder ~branch:"main"
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"onbranch:main\"]\npath = /url.inc\n"
                  );
                  ("/url.inc", url_file);
                ] );
            ( "met onbranch to syntax error",
              "syntax /syntax.inc:1",
              run_result ~working_tree:git_folder ~branch:"main"
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"onbranch:main\"]\npath = /syntax.inc\n" );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "unmet onbranch to URL",
              "no error",
              run_result ~working_tree:git_folder ~branch:"main"
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"onbranch:other\"]\npath = /url.inc\n"
                  );
                  ("/url.inc", url_file);
                ] );
            ( "unmet onbranch to syntax error",
              "no error",
              run_result ~working_tree:git_folder ~branch:"main"
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"onbranch:other\"]\npath = /syntax.inc\n" );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "onbranch in repository without working tree",
              refused "/url.inc",
              run_result ~branch:"main"
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"onbranch:**\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "met onbranch to syntax error in repository without working tree",
              "syntax /syntax.inc:1",
              run_result ~branch:"main"
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content
                      "[includeIf \"onbranch:main\"]\npath = /syntax.inc\n" );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "unmet onbranch in repository without working tree",
              "no error",
              run_result ~branch:"other"
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"onbranch:main\"]\npath = /url.inc\n"
                  );
                  ("/url.inc", url_file);
                ] );
            ( "onbranch in detached repository without working tree",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"onbranch:**\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "onbranch in detached working tree",
              "no error",
              run_result ~working_tree:git_folder
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"onbranch:**\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
            ( "unknown condition to syntax error",
              "no error",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"foo:bar\"]\npath = /syntax.inc\n" );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "indirect include cycle via plain include",
              "include cycle /a.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /a.inc\n"));
                  ("/a.inc", content "[include]\npath = /b.inc\n");
                  ("/b.inc", content "[include]\npath = /a.inc\n");
                ] );
            ( "indirect include cycle via unmet hasconfig",
              "include cycle /a.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /a.inc\n"));
                  ("/a.inc", content (unmet ^ "path = /a.inc\n"));
                ] );
            ( "plain include to unmet hasconfig to URL",
              refused "/url.inc",
              run_result
                [
                  (config_path, content "[include]\npath = /via.inc\n");
                  ("/via.inc", content (unmet ^ "path = /url.inc\n"));
                  ("/url.inc", url_file);
                ] );
            ( "met gitdir to unmet hasconfig to URL",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content "[includeIf \"gitdir:/r/.git\"]\npath = /via.inc\n"
                  );
                  ("/via.inc", content (unmet ^ "path = /url.inc\n"));
                  ("/url.inc", url_file);
                ] );
            ( "met onbranch to unmet hasconfig to URL",
              refused "/url.inc",
              run_result ~working_tree:git_folder ~branch:"main"
                [
                  ( config_path,
                    content "[includeIf \"onbranch:main\"]\npath = /via.inc\n"
                  );
                  ("/via.inc", content (unmet ^ "path = /url.inc\n"));
                  ("/url.inc", url_file);
                ] );
            ( "met hasconfig to unmet hasconfig to URL",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                       path = /via.inc\n\
                       [remote \"p\"]\n\
                       url = /v\n" );
                  ("/via.inc", content (unmet ^ "path = /url.inc\n"));
                  ("/url.inc", url_file);
                ] );
          ];
        Alcotest.(check string)
          "indirect include cycle by identity" "cycle"
          (match
             fst
               (run_with
                  (include_world
                     [
                       ( config_path,
                         content ~identity:(1, 1) (unmet ^ "path = /a.inc\n") );
                       ( "/a.inc",
                         content ~identity:(1, 2)
                           "[include]\npath = /link.inc\n" );
                       ( "/link.inc",
                         content ~identity:(1, 2) "[include]\npath = /a.inc\n"
                       );
                     ]))
           with
          | Ok _ -> "no error"
          | Error (Config.Include_cycle _) -> "cycle"
          | Error error -> error_name error);
        let check_no_leak ?working_tree ?branch name via_content =
          let cfg =
            configuration_of ?working_tree ?branch
              (include_world
                 [
                   ( config_path,
                     content
                       ("[remote \"p\"]\nurl = /v\n" ^ unmet
                      ^ "path = /via.inc\n") );
                   ("/via.inc", content via_content);
                   ("/plain.inc", plain_file);
                 ])
          in
          check_values (name ^ ": no s.v") [] cfg "s.v";
          check_values (name ^ ": remote stays") [ Some "/v" ] cfg
            "remote.p.url"
        in
        check_no_leak "plain include under unmet hasconfig"
          "[include]\npath = /plain.inc\n";
        check_no_leak "met gitdir under unmet hasconfig"
          "[includeIf \"gitdir:/r/.git\"]\npath = /plain.inc\n";
        check_no_leak ~working_tree:git_folder ~branch:"main"
          "met onbranch under unmet hasconfig"
          "[includeIf \"onbranch:main\"]\npath = /plain.inc\n";
        check_no_leak ~branch:"main"
          "met onbranch in repository under unmet hasconfig"
          "[includeIf \"onbranch:main\"]\npath = /plain.inc\n";
        check_no_leak "met hasconfig under unmet hasconfig"
          "[s]\n\
           v = 9\n\
           [includeIf \"hasconfig:remote.*.url:/v\"]\n\
           path = /plain.inc\n\
           [s]\n\
           v = 8\n";
        let after_cfg =
          configuration_of
            (include_world
               [
                 ( config_path,
                   content
                     (unmet ^ "path = /p2.inc\n"
                    ^ "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                       path = /p3.inc\n\
                       [remote \"p\"]\n\
                       url = /v\n") );
                 ("/p2.inc", content "[s]\na = 2\n");
                 ("/p3.inc", content "[s]\na = 3\n");
               ])
        in
        check_values "met hasconfig after unmet hasconfig applies" [ Some "3" ]
          after_cfg "s.a";
        let nested_restore_cfg =
          configuration_of
            (include_world
               [
                 ( config_path,
                   content
                     "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                      path = /outer.inc\n\
                      [remote \"p\"]\n\
                      url = /v\n" );
                 ( "/outer.inc",
                   content
                     ("[s]\na = 1\n" ^ unmet ^ "path = /inner.inc\n[s]\na = 3\n")
                 );
                 ("/inner.inc", content "[s]\na = 2\n");
               ])
        in
        check_values "settings before and after inner unmet hasconfig apply"
          [ Some "1"; Some "3" ] nested_restore_cfg "s.a");
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A file that an unmet condition `hasconfig:remote.*.url:`
       includes, and each file that it includes, in turn, must count toward
       `limits.max_files`, and its values toward `limits.max_values`, as any
       other included file does. *)
    case "a file under an unmet condition hasconfig counts toward limits"
      (fun () ->
        let run_limit max_files max_values files =
          match
            fst
              (run_with
                 ~limits:{ Config.max_files; max_values }
                 (include_world files))
          with
          | Ok cfg -> show_values (Config.values cfg (key "s.a"))
          | Error error -> error_name error
        in
        let single =
          [
            ( config_path,
              content ("[s]\nx = 1\n" ^ unmet ^ "path = plain.inc\n") );
            ("/r/.git/plain.inc", content "[s]\na = 1\nb = 2\n");
          ]
        in
        Alcotest.(check string)
          "2 files and 4 values" (show_values []) (run_limit 2 4 single);
        Alcotest.(check string)
          "1 file exceeds max_files" "limit exceeded" (run_limit 1 4 single);
        Alcotest.(check string)
          "3 values exceeds max_values" "limit exceeded" (run_limit 2 3 single);
        let twice =
          [
            ( config_path,
              content (unmet ^ "path = plain.inc\npath = plain.inc\n") );
            ("/r/.git/plain.inc", content "[s]\na = 1\n");
          ]
        in
        Alcotest.(check string)
          "same file twice: 3 files and 4 values" (show_values [])
          (run_limit 3 4 twice);
        Alcotest.(check string)
          "same file twice: 2 files exceeds max_files" "limit exceeded"
          (run_limit 2 4 twice);
        Alcotest.(check string)
          "same file twice: 3 values exceeds max_values" "limit exceeded"
          (run_limit 3 3 twice);
        let nested =
          [
            (config_path, content (unmet ^ "path = /via.inc\n"));
            ("/via.inc", content "[include]\npath = /plain.inc\n");
            ("/plain.inc", content "[s]\na = 1\n");
          ]
        in
        Alcotest.(check string)
          "nested: 3 files and 3 values" (show_values []) (run_limit 3 3 nested);
        Alcotest.(check string)
          "nested: 2 files exceeds max_files" "limit exceeded"
          (run_limit 2 3 nested);
        Alcotest.(check string)
          "nested: 2 values exceeds max_values" "limit exceeded"
          (run_limit 3 2 nested);
        let missing =
          [ (config_path, content (unmet ^ "path = gone.inc\n")) ]
        in
        Alcotest.(check string)
          "missing file: 2 files" (show_values []) (run_limit 2 10 missing);
        Alcotest.(check string)
          "missing file: 1 file exceeds max_files" "limit exceeded"
          (run_limit 1 10 missing));
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. For generated includes in a file that an unmet
       condition `hasconfig:remote.*.url:` includes, the result must be the
       first error of the files that the usual rules include, in their order,
       as git 2.54.0 gives it: a read error, or
       `Remote_url_in_conditional_include` for a remote URL. When those files
       give no error, the result must be a configuration with no setting of
       those files and with the settings of the file `config`. *)
    property ~count:300
      ~name:"generated include trees under an unmet condition hasconfig"
      ~print:(fun entries ->
        String.concat "; "
          (List.map (fun (k, l) -> Printf.sprintf "(%s, %s)" k l) entries))
      Gen.(
        list_size (int_range 1 4)
          (pair
             (oneof_list
                [
                  "setting";
                  "plain";
                  "met_gitdir";
                  "unmet_gitdir";
                  "unmet_hasconfig";
                  "met_hasconfig";
                ])
             (oneof_list [ "plain"; "missing"; "syntax"; "unreadable"; "url" ])))
      (fun entries ->
        let lines = ref [] in
        let files = ref [] in
        let first_error = ref None in
        let record_error err =
          if !first_error = None then first_error := Some err
        in
        List.iteri
          (fun idx (kind, leaf) ->
            let path = Printf.sprintf "/leaf_%d.inc" idx in
            let reachable =
              match kind with
              | "setting" ->
                  lines := Printf.sprintf "[s]\nv = s%d\n" idx :: !lines;
                  false
              | "plain" ->
                  lines :=
                    Printf.sprintf "[include]\npath = %s\n" path :: !lines;
                  true
              | "met_gitdir" ->
                  lines :=
                    Printf.sprintf "[includeIf \"gitdir:/r/.git\"]\npath = %s\n"
                      path
                    :: !lines;
                  true
              | "unmet_gitdir" ->
                  lines :=
                    Printf.sprintf
                      "[includeIf \"gitdir:/nothing/\"]\npath = %s\n" path
                    :: !lines;
                  false
              | "unmet_hasconfig" ->
                  lines :=
                    Printf.sprintf
                      "[includeIf \"hasconfig:remote.*.url:still-nothing\"]\n\
                       path = %s\n"
                      path
                    :: !lines;
                  true
              | _ ->
                  lines :=
                    Printf.sprintf
                      "[includeIf \"hasconfig:remote.*.url:/match\"]\n\
                       path = %s\n"
                      path
                    :: !lines;
                  true
            in
            if kind <> "setting" then
              match leaf with
              | "plain" ->
                  files :=
                    (path, content (Printf.sprintf "[s]\nv = l%d\n" idx))
                    :: !files
              | "missing" -> ()
              | "syntax" ->
                  files := (path, syntax_file) :: !files;
                  if reachable then
                    record_error (Printf.sprintf "syntax %s:1" path)
              | "unreadable" ->
                  files := (path, Config.Unreadable) :: !files;
                  if reachable then record_error ("unreadable " ^ path)
              | _ ->
                  files := (path, url_file) :: !files;
                  if reachable then record_error (refused path))
          entries;
        let mid_content = String.concat "" (List.rev !lines) in
        let world =
          include_world
            (( config_path,
               content
                 ("[remote \"p\"]\nurl = /match\n" ^ unmet ^ "path = /mid.inc\n")
             )
            :: ("/mid.inc", content mid_content)
            :: !files)
        in
        match (fst (run_with world), !first_error) with
        | Ok cfg, None ->
            Config.values cfg (key "s.v") = []
            && Config.values cfg (key "remote.p.url") = [ Some "/match" ]
        | Error err, Some expected -> error_name err = expected
        | _ -> false);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When the read meets the first setting
       `includeIf.hasconfig:remote.*.url:<pattern>.<name>` of the
       configuration, a setting `remote.<name>.url` (with or without a value)
       that the read met before in a file under a met condition must give
       `Remote_url_in_conditional_include` there with the pathname of the first
       such file, as git 2.54.0 refuses it. After that setting, such a remote
       URL must give `Remote_url_in_conditional_include` where the read meets
       it. A read error before that place must come first, and the refusal must
       come before a read error after that place. *)
    case "a remote URL is refused at the first hasconfig setting or where read"
      (fun () ->
        let gitdir path =
          Printf.sprintf "[includeIf \"gitdir:/r/.git\"]\npath = %s\n" path
        in
        let url_none = content "[remote \"o\"]\nurl\n" in
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "read error before first hasconfig wins over earlier conditional \
               URL",
              "syntax /syntax.inc:1",
              run_result
                [
                  ( config_path,
                    content
                      (gitdir "/url.inc" ^ "[include]\npath = /syntax.inc\n"
                     ^ unmet ^ "path = /plain.inc\n") );
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "earlier conditional URL is refused at first hasconfig before \
               later read error",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      (gitdir "/url.inc" ^ unmet ^ "path = /plain.inc\n"
                     ^ "[include]\npath = /syntax.inc\n") );
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "earlier conditional URL is refused before reading file of first \
               hasconfig",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content (gitdir "/url.inc" ^ unmet ^ "path = /syntax.inc\n")
                  );
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "earlier conditional URL is refused at non-path hasconfig before \
               later read error",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      (gitdir "/url.inc" ^ unmet ^ "foo = bar\n"
                     ^ "[include]\npath = /syntax.inc\n") );
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "two earlier conditional URLs report the first file",
              refused "/url1.inc",
              run_result
                [
                  ( config_path,
                    content
                      (gitdir "/url1.inc" ^ gitdir "/url2.inc" ^ unmet
                     ^ "path = /plain.inc\n") );
                  ("/url1.inc", url_file);
                  ("/url2.inc", url_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "later conditional URL after hasconfig is refused before later \
               read error",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      (unmet ^ "path = /plain.inc\n" ^ gitdir "/url.inc"
                     ^ "[include]\npath = /syntax.inc\n") );
                  ("/plain.inc", plain_file);
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "read error after hasconfig wins over later conditional URL",
              "syntax /syntax.inc:1",
              run_result
                [
                  ( config_path,
                    content
                      (unmet ^ "path = /plain.inc\n"
                     ^ "[include]\npath = /syntax.inc\n" ^ gitdir "/url.inc") );
                  ("/plain.inc", plain_file);
                  ("/syntax.inc", syntax_file);
                  ("/url.inc", url_file);
                ] );
            ( "unmet hasconfig URL is refused before later plain include read \
               error",
              refused "/url.inc",
              run_result
                [
                  ( config_path,
                    content
                      (unmet ^ "path = /url.inc\n"
                     ^ "[include]\npath = /syntax.inc\n") );
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "plain include read error before unmet hasconfig URL wins",
              "syntax /syntax.inc:1",
              run_result
                [
                  ( config_path,
                    content
                      ("[include]\npath = /syntax.inc\n" ^ unmet
                     ^ "path = /url.inc\n") );
                  ("/syntax.inc", syntax_file);
                  ("/url.inc", url_file);
                ] );
            ( "unmet hasconfig read error wins over later plain include read \
               error",
              "syntax /syntax.inc:1",
              run_result
                [
                  ( config_path,
                    content
                      (unmet ^ "path = /syntax.inc\n"
                     ^ "[include]\npath = /dir.inc\n") );
                  ("/syntax.inc", syntax_file);
                  ("/dir.inc", Config.Unreadable);
                ] );
            ( "global conditional URL: config read error before hasconfig wins",
              "syntax /syntax.inc:1",
              run_result
                ~env:(no_system @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content (gitdir "/url.inc"));
                  ( config_path,
                    content
                      ("[include]\npath = /syntax.inc\n" ^ unmet
                     ^ "path = /plain.inc\n") );
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "global conditional URL: refused at config hasconfig before \
               later read error",
              refused "/url.inc",
              run_result
                ~env:(no_system @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content (gitdir "/url.inc"));
                  ( config_path,
                    content
                      (unmet ^ "path = /plain.inc\n"
                     ^ "[include]\npath = /syntax.inc\n") );
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "config conditional URL: config read error before env hasconfig \
               wins",
              "syntax /syntax.inc:1",
              run_result
                ~env:
                  (no_system
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ( "GIT_CONFIG_KEY_0",
                        "includeIf.hasconfig:remote.*.url:nothing.path" );
                      ("GIT_CONFIG_VALUE_0", "/plain.inc");
                    ])
                [
                  ( config_path,
                    content
                      (gitdir "/url.inc" ^ "[include]\npath = /syntax.inc\n") );
                  ("/url.inc", url_file);
                  ("/syntax.inc", syntax_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "config conditional URL: refused at env hasconfig before later \
               env read error",
              refused "/url.inc",
              run_result
                ~env:
                  (no_system
                  @ [
                      ("GIT_CONFIG_COUNT", "2");
                      ( "GIT_CONFIG_KEY_0",
                        "includeIf.hasconfig:remote.*.url:nothing.path" );
                      ("GIT_CONFIG_VALUE_0", "/plain.inc");
                      ("GIT_CONFIG_KEY_1", "include.path");
                      ("GIT_CONFIG_VALUE_1", "/syntax.inc");
                    ])
                [
                  (config_path, content (gitdir "/url.inc"));
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "URL without value under unmet hasconfig is refused",
              refused "/url-none.inc",
              run_result
                [
                  (config_path, content (unmet ^ "path = /url-none.inc\n"));
                  ("/url-none.inc", url_none);
                ] );
            ( "URL without value under met hasconfig is refused",
              refused "/url-none.inc",
              run_result
                [
                  ( config_path,
                    content
                      "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                       path = /url-none.inc\n\
                       [remote \"p\"]\n\
                       url = /v\n" );
                  ("/url-none.inc", url_none);
                ] );
            ( "URL without value under met gitdir after hasconfig is refused",
              refused "/url-none.inc",
              run_result
                [
                  ( config_path,
                    content
                      (unmet ^ "path = /plain.inc\n" ^ gitdir "/url-none.inc")
                  );
                  ("/plain.inc", plain_file);
                  ("/url-none.inc", url_none);
                ] );
            ( "URL without value under met gitdir: read error before hasconfig \
               wins",
              "syntax /syntax.inc:1",
              run_result
                [
                  ( config_path,
                    content
                      (gitdir "/url-none.inc"
                     ^ "[include]\npath = /syntax.inc\n" ^ unmet
                     ^ "path = /plain.inc\n") );
                  ("/url-none.inc", url_none);
                  ("/syntax.inc", syntax_file);
                  ("/plain.inc", plain_file);
                ] );
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A met condition in a file that a met condition
       includes, in turn, must include its file as a met condition does, as
       git 2.54.0 reads that file. The settings of that file must be settings
       of the configuration. With no setting
       `includeIf.hasconfig:remote.*.url:<pattern>.<name>`, a remote URL in
       that file must be a setting. A remote URL in that file before the first
       such setting must give `Remote_url_in_conditional_include` at that
       setting, and a read error before that setting must come first. A remote
       URL in that file after that setting must give
       `Remote_url_in_conditional_include` where the read meets it, and a read
       error before the URL must come first. *)
    case
      "a met condition in a file of a met condition includes its file as a met \
       condition" (fun () ->
        let gitdir path =
          Printf.sprintf "[includeIf \"gitdir:/r/.git\"]\npath = %s\n" path
        in
        let check_setting ?working_tree ?branch name files =
          check_values name [ Some "1" ]
            (configuration_of ?working_tree ?branch (include_world files))
            "s.v"
        in
        check_setting "met gitdir in a file of a met gitdir"
          [
            (config_path, content (gitdir "/outer.inc"));
            ("/outer.inc", content (gitdir "/plain.inc"));
            ("/plain.inc", plain_file);
          ];
        check_setting "met hasconfig in a file of a met gitdir"
          [
            ( config_path,
              content (gitdir "/outer.inc" ^ "[remote \"p\"]\nurl = /v\n") );
            ( "/outer.inc",
              content
                "[includeIf \"hasconfig:remote.*.url:/v\"]\npath = /plain.inc\n"
            );
            ("/plain.inc", plain_file);
          ];
        check_setting "met gitdir in a file of a met hasconfig"
          [
            ( config_path,
              content
                "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                 path = /outer.inc\n\
                 [remote \"p\"]\n\
                 url = /v\n" );
            ("/outer.inc", content (gitdir "/plain.inc"));
            ("/plain.inc", plain_file);
          ];
        check_setting ~working_tree:git_folder ~branch:"main"
          "met onbranch in a file of a met gitdir"
          [
            (config_path, content (gitdir "/outer.inc"));
            ( "/outer.inc",
              content "[includeIf \"onbranch:main\"]\npath = /plain.inc\n" );
            ("/plain.inc", plain_file);
          ];
        let nested config =
          [
            (config_path, content config);
            ("/outer.inc", content (gitdir "/url.inc"));
            ("/url.inc", url_file);
            ("/syntax.inc", syntax_file);
            ("/plain.inc", plain_file);
          ]
        in
        check_values "a URL with no condition hasconfig is a setting"
          [ Some "/u" ]
          (configuration_of (include_world (nested (gitdir "/outer.inc"))))
          "remote.o.url";
        let syntax = "[include]\npath = /syntax.inc\n" in
        let condition = unmet ^ "path = /plain.inc\n" in
        List.iter
          (fun (name, expected, config) ->
            Alcotest.(check string) name expected (run_result (nested config)))
          [
            ( "a URL before the condition hasconfig is refused at the condition",
              refused "/url.inc",
              gitdir "/outer.inc" ^ condition ^ syntax );
            ( "a read error before the condition hasconfig comes first",
              "syntax /syntax.inc:1",
              gitdir "/outer.inc" ^ syntax ^ condition );
            ( "a URL after the condition hasconfig is refused where read",
              refused "/url.inc",
              condition ^ gitdir "/outer.inc" ^ syntax );
            ( "a read error before the URL comes first",
              "syntax /syntax.inc:1",
              condition ^ syntax ^ gitdir "/outer.inc" );
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. An unmet condition other than `hasconfig:remote.*.url:`,
       such as `gitdir:`, `onbranch:`, or `hasconfig:remote.*.pushurl:`, must
       read nothing of its file, as git 2.54.0 reads nothing of that file,
       even when that file has a syntax error or holds a condition
       `hasconfig:remote.*.url:`. *)
    case "other unmet conditions read nothing of their files" (fun () ->
        let check_unread ?working_tree ?branch name target files =
          let result, read_paths =
            run_with ?working_tree ?branch (include_world files)
          in
          (match result with
          | Ok _ -> ()
          | Error error ->
              Alcotest.failf "%s: unexpected %s" name (error_name error));
          Alcotest.(check bool)
            (name ^ ": file not read") false
            (List.mem target read_paths)
        in
        check_unread "unmet gitdir to syntax error" "/syntax.inc"
          [
            ( config_path,
              content "[includeIf \"gitdir:/nothing/\"]\npath = /syntax.inc\n"
            );
            ("/syntax.inc", syntax_file);
          ];
        check_unread "unmet gitdir to unmet hasconfig with URL" "/via.inc"
          [
            ( config_path,
              content "[includeIf \"gitdir:/nothing/\"]\npath = /via.inc\n" );
            ("/via.inc", content (unmet ^ "path = /url.inc\n"));
            ("/url.inc", url_file);
          ];
        check_unread ~working_tree:git_folder ~branch:"main"
          "unmet onbranch to unmet hasconfig with URL" "/via.inc"
          [
            ( config_path,
              content "[includeIf \"onbranch:other\"]\npath = /via.inc\n" );
            ("/via.inc", content (unmet ^ "path = /url.inc\n"));
            ("/url.inc", url_file);
          ];
        check_unread "a condition hasconfig on pushurl to syntax error"
          "/syntax.inc"
          [
            ( config_path,
              content
                "[includeIf \"hasconfig:remote.*.pushurl:x\"]\n\
                 path = /syntax.inc\n" );
            ("/syntax.inc", syntax_file);
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A met condition `hasconfig:remote.*.url:` must include
       its file: the settings of that file must be settings of the
       configuration, and a remote URL in that file must give
       `Remote_url_in_conditional_include`, as git 2.54.0 reads that file. *)
    case "a met condition hasconfig includes its file and refuses a remote URL"
      (fun () ->
        let met_cfg =
          configuration_of
            (include_world
               [
                 ( config_path,
                   content
                     "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                      path = /plain.inc\n\
                      [remote \"p\"]\n\
                      url = /v\n" );
                 ("/plain.inc", plain_file);
               ])
        in
        check_values "met hasconfig applies settings" [ Some "1" ] met_cfg "s.v";
        check_values "met hasconfig keeps remote" [ Some "/v" ] met_cfg
          "remote.p.url";
        Alcotest.(check string)
          "met hasconfig refuses URL" (refused "/url.inc")
          (run_result
             [
               ( config_path,
                 content
                   "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                    path = /url.inc\n\
                    [remote \"p\"]\n\
                    url = /v\n" );
               ("/url.inc", url_file);
             ]));
  ]

let follow_git_tests =
  let hasconfig =
    "[includeIf \"hasconfig:remote.*.url:other\"]\npath = /plain.inc\n"
  in
  let unmet = "[includeIf \"hasconfig:remote.*.url:nothing\"]\n" in
  let yes_file = content "[s]\nmet = 1\n" in
  let plain_file = content "[s]\nv = 1\n" in
  let url_file = content "[remote \"o\"]\nurl = /u\n" in
  let syntax_file = content "[s\n" in
  let refused path = "remote url in conditional include " ^ path in
  let unread pathname value =
    Printf.sprintf "unread pathname %s %s" pathname (show_value value)
  in
  let run_result ?(env = no_system) ?git_directories ?working_tree ?branch files
      =
    match
      fst
        (run_with ?git_directories ?working_tree ?branch
           (include_world ~env files))
    with
    | Ok _ -> "no error"
    | Error error -> error_name error
  in
  let empty_home = no_system @ [ ("HOME", "") ] in
  [
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. In a git repository without a working tree, a met
       condition `onbranch:` includes its file in both passes. The condition is
       met in the file `config`, in a global file, in the environment, and in a
       file that a met condition includes. The rules for a remote URL in a file
       that a met condition includes apply to the file of a met condition
       `onbranch:`. An unmet condition `onbranch:` includes no file. The read
       of a git repository reads no file `config.worktree`. *)
    case
      "a condition onbranch in a git repository applies with hasconfig and \
       across sources" (fun () ->
        let onbranch path =
          Printf.sprintf "[includeIf \"onbranch:main\"]\npath = %s\n" path
        in
        check_values "remote URL with no hasconfig" [ Some "/u" ]
          (configuration_of ~branch:"main"
             (include_world
                [
                  (config_path, content (onbranch "/url.inc"));
                  ("/url.inc", url_file);
                ]))
          "remote.o.url";
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "remote URL before hasconfig",
              refused "/url.inc",
              run_result ~branch:"main"
                [
                  (config_path, content (onbranch "/url.inc" ^ hasconfig));
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "remote URL after hasconfig",
              refused "/url.inc",
              run_result ~branch:"main"
                [
                  (config_path, content (hasconfig ^ onbranch "/url.inc"));
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "remote URL through plain include under onbranch with hasconfig",
              refused "/url.inc",
              run_result ~branch:"main"
                [
                  (config_path, content (onbranch "/via.inc" ^ hasconfig));
                  ("/via.inc", content "[include]\npath = /url.inc\n");
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "met onbranch to unmet hasconfig to remote URL",
              refused "/url.inc",
              run_result ~branch:"main"
                [
                  (config_path, content (onbranch "/via.inc"));
                  ("/via.inc", content (unmet ^ "path = /url.inc\n"));
                  ("/url.inc", url_file);
                ] );
          ];
        let both_passes =
          configuration_of ~branch:"main"
            (include_world
               [
                 ( config_path,
                   content
                     (onbranch "/yes.inc"
                    ^ "[includeIf \"hasconfig:remote.*.url:/v\"]\n\
                       path = /plain.inc\n\
                       [remote \"p\"]\n\
                       url = /v\n") );
                 ("/yes.inc", yes_file);
                 ("/plain.inc", plain_file);
               ])
        in
        check_values "onbranch applies in second pass" [ Some "1" ] both_passes
          "s.met";
        check_values "met hasconfig applies alongside onbranch" [ Some "1" ]
          both_passes "s.v";
        let check_unread ?branch name config =
          let result, read_paths =
            run_with ?branch
              (include_world
                 [
                   (config_path, content config);
                   ("/url.inc", url_file);
                   ("/plain.inc", plain_file);
                 ])
          in
          (match result with
          | Ok _ -> ()
          | Error error ->
              Alcotest.failf "%s: unexpected %s" name (error_name error));
          Alcotest.(check bool)
            (name ^ ": file not read") false
            (List.mem "/url.inc" read_paths)
        in
        check_unread ~branch:"main" "unmet onbranch with hasconfig"
          ("[includeIf \"onbranch:other\"]\npath = /url.inc\n" ^ hasconfig);
        check_unread "detached onbranch with hasconfig"
          ("[includeIf \"onbranch:**\"]\npath = /url.inc\n" ^ hasconfig);
        check_values "global onbranch" [ Some "1" ]
          (configuration_of ~branch:"main"
             (include_world
                ~env:(no_system @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content (onbranch "/yes.inc"));
                  (config_path, content "");
                  ("/yes.inc", yes_file);
                ]))
          "s.met";
        check_values "environment onbranch" [ Some "1" ]
          (configuration_of ~branch:"main"
             (include_world
                ~env:
                  (no_system
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ("GIT_CONFIG_KEY_0", "includeIf.onbranch:main.path");
                      ("GIT_CONFIG_VALUE_0", "/yes.inc");
                    ])
                [ (config_path, content ""); ("/yes.inc", yes_file) ]))
          "s.met";
        check_values "met onbranch in a file of a met gitdir" [ Some "1" ]
          (configuration_of ~branch:"main"
             (include_world
                [
                  ( config_path,
                    content
                      "[includeIf \"gitdir:/r/.git\"]\npath = /outer.inc\n" );
                  ("/outer.inc", content (onbranch "/yes.inc"));
                  ("/yes.inc", yes_file);
                ]))
          "s.met";
        let no_worktree_cfg =
          configuration_of ~branch:"main"
            (include_world
               [
                 ( config_path,
                   content
                     ("[extensions]\nworktreeConfig = true\n"
                    ^ onbranch "/yes.inc") );
                 (git_folder ^ "/config.worktree", content "[s]\nwt = 2\n");
                 ("/yes.inc", yes_file);
               ])
        in
        check_values "onbranch applies without working tree" [ Some "1" ]
          no_worktree_cfg "s.met";
        check_values "config.worktree stays unread" [] no_worktree_cfg "s.wt");
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `branch` is `Some name`, `of_repository` and
       `of_working_tree` meet a condition `onbranch:` when
       `Sinter_wildmatch.matches` matches `name`, with `**` after a pattern
       that ends with `/`. When `branch` is `None`, neither function meets the
       condition. *)
    property ~count:300
      ~name:
        "a condition onbranch in a git repository matches the wildmatch rule"
      ~print:(fun (branch, pattern) ->
        Printf.sprintf "(%s, %S)"
          (match branch with None -> "None" | Some b -> Printf.sprintf "%S" b)
          pattern)
      Gen.(
        pair
          (option
             (map (String.concat "/")
                (list_size (int_range 1 3)
                   (oneof_list [ "main"; "feat"; "a"; "b"; "MAIN" ]))))
          (oneof_list
             [
               "main";
               "other";
               "MAIN";
               "feat/";
               "feat/*";
               "feat/**";
               "a/";
               "a/*";
               "*/a";
               "*";
               "**";
               "?";
               "";
               "a/?/b";
             ]))
      (fun (branch, pattern) ->
        let expected =
          match branch with
          | None -> "not met"
          | Some name ->
              let full =
                if String.ends_with ~suffix:"/" pattern then pattern ^ "**"
                else pattern
              in
              if Sinter_wildmatch.matches (Sinter_wildmatch.compile full) name
              then "met"
              else "not met"
        in
        let cond = "onbranch:" ^ pattern in
        conditional ?branch cond = expected
        && conditional ~working_tree:git_folder ?branch cond = expected);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `HOME` is not set, a condition `gitdir:` or
       `gitdir/i:` whose pattern starts with `~/` is not met, and the read
       gives no error. The condition is not met in the file `config`, in a
       global file, in the file `config.worktree`, in the environment, and in a
       file that an unmet condition `hasconfig:remote.*.url:` includes. When
       `HOME` is not set, a value `~/...` of a met
       `includeIf.<condition>.path` gives `Unread_pathname`. *)
    case "a condition gitdir with ~/ is not met when HOME is not set" (fun () ->
        List.iter
          (fun (name, git_directories, condition) ->
            Alcotest.(check string)
              name "not met"
              (conditional ~git_directories condition))
          [
            ("gitdir/i:~/W/", [ git_folder ], "gitdir/i:~/W/");
            ("gitdir:~/", [ git_folder ], "gitdir:~/");
            ( "gitdir:~/r/.git does not expand ~ to /",
              [ git_folder ],
              "gitdir:~/r/.git" );
          ];
        let result, read_paths =
          run_with
            (include_world
               [
                 ( config_path,
                   content
                     "[includeIf \"gitdir:~/w/\"]\n\
                      path = /syntax.inc\n\
                      path = ~/y.inc\n\
                      path\n" );
                 ("/syntax.inc", syntax_file);
               ])
        in
        (match result with
        | Ok _ -> ()
        | Error error ->
            Alcotest.failf "HOME unset with bad paths: %s" (error_name error));
        Alcotest.(check bool)
          "syntax file not read" false
          (List.mem "/syntax.inc" read_paths);
        List.iter
          (fun (name, actual) -> Alcotest.(check string) name "no error" actual)
          [
            ( "global file",
              run_result
                ~env:(no_system @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ( "/global",
                    content "[includeIf \"gitdir:~/w/\"]\npath = /syntax.inc\n"
                  );
                  (config_path, content "");
                  ("/syntax.inc", syntax_file);
                ] );
            ( "config.worktree",
              run_result ~working_tree:git_folder
                [
                  (config_path, content "[extensions]\nworktreeConfig = true\n");
                  ( git_folder ^ "/config.worktree",
                    content "[includeIf \"gitdir:~/w/\"]\npath = /syntax.inc\n"
                  );
                  ("/syntax.inc", syntax_file);
                ] );
            ( "environment",
              run_result
                ~env:
                  (no_system
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ("GIT_CONFIG_KEY_0", "includeIf.gitdir:~/w/.path");
                      ("GIT_CONFIG_VALUE_0", "/syntax.inc");
                    ])
                [ (config_path, content ""); ("/syntax.inc", syntax_file) ] );
            ( "unmet hasconfig to gitdir:~/w/ to URL",
              run_result
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"gitdir:~/w/\"]\npath = /url.inc\n" );
                  ("/url.inc", url_file);
                ] );
          ];
        Alcotest.(check string)
          "met includeIf path ~/ still fails without HOME"
          (unread config_path (Some "~/plain.inc"))
          (run_result
             [
               ( config_path,
                 content "[includeIf \"gitdir:/r/.git\"]\npath = ~/plain.inc\n"
               );
             ]));
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `HOME` is empty, a setting
       `includeIf.<condition>.path` whose condition is `gitdir:` or `gitdir/i:`
       with a pattern that starts with `~/` gives `Unread_pathname` in any
       source and in a file that an unmet condition `hasconfig:remote.*.url:`
       includes. The error holds the pathname of the file (or `None` for the
       environment) and the value of the setting. When `HOME` is empty, a
       pattern without `~` keeps its rules, and a value `~/x` of `include.path`
       or of a met `includeIf.<condition>.path` names the file `/x`. *)
    case "a condition gitdir with ~/ gives Unread_pathname when HOME is empty"
      (fun () ->
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "gitdir:~/x/",
              unread config_path (Some "/yes.inc"),
              conditional ~env:empty_home "gitdir:~/x/" );
            ( "gitdir/i:~/x/",
              unread config_path (Some "/yes.inc"),
              conditional ~env:empty_home "gitdir/i:~/x/" );
            ( "gitdir:~/",
              unread config_path (Some "/yes.inc"),
              conditional ~env:empty_home "gitdir:~/" );
            ( "prefix target",
              unread config_path (Some "%(prefix)/etc/x"),
              run_result ~env:empty_home
                [
                  ( config_path,
                    content
                      "[includeIf \"gitdir:~/x/\"]\npath = %(prefix)/etc/x\n" );
                ] );
            ( "path without value",
              unread config_path None,
              run_result ~env:empty_home
                [ (config_path, content "[includeIf \"gitdir:~/x/\"]\npath\n") ]
            );
            ( "global file",
              unread "/global" (Some "/yes.inc"),
              run_result
                ~env:(empty_home @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ( "/global",
                    content "[includeIf \"gitdir:~/x/\"]\npath = /yes.inc\n" );
                  (config_path, content "");
                ] );
            ( "system file",
              unread "/sys" (Some "/yes.inc"),
              run_result
                ~env:[ ("GIT_CONFIG_SYSTEM", "/sys"); ("HOME", "") ]
                [
                  ( "/sys",
                    content "[includeIf \"gitdir:~/x/\"]\npath = /yes.inc\n" );
                  (config_path, content "");
                ] );
            ( "config.worktree",
              unread (git_folder ^ "/config.worktree") (Some "/yes.inc"),
              run_result ~env:empty_home ~working_tree:git_folder
                [
                  (config_path, content "[extensions]\nworktreeConfig = true\n");
                  ( git_folder ^ "/config.worktree",
                    content "[includeIf \"gitdir:~/x/\"]\npath = /yes.inc\n" );
                ] );
            ( "environment gitdir",
              unread "<environment>" (Some "/yes.inc"),
              run_result
                ~env:
                  (empty_home
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ("GIT_CONFIG_KEY_0", "includeIf.gitdir:~/x/.path");
                      ("GIT_CONFIG_VALUE_0", "/yes.inc");
                    ])
                [ (config_path, content "") ] );
            ( "unmet hasconfig to gitdir:~/x/",
              unread "/via.inc" (Some "/yes.inc"),
              run_result ~env:empty_home
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"gitdir:~/x/\"]\npath = /yes.inc\n" );
                ] );
            ( "unmet gitdir to gitdir:~/x/ is not read",
              "no error",
              run_result ~env:empty_home
                [
                  ( config_path,
                    content
                      "[includeIf \"gitdir:/nothing/\"]\npath = /via.inc\n" );
                  ( "/via.inc",
                    content "[includeIf \"gitdir:~/x/\"]\npath = /yes.inc\n" );
                ] );
            ( "control: met gitdir without ~/",
              "met",
              conditional ~env:empty_home "gitdir:/r/.git" );
            ( "control: relative gitdir:./",
              "not met",
              conditional ~env:empty_home "gitdir:./" );
            ( "control: met includeIf path ~/ of missing file",
              "no error",
              run_result ~env:empty_home
                [
                  ( config_path,
                    content
                      "[includeIf \"gitdir:/r/.git\"]\npath = ~/missing.inc\n"
                  );
                ] );
          ];
        let result, read_paths =
          run_with
            (include_world ~env:empty_home
               [
                 ( config_path,
                   content "[includeIf \"gitdir:~/x/\"]\npath = /syntax.inc\n"
                 );
                 ("/syntax.inc", syntax_file);
               ])
        in
        Alcotest.(check string)
          "error before reading target file"
          (unread config_path (Some "/syntax.inc"))
          (match result with
          | Ok _ -> "no error"
          | Error error -> error_name error);
        Alcotest.(check bool)
          "target file not read" false
          (List.mem "/syntax.inc" read_paths);
        check_values "control: include.path ~/ expands to / with empty HOME"
          [ Some "1" ]
          (configuration_of
             (include_world ~env:empty_home
                [
                  (config_path, content "[include]\npath = ~/yes.inc\n");
                  ("/yes.inc", yes_file);
                ]))
          "s.met");
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `HOME` is empty, `Unread_pathname` for a condition
       `gitdir:` or `gitdir/i:` whose pattern starts with `~/` occurs at the
       place of its setting in the order of the files, their lines, and the
       environment. *)
    case "an error of gitdir with ~/ and empty HOME keeps the order of errors"
      (fun () ->
        let tilde = "[includeIf \"gitdir:~/x/\"]\npath = /yes.inc\n" in
        let syntax = "[include]\npath = /syntax.inc\n" in
        let met_gitdir = "[includeIf \"gitdir:/r/.git\"]\npath = /url.inc\n" in
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "syntax include before gitdir:~/x/",
              "syntax /syntax.inc:1",
              run_result ~env:empty_home
                [
                  (config_path, content (syntax ^ tilde));
                  ("/syntax.inc", syntax_file);
                ] );
            ( "gitdir:~/x/ before syntax include",
              unread config_path (Some "/yes.inc"),
              run_result ~env:empty_home
                [
                  (config_path, content (tilde ^ syntax));
                  ("/syntax.inc", syntax_file);
                ] );
            ( "global gitdir:~/x/ before config syntax include",
              unread "/global" (Some "/yes.inc"),
              run_result
                ~env:(empty_home @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content tilde);
                  (config_path, content syntax);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "global syntax include before config gitdir:~/x/",
              "syntax /syntax.inc:1",
              run_result
                ~env:(empty_home @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content syntax);
                  (config_path, content tilde);
                  ("/syntax.inc", syntax_file);
                ] );
            ( "config gitdir:~/x/ before environment syntax include",
              unread config_path (Some "/yes.inc"),
              run_result
                ~env:
                  (empty_home
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ("GIT_CONFIG_KEY_0", "include.path");
                      ("GIT_CONFIG_VALUE_0", "/syntax.inc");
                    ])
                [ (config_path, content tilde); ("/syntax.inc", syntax_file) ]
            );
            ( "config syntax include before environment gitdir:~/x/",
              "syntax /syntax.inc:1",
              run_result
                ~env:
                  (empty_home
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ("GIT_CONFIG_KEY_0", "includeIf.gitdir:~/x/.path");
                      ("GIT_CONFIG_VALUE_0", "/yes.inc");
                    ])
                [ (config_path, content syntax); ("/syntax.inc", syntax_file) ]
            );
            ( "in unmet hasconfig: gitdir:~/x/ before remote URL",
              unread "/via.inc" (Some "/yes.inc"),
              run_result ~env:empty_home
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ("/via.inc", content (tilde ^ "[remote \"o\"]\nurl = /u\n"));
                ] );
            ( "in unmet hasconfig: remote URL before gitdir:~/x/",
              refused "/via.inc",
              run_result ~env:empty_home
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ("/via.inc", content ("[remote \"o\"]\nurl = /u\n" ^ tilde));
                ] );
            ( "gitdir:~/x/ before first hasconfig wins over earlier \
               conditional URL",
              unread config_path (Some "/yes.inc"),
              run_result ~env:empty_home
                [
                  (config_path, content (met_gitdir ^ tilde ^ hasconfig));
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "earlier conditional URL refused at first hasconfig before later \
               gitdir:~/x/",
              refused "/url.inc",
              run_result ~env:empty_home
                [
                  (config_path, content (met_gitdir ^ hasconfig ^ tilde));
                  ("/url.inc", url_file);
                  ("/plain.inc", plain_file);
                ] );
            ( "gitdir:~/x/ after hasconfig wins over later conditional URL",
              unread config_path (Some "/yes.inc"),
              run_result ~env:empty_home
                [
                  (config_path, content (hasconfig ^ tilde ^ met_gitdir));
                  ("/plain.inc", plain_file);
                  ("/url.inc", url_file);
                ] );
            ( "unmet hasconfig URL before gitdir:~/x/",
              refused "/url.inc",
              run_result ~env:empty_home
                [
                  (config_path, content (unmet ^ "path = /url.inc\n" ^ tilde));
                  ("/url.inc", url_file);
                ] );
            ( "gitdir:~/x/ before unmet hasconfig URL",
              unread config_path (Some "/yes.inc"),
              run_result ~env:empty_home
                [
                  (config_path, content (tilde ^ unmet ^ "path = /url.inc\n"));
                  ("/url.inc", url_file);
                ] );
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `HOME` is set and not empty, the pattern `~` of a
       condition `gitdir:` or `gitdir/i:` becomes the value of `HOME`, and the
       condition matches by `Sinter_wildmatch.matches`. The condition is met in
       the file `config`, in a global file, in the system file, in the file
       `config.worktree`, and in the environment. When `HOME` is not set, that
       condition is not met, and the read gives no error. When `HOME` is empty,
       each setting under that condition gives `Unread_pathname` with its file
       and its value. *)
    case "a condition gitdir with exact ~ follows HOME" (fun () ->
        let home_git = no_system @ [ ("HOME", git_folder) ] in
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "HOME equals git folder",
              "met",
              conditional ~env:home_git "gitdir:~" );
            ( "HOME equals parent of git folder",
              "not met",
              conditional ~env:(no_system @ [ ("HOME", "/r") ]) "gitdir:~" );
            ( "gitdir:~ is case sensitive",
              "not met",
              conditional ~env:(no_system @ [ ("HOME", "/R/.GIT") ]) "gitdir:~"
            );
            ( "gitdir/i:~ folds case",
              "met",
              conditional
                ~env:(no_system @ [ ("HOME", "/R/.GIT") ])
                "gitdir/i:~" );
            ( "gitdir/i:~ does not match parent",
              "not met",
              conditional ~env:(no_system @ [ ("HOME", "/R") ]) "gitdir/i:~" );
            ( "HOME holding ~ does not expand twice",
              "met",
              conditional ~git_directories:[ "/sub/~x" ]
                ~env:(no_system @ [ ("HOME", "/sub/~x") ])
                "gitdir:~" );
            ("HOME unset gitdir:~", "not met", conditional "gitdir:~");
            ( "HOME empty gitdir:~",
              unread config_path (Some "/yes.inc"),
              conditional ~env:empty_home "gitdir:~" );
            ( "HOME empty gitdir/i:~",
              unread config_path (Some "/yes.inc"),
              conditional ~env:empty_home "gitdir/i:~" );
            ( "HOME empty gitdir:~ path without value",
              unread config_path None,
              run_result ~env:empty_home
                [ (config_path, content "[includeIf \"gitdir:~\"]\npath\n") ] );
            ( "HOME empty gitdir:~ path with ~/",
              unread config_path (Some "~/yes.inc"),
              run_result ~env:empty_home
                [
                  ( config_path,
                    content "[includeIf \"gitdir:~\"]\npath = ~/yes.inc\n" );
                ] );
            ( "HOME empty gitdir:~ foo=bar",
              unread config_path (Some "bar"),
              run_result ~env:empty_home
                [
                  (config_path, content "[includeIf \"gitdir:~\"]\nfoo = bar\n");
                ] );
            ( "HOME empty gitdir:~ foo without value",
              unread config_path None,
              run_result ~env:empty_home
                [ (config_path, content "[includeIf \"gitdir:~\"]\nfoo\n") ] );
            ( "HOME empty gitdir/i:~ foo=bar",
              unread config_path (Some "bar"),
              run_result ~env:empty_home
                [
                  ( config_path,
                    content "[includeIf \"gitdir/i:~\"]\nfoo = bar\n" );
                ] );
            ( "HOME unset system gitdir:~",
              "no error",
              run_result
                ~env:[ ("GIT_CONFIG_SYSTEM", "/sys") ]
                [
                  ( "/sys",
                    content "[includeIf \"gitdir:~\"]\npath = /syntax.inc\n" );
                  (config_path, content "");
                  ("/syntax.inc", syntax_file);
                ] );
          ];
        check_values "HOME set global gitdir:~" [ Some "1" ]
          (configuration_of
             (include_world
                ~env:(home_git @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ( "/global",
                    content "[includeIf \"gitdir:~\"]\npath = /yes.inc\n" );
                  (config_path, content "");
                  ("/yes.inc", yes_file);
                ]))
          "s.met";
        check_values "HOME set system gitdir:~" [ Some "1" ]
          (configuration_of
             (include_world
                ~env:[ ("GIT_CONFIG_SYSTEM", "/sys"); ("HOME", git_folder) ]
                [
                  ("/sys", content "[includeIf \"gitdir:~\"]\npath = /yes.inc\n");
                  (config_path, content "");
                  ("/yes.inc", yes_file);
                ]))
          "s.met";
        check_values "HOME set config.worktree gitdir:~" [ Some "1" ]
          (configuration_of ~working_tree:git_folder
             (include_world ~env:home_git
                [
                  (config_path, content "[extensions]\nworktreeConfig = true\n");
                  ( git_folder ^ "/config.worktree",
                    content "[includeIf \"gitdir:~\"]\npath = /yes.inc\n" );
                  ("/yes.inc", yes_file);
                ]))
          "s.met";
        check_values "HOME set environment gitdir:~" [ Some "1" ]
          (configuration_of
             (include_world
                ~env:
                  (home_git
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ("GIT_CONFIG_KEY_0", "includeIf.gitdir:~.path");
                      ("GIT_CONFIG_VALUE_0", "/yes.inc");
                    ])
                [ (config_path, content ""); ("/yes.inc", yes_file) ]))
          "s.met";
        check_values "HOME set gitdir:~ with path ~/yes.inc" [ Some "1" ]
          (configuration_of
             (include_world ~env:home_git
                [
                  ( config_path,
                    content "[includeIf \"gitdir:~\"]\npath = ~/yes.inc\n" );
                  (git_folder ^ "/yes.inc", yes_file);
                ]))
          "s.met";
        let unset_res, unset_reads =
          run_with
            (include_world
               [
                 ( config_path,
                   content
                     "[includeIf \"gitdir:~\"]\n\
                      path = /syntax.inc\n\
                      path = ~/y.inc\n\
                      path\n\
                      foo = bar\n" );
                 ("/syntax.inc", syntax_file);
               ])
        in
        (match unset_res with
        | Ok cfg ->
            check_values "HOME unset gitdir:~ keeps foo" [ Some "bar" ] cfg
              "includeIf.gitdir:~.foo"
        | Error error ->
            Alcotest.failf "HOME unset gitdir:~: %s" (error_name error));
        Alcotest.(check bool)
          "HOME unset gitdir:~ does not read target" false
          (List.mem "/syntax.inc" unset_reads));
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `HOME` is empty, each setting
       `includeIf.<condition>.<name>`, for any `<name>` and with a value or
       with none, whose condition is `gitdir:` or `gitdir/i:` with a pattern
       that starts with `~/`, gives `Unread_pathname` with its file (or `None`
       for the environment) and its value. The error comes in any source and in
       a file that an unmet condition `hasconfig:remote.*.url:` includes. A
       section with no setting gives no error. *)
    case
      "a setting other than path under gitdir with ~/ gives Unread_pathname \
       when HOME is empty" (fun () ->
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "gitdir:~/x/ foo=bar",
              unread config_path (Some "bar"),
              run_result ~env:empty_home
                [
                  ( config_path,
                    content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n" );
                ] );
            ( "gitdir:~/x/ foo without value",
              unread config_path None,
              run_result ~env:empty_home
                [ (config_path, content "[includeIf \"gitdir:~/x/\"]\nfoo\n") ]
            );
            ( "gitdir:~/x/ foo empty value",
              unread config_path (Some ""),
              run_result ~env:empty_home
                [
                  (config_path, content "[includeIf \"gitdir:~/x/\"]\nfoo =\n");
                ] );
            ( "gitdir/i:~/x/ foo=bar",
              unread config_path (Some "bar"),
              run_result ~env:empty_home
                [
                  ( config_path,
                    content "[includeIf \"gitdir/i:~/x/\"]\nfoo = bar\n" );
                ] );
            ( "uppercase section INCLUDEIF",
              unread config_path (Some "bar"),
              run_result ~env:empty_home
                [
                  ( config_path,
                    content "[INCLUDEIF \"gitdir:~/x/\"]\nfoo = bar\n" );
                ] );
            ( "uppercase condition GITDIR is not gitdir",
              "no error",
              run_result ~env:empty_home
                [
                  ( config_path,
                    content "[includeIf \"GITDIR:~/x/\"]\nfoo = bar\n" );
                ] );
            ( "empty section gives no error",
              "no error",
              run_result ~env:empty_home
                [ (config_path, content "[includeIf \"gitdir:~/x/\"]\n") ] );
            ( "global file foo=bar",
              unread "/global" (Some "bar"),
              run_result
                ~env:(empty_home @ [ ("GIT_CONFIG_GLOBAL", "/global") ])
                [
                  ("/global", content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n");
                  (config_path, content "");
                ] );
            ( "system file foo=bar",
              unread "/sys" (Some "bar"),
              run_result
                ~env:[ ("GIT_CONFIG_SYSTEM", "/sys"); ("HOME", "") ]
                [
                  ("/sys", content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n");
                  (config_path, content "");
                ] );
            ( "config.worktree foo=bar",
              unread (git_folder ^ "/config.worktree") (Some "bar"),
              run_result ~env:empty_home ~working_tree:git_folder
                [
                  (config_path, content "[extensions]\nworktreeConfig = true\n");
                  ( git_folder ^ "/config.worktree",
                    content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n" );
                ] );
            ( "plain include to foo=bar",
              unread "/via.inc" (Some "bar"),
              run_result ~env:empty_home
                [
                  (config_path, content "[include]\npath = /via.inc\n");
                  ( "/via.inc",
                    content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n" );
                ] );
            ( "environment gitdir:~/x/ foo=bar",
              unread "<environment>" (Some "bar"),
              run_result
                ~env:
                  (empty_home
                  @ [
                      ("GIT_CONFIG_COUNT", "1");
                      ("GIT_CONFIG_KEY_0", "includeIf.gitdir:~/x/.foo");
                      ("GIT_CONFIG_VALUE_0", "bar");
                    ])
                [ (config_path, content "") ] );
            ( "unmet hasconfig to gitdir:~/x/ foo=bar",
              unread "/via.inc" (Some "bar"),
              run_result ~env:empty_home
                [
                  (config_path, content (unmet ^ "path = /via.inc\n"));
                  ( "/via.inc",
                    content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n" );
                ] );
            ( "unmet gitdir to gitdir:~/x/ foo=bar is unread",
              "no error",
              run_result ~env:empty_home
                [
                  ( config_path,
                    content
                      "[includeIf \"gitdir:/nothing/\"]\npath = /via.inc\n" );
                  ( "/via.inc",
                    content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n" );
                ] );
          ];
        let first_res, first_reads =
          run_with
            (include_world ~env:empty_home
               [
                 ( config_path,
                   content
                     "[includeIf \"gitdir:~/x/\"]\n\
                      foo = bar\n\
                      path = /syntax.inc\n" );
                 ("/syntax.inc", syntax_file);
               ])
        in
        Alcotest.(check string)
          "an earlier setting other than path wins over a later path"
          (unread config_path (Some "bar"))
          (match first_res with
          | Ok _ -> "no error"
          | Error error -> error_name error);
        Alcotest.(check bool)
          "later syntax target not read" false
          (List.mem "/syntax.inc" first_reads);
        check_values "control: HOME empty gitdir:/nothing/ foo=bar keeps value"
          [ Some "bar" ]
          (configuration_of
             (include_world ~env:empty_home
                [
                  ( config_path,
                    content "[includeIf \"gitdir:/nothing/\"]\nfoo = bar\n" );
                ]))
          "includeIf.gitdir:/nothing/.foo";
        check_values "control: HOME unset gitdir:~/x/ foo=bar keeps value"
          [ Some "bar" ]
          (configuration_of
             (include_world
                [
                  ( config_path,
                    content "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n" );
                ]))
          "includeIf.gitdir:~/x/.foo";
        let met_res, met_reads =
          run_with ~git_directories:[ "/h/w/.git" ]
            (include_world
               ~env:(no_system @ [ ("HOME", "/h") ])
               [
                 ( config_path,
                   content "[includeIf \"gitdir:~/w/\"]\nfoo = /yes.inc\n" );
                 ("/yes.inc", yes_file);
               ])
        in
        (match met_res with
        | Ok cfg ->
            check_values "control: met gitdir:~/w/ foo does not include" [] cfg
              "s.met";
            check_values "control: met gitdir:~/w/ foo keeps value"
              [ Some "/yes.inc" ] cfg "includeIf.gitdir:~/w/.foo"
        | Error error ->
            Alcotest.failf "met gitdir:~/w/ foo: %s" (error_name error));
        Alcotest.(check bool)
          "control: met gitdir:~/w/ foo does not read file" false
          (List.mem "/yes.inc" met_reads));
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. When `HOME` is empty, the error `Unread_pathname` of a
       setting other than `path` under a condition `gitdir:` or `gitdir/i:`
       with a pattern `~` or `~/...` comes at the place of that setting in the
       order of the lines, with the value of that setting. *)
    case
      "an error of a setting other than path with an empty HOME keeps the \
       order of errors" (fun () ->
        let tilde_foo = "[includeIf \"gitdir:~/x/\"]\nfoo = bar\n" in
        let syntax = "[include]\npath = /syntax.inc\n" in
        List.iter
          (fun (name, expected, actual) ->
            Alcotest.(check string) name expected actual)
          [
            ( "foo=bar before syntax include",
              unread config_path (Some "bar"),
              run_result ~env:empty_home
                [
                  (config_path, content (tilde_foo ^ syntax));
                  ("/syntax.inc", syntax_file);
                ] );
            ( "syntax include before foo=bar",
              "syntax /syntax.inc:1",
              run_result ~env:empty_home
                [
                  (config_path, content (syntax ^ tilde_foo));
                  ("/syntax.inc", syntax_file);
                ] );
            ( "gitdir:/nothing/ foo=bar before gitdir:~ baz=qux reports qux",
              unread config_path (Some "qux"),
              run_result ~env:empty_home
                [
                  ( config_path,
                    content
                      "[includeIf \"gitdir:/nothing/\"]\n\
                       foo = bar\n\
                       [includeIf \"gitdir:~\"]\n\
                       baz = qux\n" );
                ] );
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. A condition `gitdir:` or `gitdir/i:` whose pattern
       starts with `~` and then a byte other than `/` keeps its `~` and gives
       no error, whether `HOME` is set, not set, or empty. *)
    case "a condition gitdir starting with ~ and another byte keeps its ~"
      (fun () ->
        let homes =
          [
            ("HOME set", no_system @ [ ("HOME", "/h") ]);
            ("HOME unset", no_system);
            ("HOME empty", empty_home);
          ]
        in
        List.iter
          (fun (home_label, env) ->
            List.iter
              (fun (label, git_directories, condition, expected) ->
                Alcotest.(check string)
                  (home_label ^ ": " ^ label)
                  expected
                  (conditional ~git_directories ~env condition))
              [
                ( "gitdir:~x/ matches ~x dir",
                  [ "/r/~x/repo/.git" ],
                  "gitdir:~x/",
                  "met" );
                ( "gitdir/i:~X/ matches ~x dir",
                  [ "/r/~x/repo/.git" ],
                  "gitdir/i:~X/",
                  "met" );
                ( "gitdir:~x/ does not match x dir",
                  [ "/r/x/repo/.git" ],
                  "gitdir:~x/",
                  "not met" );
                ( "gitdir:~x matches bare ~x",
                  [ "/r/sub/~x" ],
                  "gitdir:~x",
                  "met" );
                ( "gitdir:~~ matches bare ~~",
                  [ "/r/sub/~~" ],
                  "gitdir:~~",
                  "met" );
                ( "gitdir:~*/ matches ~x dir",
                  [ "/r/~x/repo/.git" ],
                  "gitdir:~*/",
                  "met" );
                ( "gitdir:~nobody/x/ is not met",
                  [ git_folder ],
                  "gitdir:~nobody/x/",
                  "not met" );
              ])
          homes;
        check_values "HOME empty gitdir:~x/ foo=bar keeps value" [ Some "bar" ]
          (configuration_of
             (include_world ~env:empty_home
                [
                  ( config_path,
                    content "[includeIf \"gitdir:~x/\"]\nfoo = bar\n" );
                ]))
          "includeIf.gitdir:~x/.foo";
        Alcotest.(check string)
          "HOME empty environment gitdir:~x/ foo=bar" "no error"
          (run_result
             ~env:
               (empty_home
               @ [
                   ("GIT_CONFIG_COUNT", "1");
                   ("GIT_CONFIG_KEY_0", "includeIf.gitdir:~x/.foo");
                   ("GIT_CONFIG_VALUE_0", "bar");
                 ])
             [ (config_path, content "") ]);
        Alcotest.(check string)
          "HOME empty unmet hasconfig to gitdir:~x/ foo=bar" "no error"
          (run_result ~env:empty_home
             [
               (config_path, content (unmet ^ "path = /via.inc\n"));
               ("/via.inc", content "[includeIf \"gitdir:~x/\"]\nfoo = bar\n");
             ]));
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. For generated patterns of a condition `gitdir:` or
       `gitdir/i:`, variable names, and values, the read gives
       `Unread_pathname` when `HOME` is empty and the pattern is `~` or starts
       with `~/`. When `HOME` is not set, a condition with such a pattern is not
       met, and the read gives no error. In every other case, the `~` of a
       pattern `~` or `~/...` becomes the value of `HOME`, the condition
       matches by `Sinter_wildmatch.matches`, and the read includes a file only
       when the variable name is `path`. *)
    property ~count:300
      ~name:
        "a condition gitdir with ~ or ~/ or ~name follows HOME for any variable"
      ~print:(fun (case_fold, pattern, var_name, var_value, home, git_dir) ->
        Printf.sprintf "(%b, %S, %S, %s, %s, %S)" case_fold pattern var_name
          (show_value var_value)
          (match home with None -> "unset" | Some h -> Printf.sprintf "%S" h)
          git_dir)
      Gen.(
        let+ case_fold = bool
        and+ pattern =
          oneof_list
            [
              "~";
              "~/";
              "~/w/";
              "~/W/";
              "~/r/.git";
              "~x";
              "~X";
              "~x/";
              "~X/";
              "~~";
              "~nobody/x/";
            ]
        and+ var_name = oneof_list [ "path"; "PATH"; "foo" ]
        and+ var_value =
          oneof_list [ Some "/yes.inc"; Some "bar"; Some ""; None ]
        and+ home =
          oneof_list
            [ None; Some ""; Some "/h"; Some "/r/.git"; Some "/R/.GIT" ]
        and+ git_dir =
          oneof_list
            [
              "/r/.git";
              "/h/w/.git";
              "/r/~x/repo/.git";
              "/r/sub/~x";
              "/r/sub/~~";
            ]
        in
        (case_fold, pattern, var_name, var_value, home, git_dir))
      (fun (case_fold, pattern, var_name, var_value, home, git_dir) ->
        let prefix = if case_fold then "gitdir/i:" else "gitdir:" in
        let condition = prefix ^ pattern in
        let setting_line =
          match var_value with
          | None -> var_name ^ "\n"
          | Some v -> var_name ^ " = " ^ v ^ "\n"
        in
        let env =
          match home with
          | None -> no_system
          | Some h -> no_system @ [ ("HOME", h) ]
        in
        let world =
          include_world ~env
            [
              ( config_path,
                content
                  (Printf.sprintf "[includeIf \"%s\"]\n%s" condition
                     setting_line) );
              ("/yes.inc", yes_file);
            ]
        in
        let result, read_paths = run_with ~git_directories:[ git_dir ] world in
        let starts_with_home =
          pattern = "~" || String.starts_with ~prefix:"~/" pattern
        in
        let is_path = String.lowercase_ascii var_name = "path" in
        let setting_key =
          Config.key ~section:"includeIf" ~subsection:condition var_name
        in
        match (starts_with_home, home) with
        | true, Some "" -> (
            match result with
            | Error error ->
                error_name error = unread config_path var_value
                && not (List.mem "/yes.inc" read_paths)
            | Ok _ -> false)
        | true, None -> (
            match result with
            | Ok cfg ->
                Config.values cfg (key "s.met") = []
                && Config.values cfg setting_key = [ var_value ]
                && not (List.mem "/yes.inc" read_paths)
            | Error _ -> false)
        | _ -> (
            let expanded =
              match (starts_with_home, home) with
              | true, Some h ->
                  h ^ String.sub pattern 1 (String.length pattern - 1)
              | _ -> pattern
            in
            let with_prefix =
              if String.starts_with ~prefix:"/" expanded then expanded
              else "**/" ^ expanded
            in
            let full =
              if String.ends_with ~suffix:"/" with_prefix then
                with_prefix ^ "**"
              else with_prefix
            in
            let matched =
              Sinter_wildmatch.matches
                (Sinter_wildmatch.compile ~case_fold full)
                git_dir
            in
            if matched && is_path then
              match var_value with
              | None -> (
                  match result with
                  | Error error -> error_name error = unread config_path None
                  | Ok _ -> false)
              | Some "/yes.inc" -> (
                  match result with
                  | Ok cfg -> Config.values cfg (key "s.met") = [ Some "1" ]
                  | Error _ -> false)
              | Some _ -> (
                  match result with
                  | Ok cfg -> Config.values cfg (key "s.met") = []
                  | Error _ -> false)
            else
              match result with
              | Ok cfg ->
                  Config.values cfg (key "s.met") = []
                  && Config.values cfg setting_key = [ var_value ]
                  && not (List.mem "/yes.inc" read_paths)
              | Error _ -> false));
  ]

let worktree_tests =
  let world extension =
    include_world
      [
        (config_path, content ("[s]\na = 1\n" ^ extension));
        ("/r/.git/worktrees/w/config.worktree", content "[s]\na = 2\n");
        ("/r/.git/x.inc", content "[extensions]\nworktreeConfig = true\n");
      ]
  in
  let values extension =
    match
      fst (run_with ~working_tree:"/r/.git/worktrees/w" (world extension))
    with
    | Ok configuration -> show_values (Config.values configuration (key "s.a"))
    | Error error -> error_name error
  in
  [
    case "the file config.worktree counts only with extensions.worktreeConfig"
      (fun () ->
        Alcotest.(check string)
          "on"
          (show_values [ Some "1"; Some "2" ])
          (values "[extensions]\nworktreeConfig = true\n");
        Alcotest.(check string)
          "off" (show_values [ Some "1" ])
          (values "[extensions]\nworktreeConfig = false\n");
        Alcotest.(check string) "none" (show_values [ Some "1" ]) (values "");
        Alcotest.(check string)
          "a remote URL in config.worktree"
          (show_values [ Some "/u" ])
          (match
             fst
               (run_with ~working_tree:"/r/.git/worktrees/w"
                  (include_world
                     [
                       ( config_path,
                         content "[extensions]\nworktreeConfig = true\n" );
                       ( "/r/.git/worktrees/w/config.worktree",
                         content "[remote \"o\"]\nurl = /u\n" );
                     ]))
           with
          | Ok configuration ->
              show_values (Config.values configuration (key "remote.o.url"))
          | Error error -> error_name error);
        Alcotest.(check string)
          "through an include" (show_values [ Some "1" ])
          (values "[include]\npath = x.inc\n");
        Alcotest.(check string)
          "not a boolean" "not a boolean"
          (values "[extensions]\nworktreeConfig = maybe\n"));
    (* @verifies changes#give-default-branch-commits=v1
       The settings of the git configuration decide the upstream of the
       default branch. An integer value of `extensions.worktreeConfig` must decide whether the
       file `config.worktree` counts, as git 2.54.0 reads `2`, `-1`, `1k`, and
       `" 1"` as true and `00` as false, and refuses `08` and `2147483648`. *)
    case "an integer value of extensions.worktreeConfig is a boolean" (fun () ->
        List.iter
          (fun (value, expected) ->
            Alcotest.(check string)
              value expected
              (values ("[extensions]\nworktreeConfig = " ^ value ^ "\n")))
          [
            ("2", show_values [ Some "1"; Some "2" ]);
            ("-1", show_values [ Some "1"; Some "2" ]);
            ("1k", show_values [ Some "1"; Some "2" ]);
            ("\" 1\"", show_values [ Some "1"; Some "2" ]);
            ("00", show_values [ Some "1" ]);
            ("08", "not a boolean");
            ("2147483648", "not a boolean");
          ]);
    case "the configuration of a git repository has no file config.worktree"
      (fun () ->
        let configuration =
          configuration (world "[extensions]\nworktreeConfig = true\n")
        in
        check_values "values" [ Some "1" ] configuration "s.a");
  ]

let branch text =
  match Text.decode text with
  | Ok decoded -> (
      match Branch_name.of_text decoded with
      | Ok name -> name
      | Error _ -> Alcotest.failf "not a branch name: %s" text)
  | Error _ -> Alcotest.failf "not UTF-8: %S" text

let upstream_of text b =
  match Config.upstream (configuration (only_config text)) (branch b) with
  | Ok (Some name) -> name
  | Ok None -> "no upstream"
  | Error (Config.No_value_of _) -> "no value"
  | Error (Config.Invalid_refspec value) -> "invalid refspec " ^ value

let remote fetches =
  "[remote \"up\"]\nurl = /nowhere\n"
  ^ String.concat "" (List.map (fun f -> "fetch = " ^ f ^ "\n") fetches)

let main_branch = "[branch \"main\"]\nremote = up\nmerge = refs/heads/main\n"

let upstream_tests =
  [
    (* @verifies changes#give-default-branch-commits=v1
       The upstream of the default branch comes from the fetch refspecs of the
       remotes, as git 2.54.0 reads them. A value of `remote.<name>.fetch` of
       any remote that is not a fetch refspec must make the upstream an error,
       before or after the refspec that maps the merge ref, for another remote,
       for the remote `.`, and with no merge ref. *)
    case "a value of a fetch setting that is no refspec is an error" (fun () ->
        List.iter
          (fun refspec ->
            Alcotest.(check string)
              refspec
              ("invalid refspec " ^ refspec)
              (upstream_of
                 (main_branch
                 ^ remote [ refspec; "refs/heads/*:refs/remotes/up/*" ])
                 "main");
            Alcotest.(check string)
              ("after the one that maps: " ^ refspec)
              ("invalid refspec " ^ refspec)
              (upstream_of
                 (main_branch
                 ^ remote [ "refs/heads/*:refs/remotes/up/*"; refspec ])
                 "main"))
          [
            "a:b:c";
            "refs/heads/*";
            "refs/heads/*:";
            ":refs/remotes/up/*";
            "*:refs/remotes/up/x";
            "refs/heads/*:refs/remotes/up/x";
            "refs/heads/main:refs/remotes/up/*";
            "refs/heads/**:refs/remotes/up/**";
            "refs/heads/*/*:refs/remotes/up/*/*";
            "^";
            "^refs/heads/main:refs/remotes/up/x";
            "+^refs/heads/main";
            "refs/heads/main:../x";
            "refs/heads/main:refs/remotes/up/a..b";
            "refs/heads/main:refs/remotes/up/x.lock";
            "refs/heads/main:refs/remotes/up.lock/main";
            "refs/heads/main:refs/remotes/up/a\127b";
            "refs/heads/main:refs/remotes/up/a@{";
            "refs/heads/*:refs/remotes/up/*.lock";
            "refs/heads/*:refs/remotes/up/.*";
            "refs/heads/main:refs/remotes/.up/a";
            "refs/heads/main:refs/remotes/up/a.";
            "refs/heads/main:refs/remotes/up/a@{b";
            "refs/heads/main:@{a";
            "refs/heads/main:@";
            "refs/heads/main:/refs/remotes/up/main";
            "refs/heads/main:refs/remotes/up/main/";
            "refs/heads/main:refs/remotes//up/a";
            "refs/heads/main:refs/remotes/up/x y";
            "refs/heads/main:refs/remotes/up/a\tb";
            "refs/heads/main:refs/remotes/up/a?";
            "refs/heads/main:refs/remotes/up/a[";
            "refs/heads/main:refs/remotes/up/a~";
            "refs/heads/main:refs/remotes/up/a^";
            "refs/heads/a..b:refs/remotes/up/x";
            "../x:refs/remotes/up/x";
            ".a:refs/remotes/up/x";
            "a@{b:refs/remotes/up/x";
            "@{a:refs/remotes/up/x";
            "/a:refs/remotes/up/x";
            "a//b:refs/remotes/up/x";
            "a/:refs/remotes/up/x";
            "a.:refs/remotes/up/x";
            "refs/heads/main.lock:refs/remotes/up/x";
            "a*b*:refs/remotes/up/x*";
          ];
        Alcotest.(check string)
          "a space at the start"
          "invalid refspec  refs/heads/*:refs/remotes/up/*"
          (upstream_of
             (main_branch ^ remote [ "\" refs/heads/*:refs/remotes/up/*\"" ])
             "main");
        Alcotest.(check string)
          "a backslash" "invalid refspec refs/heads/main:refs/remotes/up/a\\b"
          (upstream_of
             (main_branch ^ remote [ "refs/heads/main:refs/remotes/up/a\\\\b" ])
             "main");
        let other = "[remote \"other\"]\nurl = /x\nfetch = a:b:c\n" in
        Alcotest.(check string)
          "another remote" "invalid refspec a:b:c"
          (upstream_of
             (main_branch ^ remote [ "refs/heads/*:refs/remotes/up/*" ] ^ other)
             "main");
        Alcotest.(check string)
          "the remote ." "invalid refspec a:b:c"
          (upstream_of
             ("[branch \"main\"]\nremote = .\nmerge = refs/heads/main\n" ^ other)
             "main");
        Alcotest.(check string)
          "no merge ref" "invalid refspec a:b:c"
          (upstream_of ("[branch \"main\"]\nremote = up\n" ^ other) "main");
        Alcotest.(check string)
          "a remote with an empty name" "invalid refspec a:b:c"
          (upstream_of
             (main_branch
             ^ remote [ "refs/heads/*:refs/remotes/up/*" ]
             ^ "[remote \"\"]\nfetch = a:b:c\n")
             "main");
        Alcotest.(check string)
          "a section remote with no subsection" "refs/remotes/up/main"
          (upstream_of
             (main_branch
             ^ remote [ "refs/heads/*:refs/remotes/up/*" ]
             ^ "[remote]\nfetch = a:b:c\n")
             "main");
        Alcotest.(check string)
          "a push refspec" "refs/remotes/up/main"
          (upstream_of
             (main_branch
             ^ remote [ "refs/heads/*:refs/remotes/up/*" ]
             ^ "[remote \"other\"]\npush = a:b:c\n")
             "main"));
    (* @verifies changes#give-default-branch-commits=v1
       A negative refspec, a refspec with no `:`, and a refspec whose source
       does not give the merge ref must map nothing, and the next refspec that
       maps the merge ref must give the upstream. *)
    case "a refspec that maps nothing lets the next one count" (fun () ->
        List.iter
          (fun refspec ->
            Alcotest.(check string)
              refspec "refs/remotes/up/main"
              (upstream_of
                 (main_branch
                 ^ remote [ refspec; "refs/heads/*:refs/remotes/up/*" ])
                 "main"))
          [
            "\"\"";
            "+";
            ":";
            "+:";
            "refs/heads/main";
            ":refs/remotes/up/x";
            "++refs/heads/*:refs/remotes/up/*";
            "main:refs/remotes/up/main";
            "heads/main:refs/remotes/up/main";
            "@:refs/remotes/up/x";
            "@*:refs/remotes/up/*";
            "x@:refs/remotes/up/x";
            "^refs/heads/main";
            "^refs/heads/m*";
            "^refs/heads/*";
            "^*";
            "^main";
            "^@";
            "^+refs/heads/main";
            "0123456789abcdef0123456789abcdef01234567:refs/remotes/up/x";
          ]);
    (* @verifies changes#give-default-branch-commits=v1
       The first refspec that maps the merge ref must give the upstream, and an
       empty destination must give no upstream, with no later refspec. *)
    case "an empty destination gives no upstream" (fun () ->
        Alcotest.(check string)
          "an empty destination" "no upstream"
          (upstream_of
             (main_branch
             ^ remote [ "refs/heads/main:"; "refs/heads/*:refs/remotes/up/*" ])
             "main"));
    (* @verifies changes#give-default-branch-commits=v1
       The upstream must be the destination of the refspec as written, with
       the bytes that the `*` takes, also when it is no ref name; the source
       must give the merge ref by its bytes, and `@` must stand for `HEAD`. *)
    case "the upstream is the destination as written" (fun () ->
        List.iter
          (fun (merge, refspecs, expected) ->
            Alcotest.(check string)
              (merge ^ " " ^ String.concat " " refspecs)
              expected
              (upstream_of
                 ("[branch \"main\"]\nremote = up\nmerge = " ^ merge ^ "\n"
                ^ remote refspecs)
                 "main"))
          [
            ("refs/heads/main", [ "refs/heads/main:up/main" ], "up/main");
            ( "refs/heads/main",
              [ "refs/heads/main:up/main"; "refs/heads/*:refs/remotes/up/*" ],
              "up/main" );
            ("refs/heads/main", [ "refs/heads/main:main" ], "main");
            ( "refs/heads/main",
              [ "refs/heads/main:refs/remotes/up/\xff" ],
              "refs/remotes/up/\xff" );
            ("refs/heads/main", [ "refs/heads/main:HEAD" ], "HEAD");
            ("refs/heads/main", [ "refs/heads/*:up/*" ], "up/main");
            ( "refs/heads/main",
              [
                "refs/heads/main*:refs/remotes/up/*";
                "refs/heads/*:refs/remotes/up/*";
              ],
              "refs/remotes/up/" );
            ( "refs/heads/main",
              [ "refs/heads/*n:refs/remotes/up/*" ],
              "refs/remotes/up/mai" );
            ( "refs/heads/main",
              [ "refs/heads/*main:refs/remotes/up/x*" ],
              "refs/remotes/up/x" );
            ( "refs/heads/main",
              [ "refs/heads/*:refs/remotes/up/a*b" ],
              "refs/remotes/up/amainb" );
            ( "refs/heads/main",
              [ "*:refs/remotes/up/*" ],
              "refs/remotes/up/refs/heads/main" );
            ( "refs/heads/team/main",
              [ "refs/heads/team/*:refs/remotes/up*" ],
              "refs/remotes/upmain" );
            ("main", [ "main:refs/remotes/up/main" ], "refs/remotes/up/main");
            ("main", [ "*:refs/remotes/up/*" ], "refs/remotes/up/main");
            ("main", [ "refs/heads/*:refs/remotes/up/*" ], "no upstream");
            ("HEAD", [ "@:refs/remotes/up/x" ], "refs/remotes/up/x");
            ("@", [ "@:refs/remotes/up/x" ], "no upstream");
            ("@", [ "HEAD:refs/remotes/up/x" ], "no upstream");
            ("HEAD", [ "HEAD:refs/remotes/up/HEAD" ], "refs/remotes/up/HEAD");
            ( "refs/heads/a..b",
              [ "refs/heads/*:refs/remotes/up/*" ],
              "refs/remotes/up/a..b" );
            ( "refs/heads/../../x",
              [ "refs/heads/*:refs/remotes/up/*" ],
              "refs/remotes/up/../../x" );
            ( "refs/heads/a b",
              [ "refs/heads/*:refs/remotes/up/*" ],
              "refs/remotes/up/a b" );
          ]);
    case "a value with no = for merge or remote is an error" (fun () ->
        Alcotest.(check string)
          "merge" "no value"
          (upstream_of
             ("[branch \"main\"]\nremote = up\nmerge\n"
             ^ remote [ "refs/heads/*:refs/x/*" ])
             "main");
        Alcotest.(check string)
          "fetch" "no value"
          (upstream_of (main_branch ^ "[remote \"up\"]\nfetch\n") "main");
        Alcotest.(check string)
          "remote" "no value"
          (upstream_of "[branch \"main\"]\nremote\nmerge = refs/heads/main\n"
             "main"));
    (* @verifies changes#give-default-branch-commits=v1
       A `*` of a fetch refspec must take the bytes of the merge ref between
       the prefix and the suffix of the source, and must give no match when the
       prefix and the suffix overlap in the merge ref; a `+` at the start of
       the refspec must not change the mapping. *)
    case "a * takes the bytes between the prefix and the suffix" (fun () ->
        Alcotest.(check string)
          "prefix and suffix" "refs/remotes/u/xaiy"
          (upstream_of
             (main_branch ^ remote [ "+refs/heads/m*n:refs/remotes/u/x*y" ])
             "main");
        Alcotest.(check string)
          "a suffix that does not fit" "no upstream"
          (upstream_of
             (main_branch ^ remote [ "refs/heads/m*x:refs/remotes/u/*" ])
             "main");
        Alcotest.(check string)
          "a prefix and a suffix that overlap by one" "no upstream"
          (upstream_of
             (main_branch ^ remote [ "refs/heads/mai*in:refs/remotes/u/*" ])
             "main");
        Alcotest.(check string)
          "a prefix and a suffix that overlap" "no upstream"
          (upstream_of
             (main_branch ^ remote [ "refs/heads/mai*ain:refs/remotes/u/*" ])
             "main");
        Alcotest.(check string)
          "a + before a plain source" "refs/remotes/u/m"
          (upstream_of
             (main_branch ^ remote [ "+refs/heads/main:refs/remotes/u/m" ])
             "main"));
    (* @verifies changes#give-default-branch-commits=v1
       A `*` of a fetch refspec must also take the empty byte sequence. *)
    case "a * takes the empty sequence" (fun () ->
        Alcotest.(check string)
          "empty" "refs/remotes/up/x"
          (upstream_of
             ("[branch \"main\"]\nremote = up\nmerge = refs/heads/main\n"
             ^ remote [ "refs/heads/main*:refs/remotes/up/x*" ])
             "main"));
    (* @verifies changes#give-default-branch-commits=v1
       The source of a fetch refspec must map only the merge ref with the same
       bytes, so that `main` does not map `refs/heads/main`, and a `*` must take
       bytes that hold `/`. *)
    case "a refspec maps by full names, and its * takes any bytes" (fun () ->
        Alcotest.(check string)
          "a short source" "no upstream"
          (upstream_of
             (main_branch ^ remote [ "main:refs/remotes/up/main" ])
             "main");
        Alcotest.(check string)
          "a * that takes /" "refs/remotes/up/team/main"
          (upstream_of
             ("[branch \"main\"]\nremote = up\nmerge = refs/heads/team/main\n"
             ^ remote [ "refs/heads/*:refs/remotes/up/*" ])
             "main"));
    (* @verifies changes#give-default-branch-commits=v1
       Over generated merge refs and lists of fetch refspecs, with negative
       refspecs, refspecs that map nothing, refspecs with no destination or an
       empty one, and refspecs that are not valid, the upstream must be the
       destination of the first refspec that maps the merge ref, as git 2.54.0
       gives it, or an error for a value that is not a refspec. Under a binding
       of `default-branch-name`, the result gives that upstream and no other, or
       no upstream, never both. *)
    property ~name:"the upstream is the map of the first refspec that maps M"
      ~print:(fun (m, refspecs) -> m ^ " " ^ String.concat " " refspecs)
      Gen.(
        pair
          (map
             (fun s -> "refs/heads/" ^ s)
             (oneof_list [ "main"; "a"; "ab"; "b" ]))
          (list_size (int_range 0 4)
             (oneof_list
                [
                  "refs/heads/*:refs/remotes/o/*";
                  "+refs/heads/a*:refs/remotes/p/*";
                  "refs/heads/main:refs/remotes/q/m";
                  "^refs/heads/main";
                  "refs/tags/*:refs/tags/*";
                  "refs/heads/ab";
                  "refs/heads/*b:refs/remotes/r/*";
                  "refs/heads/a";
                  "refs/heads/a:";
                  "a:b:c";
                ])))
      (fun (m, refspecs) ->
        let maps refspec =
          let refspec =
            if String.starts_with ~prefix:"+" refspec then
              String.sub refspec 1 (String.length refspec - 1)
            else refspec
          in
          if String.starts_with ~prefix:"^" refspec then None
          else
            match String.index_opt refspec ':' with
            | None -> if refspec = m then Some None else None
            | Some colon -> (
                let source = String.sub refspec 0 colon
                and destination =
                  String.sub refspec (colon + 1)
                    (String.length refspec - colon - 1)
                in
                match String.index_opt source '*' with
                | None -> if source = m then Some (Some destination) else None
                | Some star ->
                    let before = String.sub source 0 star
                    and after =
                      String.sub source (star + 1)
                        (String.length source - star - 1)
                    in
                    if
                      String.length m
                      >= String.length before + String.length after
                      && String.starts_with ~prefix:before m
                      && String.ends_with ~suffix:after m
                    then
                      let middle =
                        String.sub m (String.length before)
                          (String.length m - String.length before
                         - String.length after)
                      in
                      let dstar = String.index destination '*' in
                      Some
                        (Some
                           (String.sub destination 0 dstar
                           ^ middle
                           ^ String.sub destination (dstar + 1)
                               (String.length destination - dstar - 1)))
                    else None)
        in
        let expected =
          if List.mem "a:b:c" refspecs then Some "<error>"
          else
            match
              List.find_map (fun refspec -> Option.join (maps refspec)) refspecs
            with
            | Some "" | None -> None
            | Some destination -> Some destination
        in
        let text =
          "[branch \"main\"]\nremote = up\nmerge = " ^ m ^ "\n"
          ^ remote refspecs
        in
        let actual =
          match
            Config.upstream (configuration (only_config text)) (branch "main")
          with
          | Ok upstream -> upstream
          | Error _ -> Some "<error>"
        in
        actual = expected);
  ]

let commits_of_refs refs : (string, unit) Ref_commit.refs =
 fun name ->
  Ok (Option.map (fun c -> Ref_commit.Commit c) (List.assoc_opt name refs))

let set = Vectors.read "changes"

let env_of_settings settings =
  let entries =
    List.concat_map
      (fun (name, values) ->
        match values with
        | `List items ->
            List.map
              (function
                | `String value -> (name, value)
                | other ->
                    Alcotest.failf "not a setting value: %s"
                      (Yojson.Basic.to_string other))
              items
        | other ->
            Alcotest.failf "not a list of values: %s"
              (Yojson.Basic.to_string other))
      settings
  in
  ("GIT_CONFIG_NOSYSTEM", "1")
  :: ("GIT_CONFIG_COUNT", string_of_int (List.length entries))
  :: List.concat
       (List.mapi
          (fun index (name, value) ->
            [
              (Printf.sprintf "GIT_CONFIG_KEY_%d" index, name);
              (Printf.sprintf "GIT_CONFIG_VALUE_%d" index, value);
            ])
          entries)

let member name input =
  match input with
  | `Assoc fields -> List.assoc_opt name fields
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let default_branch_commit configuration input =
  let binding =
    match member "binding" input with
    | Some (`String b) -> (
        match Text.decode b with
        | Ok text -> text
        | Error _ -> Alcotest.fail "not UTF-8")
    | _ -> Alcotest.fail "no binding"
  and refs =
    match member "refs" input with
    | Some (`Assoc refs) ->
        List.map
          (fun (name, commit) ->
            match commit with
            | `String c -> (name, c)
            | _ -> Alcotest.fail "not a commit")
          refs
    | _ -> Alcotest.fail "no refs"
  in
  let upstream b =
    match Config.upstream configuration b with
    | Ok upstream -> Ok upstream
    | Error _ -> Error ()
  in
  match
    Default_branch.commit ~upstream ~refs:(commits_of_refs refs) binding
  with
  | Ok (Some commit) -> `Assoc [ ("commit", `String commit) ]
  | Ok None -> `Assoc []
  | Error () -> `String "an error"

let give_upstream (vector : Vectors.vector) =
  let settings =
    match member "settings" vector.input with
    | Some (`Assoc settings) -> settings
    | _ -> Alcotest.fail "no settings"
  in
  let configuration =
    configuration_of { files = []; env = env_of_settings settings }
  in
  `Assoc [ ("values", default_branch_commit configuration vector.input) ]

(* @verifies changes[upstreams]
   Each vector gives a binding of `default-branch-name`, the settings of the
   git configuration, and the refs of the git repository. The reader of the git
   configuration and the default-branch resolver must give the commit of the
   vector and no other commit, or no commit, never both. *)
let design_upstream_vectors =
  Vectors.group set ~name:"upstreams" ~form:"#upstream-vector=v1" give_upstream

(* @verifies changes#give-default-branch-commits=v1
   The proposed vectors of `upstreams` give a binding of `default-branch-name`,
   the file `config` of a git repository, and its refs. The reader of the git
   configuration, with the refs, must give the commit of the default branch and
   no other commit, or no commit, never both. *)
let upstream_vectors =
  Proposed_vectors.test "upstreams" (fun input ->
      let text =
        match member "config" input with
        | Some config -> Changes_model.bytes_of_json config
        | None -> Alcotest.fail "no config"
      in
      default_branch_commit (configuration (only_config text)) input)

let vector_groups = [ design_upstream_vectors ]

let tests =
  Vectors.tests "changes" vector_groups
  @ key_tests @ syntax_tests @ boolean_tests @ integer_boolean_tests
  @ pathname_tests @ order_tests @ read_tests @ environment_tests
  @ more_environment_tests @ file_tests @ include_tests @ limit_tests
  @ condition_tests @ more_condition_tests @ unmet_hasconfig_tests
  @ follow_git_tests @ worktree_tests @ upstream_tests @ [ upstream_vectors ]
