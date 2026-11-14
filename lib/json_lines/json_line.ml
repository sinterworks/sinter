(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = Json.t

let is_scalar (value : Json.t) =
  match value with
  | String _ | Integer _ | Boolean _ -> true
  | Array _ | Object _ -> false

let is_flat_object (value : Json.t) =
  match value with
  | Object members -> List.for_all (fun (_, value) -> is_scalar value) members
  | String _ | Integer _ | Boolean _ | Array _ -> false

(* @satisfies data-forms#write-canonical-line=v1
   A member value of a line object is a scalar, an array of scalars, or an
   array of flat objects; an object or any other array is not. *)
let is_member_value (value : Json.t) =
  match value with
  | String _ | Integer _ | Boolean _ -> true
  | Array elements ->
      List.for_all is_scalar elements || List.for_all is_flat_object elements
  | Object _ -> false

(* @satisfies data-forms#write-canonical-line=v1
   Only an object whose member values all fit a line object is a line object,
   so the writer gives no canonical line for any other JSON value. *)
let of_json (value : Json.t) =
  match value with
  | Object members ->
      if List.for_all (fun (_, value) -> is_member_value value) members then
        Some value
      else None
  | String _ | Integer _ | Boolean _ | Array _ -> None

(* @satisfies data-forms#write-canonical-line=v1
   The canonical line is the canonical byte sequence, then the byte 0x0A. *)
let canonical_line line_object = Json.canonical_byte_sequence line_object ^ "\n"

(* @satisfies data-forms#{read-canonical-line=v1, give-only-line-objects=v1}
   Gives a line object, and so the result valid, exactly when the bytes end in
   0x0A and the bytes before it are the canonical byte sequence of a line
   object, and then that line object; otherwise no line object. *)
let read bytes =
  let length = String.length bytes in
  if length = 0 || bytes.[length - 1] <> '\n' then None
  else Option.bind (Json.read (String.sub bytes 0 (length - 1))) of_json
