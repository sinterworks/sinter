(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type tag =
  | Declaration of {
      word : Tag_word.t;
      slug : string;
      part_name : string option;
      revision : string option;
      inline_description : string;
    }
  | Citation of {
      word : Tag_word.t;
      entries : Target.t list;
      inline_description : string;
    }
  | Status_tag of { word : Tag_word.t; inline_description : string }
  | Extern of {
      kind_word : Kind_word.t;
      part_name : string;
      inline_description : string;
    }
  | Ack of { slug : string; subject : string; hash_prefix : string }

type line_result =
  | Not_a_tag_line
  | Other_tag_word of string
  | Invalid of Tag_word.t
  | Valid of tag

type input = { first_line : int; last_line : int; result : line_result }

let tag_word = function
  | Declaration { word; _ } | Citation { word; _ } | Status_tag { word; _ } ->
      word
  | Extern _ -> Tag_word.Extern
  | Ack _ -> Tag_word.Ack

let length = String.length
let peek s i = if i < length s then Some s.[i] else None
let sub s i j = String.sub s i (j - i)
let is_wsp_at s i = i < length s && Lexical.is_wsp s.[i]

let rest s i =
  if i = length s then Some ""
  else if is_wsp_at s i then
    let j = Lexical.skip_wsp s i in
    Some (sub s j (length s))
  else None

let target_start s k =
  if is_wsp_at s k then Some (Lexical.skip_wsp s k) else None

let target_end s i =
  let rec go j =
    if j < length s && not (Lexical.is_wsp s.[j]) then go (j + 1) else j
  in
  go i

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let declaration binding word s k =
  let ( let* ) = Option.bind in
  let* i = target_start s k in
  if Grammar.is_external binding (sub s i (target_end s i)) then None
  else
    let* slug_end = Lexical.slug s i in
    let* part_name, j =
      if peek s slug_end = Some '#' then
        Option.map
          (fun j -> (Some (sub s (slug_end + 1) j), j))
          (Lexical.segment s (slug_end + 1))
      else if word = Tag_word.Spec && Lexical.segment s i <> Some slug_end then
        None
      else Some (None, slug_end)
    in
    let* revision, q =
      if peek s j = Some '=' then
        Option.map
          (fun q -> (Some (sub s (j + 1) q), q))
          (Lexical.label s (j + 1))
      else if word = Tag_word.Term then Some (None, j)
      else None
    in
    let* inline_description = rest s q in
    match (word, part_name) with
    | (Tag_word.Decision | Design | Finding_class), Some _ -> None
    | _ ->
        Some
          (Declaration
             {
               word;
               slug = sub s i slug_end;
               part_name;
               revision;
               inline_description;
             })

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1} *)
let rules_of = function
  | Tag_word.Cites ->
      {
        Grammar.vector_selection = true;
        any_revision = true;
        every_part = false;
      }
  | Verifies ->
      {
        Grammar.vector_selection = true;
        any_revision = false;
        every_part = false;
      }
  | Supersedes ->
      {
        Grammar.vector_selection = false;
        any_revision = false;
        every_part = true;
      }
  | _ ->
      {
        Grammar.vector_selection = false;
        any_revision = false;
        every_part = false;
      }

let is_list_space c = Lexical.is_wsp c || c = '\n'

let skip_list_space s i =
  let rec go i =
    if i < length s && is_list_space s.[i] then go (i + 1) else i
  in
  go i

let element_end s i =
  let rec go j =
    match peek s j with
    | Some (' ' | '\t' | '\n' | ',' | '}' | '{') | None -> j
    | Some _ -> go (j + 1)
  in
  go i

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1} *)
let list s i element =
  let ( let* ) = Option.bind in
  let rec items i acc =
    let* item, j = element (skip_list_space s i) in
    let j = skip_list_space s j in
    match peek s j with
    | Some ',' -> (
        let k = skip_list_space s (j + 1) in
        match peek s k with
        | Some '}' -> Some (List.rev (item :: acc), k + 1)
        | _ -> items k (item :: acc))
    | Some '}' -> Some (List.rev (item :: acc), j + 1)
    | _ -> None
  in
  items i []

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let citation binding word s k =
  let ( let* ) = Option.bind in
  let rules = rules_of word in
  let entry text = Grammar.single binding rules text in
  let single i =
    let j = element_end s i in
    Option.map (fun e -> ([ e ], j)) (entry (sub s i j))
  in
  let scoped i =
    let j = element_end s i in
    if peek s j = Some '{' && s.[j - 1] = '#' then
      match Grammar.scope binding (sub s i (j - 1)) with
      | Some scope ->
          let part p =
            let q = element_end s p in
            Option.map (fun e -> (e, q)) (Grammar.part rules scope (sub s p q))
          in
          list s (j + 1) part
      | None -> None
    else None
  in
  let element i = match scoped i with Some r -> Some r | None -> single i in
  let* i = target_start s k in
  let* groups, j =
    if peek s i = Some '{' then list s (i + 1) element
    else Option.map (fun (g, j) -> ([ g ], j)) (element i)
  in
  let* inline_description = rest s j in
  let entries = List.concat groups in
  (* @satisfies identifiers#reject-repeated-entries=v1 *)
  let keys = List.sort compare (List.map snd entries) in
  let rec distinct = function
    | a :: (b :: _ as others) -> a <> b && distinct others
    | _ -> true
  in
  if distinct keys then
    Some (Citation { word; entries = List.map fst entries; inline_description })
  else None

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let status word s k =
  Option.map
    (fun inline_description -> Status_tag { word; inline_description })
    (rest s k)

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let extern s k =
  let ( let* ) = Option.bind in
  let* i = target_start s k in
  let target = sub s i (target_end s i) in
  let* kind_word, j = Grammar.kind_word target in
  let* q = Lexical.segment s (i + j) in
  let* inline_description = rest s q in
  Some (Extern { kind_word; part_name = sub s (i + j) q; inline_description })

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let ack s k =
  let ( let* ) = Option.bind in
  let* i = target_start s k in
  let rec last_text j =
    if Lexical.is_wsp s.[j - 1] then last_text (j - 1) else j
  in
  let e = last_text (length s) in
  let slug_end = target_end s i in
  let rec hash_start j =
    if Lexical.is_wsp s.[j - 1] then j else hash_start (j - 1)
  in
  let* h = if slug_end < e then Some (hash_start e) else None in
  let subject_start = Lexical.skip_wsp s slug_end in
  let subject =
    if subject_start < h then sub s subject_start (last_text h) else ""
  in
  let hash_prefix = sub s h e in
  if Lexical.slug s i = Some slug_end && Lexical.is_hash_prefix hash_prefix then
    Some (Ack { slug = sub s i slug_end; subject; hash_prefix })
  else None

let parse binding word s k =
  match word with
  | Tag_word.Decision | Design | Finding_class | Req | Spec | Term ->
      declaration binding word s k
  | Cites | Refines | Satisfies | Supersedes | Verifies ->
      citation binding word s k
  | Deferred | Deprecated | Rejected -> status word s k
  | Extern -> extern s k
  | Ack -> ack s k

let is_citation = function
  | Tag_word.Cites | Refines | Satisfies | Supersedes | Verifies -> true
  | _ -> false

let tag_start s =
  let j = Lexical.skip_wsp s 0 in
  if peek s j = Some '@' then Some j else None

let is_blank s = Lexical.skip_wsp s 0 = length s

let read binding text =
  let lines =
    Array.of_list
      (List.map
         (fun run ->
           Text.encode (Option.value ~default:Text.empty (Text.sub text run)))
         (Lines.all (Lines.of_text text)))
  in
  let count = Array.length lines in
  (* @satisfies identifiers#give-no-results-for-non-inputs=v1 *)
  let continued s k first =
    let buffer = Buffer.create (length s) in
    Buffer.add_string buffer s;
    let rec scan pos depth last =
      if pos < Buffer.length buffer then
        let c = Buffer.nth buffer pos in
        if Lexical.is_wsp c && depth <= 0 then last
        else
          scan (pos + 1)
            (depth + match c with '{' -> 1 | '}' -> -1 | _ -> 0)
            last
      else if
        depth > 0
        && last + 1 < count
        && tag_start lines.(last + 1) = None
        && not (is_blank lines.(last + 1))
      then begin
        let next = lines.(last + 1) in
        let j = Lexical.skip_wsp next 0 in
        Buffer.add_char buffer '\n';
        Buffer.add_string buffer (sub next j (length next));
        scan pos depth (last + 1)
      end
      else last
    in
    let last = scan (Lexical.skip_wsp s k) 0 first in
    (Buffer.contents buffer, last)
  in
  (* @satisfies identifiers#{give-results=v1, give-tag-words=v1} *)
  let rec inputs i acc =
    if i >= count then List.rev acc
    else
      let s = lines.(i) in
      let result, last =
        match tag_start s with
        | None -> (Not_a_tag_line, i)
        | Some j -> (
            let k = Lexical.tag_word s j in
            let word = sub s j k in
            match Tag_word.of_string word with
            | None -> (Other_tag_word word, i)
            | Some tag ->
                let s, last =
                  if is_citation tag && is_wsp_at s k then continued s k i
                  else (s, i)
                in
                ( (match parse binding tag s k with
                  | Some t -> Valid t
                  | None -> Invalid tag),
                  last ))
      in
      inputs (last + 1)
        ({ first_line = i + 1; last_line = last + 1; result } :: acc)
  in
  inputs 0 []
