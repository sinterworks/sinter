(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type hunk = { old_start : int; removed : int; new_start : int; added : int }

type t = {
  old_content : string option;
  new_content : string option;
  old_lines : Lines.t option;
  new_lines : Lines.t option;
  targets : int array;
}

(* @satisfies changes#give-hunks=v1
   A content gives line texts only when it is valid UTF-8, and then the lines
   of its text; a missing file and a content that is not valid UTF-8 give
   none, so the hunks count no line of them. *)
let lines_of content =
  match content with
  | None -> None
  | Some bytes -> (
      match Text.decode bytes with
      | Ok text -> Some (Lines.of_text text)
      | Error _ -> None)

let line_texts lines =
  match lines with
  | None -> [||]
  | Some lines ->
      let text = Lines.text lines in
      Array.of_list
        (List.map Text.encode
           (List.filter_map (Text.sub text) (Lines.all lines)))

module Texts = Set.Make (String)
module Ids = Map.Make (String)

let intern olds news =
  let in_news =
    Array.fold_left (fun set line -> Texts.add line set) Texts.empty news
  in
  let ids = ref Ids.empty in
  let shared place line =
    if Texts.mem line in_news then (
      match Ids.find_opt line !ids with
      | Some k -> Some k
      | None ->
          ids := Ids.add line place !ids;
          Some place)
    else None
  in
  let a = Array.mapi shared olds in
  let b = Array.map (fun line -> Ids.find_opt line !ids) news in
  (a, b)

let bisect a b x0 x1 y0 y1 =
  let n = x1 - x0 and m = y1 - y0 in
  let delta = n - m in
  let off = m + 1 in
  let size =
    n + m
    + (3
      [@mutaml.skip
        "An array longer than its last index changes no result: the walks read \
         and write only the indices from 0 to n + m + 2."])
  in
  let forward = Array.make size (-1) and backward = Array.make size (n + 1) in
  let exception Split of int * int in
  let rec step d =
    let low = Int.max (-d) (-m) and high = Int.min d n in
    let k = ref (low + (low lxor d land 1)) in
    while !k <= high do
      let i = off + !k in
      let x =
        ref
          (Int.min
             (Int.max (forward.(i - 1) + 1) forward.(i + 1))
             (Int.min n (m + !k)))
      in
      while !x < n && !x - !k < m && a.(x0 + !x) = b.(y0 + !x - !k) do
        incr x
      done;
      forward.(i) <- !x;
      k := !k + 2
    done;
    let low = Int.max (delta - d) (-m) and high = Int.min (delta + d) n in
    let k = ref (low + (low lxor delta lxor d land 1)) in
    while !k <= high do
      let i = off + !k in
      let x =
        ref
          (Int.max
             (Int.min (backward.(i + 1) - 1) backward.(i - 1))
             (Int.max 0 !k))
      in
      while
        Int.min !x (!x - !k) > 0 && a.(x0 + !x - 1) = b.(y0 + !x - !k - 1)
      do
        decr x
      done;
      backward.(i) <- !x;
      if forward.(i) >= !x then raise (Split (!x, !x - !k));
      k := !k + 2
    done;
    step (d + 1)
  in
  try step 0 with Split (x, y) -> (x, y)

let kept ids =
  Array.of_list
    (List.filter_map
       (fun (place, id) -> Option.map (fun k -> (place, k)) id)
       (List.mapi (fun place id -> (place, id)) (Array.to_list ids)))

(* @satisfies changes#{give-hunks=v1, give-new-line-numbers=v1}
   The hunks and the new line numbers come from these pairs, which are a line
   map. The pairs come from a shortest edit script between the two sequences of
   line texts, which Myers' algorithm finds exactly: after the common first
   and last lines, and without the lines that do not occur in the other
   sequence, which can be in no pair, the first overlap of the furthest
   forward and backward paths of each part splits it into two parts whose
   scripts join into a shortest one. *)
let longest a b =
  let targets = Array.make (Array.length a) 0 in
  let ka = kept a and kb = kept b in
  let pa = Array.map fst ka and ra = Array.map snd ka in
  let pb = Array.map fst kb and rb = Array.map snd kb in
  let pair x y = targets.(pa.(x)) <- pb.(y) + 1 in
  let parts = Stack.create () in
  Stack.push (0, Array.length ra, 0, Array.length rb) parts;
  while not (Stack.is_empty parts) do
    let x0, x1, y0, y1 = Stack.pop parts in
    let x0 = ref x0 and y0 = ref y0 and x1 = ref x1 and y1 = ref y1 in
    while !x0 < !x1 && !y0 < !y1 && ra.(!x0) = rb.(!y0) do
      pair !x0 !y0;
      incr x0;
      incr y0
    done;
    while !x0 < !x1 && !y0 < !y1 && ra.(!x1 - 1) = rb.(!y1 - 1) do
      decr x1;
      decr y1;
      pair !x1 !y1
    done;
    if !x0 < !x1 && !y0 < !y1 then begin
      let x, y = bisect ra rb !x0 !x1 !y0 !y1 in
      Stack.push (!x0, !x0 + x, !y0, !y0 + y) parts;
      Stack.push (!x0 + x, !x1, !y0 + y, !y1) parts
    end
  done;
  targets

let compute old_content new_content =
  let old_lines = lines_of old_content and new_lines = lines_of new_content in
  let a, b = intern (line_texts old_lines) (line_texts new_lines) in
  { old_content; new_content; old_lines; new_lines; targets = longest a b }

let pairs map =
  let found = ref [] in
  for i = Array.length map.targets downto 1 do
    let j = map.targets.(i - 1) in
    if j > 0 then found := (i, j) :: !found
  done;
  !found

let count lines = Option.fold ~none:0 ~some:Lines.count lines

(* @satisfies changes#give-hunks=v1
   With the pairs (0, 0) and (m + 1, n + 1) around the pairs of the map, each
   pair whose next pair is not right after it in both trees gives the hunk of
   the lines between them. *)
let gaps map =
  let m = count map.old_lines and n = count map.new_lines in
  let bounded = ((0, 0) :: pairs map) @ [ (m + 1, n + 1) ] in
  let rec walk acc = function
    | (i, j) :: ((i', j') :: _ as rest) ->
        let acc =
          if i' > i + 1 || j' > j + 1 then
            {
              old_start = i + 1;
              removed = i' - i - 1;
              new_start = j + 1;
              added = j' - j - 1;
            }
            :: acc
          else acc
        in
        walk acc rest
    | _ -> List.rev acc
  in
  walk [] bounded

(* @satisfies changes#give-hunks=v1
   When the gaps give no hunk, a file in one tree only, or two different
   contents of which one is not valid UTF-8, gives the hunk with no line. *)
let lineless map =
  match (map.old_content, map.new_content) with
  | Some _, None | None, Some _ -> true
  | Some old_bytes, Some new_bytes ->
      (not (String.equal old_bytes new_bytes))
      && (Option.is_none map.old_lines || Option.is_none map.new_lines)
  | None, None -> false

let hunks map =
  match gaps map with
  | [] when lineless map ->
      [ { old_start = 1; removed = 0; new_start = 1; added = 0 } ]
  | found -> found

(* @satisfies changes#give-new-line-numbers=v1
   An old line has the new line number of the pair that holds it, and none
   when no pair holds it. *)
let new_line_number map i =
  if i < 1 || i > Array.length map.targets then None
  else match map.targets.(i - 1) with 0 -> None | j -> Some j

let line lines k =
  Option.bind lines (fun lines ->
      Option.bind (Lines.line lines k) (Text.sub (Lines.text lines)))

let old_line map i = line map.old_lines i
let new_line map j = line map.new_lines j
