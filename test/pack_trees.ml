(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen

let empty = Files_tree.regular ""
let folder = Files_tree.folder

let portable c =
  (c >= 'A' && c <= 'Z')
  || (c >= 'a' && c <= 'z')
  || (c >= '0' && c <= '9')
  || c = '.' || c = '_' || c = '-'

let non_portable_names =
  List.filter_map
    (fun code ->
      let c = Char.chr code in
      if portable c || c = '/' then None
      else Some (Printf.sprintf "a%cb" c, empty))
    (List.init 127 (fun index -> index + 1))

let probes =
  [
    ("case-distinct-names", folder [ ("A", empty); ("a", empty) ]);
    ("long-names", folder [ (String.make 255 'x', empty) ]);
    ( "names-kept",
      folder
        [
          ("d", folder [ ("\xc3\xa9.txt", empty) ]);
          ("e", folder [ ("e\xcc\x81", empty) ]);
          ("f", folder [ ("\xef\xbf\xbd\xf0\x9f\x98\x80", empty) ]);
        ] );
    ("non-portable-names", folder non_portable_names);
    ("non-utf-8-names", folder [ ("\xff", empty); ("a\x80", empty) ]);
  ]

let needs =
  lazy
    (List.map
       (fun (need, tree) ->
         match Files_tree.run tree (fun _ -> ()) with
         | Files_tree.Not_stored _ -> (need, false)
         | Files_tree.Read _ -> (need, true))
       probes)

let holds need =
  Option.value (List.assoc_opt need (Lazy.force needs)) ~default:false

let name_classes () =
  [
    ( None,
      [
        "pack.toml"; "a"; "b"; "x.wasm"; "..."; ".a"; "a."; "queries"; "~"; "d";
      ] );
    (Some "case-distinct-names", [ "A"; "Pack.toml"; "B"; "D" ]);
    ( Some "non-portable-names",
      [ "a b"; " "; "a\tb"; "a\nb"; "a\\b"; "a\x7fb"; "[x]{y}*?"; "a:b" ] );
    (Some "names-kept", [ "\xc3\xa9"; "\xe2\x80\xa8" ]);
    (Some "long-names", [ String.make 255 'x'; String.make 200 'y' ]);
    (Some "non-utf-8-names", [ "\xff"; "a\x80" ]);
  ]
  |> List.filter_map (fun (need, names) ->
      match need with
      | None -> Some names
      | Some need -> if holds need then Some names else None)
  |> List.concat

let content_gen =
  Gen.oneof_weighted
    [
      (3, Gen.return []);
      ( 3,
        Gen.map
          (fun text -> [ (text, 1) ])
          (Gen.oneof_list [ "x"; "a\n"; "\xff\x00" ]) );
      (1, Gen.return [ ("abcdefgh", 20_000) ]);
    ]

let link_gen =
  Gen.oneof_list [ "a"; "."; ".."; "/"; "pack.toml"; "../.."; "d/a"; "missing" ]

let unique entries =
  let key name =
    if holds "case-distinct-names" then name else String.lowercase_ascii name
  in
  let rec keep seen = function
    | [] -> []
    | (name, file) :: rest ->
        if List.mem (key name) seen then keep seen rest
        else (name, file) :: keep (key name :: seen) rest
  in
  List.sort (fun (a, _) (b, _) -> String.compare a b) (keep [] entries)

let file kind : Files_tree.file =
  {
    kind;
    permissions = { read = true; search = true; write = true };
    owned_by_other = false;
  }

let tree_gen =
  let names = lazy (name_classes ()) in
  let name_gen = Gen.delay (fun () -> Gen.oneof_list (Lazy.force names)) in
  let file_gen =
    Gen.fix (fun self depth ->
        let leaf =
          [
            (4, Gen.map (fun pieces -> file (Regular pieces)) content_gen);
            (1, Gen.map (fun reference -> file (Link reference)) link_gen);
            (1, Gen.return (file Pipe));
          ]
        in
        if depth = 0 then Gen.oneof_weighted leaf
        else
          Gen.oneof_weighted
            (( 3,
               Gen.map
                 (fun entries -> file (Folder (unique entries)))
                 (Gen.list_size (Gen.int_bound 4)
                    (Gen.pair name_gen (self (depth - 1)))) )
            :: leaf))
  in
  Gen.map
    (fun entries -> file (Folder (unique entries)))
    (Gen.list_size (Gen.int_bound 5) (Gen.pair name_gen (file_gen 3)))

let deep_tree depth =
  let rec go depth =
    if depth = 0 then folder [ ("f", Files_tree.regular "deep") ]
    else folder [ ("a", go (depth - 1)) ]
  in
  go depth

let rec print (file : Files_tree.file) =
  match file.kind with
  | Folder entries ->
      Printf.sprintf "{%s }"
        (String.concat ""
           (List.map
              (fun (name, file) -> Printf.sprintf " %S: %s;" name (print file))
              entries))
  | Regular pieces ->
      let bytes = Files_tree.bytes_of_pieces pieces in
      if String.length bytes > 20 then
        Printf.sprintf "<%d bytes>" (String.length bytes)
      else Printf.sprintf "%S" bytes
  | Link reference -> Printf.sprintf "-> %S" reference
  | Pipe -> "pipe"
