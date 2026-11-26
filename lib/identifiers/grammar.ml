(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type rules = { vector_selection : bool; any_revision : bool }
type key = string option * string option * string option
type scope = { kind_word : Kind_word.t option; slug : string option }

(* @satisfies identifiers#{give-line-results=v1, give-link-results=v1, give-values=v1}
   A target or a citation entry starts with a kind word when the text before
   its first `:` is a kind word; that kind word is a value of its match. *)
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

let head_is_external binding s =
  Option.is_some (Binding.id_pattern binding (namespace_of s))

(* @satisfies identifiers#{give-line-results=v1, give-link-results=v1}
   A target or a citation entry is an external target when it does not
   match `content-id` and the text of its head before its first `/`, or its
   whole head when the head holds no `/`, is the namespace name of an
   external namespace of the binding. *)
let is_external binding s =
  head_is_external binding s && not (Lexical.is_content_id s)

let ends s i = i = String.length s
let peek s i = if i < String.length s then Some s.[i] else None
let sub s i j = String.sub s i (j - i)

(* @satisfies identifiers#{give-line-results=v1, give-link-results=v1, give-values=v1}
   An external target has a match only as `external-ref` whose id fits the id
   pattern of its external namespace; its entry name is the external id with
   its `#` and part name, and its values are the namespace name, the id, and
   the part name. *)
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

(* @satisfies identifiers#{give-line-results=v1, give-link-results=v1, give-values=v1}
   A name is a slug, a full name, or `#` and a part name, and its slug and
   its part name are values of its match. *)
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

(* @satisfies identifiers#{give-line-results=v1, give-values=v1}
   A vector selection is `[`, a group name, and `]`, or `[*]`; it gives the
   group name or every vector. *)
let vector_selection r i =
  if peek r i <> Some '[' then None
  else if peek r (i + 1) = Some '*' && peek r (i + 2) = Some ']' then
    Some (Target.Every_vector, i + 3)
  else
    match Lexical.group_name r (i + 1) with
    | Some j when peek r j = Some ']' ->
        Some (Target.Group (sub r (i + 1) j), j + 1)
    | _ -> None

(* @satisfies identifiers#{give-line-results=v1, give-link-results=v1, give-values=v1}
   After the name comes `=` and a revision that the rules allow, or, where
   the rules allow one, a vector selection in place of `=` and a revision.
   The key is the entry name and the text of the vector selection, which
   `citation-line` compares between entries. *)
let finish rules kind_word slug part_name r i =
  match if rules.vector_selection then vector_selection r i else None with
  | Some (selection, j) ->
      if ends r j then
        Some
          ( Target.Internal
              {
                kind_word;
                slug;
                part_name;
                suffix = Target.Vector_selection selection;
              },
            (slug, part_name, Some (sub r i j)) )
      else None
  | None -> (
      let revision =
        if peek r i <> Some '=' then None
        else if rules.any_revision && peek r (i + 1) = Some '*' then Some (i + 2)
        else Lexical.label r (i + 1)
      in
      match revision with
      | Some k when ends r k ->
          Some
            ( Target.Internal
                {
                  kind_word;
                  slug;
                  part_name;
                  suffix = Target.Revision (sub r (i + 1) k);
                },
              (slug, part_name, None) )
      | _ -> None)

let internal rules kind_word r =
  match name r with
  | None -> None
  | Some (slug, part_name, i) -> finish rules kind_word slug part_name r i

(* @satisfies identifiers#{give-line-results=v1, give-values=v1}
   A scoped list starts with an optional kind word and `:` and an optional
   slug; each part stands for a single target with that kind word and slug,
   so a part never matches when that single target is external. *)
let scope binding prefix =
  let kind_word, r = after_kind_word prefix in
  if head_is_external binding prefix then None
  else if r = "" then Some { kind_word; slug = None }
  else if Lexical.slug r 0 = Some (String.length r) then
    Some { kind_word; slug = Some r }
  else None

(* @satisfies identifiers#{give-line-results=v1, give-values=v1}
   A part of a scoped list is a part name followed by what the rules allow
   after a name. *)
let part rules scope text =
  match Lexical.segment text 0 with
  | Some i ->
      finish rules scope.kind_word scope.slug
        (Some (String.sub text 0 i))
        text i
  | None -> None

(* @satisfies identifiers#{citation-line=v1, inline-destination=v1, give-line-results=v1, give-link-results=v1, give-values=v1}
   A single target is an external id when it is external, a content id when
   the whole target matches `content-id`, and a name otherwise; the one value
   and the entry name of a content id are the whole content id. *)
let single binding rules s =
  let kind_word, r = after_kind_word s in
  if is_external binding s then external_ref binding kind_word r
  else if Lexical.is_content_id s then
    Some (Target.Content_id s, (Some s, None, None))
  else internal rules kind_word r
