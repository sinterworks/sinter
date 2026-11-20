(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_origins
open Sinter_markdown_limits
module C = Cmarkit
module B = C.Block

type range = { first : int; last : int }
type paragraph = { lines : range; tag_text : Tag_text.t }
type heading = { line : int; level : int }

type section = {
  heading : heading option;
  lines : range option;
  first_paragraph : paragraph option;
}

type list_item = { lines : range; first_paragraph : paragraph option }

type t = {
  markdown_lines : Text.run array;
  front_matter : range option;
  markdown_run : Text.run;
  markdown_text : Source.t;
  first_text_line : int;
  sections : section list;
  list_items : list_item list;
  file_lines : File_lines.t;
}

let space = Uchar.of_int 0x20
let tab = Uchar.of_int 0x09
let is_space_or_tab c = Uchar.equal c space || Uchar.equal c tab

let rec skip_spaces_and_tabs text place =
  match Text.get text place with
  | Some c when is_space_or_tab c -> skip_spaces_and_tabs text (place + 1)
  | _ -> place

let front_matter_head text (line : Text.run) =
  match Text.sub text line with
  | None -> None
  | Some line_text ->
      let encoded = Text.encode line_text in
      let n = String.length encoded in
      if n >= 3 then
        let head = String.sub encoded 0 3 in
        let rec only_blanks i =
          i >= n
          || ((encoded.[i] = ' ' || encoded.[i] = '\t') && only_blanks (i + 1))
        in
        if (head = "+++" || head = "---") && only_blanks 3 then Some head
        else None
      else None

let find_front_matter text lines =
  let count = Array.length lines in
  if count = 0 then None
  else
    match front_matter_head text lines.(0) with
    | None -> None
    | Some head ->
        let rec search k =
          if k >= count then None
          else if front_matter_head text lines.(k) = Some head then
            Some { first = 1; last = k + 1 }
          else search (k + 1)
        in
        search 1

let ending_end text boundary =
  let line_feed = Some (Uchar.of_int 0x0A)
  and carriage_return = Some (Uchar.of_int 0x0D) in
  let c = Text.get text (boundary + 1) in
  if c = line_feed then boundary + 1
  else if c = carriage_return then
    if Text.get text (boundary + 2) = line_feed then boundary + 2
    else boundary + 1
  else Text.length text

let document text (markdown_run : Text.run) =
  let markdown_text =
    Option.value ~default:Text.empty (Text.sub text markdown_run)
  in
  let body = Text.body markdown_text in
  let bytes =
    Text.encode (Option.value ~default:Text.empty (Text.sub markdown_text body))
  in
  let bytes =
    String.concat "\xEF\xBF\xBD" (String.split_on_char '\000' bytes)
  in
  let start = markdown_run.from + body.from in
  let count = ref start in
  let places =
    Array.init (String.length bytes) (fun i ->
        if Char.code bytes.[i] land 0xC0 <> 0x80 then incr count;
        !count)
  in
  (bytes, places)

type context = {
  text : Text.t;
  file : Lines.t;
  lines : Text.run array;
  first_text_line : int;
  last_text_line : int;
  places : int array;
}

let meta_line line_of ctx meta =
  let line = fst (line_of (C.Meta.textloc meta)) in
  min ctx.last_text_line (ctx.first_text_line + line - 1)

let meta_first_line = meta_line C.Textloc.first_line
let meta_last_line = meta_line C.Textloc.last_line

let first_place ctx meta =
  ctx.places.(C.Textloc.first_byte (C.Meta.textloc meta))

let task_marker_end text place =
  let code k = Option.map Uchar.to_int (Text.get text k) in
  let after = skip_spaces_and_tabs text (place + 3) in
  match (code place, code (place + 1), code (place + 2)) with
  | Some 0x5B, Some (0x20 | 0x78 | 0x58), Some 0x5D when after > place + 3 ->
      Some after
  | _ -> None

let paragraph ctx ~in_list_item meta =
  let first = meta_first_line ctx meta and last = meta_last_line ctx meta in
  let first_line = ctx.lines.(first - 1) in
  let start = skip_spaces_and_tabs ctx.text (first_place ctx meta) in
  let start =
    if in_list_item then
      Option.value ~default:start (task_marker_end ctx.text start)
    else start
  in
  let runs =
    ({ from = start - 1; until = first_line.until } : Text.run)
    :: List.init (last - first) (fun k -> ctx.lines.(first + k))
  in
  Option.map
    (fun tag_text -> { lines = { first; last }; tag_text })
    (Tag_text.make ctx.file runs)

let rec flatten acc (block : B.t) =
  match block with
  | B.Blocks (blocks, _) -> List.fold_left flatten acc blocks
  | B.Blank_line _ -> acc
  | block -> block :: acc

let children block = List.rev (flatten [] block)

let meta_of (block : B.t) =
  match block with
  | B.Block_quote (_, m) -> Some m
  | B.Code_block (_, m) -> Some m
  | B.Heading (_, m) -> Some m
  | B.Html_block (_, m) -> Some m
  | B.Link_reference_definition (_, m) -> Some m
  | B.Paragraph (_, m) -> Some m
  | B.Thematic_break (_, m) -> Some m
  | _ -> None

let first_paragraph ctx ~in_list_item = function
  | B.Paragraph (_, meta) :: _ -> paragraph ctx ~in_list_item meta
  | _ -> None

let rec walk ctx (items, last) (block : B.t) =
  match block with
  | B.List (list, _) ->
      List.fold_left
        (fun (items, last) (item, meta) ->
          let blocks = children (B.List_item.block item) in
          let first = meta_first_line ctx meta in
          let items, item_last =
            List.fold_left (walk ctx) (items, first) (List.rev blocks)
          in
          let entry =
            {
              lines = { first; last = item_last };
              first_paragraph = first_paragraph ctx ~in_list_item:true blocks;
            }
          in
          (entry :: items, max last item_last))
        (items, last)
        (List.rev (B.List'.items list))
  | block -> (
      match meta_of block with
      | Some m -> (items, max last (meta_last_line ctx m))
      | None -> (items, last))

let list_items ctx blocks =
  fst (List.fold_left (walk ctx) ([], ctx.first_text_line) (List.rev blocks))

(* @satisfies documents#give-extents=v1
   Each heading of the document itself, ATX or setext, opens a section that
   ends before the next such heading of the same level or less, and so ends the
   claims of the declarations of the sections before it. *)
let sections ctx blocks =
  let rec openers acc = function
    | [] -> List.rev acc
    | B.Heading (h, meta) :: rest ->
        let heading =
          { line = meta_first_line ctx meta; level = B.Heading.level h }
        in
        openers
          ((heading, first_paragraph ctx ~in_list_item:false rest) :: acc)
          rest
    | _ :: rest -> openers acc rest
  in
  let headings = Array.of_list (openers [] blocks) in
  let count = Array.length headings in
  let ends = Array.make count ctx.last_text_line in
  let stack = ref [] in
  for i = 0 to count - 1 do
    let heading, _ = headings.(i) in
    let rec pop () =
      match !stack with
      | j :: rest when (fst headings.(j)).level >= heading.level ->
          ends.(j) <- heading.line - 1;
          stack := rest;
          pop ()
      | _ -> ()
    in
    pop ();
    stack := i :: !stack
  done;
  let level_0_last =
    if count = 0 then ctx.last_text_line else (fst headings.(0)).line - 1
  in
  let level_0 =
    {
      heading = None;
      lines =
        (if level_0_last >= ctx.first_text_line then
           Some { first = ctx.first_text_line; last = level_0_last }
         else None);
      first_paragraph = first_paragraph ctx ~in_list_item:false blocks;
    }
  in
  level_0
  :: List.init count (fun i ->
      let heading, first_paragraph = headings.(i) in
      {
        heading = Some heading;
        lines = Some { first = heading.line; last = ends.(i) };
        first_paragraph;
      })

let read within =
  let file = Markdown_limits.lines within in
  let text = Lines.text file in
  let markdown_lines = Array.of_list (Markdown_lines.of_text text) in
  let count = Array.length markdown_lines in
  let front_matter = find_front_matter text markdown_lines in
  let markdown_run : Text.run =
    match front_matter with
    | None -> { from = 0; until = Text.length text }
    | Some { last; _ } ->
        {
          from = ending_end text markdown_lines.(last - 1).until;
          until = Text.length text;
        }
  in
  let first_text_line =
    let rec search k =
      if k >= count || markdown_lines.(k).from >= markdown_run.from then k + 1
      else search (k + 1)
    in
    search 0
  in
  let bytes, places = document text markdown_run in
  let ctx =
    {
      text;
      file;
      lines = markdown_lines;
      first_text_line;
      last_text_line = count;
      places;
    }
  in
  let doc = C.Doc.of_string ~strict:true ~locs:true bytes in
  let blocks = children (C.Doc.block doc) in
  {
    markdown_lines;
    front_matter;
    markdown_run;
    markdown_text =
      Option.value ~default:(Source.of_file file)
        (Source.sub (Source.of_file file) markdown_run);
    first_text_line;
    sections = sections ctx blocks;
    list_items = list_items ctx blocks;
    file_lines = File_lines.of_markdown_lines (Array.to_list markdown_lines);
  }

let lines (file : t) = Array.to_list file.markdown_lines
let front_matter file = file.front_matter
let markdown_run file = file.markdown_run
let markdown_text file = file.markdown_text
let first_markdown_text_line (file : t) = file.first_text_line
let sections file = file.sections
let list_items file = file.list_items

let tag_texts file =
  let paragraphs =
    List.filter_map (fun (s : section) -> s.first_paragraph) file.sections
    @ List.filter_map (fun (i : list_item) -> i.first_paragraph) file.list_items
  in
  List.map
    (fun (p : paragraph) -> p.tag_text)
    (List.stable_sort
       (fun (a : paragraph) (b : paragraph) ->
         compare a.lines.first b.lines.first)
       paragraphs)

let file_lines file = file.file_lines
