(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = (int * int) array

let empty = [||]

let of_sorted_runs runs =
  let rec merge acc = function
    | [] -> List.rev acc
    | (a, b) :: rest -> (
        match acc with
        | (c, d) :: before when a <= d + 1 ->
            merge ((c, max b d) :: before) rest
        | _ -> merge ((a, b) :: acc) rest)
  in
  Array.of_list (merge [] runs)

let of_list numbers =
  of_sorted_runs
    (List.map (fun k -> (k, k)) (List.sort_uniq Int.compare numbers))

let range first last = if last < first then empty else [| (first, last) |]

let elements set =
  Array.fold_right
    (fun (a, b) rest -> List.init (b - a + 1) (fun k -> a + k) @ rest)
    set []

let last set =
  match Array.length set with 0 -> None | n -> Some (snd set.(n - 1))

let cardinal set = Array.fold_left (fun n (a, b) -> n + b - a + 1) 0 set

let union sets =
  of_sorted_runs
    (List.sort
       (fun (a, _) (c, _) -> Int.compare a c)
       (List.concat_map Array.to_list sets))

let diff a b =
  let rec go acc i j from =
    if i >= Array.length a then List.rev acc
    else
      let first, last = a.(i) in
      let from = max from first in
      if j >= Array.length b then go ((from, last) :: acc) (i + 1) j min_int
      else
        let c, d = b.(j) in
        if d < from then go acc i (j + 1) from
        else if c > last then go ((from, last) :: acc) (i + 1) j min_int
        else
          let acc = if c > from then (from, c - 1) :: acc else acc in
          if d >= last then go acc (i + 1) j min_int else go acc i j (d + 1)
  in
  Array.of_list (go [] 0 0 min_int)

let subset a b =
  let rec go i j =
    i >= Array.length a
    || j < Array.length b
       &&
       let first, last = a.(i) and c, d = b.(j) in
       if d < first then go i (j + 1)
       else c <= first && last <= d && go (i + 1) j
  in
  go 0 0

module Groups = Map.Make (struct
  type nonrec t = t

  let compare = Stdlib.compare
end)

module Index = struct
  type set = t

  type 'a t = {
    values : 'a array;
    group : int array;
    sets : set array;
    sizes : int array;
    members : int list array;
    firsts : int array;
    lasts : int array;
    owners : int array;
    reach : int array;
  }

  let rec fill_reach lasts reach lo hi =
    if lo >= hi then min_int
    else
      let mid = (lo + hi) / 2 in
      let left = fill_reach lasts reach lo mid in
      let right = fill_reach lasts reach (mid + 1) hi in
      reach.(mid) <- max lasts.(mid) (max left right);
      reach.(mid)

  let make pairs =
    let pairs = Array.of_list pairs in
    let groups = ref Groups.empty and sets = ref [] and count = ref 0 in
    let group =
      Array.map
        (fun (_, set) ->
          match Groups.find_opt set !groups with
          | Some id -> id
          | None ->
              let id = !count in
              incr count;
              groups := Groups.add set id !groups;
              sets := set :: !sets;
              id)
        pairs
    in
    let sets = Array.of_list (List.rev !sets) in
    let members = Array.make !count [] in
    for k = Array.length pairs - 1 downto 0 do
      members.(group.(k)) <- k :: members.(group.(k))
    done;
    let runs =
      Array.of_list
        (List.stable_sort
           (fun (a, _, _) (c, _, _) -> Int.compare a c)
           (List.concat
              (List.mapi
                 (fun id set ->
                   List.map (fun (a, b) -> (a, b, id)) (Array.to_list set))
                 (Array.to_list sets))))
    in
    let lasts = Array.map (fun (_, b, _) -> b) runs in
    let reach = Array.make (Array.length runs) min_int in
    ignore (fill_reach lasts reach 0 (Array.length runs));
    {
      values = Array.map fst pairs;
      group;
      sets;
      sizes = Array.map cardinal sets;
      members;
      firsts = Array.map (fun (a, _, _) -> a) runs;
      lasts;
      owners = Array.map (fun (_, _, id) -> id) runs;
      reach;
    }

  let stab index k =
    let rec go lo hi found =
      if lo >= hi then found
      else
        let mid = (lo + hi) / 2 in
        if index.reach.(mid) < k then found
        else
          let found = go lo mid found in
          if index.firsts.(mid) > k then found
          else
            let found =
              if index.lasts.(mid) >= k then index.owners.(mid) :: found
              else found
            in
            go (mid + 1) hi found
    in
    go 0 (Array.length index.firsts) []

  let groups_of index thing =
    if Array.length thing = 0 then List.init (Array.length index.sets) Fun.id
    else
      List.filter
        (fun id -> subset thing index.sets.(id))
        (stab index (fst thing.(0)))

  let pairs_of index ids =
    List.sort Int.compare (List.concat_map (fun id -> index.members.(id)) ids)

  let holders index thing =
    List.map
      (fun k -> index.values.(k))
      (pairs_of index (groups_of index thing))

  let innermost index thing =
    match groups_of index thing with
    | [] -> None
    | first :: _ as ids -> (
        let least =
          List.fold_left
            (fun least id ->
              if
                (index.sizes.(id) < index.sizes.(least))
                [@mutaml.skip
                  "two distinct groups of the least size are never subsets of \
                   each other"]
              then id
              else least)
            first ids
        in
        match index.members.(least) with
        | [ k ]
          when List.for_all
                 (fun id ->
                   id = least || subset index.sets.(least) index.sets.(id))
                 ids ->
            Some index.values.(k)
        | _ -> None)

  let subsets index =
    let inside = Array.make (Array.length index.sets) [] in
    Array.iteri
      (fun id set ->
        List.iter
          (fun above -> inside.(above) <- id :: inside.(above))
          (groups_of index set))
      index.sets;
    List.mapi
      (fun k value ->
        ( value,
          List.filter_map
            (fun q -> if q = k then None else Some index.values.(q))
            (pairs_of index inside.(index.group.(k))) ))
      (Array.to_list index.values)
end
