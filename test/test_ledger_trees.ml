(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_lines
open Sinter_ledger_trees
module Gen = QCheck2.Gen
module Model = Ledger_model
module Lv = Ledger_vectors
module V = Vector_json
module Store = Ledger_store
module T = Ledger_tree.Make (String)

type store = {
  s : Store.t;
  root_id : string;
  ledger_ids : string list;
  other_blob_ids : string list;
}

let commit_id = "c"
let is_tree mode = Changes_model.entry_kind mode = Changes_model.Tree_kind

let is_regular mode =
  Changes_model.entry_kind mode = Changes_model.Regular_file_kind

let store_of_tree (tree : Model.entry list) =
  let s = Store.create () in
  Store.add_commit s commit_id { Model.parents = []; tree };
  {
    s;
    root_id = Store.add_tree s tree;
    ledger_ids = Store.ledger_object_ids s commit_id;
    other_blob_ids = Store.other_blob_ids s commit_id;
  }

let of_root s root_id =
  Store.add_commit_object s commit_id [] root_id;
  { s; root_id; ledger_ids = []; other_blob_ids = [] }

let objects ?fail store = Store.objects ?fail store.s
let ids_of stored = List.map Entry.id (Ledger_tree.Stored_ledger.entries stored)

let answer = function
  | Ok (Ledger_tree.Valid stored) -> ("valid", Some (ids_of stored))
  | Ok Ledger_tree.Broken -> ("broken", None)
  | Ok Ledger_tree.Newer -> ("newer", None)
  | Error e -> Alcotest.failf "no result: %s" e

let give_ledger (vector : Vectors.vector) =
  let result, ledger =
    match Lv.ref_of_input vector.input with
    | Lv.No_ref ->
        answer (T.validity (objects (store_of_tree [])) Ledger_objects.Absent)
    | Lv.Other _ ->
        answer
          (T.validity (objects (store_of_tree [])) Ledger_objects.No_commit)
    | Lv.Entries tree ->
        answer
          (T.validity
             (objects (store_of_tree tree))
             (Ledger_objects.Commit commit_id))
  in
  Lv.ledger_answer ~result ~ledger

(* @verifies ledger[ledgers][*]=v1
   Each vector gives a ledger ref, the git tree object of its ledger commit,
   and whether the ledger is valid, broken, or newer, with the ids of the
   stored ledger in their order; a wrong condition, a missed or extra entry, or
   another order fails. The blob of each entry that is not a chunk fails to
   read, so a program that reads a git object that is no ledger object also
   fails. *)
let ledger_vectors =
  Vectors.group Lv.set ~name:"ledgers" ~form:"#ledger-vector=v1" give_ledger

let property ?(count = 300) ~name generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print:Model.print_tree generator check)

let valid_gen = Gen.(Model.ledger_lines_gen >>= Model.layout_gen)

let tree_gen =
  Gen.(
    oneof_weighted
      [
        (1, valid_gen);
        (3, valid_gen >>= Model.damage_gen);
        (1, valid_gen >>= Model.damage_gen >>= Model.damage_gen);
      ])

let reference tree = Model.validity (Model.Commit_tree tree)

let agrees tree result =
  match (reference tree, result) with
  | Model.Valid, Ok (Ledger_tree.Valid stored) ->
      Model.stored_ledger (Model.Commit_tree tree) = Some (ids_of stored)
  | Model.Broken, Ok Ledger_tree.Broken | Model.Newer, Ok Ledger_tree.Newer ->
      true
  | _ -> false

let sorted_unique lines = List.sort_uniq String.compare lines

let read_tests =
  [
    (* @verifies ledger#{validate-ledgers=v1, give-stored-ledgers=v1, give-states-only-from-valid-ledgers=v1, valid-ledger-tree=v1}
       Each generated git tree object, valid or one or two changes away from
       valid at an edge of a condition of the schema `valid-ledger-tree`, gives
       the condition that the atom `ledger-validity` gives that git tree object
       and, only when the ledger is valid, the ids of the stored ledger in the
       order of their `seq`. A program that misreads one condition, or gives
       entries from a broken or newer ledger, fails. *)
    property ~count:1000
      ~name:"the condition and the stored ledger follow the atom and the schema"
      tree_gen (fun tree ->
        agrees tree
          (T.validity
             (objects (store_of_tree tree))
             (Ledger_objects.Commit commit_id)));
    (* @verifies ledger#valid-ledger-tree=v1
       `T.read` classifies each generated git tree object as a newer tree, a
       valid ledger tree that meets all seven conditions of the schema
       `valid-ledger-tree`, or another tree, and returns its lines and stored
       ledger entries. *)
    property
      ~name:"read tells newer trees, valid ledger trees, and others apart"
      tree_gen (fun tree ->
        let lines = sorted_unique (Model.lines tree) in
        let store = store_of_tree tree in
        match T.read (objects store) store.root_id with
        | Ok (Ledger_tree.Newer_tree { lines = l } as t) ->
            Model.is_newer tree
            && sorted_unique l = lines
            && List.length l = List.length lines
            && Ledger_tree.lines t = l
        | Ok (Ledger_tree.Other_tree { lines = l } as t) ->
            (not (Model.is_newer tree))
            && (not (Model.is_valid_ledger_tree tree))
            && sorted_unique l = lines
            && List.length l = List.length lines
            && Ledger_tree.lines t = l
        | Ok (Ledger_tree.Valid_tree { lines = l; entries } as t) ->
            let seqs = List.map Ledger_line.seq l in
            Model.is_valid_ledger_tree tree
            && sorted_unique (List.map Ledger_line.bytes l) = lines
            && List.length l = List.length lines
            && seqs = List.init (List.length l) (fun i -> i + 1)
            && List.map Entry.id entries
               = Option.get (Model.stored_ledger (Model.Commit_tree tree))
            && List.for_all
                 (fun e ->
                   List.mem
                     (Ledger_line.bytes (Entry.line e))
                     (List.map Ledger_line.bytes l))
                 entries
            && Ledger_tree.lines t = List.map Ledger_line.bytes l
        | Error _ -> false);
    (* @verifies ledger#{validate-ledgers=v1, give-stored-ledgers=v1, give-states-only-from-valid-ledgers=v1}
       For each ledger object of a generated git tree object, the commit, a
       git tree object at any depth, or the blob of a chunk of any mode, a
       reader that fails on that object makes the program give no result and
       no ledger entry; a program that decides before it reads every ledger
       object fails. *)
    property ~name:"a missing ledger object gives no result" tree_gen
      (fun tree ->
        let store = store_of_tree tree in
        List.for_all
          (fun missing ->
            Result.is_error
              (T.validity
                 (objects ~fail:(fun id -> id = missing) store)
                 (Ledger_objects.Commit commit_id))
            && (missing = commit_id
               || Result.is_error
                    (T.read
                       (objects ~fail:(fun id -> id = missing) store)
                       store.root_id)))
          store.ledger_ids);
    (* @verifies ledger#{validate-ledgers=v1, give-stored-ledgers=v1}
       The blobs of entries that are not chunks are no ledger objects, so a
       git repository that lacks them still holds its ledger objects; a program
       that gives no result for it fails. *)
    property
      ~name:"a missing blob of an entry that is not a chunk changes nothing"
      tree_gen (fun tree ->
        let store = store_of_tree tree in
        agrees tree
          (T.validity
             (objects ~fail:(fun id -> List.mem id store.other_blob_ids) store)
             (Ledger_objects.Commit commit_id)));
    property ~name:"each ledger object is read at most once, and no other"
      tree_gen (fun tree ->
        let store = store_of_tree tree in
        ignore (T.validity (objects store) (Ledger_objects.Commit commit_id));
        Store.most_reads store.s <= 1
        && List.for_all
             (fun id -> not (List.mem id store.other_blob_ids))
             (Store.read_ids store.s));
  ]

let ref_tests =
  [
    Alcotest.test_case "an absent ledger ref gives an empty stored ledger"
      `Quick (fun () ->
        let store = store_of_tree [] in
        Alcotest.(check (pair string (option (list string))))
          "valid" ("valid", Some [])
          (answer
             (T.validity
                (objects ~fail:(fun _ -> true) store)
                Ledger_objects.Absent)));
    Alcotest.test_case "a ledger ref with no commit is broken and reads nothing"
      `Quick (fun () ->
        let store = store_of_tree [] in
        Alcotest.(check (pair string (option (list string))))
          "broken" ("broken", None)
          (answer
             (T.validity
                (objects ~fail:(fun _ -> true) store)
                Ledger_objects.No_commit)));
  ]

let rec append_to_chunks prefix (tree : Model.entry list) line =
  List.map
    (fun (e : Model.entry) ->
      let path = if prefix = "" then e.name else prefix ^ "/" ^ e.name in
      if is_tree e.mode then
        { e with entries = append_to_chunks path e.entries line }
      else if is_regular e.mode && Model.is_chunk_path path then
        {
          e with
          content =
            Option.map
              (fun c ->
                if c = "" || c.[String.length c - 1] = '\n' then c ^ line
                else c ^ "\n" ^ line)
              e.content;
        }
      else e)
    tree

let has_chunk tree = Model.chunks tree <> []

(* @verifies ledger#validate-ledgers=v1
   A newer line in a chunk makes the ledger newer whatever else its git tree
   object holds; a program that gives "broken" for a damaged git tree object
   with a newer line fails. *)
let newer_test =
  property ~name:"a newer line in a chunk makes any git tree object newer"
    tree_gen (fun tree ->
      QCheck2.assume (has_chunk tree);
      let tree = append_to_chunks "" tree Model.newer_line in
      T.validity
        (objects (store_of_tree tree))
        (Ledger_objects.Commit commit_id)
      = Ok Ledger_tree.Newer)

let strip_unknown line =
  match Model.object_of_line line with
  | Some (V.Object members) ->
      Model.canonical_line
        (Model.with_id
           (V.Object
              (List.filter
                 (fun (k, _) ->
                   List.mem k
                     (List.map
                        (fun s -> V.Text s)
                        [ "kind"; "v"; "seq"; "dropped"; "reason" ]))
                 members)))
  | _ -> line

(* @verifies ledger#ignore-unknown-members=v1
   Two valid ledgers whose lines differ only in members other than `id`,
   `kind`, `v`, `seq`, and the fields of the kind `void`, and in the `id`
   that these members change, give stored ledgers that agree in the kind,
   the `seq`, and the fields of the kind of each entry, which are all that
   these libraries decide from; a program that let another member change
   the order or the kinds of the stored ledger fails. *)
let unknown_members_test =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:300
       ~name:"members other than the fields change no part of the stored ledger"
       ~print:(fun (a, b) -> Model.print_tree a ^ "\n" ^ Model.print_tree b)
       Gen.(
         Model.ledger_lines_gen >>= fun lines ->
         pair (Model.layout_gen lines)
           (Model.layout_gen (List.map strip_unknown lines)))
       (fun (full, stripped) ->
         let parts tree =
           match
             T.validity
               (objects (store_of_tree tree))
               (Ledger_objects.Commit commit_id)
           with
           | Ok (Ledger_tree.Valid stored) ->
               Some
                 (List.map
                    (fun e ->
                      ( Entry_kind.to_string (Entry.kind e),
                        Entry.seq e,
                        Option.map
                          Sinter_json_lines.Json.canonical_byte_sequence
                          (Entry.dropped e),
                        Option.map
                          Sinter_json_lines.Json.canonical_byte_sequence
                          (Entry.reason e) ))
                    (Ledger_tree.Stored_ledger.entries stored))
           | _ -> None
         in
         let a = parts full in
         Option.is_some a && a = parts stripped))

let tree_entry name id = { Ledger_objects.name; mode = "40000"; id }

let dag depth =
  let s = Store.create () in
  let t = ref (Store.add_tree_object s []) in
  for _ = 1 to depth do
    t := Store.add_tree_object s [ tree_entry "a" !t; tree_entry "b" !t ]
  done;
  of_root s (Store.add_tree_object s [ tree_entry "entries" !t ])

let chain depth =
  let s = Store.create () in
  let t = ref (Store.add_tree_object s []) in
  for _ = 1 to depth do
    t := Store.add_tree_object s [ tree_entry "x" !t ]
  done;
  of_root s (Store.add_tree_object s [ tree_entry "entries" !t ])

let hostile_tests =
  [
    Alcotest.test_case "a tree of 2^40 byte paths over 41 git tree objects ends"
      `Quick (fun () ->
        let store = dag 40 in
        Alcotest.(check bool)
          "broken" true
          (T.validity (objects store) (Ledger_objects.Commit commit_id)
          = Ok Ledger_tree.Broken);
        Alcotest.(check bool)
          "each object once" true
          (Store.most_reads store.s <= 1));
    Alcotest.test_case "a git tree object that names itself ends" `Quick
      (fun () ->
        let s = Store.create () in
        Store.set_tree s "self" [ tree_entry "entries" "self" ];
        Alcotest.(check bool)
          "broken" true
          (T.validity
             (objects (of_root s "self"))
             (Ledger_objects.Commit commit_id)
          = Ok Ledger_tree.Broken));
    Alcotest.test_case "one subtree under two folders gives one chunk" `Quick
      (fun () ->
        let s = Store.create () in
        let blob = Store.add_blob s (Model.task_line ~name:"x" 1) in
        let id = Lv.id_of_line (Model.task_line ~name:"x" 1) in
        let folder =
          Store.add_tree_object s
            [
              {
                Ledger_objects.name = id ^ ".jsonl";
                mode = "100644";
                id = blob;
              };
            ]
        in
        let hh = String.sub id 2 2 in
        let other = if hh = "00" then "01" else "00" in
        let entries =
          Store.add_tree_object s
            [ tree_entry hh folder; tree_entry other folder ]
        in
        let store =
          of_root s (Store.add_tree_object s [ tree_entry "entries" entries ])
        in
        Alcotest.(check bool)
          "broken" true
          (T.validity (objects store) (Ledger_objects.Commit commit_id)
          = Ok Ledger_tree.Broken));
    Alcotest.test_case "a chain of 100,000 git tree objects ends" `Quick
      (fun () ->
        Alcotest.(check bool)
          "broken" true
          (T.validity
             (objects (chain 100_000))
             (Ledger_objects.Commit commit_id)
          = Ok Ledger_tree.Broken));
  ]

let ledger_of_lines ~chunks n =
  let lines = List.init n (fun i -> Model.task_line (i + 1)) in
  let groups =
    if chunks then List.map (fun l -> ("100644", [ l ])) lines
    else [ ("100644", lines) ]
  in
  store_of_tree (Model.tree_of_chunks groups)

let folders_of_one_tree n =
  let s = Store.create () in
  let files =
    List.init n (fun i ->
        {
          Ledger_objects.name = "x" ^ string_of_int i;
          mode = "100644";
          id = "absent";
        })
  in
  let shared = Store.add_tree_object s files in
  let bytes =
    List.init 26 (fun i -> Char.chr (0x41 + i))
    @ List.init 20 (fun i -> Char.chr (0x67 + i))
  in
  let names =
    List.concat_map
      (fun a ->
        List.map
          (fun b -> String.init 2 (fun k -> if k = 0 then a else b))
          bytes)
      bytes
  in
  let folders =
    List.filteri (fun i _ -> i < n) names
    |> List.map (fun name -> tree_entry name shared)
  in
  of_root s
    (Store.add_tree_object s
       [ tree_entry "entries" (Store.add_tree_object s folders) ])

let growth_tests =
  [
    Alcotest.test_case
      "the work grows with the objects when many folders name one git tree \
       object"
      `Slow (fun () ->
        Counted_work.check_growth ~margin:2.5 ~sizes:(200, 2000)
          ~input:folders_of_one_tree (fun store ->
            if
              T.validity (objects store) (Ledger_objects.Commit commit_id)
              <> Ok Ledger_tree.Broken
            then Alcotest.fail "the ledger is broken"));
    Alcotest.test_case "the work of validity grows linearly with the lines"
      `Slow (fun () ->
        Counted_work.check_growth ~margin:2.5 ~sizes:(500, 5000)
          ~input:(ledger_of_lines ~chunks:false) (fun store ->
            T.validity (objects store) (Ledger_objects.Commit commit_id)));
    Alcotest.test_case "the work of validity grows linearly with the chunks"
      `Slow (fun () ->
        Counted_work.check_growth ~margin:2.5 ~sizes:(500, 5000)
          ~input:(ledger_of_lines ~chunks:true) (fun store ->
            T.validity (objects store) (Ledger_objects.Commit commit_id)));
    Alcotest.test_case "the work grows linearly with the git tree objects"
      `Quick (fun () ->
        Counted_work.check_growth ~margin:2.5 ~sizes:(100, 1000) ~input:dag
          (fun store ->
            T.validity (objects store) (Ledger_objects.Commit commit_id));
        Counted_work.check_growth ~margin:2.5 ~sizes:(1000, 10000) ~input:chain
          (fun store ->
            T.validity (objects store) (Ledger_objects.Commit commit_id)));
  ]

let id_without_seq (line_object : Sinter_json_lines.Json_line.t) =
  let value = (line_object :> Sinter_json_lines.Json.t) in
  let rest =
    Option.value
      (Sinter_json_lines.Json.object_ (Member.without value [ "id"; "seq" ]))
      ~default:value
  in
  "e-"
  ^ String.sub
      Digestif.SHA256.(
        to_hex
          (digest_string (Sinter_json_lines.Json.canonical_byte_sequence rest)))
      0 32

let line_without_seq ~name seq =
  let members =
    [
      (V.Text "by", V.String (V.Text "Ada Lovelace <ada@example.com>"));
      (V.Text "kind", V.String (V.Text "task"));
      (V.Text "name", V.String (V.Text name));
      (V.Text "v", V.Number "1");
    ]
  in
  Model.canonical_line
    (V.Object
       ((V.Text "id", V.String (V.Text (Model.entry_id (V.Object members))))
       :: (V.Text "seq", V.Number (string_of_int seq))
       :: members))

(* @verifies ledger#{validate-ledgers=v1, give-stored-ledgers=v1, give-states-only-from-valid-ledgers=v1}
   By the term `ledger-object`, a git repository does not hold the ledger
   objects of a commit when the git object of a tree entry is not a git tree
   object or when the git object of a chunk is not a blob. In each such case,
   `T.validity` and `T.read` give an error (no result and no ledger entry),
   even when another chunk holds a newer line or when a tree entry and a chunk
   share an id. A non-chunk regular-file entry whose git object is not a blob
   is no ledger object, so that entry does not prevent a result. *)
let wrong_object_type_tests =
  let line1 = Model.task_line ~name:"t1" 1 in
  let id1 = Lv.id_of_line line1 in
  let hh1 = String.sub id1 2 2 in
  let line2 = Model.task_line ~name:"t2" 2 in
  let id2 = Lv.id_of_line line2 in
  let hh2 = String.sub id2 2 2 in
  let newer_id = Lv.id_of_line Model.newer_line in
  let newer_hh = String.sub newer_id 2 2 in
  let file_entry ?(mode = "100644") name id =
    { Ledger_objects.name; mode; id }
  in
  let check_error label store =
    Alcotest.(check bool)
      (label ^ " validity") true
      (Result.is_error
         (T.validity (objects store) (Ledger_objects.Commit commit_id)));
    Alcotest.(check bool)
      (label ^ " read") true
      (Result.is_error (T.read (objects store) store.root_id))
  in
  [
    Alcotest.test_case "a tree entry whose git object is a blob gives no result"
      `Quick (fun () ->
        let s = Store.create () in
        let blob = Store.add_blob s line1 in
        let root = Store.add_tree_object s [ tree_entry "entries" blob ] in
        check_error "entries points to blob" (of_root s root);
        let s2 = Store.create () in
        let chunk_blob = Store.add_blob s2 line1 in
        let newer_blob = Store.add_blob s2 Model.newer_line in
        let valid_folder =
          Store.add_tree_object s2 [ file_entry (id1 ^ ".jsonl") chunk_blob ]
        in
        let newer_folder =
          Store.add_tree_object s2
            [ file_entry (newer_id ^ ".jsonl") newer_blob ]
        in
        let entries_tree =
          Store.add_tree_object s2
            [
              tree_entry hh1 valid_folder;
              tree_entry newer_hh newer_folder;
              tree_entry "ff" chunk_blob;
            ]
        in
        let root2 =
          Store.add_tree_object s2 [ tree_entry "entries" entries_tree ]
        in
        check_error "tree entry shares id with valid chunk and newer chunk"
          (of_root s2 root2));
    Alcotest.test_case
      "a tree entry whose git object is a commit gives no result" `Quick
      (fun () ->
        let s = Store.create () in
        let empty = Store.add_tree_object s [] in
        Store.add_commit_object s "other-commit" [] empty;
        let root =
          Store.add_tree_object s [ tree_entry "entries" "other-commit" ]
        in
        check_error "entries points to commit" (of_root s root));
    Alcotest.test_case
      "a chunk whose git object is a git tree object gives no result" `Quick
      (fun () ->
        List.iter
          (fun mode ->
            let s = Store.create () in
            let sub = Store.add_tree_object s [] in
            let folder =
              Store.add_tree_object s [ file_entry ~mode (id1 ^ ".jsonl") sub ]
            in
            let entries_tree =
              Store.add_tree_object s [ tree_entry hh1 folder ]
            in
            let root =
              Store.add_tree_object s [ tree_entry "entries" entries_tree ]
            in
            check_error
              ("chunk mode " ^ mode ^ " points to tree")
              (of_root s root))
          [ "100644"; "100755" ];
        let s2 = Store.create () in
        let newer_blob = Store.add_blob s2 Model.newer_line in
        let newer_folder =
          Store.add_tree_object s2
            [ file_entry (newer_id ^ ".jsonl") newer_blob ]
        in
        let shared_tree =
          Store.add_tree_object s2 [ file_entry (id2 ^ ".jsonl") newer_folder ]
        in
        let entries_tree =
          Store.add_tree_object s2
            [ tree_entry newer_hh newer_folder; tree_entry hh2 shared_tree ]
        in
        let root2 =
          Store.add_tree_object s2 [ tree_entry "entries" entries_tree ]
        in
        check_error "chunk shares id with tree entry alongside newer chunk"
          (of_root s2 root2));
    Alcotest.test_case "a chunk whose git object is a commit gives no result"
      `Quick (fun () ->
        let s = Store.create () in
        let empty = Store.add_tree_object s [] in
        Store.add_commit_object s "other-commit" [] empty;
        let folder =
          Store.add_tree_object s [ file_entry (id1 ^ ".jsonl") "other-commit" ]
        in
        let entries_tree = Store.add_tree_object s [ tree_entry hh1 folder ] in
        let root =
          Store.add_tree_object s [ tree_entry "entries" entries_tree ]
        in
        check_error "chunk points to commit" (of_root s root));
    Alcotest.test_case
      "a non-chunk entry whose git object is not a blob does not fail the read"
      `Quick (fun () ->
        let s = Store.create () in
        let blob = Store.add_blob s line1 in
        let folder =
          Store.add_tree_object s [ file_entry (id1 ^ ".jsonl") blob ]
        in
        let entries_tree = Store.add_tree_object s [ tree_entry hh1 folder ] in
        Store.add_commit_object s "other-commit" [] folder;
        let root =
          Store.add_tree_object s
            [
              tree_entry "entries" entries_tree;
              file_entry "README.md" folder;
              file_entry "NOTES.md" "other-commit";
            ]
        in
        let store = of_root s root in
        Alcotest.(check bool)
          "broken" true
          (T.validity (objects store) (Ledger_objects.Commit commit_id)
          = Ok Ledger_tree.Broken);
        Alcotest.(check bool)
          "other tree" true
          (match T.read (objects store) store.root_id with
          | Ok (Ledger_tree.Other_tree _) -> true
          | _ -> false);
        let s2 = Store.create () in
        let newer_blob = Store.add_blob s2 Model.newer_line in
        let newer_folder =
          Store.add_tree_object s2
            [ file_entry (newer_id ^ ".jsonl") newer_blob ]
        in
        let entries_tree2 =
          Store.add_tree_object s2 [ tree_entry newer_hh newer_folder ]
        in
        let root2 =
          Store.add_tree_object s2
            [
              tree_entry "entries" entries_tree2;
              file_entry "README.md" newer_folder;
            ]
        in
        let store2 = of_root s2 root2 in
        Alcotest.(check bool)
          "newer" true
          (T.validity (objects store2) (Ledger_objects.Commit commit_id)
          = Ok Ledger_tree.Newer));
  ]

(* @verifies ledger#{validate-ledgers=v1, valid-ledger-tree=v1}
   With an id function that leaves out `seq`, two lines that differ only in
   `seq` have one `id` and meet each other condition of the schema
   `valid-ledger-tree`, so a program that does not check condition 6 takes the
   ledger as valid and fails. Lines with two ids under the same function stay
   valid, so a program that refuses them for another reason also fails. *)
let condition_6_tests =
  let condition lines =
    fst
      (answer
         (T.validity ~entry_id:id_without_seq
            (objects (store_of_tree (Model.tree_of_lines lines)))
            (Ledger_objects.Commit commit_id)))
  in
  [
    Alcotest.test_case "two lines with one id make the ledger broken" `Quick
      (fun () ->
        Alcotest.(check string)
          "condition" "broken"
          (condition
             [ line_without_seq ~name:"t" 1; line_without_seq ~name:"t" 2 ]));
    Alcotest.test_case "lines with two ids under the same id function are valid"
      `Quick (fun () ->
        Alcotest.(check string)
          "condition" "valid"
          (condition
             [ line_without_seq ~name:"a" 1; line_without_seq ~name:"b" 2 ]));
  ]

let tests =
  Vectors.tests "ledger" [ ledger_vectors ]
  @ read_tests @ ref_tests
  @ [ newer_test; unknown_members_test ]
  @ hostile_tests @ growth_tests @ wrong_object_type_tests @ condition_6_tests
