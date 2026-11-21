(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type error = Malformed_line of int

(* @satisfies changes#give-commit-parents=v1
   The commits that the file shallow names, and so the commits that have no
   parents, are those of its lines, each the object id in hex digits. *)
let parse format content =
  let width = 2 * Object_id.length format in
  let total = String.length content in
  let rec lines offset line ids =
    if offset = total then Ok (List.rev ids)
    else if offset + width < total && content.[offset + width] = '\n' then
      match Object_id.of_hex format (String.sub content offset width) with
      | Some id -> lines (offset + width + 1) (line + 1) (id :: ids)
      | None -> Error (Malformed_line line)
    else Error (Malformed_line line)
  in
  lines 0 1 []
