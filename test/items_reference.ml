(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_identifiers
open Sinter_inline_citations
open Sinter_origins
open Sinter_markdown_tag_texts
open Sinter_code_tag_texts
open Sinter_tag_inputs

type kind =
  | Design
  | Specification
  | Requirement
  | Term
  | Decision_record
  | Declared_finding_class

let kind_text = function
  | Design -> "design"
  | Specification -> "specification"
  | Requirement -> "requirement"
  | Term -> "term"
  | Decision_record -> "decision record"
  | Declared_finding_class -> "declared finding class"

type item = {
  kind : kind;
  name : string;
  file : string;
  at : Lines.position;
  claim : Text.run list;
  scope : Text.run list option;
  extent : Text.run list;
  design : int option;
  specification : int option;
  vector_path : string option;
  vector_file : string option;
}

type thing = { path : string; input : Input.t; home_design : int option }
type model = { items : item list; things : thing list }

module Ints = Set.Make (Int)

type file = {
  path : string;
  text : Text.t;
  lines : File_lines.t;
  all : Text.run array;
  index : (int * int, int) Hashtbl.t;
  code : Code_file.t option;
}

type unit_ = {
  tag_text : Tag_text.t;
  inputs : Input.t list;
  section : Ints.t option;
  level_0 : bool;
  comment_run : Code_file.comment_run option;
}

type declaration = {
  file : file;
  unit_ : unit_;
  input : Input.t;
  kind : kind;
  slug : string;
  part_name : string option;
  at : Lines.position;
}

let kind_of_word = function
  | Tag_word.Design -> Some Design
  | Spec -> Some Specification
  | Req -> Some Requirement
  | Term -> Some Term
  | Decision -> Some Decision_record
  | Finding_class -> Some Declared_finding_class
  | _ -> None

let index_of file run =
  Hashtbl.find_opt file.index (run.Text.from, run.Text.until)

let indexes file runs = Ints.of_list (List.filter_map (index_of file) runs)

let range_set first last =
  Ints.of_list (List.init (max 0 (last - first + 1)) (fun k -> first + k))

let file_of path readable =
  let text, lines, code =
    match readable with
    | Readable_file.Markdown_file lines ->
        let md = Markdown_file.read lines in
        (Lines.text lines, Markdown_file.file_lines md, None)
    | Readable_file.Code_file code ->
        ( Lines.text (Sinter_readings.Reading.lines (Code_file.reading code)),
          Code_file.file_lines code,
          Some code )
  in
  let all = Array.of_list (File_lines.all lines) in
  let index = Hashtbl.create 64 in
  Array.iteri
    (fun k run ->
      if not (Hashtbl.mem index (run.Text.from, run.Text.until)) then
        Hashtbl.add index (run.Text.from, run.Text.until) k)
    all;
  { path; text; lines; all; index; code }

let units binding file readable =
  match readable with
  | Readable_file.Markdown_file lines ->
      let md = Markdown_file.read lines in
      let markdown = Array.of_list (Markdown_file.lines md) in
      let set (range : Markdown_file.range) =
        Ints.of_list
          (List.filter_map
             (fun k -> index_of file markdown.(k - 1))
             (Ints.elements (range_set range.first range.last)))
      in
      let of_paragraph section level_0 = function
        | None -> []
        | Some (p : Markdown_file.paragraph) ->
            [
              {
                tag_text = p.tag_text;
                inputs = Input.of_tag_text binding p.tag_text;
                section;
                level_0;
                comment_run = None;
              };
            ]
      in
      List.concat_map
        (fun (s : Markdown_file.section) ->
          of_paragraph (Option.map set s.lines) (s.heading = None)
            s.first_paragraph)
        (Markdown_file.sections md)
      @ List.concat_map
          (fun (i : Markdown_file.list_item) ->
            of_paragraph (Some (set i.lines)) false i.first_paragraph)
          (Markdown_file.list_items md)
  | Readable_file.Code_file code ->
      List.filter_map
        (fun (run : Code_file.comment_run) ->
          Option.map
            (fun tag_text ->
              {
                tag_text;
                inputs = Input.of_tag_text binding tag_text;
                section = None;
                level_0 = false;
                comment_run = Some run;
              })
            run.tag_text)
        (Code_file.comment_runs code)

let declarations_of file unit_ =
  List.filter_map
    (fun input ->
      if not (Input.accepted input) then None
      else
        match Input.kind input with
        | Input.Tag_line
            {
              result =
                Tag_line.Valid
                  (Tag_line.Declaration { word; slug; part_name; _ });
              _;
            } -> (
            match (kind_of_word word, Input.origin_position input) with
            | Some kind, Some at ->
                Some { file; unit_; input; kind; slug; part_name; at }
            | _ -> None)
        | _ -> None)
    unit_.inputs

let first_line input =
  match Input.kind input with
  | Input.Tag_line { first_line; _ } -> first_line
  | Input.Link _ -> 0

let thing_lines file input = indexes file (Input.file_lines file.lines input)

let is_blank file k =
  match Text.sub file.text file.all.(k) with
  | Some text -> File_lines.is_blank text
  | None -> false

let trim file set =
  let rec drop = function
    | k :: rest when is_blank file k -> drop rest
    | rest -> rest
  in
  Ints.of_list (drop (List.rev (Ints.elements set)))

let rec after (x : declaration) = function
  | [] -> None
  | (y : declaration) :: rest ->
      if y.input == x.input then match rest with [] -> None | z :: _ -> Some z
      else after x rest

let claim binding (d : declaration) =
  let file = d.file in
  let decls = declarations_of file d.unit_ in
  let is_first =
    match decls with first :: _ -> first.input == d.input | [] -> false
  in
  match file.code with
  | None ->
      let section = Option.value d.unit_.section ~default:Ints.empty in
      if
        d.kind = Declared_finding_class
        && d.unit_.level_0
        && List.length decls = 1
      then trim file (range_set 0 (Array.length file.all - 1))
      else
        let line_of decl =
          match Ints.elements (thing_lines file decl.input) with
          | k :: _ -> k
          | [] -> 0
        in
        let start =
          if is_first then Option.value (Ints.min_elt_opt section) ~default:0
          else line_of d
        in
        let finish =
          match after d decls with
          | Some next -> line_of next - 1
          | None -> Option.value (Ints.max_elt_opt section) ~default:(-1)
        in
        trim file (range_set start finish)
  | Some _ -> (
      let tag_text = d.unit_.tag_text in
      let k = first_line d.input in
      let block =
        List.find_opt
          (fun (b : Block.t) -> b.first_line <= k && k <= b.last_line)
          (Block.of_tag_text binding tag_text)
      in
      match block with
      | None -> Ints.empty
      | Some b ->
          let in_block =
            List.filter
              (fun decl ->
                let k = first_line decl.input in
                b.first_line <= k && k <= b.last_line)
              decls
          in
          let first_in_block =
            match in_block with x :: _ -> x.input == d.input | [] -> false
          in
          let start = if first_in_block then b.first_line else k in
          let finish =
            match after d in_block with
            | Some next -> first_line next.input - 1
            | None -> b.last_line
          in
          trim file
            (indexes file
               (List.filter_map
                  (fun k -> File_lines.of_tag_text_line file.lines tag_text k)
                  (Ints.elements (range_set start finish)))))

let scope (d : declaration) claim_of =
  let file = d.file in
  match file.code with
  | None -> Option.value d.unit_.section ~default:Ints.empty
  | Some code -> (
      if d.kind = Design then claim_of d
      else
        let joined = indexes file (Tag_text.joined d.unit_.tag_text) in
        match d.unit_.comment_run with
        | None -> joined
        | Some run -> (
            match run.target with
            | Some target ->
                let t = target.Sinter_readings.Reading.run in
                let inside = ref joined in
                Array.iteri
                  (fun k (line : Text.run) ->
                    if line.from >= t.from && line.until <= t.until then
                      inside := Ints.add k !inside)
                  file.all;
                !inside
            | None ->
                let rec clear p =
                  p > run.run.from
                  || (not (Code_file.is_code_character code p))
                     && clear (p + 1)
                in
                if clear 1 then range_set 0 (Array.length file.all - 1)
                else joined))

let innermost candidates =
  let fits (_, s) = List.for_all (fun (_, o) -> Ints.subset s o) candidates in
  match List.filter fits candidates with [ (x, _) ] -> Some x | _ -> None

let has_slash s = String.contains s '/'

let dir path =
  match String.rindex_opt path '/' with
  | Some k -> String.sub path 0 (k + 1)
  | None -> ""

let model binding files paths =
  let files =
    List.map (fun (path, readable) -> (file_of path readable, readable)) files
  in
  let units =
    List.map (fun (file, readable) -> (file, units binding file readable)) files
  in
  let decls =
    List.concat_map
      (fun (file, units) ->
        List.sort
          (fun (a : declaration) (b : declaration) ->
            compare (a.at.line, a.at.column) (b.at.line, b.at.column))
          (List.concat_map (declarations_of file) units))
      units
  in
  let decls = Array.of_list decls in
  let n = Array.length decls in
  let number d =
    let rec go k = if decls.(k) == d then k else go (k + 1) in
    go 0
  in
  let claims = Array.map (fun d -> claim binding d) decls in
  let claim_of d = claims.(number d) in
  let scopes =
    Array.map
      (fun d ->
        match d.kind with
        | Design | Specification -> scope d claim_of
        | _ -> Ints.empty)
      decls
  in
  let same_file (a : declaration) (b : declaration) = a.file == b.file in
  let slug_design slug =
    let named =
      List.filter
        (fun k ->
          (decls.(k).kind = Design || decls.(k).kind = Decision_record)
          && decls.(k).part_name = None
          && String.equal decls.(k).slug slug)
        (List.init n Fun.id)
    in
    match named with [ k ] when decls.(k).kind = Design -> Some k | _ -> None
  in
  let among file kinds set_of lines =
    List.filter_map
      (fun k ->
        let e = decls.(k) in
        if
          e.file == file && List.mem e.kind kinds
          && Ints.subset lines (set_of k)
        then Some (k, set_of k)
        else None)
      (List.init n Fun.id)
  in
  let full_design k =
    match decls.(k).part_name with
    | Some _ -> slug_design decls.(k).slug
    | None -> None
  in
  let home_design file input =
    let lines = thing_lines file input in
    match innermost (among file [ Design ] (fun k -> scopes.(k)) lines) with
    | Some k -> Some k
    | None -> (
        let rule_2 =
          match file.code with
          | None -> None
          | Some _ -> (
              match
                innermost
                  (among file [ Requirement; Term ] (fun k -> claims.(k)) lines)
              with
              | Some k -> full_design k
              | None -> None)
        in
        match rule_2 with
        | Some k -> Some k
        | None -> (
            match
              innermost
                (among file [ Specification ] (fun k -> scopes.(k)) lines)
            with
            | Some k -> full_design k
            | None -> None))
  in
  let design_of =
    Array.map
      (fun d ->
        match d.kind with
        | Specification | Requirement | Term -> (
            match d.part_name with
            | Some _ -> slug_design d.slug
            | None ->
                if has_slash d.slug then None else home_design d.file d.input)
        | _ -> None)
      decls
  in
  let spec_of =
    Array.mapi
      (fun k d ->
        match d.kind with
        | Requirement | Term -> (
            let lines = thing_lines d.file d.input in
            match
              innermost
                (among d.file [ Specification ] (fun j -> scopes.(j)) lines)
            with
            | Some s when design_of.(s) = design_of.(k) -> Some s
            | _ -> None)
        | _ -> None)
      decls
  in
  let rec name k =
    let d = decls.(k) in
    match (d.kind, d.part_name) with
    | (Specification | Requirement | Term), Some p -> d.slug ^ "#" ^ p
    | (Specification | Requirement | Term), None -> (
        match design_of.(k) with
        | Some design when not (has_slash d.slug) -> name design ^ "#" ^ d.slug
        | _ -> d.slug)
    | _ -> d.slug
  in
  let holds k e = design_of.(e) = Some k || spec_of.(e) = Some k in
  let extents = Array.make n None in
  let rec extent k =
    match extents.(k) with
    | Some set -> set
    | None ->
        let d = decls.(k) in
        let others =
          List.filter
            (fun e ->
              e <> k
              && same_file decls.(e) d
              && Ints.subset claims.(e) claims.(k)
              && not (holds k e))
            (List.init n Fun.id)
        in
        let own =
          List.fold_left
            (fun set e -> Ints.diff set claims.(e))
            claims.(k) others
        in
        let set =
          List.fold_left
            (fun set e ->
              if holds k e && same_file decls.(e) d then
                Ints.union set (extent e)
              else set)
            own (List.init n Fun.id)
        in
        extents.(k) <- Some set;
        set
  in
  let vector_path k =
    let d = decls.(k) in
    match d.kind with
    | Design -> Some (dir d.file.path ^ name k ^ ".test-vectors.jsonl")
    | Specification -> (
        match design_of.(k) with
        | Some design ->
            let own = name k in
            let part =
              match String.index_opt own '#' with
              | Some i -> String.sub own (i + 1) (String.length own - i - 1)
              | None -> own
            in
            Some
              (dir decls.(design).file.path
              ^ name design ^ "." ^ part ^ ".test-vectors.jsonl")
        | None -> None)
    | _ -> None
  in
  let vector_paths = Array.init n vector_path in
  let vector_file k =
    match vector_paths.(k) with
    | Some path
      when List.mem path paths
           && not
                (List.exists
                   (fun e -> e <> k && vector_paths.(e) = Some path)
                   (List.init n Fun.id)) ->
        Some path
    | _ -> None
  in
  let items =
    List.init n (fun k ->
        let d = decls.(k) in
        {
          kind = d.kind;
          name = name k;
          file = d.file.path;
          at = d.at;
          claim = List.map (fun i -> d.file.all.(i)) (Ints.elements claims.(k));
          scope =
            (match d.kind with
            | Design | Specification ->
                Some
                  (List.map
                     (fun i -> d.file.all.(i))
                     (Ints.elements scopes.(k)))
            | _ -> None);
          extent = List.map (fun i -> d.file.all.(i)) (Ints.elements (extent k));
          design = Option.map (fun j -> j + 1) design_of.(k);
          specification = Option.map (fun j -> j + 1) spec_of.(k);
          vector_path = vector_paths.(k);
          vector_file = vector_file k;
        })
  in
  let things =
    List.concat_map
      (fun (file, units) ->
        let tag_lines =
          List.concat_map
            (fun u ->
              List.filter
                (fun input ->
                  match Input.kind input with
                  | Input.Tag_line { result = Tag_line.Not_a_tag_line; _ } ->
                      false
                  | Input.Tag_line _ -> true
                  | Input.Link _ -> false)
                u.inputs)
            units
        in
        let sources =
          match (file.code, List.assoc_opt file files) with
          | None, Some (Readable_file.Markdown_file lines) ->
              [ Markdown_file.markdown_text (Markdown_file.read lines) ]
          | _ -> List.map (fun u -> Tag_text.source u.tag_text) units
        in
        let links =
          List.concat_map
            (fun source ->
              List.filter
                (fun input ->
                  match Input.kind input with
                  | Input.Link
                      {
                        link =
                          { result = Inline_citation.Not_an_inline_citation; _ };
                        _;
                      } ->
                      false
                  | _ -> true)
                (Input.of_links binding source))
            sources
        in
        List.map
          (fun input ->
            {
              path = file.path;
              input;
              home_design = Option.map (fun j -> j + 1) (home_design file input);
            })
          (tag_lines @ links))
      units
  in
  { items; things }
