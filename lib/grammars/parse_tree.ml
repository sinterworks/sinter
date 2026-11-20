(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type node = int

type entry = {
  depth : int;
  symbol : int;
  start : int;
  finish : int;
  from : int;
  until : int;
}

type t = {
  text : Text.t;
  node_types : Text.t array;
  nodes : entry array;
  after : int array;
  root_has_error : bool;
}

type error =
  | Wrong_length
  | Wrong_flags of int
  | Wrong_depth of int
  | Unknown_symbol of int
  | Wrong_bytes of int

let ends_with_line_feed bytes =
  let length = String.length bytes in
  length > 0 && bytes.[length - 1] = '\n'

let parse_text text =
  let bytes = Text.encode text in
  if ends_with_line_feed bytes then bytes else bytes ^ "\n"

let word record index =
  Int32.to_int (String.get_int32_le record (4 * index)) land 0xFFFF_FFFF

let boundaries text =
  let bytes = Text.encode text in
  let length = String.length bytes in
  let rec go index found =
    let found = index :: found in
    if index >= length then found
    else
      go
        (index + Uchar.utf_decode_length (String.get_utf_8_uchar bytes index))
        found
  in
  let found = go 0 [] in
  Array.of_list
    (List.rev
       (if ends_with_line_feed bytes then found else (length + 1) :: found))

let boundary offsets byte =
  let rec search low high =
    if low > high then None
    else
      let middle = (low + high) / 2 in
      let found = offsets.(middle) in
      if found < byte then search (middle + 1) high
      else if found > byte then search low (middle - 1)
      else Some middle
  in
  search 0 (Array.length offsets - 1)

exception Wrong of error

let decode ~node_types text record =
  let length = String.length record in
  if length < 24 || length <> 8 + (16 * word record 0) then Error Wrong_length
  else
    let count = word record 0 and flags = word record 1 in
    if flags > 1 then Error (Wrong_flags flags)
    else
      let offsets = boundaries text in
      let entry index ~low ~high =
        let field k = word record (2 + (4 * index) + k) in
        let depth = field 0 in
        if depth < low || depth > high then raise (Wrong (Wrong_depth index));
        let symbol = field 1 in
        if symbol >= Array.length node_types then
          raise (Wrong (Unknown_symbol index));
        let start = field 2 and finish = field 3 in
        match (boundary offsets start, boundary offsets finish) with
        | Some from, Some until when start <= finish ->
            { depth; symbol; start; finish; from; until }
        | _ -> raise (Wrong (Wrong_bytes index))
      in
      try
        let nodes = Array.make count (entry 0 ~low:0 ~high:0) in
        for index = 1 to count - 1 do
          nodes.(index) <- entry index ~low:1 ~high:(nodes.(index - 1).depth + 1)
        done;
        let after = Array.make count count in
        let open_nodes = Stack.create () in
        Stack.push 0 open_nodes;
        for index = 1 to count - 1 do
          while nodes.(Stack.top open_nodes).depth >= nodes.(index).depth do
            after.(Stack.pop open_nodes) <- index
          done;
          Stack.push index open_nodes
        done;
        Ok { text; node_types; nodes; after; root_has_error = flags = 1 }
      with Wrong error -> Error error

let text tree = tree.text
let node_count tree = Array.length tree.nodes
let root _ = 0

let node tree index =
  if index >= 0 && index < node_count tree then Some index else None

let children tree n =
  let rec go child found =
    if child >= tree.after.(n) then List.rev found
    else go tree.after.(child) (child :: found)
  in
  go (n + 1) []

let node_type tree n = tree.node_types.(tree.nodes.(n).symbol)
let start_byte tree n = tree.nodes.(n).start
let end_byte tree n = tree.nodes.(n).finish

let run tree n =
  let { from; until; _ } = tree.nodes.(n) in
  let body = Text.body tree.text in
  let last = Text.length tree.text in
  let place boundary = max body.from (min boundary last) in
  { Text.from = place from; until = place until }

let root_has_error tree = tree.root_has_error
