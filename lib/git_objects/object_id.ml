(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type format = Sha1 | Sha256

let length = function Sha1 -> 20 | Sha256 -> 32

type t = string

let of_bytes format bytes =
  if String.length bytes = length format then Some bytes else None

let digit = function
  | '0' .. '9' as c -> Some (Char.code c - Char.code '0')
  | 'a' .. 'f' as c -> Some (Char.code c - Char.code 'a' + 10)
  | _ -> None

let of_hex format hex =
  let count = length format in
  if String.length hex <> 2 * count then None
  else
    let bytes = Bytes.create count in
    let rec fill k =
      if k = count then Some (Bytes.to_string bytes)
      else
        match (digit hex.[2 * k], digit hex.[(2 * k) + 1]) with
        | Some high, Some low ->
            Bytes.set bytes k (Char.chr ((high * 16) + low));
            fill (k + 1)
        | _ -> None
    in
    fill 0

let format id = if String.length id = 20 then Sha1 else Sha256
let to_bytes id = id
let hex_digits = "0123456789abcdef"

let to_hex id =
  String.init
    (2 * String.length id)
    (fun k ->
      let byte = Char.code id.[k / 2] in
      hex_digits.[if k mod 2 = 0 then byte lsr 4 else byte land 15])

let equal = String.equal
let compare = String.compare
let hash = Hashtbl.hash
