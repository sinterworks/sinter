(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type instruction =
  | Copy of int * int
  | Insert of string
  | Raw_instruction of string

let varint n =
  let buffer = Buffer.create 4 in
  let rec go n =
    let low = n land 0x7f and rest = n lsr 7 in
    if rest = 0 then Buffer.add_char buffer (Char.chr low)
    else (
      Buffer.add_char buffer (Char.chr (low lor 0x80));
      go rest)
  in
  go n;
  Buffer.contents buffer

let copy_bytes offset size =
  let size = if size = 0x10000 then 0 else size in
  let op = ref 0x80 and tail = Buffer.create 7 in
  for i = 0 to 3 do
    let byte = (offset lsr (8 * i)) land 0xff in
    if byte <> 0 then (
      op := !op lor (1 lsl i);
      Buffer.add_char tail (Char.chr byte))
  done;
  for i = 0 to 2 do
    let byte = (size lsr (8 * i)) land 0xff in
    if byte <> 0 then (
      op := !op lor (1 lsl (4 + i));
      Buffer.add_char tail (Char.chr byte))
  done;
  String.make 1 (Char.chr !op) ^ Buffer.contents tail

let instruction_bytes = function
  | Copy (offset, size) -> copy_bytes offset size
  | Insert data -> String.make 1 (Char.chr (String.length data)) ^ data
  | Raw_instruction bytes -> bytes

let delta ~base_size ~result_size instructions =
  varint base_size ^ varint result_size
  ^ String.concat "" (List.map instruction_bytes instructions)

let apply base instructions =
  String.concat ""
    (List.map
       (function
         | Copy (offset, size) ->
             if offset < 0 || size < 0 || offset + size > String.length base
             then invalid_arg "Object_files.apply: a copy outside the base"
             else String.sub base offset size
         | Insert data -> data
         | Raw_instruction _ -> invalid_arg "Object_files.apply: raw")
       instructions)

let inserts text =
  let rec go start acc =
    if start >= String.length text then List.rev acc
    else
      let size = min 127 (String.length text - start) in
      go (start + size) (Insert (String.sub text start size) :: acc)
  in
  go 0 []

let copies offset size =
  let rec go offset size acc =
    if size = 0 then List.rev acc
    else
      let part = min size 0xffffff in
      go (offset + part) (size - part) (Copy (offset, part) :: acc)
  in
  go offset size []

let delta_between base target =
  let lb = String.length base and lt = String.length target in
  let prefix = ref 0 in
  while !prefix < lb && !prefix < lt && base.[!prefix] = target.[!prefix] do
    incr prefix
  done;
  let suffix = ref 0 in
  while
    !suffix < lb - !prefix
    && !suffix < lt - !prefix
    && base.[lb - 1 - !suffix] = target.[lt - 1 - !suffix]
  do
    incr suffix
  done;
  copies 0 !prefix
  @ inserts (String.sub target !prefix (lt - !prefix - !suffix))
  @ copies (lb - !suffix) !suffix
