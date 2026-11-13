(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Texts = Map.Make (String)

type state = Root | Undefined_super | Named | Dotted | Inline

type table = {
  mutable entries : node Texts.t;
  mutable rev_order : (string * node) list;
  mutable state : state;
}

and node =
  | Leaf of Types.value
  | Elements of node list
  | Tables of tables
  | Sub of table

and tables = { mutable last : table; mutable rev_before : table list }

type slot = { target : table; text : string }

let new_table state = { entries = Texts.empty; rev_order = []; state }
let root () = new_table Root
let inline () = new_table Inline
let scalar value = Leaf value
let array elements = Elements elements
let table_value table = Sub table

let add table text node =
  table.entries <- Texts.add text node table.entries;
  table.rev_order <- (text, node) :: table.rev_order

let add_table holder text state =
  let table = new_table state in
  add holder text (Sub table);
  table

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A key/value pair walks from its holding table: a missing part makes a table
   that the pair defines, an undefined super-table becomes a table that the
   pair defines, and the walk breaks closed-inline-table at the table of an
   inline table, header-free-path at a table that a table header names, and
   table-on-the-way at a value that is not a table. *)
let step_pair holder text =
  match Texts.find_opt text holder.entries with
  | None -> Ok (add_table holder text Dotted)
  | Some (Sub table) -> (
      match table.state with
      | Inline -> Error Types.Inline_table_closed
      | Named -> Error Types.Dotted_key_into_named_table
      | Undefined_super ->
          table.state <- Dotted;
          Ok table
      | Root | Dotted -> Ok table)
  | Some (Tables _) -> Error Types.Dotted_key_into_named_table
  | Some (Leaf _ | Elements _) -> Error Types.Not_a_table

(* @satisfies data-forms#read-toml=v1
   The last part of the key of a key/value pair must lead to no value at the
   boundary right before the pair, by the rule new-key. *)
let walk_pair holding first rest =
  let rec walk table text rest =
    match rest with
    | [] ->
        if Texts.mem text table.entries then Error Types.Duplicate_key
        else Ok { target = table; text }
    | next :: rest -> (
        match step_pair table text with
        | Ok table -> walk table next rest
        | Error _ as error -> error)
  in
  walk holding first rest

(* @satisfies data-forms#give-only-root-tables=v1
   A key/value pair adds its last TOML key to the table where its walk ends,
   with its value. *)
let fill slot node = add slot.target slot.text node

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A table header walks from the root table: a missing part makes an undefined
   super-table, an array that table headers make leads to its last table, and
   the walk breaks closed-inline-table at the table of an inline table and
   table-on-the-way at a value that is not a table. *)
let step_header holder text =
  match Texts.find_opt text holder.entries with
  | None -> Ok (add_table holder text Undefined_super)
  | Some (Sub table) -> (
      match table.state with
      | Inline -> Error Types.Inline_table_closed
      | Root | Undefined_super | Named | Dotted -> Ok table)
  | Some (Tables tables) -> Ok tables.last
  | Some (Leaf _ | Elements _) -> Error Types.Not_a_table

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A table header names an undefined super-table or a new table, and breaks
   single-definition at a table that a part defines, header-target at a value
   that is not a table, and closed-inline-table at the table of an inline
   table. *)
let name_table holder text =
  match Texts.find_opt text holder.entries with
  | None -> Ok (add_table holder text Named)
  | Some (Sub table) -> (
      match table.state with
      | Undefined_super ->
          table.state <- Named;
          Ok table
      | Inline -> Error Types.Inline_table_closed
      | Root | Named | Dotted -> Error Types.Table_defined_twice)
  | Some (Tables _) -> Error Types.Table_defined_twice
  | Some (Leaf _ | Elements _) -> Error Types.Not_a_table

(* @satisfies data-forms#{read-toml=v1, give-only-root-tables=v1}
   A table header with double brackets adds a new table to the end of an array
   that table headers make, or makes such an array, and breaks
   array-header-target at every other value. *)
let add_array_table holder text =
  match Texts.find_opt text holder.entries with
  | None ->
      let table = new_table Named in
      add holder text (Tables { last = table; rev_before = [] });
      Ok table
  | Some (Tables tables) ->
      let table = new_table Named in
      tables.rev_before <- tables.last :: tables.rev_before;
      tables.last <- table;
      Ok table
  | Some (Sub { state = Inline; _ }) -> Error Types.Inline_table_closed
  | Some (Sub _ | Leaf _ | Elements _) -> Error Types.Not_an_array_of_tables

let walk_header root first rest ~array =
  let rec walk table text rest =
    match rest with
    | [] -> if array then add_array_table table text else name_table table text
    | next :: rest -> (
        match step_header table text with
        | Ok table -> walk table next rest
        | Error _ as error -> error)
  in
  walk root first rest

type frame = {
  name : string;
  build : (string * Types.value) list -> Types.value;
  mutable todo : (string * node) list;
  mutable rev_done : (string * Types.value) list;
}

let table_frame name table =
  {
    name;
    build = (fun pairs -> Types.Table pairs);
    todo = List.rev table.rev_order;
    rev_done = [];
  }

let array_frame name nodes =
  {
    name;
    build = (fun pairs -> Types.Array (List.map snd pairs));
    todo = List.map (fun node -> ("", node)) nodes;
    rev_done = [];
  }

type start = Done of Types.value | Open of frame

let start name = function
  | Leaf value -> Done value
  | Elements nodes -> Open (array_frame name nodes)
  | Tables tables ->
      Open
        (array_frame name
           (List.rev_map
              (fun table -> Sub table)
              (tables.last :: tables.rev_before)))
  | Sub table -> Open (table_frame name table)

let finish frame = frame.build (List.rev frame.rev_done)

let freeze root =
  let root_frame = table_frame "" root in
  let rec run = function
    | [] -> List.rev root_frame.rev_done
    | top :: below as stack -> (
        match top.todo with
        | (name, node) :: todo -> (
            top.todo <- todo;
            match start name node with
            | Done value ->
                top.rev_done <- (name, value) :: top.rev_done;
                run stack
            | Open frame -> run (frame :: stack))
        | [] -> (
            match below with
            | [] -> run []
            | parent :: _ ->
                parent.rev_done <- (top.name, finish top) :: parent.rev_done;
                run below))
  in
  run [ root_frame ]
