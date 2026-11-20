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
        Config.of_repository ~limits ~environment ~read ~git_directories
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
            (Some "2", None);
            (Some " true", None);
            (Some "y", None);
          ]);
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
            ".b.c";
            "a.b.1";
          ]);
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
    case
      "an include of a missing file, an empty value, or %(prefix)/ includes \
       nothing" (fun () ->
        let configuration =
          configuration
            (include_world
               [
                 ( config_path,
                   content
                     "[include]\n\
                      path = gone.inc\n\
                      path =\n\
                      path = %(prefix)/etc/x\n\
                      path = :(optional)/etc/x\n\
                      [s]\n\
                      a = 1\n" );
                 ("/etc/x", content "[s]\na = 0\n");
               ])
        in
        check_values "values" [ Some "1" ] configuration "s.a");
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
    case "a condition gitdir with ~/ takes HOME" (fun () ->
        Alcotest.(check string)
          "home" "met"
          (conditional ~git_directories:[ "/h/w/.git" ]
             ~env:(no_system @ [ ("HOME", "/h") ])
             "gitdir:~/w/");
        Alcotest.(check string)
          "no home"
          (Printf.sprintf "unread pathname %s %s" config_path
             (show_value (Some "~/w/")))
          (conditional "gitdir:~/w/"));
    case "a condition onbranch is never met in a git repository" (fun () ->
        Alcotest.(check string)
          "onbranch" "not met"
          (conditional "onbranch:main");
        Alcotest.(check string)
          "onbranch *" "not met" (conditional "onbranch:*"));
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
    case "a condition hasconfig that is not met reads nothing of its file"
      (fun () ->
        Alcotest.(check string)
          "not met" "not met"
          (match
             fst
               (run_with
                  (include_world
                     [
                       ( config_path,
                         content
                           "[includeIf \"hasconfig:remote.*.url:nothing\"]\n\
                            path = /bad.inc\n" );
                       ("/bad.inc", Config.Unreadable);
                     ]))
           with
          | Ok configuration ->
              if Config.values configuration (key "s.met") = [] then "not met"
              else "met"
          | Error error -> error_name error));
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

let remote fetches =
  "[remote \"up\"]\nurl = /nowhere\n"
  ^ String.concat "" (List.map (fun f -> "fetch = " ^ f ^ "\n") fetches)

let main_branch = "[branch \"main\"]\nremote = up\nmerge = refs/heads/main\n"

let upstream_tests =
  [
    case
      "a refspec that gives no ref name maps nothing, and the next one counts"
      (fun () ->
        List.iter
          (fun refspec ->
            Alcotest.(check string)
              refspec "refs/remotes/up/main"
              (upstream_of
                 (main_branch
                 ^ remote [ refspec; "refs/heads/*:refs/remotes/up/*" ])
                 "main"))
          [
            "a:b:c";
            "refs/heads/main:refs/remotes/x:y";
            "refs/heads/*:refs/remotes/up/x";
            "refs/heads/x:refs/remotes/up/*";
            "refs/heads/*/*:refs/remotes/up/*";
            "refs/heads/main";
            "refs/heads/main:";
            "refs/heads/main:up/main";
            "refs/heads/main:refs/remotes/a..b";
            "refs/heads/*:refs/remotes/*/x.lock";
            "refs/heads/main*:refs/remotes/up/*";
            "main:refs/remotes/up/main";
          ];
        Alcotest.(check string)
          "a merge ref that is no ref name" "no upstream"
          (upstream_of
             ("[branch \"main\"]\nremote = up\nmerge = main\n"
             ^ remote [ "*:refs/remotes/up/*"; "main:refs/remotes/up/main" ])
             "main");
        Alcotest.(check string)
          "a root name" "refs/remotes/up/HEAD"
          (upstream_of
             ("[branch \"main\"]\nremote = up\nmerge = HEAD\n"
             ^ remote [ "HEAD:refs/remotes/up/HEAD" ])
             "main");
        Alcotest.(check string)
          "after the one that maps" "refs/remotes/up/main"
          (upstream_of
             (main_branch ^ remote [ "refs/heads/*:refs/remotes/up/*"; "a:b:c" ])
             "main"));
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
    case "a * takes the empty sequence" (fun () ->
        Alcotest.(check string)
          "empty" "refs/remotes/up/x"
          (upstream_of
             ("[branch \"main\"]\nremote = up\nmerge = refs/heads/main\n"
             ^ remote [ "refs/heads/main*:refs/remotes/up/x*" ])
             "main"));
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
       refspecs, refspecs that map nothing, and refspecs with no destination,
       the upstream must be the destination of the first refspec that maps the
       merge ref, by the rule of the page git-fetch. Under a binding of
       `default-branch-name`, the result gives that upstream and no other, or no
       upstream, never both. *)
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
          List.fold_left
            (fun found refspec ->
              match found with
              | Some _ -> found
              | None -> (
                  match maps refspec with
                  | Some (Some destination)
                    when Sinter_ref_names.Ref_name.is_ref_name destination ->
                      Some destination
                  | Some _ | None -> None))
            None refspecs
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
  @ key_tests @ syntax_tests @ boolean_tests @ pathname_tests @ order_tests
  @ read_tests @ environment_tests @ more_environment_tests @ file_tests
  @ include_tests @ limit_tests @ condition_tests @ more_condition_tests
  @ worktree_tests @ upstream_tests @ [ upstream_vectors ]
