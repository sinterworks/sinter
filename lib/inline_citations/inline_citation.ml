(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module C = Cmarkit
module Inline = C.Inline

type link_result =
  | Not_an_inline_citation
  | Invalid
  | Valid of { target : Target.t; link_text : string }

type link = { run : Text.run; result : link_result }

(* @satisfies identifiers#{give-results=v1, give-values=v1} *)
let markdown_document text =
  let body =
    Text.encode
      (Option.value ~default:Text.empty (Text.sub text (Text.body text)))
  in
  String.concat "\xEF\xBF\xBD" (String.split_on_char '\000' body)

let textloc meta = C.Meta.textloc meta
let first_byte meta = C.Textloc.first_byte (textloc meta)
let last_byte meta = C.Textloc.last_byte (textloc meta)

let slice md meta =
  String.sub md (first_byte meta) (last_byte meta - first_byte meta + 1)

(* @satisfies identifiers#reject-blank-link-text=v1 *)
let is_blank = function
  | 0x09 | 0x0A | 0x0C | 0x0D | 0x20 | 0xA0 | 0x1680 | 0x2000 | 0x2001 | 0x2002
  | 0x2003 | 0x2004 | 0x2005 | 0x2006 | 0x2007 | 0x2008 | 0x2009 | 0x200A
  | 0x200B | 0x200C | 0x200D | 0x202F | 0x205F | 0x2060 | 0x3000 | 0xFEFF ->
      true
  | _ -> false

let all_blank s =
  let rec go i =
    i >= String.length s
    ||
    let d = String.get_utf_8_uchar s i in
    is_blank (Uchar.to_int (Uchar.utf_decode_uchar d))
    && go (i + Uchar.utf_decode_length d)
  in
  go 0

(* @satisfies identifiers#reject-blank-link-text=v1 *)
let rec blank (inline : Inline.t) =
  match inline with
  | Inline.Text (text, _) -> all_blank text
  | Inline.Code_span (span, _) -> all_blank (Inline.Code_span.code span)
  | Inline.Emphasis (e, _) | Inline.Strong_emphasis (e, _) ->
      blank (Inline.Emphasis.inline e)
  | Inline.Link (l, _) | Inline.Image (l, _) -> blank (Inline.Link.text l)
  | Inline.Autolink _ -> false
  | Inline.Inlines (inlines, _) -> List.for_all blank inlines
  | _ -> true

let tight_starts acc lines =
  List.fold_left (fun acc (_, (_, meta)) -> first_byte meta :: acc) acc lines

(* @satisfies identifiers#give-values=v1 *)
let rec starts acc (inline : Inline.t) =
  match inline with
  | Inline.Break (_, meta) -> (last_byte meta + 1) :: acc
  | Inline.Code_span (span, _) ->
      tight_starts acc (Inline.Code_span.code_layout span)
  | Inline.Raw_html (lines, _) -> tight_starts acc lines
  | Inline.Emphasis (e, _) | Inline.Strong_emphasis (e, _) ->
      starts acc (Inline.Emphasis.inline e)
  | Inline.Link (l, _) | Inline.Image (l, _) ->
      let acc =
        match Inline.Link.reference l with
        | `Inline (definition, _) ->
            let acc =
              match C.Link_definition.dest definition with
              | Some (_, dest) -> first_byte dest :: acc
              | None -> acc
            in
            tight_starts acc
              (Option.value ~default:[] (C.Link_definition.title definition))
        | `Ref _ -> acc
      in
      starts acc (Inline.Link.text l)
  | Inline.Inlines (inlines, _) -> List.fold_left starts acc inlines
  | _ -> acc

(* @satisfies identifiers#give-values=v1 *)
let raw_content md line_starts first stop =
  let next_start q =
    let rec search low high =
      if low >= high then low
      else
        let middle = (low + high) / 2 in
        if
          (line_starts.(middle) >= q)
          [@mutaml.skip
            "no line of a paragraph or a heading starts right after a line \
             ending with a space, a tab, or a >, so a line start at that byte \
             is also the end of the prefix"]
        then search low middle
        else search (middle + 1) high
    in
    let k = search 0 (Array.length line_starts) in
    if k < Array.length line_starts then Some line_starts.(k) else None
  in
  let rec prefix j =
    match md.[j] with ' ' | '\t' | '>' -> prefix (j + 1) | _ -> j
  in
  let rec segments a i acc =
    if i >= stop then List.rev (String.sub md a (i - a) :: acc)
    else
      match md.[i] with
      | '\r' | '\n' ->
          let q = if md.[i] = '\r' && md.[i + 1] = '\n' then i + 2 else i + 1 in
          let p = prefix q in
          let next = match next_start q with Some c -> min p c | None -> p in
          segments next next (String.sub md a (i - a) :: acc)
      | _ -> segments a (i + 1) acc
  in
  String.concat "\n" (segments first first [])

(* @satisfies identifiers#{give-results=v1, accept-inputs=v1, reject-unmatched-inputs=v1, reject-blank-link-text=v1} *)
let citation binding destination link_text ~blank =
  let prefix = "sinter:" in
  if not (String.starts_with ~prefix destination) then Not_an_inline_citation
  else
    let target =
      String.sub destination (String.length prefix)
        (String.length destination - String.length prefix)
    in
    match Inline_target.read binding target with
    | Some target when not blank -> Valid { target; link_text }
    | _ -> Invalid

let read binding text =
  let md = markdown_document text in
  let doc = C.Doc.of_string ~strict:true ~locs:true md in
  let from = (Text.body text).from in
  let boundaries =
    lazy
      (let index = Array.make (String.length md + 1) 0 in
       String.iteri
         (fun i c ->
           index.(i + 1) <-
             (index.(i) + if Char.code c land 0xC0 = 0x80 then 0 else 1))
         md;
       index)
  in
  let run meta =
    let index = Lazy.force boundaries in
    {
      Text.from = from + index.(first_byte meta);
      until = from + index.(last_byte meta + 1);
    }
  in
  (* @satisfies identifiers#give-values=v1 *)
  let link_text line_starts l meta =
    let closer =
      match Inline.Link.text l with
      | Inline.Inlines (_, text) -> last_byte text
      | text -> last_byte (Inline.meta text) + 1
    in
    raw_content md line_starts (first_byte meta + 1) closer
  in
  let destination l =
    match Inline.Link.reference_definition (C.Doc.defs doc) l with
    | Some (C.Link_definition.Def (definition, _)) -> (
        match C.Link_definition.dest definition with
        | Some (d, _) -> d
        | None -> "")
    | _ -> ""
  in
  (* @satisfies identifiers#{give-results=v1, reject-unmatched-inputs=v1, give-values=v1} *)
  let rec visit line_starts acc (inline : Inline.t) =
    match inline with
    | Inline.Link (l, meta) ->
        let result =
          citation binding (destination l)
            (link_text line_starts l meta)
            ~blank:(blank (Inline.Link.text l))
        in
        visit line_starts
          ({ run = run meta; result } :: acc)
          (Inline.Link.text l)
    | Inline.Image (l, meta) ->
        visit line_starts
          ({ run = run meta; result = Not_an_inline_citation } :: acc)
          (Inline.Link.text l)
    | Inline.Autolink (a, meta) ->
        let raw = slice md (snd (Inline.Autolink.link a)) in
        { run = run meta; result = citation binding raw raw ~blank:false }
        :: acc
    | Inline.Emphasis (e, _) | Inline.Strong_emphasis (e, _) ->
        visit line_starts acc (Inline.Emphasis.inline e)
    | Inline.Inlines (inlines, _) ->
        List.fold_left (visit line_starts) acc inlines
    | _ -> acc
  in
  let root acc inline =
    let line_starts = Array.of_list (starts [] inline) in
    Array.sort compare line_starts;
    visit line_starts acc inline
  in
  (* @satisfies identifiers#give-results=v1 *)
  let rec blocks acc (block : C.Block.t) =
    match block with
    | C.Block.Blocks (bs, _) -> List.fold_left blocks acc bs
    | C.Block.Block_quote (q, _) -> blocks acc (C.Block.Block_quote.block q)
    | C.Block.List (l, _) ->
        List.fold_left
          (fun acc (item, _) -> blocks acc (C.Block.List_item.block item))
          acc (C.Block.List'.items l)
    | C.Block.Paragraph (p, _) -> root acc (C.Block.Paragraph.inline p)
    | C.Block.Heading (h, _) -> root acc (C.Block.Heading.inline h)
    | _ -> acc
  in
  List.rev (blocks [] (C.Doc.block doc))
