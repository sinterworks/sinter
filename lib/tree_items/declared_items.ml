(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_origins
open Sinter_identifiers
open Sinter_tag_inputs
open Sinter_markdown_tag_texts
open Sinter_readings
open Sinter_code_tag_texts
open Sinter_test_vectors
open Sinter_tree_inputs

type kind =
  | Design
  | Specification
  | Requirement
  | Term
  | Decision_record
  | Declared_finding_class

type item = {
  number : int;
  kind : kind;
  file : Tree_file.t;
  declaration : Input.t;
  at : Lines.position;
  slug : string;
  part_name : string option;
  line : Line_set.t;
  claim : Line_set.t;
  scope : Line_set.t option;
  mutable name : string;
  mutable design : item option;
  mutable specification : item option;
  mutable extent : Line_set.t;
  mutable vector_path : Path.t option;
  mutable vector_file : Path.t option;
}

module By_text = Map.Make (String)
module By_number = Map.Make (Int)

type set_key = Shared_key | Finding_key | Design_key of int

module By_name = Map.Make (struct
  type t = set_key * string

  let compare = compare
end)

module By_set = Map.Make (struct
  type t = set_key

  let compare = compare
end)

type file_index = {
  tree_file : Tree_file.t;
  file_items : item list;
  design_scopes : item Line_set.Index.t;
  specification_scopes : item Line_set.Index.t;
  requirement_claims : item Line_set.Index.t;
  extents : item Line_set.Index.t;
}

type error = Repeated_path of Path.t
type name_set = Shared | Finding_classes | Of_design of item

type t = {
  items : item list;
  files : file_index list;
  by_path : file_index By_text.t;
  slug_designs : item list By_text.t;
  names : item list By_name.t;
  sets : item list By_set.t;
}

let path_key path = Text.encode (Path.to_text path)
let equal a b = a == b

let kind_of_word = function
  | Tag_word.Design -> Some Design
  | Spec -> Some Specification
  | Req -> Some Requirement
  | Term -> Some Term
  | Decision -> Some Decision_record
  | Finding_class -> Some Declared_finding_class
  | Cites | Refines | Satisfies | Supersedes | Verifies | Deferred | Deprecated
  | Rejected | Ack | Extern ->
      None

type declaration = {
  input : Input.t;
  tag_line : int;
  decl_kind : kind;
  decl_slug : string;
  decl_part : string option;
  decl_at : Lines.position;
}

(* @satisfies documents#give-declared-items=v1
   Each accepted input of a tag text that is a declaration gives one
   declaration, with the kind that its declaration word gives and the origin
   position of the text of its tag line; no other input gives one. *)
let declarations (tag_text : Tree_file.tag_text) =
  List.filter_map
    (fun input ->
      match Input.kind input with
      | Input.Tag_line
          {
            first_line;
            result =
              Tag_line.Valid (Tag_line.Declaration { word; slug; part_name; _ });
            _;
          } -> (
          match (kind_of_word word, Input.origin_position input) with
          | Some decl_kind, Some decl_at ->
              Some
                {
                  input;
                  tag_line = first_line;
                  decl_kind;
                  decl_slug = slug;
                  decl_part = part_name;
                  decl_at;
                }
          | _ -> None)
      | Input.Tag_line _ | Input.Link _ -> None)
    tag_text.inputs

let line_of file (d : declaration) =
  Tree_file.numbers file (Input.file_lines (Tree_file.file_lines file) d.input)

(* @satisfies documents#give-extents=v1
   A claim loses its blank file lines after its last file line that is not
   blank. *)
let trim file set =
  match Line_set.last set with
  | None -> set
  | Some last ->
      Line_set.diff set
        (Line_set.range (Tree_file.last_not_blank file last + 1) last)

let rec with_next first = function
  | [] -> []
  | d :: rest ->
      let next = match rest with next :: _ -> Some next | [] -> None in
      (d, first, next) :: with_next false rest

(* @satisfies documents#give-extents=v1
   In markdown, a declared finding class that is the only declaration of the
   first paragraph of the section of level 0 claims every markdown line; each
   other declaration claims its section or list item from its first line, or
   from its own line when another declaration of its paragraph comes before it,
   to the line before the next declaration of its paragraph. *)
let markdown_claims file ~level_0 (range : Markdown_file.range)
    (paragraph : Markdown_file.paragraph) declarations =
  let line d = paragraph.lines.first + d.tag_line - 1 in
  List.map
    (fun (d, first, next) ->
      match (d.decl_kind, first, next) with
      | Declared_finding_class, true, None when level_0 ->
          (d, trim file (Tree_file.all_lines file))
      | _ ->
          let from = if first then range.first else line d in
          let last =
            match next with Some next -> line next - 1 | None -> range.last
          in
          (d, trim file (Line_set.range from last)))
    (with_next true declarations)

let rec by_block blocks declarations =
  match (blocks, declarations) with
  | [], _ | _, [] -> []
  | (b : Block.t) :: other_blocks, _ ->
      let rec split inside = function
        | d :: rest when d.tag_line <= b.last_line -> split (d :: inside) rest
        | rest -> (List.rev inside, rest)
      in
      let inside, rest = split [] declarations in
      (b, inside) :: by_block other_blocks rest

(* @satisfies documents#give-extents=v1
   In code, a declaration claims its part of its block: from the first line of
   the block, or from its own line when another declaration of the block comes
   before it, to the line before the next declaration of the block. *)
let code_claims file tag_text declarations =
  let blocks = Block.of_tag_text (Tree_file.binding file) tag_text in
  let lines first last =
    Line_set.of_list
      (List.filter_map
         (fun k ->
           Option.bind
             (File_lines.of_tag_text_line
                (Tree_file.file_lines file)
                tag_text k)
             (Tree_file.number file))
         (Line_set.elements (Line_set.range first last)))
  in
  List.concat_map
    (fun ((b : Block.t), inside) ->
      List.map
        (fun (d, first, next) ->
          let from = if first then b.first_line else d.tag_line in
          let last =
            match next with
            | Some next -> next.tag_line - 1
            | None -> b.last_line
          in
          (d, trim file (lines from last)))
        (with_next true inside))
    (by_block blocks declarations)

(* @satisfies documents#give-containment=v1
   In code, the scope of a specification is the lines of its tag text, with
   the file lines in the run of the attachment target of its run of comments,
   or every file line when its run of comments is unattached and no code
   character comes before it. *)
let specification_scope file (run : Code_file.comment_run) tag_text =
  let joined = Tree_file.numbers file (Tag_text.joined tag_text) in
  match run.target with
  | Some (target : Reading.node) ->
      Line_set.union [ joined; Tree_file.within file target.run ]
  | None ->
      if Tree_file.code_character_before file run.run.from then joined
      else Tree_file.all_lines file

(* @satisfies documents#give-containment=v1
   In markdown, the scope of a design or a specification is the lines of its
   section or list item; in code, the scope of a design is its claim. *)
let scope_of kind claim ~holder =
  match kind with
  | Design -> (
      match holder with `Lines lines -> Some lines | `Run _ -> Some claim)
  | Specification -> (
      match holder with
      | `Lines lines -> Some lines
      | `Run scope -> Some (Lazy.force scope))
  | Requirement | Term | Decision_record | Declared_finding_class -> None

let raw_items file =
  List.concat_map
    (fun (tag_text : Tree_file.tag_text) ->
      let declarations = declarations tag_text in
      let markdown ~level_0 (range : Markdown_file.range) paragraph =
        ( markdown_claims file ~level_0 range paragraph declarations,
          `Lines (Line_set.range range.first range.last) )
      in
      let claims, holder =
        match tag_text.holder with
        | Tree_file.Section
            { lines = Some range; heading; first_paragraph = Some paragraph } ->
            markdown ~level_0:(heading = None) range paragraph
        | Tree_file.List_item { lines; first_paragraph = Some paragraph } ->
            markdown ~level_0:false lines paragraph
        | Tree_file.Section _ | Tree_file.List_item _ ->
            ([], `Lines Line_set.empty)
        | Tree_file.Comment_run run ->
            ( code_claims file tag_text.tag_text declarations,
              `Run (lazy (specification_scope file run tag_text.tag_text)) )
      in
      List.map
        (fun (d, claim) -> (d, claim, scope_of d.decl_kind claim ~holder))
        claims)
    (Tree_file.tag_texts file)

let index_of items select =
  Line_set.Index.make
    (List.filter_map
       (fun item -> Option.map (fun set -> (item, set)) (select item))
       items)

let of_kinds kinds get item =
  if List.mem item.kind kinds then get item else None

let lookup_slug slug_designs slug =
  match By_text.find_opt slug slug_designs with
  | Some [ ({ kind = Design; _ } as design) ] -> Some design
  | _ -> None

let full_name_design slug_designs = function
  | Some { part_name = Some _; slug; _ } -> lookup_slug slug_designs slug
  | _ -> None

(* @satisfies documents#give-containment=v1
   The home design of a thing is the innermost design in whose scope it is;
   otherwise, in code, the design of the slug of the full name of the innermost
   requirement or term in whose claim it is; otherwise the design of the slug
   of the full name of the innermost specification in whose scope it is. *)
let home slug_designs index lines =
  match Line_set.Index.innermost index.design_scopes lines with
  | Some design -> Some design
  | None -> (
      let by_claims =
        match Tree_file.content index.tree_file with
        | Tree_file.Code _ ->
            full_name_design slug_designs
              (Line_set.Index.innermost index.requirement_claims lines)
        | Tree_file.Markdown _ -> None
      in
      match by_claims with
      | Some design -> Some design
      | None ->
          full_name_design slug_designs
            (Line_set.Index.innermost index.specification_scopes lines))

(* @satisfies documents#give-containment=v1
   A specification, a requirement, or a term named by a full name belongs to
   the design of its slug; one named by a segment belongs to the home design of
   its declaration; one named by another slug belongs to no design. *)
let design_of slug_designs index item =
  match item.kind with
  | Specification | Requirement | Term -> (
      match item.part_name with
      | Some _ -> lookup_slug slug_designs item.slug
      | None ->
          if String.contains item.slug '/' then None
          else home slug_designs index item.line)
  | Design | Decision_record | Declared_finding_class -> None

(* @satisfies documents#give-containment=v1
   A requirement or a term belongs to the innermost specification in whose
   scope its declaration is, when the two belong to the same design or both to
   none. *)
let specification_of index item =
  match item.kind with
  | Requirement | Term -> (
      match Line_set.Index.innermost index.specification_scopes item.line with
      | Some spec when Option.equal equal spec.design item.design -> Some spec
      | _ -> None)
  | Design | Specification | Decision_record | Declared_finding_class -> None

(* @satisfies documents#give-declared-items=v1
   An item of the kind specification, requirement, or term named by one
   segment and that belongs to a design has the name of that design, [#], and
   that segment; each other item has the name in its target. *)
let name_of item =
  match (item.kind, item.part_name, item.design) with
  | (Specification | Requirement | Term), None, Some design
    when not (String.contains item.slug '/') ->
      design.slug ^ "#" ^ item.slug
  | _, Some part, _ -> item.slug ^ "#" ^ part
  | _, None, _ -> item.slug

(* @satisfies documents#give-extents=v1
   The extent of an item is its claim without the claims of the other items
   inside it, with the extents of the items of its file that it holds. A held
   item gives back by its extent each line of its claim that the term keeps,
   so this is the claim without the claims inside it of the items that it does
   not hold, with these extents. *)
let extents items =
  let claims = Line_set.Index.make (List.map (fun i -> (i, i.claim)) items) in
  let held =
    List.fold_left
      (fun held h ->
        List.fold_left
          (fun held (holder : item) ->
            if holder.file == h.file then
              By_number.add_to_list holder.number h held
            else held)
          held
          (List.filter_map Fun.id [ h.design; h.specification ]))
      By_number.empty items
  in
  let inside =
    List.fold_left
      (fun inside (d, items) -> By_number.add d.number items inside)
      By_number.empty
      (Line_set.Index.subsets claims)
  in
  let find d map = Option.value ~default:[] (By_number.find_opt d.number map) in
  let extent d =
    Line_set.union
      (Line_set.diff d.claim
         (Line_set.union (List.map (fun e -> e.claim) (find d inside)))
      :: List.map (fun h -> h.extent) (find d held))
  in
  let pass kinds =
    List.iter
      (fun d -> if List.mem d.kind kinds then d.extent <- extent d)
      items
  in
  pass [ Requirement; Term; Decision_record; Declared_finding_class ];
  pass [ Specification ];
  pass [ Design ]

let directory path =
  let text = path_key path in
  match String.rindex_opt text '/' with
  | Some i -> String.sub text 0 (i + 1)
  | None -> ""

let decoded s = Result.to_option (Text.decode s)

(* @satisfies documents#give-vector-files=v1
   The vector path of a design is the folder of its file and its test-vector
   file name; that of a specification of a design is the folder of the file of
   that design and the test-vector file name of the two names; a specification
   of no design has none. *)
let vector_path_of item =
  let make design file_name =
    Option.bind
      (decoded (directory (Tree_file.path design.file)))
      (fun folder ->
        Result.to_option (Path.of_text (Text.concat [ folder; file_name ])))
  in
  match (item.kind, item.design) with
  | Design, _ ->
      Option.bind (decoded item.name) (fun x ->
          make item (Test_vector_file_name.of_design x))
  | Specification, Some design ->
      let part = Option.value ~default:item.slug item.part_name in
      Option.bind (decoded design.name) (fun x ->
          Option.bind (decoded part) (fun y ->
              make design (Test_vector_file_name.of_specification x y)))
  | ( ( Specification | Requirement | Term | Decision_record
      | Declared_finding_class ),
      _ ) ->
      None

(* @satisfies documents#give-vector-files=v1
   The vector file of an item is the file of the tree at its vector path, when
   no other item has that vector path. *)
let vector_files tree items =
  let counts =
    List.fold_left
      (fun counts item ->
        Option.fold ~none:counts
          ~some:(fun path -> By_text.add_to_list (path_key path) () counts)
          item.vector_path)
      By_text.empty items
  in
  List.iter
    (fun item ->
      item.vector_file <-
        Option.bind item.vector_path (fun path ->
            match By_text.find_opt (path_key path) counts with
            | Some [ () ] when Option.is_some (Tree.content tree path) ->
                Some path
            | _ -> None))
    items

let set_key item =
  match (item.kind, item.design) with
  | (Design | Decision_record), _ -> Some Shared_key
  | Declared_finding_class, _ -> Some Finding_key
  | (Specification | Requirement | Term), Some design ->
      Some (Design_key design.number)
  | (Specification | Requirement | Term), None ->
      if String.contains item.name '#' then None else Some Shared_key

let make_item file number (d, claim, scope) =
  {
    number;
    kind = d.decl_kind;
    file;
    declaration = d.input;
    at = d.decl_at;
    slug = d.decl_slug;
    part_name = d.decl_part;
    line = line_of file d;
    claim;
    scope;
    name = d.decl_slug;
    design = None;
    specification = None;
    extent = Line_set.empty;
    vector_path = None;
    vector_file = None;
  }

let build tree files =
  let _, per_file =
    List.fold_left_map
      (fun next file ->
        let raws =
          List.stable_sort
            (fun (a, _, _) (b, _, _) ->
              Position_order.compare a.decl_at b.decl_at)
            (raw_items file)
        in
        ( next + List.length raws,
          (file, List.mapi (fun k raw -> make_item file (next + k) raw) raws) ))
      1 files
  in
  let items = List.concat_map snd per_file in
  let slug_designs =
    List.fold_left
      (fun table item ->
        match item.kind with
        | Design | Decision_record -> By_text.add_to_list item.slug item table
        | Specification | Requirement | Term | Declared_finding_class -> table)
      By_text.empty (List.rev items)
  in
  let partial =
    List.map
      (fun (file, items) ->
        let index =
          {
            tree_file = file;
            file_items = items;
            design_scopes =
              index_of items (of_kinds [ Design ] (fun i -> i.scope));
            specification_scopes =
              index_of items (of_kinds [ Specification ] (fun i -> i.scope));
            requirement_claims =
              index_of items
                (of_kinds [ Requirement; Term ] (fun i -> Some i.claim));
            extents = Line_set.Index.make [];
          }
        in
        List.iter
          (fun item -> item.design <- design_of slug_designs index item)
          items;
        index)
      per_file
  in
  List.iter
    (fun index ->
      List.iter
        (fun item -> item.specification <- specification_of index item)
        index.file_items)
    partial;
  List.iter (fun item -> item.name <- name_of item) items;
  let files =
    List.map
      (fun index ->
        extents index.file_items;
        {
          index with
          extents =
            Line_set.Index.make
              (List.map (fun i -> (i, i.extent)) index.file_items);
        })
      partial
  in
  List.iter (fun item -> item.vector_path <- vector_path_of item) items;
  vector_files tree items;
  {
    items;
    files;
    by_path =
      List.fold_left
        (fun map index ->
          By_text.add (path_key (Tree_file.path index.tree_file)) index map)
        By_text.empty files;
    slug_designs;
    names =
      List.fold_left
        (fun map item ->
          Option.fold ~none:map
            ~some:(fun key -> By_name.add_to_list (key, item.name) item map)
            (set_key item))
        By_name.empty (List.rev items);
    sets =
      List.fold_left
        (fun map item ->
          Option.fold ~none:map
            ~some:(fun key -> By_set.add_to_list key item map)
            (set_key item))
        By_set.empty (List.rev items);
  }

let rec repeated = function
  | a :: (b :: _ as rest) ->
      if
        String.equal (path_key (Tree_file.path a)) (path_key (Tree_file.path b))
      then Some (Tree_file.path a)
      else repeated rest
  | [] | [ _ ] -> None

let make tree files =
  let files =
    List.stable_sort
      (fun a b ->
        String.compare
          (path_key (Tree_file.path a))
          (path_key (Tree_file.path b)))
      files
  in
  match repeated files with
  | Some path -> Error (Repeated_path path)
  | None -> Ok (build tree files)

let items declared = declared.items
let number item = item.number
let files declared = List.map (fun index -> index.tree_file) declared.files

let with_index declared path f =
  Option.map f (By_text.find_opt (path_key path) declared.by_path)

let file_items declared path =
  Option.value ~default:[]
    (with_index declared path (fun index -> index.file_items))

let kind item = item.kind
let file item = item.file
let declaration item = item.declaration
let at item = item.at
let target_name item = (item.slug, item.part_name)
let name item = item.name

let runs item set =
  List.filter_map (Tree_file.line item.file) (Line_set.elements set)

let claim item = runs item item.claim
let scope item = Option.map (runs item) item.scope
let design item = item.design
let specification item = item.specification
let extent item = runs item item.extent
let vector_path item = item.vector_path
let vector_file item = item.vector_file
let slug_design declared slug = lookup_slug declared.slug_designs slug
let thing index lines = Tree_file.numbers index.tree_file lines

let home_design declared path lines =
  Option.join
    (with_index declared path (fun index ->
         home declared.slug_designs index (thing index lines)))

let part_of declared path lines =
  Option.join
    (with_index declared path (fun index ->
         Line_set.Index.innermost index.extents (thing index lines)))

let extent_holders declared path lines =
  Option.value ~default:[]
    (with_index declared path (fun index ->
         Line_set.Index.holders index.extents (thing index lines)))

let key = function
  | Shared -> Shared_key
  | Finding_classes -> Finding_key
  | Of_design design -> Design_key design.number

let named declared set name =
  Option.value ~default:[] (By_name.find_opt (key set, name) declared.names)

let members declared set =
  Option.value ~default:[] (By_set.find_opt (key set) declared.sets)
