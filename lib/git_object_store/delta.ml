(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type error =
  | Truncated
  | Base_size_differs
  | Too_large
  | Copy_outside_base
  | Reserved_instruction
  | Result_size_differs

let ( let* ) = Result.bind

let size delta start =
  let length = String.length delta in
  let rec go position value shift =
    if position >= length then Error Truncated
    else
      let byte = Char.code delta.[position] in
      let value = Saturating.add_bits value ~bits:(byte land 0x7f) ~shift in
      if byte land 0x80 = 0 then Ok (value, position + 1)
      else go (position + 1) value (shift + 7)
  in
  go start 0 0

let apply ~max_size ~base delta =
  if max_size < 0 then invalid_arg "Delta.apply: a negative maximum size";
  let max_size = min max_size Sys.max_string_length in
  let* base_size, position = size delta 0 in
  let* () =
    if base_size <> String.length base then Error Base_size_differs else Ok ()
  in
  let* result_size, position = size delta position in
  let* () = if result_size > max_size then Error Too_large else Ok () in
  let result = Bytes.create result_size in
  let length = String.length delta in
  let field byte position present shift value =
    if byte land present = 0 then Ok (value, position)
    else if position >= length then Error Truncated
    else Ok (value lor (Char.code delta.[position] lsl shift), position + 1)
  in
  let copy byte position written =
    let* offset, position = field byte position 0x01 0 0 in
    let* offset, position = field byte position 0x02 8 offset in
    let* offset, position = field byte position 0x04 16 offset in
    let* offset, position = field byte position 0x08 24 offset in
    let* count, position = field byte position 0x10 0 0 in
    let* count, position = field byte position 0x20 8 count in
    let* count, position = field byte position 0x40 16 count in
    let count = if count = 0 then 0x10000 else count in
    if offset + count > String.length base then Error Copy_outside_base
    else if count > result_size - written then Error Result_size_differs
    else (
      Bytes.blit_string base offset result written count;
      Ok (position, written + count))
  in
  let add count position written =
    if position + count > length then Error Truncated
    else if count > result_size - written then Error Result_size_differs
    else (
      Bytes.blit_string delta position result written count;
      Ok (position + count, written + count))
  in
  let rec run position written =
    if position = length then
      if written = result_size then Ok (Bytes.unsafe_to_string result)
      else Error Result_size_differs
    else
      let byte = Char.code delta.[position] in
      let* position, written =
        if byte land 0x80 <> 0 then copy byte (position + 1) written
        else if byte = 0 then Error Reserved_instruction
        else add byte (position + 1) written
      in
      run position written
  in
  run position 0
