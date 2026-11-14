(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type atom = Literal of char | Class of (char * char) list | Sub of branch list
and piece = { atom : atom; least : int; most : int option; copies : int }
and branch = piece list

type state = Step of (char * char) list * int | Split of int * int | Accept
type t = { text : string; states : state array; start : int }

type error =
  | Too_long
  | Unmatched
  | Reversed_range
  | Large_count
  | Reversed_bounds
  | Oversized
  | Empty_id_fits

exception No_match

(* @satisfies identifiers#reject-unmatched-id-patterns=v1 *)
let is_literal c =
  match c with
  | '!' | '"'
  | '%' .. '\''
  | '-'
  | '0' .. '<'
  | '>'
  | 'A' .. 'Z'
  | '_' .. 'z'
  | '~' ->
      true
  | _ -> false

(* @satisfies identifiers#reject-unmatched-id-patterns=v1 *)
let is_single c =
  match c with
  | '!' | '"'
  | '$' .. '+'
  | '.'
  | '0' .. '<'
  | '>' | '?'
  | 'A' .. 'Z'
  | '_' .. 'z'
  | '|' | '~' ->
      true
  | _ -> false

(* @satisfies identifiers#reject-unmatched-id-patterns=v1 *)
let same_range_kind a b =
  match (a, b) with
  | '0' .. '9', '0' .. '9' | 'A' .. 'Z', 'A' .. 'Z' | 'a' .. 'z', 'a' .. 'z' ->
      true
  | _ -> false

let count_cap =
  (1_000_000
  [@mutaml.skip
    "each count above 255 makes the id pattern invalid before its size or its \
     automaton is computed, so every cap above 255 gives the same results"])

type flags = {
  mutable reversed_range : bool;
  mutable large_count : bool;
  mutable reversed_bounds : bool;
}

(* @satisfies identifiers#reject-unmatched-id-patterns=v1 *)
let parse text =
  let n = String.length text in
  let flags =
    { reversed_range = false; large_count = false; reversed_bounds = false }
  in
  let peek i = if i < n then Some text.[i] else None in
  let count i =
    match peek i with
    | Some '0' -> (0, i + 1)
    | Some '1' .. '9' ->
        let rec digits i value =
          match peek i with
          | Some ('0' .. '9' as c) ->
              digits (i + 1)
                (min count_cap ((value * 10) + Char.code c - Char.code '0'))
          | _ -> (value, i)
        in
        let value, i = digits i 0 in
        (* @satisfies identifiers#reject-large-counts=v1 *)
        if value > 255 then flags.large_count <- true;
        (value, i)
    | _ -> raise No_match
  in
  let expect c i = if peek i = Some c then i + 1 else raise No_match in
  (* @satisfies identifiers#reject-oversized-id-patterns=v1 *)
  let quantifier i =
    match peek i with
    | Some '?' -> (0, Some 1, 1, i + 1)
    | Some '*' -> (0, None, 1, i + 1)
    | Some '+' -> (1, None, 1, i + 1)
    | Some '{' -> (
        let least, i = count (i + 1) in
        match peek i with
        | Some '}' -> (least, Some least, max least 1, i + 1)
        | Some ',' when peek (i + 1) = Some '}' ->
            (least, None, least + 1, i + 2)
        | Some ',' ->
            let most, i = count (i + 1) in
            (* @satisfies identifiers#reject-reversed-bounds=v1 *)
            if least > most then flags.reversed_bounds <- true;
            (least, Some most, max most 1, expect '}' i)
        | _ -> raise No_match)
    | _ -> (1, Some 1, 1, i)
  in
  let char_class i =
    let rec members i acc =
      match peek i with
      | Some ']' -> (acc, i + 1)
      | Some '-' -> (('-', '-') :: acc, expect ']' (i + 1))
      | Some c
        when peek (i + 1) = Some '-'
             &&
             match peek (i + 2) with
             | Some d -> same_range_kind c d
             | None -> false ->
          let d = text.[i + 2] in
          (* @satisfies identifiers#reject-reversed-ranges=v1 *)
          if c > d then flags.reversed_range <- true;
          members (i + 3) ((c, d) :: acc)
      | Some c when is_single c -> members (i + 1) ((c, c) :: acc)
      | _ -> raise No_match
    in
    let leading, i =
      if peek i = Some '-' then ([ ('-', '-') ], i + 1) else ([], i)
    in
    let acc, j = members i leading in
    if acc = [] then raise No_match;
    (Class acc, j)
  in
  let rec pattern i =
    let first, i = branch i in
    let rec more i acc =
      if peek i = Some '|' then
        let b, i = branch (i + 1) in
        more i (b :: acc)
      else (List.rev acc, i)
    in
    more i [ first ]
  and branch i =
    let rec pieces i acc =
      match atom i with
      | Some (a, i) ->
          let least, most, copies, i = quantifier i in
          pieces i ({ atom = a; least; most; copies } :: acc)
      | None -> if acc = [] then raise No_match else (List.rev acc, i)
    in
    pieces i []
  and atom i =
    match peek i with
    | Some '[' -> Some (char_class (i + 1))
    | Some '(' ->
        let p, i = pattern (i + 1) in
        Some (Sub p, expect ')' i)
    | Some c when is_literal c -> Some (Literal c, i + 1)
    | _ -> None
  in
  match pattern 0 with
  | p, i when i = n -> Some (p, flags)
  | _ -> None
  | exception No_match -> None

let size_cap =
  (1001
  [@mutaml.skip
    "the size is only compared with 1,000, so every cap above 1,000 gives the \
     same results"])

(* @satisfies identifiers#reject-oversized-id-patterns=v1 *)
let rec size_of_branches branches =
  List.fold_left
    (fun total b -> min size_cap (total + size_of_branch b))
    0 branches

and size_of_branch b =
  List.fold_left (fun total p -> min size_cap (total + size_of_piece p)) 0 b

and size_of_piece p =
  let atom =
    match p.atom with Literal _ | Class _ -> 1 | Sub bs -> size_of_branches bs
  in
  min size_cap (atom * p.copies)

(* @satisfies identifiers#reject-empty-id-fit=v1 *)
let rec nullable_branches branches = List.exists nullable_branch branches
and nullable_branch b = List.for_all nullable_piece b

and nullable_piece p =
  p.least = 0
  ||
  match p.atom with
  | Literal _ | Class _ -> false
  | Sub bs -> nullable_branches bs

(* @satisfies identifiers#decide-fit=v1 *)
let compile branches =
  let states = Dynarray.create () in
  let add state =
    Dynarray.add_last states state;
    Dynarray.length states - 1
  in
  let set i state = Dynarray.set states i state in
  let rec alternatives branches next =
    match branches with
    | [] -> next
    | [ b ] -> sequence b next
    | b :: rest ->
        let first = sequence b next in
        add (Split (first, alternatives rest next))
  and sequence pieces next =
    List.fold_right (fun p next -> piece p next) pieces next
  and atom a next =
    match a with
    | Literal c -> add (Step ([ (c, c) ], next))
    | Class members -> add (Step (members, next))
    | Sub bs -> alternatives bs next
  and piece p next =
    let tail =
      match p.most with
      | None ->
          let loop = add Accept in
          set loop (Split (atom p.atom loop, next));
          loop
      | Some most ->
          let rec optional k cur =
            if k = 0 then cur
            else optional (k - 1) (add (Split (atom p.atom cur, next)))
          in
          optional (most - p.least) next
    in
    let rec mandatory k cur =
      if k = 0 then cur else mandatory (k - 1) (atom p.atom cur)
    in
    mandatory p.least tail
  in
  let accept = add Accept in
  let start = alternatives branches accept in
  (Dynarray.to_array states, start)

let in_alphabet = function
  | '!' .. '"'
  | '$' .. '.'
  | '0' .. '<'
  | '>' .. '?'
  | 'A' .. '['
  | ']'
  | '_' .. '~' ->
      true
  | _ -> false

(* @satisfies identifiers#accept-inputs=v1 *)
let of_string text =
  if not (String.for_all in_alphabet text) then Error Unmatched
    (* @satisfies identifiers#reject-long-id-patterns=v1 *)
  else if String.length text > 1000 then Error Too_long
  else
    match parse text with
    | None -> Error Unmatched
    | Some (_, { reversed_range = true; _ }) -> Error Reversed_range
    | Some (_, { large_count = true; _ }) -> Error Large_count
    | Some (_, { reversed_bounds = true; _ }) -> Error Reversed_bounds
    | Some (branches, _) ->
        if size_of_branches branches > 1000 then Error Oversized
        else if nullable_branches branches then Error Empty_id_fits
        else
          let states, start = compile branches in
          Ok { text; states; start }

let to_string pattern = pattern.text

(* @satisfies identifiers#decide-fit=v1 *)
let fits pattern id =
  let count = Array.length pattern.states in
  let closure set =
    let seen = Array.make count false in
    let rec visit acc i =
      if seen.(i) then acc
      else begin
        seen.(i) <- true;
        match pattern.states.(i) with
        | Split (a, b) -> visit (visit acc a) b
        | Step _ | Accept -> i :: acc
      end
    in
    List.fold_left visit [] set
  in
  let step set c =
    List.filter_map
      (fun i ->
        match pattern.states.(i) with
        | Step (members, next)
          when List.exists (fun (low, high) -> low <= c && c <= high) members ->
            Some next
        | _ -> None)
      set
  in
  let final =
    String.fold_left
      (fun set c -> closure (step set c))
      (closure [ pattern.start ])
      id
  in
  List.exists (fun i -> pattern.states.(i) = Accept) final
