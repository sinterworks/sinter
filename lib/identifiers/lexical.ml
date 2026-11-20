(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let is_wsp c = c = ' ' || c = '\t'

let rec skip_wsp s i =
  if i < String.length s && is_wsp s.[i] then skip_wsp s (i + 1) else i

let is_alnum = function
  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' -> true
  | _ -> false

let is_lower_alnum = function 'a' .. 'z' | '0' .. '9' -> true | _ -> false
let at s i p = i < String.length s && p s.[i]

let run s i p =
  let rec go j = if at s j p then go (j + 1) else j in
  go i

let one_or_more s i p = if at s i p then Some (run s i p) else None

let separated s i ~first ~member ~separator =
  if not (at s i first) then None
  else
    let rec go j =
      if at s j separator && at s (j + 1) member then go (run s (j + 1) member)
      else j
    in
    Some (go (run s i member))

let segment s i =
  separated s i ~first:is_alnum ~member:is_alnum ~separator:(function
    | '-' | '_' | '.' -> true
    | _ -> false)

let slug s i =
  match segment s i with
  | None -> None
  | Some j ->
      let rec go j =
        if at s j (( = ) '/') then
          match segment s (j + 1) with Some k -> go k | None -> j
        else j
      in
      Some (go j)

let is_label_char = function
  | '!' .. '"'
  | '$' .. ')'
  | '+'
  | '-' .. '.'
  | '0' .. '<'
  | '>' .. '?'
  | 'A' .. 'Z'
  | '\\'
  | '^' .. 'z'
  | '|' | '~' ->
      true
  | _ -> false

let label s i = one_or_more s i is_label_char

let is_id_char = function
  | '!' .. '"'
  | '$' .. '+'
  | '-' .. '.'
  | '0' .. '<'
  | '>' .. '?'
  | 'A' .. 'Z'
  | '\\'
  | '^' .. 'z'
  | '|' | '~' ->
      true
  | _ -> false

let id_text s i = one_or_more s i is_id_char

let lower_name s i =
  separated s i
    ~first:(function 'a' .. 'z' -> true | _ -> false)
    ~member:is_lower_alnum ~separator:(( = ) '-')

let group_name = lower_name

let vector_number s i =
  if at s i (function '1' .. '9' -> true | _ -> false) then
    Some (run s i (function '0' .. '9' -> true | _ -> false))
  else None

(* @satisfies identifiers#give-tag-words=v1 *)
let tag_word s i = run s (i + 1) (fun c -> is_alnum c || c = '-')

(* @satisfies identifiers#reject-malformed-namespace-names=v1 *)
let is_namespace_name s = lower_name s 0 = Some (String.length s)

let is_hash_prefix s =
  let n = String.length s in
  n >= 8 && n <= 64
  && String.for_all (function '0' .. '9' | 'a' .. 'f' -> true | _ -> false) s
