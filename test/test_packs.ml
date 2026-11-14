(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_packs
module Gen = QCheck2.Gen

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "Test_packs.text_of: not valid UTF-8"

let path_of string =
  match Sinter_paths.Path.of_text (text_of string) with
  | Ok path -> path
  | Error _ -> invalid_arg "Test_packs.path_of: not a valid path"

let string_of_path path = Text.encode (Sinter_paths.Path.to_text path)
let packs_set = Vectors.read "packs"

type use = {
  named : bool;
  files : string list;
  listing : string option;
  hash : string option;
  contents : (string * (string, Pack.content_failure) result) list;
}

let use_pack ?(paths = []) root =
  match Pack.read ~root with
  | Error Pack.Unreadable -> None
  | Ok pack -> (
      let contents =
        List.map (fun path -> (path, Pack.content pack (path_of path))) paths
      in
      match Pack.well_named pack with
      | None ->
          Some
            { named = false; files = []; listing = None; hash = None; contents }
      | Some named -> (
          let files = List.map string_of_path (Pack.files named) in
          match Pack.listing named with
          | Error Pack.Unreadable ->
              Some
                { named = true; files; listing = None; hash = None; contents }
          | Ok listing ->
              Some
                {
                  named = true;
                  files;
                  listing = Some (Pack.listing_text listing);
                  hash = Some (Pack.hash listing :> string);
                  contents;
                }))

let in_tree tree action =
  match Files_tree.run tree action with
  | Files_tree.Not_stored reason -> Alcotest.failf "not stored: %s" reason
  | Files_tree.Read { value; changes = [] } -> value
  | Files_tree.Read { changes; _ } ->
      Alcotest.failf "the use of the pack changed the folder tree: %s"
        (String.concat "; " changes)

let use_of_vector (vector : Vectors.vector) =
  match
    in_tree (Files_tree.of_json vector.input) (fun root -> use_pack root)
  with
  | Some use -> use
  | None -> Alcotest.fail "the pack could not be read"

let needs = lazy (Lazy.force Pack_trees.needs)

let unmet_needs (vector : Vectors.vector) =
  List.filter
    (fun need ->
      not (Option.value (List.assoc_opt need (Lazy.force needs)) ~default:true))
    vector.needs

let skipped group =
  List.filter_map
    (fun (vector : Vectors.vector) ->
      match unmet_needs vector with
      | [] -> None
      | needs -> Some (vector.number, needs))
    (Vectors.vectors packs_set group)

let give_well_named vector =
  let use = use_of_vector vector in
  `Assoc
    [
      ("result", `String (if use.named then "well named" else "not well named"));
    ]

(* @verifies packs[well-named-packs][*]=v1
   Each vector makes the folder tree of a pack on the file system, and the test
   compares whether the pack read from it is well named with the result of the
   vector, so a wrong decision on any rule of a well-named pack fails it. *)
let well_named_vectors =
  Vectors.group packs_set ~name:"well-named-packs" ~rev:"v1"
    ~needs:(Lazy.force needs)
    ~skipped:(skipped "well-named-packs")
    give_well_named

let give_pack_hash vector =
  let use = use_of_vector vector in
  match (use.named, use.listing, use.hash) with
  | false, _, _ -> `Assoc [ ("values", `Assoc []) ]
  | true, Some listing, Some hash ->
      `Assoc
        [
          ( "values",
            `Assoc
              [
                ("files", `List (List.map (fun path -> `String path) use.files));
                ("hash", `String hash);
                ("listing", `String listing);
              ] );
        ]
  | true, _, _ -> Alcotest.fail "the well-named pack gave no pack listing"

(* @verifies packs[pack-hashes][*]=v1
   Each vector makes the folder tree of a pack on the file system, and the test
   compares the valid paths of the files, the pack listing, and the pack hash of
   the pack read from it with those of the vector, or with no listing and no
   hash for a pack that is not well named. *)
let pack_hash_vectors =
  Vectors.group packs_set ~name:"pack-hashes" ~rev:"v1"
    ~needs:(Lazy.force needs) ~skipped:(skipped "pack-hashes") give_pack_hash

let reference_use tree paths =
  let named = Pack_reference.well_named tree in
  let files = Pack_reference.files tree in
  {
    named;
    files = (if named then List.map fst files else []);
    listing = Pack_reference.listing tree;
    hash = Pack_reference.hash tree;
    contents =
      List.map
        (fun path ->
          ( path,
            match List.assoc_opt path files with
            | Some content -> Ok content
            | None -> Error Pack.No_file ))
        paths;
  }

let candidate_paths tree =
  List.map fst (Pack_reference.files tree)
  @ [ "pack.toml"; "a"; "d/a"; "missing"; "a/b"; "A"; "\xc3\xa9" ]

(* @verifies packs#{
       decide-well-named-packs=v1, give-pack-files=v1, give-pack-file-contents=v1,
       give-pack-listings=v1, omit-pack-listings=v1, give-pack-hashes=v1,
       omit-pack-hashes=v1, keep-packs-unchanged=v1,
   }
   For generated folder trees with names that break each rule of a well-named
   pack, symbolic links, FIFO special files, and empty folders, a decision, a
   list of files, a content, a pack listing, or a pack hash that differs from a
   direct reading of the terms fails the comparison, and a change to a file of
   the folder tree fails the check after the use. *)
let packs_follow_the_terms =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:300
       ~name:
         "a generated pack gives the decision, the files, their contents, the \
          pack listing, and the pack hash of the terms, and changes no file"
       ~print:Pack_trees.print Pack_trees.tree_gen (fun tree ->
         let paths = candidate_paths tree in
         match Files_tree.run tree (fun root -> use_pack ~paths root) with
         | Files_tree.Not_stored reason ->
             QCheck2.Test.fail_reportf "not stored: %s" reason
         | Files_tree.Read { changes = _ :: _ as changes; _ } ->
             QCheck2.Test.fail_reportf "changed: %s"
               (String.concat "; " changes)
         | Files_tree.Read { value = None; _ } ->
             QCheck2.Test.fail_report "the pack could not be read"
         | Files_tree.Read { value = Some use; changes = [] } ->
             use = reference_use tree paths))

let pack_path_text_gen =
  let char_gen =
    Gen.oneof_weighted
      [
        (10, Gen.map Char.chr (Gen.int_range 0x20 0x7e));
        (3, Gen.oneof_list [ '.'; '/'; 'a' ]);
        (1, Gen.oneof_list [ '\t'; '\n'; '\x7f'; '\\'; '\x00'; '\x01' ]);
      ]
  in
  let ascii =
    Gen.oneof_weighted
      [
        (6, Gen.string_size ~gen:char_gen (Gen.int_range 0 12));
        ( 1,
          Gen.map2
            (fun length suffix -> String.make length 'x' ^ suffix)
            (Gen.int_range 250 260)
            (Gen.oneof_list [ ""; "/a"; "/." ]) );
      ]
  in
  Gen.oneof_weighted
    [
      (8, ascii);
      ( 1,
        Gen.map2 ( ^ ) ascii
          (Gen.oneof_list
             [ "\xc3\xa9"; "\xe2\x80\xa8"; "\xef\xbf\xbd"; "\xc2\x85" ]) );
    ]

let pack_paths_follow_the_production =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:2000
       ~name:"a text is a pack path when, and only when, it matches pack-path"
       ~print:String.escaped pack_path_text_gen (fun text ->
         Pack_path.is_pack_path (text_of text)
         = Pack_reference.is_pack_path text))

let pack_path_edges () =
  List.iter
    (fun (text, expected) ->
      Alcotest.(check bool)
        (Printf.sprintf "%S is a pack path" text)
        expected
        (Pack_path.is_pack_path (text_of text)))
    [
      ("a", true);
      ("...", true);
      (".a", true);
      ("a.", true);
      ("a b/~", true);
      (".", false);
      ("..", false);
      ("a/./b", false);
      ("a/../b", false);
      ("", false);
      ("a/", false);
      ("/a", false);
      ("a//b", false);
      ("a\\b", false);
      ("a\tb", false);
      ("a\x7fb", false);
      ("\xc3\xa9", false);
      (String.make 255 'x', true);
      (String.make 256 'x', false);
      (String.make 127 'x' ^ "/" ^ String.make 127 'y', true);
      (String.make 127 'x' ^ "/" ^ String.make 128 'y', false);
    ]

let every : Files_tree.permissions =
  { read = true; search = true; write = true }

let file kind : Files_tree.file =
  { kind; permissions = every; owned_by_other = false }

let regular = Files_tree.regular
let folder = Files_tree.folder

let well_named_pack_gives_its_pack () =
  let content, files =
    in_tree
      (folder
         [ ("pack.toml", regular "a"); ("d", folder [ ("x", regular "b") ]) ])
      (fun root ->
        match Pack.read ~root with
        | Error Pack.Unreadable -> Alcotest.fail "the pack could not be read"
        | Ok pack -> (
            match Pack.well_named pack with
            | None -> Alcotest.fail "the pack is not well named"
            | Some named ->
                ( Pack.content (Pack.pack named) (path_of "d/x"),
                  List.map string_of_path (Pack.files named) )))
  in
  Alcotest.(check bool) "the content of d/x" true (content = Ok "b");
  Alcotest.(check (list string)) "the files" [ "d/x"; "pack.toml" ] files

let content_of_files_that_are_not_valid_utf_8 () =
  let big =
    String.concat ""
      (List.init 70_000 (fun index -> String.make 1 (Char.chr (index mod 256))))
  in
  let tree =
    folder
      [
        ("pack.toml", regular "");
        ( "bin",
          folder [ ("x.wasm", regular "\x00asm\xff\xfe"); ("big", regular big) ]
        );
        ("l", file (Link "pack.toml"));
        ("p", file Pipe);
        ("e", folder []);
      ]
  in
  let contents =
    in_tree tree (fun root ->
        match Pack.read ~root with
        | Error Pack.Unreadable -> Alcotest.fail "the pack could not be read"
        | Ok pack ->
            List.map
              (fun path -> Pack.content pack (path_of path))
              [
                "pack.toml";
                "bin/x.wasm";
                "bin/big";
                "l";
                "p";
                "e";
                "bin";
                "bin/y";
                "Pack.toml";
              ])
  in
  let expected =
    [
      Ok "";
      Ok "\x00asm\xff\xfe";
      Ok big;
      Error Pack.No_file;
      Error Pack.No_file;
      Error Pack.No_file;
      Error Pack.No_file;
      Error Pack.No_file;
      Error Pack.No_file;
    ]
  in
  Alcotest.(check bool) "the contents" true (contents = expected)

let with_outside action =
  let outside = Filename.temp_dir "sinter-outside-" "" in
  let pipe = Filename.concat outside "p" in
  let secret = Filename.concat outside "secret" in
  Fun.protect
    ~finally:(fun () ->
      Sys.remove pipe;
      Sys.remove secret;
      Unix.rmdir outside)
    (fun () ->
      Unix.mkfifo pipe 0o600;
      Out_channel.with_open_bin secret (fun channel ->
          Out_channel.output_string channel "outside");
      Unix.chmod outside 0o755;
      Unix.chmod pipe 0o666;
      Unix.chmod secret 0o644;
      action outside pipe)

(* @verifies packs#follow-no-pack-links=v1
   A program that found a file by the reference of the symbolic link `out`
   would give the file `out/secret` or open the pipe `out/p` and end the wait of
   its writer; the test checks the files of the pack, the content of
   `out/secret`, and that the writer still waits. *)
let links_lead_to_no_file () =
  with_outside (fun outside pipe ->
      let tree =
        folder
          [
            ("pack.toml", regular "a");
            ("out", file (Link outside));
            ("self", file (Link "."));
            ("up", file (Link ".."));
            ("toml", file (Link "pack.toml"));
          ]
      in
      let use, secret, waiting =
        in_tree tree (fun root ->
            match Unix.fork () with
            | 0 ->
                (try ignore (Unix.openfile pipe [ Unix.O_WRONLY ] 0)
                 with _ -> ());
                Unix._exit 0
            | writer ->
                Fun.protect
                  ~finally:(fun () ->
                    (try Unix.kill writer Sys.sigkill
                     with Unix.Unix_error _ -> ());
                    ignore (Unix.waitpid [] writer))
                  (fun () ->
                    Unix.sleepf 0.2;
                    let use =
                      use_pack ~paths:[ "out/secret"; "out/p"; "toml" ] root
                    in
                    Unix.sleepf 0.1;
                    let pid, _ = Unix.waitpid [ Unix.WNOHANG ] writer in
                    (use, Option.is_some use, pid = 0)))
      in
      ignore secret;
      (match use with
      | None -> Alcotest.fail "the pack could not be read"
      | Some use ->
          Alcotest.(check (list string)) "the files" [ "pack.toml" ] use.files;
          Alcotest.(check bool)
            "the contents" true
            (List.for_all
               (fun (_, content) -> content = Error Pack.No_file)
               use.contents));
      Alcotest.(check bool) "the writer still waits" true waiting)

(* @verifies packs#{read-only-pack-files=v1, avoid-pack-waits=v1}
   A program that took a byte from the pipe `p` leaves the test no byte to
   read from it, and a program that waited for a process to open the other end
   of the pipe `pack.toml` or `d/q` gives no result before the time limit of the
   test. Of read-only-pack-files, the test checks only the data of a file of
   another kind: a program that took the bytes of the reference of a symbolic
   link or of an extended attribute changes nothing that a test can see. *)
let pipes_keep_their_data_and_cause_no_wait () =
  let tree =
    folder
      [
        ("pack.toml", file Pipe);
        ("p", file Pipe);
        ("d", folder [ ("q", file Pipe); ("a", regular "x") ]);
      ]
  in
  let outcome =
    Files_tree.run ~limit:5 tree (fun root ->
        let pipe = Filename.concat root "p" in
        let reader = Unix.openfile pipe [ Unix.O_RDONLY; Unix.O_NONBLOCK ] 0 in
        let writer = Unix.openfile pipe [ Unix.O_WRONLY; Unix.O_NONBLOCK ] 0 in
        Fun.protect
          ~finally:(fun () ->
            Unix.close writer;
            Unix.close reader)
          (fun () ->
            ignore (Unix.write_substring writer "x" 0 1);
            let use = use_pack ~paths:[ "pack.toml"; "p"; "d/q"; "d/a" ] root in
            let buffer = Bytes.create 8 in
            let length = Unix.read reader buffer 0 8 in
            (use, Bytes.sub_string buffer 0 length)))
  in
  match outcome with
  | Files_tree.Not_stored reason -> Alcotest.failf "not stored: %s" reason
  | Files_tree.Read { value = use, data; changes } -> (
      let times_of_p change =
        List.mem change
          [
            "root/p: the time of last change of the data";
            "root/p: the time of last change of the status";
          ]
      in
      Alcotest.(check (list string))
        "the changes other than the times of the pipe that the test wrote" []
        (List.filter (fun change -> not (times_of_p change)) changes);
      Alcotest.(check string) "the data in the pipe" "x" data;
      match use with
      | None -> Alcotest.fail "the pack could not be read"
      | Some use ->
          Alcotest.(check (list string)) "the files" [ "d/a" ] use.files;
          Alcotest.(check bool)
            "the contents" true
            (use.contents
            = [
                ("pack.toml", Error Pack.No_file);
                ("p", Error Pack.No_file);
                ("d/q", Error Pack.No_file);
                ("d/a", Ok "x");
              ]))

let identity () =
  ( Unix.getuid (),
    Unix.geteuid (),
    Unix.getgid (),
    Unix.getegid (),
    List.sort compare (Array.to_list (Unix.getgroups ())) )

(* @verifies packs#{gain-no-pack-privileges=v1, keep-packs-unchanged=v1}
   The process has no permission to list `d`, so a program that gives a
   decision, files, or a listing for this pack took them by a permission that
   it did not have, or gave them wrong; a program that changed the mode of `d`
   or the user IDs or the group IDs of its process fails the check of the
   folder tree or of the IDs after the use. The test cannot see a program that
   used a privilege that its process already had. *)
let folder_with_no_permissions_gives_no_result () =
  let closed : Files_tree.file =
    {
      kind = Folder [ ("secret", regular "s") ];
      permissions = { read = false; search = false; write = true };
      owned_by_other = false;
    }
  in
  let unlisted : Files_tree.file =
    {
      kind = Folder [ ("secret", regular "s") ];
      permissions = { read = false; search = true; write = false };
      owned_by_other = false;
    }
  in
  List.iter
    (fun closed ->
      let read, same =
        in_tree
          (folder [ ("pack.toml", regular "a"); ("d", closed) ])
          (fun root ->
            let before = identity () in
            let read = Pack.read ~root in
            (Result.is_ok read, before = identity ()))
      in
      Alcotest.(check bool) "the pack was read" false read;
      Alcotest.(check bool)
        "the user IDs and the group IDs of the process" true same)
    [ closed; unlisted ]

(* @verifies packs#{gain-no-pack-privileges=v1, keep-packs-unchanged=v1}
   The process has no permission to read `secret`, so a program that gives a
   pack listing for this pack took its content by a permission that it did not
   have; a program that changed the mode of `secret` fails the check of the
   folder tree after the use. The test cannot see a program that used a
   privilege that its process already had. *)
let file_with_no_permission_gives_no_listing () =
  let secret : Files_tree.file =
    {
      kind = Regular [ ("s", 1) ];
      permissions = { read = false; search = true; write = false };
      owned_by_other = false;
    }
  in
  let use, same =
    in_tree
      (folder [ ("pack.toml", regular "a"); ("secret", secret) ])
      (fun root ->
        let before = identity () in
        let use = use_pack ~paths:[ "secret"; "pack.toml" ] root in
        (use, before = identity ()))
  in
  (match use with
  | None -> Alcotest.fail "the pack could not be read"
  | Some use ->
      Alcotest.(check bool) "well named" true use.named;
      Alcotest.(check (list string))
        "the files" [ "pack.toml"; "secret" ] use.files;
      Alcotest.(check (option string)) "the pack listing" None use.listing;
      Alcotest.(check bool)
        "the contents" true
        (use.contents
        = [ ("secret", Error Pack.Unreadable_file); ("pack.toml", Ok "a") ]));
  Alcotest.(check bool)
    "the user IDs and the group IDs of the process" true same

let open_descriptors () = Array.length (Sys.readdir "/dev/fd")

let deep_pack_gives_a_result_or_none () =
  List.iter
    (fun depth ->
      let tree = Pack_trees.deep_tree depth in
      let use, before, after =
        in_tree tree (fun root ->
            let before = open_descriptors () in
            let use = use_pack ~paths:[ "a/f" ] root in
            (use, before, open_descriptors ()))
      in
      Alcotest.(check int) "the open file descriptors" before after;
      match use with
      | None -> ()
      | Some use ->
          Alcotest.(check bool)
            (Printf.sprintf "the use of the pack of depth %d" depth)
            true
            (use = reference_use tree [ "a/f" ]))
    [ 600 ]

let with_flat_pack ~files ~bytes action =
  let root = Filename.temp_dir "sinter-pack-" "" in
  let names = List.init files (fun index -> Printf.sprintf "f%06d" index) in
  Fun.protect
    ~finally:(fun () ->
      List.iter (fun name -> Sys.remove (Filename.concat root name)) names;
      Unix.rmdir root)
    (fun () ->
      List.iter
        (fun name ->
          Out_channel.with_open_bin (Filename.concat root name) (fun channel ->
              Out_channel.output_string channel (String.make bytes 'x')))
        names;
      action root)

let named_pack root =
  match Pack.read ~root with
  | Error Pack.Unreadable -> Alcotest.fail "the pack could not be read"
  | Ok pack -> (
      match Pack.well_named pack with
      | Some named -> named
      | None -> Alcotest.fail "the pack is not well named")

let listing_bytes ~files ~bytes =
  with_flat_pack ~files ~bytes (fun root ->
      let named = named_pack root in
      let before = Gc.allocated_bytes () in
      (match Pack.listing named with
      | Ok listing -> ignore (Sys.opaque_identity (Pack.listing_text listing))
      | Error Pack.Unreadable -> Alcotest.fail "the pack gave no listing");
      Gc.allocated_bytes () -. before)

let check_growth what ~times small large limit =
  let ratio = large /. Float.max small 1e-6 in
  if ratio > limit then
    Alcotest.failf "%s: %d times the input took %.1f times as much (%g and %g)"
      what times ratio small large

let listing_memory_grows_with_the_pack () =
  check_growth "the bytes that the listing of 2,500 and 10,000 files allocates"
    ~times:4
    (listing_bytes ~files:2_500 ~bytes:0)
    (listing_bytes ~files:10_000 ~bytes:0)
    9.;
  check_growth "the bytes that the listing of 8 MB and 32 MB allocates" ~times:4
    (listing_bytes ~files:4 ~bytes:2_000_000)
    (listing_bytes ~files:4 ~bytes:8_000_000)
    9.

module Tree = Sinter_file_read.Tree

let tree_regular name = { Tree.name; file = Tree.Regular_file () }
let tree_folder name entries = { Tree.name; file = Tree.Folder entries }

let paths_of entries =
  Option.map (List.map string_of_path) (Pack.well_named_files entries)

let well_named_files_keep_to_255_characters () =
  List.iter
    (fun (what, entries, expected) ->
      Alcotest.(check (option (list string))) what expected (paths_of entries))
    [
      ( "a root name of 255 bytes",
        [ tree_regular (String.make 255 'x') ],
        Some [ String.make 255 'x' ] );
      ("a root name of 256 bytes", [ tree_regular (String.make 256 'x') ], None);
      ( "a folder of 256 bytes",
        [ tree_folder (String.make 256 'x') [ tree_regular "a" ] ],
        None );
      ( "d/ and 253 bytes",
        [ tree_folder "d" [ tree_regular (String.make 253 'x') ] ],
        Some [ "d/" ^ String.make 253 'x' ] );
      ( "d/ and 254 bytes",
        [ tree_folder "d" [ tree_regular (String.make 254 'x') ] ],
        None );
      ( "a folder of 256 bytes with no regular file",
        [
          tree_folder (String.make 256 'x') [ tree_folder "e" [] ];
          tree_regular "a";
        ],
        Some [ "a" ] );
    ]

let print_unstored tree = Pack_trees.print tree

(* @verifies packs#{decide-well-named-packs=v1, give-pack-files=v1}
   For generated folder trees with names that no one file system stores
   together, such as names that differ only in case, names that are not
   valid UTF-8, and names of more than 255 bytes, a decision or a list of
   files that differs from a direct reading of the terms fails the
   comparison. *)
let well_named_files_follow_the_terms =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:5000
       ~name:
         "the files of a generated folder tree are those of a direct reading \
          of the terms when the pack is well named, and none when it is not"
       ~print:print_unstored Pack_trees.unstored_tree_gen (fun tree ->
         let entries =
           match tree.kind with
           | Folder children ->
               Test_file_read.tree_entries (fun _ -> ()) children
           | _ -> []
         in
         paths_of entries
         =
         if Pack_reference.well_named tree then
           Some (List.map fst (Pack_reference.files tree))
         else None))

let best_time action =
  List.fold_left
    (fun best _ ->
      let start = Unix.gettimeofday () in
      ignore (Sys.opaque_identity (action ()));
      Float.min best (Unix.gettimeofday () -. start))
    infinity [ 1; 2; 3 ]

let flat count =
  List.init count (fun index -> tree_regular (Printf.sprintf "f%06d" index))

let chain count =
  let rec go entries count =
    if count = 0 then entries else go [ tree_folder "a" entries ] (count - 1)
  in
  go [ tree_regular "f" ] count

let spread count =
  List.init count (fun index ->
      tree_folder (Printf.sprintf "d%06d" index) [ tree_regular "f" ])

let decision_time_grows_with_n_log_n () =
  List.iter
    (fun (what, make) ->
      check_growth what ~times:8
        (let entries = make 40_000 in
         best_time (fun () -> Pack.well_named_files entries))
        (let entries = make 320_000 in
         best_time (fun () -> Pack.well_named_files entries))
        24.)
    [
      ("the decision on 40,000 and 320,000 files in one folder", flat);
      ("the decision on 40,000 and 320,000 nested folders", chain);
      ("the decision on 40,000 and 320,000 folders of one file each", spread);
    ]

let changed_tree_gives_no_listing () =
  List.iter
    (fun (what, change) ->
      with_flat_pack ~files:2 ~bytes:1 (fun root ->
          let named = named_pack root in
          let added = Filename.concat root (change ()) in
          Fun.protect
            ~finally:(fun () -> Sys.remove added)
            (fun () ->
              Out_channel.with_open_bin added (fun channel ->
                  Out_channel.output_string channel "x");
              match Pack.listing named with
              | Error Pack.Unreadable -> ()
              | Ok _ -> Alcotest.failf "a listing after %s" what)))
    [
      ("a file was added", fun () -> "g");
      ("a file whose path is no pack path was added", fun () -> "a\\b");
    ]

let tests =
  Vectors.tests "packs" [ well_named_vectors; pack_hash_vectors ]
  @ [
      packs_follow_the_terms;
      pack_paths_follow_the_production;
      Alcotest.test_case "the edges of pack paths" `Quick pack_path_edges;
      Alcotest.test_case "a well-named pack gives its pack" `Quick
        well_named_pack_gives_its_pack;
      Alcotest.test_case "a pack gives contents that are not valid UTF-8" `Quick
        content_of_files_that_are_not_valid_utf_8;
      Alcotest.test_case "a symbolic link of a pack leads to no file" `Quick
        links_lead_to_no_file;
      Alcotest.test_case "a pipe of a pack keeps its data and causes no wait"
        `Quick pipes_keep_their_data_and_cause_no_wait;
      Alcotest.test_case "a folder with no permissions gives no pack" `Quick
        folder_with_no_permissions_gives_no_result;
      Alcotest.test_case "a file with no read permission gives no pack listing"
        `Quick file_with_no_permission_gives_no_listing;
      Alcotest.test_case "a deep pack gives the result of the terms or none"
        `Quick deep_pack_gives_a_result_or_none;
      Alcotest.test_case "a folder tree that changed gives no listing" `Quick
        changed_tree_gives_no_listing;
      Alcotest.test_case "the memory of a listing grows with the pack" `Quick
        listing_memory_grows_with_the_pack;
      Alcotest.test_case "the files of a well-named pack keep to 255 characters"
        `Quick well_named_files_keep_to_255_characters;
      well_named_files_follow_the_terms;
      Alcotest.test_case "the time of a decision grows with n log n" `Quick
        decision_time_grows_with_n_log_n;
    ]
