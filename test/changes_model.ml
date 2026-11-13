(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

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
