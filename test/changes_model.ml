(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen

let starts_with ~prefix s = String.starts_with ~prefix s
let ends_with ~suffix s = String.ends_with ~suffix s

let holds ~sub s =
  let k = String.length sub in
  let rec at i =
    i + k <= String.length s && (String.sub s i k = sub || at (i + 1))
  in
  at 0

let branch_name_faults b =
  let parts = String.split_on_char '/' b in
  let code_points =
    let rec go index acc =
      if index >= String.length b then List.rev acc
      else
        let decode = String.get_utf_8_uchar b index in
        go
          (index + Uchar.utf_decode_length decode)
          (Uchar.to_int (Uchar.utf_decode_uchar decode) :: acc)
    in
    go 0 []
  in
  let forbidden =
    List.map Char.code [ ' '; '~'; '^'; ':'; '?'; '*'; '['; '\\' ]
  in
  let conditions =
    [
      b <> ""
      && (not (starts_with ~prefix:"/" b))
      && (not (ends_with ~suffix:"/" b))
      && not (holds ~sub:"//" b);
      List.for_all
        (fun part ->
          (not (starts_with ~prefix:"." part))
          && not (ends_with ~suffix:".lock" part))
        parts;
      (not (holds ~sub:".." b)) && not (holds ~sub:"@{" b);
      not (ends_with ~suffix:"." b);
      List.for_all (fun cp -> cp > 31 && cp <> 127) code_points;
      List.for_all (fun cp -> not (List.mem cp forbidden)) code_points;
      b <> "HEAD" && not (starts_with ~prefix:"-" b);
      not (starts_with ~prefix:"refs/" b);
    ]
  in
  List.filter_map Fun.id
    (List.mapi (fun k met -> if met then None else Some (k + 1)) conditions)

let is_branch_name b = branch_name_faults b = []

let branch_name_gen =
  let open Gen in
  map (String.concat "")
    (list_size (int_range 0 8)
       (oneof_list
          [
            "a";
            "b";
            "/";
            ".";
            "..";
            ".lock";
            "lock";
            "@";
            "{";
            "@{";
            "-";
            "HEAD";
            "refs";
            "refs/";
            " ";
            "\t";
            "\x7f";
            "\x01";
            "~";
            "^";
            ":";
            "?";
            "*";
            "[";
            "]";
            "\\";
            "\xc2\xa0";
            "\xc3\xa9";
            "\xe2\x80\xa8";
          ]))

let bytes_of_json = function
  | `String text -> text
  | `Assoc [ ("bytes", `String digits) ] -> Vector_json.of_hex digits
  | other ->
      Alcotest.failf "not a byte sequence: %s" (Yojson.Basic.to_string other)

let line_texts = function
  | None -> None
  | Some content -> (
      match Text.decode content with
      | Error _ -> None
      | Ok text ->
          let lines = Lines.of_text text in
          Some
            (List.map
               (fun run ->
                 match Text.sub text run with
                 | Some line -> Text.encode line
                 | None -> Alcotest.fail "a line is not a run of its text")
               (Lines.all lines)))

let is_map old_lines new_lines pairs =
  let old_lines = Array.of_list old_lines in
  let new_lines = Array.of_list new_lines in
  let m = Array.length old_lines and n = Array.length new_lines in
  let rec ordered = function
    | (i, j) :: ((i', j') :: _ as rest) -> i < i' && j < j' && ordered rest
    | _ -> true
  in
  List.for_all
    (fun (i, j) ->
      i >= 1 && i <= m && j >= 1 && j <= n
      && String.equal old_lines.(i - 1) new_lines.(j - 1))
    pairs
  && ordered (List.sort compare pairs)

let longest_by_search old_lines new_lines =
  let old_lines = Array.of_list old_lines in
  let new_lines = Array.of_list new_lines in
  let m = Array.length old_lines and n = Array.length new_lines in
  let rec best i0 j0 =
    let result = ref 0 in
    for i = i0 + 1 to m do
      for j = j0 + 1 to n do
        if String.equal old_lines.(i - 1) new_lines.(j - 1) then
          result := max !result (1 + best i j)
      done
    done;
    !result
  in
  best 0 0

let longest_by_table old_lines new_lines =
  let old_lines = Array.of_list old_lines in
  let new_lines = Array.of_list new_lines in
  let m = Array.length old_lines and n = Array.length new_lines in
  let table = Array.make_matrix (m + 1) (n + 1) 0 in
  for i = 1 to m do
    for j = 1 to n do
      table.(i).(j) <-
        (if String.equal old_lines.(i - 1) new_lines.(j - 1) then
           table.(i - 1).(j - 1) + 1
         else max table.(i - 1).(j) table.(i).(j - 1))
    done
  done;
  table.(m).(n)

type hunk = { old_start : int; removed : int; new_start : int; added : int }

let count = function None -> 0 | Some lines -> List.length lines

let hunks ~old_content ~new_content pairs =
  let m = count (line_texts old_content) in
  let n = count (line_texts new_content) in
  let points = ((0, 0) :: List.sort compare pairs) @ [ (m + 1, n + 1) ] in
  let rec gaps = function
    | (i, j) :: ((i', j') :: _ as rest) ->
        if i' > i + 1 || j' > j + 1 then
          {
            old_start = i + 1;
            removed = i' - i - 1;
            new_start = j + 1;
            added = j' - j - 1;
          }
          :: gaps rest
        else gaps rest
    | _ -> []
  in
  match gaps points with
  | _ :: _ as found -> found
  | [] -> (
      let not_utf_8 content = Result.is_error (Text.decode content) in
      let empty =
        [ { old_start = 1; removed = 0; new_start = 1; added = 0 } ]
      in
      match (old_content, new_content) with
      | Some _, None | None, Some _ -> empty
      | Some a, Some b
        when (not (String.equal a b)) && (not_utf_8 a || not_utf_8 b) ->
          empty
      | _ -> [])

let content_gen =
  let open Gen in
  let line = oneof_list [ "a"; "b"; "c"; ""; "a\r"; "\xc3\xa9" ] in
  let ending = oneof_weighted [ (6, return "\n"); (2, return "\r\n") ] in
  let body =
    list_size (int_range 0 6) (pair line ending) >>= fun lines ->
    bool >>= fun last ->
    let text = String.concat "" (List.map (fun (l, e) -> l ^ e) lines) in
    if last then map (fun l -> text ^ l) line else return text
  in
  oneof_weighted
    [
      (1, return None);
      (12, map Option.some body);
      (1, map (fun b -> Some ("\xef\xbb\xbf" ^ b)) body);
      (1, map (fun b -> Some (b ^ "\xff")) body);
    ]

let print_content = function
  | None -> "no file"
  | Some content -> Printf.sprintf "%S" content

let a_line_map old_lines new_lines =
  let old_a = Array.of_list old_lines and new_a = Array.of_list new_lines in
  let m = Array.length old_a and n = Array.length new_a in
  let table = Array.make_matrix (m + 2) (n + 2) 0 in
  for i = m downto 1 do
    for j = n downto 1 do
      table.(i).(j) <-
        (if String.equal old_a.(i - 1) new_a.(j - 1) then
           table.(i + 1).(j + 1) + 1
         else max table.(i + 1).(j) table.(i).(j + 1))
    done
  done;
  let rec walk i j acc =
    if i > m || j > n then List.rev acc
    else if String.equal old_a.(i - 1) new_a.(j - 1) then
      walk (i + 1) (j + 1) ((i, j) :: acc)
    else if table.(i + 1).(j) >= table.(i).(j + 1) then walk (i + 1) j acc
    else walk i (j + 1) acc
  in
  walk 1 1 []
