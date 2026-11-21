(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module J = Vector_json

type entry = {
  name : string;
  mode : string;
  entries : entry list;
  content : string option;
}

let assoc name fields = List.assoc_opt name fields

let text_of = function
  | `String s -> s
  | j -> Alcotest.failf "not a text: %s" (Yojson.Basic.to_string j)

let canonical_line obj =
  match J.canonical_line obj with
  | Some line -> line
  | None -> invalid_arg "canonical_line: not a line object"

let lines_of_json = function
  | `List objects ->
      List.map
        (fun o ->
          match J.canonical_line (J.of_basic o) with
          | Some line -> line
          | None ->
              Alcotest.failf "not a line object: %s" (Yojson.Basic.to_string o))
        objects
  | other ->
      Alcotest.failf "not a list of lines: %s" (Yojson.Basic.to_string other)

let rec tree_of_json = function
  | `List items -> List.map entry_of_json items
  | other ->
      Alcotest.failf "not a git tree object: %s" (Yojson.Basic.to_string other)

and entry_of_json = function
  | `Assoc fields as json ->
      List.iter
        (fun (key, _) ->
          if
            not (List.mem key [ "name"; "mode"; "entries"; "content"; "lines" ])
          then Alcotest.failf "an unknown member %s" key)
        fields;
      let name =
        match assoc "name" fields with
        | Some j -> Changes_model.bytes_of_json j
        | None -> Alcotest.failf "no name: %s" (Yojson.Basic.to_string json)
      in
      let mode =
        match assoc "mode" fields with
        | Some j -> text_of j
        | None -> Alcotest.failf "no mode: %s" (Yojson.Basic.to_string json)
      in
      let entries =
        match assoc "entries" fields with
        | Some j -> tree_of_json j
        | None -> []
      in
      let content =
        match (assoc "content" fields, assoc "lines" fields) with
        | Some j, None -> Some (Changes_model.bytes_of_json j)
        | None, Some j -> Some (String.concat "" (lines_of_json j))
        | None, None -> None
        | Some _, Some _ ->
            Alcotest.failf "both content and lines: %s"
              (Yojson.Basic.to_string json)
      in
      { name; mode; entries; content }
  | other -> Alcotest.failf "not an entry: %s" (Yojson.Basic.to_string other)

let member key = function
  | J.Object members ->
      List.find_map
        (function J.Text k, v when String.equal k key -> Some v | _ -> None)
        members
  | _ -> None

let integer_member key value =
  match member key value with Some (J.Number s) -> J.integer s | _ -> None

let string_member key value =
  match member key value with Some (J.String (J.Text s)) -> Some s | _ -> None

let without key = function
  | J.Object members ->
      J.Object
        (List.filter
           (function J.Text k, _ -> not (String.equal k key) | _ -> true)
           members)
  | other -> other

let set_member key value obj =
  match without key obj with
  | J.Object members -> J.Object (members @ [ (J.Text key, value) ])
  | other -> other

let id_digits = 32
let zero_id = "e-" ^ String.make id_digits '0'

let entry_id obj =
  match J.canonical (without "id" obj) with
  | Some bytes ->
      "e-"
      ^ String.sub Digestif.SHA256.(to_hex (digest_string bytes)) 0 id_digits
  | None -> invalid_arg "entry_id: not a JSON value"

let with_id obj = set_member "id" (J.String (J.Text (entry_id obj))) obj
let is_hex c = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')

let is_id text =
  String.length text = id_digits + 2
  && String.sub text 0 2 = "e-"
  && String.for_all is_hex (String.sub text 2 id_digits)

let is_chunk_path t =
  String.length t = id_digits + 19
  && String.sub t 0 8 = "entries/"
  && String.for_all is_hex (String.sub t 8 2)
  && t.[10] = '/'
  && is_id (String.sub t 11 (id_digits + 2))
  && String.sub t (id_digits + 13) 6 = ".jsonl"
  && String.sub t 8 2 = String.sub t 13 2

let chunk_mode_is_valid mode =
  mode <> ""
  && String.for_all (fun c -> c >= '0' && c <= '7') mode
  &&
  let rec strip i =
    if i < String.length mode && mode.[i] = '0' then strip (i + 1) else i
  in
  let i = strip 0 in
  String.sub mode i (String.length mode - i) = "100644"

let kind_of entry = Changes_model.entry_kind entry.mode

let all_entries tree =
  let rec walk prefix acc = function
    | [] -> acc
    | e :: rest ->
        let path = if prefix = "" then e.name else prefix ^ "/" ^ e.name in
        let acc = (path, e) :: acc in
        let acc =
          if kind_of e = Changes_model.Tree_kind then walk path acc e.entries
          else acc
        in
        walk prefix acc rest
  in
  List.rev (walk "" [] tree)

let chunks tree =
  List.filter
    (fun (path, e) ->
      kind_of e = Changes_model.Regular_file_kind && is_chunk_path path)
    (all_entries tree)

let lines_of_content content =
  let n = String.length content in
  let rec cut start i acc =
    if i = n then
      List.rev
        (if start < n then String.sub content start (n - start) :: acc else acc)
    else if content.[i] = '\n' then
      cut (i + 1) (i + 1) (String.sub content start (i + 1 - start) :: acc)
    else cut start (i + 1) acc
  in
  cut 0 0 []

let chunk_content (path, e) =
  match e.content with
  | Some c -> c
  | None -> Alcotest.failf "the chunk %s has no content in the input" path

let lines tree =
  List.concat_map (fun c -> lines_of_content (chunk_content c)) (chunks tree)

let object_of_line line =
  match J.json_value_of_bytes line with
  | Some v when J.is_line_object v && J.canonical_line v = Some line -> Some v
  | _ -> None

let is_newer_line line =
  match J.json_value_of_bytes line with
  | Some v -> (
      match integer_member "v" v with Some n -> n > 1 | None -> false)
  | None -> false

let is_newer tree = List.exists is_newer_line (lines tree)

let faults tree =
  let all = all_entries tree in
  let paths = List.map fst all in
  let chunk_list = chunks tree in
  let chunk_paths = List.map fst chunk_list in
  let ls = lines tree in
  let objects = List.map object_of_line ls in
  let dup_path =
    List.length (List.sort_uniq String.compare paths) <> List.length paths
  in
  let has_slash = List.exists (fun (_, e) -> String.contains e.name '/') all in
  let is_tree path =
    List.exists
      (fun (p, e) -> String.equal p path && kind_of e = Changes_model.Tree_kind)
      all
  in
  let allowed (path, e) =
    List.mem path chunk_paths
    && kind_of e = Changes_model.Regular_file_kind
    && chunk_mode_is_valid e.mode
    || kind_of e = Changes_model.Tree_kind
       && ((path = "entries" && chunk_paths <> [])
          || List.exists (fun c -> String.sub c 0 10 = path) chunk_paths)
  in
  let c1 =
    dup_path || has_slash
    || (not (List.for_all allowed all))
    || (chunk_paths <> [] && not (is_tree "entries"))
    || List.exists (fun c -> not (is_tree (String.sub c 0 10))) chunk_paths
  in
  let c2 =
    List.exists (fun c -> lines_of_content (chunk_content c) = []) chunk_list
    || List.exists Option.is_none objects
  in
  let good3 o =
    Option.is_some (string_member "id" o)
    && Option.is_some (string_member "kind" o)
    && integer_member "v" o = Some 1
    && match integer_member "seq" o with Some s -> s >= 1 | None -> false
  in
  let c3 =
    List.exists (function Some o -> not (good3 o) | None -> true) objects
  in
  let c4 =
    List.exists
      (function
        | Some o -> string_member "id" o <> Some (entry_id o) | None -> true)
      objects
  in
  let c5 =
    List.exists
      (fun ((path, _) as c) ->
        match lines_of_content (chunk_content c) with
        | first :: _ -> (
            match Option.bind (object_of_line first) (string_member "id") with
            | Some id ->
                String.sub path 11 (String.length path - 11) <> id ^ ".jsonl"
            | None -> true)
        | [] -> false)
      chunk_list
  in
  let ids = List.map (fun o -> Option.bind o (string_member "id")) objects in
  let c6 =
    let some = List.filter_map Fun.id ids in
    List.length (List.sort_uniq String.compare some) <> List.length some
  in
  let c7 =
    let seqs =
      List.map (fun o -> Option.bind o (integer_member "seq")) objects
    in
    List.sort compare seqs <> List.init (List.length ls) (fun i -> Some (i + 1))
  in
  List.filter_map
    (fun (n, fault) -> if fault then Some n else None)
    [ (1, c1); (2, c2); (3, c3); (4, c4); (5, c5); (6, c6); (7, c7) ]

let is_valid_ledger_tree tree = (not (is_newer tree)) && faults tree = []

type ledger_ref = No_ref | Not_a_commit | Commit_tree of entry list
type validity = Valid | Broken | Newer

let validity = function
  | No_ref -> Valid
  | Not_a_commit -> Broken
  | Commit_tree tree ->
      if is_newer tree then Newer
      else if faults tree = [] then Valid
      else Broken

let validity_text = function
  | Valid -> "valid"
  | Broken -> "broken"
  | Newer -> "newer"

let kinds =
  [
    "task";
    "plan";
    "approval";
    "decline";
    "done";
    "abandoned";
    "delivered";
    "void";
  ]

let seq_of line =
  Option.bind (J.json_value_of_bytes line) (integer_member "seq")

let by_seq ls =
  List.stable_sort
    (fun a b ->
      match (seq_of a, seq_of b) with
      | Some x, Some y -> compare x y
      | Some _, None -> -1
      | None, Some _ -> 1
      | None, None -> 0)
    ls

let id_of line =
  match Option.bind (J.json_value_of_bytes line) (string_member "id") with
  | Some id -> id
  | None -> invalid_arg "id_of: no string id"

let stored_ledger ledger_ref =
  match (validity ledger_ref, ledger_ref) with
  | Valid, Commit_tree tree ->
      Some
        (List.map id_of
           (by_seq
              (List.filter
                 (fun line ->
                   match
                     Option.bind (object_of_line line) (string_member "kind")
                   with
                   | Some k -> List.mem k kinds
                   | None -> false)
                 (lines tree))))
  | Valid, _ -> Some []
  | _ -> None

type commit = { parents : string list; tree : entry list }

let graph_of_json = function
  | `Assoc commits ->
      List.map
        (fun (name, json) ->
          match json with
          | `Assoc fields ->
              let parents =
                match assoc "parents" fields with
                | Some j -> Changes_model.names_of_json j
                | None -> Alcotest.failf "the commit %s has no parents" name
              in
              let tree =
                match assoc "entries" fields with
                | Some j -> tree_of_json j
                | None -> Alcotest.failf "the commit %s has no entries" name
              in
              (name, { parents; tree })
          | other ->
              Alcotest.failf "not a commit: %s" (Yojson.Basic.to_string other))
        commits
  | other -> Alcotest.failf "not commits: %s" (Yojson.Basic.to_string other)

let find commits name =
  match List.assoc_opt name commits with
  | Some c -> c
  | None -> Alcotest.failf "the input has no commit %s" name

let holds_lines ~child ~parent =
  let child_lines = lines child.tree in
  List.for_all (fun l -> List.mem l child_lines) (lines parent.tree)

let extends commits d c =
  let rec go seen d =
    String.equal d c
    ||
    match (find commits d).parents with
    | [ p ] when not (List.mem p seen) ->
        holds_lines ~child:(find commits d) ~parent:(find commits p)
        && go (d :: seen) p
    | _ -> false
  in
  go [] d

let ancestry commits c =
  let rec go seen = function
    | [] -> seen
    | x :: rest ->
        if List.mem x seen then go seen rest
        else go (x :: seen) ((find commits x).parents @ rest)
  in
  go [] [ c ]

let intact commits c =
  let rec chain seen x =
    match (find commits x).parents with
    | [] -> true
    | [ p ] when not (List.mem p seen) ->
        holds_lines ~child:(find commits x) ~parent:(find commits p)
        && chain (x :: seen) p
    | _ -> false
  in
  chain [] c
  && List.for_all
       (fun x -> is_valid_ledger_tree (find commits x).tree)
       (ancestry commits c)

let equal_value a b =
  match (J.canonical a, J.canonical b) with
  | Some x, Some y -> String.equal x y
  | _ -> false

let accounts ls line =
  List.mem line ls
  ||
  match Option.bind (J.json_value_of_bytes line) (member "id") with
  | Some id ->
      List.exists
        (fun l ->
          match object_of_line l with
          | Some o -> (
              string_member "kind" o = Some "void"
              &&
              match member "dropped" o with
              | Some d -> equal_value d id
              | None -> false)
          | None -> false)
        ls
  | None -> false

type pull = Refused | Pulled of { lines : string list; left : string list }

let pull ~clone ~shared ~accept =
  let s_lines = lines shared in
  let s_sorted = by_seq s_lines in
  match clone with
  | None -> Pulled { lines = s_sorted; left = [] }
  | Some a_tree ->
      let unaccounted =
        List.filter (fun l -> not (accounts s_lines l)) (lines a_tree)
      in
      if unaccounted = [] then Pulled { lines = s_sorted; left = [] }
      else
        let allowed =
          is_valid_ledger_tree a_tree
          && is_valid_ledger_tree shared
          && List.for_all
               (fun l ->
                 match
                   Option.bind (object_of_line l) (string_member "kind")
                 with
                 | Some k -> List.mem k kinds
                 | None -> false)
               unaccounted
        in
        if not allowed then Refused
        else
          let n = List.length s_lines in
          let stayed, left =
            List.fold_left
              (fun (stayed, left) li ->
                match object_of_line li with
                | None -> (stayed, left @ [ id_of li ])
                | Some o ->
                    let p = n + List.length stayed + 1 in
                    let moved =
                      with_id
                        (set_member "seq"
                           (J.Number (string_of_int p))
                           (without "id" (without "seq" o)))
                    in
                    let line = canonical_line moved in
                    let kind = string_member "kind" moved in
                    if
                      kind <> Some "void"
                      && Option.fold ~none:false
                           ~some:(fun k -> List.mem k kinds)
                           kind
                      && accept ~original:li ~before:(s_sorted @ stayed) line
                    then (stayed @ [ line ], left)
                    else (stayed, left @ [ id_of li ]))
              ([], []) (by_seq unaccounted)
          in
          if stayed = [] then Pulled { lines = s_sorted; left }
          else Pulled { lines = s_sorted @ stayed; left }

let tree_of_chunks chunks =
  let folders = ref [] in
  List.iter
    (fun (mode, ls) ->
      match ls with
      | [] -> invalid_arg "tree_of_chunks: a chunk with no line"
      | first :: _ ->
          let id =
            match
              Option.bind (J.json_value_of_bytes first) (string_member "id")
            with
            | Some id when is_id id -> id
            | _ -> invalid_arg "tree_of_chunks: no id"
          in
          let hh = String.sub id 2 2 in
          let file =
            {
              name = id ^ ".jsonl";
              mode;
              entries = [];
              content = Some (String.concat "" ls);
            }
          in
          folders :=
            if List.mem_assoc hh !folders then
              List.map
                (fun (h, files) ->
                  if h = hh then (h, files @ [ file ]) else (h, files))
                !folders
            else !folders @ [ (hh, [ file ]) ])
    chunks;
  match !folders with
  | [] -> []
  | folders ->
      [
        {
          name = "entries";
          mode = "40000";
          content = None;
          entries =
            List.map
              (fun (hh, files) ->
                { name = hh; mode = "40000"; entries = files; content = None })
              folders;
        };
      ]

let tree_of_lines = function
  | [] -> []
  | ls -> tree_of_chunks [ ("100644", ls) ]

let str s = J.String (J.Text s)
let num n = J.Number (string_of_int n)

let line_object_gen ~seq =
  let open Gen in
  let* kind = oneof_list (kinds @ [ "pin" ]) in
  let* by =
    oneof_list
      [ "Ada Lovelace <ada@example.com>"; "ci"; ""; "\xc3\xa9\xe2\x80\xa8" ]
  in
  let* extra =
    list_size (int_range 0 3)
      (oneof
         [
           map (fun s -> ("name", str s)) (oneof_list [ "t1"; "t2"; "a b" ]);
           map
             (fun s -> ("subject", str s))
             (oneof_list [ "billing#limit"; "x" ]);
           map (fun n -> ("x-count", num n)) (int_range (-5) 5);
           map (fun b -> ("x-flag", J.Bool b)) bool;
           return ("agent", str "an agent");
           return ("ts", str "2026-10-31T14:05:09Z");
           return ("ts", str "not a time");
           return ("branch", str "main");
           return ("refs", J.Array [ str "gh/1"; num 2 ]);
           return ("parts", J.Array [ J.Object [ (J.Text "a", num 1) ] ]);
         ])
  in
  let* void_fields =
    if kind = "void" then
      map
        (fun d -> [ ("dropped", str d); ("reason", str "a secret") ])
        (oneof_list [ "e-5b1c0a9d2e114f0c8a6b3d9e7f21a05c"; zero_id ])
    else return []
  in
  let members =
    [ ("kind", str kind); ("v", num 1); ("seq", num seq); ("by", str by) ]
    @ void_fields @ extra
  in
  let members =
    List.fold_left
      (fun acc (k, v) -> if List.mem_assoc k acc then acc else acc @ [ (k, v) ])
      [] members
  in
  return (with_id (J.Object (List.map (fun (k, v) -> (J.Text k, v)) members)))

let ledger_lines_gen =
  let open Gen in
  let* n = int_range 0 12 in
  let rec build seq acc =
    if seq > n then return (List.rev acc)
    else
      let* o = line_object_gen ~seq in
      build (seq + 1) (canonical_line o :: acc)
  in
  let* ls = build 1 [] in
  shuffle_list ls

let rec shuffle_tree tree =
  let open Gen in
  let* entries =
    flatten_list
      (List.map
         (fun e ->
           if e.entries = [] then return e
           else map (fun es -> { e with entries = es }) (shuffle_tree e.entries))
         tree)
  in
  shuffle_list entries

let layout_gen ls =
  let open Gen in
  if ls = [] then return []
  else
    let* ls = shuffle_list ls in
    let* cuts =
      list_size
        (return (List.length ls - 1))
        (oneof_weighted [ (2, return true); (1, return false) ])
    in
    let rec split acc current ls cuts =
      match (ls, cuts) with
      | [ l ], _ -> List.rev (List.rev (l :: current) :: acc)
      | l :: rest, cut :: cuts ->
          if cut then split (List.rev (l :: current) :: acc) [] rest cuts
          else split acc (l :: current) rest cuts
      | _ -> List.rev acc
    in
    let groups = split [] [] ls cuts in
    let* modes =
      list_size
        (return (List.length groups))
        (oneof_weighted
           [
             (8, return "100644"); (1, return "0100644"); (1, return "000100644");
           ])
    in
    shuffle_tree (tree_of_chunks (List.combine modes groups))

let rec positions prefix tree =
  List.concat
    (List.mapi
       (fun i e -> (prefix @ [ i ]) :: positions (prefix @ [ i ]) e.entries)
       tree)

let rec update tree pos f =
  match pos with
  | [] -> tree
  | [ i ] ->
      List.concat (List.mapi (fun j e -> if j = i then f e else [ e ]) tree)
  | i :: rest ->
      List.mapi
        (fun j e ->
          if j = i then { e with entries = update e.entries rest f } else e)
        tree

let rec entry_at tree = function
  | [] -> None
  | [ i ] -> List.nth_opt tree i
  | i :: rest ->
      Option.bind (List.nth_opt tree i) (fun e -> entry_at e.entries rest)

let newer_line =
  "{\"by\":\"b\",\"id\":\"" ^ zero_id
  ^ "\",\"kind\":\"task\",\"seq\":1,\"v\":2}\n"

let change_object_gen o =
  let open Gen in
  let rehash = oneof_list [ true; false ] in
  let* change =
    oneof_list
      [
        set_member "v" (num 2);
        set_member "v" (num 0);
        set_member "v" (str "1");
        set_member "seq" (num 0);
        (fun o ->
          set_member "seq"
            (num (Option.value ~default:0 (integer_member "seq" o) + 1))
            o);
        without "seq";
        without "kind";
        without "v";
        set_member "kind" (num 1);
        set_member "kind" (str "pin");
        set_member "kind" (str "void");
        set_member "id" (str zero_id);
        set_member "id" (num 5);
        set_member "id" (J.Bool true);
        set_member "kind" (J.Array [ str "task" ]);
        set_member "v" (J.Bool true);
        set_member "v" (J.Array [ num 2 ]);
        set_member "seq" (J.Bool false);
        set_member "seq" (J.Array [ num 1 ]);
        set_member "x-extra" (str "x");
        set_member "x-deep" (J.Object [ (J.Text "a", J.Object []) ]);
      ]
  in
  let* rehash = rehash in
  let o' = change o in
  let o' = if J.is_json_value o' then o' else o in
  return (if rehash && Option.is_some (member "id" o') then with_id o' else o')

let line_damage_gen content =
  let open Gen in
  let ls = lines_of_content content in
  let k = List.length ls in
  oneof
    [
      J.corrupt_gen content;
      return (content ^ "\n");
      return
        (if content <> "" && content.[String.length content - 1] = '\n' then
           String.sub content 0 (String.length content - 1)
         else content);
      return "";
      return (content ^ newer_line);
      map
        (fun v -> content ^ "{\"kind\":\"task\",\"v\":" ^ v ^ "}\n")
        (oneof_list [ "true"; "[2]"; "{\"a\":2}"; "\"2\""; "2"; "1" ]);
      map
        (fun i ->
          String.concat ""
            (List.mapi
               (fun j l ->
                 if
                   j = i
                   && String.length l > 0
                   && l.[String.length l - 1] = '\n'
                 then String.sub l 0 (String.length l - 1) ^ "\r\n"
                 else l)
               ls))
        (int_range 0 (max 0 (k - 1)));
      (if k = 0 then return content
       else
         let* i = int_range 0 (k - 1) in
         match object_of_line (List.nth ls i) with
         | None -> return content
         | Some o ->
             let* o' = change_object_gen o in
             let line' =
               match J.canonical o' with
               | Some bytes -> bytes ^ "\n"
               | None -> List.nth ls i
             in
             return
               (String.concat ""
                  (List.mapi (fun j l -> if j = i then line' else l) ls)));
      (if k = 0 then return content
       else
         map
           (fun i -> String.concat "" (ls @ [ List.nth ls i ]))
           (int_range 0 (k - 1)));
    ]

let damage_gen tree =
  let open Gen in
  let ps = positions [] tree in
  let file name content =
    { name; mode = "100644"; entries = []; content = Some content }
  in
  let additions =
    [
      file "README.md" "x\n";
      file (zero_id ^ ".jsonl") newer_line;
      { name = "00"; mode = "40000"; entries = []; content = None };
      { name = "entries"; mode = "40000"; entries = []; content = None };
      {
        name = "AB";
        mode = "40000";
        entries =
          [
            file
              ("e-AB" ^ String.make (id_digits - 2) '0' ^ ".jsonl")
              newer_line;
          ];
        content = None;
      };
      {
        name = "abcdefgh00";
        mode = "40000";
        entries = [ file (zero_id ^ ".jsonl") newer_line ];
        content = None;
      };
      {
        name = "zz";
        mode = "40000";
        entries = [ file "e-zz0000000000.jsonl" "x\n" ];
        content = None;
      };
    ]
  in
  let add =
    let* extra = oneof_list additions in
    if ps = [] then return (extra :: tree)
    else
      let* pos = oneof_list ([] :: ps) in
      if pos = [] then return (extra :: tree)
      else
        return
          (update tree pos (fun e ->
               [ { e with entries = extra :: e.entries } ]))
  in
  if ps = [] then add
  else
    let* pos = oneof_list ps in
    let e = Option.get (entry_at tree pos) in
    let chunk_mode =
      map
        (fun mode ->
          update tree pos (fun e ->
              [ (if e.content = None then e else { e with mode }) ]))
        (oneof_list
           [ "1006440"; "1100644"; "10064"; "100645"; "0100644"; "100755" ])
    in
    let siblings =
      match List.rev pos with
      | _ :: parent -> (
          match List.rev parent with
          | [] -> List.map (fun e -> e.name) tree
          | parent -> (
              match entry_at tree parent with
              | Some p -> List.map (fun e -> e.name) p.entries
              | None -> []))
      | [] -> []
    in
    let sibling_name =
      match List.filter (fun n -> n <> e.name) siblings with
      | [] -> return tree
      | names ->
          map
            (fun name -> update tree pos (fun e -> [ { e with name } ]))
            (oneof_list names)
    in
    oneof_weighted
      [
        (2, add);
        (2, sibling_name);
        (1, return (update tree pos (fun _ -> [])));
        (1, return (update tree pos (fun e -> [ e; e ])));
        (2, chunk_mode);
        ( 1,
          map
            (fun mode -> update tree pos (fun e -> [ { e with mode } ]))
            (oneof_list
               [
                 "100755";
                 "100664";
                 "120000";
                 "160000";
                 "40000";
                 "040000";
                 "644";
                 "";
                 "1006440";
                 "100648";
                 "0100644";
               ]) );
        ( 1,
          map
            (fun name -> update tree pos (fun e -> [ { e with name } ]))
            (oneof_list
               [
                 e.name ^ "/x";
                 String.uppercase_ascii e.name;
                 e.name ^ "0";
                 "x" ^ e.name;
                 "";
                 (if e.name = "" then "0"
                  else "0" ^ String.sub e.name 1 (String.length e.name - 1));
               ]) );
        ( 3,
          match e.content with
          | Some content ->
              map
                (fun content ->
                  update tree pos (fun e ->
                      [ { e with content = Some content } ]))
                (line_damage_gen content)
          | None -> add );
      ]

let rec tree_to_json tree =
  `List
    (List.map
       (fun e ->
         let bytes s =
           if String.is_valid_utf_8 s then `String s
           else `Assoc [ ("bytes", `String (J.hex s)) ]
         in
         `Assoc
           ([ ("name", bytes e.name); ("mode", `String e.mode) ]
           @ (if e.entries = [] then []
              else [ ("entries", tree_to_json e.entries) ])
           @
           match e.content with
           | Some c -> [ ("content", bytes c) ]
           | None -> []))
       tree)

let print_tree tree = Yojson.Basic.to_string (tree_to_json tree)

let is_ledger_line line =
  match object_of_line line with
  | Some o ->
      Option.is_some (string_member "kind" o)
      && integer_member "v" o = Some 1
      && (match integer_member "seq" o with Some s -> s >= 1 | None -> false)
      && string_member "id" o = Some (entry_id o)
  | None -> false

let line_gen =
  let open Gen in
  let* seq =
    oneof_weighted
      [ (4, int_range 1 9); (1, int_range 9007199254740980 9007199254740991) ]
  in
  let* o = line_object_gen ~seq in
  let* damaged = bool in
  if not damaged then return (canonical_line o)
  else
    let* o' = change_object_gen o in
    return
      (match J.canonical_line o' with Some l -> l | None -> canonical_line o)

let task_line ?(name = "t") seq =
  canonical_line
    (with_id
       (J.Object
          [
            (J.Text "by", str "Ada Lovelace <ada@example.com>");
            (J.Text "kind", str "task");
            (J.Text "name", str name);
            (J.Text "seq", num seq);
            (J.Text "v", num 1);
          ]))
