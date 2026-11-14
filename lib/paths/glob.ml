(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type pattern =
  | Literal of string
  | Stars of { first : string; middle : string list; last : string }

type form = Any_names | Name of pattern
type segment = { text : Text.t; form : form }
type t = { text : Text.t; segments : segment array }

type error =
  | Empty_part of int
  | Dot_part of int
  | Forbidden_character of int
  | Adjacent_stars of int

let is_forbidden = function
  | '?' | '[' | ']' | '{' | '}' | '\\' -> true
  | _ -> false

(* @satisfies files#{validate-globs=v1, decide-glob-fit=v1}
   A part is a glob segment when it is `**`, or when it is not empty, is not
   `.` or `..`, holds none of `?`, `[`, `]`, `{`, `}`, and the backslash, and
   holds no two `*` together; the texts between its `*` are the runs that a
   file name must hold in order. *)
let form_of number bytes =
  if bytes = "" then Error (Empty_part number)
  else if bytes = "." || bytes = ".." then Error (Dot_part number)
  else if String.exists is_forbidden bytes then
    Error (Forbidden_character number)
  else if bytes = "**" then Ok Any_names
  else
    let pieces = Array.of_list (String.split_on_char '*' bytes) in
    let count = Array.length pieces in
    if count = 1 then Ok (Name (Literal bytes))
    else
      let middle = Array.to_list (Array.sub pieces 1 (count - 2)) in
      if List.mem "" middle then Error (Adjacent_stars number)
      else
        Ok
          (Name
             (Stars { first = pieces.(0); middle; last = pieces.(count - 1) }))

let any_names = Text.of_uchars [ Uchar.of_char '*'; Uchar.of_char '*' ]

(* @satisfies files#{validate-globs=v1, decide-glob-fit=v1}
   An empty last part after a `/` is no fault, and it is the glob segment
   `**`. *)
let of_text text =
  let finish segments =
    Ok { text; segments = Array.of_list (List.rev segments) }
  in
  let rec read number segments = function
    | [] -> finish segments
    | [ (part : Parts.t) ] when part.bytes = "" && number > 1 ->
        finish ({ text = any_names; form = Any_names } :: segments)
    | (part : Parts.t) :: parts -> (
        match form_of number part.bytes with
        | Ok form ->
            read (number + 1) ({ text = part.text; form } :: segments) parts
        | Error error -> Error error)
  in
  read 1 [] (Parts.split text)

let to_text glob = glob.text

let segments glob =
  Array.to_list
    (Array.map (fun (segment : segment) -> segment.text) glob.segments)

let occurs_at piece name at =
  let length = String.length piece in
  let rec from i = i = length || (piece.[i] = name.[at + i] && from (i + 1)) in
  from 0

let rec find piece name ~from ~limit =
  if from + String.length piece > limit then None
  else if occurs_at piece name from then Some from
  else find piece name ~from:(from + 1) ~limit

(* @satisfies files#decide-glob-fit=v1
   A file name fits a glob segment without `*` only when it is the same text;
   with `*`, it starts with the text before the first `*`, ends with the text
   after the last `*`, and holds the texts between them in order, apart. *)
let name_fits pattern name =
  match pattern with
  | Literal literal -> String.equal literal name
  | Stars { first; middle; last } ->
      let limit = String.length name - String.length last in
      let rec inside from = function
        | [] -> true
        | piece :: pieces -> (
            match find piece name ~from ~limit with
            | Some at -> inside (at + String.length piece) pieces
            | None -> false)
      in
      String.length first <= limit
      && String.starts_with ~prefix:first name
      && String.ends_with ~suffix:last name
      && inside (String.length first) middle

(* @satisfies files#decide-glob-fit=v1
   The file names are divided into one group for each glob segment, in order:
   a last segment `**` takes one or more names, any other `**` takes zero or
   more, and each other glob segment takes one name that fits it. *)
let fits glob path =
  let names = Array.of_list (List.map Text.encode (Path.file_names path)) in
  let count = Array.length names in
  let last = Array.length glob.segments - 1 in
  let reached = Array.make (count + 1) false in
  reached.(0) <- true;
  Array.iteri
    (fun s (segment : segment) ->
      match segment.form with
      | Any_names ->
          let before = ref false in
          for j = 0 to count do
            let here = reached.(j) in
            reached.(j) <- !before || (s < last && here);
            before := !before || here
          done
      | Name pattern ->
          for j = count downto 1 do
            reached.(j) <- reached.(j - 1) && name_fits pattern names.(j - 1)
          done;
          reached.(0) <- false)
    glob.segments;
  reached.(count)
