(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen
module Model = Changes_model
module Path = Sinter_paths.Path
module Tree = Sinter_tree.Tree
module Line_map = Sinter_line_maps.Line_map
module Graph = Sinter_commit_graphs.Commit_graph.Make (String)
module Ref_commit = Sinter_git_model.Ref_commit
module Default_branch = Sinter_git_model.Default_branch
module Message = Sinter_git_model.Message
module Commit_files = Sinter_git_model.Commit_files
module Change_diff = Sinter_git_model.Change_diff

let set = Vectors.read "changes"

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

let required name json =
  match member name json with
  | Some value -> value
  | None -> Alcotest.failf "no member %s" name

let name_of = function
  | `String name -> name
  | other -> Alcotest.failf "not a name: %s" (Yojson.Basic.to_string other)

let names list = `List (List.map (fun name -> `String name) list)
let values members = `Assoc [ ("values", `Assoc members) ]

let ok = function
  | Ok value -> value
  | Error () -> Alcotest.fail "the refs gave no error"

let commit_or_none = function
  | Some commit -> values [ ("commit", `String commit) ]
  | None -> values []

let text_of bytes =
  match Text.decode bytes with
  | Ok text -> text
  | Error _ -> Alcotest.failf "%S is not valid UTF-8" bytes

let path_of bytes =
  match Path.of_text (text_of bytes) with
  | Ok path -> path
  | Error _ -> Alcotest.failf "%S is not a valid path" bytes

let path_bytes path = Text.encode (Path.to_text path)

let refs_of_list list : (string, unit) Ref_commit.refs =
 fun name -> Ok (List.assoc_opt name list)

let give_ref_commit (vector : Vectors.vector) =
  let refs =
    match required "refs" vector.input with
    | `Assoc refs ->
        List.map
          (fun (name, target) ->
            ( name,
              match target with
              | `Assoc [ ("commit", `String c) ] -> Ref_commit.Commit c
              | `Assoc [ ("ref", `String r) ] -> Ref_commit.Ref r
              | `Assoc [ ("other", `String _) ] -> Ref_commit.Other
              | `Assoc [] -> Ref_commit.Broken
              | other ->
                  Alcotest.failf "not a target: %s"
                    (Yojson.Basic.to_string other) ))
          refs
    | other -> Alcotest.failf "not refs: %s" (Yojson.Basic.to_string other)
  in
  commit_or_none
    (ok
       (Ref_commit.commit (refs_of_list refs)
          (name_of (required "ref" vector.input))))

(* @verifies changes[ref-commits][*]=v1
   Each vector gives the refs of a repository and a ref, through symbolic refs
   in turn, to a commit, to another git object, to a broken loose ref, or to
   no ref; a program that stops at the first symbolic ref, or takes another
   object as a commit, gives another commit. *)
let ref_commit_vectors =
  Vectors.group set ~name:"ref-commits" ~rev:"v1" give_ref_commit

let give_head_commit (vector : Vectors.vector) =
  let refs =
    match required "refs" vector.input with
    | `Assoc refs ->
        List.map (fun (name, c) -> (name, Ref_commit.Commit (name_of c))) refs
    | other -> Alcotest.failf "not refs: %s" (Yojson.Basic.to_string other)
  in
  let head = required "head" vector.input in
  let head =
    match (member "ref" head, member "commit" head) with
    | Some name, None -> Ref_commit.Ref (name_of name)
    | None, Some commit -> Ref_commit.Commit (name_of commit)
    | _ -> Alcotest.fail "not a HEAD"
  in
  commit_or_none (ok (Ref_commit.head_commit (refs_of_list refs) head))

(* @verifies changes[head-commits][*]=v1
   Each vector gives a HEAD that names a ref or is detached, and the refs; a
   program that reads a detached HEAD as a ref, or gives a commit for a branch
   that does not exist, gives another head commit. *)
let head_commit_vectors =
  Vectors.group set ~name:"head-commits" ~rev:"v1" give_head_commit

let upstream_name = "refs/remotes/upstream/the-branch"

let default_commit ~binding ~upstream ~local ~remote =
  let target = function
    | Some commit -> Ref_commit.Commit commit
    | None -> Ref_commit.Other
  in
  let refs =
    List.filter_map
      (fun (name, ref_) ->
        Option.map (fun commit -> (name, target commit)) ref_)
      [
        (upstream_name, upstream);
        ("refs/heads/" ^ binding, local);
        ("refs/remotes/origin/" ^ binding, remote);
      ]
  in
  let upstream_of _ =
    Ok (if Option.is_some upstream then Some upstream_name else None)
  in
  ok
    (Default_branch.commit ~upstream:upstream_of ~refs:(refs_of_list refs)
       (text_of binding))

let give_default_branch (vector : Vectors.vector) =
  let ref_ name =
    match member name vector.input with
    | None -> None
    | Some (`String commit) -> Some (Some commit)
    | Some (`Assoc []) -> Some None
    | Some other ->
        Alcotest.failf "not a commit: %s" (Yojson.Basic.to_string other)
  in
  commit_or_none
    (default_commit
       ~binding:(name_of (required "binding" vector.input))
       ~upstream:(ref_ "upstream") ~local:(ref_ "local") ~remote:(ref_ "remote"))

(* @verifies changes[default-branch-commits][*]=v1
   Each vector gives a binding and which of the three refs exist, with their
   commits; a program that takes the refs in another order, skips a ref that
   exists with no commit, or takes a binding that is not a branch name, gives
   another commit. *)
let default_branch_vectors =
  Vectors.group set ~name:"default-branch-commits" ~rev:"v1" give_default_branch

let give_message (vector : Vectors.vector) =
  match Message.text (Model.bytes_of_json vector.input) with
  | Some text -> values [ ("text", `String (Text.encode text)) ]
  | None -> values []

(* @verifies changes[message-texts][*]=v1
   Each vector gives the content of a commit object and the text of its
   message, or none; a program that ends the header at a line of one space,
   drops a carriage return or U+FEFF, or follows the header `encoding`, gives
   another text. *)
let message_vectors =
  Vectors.group set ~name:"message-texts" ~rev:"v1" give_message

let rec entries_under prefix (entries : Model.entry list) =
  List.map
    (fun (entry : Model.entry) ->
      match Commit_files.kind entry.mode with
      | Commit_files.Tree_entry ->
          Commit_files.Tree
            {
              name = entry.name;
              entries = entries_under (prefix ^ entry.name ^ "/") entry.entries;
            }
      | Commit_files.Regular_file_entry ->
          Commit_files.Regular_file
            { name = entry.name; blob = prefix ^ entry.name }
      | Commit_files.Symbolic_link_entry | Commit_files.Submodule_entry ->
          Commit_files.Other { name = entry.name })
    entries

let library_entries entries = entries_under "" entries

let rec entries_of_json = function
  | `List entries ->
      List.map
        (fun entry ->
          {
            Model.name = Model.bytes_of_json (required "name" entry);
            mode = name_of (required "mode" entry);
            entries =
              (match member "entries" entry with
              | Some nested -> entries_of_json nested
              | None -> []);
          })
        entries
  | other -> Alcotest.failf "not entries: %s" (Yojson.Basic.to_string other)

let paths_of_files files =
  List.sort String.compare (List.map (fun (path, _) -> path_bytes path) files)

let valid_path_of bytes =
  match Text.decode bytes with
  | Error _ -> None
  | Ok text -> Result.to_option (Path.of_text text)

let lookup_agrees entries candidates =
  let library = library_entries entries in
  let expected = Model.commit_files entries in
  List.for_all
    (fun bytes ->
      match valid_path_of bytes with
      | None -> true
      | Some path ->
          Commit_files.file library path
          = if List.mem bytes expected then Some bytes else None)
    candidates

let give_commit_files (vector : Vectors.vector) =
  let entries = entries_of_json (required "entries" vector.input) in
  let paths = paths_of_files (Commit_files.files (library_entries entries)) in
  let found =
    List.filter
      (fun bytes ->
        match valid_path_of bytes with
        | Some path -> Commit_files.file (library_entries entries) path <> None
        | None -> false)
      (List.sort_uniq String.compare (paths @ Model.entry_byte_paths entries))
  in
  if found <> paths then
    Alcotest.failf "the lookup finds %s, and the files are %s"
      (String.concat ", " found) (String.concat ", " paths);
  values [ ("paths", names paths) ]

(* @verifies changes[commit-files][*]=v1
   Each vector gives the entries of the git tree object of a commit, nested,
   and the valid paths of its files; a program that gives a file for a
   symbolic link, a submodule, a mode that is no number in base 8, a name that
   is no file name or not UTF-8, or an entry whose byte path repeats, gives
   other paths. The lookup of each byte path of the entries must find a file
   exactly for those paths. *)
let commit_file_vectors =
  Vectors.group set ~name:"commit-files" ~rev:"v1" give_commit_files

let tree_of json =
  match json with
  | `Assoc files -> (
      match
        Tree.of_files
          (List.map
             (fun (path, content) ->
               (path_of path, Model.bytes_of_json content))
             files)
      with
      | Ok tree -> tree
      | Error _ -> Alcotest.fail "two files with one valid path")
  | other -> Alcotest.failf "not a tree: %s" (Yojson.Basic.to_string other)

let hunk_json (hunk : Line_map.hunk) =
  `Assoc
    [
      ("added", `Int hunk.added);
      ("new-start", `Int hunk.new_start);
      ("old-start", `Int hunk.old_start);
      ("removed", `Int hunk.removed);
    ]

let give_change_diff (vector : Vectors.vector) =
  let model = Model.graph_of_json (required "commits" vector.input) in
  let graph : unit Graph.graph = fun c -> Ok (Model.parents model c) in
  let h = name_of (required "last" vector.input) in
  let d = name_of (required "default" vector.input) in
  let trees = required "trees" vector.input in
  let base =
    match Graph.change_base graph ~default:(Some d) h with
    | Ok base -> Option.map (fun b -> tree_of (required b trees)) base
    | Error () -> Alcotest.fail "the graph gave no error"
  in
  match Change_diff.of_trees ~base (tree_of (required h trees)) with
  | None -> values []
  | Some diff ->
      values
        [
          ( "diff",
            `List
              (List.map
                 (fun (path, map) ->
                   `Assoc
                     [
                       ("hunks", `List (List.map hunk_json (Line_map.hunks map)));
                       ("path", `String (path_bytes path));
                     ])
                 diff) );
        ]

(* @verifies changes[change-diffs][*]=v1
   Each vector gives a commit graph with the tree of each commit, and the diff
   of the change of a commit from the tree of its base, or no diff when there
   is no base; a diff from the commit of the default branch, or a diff when the
   merge bases cross, fails. *)
let change_diff_vectors =
  Vectors.group set ~name:"change-diffs" ~rev:"v1" give_change_diff

let property ?(count = 1000) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let ref_names = [ "refs/heads/a"; "refs/heads/b"; "refs/tags/t"; "HEAD"; "x" ]

let target_gen =
  Gen.oneof_weighted
    [
      (2, Gen.map (fun c -> Model.Commit c) (Gen.oneof_list [ "c1"; "c2" ]));
      (1, Gen.return (Model.Other "o"));
      (1, Gen.return Model.Broken);
      (3, Gen.map (fun r -> Model.Names r) (Gen.oneof_list ref_names));
    ]

let refs_gen =
  Gen.map
    (fun targets ->
      List.filter_map
        (fun (name, target) -> Option.map (fun t -> (name, t)) target)
        (List.combine ref_names targets))
    (Gen.flatten_list
       (List.map (fun _ -> Gen.option ~ratio:0.7 target_gen) ref_names))

let print_refs refs =
  String.concat ", "
    (List.map
       (fun (name, target) ->
         name ^ " -> "
         ^
         match target with
         | Model.Commit c -> "commit " ^ c
         | Model.Names r -> "ref " ^ r
         | Model.Other o -> "other " ^ o
         | Model.Broken -> "broken")
       refs)

let library_target = function
  | Model.Commit c -> Ref_commit.Commit c
  | Model.Names r -> Ref_commit.Ref r
  | Model.Other _ -> Ref_commit.Other
  | Model.Broken -> Ref_commit.Broken

let library_refs refs =
  refs_of_list (List.map (fun (name, t) -> (name, library_target t)) refs)

(* @verifies changes#give-ref-commits=v1
   For generated refs, with symbolic refs that name each other in turn, in a
   cycle, or nothing, the commit must be the commit to which the ref resolves,
   and none when it resolves to no commit, as through a broken loose ref; a
   stop at a symbolic ref, a commit through a cycle, or a commit for another
   object fails. *)
let ref_commits_follow_the_term =
  property ~name:"the commit of a ref is the commit to which it resolves"
    ~print:print_refs refs_gen (fun refs ->
      List.for_all
        (fun name ->
          ok (Ref_commit.commit (library_refs refs) name)
          = Model.ref_commit refs name)
        ("missing" :: ref_names))

(* @verifies changes#give-head-commits=v1
   For generated refs and each form of HEAD, the head commit must be the
   commit of HEAD: the commit of the ref that it names, or the commit that a
   detached HEAD points to, and none for a HEAD that points to another
   object; another commit fails. *)
let head_commits_follow_the_term =
  property ~name:"the head commit is the commit of HEAD" ~print:print_refs
    refs_gen (fun refs ->
      let head_of head = ok (Ref_commit.head_commit (library_refs refs) head) in
      List.for_all
        (fun name -> head_of (Ref_commit.Ref name) = Model.ref_commit refs name)
        ("missing" :: ref_names)
      && head_of (Ref_commit.Commit "c9") = Some "c9"
      && head_of Ref_commit.Other = None
      && head_of Ref_commit.Broken = None)

let errors_of_the_refs_come_back () =
  let refs : (string, string) Ref_commit.refs = function
    | "refs/heads/a" -> Ok (Some (Ref_commit.Ref "refs/heads/b"))
    | name -> Error name
  in
  Alcotest.(check (result (option string) string))
    "a ref" (Error "refs/heads/b")
    (Ref_commit.commit refs "refs/heads/a");
  Alcotest.(check (result (option string) string))
    "HEAD" (Error "refs/heads/b")
    (Ref_commit.head_commit refs (Ref_commit.Ref "refs/heads/a"));
  Alcotest.(check (result (option string) string))
    "a ref of the default branch" (Error "refs/heads/main")
    (Default_branch.commit ~upstream:(fun _ -> Ok None) ~refs (text_of "main"));
  Alcotest.(check (result (option string) string))
    "an upstream" (Error "upstream")
    (Default_branch.commit
       ~upstream:(fun _ -> Error "upstream")
       ~refs (text_of "main"))

let a_long_chain_of_symbolic_refs () =
  let length = 200_000 in
  let refs : (int, unit) Ref_commit.refs =
   fun name ->
    match int_of_string_opt name with
    | Some 0 -> Ok (Some (Ref_commit.Commit 0))
    | Some k when k > 0 && k <= length ->
        Ok (Some (Ref_commit.Ref (string_of_int (k - 1))))
    | _ -> Ok None
  in
  let before = Gc.get () in
  Gc.set { before with stack_limit = 1 lsl 16 };
  let result =
    Fun.protect
      ~finally:(fun () -> Gc.set before)
      (fun () -> Ref_commit.commit refs (string_of_int length))
  in
  Alcotest.(check (result (option int) unit)) "the commit" (Ok (Some 0)) result

let existence_gen =
  Gen.oneof_weighted
    [
      (2, Gen.return None);
      (1, Gen.return (Some None));
      (2, Gen.map (fun c -> Some (Some c)) (Gen.oneof_list [ "u"; "l"; "r" ]));
    ]

let default_gen =
  Gen.(
    quad
      (oneof_weighted
         [
           (3, oneof_list [ "main"; "release/2.0"; "@" ]);
           (2, Model.branch_name_gen);
         ])
      existence_gen existence_gen existence_gen)

let print_default (binding, upstream, local, remote) =
  let show = function
    | None -> "absent"
    | Some None -> "no commit"
    | Some (Some c) -> c
  in
  Printf.sprintf "%S upstream %s, local %s, remote %s" binding (show upstream)
    (show local) (show remote)

(* @verifies changes#give-default-branch-commits=v1
   For generated bindings, branch names or not, and each way in which each of
   the three refs exists or not, the commit must be the commit of the first
   that exists, and none for a binding that is not a branch name; another
   order of the refs, or a skip of a ref with no commit, fails. *)
let default_branch_follows_the_term =
  property ~name:"the commit of the default branch is that of the first ref"
    ~print:print_default default_gen (fun (binding, upstream, local, remote) ->
      String.is_valid_utf_8 binding
      && default_commit ~binding ~upstream ~local ~remote
         = Model.default_branch_commit ~binding ~upstream ~local ~remote)

let an_upstream_that_does_not_exist_is_skipped () =
  let refs = refs_of_list [ ("refs/heads/main", Ref_commit.Commit "l") ] in
  Alcotest.(check (result (option string) unit))
    "the local branch" (Ok (Some "l"))
    (Default_branch.commit
       ~upstream:(fun _ -> Ok (Some "refs/remotes/origin/gone"))
       ~refs (text_of "main"))

let a_broken_ref_of_the_default_branch_decides () =
  let refs =
    refs_of_list
      [
        ("refs/heads/main", Ref_commit.Broken);
        ("refs/remotes/origin/main", Ref_commit.Commit "r");
      ]
  in
  Alcotest.(check (result (option string) unit))
    "no commit" (Ok None)
    (Default_branch.commit ~upstream:(fun _ -> Ok None) ~refs (text_of "main"))

let the_upstream_takes_the_branch_name () =
  let seen = ref [] in
  let upstream name =
    seen := Text.encode (Sinter_branch_names.Branch_name.to_text name) :: !seen;
    Ok None
  in
  ignore
    (Default_branch.commit ~upstream ~refs:(refs_of_list [])
       (text_of "release/2.0"));
  Alcotest.(check (list string)) "the names" [ "release/2.0" ] !seen

let header =
  "tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904\n\
   author A <a@example.invalid> 1 +0000\n"

let content_gen =
  let piece =
    Gen.oneof_list
      [
        "a";
        "\n";
        "\n\n";
        " \n";
        "\r\n";
        "\xef\xbb\xbf";
        "\xc3\xa9";
        "\xff";
        "encoding ISO-8859-1\n";
      ]
  in
  Gen.oneof_weighted
    [
      ( 3,
        Gen.map
          (fun pieces -> header ^ String.concat "" pieces)
          (Gen.list_size (Gen.int_range 0 8) piece) );
      (1, Gen.map (String.concat "") (Gen.list_size (Gen.int_range 0 8) piece));
      (1, Gen.string_size (Gen.int_range 0 20));
    ]

(* @verifies changes#give-message-texts=v1
   For generated commit objects, the text must be the bytes after the first
   two line feeds that follow one another when they are valid UTF-8, and none
   otherwise; a later empty line, a dropped byte order mark or carriage
   return, or a text for bytes that are not UTF-8 fails. *)
let message_texts_follow_the_term =
  property ~name:"the text of a message is its bytes when they are UTF-8"
    ~print:(Printf.sprintf "%S") content_gen (fun content ->
      Option.map Text.encode (Message.text content) = Model.message_text content
      && Message.message content = Model.message content)

let messages_take_corrupted_contents =
  property ~count:2000 ~name:"message and text take corrupted commit objects"
    ~print:(Printf.sprintf "%S")
    (Vector_json.corrupt_gen (header ^ "\nSubject\n\nBody \xc3\xa9\n"))
    (fun content ->
      Option.map Text.encode (Message.text content) = Model.message_text content
      && Message.message content = Model.message content)

let mode_gen =
  Gen.oneof_weighted
    [
      ( 4,
        Gen.oneof_list
          [
            "40000";
            "040000";
            "100644";
            "100755";
            "100600";
            "120000";
            "160000";
            "170000";
            "0";
            "7777";
            "10000";
            "00000000000000000000100644";
          ] );
      ( 2,
        Gen.string_size
          ~gen:(Gen.oneof_list [ '0'; '1'; '2'; '4'; '7' ])
          (Gen.int_range 0 30) );
      ( 1,
        Gen.string_size
          ~gen:(Gen.oneof_list [ '0'; '1'; '4'; '8'; '9'; ' '; '\x00'; 'a' ])
          (Gen.int_range 0 8) );
    ]

let kind_of_model = function
  | Model.Tree_kind -> Commit_files.Tree_entry
  | Model.Regular_file_kind -> Commit_files.Regular_file_entry
  | Model.Symbolic_link_kind -> Commit_files.Symbolic_link_entry
  | Model.Submodule_kind -> Commit_files.Submodule_entry

(* @verifies changes#give-commit-files=v1
   For generated modes of any length, leading zeros included, the type of an
   entry must follow the quotient of the mode by 4096: 4, 8, 10, or another,
   and a mode that is empty or holds a byte that is no digit of base 8 must
   give a submodule entry; a mode read in base 10, cut to a fixed number of
   digits, or read up to its first byte that is no digit, gives another
   type. *)
let kinds_follow_the_mode =
  property ~count:2000
    ~name:"the type of an entry follows its mode divided by 4096"
    ~print:(Printf.sprintf "%S") mode_gen (fun mode ->
      Commit_files.kind mode = kind_of_model (Model.entry_kind mode))

let kind_takes_any_bytes =
  property ~count:2000 ~name:"kind takes any bytes" ~print:(Printf.sprintf "%S")
    (Gen.string_size (Gen.int_range 0 12))
    (fun mode -> Commit_files.kind mode = kind_of_model (Model.entry_kind mode))

(* @verifies changes#give-commit-files=v1
   For generated nested entries, with names that repeat, hold `/`, are no file
   names, or are not UTF-8, the files must be the regular-file entries whose
   byte paths are valid paths that no other entry has, each with its own
   blob; a file for a repeated byte path or for another type fails. *)
let files_follow_the_term =
  property
    ~name:
      "the files of a commit are its regular-file entries with unique valid \
       paths" ~print:Model.print_entries Model.entries_gen (fun entries ->
      let files = Commit_files.files (library_entries entries) in
      paths_of_files files = Model.commit_files entries
      && List.length files = List.length (Model.commit_files entries)
      && List.for_all
           (fun (path, blob) -> String.equal blob (path_bytes path))
           files)

let candidate_paths =
  let names = [ "a"; "b"; "a.md"; "..."; "\xc3\xa9" ] in
  let longer paths =
    List.concat_map (fun path -> List.map (fun n -> path ^ "/" ^ n) names) paths
  in
  names @ longer names @ longer (longer names)

(* @verifies changes#give-commit-file-at-path=v1
   For generated nested entries and each valid path of up to three file names
   over their names, with each byte path of the entries, the lookup must give
   the file, with its own blob, when the tree has a file with that valid path,
   and none when it has none; a file for a repeated byte path, for another
   type, or for a path under a regular-file entry fails, and so does a missed
   file whose name holds `/`. *)
let file_at_a_path_follows_the_term =
  property
    ~name:"the file at a valid path is the file of the tree with that path"
    ~print:Model.print_entries Model.entries_gen (fun entries ->
      lookup_agrees entries (candidate_paths @ Model.entry_byte_paths entries))

let file_agrees_with_files =
  property ~name:"file gives a blob exactly for the valid paths of files"
    ~print:Model.print_entries Model.entries_gen (fun entries ->
      let library = library_entries entries in
      List.for_all
        (fun (path, blob) -> Commit_files.file library path = Some blob)
        (Commit_files.files library))

let deep_entries () =
  let depth = 20_000 in
  let rec build k acc =
    if k = 0 then acc
    else build (k - 1) [ Commit_files.Tree { name = "d"; entries = acc } ]
  in
  let entries =
    build depth [ Commit_files.Regular_file { name = "f"; blob = () } ]
  in
  let before = Gc.get () in
  Gc.set { before with stack_limit = 1 lsl 15 };
  let files =
    Fun.protect
      ~finally:(fun () -> Gc.set before)
      (fun () -> Commit_files.files entries)
  in
  Alcotest.(check int) "one file" 1 (List.length files);
  match files with
  | [ (path, ()) ] ->
      let found =
        Gc.set { before with stack_limit = 1 lsl 15 };
        Fun.protect
          ~finally:(fun () -> Gc.set before)
          (fun () -> Commit_files.file entries path)
      in
      Alcotest.(check bool) "the lookup finds it" true (found = Some ());
      Alcotest.(check int)
        "its file names" (depth + 1)
        (List.length (Path.file_names path))
  | _ -> Alcotest.fail "not one file"

let a_deep_chain_of_names_that_are_not_utf_8 () =
  let depth = 200_000 in
  let rec build k acc =
    if k = 0 then acc
    else
      build (k - 1)
        [
          Commit_files.Regular_file { name = "\xff"; blob = () };
          Commit_files.Tree { name = "d"; entries = acc };
        ]
  in
  Alcotest.(check int)
    "no file" 0
    (List.length (Commit_files.files (build depth [])))

let tree_gen =
  Gen.map
    (fun files ->
      List.sort_uniq
        (fun (a, _) (b, _) -> String.compare a b)
        (List.filter_map
           (fun (path, content) -> Option.map (fun c -> (path, c)) content)
           files))
    (Gen.list_size (Gen.int_range 0 5)
       (Gen.pair
          (Gen.oneof_list [ "a.md"; "b.md"; "d/c.md"; "d/e"; "\xc3\xa9" ])
          Model.content_gen))

let library_tree files =
  match
    Tree.of_files
      (List.map (fun (path, content) -> (path_of path, content)) files)
  with
  | Ok tree -> tree
  | Error _ -> Alcotest.fail "two files with one valid path"

let print_trees (base, last) =
  let show files =
    String.concat ", "
      (List.map (fun (p, c) -> p ^ " = " ^ Model.print_content (Some c)) files)
  in
  Printf.sprintf "base: %s; last: %s" (show base) (show last)

(* @verifies changes#give-change-diffs=v1
   For generated base and last trees, the diff must hold each valid path that
   has a hunk between them, with a line map of its two contents, in code point
   order, and no other path; and no diff without a base. A missed added or
   removed file, a path with no hunk, or a map that is not longest fails. *)
let change_diffs_follow_the_term =
  property ~name:"the diff holds each valid path that has a hunk"
    ~print:print_trees (Gen.pair tree_gen tree_gen) (fun (base, last) ->
      let paths =
        List.sort_uniq String.compare (List.map fst base @ List.map fst last)
      in
      let expected =
        List.filter
          (fun path ->
            let old_content = List.assoc_opt path base in
            let new_content = List.assoc_opt path last in
            let o = Option.value ~default:[] (Model.line_texts old_content) in
            let n = Option.value ~default:[] (Model.line_texts new_content) in
            Model.hunks ~old_content ~new_content (Model.a_line_map o n) <> [])
          paths
      in
      Change_diff.of_trees ~base:None (library_tree last) = None
      &&
      match
        Change_diff.of_trees
          ~base:(Some (library_tree base))
          (library_tree last)
      with
      | None -> false
      | Some diff ->
          List.map (fun (path, _) -> path_bytes path) diff = expected
          && List.for_all
               (fun (path, map) ->
                 let old_content = List.assoc_opt (path_bytes path) base in
                 let new_content = List.assoc_opt (path_bytes path) last in
                 let o =
                   Option.value ~default:[] (Model.line_texts old_content)
                 in
                 let n =
                   Option.value ~default:[] (Model.line_texts new_content)
                 in
                 let pairs = Line_map.pairs map in
                 Model.is_map o n pairs
                 && List.length pairs = Model.longest_by_table o n
                 && List.map
                      (fun (h : Line_map.hunk) ->
                        {
                          Model.old_start = h.old_start;
                          removed = h.removed;
                          new_start = h.new_start;
                          added = h.added;
                        })
                      (Line_map.hunks map)
                    = Model.hunks ~old_content ~new_content pairs)
               diff)

let vector_groups =
  [
    ref_commit_vectors;
    head_commit_vectors;
    default_branch_vectors;
    message_vectors;
    commit_file_vectors;
    change_diff_vectors;
  ]

let tests =
  Vectors.tests "changes" vector_groups
  @ [
      ref_commits_follow_the_term;
      head_commits_follow_the_term;
      Alcotest.test_case "the errors of the refs come back" `Quick
        errors_of_the_refs_come_back;
      Alcotest.test_case
        "a chain of 200,000 symbolic refs on a stack of 512 KiB" `Quick
        a_long_chain_of_symbolic_refs;
      default_branch_follows_the_term;
      Alcotest.test_case "an upstream that does not exist is skipped" `Quick
        an_upstream_that_does_not_exist_is_skipped;
      Alcotest.test_case "a broken ref of the default branch decides" `Quick
        a_broken_ref_of_the_default_branch_decides;
      Alcotest.test_case "the upstream takes the branch name" `Quick
        the_upstream_takes_the_branch_name;
      message_texts_follow_the_term;
      messages_take_corrupted_contents;
      kinds_follow_the_mode;
      kind_takes_any_bytes;
      files_follow_the_term;
      file_at_a_path_follows_the_term;
      file_agrees_with_files;
      Alcotest.test_case "entries nested 20,000 deep on a stack of 256 KiB"
        `Quick deep_entries;
      change_diffs_follow_the_term;
      Alcotest.test_case
        "a chain of 200,000 tree entries with names that are not UTF-8 gives \
         no file"
        `Quick a_deep_chain_of_names_that_are_not_utf_8;
    ]
