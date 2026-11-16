(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Id = Sinter_git_objects.Object_id
module Commit_content = Sinter_git_objects.Commit_content
module Shallow_content = Sinter_git_objects.Shallow_content
module Tree_content = Sinter_git_objects.Tree_content
module Commit_files = Sinter_git_model.Commit_files
module Model = Changes_model
module Path = Sinter_paths.Path
module Text = Sinter_text.Text

module Graph = Sinter_commit_graphs.Commit_graph.Make (struct
  type t = Id.t

  let equal = Id.equal
  let hash = Id.hash
end)

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f
let big = 1 lsl 40

let hex_of bytes =
  String.concat ""
    (List.map
       (fun c -> Printf.sprintf "%02x" (Char.code c))
       (List.of_seq (String.to_seq bytes)))

let bytes_of_hex hex =
  String.init
    (String.length hex / 2)
    (fun i -> Char.chr (int_of_string ("0x" ^ String.sub hex (2 * i) 2)))

let find_blank content =
  let rec go i =
    if i + 1 >= String.length content then None
    else if content.[i] = '\n' && content.[i + 1] = '\n' then Some i
    else go (i + 1)
  in
  go 0

let format_name = function Id.Sha1 -> "sha1" | Id.Sha256 -> "sha256"
let format_gen = Gen.oneof_list [ Id.Sha1; Id.Sha256 ]

let id_bytes_gen format =
  Gen.string_size ~gen:Gen.char (Gen.return (Id.length format))

let id_of_bytes format bytes =
  match Id.of_bytes format bytes with
  | Some id -> id
  | None -> Alcotest.failf "no id of %d bytes" (String.length bytes)

let id_of_hex format hex =
  match Id.of_hex format hex with
  | Some id -> id
  | None -> Alcotest.failf "no id of the hex %S" hex

let ids_hex ids = List.map Id.to_hex ids

let format_of_json = function
  | `String "sha1" -> Id.Sha1
  | `String "sha256" -> Id.Sha256
  | other -> Alcotest.failf "not a format: %s" (Yojson.Basic.to_string other)

let required name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other -> Alcotest.failf "not an object: %s" (Yojson.Basic.to_string other)

(* Object ids. *)

let object_id_tests =
  [
    case "an object id has 20 bytes in sha1 and 32 in sha256" (fun () ->
        Alcotest.(check int) "sha1" 20 (Id.length Id.Sha1);
        Alcotest.(check int) "sha256" 32 (Id.length Id.Sha256));
    property ~name:"the bytes and the hex form of an object id go and come back"
      ~print:(fun (format, bytes) -> format_name format ^ " " ^ hex_of bytes)
      Gen.(
        format_gen >>= fun format -> pair (return format) (id_bytes_gen format))
      (fun (format, bytes) ->
        match Id.of_bytes format bytes with
        | None -> false
        | Some id -> (
            Id.to_bytes id = bytes
            && Id.format id = format
            && Id.to_hex id = hex_of bytes
            &&
            match Id.of_hex format (Id.to_hex id) with
            | Some back -> Id.equal back id && Id.to_bytes back = bytes
            | None -> false));
    property ~name:"of_bytes takes exactly the number of bytes of the format"
      ~print:(fun (format, bytes) -> format_name format ^ " " ^ hex_of bytes)
      Gen.(pair format_gen (string_size ~gen:char (int_range 0 40)))
      (fun (format, bytes) ->
        Id.of_bytes format bytes <> None
        = (String.length bytes = Id.length format));
    property ~name:"of_hex takes exactly the lower-case hex digits of an id"
      ~print:(fun (format, hex) -> format_name format ^ " " ^ hex)
      Gen.(
        format_gen >>= fun format ->
        pair (return format)
          (string_size
             ~gen:
               (oneof_list
                  (List.of_seq (String.to_seq "0123456789abcdefABCDEFg x")))
             (oneof_list
                [
                  2 * Id.length format;
                  (2 * Id.length format) - 1;
                  (2 * Id.length format) + 1;
                  0;
                  40;
                  64;
                ])))
      (fun (format, hex) ->
        let digit c = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') in
        Id.of_hex format hex <> None
        = (String.length hex = 2 * Id.length format && String.for_all digit hex));
    case "an upper-case hex digit is not a hex digit" (fun () ->
        let hex = String.make 39 'a' ^ "A" in
        Alcotest.(check bool) "upper case" true (Id.of_hex Id.Sha1 hex = None);
        Alcotest.(check bool)
          "lower case" true
          (Id.of_hex Id.Sha1 (String.lowercase_ascii hex) <> None));
    property ~name:"equal, compare, and hash agree with the bytes of the ids"
      ~print:(fun (a, b) -> hex_of a ^ " " ^ hex_of b)
      Gen.(
        pair (id_bytes_gen Id.Sha1)
          (oneof [ id_bytes_gen Id.Sha1; return (String.make 20 '\000') ]))
      (fun (a, b) ->
        let ia = id_of_bytes Id.Sha1 a and ib = id_of_bytes Id.Sha1 b in
        let sign n = compare n 0 in
        Id.equal ia ib = (a = b)
        && sign (Id.compare ia ib) = sign (String.compare a b)
        && Id.compare ia ib = 0 = Id.equal ia ib
        && Id.compare ia ia = 0
        && Id.equal ia ia
        && Id.hash ia >= 0
        && Id.hash ia = Id.hash (id_of_bytes Id.Sha1 a));
  ]

(* Commit objects. *)

type commit_shape = {
  format : Id.format;
  tree : string;
  named : string list;
  header : string list;
  after : string list;
  message : string option;
}

let commit_content shape =
  "tree " ^ shape.tree ^ "\n"
  ^ String.concat "" (List.map (fun p -> "parent " ^ p ^ "\n") shape.named)
  ^ String.concat ""
      (List.map (fun line -> line ^ "\n") (shape.header @ shape.after))
  ^ match shape.message with None -> "" | Some message -> "\n" ^ message

let print_shape shape = Printf.sprintf "%S" (commit_content shape)
let hex_gen format = Gen.map hex_of (id_bytes_gen format)

let other_header_gen =
  Gen.oneof_list
    [
      "author A U Thor <a@example.invalid> 1767225600 +0000";
      "committer A U Thor <a@example.invalid> 1767225600 +0000";
      "encoding ISO-8859-1";
      "gpgsig -----BEGIN PGP SIGNATURE-----";
      " parent 0123";
      "parents x";
      "parent";
      "parentparent x";
      "Parent x";
      "mergetag object x";
    ]

let commit_shape_gen =
  let open Gen in
  format_gen >>= fun format ->
  let pool = list_size (return 3) (hex_gen format) in
  pool >>= fun pool ->
  hex_gen format >>= fun tree ->
  list_size (int_range 0 5) (oneof_list pool) >>= fun named ->
  list_size (int_range 0 3) other_header_gen >>= fun header ->
  (if header = [] then return []
   else
     list_size (int_range 0 2)
       (oneof
          [
            map (fun p -> "parent " ^ p) (oneof_list pool);
            return "parent NOT-HEX";
            other_header_gen;
          ]))
  >>= fun after ->
  option
    (oneof
       [
         string_size ~gen:char (int_range 0 30);
         map (fun p -> "parent " ^ p ^ "\n") (oneof_list pool);
       ])
  >>= fun message -> return { format; tree; named; header; after; message }

let parse_named format content =
  match Commit_content.parse format content with
  | Ok { tree; named } -> Ok (Id.to_hex tree, ids_hex named)
  | Error error -> Error error

let commit_error_name = function
  | Commit_content.Malformed_tree_line -> "malformed tree line"
  | Commit_content.Malformed_parent_line n ->
      Printf.sprintf "malformed parent line %d" n

let check_commit name expected content format =
  let show = function
    | Ok (tree, named) -> tree ^ " " ^ String.concat "," named
    | Error error -> commit_error_name error
  in
  Alcotest.(check string)
    name (show expected)
    (show (parse_named format content))

let h1 = String.make 40 '1'
let h2 = String.make 40 '2'
let h3 = String.make 40 'a'

let commit_tests =
  [
    (* @verifies changes#give-commit-parents=v1
       Over generated commit objects, of both object formats, the named parents
       must be exactly the ids of the lines 2 to k + 1 that start with `parent`
       and a space, in order and with repeats: the test fails when a program
       takes a `parent` line after another header line or in the message, or
       drops a repeated parent. The shallow rule over the named parents is the
       part-1 test of `Commit_graph.parents`. *)
    property ~name:"the named parents are the parent lines right after line 1"
      ~print:print_shape commit_shape_gen (fun shape ->
        parse_named shape.format (commit_content shape)
        = Ok (shape.tree, shape.named));
    property ~name:"the parse reads only line 1 and the parent lines"
      ~print:(fun (shape, rest) ->
        print_shape shape ^ " then " ^ Printf.sprintf "%S" rest)
      Gen.(pair commit_shape_gen (string_size ~gen:char (int_range 0 40)))
      (fun (shape, rest) ->
        let prefix =
          "tree " ^ shape.tree ^ "\n"
          ^ String.concat ""
              (List.map (fun p -> "parent " ^ p ^ "\n") shape.named)
        in
        let rest =
          if String.starts_with ~prefix:"parent " rest then "x" ^ rest else rest
        in
        parse_named shape.format (prefix ^ rest)
        = parse_named shape.format (commit_content shape));
    case "a tree line that is not in its form is malformed" (fun () ->
        List.iter
          (fun content ->
            check_commit content (Error Commit_content.Malformed_tree_line)
              content Id.Sha1)
          [
            "";
            "tree";
            "tree " ^ h1;
            "tree " ^ String.uppercase_ascii h3 ^ "\n";
            "tree  " ^ h1 ^ "\n";
            "tree " ^ h1 ^ " \n";
            "tre " ^ h1 ^ "\n";
            "parent " ^ h1 ^ "\n";
            "tree " ^ String.sub h1 0 39 ^ "\n";
            "tree " ^ String.make 64 '1' ^ "\n";
          ];
        check_commit "sha1 id in sha256"
          (Error Commit_content.Malformed_tree_line)
          ("tree " ^ h1 ^ "\n")
          Id.Sha256);
    case "the first parent line that is not in its form is malformed" (fun () ->
        let tree = "tree " ^ h1 ^ "\n" in
        List.iter
          (fun (rest, line) ->
            check_commit rest
              (Error (Commit_content.Malformed_parent_line line)) (tree ^ rest)
              Id.Sha1)
          [
            ("parent " ^ String.uppercase_ascii h3 ^ "\n", 2);
            ("parent " ^ h2 ^ "\nparent " ^ String.uppercase_ascii h3 ^ "\n", 3);
            ("parent " ^ h2 ^ " \n", 2);
            ("parent " ^ h2, 2);
            ("parent " ^ h2 ^ "\nparent x\nparent y\n", 3);
            ("parent \n", 2);
            ("parent ", 2);
          ]);
    case "a commit with no parent line names no commit" (fun () ->
        check_commit "root"
          (Ok (h1, []))
          ("tree " ^ h1 ^ "\nauthor A <a@example.invalid> 1 +0000\n\nm\n")
          Id.Sha1;
        check_commit "no header" (Ok (h1, [])) ("tree " ^ h1 ^ "\n") Id.Sha1);
    case "a parent line after another line names no parent" (fun () ->
        check_commit "after"
          (Ok (h1, [ h2 ]))
          ("tree " ^ h1 ^ "\nparent " ^ h2 ^ "\nauthor A\nparent " ^ h3
         ^ "\n\nparent " ^ h3 ^ "\n")
          Id.Sha1);
    case "a parse takes a long message in time that does not grow with it"
      (fun () ->
        Counted_work.check_growth ~exponent:0. ~margin:4. ~sizes:(100, 100_000)
          ~input:(fun n ->
            "tree " ^ h1 ^ "\nparent " ^ h2 ^ "\n\n" ^ String.make (n * 10) 'm')
          (fun content -> Commit_content.parse Id.Sha1 content));
    case "a parse takes time linear in the number of parent lines" (fun () ->
        Counted_work.check_growth ~margin:4. ~sizes:(100, 10_000)
          ~input:(fun n ->
            "tree " ^ h1 ^ "\n"
            ^ String.concat "" (List.init n (fun _ -> "parent " ^ h2 ^ "\n")))
          (fun content -> Commit_content.parse Id.Sha1 content));
    property ~count:2000 ~name:"a parse takes any bytes and never raises"
      ~print:(Printf.sprintf "%S")
      Gen.(
        oneof
          [
            string_size ~gen:char (int_range 0 120);
            map2
              (fun shape (cut, byte) ->
                let content = commit_content shape in
                let length = String.length content in
                let cut = if length = 0 then 0 else cut mod length in
                let mutated = Bytes.of_string content in
                if length > 0 then Bytes.set mutated cut byte;
                if cut mod 2 = 0 then Bytes.to_string mutated
                else String.sub content 0 cut)
              commit_shape_gen (pair nat char);
          ])
      (fun content ->
        List.for_all
          (fun format ->
            match Commit_content.parse format content with
            | Ok _ | Error _ -> true)
          [ Id.Sha1; Id.Sha256 ]);
  ]

(* The vectors of the group message-texts give the message of a commit and its
   header encoding; the parse of the commit object gives the same result when
   the message changes. *)
let message_text_inputs_tests =
  let set = Vectors.read "changes" in
  [
    case "the commit objects of the vectors message-texts keep their parse"
      (fun () ->
        List.iter
          (fun (vector : Vectors.vector) ->
            let content = Model.commit_object_of_message_input vector.input in
            let header =
              match find_blank content with
              | Some index -> String.sub content 0 index
              | None -> content
            in
            let other = header ^ "\n\nanother message\xff\n" in
            Alcotest.(check bool)
              (Printf.sprintf "vector %d" vector.number)
              true
              (parse_named Id.Sha1 content = parse_named Id.Sha1 other))
          (Vectors.vectors set "message-texts"));
  ]

(* The file shallow. *)

let shallow_error_name = function
  | Shallow_content.Malformed_line n -> Printf.sprintf "malformed line %d" n

let shallow_show = function
  | Ok ids -> String.concat "," (ids_hex ids)
  | Error error -> shallow_error_name error

let check_shallow name expected format content =
  Alcotest.(check string)
    name (shallow_show expected)
    (shallow_show (Shallow_content.parse format content))

let shallow_tests =
  [
    case "an empty file shallow names no commit" (fun () ->
        check_shallow "empty" (Ok []) Id.Sha1 "");
    property ~name:"the file shallow names the ids of its lines, in order"
      ~print:(fun (format, ids) ->
        format_name format ^ " " ^ String.concat "," ids)
      Gen.(
        format_gen >>= fun format ->
        pair (return format) (list_size (int_range 0 6) (hex_gen format)))
      (fun (format, ids) ->
        match
          Shallow_content.parse format
            (String.concat "" (List.map (fun id -> id ^ "\n") ids))
        with
        | Ok parsed -> ids_hex parsed = ids
        | Error _ -> false);
    case "a line of the file shallow that is not an id is malformed" (fun () ->
        List.iter
          (fun (content, line) ->
            check_shallow
              (Printf.sprintf "%S" content)
              (Error (Shallow_content.Malformed_line line)) Id.Sha1 content)
          [
            (h1, 1);
            (h1 ^ "\n" ^ h2, 2);
            ("\n", 1);
            (h1 ^ "\n\n", 2);
            (String.uppercase_ascii h3 ^ "\n", 1);
            (h1 ^ " \n", 1);
            (h1 ^ "\r\n", 1);
            (h1 ^ "\n" ^ String.make 64 '1' ^ "\n", 2);
          ]);
    case "the parse of the file shallow takes time linear in its length"
      (fun () ->
        Counted_work.check_growth ~margin:4. ~sizes:(100, 10_000)
          ~input:(fun n -> String.concat "" (List.init n (fun _ -> h1 ^ "\n")))
          (Shallow_content.parse Id.Sha1));
    property ~count:2000 ~name:"the parse of the file shallow never raises"
      ~print:(Printf.sprintf "%S")
      Gen.(
        oneof
          [
            string_size ~gen:char (int_range 0 100);
            map
              (fun ids -> String.concat "\n" ids)
              (list_size (int_range 0 4)
                 (string_size
                    ~gen:(oneof_list (List.of_seq (String.to_seq "0af\nA ")))
                    (int_range 0 42)));
          ])
      (fun content ->
        match Shallow_content.parse Id.Sha1 content with
        | Ok _ | Error _ -> true);
  ]

(* Git tree objects. *)

type raw = { mode : string; name : string; id : string }

let serialize entries =
  String.concat ""
    (List.map
       (fun { mode; name; id } -> mode ^ " " ^ name ^ "\000" ^ id)
       entries)

let raw_gen format =
  let open Gen in
  map3
    (fun mode name id -> { mode; name; id })
    (oneof
       [
         oneof_list [ "100644"; "100755"; "40000"; "120000"; "160000"; ""; "0" ];
         string_size
           ~gen:(map (fun c -> if c = ' ' then 'x' else c) char)
           (int_range 0 8);
       ])
    (oneof
       [
         oneof_list [ "a"; "a b"; "a/b"; ""; "\xff"; "."; "x.md" ];
         string_size
           ~gen:(map (fun c -> if c = '\000' then 'y' else c) char)
           (int_range 0 8);
       ])
    (oneof
       [
         id_bytes_gen format;
         return (String.make (Id.length format) '\000');
         return (String.make (Id.length format) ' ');
       ])

let print_raws entries =
  String.concat "; "
    (List.map
       (fun { mode; name; id } ->
         Printf.sprintf "%S %S %s" mode name (hex_of id))
       entries)

let raws_of format content =
  match Tree_content.parse format content with
  | Ok entries ->
      Ok
        (List.map
           (fun (entry : Tree_content.entry) ->
             { mode = entry.mode; name = entry.name; id = Id.to_bytes entry.id })
           entries)
  | Error error -> Error error

let tree_error_offset = function Tree_content.Malformed_entry offset -> offset

let tree_parse_tests =
  [
    case "an empty git tree object lists no entry" (fun () ->
        Alcotest.(check bool) "empty" true (raws_of Id.Sha1 "" = Ok []));
    property
      ~name:"the parse gives each entry, in order, byte for byte, repeats kept"
      ~print:(fun (format, entries) ->
        format_name format ^ " " ^ print_raws entries)
      Gen.(
        format_gen >>= fun format ->
        pair (return format)
          ( list_size (int_range 0 6) (raw_gen format) >>= fun entries ->
            oneof [ return entries; return (entries @ entries) ] ))
      (fun (format, entries) -> raws_of format (serialize entries) = Ok entries);
    property
      ~name:
        "a content cut inside an entry is malformed at the start of that entry"
      ~print:(fun (format, entries, cut) ->
        Printf.sprintf "%s %s cut at %d" (format_name format)
          (print_raws entries) cut)
      Gen.(
        format_gen >>= fun format ->
        triple (return format) (list_size (int_range 1 5) (raw_gen format)) nat)
      (fun (format, entries, cut) ->
        let content = serialize entries in
        let cut = cut mod (String.length content + 1) in
        let rec expected start = function
          | [] -> Ok []
          | entry :: rest ->
              let length = String.length (serialize [ entry ]) in
              if cut <= start then Ok []
              else if cut < start + length then Error start
              else
                Result.map
                  (fun tail -> entry :: tail)
                  (expected (start + length) rest)
        in
        let actual =
          Result.map_error tree_error_offset
            (raws_of format (String.sub content 0 cut))
        in
        actual = expected 0 entries);
    case "an entry with no space, no 0x00, or a short id is malformed"
      (fun () ->
        let good =
          serialize [ { mode = "100644"; name = "a"; id = String.make 20 'i' } ]
        in
        let offset = String.length good in
        List.iter
          (fun (label, rest) ->
            Alcotest.(check bool)
              label true
              (Result.map_error tree_error_offset
                 (raws_of Id.Sha1 (good ^ rest))
              = Error offset))
          [
            ("no space", "100644");
            ("no 0x00", "100644 name");
            ("a short id", "100644 name\000" ^ String.make 19 'i');
          ]);
    case "the mode ends at the first space and the name can hold spaces"
      (fun () ->
        let id = String.make 20 '\000' in
        Alcotest.(check bool)
          "parsed" true
          (raws_of Id.Sha1 ("100644 a b c\000" ^ id ^ " x\000" ^ id)
          = Ok
              [
                { mode = "100644"; name = "a b c"; id };
                { mode = ""; name = "x"; id };
              ]));
    case "the parse of a git tree object takes time linear in its length"
      (fun () ->
        Counted_work.check_growth ~margin:4. ~sizes:(100, 10_000)
          ~input:(fun n ->
            serialize
              (List.init n (fun i ->
                   {
                     mode = "100644";
                     name = string_of_int i;
                     id = String.make 20 'i';
                   })))
          (Tree_content.parse Id.Sha1));
    property ~count:2000 ~name:"the parse of a git tree object never raises"
      ~print:(Printf.sprintf "%S")
      Gen.(
        string_size
          ~gen:(oneof [ char; oneof_list [ ' '; '\000'; '1' ] ])
          (int_range 0 120))
      (fun content ->
        List.for_all
          (fun format ->
            match Tree_content.parse format content with
            | Ok _ | Error _ -> true)
          [ Id.Sha1; Id.Sha256 ]);
  ]

(* The entries of the git tree object of a commit. *)

type store = (string * string) list

let reader (store : store) =
  let reads = ref [] in
  let read id =
    let hex = Id.to_hex id in
    reads := hex :: !reads;
    match List.assoc_opt hex store with
    | Some content -> Ok content
    | None -> Error hex
  in
  (read, fun () -> List.rev !reads)

let tree_id format content =
  (* The id of a git tree object is a name here, not a hash; any distinct bytes
     do. *)
  let digest = Digest.string (format_name format ^ content) in
  hex_of (String.sub (digest ^ digest ^ digest) 0 (Id.length format))

let blob format name =
  String.sub
    (Digest.string name ^ Digest.string name ^ Digest.string name)
    0 (Id.length format)

(* A tree of the model, written as git tree objects into a store. *)
let rec store_of format (entries : Model.entry list) : string * store =
  let parts, stores =
    List.split
      (List.map
         (fun (entry : Model.entry) ->
           match Model.entry_kind entry.mode with
           | Model.Tree_kind ->
               let id, store = store_of format entry.entries in
               ( { mode = entry.mode; name = entry.name; id = bytes_of_hex id },
                 store )
           | _ ->
               ( {
                   mode = entry.mode;
                   name = entry.name;
                   id = blob format entry.name;
                 },
                 [] ))
         entries)
  in
  let content = serialize parts in
  let id = tree_id format content in
  (id, (id, content) :: List.concat stores)

let build_error_name = function
  | Tree_content.Unread hex -> "unread " ^ hex
  | Tree_content.Malformed { tree; error } ->
      Printf.sprintf "malformed %s at %d" (Id.to_hex tree)
        (tree_error_offset error)
  | Tree_content.Cycle id -> "cycle " ^ Id.to_hex id
  | Tree_content.Too_many_entries -> "too many entries"

let entries_or_fail ?path format store root =
  let read, reads = reader store in
  match
    Tree_content.entries ~max_entries:big ?path ~read format
      (id_of_hex format root)
  with
  | Ok entries -> (entries, reads ())
  | Error error -> Alcotest.failf "entries: %s" (build_error_name error)

let path_bytes path = Text.encode (Path.to_text path)

let paths_of entries =
  List.sort String.compare
    (List.map (fun (path, _) -> path_bytes path) (Commit_files.files entries))

let valid_path bytes =
  match Text.decode bytes with
  | Error _ -> None
  | Ok text -> Result.to_option (Path.of_text text)

let path_of bytes =
  match valid_path bytes with
  | Some path -> path
  | None -> Alcotest.failf "not a valid path: %S" bytes

let model_entry_gen =
  let open Gen in
  let name = oneof_list [ "a"; "b"; "a/b"; "b.md"; ""; "\xff"; "c d"; "." ] in
  let leaf =
    map2
      (fun name mode -> { Model.name; mode; entries = [] })
      name
      (oneof_list [ "100644"; "100755"; "120000"; "160000"; "100684"; "" ])
  in
  sized_size (int_range 0 3)
  @@ fix (fun self depth ->
      if depth = 0 then list_size (int_range 0 4) leaf
      else
        list_size (int_range 0 4)
          (oneof
             [
               leaf;
               map2
                 (fun name entries -> { Model.name; mode = "40000"; entries })
                 name
                 (self (depth - 1));
             ]))

let rec print_model (entries : Model.entry list) =
  "["
  ^ String.concat "; "
      (List.map
         (fun (entry : Model.entry) ->
           Printf.sprintf "%S %S%s" entry.mode entry.name
             (if entry.entries = [] then "" else " " ^ print_model entry.entries))
         entries)
  ^ "]"

let entries_tests =
  [
    (* @verifies changes#give-commit-files=v1
       Generated trees, with names that repeat, hold `/`, are empty or not
       UTF-8, and modes of every type, are written as the bytes of git tree
       objects; the valid paths of the files from the parse and the build must
       be those that the term `commit-file` gives from the same entries, by the
       model of the tests, or the test fails. *)
    property
      ~name:"the files from the bytes of the trees are the files of the term"
      ~print:(fun (format, entries) ->
        format_name format ^ " " ^ print_model entries)
      Gen.(pair format_gen model_entry_gen)
      (fun (format, entries) ->
        let root, store = store_of format entries in
        let read, _ = reader store in
        match
          Tree_content.entries ~max_entries:big ~read format
            (id_of_hex format root)
        with
        | Ok built -> paths_of built = Model.commit_files entries
        | Error _ -> false);
    (* @verifies changes#give-commit-file-at-path=v1
       For each byte path of the generated trees that is a valid path, the
       lookup with `~path` must find a file exactly when the term
       `commit-file` gives a file with that path, and the same blob as the
       lookup over all the entries; a program that reads too few trees, or
       keeps an entry of the same byte path out, gives another answer. *)
    property
      ~name:"the lookup at a path gives the file of the term at that path"
      ~print:(fun (format, entries) ->
        format_name format ^ " " ^ print_model entries)
      Gen.(pair format_gen model_entry_gen)
      (fun (format, entries) ->
        let root, store = store_of format entries in
        let expected = Model.commit_files entries in
        let read, _ = reader store in
        let all =
          Tree_content.entries ~max_entries:big ~read format
            (id_of_hex format root)
        in
        List.for_all
          (fun bytes ->
            match (valid_path bytes, all) with
            | None, _ -> true
            | Some path, Ok all -> (
                let read, _ = reader store in
                match
                  Tree_content.entries ~max_entries:big ~path ~read format
                    (id_of_hex format root)
                with
                | Ok some ->
                    let found = Commit_files.file some path in
                    found = Commit_files.file all path
                    && found <> None = List.mem bytes expected
                | Error _ -> false)
            | Some _, Error _ -> false)
          (Model.entry_byte_paths entries @ [ "a/b/c"; "zz" ]));
    case "each entry has its type, its blob, and the order of its tree"
      (fun () ->
        let format = Id.Sha1 in
        let sub =
          serialize [ { mode = "100755"; name = "x"; id = blob format "x" } ]
        in
        let sub_id = tree_id format sub in
        let root =
          serialize
            [
              { mode = "100644"; name = "z"; id = blob format "z" };
              { mode = "40000"; name = "d"; id = bytes_of_hex sub_id };
              { mode = "120000"; name = "l"; id = blob format "l" };
              { mode = "160000"; name = "m"; id = blob format "m" };
              { mode = "100644"; name = "z"; id = blob format "z2" };
            ]
        in
        let root_id = tree_id format root in
        let entries, _ =
          entries_or_fail format [ (root_id, root); (sub_id, sub) ] root_id
        in
        let rec show (entries : Id.t Commit_files.entry list) =
          String.concat ","
            (List.map
               (function
                 | Commit_files.Tree { name; entries } ->
                     name ^ "(" ^ show entries ^ ")"
                 | Commit_files.Regular_file { name; blob } ->
                     name ^ "=" ^ String.sub (Id.to_hex blob) 0 4
                 | Commit_files.Other { name } -> name ^ "?")
               entries)
        in
        let short name = String.sub (hex_of (blob format name)) 0 4 in
        Alcotest.(check string)
          "entries"
          (Printf.sprintf "z=%s,d(x=%s),l?,m?,z=%s" (short "z") (short "x")
             (short "z2"))
          (show entries));
    case "a tree that two entries name is read once" (fun () ->
        let format = Id.Sha1 in
        let sub =
          serialize [ { mode = "100644"; name = "x"; id = blob format "x" } ]
        in
        let sub_id = tree_id format sub in
        let mid =
          serialize
            [
              { mode = "40000"; name = "p"; id = bytes_of_hex sub_id };
              { mode = "40000"; name = "q"; id = bytes_of_hex sub_id };
            ]
        in
        let mid_id = tree_id format mid in
        let root =
          serialize
            [
              { mode = "40000"; name = "a"; id = bytes_of_hex mid_id };
              { mode = "40000"; name = "b"; id = bytes_of_hex mid_id };
              { mode = "40000"; name = "c"; id = bytes_of_hex sub_id };
            ]
        in
        let root_id = tree_id format root in
        let entries, reads =
          entries_or_fail format
            [ (root_id, root); (mid_id, mid); (sub_id, sub) ]
            root_id
        in
        Alcotest.(check (list string))
          "the reads"
          (List.sort String.compare [ root_id; mid_id; sub_id ])
          (List.sort String.compare reads);
        Alcotest.(check (list string))
          "the paths"
          [ "a/p/x"; "a/q/x"; "b/p/x"; "b/q/x"; "c/x" ]
          (paths_of entries));
    case "the lookup at a path reads only the trees on the path" (fun () ->
        let format = Id.Sha1 in
        let x =
          serialize [ { mode = "100644"; name = "f"; id = blob format "f" } ]
        in
        let x_id = tree_id format x in
        let other =
          serialize [ { mode = "100644"; name = "g"; id = blob format "g" } ]
        in
        let other_id = tree_id format other in
        let a =
          serialize
            [
              { mode = "40000"; name = "x"; id = bytes_of_hex x_id };
              { mode = "40000"; name = "y"; id = bytes_of_hex other_id };
            ]
        in
        let a_id = tree_id format a in
        let root =
          serialize
            [
              { mode = "40000"; name = "a"; id = bytes_of_hex a_id };
              { mode = "40000"; name = "b"; id = bytes_of_hex other_id };
              { mode = "40000"; name = "a/x"; id = bytes_of_hex other_id };
            ]
        in
        let root_id = tree_id format root in
        let store =
          [ (root_id, root); (a_id, a); (x_id, x); (other_id, other) ]
        in
        let path = path_of "a/x/f" in
        let some, reads = entries_or_fail ~path format store root_id in
        Alcotest.(check (list string))
          "the reads"
          (List.sort String.compare [ root_id; a_id; x_id; other_id ])
          (List.sort String.compare reads);
        let all, _ = entries_or_fail format store root_id in
        Alcotest.(check bool)
          "the same file" true
          (Commit_files.file some path = Commit_files.file all path
          && Commit_files.file some path <> None);
        let path = path_of "a" in
        let some, reads = entries_or_fail ~path format store root_id in
        Alcotest.(check (list string)) "the reads at a tree" [ root_id ] reads;
        Alcotest.(check bool)
          "a tree entry at the path holds no entries" true
          (List.exists
             (function
               | Commit_files.Tree { name = "a"; entries = [] } -> true
               | _ -> false)
             some));
    case "a result of more entries than the maximum gives no result" (fun () ->
        let format = Id.Sha1 in
        let sub =
          serialize
            (List.map
               (fun name -> { mode = "100644"; name; id = blob format name })
               [ "x"; "y"; "z" ])
        in
        let sub_id = tree_id format sub in
        let root =
          serialize
            [
              { mode = "40000"; name = "a"; id = bytes_of_hex sub_id };
              { mode = "40000"; name = "b"; id = bytes_of_hex sub_id };
            ]
        in
        let root_id = tree_id format root in
        let store = [ (root_id, root); (sub_id, sub) ] in
        let run ?path max_entries =
          let read, _ = reader store in
          match
            Tree_content.entries ?path ~max_entries ~read format
              (id_of_hex format root_id)
          with
          | Ok _ -> "ok"
          | Error error -> build_error_name error
        in
        Alcotest.(check string) "8 of 8" "ok" (run 8);
        Alcotest.(check string) "8 of 7" "too many entries" (run 7);
        Alcotest.(check string) "0 of 0" "too many entries" (run 0);
        let path = path_of "a/x" in
        Alcotest.(check string) "a path: 2 of 2" "ok" (run ~path 2);
        Alcotest.(check string)
          "a path: 2 of 1" "too many entries" (run ~path 1);
        let path = path_of "a" in
        Alcotest.(check string) "a tree at the path: 1 of 1" "ok" (run ~path 1);
        Alcotest.(check string)
          "a tree at the path: 1 of 0" "too many entries" (run ~path 0);
        match run (-1) with
        | _ -> Alcotest.fail "no exception"
        | exception Invalid_argument _ -> ());
    case "a name longer than the path by one byte is not on the path" (fun () ->
        let format = Id.Sha1 in
        let root =
          serialize
            [
              { mode = "100644"; name = "ab"; id = blob format "ab" };
              { mode = "40000"; name = "ac"; id = blob format "ac" };
              { mode = "100644"; name = "a"; id = blob format "a" };
            ]
        in
        let root_id = tree_id format root in
        let some, reads =
          entries_or_fail ~path:(path_of "a") format [ (root_id, root) ] root_id
        in
        Alcotest.(check (list string)) "one read" [ root_id ] reads;
        Alcotest.(check bool)
          "the file a" true
          (Commit_files.file some (path_of "a") <> None));
    case "a tree that cannot be read gives its error" (fun () ->
        let format = Id.Sha1 in
        let missing = String.make 40 'e' in
        let root =
          serialize
            [
              { mode = "40000"; name = "a"; id = bytes_of_hex missing };
              {
                mode = "40000";
                name = "b";
                id = bytes_of_hex (String.make 40 'f');
              };
            ]
        in
        let root_id = tree_id format root in
        let read, _ = reader [ (root_id, root) ] in
        Alcotest.(check string)
          "first missing" ("unread " ^ missing)
          (match
             Tree_content.entries ~max_entries:big ~read format
               (id_of_hex format root_id)
           with
          | Ok _ -> "ok"
          | Error error -> build_error_name error);
        let read, _ = reader [] in
        Alcotest.(check string)
          "root missing" ("unread " ^ root_id)
          (match
             Tree_content.entries ~max_entries:big ~read format
               (id_of_hex format root_id)
           with
          | Ok _ -> "ok"
          | Error error -> build_error_name error));
    case "a tree whose content is malformed gives its id" (fun () ->
        let format = Id.Sha1 in
        let bad = "100644 x" in
        let bad_id = tree_id format bad in
        let root =
          serialize
            [
              { mode = "100644"; name = "f"; id = blob format "f" };
              { mode = "40000"; name = "a"; id = bytes_of_hex bad_id };
            ]
        in
        let root_id = tree_id format root in
        let read, _ = reader [ (root_id, root); (bad_id, bad) ] in
        Alcotest.(check string)
          "malformed"
          (Printf.sprintf "malformed %s at 0" bad_id)
          (match
             Tree_content.entries ~max_entries:big ~read format
               (id_of_hex format root_id)
           with
          | Ok _ -> "ok"
          | Error error -> build_error_name error));
    case "a tree that lists itself, in turn, is a cycle" (fun () ->
        let format = Id.Sha1 in
        let a_id = String.make 40 'a' and b_id = String.make 40 'b' in
        let self =
          serialize [ { mode = "40000"; name = "s"; id = bytes_of_hex a_id } ]
        in
        let read, reads = reader [ (a_id, self) ] in
        Alcotest.(check string)
          "itself" ("cycle " ^ a_id)
          (match
             Tree_content.entries ~max_entries:big ~read format
               (id_of_hex format a_id)
           with
          | Ok _ -> "ok"
          | Error error -> build_error_name error);
        Alcotest.(check (list string)) "one read" [ a_id ] (reads ());
        let to_b =
          serialize [ { mode = "40000"; name = "b"; id = bytes_of_hex b_id } ]
        in
        let to_a =
          serialize [ { mode = "40000"; name = "a"; id = bytes_of_hex a_id } ]
        in
        let read, _ = reader [ (a_id, to_b); (b_id, to_a) ] in
        let result =
          match
            Tree_content.entries ~max_entries:big ~read format
              (id_of_hex format a_id)
          with
          | Ok _ -> "ok"
          | Error error -> build_error_name error
        in
        Alcotest.(check bool)
          ("two trees: " ^ result) true
          (result = "cycle " ^ a_id || result = "cycle " ^ b_id));
    case "the lookup at a path ends on a cycle" (fun () ->
        let a_id = String.make 40 'a' in
        let self =
          serialize [ { mode = "40000"; name = "a"; id = bytes_of_hex a_id } ]
        in
        let path = path_of (String.concat "/" (List.init 50 (fun _ -> "a"))) in
        let read, _ = reader [ (a_id, self) ] in
        match
          Tree_content.entries ~max_entries:big ~path ~read Id.Sha1
            (id_of_hex Id.Sha1 a_id)
        with
        | Ok _ | Error _ -> ());
    case "deep trees need no deep stack" (fun () ->
        let format = Id.Sha1 in
        let depth = 20_000 in
        let leaf =
          serialize [ { mode = "100644"; name = "f"; id = blob format "f" } ]
        in
        let leaf_id = String.make 40 'f' in
        let rec build n id store =
          if n = 0 then (id, store)
          else
            let parent =
              serialize [ { mode = "40000"; name = "d"; id = bytes_of_hex id } ]
            in
            let parent_id = Printf.sprintf "%040x" n in
            build (n - 1) parent_id ((parent_id, parent) :: store)
        in
        let root_id, store = build depth leaf_id [ (leaf_id, leaf) ] in
        let table = Hashtbl.create depth in
        List.iter (fun (id, content) -> Hashtbl.replace table id content) store;
        let read id =
          match Hashtbl.find_opt table (Id.to_hex id) with
          | Some content -> Ok content
          | None -> Error ()
        in
        let path =
          path_of (String.concat "/" (List.init depth (fun _ -> "d")) ^ "/f")
        in
        let found =
          Small_stack.run (fun () ->
              match
                ( Tree_content.entries ~max_entries:big ~read format
                    (id_of_hex format root_id),
                  Tree_content.entries ~max_entries:big ~path ~read format
                    (id_of_hex format root_id) )
              with
              | Ok _, Ok some -> Commit_files.file some path <> None
              | _ -> false)
        in
        Alcotest.(check bool) "found" true found);
  ]

(* The proposed vectors. *)

(* @verifies changes#give-commit-parents=v1
   The proposed vectors of `parent-lines` give the bytes of commit objects and
   whether the file `shallow` names them; the parents from the parse and the
   shallow rule must be those of each vector, or the test fails. *)
let parent_lines_vectors =
  Proposed_vectors.test "parent-lines" (fun input ->
      let format = format_of_json (required "format" input) in
      let content = Model.bytes_of_json (required "content" input) in
      let shallow = required "shallow" input = `Bool true in
      match Commit_content.parse format content with
      | Ok { named; _ } ->
          `Assoc
            [
              ( "parents",
                `List
                  (List.map
                     (fun id -> `String (Id.to_hex id))
                     (Graph.parents ~named ~shallow)) );
            ]
      | Error error -> `String (commit_error_name error))

(* @verifies changes#{give-commit-files=v1, give-commit-file-at-path=v1}
   The proposed vectors of `tree-objects` give the bytes of the git tree
   objects of a commit; the valid paths of the files, and the lookup at each
   byte path of the entries, must be those of each vector, or the test fails. *)
let tree_objects_vectors =
  Proposed_vectors.test "tree-objects" (fun input ->
      let format = format_of_json (required "format" input) in
      let root =
        match required "tree" input with
        | `String hex -> hex
        | other ->
            Alcotest.failf "not a tree: %s" (Yojson.Basic.to_string other)
      in
      let store =
        match required "trees" input with
        | `Assoc trees ->
            List.map
              (fun (id, content) -> (id, Model.bytes_of_json content))
              trees
        | other -> Alcotest.failf "not trees: %s" (Yojson.Basic.to_string other)
      in
      let all, _ = entries_or_fail format store root in
      let paths = paths_of all in
      let byte_paths =
        List.concat_map
          (fun (_, content) ->
            match Tree_content.parse format content with
            | Ok entries ->
                List.map (fun (e : Tree_content.entry) -> e.name) entries
            | Error _ -> [])
          store
      in
      List.iter
        (fun bytes ->
          match valid_path bytes with
          | None -> ()
          | Some path ->
              let some, _ = entries_or_fail ~path format store root in
              if Commit_files.file some path <> None <> List.mem bytes paths
              then Alcotest.failf "the lookup of %S" bytes)
        (paths @ byte_paths);
      `Assoc [ ("paths", `List (List.map (fun p -> `String p) paths)) ])

let tests =
  object_id_tests @ commit_tests @ message_text_inputs_tests @ shallow_tests
  @ tree_parse_tests @ entries_tests
  @ [ parent_lines_vectors; tree_objects_vectors ]
