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

let names_of_json = function
  | `List names ->
      List.map
        (function
          | `String name -> name
          | other ->
              Alcotest.failf "not a name: %s" (Yojson.Basic.to_string other))
        names
  | other -> Alcotest.failf "not an array: %s" (Yojson.Basic.to_string other)

type graph = (string * string list) list

let graph_of_json = function
  | `Assoc commits ->
      List.map (fun (name, parents) -> (name, names_of_json parents)) commits
  | other ->
      Alcotest.failf "not a commit graph: %s" (Yojson.Basic.to_string other)

let parents graph c = Option.value ~default:[] (List.assoc_opt c graph)

module Names = Set.Make (String)

let ancestry_set graph c =
  let rec grow seen = function
    | [] -> seen
    | c :: rest when Names.mem c seen -> grow seen rest
    | c :: rest -> grow (Names.add c seen) (parents graph c @ rest)
  in
  grow Names.empty [ c ]

let ancestry graph c = Names.elements (ancestry_set graph c)
let reaches graph c c' = Names.mem c' (ancestry_set graph c)

let range_set graph ~from h =
  let reached = ancestry_set graph h in
  match from with
  | None -> reached
  | Some s -> Names.diff reached (ancestry_set graph s)

let range graph ~from h = Names.elements (range_set graph ~from h)

let parents_first graph ~from h =
  let r = range_set graph ~from h in
  let started = Hashtbl.create 16 in
  let finished = ref [] in
  let rec walk c =
    Hashtbl.replace started c ();
    List.iter
      (fun p -> if Names.mem p r && not (Hashtbl.mem started p) then walk p)
      (parents graph c);
    finished := c :: !finished
  in
  if Names.mem h r then walk h;
  List.rev !finished

let merge_bases graph a b =
  let common = Names.inter (ancestry_set graph a) (ancestry_set graph b) in
  Names.elements
    (Names.filter
       (fun x ->
         not
           (Names.exists
              (fun y -> (not (String.equal x y)) && reaches graph y x)
              common))
       common)

let first_parent_line graph c =
  let rec go c acc =
    if List.mem c acc then None
    else
      match parents graph c with
      | [] -> Some (List.rev (c :: acc))
      | p :: _ -> go p (c :: acc)
  in
  go c []

let landing_commit graph ~line_of c =
  if not (reaches graph line_of c) then None
  else
    match
      List.filter
        (fun m ->
          reaches graph m c
          &&
          match parents graph m with
          | [] -> true
          | p :: _ -> not (reaches graph p c))
        (match first_parent_line graph line_of with
        | Some line -> line
        | None -> Alcotest.fail "the first parents come back to a commit")
    with
    | [ m ] -> Some m
    | ms -> Alcotest.failf "the term gives %d landing commits" (List.length ms)

let some_graph_gen ~cycles =
  let open Gen in
  int_range 1 12 >>= fun size ->
  let name k = "c" ^ string_of_int k in
  let commit k =
    if k = 0 && not cycles then return (name 0, [])
    else
      map
        (fun picks -> (name k, List.map name picks))
        (list_size
           (oneof_weighted
              [ (2, return 0); (5, return 1); (3, return 2); (1, return 3) ])
           (int_range 0 (if cycles then size - 1 else k - 1)))
  in
  flatten_list (List.init size commit)

let graph_gen = some_graph_gen ~cycles:false
let cyclic_graph_gen = some_graph_gen ~cycles:true

let print_graph graph =
  Yojson.Basic.to_string
    (`Assoc
       (List.map
          (fun (name, parents) ->
            (name, `List (List.map (fun p -> `String p) parents)))
          graph))

type target = Commit of string | Names of string | Other of string | Broken

let ref_commit refs name =
  let rec go seen name =
    if List.mem name seen then None
    else
      match List.assoc_opt name refs with
      | None | Some (Other _) | Some Broken -> None
      | Some (Commit c) -> Some c
      | Some (Names next) -> go (name :: seen) next
  in
  go [] name

let default_branch_commit ~binding ~upstream ~local ~remote =
  if not (is_branch_name binding) then None
  else
    match List.find_opt Option.is_some [ upstream; local; remote ] with
    | Some (Some commit) -> commit
    | _ -> None

let message content =
  let k = String.length content in
  let rec find i =
    if i + 1 >= k then ""
    else if content.[i] = '\n' && content.[i + 1] = '\n' then
      String.sub content (i + 2) (k - i - 2)
    else find (i + 1)
  in
  find 0

let message_text content =
  let message = message content in
  if String.is_valid_utf_8 message then Some message else None

type kind =
  | Tree_kind
  | Regular_file_kind
  | Symbolic_link_kind
  | Submodule_kind

let entry_kind mode =
  let k = String.length mode in
  let digit c = c >= '0' && c <= '7' in
  if k = 0 || not (String.for_all digit mode) then Submodule_kind
  else
    let quotient = if k > 4 then String.sub mode 0 (k - 4) else "" in
    let rec strip s =
      if String.length s > 0 && s.[0] = '0' then
        strip (String.sub s 1 (String.length s - 1))
      else s
    in
    match strip quotient with
    | "4" -> Tree_kind
    | "10" -> Regular_file_kind
    | "12" -> Symbolic_link_kind
    | _ -> Submodule_kind

type entry = { name : string; mode : string; entries : entry list }

let rec byte_paths prefix entries =
  List.concat_map
    (fun e ->
      let path = prefix ^ e.name in
      (path, entry_kind e.mode)
      ::
      (if entry_kind e.mode = Tree_kind then byte_paths (path ^ "/") e.entries
       else []))
    entries

let is_valid_path bytes =
  String.is_valid_utf_8 bytes
  && List.for_all
       (fun name ->
         name <> "" && name <> "." && name <> ".."
         && not (String.contains name '\000'))
       (String.split_on_char '/' bytes)

let entry_byte_paths entries = List.map fst (byte_paths "" entries)

let commit_files entries =
  let all = byte_paths "" entries in
  List.sort_uniq String.compare
    (List.filter_map
       (fun (path, t) ->
         if
           t = Regular_file_kind && is_valid_path path
           && List.length (List.filter (fun (p, _) -> String.equal p path) all)
              = 1
         then Some path
         else None)
       all)

let entries_gen =
  let open Gen in
  let name =
    oneof_list
      [ "a"; "b"; "a.md"; "."; ".."; "..."; ""; "a/b"; "x\xff"; "\xc3\xa9" ]
  in
  let leaf_mode =
    oneof_list
      [
        "100644";
        "100755";
        "100600";
        "120000";
        "160000";
        "170000";
        "0100644";
        "";
        "100684";
        "10064x";
        "1006\xff4";
      ]
  in
  let tree_mode = oneof_list [ "40000"; "040000" ] in
  fix
    (fun self depth ->
      list_size (int_range 0 4)
        (if depth = 0 then
           map2 (fun name mode -> { name; mode; entries = [] }) name leaf_mode
         else
           oneof_weighted
             [
               ( 3,
                 map2
                   (fun name mode -> { name; mode; entries = [] })
                   name leaf_mode );
               ( 1,
                 map3
                   (fun name mode entries -> { name; mode; entries })
                   name tree_mode
                   (self (depth - 1)) );
             ]))
    3

let rec print_entries entries =
  "["
  ^ String.concat ", "
      (List.map
         (fun e ->
           Printf.sprintf "%S %s%s" e.name e.mode
             (if e.entries = [] then "" else " " ^ print_entries e.entries))
         entries)
  ^ "]"
