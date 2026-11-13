(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(* @cites commitment-set-form *)

type step = { scope : string list; promises : (string * string) list }

let canonical_bytes value =
  match Json.to_string value with
  | Ok text -> text
  | Error _ ->
      invalid_arg
        "Sinter_core.Commitment_set.hash: a glob, a word, or a target is not \
         UTF-8"

let globs globs =
  Json.Array
    (List.map
       (fun glob -> Json.String glob)
       (List.sort_uniq String.compare globs))

module Groups = Map.Make (String)

let promise_objects promises =
  Json.Array
    (List.map
       (fun (word, target) ->
         Json.Object
           [ ("target", Json.String target); ("word", Json.String word) ])
       (List.sort
          (fun (w1, t1) (w2, t2) ->
            match String.compare w1 w2 with 0 -> String.compare t1 t2 | n -> n)
          promises))

let groups steps =
  let by_scope =
    List.fold_left
      (fun groups { scope; promises } ->
        match promises with
        | [] -> groups
        | _ :: _ ->
            let scope = globs scope in
            Groups.update (canonical_bytes scope)
              (fun found ->
                let earlier =
                  match found with Some (_, earlier) -> earlier | None -> []
                in
                Some (scope, List.rev_append promises earlier))
              groups)
      Groups.empty steps
  in
  Json.Array
    (List.map
       (fun (_, (scope, promises)) ->
         Json.Object
           [ ("promises", promise_objects promises); ("scope", scope) ])
       (Groups.bindings by_scope))

let bytes ~scope steps =
  canonical_bytes
    (Json.Object [ ("groups", groups steps); ("scope", globs scope) ])

let hash ~scope steps = Sha256.hex (bytes ~scope steps)

type stated = {
  slug : string;
  own : string list option;
  stated_promises : (string * string) list;
}

type set = { plan_scope : string list; steps : stated list }

let hash_of_set { plan_scope; steps } =
  let inherited, owned =
    List.partition_map
      (fun { own; stated_promises; _ } ->
        match own with
        | None -> Left stated_promises
        | Some scope -> Right { scope; promises = stated_promises })
      steps
  in
  hash ~scope:plan_scope
    ({ scope = plan_scope; promises = List.concat inherited } :: owned)

type difference = {
  added : (string * string) list;
  removed : (string * string) list;
  wider : string list;
}

module Texts = Set.Make (String)

type interned = {
  number : int;
  key : string;
  plain : string list;
  excluded : Texts.t;
  container : Glob.container Lazy.t;
}

let table () =
  Hashtbl.create ~random:true 16
  [@mutaml.skip
    "the seed and the first size change only the time of a lookup on keys that \
     collide, and never its result; the code reads a table only by its keys, \
     never in its order"]

let interner () =
  let known = table () in
  fun scope ->
    let key = canonical_bytes (globs scope) in
    match Hashtbl.find_opt known key with
    | Some found -> found
    | None ->
        let excluded, plain =
          List.partition
            (String.starts_with ~prefix:"!")
            (List.sort_uniq String.compare scope)
        in
        let found =
          {
            number = Hashtbl.length known;
            key;
            plain;
            excluded = Texts.of_list excluded;
            container = lazy (Glob.container plain);
          }
        in
        Hashtbl.add known key found;
        found

let scope_wider ~inner ~outer =
  let container = Lazy.force outer.container in
  List.filter (fun glob -> not (Glob.holds container glob)) inner.plain
  @ Texts.elements (Texts.diff outer.excluded inner.excluded)

module Pairs = Map.Make (struct
  type t = string * string

  let compare (a, b) (c, d) =
    match String.compare a c with 0 -> String.compare b d | order -> order
end)

let promises_of intern { plan_scope; steps } =
  let plan = intern plan_scope in
  ( plan,
    List.fold_left
      (fun found { slug; own; stated_promises } ->
        let scope = match own with None -> plan | Some own -> intern own in
        List.fold_left
          (fun found pair ->
            Pairs.update pair
              (fun held ->
                Some ((slug, scope) :: Option.value held ~default:[]))
              found)
          found stated_promises)
      Pairs.empty steps )

let by_slug_and_scope (slug_a, scope_a) (slug_b, scope_b) =
  match String.compare slug_a slug_b with
  | 0 -> String.compare scope_a.key scope_b.key
  | order -> order

let matched current approved =
  let rec equal_slugs pairs rest_current rest_approved = function
    | (c :: cs as all_c), (a :: az as all_a) -> (
        match String.compare (fst c) (fst a) with
        | 0 -> equal_slugs ((c, a) :: pairs) rest_current rest_approved (cs, az)
        | order
          when (order < 0)
               [@mutaml.skip
                 "the case 0 comes first, so order is never 0 here, and order \
                  < 0, order < 1, and order <= 0 give one answer"] ->
            equal_slugs pairs (c :: rest_current) rest_approved (cs, all_a)
        | _ -> equal_slugs pairs rest_current (a :: rest_approved) (all_c, az))
    | cs, az ->
        ( pairs,
          List.rev_append rest_current cs,
          List.rev_append rest_approved az )
  in
  let rec zip pairs = function
    | c :: cs, a :: az -> zip ((c, a) :: pairs) (cs, az)
    | cs, az -> (pairs, List.length cs, List.length az)
  in
  let pairs, rest_current, rest_approved =
    equal_slugs [] [] []
      (List.sort by_slug_and_scope current, List.sort by_slug_and_scope approved)
  in
  zip pairs (rest_current, rest_approved)

let compare_sets ~current ~approved =
  let intern = interner () in
  let plan_current, promises_current = promises_of intern current in
  let plan_approved, promises_approved = promises_of intern approved in
  let compared = table () in
  let compare_once wide ~inner ~outer =
    let key = (inner.number, outer.number) in
    if Hashtbl.mem compared key then wide
    else (
      Hashtbl.add compared key ();
      scope_wider ~inner ~outer @ wide)
  in
  let added, removed, wide =
    Pairs.fold
      (fun pair (held_current, held_approved) (added, removed, wide) ->
        let pairs, extra, missing =
          matched
            (Option.value held_current ~default:[])
            (Option.value held_approved ~default:[])
        in
        ( List.init extra (fun _ -> pair) @ added,
          List.init missing (fun _ -> pair) @ removed,
          List.fold_left
            (fun wide ((_, inner), (_, outer)) ->
              compare_once wide ~inner ~outer)
            wide pairs ))
      (Pairs.merge
         (fun _ held_current held_approved ->
           Some (held_current, held_approved))
         promises_current promises_approved)
      ([], [], compare_once [] ~inner:plan_current ~outer:plan_approved)
  in
  match (added, removed, wide) with
  | [], [], [] -> None
  | _, _, wider ->
      Some
        {
          added = List.rev added;
          removed = List.rev removed;
          wider = List.sort_uniq String.compare wider;
        }
