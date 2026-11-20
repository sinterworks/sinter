(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type code
type t = { code : code; size : int; back_references : int }
type compile_error = Not_valid of string | Too_deep | Too_large
type stop = Steps | Memory

let default_depth = 100
let default_compile_memory = 67_108_864
let default_steps = 10_000
let default_test_memory = 268_435_456
let most_depth = 200

external compile_stub : string -> int -> (code * int, compile_error) result
  = "sinter_ecma_pattern_compile_stub"

external test_stub : code -> string -> int -> int -> (bool, stop) result
  = "sinter_ecma_pattern_test_stub"

let check_count name count =
  if count < 0 then
    invalid_arg ("Sinter_ecma_pattern.Pattern: a negative " ^ name)

type scan = Plain | Escape | Class | Class_escape

let back_references ~depth bytes =
  let length = String.length bytes in
  let rec go index state open_groups references =
    if index >= length then Some references
    else
      let next = index + 1 in
      match (state, bytes.[index]) with
      | Plain, '\\' -> go next Escape open_groups references
      | Plain, '[' -> go next Class open_groups references
      | Plain, '(' ->
          if open_groups > depth then None
          else go next Plain (open_groups + 1) references
      | Plain, ')' -> go next Plain (max 0 (open_groups - 1)) references
      | Escape, ('1' .. '9' | 'k') -> go next Plain open_groups (references + 1)
      | Plain, _ | Escape, _ -> go next Plain open_groups references
      | Class, '\\' -> go next Class_escape open_groups references
      | Class, ']' -> go next Plain open_groups references
      | Class, _ | Class_escape, _ -> go next Class open_groups references
  in
  go 0 Plain 0 0

let compile ?(depth = default_depth) ?(memory = default_compile_memory) source =
  check_count "depth" depth;
  if depth > most_depth then
    invalid_arg "Sinter_ecma_pattern.Pattern: a depth of more than 200";
  check_count "memory" memory;
  let bytes = Text.encode source in
  match back_references ~depth bytes with
  | None -> Error Too_deep
  | Some back_references -> (
      match compile_stub bytes memory with
      | Ok (code, size) -> Ok { code; size; back_references }
      | Error _ as error -> error)

let fold_uchars f bytes first =
  let length = String.length bytes in
  let rec go index found =
    if index >= length then found
    else
      let decoded = String.get_utf_8_uchar bytes index in
      go
        (index + Uchar.utf_decode_length decoded)
        (f found (Uchar.to_int (Uchar.utf_decode_uchar decoded)))
  in
  go 0 first

let units_of code = if code < 0x10000 then 1 else 2

let utf_16 bytes count =
  let units = Bytes.create (2 * count) in
  let put place code =
    if code < 0x10000 then (
      Bytes.set_uint16_ne units place code;
      place + 2)
    else
      let offset = code - 0x10000 in
      Bytes.set_uint16_ne units place (0xD800 lor (offset lsr 10));
      Bytes.set_uint16_ne units (place + 2) (0xDC00 lor (offset land 0x3FF));
      place + 4
  in
  ignore (fold_uchars put bytes 0 : int);
  Bytes.unsafe_to_string units

let too_long count = count > 2_147_483_647
let size pattern = pattern.size

let test ?(steps = default_steps) ?(memory = default_test_memory) pattern
    subject =
  check_count "number of steps" steps;
  check_count "memory" memory;
  let bytes = Text.encode subject in
  let count = fold_uchars (fun count code -> count + units_of code) bytes 0 in
  if too_long count then Error Memory
  else
    let work = pattern.size + (pattern.back_references * count) in
    test_stub pattern.code (utf_16 bytes count) (steps / work) memory
