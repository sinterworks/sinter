(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type value =
  | String of string
  | Integer of int64
  | Float of float
  | Boolean of bool
  | Local_date of Sinter_toml.date
  | Local_time of Sinter_toml.time
  | Local_date_time of Sinter_toml.date * Sinter_toml.time
  | Offset_date_time of Sinter_toml.date * Sinter_toml.time * Sinter_toml.offset
  | Array of value list
  | Table of table

and table = (string * value) list

type step = Text of string | Index of int
type location = step list

let steps location = List.rev location

type subject = Toml_value | Key | Toml_key of int

type span = {
  start : Sinter_text.Lines.position;
  end_ : Sinter_text.Lines.position;
}

type document = { root_table : table; spans : (subject * location * span) list }
type outcome = Valid of document | Invalid | No_result

let sorted pairs = List.sort (fun (a, _) (b, _) -> String.compare a b) pairs

let boundaries bytes =
  let counts = Array.make (String.length bytes + 1) 0 in
  String.iteri
    (fun index byte ->
      let continuation = Char.code byte land 0xC0 = 0x80 in
      counts.(index + 1) <- (counts.(index) + if continuation then 0 else 1))
    bytes;
  counts

(* @satisfies data-forms#give-only-toml-spans=v1
   Each span of the reader, a pair of byte offsets, becomes the run between
   the boundaries of the characters that the offsets stand at, and its start
   and end are the positions that Text and notation gives for that run. *)
let position_span lines counts (span : Sinter_toml.span) =
  match
    Sinter_text.Lines.span lines
      { from = counts.(span.start); until = counts.(span.stop) }
  with
  | Ok (start, end_) -> Some { start; end_ }
  | Error (Not_a_run | Not_a_span) -> None

(* @satisfies data-forms#give-only-toml-spans=v1
   Each item gives its location, the steps from the root table, with the span
   of its TOML value, the span of the key that leads to it, and the span of
   each TOML key of that key with its index. *)
let item_spans convert location (item : Sinter_toml.item) =
  let value =
    match item.span with Some span -> [ (Toml_value, span) ] | None -> []
  in
  let keys =
    match item.key with
    | Some key ->
        (Key, key.whole)
        :: List.mapi (fun index part -> (Toml_key (index + 1), part)) key.parts
    | None -> []
  in
  List.filter_map
    (fun (subject, span) ->
      Option.map (fun span -> (subject, location, span)) (convert span))
    (value @ keys)

type frame = {
  name : string;
  rev_location : step list;
  build : (string * value) list -> value;
  mutable todo : (string * step * Sinter_toml.item) list;
  mutable rev_done : (string * value) list;
}

type visit = Done of value | Open of frame

let table_value pairs = Table (sorted pairs)

let visit name rev_location (item : Sinter_toml.item) =
  let open_frame build todo =
    Open { name; rev_location; build; todo; rev_done = [] }
  in
  match item.value with
  | String text -> Done (String text)
  | Integer integer -> Done (Integer integer)
  | Float float -> Done (Float float)
  | Boolean boolean -> Done (Boolean boolean)
  | Local_date date -> Done (Local_date date)
  | Local_time time -> Done (Local_time time)
  | Local_date_time (date, time) -> Done (Local_date_time (date, time))
  | Offset_date_time (date, time, offset) ->
      Done (Offset_date_time (date, time, offset))
  | Array items ->
      open_frame
        (fun pairs -> Array (List.map snd pairs))
        (List.mapi (fun index item -> ("", Index (index + 1), item)) items)
  | Table pairs ->
      open_frame table_value
        (List.map (fun (text, item) -> (text, Text text, item)) pairs)

let document convert (root : Sinter_toml.table) =
  let rev_spans = ref [] in
  let root_frame =
    {
      name = "";
      rev_location = [];
      build = table_value;
      todo = List.map (fun (text, item) -> (text, Text text, item)) root;
      rev_done = [];
    }
  in
  let rec run = function
    | [] -> { root_table = sorted root_frame.rev_done; spans = !rev_spans }
    | top :: below as stack -> (
        match top.todo with
        | (name, step, item) :: todo -> (
            top.todo <- todo;
            let rev_location = step :: top.rev_location in
            rev_spans :=
              List.rev_append (item_spans convert rev_location item) !rev_spans;
            match visit name rev_location item with
            | Done value ->
                top.rev_done <- (name, value) :: top.rev_done;
                run stack
            | Open frame -> run (frame :: stack))
        | [] -> (
            match below with
            | [] -> run []
            | parent :: _ ->
                parent.rev_done <-
                  (top.name, top.build (List.rev top.rev_done))
                  :: parent.rev_done;
                run below))
  in
  run [ root_frame ]

(* @satisfies data-forms#read-toml=v1
   A limit of the reader gives no result, never "invalid", so the result
   "invalid" comes only for a byte sequence that is not a TOML document. *)
let read ?max_depth ?max_key_parts bytes =
  match Sinter_toml.read ?max_depth ?max_key_parts bytes with
  | Error (Invalid _) -> Invalid
  | Error (Limit_reached _) -> No_result
  | Ok root -> (
      match Sinter_text.Text.decode bytes with
      | Error (Invalid_utf_8 _) -> Invalid
      | Ok text ->
          let lines = Sinter_text.Lines.of_text text in
          Valid (document (position_span lines (boundaries bytes)) root))
