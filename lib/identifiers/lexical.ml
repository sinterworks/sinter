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
  | '_' .. 'z'
  | '|' | '~' ->
      true
  | _ -> false

let id_text s i = one_or_more s i is_id_char

let lower_name s i =
  separated s i
    ~first:(function 'a' .. 'z' -> true | _ -> false)
    ~member:is_lower_alnum ~separator:(( = ) '-')

let group_name = lower_name

let object_kind_words =
  [
    "abandoned";
    "approval";
    "atom";
    "decision";
    "decline";
    "delivered";
    "design";
    "done";
    "ext";
    "name";
    "pin";
    "plan";
    "plan-def";
    "progress";
    "req";
    "schema";
    "scope";
    "spec";
    "task";
    "task-def";
    "term";
    "vector-group";
    "vector-group-def";
    "vector-set";
    "void";
  ]

let is_hex_digit = function '0' .. '9' | 'a' .. 'f' -> true | _ -> false

(* @satisfies identifiers#{give-line-results=v1, give-link-results=v1}
   A content id is one of the twenty-five object kind words, in lower case,
   then `:`, then exactly 32 lower-case hex digits. *)
let is_content_id s =
  match String.index_opt s ':' with
  | Some colon ->
      String.length s = colon + 33
      && List.mem (String.sub s 0 colon) object_kind_words
      && String.for_all is_hex_digit (String.sub s (colon + 1) 32)
  | None -> false

(* @satisfies identifiers#give-tag-words=v1
   The tag word of a tag line is its `@` and the longest run of ASCII
   letters, ASCII digits, and `-` right after that `@`. *)
let tag_word s i = run s (i + 1) (fun c -> is_alnum c || c = '-')

(* @satisfies identifiers#validate-bindings=v1
   A binding meets the schema `external-namespaces` only when each of its
   namespace names matches the production `namespace-name`. *)
let is_namespace_name s = lower_name s 0 = Some (String.length s)

let is_hash_prefix s =
  let n = String.length s in
  n >= 8 && n <= 64 && String.for_all is_hex_digit s
