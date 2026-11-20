(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = {
  memory_size : int;
  memory_alignment : int;
  table_size : int;
  table_alignment : int;
}

type error =
  | Not_a_module
  | No_section
  | Several_sections
  | Malformed_section
  | Other_subsection of int
  | No_memory_subsection
  | Several_memory_subsections
  | Malformed_memory_subsection

let u32 bytes ~at ~until =
  let rec go index count number =
    if index >= until || count = 5 then None
    else
      let byte = Char.code bytes.[index] in
      let number = number lor ((byte land 0x7f) lsl (7 * count)) in
      if byte < 0x80 then
        if count = 4 && byte > 0x0f then None else Some (number, index + 1)
      else go (index + 1) (count + 1) number
  in
  go at 0 0

let header = "\000asm\001\000\000\000"

let sections bytes =
  let length = String.length bytes in
  let rec go at found =
    if at = length then Some (List.rev found)
    else
      match u32 bytes ~at:(at + 1) ~until:length with
      | Some (size, start) when size <= length - start -> (
          let until = start + size in
          if bytes.[at] <> '\000' then go until found
          else
            match u32 bytes ~at:start ~until with
            | Some (name_length, name_start)
              when name_length <= until - name_start ->
                let name = String.sub bytes name_start name_length in
                let content = name_start + name_length in
                go until
                  (if name = "dylink.0" then (content, until) :: found
                   else found)
            | _ -> None)
      | _ -> None
  in
  if length >= 8 && String.sub bytes 0 8 = header then go 8 [] else None

let subsections bytes (at, until) =
  let rec go at found =
    if at = until then Some (List.rev found)
    else
      match u32 bytes ~at:(at + 1) ~until with
      | Some (size, start) ->
          go (start + size)
            ((Char.code bytes.[at], (start, start + size)) :: found)
      | _ -> None
  in
  go at []

let memory_information bytes (at, until) =
  let rec go at count found =
    if count = 4 then if at = until then Some (List.rev found) else None
    else
      match u32 bytes ~at ~until with
      | Some (number, next) -> go next (count + 1) (number :: found)
      | None -> None
  in
  match go at 0 [] with
  | Some [ memory_size; memory_alignment; table_size; table_alignment ] ->
      Ok { memory_size; memory_alignment; table_size; table_alignment }
  | _ -> Error Malformed_memory_subsection

let read bytes =
  match sections bytes with
  | None -> Error Not_a_module
  | Some [] -> Error No_section
  | Some (_ :: _ :: _) -> Error Several_sections
  | Some [ section ] -> (
      match subsections bytes section with
      | None -> Error Malformed_section
      | Some found -> (
          match List.find_opt (fun (kind, _) -> kind <> 1) found with
          | Some (kind, _) -> Error (Other_subsection kind)
          | None -> (
              match found with
              | [] -> Error No_memory_subsection
              | [ (_, subsection) ] -> memory_information bytes subsection
              | _ -> Error Several_memory_subsections)))
