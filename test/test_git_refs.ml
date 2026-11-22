(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Id = Sinter_git_objects.Object_id
module Files = Sinter_repository_files
module Ref_name = Sinter_ref_names.Ref_name
module Names = Test_ref_names
module Loose_ref = Sinter_git_refs.Loose_ref
module Packed_refs = Sinter_git_refs.Packed_refs
module Refs = Sinter_git_refs.Refs
module Ref_commit = Sinter_git_model.Ref_commit
module Fake = Test_repository_files.Fake
module Fake_refs = Refs.Make (Test_repository_files.Reader)

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f

let limits =
  {
    Refs.max_loose_size = 1 lsl 16;
    max_packed_size = 1 lsl 30;
    max_tables_list_size = 1 lsl 16;
    max_stack_size = 1 lsl 30;
    max_names_size = 1 lsl 30;
  }

let ( / ) = Filename.concat
let h1 = String.make 40 '1'
let h2 = String.make 40 '2'
let h3 = String.make 40 'c'

let show_target = function
  | Loose_ref.Object id -> "object " ^ Id.to_hex id
  | Loose_ref.Symbolic name -> Printf.sprintf "symbolic %S" name
  | Loose_ref.Broken -> "broken"

let failure_name = Test_repository_files.failure_name

let error_name = function
  | Refs.Unread { pathname; failure } ->
      Printf.sprintf "unread %s: %s"
        (Filename.basename pathname)
        (failure_name failure)
  | Refs.Malformed_packed_refs { error = Packed_refs.No_final_line_feed; _ } ->
      "packed-refs has no final line feed"
  | Refs.Malformed_packed_refs { error = Packed_refs.Repeated_name name; _ } ->
      "packed-refs repeats " ^ name
  | Refs.Malformed_tables_list _ -> "malformed tables.list"
  | Refs.Malformed_table _ -> "malformed table"

let show_lookup = function
  | Ok (Some target) -> show_target target
  | Ok None -> "none"
  | Error error -> error_name error

let loose_tests =
  [
    case "a loose ref is an object id or ref: and a ref name, then a line feed"
      (fun () ->
        List.iter
          (fun (content, expected) ->
            Alcotest.(check string)
              (Printf.sprintf "%S" content)
              expected
              (show_target (Loose_ref.parse Id.Sha1 content)))
          [
            (h1 ^ "\n", "object " ^ h1);
            ("ref: refs/heads/main\n", "symbolic \"refs/heads/main\"");
            ("ref: HEAD\n", "symbolic \"HEAD\"");
            ("ref: ../../x\n", "broken");
            ("ref: main\n", "broken");
            ("ref: a b\n", "broken");
            ("ref: refs/heads/\xff\n", "broken");
            ("ref: \n", "broken");
            ("", "broken");
            (h1, "broken");
            (h1 ^ " \n", "broken");
            (h1 ^ "\r\n", "broken");
            (h1 ^ "\n\n", "broken");
            (h1 ^ "\nx", "broken");
            (" " ^ h1 ^ "\n", "broken");
            (String.uppercase_ascii h3 ^ "\n", "broken");
            (String.make 64 '1' ^ "\n", "broken");
            ("ref:refs/heads/main\n", "broken");
            ("ref: refs/heads/main", "broken");
            ("ref: refs/heads/a\nb\n", "broken");
            ("\n", "broken");
          ];
        Alcotest.(check string)
          "sha256"
          ("object " ^ String.make 64 'a')
          (show_target (Loose_ref.parse Id.Sha256 (String.make 64 'a' ^ "\n"))));
    property ~count:2000 ~name:"the parse of a loose ref takes any bytes"
      ~print:(Printf.sprintf "%S")
      Gen.(
        oneof
          [
            string_size
              ~gen:
                (oneof
                   [ char; oneof_list [ '\n'; 'r'; 'e'; 'f'; ':'; ' '; 'a' ] ])
              (int_range 0 70);
            map (fun name -> "ref: " ^ name ^ "\n") Names.name_gen;
          ])
      (fun content ->
        match Loose_ref.parse Id.Sha1 content with
        | Loose_ref.Object id -> content = Id.to_hex id ^ "\n"
        | Loose_ref.Symbolic name ->
            content = "ref: " ^ name ^ "\n" && Ref_name.is_ref_name name
        | Loose_ref.Broken -> true);
  ]

let packed_error = function
  | Packed_refs.No_final_line_feed -> "no final line feed"
  | Packed_refs.Repeated_name name -> "repeated " ^ name

let packed content =
  match Packed_refs.parse Id.Sha1 content with
  | Ok refs -> refs
  | Error error ->
      Alcotest.failf "packed-refs %S: %s" content (packed_error error)

let find refs name = Option.map Id.to_hex (Packed_refs.find refs name)

let packed_tests =
  [
    case "packed-refs holds a ref on each line, with peeled lines after"
      (fun () ->
        let refs =
          packed
            ("# pack-refs with: peeled fully-peeled sorted \n" ^ h1
           ^ " refs/heads/main\n" ^ h2 ^ " refs/tags/v1\n^" ^ h3 ^ "\n" ^ h3
           ^ " refs/tags/v2\n" ^ h1 ^ " HEAD\n")
        in
        Alcotest.(check (option string))
          "main" (Some h1)
          (find refs "refs/heads/main");
        Alcotest.(check (option string))
          "v1" (Some h2) (find refs "refs/tags/v1");
        Alcotest.(check (option string))
          "v2" (Some h3) (find refs "refs/tags/v2");
        Alcotest.(check (option string))
          "a root name" (Some h1) (find refs "HEAD");
        Alcotest.(check (option string))
          "none" None
          (find refs "refs/heads/other");
        Alcotest.(check (option string))
          "empty" None
          (find (packed "") "refs/heads/main"));
    case "a line in no form gives no ref and no error" (fun () ->
        List.iter
          (fun (line, name) ->
            let refs =
              packed
                (h2 ^ " refs/heads/ok\n" ^ line ^ "\n" ^ h3
               ^ " refs/heads/after\n")
            in
            Alcotest.(check (option string))
              (Printf.sprintf "%S: ok" line)
              (Some h2)
              (find refs "refs/heads/ok");
            Alcotest.(check (option string))
              (Printf.sprintf "%S: after" line)
              (Some h3)
              (find refs "refs/heads/after");
            Alcotest.(check (option string))
              (Printf.sprintf "%S: the name" line)
              None (find refs name))
          [
            ("# x", "x");
            ("^" ^ h1, "refs/heads/main");
            ("^" ^ h1 ^ "\n^" ^ h1, "refs/heads/main");
            (String.uppercase_ascii h3 ^ " refs/heads/upper", "refs/heads/upper");
            (h1 ^ "  refs/heads/two", "refs/heads/two");
            (h1 ^ " main", "main");
            (h1 ^ " refs/heads/a..b", "refs/heads/a..b");
            (h1 ^ " refs/heads/\xff", "refs/heads/\xff");
            (h1 ^ " refs/heads/cr\r", "refs/heads/cr\r");
            ("", "");
            (h1 ^ " ", "");
            (h1, "");
            (String.make 64 '1' ^ " refs/heads/long", "refs/heads/long");
          ]);
    case "packed-refs with no final line feed or a repeated name is an error"
      (fun () ->
        List.iter
          (fun (content, expected) ->
            Alcotest.(check string)
              (Printf.sprintf "%S" content)
              expected
              (match Packed_refs.parse Id.Sha1 content with
              | Ok _ -> "ok"
              | Error error -> packed_error error))
          [
            (h1 ^ " refs/heads/main", "no final line feed");
            ("# header", "no final line feed");
            ( h1 ^ " refs/heads/main\n" ^ h2 ^ " refs/heads/main\n",
              "repeated refs/heads/main" );
          ]);
    property ~name:"packed-refs gives back the refs that it holds"
      ~print:(fun refs ->
        String.concat "; " (List.map (fun (n, h, _) -> n ^ " " ^ h) refs))
      Gen.(
        list_size (int_range 0 6)
          (triple
             (map
                (fun s -> "refs/heads/" ^ s)
                (oneof_list [ "a"; "b"; "c/d"; "e-f"; "\xc3\xa9" ]))
             (oneof_list [ h1; h2; h3 ])
             bool))
      (fun refs ->
        let refs =
          List.fold_left
            (fun acc (name, hex, peeled) ->
              if List.exists (fun (n, _, _) -> n = name) acc then acc
              else (name, hex, peeled) :: acc)
            [] refs
        in
        let content =
          "# pack-refs with: peeled\n"
          ^ String.concat ""
              (List.map
                 (fun (name, hex, peeled) ->
                   hex ^ " " ^ name ^ "\n"
                   ^ if peeled then "^" ^ h3 ^ "\n" else "")
                 refs)
        in
        match Packed_refs.parse Id.Sha1 content with
        | Error _ -> false
        | Ok parsed ->
            List.for_all
              (fun (name, hex, _) -> find parsed name = Some hex)
              refs
            && find parsed "refs/heads/zz" = None);
    property ~count:2000 ~name:"the parse of packed-refs takes any bytes"
      ~print:(Printf.sprintf "%S")
      Gen.(
        map (String.concat "")
          (list_size (int_range 0 6)
             (oneof_list
                [ h1; " "; "refs/heads/a"; "\n"; "^"; "#"; "x"; "\000" ])))
      (fun content ->
        match Packed_refs.parse Id.Sha1 content with Ok _ | Error _ -> true);
  ]

let write path content =
  let rec parents dir =
    if not (Sys.file_exists dir) then (
      parents (Filename.dirname dir);
      Unix.mkdir dir 0o755)
  in
  parents (Filename.dirname path);
  Out_channel.with_open_bin path (fun channel ->
      Out_channel.output_string channel content)

let git_folder files =
  let root = Git_fixture.temp_dir () / ".git" in
  Unix.mkdir root 0o755;
  List.iter (fun (name, content) -> write (root / name) content) files;
  root

let refs_of ?(storage = Refs.Files) ?(working_tree = Refs.Main) root =
  Refs.create limits storage Id.Sha1 ~git_folder:root working_tree

let lookup refs name = show_lookup (Refs.lookup refs name)
let head refs = lookup refs "HEAD"

let files_tests =
  [
    case "a loose ref gives its target, and a packed ref its object" (fun () ->
        let root =
          git_folder
            [
              ("refs/heads/main", h1 ^ "\n");
              ("refs/heads/alias", "ref: refs/heads/main\n");
              ("refs/heads/broken", "");
              ( "packed-refs",
                "# pack-refs with: peeled\n" ^ h2 ^ " refs/tags/v1\n" );
            ]
        in
        let refs = refs_of root in
        Alcotest.(check string)
          "main" ("object " ^ h1)
          (lookup refs "refs/heads/main");
        Alcotest.(check string)
          "alias" "symbolic \"refs/heads/main\""
          (lookup refs "refs/heads/alias");
        Alcotest.(check string)
          "broken" "broken"
          (lookup refs "refs/heads/broken");
        Alcotest.(check string)
          "v1" ("object " ^ h2)
          (lookup refs "refs/tags/v1");
        Alcotest.(check string) "none" "none" (lookup refs "refs/heads/gone"));
    case "a loose ref hides a packed ref of the same name, a broken one too"
      (fun () ->
        let root =
          git_folder
            [
              ("refs/heads/main", h1 ^ "\n");
              ("refs/heads/broken", h1);
              ( "packed-refs",
                h2 ^ " refs/heads/main\n" ^ h2 ^ " refs/heads/broken\n" );
            ]
        in
        let refs = refs_of root in
        Alcotest.(check string)
          "main" ("object " ^ h1)
          (lookup refs "refs/heads/main");
        Alcotest.(check string)
          "broken" "broken"
          (lookup refs "refs/heads/broken"));
    case
      "a folder or a file of another kind at the pathname of a ref is no loose \
       ref" (fun () ->
        let root =
          git_folder
            [
              ("refs/heads/team/a", h1 ^ "\n");
              ( "packed-refs",
                h2 ^ " refs/heads/team\n" ^ h3 ^ " refs/heads/pipe\n" );
            ]
        in
        Unix.mkfifo (root / "refs" / "heads" / "pipe") 0o600;
        let refs = refs_of root in
        Alcotest.(check string)
          "a folder" ("object " ^ h2)
          (lookup refs "refs/heads/team");
        Alcotest.(check string)
          "a FIFO" ("object " ^ h3)
          (lookup refs "refs/heads/pipe");
        let root = git_folder [ ("refs/heads/team/a", h1 ^ "\n") ] in
        Alcotest.(check string)
          "none" "none"
          (lookup (refs_of root) "refs/heads/team"));
    case "a link at the pathname of a ref names the ref of its text" (fun () ->
        let root = git_folder [ ("refs/heads/main", h1 ^ "\n") ] in
        Unix.symlink "refs/heads/main" (root / "refs" / "heads" / "link");
        Unix.symlink "refs/heads/gone" (root / "refs" / "heads" / "dangling");
        Unix.symlink "main" (root / "refs" / "heads" / "short");
        Unix.symlink
          (root / "refs" / "heads" / "main")
          (root / "refs" / "heads" / "absolute");
        Unix.symlink "refs/heads/main" (root / "HEAD");
        let refs = refs_of root in
        Alcotest.(check string)
          "link" "symbolic \"refs/heads/main\""
          (lookup refs "refs/heads/link");
        Alcotest.(check string)
          "dangling" "symbolic \"refs/heads/gone\""
          (lookup refs "refs/heads/dangling");
        Alcotest.(check string)
          "short" "broken"
          (lookup refs "refs/heads/short");
        Alcotest.(check string)
          "absolute" "broken"
          (lookup refs "refs/heads/absolute");
        Alcotest.(check string)
          "HEAD" "symbolic \"refs/heads/main\"" (head refs));
    case "a folder on the pathname that is a link is followed" (fun () ->
        let root = git_folder [ ("elsewhere/main", h1 ^ "\n") ] in
        Unix.mkdir (root / "refs") 0o755;
        Unix.symlink (root / "elsewhere") (root / "refs" / "heads");
        Alcotest.(check string)
          "main" ("object " ^ h1)
          (lookup (refs_of root) "refs/heads/main"));
    case "a linked working tree reads its own refs only from its folder"
      (fun () ->
        let root =
          git_folder
            [
              ("HEAD", "ref: refs/heads/main\n");
              ("ORIG_HEAD", h3 ^ "\n");
              ("refs/bisect/bad", h1 ^ "\n");
              ("refs/heads/main", h1 ^ "\n");
              ("worktrees/w/HEAD", h2 ^ "\n");
              ("worktrees/w/refs/bisect/bad", h2 ^ "\n");
              ("worktrees/w/refs/worktree/x", h2 ^ "\n");
              ("worktrees/w/refs/rewritten/y", h2 ^ "\n");
              ("worktrees/w/refs/heads/main", h2 ^ "\n");
              ("packed-refs", h3 ^ " refs/worktree/p\n" ^ h3 ^ " FETCH_HEAD\n");
            ]
        in
        let linked =
          refs_of ~working_tree:(Refs.Linked (root / "worktrees" / "w")) root
        in
        Alcotest.(check string) "HEAD" ("object " ^ h2) (head linked);
        Alcotest.(check string)
          "bisect" ("object " ^ h2)
          (lookup linked "refs/bisect/bad");
        Alcotest.(check string)
          "worktree" ("object " ^ h2)
          (lookup linked "refs/worktree/x");
        Alcotest.(check string)
          "rewritten" ("object " ^ h2)
          (lookup linked "refs/rewritten/y");
        Alcotest.(check string)
          "a branch is in the git folder" ("object " ^ h1)
          (lookup linked "refs/heads/main");
        Alcotest.(check string)
          "a root name of the git folder" "none"
          (lookup linked "ORIG_HEAD");
        Alcotest.(check string)
          "no packed own ref" "none"
          (lookup linked "refs/worktree/p");
        Alcotest.(check string)
          "no packed root name" "none"
          (lookup linked "FETCH_HEAD");
        let main = refs_of root in
        Alcotest.(check string)
          "main HEAD" "symbolic \"refs/heads/main\"" (head main);
        Alcotest.(check string)
          "main bisect" ("object " ^ h1)
          (lookup main "refs/bisect/bad");
        Alcotest.(check string)
          "main ORIG_HEAD" ("object " ^ h3) (lookup main "ORIG_HEAD");
        Alcotest.(check string)
          "main packed own ref" ("object " ^ h3)
          (lookup main "refs/worktree/p");
        Alcotest.(check string)
          "main packed root name" ("object " ^ h3) (lookup main "FETCH_HEAD"));
    case "a loose ref that cannot be read gives no target" (fun () ->
        if Unix.geteuid () <> 0 then (
          let root = git_folder [ ("refs/heads/main", h1 ^ "\n") ] in
          Unix.chmod (root / "refs" / "heads" / "main") 0o000;
          Fun.protect
            ~finally:(fun () ->
              Unix.chmod (root / "refs" / "heads" / "main") 0o644)
            (fun () ->
              Alcotest.(check string)
                "unreadable" "unread main: cannot read"
                (lookup (refs_of root) "refs/heads/main"))));
    case "a missing HEAD is no ref" (fun () ->
        let root = git_folder [ ("refs/heads/main", h1 ^ "\n") ] in
        Alcotest.(check string) "main" "none" (head (refs_of root));
        Alcotest.(check string)
          "linked" "none"
          (head
             (refs_of
                ~working_tree:(Refs.Linked (root / "worktrees" / "x"))
                root)));
    case "a text that is not a ref name names no ref" (fun () ->
        let root =
          git_folder
            [
              ("refs/heads/main", h1 ^ "\n");
              ("x", h1 ^ "\n");
              ("main", h1 ^ "\n");
            ]
        in
        let refs = refs_of root in
        List.iter
          (fun name -> Alcotest.(check string) name "none" (lookup refs name))
          [
            "refs/heads/../../x";
            "../x";
            "x";
            "main";
            "refs/heads/main/";
            "refs//heads/main";
            "refs/heads/./main";
            "";
            "refs/heads/\xff";
          ]);
    (* @verifies conformance#report-stops-at-limits=v1
       A loose ref file or packed-refs file larger than its limit stops and
       reports Unread with Too_large and the pathname of the file. *)
    case "a file larger than its limit gives no target, one inside gives it"
      (fun () ->
        let content = h1 ^ "\n" in
        let packed_content = h2 ^ " refs/tags/v1\n" in
        let size = String.length content
        and packed_size = String.length packed_content in
        let root =
          git_folder
            [
              ("refs/heads/main", content);
              ("HEAD", content);
              ("packed-refs", packed_content);
            ]
        in
        let refs max_loose_size max_packed_size =
          Refs.create
            { limits with Refs.max_loose_size; max_packed_size }
            Refs.Files Id.Sha1 ~git_folder:root Refs.Main
        in
        Alcotest.(check string)
          "inside" ("object " ^ h1)
          (lookup (refs size packed_size) "refs/heads/main");
        Alcotest.(check string)
          "HEAD inside" ("object " ^ h1)
          (head (refs size packed_size));
        Alcotest.(check string)
          "packed inside" ("object " ^ h2)
          (lookup (refs size packed_size) "refs/tags/v1");
        Alcotest.(check string)
          "outside" "unread main: too large"
          (lookup (refs (size - 1) packed_size) "refs/heads/main");
        Alcotest.(check string)
          "HEAD outside" "unread HEAD: too large"
          (head (refs (size - 1) packed_size));
        Alcotest.(check string)
          "packed outside" "unread packed-refs: too large"
          (lookup (refs size (packed_size - 1)) "refs/tags/v1");
        Alcotest.(check string)
          "a loose ref needs no packed-refs" ("object " ^ h1)
          (lookup (refs size 0) "refs/heads/main");
        Alcotest.(check string)
          "a limit of 0" "unread main: too large"
          (lookup (refs 0 0) "refs/heads/main");
        List.iter
          (fun (loose, packed) ->
            match refs loose packed with
            | _ -> Alcotest.fail "no exception"
            | exception Invalid_argument _ -> ())
          [ (-1, 10); (10, -1) ]);
    case
      "a packed-refs that is not in its form fails only a lookup that needs it"
      (fun () ->
        let root =
          git_folder
            [
              ("refs/heads/main", h1 ^ "\n");
              ("packed-refs", h2 ^ " refs/heads/x");
            ]
        in
        let refs = refs_of root in
        Alcotest.(check string)
          "loose" ("object " ^ h1)
          (lookup refs "refs/heads/main");
        Alcotest.(check string)
          "packed" "packed-refs has no final line feed"
          (lookup refs "refs/heads/x");
        Alcotest.(check string)
          "again" "packed-refs has no final line feed"
          (lookup refs "refs/heads/y"));
  ]

let fake_folder = "/g"

let fake_refs nodes =
  Fake.reset nodes;
  Fake_refs.create limits Refs.Files Id.Sha1 ~git_folder:fake_folder
    (Refs.Linked (fake_folder / "worktrees" / "w"))

(* @verifies changes#read-only-repository-files=v1
   On a system in memory that records each call, the lookups of the refs, HEAD
   among them, make calls only on pathnames inside the git folder and the
   folder of the working tree, and none for a text that is not a ref name,
   such as `refs/heads/../../x`, so the lookups take bytes only from
   repository files, item 1 of the list of the requirement; another call fails
   the test. The test sees only the refs: not the pathnames that their caller
   gives as the two folders. *)
let fake_tests =
  [
    case "the refs make calls only inside the two folders" (fun () ->
        let refs =
          fake_refs
            [
              ("/g/refs/heads/main", Fake.File (h1 ^ "\n"));
              ("/g/packed-refs", Fake.File (h2 ^ " refs/tags/v1\n"));
              ("/g/worktrees/w/HEAD", Fake.File "ref: refs/heads/main\n");
              ("/g/worktrees/w/refs/bisect/bad", Fake.File (h1 ^ "\n"));
            ]
        in
        List.iter
          (fun name -> ignore (Fake_refs.lookup refs name))
          [
            "refs/heads/main";
            "refs/tags/v1";
            "refs/heads/gone";
            "refs/bisect/bad";
            "HEAD";
            "ORIG_HEAD";
            "refs/heads/../../etc/passwd";
            "../x";
            "refs/heads/a\000";
            "x";
          ];
        List.iter
          (fun call ->
            match String.index_opt call ' ' with
            | Some space
              when String.length call > space + 1 && call.[space + 1] = '/' ->
                let path =
                  String.sub call (space + 1) (String.length call - space - 1)
                in
                Alcotest.(check bool)
                  call true
                  (String.starts_with ~prefix:"/g/" path
                  && not (List.mem ".." (String.split_on_char '/' path)))
            | _ -> ())
          (Test_repository_files.calls ()));
    case "a text that is not a ref name makes no call" (fun () ->
        let refs = fake_refs [] in
        List.iter
          (fun name ->
            ignore (Fake_refs.lookup refs name);
            Alcotest.(check (list string))
              name []
              (Test_repository_files.calls ()))
          [ "refs/heads/../../x"; "../x"; "refs/heads/a\000"; "x"; ""; "main" ]);
    case "a value of the refs reads packed-refs once" (fun () ->
        let refs =
          fake_refs
            [
              ( "/g/packed-refs",
                Fake.File (h2 ^ " refs/tags/v1\n" ^ h1 ^ " refs/tags/v2\n") );
            ]
        in
        let opens () =
          List.length
            (List.filter
               (fun call -> call = "open_file /g/packed-refs")
               (Test_repository_files.calls ()))
        in
        Alcotest.(check string)
          "v1" ("object " ^ h2)
          (show_lookup (Fake_refs.lookup refs "refs/tags/v1"));
        Alcotest.(check string)
          "v2" ("object " ^ h1)
          (show_lookup (Fake_refs.lookup refs "refs/tags/v2"));
        Alcotest.(check string)
          "v3" "none"
          (show_lookup (Fake_refs.lookup refs "refs/tags/v3"));
        Alcotest.(check int) "one open" 1 (opens ()));
    case "a FIFO at the pathname of a ref is not opened" (fun () ->
        let refs = fake_refs [ ("/g/refs/heads/pipe", Fake.Other) ] in
        ignore (Fake_refs.lookup refs "refs/heads/pipe");
        Alcotest.(check bool)
          "no open" false
          (List.mem "open_file /g/refs/heads/pipe"
             (Test_repository_files.calls ())));
    case "a value of the refs reads no file when it is made" (fun () ->
        ignore (fake_refs [ ("/g/HEAD", Fake.File (h1 ^ "\n")) ]);
        Alcotest.(check (list string))
          "calls" []
          (Test_repository_files.calls ()));
  ]

let no_wait_tests =
  [
    case
      "no lookup waits on a FIFO, as the interfaces of the refs and of the \
       reads promise" (fun () ->
        let probe root name =
          match Bounded_run.probe ~seconds:5. [ "refs"; root; name ] with
          | Ok lines -> lines
          | Error reason -> Alcotest.failf "the lookups: %s" reason
        in
        let root = git_folder [] in
        Unix.mkdir (root / "refs") 0o755;
        Unix.mkdir (root / "refs" / "heads") 0o755;
        Unix.mkfifo (root / "refs" / "heads" / "main") 0o600;
        Unix.mkfifo (root / "HEAD") 0o600;
        Alcotest.(check (list string))
          "a loose ref and HEAD" [ "none"; "none" ]
          (probe root "refs/heads/main");
        Unix.mkfifo (root / "packed-refs") 0o600;
        Alcotest.(check (list string))
          "packed-refs"
          [
            "unread packed-refs: not a regular file";
            "unread packed-refs: not a regular file";
          ]
          (probe root "refs/heads/other"));
  ]

let adapter_tests =
  [
    case "the refs give commits, other objects, names, and broken refs"
      (fun () ->
        let root =
          git_folder
            [
              ("refs/heads/main", h1 ^ "\n");
              ("refs/tags/t", h2 ^ "\n");
              ("refs/heads/alias", "ref: refs/heads/main\n");
              ("refs/heads/broken", "x");
              ("HEAD", "ref: refs/heads/alias\n");
            ]
        in
        let refs = refs_of root in
        let is_commit id = Ok (Id.to_hex id = h1) in
        let show = function
          | Ok (Some (Ref_commit.Commit id)) -> "commit " ^ Id.to_hex id
          | Ok (Some Ref_commit.Other) -> "other"
          | Ok (Some Ref_commit.Broken) -> "broken"
          | Ok (Some (Ref_commit.Ref name)) -> "ref " ^ name
          | Ok None -> "none"
          | Error _ -> "error"
        in
        let target = Refs.refs refs ~is_commit in
        List.iter
          (fun (name, expected) ->
            Alcotest.(check string) name expected (show (target name)))
          [
            ("refs/heads/main", "commit " ^ h1);
            ("refs/tags/t", "other");
            ("refs/heads/alias", "ref refs/heads/main");
            ("refs/heads/broken", "broken");
            ("refs/heads/gone", "none");
            ("HEAD", "ref refs/heads/alias");
          ];
        Alcotest.(check bool)
          "the head commit" true
          (match Ref_commit.commit target "HEAD" with
          | Ok (Some id) -> Id.to_hex id = h1
          | _ -> false);
        let failing _ = Error "the store" in
        Alcotest.(check bool)
          "an error of the objects" true
          (match Refs.refs refs ~is_commit:failing "refs/heads/main" with
          | Error (Refs.Objects "the store") -> true
          | _ -> false));
  ]

let set = Vectors.read "changes"

let hex_of_name name =
  let digest = Digest.to_hex (Digest.string name) in
  String.sub (digest ^ digest) 0 40

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let required name json =
  match member name json with
  | Some value -> value
  | None -> Alcotest.failf "no member %s" name

let commit_values commits = function
  | Ok (Some id) -> (
      match List.assoc_opt (Id.to_hex id) commits with
      | Some name -> `Assoc [ ("values", `Assoc [ ("commit", `String name) ]) ]
      | None -> `String "an unknown commit")
  | Ok None -> `Assoc [ ("values", `Assoc []) ]
  | Error _ -> `String "an error"

let ref_commits_on ~packed (vector : Vectors.vector) =
  let refs =
    match required "refs" vector.input with
    | `Assoc refs -> refs
    | _ -> Alcotest.fail "no refs"
  in
  let commits = ref [] in
  let loose = ref [] and lines = ref [] in
  List.iter
    (fun (name, target) ->
      let object_line hex =
        if packed then lines := (hex ^ " " ^ name ^ "\n") :: !lines
        else loose := (name, hex ^ "\n") :: !loose
      in
      match target with
      | `Assoc [ ("commit", `String c) ] ->
          commits := (hex_of_name c, c) :: !commits;
          object_line (hex_of_name c)
      | `Assoc [ ("other", `String o) ] ->
          object_line (hex_of_name ("other " ^ o))
      | `Assoc [ ("ref", `String r) ] ->
          loose := (name, "ref: " ^ r ^ "\n") :: !loose
      | `Assoc [] -> loose := (name, "") :: !loose
      | other ->
          Alcotest.failf "not a target: %s" (Yojson.Basic.to_string other))
    refs;
  let root =
    git_folder (("packed-refs", String.concat "" (List.rev !lines)) :: !loose)
  in
  let is_commit id = Ok (List.mem_assoc (Id.to_hex id) !commits) in
  let name =
    match required "ref" vector.input with
    | `String n -> n
    | _ -> Alcotest.fail "no ref"
  in
  commit_values !commits
    (Ref_commit.commit (Refs.refs (refs_of root) ~is_commit) name)

let head_commits_on (vector : Vectors.vector) =
  let refs =
    match required "refs" vector.input with
    | `Assoc refs ->
        List.map
          (function
            | name, `String c -> (name, c) | _ -> Alcotest.fail "not a ref")
          refs
    | _ -> Alcotest.fail "no refs"
  in
  let head =
    match required "head" vector.input with
    | `Assoc [ ("ref", `String r) ] -> "ref: " ^ r ^ "\n"
    | `Assoc [ ("commit", `String c) ] -> hex_of_name c ^ "\n"
    | _ -> Alcotest.fail "not a HEAD"
  in
  let root =
    git_folder
      (("HEAD", head)
      :: List.map (fun (name, c) -> (name, hex_of_name c ^ "\n")) refs)
  in
  let commits =
    List.map (fun (_, c) -> (hex_of_name c, c)) refs
    @
    match required "head" vector.input with
    | `Assoc [ ("commit", `String c) ] -> [ (hex_of_name c, c) ]
    | _ -> []
  in
  let is_commit id = Ok (List.mem_assoc (Id.to_hex id) commits) in
  commit_values commits
    (Ref_commit.commit (Refs.refs (refs_of root) ~is_commit) "HEAD")

(* @verifies changes[ref-commits]
   Each vector is written as loose refs in the files format, once with each
   ref that points to a git object as a loose ref and once in packed-refs, and
   a broken loose ref as an empty file; the commit of the ref from the reader
   of the files format must be that of the vector, so a reader that reads an
   empty file as no ref, or a packed ref under a broken loose ref, fails. *)
let ref_commit_vectors =
  [
    Vectors.group set ~name:"ref-commits" ~form:"#ref-commit-vector=v1"
      (ref_commits_on ~packed:false);
    Vectors.group set ~name:"ref-commits" ~form:"#ref-commit-vector=v1"
      (ref_commits_on ~packed:true);
  ]

(* @verifies changes[head-commits]
   Each vector is written as the file HEAD and loose refs; the head commit
   from the reader of the files format must be that of the vector, or the test
   fails. *)
let head_commit_vectors =
  [
    Vectors.group set ~name:"head-commits" ~form:"#head-commit-vector=v1"
      head_commits_on;
  ]

let git_lines repo args =
  match Git_fixture.git repo args with
  | output ->
      List.filter (fun line -> line <> "") (String.split_on_char '\n' output)
  | exception Failure _ -> []

let compare_with_git ?(object_format = "sha1") () =
  let format = if object_format = "sha1" then Id.Sha1 else Id.Sha256 in
  let repo = Git_fixture.init ~object_format () in
  Git_fixture.import repo
    [
      Git_fixture.commit ~ref:"refs/heads/main" ~mark:1 ~message:"a"
        [ Git_fixture.File ("a.md", "a\n") ];
      Git_fixture.commit ~ref:"refs/heads/main" ~mark:2 ~message:"b"
        [ Git_fixture.File ("b.md", "b\n") ];
      Git_fixture.reset ~ref:"refs/heads/topic/x" ~mark:1;
    ];
  ignore
    (Git_fixture.git repo [ "tag"; "-a"; "-m"; "t"; "v1"; "refs/heads/main" ]);
  ignore (Git_fixture.git repo [ "tag"; "light"; "refs/heads/topic/x" ]);
  ignore
    (Git_fixture.git repo
       [ "symbolic-ref"; "refs/remotes/origin/HEAD"; "refs/heads/main" ]);
  ignore (Git_fixture.git repo [ "pack-refs"; "--all" ]);
  ignore
    (Git_fixture.git repo
       [ "update-ref"; "refs/heads/main"; "refs/heads/topic/x" ]);
  ignore
    (Git_fixture.git repo
       [ "update-ref"; "refs/heads/loose"; "refs/heads/topic/x" ]);
  let git_folder = Git_fixture.root repo / ".git" in
  let before = Git_fixture.git_dir_state repo in
  let refs = Refs.create limits Refs.Files format ~git_folder Refs.Main in
  let names = git_lines repo [ "for-each-ref"; "--format=%(refname)" ] in
  Alcotest.(check bool) "git gives refs" true (List.length names >= 5);
  List.iter
    (fun name ->
      let expected =
        match git_lines repo [ "symbolic-ref"; "-q"; "--no-recurse"; name ] with
        | [ target ] -> Printf.sprintf "symbolic %S" target
        | _ -> (
            match git_lines repo [ "rev-parse"; "--verify"; name ] with
            | [ hex ] -> "object " ^ hex
            | _ -> "none")
      in
      Alcotest.(check string)
        name expected
        (show_lookup (Refs.lookup refs name)))
    names;
  Alcotest.(check string)
    "HEAD" "symbolic \"refs/heads/main\""
    (show_lookup (Refs.lookup refs "HEAD"));
  Alcotest.(check (list string))
    "no file under .git changed" before
    (Git_fixture.git_dir_state repo)

(* @verifies changes#give-ref-commits=v1
   In repositories that git writes, in both object formats, with packed refs,
   peeled tags, loose refs that hide packed ones, and a symbolic ref, the
   reader must give for each ref the exact target that git gives (`git
   symbolic-ref` or `git rev-parse`) and no other, or none, never both. *)
let git_tests =
  [
    case "the refs agree with git in sha1" (fun () -> compare_with_git ());
    case "the refs agree with git in sha256" (fun () ->
        compare_with_git ~object_format:"sha256" ());
    (* @verifies changes#give-head-commits=v1
       In a linked working tree that `git worktree add` makes, the HEAD from
       the folder of that working tree must give the exact commit that git
       gives for HEAD there and no other commit, or no commit, never both, and
       the main HEAD must stay that of the main working tree. *)
    case "the HEAD of a linked working tree agrees with git" (fun () ->
        let repo = Git_fixture.init () in
        Git_fixture.import repo
          [
            Git_fixture.commit ~ref:"refs/heads/main" ~mark:1 ~message:"a"
              [ Git_fixture.File ("a.md", "a\n") ];
            Git_fixture.commit ~ref:"refs/heads/other" ~mark:2 ~message:"b"
              [ Git_fixture.File ("b.md", "b\n") ];
          ];
        let linked = Git_fixture.temp_dir () / "linked" in
        ignore
          (Git_fixture.git repo
             [ "worktree"; "add"; "--detach"; linked; "refs/heads/other" ]);
        let git_folder = Git_fixture.root repo / ".git" in
        let worktrees = Sys.readdir (git_folder / "worktrees") in
        Alcotest.(check int)
          "one linked working tree" 1 (Array.length worktrees);
        let folder = git_folder / "worktrees" / worktrees.(0) in
        let refs =
          Refs.create limits Refs.Files Id.Sha1 ~git_folder (Refs.Linked folder)
        in
        let expected =
          String.trim (Git_fixture.git repo [ "rev-parse"; "refs/heads/other" ])
        in
        Alcotest.(check string) "linked HEAD" ("object " ^ expected) (head refs);
        Alcotest.(check string)
          "main HEAD" "symbolic \"refs/heads/main\""
          (head (Refs.create limits Refs.Files Id.Sha1 ~git_folder Refs.Main)));
  ]

let tests =
  loose_tests @ packed_tests @ files_tests @ fake_tests @ no_wait_tests
  @ adapter_tests
  @ Vectors.tests "changes on the files format"
      (ref_commit_vectors @ head_commit_vectors)
  @ git_tests
