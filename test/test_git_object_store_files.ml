(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Store = Sinter_git_object_store.Object_store
module Id = Sinter_git_objects.Object_id
module Files = Sinter_repository_files
module O = Object_files
module Repo = Git_fixture

let case name f = Alcotest.test_case name `Quick f
let slow name f = Alcotest.test_case name `Slow f
let ( / ) = Filename.concat

let limits =
  {
    Store.max_content_size = 1 lsl 24;
    max_deltas = 10_000;
    max_databases = 100;
    max_packs = 100;
    max_alternates_size = 1 lsl 16;
  }

let kind_of_type = function
  | "commit" -> Store.Commit
  | "tree" -> Store.Tree
  | "blob" -> Store.Blob
  | "tag" -> Store.Tag
  | other -> Alcotest.failf "the type %s" other

let kind_text = function
  | Store.Commit -> "commit"
  | Tree -> "tree"
  | Blob -> "blob"
  | Tag -> "tag"

let failure_text = function
  | Store.Unread { pathname; failure } ->
      Printf.sprintf "unread %s: %s" pathname
        (match failure with
        | Files.No_file -> "no file"
        | Not_a_regular_file -> "not a regular file"
        | Not_a_folder -> "not a folder"
        | Not_a_symbolic_link -> "not a symbolic link"
        | Too_large -> "too large"
        | Cannot_read -> "cannot read")
  | Too_large { pathname; _ } -> "too large " ^ pathname
  | Too_many_deltas -> "too many deltas"
  | Too_many_databases -> "too many databases"
  | Too_many_packs pathname -> "too many packs " ^ pathname

let result_text = function
  | Ok { Store.held = Some { kind; content }; damage } ->
      Printf.sprintf "%s %S, %d damage" (kind_text kind) content
        (List.length damage)
  | Ok { held = None; damage } ->
      Printf.sprintf "not held, %d damage" (List.length damage)
  | Error failure -> "Error " ^ failure_text failure

let format_of = function "sha256" -> Id.Sha256 | _ -> Id.Sha1

let id_of format hex =
  match Id.of_hex format hex with
  | Some id -> id
  | None -> Alcotest.failf "not an id: %s" hex

let git_folder repo = Repo.root repo / ".git"

let split_lines text =
  List.filter (fun l -> l <> "") (String.split_on_char '\n' text)

let catalog ?(dir = []) repo =
  let listing =
    Repo.git repo
      (dir
      @ [
          "cat-file";
          "--batch-all-objects";
          "--batch-check=%(objectname) %(objecttype)";
        ])
  in
  let ids =
    List.map
      (fun line -> List.hd (String.split_on_char ' ' line))
      (split_lines listing)
  in
  let output =
    Repo.git_input repo
      (dir @ [ "cat-file"; "--batch" ])
      (String.concat "" (List.map (fun id -> id ^ "\n") ids))
  in
  let rec parse at acc =
    if at >= String.length output then List.rev acc
    else
      let eol = String.index_from output at '\n' in
      match String.split_on_char ' ' (String.sub output at (eol - at)) with
      | [ hex; typ; size ] ->
          let size = int_of_string size in
          let content = String.sub output (eol + 1) size in
          parse (eol + 1 + size + 1) ((hex, kind_of_type typ, content) :: acc)
      | _ -> Alcotest.failf "the output of git cat-file at %d" at
  in
  parse 0 []

let lines n =
  String.concat "" (List.init n (fun i -> Printf.sprintf "line %d\n" i))

let history ?(object_format = "sha1") ?(commits = 12) () =
  let repo = Repo.init ~object_format () in
  for i = 1 to commits do
    Repo.write repo "f.txt" (lines (100 + (i * 3)));
    Repo.write repo
      (Printf.sprintf "d/e/%d.md" (i mod 3))
      (Printf.sprintf "note %d\n" i);
    if i = 3 then Repo.symlink repo ~target:"f.txt" "l";
    if i = 4 then (
      Repo.write repo "x.sh" "#!/bin/sh\n";
      Repo.make_executable repo "x.sh");
    ignore (Repo.git repo [ "add"; "-A" ]);
    ignore
      (Repo.git repo [ "commit"; "-q"; "-m"; Printf.sprintf "commit %d" i ])
  done;
  ignore (Repo.git repo [ "tag"; "-a"; "-m"; "a tag"; "v1" ]);
  repo

let check_every_object ?(dir = []) ?(store_folder = None) repo format =
  let git_folder = Option.value store_folder ~default:(git_folder repo) in
  let store = Store.create limits format ~git_folder in
  let objects = catalog ~dir repo in
  Alcotest.(check bool) "git lists objects" true (List.length objects > 20);
  List.iter
    (fun (hex, kind, content) ->
      Alcotest.(check string)
        hex
        (result_text (Ok { Store.held = Some { kind; content }; damage = [] }))
        (result_text (Store.find store (id_of format hex))))
    objects

let read_file path = In_channel.with_open_bin path In_channel.input_all

let pack_entry_types repo =
  let packs =
    List.filter
      (fun n -> Filename.check_suffix n ".idx")
      (Array.to_list (Sys.readdir (git_folder repo / "objects" / "pack")))
  in
  List.concat_map
    (fun idx ->
      let base =
        git_folder repo / "objects" / "pack" / Filename.chop_suffix idx ".idx"
      in
      let bytes = read_file (base ^ ".pack") in
      let verify = Repo.git repo [ "verify-pack"; "-v"; base ^ ".idx" ] in
      List.filter_map
        (fun line ->
          match List.filter (( <> ) "") (String.split_on_char ' ' line) with
          | [ _; _; _; _; offset; _; _ ] ->
              Some ((Char.code bytes.[int_of_string offset] lsr 4) land 7)
          | _ -> None)
        (split_lines verify))
    packs

let index_versions repo =
  List.filter_map
    (fun n ->
      if Filename.check_suffix n ".idx" then
        let bytes = read_file (git_folder repo / "objects" / "pack" / n) in
        Some (if String.sub bytes 0 4 = "\255tOc" then 2 else 1)
      else None)
    (Array.to_list (Sys.readdir (git_folder repo / "objects" / "pack")))

(* @verifies changes#{give-commit-parents=v1, give-message-texts=v1, give-commit-files=v1, give-commit-file-at-path=v1}
   @cites changes#commit=v1
   In repositories that git creates, in both SHA-1 and SHA-256, the store must
   give the same type and content as `git cat-file --batch` for every loose
   object, every packed object with `OFS_DELTA` and `REF_DELTA` entries, and
   every object in an alternate named by `info/alternates`. Any missing object,
   damage, or difference in type or content fails the test. *)
let repository_tests =
  List.concat_map
    (fun object_format ->
      let format = format_of object_format in
      [
        slow
          (Printf.sprintf "every loose object that git writes is held, in %s"
             object_format) (fun () ->
            check_every_object (history ~object_format ()) format);
        slow
          (Printf.sprintf
             "every object of a pack with OFS_DELTA entries is held, in %s"
             object_format) (fun () ->
            let repo = history ~object_format () in
            ignore
              (Repo.git repo
                 [ "repack"; "-adf"; "-q"; "--depth=50"; "--window=50" ]);
            let types = pack_entry_types repo in
            Alcotest.(check bool)
              "the pack has OFS_DELTA entries" true (List.mem 6 types);
            Alcotest.(check (list int))
              "index versions" [ 2 ] (index_versions repo);
            check_every_object repo format);
        slow
          (Printf.sprintf
             "every object of a pack with REF_DELTA entries and an index v1 is \
              held, in %s"
             object_format) (fun () ->
            let repo = history ~object_format () in
            ignore
              (Repo.git repo
                 [
                   "-c";
                   "repack.useDeltaBaseOffset=false";
                   "-c";
                   "pack.indexVersion=1";
                   "repack";
                   "-adf";
                   "-q";
                   "--depth=50";
                   "--window=50";
                 ]);
            let types = pack_entry_types repo in
            Alcotest.(check bool)
              "the pack has REF_DELTA entries" true (List.mem 7 types);
            Alcotest.(check bool) "no OFS_DELTA entry" false (List.mem 6 types);
            Alcotest.(check (list int))
              "index versions" [ 1 ] (index_versions repo);
            check_every_object repo format);
        slow
          (Printf.sprintf
             "every object of loose objects, two packs, and an alternate is \
              held, in %s"
             object_format) (fun () ->
            let source = history ~object_format () in
            ignore (Repo.git source [ "repack"; "-ad"; "-q" ]);
            Repo.write source "late.txt" "late\n";
            ignore (Repo.git source [ "add"; "-A" ]);
            ignore (Repo.git source [ "commit"; "-q"; "-m"; "late" ]);
            ignore (Repo.git source [ "repack"; "-d"; "-q" ]);
            Repo.write source "loose.txt" "loose\n";
            ignore (Repo.git source [ "add"; "-A" ]);
            ignore (Repo.git source [ "commit"; "-q"; "-m"; "loose" ]);
            let dir = Repo.temp_dir () in
            ignore
              (Repo.git source
                 [ "clone"; "-q"; "--shared"; Repo.root source; dir / "shared" ]);
            let clone = [ "-C"; dir / "shared" ] in
            O.write_file (dir / "shared" / "own.txt") "own\n";
            ignore (Repo.git source (clone @ [ "add"; "-A" ]));
            ignore (Repo.git source (clone @ [ "commit"; "-q"; "-m"; "own" ]));
            let clone_git = dir / "shared" / ".git" in
            Alcotest.(check bool)
              "the clone has alternates" true
              (Sys.file_exists (clone_git / "objects" / "info" / "alternates"));
            check_every_object ~dir:clone ~store_folder:(Some clone_git) source
              format);
      ])
    [ "sha1"; "sha256" ]

module Recording = struct
  let pathnames = ref []
  let note pathname = pathnames := pathname :: !pathnames

  include (Files : Files.READER with type handle = Files.handle)

  let read ~max_size pathname =
    note pathname;
    Files.read ~max_size pathname

  let with_file pathname f =
    note pathname;
    Files.with_file pathname f

  let list pathname =
    note pathname;
    Files.list pathname

  let folder_identity pathname =
    note pathname;
    Files.folder_identity pathname

  let link_kind pathname =
    note pathname;
    Files.link_kind pathname

  let link_text pathname =
    note pathname;
    Files.link_text pathname
end

module Recorded = Store.Make (Recording)

(* @verifies changes#read-only-repository-files=v1
   A partial clone whose remote is a local folder lacks the blobs of its
   remote. The store makes no fetch, so a file of the remote is no source that
   the list of the requirement allows, and a read of any pathname outside the
   object database of the clone, such as a file of the remote, fails the test.
   By the promise of the interface of the store that it takes no object from a
   remote, a lookup that gives one of the blobs of the remote also fails it.
   The test cannot see a remote that the store reaches by other means than the
   reader of repository files. *)
let partial_clone_tests =
  [
    slow "a partial clone holds no blob that only its remote holds" (fun () ->
        let source = history () in
        ignore (Repo.git source [ "config"; "uploadpack.allowFilter"; "true" ]);
        let dir = Repo.temp_dir () in
        let clone_root = dir / "partial" in
        ignore
          (Repo.git source
             [
               "clone";
               "-q";
               "--filter=blob:none";
               "--no-checkout";
               "file://" ^ Repo.root source;
               clone_root;
             ]);
        let clone_git = clone_root / ".git" in
        Alcotest.(check bool)
          "the clone is a partial clone" true
          (Array.exists
             (fun n -> Filename.check_suffix n ".promisor")
             (Sys.readdir (clone_git / "objects" / "pack")));
        let in_clone =
          let output =
            Repo.git source
              [
                "--git-dir=" ^ clone_git;
                "cat-file";
                "--batch-all-objects";
                "--batch-check=%(objectname)";
              ]
          in
          split_lines output
        in
        let missing =
          List.filter
            (fun (hex, kind, _) ->
              kind = Store.Blob && not (List.mem hex in_clone))
            (catalog source)
        in
        Alcotest.(check bool) "the clone lacks blobs" true (missing <> []);
        Recording.pathnames := [];
        let store = Recorded.create limits Id.Sha1 ~git_folder:clone_git in
        List.iter
          (fun (hex, _, _) ->
            Alcotest.(check string)
              hex "not held, 0 damage"
              (result_text (Recorded.find store (id_of Id.Sha1 hex))))
          missing;
        List.iter
          (fun hex ->
            match Recorded.find store (id_of Id.Sha1 hex) with
            | Ok { held = Some _; _ } -> ()
            | other -> Alcotest.failf "%s: %s" hex (result_text other))
          in_clone;
        let prefix = clone_git / "objects" in
        Alcotest.(check (list string))
          "pathnames outside the object database" []
          (List.sort_uniq String.compare
             (List.filter
                (fun p -> not (String.starts_with ~prefix p))
                !Recording.pathnames)));
  ]

let probe ?env name args =
  match Bounded_run.probe ?env ~seconds:5. args with
  | Ok lines -> lines
  | Error reason -> Alcotest.failf "%s: %s" name reason

let small_database () =
  let dir = Repo.temp_dir () in
  let git = dir / "g" in
  let objects = git / "objects" in
  let x = O.write_loose objects Id.Sha1 O.Blob "loose\n" in
  let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, "packed\n") ] in
  let y = O.id Id.Sha1 O.Blob "packed\n" in
  O.write_pack objects ~name:"p" pack (O.index_v2 Id.Sha1 ~pack [ y ]);
  (dir, git, objects, x, y)

let look ?env ?(deltas = 100) ?(databases = 100) git raw =
  probe ?env "objects"
    [
      "objects";
      git;
      "sha1";
      O.hex raw;
      string_of_int deltas;
      string_of_int databases;
    ]

let no_wait_tests =
  [
    case
      "no lookup waits on a FIFO or a device, as the interface of the reads \
       promises" (fun () ->
        let z = O.id Id.Sha1 O.Blob "z" in
        let cases =
          [
            ( "a loose object",
              (fun objects -> Unix.mkfifo (objects / O.loose_path z) 0o600),
              fun objects ->
                [
                  Printf.sprintf "unread %s: not a regular file"
                    (objects / O.loose_path z);
                ] );
            ( "an index",
              (fun objects ->
                Unix.mkfifo (objects / "pack" / "pack-f.idx") 0o600;
                O.write_file (objects / "pack" / "pack-f.pack") "PACK";
                ()),
              fun objects ->
                [
                  Printf.sprintf "unread %s: not a regular file"
                    (objects / "pack" / "pack-f.idx");
                ] );
            ( "a pack",
              (fun objects ->
                let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, "z") ] in
                O.write_file
                  (objects / "pack" / "pack-f.idx")
                  (O.index_v2 Id.Sha1 ~pack [ z ]);
                Unix.mkfifo (objects / "pack" / "pack-f.pack") 0o600),
              fun objects ->
                [
                  Printf.sprintf "unread %s: not a regular file"
                    (objects / "pack" / "pack-f.pack");
                ] );
            ( "a pack that is a link to /dev/zero",
              (fun objects ->
                let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, "z") ] in
                O.write_file
                  (objects / "pack" / "pack-f.idx")
                  (O.index_v2 Id.Sha1 ~pack [ z ]);
                Unix.symlink "/dev/zero" (objects / "pack" / "pack-f.pack")),
              fun objects ->
                [
                  Printf.sprintf "unread %s: not a regular file"
                    (objects / "pack" / "pack-f.pack");
                ] );
            ( "an index that is a link to /dev/null",
              (fun objects ->
                Unix.symlink "/dev/null" (objects / "pack" / "pack-f.idx");
                O.write_file (objects / "pack" / "pack-f.pack") "PACK"),
              fun objects ->
                [
                  Printf.sprintf "unread %s: not a regular file"
                    (objects / "pack" / "pack-f.idx");
                ] );
            ( "the file info/alternates",
              (fun objects ->
                O.write_file (objects / "info" / "x") "";
                Unix.mkfifo (objects / "info" / "alternates") 0o600),
              fun objects ->
                [
                  Printf.sprintf "unread %s: not a regular file"
                    (objects / "info" / "alternates");
                ] );
            ( "an object database that an alternates line names",
              (fun objects ->
                Unix.mkfifo (objects / ".." / "fifo") 0o600;
                O.write_file (objects / "info" / "alternates") "../fifo\n"),
              fun _ -> [ "not held 0" ] );
          ]
        in
        List.iter
          (fun (label, plant, expected) ->
            let _, git, objects, _, _ = small_database () in
            Unix.mkdir (Filename.dirname (objects / O.loose_path z)) 0o755;
            plant objects;
            Alcotest.(check (list string)) label (expected objects) (look git z))
          cases;
        List.iter
          (fun (label, plant) ->
            let dir = Repo.temp_dir () in
            let git = dir / "g" in
            Unix.mkdir git 0o755;
            plant git;
            Alcotest.(check (list string)) label [ "not held 0" ] (look git z))
          [
            ( "a FIFO in place of the folder objects",
              fun git -> Unix.mkfifo (git / "objects") 0o600 );
            ( "a FIFO in place of the folder pack",
              fun git ->
                Unix.mkdir (git / "objects") 0o755;
                Unix.mkfifo (git / "objects" / "pack") 0o600 );
          ]);
  ]

(* @verifies changes#read-only-repository-files=v1
   The environment variables by which git takes objects from other folders name
   an object database that holds the object; the test fails when the store,
   in a child process with these variables, gives the object. With the test of
   the system in memory, it shows that the store takes bytes only from the
   files of the object databases of the repository. *)
let environment_tests =
  [
    case "the environment variables of git have no effect on a lookup"
      (fun () ->
        let dir = Repo.temp_dir () in
        let other = dir / "other" / "objects" in
        let x = O.write_loose other Id.Sha1 O.Blob "elsewhere\n" in
        let git = dir / "g" in
        O.write_file (git / "objects" / "info" / "packs") "";
        Alcotest.(check (list string))
          "with the variables" [ "not held 0" ]
          (look
             ~env:
               [
                 "GIT_DIR=" ^ (dir / "other");
                 "GIT_COMMON_DIR=" ^ (dir / "other");
                 "GIT_OBJECT_DIRECTORY=" ^ other;
                 "GIT_ALTERNATE_OBJECT_DIRECTORIES=" ^ other;
               ]
             git x);
        O.write_file (git / "objects" / "info" / "alternates") (other ^ "\n");
        Alcotest.(check (list string))
          "through an alternates file" [ "held 10 0" ] (look git x));
  ]

let chain_pack length =
  let content = "sixteen bytes!!\n" in
  let delta = O.delta ~base_size:16 ~result_size:16 [ O.Copy (0, 16) ] in
  let entries =
    O.Whole (O.Blob, content)
    :: List.init length (fun i -> O.Ofs_delta (i, delta))
  in
  let x = O.id Id.Sha1 O.Blob content in
  let ids =
    List.init (length + 1) (fun i ->
        if i = length then x else O.hash Id.Sha1 (Printf.sprintf "filler %d" i))
  in
  let pack = O.pack Id.Sha1 entries in
  (pack, O.index_v2 Id.Sha1 ~pack ids, x)

let stack_limit = "OCAMLRUNPARAM=l=32k"

let growth_tests =
  [
    slow "the stack does not grow with the length of a delta chain" (fun () ->
        List.iter
          (fun length ->
            let dir = Repo.temp_dir () in
            let git = dir / "g" in
            let pack, index, x = chain_pack length in
            O.write_pack (git / "objects") ~name:"c" pack index;
            Alcotest.(check (list string))
              (Printf.sprintf "a chain of %d" length)
              [ "held 16 0" ]
              (look ~env:[ stack_limit ] ~deltas:length git x))
          [ 10; 20_000 ]);
    slow "the stack does not grow with the number of object databases"
      (fun () ->
        List.iter
          (fun count ->
            let dir = Repo.temp_dir () in
            let x = O.write_loose (dir / "db0") Id.Sha1 O.Blob "far\n" in
            for i = 1 to count do
              O.write_file
                (dir / Printf.sprintf "db%d" i / "info" / "alternates")
                ((dir / Printf.sprintf "db%d" (i - 1)) ^ "\n")
            done;
            let git = dir / "g" in
            Unix.mkdir git 0o755;
            Unix.symlink (dir / Printf.sprintf "db%d" count) (git / "objects");
            Alcotest.(check (list string))
              (Printf.sprintf "%d databases" count)
              [ "held 4 0" ]
              (look ~env:[ stack_limit ] ~databases:(count + 1) git x))
          [ 3; 2_000 ]);
  ]

type state = {
  name : string;
  kind : Unix.file_kind;
  perm : int;
  inode : int;
  size : int;
  mtime : float;
  ctime : float;
  digest : string;
}

let rec states root name =
  let path = if name = "" then root else root / name in
  let stat = Unix.lstat path in
  let digest =
    match stat.st_kind with
    | Unix.S_REG -> Digest.to_hex (Digest.file path)
    | Unix.S_LNK -> Unix.readlink path
    | _ -> ""
  in
  let here =
    {
      name;
      kind = stat.st_kind;
      perm = stat.st_perm;
      inode = stat.st_ino;
      size = stat.st_size;
      mtime = stat.st_mtime;
      ctime = stat.st_ctime;
      digest;
    }
  in
  here
  ::
  (match stat.st_kind with
  | Unix.S_DIR ->
      List.concat_map
        (fun entry -> states root (if name = "" then entry else name / entry))
        (List.sort String.compare (Array.to_list (Sys.readdir path)))
  | _ -> [])

let state_text s =
  Printf.sprintf "%s %d %o %d %d %.6f %.6f %s" s.name (Hashtbl.hash s.kind)
    s.perm s.inode s.size s.mtime s.ctime s.digest

let rec set_writable root writable =
  let stat = Unix.lstat root in
  match stat.st_kind with
  | Unix.S_DIR ->
      if writable then Unix.chmod root 0o755;
      Array.iter
        (fun entry -> set_writable (root / entry) writable)
        (Sys.readdir root);
      if not writable then Unix.chmod root 0o555
  | Unix.S_REG -> Unix.chmod root (if writable then 0o644 else 0o444)
  | _ -> ()

(* @verifies changes#leave-repositories-unchanged=v1
   The test takes the state of each file of the git folder of a repository and
   of the git folder of its alternate (name, kind, inode, size, content, and
   the reference of each symbolic link) before and after the store reads every
   object, first when every file is writable, so that a creation, a deletion,
   or a change by a lookup would take place; any difference fails it. The store
   reads through the reads of repository files, which open no file for
   writing, so it makes no own change, such as a new loose object or pack. The
   test also compares the permissions and the times of change, by the promise
   of the interface of those reads that nothing changes an attribute of a
   file, and it runs once more when no file is writable. It cannot see a change
   that is made and undone during the read, or a change outside these two
   folders. *)
let unchanged_tests =
  [
    slow "a lookup changes no file, also when the files are read-only"
      (fun () ->
        let source = history ~commits:6 () in
        ignore (Repo.git source [ "repack"; "-ad"; "-q" ]);
        Repo.write source "late.txt" "late\n";
        ignore (Repo.git source [ "add"; "-A" ]);
        ignore (Repo.git source [ "commit"; "-q"; "-m"; "late" ]);
        let dir = Repo.temp_dir () in
        let clone = dir / "shared" in
        ignore
          (Repo.git source
             [ "clone"; "-q"; "--shared"; Repo.root source; clone ]);
        let folders = [ git_folder source; clone / ".git" ] in
        let objects = catalog source in
        let read_all () =
          let store =
            Store.create limits Id.Sha1 ~git_folder:(clone / ".git")
          in
          List.iter
            (fun (hex, kind, content) ->
              Alcotest.(check string)
                hex
                (result_text
                   (Ok { Store.held = Some { kind; content }; damage = [] }))
                (result_text (Store.find store (id_of Id.Sha1 hex))))
            objects;
          ignore (Store.find store (id_of Id.Sha1 (String.make 40 '0')))
        in
        let snapshot () =
          List.concat_map (fun f -> List.map state_text (states f "")) folders
        in
        let before = snapshot () in
        read_all ();
        Alcotest.(check (list string)) "writable" before (snapshot ());
        if Unix.geteuid () <> 0 then
          Fun.protect
            ~finally:(fun () ->
              List.iter (fun f -> set_writable f true) folders)
            (fun () ->
              List.iter (fun f -> set_writable f false) folders;
              let before = snapshot () in
              read_all ();
              Alcotest.(check (list string)) "read-only" before (snapshot ())));
  ]

let permission_tests =
  [
    case "a loose object that cannot be read is a failure" (fun () ->
        if Unix.geteuid () <> 0 then (
          let _, git, objects, x, _ = small_database () in
          let path = objects / O.loose_path x in
          Unix.chmod path 0o000;
          Fun.protect
            ~finally:(fun () -> Unix.chmod path 0o644)
            (fun () ->
              let store = Store.create limits Id.Sha1 ~git_folder:git in
              Alcotest.(check string)
                "the failure"
                ("Error unread " ^ path ^ ": cannot read")
                (result_text (Store.find store (id_of Id.Sha1 (O.hex x)))))));
    case "a store on the files of the system gives loose and packed objects"
      (fun () ->
        let _, git, _, x, y = small_database () in
        let store = Store.create limits Id.Sha1 ~git_folder:git in
        Alcotest.(check string)
          "loose" "blob \"loose\\n\", 0 damage"
          (result_text (Store.find store (id_of Id.Sha1 (O.hex x))));
        Alcotest.(check string)
          "packed" "blob \"packed\\n\", 0 damage"
          (result_text (Store.find store (id_of Id.Sha1 (O.hex y)))));
  ]

(* @verifies changes#{give-commit-parents=v1, give-message-texts=v1, give-commit-files=v1, give-commit-file-at-path=v1}
   @cites changes#commit=v1
   By the term `commit`, the base of a `REF_DELTA` entry in a pack is in the
   same pack. In a repacked repository on disk, the test adds a second pack
   whose `REF_DELTA` entry names a blob from the first pack. The test fails
   when the store gives that object or reports a problem other than
   `Base_not_in_pack` at offset 12 of the second pack. *)
let ref_delta_pack_tests =
  [
    slow "a pack whose REF_DELTA base is in another pack gives nothing"
      (fun () ->
        let repo = history () in
        ignore (Repo.git repo [ "repack"; "-adf"; "-q" ]);
        let all = catalog repo in
        let blobs = List.filter (fun (_, k, _) -> k = Store.Blob) all in
        let base_hex, _, base =
          List.find (fun (_, _, c) -> String.length c > 500) blobs
        in
        let target = base ^ "one more line\n" in
        let target_raw = O.id Id.Sha1 O.Blob target in
        let base_id = id_of Id.Sha1 base_hex in
        let base_raw = Id.to_bytes base_id in
        let pack =
          O.pack Id.Sha1
            [
              O.Ref_delta
                ( base_raw,
                  O.delta ~base_size:(String.length base)
                    ~result_size:(String.length target)
                    (O.delta_between base target) );
            ]
        in
        let name = O.hex pack.checksum in
        O.write_pack
          (git_folder repo / "objects")
          ~name pack
          (O.index_v2 Id.Sha1 ~pack [ target_raw ]);
        let store = Store.create limits Id.Sha1 ~git_folder:(git_folder repo) in
        let expected_path =
          git_folder repo / "objects" / "pack" / ("pack-" ^ name ^ ".pack")
        in
        match Store.find store (id_of Id.Sha1 (O.hex target_raw)) with
        | Ok
            {
              held = None;
              damage =
                [
                  {
                    pathname;
                    offset = Some 12;
                    problem = Store.Base_not_in_pack missing;
                  };
                ];
            } ->
            Alcotest.(check string) "the pack pathname" expected_path pathname;
            Alcotest.(check string)
              "the missing base id" base_hex (Id.to_hex missing)
        | other -> Alcotest.fail (result_text other));
  ]

let tests =
  permission_tests @ no_wait_tests @ environment_tests @ repository_tests
  @ ref_delta_pack_tests @ partial_clone_tests @ unchanged_tests @ growth_tests
