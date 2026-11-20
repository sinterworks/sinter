(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines
open Sinter_ledger_lines
open Sinter_ledger_trees
open Sinter_ledger_sync
module Gen = QCheck2.Gen
module Model = Ledger_model
module Lv = Ledger_vectors
module Store = Ledger_store
module V = Vector_json
module T = Ledger_tree.Make (String)

let read_tree tree =
  let store = Store.create () in
  let id = Store.add_tree store tree in
  match T.read (Store.objects store) id with
  | Ok tree -> tree
  | Error e -> Alcotest.failf "the tree does not read: %s" e

let seq_of line =
  match
    Option.bind (V.json_value_of_bytes line) (Model.integer_member "seq")
  with
  | Some s -> s
  | None -> max_int

let by_seq lines =
  List.stable_sort (fun a b -> compare (seq_of a) (seq_of b)) lines

let without_id_and_seq line =
  match V.json_value_of_bytes line with
  | Some (V.Object members) ->
      V.canonical
        (V.Object
           (List.filter
              (fun (k, _) -> k <> V.Text "id" && k <> V.Text "seq")
              members))
  | _ -> None

let original_of clone entry =
  let key =
    without_id_and_seq (Json_line.canonical_line (Entry.line_object entry))
  in
  match List.filter (fun l -> without_id_and_seq l = key) clone with
  | [] ->
      Alcotest.failf "no line of the clone gives %s"
        (Json_line.canonical_line (Entry.line_object entry))
  | candidates -> candidates

let rule_of ~clone ~refused : Acceptance.rule =
 fun _ entry ->
  match
    List.sort_uniq compare
      (List.map
         (fun l -> List.mem (Lv.id_of_line l) refused)
         (original_of clone entry))
  with
  | [ refused ] -> not refused
  | _ -> Alcotest.failf "two lines of the clone give one entry"

let acceptance_of ~clone ~refused =
  let rule = rule_of ~clone ~refused in
  Acceptance.of_rules (fun _ -> Some rule)

let give_pull (vector : Vectors.vector) =
  let clone = Model.lines_of_json (Lv.required "clone" vector.input) in
  let shared = Model.lines_of_json (Lv.required "shared" vector.input) in
  let refused = Lv.refused vector.input in
  Lv.pull_answer
    (match
       Pull.pull
         (acceptance_of ~clone ~refused)
         ~clone:(Some (read_tree (Model.tree_of_lines clone)))
         ~shared:(read_tree (Model.tree_of_lines shared))
     with
    | Pull.Refused -> None
    | Pull.Pulled { added; left } ->
        Some
          ( List.map Lv.id_of_line (by_seq shared)
            @ List.map Ledger_line.id added,
            left ))

(* @verifies ledger[pulls][*]=v1
   Each vector gives the lines of a clone and of a commit s of its shared
   clone, and the ids that the acceptance rules refuse; a program that keeps a
   line for which s accounts, gives a moved line the wrong `seq` or `id`,
   keeps a refused or void line, reports a line that does not leave, or pulls
   where it must refuse, fails. *)
let pull_vectors =
  Vectors.group Lv.set ~name:"pulls" ~form:"#pull-vector=v1" give_pull

type scenario = {
  clone : Model.entry list option;
  shared : Model.entry list;
  refused : string list;
}

let print_scenario s =
  Printf.sprintf "clone %s\nshared %s\nrefused [%s]"
    (match s.clone with Some t -> Model.print_tree t | None -> "none")
    (Model.print_tree s.shared)
    (String.concat " " s.refused)

let unique ~tag o =
  match o with
  | V.Object members ->
      Model.with_id
        (V.Object
           ((V.Text "x-line", V.String (V.Text tag))
           :: List.filter (fun (k, _) -> k <> V.Text "x-line") members))
  | other -> other

let lines_from ~side ~first count =
  let open Gen in
  let rec go seq acc =
    if seq >= first + count then return (List.rev acc)
    else
      let* o = Model.line_object_gen ~seq in
      let o = unique ~tag:(side ^ string_of_int seq) o in
      go (seq + 1) (Model.canonical_line o :: acc)
  in
  go first []

let void_for line =
  let seq = seq_of line in
  Model.canonical_line
    (Model.with_id
       (V.Object
          [
            (V.Text "by", V.String (V.Text "Ada Lovelace <ada@example.com>"));
            (V.Text "dropped", V.String (V.Text (Lv.id_of_line line)));
            (V.Text "kind", V.String (V.Text "void"));
            (V.Text "reason", V.String (V.Text "the entry holds a secret"));
            (V.Text "seq", V.Number (string_of_int seq));
            (V.Text "v", V.Number "1");
          ]))

let scenario_gen =
  let open Gen in
  let* n = int_range 0 5 in
  let* base = lines_from ~side:"base" ~first:1 n in
  let* repaired =
    list_size (return n)
      (oneof_weighted [ (4, return false); (1, return true) ])
  in
  let shared_base =
    List.map2 (fun l r -> if r then void_for l else l) base repaired
  in
  let* m = int_range 0 3 in
  let* shared_extra = lines_from ~side:"shared" ~first:(n + 1) m in
  let* j = int_range 0 m in
  let pushed = List.filteri (fun i _ -> i < j) shared_extra in
  let* k = int_range 0 4 in
  let* own = lines_from ~side:"own" ~first:(n + j + 1) k in
  let clone_lines = base @ pushed @ own in
  let shared_lines = shared_base @ shared_extra in
  let* clone_tree = Model.layout_gen clone_lines in
  let* shared_tree = Model.layout_gen shared_lines in
  let* clone_tree =
    oneof_weighted [ (5, return clone_tree); (1, Model.damage_gen clone_tree) ]
  in
  let* shared_tree =
    oneof_weighted
      [ (5, return shared_tree); (1, Model.damage_gen shared_tree) ]
  in
  let* clone =
    oneof_weighted [ (8, return (Some clone_tree)); (1, return None) ]
  in
  let ids =
    List.filter_map
      (fun l -> Option.bind (Model.object_of_line l) (Model.string_member "id"))
      clone_lines
  in
  let* refused = list_size (return (List.length ids)) bool in
  let refused = List.filteri (fun i _ -> List.nth refused i) ids in
  return { clone; shared = shared_tree; refused }

let property ?(count = 500) ~name check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print:print_scenario scenario_gen check)

let reference ?(accept = fun _ -> true) s =
  Model.pull ~clone:s.clone ~shared:s.shared
    ~accept:(fun ~original ~before:_ _ ->
      accept original && not (List.mem (Lv.id_of_line original) s.refused))

let library ?acceptance s =
  let clone_lines = Option.fold ~none:[] ~some:Model.lines s.clone in
  let acceptance =
    match acceptance with
    | Some a -> a
    | None -> acceptance_of ~clone:clone_lines ~refused:s.refused
  in
  Pull.pull acceptance
    ~clone:(Option.map read_tree s.clone)
    ~shared:(read_tree s.shared)

let same s reference library =
  match (reference, library) with
  | Model.Refused, Pull.Refused -> true
  | Model.Pulled { lines; left }, Pull.Pulled { added; left = left' } ->
      let n = List.length (Model.lines s.shared) in
      List.filteri (fun i _ -> i >= n) lines = List.map Ledger_line.bytes added
      && left = left'
  | _ -> false

let pull_tests =
  [
    (* @verifies ledger#{pull-shared-entries=v1, refuse-unsafe-pulls=v1, report-leaving-entries=v1}
       Each generated pair of a clone and a commit s of its shared clone, with
       lines that s accounts for by the same bytes or by voids, provisional
       lines, refused lines, damaged trees, and a clone with no ledger commit,
       gives the pull of the term pull-commit, the lines that leave, or a
       refusal, as a reference that reads the terms directly gives them. *)
    property ~count:1000 ~name:"a pull gives the lines of the term pull-commit"
      (fun s -> same s (reference s) (library s));
    (* @verifies ledger#pull-shared-entries=v1
       With no ledger commit, no line stays, so the pull commit is s, whatever
       s holds, also when its ledger is broken or newer. *)
    property ~name:"a pull over no commit is s" (fun s ->
        Pull.pull Acceptance.none ~clone:None ~shared:(read_tree s.shared)
        = Pull.Pulled { added = []; left = [] });
    property ~name:"with no acceptance rule, every provisional line leaves"
      (fun s ->
        same s
          (reference ~accept:(fun _ -> false) s)
          (library ~acceptance:Acceptance.none s));
    property ~name:"a rule sees the ledger of s and of the lines that stayed"
      (fun s ->
        let calls = ref [] in
        let clone_lines = Option.fold ~none:[] ~some:Model.lines s.clone in
        let inner = rule_of ~clone:clone_lines ~refused:s.refused in
        let acceptance =
          Acceptance.of_rules (fun _ ->
              Some
                (fun ledger entry ->
                  calls :=
                    (List.map Entry.id (Acceptance.entries ledger), entry)
                    :: !calls;
                  inner ledger entry))
        in
        match library ~acceptance s with
        | Pull.Refused -> !calls = []
        | Pull.Pulled { added; _ } ->
            let provisional =
              List.filter
                (fun l ->
                  (not (Model.accounts (Model.lines s.shared) l))
                  && Option.bind (Model.object_of_line l)
                       (Model.string_member "kind")
                     <> Some "void")
                clone_lines
            in
            let s_ids =
              match read_tree s.shared with
              | Ledger_tree.Valid_tree { entries; _ } ->
                  List.map Entry.id entries
              | _ -> []
            in
            let n = List.length (Model.lines s.shared) in
            List.for_all
              (fun (ledger, entry) ->
                let before =
                  List.filter
                    (fun l -> Ledger_line.seq l < Entry.seq entry)
                    added
                in
                Entry.seq entry = n + List.length before + 1
                && ledger
                   = s_ids
                     @ List.filter_map
                         (fun l -> Option.map Entry.id (Entry.of_line l))
                         before)
              !calls
            && List.length !calls = List.length provisional);
    (* @verifies ledger#report-leaving-entries=v1
       The program gives the `id` of each line that leaves once; a program
       that names one line twice fails. *)
    property ~name:"each line that leaves is named once" (fun s ->
        match library s with
        | Pull.Refused -> true
        | Pull.Pulled { left; _ } ->
            List.length (List.sort_uniq String.compare left) = List.length left);
  ]

let task = Model.task_line

let spaced line =
  String.concat ", "
    (String.split_on_char ',' (String.sub line 0 (String.length line - 1)))
  ^ "\n"

let chunk_tree content =
  match Model.tree_of_lines [ task 1 ] with
  | [
   ({ Model.entries = [ ({ Model.entries = [ file ]; _ } as folder) ]; _ } as
    root);
  ] ->
      [
        {
          root with
          entries =
            [
              { folder with entries = [ { file with content = Some content } ] };
            ];
        };
      ]
  | _ -> Alcotest.fail "the layout of one line"

let deep_line_gen =
  Gen.(
    let* depth = int_range 1000 100_000 in
    let* inner =
      oneof_list [ ("[", "]"); ("{\"id\":[", "]}"); ("{\"a\":", "}") ]
    in
    let opener, closer = inner in
    let* closed = bool in
    let body =
      "{\"id\":"
      ^ String.concat "" (List.init depth (fun _ -> opener))
      ^ "1"
      ^ (if closed then String.concat "" (List.init depth (fun _ -> closer))
         else "")
      ^ "}"
    in
    return (body ^ "\n"))

let accounting_tests =
  let x = task ~name:"x" 1 and y = task ~name:"y" 2 in
  let shared = read_tree (Model.tree_of_lines [ x; void_for y ]) in
  let accounting = Accounting.of_tree shared in
  [
    Alcotest.test_case "a git tree object accounts for its own lines" `Quick
      (fun () ->
        Alcotest.(check bool) "x" true (Accounting.accounts accounting x));
    Alcotest.test_case "a void accounts for any line with the id it drops"
      `Quick (fun () ->
        Alcotest.(check bool) "y" true (Accounting.accounts accounting y);
        Alcotest.(check bool)
          "y spelled with spaces" true
          (Accounting.accounts accounting (spaced y)));
    Alcotest.test_case "the same JSON value in other bytes is not accounted for"
      `Quick (fun () ->
        Alcotest.(check bool)
          "x spelled with spaces" false
          (Accounting.accounts accounting (spaced x));
        Alcotest.(check bool)
          "x without its line feed" false
          (Accounting.accounts accounting
             (String.sub x 0 (String.length x - 1))));
    Alcotest.test_case
      "a dropped of a line that is no void accounts for nothing" `Quick
      (fun () ->
        let not_a_void kind =
          Model.canonical_line
            (Model.with_id
               (V.Object
                  [
                    (V.Text "dropped", V.String (V.Text (Lv.id_of_line y)));
                    (V.Text "kind", kind);
                    (V.Text "seq", V.Number "1");
                    (V.Text "v", V.Number "1");
                  ]))
        in
        List.iter
          (fun kind ->
            Alcotest.(check bool)
              "y" false
              (Accounting.accounts
                 (Accounting.of_tree
                    (read_tree (Model.tree_of_lines [ not_a_void kind ])))
                 y))
          [
            V.String (V.Text "task");
            V.String (V.Text "Void");
            V.Number "1";
            V.Bool true;
          ]);
    Alcotest.test_case "a dropped value matches an id of the same JSON value"
      `Quick (fun () ->
        let void dropped =
          Model.canonical_line
            (Model.with_id
               (V.Object
                  [
                    (V.Text "dropped", dropped);
                    (V.Text "kind", V.String (V.Text "void"));
                    (V.Text "seq", V.Number "1");
                    (V.Text "v", V.Number "1");
                  ]))
        in
        let of_void d =
          Accounting.of_tree (read_tree (Model.tree_of_lines [ void d ]))
        in
        Alcotest.(check bool)
          "5 and 5" true
          (Accounting.accounts (of_void (V.Number "5")) "{\"id\":5}\n");
        Alcotest.(check bool)
          "\"5\" and 5" false
          (Accounting.accounts (of_void (V.String (V.Text "5"))) "{\"id\":5}\n"));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:500
         ~name:"accounts follows the term on lines of any bytes"
         ~print:(fun (tree, line) ->
           Model.print_tree tree ^ "\n" ^ Printf.sprintf "%S" line)
         Gen.(
           let* tree =
             oneof
               [
                 Model.ledger_lines_gen >>= Model.layout_gen;
                 Model.ledger_lines_gen >>= Model.layout_gen
                 >>= Model.damage_gen;
               ]
           in
           let lines = Model.lines tree in
           let* line =
             oneof
               ([
                  Model.line_gen;
                  map (fun t -> V.print t ^ "\n") V.thing_gen;
                  deep_line_gen;
                  string_of V.byte_gen;
                ]
               @
               if lines = [] then []
               else
                 [
                   oneof_list lines;
                   oneof_list lines >>= V.corrupt_gen;
                   ( oneof_list lines >>= fun l ->
                     match V.json_value_of_bytes l with
                     | Some v -> map (fun t -> t ^ "\n") (V.spelling_gen v)
                     | None -> return l );
                 ])
           in
           return (tree, line))
         (fun (tree, line) ->
           Accounting.accounts (Accounting.of_tree (read_tree tree)) line
           = Model.accounts (Model.lines tree) line));
    (* @verifies ledger#refuse-unsafe-pulls=v1
       A broken clone whose line in other bytes has the id that a void of s
       drops is accounted for line by line, so the requirement allows the
       pull, and the model gives it; a line of a broken clone with the same
       JSON value as a line of s, in other bytes, is not accounted for, so the
       requirement allows no pull, and a model that pulls fails. *)
    Alcotest.test_case "a void accounts for a line of a broken clone" `Quick
      (fun () ->
        let clone = read_tree (chunk_tree (x ^ spaced y)) in
        Alcotest.(check bool)
          "pulled" true
          (Pull.pull Acceptance.none ~clone:(Some clone) ~shared
          = Pull.Pulled { added = []; left = [] });
        let clone = read_tree (chunk_tree (spaced x)) in
        Alcotest.(check bool)
          "refused" true
          (Pull.pull Acceptance.none ~clone:(Some clone) ~shared = Pull.Refused));
  ]

let entry_of line =
  match Json_line.read line with
  | Some lo -> (
      match Ledger_line.of_line_object lo with
      | Some l -> (
          match Entry.of_line l with
          | Some e -> e
          | None -> Alcotest.fail "no entry")
      | None -> Alcotest.fail "no ledger line")
  | None -> Alcotest.fail "no line object"

let acceptance_tests =
  let a = entry_of (task 1) and b = entry_of (task 2) in
  let void = entry_of (void_for (task 3)) in
  let always _ _ = true in
  [
    Alcotest.test_case "a ledger holds its entries in their order" `Quick
      (fun () ->
        let ledger = Acceptance.append (Acceptance.ledger [ a ]) b in
        Alcotest.(check (list string))
          "entries"
          [ Entry.id a; Entry.id b ]
          (List.map Entry.id (Acceptance.entries ledger));
        Alcotest.(check (list string))
          "newest first"
          [ Entry.id b; Entry.id a ]
          (List.map Entry.id (Acceptance.newest_first ledger));
        Alcotest.(check (list string))
          "empty" []
          (List.map Entry.id (Acceptance.entries (Acceptance.ledger []))));
    Alcotest.test_case "none accepts no entry" `Quick (fun () ->
        Alcotest.(check bool)
          "task" false
          (Acceptance.accepted Acceptance.none (Acceptance.ledger []) a));
    Alcotest.test_case "a rule decides for its kind only" `Quick (fun () ->
        let acceptance =
          Acceptance.of_rules (function
            | Entry_kind.Task ->
                Some (fun ledger _ -> Acceptance.entries ledger = [])
            | _ -> None)
        in
        Alcotest.(check bool)
          "at the start" true
          (Acceptance.accepted acceptance (Acceptance.ledger []) a);
        Alcotest.(check bool)
          "after an entry" false
          (Acceptance.accepted acceptance (Acceptance.ledger [ b ]) a));
    Alcotest.test_case "a kind with no rule is accepted at no point" `Quick
      (fun () ->
        let plan =
          entry_of
            (Model.canonical_line
               (Model.with_id
                  (V.Object
                     [
                       (V.Text "kind", V.String (V.Text "plan"));
                       (V.Text "seq", V.Number "1");
                       (V.Text "v", V.Number "1");
                     ])))
        in
        let acceptance =
          Acceptance.of_rules (function
            | Entry_kind.Task -> Some always
            | _ -> None)
        in
        Alcotest.(check bool)
          "plan" false
          (Acceptance.accepted acceptance (Acceptance.ledger []) plan));
    Alcotest.test_case "a void is accepted at no point, whatever the rules"
      `Quick (fun () ->
        Alcotest.(check bool)
          "void" false
          (Acceptance.accepted
             (Acceptance.of_rules (fun _ -> Some always))
             (Acceptance.ledger []) void));
  ]

let growth_input n =
  let shared = List.init n (fun i -> task ~name:"s" (i + 1)) in
  let clone = List.init n (fun i -> task ~name:"c" (i + 1)) in
  (read_tree (Model.tree_of_lines clone), read_tree (Model.tree_of_lines shared))

let growth_tests =
  [
    Alcotest.test_case "the work of a pull grows linearly with the lines" `Slow
      (fun () ->
        let always = Acceptance.of_rules (fun _ -> Some (fun _ _ -> true)) in
        Counted_work.check_growth ~margin:2.5 ~sizes:(300, 3000)
          ~input:growth_input (fun (clone, shared) ->
            Pull.pull always ~clone:(Some clone) ~shared));
  ]

let tests =
  Vectors.covers "ledger" Lv.set
    [
      Test_ledger_trees.ledger_vectors;
      Test_ledger_histories.history_vectors;
      pull_vectors;
    ]
  :: Vectors.tests "ledger" [ pull_vectors ]
  @ pull_tests @ accounting_tests @ acceptance_tests @ growth_tests
