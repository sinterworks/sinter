(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type rules = { vector_selection : bool; any_revision : bool; every_part : bool }
type key = string option * string option * string option
type scope = { kind_word : Kind_word.t option; slug : string option }

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let kind_word s =
  match String.index_opt s ':' with
  | Some i -> (
      match Kind_word.of_string (String.sub s 0 i) with
      | Some word -> Some (word, i + 1)
      | None -> None)
  | None -> None

let after_kind_word s =
  match kind_word s with
  | Some (word, i) -> (Some word, String.sub s i (String.length s - i))
  | None -> (None, s)

let prefix_until s stops =
  let n = String.length s in
  let rec go i =
    if i < n && not (List.mem s.[i] stops) then go (i + 1) else i
  in
  String.sub s 0 (go 0)

let namespace_of s =
  let head = prefix_until (snd (after_kind_word s)) [ '#'; '='; '[' ] in
  prefix_until head [ '/' ]

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1} *)
let is_external binding s =
  Option.is_some (Binding.id_pattern binding (namespace_of s))

let ends s i = i = String.length s
let peek s i = if i < String.length s then Some s.[i] else None
let sub s i j = String.sub s i (j - i)

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, reject-repeated-entries=v1, give-values=v1} *)
let external_ref binding kind_word r =
  let namespace_name = prefix_until r [ '/' ] in
  let i = String.length namespace_name in
  match
    (Binding.id_pattern binding namespace_name, Lexical.id_text r (i + 1))
  with
  | Some pattern, Some j when peek r i = Some '/' -> (
      let id = sub r (i + 1) j in
      let part_name =
        if ends r j then Some None
        else if peek r j = Some '#' then
          match Lexical.segment r (j + 1) with
          | Some k when ends r k -> Some (Some (sub r (j + 1) k))
          | _ -> None
        else None
      in
      match part_name with
      | Some part_name when Id_pattern.fits pattern id ->
          Some
            ( Target.External { kind_word; namespace_name; id; part_name },
              (Some (sub r 0 j), part_name, None) )
      | _ -> None)
  | _ -> None

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let name r =
  if peek r 0 = Some '#' then
    Option.map (fun j -> (None, Some (sub r 1 j), j)) (Lexical.segment r 1)
  else
    match Lexical.slug r 0 with
    | None -> None
    | Some i when peek r i = Some '#' -> (
        match Lexical.segment r (i + 1) with
        | Some j -> Some (Some (sub r 0 i), Some (sub r (i + 1) j), j)
        | None -> None)
    | Some i -> Some (Some (sub r 0 i), None, i)

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let vector_selection r i =
  if peek r i <> Some '[' then None
  else if peek r (i + 1) = Some '*' && peek r (i + 2) = Some ']' then
    Some (Target.Every_vector, i + 3)
  else
    match Lexical.vector_number r (i + 1) with
    | Some j when peek r j = Some ']' ->
        Some (Target.Vector_number (sub r (i + 1) j), j + 1)
    | Some _ -> None
    | None -> (
        match Lexical.group_name r (i + 1) with
        | Some j when sub r j (min (String.length r) (j + 4)) = "][*]" ->
            Some (Target.Group (sub r (i + 1) j), j + 4)
        | _ -> None)

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, reject-repeated-entries=v1, give-values=v1} *)
let finish rules kind_word slug part_name r i =
  let selection =
    if rules.vector_selection then vector_selection r i else None
  in
  let j = match selection with Some (_, j) -> j | None -> i in
  let revision =
    if peek r j <> Some '=' then None
    else if rules.any_revision && peek r (j + 1) = Some '*' then Some (j + 2)
    else Lexical.label r (j + 1)
  in
  let selection_text = Option.map (fun _ -> sub r i j) selection in
  match (revision, slug, part_name) with
  | Some k, _, _ when ends r k ->
      Some
        ( Target.Internal
            {
              kind_word;
              slug;
              part_name;
              vector_selection = Option.map fst selection;
              revision = sub r (j + 1) k;
            },
          (slug, part_name, selection_text) )
  | Some k, Some slug, None
    when rules.every_part && kind_word = None
         && sub r k (String.length r) = "#*" ->
      Some
        ( Target.Every_part { slug; revision = sub r (j + 1) k },
          (Some slug, None, None) )
  | _ -> None

let internal rules kind_word r =
  match name r with
  | None -> None
  | Some (slug, part_name, i) -> finish rules kind_word slug part_name r i

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let scope binding prefix =
  let kind_word, r = after_kind_word prefix in
  if is_external binding prefix then None
  else if r = "" then Some { kind_word; slug = None }
  else if Lexical.slug r 0 = Some (String.length r) then
    Some { kind_word; slug = Some r }
  else None

(* @satisfies identifiers#{reject-unmatched-inputs=v1, accept-inputs=v1, give-values=v1} *)
let part rules scope text =
  match Lexical.segment text 0 with
  | Some i ->
      finish rules scope.kind_word scope.slug
        (Some (String.sub text 0 i))
        text i
  | None -> None

let single binding rules s =
  let kind_word, r = after_kind_word s in
  if is_external binding s then external_ref binding kind_word r
  else internal rules kind_word r
