(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = Text.t
type error = Condition of int

let holds bytes sub =
  let n = String.length bytes and k = String.length sub in
  let rec from i =
    i + k <= n && (String.equal (String.sub bytes i k) sub || from (i + 1))
  in
  from 0

let forbidden c = Char.code c <= 31 || Char.code c = 127

let special c =
  match c with
  | ' ' | '~' | '^' | ':' | '?' | '*' | '[' | '\\' -> true
  | _ -> false

(* @satisfies changes#validate-branch-names=v1
   Each condition of the term is one test on the UTF-8 encoding of the text,
   in the order of the conditions; the text is a branch name when it fails
   none. Every character that a condition names is one byte below 0x80, so a
   byte test decides it. *)
let condition bytes =
  let parts = String.split_on_char '/' bytes in
  if
    String.equal bytes ""
    || String.starts_with ~prefix:"/" bytes
    || String.ends_with ~suffix:"/" bytes
    || holds bytes "//"
  then Some 1
  else if
    List.exists
      (fun part ->
        String.starts_with ~prefix:"." part
        || String.ends_with ~suffix:".lock" part)
      parts
  then Some 2
  else if holds bytes ".." || holds bytes "@{" then Some 3
  else if String.ends_with ~suffix:"." bytes then Some 4
  else if String.exists forbidden bytes then Some 5
  else if String.exists special bytes then Some 6
  else if String.equal bytes "HEAD" || String.starts_with ~prefix:"-" bytes then
    Some 7
  else if String.starts_with ~prefix:"refs/" bytes then Some 8
  else None

let of_text text =
  match condition (Text.encode text) with
  | Some k -> Error (Condition k)
  | None -> Ok text

let to_text name = name
