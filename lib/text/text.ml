(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = { bytes : string; offsets : int array }
type run = { from : int; until : int }
type decode_error = Invalid_utf_8 of { place : int }

let offsets_of bytes count =
  let next = ref 0 in
  Array.init (count + 1) (fun k ->
      let offset = !next in
      if k < count then
        next :=
          offset + Uchar.utf_decode_length (String.get_utf_8_uchar bytes offset);
      offset)

(* @satisfies text#{validate-utf-8=v1, give-texts-of-byte-sequences=v1, omit-texts-of-invalid-byte-sequences=v1} *)
let decode bytes =
  let n = String.length bytes in
  let rec scan i count =
    if i >= n then Ok { bytes; offsets = offsets_of bytes count }
    else
      let d = String.get_utf_8_uchar bytes i in
      if Uchar.utf_decode_is_valid d then
        scan (i + Uchar.utf_decode_length d) (count + 1)
      else Error (Invalid_utf_8 { place = i + 1 })
  in
  scan 0 0

let encode text = text.bytes

(* @satisfies text#give-utf-8-encodings=v1 *)
let of_uchars characters =
  let count = List.length characters in
  let buffer = Buffer.create count in
  List.iter (Buffer.add_utf_8_uchar buffer) characters;
  let bytes = Buffer.contents buffer in
  { bytes; offsets = offsets_of bytes count }

let empty = of_uchars []
let length text = Array.length text.offsets - 1

let get text place =
  if place < 1 || place > length text then None
  else
    Some
      (Uchar.utf_decode_uchar
         (String.get_utf_8_uchar text.bytes text.offsets.(place - 1)))

let sub text run =
  if run.from < 0 || run.until < run.from || run.until > length text then None
  else
    let first = text.offsets.(run.from) in
    let bytes =
      String.sub text.bytes first (text.offsets.(run.until) - first)
    in
    Some
      {
        bytes;
        offsets =
          Array.init
            (run.until - run.from + 1)
            (fun k -> text.offsets.(run.from + k) - first);
      }

let equal a b = String.equal a.bytes b.bytes

let has_byte_order_mark text =
  String.starts_with ~prefix:"\xef\xbb\xbf" text.bytes

let body text =
  { from = (if has_byte_order_mark text then 1 else 0); until = length text }
