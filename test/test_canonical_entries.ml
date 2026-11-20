(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_identifiers
open Test_identifier_patterns
open Test_identifier_lines
open Sinter_inline_citations
module Gen = QCheck2.Gen

let kind_word_of_text text =
  match Kind_word.of_string text with
  | Some word -> word
  | None -> Alcotest.failf "not a kind word: %s" text

let optional_member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | other ->
      Alcotest.failf "not a JSON object: %s" (Yojson.Basic.to_string other)

let entry_kind_words = function
  | `List entries ->
      List.map
        (fun entry ->
          Option.map
            (fun word -> kind_word_of_text (json_string word))
            (optional_member "kind-word" entry))
        entries
  | other ->
      Alcotest.failf "not a JSON array: %s" (Yojson.Basic.to_string other)

let citation_entries binding text =
  List.find_map
    (fun (input : Tag_line.input) ->
      match input.result with
      | Tag_line.Valid (Tag_line.Citation { entries; _ }) -> Some entries
      | _ -> None)
    (Tag_line.read binding (text_of text))

let inline_targets binding text =
  List.filter_map
    (fun (link : Inline_citation.link) ->
      match link.result with
      | Inline_citation.Valid { target; _ } -> Some target
      | _ -> None)
    (Inline_citation.read binding (text_of text))

let targets_of binding text =
  match citation_entries binding text with
  | Some entries -> entries
  | None -> inline_targets binding text

let forms ?slug targets kind_words =
  if List.length targets <> List.length kind_words then
    Alcotest.failf "%d targets for %d kind words" (List.length targets)
      (List.length kind_words);
  List.map2
    (fun target kind_word -> Canonical.entry ?slug ?kind_word target)
    targets kind_words

let give_forms (vector : Vectors.vector) =
  let binding, text = read_input vector in
  let slug = Option.map json_string (optional_member "slug" vector.input) in
  let kind_words = entry_kind_words (json_member "entries" vector.input) in
  let forms = forms ?slug (targets_of binding text) kind_words in
  `Assoc [ ("values", `Assoc [ ("forms", `List (List.map str forms)) ]) ]

(* @verifies identifiers[canonical-entries][*]=v1
   Each vector reads the citation entries of its citation, or the target of its
   inline citation, and compares the canonical form of each with its slug and
   kind word against the form that the vector gives. *)
let canonical_entry_vectors =
  Vectors.group set ~name:"canonical-entries" ~form:"#canonical-entry-vector=v1"
    give_forms

type expected = { name : string; suffix : string }

let expected_form ?slug kind_word { name; suffix } =
  let name =
    match slug with
    | Some slug when slug <> "" && name.[0] = '#' -> slug ^ name
    | _ -> name
  in
  let kind =
    match kind_word with
    | Some word -> Kind_word.to_string word ^ ":"
    | None -> ""
  in
  kind ^ name ^ suffix

let selection_text_gen allowed index = Gen.map fst (selection_gen allowed index)

let single_entry_gen rules index =
  let open Gen in
  let* kind = kind_gen
  and* slug = slug_gen index
  and* part = unique_segment index in
  let* selection = selection_text_gen rules.selections index in
  let* revision = revision_gen rules.star and* label = label_gen in
  let* shape = int_range 0 (if rules.every_part then 4 else 3) in
  let* external_part = bool in
  let internal name =
    ( kind_prefix kind ^ name ^ selection ^ "=" ^ revision,
      { name; suffix = selection } )
  in
  return
    (match shape with
    | 0 -> internal slug
    | 1 -> internal (slug ^ "#" ^ part)
    | 2 -> internal ("#" ^ part)
    | 3 ->
        let id =
          "gh/"
          ^ string_of_int (index + 1)
          ^ if external_part then "#" ^ part else ""
        in
        (kind_prefix kind ^ id, { name = id; suffix = "" })
    | _ -> (slug ^ "=" ^ label ^ "#*", { name = slug; suffix = "#*" }))

let scoped_entries_gen rules index =
  let open Gen in
  let* kind = kind_gen and* slug = slug_gen index and* with_slug = bool in
  let* count = int_range 1 3 and* trailing = bool in
  let* spaces = list_size (int_range 4 4) list_space_gen in
  let space k = List.nth spaces k in
  let* parts =
    flatten_list
      (List.init count (fun k ->
           let* part = unique_segment (1000 + (index * 10) + k) in
           let* selection = selection_text_gen rules.selections k in
           let* revision = revision_gen rules.star in
           let name = (if with_slug then slug else "") ^ "#" ^ part in
           return
             (part ^ selection ^ "=" ^ revision, { name; suffix = selection })))
  in
  return
    ( kind_prefix kind
      ^ (if with_slug then slug else "")
      ^ "#{" ^ space 0
      ^ String.concat (space 1 ^ "," ^ space 2) (List.map fst parts)
      ^ (if trailing then space 3 ^ "," else "")
      ^ "}",
      List.map snd parts )

let canonical_citation_gen =
  let open Gen in
  let* word =
    one_of [ "@cites"; "@verifies"; "@refines"; "@satisfies"; "@supersedes" ]
  in
  let rules = rules_of word in
  let* count = int_range 1 4 and* shape = int_range 0 2 in
  let* space = list_space_gen in
  let* target, entries =
    match shape with
    | 0 ->
        map (fun (text, entry) -> (text, [ entry ])) (single_entry_gen rules 0)
    | 1 -> scoped_entries_gen rules 0
    | _ ->
        let* elements =
          flatten_list
            (List.init count (fun k ->
                 oneof
                   [
                     map
                       (fun (text, entry) -> (text, [ entry ]))
                       (single_entry_gen rules k);
                     scoped_entries_gen rules k;
                   ]))
        in
        return
          ( "{" ^ space
            ^ String.concat ("," ^ space) (List.map fst elements)
            ^ "}",
            List.concat_map snd elements )
  in
  let* slug = option (slug_gen 7)
  and* kind_words =
    list_size (return (List.length entries)) (option (oneof_list Kind_word.all))
  in
  return (word ^ " " ^ target, slug, entries, kind_words)

let print_citation (text, slug, entries, kind_words) =
  Printf.sprintf "%S, slug %s, want %s" text
    (Option.value slug ~default:"none")
    (String.concat ", " (List.map2 (expected_form ?slug) kind_words entries))

let same_forms (text, slug, entries, kind_words) =
  let want = List.map2 (expected_form ?slug) kind_words entries in
  let have = forms ?slug (targets_of standard_binding text) kind_words in
  have = want
  ||
  (Printf.eprintf "have: %s\n" (String.concat ", " have);
   false)

(* @verifies identifiers#give-canonical-entries=v1
   The citations come from the grammar, with every shape of citation entry, a
   slug or none, and a kind word or none for each entry; the form that each
   entry must give follows the steps of the term canonical-entry, so a slug put
   before a name that does not start with `#`, a revision or a kind word of the
   entry left in the form, or a lost vector selection or `#*` fails. *)
let citations_give_their_canonical_forms =
  property ~count:1000
    ~name:"each citation entry gives the canonical form of the design"
    ~print:print_citation canonical_citation_gen same_forms

let inline_label_gen =
  Gen.oneof
    [
      Gen.return "*";
      Gen.map
        (fun digits -> "v" ^ digits)
        (word_gen "0123456789" (Gen.int_range 1 3));
    ]

let inline_target_gen =
  let open Gen in
  let* kind = kind_gen
  and* slug = slug_gen 0
  and* part = unique_segment 1
  and* label = inline_label_gen
  and* shape = int_range 0 3
  and* external_part = bool in
  let internal name =
    (kind_prefix kind ^ name ^ "=" ^ label, { name; suffix = "" })
  in
  return
    (match shape with
    | 0 -> internal slug
    | 1 -> internal (slug ^ "#" ^ part)
    | 2 -> internal ("#" ^ part)
    | _ ->
        let id = "rfc/8259" ^ if external_part then "#" ^ part else "" in
        (kind_prefix kind ^ id, { name = id; suffix = "" }))

let inline_citation_gen =
  let open Gen in
  let* destination, entry = inline_target_gen
  and* autolink = bool
  and* slug = option (slug_gen 7)
  and* kind_word = option (oneof_list Kind_word.all) in
  let text =
    if autolink then "See <sinter:" ^ destination ^ ">."
    else "See [the target](sinter:" ^ destination ^ ")."
  in
  return (text, slug, [ entry ], [ kind_word ])

(* @verifies identifiers#give-canonical-entries=v1
   The inline citations come from the grammar of their destination, with a slug
   or none and a kind word or none; the form that the target must give follows
   the steps of the term canonical-entry from the name or the external id of the
   destination, so a revision or a kind word of the destination left in the
   form, or a slug put before a name that does not start with `#`, fails. *)
let inline_citations_give_their_canonical_forms =
  property ~count:500
    ~name:
      "the target of an inline citation gives the canonical form of the design"
    ~print:print_citation inline_citation_gen same_forms

let entry text = List.hd (targets_of standard_binding text)

let slug_is_taken_as_a_text () =
  Alcotest.(check string)
    "a text that is not a slug goes where a slug goes" "a b#notation"
    (Canonical.entry ~slug:"a b" (entry "@cites #notation=v1"));
  Alcotest.(check string)
    "the empty slug is no slug" "#notation"
    (Canonical.entry ~slug:"" (entry "@cites #notation=v1"))

let long_targets n =
  let long letter = String.make n letter in
  [
    Target.Internal
      {
        kind_word = Some Kind_word.Req;
        slug = None;
        part_name = Some (long 'p');
        vector_selection = Some (Target.Group (long 'g'));
        revision = long 'r';
      };
    Target.Internal
      {
        kind_word = None;
        slug = Some (long 's');
        part_name = Some (long 'p');
        vector_selection = Some (Target.Vector_number (long '1'));
        revision = "v1";
      };
    Target.Every_part { slug = long 's'; revision = long 'r' };
    Target.External
      {
        kind_word = None;
        namespace_name = long 'n';
        id = long '1';
        part_name = Some (long 'p');
      };
  ]
  |> List.map (fun target -> (long 'k', target))

let forms_grow_with_their_length () =
  Counted_work.check_growth ~margin:2. ~sizes:(10_000, 40_000)
    ~input:long_targets
    (List.map (fun (slug, target) ->
         Canonical.entry ~slug ~kind_word:Kind_word.Schema target))

let vector_groups = [ canonical_entry_vectors ]

let tests =
  Vectors.tests "identifiers" vector_groups
  @ [
      Alcotest.test_case "a slug is taken as a text" `Quick
        slug_is_taken_as_a_text;
      Alcotest.test_case "the work grows with the length of the form" `Quick
        forms_grow_with_their_length;
      citations_give_their_canonical_forms;
      inline_citations_give_their_canonical_forms;
    ]
