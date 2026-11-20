(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_lines

let is_hex_digit c = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')

(* @satisfies ledger#valid-ledger-tree=v1
   Conditions 1 and 5 read the chunk path. The production `chunk-path`:
   `entries/`, two hex digits, `/`, an entry id in the form of `Entry_id`,
   `.jsonl`, and the two hex digits of the folder are the first two after
   `e-`. *)
let chunk_id bytes =
  match String.split_on_char '/' bytes with
  | [ "entries"; folder; file ] when String.ends_with ~suffix:".jsonl" file ->
      let id = String.sub file 0 (String.length file - 6) in
      if Entry_id.is_entry_id id && String.equal folder (String.sub id 2 2) then
        Some id
      else None
  | _ -> None

let is_hex_folder name =
  String.length name = 2 && String.for_all is_hex_digit name

(* @satisfies ledger#valid-ledger-tree=v1
   Condition 1 reads the number of the mode: after its leading zeros, the mode
   is `100644`, so its digits write that number in base 8 and no other. *)
let is_chunk_mode mode =
  String.ends_with ~suffix:"100644" mode
  && String.for_all (Char.equal '0')
       (String.sub mode 0 (String.length mode - 6))
