(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Model = Changes_model
module Graph = Sinter_commit_graphs.Commit_graph.Make (String)
module Deep = Sinter_commit_graphs.Commit_graph.Make (Int)

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
let sorted list = List.sort String.compare list

let graph_of (model : Model.graph) : unit Graph.graph =
 fun c -> Ok (Model.parents model c)

let ok = function
  | Ok value -> value
  | Error () -> Alcotest.fail "the graph gave no error"

let ok_line = function
  | Ok value -> value
  | Error (Graph.Unread ()) -> Alcotest.fail "the graph gave no error"
  | Error (Graph.First_parent_cycle c) ->
      Alcotest.failf "a first-parent cycle at %s" c

let values members = `Assoc [ ("values", `Assoc members) ]
let commits_of vector = Model.graph_of_json (required "commits" vector)

let give_reach (vector : Vectors.vector) =
  let graph = graph_of (commits_of vector.input) in
  let c = name_of (required "commit" vector.input) in
  let c' = name_of (required "other" vector.input) in
  `Assoc
    [
      ( "result",
        `String
          (if ok (Graph.reaches graph c c') then "reaches" else "does not reach")
      );
    ]

(* @verifies changes[reach][*]=v1
   Each vector gives two commits of a commit graph and whether the first
   reaches the second, through second parents too; a walk that misses a parent
   or a commit itself gives the other result. *)
let reach_vectors = Vectors.group set ~name:"reach" ~rev:"v1" give_reach

let give_parents (vector : Vectors.vector) =
  let named = Model.names_of_json (required "named" vector.input) in
  let shallow =
    match required "shallow" vector.input with
    | `Bool shallow -> shallow
    | other -> Alcotest.failf "not a boolean: %s" (Yojson.Basic.to_string other)
  in
  values [ ("parents", names (Graph.parents ~named ~shallow)) ]

(* @verifies changes[parents][*]=v1
   Each vector gives the commits that a commit object names and whether the
   file `shallow` names the commit; a program that drops, reorders, or merges
   parents, or keeps them for a shallow commit, gives other parents. *)
let parent_vectors = Vectors.group set ~name:"parents" ~rev:"v1" give_parents

let give_range (vector : Vectors.vector) =
  let graph = graph_of (commits_of vector.input) in
  let from = Option.map name_of (member "from" vector.input) in
  let h = name_of (required "to" vector.input) in
  values [ ("order", names (ok (Graph.range graph ~from h))) ]

(* @verifies changes[ranges][*]=v1
   Each vector gives the commits of a range in their parents-first order; a
   range with a commit too many or too few, or another order of the walk of
   the parents, gives another sequence. *)
let range_vectors = Vectors.group set ~name:"ranges" ~rev:"v1" give_range

let give_change (vector : Vectors.vector) =
  let graph = graph_of (commits_of vector.input) in
  let h = name_of (required "last" vector.input) in
  let d = name_of (required "default" vector.input) in
  let change =
    match ok (Graph.change graph ~default:(Some d) h) with
    | Some commits -> sorted commits
    | None -> Alcotest.fail "no change while the default branch has a commit"
  in
  values
    ([
       ("change", names change);
       ("merge-bases", names (sorted (ok (Graph.merge_bases graph h d))));
     ]
    @
    match ok (Graph.change_base graph ~default:(Some d) h) with
    | Some base -> [ ("base", `String base) ]
    | None -> [])

(* @verifies changes[changes][*]=v1
   Each vector gives the commits of the change of a commit, the merge bases of
   that commit and the commit of the default branch, and the base when there is
   exactly one merge base; a wrong range, a common ancestor that another one
   reaches, or a base of two merge bases fails. *)
let change_vectors = Vectors.group set ~name:"changes" ~rev:"v1" give_change

let give_landing (vector : Vectors.vector) =
  let graph = graph_of (commits_of vector.input) in
  let d = name_of (required "line-of" vector.input) in
  let c = name_of (required "commit" vector.input) in
  values
    ([
       ("first-parent-line", names (ok_line (Graph.first_parent_line graph d)));
     ]
    @
    match ok_line (Graph.landing_commit graph ~line_of:d c) with
    | Some m -> [ ("landing-commit", `String m) ]
    | None -> [])

(* @verifies changes[landing-commits][*]=v1
   Each vector gives the first-parent line of a commit and the landing commit
   of another commit on it, or none when the first does not reach the second; a
   line that takes a second parent, or a landing commit that is not the last of
   the line to reach the commit, fails. *)
let landing_vectors =
  Vectors.group set ~name:"landing-commits" ~rev:"v1" give_landing

let property ?(count = 1000) ~name generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print:Model.print_graph generator check)

let commits graph = List.map fst graph

let for_all_pairs graph check =
  List.for_all
    (fun a -> List.for_all (fun b -> check a b) (commits graph))
    (commits graph)

let both_gen =
  Gen.oneof_weighted [ (3, Model.graph_gen); (1, Model.cyclic_graph_gen) ]

(* @verifies changes#decide-reach=v1
   For every two commits of generated graphs, cycles included, the result must
   be "reaches" exactly when the second is in the ancestry of the first, as the
   smallest set closed under parents; a missed parent or a missed commit
   itself fails. *)
let reach_follows_the_ancestry =
  property ~name:"a commit reaches exactly the commits of its ancestry" both_gen
    (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun a b ->
          ok (Graph.reaches graph a b) = Model.reaches model a b))

(* @verifies changes#give-ranges=v1
   For every two commits, and for no first commit, the commits of the range
   must be exactly those that the last commit reaches and the first does not,
   each once; a commit that the first reaches, a missed commit, or a commit
   twice fails. *)
let ranges_follow_the_term =
  property ~name:"a range holds what the last reaches and the first does not"
    both_gen (fun model ->
      let graph = graph_of model in
      List.for_all
        (fun h ->
          List.for_all
            (fun from ->
              sorted (ok (Graph.range graph ~from h))
              = Model.range model ~from h)
            (None :: List.map Option.some (commits model)))
        (commits model))

(* @verifies changes#give-parents-first-orders=v1
   For every range of generated graphs, the order must be the order in which
   the walk of the term finishes the commits; another order of the parents,
   or a commit that comes before a parent in the range, fails. *)
let order_follows_the_walk =
  property ~name:"a range comes in the order in which the walk finishes it"
    both_gen (fun model ->
      let graph = graph_of model in
      List.for_all
        (fun h ->
          List.for_all
            (fun from ->
              ok (Graph.range graph ~from h) = Model.parents_first model ~from h)
            (None :: List.map Option.some (commits model)))
        (commits model))

let parents_come_first =
  property ~name:"each commit of a range comes after its parents in the range"
    Model.graph_gen (fun model ->
      let graph = graph_of model in
      List.for_all
        (fun h ->
          let order = ok (Graph.range graph ~from:None h) in
          let rec check seen = function
            | [] -> true
            | c :: rest ->
                List.for_all (fun p -> List.mem p seen) (Model.parents model c)
                && check (c :: seen) rest
          in
          check [] order)
        (commits model))

(* @verifies changes#give-merge-bases=v1
   For every two commits, the merge bases must be the common ancestors that no
   other common ancestor reaches, by a search of the common ancestors; a common
   ancestor too many, or a missed one, fails. *)
let merge_bases_follow_the_term =
  property ~name:"the merge bases are the common ancestors that none reaches"
    both_gen (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun a b ->
          sorted (ok (Graph.merge_bases graph a b))
          = Model.merge_bases model a b))

let merge_bases_are_each_once =
  property ~name:"each merge base comes once" both_gen (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun a b ->
          let bases = ok (Graph.merge_bases graph a b) in
          List.length bases = List.length (List.sort_uniq String.compare bases)))

(* @verifies changes#give-changes-of-commits=v1
   For every commit as the commit of the default branch, the change of each
   commit must be the range from it, and with no commit of the default branch
   the change must be none; a change without a default commit fails. *)
let changes_follow_the_term =
  property ~name:"the change of a commit is the range from the default commit"
    both_gen (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun h d ->
          Option.map sorted (ok (Graph.change graph ~default:(Some d) h))
          = Some (Model.range model ~from:(Some d) h)
          && ok (Graph.change graph ~default:None h) = None))

let change_keeps_the_order_of_the_range =
  property ~name:"the change comes in the parents-first order of its range"
    both_gen (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun h d ->
          ok (Graph.change graph ~default:(Some d) h)
          = Some (ok (Graph.range graph ~from:(Some d) h))))

(* @verifies changes#give-change-bases=v1
   For every two commits, the base must be the merge base when there is exactly
   one, and none when there are none or several or no default commit; a base
   picked from several merge bases fails. *)
let change_bases_follow_the_term =
  property ~name:"the base is the one merge base, or none" both_gen
    (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun h d ->
          (ok (Graph.change_base graph ~default:(Some d) h)
          =
          match Model.merge_bases model h d with
          | [ base ] -> Some base
          | _ -> None)
          && ok (Graph.change_base graph ~default:None h) = None))

(* @verifies changes#give-first-parent-lines=v1
   For every commit of generated graphs, the line must be the commit and its
   first parents in turn, up to a commit with no parent; a second parent, a
   missed commit, or a line that stops early fails. *)
let first_parent_lines_follow_the_term =
  property ~name:"the first-parent line follows the first parents"
    Model.graph_gen (fun model ->
      let graph = graph_of model in
      List.for_all
        (fun c ->
          Some (ok_line (Graph.first_parent_line graph c))
          = Model.first_parent_line model c)
        (commits model))

let first_parent_cycles_are_errors =
  property ~name:"first parents that come back to a commit give an error"
    Model.cyclic_graph_gen (fun model ->
      let graph = graph_of model in
      List.for_all
        (fun c ->
          match
            (Graph.first_parent_line graph c, Model.first_parent_line model c)
          with
          | Ok line, Some expected -> line = expected
          | Error (Graph.First_parent_cycle cycle), None ->
              List.mem cycle (Model.ancestry model c)
          | _ -> false)
        (commits model))

(* @verifies changes#give-landing-commits=v1
   For every two commits, the landing commit must be the commit of the
   first-parent line that reaches the commit and whose first parent does not,
   and none when the line's commit does not reach it; another commit of the
   line fails. *)
let landing_commits_follow_the_term =
  property ~name:"the landing commit is where the commit joins the line"
    Model.graph_gen (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun d c ->
          ok_line (Graph.landing_commit graph ~line_of:d c)
          = Model.landing_commit model ~line_of:d c))

let landing_on_a_cycle_is_an_error =
  property
    ~name:"a landing commit on a line whose first parents cycle is an error"
    Model.cyclic_graph_gen (fun model ->
      let graph = graph_of model in
      for_all_pairs model (fun d c ->
          match
            ( Graph.landing_commit graph ~line_of:d c,
              Model.first_parent_line model d )
          with
          | Error (Graph.First_parent_cycle _), None -> true
          | Ok landing, Some _ ->
              landing = Model.landing_commit model ~line_of:d c
          | Ok None, None -> not (Model.reaches model d c)
          | _ -> false))

(* @verifies changes#give-commit-parents=v1
   For generated named parents, repeats included, the parents must be the named
   commits in their order, and none for a commit that the file `shallow`
   names; a dropped repeat, a new order, or a kept parent fails. *)
let parents_follow_the_term =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:500
       ~name:"the parents are the named commits, or none when shallow"
       ~print:(fun (named, shallow) ->
         Printf.sprintf "%s %b" (String.concat " " named) shallow)
       Gen.(
         pair (list_size (int_range 0 5) (oneof_list [ "a"; "b"; "c" ])) bool)
       (fun (named, shallow) ->
         Graph.parents ~named ~shallow = if shallow then [] else named))

let within model a b : string Graph.graph =
  let reached = Model.ancestry model a @ Model.ancestry model b in
  fun c -> if List.mem c reached then Ok (Model.parents model c) else Error c

let reads_only_the_commits_that_it_reaches =
  property
    ~name:
      "no function reads the parents of a commit that its commits do not reach"
    both_gen (fun model ->
      for_all_pairs model (fun a b ->
          let graph = within model a b in
          Result.is_ok (Graph.reaches graph a b)
          && Result.is_ok (Graph.range graph ~from:(Some a) b)
          && Result.is_ok (Graph.range graph ~from:None b)
          && Result.is_ok (Graph.merge_bases graph a b)
          && Result.is_ok (Graph.change graph ~default:(Some a) b)
          && Result.is_ok (Graph.change_base graph ~default:(Some a) b)
          &&
          match Graph.landing_commit graph ~line_of:a b with
          | Error (Graph.Unread _) -> false
          | _ -> true))

let unread_everywhere : string Graph.graph = fun c -> Error c

let errors_of_the_graph_come_back () =
  let check name result =
    match result with
    | Error ("a" | "b") -> ()
    | Error other -> Alcotest.failf "%s: the error of %s" name other
    | Ok _ ->
        Alcotest.failf "%s: a result from a graph that gives no parents" name
  in
  let line name = function
    | Error (Graph.Unread ("a" | "b")) -> ()
    | Error _ -> Alcotest.failf "%s: another error" name
    | Ok _ -> Alcotest.failf "%s: a result" name
  in
  check "reaches" (Graph.reaches unread_everywhere "a" "b");
  check "range" (Graph.range unread_everywhere ~from:None "b");
  check "range from" (Graph.range unread_everywhere ~from:(Some "a") "b");
  check "merge bases" (Graph.merge_bases unread_everywhere "a" "b");
  check "change" (Graph.change unread_everywhere ~default:(Some "a") "b");
  check "base" (Graph.change_base unread_everywhere ~default:(Some "a") "b");
  line "first-parent line" (Graph.first_parent_line unread_everywhere "a");
  line "landing" (Graph.landing_commit unread_everywhere ~line_of:"a" "b")

let a_failing_commit_in_the_walk_gives_its_error () =
  let graph : string Graph.graph = function
    | "h" -> Ok [ "p"; "q" ]
    | "p" -> Ok [ "r" ]
    | "q" -> Error "q"
    | "r" -> Ok []
    | other -> Error other
  in
  Alcotest.(check (result (list string) string))
    "range" (Error "q")
    (Graph.range graph ~from:None "h")

let a_landing_walk_that_meets_an_unread_commit_gives_its_error () =
  let graph : string Graph.graph = function
    | "m" -> Ok [ "b"; "x" ]
    | "b" -> Ok []
    | other -> Error other
  in
  Alcotest.(check bool)
    "the line reads" true
    (Graph.first_parent_line graph "m" = Ok [ "m"; "b" ]);
  match Graph.landing_commit graph ~line_of:"m" "z" with
  | Error (Graph.Unread "x") -> ()
  | Error _ -> Alcotest.fail "another error"
  | Ok _ -> Alcotest.fail "a result from a walk that meets an unread commit"

let with_small_stack run =
  let before = Gc.get () in
  Gc.set { before with stack_limit = 1 lsl 16 };
  Fun.protect ~finally:(fun () -> Gc.set before) run

let depth = 200_000
let chain : unit Deep.graph = fun k -> Ok (if k = 0 then [] else [ k - 1 ])

let ladder : unit Deep.graph =
 fun k ->
  Ok
    (if k <= 1 then [] else if k mod 2 = 0 then [ k - 2; k - 1 ] else [ k - 2 ])

let deep_ok = function
  | Ok value -> value
  | Error () -> Alcotest.fail "the graph gave no error"

let deep_line = function
  | Ok value -> value
  | Error _ -> Alcotest.fail "the line gave an error"

let walks_of_a_deep_chain () =
  with_small_stack (fun () ->
      let tip = depth - 1 in
      Alcotest.(check bool) "reach" true (deep_ok (Deep.reaches chain tip 0));
      Alcotest.(check bool)
        "no reach" false
        (deep_ok (Deep.reaches chain 0 tip));
      let order = deep_ok (Deep.range chain ~from:None tip) in
      Alcotest.(check int) "the range" depth (List.length order);
      Alcotest.(check (list int))
        "the first two" [ 0; 1 ]
        (List.filteri (fun k _ -> k < 2) order);
      Alcotest.(check (list int))
        "a range from the middle" [ tip ]
        (deep_ok (Deep.range chain ~from:(Some (tip - 1)) tip));
      Alcotest.(check (list int))
        "the merge base" [ 7 ]
        (deep_ok (Deep.merge_bases chain tip 7));
      Alcotest.(check (option int))
        "the base" (Some 7)
        (deep_ok (Deep.change_base chain ~default:(Some 7) tip));
      Alcotest.(check int)
        "the change" (tip - 7)
        (match deep_ok (Deep.change chain ~default:(Some 7) tip) with
        | Some change -> List.length change
        | None -> -1);
      Alcotest.(check int)
        "the first-parent line" depth
        (List.length (deep_line (Deep.first_parent_line chain tip)));
      Alcotest.(check (option int))
        "the landing commit" (Some 3)
        (deep_line (Deep.landing_commit chain ~line_of:tip 3)))

let walks_of_a_deep_ladder () =
  with_small_stack (fun () ->
      let tip = depth in
      Alcotest.(check bool) "reach" true (deep_ok (Deep.reaches ladder tip 1));
      Alcotest.(check int)
        "the range" (depth + 1)
        (List.length (deep_ok (Deep.range ladder ~from:None tip)));
      Alcotest.(check (list int))
        "the merge bases" [ 3 ]
        (deep_ok (Deep.merge_bases ladder tip 3));
      Alcotest.(check int)
        "the first-parent line"
        ((depth / 2) + 1)
        (List.length (deep_line (Deep.first_parent_line ladder tip)));
      Alcotest.(check (option int))
        "the landing commit of an odd commit" (Some 4)
        (deep_line (Deep.landing_commit ladder ~line_of:tip 3)))

let vector_groups =
  [
    reach_vectors;
    parent_vectors;
    range_vectors;
    change_vectors;
    landing_vectors;
  ]

let tests =
  Vectors.tests "changes" vector_groups
  @ [
      reach_follows_the_ancestry;
      ranges_follow_the_term;
      order_follows_the_walk;
      parents_come_first;
      merge_bases_follow_the_term;
      merge_bases_are_each_once;
      changes_follow_the_term;
      change_keeps_the_order_of_the_range;
      change_bases_follow_the_term;
      first_parent_lines_follow_the_term;
      first_parent_cycles_are_errors;
      landing_commits_follow_the_term;
      landing_on_a_cycle_is_an_error;
      parents_follow_the_term;
      reads_only_the_commits_that_it_reaches;
      Alcotest.test_case "a graph that gives no parents gives its error" `Quick
        errors_of_the_graph_come_back;
      Alcotest.test_case
        "a commit of the walk that gives no parents gives its error" `Quick
        a_failing_commit_in_the_walk_gives_its_error;
      Alcotest.test_case
        "the walks of a chain of 200,000 commits on a stack of 512 KiB" `Quick
        walks_of_a_deep_chain;
      Alcotest.test_case
        "the walks of a ladder of 200,000 commits on a stack of 512 KiB" `Quick
        walks_of_a_deep_ladder;
    ]
