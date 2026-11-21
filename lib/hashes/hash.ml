(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = string

let hex_digits = "0123456789abcdef"

(* @satisfies data-forms#compute-hash=v1
   The hex text of the digest is two lower-case hex digits for each byte: the
   quotient of the byte by 16, then the remainder. *)
let hex_text bytes =
  String.init
    (2 * String.length bytes)
    (fun i ->
      let byte = Char.code bytes.[i / 2] in
      hex_digits.[if i mod 2 = 0 then byte / 16 else byte mod 16])

(* @satisfies data-forms#compute-hash=v1
   The hash is the hex text of the SHA-256 digest of the bytes: two lower-case
   hex digits for each of its 32 bytes. *)
let compute bytes =
  hex_text Digestif.SHA256.(to_raw_string (digest_string bytes))

(* @satisfies data-forms#validate-hash=v1
   The hex digits are the characters `0` to `9` and `a` to `f`, and no
   others. *)
let is_hex_digit c = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')

(* @satisfies data-forms#validate-hash=v1
   Valid exactly when the text is 64 characters, each one of `0` to `9` and
   `a` to `f`. *)
let validate text =
  if String.length text = 64 && String.for_all is_hex_digit text then Some text
  else None
