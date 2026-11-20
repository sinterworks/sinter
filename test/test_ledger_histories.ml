(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_trees
module Gen = QCheck2.Gen
module Model = Ledger_model
module Lv = Ledger_vectors
module Store = Ledger_store
module V = Vector_json
module H = Ledger_history.Make (String)

let answer = function
  | Ok (Some Ledger_history.Intact) -> Some "valid"
  | Ok (Some Ledger_history.Not_intact) -> Some "invalid"
  | Ok None -> None
  | Error e -> Alcotest.failf "no result: %s" e

let give_history (vector : Vectors.vector) =
  let commits = Model.graph_of_json (Lv.required "commits" vector.input) in
  let c =
    match Lv.required "commit" vector.input with
    | `String c -> c
    | other -> Alcotest.failf "not a commit: %s" (Yojson.Basic.to_string other)
  in
  let store = Store.of_history commits in
  Lv.history_answer
    (answer (H.history (Store.objects store) (Ledger_objects.Commit c)))

(* @verifies ledger[histories][*]=v1
   Each vector gives the commits of the history of a ledger, each with its
   parents and its git tree object, and whether the history is intact, or no
   result for a newer ledger; a program that takes a commit that changes or
   drops a line, a merge, or an earlier git tree object that is no valid
   ledger tree as intact, or that gives a result for a newer ledger, fails. *)
let history_vectors =
  Vectors.group Lv.set ~name:"histories" ~form:"#history-vector=v1" give_history

type history = { commits : (string * Model.commit) list; head : string }

let print_history h =
  String.concat "\n"
    (Printf.sprintf "head %s" h.head
    :: List.map
         (fun (name, (c : Model.commit)) ->
           Printf.sprintf "%s <- [%s] %s" name
             (String.concat " " c.parents)
             (Model.print_tree c.tree))
         h.commits)

let seq_of line =
  match
    Option.bind (Model.object_of_line line) (Model.integer_member "seq")
  with
  | Some s -> s
  | None -> 0

let take n list = List.filteri (fun i _ -> i < n) list

let history_gen =
  let open Gen in
  let* lines = Model.ledger_lines_gen in
  let lines = List.sort (fun a b -> compare (seq_of a) (seq_of b)) lines in
  let n = List.length lines in
  let* k = int_range 1 5 in
  let* counts = list_size (return k) (int_range 0 n) in
  let counts = List.sort compare counts in
  let* trees =
    flatten_list (List.map (fun m -> Model.layout_gen (take m lines)) counts)
  in
  let name i = "c" ^ string_of_int i in
  let commits =
    List.mapi
      (fun i tree ->
        ( name i,
          { Model.parents = (if i = 0 then [] else [ name (i - 1) ]); tree } ))
      trees
  in
  let head = name (k - 1) in
  let replace i f =
    List.mapi (fun j (nm, c) -> if j = i then (nm, f c) else (nm, c)) commits
  in
  let* i = int_range 0 (k - 1) in
  let* commits =
    oneof_weighted
      [
        ( 2,
          let m = List.nth counts i in
          let* extra = Model.line_object_gen ~seq:(max 1 m) in
          map
            (fun tree -> replace i (fun c -> { c with Model.tree }))
            (Model.layout_gen (take m lines @ [ Model.canonical_line extra ]))
        );
        (3, return commits);
        ( 3,
          let c = List.assoc (name i) commits in
          map
            (fun tree -> replace i (fun c -> { c with Model.tree }))
            (Model.damage_gen c.Model.tree) );
        ( 1,
          return
            (replace i (fun c ->
                 { c with parents = c.parents @ [ name (max 0 (i - 1)) ] })) );
        (1, return (replace 0 (fun c -> { c with parents = [ head ] })));
        ( 1,
          map
            (fun tree -> replace i (fun c -> { c with Model.tree }))
            (Model.layout_gen
               (List.filteri
                  (fun j _ -> j <> 0)
                  (take (List.nth counts i) lines))) );
      ]
  in
  return { commits; head }

let property ?(count = 500) ~name check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print:print_history history_gen check)

let reference h =
  let tree = (List.assoc h.head h.commits).tree in
  if Model.is_newer tree then None else Some (Model.intact h.commits h.head)

let agrees h result =
  match (reference h, result) with
  | None, Ok None -> true
  | Some true, Ok (Some Ledger_history.Intact) -> true
  | Some false, Ok (Some Ledger_history.Not_intact) -> true
  | _ -> false

let reached h =
  let rec go seen = function
    | [] -> List.rev seen
    | x :: rest ->
        if List.mem x seen then go seen rest
        else go (x :: seen) ((List.assoc x h.commits).Model.parents @ rest)
  in
  go [] [ h.head ]

let history_tests =
  [
    (* @verifies ledger#validate-histories=v1
       Each generated history, of commits that append lines in any layout, or
       one change away at an edge of the atom `intact-history`, gives "valid"
       exactly when the history is intact, "invalid" when it is not, and
       neither when the ledger is newer. The reference checks each commit of
       the history alone, so a check along the chain that skips a commit, a
       line, or a git tree object fails. *)
    property ~count:1000 ~name:"the history is intact as the atom gives it"
      (fun h ->
        agrees h
          (H.history
             (Store.objects (Store.of_history h.commits))
             (Ledger_objects.Commit h.head)));
    (* @verifies ledger#validate-histories=v1
       Each history object of a history whose ledger is not newer, the commits
       that the ledger commit reaches, their parents, and their ledger objects,
       makes the program give neither result when a reader fails on it; when
       the ledger is newer, only the ledger objects of the ledger commit do. *)
    property ~name:"a missing history object gives no result" (fun h ->
        let store = Store.of_history h.commits in
        let newer = reference h = None in
        let needed =
          if newer then Store.ledger_object_ids store h.head
          else List.concat_map (Store.ledger_object_ids store) (reached h)
        in
        let all = List.concat_map (Store.ledger_object_ids store) (reached h) in
        List.for_all
          (fun id ->
            let result =
              H.history
                (Store.objects ~fail:(String.equal id) store)
                (Ledger_objects.Commit h.head)
            in
            if List.mem id needed then Result.is_error result
            else result = Ok None)
          all);
    (* @verifies ledger#validate-histories=v1
       The blobs of entries that are not chunks are no history objects, so a
       git repository that lacks them still gives the result. *)
    property ~name:"a missing blob that is no history object changes nothing"
      (fun h ->
        let store = Store.of_history h.commits in
        let others = List.concat_map (Store.other_blob_ids store) (reached h) in
        agrees h
          (H.history
             (Store.objects ~fail:(fun id -> List.mem id others) store)
             (Ledger_objects.Commit h.head)));
    property ~name:"each history object is read at most once, and no other"
      (fun h ->
        let store = Store.of_history h.commits in
        ignore (H.history (Store.objects store) (Ledger_objects.Commit h.head));
        let allowed =
          if reference h = None then Store.ledger_object_ids store h.head
          else List.concat_map (Store.ledger_object_ids store) (reached h)
        in
        Store.most_reads store <= 1
        && List.for_all (fun id -> List.mem id allowed) (Store.read_ids store));
    property ~name:"a commit extends another as the term gives it" (fun h ->
        let store = Store.of_history h.commits in
        List.for_all
          (fun (d, _) ->
            List.for_all
              (fun (c, _) ->
                H.extends (Store.objects store) d c
                = Ok (Model.extends h.commits d c))
              h.commits)
          h.commits);
    Alcotest.test_case "an absent ledger ref has an intact history" `Quick
      (fun () ->
        Alcotest.(check (option string))
          "valid" (Some "valid")
          (answer
             (H.history
                (Store.objects ~fail:(fun _ -> true) (Store.create ()))
                Ledger_objects.Absent)));
    (* @verifies ledger#validate-histories=v1
       A ledger ref with no commit has no commit that extends a commit with no
       parent, and its ledger is broken, not newer, so the result is
       "invalid". *)
    Alcotest.test_case "a ledger ref with no commit has no intact history"
      `Quick (fun () ->
        Alcotest.(check (option string))
          "invalid" (Some "invalid")
          (answer
             (H.history
                (Store.objects ~fail:(fun _ -> true) (Store.create ()))
                Ledger_objects.No_commit)));
    Alcotest.test_case "extends gives the error of a commit on its way" `Quick
      (fun () ->
        let tree = Model.tree_of_lines [] in
        let store =
          Store.of_history
            [
              ("a", { Model.parents = [ "b" ]; tree });
              ("b", { Model.parents = [ "c" ]; tree });
              ("c", { Model.parents = []; tree });
            ]
        in
        Alcotest.(check bool)
          "an error" true
          (Result.is_error
             (H.extends (Store.objects ~fail:(String.equal "b") store) "a" "c"));
        Alcotest.(check bool)
          "no error" true
          (H.extends (Store.objects store) "a" "c" = Ok true));
    Alcotest.test_case "extends follows a cycle of single parents to its end"
      `Quick (fun () ->
        let tree = Model.tree_of_lines [] in
        let store =
          Store.of_history
            [
              ("a", { Model.parents = [ "b" ]; tree });
              ("b", { Model.parents = [ "a" ]; tree });
            ]
        in
        Alcotest.(check bool)
          "no extension" true
          (H.extends (Store.objects store) "a" "c" = Ok false));
  ]

let task = Model.task_line

let appends n =
  let store = Store.create () in
  let folders = Hashtbl.create 256 in
  let folder_ids = Hashtbl.create 256 in
  let entry name id = { Ledger_objects.name; mode = "40000"; id } in
  for i = 1 to n do
    let line = task i in
    let id = Lv.id_of_line line in
    let hh = String.sub id 2 2 in
    let files =
      Option.value ~default:[] (Hashtbl.find_opt folders hh)
      @ [
          {
            Ledger_objects.name = id ^ ".jsonl";
            mode = "100644";
            id = Store.add_blob store line;
          };
        ]
    in
    Hashtbl.replace folders hh files;
    Hashtbl.replace folder_ids hh (Store.add_tree_object store files);
    let listed =
      List.sort compare
        (Hashtbl.fold (fun hh id acc -> entry hh id :: acc) folder_ids [])
    in
    let root =
      Store.add_tree_object store
        [ entry "entries" (Store.add_tree_object store listed) ]
    in
    Store.add_commit_object store
      ("c" ^ string_of_int i)
      (if i = 1 then [] else [ "c" ^ string_of_int (i - 1) ])
      root
  done;
  (store, "c" ^ string_of_int n)

let shared_tree_chain n =
  let store = Store.create () in
  let tree = Store.add_tree store (Model.tree_of_lines [ task 1; task 2 ]) in
  for i = 1 to n do
    Store.add_commit_object store
      ("c" ^ string_of_int i)
      (if i = 1 then [] else [ "c" ^ string_of_int (i - 1) ])
      tree
  done;
  (store, "c" ^ string_of_int n)

let mined ~hh ~seq =
  let rec find i =
    let line = Model.task_line ~name:("m" ^ string_of_int i) seq in
    if String.sub (Lv.id_of_line line) 2 2 = hh then line else find (i + 1)
  in
  find 0

let swaps ~large n =
  let store = Store.create () in
  let big = List.init large (fun i -> Model.task_line (i + 1)) in
  let hh = String.sub (Lv.id_of_line (List.hd big)) 2 2 in
  let p = mined ~hh ~seq:(large + 1) and q = mined ~hh ~seq:(large + 2) in
  let tree first second =
    Store.add_tree store
      (Model.tree_of_chunks [ ("100644", big); ("100644", [ first; second ]) ])
  in
  let a = tree p q and b = tree q p in
  for i = 1 to n do
    Store.add_commit_object store
      ("c" ^ string_of_int i)
      (if i = 1 then [] else [ "c" ^ string_of_int (i - 1) ])
      (if i mod 2 = 0 then a else b)
  done;
  (store, "c" ^ string_of_int n)

let growth_tests =
  [
    Alcotest.test_case
      "the work of a history does not grow with a chunk that no commit changes"
      `Slow (fun () ->
        Counted_work.check_growth ~exponent:0. ~margin:2. ~sizes:(100, 1000)
          ~input:(swaps ~large:20_000) (fun (store, head) ->
            if
              H.history (Store.objects store) (Ledger_objects.Commit head)
              <> Ok (Some Ledger_history.Intact)
            then Alcotest.fail "the history is intact"));
    Alcotest.test_case "the work of extends grows linearly with the commits"
      `Slow (fun () ->
        Counted_work.check_growth ~margin:2. ~sizes:(1000, 10000)
          ~input:shared_tree_chain (fun (store, head) ->
            if H.extends (Store.objects store) head "c1" <> Ok true then
              Alcotest.fail "the chain extends its first commit"));
    Alcotest.test_case
      "the work of a history of one chunk for each append grows linearly" `Slow
      (fun () ->
        Counted_work.check_growth ~margin:2. ~sizes:(1000, 10000) ~input:appends
          (fun (store, head) ->
            let result =
              H.history (Store.objects store) (Ledger_objects.Commit head)
            in
            if result <> Ok (Some Ledger_history.Intact) then
              Alcotest.fail "the history is intact"));
  ]

let history_without_seq commits head =
  answer
    (H.history ~entry_id:Test_ledger_trees.id_without_seq
       (Store.objects (Store.of_history commits))
       (Ledger_objects.Commit head))

let line_without_seq = Test_ledger_trees.line_without_seq

(* @verifies ledger#validate-histories=v1
   By the term `ledger-object`, a git repository does not hold the history
   objects when a tree entry of any reached commit names a git object that is
   not a git tree object or when a chunk names a git object that is not a blob.
   `H.history` gives an error (neither result) in each such case, except when
   the ledger commit itself is newer and only an earlier commit has a
   wrong-type object. A non-chunk regular-file entry that names a wrong-type
   object is no history object and does not fail the read. *)
let wrong_object_type_tests =
  let line1 = Model.task_line ~name:"h1" 1 in
  let id1 = Lv.id_of_line line1 in
  let hh1 = String.sub id1 2 2 in
  let newer_id = Lv.id_of_line Model.newer_line in
  let newer_hh = String.sub newer_id 2 2 in
  let tree_entry name id = { Ledger_objects.name; mode = "40000"; id } in
  let file_entry ?(mode = "100644") name id =
    { Ledger_objects.name; mode; id }
  in
  let valid_tree_in s = Store.add_tree s (Model.tree_of_lines [ line1 ]) in
  let newer_tree_in s =
    let nb = Store.add_blob s Model.newer_line in
    let nf = Store.add_tree_object s [ file_entry (newer_id ^ ".jsonl") nb ] in
    let et = Store.add_tree_object s [ tree_entry newer_hh nf ] in
    Store.add_tree_object s [ tree_entry "entries" et ]
  in
  let tree_entry_is_blob_in s =
    let blob = Store.add_blob s line1 in
    Store.add_tree_object s [ tree_entry "entries" blob ]
  in
  let chunk_is_tree_in ?(mode = "100644") s =
    let sub = Store.add_tree_object s [] in
    let folder =
      Store.add_tree_object s [ file_entry ~mode (id1 ^ ".jsonl") sub ]
    in
    let entries_tree = Store.add_tree_object s [ tree_entry hh1 folder ] in
    Store.add_tree_object s [ tree_entry "entries" entries_tree ]
  in
  [
    Alcotest.test_case
      "a ledger commit with a wrong-type tree entry or chunk gives no result"
      `Quick (fun () ->
        let s1 = Store.create () in
        Store.add_commit_object s1 "head" [] (tree_entry_is_blob_in s1);
        Alcotest.(check bool)
          "tree entry is blob" true
          (Result.is_error
             (H.history (Store.objects s1) (Ledger_objects.Commit "head")));
        List.iter
          (fun mode ->
            let s2 = Store.create () in
            Store.add_commit_object s2 "head" [] (chunk_is_tree_in ~mode s2);
            Alcotest.(check bool)
              ("chunk mode " ^ mode ^ " is tree")
              true
              (Result.is_error
                 (H.history (Store.objects s2) (Ledger_objects.Commit "head"))))
          [ "100644"; "100755" ];
        let s3 = Store.create () in
        let nb = Store.add_blob s3 Model.newer_line in
        let nf =
          Store.add_tree_object s3 [ file_entry (newer_id ^ ".jsonl") nb ]
        in
        let et =
          Store.add_tree_object s3
            [ tree_entry newer_hh nf; tree_entry "ff" nb ]
        in
        let root3 = Store.add_tree_object s3 [ tree_entry "entries" et ] in
        Store.add_commit_object s3 "head" [] root3;
        Alcotest.(check bool)
          "wrong-type tree entry alongside newer chunk" true
          (Result.is_error
             (H.history (Store.objects s3) (Ledger_objects.Commit "head"))));
    Alcotest.test_case
      "an earlier commit with a wrong-type tree entry or chunk gives no result"
      `Quick (fun () ->
        let s1 = Store.create () in
        Store.add_commit_object s1 "a" [] (tree_entry_is_blob_in s1);
        Store.add_commit_object s1 "b" [ "a" ] (valid_tree_in s1);
        Alcotest.(check bool)
          "history tree entry is blob" true
          (Result.is_error
             (H.history (Store.objects s1) (Ledger_objects.Commit "b")));
        Alcotest.(check bool)
          "extends tree entry is blob" true
          (Result.is_error (H.extends (Store.objects s1) "b" "a"));
        let s2 = Store.create () in
        Store.add_commit_object s2 "a" [] (chunk_is_tree_in s2);
        Store.add_commit_object s2 "b" [ "a" ] (valid_tree_in s2);
        Alcotest.(check bool)
          "history chunk is tree" true
          (Result.is_error
             (H.history (Store.objects s2) (Ledger_objects.Commit "b")));
        Alcotest.(check bool)
          "extends chunk is tree" true
          (Result.is_error (H.extends (Store.objects s2) "b" "a")));
    Alcotest.test_case
      "a newer ledger commit ignores a wrong-type object in an earlier commit"
      `Quick (fun () ->
        let s = Store.create () in
        Store.add_commit_object s "a" [] (tree_entry_is_blob_in s);
        Store.add_commit_object s "b" [ "a" ] (newer_tree_in s);
        Alcotest.(check (option string))
          "newer gives neither result" None
          (answer (H.history (Store.objects s) (Ledger_objects.Commit "b"))));
    Alcotest.test_case
      "an earlier commit with a non-chunk entry naming a tree is not intact"
      `Quick (fun () ->
        let s = Store.create () in
        let sub = Store.add_tree_object s [] in
        let parent_root =
          Store.add_tree_object s [ file_entry "README.md" sub ]
        in
        Store.add_commit_object s "a" [] parent_root;
        Store.add_commit_object s "b" [ "a" ] (valid_tree_in s);
        Alcotest.(check (option string))
          "invalid" (Some "invalid")
          (answer (H.history (Store.objects s) (Ledger_objects.Commit "b"))));
  ]

(* @verifies ledger#{validate-histories=v1, valid-ledger-tree=v1}
   With an id function that leaves out `seq`, a line that differs from another
   only in `seq` has the same `id`. A history whose first commit holds two such
   lines, or whose second commit adds a line with the `id` of a line of the
   first, has a commit that is no valid ledger tree by condition 6 of the
   schema `valid-ledger-tree`, so a program that takes that history as intact
   fails. A history that adds a line with another `id` stays intact, so a
   program that refuses that history fails. *)
let condition_6_tests =
  let tree lines = Model.tree_of_lines lines in
  let a = line_without_seq ~name:"a" 1 in
  [
    Alcotest.test_case "a first commit with two lines of one id is not intact"
      `Quick (fun () ->
        Alcotest.(check (option string))
          "history" (Some "invalid")
          (history_without_seq
             [
               ( "c1",
                 {
                   Model.parents = [];
                   tree = tree [ a; line_without_seq ~name:"a" 2 ];
                 } );
             ]
             "c1"));
    Alcotest.test_case
      "a commit that adds a line with the id of an earlier line is not intact"
      `Quick (fun () ->
        Alcotest.(check (option string))
          "history" (Some "invalid")
          (history_without_seq
             [
               ("c1", { Model.parents = []; tree = tree [ a ] });
               ( "c2",
                 {
                   Model.parents = [ "c1" ];
                   tree = tree [ a; line_without_seq ~name:"a" 2 ];
                 } );
             ]
             "c2"));
    Alcotest.test_case "a commit that adds a line with another id is intact"
      `Quick (fun () ->
        Alcotest.(check (option string))
          "history" (Some "valid")
          (history_without_seq
             [
               ("c1", { Model.parents = []; tree = tree [ a ] });
               ( "c2",
                 {
                   Model.parents = [ "c1" ];
                   tree = tree [ a; line_without_seq ~name:"b" 2 ];
                 } );
             ]
             "c2"));
  ]

let tests =
  Vectors.tests "ledger" [ history_vectors ]
  @ history_tests @ growth_tests @ wrong_object_type_tests @ condition_6_tests
