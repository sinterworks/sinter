(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_code_tag_texts
open Sinter_identifiers
open Sinter_origins
open Sinter_tag_inputs
open Sinter_tree_inputs
open Sinter_tree_items
module Gen = QCheck2.Gen

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let path_of string =
  match Path.of_text (text_of string) with
  | Ok path -> path
  | Error _ -> invalid_arg "path_of"

let path_text path = Text.encode (Path.to_text path)

type built = {
  case : Tree_gen.case;
  tree : Tree.t;
  readables : (string * Readable_file.t) list;
  reference : Items_reference.model;
  declared : Declared_items.t;
}

let build case =
  let tree, readables = Tree_gen.read case in
  let reference =
    Items_reference.model Tree_gen.namespaces readables
      (List.map (fun (path, _) -> path_text path) (Tree.files tree))
  in
  let declared =
    match
      Declared_items.make tree
        (List.map
           (fun (path, readable) ->
             Tree_file.make Tree_gen.namespaces (path_of path) readable)
           readables)
    with
    | Ok declared -> declared
    | Error _ -> invalid_arg "build"
  in
  { case; tree; readables; reference; declared }

let built_gen = Gen.map build Tree_gen.case

let same_length_of b =
  List.length (Declared_items.items b.declared) = List.length b.reference.items

let print_runs runs =
  String.concat ","
    (List.map
       (fun { Text.from; until } -> Printf.sprintf "%d-%d" from until)
       runs)

let print_lines b =
  String.concat "\n"
    (List.map2
       (fun item (r : Items_reference.item) ->
         Printf.sprintf "%d: claim %s / %s; scope %s / %s"
           (Declared_items.number item)
           (print_runs (Declared_items.claim item))
           (print_runs r.claim)
           (Option.fold ~none:"-" ~some:print_runs (Declared_items.scope item))
           (Option.fold ~none:"-" ~some:print_runs r.scope))
       (Declared_items.items b.declared)
       b.reference.items)

let print_built b =
  Tree_gen.print b.case ^ "\nclaims and scopes, given / reference:\n"
  ^ (if same_length_of b then print_lines b else "other lengths")
  ^ "\nreference: "
  ^ Yojson.Basic.to_string (Items_json.of_reference b.reference.items)
  ^ "\ngiven: "
  ^ Yojson.Basic.to_string (Items_json.of_declared b.declared)

let items_property ?(count = 200) ~name check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print:print_built built_gen check)

let project names = function
  | `List elements ->
      `List
        (List.map
           (function
             | `Assoc members ->
                 `Assoc
                   (List.filter (fun (key, _) -> List.mem key names) members)
             | other -> other)
           elements)
  | other -> other

let agree names b =
  Yojson.Basic.equal
    (project names (Items_json.of_reference b.reference.items))
    (project names (Items_json.of_declared b.declared))

(* @verifies documents#give-declared-items=v1
   For generated trees of markdown files and code files, a declared item given
   twice, missing, given for an input that is no accepted declaration, or given
   with another kind, name, file, or origin position, or out of the order of
   files and positions, differs from a direct reading of the terms item-file
   and item-name. *)
let items_follow_the_terms =
  items_property ~name:"the declared items are those of the terms"
    (agree [ "kind"; "name"; "file"; "at" ])

(* @verifies documents#give-extents=v1
   For generated trees, an extent with a line too many or too few, such as a
   line of the claim of an item that the item does not hold, or a line of the
   extent of a held item in the same file left out, differs from a direct
   reading of the terms claim and extent. *)
let extents_follow_the_terms =
  items_property ~name:"the extents are those of the terms" (agree [ "extent" ])

let containment_of_the_ontology b =
  let items = Declared_items.items b.declared in
  List.for_all
    (fun item ->
      let kind = Declared_items.kind item in
      let design = Declared_items.design item in
      let specification = Declared_items.specification item in
      (match design with
        | Some d ->
            Declared_items.kind d = Declared_items.Design
            && List.mem kind
                 Declared_items.
                   [ Specification; Schema; Requirement; Atom; Term ]
        | None -> true)
      &&
      match specification with
      | Some s -> (
          Declared_items.kind s = Declared_items.Specification
          && List.mem kind Declared_items.[ Schema; Requirement; Atom; Term ]
          &&
          match (Declared_items.design s, design) with
          | Some a, Some b -> Declared_items.equal a b
          | None, None -> true
          | _ -> false)
      | None -> true)
    items

(* @verifies documents#give-containment=v1
   For generated trees, a design or a specification given to an item that
   belongs to none, or the wrong one, such as the design of a slug that has
   two designs, or a specification of another design, differs from a direct
   reading of the terms slug-design, home-design, and tree-containment, and
   breaks the rules of containment of the Ontology. *)
let containment_follows_the_terms =
  items_property ~name:"the containment of items is that of the terms" (fun b ->
      agree [ "design"; "specification" ] b && containment_of_the_ontology b)

(* @verifies documents#give-vector-files=v1
   For generated trees with files at some vector paths, a vector path or a
   vector file other than that of the term vector-file, such as one beside the
   file of a specification, or one that two items share, differs from a direct
   reading of the term. *)
let vector_files_follow_the_term =
  items_property ~name:"the vector files of items are those of the term"
    (fun b ->
      agree [ "vector-file" ] b
      && List.for_all2
           (fun item (r : Items_reference.item) ->
             Option.map path_text (Declared_items.vector_path item)
             = r.vector_path)
           (Declared_items.items b.declared)
           b.reference.items)

let pairs b = List.combine (Declared_items.items b.declared) b.reference.items

let claims_follow_the_term =
  items_property ~name:"the claims of items are those of the term" (fun b ->
      same_length_of b
      && List.for_all
           (fun (item, (r : Items_reference.item)) ->
             Declared_items.claim item = r.claim)
           (pairs b))

let scopes_follow_the_term =
  items_property ~name:"the scopes of items are those of the term" (fun b ->
      same_length_of b
      && List.for_all
           (fun (item, (r : Items_reference.item)) ->
             Declared_items.scope item = r.scope)
           (pairs b))

let number_of = Option.map Declared_items.number

let home_designs_follow_the_term =
  items_property ~name:"the home design of each tag line and inline citation"
    (fun b ->
      List.for_all
        (fun (thing : Items_reference.thing) ->
          let file =
            List.find
              (fun f -> path_text (Tree_file.path f) = thing.path)
              (Declared_items.files b.declared)
          in
          let lines =
            Input.file_lines (Tree_file.file_lines file) thing.input
          in
          number_of
            (Declared_items.home_design b.declared (path_of thing.path) lines)
          = thing.home_design)
        b.reference.things)

let things_of b =
  List.concat_map
    (fun file ->
      let path = Tree_file.path file in
      let file_lines = Tree_file.file_lines file in
      List.map (fun run -> (path, [ run ])) (File_lines.all file_lines)
      @ List.map
          (fun (thing : Items_reference.thing) ->
            (path, Input.file_lines file_lines thing.input))
          (List.filter
             (fun (t : Items_reference.thing) -> t.path = path_text path)
             b.reference.things))
    (Declared_items.files b.declared)

let reference_holders b (path, lines) =
  let reference = Array.of_list b.reference.items in
  let holders =
    List.filter
      (fun k ->
        let r = reference.(k - 1) in
        r.file = path_text path
        && List.for_all (fun l -> List.mem l r.extent) lines)
      (List.init (Array.length reference) (fun k -> k + 1))
  in
  let extent k = reference.(k - 1).extent in
  let subset a c = List.for_all (fun l -> List.mem l (extent c)) (extent a) in
  let innermost =
    match
      List.filter (fun a -> List.for_all (fun c -> subset a c) holders) holders
    with
    | [ k ] -> Some k
    | _ -> None
  in
  (holders, innermost)

let holders_follow_the_extents =
  items_property
    ~name:"the extent holders of a thing are the items whose extents have it"
    (fun b ->
      List.for_all
        (fun (path, lines) ->
          List.map Declared_items.number
            (Declared_items.extent_holders b.declared path lines)
          = fst (reference_holders b (path, lines)))
        (things_of b))

let parts_follow_the_extents =
  items_property
    ~name:"the part of a thing is the innermost of its extent holders" (fun b ->
      List.for_all
        (fun (path, lines) ->
          Option.map Declared_items.number
            (Declared_items.part_of b.declared path lines)
          = snd (reference_holders b (path, lines)))
        (things_of b))

let slugs = [ "a"; "b"; "d"; "e"; "a/b"; "a.x"; "zz"; "x"; "r" ]

let slug_designs_follow_the_term =
  items_property ~name:"the design of a slug is that of the term" (fun b ->
      let reference = Array.of_list b.reference.items in
      List.for_all
        (fun slug ->
          let named =
            List.filter
              (fun k ->
                let r = reference.(k - 1) in
                (r.kind = Items_reference.Design
                || r.kind = Items_reference.Decision_record)
                && r.name = slug)
              (List.init (Array.length reference) (fun k -> k + 1))
          in
          let expected =
            match named with
            | [ k ] when reference.(k - 1).kind = Items_reference.Design ->
                Some k
            | _ -> None
          in
          Option.map Declared_items.number
            (Declared_items.slug_design b.declared slug)
          = expected)
        slugs)

let name_sets_follow_the_term =
  items_property ~name:"the sets of names are those of the term" (fun b ->
      let reference = Array.of_list b.reference.items in
      let numbers = List.init (Array.length reference) (fun k -> k + 1) in
      let where test = List.filter (fun k -> test reference.(k - 1)) numbers in
      let shared =
        where (fun r ->
            match r.kind with
            | Items_reference.Design | Decision_record -> true
            | Specification | Schema | Requirement | Atom | Term ->
                r.design = None && not (String.contains r.name '#'))
      in
      let check set expected =
        List.map Declared_items.number (Declared_items.members b.declared set)
        = expected
        && List.for_all
             (fun k ->
               List.map Declared_items.number
                 (Declared_items.named b.declared set reference.(k - 1).name)
               = List.filter
                   (fun j -> reference.(j - 1).name = reference.(k - 1).name)
                   expected)
             numbers
        && Declared_items.named b.declared set "no-such-name" = []
      in
      check Declared_items.Shared shared
      && List.for_all
           (fun item ->
             let k = Declared_items.number item in
             check (Declared_items.Of_design item)
               (if reference.(k - 1).kind = Items_reference.Design then
                  where (fun r -> r.design = Some k)
                else []))
           (Declared_items.items b.declared))

let items_keep_their_declarations =
  items_property
    ~name:"the items are the declarations of the tree, in their order" (fun b ->
      let items = Declared_items.items b.declared in
      let files = Declared_items.files b.declared in
      List.map (fun f -> path_text (Tree_file.path f)) files
      = List.map fst b.readables
      && List.for_all2
           (fun k item ->
             let declaration = Declared_items.declaration item in
             Declared_items.number item = k
             && Input.origin_position declaration
                = Some (Declared_items.at item)
             && Input.accepted declaration
             && List.for_all
                  (fun other ->
                    Declared_items.equal item other
                    = (Declared_items.number other = k))
                  items
             &&
             match Input.kind declaration with
             | Input.Tag_line
                 {
                   result =
                     Tag_line.Valid
                       (Tag_line.Declaration { slug; part_name; _ });
                   _;
                 } ->
                 Declared_items.target_name item = (slug, part_name)
             | _ -> false)
           (List.init (List.length items) (fun k -> k + 1))
           items
      && List.for_all
           (fun file ->
             let path = Tree_file.path file in
             List.map Declared_items.number
               (Declared_items.file_items b.declared path)
             = List.filter_map
                 (fun item ->
                   if Tree_file.path (Declared_items.file item) = path then
                     Some (Declared_items.number item)
                   else None)
                 items)
           files)

let bogus = { Text.from = -1; until = -2 }
let elsewhere = path_of "no/such/file.md"

let queries_take_no_line_for_what_is_no_file_line =
  items_property
    ~name:
      "a run that is no file line counts as no line, and a path with no file \
       has no item" (fun b ->
      List.for_all
        (fun (path, lines) ->
          let same f = f (bogus :: lines) = f lines in
          same (fun l ->
              number_of (Declared_items.home_design b.declared path l))
          && same (fun l ->
              number_of (Declared_items.part_of b.declared path l))
          && same (fun l ->
              List.map Declared_items.number
                (Declared_items.extent_holders b.declared path l))
          && Declared_items.home_design b.declared elsewhere lines = None
          && Declared_items.part_of b.declared elsewhere lines = None
          && Declared_items.extent_holders b.declared elsewhere lines = [])
        (things_of b)
      && Declared_items.file_items b.declared elsewhere = [])

let read_one ?(binding = Tree_gen.namespaces) path content =
  match Tree_gen.read { Tree_gen.files = [ (path, content) ]; code = [] } with
  | _, [ (_, readable) ] -> Tree_file.make binding (path_of path) readable
  | _ -> Alcotest.fail "one file that can be read"

let tree_of files =
  match
    Tree.of_files (List.map (fun (path, bytes) -> (path_of path, bytes)) files)
  with
  | Ok tree -> tree
  | Error _ -> Alcotest.fail "no two files at one valid path"

let two_files_at_one_path_are_refused () =
  let a = read_one "a.md" "# A\n@design a=v1\n" in
  let b = read_one "b.md" "# B\n@design b=v1\n" in
  match Declared_items.make Tree.empty [ b; a; b; a ] with
  | Error (Declared_items.Repeated_path path) ->
      Alcotest.(check string) "the least such path" "a.md" (path_text path)
  | Ok _ -> Alcotest.fail "two files at one valid path"

let each_file_gives_the_declarations_of_its_own_inputs () =
  let content = "# A\n@req gh/12=v1\n" in
  let count binding =
    match
      Declared_items.make Tree.empty [ read_one ~binding "a.md" content ]
    with
    | Ok declared -> List.length (Declared_items.items declared)
    | Error _ -> Alcotest.fail "one file"
  in
  Alcotest.(check int) "a slug where gh is no namespace" 1 (count Binding.empty);
  Alcotest.(check int)
    "an external target where gh is a namespace" 0
    (count Tree_gen.namespaces)

let vector_files_are_files_of_the_tree () =
  let design = read_one "docs/a.md" "# A\n@design a=v1\n" in
  let vector_file tree =
    match Declared_items.make tree [ design ] with
    | Ok declared -> (
        match Declared_items.items declared with
        | [ item ] -> Option.map path_text (Declared_items.vector_file item)
        | _ -> Alcotest.fail "one item")
    | Error _ -> Alcotest.fail "one file"
  in
  Alcotest.(check (option string))
    "a vector file in a tree without the file of the design"
    (Some "docs/a.test-vectors.jsonl")
    (vector_file (tree_of [ ("docs/a.test-vectors.jsonl", "") ]));
  Alcotest.(check (option string))
    "no vector file in a tree without the file at the vector path" None
    (vector_file (tree_of [ ("docs/a.md", "# A\n@design a=v1\n") ]))

let designs_in_one_paragraph count =
  let buffer = Buffer.create (count * 20) in
  Buffer.add_string buffer "# A\n";
  for k = 1 to count do
    Printf.bprintf buffer "@design a%d=v1\n" k
  done;
  read_one "docs/a.md" (Buffer.contents buffer)

let make_one file =
  match Declared_items.make Tree.empty [ file ] with
  | Ok declared -> declared
  | Error _ -> Alcotest.fail "one file"

let comment from until =
  {
    Code_reference.run = { Text.from; until };
    comment = Some Code_reference.Tagged;
    body = None;
    decoration = false;
    test = None;
  }

let definition from until body =
  {
    Code_reference.run = { Text.from; until };
    comment = None;
    body = Some [ body ];
    decoration = false;
    test = None;
  }

let code_files source nodes =
  let case =
    {
      Tree_gen.files =
        [ ("docs/d.md", "# D\n@design d=v1\n"); ("lib/w.rs", source) ];
      code =
        [
          ( "lib/w.rs",
            {
              Tree_gen.sigils =
                { Code_reference.line = [ "//" ]; block = []; inner = [] };
              nodes;
            } );
        ];
    }
  in
  let tree, readables = Tree_gen.read case in
  ( tree,
    List.map
      (fun (path, readable) ->
        Tree_file.make Tree_gen.namespaces (path_of path) readable)
      readables )

let make_all (tree, files) =
  match Declared_items.make tree files with
  | Ok declared -> declared
  | Error _ -> Alcotest.fail "files at distinct valid paths"

let code_case source nodes = make_all (code_files source nodes)

let scope_of_spec declared =
  match
    List.find_opt
      (fun item -> Declared_items.name item = "d#s")
      (Declared_items.items declared)
  with
  | Some spec -> Option.value ~default:[] (Declared_items.scope spec)
  | None -> Alcotest.fail "the specification d#s"

let runs = Alcotest.(list (pair int int))
let pairs_of = List.map (fun { Text.from; until } -> (from, until))

let a_scope_has_the_file_lines_at_the_ends_of_its_target () =
  let starts_with_t =
    code_case "// @spec d#s=v1\n@req r=v1 fn\n"
      [
        comment 0 15;
        definition 16 28 { Text.from = 26; until = 28 };
        comment 16 25;
      ]
  in
  Alcotest.check runs "a file line that starts where T starts"
    [ (2, 15); (16, 25) ]
    (pairs_of (scope_of_spec starts_with_t));
  let ends_with_t =
    code_case "// @spec d#s=v1\nfn @req r=v1\n"
      [
        comment 0 15;
        definition 16 28 { Text.from = 16; until = 18 };
        comment 19 28;
      ]
  in
  Alcotest.check runs "a file line that ends where T ends"
    [ (2, 15); (19, 28) ]
    (pairs_of (scope_of_spec ends_with_t));
  let empty_at_the_end =
    code_case "// @spec d#s=v1\nfn {}//\n"
      [
        comment 0 15;
        definition 16 23 { Text.from = 19; until = 21 };
        comment 21 23;
      ]
  in
  Alcotest.check runs "an empty file line at the boundary where T ends"
    [ (2, 15); (23, 23) ]
    (pairs_of (scope_of_spec empty_at_the_end));
  let after_t =
    code_case "// @spec d#s=v1\nfn {}@req r=v1\n"
      [
        comment 0 15;
        definition 16 21 { Text.from = 19; until = 21 };
        comment 21 30;
      ]
  in
  Alcotest.check runs "a file line that starts where T ends and ends after it"
    [ (2, 15) ]
    (pairs_of (scope_of_spec after_t))

let designs_in_one_paragraph_grow_linearly () =
  let count = 30 in
  let file = designs_in_one_paragraph count in
  let declared = make_one file in
  let path = Tree_file.path file in
  let items = Declared_items.items declared in
  Alcotest.(check int) "each item" count (List.length items);
  let section = File_lines.all (Tree_file.file_lines file) in
  Alcotest.(check bool)
    "each scope is the section" true
    (List.for_all (fun item -> Declared_items.scope item = Some section) items);
  Alcotest.(check (option int))
    "no home design, since the scopes tie" None
    (number_of
       (Declared_items.home_design declared path [ List.nth section 5 ]));
  Alcotest.(check (option int))
    "a line is a part of the design whose extent has it" (Some 5)
    (number_of (Declared_items.part_of declared path [ List.nth section 5 ]));
  Time_growth.check ~bound:10. ~size:1000 ~input:designs_in_one_paragraph
    make_one

let nested_list_items depth =
  let buffer = Buffer.create (depth * (depth + 20)) in
  Buffer.add_string buffer "# A\n@design a=v1\n\n";
  for k = 1 to depth do
    Printf.bprintf buffer "%s- @req a#r%d=v1\n"
      (String.make (2 * (k - 1)) ' ')
      k
  done;
  read_one "docs/a.md" (Buffer.contents buffer)

let nested_list_items_grow_as_their_text () =
  let file = nested_list_items 6 in
  let declared = make_one file in
  Alcotest.(check (list int))
    "the claim of each list item holds the list items in it"
    [ 6; 5; 4; 3; 2; 1 ]
    (List.map
       (fun item -> List.length (Declared_items.claim item))
       (List.tl (Declared_items.items declared)));
  Time_growth.check ~bound:40. ~size:50 ~input:nested_list_items make_one

let nested_specifications n =
  let buffer = Buffer.create (n * 40) in
  let line text =
    let from = Buffer.length buffer in
    Buffer.add_string buffer text;
    let until = Buffer.length buffer in
    Buffer.add_char buffer '\n';
    (from, until)
  in
  let opened = Array.make n 0 and closed = Array.make n 0 in
  let order = ref [] in
  for k = 1 to n do
    order := `Comment (line (Printf.sprintf "// @spec d#s%d=v1" k)) :: !order;
    opened.(k - 1) <- fst (line "fn {");
    order := `Definition k :: !order
  done;
  for k = 1 to n do
    order := `Comment (line (Printf.sprintf "// @req d#r%d=v1" k)) :: !order
  done;
  for k = n downto 1 do
    closed.(k - 1) <- snd (line "}")
  done;
  code_files (Buffer.contents buffer)
    (List.rev_map
       (function
         | `Comment (from, until) -> comment from until
         | `Definition k ->
             definition
               opened.(k - 1)
               closed.(k - 1)
               { Text.from = opened.(k - 1) + 3; until = closed.(k - 1) })
       !order)

let nested_specifications_grow_as_their_scopes () =
  let declared = make_all (nested_specifications 4) in
  let by_name name =
    List.find
      (fun item -> Declared_items.name item = name)
      (Declared_items.items declared)
  in
  Alcotest.(check (list int))
    "the scope of each specification holds the specifications in it"
    [ 8; 7; 6; 5 ]
    (List.map
       (fun k ->
         List.length
           (Option.value ~default:[]
              (Declared_items.scope (by_name (Printf.sprintf "d#s%d" k)))))
       [ 1; 2; 3; 4 ]);
  Alcotest.(check (option string))
    "a requirement belongs to the innermost specification" (Some "d#s4")
    (Option.map Declared_items.name
       (Declared_items.specification (by_name "d#r1")));
  Time_growth.check ~bound:40. ~size:50 ~input:nested_specifications make_all

let many_files n =
  let tree, readables =
    Tree_gen.read
      {
        Tree_gen.files =
          List.init n (fun k ->
              ( Printf.sprintf "docs/d%d.md" k,
                Printf.sprintf "# D\n@design d%d=v1\n@spec d%d#s=v1\n" k k ));
        code = [];
      }
  in
  ( tree,
    List.map
      (fun (path, readable) ->
        Tree_file.make Tree_gen.namespaces (path_of path) readable)
      readables )

let many_files_grow_linearly () =
  let declared = make_all (many_files 3) in
  Alcotest.(check (list string))
    "the items in the order of their files"
    [ "d0"; "d0#s"; "d1"; "d1#s"; "d2"; "d2#s" ]
    (List.map Declared_items.name (Declared_items.items declared));
  Counted_work.check_growth ~margin:1.5 ~sizes:(250, 1000) ~input:many_files
    make_all

let many_sections n =
  let buffer = Buffer.create (n * 40) in
  Buffer.add_string buffer "# Big\n@design big=v1\n\n";
  for k = 1 to n do
    Printf.bprintf buffer "## R %d\n@req r-%d=v1\nText %d.\n\n" k k k
  done;
  read_one "docs/big.md" (Buffer.contents buffer)

let many_sections_grow_linearly () =
  let count = 8 in
  let items = Declared_items.items (make_one (many_sections count)) in
  Alcotest.(check int) "each item" (count + 1) (List.length items);
  (match List.rev items with
  | last :: _ ->
      Alcotest.(check string)
        "the name of the last"
        (Printf.sprintf "big#r-%d" count)
        (Declared_items.name last);
      Alcotest.(check (option int))
        "its design" (Some 1)
        (number_of (Declared_items.design last));
      Alcotest.(check int)
        "the extent of the design"
        ((4 * count) + 2)
        (List.length (Declared_items.extent (List.hd items)))
  | [] -> Alcotest.fail "no item");
  Counted_work.check_growth ~margin:1.5 ~sizes:(500, 2000) ~input:many_sections
    make_one

let queries_grow_as_logarithms () =
  let input n =
    let file = many_sections n in
    let declared = make_one file in
    let path = Tree_file.path file in
    let lines =
      match Tree_file.line file (2 * n) with Some run -> [ run ] | None -> []
    in
    (declared, path, lines, Printf.sprintf "big#r-%d" (n / 2))
  in
  let declared, path, lines, name = input 8 in
  Alcotest.(check (option string))
    "the part of a line" (Some "big#r-4")
    (Option.map Declared_items.name
       (Declared_items.part_of declared path lines));
  Alcotest.(check (list string))
    "the named items" [ "big#r-4" ]
    (List.map Declared_items.name
       (Declared_items.named declared
          (Declared_items.Of_design (List.hd (Declared_items.items declared)))
          name));
  Time_growth.check ~bound:2.5 ~size:1000 ~input
    (Time_growth.repeat 2000 (fun (declared, path, lines, name) ->
         ( Declared_items.part_of declared path lines,
           Declared_items.home_design declared path lines,
           Declared_items.extent_holders declared path lines,
           Declared_items.slug_design declared "big",
           Declared_items.named declared Declared_items.Shared name,
           Declared_items.file_items declared path,
           Declared_items.members declared Declared_items.Shared )))

let find_span source sub =
  let n = String.length sub in
  let rec go k =
    if k + n > String.length source then invalid_arg ("find_span " ^ sub)
    else if String.sub source k n = sub then (k, k + n)
    else go (k + 1)
  in
  go 0

(* @verifies documents#{give-declared-items=v1, give-containment=v1, give-extents=v1, give-vector-files=v1}
   The test checks markdown schema and atom declarations for kinds, scopes,
   containment in designs and specifications, names, sets of names, slug_design
   non-shadowing, extents of held and unheld items, level-0 claims after front
   matter, and the absence of vector paths and vector files. *)
let schemas_and_atoms_in_markdown () =
  let d_md =
    "# D\n\
     @design d=v1\n\n\
     ## S1\n\
     @schema s1=v1\n\
     Schema text.\n\n\
     ## A1\n\
     @atom a1=v1\n\
     Atom text.\n\n\
     ## Spec\n\
     @spec sp=v1\n\n\
     ### S2\n\
     @schema s2=v1\n\n\
     ### A2\n\
     @atom a2=v1\n\n\
     ## Slash\n\
     @schema a/b=v1\n\n\
     ## Unknown\n\
     @atom none#a=v1\n"
  in
  let other_md =
    "---\n\
     title: x\n\
     ---\n\
     @schema orphan-s=v1\n\n\
     # A\n\
     @atom d=v1\n\n\
     ## External\n\
     @schema d#s3=v1\n\n\
     ## External Atom\n\
     @atom d#a3=v1\n"
  in
  let files =
    [ read_one "docs/d.md" d_md; read_one "docs/other.md" other_md ]
  in
  let tree =
    tree_of
      [
        ("docs/d.md", d_md);
        ("docs/other.md", other_md);
        ("docs/d.s1.test-vectors.jsonl", "");
        ("docs/d.a1.test-vectors.jsonl", "");
      ]
  in
  let declared = make_all (tree, files) in
  let by_name name =
    List.find
      (fun item -> Declared_items.name item = name)
      (Declared_items.items declared)
  in
  let d = by_name "d" in
  let s1 = by_name "d#s1" in
  let a1 = by_name "d#a1" in
  let sp = by_name "d#sp" in
  let s2 = by_name "d#s2" in
  let a2 = by_name "d#a2" in
  let slash = by_name "a/b" in
  let unknown = by_name "none#a" in
  let orphan_s = by_name "orphan-s" in
  let atom_d =
    List.find
      (fun item ->
        Declared_items.name item = "d"
        && Declared_items.kind item = Declared_items.Atom)
      (Declared_items.items declared)
  in
  let s3 = by_name "d#s3" in
  let a3 = by_name "d#a3" in
  Alcotest.(check bool)
    "s1 is a schema" true
    (Declared_items.kind s1 = Declared_items.Schema);
  Alcotest.(check bool)
    "a1 is an atom" true
    (Declared_items.kind a1 = Declared_items.Atom);
  Alcotest.(check bool) "s1 has no scope" true (Declared_items.scope s1 = None);
  Alcotest.(check bool) "a1 has no scope" true (Declared_items.scope a1 = None);
  Alcotest.(check (option int))
    "s1 belongs to d"
    (Some (Declared_items.number d))
    (number_of (Declared_items.design s1));
  Alcotest.(check (option int))
    "s1 belongs to no spec" None
    (number_of (Declared_items.specification s1));
  Alcotest.(check (option int))
    "a1 belongs to d"
    (Some (Declared_items.number d))
    (number_of (Declared_items.design a1));
  Alcotest.(check (option int))
    "s2 belongs to d"
    (Some (Declared_items.number d))
    (number_of (Declared_items.design s2));
  Alcotest.(check (option int))
    "s2 belongs to sp"
    (Some (Declared_items.number sp))
    (number_of (Declared_items.specification s2));
  Alcotest.(check (option int))
    "a2 belongs to d"
    (Some (Declared_items.number d))
    (number_of (Declared_items.design a2));
  Alcotest.(check (option int))
    "a2 belongs to sp"
    (Some (Declared_items.number sp))
    (number_of (Declared_items.specification a2));
  Alcotest.(check (option int))
    "a slash-slug schema belongs to no design" None
    (number_of (Declared_items.design slash));
  Alcotest.(check (option int))
    "a full-name atom with unknown slug belongs to no design" None
    (number_of (Declared_items.design unknown));
  Alcotest.(check (option int))
    "s3 in another file belongs to d"
    (Some (Declared_items.number d))
    (number_of (Declared_items.design s3));
  Alcotest.(check (option int))
    "a3 in another file belongs to d"
    (Some (Declared_items.number d))
    (number_of (Declared_items.design a3));
  Alcotest.(check (option string))
    "a schema has no vector path" None
    (Option.map path_text (Declared_items.vector_path s1));
  Alcotest.(check (option string))
    "a schema has no vector file" None
    (Option.map path_text (Declared_items.vector_file s1));
  Alcotest.(check (option string))
    "an atom has no vector path" None
    (Option.map path_text (Declared_items.vector_path a1));
  Alcotest.(check (option string))
    "an atom has no vector file" None
    (Option.map path_text (Declared_items.vector_file a1));
  let subset a b = List.for_all (fun line -> List.mem line b) a in
  Alcotest.(check bool)
    "d holds the extents of s1, a1, s2, and a2" true
    (subset (Declared_items.extent s1) (Declared_items.extent d)
    && subset (Declared_items.extent a1) (Declared_items.extent d)
    && subset (Declared_items.extent s2) (Declared_items.extent d)
    && subset (Declared_items.extent a2) (Declared_items.extent d));
  Alcotest.(check bool)
    "sp holds the extents of s2 and a2" true
    (subset (Declared_items.extent s2) (Declared_items.extent sp)
    && subset (Declared_items.extent a2) (Declared_items.extent sp));
  Alcotest.(check bool)
    "d does not hold the claim of an unheld slash-slug schema" true
    (List.for_all
       (fun line -> not (List.mem line (Declared_items.extent d)))
       (Declared_items.claim slash));
  Alcotest.(check int)
    "a level-0 schema claim after front matter does not include front matter" 1
    (List.length (Declared_items.claim orphan_s));
  Alcotest.(check (option int))
    "an atom named d does not shadow slug_design d"
    (Some (Declared_items.number d))
    (number_of (Declared_items.slug_design declared "d"));
  Alcotest.(check (option int))
    "the atom named d belongs to no design" None
    (number_of (Declared_items.design atom_d));
  let shared_names =
    List.map Declared_items.name
      (Declared_items.members declared Declared_items.Shared)
  in
  Alcotest.(check (list string))
    "Shared contains designs and unowned slug schemas and atoms, not full names"
    [ "d"; "a/b"; "orphan-s"; "d" ]
    shared_names;
  let design_names =
    List.map Declared_items.name
      (Declared_items.members declared (Declared_items.Of_design d))
  in
  Alcotest.(check (list string))
    "Of_design d contains its specs, schemas, and atoms"
    [ "d#s1"; "d#a1"; "d#sp"; "d#s2"; "d#a2"; "d#s3"; "d#a3" ]
    design_names;
  let other_file =
    List.find
      (fun f -> path_text (Tree_file.path f) = "docs/other.md")
      (Declared_items.files declared)
  in
  let s3_line =
    match Declared_items.claim s3 with l :: _ -> [ l ] | [] -> []
  in
  Alcotest.(check (option int))
    "home_design rule 2 does not apply to a schema in a markdown file" None
    (number_of
       (Declared_items.home_design declared (Tree_file.path other_file) s3_line))

(* @verifies documents#{give-containment=v1, give-extents=v1}
   The test checks code-file schema and atom declarations for home-design rule
   2, including priority over an enclosing specification and slugs with no
   design, for specification containment, and for specification extents of held
   and unheld items. *)
let schemas_and_atoms_home_design_in_code () =
  let source =
    "// @schema d#sc=v1\n\
     // @cites #at=v1\n\
     fn sc() {}\n\n\
     // @atom d#at=v1\n\
     // @cites #sc=v1\n\
     fn at() {}\n\n\
     // @spec e#sp=v1\n\
     fn outer() {\n\
    \  // @schema d#override-s=v1\n\
    \  // @cites #sc=v1\n\
    \  fn s() {}\n\
    \  // @atom d#override-a=v1\n\
    \  // @cites #at=v1\n\
    \  fn a() {}\n\
    \  // @schema seg-s=v1\n\
    \  // @atom seg-a=v1\n\
    \  fn inner() {}\n\
     }\n\n\
     // @schema missing#ms=v1\n\
     // @cites #x=v1\n\
     fn ms() {}\n"
  in
  let c s =
    let from, until = find_span source s in
    comment from until
  in
  let def_fn name =
    let from, until = find_span source name in
    definition from until
      { Text.from = String.index_from source from '{'; until }
  in
  let outer_from, _ = find_span source "fn outer() {" in
  let outer_body_from = String.index_from source outer_from '{' in
  let outer_until = snd (find_span source "  fn inner() {}\n}") in
  let nodes =
    [
      c "// @schema d#sc=v1\n// @cites #at=v1";
      def_fn "fn sc() {}";
      c "// @atom d#at=v1\n// @cites #sc=v1";
      def_fn "fn at() {}";
      c "// @spec e#sp=v1";
      definition outer_from outer_until
        { Text.from = outer_body_from; until = outer_until };
      c "// @schema d#override-s=v1\n  // @cites #sc=v1";
      def_fn "fn s() {}";
      c "// @atom d#override-a=v1\n  // @cites #at=v1";
      def_fn "fn a() {}";
      c "// @schema seg-s=v1\n  // @atom seg-a=v1";
      def_fn "fn inner() {}";
      c "// @schema missing#ms=v1\n// @cites #x=v1";
      def_fn "fn ms() {}";
    ]
  in
  let case =
    {
      Tree_gen.files =
        [
          ("docs/d.md", "# D\n@design d=v1\n");
          ("docs/e.md", "# E\n@design e=v1\n");
          ("lib/w.rs", source);
        ];
      code =
        [
          ( "lib/w.rs",
            {
              Tree_gen.sigils =
                { Code_reference.line = [ "//" ]; block = []; inner = [] };
              nodes;
            } );
        ];
    }
  in
  let tree, readables = Tree_gen.read case in
  let files =
    List.map
      (fun (path, readable) ->
        Tree_file.make Tree_gen.namespaces (path_of path) readable)
      readables
  in
  let declared = make_all (tree, files) in
  let by_name name =
    List.find
      (fun item -> Declared_items.name item = name)
      (Declared_items.items declared)
  in
  let d = by_name "d" in
  let e = by_name "e" in
  let sp = by_name "e#sp" in
  let sc = by_name "d#sc" in
  let at = by_name "d#at" in
  let ov_s = by_name "d#override-s" in
  let ov_a = by_name "d#override-a" in
  let seg_s = by_name "e#seg-s" in
  let seg_a = by_name "e#seg-a" in
  let ms = by_name "missing#ms" in
  let code_path = path_of "lib/w.rs" in
  let second_line item =
    match Declared_items.claim item with
    | _ :: line :: _ -> [ line ]
    | _ ->
        Alcotest.fail ("expected two-line claim for " ^ Declared_items.name item)
  in
  Alcotest.(check (option int))
    "home_design rule 2 uses full-name schema in code"
    (Some (Declared_items.number d))
    (number_of (Declared_items.home_design declared code_path (second_line sc)));
  Alcotest.(check (option int))
    "home_design rule 2 uses full-name atom in code"
    (Some (Declared_items.number d))
    (number_of (Declared_items.home_design declared code_path (second_line at)));
  Alcotest.(check (option int))
    "home_design rule 2 on schema beats rule 3 on enclosing spec"
    (Some (Declared_items.number d))
    (number_of
       (Declared_items.home_design declared code_path (second_line ov_s)));
  Alcotest.(check (option int))
    "home_design rule 2 on atom beats rule 3 on enclosing spec"
    (Some (Declared_items.number d))
    (number_of
       (Declared_items.home_design declared code_path (second_line ov_a)));
  Alcotest.(check (option int))
    "home_design rule 2 gives None when full-name schema slug has no design"
    None
    (number_of (Declared_items.home_design declared code_path (second_line ms)));
  Alcotest.(check (option int))
    "segment schema in spec scope inherits spec design"
    (Some (Declared_items.number e))
    (number_of (Declared_items.design seg_s));
  Alcotest.(check (option int))
    "segment schema in spec scope belongs to spec"
    (Some (Declared_items.number sp))
    (number_of (Declared_items.specification seg_s));
  Alcotest.(check (option int))
    "segment atom in spec scope inherits spec design"
    (Some (Declared_items.number e))
    (number_of (Declared_items.design seg_a));
  Alcotest.(check (option int))
    "segment atom in spec scope belongs to spec"
    (Some (Declared_items.number sp))
    (number_of (Declared_items.specification seg_a));
  Alcotest.(check (option int))
    "schema of another design inside spec scope does not belong to that spec"
    None
    (number_of (Declared_items.specification ov_s));
  Alcotest.(check (option int))
    "atom of another design inside spec scope does not belong to that spec" None
    (number_of (Declared_items.specification ov_a));
  let subset a b = List.for_all (fun line -> List.mem line b) a in
  Alcotest.(check bool)
    "sp holds the extents of seg_s and seg_a in code" true
    (subset (Declared_items.extent seg_s) (Declared_items.extent sp)
    && subset (Declared_items.extent seg_a) (Declared_items.extent sp));
  Alcotest.(check bool)
    "sp does not hold the extents of ov_s or ov_a" true
    (List.for_all
       (fun line -> not (List.mem line (Declared_items.extent sp)))
       (Declared_items.extent ov_s @ Declared_items.extent ov_a))

let tests =
  [
    Alcotest.test_case
      "the queries of a tree of four times as many items take at most 2.5 \
       times as long"
      `Quick queries_grow_as_logarithms;
    Alcotest.test_case "four times as many files take at most 6 times the work"
      `Quick many_files_grow_linearly;
    Alcotest.test_case
      "four times as many sections take at most 6 times the work" `Quick
      many_sections_grow_linearly;
    Alcotest.test_case "a scope has the file lines at the ends of its target"
      `Quick a_scope_has_the_file_lines_at_the_ends_of_its_target;
    Alcotest.test_case
      "four times as many designs in one paragraph take at most 10 times as \
       long"
      `Quick designs_in_one_paragraph_grow_linearly;
    Alcotest.test_case
      "list items nested four times as deep take at most 40 times as long"
      `Quick nested_list_items_grow_as_their_text;
    Alcotest.test_case
      "four times as many nested specifications take at most 40 times as long"
      `Quick nested_specifications_grow_as_their_scopes;
    queries_take_no_line_for_what_is_no_file_line;
    Alcotest.test_case "two files at one valid path are refused" `Quick
      two_files_at_one_path_are_refused;
    Alcotest.test_case "each file gives the declarations of its own inputs"
      `Quick each_file_gives_the_declarations_of_its_own_inputs;
    Alcotest.test_case "a vector file is a file of the tree given to make"
      `Quick vector_files_are_files_of_the_tree;
    Alcotest.test_case
      "schemas and atoms follow containment, extent, name-set, and vector-file \
       rules in markdown"
      `Quick schemas_and_atoms_in_markdown;
    Alcotest.test_case
      "schemas and atoms follow home-design rule 2 and spec containment in code"
      `Quick schemas_and_atoms_home_design_in_code;
    items_follow_the_terms;
    extents_follow_the_terms;
    containment_follows_the_terms;
    vector_files_follow_the_term;
    claims_follow_the_term;
    scopes_follow_the_term;
    home_designs_follow_the_term;
    holders_follow_the_extents;
    parts_follow_the_extents;
    slug_designs_follow_the_term;
    name_sets_follow_the_term;
    items_keep_their_declarations;
  ]
