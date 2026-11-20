(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = { text : Sinter_text.Text.t; names : Sinter_text.Text.t list }
type error = Empty_part of int | Dot_part of int | Null_character of int

(* @satisfies files#validate-paths=v1
   A part is a file name when it is not empty, is not `.` or `..`, and holds
   no U+0000; a text is a valid path when no part has a fault. *)
let fault number (part : Parts.t) =
  match part.bytes with
  | "" -> Some (Empty_part number)
  | "." | ".." -> Some (Dot_part number)
  | bytes when String.contains bytes '\000' -> Some (Null_character number)
  | _ -> None

let of_text text =
  let parts = Parts.split text in
  match List.find_mapi (fun i part -> fault (i + 1) part) parts with
  | Some error -> Error error
  | None ->
      Ok { text; names = List.map (fun (part : Parts.t) -> part.text) parts }

let to_text path = path.text
let file_names path = path.names
