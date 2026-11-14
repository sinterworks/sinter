(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Object_id = Sinter_git_objects.Object_id
module Ref_name = Sinter_ref_names.Ref_name

type target = Object of Object_id.t | Symbolic of string | Broken

(* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
   A loose ref points to a git object only when its content is the object id
   in lower-case hex digits and one byte 0x0A, and names a ref only when it is
   "ref: ", a ref name, and one byte 0x0A; every other content is a broken
   loose ref. *)
let parse format content =
  let length = String.length content in
  if length = 0 || content.[length - 1] <> '\n' then Broken
  else
    let body = String.sub content 0 (length - 1) in
    match Object_id.of_hex format body with
    | Some id -> Object id
    | None -> (
        match String.starts_with ~prefix:"ref: " body with
        | false -> Broken
        | true ->
            let name = String.sub body 5 (String.length body - 5) in
            if Ref_name.is_ref_name name then Symbolic name else Broken)
