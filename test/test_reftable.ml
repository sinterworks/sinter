(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Id = Sinter_git_objects.Object_id
module Files = Sinter_repository_files
module Config = Sinter_git_config
module Ref_name = Sinter_ref_names.Ref_name
module Loose_ref = Sinter_git_refs.Loose_ref
module Reftable = Sinter_git_refs.Reftable
module Refs = Sinter_git_refs.Refs
module Ref_commit = Sinter_git_model.Ref_commit
module Default_branch = Sinter_git_model.Default_branch
module Text = Sinter_text.Text
module Fake = Test_repository_files.Fake
module Fake_refs = Refs.Make (Test_repository_files.Reader)
module W = Reftable_writer

let ( / ) = Filename.concat
let case name f = Alcotest.test_case name `Quick f

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let default_limits =
  {
    Refs.max_loose_size = 1 lsl 16;
    max_packed_size = 1 lsl 30;
    max_tables_list_size = 1 lsl 20;
    max_stack_size = 1 lsl 26;
    max_names_size = 1 lsl 26;
  }

let raw_id_of_hex hex =
  String.init
    (String.length hex lsr 1)
    (fun i -> Char.chr (int_of_string ("0x" ^ String.sub hex (i * 2) 2)))

let sha1_hex c = String.make 40 c
let sha256_hex c = String.make 64 c
let sha1_raw c = raw_id_of_hex (sha1_hex c)
let sha256_raw c = raw_id_of_hex (sha256_hex c)

let hex_of_name format name =
  let d1 = Digest.to_hex (Digest.string ("a:" ^ name)) in
  let d2 = Digest.to_hex (Digest.string ("b:" ^ name)) in
  match format with
  | Id.Sha1 -> String.sub (d1 ^ d2) 0 40
  | Id.Sha256 -> String.sub (d1 ^ d2) 0 64

let show_record = function
  | Reftable.Deletion -> "deletion"
  | Reftable.Object id -> "object " ^ Id.to_hex id
  | Reftable.Symbolic name -> Printf.sprintf "symbolic %S" name

let show_reftable_error = function
  | Reftable.Not_a_table -> "not a table"
  | Reftable.Other_object_format -> "other object format"
  | Reftable.Bad_footer -> "bad footer"
  | Reftable.Bad_block off -> Printf.sprintf "bad block %d" off
  | Reftable.Names_too_large -> "names too large"

let show_list_error = function
  | Reftable.No_final_line_feed -> "no final line feed"
  | Reftable.Bad_table_name s -> Printf.sprintf "bad table name %S" s
  | Reftable.Repeated_table_name s -> Printf.sprintf "repeated table name %S" s

let show_storage_error = function
  | Refs.Not_a_version None -> "not a version none"
  | Refs.Not_a_version (Some s) -> Printf.sprintf "not a version %S" s
  | Refs.Not_version_1 -> "not version 1"
  | Refs.Unknown_format None -> "unknown format none"
  | Refs.Unknown_format (Some s) -> Printf.sprintf "unknown format %S" s
  | Refs.Payload p -> Printf.sprintf "payload %S" p

let show_storage = function
  | Ok Refs.Files -> "files"
  | Ok Refs.Reftable -> "reftable"
  | Error e -> "error: " ^ show_storage_error e

let show_target = function
  | Loose_ref.Object id -> "object " ^ Id.to_hex id
  | Loose_ref.Symbolic name -> Printf.sprintf "symbolic %S" name
  | Loose_ref.Broken -> "broken"

let show_refs_error = function
  | Refs.Unread { pathname; failure } ->
      Printf.sprintf "unread %s: %s"
        (Filename.basename pathname)
        (Test_repository_files.failure_name failure)
  | Refs.Malformed_packed_refs _ -> "malformed packed-refs"
  | Refs.Malformed_tables_list { pathname; error } ->
      Printf.sprintf "malformed tables.list %s: %s"
        (Filename.basename pathname)
        (show_list_error error)
  | Refs.Malformed_table { pathname; error } ->
      Printf.sprintf "malformed table %s: %s"
        (Filename.basename pathname)
        (show_reftable_error error)

let show_lookup = function
  | Ok (Some t) -> show_target t
  | Ok None -> "none"
  | Error e -> show_refs_error e

let write_file path content =
  let rec parents dir =
    if not (Sys.file_exists dir) then (
      parents (Filename.dirname dir);
      Unix.mkdir dir 0o755)
  in
  parents (Filename.dirname path);
  Out_channel.with_open_bin path (fun ch ->
      Out_channel.output_string ch content)

let read_file path = In_channel.with_open_bin path In_channel.input_all

let flip_byte s offset =
  let b = Bytes.of_string s in
  Bytes.set b offset (Char.chr (Char.code (Bytes.get b offset) lxor 0xff));
  Bytes.to_string b

let set_byte s offset value =
  let b = Bytes.of_string s in
  Bytes.set b offset (Char.chr value);
  Bytes.to_string b

let set_u64_be s offset value =
  let b = Bytes.of_string s in
  for shift = 7 downto 0 do
    let byte =
      Int64.to_int
        (Int64.logand (Int64.shift_right_logical value (shift * 8)) 0xffL)
    in
    Bytes.set b (offset + (7 - shift)) (Char.chr byte)
  done;
  Bytes.to_string b

let set_u24_be s offset value =
  let b = Bytes.of_string s in
  Bytes.set b offset (Char.chr ((value lsr 16) land 0xff));
  Bytes.set b (offset + 1) (Char.chr ((value lsr 8) land 0xff));
  Bytes.set b (offset + 2) (Char.chr (value land 0xff));
  Bytes.to_string b

let set_u16_be s offset value =
  let b = Bytes.of_string s in
  Bytes.set b offset (Char.chr ((value lsr 8) land 0xff));
  Bytes.set b (offset + 1) (Char.chr (value land 0xff));
  Bytes.to_string b

let parse_ok ?(format = Id.Sha1) ?(max_names = 1 lsl 20) bytes =
  match Reftable.parse format ~max_names bytes with
  | Ok t -> t
  | Error e -> Alcotest.failf "expected Ok, got %s" (show_reftable_error e)

let parse_err ?(format = Id.Sha1) ?(max_names = 1 lsl 20) bytes =
  match Reftable.parse format ~max_names bytes with
  | Ok _ -> "ok"
  | Error e -> show_reftable_error e

let parse_config text =
  match Config.parse text with
  | Ok settings -> settings
  | Error { line } -> Alcotest.failf "bad config at line %d" line

let run_git_env ~home ~ceiling =
  let inherited =
    Array.to_list (Unix.environment ())
    |> List.filter (fun entry ->
        not
          (String.starts_with ~prefix:"GIT_" entry
          || String.starts_with ~prefix:"HOME=" entry
          || String.starts_with ~prefix:"XDG_CONFIG_HOME=" entry))
  in
  Array.of_list
    (inherited
    @ [
        "HOME=" ^ home;
        "GIT_CONFIG_NOSYSTEM=1";
        "GIT_CONFIG_GLOBAL=/dev/null";
        "GIT_CEILING_DIRECTORIES=" ^ Unix.realpath ceiling;
        "GIT_AUTHOR_NAME=t";
        "GIT_AUTHOR_EMAIL=t@example.com";
        "GIT_COMMITTER_NAME=t";
        "GIT_COMMITTER_EMAIL=t@example.com";
        "GIT_AUTHOR_DATE=1700000000 +0000";
        "GIT_COMMITTER_DATE=1700000000 +0000";
      ])

let spawn_git ~env ~dir ?(input = "") args =
  let scratch = Git_fixture.temp_dir () in
  let p name = scratch / name in
  write_file (p "in") input;
  let open_fd name flags = Unix.openfile (p name) flags 0o600 in
  let stdin = open_fd "in" [ Unix.O_RDONLY ] in
  let stdout = open_fd "out" [ Unix.O_WRONLY; Unix.O_CREAT ] in
  let stderr = open_fd "err" [ Unix.O_WRONLY; Unix.O_CREAT ] in
  let pid =
    Fun.protect
      ~finally:(fun () -> List.iter Unix.close [ stdin; stdout; stderr ])
      (fun () ->
        Unix.create_process_env "/usr/bin/git"
          (Array.of_list ("git" :: "-C" :: dir :: args))
          env stdin stdout stderr)
  in
  let _, status = Unix.waitpid [] pid in
  let code =
    match status with
    | Unix.WEXITED c -> c
    | Unix.WSIGNALED _ | Unix.WSTOPPED _ -> 255
  in
  (code, read_file (p "out"), read_file (p "err"))

type rt_repo = { dir : string; env : string array }

let git_ok repo ?input args =
  let code, out, err = spawn_git ~env:repo.env ~dir:repo.dir ?input args in
  if code = 0 then out
  else Alcotest.failf "git %s failed (%d): %s" (String.concat " " args) code err

let git_lines repo args =
  let code, out, _ = spawn_git ~env:repo.env ~dir:repo.dir args in
  if code <> 0 then []
  else List.filter (fun s -> s <> "") (String.split_on_char '\n' out)

let git_status repo args =
  let code, _, _ = spawn_git ~env:repo.env ~dir:repo.dir args in
  code

let init_reftable ?(extra = []) () =
  let base = Git_fixture.temp_dir () in
  let home = base / "home" in
  let dir = base / "repo" in
  Unix.mkdir home 0o700;
  Unix.mkdir dir 0o755;
  let env = run_git_env ~home ~ceiling:base in
  let code, _, err =
    spawn_git ~env ~dir
      ([ "init"; "-q"; "--ref-format=reftable"; "-b"; "main" ] @ extra)
  in
  if code <> 0 then Alcotest.failf "git init failed (%d): %s" code err;
  { dir = Unix.realpath dir; env }

let git_commit repo msg =
  ignore (git_ok repo [ "commit"; "-q"; "--allow-empty"; "-m"; msg ])

let rec copy_tree src dst =
  let st = Unix.lstat src in
  match st.Unix.st_kind with
  | Unix.S_DIR ->
      Unix.mkdir dst 0o755;
      Array.iter
        (fun name -> copy_tree (src / name) (dst / name))
        (Sys.readdir src)
  | Unix.S_LNK -> Unix.symlink (Unix.readlink src) dst
  | _ ->
      write_file dst (read_file src);
      Unix.chmod dst st.Unix.st_perm

let dir_state root =
  let rec walk rel =
    let path = if rel = "" then root else root / rel in
    match Unix.lstat path with
    | { Unix.st_kind = Unix.S_DIR; _ } ->
        (rel ^ "/")
        :: List.concat_map
             (fun name -> walk (if rel = "" then name else rel / name))
             (List.sort String.compare (Array.to_list (Sys.readdir path)))
    | st ->
        [
          Printf.sprintf "%s:%d:%d:%h:%s" rel st.Unix.st_ino st.Unix.st_size
            st.Unix.st_mtime
            (Digest.to_hex (Digest.file path));
        ]
  in
  walk ""

let git_expected_target repo name =
  match git_lines repo [ "symbolic-ref"; "-q"; "--no-recurse"; name ] with
  | [ target ] -> Printf.sprintf "symbolic %S" target
  | _ -> (
      match git_lines repo [ "rev-parse"; "--verify"; name ] with
      | [ hex ] -> "object " ^ hex
      | _ -> "none")

let table_names_tests =
  [
    case "empty tables.list names no table" (fun () ->
        Alcotest.(check (result (list string) string))
          "empty" (Ok [])
          (Result.map_error show_list_error (Reftable.table_names "")));
    case "valid tables.list preserves oldest-to-newest order and plain names"
      (fun () ->
        let content =
          "0x000000000001-0x000000000001-aaaa1111.ref\n\
           not-a-table-name.ref\n\
           0x000000000002-0x000000000005-bbbb2222.ref\n"
        in
        Alcotest.(check (result (list string) string))
          "names"
          (Ok
             [
               "0x000000000001-0x000000000001-aaaa1111.ref";
               "not-a-table-name.ref";
               "0x000000000002-0x000000000005-bbbb2222.ref";
             ])
          (Result.map_error show_list_error (Reftable.table_names content)));
    case "tables.list rejects missing final line feed, bad names, and repeats"
      (fun () ->
        List.iter
          (fun (content, expected) ->
            Alcotest.(check string)
              (Printf.sprintf "%S" content)
              expected
              (match Reftable.table_names content with
              | Ok _ -> "ok"
              | Error e -> show_list_error e))
          [
            ("a.ref", "no final line feed");
            ("a.ref\nb.ref", "no final line feed");
            ("\n", "bad table name \"\"");
            ("a.ref\n\nb.ref\n", "bad table name \"\"");
            (".\n", "bad table name \".\"");
            ("..\n", "bad table name \"..\"");
            ("../../../outside.ref\n", "bad table name \"../../../outside.ref\"");
            ("sub/a.ref\n", "bad table name \"sub/a.ref\"");
            ("/abs.ref\n", "bad table name \"/abs.ref\"");
            ("a\000b.ref\n", "bad table name \"a\\000b.ref\"");
            ("a.ref\na.ref\n", "repeated table name \"a.ref\"");
            ("a.ref\nb.ref\na.ref\n", "repeated table name \"a.ref\"");
          ]);
    property ~name:"table_names round-trips valid unique lists"
      ~print:(String.concat "; ")
      Gen.(
        let name =
          string_size
            ~gen:(oneof_list [ 'a'; 'b'; '0'; '1'; '-'; '.'; '_' ])
            (int_range 1 12)
        in
        map
          (fun xs ->
            let valid = List.filter (fun s -> s <> "." && s <> "..") xs in
            List.fold_left
              (fun acc s -> if List.mem s acc then acc else s :: acc)
              [] valid
            |> List.rev)
          (list_size (int_range 0 10) name))
      (fun names ->
        let content = String.concat "" (List.map (fun n -> n ^ "\n") names) in
        Reftable.table_names content = Ok names);
    property ~count:2000 ~name:"table_names takes any bytes and checks its form"
      ~print:(Printf.sprintf "%S")
      Gen.(
        oneof
          [
            string_size ~gen:char (int_range 0 80);
            map (String.concat "")
              (list_size (int_range 0 8)
                 (oneof_list [ "a.ref"; "b.ref"; "\n"; "/"; "."; ".."; "\000" ]));
          ])
      (fun content ->
        match Reftable.table_names content with
        | Error _ -> true
        | Ok names ->
            let rebuilt =
              String.concat "" (List.map (fun n -> n ^ "\n") names)
            in
            let unique =
              List.length (List.sort_uniq String.compare names)
              = List.length names
            in
            let all_valid =
              List.for_all
                (fun n ->
                  n <> "" && n <> "." && n <> ".."
                  && (not (String.contains n '/'))
                  && not (String.contains n '\000'))
                names
            in
            rebuilt = content && unique && all_valid);
  ]

let storage_tests =
  [
    case "storage defaults to files when extensions.refStorage is absent"
      (fun () ->
        List.iter
          (fun cfg ->
            Alcotest.(check string)
              (Printf.sprintf "%S" cfg) "files"
              (show_storage (Refs.storage (parse_config cfg))))
          [
            "";
            "[core]\n\trepositoryformatversion = 0\n";
            "[core]\n\trepositoryformatversion = 1\n";
            "[core]\n\trepositoryformatversion = 2\n";
            "[core]\n\trepositoryformatversion = -1\n";
            "[core]\n\trepositoryformatversion = -2\n";
          ]);
    case "storage accepts files and reftable formats under version 1" (fun () ->
        List.iter
          (fun (cfg, expected) ->
            Alcotest.(check string)
              (Printf.sprintf "%S" cfg) expected
              (show_storage (Refs.storage (parse_config cfg))))
          [
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = files\n",
              "files" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefStorage = files://\n",
              "files" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "reftable" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefStorage = reftable://\n",
              "reftable" );
            ( "[EXTENSIONS]\n\
               \tREFSTORAGE = reftable\n\
               [CORE]\n\
               \tREPOSITORYFORMATVERSION = 1\n",
              "reftable" );
            ( "[core]\n\
               \trepositoryformatversion = 0\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = files\n\
               \trefstorage = reftable\n",
              "reftable" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = reftable\n\
               \trefstorage = files\n",
              "files" );
          ]);
    case "storage rejects non-version-1, unknown formats, and payloads"
      (fun () ->
        List.iter
          (fun (cfg, expected) ->
            Alcotest.(check string)
              (Printf.sprintf "%S" cfg) expected
              (show_storage (Refs.storage (parse_config cfg))))
          [
            ( "[core]\n\
               \trepositoryformatversion = 0\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "error: not version 1" );
            ( "[core]\n\
               \trepositoryformatversion = 0\n\
               [extensions]\n\
               \trefstorage = files\n",
              "error: not version 1" );
            ( "[core]\n\
               \trepositoryformatversion = 2\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "error: not version 1" );
            ( "[core]\n\
               \trepositoryformatversion\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "error: not a version none" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               \trepositoryformatversion = 0\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "error: not version 1" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = Reftable\n",
              "error: unknown format \"Reftable\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = REFTABLE\n",
              "error: unknown format \"REFTABLE\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = Files\n",
              "error: unknown format \"Files\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = \n",
              "error: unknown format \"\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage\n",
              "error: unknown format none" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = postgres://127.0.0.1\n",
              "error: unknown format \"postgres://127.0.0.1\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = reftable:///abs/path\n",
              "error: payload \"/abs/path\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = reftable://../../rel\n",
              "error: payload \"../../rel\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = files:///abs/path\n",
              "error: payload \"/abs/path\"" );
            ( "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = files://rel\n",
              "error: payload \"rel\"" );
          ]);
    (* @verifies changes#give-ref-commits=v1
       The ref storage format of a git repository comes from the file `config`
       of its git folder by the rules of git 2.54.0. `Refs.storage` reads
       `core.repositoryformatversion` as a git integer and rejects any
       non-integer value with `Not_a_version` first. Next, it rejects any
       unknown value of `extensions.refStorage` with `Unknown_format`. It
       returns `Files` when the version is absent or -1. It rejects version 0
       or 2 or more with `Not_version_1`, and uses the last format under
       version 1 or a version below -1. *)
    case
      "storage follows git rules for integer versions, absent or negative \
       versions, and all values" (fun () ->
        List.iter
          (fun (name, cfg, expected) ->
            Alcotest.(check string)
              name expected
              (show_storage (Refs.storage (parse_config cfg))))
          [
            ( "version 01",
              "[core]\n\
               \trepositoryformatversion = 01\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "reftable" );
            ( "version absent ignores valid refStorage",
              "[extensions]\n\trefstorage = reftable\n",
              "files" );
            ( "version absent ignores valid refStorage with payload",
              "[extensions]\n\trefstorage = reftable:///abs/path\n",
              "files" );
            ( "version -1 ignores valid refStorage",
              "[core]\n\
               \trepositoryformatversion = -1\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "files" );
            ( "version -2 uses reftable",
              "[core]\n\
               \trepositoryformatversion = -2\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "reftable" );
            ( "version -2 still rejects payload",
              "[core]\n\
               \trepositoryformatversion = -2\n\
               [extensions]\n\
               \trefstorage = reftable:///abs\n",
              "error: payload \"/abs\"" );
            ( "earlier payload overridden by plain reftable succeeds",
              "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = reftable:///abs\n\
               \trefstorage = reftable\n",
              "reftable" );
            ( "non-integer version without refStorage fails",
              "[core]\n\trepositoryformatversion = one\n",
              "error: not a version \"one\"" );
            ( "bad version then good version reports first bad version",
              "[core]\n\
               \trepositoryformatversion = one\n\
               \trepositoryformatversion = two\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = reftable\n",
              "error: not a version \"one\"" );
            ( "bad version wins over bad refStorage",
              "[extensions]\n\
               \trefstorage = bogus\n\
               [core]\n\
               \trepositoryformatversion = one\n",
              "error: not a version \"one\"" );
            ( "unknown format then valid format fails on first unknown",
              "[core]\n\
               \trepositoryformatversion = 1\n\
               [extensions]\n\
               \trefstorage = bogus\n\
               \trefstorage = other\n\
               \trefstorage = reftable\n",
              "error: unknown format \"bogus\"" );
            ( "unknown format fails when version is absent",
              "[extensions]\n\trefstorage = bogus\n",
              "error: unknown format \"bogus\"" );
            ( "unknown format fails when version is 0",
              "[core]\n\
               \trepositoryformatversion = 0\n\
               [extensions]\n\
               \trefstorage = bogus\n",
              "error: unknown format \"bogus\"" );
          ]);
    (* @verifies changes#give-ref-commits=v1
       Over generated lists of interleaved `core.repositoryformatversion`,
       `extensions.refStorage`, and other settings, `Refs.storage` checks every
       version value first and every `extensions.refStorage` value next. It
       returns `Files` when `extensions.refStorage` is absent or
       `format_version` gives `None`. It returns `Not_version_1` for version 0
       or 2 or more, and decodes the last `extensions.refStorage` value
       otherwise. *)
    property ~count:400
      ~name:"storage follows the specification on generated settings"
      ~print:(fun items ->
        String.concat "; "
          (List.map
             (function
               | `Ver None -> "ver=<no =>"
               | `Ver (Some s) -> Printf.sprintf "ver=%S" s
               | `Ref None -> "ref=<no =>"
               | `Ref (Some s) -> Printf.sprintf "ref=%S" s
               | `Other -> "other")
             items))
      Gen.(
        let ver_val =
          oneof_list
            [
              Some "0";
              Some "1";
              Some "01";
              Some "+1";
              Some "0x1";
              Some " 1";
              Some "0k";
              Some "-1";
              Some "-01";
              Some "-2";
              Some "2";
              Some "1k";
              Some "one";
              Some "";
              Some "08";
              None;
            ]
        in
        let ref_val =
          oneof_list
            [
              Some "files";
              Some "files://";
              Some "files:///p";
              Some "reftable";
              Some "reftable://";
              Some "reftable:///p";
              Some "bogus";
              Some "Reftable";
              Some "";
              None;
            ]
        in
        list_size (int_range 0 6)
          (oneof
             [
               map (fun v -> `Ver v) ver_val;
               map (fun s -> `Ref s) ref_val;
               return `Other;
             ]))
      (fun items ->
        let k_ver = Config.key ~section:"core" "repositoryformatversion" in
        let k_ref = Config.key ~section:"extensions" "refStorage" in
        let k_other = Config.key ~section:"core" "bare" in
        let settings =
          List.map
            (function
              | `Ver v -> (k_ver, v)
              | `Ref s -> (k_ref, s)
              | `Other -> (k_other, Some "false"))
            items
        in
        let storages =
          List.filter_map (function `Ref s -> Some s | _ -> None) items
        in
        let parse_fmt = function
          | Some "files" | Some "files://" -> Ok (Refs.Files, "")
          | Some "reftable" | Some "reftable://" -> Ok (Refs.Reftable, "")
          | Some s when String.starts_with ~prefix:"files://" s ->
              Ok (Refs.Files, String.sub s 8 (String.length s - 8))
          | Some s when String.starts_with ~prefix:"reftable://" s ->
              Ok (Refs.Reftable, String.sub s 11 (String.length s - 11))
          | other -> Error other
        in
        let expected =
          match Config.format_version settings with
          | Error bad -> Error (Refs.Not_a_version bad)
          | Ok ver -> (
              match
                List.find_map
                  (fun v ->
                    match parse_fmt v with Ok _ -> None | Error e -> Some e)
                  storages
              with
              | Some bad -> Error (Refs.Unknown_format bad)
              | None -> (
                  match (List.rev storages, ver) with
                  | [], _ | _, None -> Ok Refs.Files
                  | _, Some n when n = 0 || n >= 2 -> Error Refs.Not_version_1
                  | last :: _, Some _ -> (
                      match parse_fmt last with
                      | Ok (fmt, "") -> Ok fmt
                      | Ok (_, payload) -> Error (Refs.Payload payload)
                      | Error bad -> Error (Refs.Unknown_format bad))))
        in
        Refs.storage settings = expected);
    case "storage agrees with git config on real repositories" (fun () ->
        let rt = init_reftable () in
        let fl = Git_fixture.init () in
        Alcotest.(check string)
          "reftable" "reftable"
          (show_storage
             (Refs.storage (parse_config (read_file (rt.dir / ".git/config")))));
        Alcotest.(check string)
          "files" "files"
          (show_storage
             (Refs.storage
                (parse_config (read_file (Git_fixture.root fl / ".git/config"))))));
  ]

let parse_valid_tests =
  [
    case "empty tables in v1, v2 sha1, and v2 s256 hold no records" (fun () ->
        List.iter
          (fun (version, format) ->
            let bytes = W.encode ~config:{ W.default_config with version } [] in
            let t = parse_ok ~format ~max_names:0 bytes in
            Alcotest.(check int) "names_size" 0 (Reftable.names_size t);
            Alcotest.(check (option string))
              "find" None
              (Option.map show_record (Reftable.find t "HEAD")))
          [ (W.V1, Id.Sha1); (W.V2_sha1, Id.Sha1); (W.V2_sha256, Id.Sha256) ]);
    case "log-only tables in v1 and v2 hold no ref records" (fun () ->
        List.iter
          (fun (version, format) ->
            let log_body = "\000\000\010dummy-log!" in
            let bytes =
              W.encode
                ~config:
                  { W.default_config with version; log_block = Some log_body }
                []
            in
            let t = parse_ok ~format ~max_names:0 bytes in
            Alcotest.(check int) "names_size" 0 (Reftable.names_size t);
            Alcotest.(check (option string))
              "find" None
              (Option.map show_record (Reftable.find t "refs/heads/main"));
            let fl =
              match version with W.V1 -> 68 | W.V2_sha1 | W.V2_sha256 -> 72
            in
            let hl =
              match version with W.V1 -> 24 | W.V2_sha1 | W.V2_sha256 -> 28
            in
            let fstart = String.length bytes - fl in
            let zero_log_pos =
              W.patch_footer_crc version
                (set_u64_be bytes (fstart + hl + 24) 0L)
            in
            let t0 = parse_ok ~format ~max_names:0 zero_log_pos in
            Alcotest.(check int)
              "zero log_pos names_size" 0 (Reftable.names_size t0))
          [ (W.V1, Id.Sha1); (W.V2_sha1, Id.Sha1); (W.V2_sha256, Id.Sha256) ]);
    case "all four value types decode in v1, v2 sha1, and v2 s256" (fun () ->
        let check_version version format hex1 hex2 raw1 raw2 =
          let recs =
            [
              {
                W.name = "HEAD";
                update_index_delta = 0L;
                value = W.Symbolic "refs/heads/main";
              };
              {
                W.name = "refs/heads/bad-sym";
                update_index_delta = 1L;
                value = W.Symbolic "not a ref name";
              };
              {
                W.name = "refs/heads/deleted";
                update_index_delta = 200L;
                value = W.Deletion;
              };
              {
                W.name = "refs/heads/foo";
                update_index_delta = 17_000L;
                value = W.Object raw1;
              };
              {
                W.name = "refs/heads/foo/bar";
                update_index_delta = 300_000L;
                value = W.Object raw2;
              };
              {
                W.name = "refs/tags/annotated";
                update_index_delta = 0L;
                value = W.Peeled (raw1, raw2);
              };
            ]
          in
          let bytes =
            W.encode
              ~config:
                {
                  W.default_config with
                  version;
                  max_update_index = 500_000L;
                  log_block = Some "\000\000\008logbytes";
                }
              recs
          in
          let expected_names_size =
            List.fold_left (fun acc r -> acc + String.length r.W.name) 0 recs
          in
          let t = parse_ok ~format ~max_names:expected_names_size bytes in
          Alcotest.(check int)
            "names_size" expected_names_size (Reftable.names_size t);
          List.iter
            (fun (name, expected) ->
              Alcotest.(check (option string))
                name expected
                (Option.map show_record (Reftable.find t name)))
            [
              ("HEAD", Some "symbolic \"refs/heads/main\"");
              ("refs/heads/bad-sym", Some "symbolic \"not a ref name\"");
              ("refs/heads/deleted", Some "deletion");
              ("refs/heads/foo", Some ("object " ^ hex1));
              ("refs/heads/foo/bar", Some ("object " ^ hex2));
              ("refs/tags/annotated", Some ("object " ^ hex1));
              ("refs/heads/fo", None);
              ("refs/heads/foo/", None);
              ("refs/heads/missing", None);
            ];
          Alcotest.(check string)
            "max_names boundary minus one" "names too large"
            (parse_err ~format ~max_names:(expected_names_size - 1) bytes)
        in
        check_version W.V1 Id.Sha1 (sha1_hex 'a') (sha1_hex 'b') (sha1_raw 'a')
          (sha1_raw 'b');
        check_version W.V2_sha1 Id.Sha1 (sha1_hex 'a') (sha1_hex 'b')
          (sha1_raw 'a') (sha1_raw 'b');
        check_version W.V2_sha256 Id.Sha256 (sha256_hex 'c') (sha256_hex 'd')
          (sha256_raw 'c') (sha256_raw 'd'));
    case "single padded block, unaligned multi-block, and multi-level ref index"
      (fun () ->
        let make_recs n =
          List.init n (fun i ->
              {
                W.name =
                  Printf.sprintf "refs/heads/long-branch-name-prefix/%04d" i;
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              })
        in
        let single_padded =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 512;
                pad_single_block = true;
              }
            (make_recs 2)
        in
        let t1 = parse_ok single_padded in
        Alcotest.(check (option string))
          "padded single"
          (Some ("object " ^ sha1_hex '1'))
          (Option.map show_record
             (Reftable.find t1 "refs/heads/long-branch-name-prefix/0001"));
        let unaligned_multi =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 0;
                max_records_per_block = Some 3;
                write_ref_index = true;
              }
            (make_recs 10)
        in
        let t2 = parse_ok unaligned_multi in
        Alcotest.(check (option string))
          "unaligned multi last"
          (Some ("object " ^ sha1_hex '1'))
          (Option.map show_record
             (Reftable.find t2 "refs/heads/long-branch-name-prefix/0009"));
        let unaligned_no_idx =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 0;
                max_records_per_block = Some 3;
                write_ref_index = false;
              }
            (make_recs 10)
        in
        let t3 = parse_ok unaligned_no_idx in
        Alcotest.(check (option string))
          "unaligned no index"
          (Some ("object " ^ sha1_hex '1'))
          (Option.map show_record
             (Reftable.find t3 "refs/heads/long-branch-name-prefix/0000"));
        let multi_level =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 256;
                restart_interval = 2;
                write_ref_index = true;
              }
            (make_recs 120)
        in
        let t4 = parse_ok multi_level in
        Alcotest.(check (option string))
          "multi-level first"
          (Some ("object " ^ sha1_hex '1'))
          (Option.map show_record
             (Reftable.find t4 "refs/heads/long-branch-name-prefix/0000"));
        Alcotest.(check (option string))
          "multi-level last"
          (Some ("object " ^ sha1_hex '1'))
          (Option.map show_record
             (Reftable.find t4 "refs/heads/long-branch-name-prefix/0119")));
    case "exact block_size fit (zero padding) and non-zero obj_id_len"
      (fun () ->
        let recs =
          [
            {
              W.name = "refs/heads/a";
              update_index_delta = 0L;
              value = W.Object (sha1_raw '1');
            };
            {
              W.name = "refs/heads/b";
              update_index_delta = 0L;
              value = W.Object (sha1_raw '2');
            };
          ]
        in
        let single_unpadded =
          W.encode
            ~config:{ W.default_config with block_size = 0 }
            [ List.hd recs ]
        in
        let b0_len =
          (Char.code single_unpadded.[25] lsl 16)
          lor (Char.code single_unpadded.[26] lsl 8)
          lor Char.code single_unpadded.[27]
        in
        let exact =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = b0_len;
                max_records_per_block = Some 1;
                write_ref_index = false;
              }
            recs
        in
        let t = parse_ok exact in
        Alcotest.(check (option string))
          "b"
          (Some ("object " ^ sha1_hex '2'))
          (Option.map show_record (Reftable.find t "refs/heads/b"));
        let unpadded_aligned =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 0;
                max_records_per_block = Some 1;
                write_ref_index = false;
              }
            recs
          |> W.patch_header_and_footer W.V1 ~block_size:4096
        in
        let tu = parse_ok unpadded_aligned in
        Alcotest.(check (option string))
          "unpadded aligned a"
          (Some ("object " ^ sha1_hex '1'))
          (Option.map show_record (Reftable.find tu "refs/heads/a"));
        Alcotest.(check (option string))
          "unpadded aligned b"
          (Some ("object " ^ sha1_hex '2'))
          (Option.map show_record (Reftable.find tu "refs/heads/b"));
        let with_obj =
          let base =
            W.encode
              ~config:
                {
                  W.default_config with
                  block_size = 4096;
                  log_block = Some "\000\000\008logbytes";
                }
              recs
          in
          let fstart = String.length base - 68 in
          let obj_pos = fstart - 12 in
          let patched =
            set_u64_be base
              (fstart + 24 + 8)
              (Int64.logor (Int64.shift_left (Int64.of_int obj_pos) 5) 4L)
          in
          W.patch_footer_crc W.V1 patched
        in
        ignore (parse_ok with_obj));
    case "negative max_names raises Invalid_argument" (fun () ->
        let empty = W.encode [] in
        match Reftable.parse Id.Sha1 ~max_names:(-1) empty with
        | _ -> Alcotest.fail "no exception"
        | exception Invalid_argument _ -> ());
  ]

let parse_damaged_tests =
  [
    case "Not_a_table on short input, bad magic, bad version, and bad hash_id"
      (fun () ->
        let v1 = W.encode ~config:{ W.default_config with version = W.V1 } [] in
        let v2 =
          W.encode ~config:{ W.default_config with version = W.V2_sha256 } []
        in
        List.iter
          (fun (label, bytes) ->
            Alcotest.(check string) label "not a table" (parse_err bytes))
          [
            ("empty", "");
            ("23 bytes v1 magic", "REFT\001" ^ String.make 18 '\000');
            ("27 bytes v2 magic", "REFT\002" ^ String.make 22 '\000');
            ("91 bytes v1", String.sub v1 0 91);
            ("99 bytes v2", String.sub v2 0 99);
            ("bad magic", flip_byte v1 0);
            ("version 0", set_byte v1 4 0);
            ("version 3", set_byte v1 4 3);
            ("version 255", set_byte v1 4 255);
            ("v2 bad hash_id", set_byte v2 24 (Char.code 'x'));
          ]);
    case "Other_object_format when table hash disagrees with reader format"
      (fun () ->
        let v1 = W.encode ~config:{ W.default_config with version = W.V1 } [] in
        let v2_sha1 =
          W.encode ~config:{ W.default_config with version = W.V2_sha1 } []
        in
        let v2_s256 =
          W.encode ~config:{ W.default_config with version = W.V2_sha256 } []
        in
        Alcotest.(check string)
          "v1 as sha256" "other object format"
          (parse_err ~format:Id.Sha256 v1);
        Alcotest.(check string)
          "v2 sha1 as sha256" "other object format"
          (parse_err ~format:Id.Sha256 v2_sha1);
        Alcotest.(check string)
          "v2 s256 as sha1" "other object format"
          (parse_err ~format:Id.Sha1 v2_s256));
    case "Bad_footer on CRC, header mismatch, and out-of-range positions"
      (fun () ->
        let base =
          W.encode
            [
              {
                W.name = "refs/heads/main";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
            ]
        in
        let fstart = String.length base - 68 in
        Alcotest.(check string)
          "bad crc v1" "bad footer"
          (parse_err (flip_byte base (String.length base - 1)));
        let base_v2 =
          W.encode
            ~config:{ W.default_config with version = W.V2_sha256 }
            [
              {
                W.name = "refs/heads/main";
                update_index_delta = 0L;
                value = W.Object (sha256_raw '1');
              };
            ]
        in
        Alcotest.(check string)
          "bad crc v2" "bad footer"
          (parse_err ~format:Id.Sha256
             (flip_byte base_v2 (String.length base_v2 - 1)));
        Alcotest.(check string)
          "bad footer header copy (crc valid)" "bad footer"
          (parse_err (W.patch_footer_crc W.V1 (flip_byte base (fstart + 10))));
        List.iter
          (fun (label, field_idx, shift, bad_pos) ->
            let raw_val = Int64.shift_left bad_pos shift in
            let patched =
              W.patch_footer_crc W.V1
                (set_u64_be base (fstart + 24 + (field_idx * 8)) raw_val)
            in
            Alcotest.(check string) label "bad footer" (parse_err patched))
          [
            ("ref_index < header", 0, 0, 23L);
            ("ref_index = footer", 0, 0, Int64.of_int fstart);
            ("ref_index 0x40 top byte", 0, 0, 0x4000_0000_0000_0000L);
            ("ref_index 0x3f top byte", 0, 0, 0x3fff_ffff_ffff_ffffL);
            ("ref_index huge", 0, 0, Int64.max_int);
            ("ref_index 0x80 top byte", 0, 0, Int64.min_int);
            ( "ref_index 0x80 top byte with header offset",
              0,
              0,
              Int64.logor Int64.min_int 24L );
            ("obj_pos < header", 1, 5, 23L);
            ("obj_pos = footer", 1, 5, Int64.of_int fstart);
            ("obj_pos 0x80 top byte", 1, 5, 0x0400_0000_0000_0000L);
            ("obj_index < header", 2, 0, 23L);
            ("obj_index = footer", 2, 0, Int64.of_int fstart);
            ("log_pos < header", 3, 0, 23L);
            ("log_pos = footer", 3, 0, Int64.of_int fstart);
            ("log_index < header", 4, 0, 23L);
            ("log_index = footer", 4, 0, Int64.of_int fstart);
          ]);
    case "Bad_block on type, length, padding, restarts, records, and order"
      (fun () ->
        let one =
          W.encode
            [
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
              {
                W.name = "refs/heads/b";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
            ]
        in
        Alcotest.(check string)
          "wrong block type" "bad block 0"
          (parse_err (set_byte one 24 (Char.code 'x')));
        Alcotest.(check string)
          "index block without ref_index_position" "bad block 0"
          (parse_err (set_byte one 24 (Char.code 'i')));
        Alcotest.(check string)
          "block_len > block_size" "bad block 0"
          (parse_err (W.patch_header_and_footer W.V1 ~block_size:32 one));
        Alcotest.(check string)
          "block_len too small" "bad block 0"
          (parse_err (set_u24_be one 25 26));
        Alcotest.(check string)
          "block_len = 1" "bad block 0"
          (parse_err (set_u24_be one 25 1));
        Alcotest.(check string)
          "block_len past footer" "bad block 0"
          (parse_err (set_u24_be one 25 (String.length one)));
        let block_end =
          (Char.code one.[25] lsl 16)
          lor (Char.code one.[26] lsl 8)
          lor Char.code one.[27]
        in
        Alcotest.(check string)
          "restart_count = 0" "bad block 0"
          (parse_err (set_u16_be one (block_end - 2) 0));
        Alcotest.(check string)
          "restart_count too huge" "bad block 0"
          (parse_err (set_u16_be one (block_end - 2) 500));
        Alcotest.(check string)
          "first restart offset != first record" "bad block 0"
          (parse_err (set_u24_be one (block_end - 5) 29));
        let two_restarts =
          W.encode
            ~config:{ W.default_config with restart_interval = 1 }
            [
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
              {
                W.name = "refs/heads/b";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
            ]
        in
        let tr_end =
          (Char.code two_restarts.[25] lsl 16)
          lor (Char.code two_restarts.[26] lsl 8)
          lor Char.code two_restarts.[27]
        in
        Alcotest.(check string)
          "duplicate restart offset" "bad block 0"
          (parse_err (set_u24_be two_restarts (tr_end - 5) 28));
        Alcotest.(check string)
          "restart points to non-zero prefix" "bad block 0"
          (let b = Bytes.of_string two_restarts in
           let second_off =
             (Char.code two_restarts.[tr_end - 5] lsl 16)
             lor (Char.code two_restarts.[tr_end - 4] lsl 8)
             lor Char.code two_restarts.[tr_end - 3]
           in
           Bytes.set b second_off '\001';
           parse_err (Bytes.to_string b));
        List.iter
          (fun vt ->
            let reserved =
              W.encode
                [
                  {
                    W.name = "refs/heads/main";
                    update_index_delta = 0L;
                    value = W.Raw (vt, "");
                  };
                ]
            in
            Alcotest.(check string)
              (Printf.sprintf "reserved value_type %d" vt)
              "bad block 0" (parse_err reserved))
          [ 4; 5; 6; 7 ];
        let unsorted =
          W.encode
            [
              {
                W.name = "refs/heads/z";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
            ]
        in
        Alcotest.(check string)
          "unsorted in block" "bad block 0" (parse_err unsorted);
        let duplicate =
          W.encode
            [
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
            ]
        in
        Alcotest.(check string)
          "duplicate in block" "bad block 0" (parse_err duplicate);
        let unsorted_across =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 256;
                max_records_per_block = Some 1;
                write_ref_index = false;
              }
            [
              {
                W.name = "refs/heads/z";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
            ]
        in
        Alcotest.(check string)
          "unsorted across blocks" "bad block 256"
          (parse_err unsorted_across);
        let non_nul_pad =
          let t =
            W.encode
              ~config:
                {
                  W.default_config with
                  block_size = 256;
                  max_records_per_block = Some 1;
                  write_ref_index = false;
                }
              [
                {
                  W.name = "refs/heads/a";
                  update_index_delta = 0L;
                  value = W.Object (sha1_raw '1');
                };
                {
                  W.name = "refs/heads/b";
                  update_index_delta = 0L;
                  value = W.Object (sha1_raw '2');
                };
              ]
          in
          set_byte t 255 1
        in
        Alcotest.(check bool)
          "non-NUL padding gives Bad_block" true
          (match Reftable.parse Id.Sha1 ~max_names:10_000 non_nul_pad with
          | Error (Reftable.Bad_block _) -> true
          | _ -> false);
        let prefix_overflow = set_byte one 28 5 in
        Alcotest.(check string)
          "first record non-zero prefix" "bad block 0"
          (parse_err prefix_overflow);
        Alcotest.(check string)
          "restart offset not on record boundary" "bad block 0"
          (let second_off =
             (Char.code two_restarts.[tr_end - 5] lsl 16)
             lor (Char.code two_restarts.[tr_end - 4] lsl 8)
             lor Char.code two_restarts.[tr_end - 3]
           in
           parse_err (set_u24_be two_restarts (tr_end - 5) (second_off + 1)));
        Alcotest.(check string)
          "restart offset past records end" "bad block 0"
          (parse_err (set_u24_be two_restarts (tr_end - 5) (tr_end - 6)));
        let truncated_sym =
          W.encode
            [
              {
                W.name = "refs/heads/sym";
                update_index_delta = 0L;
                value = W.Raw (3, W.encode_varint 50L ^ "short");
              };
            ]
        in
        Alcotest.(check string)
          "truncated symbolic target" "bad block 0" (parse_err truncated_sym);
        let truncated_obj =
          W.encode
            [
              {
                W.name = "refs/heads/obj";
                update_index_delta = 0L;
                value = W.Raw (1, "short");
              };
            ]
        in
        Alcotest.(check string)
          "truncated object id" "bad block 0" (parse_err truncated_obj);
        let truncated_peeled =
          W.encode
            [
              {
                W.name = "refs/heads/tag";
                update_index_delta = 0L;
                value = W.Raw (2, sha1_raw '1' ^ "short");
              };
            ]
        in
        Alcotest.(check string)
          "truncated peeled id" "bad block 0"
          (parse_err truncated_peeled);
        let trailing_garbage =
          W.encode
            [
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Raw (0, "\x80");
              };
            ]
        in
        Alcotest.(check string)
          "truncated trailing varint" "bad block 0"
          (parse_err trailing_garbage);
        let overflow_varint =
          W.encode
            [
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Raw (3, String.make 12 '\xff' ^ "\000");
              };
            ]
        in
        Alcotest.(check string)
          "overflowing varint" "bad block 0"
          (parse_err overflow_varint);
        let short_block_before_log =
          let empty = W.encode [] in
          let hdr = String.sub empty 0 24 in
          let ftr = String.sub empty 24 68 in
          let raw = hdr ^ "r\000g" ^ ftr in
          let fstart = String.length raw - 68 in
          W.patch_footer_crc W.V1 (set_u64_be raw (fstart + 24 + 24) 26L)
        in
        Alcotest.(check string)
          "truncated 2-byte block header before bound" "bad block 0"
          (parse_err short_block_before_log);
        let empty_ref_block =
          let empty = W.encode [] in
          let hdr = String.sub empty 0 24 in
          let ftr = String.sub empty 24 68 in
          let body = "r\000\000\033\000\000\028\000\001" in
          W.patch_footer_crc W.V1 (hdr ^ body ^ ftr)
        in
        Alcotest.(check string)
          "empty ref block with 1 restart" "bad block 0"
          (parse_err empty_ref_block);
        let truncated_padding =
          let hdr = String.sub one 0 (String.length one - 68) in
          let ftr = String.sub one (String.length one - 68) 68 in
          W.patch_footer_crc W.V1 (hdr ^ "\000\000\000\000" ^ ftr)
        in
        Alcotest.(check string)
          "truncated NUL padding before footer" "bad block 0"
          (parse_err truncated_padding);
        let non_nul_at_block_end =
          let t =
            W.encode
              ~config:
                {
                  W.default_config with
                  block_size = 256;
                  max_records_per_block = Some 1;
                  write_ref_index = false;
                }
              [
                {
                  W.name = "refs/heads/a";
                  update_index_delta = 0L;
                  value = W.Object (sha1_raw '1');
                };
                {
                  W.name = "refs/heads/b";
                  update_index_delta = 0L;
                  value = W.Object (sha1_raw '2');
                };
              ]
          in
          let b0_end =
            (Char.code t.[25] lsl 16)
            lor (Char.code t.[26] lsl 8)
            lor Char.code t.[27]
          in
          (b0_end, set_byte t b0_end 1)
        in
        Alcotest.(check string)
          "non-NUL byte right at block_end"
          (Printf.sprintf "bad block %d" (fst non_nul_at_block_end))
          (parse_err (snd non_nul_at_block_end));
        let non_restart_prefix_overflow =
          let t =
            W.encode
              ~config:{ W.default_config with restart_interval = 16 }
              [
                {
                  W.name = "refs/heads/a";
                  update_index_delta = 0L;
                  value = W.Deletion;
                };
                {
                  W.name = "refs/heads/b";
                  update_index_delta = 0L;
                  value = W.Deletion;
                };
              ]
          in
          let rec2_off = 28 + 1 + 1 + String.length "refs/heads/a" + 1 in
          (t, rec2_off)
        in
        Alcotest.(check string)
          "non-restart prefix > previous length" "bad block 0"
          (parse_err
             (set_byte
                (fst non_restart_prefix_overflow)
                (snd non_restart_prefix_overflow)
                50));
        Alcotest.(check string)
          "non-restart prefix = previous length + 1" "bad block 0"
          (parse_err
             (set_byte
                (fst non_restart_prefix_overflow)
                (snd non_restart_prefix_overflow)
                (String.length "refs/heads/a" + 1)));
        let missing_update_index =
          let empty = W.encode [] in
          let hdr = String.sub empty 0 24 in
          let ftr = String.sub empty 24 68 in
          let name = "refs/heads/a" in
          let rec_bytes =
            "\000" ^ String.make 1 (Char.chr (String.length name lsl 3)) ^ name
          in
          let len = 24 + 4 + String.length rec_bytes + 3 + 2 in
          let block =
            "r" ^ "\000\000"
            ^ String.make 1 (Char.chr len)
            ^ rec_bytes ^ "\000\000\028\000\001"
          in
          W.patch_footer_crc W.V1 (hdr ^ block ^ ftr)
        in
        Alcotest.(check string)
          "missing update_index_delta at restarts boundary" "bad block 0"
          (parse_err missing_update_index);
        let obj_into_restarts =
          W.encode
            [
              {
                W.name = "refs/heads/obj";
                update_index_delta = 0L;
                value = W.Raw (1, String.make 19 '\001');
              };
            ]
        in
        Alcotest.(check string)
          "object id runs 1 byte into restarts" "bad block 0"
          (parse_err obj_into_restarts);
        let sym_past_eof =
          W.encode
            [
              {
                W.name = "refs/heads/sym";
                update_index_delta = 0L;
                value = W.Raw (3, W.encode_varint 90L ^ "short");
              };
            ]
        in
        Alcotest.(check string)
          "symbolic target past end of table" "bad block 0"
          (parse_err sym_past_eof);
        let prefix_overflow_varint =
          let empty = W.encode [] in
          let hdr = String.sub empty 0 24 in
          let ftr = String.sub empty 24 68 in
          let rec1 =
            "\000"
            ^ String.make 1 (Char.chr (String.length "refs/heads/a" lsl 3))
            ^ "refs/heads/a\000"
          in
          let rec2 =
            W.encode_varint 0x4000_0000_0000_0000L
            ^ String.make 1 (Char.chr (1 lsl 3))
            ^ "b\000"
          in
          let recs_bytes = rec1 ^ rec2 in
          let len = 24 + 4 + String.length recs_bytes + 3 + 2 in
          let block =
            "r" ^ "\000\000"
            ^ String.make 1 (Char.chr len)
            ^ recs_bytes ^ "\000\000\028\000\001"
          in
          W.patch_footer_crc W.V1 (hdr ^ block ^ ftr)
        in
        Alcotest.(check string)
          "non-restart prefix varint 2^62" "bad block 0"
          (parse_err prefix_overflow_varint);
        let only_second_restart =
          let before_restarts = String.sub two_restarts 0 (tr_end - 8) in
          let second_off_bytes = String.sub two_restarts (tr_end - 5) 3 in
          let ftr = String.sub two_restarts tr_end 68 in
          let rebuilt = before_restarts ^ second_off_bytes ^ "\000\001" ^ ftr in
          set_u24_be rebuilt 25 (tr_end - 3)
        in
        Alcotest.(check string)
          "single restart offset naming second record" "bad block 0"
          (parse_err only_second_restart);
        let exact_fit_followed_by_nuls =
          let single =
            W.encode
              ~config:{ W.default_config with block_size = 0 }
              [
                {
                  W.name = "refs/heads/a";
                  update_index_delta = 0L;
                  value = W.Object (sha1_raw '1');
                };
              ]
          in
          let b0_len =
            (Char.code single.[25] lsl 16)
            lor (Char.code single.[26] lsl 8)
            lor Char.code single.[27]
          in
          let raw =
            String.sub single 0 b0_len ^ String.make b0_len '\000'
            ^ String.sub single b0_len 68
          in
          (b0_len, W.patch_header_and_footer W.V1 ~block_size:b0_len raw)
        in
        Alcotest.(check string)
          "NUL block after exact block_size fit"
          (Printf.sprintf "bad block %d" (fst exact_fit_followed_by_nuls))
          (parse_err (snd exact_fit_followed_by_nuls));
        let log_pos_in_padding =
          let padded =
            W.encode
              ~config:
                {
                  W.default_config with
                  block_size = 256;
                  pad_single_block = true;
                }
              [
                {
                  W.name = "refs/heads/a";
                  update_index_delta = 0L;
                  value = W.Object (sha1_raw '1');
                };
              ]
          in
          let b0_end =
            (Char.code padded.[25] lsl 16)
            lor (Char.code padded.[26] lsl 8)
            lor Char.code padded.[27]
          in
          let fstart = String.length padded - 68 in
          W.patch_footer_crc W.V1
            (set_u64_be padded (fstart + 24 + 24) (Int64.of_int (b0_end + 1)))
        in
        Alcotest.(check string)
          "footer log_position inside NUL padding" "bad block 0"
          (parse_err log_pos_in_padding);
        let huge_suffix =
          let t =
            W.encode
              [
                {
                  W.name = "refs/heads/a";
                  update_index_delta = 0L;
                  value = W.Deletion;
                };
              ]
          in
          set_byte t 29 (15 lsl 3)
        in
        Alcotest.(check string)
          "suffix_length past block records end" "bad block 0"
          (parse_err huge_suffix));
    (* @verifies changes#give-ref-commits=v1
       By the promise of `Reftable.parse` in `lib/git_refs/reftable.mli`, when
       the footer gives the position 0 for the log blocks, the ref blocks end at
       a block of the type `g` only when that block comes right after the
       header. A table of two ref blocks with no log block whose second ref
       block has type `g` must give `Bad_block` at the byte offset of that
       second block, not a partial table of refs. *)
    case "later ref block of type g with log position 0 gives Bad_block"
      (fun () ->
        List.iter
          (fun (label, version, format, raw1, raw2) ->
            let two_blocks =
              W.encode
                ~config:
                  {
                    W.default_config with
                    version;
                    block_size = 256;
                    max_records_per_block = Some 1;
                    write_ref_index = false;
                  }
                [
                  {
                    W.name = "refs/heads/a";
                    update_index_delta = 0L;
                    value = W.Object raw1;
                  };
                  {
                    W.name = "refs/heads/b";
                    update_index_delta = 0L;
                    value = W.Object raw2;
                  };
                ]
            in
            ignore (parse_ok ~format two_blocks);
            Alcotest.(check char)
              (label ^ " second block type before edit")
              'r' two_blocks.[256];
            Alcotest.(check string)
              (label ^ " second ref block with type g")
              "bad block 256"
              (parse_err ~format (set_byte two_blocks 256 (Char.code 'g'))))
          [
            ("v1", W.V1, Id.Sha1, sha1_raw '1', sha1_raw '2');
            ("v2 sha1", W.V2_sha1, Id.Sha1, sha1_raw '1', sha1_raw '2');
            ("v2 s256", W.V2_sha256, Id.Sha256, sha256_raw '1', sha256_raw '2');
          ]);
    (* @verifies changes#give-ref-commits=v1
       By the promise of `Reftable.parse` in `lib/git_refs/reftable.mli`, the
       ref blocks end at a block of the type `g` right after the header only
       when the footer gives the position 0 for the log blocks. A table with one
       ref block and a log block whose footer gives a log position above the
       header must give `Bad_block 0` when the first block has type `g`, not an
       empty table of refs. *)
    case "first block of type g with non-zero log position gives Bad_block 0"
      (fun () ->
        List.iter
          (fun (label, version, format, hl, raw1) ->
            let with_log =
              W.encode
                ~config:
                  {
                    W.default_config with
                    version;
                    log_block = Some "\000\000\008logbytes";
                  }
                [
                  {
                    W.name = "refs/heads/a";
                    update_index_delta = 0L;
                    value = W.Object raw1;
                  };
                ]
            in
            ignore (parse_ok ~format with_log);
            Alcotest.(check char)
              (label ^ " first block type before edit")
              'r' with_log.[hl];
            Alcotest.(check string)
              (label ^ " first block with type g and log block")
              "bad block 0"
              (parse_err ~format (set_byte with_log hl (Char.code 'g'))))
          [
            ("v1", W.V1, Id.Sha1, 24, sha1_raw '1');
            ("v2 sha1", W.V2_sha1, Id.Sha1, 28, sha1_raw '1');
            ("v2 s256", W.V2_sha256, Id.Sha256, 28, sha256_raw '1');
          ]);
    case "prefix compression bomb stops at max_names" (fun () ->
        let prefix = "refs/heads/" ^ String.make 900 'a' in
        let recs =
          List.init 200 (fun i ->
              {
                W.name = Printf.sprintf "%s/%04d" prefix i;
                update_index_delta = 0L;
                value = W.Deletion;
              })
        in
        let bytes =
          W.encode
            ~config:
              { W.default_config with block_size = 0; restart_interval = 1000 }
            recs
        in
        Alcotest.(check bool)
          "compressed table is small" true
          (String.length bytes < 5000);
        Alcotest.(check string)
          "bounded by max_names" "names too large"
          (parse_err ~max_names:10_000 bytes));
  ]

let qcheck_tests =
  let ref_name_gen =
    Gen.(
      map2
        (fun dir leaf -> dir ^ leaf)
        (oneof_list
           [
             "refs/heads/";
             "refs/heads/sub/";
             "refs/tags/";
             "refs/remotes/origin/";
           ])
        (string_size
           ~gen:(oneof_list [ 'a'; 'b'; 'c'; '0'; '1'; '-'; '/' ])
           (int_range 1 12)))
  in
  let record_gen format =
    let id_gen =
      let len = Id.length format in
      Gen.string_size ~gen:Gen.char (Gen.return len)
    in
    let value_gen =
      Gen.oneof
        [
          Gen.return W.Deletion;
          Gen.map (fun id -> W.Object id) id_gen;
          Gen.map2 (fun a b -> W.Peeled (a, b)) id_gen id_gen;
          Gen.map (fun s -> W.Symbolic s) ref_name_gen;
        ]
    in
    Gen.map3
      (fun name delta value -> { W.name; update_index_delta = delta; value })
      ref_name_gen
      (Gen.map Int64.of_int (Gen.int_range 0 500))
      value_gen
  in
  [
    property ~count:300
      ~name:"parse round-trips encoded tables across versions and layouts"
      ~print:(fun (v, bs, ri, pad, idx, recs) ->
        Printf.sprintf "v=%d bs=%d ri=%d pad=%b idx=%b n=%d"
          (match v with W.V1 -> 1 | W.V2_sha1 -> 21 | W.V2_sha256 -> 22)
          bs ri pad idx (List.length recs))
      Gen.(
        let* version = oneof_list [ W.V1; W.V2_sha1; W.V2_sha256 ] in
        let format =
          match version with
          | W.V1 | W.V2_sha1 -> Id.Sha1
          | W.V2_sha256 -> Id.Sha256
        in
        let* block_size = oneof_list [ 0; 256; 512; 4096 ] in
        let* restart_interval = oneof_list [ 1; 2; 4; 16 ] in
        let* pad_single_block = bool in
        let* write_ref_index = bool in
        let* raw_recs = list_size (int_range 0 40) (record_gen format) in
        let sorted =
          List.sort (fun a b -> String.compare a.W.name b.W.name) raw_recs
          |> List.fold_left
               (fun acc r ->
                 match acc with
                 | h :: _ when h.W.name = r.W.name -> acc
                 | _ -> r :: acc)
               []
          |> List.rev
        in
        return
          ( version,
            block_size,
            restart_interval,
            pad_single_block,
            write_ref_index,
            sorted ))
      (fun ( version,
             block_size,
             restart_interval,
             pad_single_block,
             write_ref_index,
             recs )
         ->
        let format =
          match version with
          | W.V1 | W.V2_sha1 -> Id.Sha1
          | W.V2_sha256 -> Id.Sha256
        in
        let max_records_per_block = if block_size = 0 then Some 5 else None in
        let bytes =
          W.encode
            ~config:
              {
                W.default_config with
                version;
                block_size;
                max_update_index = 1000L;
                restart_interval;
                max_records_per_block;
                pad_single_block;
                write_ref_index;
              }
            recs
        in
        match Reftable.parse format ~max_names:(1 lsl 20) bytes with
        | Error _ -> false
        | Ok table ->
            let expected_size =
              List.fold_left (fun acc r -> acc + String.length r.W.name) 0 recs
            in
            Reftable.names_size table = expected_size
            && List.for_all
                 (fun r ->
                   match (r.W.value, Reftable.find table r.W.name) with
                   | W.Deletion, Some Reftable.Deletion -> true
                   | W.Object raw, Some (Reftable.Object id) ->
                       Id.to_bytes id = raw
                   | W.Peeled (raw, _), Some (Reftable.Object id) ->
                       Id.to_bytes id = raw
                   | W.Symbolic s, Some (Reftable.Symbolic s') -> s = s'
                   | _ -> false)
                 recs
            && Reftable.find table "refs/heads/zz-absent" = None);
    property ~count:2000
      ~name:"parse never raises on arbitrary or mutated bytes"
      ~print:(fun (fmt, s) ->
        Printf.sprintf "fmt=%s len=%d"
          (if fmt = Id.Sha1 then "sha1" else "sha256")
          (String.length s))
      Gen.(
        let* format = oneof_list [ Id.Sha1; Id.Sha256 ] in
        let version = if format = Id.Sha1 then W.V1 else W.V2_sha256 in
        let base_table =
          W.encode
            ~config:{ W.default_config with version; block_size = 256 }
            [
              {
                W.name = "HEAD";
                update_index_delta = 0L;
                value = W.Symbolic "refs/heads/main";
              };
              {
                W.name = "refs/heads/main";
                update_index_delta = 0L;
                value =
                  W.Object
                    (if format = Id.Sha1 then sha1_raw 'a' else sha256_raw 'a');
              };
            ]
        in
        let* bytes =
          oneof
            [
              string_size ~gen:char (int_range 0 300);
              map
                (fun tail -> "REFT\001" ^ tail)
                (string_size ~gen:char (int_range 0 200));
              map
                (fun tail -> "REFT\002\000\001\000" ^ tail)
                (string_size ~gen:char (int_range 0 200));
              (let* mutations =
                 list_size (int_range 1 5)
                   (pair (int_range 0 (String.length base_table - 1)) char)
               in
               let* cut = int_range 0 (String.length base_table) in
               let* fix_crc = bool in
               let buf = Bytes.of_string base_table in
               List.iter (fun (i, c) -> Bytes.set buf i c) mutations;
               let s = Bytes.sub_string buf 0 cut in
               let fl = if version = W.V1 then 68 else 72 in
               let s =
                 if fix_crc && String.length s >= fl then
                   W.patch_footer_crc version s
                 else s
               in
               return s);
            ]
        in
        return (format, bytes))
      (fun (format, bytes) ->
        match Reftable.parse format ~max_names:10_000 bytes with
        | Ok _ | Error _ -> true);
    property ~count:200
      ~name:"multi-table stack lookup matches newest-table-wins model"
      ~print:(fun layers -> Printf.sprintf "%d layers" (List.length layers))
      Gen.(
        let names =
          [| "HEAD"; "refs/heads/a"; "refs/heads/b"; "refs/tags/t" |]
        in
        let vals =
          [|
            W.Deletion;
            W.Object (sha1_raw '1');
            W.Object (sha1_raw '2');
            W.Peeled (sha1_raw '3', sha1_raw '1');
            W.Symbolic "refs/heads/a";
            W.Symbolic "bad target";
          |]
        in
        let layer =
          list_size (int_range 0 4)
            (pair
               (int_range 0 (Array.length names - 1))
               (int_range 0 (Array.length vals - 1)))
          |> map (fun pairs ->
              let tbl = Hashtbl.create 4 in
              List.iter
                (fun (ni, vi) -> Hashtbl.replace tbl names.(ni) vals.(vi))
                pairs;
              Hashtbl.fold (fun k v acc -> (k, v) :: acc) tbl []
              |> List.sort (fun (a, _) (b, _) -> String.compare a b))
        in
        list_size (int_range 0 4) layer)
      (fun layers ->
        let nodes = ref [] in
        let tnames = ref [] in
        List.iteri
          (fun i entries ->
            let tname = Printf.sprintf "t%d.ref" i in
            let recs =
              List.map
                (fun (name, value) ->
                  { W.name; update_index_delta = 0L; value })
                entries
            in
            let bytes =
              W.encode
                ~config:
                  {
                    W.default_config with
                    min_update_index = Int64.of_int (i + 1);
                    max_update_index = Int64.of_int (i + 1);
                  }
                recs
            in
            nodes := ("/g/reftable/" ^ tname, Fake.File bytes) :: !nodes;
            tnames := tname :: !tnames)
          layers;
        let list_content =
          String.concat "" (List.map (fun n -> n ^ "\n") (List.rev !tnames))
        in
        Fake.reset
          (("/g/reftable/tables.list", Fake.File list_content) :: !nodes);
        let refs =
          Fake_refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:"/g"
            Refs.Main
        in
        let model = Hashtbl.create 8 in
        List.iter
          (fun entries ->
            List.iter
              (fun (name, value) ->
                match value with
                | W.Deletion -> Hashtbl.remove model name
                | W.Object raw | W.Peeled (raw, _) ->
                    Hashtbl.replace model name
                      (Loose_ref.Object (Option.get (Id.of_bytes Id.Sha1 raw)))
                | W.Symbolic s ->
                    Hashtbl.replace model name
                      (if Ref_name.is_ref_name s then Loose_ref.Symbolic s
                       else Loose_ref.Broken)
                | W.Raw _ -> ())
              entries)
          layers;
        List.for_all
          (fun name ->
            Fake_refs.lookup refs name = Ok (Hashtbl.find_opt model name))
          [
            "HEAD";
            "refs/heads/a";
            "refs/heads/b";
            "refs/tags/t";
            "refs/heads/none";
          ]);
  ]

let make_basic_repo ?(extra = []) () =
  let r = init_reftable ~extra () in
  git_commit r "one";
  git_commit r "two";
  ignore (git_ok r [ "branch"; "topic"; "HEAD~1" ]);
  ignore (git_ok r [ "tag"; "light"; "HEAD~1" ]);
  ignore (git_ok r [ "tag"; "-a"; "-m"; "annotated"; "v1"; "HEAD" ]);
  ignore (git_ok r [ "symbolic-ref"; "refs/heads/alias"; "refs/heads/main" ]);
  ignore (git_ok r [ "branch"; "gone" ]);
  ignore (git_ok r [ "branch"; "-D"; "-q"; "gone" ]);
  r

let compare_repo_with_git ?(format = Id.Sha1) ?(working_tree = Refs.Main)
    ~git_folder repo =
  let before = dir_state git_folder in
  let refs =
    Refs.create default_limits Refs.Reftable format ~git_folder working_tree
  in
  let names =
    git_lines repo
      [ "for-each-ref"; "--include-root-refs"; "--format=%(refname)" ]
  in
  List.iter
    (fun name ->
      if Ref_name.is_ref_name name then
        Alcotest.(check string)
          name
          (git_expected_target repo name)
          (show_lookup (Refs.lookup refs name)))
    names;
  Alcotest.(check (list string))
    "git folder unchanged" before (dir_state git_folder);
  refs

(* @verifies changes#{give-ref-commits=v1, give-head-commits=v1,
   give-default-branch-commits=v1, leave-repositories-unchanged=v1}
   On real reftable repositories that git 2.54.0 writes (versions 1 and 2,
   SHA-1 and SHA-256, unborn HEAD, bare, many refs with single-level and
   two-level ref indexes, multi-table stacks with deletions and updates,
   compacted stacks, linked working trees, root refs, and annotated tags),
   every lookup, head commit, ref commit, and default-branch commit agrees
   with git, and no file under the git folder changes during the reads. *)
let real_git_tests =
  [
    case "basic SHA-1 (v1) and SHA-256 (v2) repositories agree with git"
      (fun () ->
        let check extra format =
          let r = make_basic_repo ~extra () in
          let git_folder = r.dir / ".git" in
          let refs = compare_repo_with_git ~format ~git_folder r in
          Alcotest.(check string)
            "deleted branch" "none"
            (show_lookup (Refs.lookup refs "refs/heads/gone"));
          Alcotest.(check string)
            "HEAD" "symbolic \"refs/heads/main\""
            (show_lookup (Refs.lookup refs "HEAD"));
          let main_hex =
            String.trim (git_ok r [ "rev-parse"; "refs/heads/main" ])
          in
          let topic_hex =
            String.trim (git_ok r [ "rev-parse"; "refs/heads/topic" ])
          in
          let is_commit id =
            let h = Id.to_hex id in
            Ok (h = main_hex || h = topic_hex)
          in
          let rfn = Refs.refs refs ~is_commit in
          Alcotest.(check (option string))
            "HEAD commit" (Some main_hex)
            (match Ref_commit.commit rfn "HEAD" with
            | Ok o -> Option.map Id.to_hex o
            | Error _ -> Alcotest.fail "error");
          Alcotest.(check (option string))
            "alias commit" (Some main_hex)
            (match Ref_commit.commit rfn "refs/heads/alias" with
            | Ok o -> Option.map Id.to_hex o
            | Error _ -> Alcotest.fail "error");
          Alcotest.(check (option string))
            "annotated tag has no commit" None
            (match Ref_commit.commit rfn "refs/tags/v1" with
            | Ok o -> Option.map Id.to_hex o
            | Error _ -> Alcotest.fail "error");
          Alcotest.(check (option string))
            "default branch commit" (Some main_hex)
            (let binding =
               Result.get_ok
                 (Sinter_branch_names.Branch_name.of_text
                    (Result.get_ok (Text.decode "main")))
             in
             match
               Default_branch.commit
                 ~upstream:(fun _ -> Ok None)
                 ~refs:rfn binding
             with
             | Ok o -> Option.map Id.to_hex o
             | Error _ -> Alcotest.fail "error")
        in
        check [] Id.Sha1;
        check [ "--object-format=sha256" ] Id.Sha256);
    case "empty and bare repositories hold unborn HEAD" (fun () ->
        let empty = init_reftable () in
        let bare = init_reftable ~extra:[ "--bare" ] () in
        List.iter
          (fun (label, git_folder) ->
            let refs =
              Refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder
                Refs.Main
            in
            Alcotest.(check string)
              (label ^ " HEAD") "symbolic \"refs/heads/main\""
              (show_lookup (Refs.lookup refs "HEAD"));
            let rfn = Refs.refs refs ~is_commit:(fun _ -> Ok true) in
            Alcotest.(check (option string))
              (label ^ " head commit") None
              (match Ref_commit.commit rfn "HEAD" with
              | Ok o -> Option.map Id.to_hex o
              | Error _ -> Alcotest.fail "error"))
          [ ("empty", empty.dir / ".git"); ("bare", bare.dir) ]);
    case "many refs (single-level index) and tiny blocks (two-level index)"
      (fun () ->
        let many = init_reftable () in
        ignore (git_ok many [ "config"; "reftable.blockSize"; "1024" ]);
        git_commit many "one";
        git_commit many "two";
        let one = String.trim (git_ok many [ "rev-parse"; "HEAD~1" ]) in
        let two = String.trim (git_ok many [ "rev-parse"; "HEAD" ]) in
        let buf = Buffer.create 40_000 in
        for i = 0 to 499 do
          let id = if i mod 2 = 0 then one else two in
          Buffer.add_string buf
            (Printf.sprintf "create refs/heads/b/%05d %s\n" i id)
        done;
        ignore
          (git_ok many ~input:(Buffer.contents buf) [ "update-ref"; "--stdin" ]);
        ignore (git_ok many [ "pack-refs" ]);
        ignore (compare_repo_with_git ~git_folder:(many.dir / ".git") many);
        let tiny = init_reftable () in
        ignore (git_ok tiny [ "config"; "reftable.blockSize"; "256" ]);
        git_commit tiny "one";
        let id = String.trim (git_ok tiny [ "rev-parse"; "HEAD" ]) in
        let tbuf = Buffer.create 60_000 in
        for i = 0 to 599 do
          Buffer.add_string tbuf
            (Printf.sprintf
               "create refs/heads/a-rather-long-name-to-fill-blocks/%05d %s\n" i
               id)
        done;
        ignore
          (git_ok tiny ~input:(Buffer.contents tbuf)
             [ "update-ref"; "--stdin" ]);
        ignore (git_ok tiny [ "pack-refs" ]);
        ignore (compare_repo_with_git ~git_folder:(tiny.dir / ".git") tiny));
    case
      "multi-table stack with deletion and override agrees before and after \
       pack-refs" (fun () ->
        let r = init_reftable () in
        ignore (git_ok r [ "config"; "reftable.geometricFactor"; "1" ]);
        git_commit r "one";
        let id = String.trim (git_ok r [ "rev-parse"; "HEAD" ]) in
        let two =
          String.trim
            (git_ok r [ "commit-tree"; "-p"; id; "-m"; "two"; id ^ "^{tree}" ])
        in
        List.iter
          (fun n ->
            let buf = Buffer.create (n * 64) in
            for i = 0 to n - 1 do
              Buffer.add_string buf
                (Printf.sprintf "create refs/heads/s%d/%04d %s\n" n i id)
            done;
            ignore
              (git_ok r ~input:(Buffer.contents buf)
                 [ "update-ref"; "--stdin" ]))
          [ 200; 80; 30; 10; 4 ];
        ignore
          (git_ok r
             ~input:
               (Printf.sprintf
                  "delete refs/heads/s200/0007\n\
                   update refs/heads/s200/0008 %s\n"
                  two)
             [ "update-ref"; "--stdin" ]);
        let tables_count =
          read_file (r.dir / ".git/reftable/tables.list")
          |> String.split_on_char '\n'
          |> List.filter (fun s -> s <> "")
          |> List.length
        in
        Alcotest.(check bool) "multiple tables in stack" true (tables_count >= 2);
        let refs = compare_repo_with_git ~git_folder:(r.dir / ".git") r in
        Alcotest.(check string)
          "deleted ref" "none"
          (show_lookup (Refs.lookup refs "refs/heads/s200/0007"));
        Alcotest.(check string)
          "updated ref" ("object " ^ two)
          (show_lookup (Refs.lookup refs "refs/heads/s200/0008"));
        ignore (git_ok r [ "pack-refs" ]);
        let packed = compare_repo_with_git ~git_folder:(r.dir / ".git") r in
        Alcotest.(check string)
          "deleted ref after pack-refs" "none"
          (show_lookup (Refs.lookup packed "refs/heads/s200/0007"));
        Alcotest.(check string)
          "updated ref after pack-refs" ("object " ^ two)
          (show_lookup (Refs.lookup packed "refs/heads/s200/0008")));
    case "linked working trees isolate own refs and share common refs"
      (fun () ->
        let r = init_reftable () in
        git_commit r "one";
        git_commit r "two";
        let wt_a_dir = Git_fixture.temp_dir () / "wt-a" in
        let wt_b_dir = Git_fixture.temp_dir () / "wt-b" in
        ignore
          (git_ok r
             [ "worktree"; "add"; "-q"; wt_a_dir; "-b"; "side"; "HEAD~1" ]);
        ignore
          (git_ok r [ "worktree"; "add"; "-q"; "--detach"; wt_b_dir; "HEAD" ]);
        let wt_a = { dir = wt_a_dir; env = r.env } in
        let wt_b = { dir = wt_b_dir; env = r.env } in
        ignore (git_ok wt_a [ "update-ref"; "refs/worktree/mine"; "HEAD" ]);
        ignore (git_ok wt_b [ "update-ref"; "refs/bisect/bad"; "HEAD" ]);
        ignore (git_ok wt_b [ "update-ref"; "refs/rewritten/step"; "HEAD" ]);
        ignore (git_ok r [ "update-ref"; "refs/worktree/main-only"; "HEAD" ]);
        let git_folder = r.dir / ".git" in
        ignore (compare_repo_with_git ~git_folder r);
        let refs_a =
          compare_repo_with_git ~git_folder
            ~working_tree:(Refs.Linked (git_folder / "worktrees/wt-a"))
            wt_a
        in
        let refs_b =
          compare_repo_with_git ~git_folder
            ~working_tree:(Refs.Linked (git_folder / "worktrees/wt-b"))
            wt_b
        in
        Alcotest.(check string)
          "wt-a HEAD" "symbolic \"refs/heads/side\""
          (show_lookup (Refs.lookup refs_a "HEAD"));
        Alcotest.(check string)
          "wt-a does not see main worktree ref" "none"
          (show_lookup (Refs.lookup refs_a "refs/worktree/main-only"));
        Alcotest.(check string)
          "wt-a does not see wt-b bisect ref" "none"
          (show_lookup (Refs.lookup refs_a "refs/bisect/bad"));
        Alcotest.(check string)
          "wt-b sees shared branch side"
          (git_expected_target wt_b "refs/heads/side")
          (show_lookup (Refs.lookup refs_b "refs/heads/side"));
        Alcotest.(check string)
          "wt-b sees its rewritten ref"
          (git_expected_target wt_b "refs/rewritten/step")
          (show_lookup (Refs.lookup refs_b "refs/rewritten/step")));
    case
      "root refs in stack match git while FETCH_HEAD and MERGE_HEAD are not \
       read" (fun () ->
        let r = init_reftable () in
        write_file (r.dir / "f") "base\n";
        ignore (git_ok r [ "add"; "f" ]);
        git_commit r "base";
        ignore (git_ok r [ "switch"; "-q"; "-c"; "other" ]);
        write_file (r.dir / "f") "other\n";
        ignore (git_ok r [ "commit"; "-q"; "-am"; "other" ]);
        ignore (git_ok r [ "switch"; "-q"; "main" ]);
        write_file (r.dir / "f") "main\n";
        ignore (git_ok r [ "commit"; "-q"; "-am"; "main" ]);
        git_commit r "extra";
        ignore (git_ok r [ "reset"; "-q"; "--hard"; "HEAD~1" ]);
        ignore (git_ok r [ "fetch"; "-q"; r.dir; "other" ]);
        ignore (git_status r [ "merge"; "-q"; "other" ]);
        let refs = compare_repo_with_git ~git_folder:(r.dir / ".git") r in
        Alcotest.(check string)
          "ORIG_HEAD"
          (git_expected_target r "ORIG_HEAD")
          (show_lookup (Refs.lookup refs "ORIG_HEAD"));
        Alcotest.(check string)
          "AUTO_MERGE"
          (git_expected_target r "AUTO_MERGE")
          (show_lookup (Refs.lookup refs "AUTO_MERGE"));
        Alcotest.(check string)
          "FETCH_HEAD not read from file" "none"
          (show_lookup (Refs.lookup refs "FETCH_HEAD"));
        Alcotest.(check string)
          "MERGE_HEAD not read from file" "none"
          (show_lookup (Refs.lookup refs "MERGE_HEAD"));
        ignore (git_ok r [ "merge"; "--abort" ]);
        ignore (git_status r [ "cherry-pick"; "other" ]);
        let refs_pick = compare_repo_with_git ~git_folder:(r.dir / ".git") r in
        Alcotest.(check string)
          "CHERRY_PICK_HEAD"
          (git_expected_target r "CHERRY_PICK_HEAD")
          (show_lookup (Refs.lookup refs_pick "CHERRY_PICK_HEAD"));
        ignore (git_ok r [ "cherry-pick"; "--abort" ]);
        ignore (git_status r [ "bisect"; "start"; "HEAD"; "HEAD~2" ]);
        ignore (compare_repo_with_git ~git_folder:(r.dir / ".git") r));
    case "annotated tags return tag object id, not peeled id" (fun () ->
        let r = init_reftable () in
        write_file (r.dir / "f") "x\n";
        ignore (git_ok r [ "add"; "f" ]);
        git_commit r "one";
        ignore (git_ok r [ "tag"; "-a"; "-m"; "a1"; "t-commit"; "HEAD" ]);
        ignore (git_ok r [ "tag"; "-a"; "-m"; "a2"; "t-tag"; "t-commit" ]);
        ignore (git_ok r [ "tag"; "-a"; "-m"; "a3"; "t-tag2"; "t-tag" ]);
        ignore (git_ok r [ "tag"; "-a"; "-m"; "a4"; "t-tree"; "HEAD^{tree}" ]);
        ignore (git_ok r [ "tag"; "-a"; "-m"; "a5"; "t-blob"; "HEAD:f" ]);
        ignore (git_ok r [ "tag"; "light-of-tag"; "t-commit" ]);
        let refs = compare_repo_with_git ~git_folder:(r.dir / ".git") r in
        let commit_hex = String.trim (git_ok r [ "rev-parse"; "HEAD" ]) in
        let rfn =
          Refs.refs refs ~is_commit:(fun id -> Ok (Id.to_hex id = commit_hex))
        in
        List.iter
          (fun tag ->
            let refname = "refs/tags/" ^ tag in
            let tag_obj =
              String.trim (git_ok r [ "rev-parse"; "--verify"; refname ])
            in
            Alcotest.(check string)
              refname ("object " ^ tag_obj)
              (show_lookup (Refs.lookup refs refname));
            Alcotest.(check (option string))
              (refname ^ " has no commit")
              None
              (match Ref_commit.commit rfn refname with
              | Ok o -> Option.map Id.to_hex o
              | Error _ -> Alcotest.fail "error"))
          [ "t-commit"; "t-tag"; "t-tag2"; "t-tree"; "t-blob"; "light-of-tag" ]);
  ]

let damaged_input_tests =
  [
    case "all 22 damaged-input cases of the fact sheet" (fun () ->
        let src = make_basic_repo () in
        let fresh_copy () =
          let dst = Git_fixture.temp_dir () / "dmg" in
          copy_tree src.dir dst;
          dst / ".git"
        in
        let table_names_of gf =
          read_file (gf / "reftable/tables.list")
          |> String.split_on_char '\n'
          |> List.filter (fun s -> s <> "")
        in
        let check_main gf =
          let refs =
            Refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:gf
              Refs.Main
          in
          Refs.lookup refs "refs/heads/main"
        in
        let check_is_malformed_table label res =
          Alcotest.(check bool)
            label true
            (match res with
            | Error (Refs.Malformed_table _) -> true
            | _ -> false)
        in
        let gf0 = fresh_copy () in
        let ts0 = table_names_of gf0 in
        Alcotest.(check bool) "3 tables in basic" true (List.length ts0 >= 2);
        let main_ok =
          match check_main gf0 with
          | Ok (Some (Loose_ref.Object id)) -> Id.to_hex id
          | _ -> Alcotest.fail "control failed"
        in
        let gf1 = fresh_copy () in
        let t1 = gf1 / "reftable" / List.hd (table_names_of gf1) in
        let d1 = read_file t1 in
        write_file t1 (String.sub d1 0 (String.length d1 - 10));
        check_is_malformed_table "truncated by 10 bytes" (check_main gf1);
        let gf2 = fresh_copy () in
        let t2 = gf2 / "reftable" / List.hd (table_names_of gf2) in
        let d2 = read_file t2 in
        write_file t2 (String.sub d2 0 (String.length d2 lsr 1));
        check_is_malformed_table "truncated to half" (check_main gf2);
        let gf3 = fresh_copy () in
        let t3 = gf3 / "reftable" / List.hd (List.rev (table_names_of gf3)) in
        write_file t3 "";
        Alcotest.(check bool)
          "newest truncated to 0" true
          (match check_main gf3 with
          | Error (Refs.Malformed_table { error = Reftable.Not_a_table; _ }) ->
              true
          | _ -> false);
        let gf4 = fresh_copy () in
        let mid = List.nth (table_names_of gf4) 1 in
        Unix.unlink (gf4 / "reftable" / mid);
        Alcotest.(check bool)
          "missing named table" true
          (match check_main gf4 with
          | Error (Refs.Unread { failure = Files.No_file; _ }) -> true
          | _ -> false);
        let gf5 = fresh_copy () in
        let t5 = gf5 / "reftable" / List.hd (table_names_of gf5) in
        let d5 = read_file t5 in
        write_file t5 (flip_byte d5 (String.length d5 - 1));
        Alcotest.(check bool)
          "changed CRC" true
          (match check_main gf5 with
          | Error (Refs.Malformed_table { error = Reftable.Bad_footer; _ }) ->
              true
          | _ -> false);
        let gf6 = fresh_copy () in
        let t6 = gf6 / "reftable" / List.hd (table_names_of gf6) in
        let d6 = read_file t6 in
        write_file t6 (flip_byte d6 (String.length d6 - 30));
        Alcotest.(check bool)
          "changed footer fields" true
          (match check_main gf6 with
          | Error (Refs.Malformed_table { error = Reftable.Bad_footer; _ }) ->
              true
          | _ -> false);
        let gf7 = fresh_copy () in
        let t7 = gf7 / "reftable" / List.hd (table_names_of gf7) in
        let d7 = read_file t7 in
        let raw_main = raw_id_of_hex main_ok in
        let rec find_sub i =
          if i + String.length raw_main > String.length d7 then
            Alcotest.fail "id not found"
          else if String.sub d7 i (String.length raw_main) = raw_main then i
          else find_sub (i + 1)
        in
        let pos = find_sub 28 in
        write_file t7 (flip_byte d7 pos);
        Alcotest.(check bool)
          "changed object id byte is read with no block checksum" true
          (match check_main gf7 with
          | Ok (Some (Loose_ref.Object id)) -> Id.to_hex id <> main_ok
          | _ -> false);
        let gf8 = fresh_copy () in
        let t8 = gf8 / "reftable" / List.hd (table_names_of gf8) in
        write_file t8 (flip_byte (read_file t8) 0);
        Alcotest.(check bool)
          "changed magic" true
          (match check_main gf8 with
          | Error (Refs.Malformed_table { error = Reftable.Not_a_table; _ }) ->
              true
          | _ -> false);
        let gf9 = fresh_copy () in
        let t9 = gf9 / "reftable" / List.hd (table_names_of gf9) in
        write_file t9 (set_byte (read_file t9) 4 3);
        Alcotest.(check bool)
          "version set to 3" true
          (match check_main gf9 with
          | Error (Refs.Malformed_table { error = Reftable.Not_a_table; _ }) ->
              true
          | _ -> false);
        let gf10 = fresh_copy () in
        let ts10 = table_names_of gf10 in
        (match ts10 with
        | a :: b :: rest ->
            write_file
              (gf10 / "reftable/tables.list")
              (String.concat "" (List.map (fun s -> s ^ "\n") (b :: a :: rest)));
            Alcotest.(check string)
              "swapped first two tables" ("object " ^ main_ok)
              (show_lookup (check_main gf10))
        | _ -> Alcotest.fail "need at least 2 tables");
        let gf11 = fresh_copy () in
        (match List.rev (table_names_of gf11) with
        | last :: prev :: rev_rest ->
            let swapped = List.rev (prev :: last :: rev_rest) in
            write_file
              (gf11 / "reftable/tables.list")
              (String.concat "" (List.map (fun s -> s ^ "\n") swapped));
            let refs =
              Refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:gf11
                Refs.Main
            in
            Alcotest.(check string)
              "deletion before creation revives gone" ("object " ^ main_ok)
              (show_lookup (Refs.lookup refs "refs/heads/gone"))
        | _ -> Alcotest.fail "need at least 2 tables");
        let gf12 = fresh_copy () in
        let t12 =
          gf12 / "reftable" / List.hd (List.rev (table_names_of gf12))
        in
        write_file t12
          (W.patch_header_and_footer W.V1 ~min_update_index:1L (read_file t12));
        Alcotest.(check string)
          "overlapping min_update_index with valid CRC succeeds"
          ("object " ^ main_ok)
          (show_lookup (check_main gf12));
        let gf13 = fresh_copy () in
        write_file (gf13 / "reftable/tables.list") "";
        Alcotest.(check string)
          "empty tables.list gives none" "none"
          (show_lookup (check_main gf13));
        let gf14 = fresh_copy () in
        Unix.unlink (gf14 / "reftable/tables.list");
        Alcotest.(check bool)
          "missing tables.list" true
          (match check_main gf14 with
          | Error (Refs.Unread { failure = Files.No_file; _ }) -> true
          | _ -> false);
        let gf15 = fresh_copy () in
        let tl15 = read_file (gf15 / "reftable/tables.list") in
        write_file
          (gf15 / "reftable/tables.list")
          (String.sub tl15 0 (String.length tl15 - 1));
        Alcotest.(check bool)
          "tables.list without final LF" true
          (match check_main gf15 with
          | Error
              (Refs.Malformed_tables_list
                 { error = Reftable.No_final_line_feed; _ }) ->
              true
          | _ -> false);
        let gf16 = fresh_copy () in
        let tl16 = read_file (gf16 / "reftable/tables.list") in
        write_file (gf16 / "reftable/tables.list") ("\n" ^ tl16);
        Alcotest.(check bool)
          "tables.list with empty line" true
          (match check_main gf16 with
          | Error
              (Refs.Malformed_tables_list
                 { error = Reftable.Bad_table_name ""; _ }) ->
              true
          | _ -> false);
        let gf17 = fresh_copy () in
        let ts17 = table_names_of gf17 in
        let last17 = List.hd (List.rev ts17) in
        write_file
          (gf17 / "reftable/tables.list")
          (String.concat "" (List.map (fun s -> s ^ "\n") (ts17 @ [ last17 ])));
        Alcotest.(check bool)
          "tables.list with duplicate name" true
          (match check_main gf17 with
          | Error
              (Refs.Malformed_tables_list
                 { error = Reftable.Repeated_table_name n; _ }) ->
              n = last17
          | _ -> false);
        let gf18 = fresh_copy () in
        let outside = Filename.dirname gf18 / "outside.ref" in
        let ts18 = table_names_of gf18 in
        write_file outside (read_file (gf18 / "reftable" / List.hd ts18));
        write_file
          (gf18 / "reftable/tables.list")
          (String.concat ""
             (List.map
                (fun s -> s ^ "\n")
                ("../../outside.ref" :: List.tl ts18)));
        Alcotest.(check bool)
          "tables.list path traversal rejected" true
          (match check_main gf18 with
          | Error
              (Refs.Malformed_tables_list
                 { error = Reftable.Bad_table_name "../../outside.ref"; _ }) ->
              true
          | _ -> false);
        let gf19 = fresh_copy () in
        let ts19 = table_names_of gf19 in
        Unix.rename
          (gf19 / "reftable" / List.hd ts19)
          (gf19 / "reftable/not-a-table-name.ref");
        write_file
          (gf19 / "reftable/tables.list")
          (String.concat ""
             (List.map
                (fun s -> s ^ "\n")
                ("not-a-table-name.ref" :: List.tl ts19)));
        Alcotest.(check string)
          "non-git plain table name accepted" ("object " ^ main_ok)
          (show_lookup (check_main gf19));
        let gf20 = fresh_copy () in
        write_file
          (gf20 / "reftable/0x000000000099-0x000000000099-deadbeef.ref")
          "not even a reftable";
        Alcotest.(check string)
          "unlisted table is ignored" ("object " ^ main_ok)
          (show_lookup (check_main gf20));
        let gf21 = Git_fixture.temp_dir () / ".git" in
        let multi_table =
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 256;
                max_records_per_block = Some 1;
                write_ref_index = false;
              }
            [
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
              {
                W.name = "refs/heads/b";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
            ]
        in
        write_file (gf21 / "reftable/tables.list") "t1.ref\n";
        write_file (gf21 / "reftable/t1.ref")
          (set_byte multi_table 256 (Char.code 'x'));
        let refs21 =
          Refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:gf21
            Refs.Main
        in
        Alcotest.(check bool)
          "corrupted second ref block type fails whole read" true
          (match Refs.lookup refs21 "refs/heads/a" with
          | Error (Refs.Malformed_table { error = Reftable.Bad_block 256; _ })
            ->
              true
          | _ -> false));
  ]

let set = Vectors.read "changes"

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let required name json =
  match member name json with
  | Some v -> v
  | None -> Alcotest.failf "no member %s" name

let commit_values commits = function
  | Ok (Some id) -> (
      match List.assoc_opt (Id.to_hex id) commits with
      | Some name -> `Assoc [ ("values", `Assoc [ ("commit", `String name) ]) ]
      | None -> `String "an unknown commit")
  | Ok None -> `Assoc [ ("values", `Assoc []) ]
  | Error _ -> `String "an error"

let make_reftable_git_folder ~version ~multi records =
  let root = Git_fixture.temp_dir () / ".git" in
  let sorted =
    List.sort (fun a b -> String.compare a.W.name b.W.name) records
  in
  let tables =
    if multi && sorted <> [] then
      let older =
        List.map
          (fun r -> { r with W.value = W.Symbolic "refs/heads/stale-older" })
          sorted
      in
      let deleted_extra =
        {
          W.name = "refs/zz-deleted-in-newer";
          update_index_delta = 0L;
          value = W.Symbolic "refs/heads/stale-older";
        }
      in
      let sort_recs rs =
        List.sort (fun a b -> String.compare a.W.name b.W.name) rs
      in
      let t1 =
        W.encode
          ~config:
            {
              W.default_config with
              version;
              min_update_index = 1L;
              max_update_index = 1L;
            }
          (sort_recs (older @ [ deleted_extra ]))
      in
      let t2 =
        W.encode
          ~config:
            {
              W.default_config with
              version;
              min_update_index = 2L;
              max_update_index = 2L;
            }
          (sort_recs
             (sorted
             @ [
                 {
                   W.name = "refs/zz-deleted-in-newer";
                   update_index_delta = 0L;
                   value = W.Deletion;
                 };
               ]))
      in
      [ ("t1.ref", t1); ("t2.ref", t2) ]
    else
      [ ("t1.ref", W.encode ~config:{ W.default_config with version } sorted) ]
  in
  let list_content =
    String.concat "" (List.map (fun (n, _) -> n ^ "\n") tables)
  in
  write_file (root / "reftable/tables.list") list_content;
  List.iter (fun (n, bytes) -> write_file (root / "reftable" / n) bytes) tables;
  root

let ref_commits_on ~version ~multi (vector : Vectors.vector) =
  let format =
    match version with W.V1 | W.V2_sha1 -> Id.Sha1 | W.V2_sha256 -> Id.Sha256
  in
  let refs_json =
    match required "refs" vector.input with
    | `Assoc refs -> refs
    | _ -> Alcotest.fail "no refs"
  in
  let commits = ref [] in
  let recs =
    List.map
      (fun (name, target) ->
        let value =
          match target with
          | `Assoc [ ("commit", `String c) ] ->
              let h = hex_of_name format c in
              commits := (h, c) :: !commits;
              W.Object (raw_id_of_hex h)
          | `Assoc [ ("other", `String o) ] ->
              let h = hex_of_name format ("other:" ^ o) in
              W.Object (raw_id_of_hex h)
          | `Assoc [ ("ref", `String r) ] -> W.Symbolic r
          | `Assoc [] -> W.Symbolic "not a ref name"
          | other ->
              Alcotest.failf "not a target: %s" (Yojson.Basic.to_string other)
        in
        { W.name; update_index_delta = 0L; value })
      refs_json
  in
  let root = make_reftable_git_folder ~version ~multi recs in
  let refs =
    Refs.create default_limits Refs.Reftable format ~git_folder:root Refs.Main
  in
  let is_commit id = Ok (List.mem_assoc (Id.to_hex id) !commits) in
  let name =
    match required "ref" vector.input with
    | `String n -> n
    | _ -> Alcotest.fail "no ref"
  in
  commit_values !commits (Ref_commit.commit (Refs.refs refs ~is_commit) name)

let head_commits_on ~version (vector : Vectors.vector) =
  let format =
    match version with W.V1 | W.V2_sha1 -> Id.Sha1 | W.V2_sha256 -> Id.Sha256
  in
  let refs_list =
    match required "refs" vector.input with
    | `Assoc refs ->
        List.map
          (function
            | name, `String c -> (name, c) | _ -> Alcotest.fail "not ref")
          refs
    | _ -> Alcotest.fail "no refs"
  in
  let head_val, head_commit =
    match required "head" vector.input with
    | `Assoc [ ("ref", `String r) ] -> (W.Symbolic r, [])
    | `Assoc [ ("commit", `String c) ] ->
        let h = hex_of_name format c in
        (W.Object (raw_id_of_hex h), [ (h, c) ])
    | _ -> Alcotest.fail "not HEAD"
  in
  let commits =
    head_commit @ List.map (fun (_, c) -> (hex_of_name format c, c)) refs_list
  in
  let recs =
    { W.name = "HEAD"; update_index_delta = 0L; value = head_val }
    :: List.map
         (fun (name, c) ->
           {
             W.name;
             update_index_delta = 0L;
             value = W.Object (raw_id_of_hex (hex_of_name format c));
           })
         refs_list
  in
  let root = make_reftable_git_folder ~version ~multi:false recs in
  let refs =
    Refs.create default_limits Refs.Reftable format ~git_folder:root Refs.Main
  in
  let is_commit id = Ok (List.mem_assoc (Id.to_hex id) commits) in
  commit_values commits (Ref_commit.commit (Refs.refs refs ~is_commit) "HEAD")

let default_branch_on ~version (vector : Vectors.vector) =
  let format =
    match version with W.V1 | W.V2_sha1 -> Id.Sha1 | W.V2_sha256 -> Id.Sha256
  in
  let binding =
    match required "binding" vector.input with
    | `String s -> s
    | _ -> Alcotest.fail "no binding"
  in
  let upstream_name = "refs/remotes/upstream/the-branch" in
  let commits = ref [] in
  let recs = ref [] in
  let add_ref name = function
    | None -> ()
    | Some (`String c) ->
        let h = hex_of_name format c in
        commits := (h, c) :: !commits;
        recs :=
          {
            W.name;
            update_index_delta = 0L;
            value = W.Object (raw_id_of_hex h);
          }
          :: !recs
    | Some (`Assoc []) ->
        let h = hex_of_name format ("other:" ^ name) in
        recs :=
          {
            W.name;
            update_index_delta = 0L;
            value = W.Object (raw_id_of_hex h);
          }
          :: !recs
    | Some other -> Alcotest.failf "not ref: %s" (Yojson.Basic.to_string other)
  in
  let upstream_m = member "upstream" vector.input in
  add_ref upstream_name upstream_m;
  add_ref ("refs/heads/" ^ binding) (member "local" vector.input);
  add_ref ("refs/remotes/origin/" ^ binding) (member "remote" vector.input);
  let root = make_reftable_git_folder ~version ~multi:false !recs in
  let refs =
    Refs.create default_limits Refs.Reftable format ~git_folder:root Refs.Main
  in
  let is_commit id = Ok (List.mem_assoc (Id.to_hex id) !commits) in
  let upstream _ =
    Ok (if Option.is_some upstream_m then Some upstream_name else None)
  in
  commit_values !commits
    (Default_branch.commit ~upstream
       ~refs:(Refs.refs refs ~is_commit)
       (Result.get_ok
          (Sinter_branch_names.Branch_name.of_text
             (Result.get_ok (Text.decode binding)))))

let upstreams_on (vector : Vectors.vector) =
  let binding =
    match required "binding" vector.input with
    | `String s -> s
    | _ -> Alcotest.fail "no binding"
  in
  let refs_list =
    match required "refs" vector.input with
    | `Assoc refs ->
        List.map
          (function
            | name, `String c -> (name, c) | _ -> Alcotest.fail "not ref")
          refs
    | _ -> Alcotest.fail "no refs"
  in
  let settings =
    match required "settings" vector.input with
    | `Assoc pairs -> pairs
    | _ -> Alcotest.fail "no settings"
  in
  let config_lines =
    List.concat_map
      (fun (full_key, values_json) ->
        let values =
          match values_json with
          | `List vs ->
              List.map
                (function `String s -> s | _ -> Alcotest.fail "not string")
                vs
          | _ -> Alcotest.fail "not list"
        in
        let parts = String.split_on_char '.' full_key in
        match parts with
        | section :: rest when List.length rest >= 1 ->
            let rev = List.rev rest in
            let var = List.hd rev in
            let sub = String.concat "." (List.rev (List.tl rev)) in
            let header =
              if sub = "" then Printf.sprintf "[%s]\n" section
              else Printf.sprintf "[%s %S]\n" section sub
            in
            header
            :: List.map (fun v -> Printf.sprintf "\t%s = %s\n" var v) values
        | _ -> Alcotest.failf "bad setting key %s" full_key)
      settings
  in
  let commits = List.map (fun (_, c) -> (hex_of_name Id.Sha1 c, c)) refs_list in
  let recs =
    List.map
      (fun (name, c) ->
        {
          W.name;
          update_index_delta = 0L;
          value = W.Object (raw_id_of_hex (hex_of_name Id.Sha1 c));
        })
      refs_list
  in
  let root = make_reftable_git_folder ~version:W.V1 ~multi:false recs in
  write_file (root / "config") (String.concat "" config_lines);
  let cfg =
    match
      Config.of_repository
        ~limits:{ Config.max_files = 16; max_values = 1024 }
        ~environment:(fun name ->
          if name = "GIT_CONFIG_NOSYSTEM" then Some "1" else None)
        ~read:(fun path ->
          if Sys.file_exists path then
            Config.Content { content = read_file path; identity = None }
          else Config.No_file)
        ~real_path:(fun pathname -> Some pathname)
        ~git_directories:[ root ] ~branch:None root
    with
    | Ok c -> c
    | Error _ -> Alcotest.fail "config read failed"
  in
  let refs =
    Refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:root Refs.Main
  in
  let is_commit id = Ok (List.mem_assoc (Id.to_hex id) commits) in
  let upstream b =
    match Config.upstream cfg b with
    | Ok u -> Ok u
    | Error _ -> Error (Refs.Objects "upstream")
  in
  commit_values commits
    (Default_branch.commit ~upstream
       ~refs:(Refs.refs refs ~is_commit)
       (Result.get_ok
          (Sinter_branch_names.Branch_name.of_text
             (Result.get_ok (Text.decode binding)))))

(* @verifies changes[ref-commits]
   Each vector of `ref-commits` is encoded into a reftable stack (version 1
   SHA-1 single-table, version 1 SHA-1 multi-table with override and deletion,
   and version 2 SHA-256) and evaluated through `Refs.refs` and
   `Ref_commit.commit`; the result must equal the vector's commit or none. *)
let ref_commit_vectors =
  [
    Vectors.group set ~name:"ref-commits" ~form:"#ref-commit-vector=v1"
      (ref_commits_on ~version:W.V1 ~multi:false);
    Vectors.group set ~name:"ref-commits" ~form:"#ref-commit-vector=v1"
      (ref_commits_on ~version:W.V1 ~multi:true);
    Vectors.group set ~name:"ref-commits" ~form:"#ref-commit-vector=v1"
      (ref_commits_on ~version:W.V2_sha256 ~multi:false);
  ]

(* @verifies changes[head-commits]
   Each vector of `head-commits` is encoded into a reftable stack (version 1
   SHA-1 and version 2 SHA-256) and evaluated through `Refs.refs` and
   `Ref_commit.commit` on `HEAD`; the result must equal the vector's head
   commit or none. *)
let head_commit_vectors =
  [
    Vectors.group set ~name:"head-commits" ~form:"#head-commit-vector=v1"
      (head_commits_on ~version:W.V1);
    Vectors.group set ~name:"head-commits" ~form:"#head-commit-vector=v1"
      (head_commits_on ~version:W.V2_sha256);
  ]

(* @verifies changes[default-branch-commits]
   Each vector of `default-branch-commits` is encoded into a reftable stack
   (version 1 SHA-1 and version 2 SHA-256) and evaluated through
   `Default_branch.commit` on `Refs.refs`; the result must equal the vector's
   commit or none. *)
let default_branch_vectors =
  [
    Vectors.group set ~name:"default-branch-commits"
      ~form:"#default-branch-commit-vector=v1"
      (default_branch_on ~version:W.V1);
    Vectors.group set ~name:"default-branch-commits"
      ~form:"#default-branch-commit-vector=v1"
      (default_branch_on ~version:W.V2_sha256);
  ]

(* @verifies changes[upstreams]
   Each vector of `upstreams` is written with its configuration and reftable
   stack and evaluated through `Config.upstream`, `Refs.refs`, and
   `Default_branch.commit`; the result must equal the vector's commit or
   none. *)
let upstream_vectors =
  [
    Vectors.group set ~name:"upstreams" ~form:"#upstream-vector=v1" upstreams_on;
  ]

(* @verifies changes#read-only-repository-files=v1
   On a fake filesystem recording every system call, reftable lookups read
   only `tables.list` and the named tables inside the git folder's or working
   tree's `reftable` folder, never read stub `HEAD` or loose ref files, make
   no call for non-ref names, and reject path traversal in `tables.list`
   before opening any file outside the `reftable` folder. *)
let security_and_limits_tests =
  [
    case
      "reftable reads only inside reftable folders and caches each stack \
       independently" (fun () ->
        let main_table =
          W.encode
            [
              {
                W.name = "HEAD";
                update_index_delta = 0L;
                value = W.Symbolic "refs/heads/main";
              };
              {
                W.name = "refs/heads/bad";
                update_index_delta = 0L;
                value = W.Symbolic "../escape";
              };
              {
                W.name = "refs/heads/main";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
            ]
        in
        let wt_table =
          W.encode
            [
              {
                W.name = "HEAD";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
              {
                W.name = "refs/worktree/x";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '3');
              };
            ]
        in
        Fake.reset
          [
            ("/g/HEAD", Fake.File "ref: refs/heads/.invalid\n");
            ("/g/reftable/tables.list", Fake.File "m.ref\n");
            ("/g/reftable/m.ref", Fake.File main_table);
            ("/g/worktrees/w/HEAD", Fake.File "ref: refs/heads/.invalid\n");
            ("/g/worktrees/w/reftable/tables.list", Fake.File "w.ref\n");
            ("/g/worktrees/w/reftable/w.ref", Fake.File wt_table);
          ];
        let refs =
          Fake_refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:"/g"
            (Refs.Linked "/g/worktrees/w")
        in
        Alcotest.(check (list string))
          "create makes no calls" []
          (Test_repository_files.calls ());
        Alcotest.(check string)
          "invalid ref name makes no calls" "none"
          (show_lookup (Fake_refs.lookup refs "refs/heads/../../etc/passwd"));
        Alcotest.(check (list string))
          "still no calls" []
          (Test_repository_files.calls ());
        Alcotest.(check string)
          "shared ref reads only git folder stack"
          ("object " ^ sha1_hex '1')
          (show_lookup (Fake_refs.lookup refs "refs/heads/main"));
        let calls_after_shared = Test_repository_files.calls () in
        Alcotest.(check bool)
          "no call to worktree stack yet" false
          (List.exists (fun c -> String.contains c 'w') calls_after_shared);
        Alcotest.(check bool)
          "stub HEAD never read" false
          (List.exists (fun c -> c = "open_file /g/HEAD") calls_after_shared);
        Alcotest.(check string)
          "broken symbolic target" "broken"
          (show_lookup (Fake_refs.lookup refs "refs/heads/bad"));
        Alcotest.(check int)
          "second shared lookup makes no new calls"
          (List.length calls_after_shared)
          (List.length (Test_repository_files.calls ()));
        Alcotest.(check string)
          "own ref reads worktree stack"
          ("object " ^ sha1_hex '2')
          (show_lookup (Fake_refs.lookup refs "HEAD"));
        let calls_after_own = Test_repository_files.calls () in
        Alcotest.(check string)
          "second own lookup cached"
          ("object " ^ sha1_hex '3')
          (show_lookup (Fake_refs.lookup refs "refs/worktree/x"));
        Alcotest.(check int)
          "no extra calls on cached own stack"
          (List.length calls_after_own)
          (List.length (Test_repository_files.calls ()));
        Fake.reset
          [
            ("/g/reftable/tables.list", Fake.File "m.ref\n");
            ("/g/reftable/m.ref", Fake.File main_table);
          ];
        let main_refs =
          Fake_refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:"/g"
            Refs.Main
        in
        Alcotest.(check string)
          "Main HEAD" "symbolic \"refs/heads/main\""
          (show_lookup (Fake_refs.lookup main_refs "HEAD"));
        let calls_main = Test_repository_files.calls () in
        Alcotest.(check string)
          "Main shared ref reuses cached stack"
          ("object " ^ sha1_hex '1')
          (show_lookup (Fake_refs.lookup main_refs "refs/heads/main"));
        Alcotest.(check int)
          "Main reads stack only once across own and shared refs"
          (List.length calls_main)
          (List.length (Test_repository_files.calls ()));
        let rfn_err_obj =
          Fake_refs.refs main_refs ~is_commit:(fun _ -> Error "store fail")
        in
        Alcotest.(check bool)
          "Refs.refs propagates Objects error on reftable" true
          (match rfn_err_obj "refs/heads/main" with
          | Error (Refs.Objects "store fail") -> true
          | _ -> false);
        Fake.reset [];
        let missing_refs =
          Fake_refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:"/g"
            Refs.Main
        in
        Alcotest.(check bool)
          "Refs.refs propagates Refs error on reftable" true
          (match
             Fake_refs.refs missing_refs
               ~is_commit:(fun _ -> Ok true)
               "refs/heads/main"
           with
          | Error (Refs.Refs (Refs.Unread { failure = Files.No_file; _ })) ->
              true
          | _ -> false));
    case "path traversal in tables.list opens no outside file and caches error"
      (fun () ->
        Fake.reset
          [
            ("/g/reftable/tables.list", Fake.File "../../../outside.ref\n");
            ("/outside.ref", Fake.File (W.encode []));
          ];
        let refs =
          Fake_refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:"/g"
            Refs.Main
        in
        let r1 = Fake_refs.lookup refs "refs/heads/main" in
        let calls1 = Test_repository_files.calls () in
        Alcotest.(check bool)
          "bad table name error" true
          (match r1 with
          | Error
              (Refs.Malformed_tables_list
                 { error = Reftable.Bad_table_name "../../../outside.ref"; _ })
            ->
              true
          | _ -> false);
        Alcotest.(check bool)
          "never touched outside.ref" false
          (List.exists
             (fun c ->
               String.starts_with ~prefix:"open_file " c
               && not
                    (String.starts_with
                       ~prefix:"open_file /g/reftable/tables.list" c))
             calls1);
        let r2 = Fake_refs.lookup refs "refs/heads/other" in
        Alcotest.(check string)
          "same cached error" (show_lookup r1) (show_lookup r2);
        Alcotest.(check int)
          "no extra calls after cached error" (List.length calls1)
          (List.length (Test_repository_files.calls ())));
    (* @verifies conformance#report-stops-at-limits=v1
       A tables.list file larger than max_tables_list_size or a table larger
       than the remaining max_stack_size stops and reports Unread with
       Too_large and the pathname of that file. *)
    case
      "limits enforce max_tables_list_size, max_stack_size, max_names_size, \
       and non-negativity" (fun () ->
        let t1 =
          W.encode
            [
              {
                W.name = "refs/heads/a";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '1');
              };
            ]
        in
        let t2 =
          W.encode
            [
              {
                W.name = "refs/heads/b";
                update_index_delta = 0L;
                value = W.Object (sha1_raw '2');
              };
            ]
        in
        let tl = "t1.ref\nt2.ref\n" in
        let setup () =
          Fake.reset
            [
              ("/g/reftable/tables.list", Fake.File tl);
              ("/g/reftable/t1.ref", Fake.File t1);
              ("/g/reftable/t2.ref", Fake.File t2);
            ]
        in
        let mk lim =
          setup ();
          Fake_refs.create lim Refs.Reftable Id.Sha1 ~git_folder:"/g" Refs.Main
        in
        let exact =
          {
            default_limits with
            max_tables_list_size = String.length tl;
            max_stack_size = String.length t1 + String.length t2;
            max_names_size =
              String.length "refs/heads/a" + String.length "refs/heads/b";
          }
        in
        Alcotest.(check string)
          "exact limits succeed"
          ("object " ^ sha1_hex '1')
          (show_lookup (Fake_refs.lookup (mk exact) "refs/heads/a"));
        Alcotest.(check string)
          "tables.list over by 1" "unread tables.list: too large"
          (show_lookup
             (Fake_refs.lookup
                (mk
                   {
                     exact with
                     max_tables_list_size = exact.max_tables_list_size - 1;
                   })
                "refs/heads/a"));
        Alcotest.(check string)
          "stack size over by 1 fails older table" "unread t1.ref: too large"
          (show_lookup
             (Fake_refs.lookup
                (mk { exact with max_stack_size = exact.max_stack_size - 1 })
                "refs/heads/a"));
        Alcotest.(check string)
          "names size over by 1 fails older table"
          "malformed table t1.ref: names too large"
          (show_lookup
             (Fake_refs.lookup
                (mk { exact with max_names_size = exact.max_names_size - 1 })
                "refs/heads/a"));
        List.iter
          (fun lim ->
            match
              Refs.create lim Refs.Reftable Id.Sha1 ~git_folder:"/g" Refs.Main
            with
            | _ -> Alcotest.fail "no Invalid_argument"
            | exception Invalid_argument _ -> ())
          [
            { default_limits with max_loose_size = -1 };
            { default_limits with max_packed_size = -1 };
            { default_limits with max_tables_list_size = -1 };
            { default_limits with max_stack_size = -1 };
            { default_limits with max_names_size = -1 };
          ]);
    case "a symlinked reftable folder is followed" (fun () ->
        let base = Git_fixture.temp_dir () in
        let real_rt = base / "real-reftable" in
        let gf = base / ".git" in
        Unix.mkdir gf 0o755;
        let t =
          W.encode
            [
              {
                W.name = "refs/heads/main";
                update_index_delta = 0L;
                value = W.Object (sha1_raw 'a');
              };
            ]
        in
        write_file (real_rt / "tables.list") "t.ref\n";
        write_file (real_rt / "t.ref") t;
        Unix.symlink real_rt (gf / "reftable");
        let refs =
          Refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:gf
            Refs.Main
        in
        Alcotest.(check string)
          "through symlinked reftable dir"
          ("object " ^ sha1_hex 'a')
          (show_lookup (Refs.lookup refs "refs/heads/main")));
    case "a FIFO in place of tables.list or a table is not opened" (fun () ->
        Fake.reset [ ("/g/reftable/tables.list", Fake.Other) ];
        let r1 =
          Fake_refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:"/g"
            Refs.Main
        in
        Alcotest.(check string)
          "FIFO tables.list" "unread tables.list: not a regular file"
          (show_lookup (Fake_refs.lookup r1 "refs/heads/main"));
        Alcotest.(check bool)
          "FIFO tables.list not opened" false
          (List.mem "open_file /g/reftable/tables.list"
             (Test_repository_files.calls ()));
        Fake.reset
          [
            ("/g/reftable/tables.list", Fake.File "pipe.ref\n");
            ("/g/reftable/pipe.ref", Fake.Other);
          ];
        let r2 =
          Fake_refs.create default_limits Refs.Reftable Id.Sha1 ~git_folder:"/g"
            Refs.Main
        in
        Alcotest.(check string)
          "FIFO table" "unread pipe.ref: not a regular file"
          (show_lookup (Fake_refs.lookup r2 "refs/heads/main"));
        Alcotest.(check bool)
          "FIFO table not opened" false
          (List.mem "open_file /g/reftable/pipe.ref"
             (Test_repository_files.calls ())));
    case "no reftable lookup waits on a real FIFO" (fun () ->
        let probe gf name =
          match Bounded_run.probe ~seconds:5. [ "reftable"; gf; name ] with
          | Ok lines -> lines
          | Error reason -> Alcotest.failf "the reftable probe: %s" reason
        in
        let gf1 = Git_fixture.temp_dir () / ".git" in
        Unix.mkdir gf1 0o755;
        Unix.mkdir (gf1 / "reftable") 0o755;
        Unix.mkfifo (gf1 / "reftable/tables.list") 0o600;
        Alcotest.(check (list string))
          "real FIFO tables.list"
          [
            "unread tables.list: not a regular file";
            "unread tables.list: not a regular file";
          ]
          (probe gf1 "refs/heads/main");
        let gf2 = Git_fixture.temp_dir () / ".git" in
        write_file (gf2 / "reftable/tables.list") "pipe.ref\n";
        Unix.mkfifo (gf2 / "reftable/pipe.ref") 0o600;
        Alcotest.(check (list string))
          "real FIFO table"
          [
            "unread pipe.ref: not a regular file";
            "unread pipe.ref: not a regular file";
          ]
          (probe gf2 "refs/heads/main"));
  ]

let growth_tests =
  let make_table n =
    let recs =
      List.init n (fun i ->
          {
            W.name = Printf.sprintf "refs/heads/growth/%06d" i;
            update_index_delta = 0L;
            value = W.Object (sha1_raw '1');
          })
    in
    W.encode ~config:{ W.default_config with block_size = 1024 } recs
  in
  let make_tables_list n =
    let buf = Buffer.create (n * 20) in
    for i = 0 to n - 1 do
      Buffer.add_string buf (Printf.sprintf "table-%06d.ref\n" i)
    done;
    Buffer.contents buf
  in
  [
    case "Reftable.parse memory and time grow linearly with table size"
      (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(200, 3200)
          ~input:make_table (fun bytes ->
            ignore (Reftable.parse Id.Sha1 ~max_names:(1 lsl 24) bytes));
        Time_growth.check ~bound:10. ~size:200 ~input:make_table (fun bytes ->
            ignore (Reftable.parse Id.Sha1 ~max_names:(1 lsl 24) bytes)));
    case "Reftable.table_names memory and time grow linearly with entry count"
      (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(200, 3200)
          ~input:make_tables_list (fun content ->
            ignore (Reftable.table_names content));
        Time_growth.check ~bound:10. ~size:200 ~input:make_tables_list
          (fun content -> ignore (Reftable.table_names content)));
    case "Reftable.find lookup time stays sublinear with table size" (fun () ->
        let make_parsed n =
          ( parse_ok ~max_names:(1 lsl 26) (make_table n),
            Printf.sprintf "refs/heads/growth/%06d" (n lsr 1) )
        in
        Time_growth.check ~bound:4.0 ~size:500 ~input:make_parsed
          (Time_growth.repeat 100_000 (fun (t, name) -> Reftable.find t name)));
    case "prefix-compression bomb stops in O(max_names) memory and time"
      (fun () ->
        let make_bomb n =
          let prefix = "refs/heads/" ^ String.make 500 'a' in
          let recs =
            List.init n (fun i ->
                {
                  W.name = Printf.sprintf "%s/%06d" prefix i;
                  update_index_delta = 0L;
                  value = W.Deletion;
                })
          in
          W.encode
            ~config:
              {
                W.default_config with
                block_size = 0;
                restart_interval = 100_000;
              }
            recs
        in
        Counted_work.check_growth ~exponent:0. ~margin:2.0 ~sizes:(200, 3200)
          ~input:make_bomb (fun bytes ->
            ignore (Reftable.parse Id.Sha1 ~max_names:20_000 bytes)));
  ]

let tests =
  table_names_tests @ storage_tests @ parse_valid_tests @ parse_damaged_tests
  @ qcheck_tests @ real_git_tests @ damaged_input_tests
  @ Vectors.tests "changes on the reftable format"
      (ref_commit_vectors @ head_commit_vectors @ default_branch_vectors
     @ upstream_vectors)
  @ security_and_limits_tests @ growth_tests
