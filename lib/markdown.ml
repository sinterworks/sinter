(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type position = Line_index.position = { line : int; column : int }
type span = { start : position; stop : position }

type reader = {
  language : Sinter_bridge.Language.t;
  query : Sinter_bridge.Query.t;
}

type load_error =
  | Grammar of Sinter_bridge.Language.error
  | Query of Sinter_bridge.Query.error

let create engine =
  match
    Sinter_bridge.Language.load engine ~name:"markdown"
      ~wasm:Markdown_pack.grammar
  with
  | Error error -> Error (Grammar error)
  | Ok language -> (
      match Sinter_bridge.Query.compile language Markdown_pack.query with
      | Ok query -> Ok { language; query }
      | Error error ->
          Fun.protect
            ~finally:(fun () -> Sinter_bridge.Language.close language)
            (fun () -> Error (Query error)))

let close reader =
  Fun.protect
    ~finally:(fun () -> Sinter_bridge.Language.close reader.language)
    (fun () -> Sinter_bridge.Query.close reader.query)

type heading = { text : string; slug : string; name : string; span : span }

type section = {
  level : int;
  heading : heading option;
  parent : int option;
  first_paragraph : span option;
  extent : span option;
  text : string option;
}

type node = Section_node | Item_node
type extent = { first : int; last : int; hash : string }

type tag = {
  span : span;
  word : string;
  rest : string;
  target : string option;
  rev : int option;
  desc : string;
  block : int;
  node : node;
  section : int;
  owner : int option;
  extent : extent option;
  in_comment : bool;
  closes_comment : bool;
}

type block = {
  tags : int list;
  prose : string list;
  hash : string;
  new_line : string;
}

type t = {
  sections : section array;
  tags : tag array;
  blocks : block array;
  unread : span list;
  errors : span list;
  unterminated : int option;
}

type error = Not_utf_8 of int | No_tree of Sinter_bridge.Tree.error
type kind = Section | Heading | Paragraph | Item | Html | Other

type tree = {
  kind : kind;
  start : int;
  stop : int;
  mutable children : tree list;
}

let kind_of = function
  | "section" -> Section
  | "atx_heading" -> Heading
  | "paragraph" -> Paragraph
  | "list_item" -> Item
  | "html_block" -> Html
  | _ -> Other

let order a b =
  match Int.compare a.start b.start with
  | 0 -> Int.compare b.stop a.stop
  | other -> other

let contains outer inner =
  outer.start <= inner.start && inner.stop <= outer.stop

let nest nodes =
  let place (stack, roots) node =
    let rec pop = function
      | top :: rest when not (contains top node) -> pop rest
      | stack -> stack
    in
    match pop stack with
    | top :: _ as stack ->
        top.children <- node :: top.children;
        (node :: stack, roots)
    | [] -> ([ node ], node :: roots)
  in
  let _, roots = List.fold_left place ([], []) (List.stable_sort order nodes) in
  let rec finish node =
    node.children <- List.rev node.children;
    List.iter finish node.children
  in
  let roots = List.rev roots in
  List.iter finish roots;
  roots

let rec flatten children =
  List.concat_map
    (fun child ->
      match child.kind with Section -> flatten child.children | _ -> [ child ])
    children

let is_blank_byte = function ' ' | '\t' -> true | _ -> false
let is_space_byte = function ' ' | '\t' | '\r' | '\n' -> true | _ -> false

let is_blank_line lines line =
  String.for_all is_blank_byte (Line_index.content lines line)

let strip_end text =
  let rec stop offset =
    if offset > 0 && is_blank_byte text.[offset - 1] then stop (offset - 1)
    else offset
  in
  String.sub text 0 (stop (String.length text))

let strip text =
  let length = String.length text in
  let rec start offset =
    if offset < length && is_blank_byte text.[offset] then start (offset + 1)
    else offset
  in
  let first = start 0 in
  strip_end (String.sub text first (length - first))

let last_kept skip text start stop =
  let rec back offset =
    if offset < start then None
    else if skip text.[offset] then back (offset - 1)
    else Some offset
  in
  back (stop - 1)

let rec first_kept skip text start =
  if skip text.[start] then first_kept skip text (start + 1) else start

let trimmed_span lines start stop =
  let text = Line_index.text lines in
  match last_kept is_space_byte text start stop with
  | Some last ->
      {
        start = Line_index.position lines (first_kept is_space_byte text start);
        stop = Line_index.after lines (last + 1);
      }
  | None ->
      let place = Line_index.position lines start in
      { start = place; stop = place }

let last_line lines node =
  match
    last_kept is_blank_byte (Line_index.text lines) node.start node.stop
  with
  | Some offset -> Line_index.line_of lines offset
  | None -> Line_index.line_of lines node.start

let content_last_line lines node =
  match
    last_kept is_space_byte (Line_index.text lines) node.start node.stop
  with
  | Some offset -> Line_index.line_of lines offset
  | None -> Line_index.line_of lines node.start

let heading_text content =
  let length = String.length content in
  let rec skip keep offset =
    if offset < length && keep content.[offset] then skip keep (offset + 1)
    else offset
  in
  let marks = skip is_blank_byte 0 in
  let after = skip (fun byte -> byte = '#') marks in
  let offset = skip is_blank_byte after in
  let text = strip (String.sub content after (length - after)) in
  let rec run offset =
    if offset > 0 && text.[offset - 1] = '#' then run (offset - 1) else offset
  in
  let run = run (String.length text) in
  let rec blanks offset =
    if is_blank_byte text.[offset - 1] then blanks (offset - 1) else offset
  in
  let heading =
    if run = 0 then ""
    else
      let stop = blanks run in
      if stop < run then String.sub text 0 stop else text
  in
  (marks, after - marks, heading, offset)

module Names = Map.Make (String)

let numberer () =
  let taken = ref Names.empty in
  fun slug ->
    let rec find name =
      if Names.mem name !taken then (
        let count = Names.find slug !taken + 1 in
        taken := Names.add slug count !taken;
        find (slug ^ "-" ^ string_of_int count))
      else name
    in
    let name = find slug in
    taken := Names.add name 0 !taken;
    name

type container = { first_line : int; last_line : int; parent : int option }

type row = {
  row : int;
  head_stop : int;
  body_start : int;
  body_stop : int;
  closes : bool;
  written : (int * Tag_line.t) option;
}

type comment = {
  rows : row list;
  holds_tag : bool;
  first_content : row option;
  delimiter_rows : int list;
}

type part = Comment_part of comment | Paragraph_part of tree
type bearing = { container : int; in_section : int; bearer : node; part : part }

type walk = {
  lines : Line_index.t;
  containers : container Dynarray.t;
  sections : (section * int) Dynarray.t;
  bearing : bearing Dynarray.t;
  unread : span Dynarray.t;
  delimiter_lines : int Dynarray.t;
  comment_rows : row Dynarray.t;
  numbers : (int * int * int) Dynarray.t;
  number : string -> string;
}

let add array value =
  Dynarray.add_last array value;
  Dynarray.length array - 1

let span_to lines start stop =
  {
    start = Line_index.position lines start;
    stop = Line_index.after lines stop;
  }

let tag_span lines start line =
  span_to lines start (Line_index.content_end lines line)

let check_unread walk paragraph =
  let text = Line_index.text walk.lines in
  let at = first_kept is_blank_byte text paragraph.start in
  if text.[at] = '@' then
    Dynarray.add_last walk.unread
      (tag_span walk.lines at (Line_index.line_of walk.lines at))

let open_delimiter = "<!--"
let close_delimiter = "-->"

let holds text offset stop word =
  let length = String.length word in
  let rec same index =
    index = length || (text.[offset + index] = word.[index] && same (index + 1))
  in
  (offset + length <= stop)
  [@mutaml.skip
    "every caller passes an offset where the word fits before stop or meets a \
     line ending first: first_close checks offset + 3 <= stop itself, and \
     comment_range calls it at the < that starts a block, whose first line \
     ends before stop; no delimiter holds a line ending, so the compare fails \
     there as the bound does"]
  && same 0

let first_close text start stop =
  let rec search offset =
    if
      (offset
      + String.length close_delimiter)
      [@mutaml.skip
        "holds refuses an offset whose three bytes pass stop, so a search that \
         goes some offsets further finds no other close and ends with None"]
      > stop
    then None
    else if holds text offset stop close_delimiter then Some offset
    else search (offset + 1)
  in
  search (start + 2)

let comment_range lines start stop =
  let text = Line_index.text lines in
  let at = first_kept is_blank_byte text start in
  if holds text at stop open_delimiter then
    Option.map (fun close -> (at, close)) (first_close text at stop)
  else None

let rec skip_blanks text offset stop =
  if
    (offset < stop)
    [@mutaml.skip
      "the byte at stop is the - of the close or the line ending of the line, \
       never a space or a tab, so the scan stops at stop either way"]
    && is_blank_byte text.[offset]
  then skip_blanks text (offset + 1) stop
  else offset

let rec back_blanks text offset start =
  if offset > start && is_blank_byte text.[offset - 1] then
    back_blanks text (offset - 1) start
  else offset

let comment_row lines ~opened ~close ~first_line ~last_line line =
  let text = Line_index.text lines in
  let limit =
    if line = last_line then close else Line_index.content_end lines line
  in
  let head_stop =
    if line = first_line then opened else Line_index.first lines line
  in
  let body_start =
    if line = first_line then
      skip_blanks text (min (opened + String.length open_delimiter) limit) limit
    else head_stop
  in
  let body_stop = back_blanks text limit body_start in
  ( {
      row = line;
      head_stop;
      body_start;
      body_stop;
      closes = line = last_line;
      written =
        Tag_line.read (String.sub text body_start (body_stop - body_start));
    },
    (line = first_line || line = last_line) && body_stop = body_start )

let comment_of_range lines ~opened ~close =
  let first_line = Line_index.line_of lines opened in
  let last_line = Line_index.line_of lines close in
  let rec collect line rows delimiters =
    if line < first_line then (rows, delimiters)
    else
      let row, only_delimiter =
        comment_row lines ~opened ~close ~first_line ~last_line line
      in
      if only_delimiter then collect (line - 1) rows (line :: delimiters)
      else collect (line - 1) (row :: rows) delimiters
  in
  let rows, delimiter_rows = collect last_line [] [] in
  {
    rows;
    holds_tag = List.exists (fun row -> Option.is_some row.written) rows;
    first_content =
      List.find_opt (fun row -> row.body_stop > row.body_start) rows;
    delimiter_rows;
  }

let comment_block lines block =
  match comment_range lines block.start block.stop with
  | Some (opened, close)
    when Option.is_none
           (last_kept is_space_byte (Line_index.text lines)
              (close + String.length close_delimiter)
              block.stop) ->
      Some (comment_of_range lines ~opened ~close)
  | Some _ | None -> None

let split_task_comment lines = function
  | ({ kind = Paragraph; start; stop; _ } as paragraph) :: blocks -> (
      let text = Line_index.text lines in
      match comment_range lines start stop with
      | Some (_, close) ->
          let line = Line_index.line_of lines close in
          let line_end = Line_index.content_end lines line in
          if
            Option.is_some
              (last_kept is_space_byte text
                 (close + String.length close_delimiter)
                 line_end)
          then paragraph :: blocks
          else
            let comment =
              { kind = Html; start; stop = line_end; children = [] }
            in
            if line < content_last_line lines paragraph then
              comment
              :: { paragraph with start = Line_index.first lines (line + 1) }
              :: blocks
            else comment :: blocks
      | None -> paragraph :: blocks)
  | blocks -> blocks

let rec leading lines comments = function
  | ({ kind = Html; _ } as block) :: blocks as all -> (
      match comment_block lines block with
      | Some comment -> leading lines (comment :: comments) blocks
      | None -> (List.rev comments, all))
  | blocks -> (List.rev comments, blocks)

let check_comment walk comment =
  match comment.first_content with
  | Some { written = Some (at, _); body_start; body_stop; _ } ->
      Dynarray.add_last walk.unread
        (span_to walk.lines (body_start + at) body_stop)
  | Some _ | None -> ()

let rec walk_blocks walk ~container ~in_section ~bearer (comments, blocks) =
  let node part =
    Dynarray.add_last walk.bearing { container; in_section; bearer; part }
  in
  List.iter
    (fun comment ->
      if comment.holds_tag then (
        node (Comment_part comment);
        List.iter (Dynarray.add_last walk.comment_rows) comment.rows;
        List.iter
          (Dynarray.add_last walk.delimiter_lines)
          comment.delimiter_rows))
    comments;
  let blocks =
    match blocks with
    | ({ kind = Paragraph; _ } as paragraph) :: blocks ->
        node (Paragraph_part paragraph);
        blocks
    | blocks -> blocks
  in
  List.iter
    (fun block ->
      match block.kind with
      | Paragraph -> check_unread walk block
      | Html ->
          Option.iter (check_comment walk) (comment_block walk.lines block)
      | Item -> walk_item walk ~parent:container ~in_section block
      | Section ->
          walk_section walk ~parent:(Some in_section) ~holder:(Some container)
            block
      | Heading | Other -> ())
    blocks

and walk_item walk ~parent ~in_section item =
  let container =
    add walk.containers
      {
        first_line = Line_index.line_of walk.lines item.start;
        last_line = last_line walk.lines item;
        parent = Some parent;
      }
  in
  walk_blocks walk ~container ~in_section ~bearer:Item_node
    (leading walk.lines []
       (split_task_comment walk.lines (flatten item.children)))

and walk_section walk ~parent ~holder section =
  let lines = walk.lines in
  let level, heading, blocks =
    match section.children with
    | ({ kind = Heading; _ } as node) :: blocks ->
        let line = Line_index.line_of lines node.start in
        let content =
          String.sub (Line_index.text lines) node.start
            (Line_index.content_end lines line - node.start)
        in
        let marks, level, text, offset = heading_text content in
        let cut = Section_number.length text in
        if
          (cut > 0)
          [@mutaml.skip
            "Section_number.length is 0 or at least 3, and an entry with a cut \
             of 0 removes no byte, so each text and each hash is the same with \
             it or without it"]
        then Dynarray.add_last walk.numbers (line, node.start + offset, cut);
        let text = String.sub text cut (String.length text - cut) in
        let slug = Slug.of_heading text in
        ( level,
          Some
            {
              text;
              slug;
              name = walk.number slug;
              span = tag_span lines (node.start + marks) line;
            },
          blocks )
    | blocks -> (0, None, blocks)
  in
  let container =
    add walk.containers
      {
        first_line =
          (if level = 0 then 1 else Line_index.line_of lines section.start);
        last_line = last_line lines section;
        parent = holder;
      }
  in
  let ((_, after) as start) = leading lines [] blocks in
  let first_paragraph =
    match after with
    | { kind = Paragraph; start; stop; _ } :: _ ->
        Some (trimmed_span lines start stop)
    | _ -> None
  in
  let in_section =
    add walk.sections
      ( { level; heading; parent; first_paragraph; extent = None; text = None },
        container )
  in
  walk_blocks walk ~container ~in_section ~bearer:Section_node start

type pending = {
  line : int;
  at : int;
  tag_line : Tag_line.t;
  parts : Tag_line.parts;
  head_stop : int;
  body_start : int;
  rest_start : int;
  stop_offset : int;
  of_node : bearing;
  in_block : int;
  declares : bool;
  in_comment_block : bool;
  closes : bool;
}

type pending_block = {
  members : int list;
  prose_lines : string list;
  block_lines : int list;
  last_tag_line : int;
  last_at : int;
}

let declaration_words = [ "req"; "design"; "decision"; "rule" ]

let citation_words =
  [ "satisfies"; "verifies"; "refines"; "cites"; "supersedes" ]

let declares (tag_line : Tag_line.t) (parts : Tag_line.parts) =
  List.mem tag_line.word declaration_words
  &&
  match parts.target with
  | Some target -> Slug.is_valid target
  | None -> false

let read_node lines tags blocks node =
  let text = Line_index.text lines in
  let current = ref None in
  let close () =
    match !current with
    | Some block ->
        ignore
          (add blocks
             {
               block with
               members = List.rev block.members;
               prose_lines = List.rev block.prose_lines;
               block_lines = List.rev block.block_lines;
             });
        current := None
    | None -> ()
  in
  let tag_line ~line ~head_stop ~body_start ~at ~stop ~in_comment_block ~closes
      (tag_line : Tag_line.t) =
    (match !current with
    | Some { prose_lines = []; _ } -> ()
    | Some _ | None ->
        close ();
        current :=
          Some
            {
              members = [];
              prose_lines = [];
              block_lines = [];
              last_tag_line = line;
              last_at =
                at
                [@mutaml.skip
                  "the update of current right after this one sets last_at to \
                   at again, so no code reads this value"];
            });
    let in_block = Dynarray.length blocks in
    let parts = Tag_line.parts tag_line.rest in
    let index =
      add tags
        {
          line;
          at;
          tag_line;
          parts;
          head_stop;
          body_start;
          rest_start = at + 1 + String.length tag_line.word;
          stop_offset = stop;
          of_node = node;
          in_block;
          declares = declares tag_line parts;
          in_comment_block;
          closes;
        }
    in
    current :=
      Option.map
        (fun block ->
          {
            block with
            members = index :: block.members;
            block_lines = line :: block.block_lines;
            last_tag_line = line;
            last_at = at;
          })
        !current
  in
  let prose line words =
    current :=
      Option.map
        (fun block ->
          {
            block with
            prose_lines = words :: block.prose_lines;
            block_lines = line :: block.block_lines;
          })
        !current
  in
  (match node.part with
  | Comment_part comment ->
      List.iter
        (fun row ->
          match row.written with
          | Some (at, written) ->
              tag_line ~line:row.row ~head_stop:row.head_stop
                ~body_start:row.body_start ~at:(row.body_start + at)
                ~stop:row.body_stop ~in_comment_block:true ~closes:row.closes
                written
          | None when row.body_stop > row.body_start ->
              prose row.row
                (String.sub text row.body_start
                   (row.body_stop - row.body_start))
          | None -> close ())
        comment.rows
  | Paragraph_part paragraph ->
      let first = Line_index.line_of lines paragraph.start in
      let last = content_last_line lines paragraph in
      for line = first to last do
        let start =
          if line = first then paragraph.start else Line_index.first lines line
        in
        let stop = max start (Line_index.content_end lines line) in
        match Tag_line.read (String.sub text start (stop - start)) with
        | Some (at, written) ->
            let first_byte = Line_index.first lines line in
            tag_line ~line ~head_stop:first_byte ~body_start:first_byte
              ~at:(start + at) ~stop ~in_comment_block:false ~closes:false
              written
        | None -> prose line (Line_index.content lines line)
      done);
  close ()

let extent_lines lines ~delimiter ~holes first last =
  let count = Array.length holes in
  let rec collect line hole found =
    if line > last then found
    else if hole < count && fst holes.(hole) <= line then
      collect (max line (snd holes.(hole) + 1)) (hole + 1) found
    else collect (line + 1) hole (line :: found)
  in
  let rec drop_blank = function
    | line :: rest when delimiter line || is_blank_line lines line ->
        drop_blank rest
    | kept -> kept
  in
  List.rev (drop_blank (collect first 0 []))

let plain_line lines ~numbered ~row_at line =
  let content = Line_index.content lines line in
  match (numbered line, row_at line) with
  | Some (offset, cut), _ ->
      let start = offset - Line_index.first lines line in
      strip_end
        (String.sub content 0 start
        ^ String.sub content (start + cut) (String.length content - start - cut)
        )
  | None, Some (row : row) ->
      let text = Line_index.text lines in
      let first = Line_index.first lines line in
      strip_end
        (String.sub text first (row.head_stop - first)
        ^ String.sub text row.body_start (row.body_stop - row.body_start))
  | None, None -> strip_end content

let section_text lines ~at ~delimiter ~numbered ~row_at first last =
  let rec drop_blank = function
    | line :: rest when is_blank_line lines line -> drop_blank rest
    | kept -> kept
  in
  List.init (max 0 (last - first + 1)) (fun offset -> first + offset)
  |> List.filter (fun line -> Option.is_none (at line) && not (delimiter line))
  |> drop_blank |> List.rev |> drop_blank |> List.rev
  |> List.map (fun line -> plain_line lines ~numbered ~row_at line ^ "\n")
  |> String.concat ""

let hash_lines lines ~at ~delimiter ~numbered ~row_at ~own included =
  let normal line =
    match at line with
    | Some (_, pending) when pending.tag_line.word = "ack" -> None
    | Some (index, pending) when own index ->
        Some (strip pending.parts.description)
    | Some (_, pending) ->
        let text = Line_index.text lines in
        let start = Line_index.first lines line in
        let rest =
          if List.mem pending.tag_line.word citation_words then
            Tag_line.without_revision pending.tag_line.rest
          else pending.tag_line.rest
        in
        Some
          (strip_end
             (String.sub text start (pending.head_stop - start)
             ^ String.sub text pending.body_start
                 (pending.rest_start - pending.body_start)
             ^ rest))
    | None when delimiter line -> None
    | None -> Some (plain_line lines ~numbered ~row_at line)
  in
  Sha256.hex (String.concat "\n" (List.filter_map normal included) ^ "\n")

let parse_errors lines (report : Sinter_bridge.Tree.report) =
  let span_of (node : Sinter_bridge.Tree.node) =
    trimmed_span lines node.range.start_byte node.range.end_byte
  in
  match (report.errors, report.lowest) with
  | [], Some node -> [ span_of node ]
  | errors, _ -> List.map (fun (_, node) -> span_of node) errors

let structure lines captures =
  let nodes =
    List.map
      (fun (capture : Sinter_bridge.Query.capture) ->
        {
          kind = kind_of capture.node_type;
          start = capture.range.start_byte;
          stop = capture.range.end_byte;
          children = [];
        })
      captures
  in
  let walk =
    {
      lines;
      containers = Dynarray.create ();
      sections = Dynarray.create ();
      bearing = Dynarray.create ();
      unread = Dynarray.create ();
      delimiter_lines = Dynarray.create ();
      comment_rows = Dynarray.create ();
      numbers = Dynarray.create ();
      number = numberer ();
    }
  in
  List.iter
    (fun root ->
      match root.kind with
      | Section -> walk_section walk ~parent:None ~holder:None root
      | Heading | Paragraph | Item | Html | Other -> ())
    (nest nodes);
  walk

let range_of = function
  | low :: _ as included ->
      Some (low, List.nth included (List.length included - 1))
  | [] -> None

let by_container declarations =
  let rec group = function
    | [] -> []
    | ((_, first) as head) :: rest ->
        let same, others =
          let rec take same = function
            | ((_, tag) as next) :: rest
              when tag.of_node.container = first.of_node.container ->
                take (next :: same) rest
            | rest -> (List.rev same, rest)
          in
          take [ head ] rest
        in
        same :: group others
  in
  group declarations

let widest_shared_indent = 16

let shared_new_lines ending =
  Array.init (widest_shared_indent + 1) (fun width ->
      ending ^ String.make width ' ')

let shared_lf = shared_new_lines "\n"
let shared_crlf = shared_new_lines "\r\n"

let new_line lines ~line ~at =
  let text = Line_index.text lines in
  let crlf = text.[Line_index.content_end lines line] = '\r' in
  let first = Line_index.first lines line in
  let rec width offset count =
    if offset = at then Some count
    else if text.[offset] = '\t' then None
    else
      width (offset + 1)
        (if
           Char.code
             (text.[offset]
              [@mutaml.skip
                "the bytes of a line before the @ of a tag line are blanks, \
                 list markers, task boxes, and a comment delimiter, all ASCII, \
                 and the @ is ASCII too, so offset + 1 also reads a byte that \
                 starts a character; the mark also takes out offset - 1, which \
                 counts the byte before each byte"])
           land (0xC0
                [@mutaml.skip
                  "the bytes of a line before the @ of a tag line are blanks, \
                   list markers, task boxes, and a comment delimiter, all \
                   ASCII; an ASCII byte has its top bit clear, so no mask \
                   gives 0x80, and each byte counts as one character either \
                   way"])
           <> (0x80
              [@mutaml.skip
                "the bytes of a line before the @ of a tag line are blanks, \
                 list markers, task boxes, and a comment delimiter, all ASCII, \
                 so each byte counts as one character either way"])
         then count + 1
         else count)
  in
  match width first 0 with
  | Some count when count <= widest_shared_indent ->
      (if crlf then shared_crlf else shared_lf).(count)
  | Some _ | None ->
      (if crlf then "\r\n" else "\n")
      ^ Tag_line.indent (String.sub text first (at - first))

let assemble lines ~open_end ~texts walk errors =
  let pending = Dynarray.create () and pending_blocks = Dynarray.create () in
  Dynarray.iter (read_node lines pending pending_blocks) walk.bearing;
  let pending = Dynarray.to_array pending in
  let containers = Dynarray.to_array walk.containers in
  let declared = Array.make (Array.length containers) false in
  Array.iter
    (fun tag -> if tag.declares then declared.(tag.of_node.container) <- true)
    pending;
  let holes = Array.make (Array.length containers) [] in
  Array.iteri
    (fun index (container : container) ->
      if declared.(index) then
        let rec up = function
          | Some parent ->
              holes.(parent) <-
                (container.first_line, container.last_line) :: holes.(parent);
              up containers.(parent).parent
          | None -> ()
        in
        up container.parent)
    containers;
  let holes =
    Array.map (fun holes -> Array.of_list (List.sort compare holes)) holes
  in
  let count = Line_index.count lines in
  let at_line = Array.make (count + 1) None in
  Array.iteri (fun index tag -> at_line.(tag.line) <- Some (index, tag)) pending;
  let at line = at_line.(line) in
  let number_at = Array.make (count + 1) None in
  Dynarray.iter
    (fun (line, offset, cut) -> number_at.(line) <- Some (offset, cut))
    walk.numbers;
  let numbered line = number_at.(line) in
  let delimiter_at = Array.make (count + 1) false in
  Dynarray.iter (fun line -> delimiter_at.(line) <- true) walk.delimiter_lines;
  let delimiter line = delimiter_at.(line) in
  let row_table = Array.make (count + 1) None in
  Dynarray.iter (fun row -> row_table.(row.row) <- Some row) walk.comment_rows;
  let row_at line = row_table.(line) in
  let owners = Array.make (count + 1) None in
  let extents = Array.make (Array.length pending) None in
  let claim declarations =
    let rec split start = function
      | [] -> ()
      | (index, tag) :: later -> (
          let container = tag.of_node.container in
          let stop =
            match later with
            | (_, next) :: _ -> next.line - 1
            | [] -> containers.(container).last_line
          in
          let included =
            extent_lines lines ~delimiter ~holes:holes.(container) start stop
          in
          List.iter (fun line -> owners.(line) <- Some index) included;
          (match range_of included with
          | Some (first, last) ->
              let hash =
                hash_lines lines ~at ~delimiter ~numbered ~row_at
                  ~own:(fun other -> other = index)
                  included
              in
              extents.(index) <- Some { first; last; hash }
          | None -> ());
          match later with (_, next) :: _ -> split next.line later | [] -> ())
    in
    match declarations with
    | (_, tag) :: _ ->
        split containers.(tag.of_node.container).first_line declarations
    | [] -> ()
  in
  pending |> Array.to_list
  |> List.mapi (fun index tag -> (index, tag))
  |> List.filter (fun (_, tag) -> tag.declares)
  |> by_container |> List.iter claim;
  let blocks =
    Array.map
      (fun block ->
        let own index = pending.(index).declares in
        {
          tags = block.members;
          prose = block.prose_lines;
          new_line = new_line lines ~line:block.last_tag_line ~at:block.last_at;
          hash =
            hash_lines lines ~at ~delimiter ~numbered ~row_at ~own
              block.block_lines;
        })
      (Dynarray.to_array pending_blocks)
  in
  let tags =
    Array.mapi
      (fun index tag ->
        {
          span = span_to lines tag.at tag.stop_offset;
          word = tag.tag_line.word;
          rest = tag.tag_line.rest;
          target = tag.parts.target;
          rev = tag.parts.revision;
          desc = tag.parts.description;
          block = tag.in_block;
          node = tag.of_node.bearer;
          section = tag.of_node.in_section;
          owner = owners.(tag.line);
          extent = extents.(index);
          in_comment = tag.in_comment_block;
          closes_comment = tag.closes;
        })
      pending
  in
  let sections =
    Array.map
      (fun ((section : section), container_index) ->
        let container = containers.(container_index) in
        let extent =
          extent_lines lines ~delimiter ~holes:holes.(container_index)
            container.first_line container.last_line
          |> range_of
          |> Option.map (fun (first, last) ->
              {
                start = { line = first; column = 1 };
                stop =
                  Line_index.after lines (Line_index.content_end lines last);
              })
        in
        let text =
          if texts then
            Some
              (section_text lines ~at ~delimiter ~numbered ~row_at
                 (if section.level = 0 then container.first_line
                  else container.first_line + 1)
                 container.last_line)
          else None
        in
        { section with extent; text })
      (Dynarray.to_array walk.sections)
  in
  {
    sections;
    tags;
    blocks;
    unread = Dynarray.to_list walk.unread;
    errors;
    unterminated = (if open_end then Some (Line_index.count lines) else None);
  }

let columns (tag : tag) part =
  let start = tag.span.start.column in
  let word_stop = 1 + String.length tag.word in
  match part with
  | Tag_line.Word -> Some (start, start + word_stop)
  | Tag_line.Target | Tag_line.Revision ->
      let column offset =
        start + word_stop + Line_index.characters tag.rest 0 (offset - word_stop)
      in
      Option.map
        (fun (range : Tag_line.range) ->
          (column range.start, column range.stop))
        (Tag_line.range { Tag_line.word = tag.word; rest = tag.rest } part)

let read ?(texts = true) reader content =
  match Sinter_bridge.Utf_8.first_invalid content with
  | Some offset -> Error (Not_utf_8 offset)
  | None -> (
      let text = Text_file.with_final_line_feed content in
      let open_end =
        content <> "" && String.length text <> String.length content
      in
      match Sinter_bridge.Tree.parse reader.language text with
      | Error error -> Error (No_tree error)
      | Ok tree ->
          Fun.protect
            ~finally:(fun () -> Sinter_bridge.Tree.close tree)
            (fun () ->
              let lines = Line_index.make ~open_end text in
              let captures =
                match Sinter_bridge.Query.run reader.query tree with
                | Ok captures -> captures
                | Error error ->
                    invalid_arg (Sinter_bridge.Query.run_message error)
              in
              let errors =
                parse_errors lines (Sinter_bridge.Tree.errors tree)
              in
              Ok
                (assemble lines ~open_end ~texts (structure lines captures)
                   errors)))
