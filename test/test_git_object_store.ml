(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Store = Sinter_git_object_store.Object_store
module Id = Sinter_git_objects.Object_id
module Files = Sinter_repository_files
module M = Memory_system
module O = Object_files

let property ?(count = 200) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f

let limits =
  {
    Store.max_content_size = 1 lsl 24;
    max_deltas = 1000;
    max_databases = 100;
    max_packs = 100;
    max_alternates_size = 1 lsl 16;
  }

let oid format raw =
  match Id.of_bytes format raw with
  | Some id -> id
  | None -> invalid_arg "oid: not an object id"

let finder ?(limits = limits) ?(format = Id.Sha1) ?(git_folder = "/g") system =
  let module R = Files.Make ((val M.system system)) in
  let module S = Store.Make (R) in
  let store = S.create limits format ~git_folder in
  fun raw -> S.find store (oid format raw)

let store_kind = function
  | O.Commit -> Store.Commit
  | O.Tree -> Store.Tree
  | O.Blob -> Store.Blob
  | O.Tag -> Store.Tag

let kind_text = function
  | Store.Commit -> "commit"
  | Tree -> "tree"
  | Blob -> "blob"
  | Tag -> "tag"

let delta_error_text = function
  | Sinter_git_object_store.Delta.Truncated -> "truncated"
  | Base_size_differs -> "base size differs"
  | Too_large -> "too large"
  | Copy_outside_base -> "copy outside base"
  | Reserved_instruction -> "reserved instruction"
  | Result_size_differs -> "result size differs"

let problem_text = function
  | Store.Not_zlib -> "not zlib"
  | Size_differs -> "size differs"
  | Bytes_after_stream -> "bytes after stream"
  | Malformed_loose_header -> "malformed loose header"
  | Malformed_entry_header -> "malformed entry header"
  | Malformed_delta error -> "malformed delta: " ^ delta_error_text error
  | Malformed_index -> "malformed index"
  | Pack_does_not_match_index -> "pack does not match index"
  | Wrong_id -> "wrong id"
  | Base_not_in_pack id -> "base not in pack " ^ Id.to_hex id
  | Delta_cycle -> "delta cycle"

let offset_text = function None -> "" | Some n -> Printf.sprintf "@%d" n

let damage_text { Store.pathname; offset; problem } =
  pathname ^ offset_text offset ^ ": " ^ problem_text problem

let file_failure_text = function
  | Files.No_file -> "no file"
  | Not_a_regular_file -> "not a regular file"
  | Not_a_folder -> "not a folder"
  | Not_a_symbolic_link -> "not a symbolic link"
  | Too_large -> "too large"
  | Cannot_read -> "cannot read"

let failure_text = function
  | Store.Unread { pathname; failure } ->
      Printf.sprintf "unread %s: %s" pathname (file_failure_text failure)
  | Too_large { pathname; offset } ->
      Printf.sprintf "too large %s%s" pathname (offset_text offset)
  | Too_many_deltas -> "too many deltas"
  | Too_many_databases -> "too many databases"
  | Too_many_packs pathname -> "too many packs " ^ pathname

let result_text = function
  | Ok { Store.held; damage } ->
      let held =
        match held with
        | None -> "not held"
        | Some { Store.kind; content } ->
            Printf.sprintf "%s %S" (kind_text kind) content
      in
      String.concat "\n" (held :: List.map damage_text damage)
  | Error failure -> "Error " ^ failure_text failure

let held ?(damage = []) kind content =
  Ok { Store.held = Some { Store.kind = store_kind kind; content }; damage }

let not_held ?(damage = []) () = Ok { Store.held = None; damage }
let damage ?offset pathname problem = { Store.pathname; offset; problem }

let check name expected actual =
  Alcotest.(check string) name (result_text expected) (result_text actual)

let db = "/g/objects"
let loose_pathname ?(db = db) raw = db ^ "/" ^ O.loose_path raw

let loose ?(db = db) ?stored ?(format = Id.Sha1) kind content =
  let raw = O.id format kind content in
  (raw, (loose_pathname ~db raw, M.File (O.loose ?stored kind content)))

let pack_pathname ?(db = db) name = db ^ "/pack/pack-" ^ name ^ ".pack"
let index_pathname ?(db = db) name = db ^ "/pack/pack-" ^ name ^ ".idx"

let pack_nodes ?(db = db) name (pack : O.pack) index =
  [
    (pack_pathname ~db name, M.File pack.bytes);
    (index_pathname ~db name, M.File index);
  ]

let index ?large ~version format pack ids =
  if version = 1 then O.index_v1 format ~pack ids
  else O.index_v2 ?large format ~pack ids

let nth_offset (pack : O.pack) n = List.nth pack.offsets n
let both_formats = [ ("sha1", Id.Sha1); ("sha256", Id.Sha256) ]
let kinds = [ O.Commit; O.Tree; O.Blob; O.Tag ]

let content_of kind =
  match kind with
  | O.Commit -> "tree 0000\n\nmessage\n"
  | Tree -> "100644 a\000" ^ String.make 20 '\001'
  | Blob -> "the bytes of a blob\n\000\255"
  | Tag -> "object 0000\ntype commit\n"

let loose_tests =
  [
    case "a loose object of each kind is held, in each object format" (fun () ->
        List.iter
          (fun (label, format) ->
            List.iter
              (fun stored ->
                List.iter
                  (fun kind ->
                    let content = content_of kind in
                    let raw, node = loose ~stored ~format kind content in
                    let find = finder ~format (M.create [ node ]) in
                    check
                      (Printf.sprintf "%s %s" label (O.kind_name kind))
                      (held kind content) (find raw))
                  kinds)
              [ false; true ])
          both_formats);
    case "an empty blob and a large blob are held" (fun () ->
        List.iter
          (fun content ->
            let raw, node = loose O.Blob content in
            check "blob" (held O.Blob content) (finder (M.create [ node ]) raw))
          [ ""; String.init 200_000 (fun i -> Char.chr (i * 7 mod 256)) ]);
    case "an id that no place holds is not held, with no damage" (fun () ->
        let _, node = loose O.Blob "here" in
        let absent = O.id Id.Sha1 O.Blob "absent" in
        List.iter
          (fun (label, nodes) ->
            check label (not_held ()) (finder (M.create nodes) absent))
          [
            ("no git folder", []);
            ( "no folder objects",
              [ ("/g/HEAD", M.File "ref: refs/heads/main\n") ] );
            ("an empty folder objects", [ (db, M.Folder) ]);
            ("other objects", [ node ]);
            ("an empty folder pack", [ node; (db ^ "/pack", M.Folder) ]);
          ]);
  ]

(* @verifies changes#{give-commit-parents=v1, give-message-texts=v1, give-commit-files=v1, give-commit-file-at-path=v1}
   @cites changes#commit=v1
   By the term `commit`, a loose object is one RFC 1950 zlib stream whose
   inflated bytes start with `<type> <size>\0` and hash to its object id. Each
   case puts a malformed stream, a malformed header, or an object of another id
   or kind at the loose pathname of X. The test fails when the store gives an
   object from such a file or omits its damage. *)
let loose_damage_tests =
  let x = O.id Id.Sha1 O.Blob "abc" in
  let at bytes = M.create [ (loose_pathname x, M.File bytes) ] in
  let damaged name bytes problem =
    case ("a loose object gives nothing: " ^ name) (fun () ->
        check name
          (not_held ~damage:[ damage (loose_pathname x) problem ] ())
          (finder (at bytes) x))
  in
  let data = O.loose_data O.Blob "abc" in
  let compressed = O.zlib data in
  let with_dictionary =
    "\x78\x20\x00\x00\x00\x01"
    ^ String.sub compressed 2 (String.length compressed - 2)
  in
  let bad_checksum =
    let n = String.length compressed in
    String.sub compressed 0 (n - 1)
    ^ String.make 1 (Char.chr ((Char.code compressed.[n - 1] + 1) land 0xff))
  in
  [
    damaged "bytes that are not zlib" "not a zlib stream" Store.Not_zlib;
    damaged "an empty file" "" Store.Not_zlib;
    damaged "a stream that ends early"
      (String.sub compressed 0 (String.length compressed - 3))
      Store.Not_zlib;
    damaged "a stream with a preset dictionary" with_dictionary Store.Not_zlib;
    damaged
      "a stream with a preset dictionary and deflate data after the header"
      ("\x78\x20" ^ String.sub compressed 2 (String.length compressed - 2))
      Store.Not_zlib;
    damaged "a stream with a window of more than 32768 bytes"
      ("\x88\x1c" ^ String.sub compressed 2 (String.length compressed - 2))
      Store.Not_zlib;
    damaged "a stream whose method is not deflate"
      ("\x79\x18" ^ String.sub compressed 2 (String.length compressed - 2))
      Store.Not_zlib;
    damaged "a stream whose header check is wrong"
      ("\x78\x9d" ^ String.sub compressed 2 (String.length compressed - 2))
      Store.Not_zlib;
    damaged "a stream whose Adler-32 is wrong" bad_checksum Store.Not_zlib;
    damaged "a stored stream whose Adler-32 is wrong"
      (let s = O.zlib_stored data in
       String.sub s 0 (String.length s - 4) ^ "\000\000\000\000")
      Store.Not_zlib;
    damaged "a header that states fewer bytes" (O.zlib "blob 2\000abc")
      Store.Size_differs;
    damaged "a header that states more bytes" (O.zlib "blob 4\000abc")
      Store.Size_differs;
    damaged "an unknown type" (O.zlib "blub 3\000abc")
      Store.Malformed_loose_header;
    damaged "a type in upper case" (O.zlib "BLOB 3\000abc")
      Store.Malformed_loose_header;
    damaged "a size with a sign" (O.zlib "blob +3\000abc")
      Store.Malformed_loose_header;
    damaged "an empty size" (O.zlib "blob \000abc") Store.Malformed_loose_header;
    damaged "two spaces" (O.zlib "blob  3\000abc") Store.Malformed_loose_header;
    damaged "no space" (O.zlib "blob3\000abc") Store.Malformed_loose_header;
    damaged "no byte 0x00" (O.zlib "blob 3") Store.Malformed_loose_header;
    damaged "a size in hex" (O.zlib "blob 0x3\000abc")
      Store.Malformed_loose_header;
    damaged "the object of another id" (O.loose O.Blob "abd") Store.Wrong_id;
    damaged "the content of another kind" (O.loose O.Tree "abc") Store.Wrong_id;
    case "a stream with an invalid distance code is not zlib" (fun () ->
        let bytes =
          "x\156\029\201\177\t\128\000\000\196\192\212?\133C\232@I-\184\127'\218\003\029\\\247\211q\157\2324\213-m\254\182\020\179\234\251\001*\132\241\002J\174\017\154"
        in
        let pathname = "/g/objects/ad/fd6a4bfe9422d1053fce8f01b047bacb5877ae" in
        let raw =
          match
            Id.of_hex Id.Sha1 "adfd6a4bfe9422d1053fce8f01b047bacb5877ae"
          with
          | Some id -> Id.to_bytes id
          | None -> Alcotest.fail "the id"
        in
        check "an invalid distance code"
          (not_held ~damage:[ damage pathname Store.Not_zlib ] ())
          (finder (M.create [ (pathname, M.File bytes) ]) raw));
    case "a file of another kind at a loose pathname is a failure" (fun () ->
        List.iter
          (fun node ->
            check "the failure"
              (Error
                 (Store.Unread
                    {
                      pathname = loose_pathname x;
                      failure = Not_a_regular_file;
                    }))
              (finder (M.create [ (loose_pathname x, node) ]) x))
          [ M.Fifo; M.Folder ]);
    case "a loose header has at most 32 bytes before the byte 0x00" (fun () ->
        let header digits =
          O.zlib ("blob 1" ^ String.make digits '0' ^ "\000")
        in
        check "32 bytes"
          (Error
             (Store.Too_large { pathname = loose_pathname x; offset = None }))
          (finder (at (header 26)) x);
        check "33 bytes"
          (not_held
             ~damage:[ damage (loose_pathname x) Store.Malformed_loose_header ]
             ())
          (finder (at (header 27)) x));
  ]

let objects_of n =
  List.init n (fun i ->
      let kind = List.nth kinds (i mod 4) in
      (kind, Printf.sprintf "object %d of the pack\n%s" i (String.make i 'z')))

let pack_tests =
  [
    case "an object in a pack is held, in each pack version and index version"
      (fun () ->
        List.iter
          (fun (label, format) ->
            List.iter
              (fun (version, index_version) ->
                let objects = objects_of 9 in
                let pack =
                  O.pack ~version format
                    (List.map (fun (k, c) -> O.Whole (k, c)) objects)
                in
                let ids = List.map (fun (k, c) -> O.id format k c) objects in
                let find =
                  finder ~format
                    (M.create
                       (pack_nodes "p" pack
                          (index ~version:index_version format pack ids)))
                in
                List.iter2
                  (fun raw (kind, content) ->
                    check
                      (Printf.sprintf "%s pack %d index %d" label version
                         index_version)
                      (held kind content) (find raw))
                  ids objects)
              [ (2, 1); (2, 2); (3, 1); (3, 2) ])
          both_formats);
    case "an object at a large offset of an index v2 is held" (fun () ->
        let objects = objects_of 5 in
        let pack =
          O.pack Id.Sha1 (List.map (fun (k, c) -> O.Whole (k, c)) objects)
        in
        let ids = List.map (fun (k, c) -> O.id Id.Sha1 k c) objects in
        let find =
          finder
            (M.create
               (pack_nodes "p" pack
                  (O.index_v2 ~large:[ 1; 3 ] Id.Sha1 ~pack ids)))
        in
        List.iter2
          (fun raw (kind, content) ->
            check "large offsets" (held kind content) (find raw))
          ids objects);
    case "an object of a chain of OFS_DELTA entries is held" (fun () ->
        List.iter
          (fun (label, format) ->
            let versions =
              List.init 6 (fun i ->
                  String.concat ""
                    (List.init (40 + i) (fun j -> Printf.sprintf "line %d\n" j)))
            in
            let entries =
              List.mapi
                (fun i content ->
                  if i = 0 then O.Whole (O.Blob, content)
                  else
                    let base = List.nth versions (i - 1) in
                    O.Ofs_delta
                      ( i - 1,
                        O.delta ~base_size:(String.length base)
                          ~result_size:(String.length content)
                          (O.delta_between base content) ))
                versions
            in
            let pack = O.pack format entries in
            let ids = List.map (O.id format O.Blob) versions in
            let find =
              finder ~format
                (M.create (pack_nodes "p" pack (O.index_v2 format ~pack ids)))
            in
            List.iter2
              (fun raw content -> check label (held O.Blob content) (find raw))
              ids versions)
          both_formats);
    case "an object of a chain of REF_DELTA entries is held" (fun () ->
        List.iter
          (fun (label, format) ->
            let versions =
              List.init 5 (fun i -> String.make (100 + i) 'r' ^ string_of_int i)
            in
            let ids = List.map (O.id format O.Tag) versions in
            let entries =
              List.rev
                (List.mapi
                   (fun i content ->
                     if i = 0 then O.Whole (O.Tag, content)
                     else
                       let base = List.nth versions (i - 1) in
                       O.Ref_delta
                         ( List.nth ids (i - 1),
                           O.delta ~base_size:(String.length base)
                             ~result_size:(String.length content)
                             (O.delta_between base content) ))
                   versions)
            in
            let pack = O.pack format entries in
            let find =
              finder ~format
                (M.create
                   (pack_nodes "p" pack
                      (O.index_v1 format ~pack (List.rev ids))))
            in
            List.iter2
              (fun raw content -> check label (held O.Tag content) (find raw))
              ids versions)
          both_formats);
  ]

let delta_of base target =
  O.delta ~base_size:(String.length base) ~result_size:(String.length target)
    (O.delta_between base target)

(* @verifies changes#{give-commit-parents=v1, give-message-texts=v1, give-commit-files=v1, give-commit-file-at-path=v1}
   @cites changes#commit=v1
   By the term `commit`, a `REF_DELTA` entry in a pack uses a base entry in the
   same pack whose object hashes to the named base id. The cases test a valid
   base in the same pack, a base entry that hashes to another object, delta
   cycles, and the delta limit. A lookup that accepts a wrong base or misses a
   valid base in the same pack fails the test. *)
let ref_delta_tests =
  let base = String.make 200 'b' and target = String.make 200 'b' ^ "t" in
  let base_id = O.id Id.Sha1 O.Blob base
  and target_id = O.id Id.Sha1 O.Blob target in
  let in_pack name entries ids =
    let pack = O.pack Id.Sha1 entries in
    (pack, pack_nodes name pack (O.index_v2 Id.Sha1 ~pack ids))
  in
  [
    case "a REF_DELTA base in the same pack is used" (fun () ->
        let _, nodes =
          in_pack "s"
            [
              O.Ref_delta (base_id, delta_of base target); O.Whole (O.Blob, base);
            ]
            [ target_id; base_id ]
        in
        check "the same pack" (held O.Blob target)
          (finder (M.create nodes) target_id));
    case "a REF_DELTA base whose entry gives another object gives nothing"
      (fun () ->
        let _, nodes =
          in_pack "s"
            [
              O.Whole (O.Blob, "not the base");
              O.Ref_delta (base_id, delta_of base target);
            ]
            [ base_id; target_id ]
        in
        check "the base entry"
          (not_held
             ~damage:[ damage ~offset:12 (pack_pathname "s") Store.Wrong_id ]
             ())
          (finder (M.create nodes) target_id));
    case "a REF_DELTA that names its own id is a cycle" (fun () ->
        let _, nodes =
          in_pack "s"
            [ O.Ref_delta (target_id, delta_of target target) ]
            [ target_id ]
        in
        check "itself"
          (not_held
             ~damage:[ damage ~offset:12 (pack_pathname "s") Store.Delta_cycle ]
             ())
          (finder (M.create nodes) target_id));
    case "two REF_DELTA entries that name each other are a cycle" (fun () ->
        let pack, nodes =
          in_pack "c"
            [
              O.Ref_delta (base_id, delta_of base target);
              O.Ref_delta (target_id, delta_of target base);
            ]
            [ target_id; base_id ]
        in
        check "a cycle of two"
          (not_held
             ~damage:
               [
                 damage ~offset:(nth_offset pack 1) (pack_pathname "c")
                   Store.Delta_cycle;
               ]
             ())
          (finder (M.create nodes) target_id));
    case "an OFS_DELTA and a REF_DELTA that lead to each other are a cycle"
      (fun () ->
        let pack, nodes =
          in_pack "c"
            [
              O.Ref_delta (target_id, delta_of target base);
              O.Ofs_delta (0, delta_of base target);
            ]
            [ base_id; target_id ]
        in
        check "a cycle of two kinds"
          (not_held
             ~damage:[ damage ~offset:12 (pack_pathname "c") Store.Delta_cycle ]
             ())
          (finder (M.create nodes) target_id);
        ignore pack);
    case "a cycle in a pack does not keep an object of another place" (fun () ->
        let _, nodes =
          in_pack "s"
            [ O.Ref_delta (target_id, delta_of target target) ]
            [ target_id ]
        in
        let _, node = loose ~db:"/a/objects" O.Blob target in
        check "held from the alternate"
          (held
             ~damage:[ damage ~offset:12 (pack_pathname "s") Store.Delta_cycle ]
             O.Blob target)
          (finder
             (M.create
                ((db ^ "/info/alternates", M.File "/a/objects\n")
                :: node :: nodes))
             target_id));
    case "max_deltas counts the deltas of a base that an id names" (fun () ->
        let middle = base ^ "m" in
        let middle_id = O.id Id.Sha1 O.Blob middle in
        let _, nodes =
          in_pack "a"
            [
              O.Whole (O.Blob, base);
              O.Ofs_delta (0, delta_of base middle);
              O.Ref_delta (middle_id, delta_of middle target);
            ]
            [ base_id; middle_id; target_id ]
        in
        let deltas n = { limits with max_deltas = n } in
        check "2 deltas" (held O.Blob target)
          (finder ~limits:(deltas 2) (M.create nodes) target_id);
        check "1 delta" (Error Store.Too_many_deltas)
          (finder ~limits:(deltas 1) (M.create nodes) target_id));
  ]

let entry_damage_tests =
  let content = "the content\n" in
  let x = O.id Id.Sha1 O.Blob content in
  let n = String.length content in
  let base = "base bytes" in
  let base_entry = O.Whole (O.Blob, base) in
  let damaged label ?(entry = 0) entries problem =
    case ("an entry of a pack gives nothing: " ^ label) (fun () ->
        let ids =
          List.mapi
            (fun i _ ->
              if i = entry then x else O.hash Id.Sha1 (string_of_int i))
            entries
        in
        let pack = O.pack Id.Sha1 entries in
        check label
          (not_held
             ~damage:
               [
                 damage ~offset:(nth_offset pack entry) (pack_pathname "e")
                   problem;
               ]
             ())
          (finder
             (M.create (pack_nodes "e" pack (O.index_v2 Id.Sha1 ~pack ids)))
             x))
  in
  let on_base label instructions problem =
    damaged label ~entry:1
      [
        base_entry;
        O.Ofs_delta (0, O.delta ~base_size:10 ~result_size:n instructions);
      ]
      problem
  in
  [
    damaged "the type 0"
      [ O.Header_and (0, n, O.zlib content) ]
      Store.Malformed_entry_header;
    damaged "the type 5"
      [ O.Header_and (5, n, O.zlib content) ]
      Store.Malformed_entry_header;
    damaged "a size that does not end before the trailer"
      [ O.Raw_entry "\xb3\xff\xff" ]
      Store.Malformed_entry_header;
    damaged "an OFS_DELTA that names itself"
      [ O.Ofs_delta_distance (0, delta_of content content) ]
      Store.Malformed_entry_header;
    damaged "an OFS_DELTA that leads into the header of the pack"
      [ O.Ofs_delta_distance (1, delta_of content content) ]
      Store.Malformed_entry_header;
    damaged "an OFS_DELTA that leads before the pack"
      [ O.Ofs_delta_distance (13, delta_of content content) ]
      Store.Malformed_entry_header;
    damaged "an OFS_DELTA offset that does not end"
      [ O.Header_and (6, 3, "\xff\xff") ]
      Store.Malformed_entry_header;
    damaged "data that is not zlib"
      [ O.Header_and (3, n, "not zlib at all") ]
      Store.Not_zlib;
    damaged "a stream that runs into the trailer"
      [ O.Header_and (3, n, String.sub (O.zlib content) 0 4) ]
      Store.Not_zlib;
    damaged "a stream that inflates to more bytes"
      [ O.Header_and (3, n - 1, O.zlib content) ]
      Store.Size_differs;
    damaged "a stream that inflates to fewer bytes"
      [ O.Header_and (3, n + 1, O.zlib content) ]
      Store.Size_differs;
    damaged "an object of another id"
      [ O.Whole (O.Blob, "other") ]
      Store.Wrong_id;
    damaged "an object of another kind"
      [ O.Whole (O.Commit, content) ]
      Store.Wrong_id;
    damaged "delta data that is cut" ~entry:1
      [ base_entry; O.Ofs_delta (0, "\x0a") ]
      (Store.Malformed_delta Truncated);
    damaged "delta data with another base size" ~entry:1
      [
        base_entry;
        O.Ofs_delta (0, O.delta ~base_size:3 ~result_size:n [ O.Insert content ]);
      ]
      (Store.Malformed_delta Base_size_differs);
    on_base "delta data that copies outside the base"
      [ O.Copy (5, 12) ]
      (Store.Malformed_delta Copy_outside_base);
    on_base "delta data with a reserved instruction"
      [ O.Raw_instruction "\x00" ]
      (Store.Malformed_delta Reserved_instruction);
    on_base "delta data that gives fewer bytes" [ O.Insert "x" ]
      (Store.Malformed_delta Result_size_differs);
    damaged "a delta whose result has another id" ~entry:1
      [ base_entry; O.Ofs_delta (0, delta_of base "another result") ]
      Store.Wrong_id;
    case "an OFS_DELTA to the first entry of the pack rebuilds the object"
      (fun () ->
        let pack =
          O.pack Id.Sha1 [ base_entry; O.Ofs_delta (0, delta_of base content) ]
        in
        check "rebuilt" (held O.Blob content)
          (finder
             (M.create
                (pack_nodes "e" pack
                   (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob base; x ])))
             x));
  ]

let set_byte text at byte =
  String.mapi (fun i c -> if i = at then Char.chr byte else c) text

let replace text at bytes =
  String.sub text 0 at ^ bytes
  ^ String.sub text
      (at + String.length bytes)
      (String.length text - at - String.length bytes)

let index_damage_tests =
  let objects = objects_of 4 in
  let entries = List.map (fun (k, c) -> O.Whole (k, c)) objects in
  let pack = O.pack Id.Sha1 entries in
  let ids = List.map (fun (k, c) -> O.id Id.Sha1 k c) objects in
  let sorted = List.sort String.compare ids in
  let x = List.hd sorted in
  let kind, content = List.assoc x (List.combine ids objects) in
  let v1 = O.index_v1 Id.Sha1 ~pack ids and v2 = O.index_v2 Id.Sha1 ~pack ids in
  let try_index label index problem =
    case ("an index gives nothing: " ^ label) (fun () ->
        check label
          (not_held ~damage:[ damage (index_pathname "i") problem ] ())
          (finder (M.create (pack_nodes "i" pack index)) x))
  in
  let try_pack label bytes =
    case ("a pack gives nothing: " ^ label) (fun () ->
        check label
          (not_held
             ~damage:
               [ damage (pack_pathname "i") Store.Pack_does_not_match_index ]
             ())
          (finder
             (M.create
                [
                  (pack_pathname "i", M.File bytes);
                  (index_pathname "i", M.File v2);
                ])
             x))
  in
  let v2_offsets = 8 + 1024 + (20 * 4) + (4 * 4) in
  [
    case "the undamaged index and pack give the object" (fun () ->
        List.iter
          (fun index ->
            check "undamaged" (held kind content)
              (finder (M.create (pack_nodes "i" pack index)) x))
          [ v1; v2 ]);
    try_index "an empty index v1" "" Store.Malformed_index;
    try_index "an index v1 that is cut"
      (String.sub v1 0 (String.length v1 - 1))
      Store.Malformed_index;
    try_index "an index v1 with a byte more" (v1 ^ "\000") Store.Malformed_index;
    try_index "an index v2 that is cut"
      (String.sub v2 0 (String.length v2 - 1))
      Store.Malformed_index;
    try_index "an index v2 of the version 3"
      (replace v2 4 (O.be32 3))
      Store.Malformed_index;
    try_index "an index v1 whose fan-out falls"
      (replace v1 (4 * 200) (O.be32 1000))
      Store.Malformed_index;
    try_index "an index v2 whose fan-out falls"
      (replace v2 (8 + (4 * 200)) (O.be32 1000))
      Store.Malformed_index;
    try_index "an index v1 whose last fan-out entry is not its count"
      (replace v1 (4 * 255) (O.be32 5))
      Store.Malformed_index;
    try_index "an index v2 whose last fan-out entry is not its count"
      (replace v2 (8 + (4 * 255)) (O.be32 3))
      Store.Malformed_index;
    try_index "an index v2 with an offset after the data of the pack"
      (replace v2 v2_offsets (O.be32 (String.length pack.bytes - 20)))
      Store.Malformed_index;
    try_index "an index v2 with an offset in the header of the pack"
      (replace v2 v2_offsets (O.be32 11))
      Store.Malformed_index;
    try_index "an index v1 with an offset in the header of the pack"
      (replace v1 1024 (O.be32 0))
      Store.Malformed_index;
    try_index "an index v2 with a large offset and no table of large offsets"
      (replace v2 v2_offsets (O.be32 0x80000000))
      Store.Malformed_index;
    try_pack "a pack that does not start with PACK"
      (replace pack.bytes 0 "KCAP");
    try_pack "a pack of the version 4" (replace pack.bytes 4 (O.be32 4));
    try_pack "a pack of the version 1" (replace pack.bytes 4 (O.be32 1));
    try_pack "a pack with another number of objects"
      (replace pack.bytes 8 (O.be32 5));
    try_pack "a pack whose trailer is not the copy in the index"
      (let last = String.length pack.bytes - 1 in
       set_byte pack.bytes last (Char.code pack.bytes.[last] lxor 1));
    try_pack "an empty pack" "";
    case "an index whose names are out of order gives no wrong object"
      (fun () ->
        let shuffled =
          O.index_entries_v2 Id.Sha1 ~pack_checksum:pack.checksum
            (List.rev
               (List.map2
                  (fun id (offset, crc) -> (id, crc, offset))
                  ids
                  (List.combine pack.offsets pack.crcs)))
        in
        let find = finder (M.create (pack_nodes "i" pack shuffled)) in
        List.iter2
          (fun raw (kind, content) ->
            match find raw with
            | Ok { held = Some obj; _ } ->
                check "the right object" (held kind content)
                  (Ok { Store.held = Some obj; damage = [] })
            | Ok { held = None; damage } ->
                List.iter
                  (fun d ->
                    Alcotest.(check string)
                      "only the index"
                      (index_pathname "i" ^ ": malformed index")
                      (damage_text d))
                  damage
            | Error failure -> Alcotest.fail (failure_text failure))
          ids objects);
  ]

let wrong_at pathname = (pathname, M.File (O.loose O.Blob "not this one"))

let order_tests =
  let content = "the object\n" in
  let x = O.id Id.Sha1 O.Blob content in
  let wrong_pack name =
    let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, "another object") ] in
    pack_nodes name pack (O.index_v2 Id.Sha1 ~pack [ x ])
  in
  let good_pack name =
    let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, content) ] in
    pack_nodes name pack (O.index_v1 Id.Sha1 ~pack [ x ])
  in
  [
    case
      "the loose object comes first, then the packs by the names of their \
       indexes" (fun () ->
        check "the order"
          (held
             ~damage:
               [
                 damage (loose_pathname x) Store.Wrong_id;
                 damage ~offset:12 (pack_pathname "a") Store.Wrong_id;
                 damage ~offset:12 (pack_pathname "b") Store.Wrong_id;
               ]
             O.Blob content)
          (finder
             (M.create
                ((wrong_at (loose_pathname x) :: wrong_pack "b")
                @ wrong_pack "a" @ good_pack "c" @ wrong_pack "d"))
             x));
    case "the first place that gives the object ends the lookup" (fun () ->
        let _, node = loose O.Blob content in
        check "the loose object" (held O.Blob content)
          (finder (M.create ((node :: wrong_pack "a") @ good_pack "b")) x));
    case "a place that is not a pack of the database is not read" (fun () ->
        let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, content) ] in
        let index = O.index_v2 Id.Sha1 ~pack [ x ] in
        List.iter
          (fun (label, nodes) ->
            check label (not_held ()) (finder (M.create nodes) x))
          [
            ("an index with no pack", [ (index_pathname "a", M.File index) ]);
            ("a pack with no index", [ (pack_pathname "a", M.File pack.bytes) ]);
            ( "a name that does not start with pack-",
              [
                (db ^ "/pack/other.idx", M.File index);
                (db ^ "/pack/other.pack", M.File pack.bytes);
              ] );
            ( "a pack in a folder below the folder pack",
              [
                (db ^ "/pack/sub/pack-a.idx", M.File index);
                (db ^ "/pack/sub/pack-a.pack", M.File pack.bytes);
              ] );
            ( "a pack in the folder objects",
              [
                (db ^ "/pack-a.idx", M.File index);
                (db ^ "/pack-a.pack", M.File pack.bytes);
              ] );
            ("a file named pack", [ (db ^ "/pack", M.File "x") ]);
            ( "a loose object at another pathname",
              [ (db ^ "/" ^ O.hex x, M.File (O.loose O.Blob content)) ] );
          ]);
  ]

let alternates ?(db = db) text = (db ^ "/info/alternates", M.File text)

(* @verifies changes#{give-commit-parents=v1, give-message-texts=v1, give-commit-files=v1, give-commit-file-at-path=v1, read-only-repository-files=v1}
   @cites changes#commit=v1
   By the term `commit`, the object databases of a git repository are the
   folder `objects` of its git folder and, in turn, each folder that a file
   `info/alternates` names. The cases check absolute and relative paths,
   transitive `info/alternates` files, symbolic links, non-folders, cycles,
   search order, and folder deduplication. A lookup that misses a named object
   database or follows an invalid line fails the test. *)
let alternate_tests =
  let content = "in an alternate\n" in
  let x = O.id Id.Sha1 O.Blob content in
  let at db = snd (loose ~db O.Blob content) in
  let wrong db = wrong_at (loose_pathname ~db x) in
  [
    case "an object in an object database that an alternates line names is held"
      (fun () ->
        List.iter
          (fun (label, nodes) ->
            check label (held O.Blob content) (finder (M.create nodes) x))
          [
            ("absolute", [ alternates "/a/objects\n"; at "/a/objects" ]);
            ("relative", [ alternates "../../a/objects\n"; at "/a/objects" ]);
            ( "a last line with no line feed",
              [ alternates "/b\n/a/objects"; at "/a/objects" ] );
            ( "the second line",
              [ alternates "/b\n/a/objects\n"; at "/a/objects" ] );
            ( "in turn",
              [
                alternates "/a\n";
                alternates ~db:"/a" "/b\n";
                alternates ~db:"/b" "../c\n";
                at "/c";
              ] );
            ( "through a link",
              [
                alternates "/l\n"; ("/l", M.Link "/a/objects"); at "/a/objects";
              ] );
            ("a line that starts with #", [ alternates "#x\n"; at (db ^ "/#x") ]);
            ( "a line in double quotes",
              [ alternates "\"q\"\n"; at (db ^ "/\"q\"") ] );
            ( "a line that ends with a carriage return",
              [ alternates "/a\r\n"; at "/a\r" ] );
            ("a line with a space", [ alternates " /a\n"; at (db ^ "/ /a") ]);
          ]);
    case "an alternates line is a pathname as it is written" (fun () ->
        List.iter
          (fun (label, nodes) ->
            check label (not_held ()) (finder (M.create nodes) x))
          [
            ("a comment is a pathname", [ alternates "#/a\n"; at "/a" ]);
            ( "quotes are part of the pathname",
              [ alternates "\"/a\"\n"; at "/a" ] );
            ("a carriage return is part of it", [ alternates "/a\r\n"; at "/a" ]);
            ("a leading space is part of it", [ alternates " /a\n"; at "/a" ]);
            ( "relative to the object database, not to the git folder",
              [ alternates "../a\n"; at "/a" ] );
          ]);
    case "a line that names no folder names no object database" (fun () ->
        List.iter
          (fun (label, nodes) ->
            check label (not_held ()) (finder (M.create nodes) x))
          [
            ("a missing folder", [ alternates "/missing\n" ]);
            ("a file", [ alternates "/file\n"; ("/file", M.File "x") ]);
            ("a FIFO", [ alternates "/fifo\n"; ("/fifo", M.Fifo) ]);
            ("a dangling link", [ alternates "/l\n"; ("/l", M.Link "/gone") ]);
            ("an empty file", [ alternates "" ]);
            ("empty lines", [ alternates "\n\n\n" ]);
          ]);
    case "a cycle of two or three object databases is no failure" (fun () ->
        let two = [ alternates "/a\n"; alternates ~db:"/a" "/g/objects\n" ] in
        let three =
          [
            alternates "/a\n";
            alternates ~db:"/a" "/b\n";
            alternates ~db:"/b" "/g/objects\n";
          ]
        in
        List.iter
          (fun (label, cycle, places) ->
            List.iter
              (fun place ->
                check
                  (Printf.sprintf "%s, in %s" label place)
                  (held O.Blob content)
                  (finder (M.create (at place :: cycle)) x))
              places;
            check (label ^ ", in none") (not_held ())
              (finder (M.create cycle) x))
          [ ("two", two, [ db; "/a" ]); ("three", three, [ db; "/a"; "/b" ]) ]);
    case
      "the object databases are in the order of the databases and of the lines"
      (fun () ->
        check "the order"
          (not_held
             ~damage:
               [
                 damage (loose_pathname x) Store.Wrong_id;
                 damage (loose_pathname ~db:"/a" x) Store.Wrong_id;
                 damage (loose_pathname ~db:"/b" x) Store.Wrong_id;
                 damage (loose_pathname ~db:"/c" x) Store.Wrong_id;
                 damage (loose_pathname ~db:"/d" x) Store.Wrong_id;
               ]
             ())
          (finder
             (M.create
                [
                  alternates "/a\n/b\n";
                  alternates ~db:"/a" "/c\n/b\n";
                  alternates ~db:"/b" "/d\n/a\n";
                  wrong db;
                  wrong "/a";
                  wrong "/b";
                  wrong "/c";
                  wrong "/d";
                ])
             x));
    case "two pathnames of one folder are one object database" (fun () ->
        List.iter
          (fun (label, lines) ->
            check label
              (not_held ~damage:[ damage (loose_pathname x) Store.Wrong_id ] ())
              (finder
                 (M.create
                    [ alternates lines; ("/l", M.Link "/g/objects"); wrong db ])
                 x))
          [
            ("an empty line", "\n");
            ("a dot", ".\n");
            ("a link", "/l\n");
            ("the same pathname", "/g/objects\n");
            ("a pathname with ..", "../objects\n");
          ];
        check "a link to an alternate"
          (not_held
             ~damage:[ damage (loose_pathname ~db:"/a" x) Store.Wrong_id ]
             ())
          (finder
             (M.create
                [ alternates "/a\n/l\n/a/\n"; ("/l", M.Link "/a"); wrong "/a" ])
             x));
  ]

let raises_invalid name f =
  match f () with
  | exception Invalid_argument _ -> ()
  | _ -> Alcotest.failf "%s: no Invalid_argument" name

let limit_tests =
  let content = String.make 100 'c' in
  let x = O.id Id.Sha1 O.Blob content in
  let with_limits l nodes = finder ~limits:l (M.create nodes) x in
  let size n = { limits with max_content_size = n } in
  [
    case "a negative limit raises Invalid_argument" (fun () ->
        let module R = Files.Make ((val M.system (M.create []))) in
        let module S = Store.Make (R) in
        List.iter
          (fun (name, l) ->
            raises_invalid name (fun () -> S.create l Id.Sha1 ~git_folder:"/g"))
          [
            ("max_content_size", { limits with max_content_size = -1 });
            ("max_deltas", { limits with max_deltas = -1 });
            ("max_databases", { limits with max_databases = -1 });
            ("max_packs", { limits with max_packs = -1 });
            ("max_alternates_size", { limits with max_alternates_size = -1 });
          ]);
    case "an id of the other object format raises Invalid_argument" (fun () ->
        let module R = Files.Make ((val M.system (M.create []))) in
        let module S = Store.Make (R) in
        let sha1 = S.create limits Id.Sha1 ~git_folder:"/g" in
        let sha256 = S.create limits Id.Sha256 ~git_folder:"/g" in
        raises_invalid "sha256 id" (fun () ->
            S.find sha1 (oid Id.Sha256 (String.make 32 'a')));
        raises_invalid "sha1 id" (fun () ->
            S.find sha256 (oid Id.Sha1 (String.make 20 'a'))));
    case
      "a loose object of the maximum size is held, and one byte more is too \
       large" (fun () ->
        let _, node = loose O.Blob content in
        check "at the maximum" (held O.Blob content)
          (with_limits (size 100) [ node ]);
        check "above"
          (Error
             (Store.Too_large { pathname = loose_pathname x; offset = None }))
          (with_limits (size 99) [ node ]));
    case
      "a packed object of the maximum size is held, and one byte more is too \
       large" (fun () ->
        let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, content) ] in
        let nodes = pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack [ x ]) in
        check "at the maximum" (held O.Blob content)
          (with_limits (size 100) nodes);
        check "above"
          (Error
             (Store.Too_large { pathname = pack_pathname "p"; offset = Some 12 }))
          (with_limits (size 99) nodes));
    case "a size above the maximum stops before the bytes after the header"
      (fun () ->
        let loose_bytes =
          let s = O.zlib_stored "blob 1000\000" in
          String.sub s 0 (String.length s - 4)
        in
        check "loose"
          (Error
             (Store.Too_large { pathname = loose_pathname x; offset = None }))
          (with_limits (size 999) [ (loose_pathname x, M.File loose_bytes) ]);
        let pack = O.pack Id.Sha1 [ O.Header_and (3, 1000, "no zlib here") ] in
        check "packed"
          (Error
             (Store.Too_large { pathname = pack_pathname "p"; offset = Some 12 }))
          (with_limits (size 999)
             (pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack [ x ]))));
    case "a size above the longest string is too large with no maximum"
      (fun () ->
        let huge = Sys.max_string_length + 1 in
        let loose_bytes =
          let s = O.zlib_stored (Printf.sprintf "blob %d\000" huge) in
          String.sub s 0 (String.length s - 4)
        in
        check "loose"
          (Error
             (Store.Too_large { pathname = loose_pathname x; offset = None }))
          (with_limits (size max_int)
             [ (loose_pathname x, M.File loose_bytes) ]);
        let pack = O.pack Id.Sha1 [ O.Header_and (3, huge, "no zlib here") ] in
        check "packed"
          (Error
             (Store.Too_large { pathname = pack_pathname "p"; offset = Some 12 }))
          (with_limits (size max_int)
             (pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack [ x ]))));
    case "a delta whose result or delta data is above the maximum is too large"
      (fun () ->
        let base = String.make 50 'c' in
        let delta = delta_of base content in
        let pack =
          O.pack Id.Sha1 [ O.Whole (O.Blob, base); O.Ofs_delta (0, delta) ]
        in
        let second = nth_offset pack 1 in
        let nodes =
          pack_nodes "p" pack
            (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob base; x ])
        in
        check "at the maximum" (held O.Blob content)
          (with_limits (size 100) nodes);
        check "the result above"
          (Error
             (Store.Too_large
                { pathname = pack_pathname "p"; offset = Some second }))
          (with_limits (size 99) nodes);
        let long_delta =
          O.delta ~base_size:50 ~result_size:100
            (List.init 100 (fun _ -> O.Insert "c"))
        in
        let pack =
          O.pack Id.Sha1 [ O.Whole (O.Blob, base); O.Ofs_delta (0, long_delta) ]
        in
        let second = nth_offset pack 1 in
        check "the delta data above"
          (Error
             (Store.Too_large
                { pathname = pack_pathname "p"; offset = Some second }))
          (with_limits (size 199)
             (pack_nodes "p" pack
                (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob base; x ]))));
    case "a chain of max_deltas delta entries is followed, and one more is not"
      (fun () ->
        let versions = List.init 6 (fun i -> content ^ String.make i 'v') in
        let last = List.nth versions 5 in
        let id = O.id Id.Sha1 O.Blob last in
        let entries =
          List.mapi
            (fun i c ->
              if i = 0 then O.Whole (O.Blob, c)
              else O.Ofs_delta (i - 1, delta_of (List.nth versions (i - 1)) c))
            versions
        in
        let pack = O.pack Id.Sha1 entries in
        let nodes =
          pack_nodes "p" pack
            (O.index_v2 Id.Sha1 ~pack (List.map (O.id Id.Sha1 O.Blob) versions))
        in
        let deltas n = { limits with max_deltas = n } in
        check "5 deltas" (held O.Blob last)
          (finder ~limits:(deltas 5) (M.create nodes) id);
        check "4 deltas" (Error Store.Too_many_deltas)
          (finder ~limits:(deltas 4) (M.create nodes) id));
    case "max_deltas counts the deltas of every place that the lookup tries"
      (fun () ->
        let base = String.make 100 'b' in
        let wrong =
          O.pack Id.Sha1
            [ O.Whole (O.Blob, base); O.Ofs_delta (0, delta_of base "wrong") ]
        in
        let good =
          O.pack Id.Sha1
            [ O.Whole (O.Blob, base); O.Ofs_delta (0, delta_of base content) ]
        in
        let nodes =
          pack_nodes "a" wrong
            (O.index_v2 Id.Sha1 ~pack:wrong [ O.id Id.Sha1 O.Blob base; x ])
          @ pack_nodes "b" good
              (O.index_v2 Id.Sha1 ~pack:good [ O.id Id.Sha1 O.Blob base; x ])
        in
        let deltas n = { limits with max_deltas = n } in
        check "2 deltas"
          (held
             ~damage:
               [
                 damage ~offset:(nth_offset wrong 1) (pack_pathname "a")
                   Store.Wrong_id;
               ]
             O.Blob content)
          (finder ~limits:(deltas 2) (M.create nodes) x);
        check "1 delta" (Error Store.Too_many_deltas)
          (finder ~limits:(deltas 1) (M.create nodes) x));
    case "max_databases object databases are read, and one more is too many"
      (fun () ->
        let chain =
          [ alternates "/a\n"; alternates ~db:"/a" "/b\n"; ("/b", M.Folder) ]
        in
        let dbs n = { limits with max_databases = n } in
        let _, node = loose ~db:"/b" O.Blob content in
        check "3, held" (held O.Blob content)
          (finder ~limits:(dbs 3) (M.create (node :: chain)) x);
        check "3, not held" (not_held ())
          (finder ~limits:(dbs 3) (M.create chain) x);
        check "2" (Error Store.Too_many_databases)
          (finder ~limits:(dbs 2) (M.create chain) x);
        check "a cycle of 3 with a limit of 3" (not_held ())
          (finder ~limits:(dbs 3)
             (M.create (alternates ~db:"/b" "/g/objects\n/a\n" :: chain))
             x));
    case "max_packs packs are read, and one more is too many" (fun () ->
        let packs =
          List.concat_map
            (fun name ->
              let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, name) ] in
              pack_nodes name pack
                (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob name ]))
            [ "a"; "b"; "c" ]
        in
        let packs_limit n = { limits with max_packs = n } in
        check "3" (not_held ())
          (finder ~limits:(packs_limit 3) (M.create packs) x);
        check "2"
          (Error (Store.Too_many_packs (db ^ "/pack")))
          (finder ~limits:(packs_limit 2) (M.create packs) x));
    case "a stop at a limit is kept, with no new read of what it read"
      (fun () ->
        let earlier = "in /a" in
        let y = O.id Id.Sha1 O.Blob earlier in
        let calls system p =
          List.length
            (List.filter
               (function
                 | M.Open_file q | M.Open_folder q | M.Listing q -> q = p
                 | _ -> false)
               (M.calls system))
        in
        let _, node = loose ~db:"/a" O.Blob earlier in
        let system =
          M.create
            [
              alternates "/a\n";
              alternates ~db:"/a" "/b\n";
              ("/b", M.Folder);
              node;
            ]
        in
        let find = finder ~limits:{ limits with max_databases = 2 } system in
        check "databases, 1" (Error Store.Too_many_databases) (find x);
        check "databases, 2" (Error Store.Too_many_databases) (find x);
        check "databases, the object before the limit" (held O.Blob earlier)
          (find y);
        List.iter
          (fun p -> Alcotest.(check int) p 1 (calls system p))
          [ "/b"; "/a/info/alternates" ];
        let packs =
          List.concat_map
            (fun name ->
              let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, name) ] in
              pack_nodes name pack
                (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob name ]))
            [ "a"; "b"; "c" ]
        in
        let _, node = loose O.Blob earlier in
        let system = M.create (node :: packs) in
        let find = finder ~limits:{ limits with max_packs = 2 } system in
        let full = Error (Store.Too_many_packs (db ^ "/pack")) in
        check "packs, 1" full (find x);
        check "packs, 2" full (find x);
        check "packs, the loose object before the limit" (held O.Blob earlier)
          (find y);
        Alcotest.(check int)
          "listings" 1
          (List.length
             (List.filter
                (function M.Listing q -> q = db ^ "/pack" | _ -> false)
                (M.calls system))));
    case
      "an alternates file of the maximum size is read, and one byte more is a \
       failure" (fun () ->
        let _, node = loose ~db:"/a" O.Blob content in
        let nodes = [ alternates "/a\n"; node ] in
        let size n = { limits with max_alternates_size = n } in
        check "3" (held O.Blob content)
          (finder ~limits:(size 3) (M.create nodes) x);
        check "2"
          (Error
             (Store.Unread
                { pathname = db ^ "/info/alternates"; failure = Too_large }))
          (finder ~limits:(size 2) (M.create nodes) x));
  ]

let only_listed calls allowed =
  List.filter
    (fun call ->
      let pathname = M.pathname_of_call call in
      not
        (List.exists
           (fun prefix -> String.starts_with ~prefix pathname)
           allowed))
    calls

(* @verifies changes#read-only-repository-files=v1
   The system in memory records every call of the reader of repository files.
   Beside the object databases it holds the object database of a remote of a
   partial clone, at /remote, which holds the object. The store makes no fetch,
   so a file of that remote is no source that the list of the requirement
   allows, and a call on a pathname under /remote fails the test. The system
   also holds replacement refs, grafts, http-alternates, a file shallow, and
   the files of packs that the design does not name; by the promise of the
   interface of the store that it reads only the files of the places, the
   files info/alternates, and the folders of the object databases, a call on
   one of them, and a lookup that gives the object of the remote, also fail
   the test. *)
let reads_tests =
  let content = "content\n" in
  let x = O.id Id.Sha1 O.Blob content in
  let other = O.id Id.Sha1 O.Blob "other" in
  let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, "packed") ] in
  let planted =
    [
      ("/g/HEAD", M.File "ref: refs/heads/main\n");
      ( "/g/config",
        M.File "[remote \"origin\"]\n\turl = /remote\n\tpromisor = true\n" );
      ("/g/refs/replace/" ^ O.hex x, M.File (O.hex other ^ "\n"));
      ("/g/info/grafts", M.File (O.hex x ^ "\n"));
      ("/g/shallow", M.File (O.hex x ^ "\n"));
      (db ^ "/info/grafts", M.File (O.hex x ^ "\n"));
      (db ^ "/info/http-alternates", M.File "/remote/objects\n");
      (db ^ "/info/packs", M.File "P pack-r.pack\n");
      (db ^ "/info/commit-graph", M.File "CGPH");
      (db ^ "/pack/multi-pack-index", M.File "MIDX");
      (db ^ "/pack/pack-p.bitmap", M.File "BITM");
      (db ^ "/pack/pack-p.rev", M.File "RIDX");
      (db ^ "/pack/pack-p.promisor", M.File "");
      (db ^ "/pack/pack-p.keep", M.File "");
      (db ^ "/pack/pack-p.mtimes", M.File "MTME");
      snd (loose ~db:"/remote/objects" O.Blob content);
    ]
    @ pack_nodes "p" pack
        (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob "packed" ])
  in
  [
    case
      "a lookup reads only the files of the places, of the alternates, and the \
       folders of the databases" (fun () ->
        let system = M.create planted in
        let find = finder system in
        check "not held" (not_held ()) (find x);
        check "packed" (held O.Blob "packed")
          (find (O.id Id.Sha1 O.Blob "packed"));
        let allowed =
          [
            loose_pathname x;
            loose_pathname (O.id Id.Sha1 O.Blob "packed");
            db ^ "/info/alternates";
            pack_pathname "p";
            index_pathname "p";
          ]
        in
        let folders = [ db; db ^ "/pack" ] in
        let unexpected =
          List.filter
            (fun call ->
              let p = M.pathname_of_call call in
              not
                (List.mem p allowed || List.mem p folders
                || List.exists (fun f -> p = f ^ "/" || p = f ^ "/.") folders))
            (M.calls system)
        in
        Alcotest.(check (list string))
          "calls on other pathnames" []
          (List.map M.pathname_of_call unexpected));
    case "a partial clone does not take an object from its remote" (fun () ->
        let system =
          M.create ((db ^ "/info/alternates", M.File "") :: planted)
        in
        check "not held" (not_held ()) (finder system x);
        Alcotest.(check (list string))
          "calls under the remote" []
          (List.map M.pathname_of_call
             (List.filter
                (fun call ->
                  String.starts_with ~prefix:"/remote" (M.pathname_of_call call))
                (M.calls system))));
    case "a store reads each alternates file and each listing once" (fun () ->
        let system =
          M.create
            (alternates "/a\n" :: alternates ~db:"/a" "/b\n"
            :: (pack_nodes ~db:"/a" "q" pack
                  (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob "packed" ])
               @ planted))
        in
        let find = finder system in
        for _ = 1 to 3 do
          ignore (find x);
          ignore (find other)
        done;
        let count p =
          List.length
            (List.filter
               (function M.Open_file q | M.Listing q -> q = p | _ -> false)
               (M.calls system))
        in
        List.iter
          (fun p -> Alcotest.(check int) p 1 (count p))
          [
            db ^ "/info/alternates";
            "/a/info/alternates";
            db ^ "/pack";
            "/a/pack";
          ]);
    case "a store reads the identity of each folder of a database once"
      (fun () ->
        let system =
          M.create (alternates "/a\n" :: alternates ~db:"/a" "/b\n" :: planted)
        in
        let find = finder system in
        for _ = 1 to 3 do
          ignore (find x)
        done;
        List.iter
          (fun p ->
            Alcotest.(check int)
              p 1
              (List.length
                 (List.filter
                    (function M.Open_folder q -> q = p | _ -> false)
                    (M.calls system))))
          [ db; "/a" ]);
    case "a failure inside an alternates file repeats only the read that failed"
      (fun () ->
        let content = "in c" in
        let y = O.id Id.Sha1 O.Blob content in
        let system =
          M.create
            [
              alternates "/a\n/b\n/c\n";
              ("/a", M.Folder);
              ("/b", M.Folder);
              ("/c", M.Link "/c");
            ]
        in
        let find = finder system in
        check "the first lookup"
          (Error (Store.Unread { pathname = "/c"; failure = Cannot_read }))
          (find y);
        M.remove system "/c";
        let path, node = snd (loose ~db:"/c" O.Blob content) in
        M.add system path node;
        check "the second lookup" (held O.Blob content) (find y);
        let count p =
          List.length
            (List.filter
               (function
                 | M.Open_file q | M.Open_folder q -> q = p | _ -> false)
               (M.calls system))
        in
        List.iter
          (fun p -> Alcotest.(check int) p 1 (count p))
          [ db ^ "/info/alternates"; "/a"; "/b" ]);
    case "a read that failed is made again at a later lookup" (fun () ->
        let content = "in a" in
        let y = O.id Id.Sha1 O.Blob content in
        let system = M.create [ (db ^ "/info/alternates", M.Fifo) ] in
        let find = finder system in
        check "the first lookup"
          (Error
             (Store.Unread
                {
                  pathname = db ^ "/info/alternates";
                  failure = Not_a_regular_file;
                }))
          (find y);
        M.remove system (db ^ "/info/alternates");
        M.add system (db ^ "/info/alternates") (M.File "/a\n");
        let path, node = snd (loose ~db:"/a" O.Blob content) |> fun n -> n in
        M.add system path node;
        check "the second lookup" (held O.Blob content) (find y));
    case "create reads no file" (fun () ->
        let system = M.create planted in
        let module R = Files.Make ((val M.system system)) in
        let module S = Store.Make (R) in
        ignore (S.create limits Id.Sha1 ~git_folder:"/g");
        Alcotest.(check int) "calls" 0 (List.length (M.calls system)));
    case "a lookup closes every file that it opens" (fun () ->
        let system = M.create planted in
        let find = finder system in
        ignore (find x);
        ignore (find (O.id Id.Sha1 O.Blob "packed"));
        Alcotest.(check int) "open" 0 (M.open_descriptors system));
  ]

let read_calls system =
  List.length
    (List.filter (function M.Read _ -> true | _ -> false) (M.calls system))

let chain_nodes length =
  let content = "sixteen bytes!!\n" in
  let delta = O.delta ~base_size:16 ~result_size:16 [ O.Copy (0, 16) ] in
  let x = O.id Id.Sha1 O.Blob content in
  let pack =
    O.pack Id.Sha1
      (O.Whole (O.Blob, content)
      :: List.init length (fun i -> O.Ofs_delta (i, delta)))
  in
  let ids =
    List.init (length + 1) (fun i ->
        if i = length then x else O.hash Id.Sha1 (Printf.sprintf "filler %d" i))
  in
  (x, pack_nodes "c" pack (O.index_v2 Id.Sha1 ~pack ids))

let cost_tests =
  [
    case "the reads of a lookup grow linearly with a delta chain" (fun () ->
        let reads length =
          let x, nodes = chain_nodes length in
          let system = M.create nodes in
          let find =
            finder ~limits:{ limits with max_deltas = length } system
          in
          ignore (find (O.id Id.Sha1 O.Blob "warm"));
          M.clear system;
          check "held" (held O.Blob "sixteen bytes!!\n") (find x);
          read_calls system
        in
        let small = reads 100 and large = reads 400 in
        Alcotest.(check bool)
          (Printf.sprintf "%d reads for 100 deltas, %d for 400" small large)
          true
          (2 * large <= 9 * small));
    case "the reads of a lookup grow linearly with the object databases"
      (fun () ->
        let reads count =
          let x = O.id Id.Sha1 O.Blob "far" in
          let nodes =
            snd (loose ~db:"/d0" O.Blob "far")
            :: alternates (Printf.sprintf "/d%d\n" count)
            :: List.init count (fun i ->
                alternates
                  ~db:(Printf.sprintf "/d%d" (i + 1))
                  (Printf.sprintf "/d%d\n" i))
          in
          let system = M.create nodes in
          let find =
            finder ~limits:{ limits with max_databases = count + 2 } system
          in
          check "held" (held O.Blob "far") (find x);
          List.length (M.calls system)
        in
        let small = reads 50 and large = reads 200 in
        Alcotest.(check bool)
          (Printf.sprintf "%d calls for 50 databases, %d for 200" small large)
          true
          (2 * large <= 9 * small));
    case "a lookup in a large pack reads few bytes of the pack and of its index"
      (fun () ->
        let count = 4096 in
        let contents =
          List.init count (fun i ->
              String.init 512 (fun j ->
                  Char.chr (((i * 31) + (j * 17)) land 255)))
          |> List.mapi (fun i c -> Printf.sprintf "%d:%s" i c)
        in
        let ids = List.map (O.id Id.Sha1 O.Blob) contents in
        let pack =
          O.pack Id.Sha1 (List.map (fun c -> O.Whole (O.Blob, c)) contents)
        in
        let system =
          M.create (pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack ids))
        in
        let find = finder system in
        ignore (find (List.nth ids 0));
        List.iter
          (fun i ->
            M.clear system;
            let raw = List.nth ids i in
            check "held" (held O.Blob (List.nth contents i)) (find raw);
            let reads p =
              List.filter
                (function M.Read (q, _, _) -> q = p | _ -> false)
                (M.calls system)
            in
            let index_reads = List.length (reads (index_pathname "p")) in
            Alcotest.(check bool)
              (Printf.sprintf "%d reads of the index, at most 3 + 12"
                 index_reads)
              true (index_reads <= 15);
            let pack_bytes =
              List.fold_left
                (fun sum -> function M.Read (_, _, n) -> sum + n | _ -> sum)
                0
                (reads (pack_pathname "p"))
            in
            Alcotest.(check bool)
              (Printf.sprintf "%d bytes of a pack of %d" pack_bytes
                 (String.length pack.bytes))
              true
              (pack_bytes <= 4 * 65536))
          [ 1; 100; 2048; 4095 ]);
    case
      "a stream that inflates to far more than its header states takes no \
       memory for it" (fun () ->
        let huge = String.make (32 * 1024 * 1024) '\000' in
        let bomb = O.zlib ~level:9 ("blob 10\000" ^ huge) in
        let x = O.id Id.Sha1 O.Blob (String.sub huge 0 10) in
        let pack_bomb = O.zlib ~level:9 huge in
        let pack = O.pack Id.Sha1 [ O.Header_and (3, 10, pack_bomb) ] in
        List.iter
          (fun (label, nodes, expected) ->
            let system = M.create nodes in
            Gc.full_major ();
            let before = Gc.allocated_bytes () in
            let result = finder system x in
            let taken = Gc.allocated_bytes () -. before in
            check label expected result;
            Alcotest.(check bool)
              (Printf.sprintf "%s: %.0f bytes taken" label taken)
              true (taken < 16_000_000.))
          [
            ( "loose",
              [ (loose_pathname x, M.File bomb) ],
              not_held
                ~damage:[ damage (loose_pathname x) Store.Size_differs ]
                () );
            ( "packed",
              pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack [ x ]),
              not_held
                ~damage:
                  [ damage ~offset:12 (pack_pathname "p") Store.Size_differs ]
                () );
          ]);
  ]

type layout = Loose | Whole_in of int | Ofs_in of int | Ref_in of int

type plan = {
  format : Id.format;
  objects : (O.kind * string * layout) list;
  versions : int * int;
  index_versions : int * int;
}

let layout_text = function
  | Loose -> "loose"
  | Whole_in p -> Printf.sprintf "whole in %d" p
  | Ofs_in p -> Printf.sprintf "ofs delta in %d" p
  | Ref_in p -> Printf.sprintf "ref delta in %d" p

let print_plan plan =
  String.concat "; "
    (List.map
       (fun (k, c, l) ->
         Printf.sprintf "%s %S %s" (O.kind_name k) c (layout_text l))
       plan.objects)

let plan_gen =
  Gen.(
    let* format = oneof_list [ Id.Sha1; Id.Sha256 ] in
    let* n = int_range 1 10 in
    let* objects =
      list_size (return n)
        (triple (oneof_list kinds)
           (string_size
              ~gen:(oneof_list [ 'a'; 'b'; '\n'; '\000' ])
              (int_range 0 120))
           (int_range 0 6))
    in
    let* versions = pair (oneof_list [ 2; 3 ]) (oneof_list [ 2; 3 ]) in
    let+ index_versions = pair (oneof_list [ 1; 2 ]) (oneof_list [ 1; 2 ]) in
    let seen = Hashtbl.create 16 in
    let objects =
      List.filter_map
        (fun (k, c, choice) ->
          let key = (k, c) in
          if Hashtbl.mem seen key then None
          else (
            Hashtbl.add seen key ();
            let earlier = Hashtbl.length seen > 1 in
            let layout =
              match choice with
              | 0 -> Loose
              | 1 | 2 -> Whole_in (choice - 1)
              | (3 | 4) when earlier -> Ofs_in (choice - 3)
              | (5 | 6) when earlier -> Ref_in (choice - 5)
              | _ -> Whole_in 0
            in
            Some (k, c, layout)))
        objects
    in
    { format; objects; versions; index_versions })

let build plan =
  let f = plan.format in
  let packs = [| []; [] |] and loose_nodes = ref [] in
  List.iteri
    (fun i (kind, content, layout) ->
      let raw = O.id f kind content in
      match layout with
      | Loose ->
          loose_nodes :=
            (loose_pathname raw, M.File (O.loose kind content)) :: !loose_nodes
      | Whole_in p ->
          packs.(p) <- packs.(p) @ [ (O.Whole (kind, content), raw) ]
      | Ofs_in p | Ref_in p -> (
          let same_kind =
            List.filteri
              (fun j (k, _, l) ->
                j < i && k = kind
                &&
                match (layout, l) with
                | Ofs_in _, (Whole_in q | Ofs_in q | Ref_in q) -> q = p
                | Ref_in _, (Whole_in q | Ofs_in q | Ref_in q) -> q = p
                | _ -> false)
              plan.objects
          in
          match List.rev same_kind with
          | [] -> packs.(p) <- packs.(p) @ [ (O.Whole (kind, content), raw) ]
          | (_, base, _) :: _ -> (
              let delta = delta_of base content in
              match layout with
              | Ofs_in _ ->
                  let base_raw = O.id f kind base in
                  let index =
                    let rec find k = function
                      | [] -> 0
                      | (_, r) :: rest ->
                          if r = base_raw then k else find (k + 1) rest
                    in
                    find 0 packs.(p)
                  in
                  packs.(p) <- packs.(p) @ [ (O.Ofs_delta (index, delta), raw) ]
              | _ ->
                  packs.(p) <-
                    packs.(p) @ [ (O.Ref_delta (O.id f kind base, delta), raw) ]
              )))
    plan.objects;
  let pack_files p name version index_version =
    if packs.(p) = [] then []
    else
      let pack = O.pack ~version f (List.map fst packs.(p)) in
      pack_nodes name pack
        (index ~version:index_version f pack (List.map snd packs.(p)))
  in
  !loose_nodes
  @ pack_files 0 "a" (fst plan.versions) (fst plan.index_versions)
  @ pack_files 1 "b" (snd plan.versions) (snd plan.index_versions)

let corrupt_gen =
  Gen.(
    let* plan = plan_gen in
    let nodes = build plan in
    let* which = int_range 0 (List.length nodes - 1) in
    let* how = int_range 0 2 in
    let* at = nat in
    let* byte = char in
    let* extra = string_size ~gen:char (int_range 1 6) in
    let nodes =
      List.mapi
        (fun i (p, node) ->
          match node with
          | M.File bytes when i = which ->
              let n = String.length bytes in
              let at = if n = 0 then 0 else at mod n in
              let bytes =
                match how with
                | 0 -> String.sub bytes 0 at
                | 1 when n > 0 -> set_byte bytes at (Char.code byte)
                | _ ->
                    String.sub bytes 0 at ^ extra ^ String.sub bytes at (n - at)
              in
              (p, M.File bytes)
          | _ -> (p, node))
        nodes
    in
    return (plan, nodes))

let generated_properties =
  [
    property ~name:"each object of a generated object database is held"
      ~print:print_plan plan_gen (fun plan ->
        let find = finder ~format:plan.format (M.create (build plan)) in
        List.for_all
          (fun (kind, content, _) ->
            find (O.id plan.format kind content) = held kind content)
          plan.objects
        && find (O.id plan.format O.Blob "no such object\n") = not_held ());
    property ~count:500
      ~name:"a damaged object database gives only the objects that it was given"
      ~print:(fun (plan, nodes) ->
        print_plan plan ^ "\nfiles: "
        ^ String.concat "; "
            (List.map
               (fun (p, node) ->
                 match node with
                 | M.File bytes -> Printf.sprintf "%s %S" p bytes
                 | _ -> p)
               nodes))
      corrupt_gen
      (fun (plan, nodes) ->
        let find = finder ~format:plan.format (M.create nodes) in
        List.for_all
          (fun (kind, content, _) ->
            match find (O.id plan.format kind content) with
            | Ok { held = Some obj; _ } ->
                obj = { Store.kind = store_kind kind; content }
            | Ok { held = None; _ } | Error _ -> true)
          plan.objects);
  ]

(* @verifies changes#{give-commit-parents=v1, give-message-texts=v1, give-commit-files=v1, give-commit-file-at-path=v1}
   @cites changes#commit=v1
   By the term `commit`, a git repository holds a git object only when a place
   gives bytes that follow gitformat-loose or gitformat-pack and hash to the
   object id from `<type> <size>\0` and the content. The cases check fixed
   object ids, prefix omission, SHA-256 hash mismatches, loose sizes with
   leading zeros or non-decimal characters, bytes after the zlib stream of a
   loose object, and `REF_DELTA` bases outside the same pack. The test fails
   when the store gives an object from a place that breaks any of these rules
   or rejects a valid object. *)
let held_tests =
  let base = String.make 200 'b' and target = String.make 200 'b' ^ "t" in
  let base_id = O.id Id.Sha1 O.Blob base
  and target_id = O.id Id.Sha1 O.Blob target in
  let delta_pack =
    O.pack Id.Sha1 [ O.Ref_delta (base_id, delta_of base target) ]
  in
  let delta_nodes ?(db = db) () =
    pack_nodes ~db "d" delta_pack
      (O.index_v2 Id.Sha1 ~pack:delta_pack [ target_id ])
  in
  let not_in_pack =
    not_held
      ~damage:
        [
          damage ~offset:12 (pack_pathname "d")
            (Store.Base_not_in_pack (oid Id.Sha1 base_id));
        ]
      ()
  in
  let x = O.id Id.Sha1 O.Blob "abc" in
  let loose_at bytes = M.create [ (loose_pathname x, M.File bytes) ] in
  let raw_of_hex format hex =
    match Id.of_hex format hex with
    | Some id -> Id.to_bytes id
    | None -> Alcotest.failf "not an id: %s" hex
  in
  [
    case "the object id is the hash of type, space, size, NUL, and content"
      (fun () ->
        let vectors =
          [
            ( "sha1 blob abc",
              Id.Sha1,
              O.Blob,
              "abc",
              "f2ba8f84ab5c1bce84a7b441cb1959cfc7093b7f" );
            ( "sha256 empty tree",
              Id.Sha256,
              O.Tree,
              "",
              "6ef19b41225c5369f1c104d45d8d85efa9b057b53b14b4b9b939dd74decc5321"
            );
          ]
        in
        List.iter
          (fun (label, format, kind, content, hex) ->
            let raw = raw_of_hex format hex in
            let loose_node =
              (loose_pathname raw, M.File (O.loose kind content))
            in
            check (label ^ ", loose") (held kind content)
              (finder ~format (M.create [ loose_node ]) raw);
            let pack = O.pack format [ O.Whole (kind, content) ] in
            check (label ^ ", packed") (held kind content)
              (finder ~format
                 (M.create
                    (pack_nodes "p" pack (O.index_v2 format ~pack [ raw ])))
                 raw);
            let unprefixed = O.hash format content in
            check
              (label ^ ", loose without prefix")
              (not_held
                 ~damage:[ damage (loose_pathname unprefixed) Store.Wrong_id ]
                 ())
              (finder ~format
                 (M.create
                    [
                      (loose_pathname unprefixed, M.File (O.loose kind content));
                    ])
                 unprefixed);
            check
              (label ^ ", packed without prefix")
              (not_held
                 ~damage:
                   [ damage ~offset:12 (pack_pathname "p") Store.Wrong_id ]
                 ())
              (finder ~format
                 (M.create
                    (pack_nodes "p" pack
                       (O.index_v2 format ~pack [ unprefixed ])))
                 unprefixed))
          vectors;
        let sha256_id = O.id Id.Sha256 O.Blob "abc" in
        check "sha256 loose wrong content"
          (not_held
             ~damage:[ damage (loose_pathname sha256_id) Store.Wrong_id ]
             ())
          (finder ~format:Id.Sha256
             (M.create
                [ (loose_pathname sha256_id, M.File (O.loose O.Blob "abd")) ])
             sha256_id);
        check "sha256 loose wrong kind"
          (not_held
             ~damage:[ damage (loose_pathname sha256_id) Store.Wrong_id ]
             ())
          (finder ~format:Id.Sha256
             (M.create
                [ (loose_pathname sha256_id, M.File (O.loose O.Tree "abc")) ])
             sha256_id);
        let bad_pack = O.pack Id.Sha256 [ O.Whole (O.Commit, "abc") ] in
        check "sha256 packed wrong kind"
          (not_held
             ~damage:[ damage ~offset:12 (pack_pathname "p") Store.Wrong_id ]
             ())
          (finder ~format:Id.Sha256
             (M.create
                (pack_nodes "p" bad_pack
                   (O.index_v2 Id.Sha256 ~pack:bad_pack [ sha256_id ])))
             sha256_id));
    case "a REF_DELTA base of another kind gives nothing" (fun () ->
        List.iter
          (fun (label, format) ->
            let b_id = O.id format O.Blob base
            and t_id = O.id format O.Blob target in
            let pack =
              O.pack format
                [
                  O.Whole (O.Commit, base);
                  O.Ref_delta (b_id, delta_of base target);
                ]
            in
            check label
              (not_held
                 ~damage:
                   [ damage ~offset:12 (pack_pathname "s") Store.Wrong_id ]
                 ())
              (finder ~format
                 (M.create
                    (pack_nodes "s" pack
                       (O.index_v2 format ~pack [ b_id; t_id ])))
                 t_id))
          both_formats);
    case "a REF_DELTA whose result has another id gives nothing" (fun () ->
        let pack =
          O.pack Id.Sha1
            [
              O.Whole (O.Blob, base);
              O.Ref_delta (base_id, delta_of base "another result");
            ]
        in
        check "wrong result"
          (not_held
             ~damage:
               [
                 damage ~offset:(nth_offset pack 1) (pack_pathname "s")
                   Store.Wrong_id;
               ]
             ())
          (finder
             (M.create
                (pack_nodes "s" pack
                   (O.index_v2 Id.Sha1 ~pack [ base_id; target_id ])))
             target_id));
    case "a REF_DELTA base in another pack is not a base" (fun () ->
        let whole = O.pack Id.Sha1 [ O.Whole (O.Blob, base) ] in
        check "another pack" not_in_pack
          (finder
             (M.create
                (delta_nodes ()
                @ pack_nodes "w" whole
                    (O.index_v2 Id.Sha1 ~pack:whole [ base_id ])))
             target_id));
    case "a REF_DELTA base that is a loose object is not a base" (fun () ->
        let _, node = loose O.Blob base in
        check "loose" not_in_pack
          (finder (M.create (node :: delta_nodes ())) target_id));
    case "a REF_DELTA base in another object database is not a base" (fun () ->
        let _, node = loose ~db:"/a/objects" O.Blob base in
        check "alternate" not_in_pack
          (finder
             (M.create (alternates "/a/objects\n" :: node :: delta_nodes ()))
             target_id));
    case
      "a REF_DELTA in an alternate does not take its base from the first \
       database" (fun () ->
        let _, node = loose O.Blob base in
        check "from the first database"
          (not_held
             ~damage:
               [
                 damage ~offset:12
                   (pack_pathname ~db:"/a/objects" "d")
                   (Store.Base_not_in_pack (oid Id.Sha1 base_id));
               ]
             ())
          (finder
             (M.create
                (alternates "/a/objects\n" :: node
                :: delta_nodes ~db:"/a/objects" ()))
             target_id));
    case
      "a REF_DELTA whose base is outside its pack does not hide a later place"
      (fun () ->
        let whole = O.pack Id.Sha1 [ O.Whole (O.Blob, base) ] in
        let _, good = loose ~db:"/a/objects" O.Blob target in
        check "held from the alternate"
          (held
             ~damage:
               [
                 damage ~offset:12 (pack_pathname "d")
                   (Store.Base_not_in_pack (oid Id.Sha1 base_id));
               ]
             O.Blob target)
          (finder
             (M.create
                ((alternates "/a/objects\n" :: good :: delta_nodes ())
                @ pack_nodes "w" whole
                    (O.index_v2 Id.Sha1 ~pack:whole [ base_id ])))
             target_id));
    case "a REF_DELTA whose base no place holds names the base" (fun () ->
        check "no base" not_in_pack
          (finder (M.create (delta_nodes ())) target_id));
    case "a loose size with a leading zero gives nothing" (fun () ->
        List.iter
          (fun (label, header) ->
            check label
              (not_held
                 ~damage:
                   [ damage (loose_pathname x) Store.Malformed_loose_header ]
                 ())
              (finder (loose_at (O.zlib (header ^ "abc"))) x))
          [ ("one zero", "blob 03\000"); ("two zeros", "blob 003\000") ];
        let own_raw = O.hash Id.Sha1 "blob 03\000abc" in
        check "at its own hash"
          (not_held
             ~damage:
               [ damage (loose_pathname own_raw) Store.Malformed_loose_header ]
             ())
          (finder
             (M.create
                [ (loose_pathname own_raw, M.File (O.zlib "blob 03\000abc")) ])
             own_raw);
        let ten = String.make 10 'a' in
        let ten_id = O.id Id.Sha1 O.Blob ten in
        check "a negative size"
          (not_held
             ~damage:[ damage (loose_pathname x) Store.Malformed_loose_header ]
             ())
          (finder (loose_at (O.zlib "blob -3\000abc")) x);
        check "an underscore in the size"
          (not_held
             ~damage:
               [ damage (loose_pathname ten_id) Store.Malformed_loose_header ]
             ())
          (finder
             (M.create
                [
                  (loose_pathname ten_id, M.File (O.zlib ("blob 1_0\000" ^ ten)));
                ])
             ten_id));
    case "the size 0 is written as one digit 0" (fun () ->
        let raw = O.id Id.Sha1 O.Blob "" in
        check "blob 00"
          (not_held
             ~damage:
               [ damage (loose_pathname raw) Store.Malformed_loose_header ]
             ())
          (finder
             (M.create [ (loose_pathname raw, M.File (O.zlib "blob 00\000")) ])
             raw));
    case "bytes after the zlib stream of a loose object give nothing" (fun () ->
        let stream = O.zlib "blob 3\000abc" in
        List.iter
          (fun (label, after) ->
            check label
              (not_held
                 ~damage:[ damage (loose_pathname x) Store.Bytes_after_stream ]
                 ())
              (finder (loose_at (stream ^ after)) x))
          [
            ("one byte", "\000");
            ("a second stream", O.zlib "more");
            ("many bytes", String.make 70_000 'z');
          ]);
    case
      "each count of bytes after the zlib stream, up to two first reads, gives \
       nothing" (fun () ->
        let stream = O.zlib "blob 3\000abc" in
        for count = 1 to 2 * 4096 do
          check (string_of_int count)
            (not_held
               ~damage:[ damage (loose_pathname x) Store.Bytes_after_stream ]
               ())
            (finder (loose_at (stream ^ String.make count 'z')) x)
        done);
  ]

let noise n =
  String.init n (fun i -> Char.chr (((i * 7919) + (i lsr 8)) land 0xff))

let random_bytes n =
  let state = Random.State.make [| n |] in
  String.init n (fun _ -> Char.chr (Random.State.int state 256))

let raw_pack ?(count = 1) body trailer =
  "PACK" ^ O.be32 2 ^ O.be32 count ^ body ^ trailer

let name byte = "\000" ^ String.make 19 (Char.chr byte)

let index_v2_words ?(large = []) ~names ~words pack_checksum =
  let fanout =
    String.concat ""
      (List.init 256 (fun n ->
           O.be32
             (List.length (List.filter (fun id -> Char.code id.[0] <= n) names))))
  in
  "\255tOc" ^ O.be32 2 ^ fanout ^ String.concat "" names
  ^ String.concat "" (List.map (fun _ -> O.be32 0) names)
  ^ String.concat "" (List.map O.be32 words)
  ^ String.concat "" large ^ pack_checksum ^ String.make 20 '\000'

let index_reads system pathname =
  List.length
    (List.filter
       (function
         | M.Read (p, _, count) -> p = pathname && count > 0 | _ -> false)
       (M.calls system))

let form_tests =
  let content = "the content\n" in
  let x = O.id Id.Sha1 O.Blob content in
  let one_pack ?large ?(version = 2) ?count entries ids =
    let pack = O.pack ?count Id.Sha1 entries in
    (pack, pack_nodes "p" pack (index ?large ~version Id.Sha1 pack ids))
  in
  let index_damaged = damage (index_pathname "p") Store.Malformed_index in
  [
    case "each limit may be 0" (fun () ->
        List.iter
          (fun limits -> ignore (finder ~limits (M.create []) x))
          [
            { limits with max_content_size = 0 };
            { limits with max_deltas = 0 };
            { limits with max_databases = 0 };
            { limits with max_packs = 0 };
            { limits with max_alternates_size = 0 };
          ]);
    case "a pack with no objects holds nothing and is not damaged" (fun () ->
        let _, nodes = one_pack [] [] in
        check "empty" (not_held ()) (finder (M.create nodes) x));
    case "a whole entry of 2048 bytes or more is held" (fun () ->
        List.iter
          (fun size ->
            let content = noise size in
            let raw = O.id Id.Sha1 O.Blob content in
            let _, nodes = one_pack [ O.Whole (O.Blob, content) ] [ raw ] in
            check (string_of_int size) (held O.Blob content)
              (finder (M.create nodes) raw))
          [ 2048; 3000; 1 lsl 18; 300_000 ]);
    case "each object of a pack with an index of version 1 is held" (fun () ->
        let contents = List.init 5 (fun i -> Printf.sprintf "object %d\n" i) in
        let ids = List.map (O.id Id.Sha1 O.Blob) contents in
        let _, nodes =
          one_pack ~version:1
            (List.map (fun c -> O.Whole (O.Blob, c)) contents)
            ids
        in
        let find = finder (M.create nodes) in
        List.iter2
          (fun raw c -> check c (held O.Blob c) (find raw))
          ids contents);
    case "an entry size with zero bits past bit 63 is its value" (fun () ->
        let header =
          Char.chr (0x80 lor (3 lsl 4) lor (String.length content land 15))
          |> String.make 1
        in
        let rest = String.make 9 '\x80' ^ "\000" in
        let _, nodes =
          one_pack [ O.Raw_entry (header ^ rest ^ O.zlib content) ] [ x ]
        in
        check "overlong" (held O.Blob content) (finder (M.create nodes) x));
    case "an entry size with bits at 2^62 and above is above the maximum"
      (fun () ->
        List.iter
          (fun rest ->
            let pack, nodes =
              one_pack [ O.Raw_entry ("\xb0" ^ rest ^ O.zlib content) ] [ x ]
            in
            check (String.escaped rest)
              (Error
                 (Store.Too_large
                    {
                      pathname = pack_pathname "p";
                      offset = Some (nth_offset pack 0);
                    }))
              (finder (M.create nodes) x))
          [
            String.make 8 '\x80' ^ "\x04";
            String.make 8 '\x80' ^ "\x7f";
            String.make 9 '\x80' ^ "\x01";
          ]);
    case "delta data of the maximum size is read" (fun () ->
        let base = "b" and result = noise 300 in
        let data = delta_of base result in
        let rid = O.id Id.Sha1 O.Blob result in
        let _, nodes =
          one_pack
            [ O.Whole (O.Blob, base); O.Ofs_delta (0, data) ]
            [ O.id Id.Sha1 O.Blob base; rid ]
        in
        Alcotest.(check bool)
          "the delta data is the largest" true
          (String.length data > String.length result);
        check "at the maximum" (held O.Blob result)
          (finder
             ~limits:{ limits with max_content_size = String.length data }
             (M.create nodes) rid));
    case "an index of version 2 whose every offset is in the large table"
      (fun () ->
        let contents = [ "one\n"; "two\n" ] in
        let ids = List.map (O.id Id.Sha1 O.Blob) contents in
        let _, nodes =
          one_pack ~large:[ 0; 1 ]
            (List.map (fun c -> O.Whole (O.Blob, c)) contents)
            ids
        in
        let find = finder (M.create nodes) in
        List.iter2
          (fun raw c -> check c (held O.Blob c) (find raw))
          ids contents);
    case "an index of version 2 of a wrong size is malformed" (fun () ->
        let pack, nodes = one_pack [ O.Whole (O.Blob, content) ] [ x ] in
        let good = O.index_v2 Id.Sha1 ~pack [ x ] in
        let n = String.length good in
        List.iter
          (fun (label, bytes) ->
            check label
              (not_held ~damage:[ index_damaged ] ())
              (finder
                 (M.create
                    (List.map
                       (fun (p, node) ->
                         if p = index_pathname "p" then (p, M.File bytes)
                         else (p, node))
                       nodes))
                 x))
          [
            ("4 bytes more", good ^ "\000\000\000\000");
            ("8 bytes less", String.sub good 0 (n - 8));
            ( "16 bytes more, above one large offset",
              good ^ String.make 16 '\000' );
          ]);
    case "a large offset slot outside the table is malformed" (fun () ->
        let entry = O.entry_header 3 (String.length content) ^ O.zlib content in
        let trailer = O.be64 12 ^ String.make 12 '\000' in
        let nodes =
          [
            (pack_pathname "p", M.File (raw_pack entry trailer));
            ( index_pathname "p",
              M.File (index_v2_words ~names:[ x ] ~words:[ 1 lsl 31 ] trailer)
            );
          ]
        in
        check "slot 0 of no large offsets"
          (not_held ~damage:[ index_damaged ] ())
          (finder (M.create nodes) x));
    case "a large offset of 2^63 or more is malformed" (fun () ->
        let entry = O.entry_header 3 (String.length content) ^ O.zlib content in
        let trailer = String.make 20 '\001' in
        let nodes =
          [
            (pack_pathname "p", M.File (raw_pack entry trailer));
            ( index_pathname "p",
              M.File
                (index_v2_words ~names:[ x ]
                   ~words:[ 1 lsl 31 ]
                   ~large:[ "\x80\000\000\000\000\000\000\x0c" ]
                   trailer) );
          ]
        in
        check "2^63 + 12"
          (not_held ~damage:[ index_damaged ] ())
          (finder (M.create nodes) x));
    case "an offset of 2^31 or more in a pack of more than 2 GiB is read"
      (fun () ->
        let entry = O.entry_header 3 (String.length content) ^ O.zlib content in
        let trailer = String.make 20 '\002' in
        List.iter
          (fun (label, at, version) ->
            let size = at + String.length entry + 4096 + 20 in
            let pack =
              M.Sparse
                ( size,
                  [
                    (0, "PACK" ^ O.be32 2 ^ O.be32 1);
                    (at, entry);
                    (size - 20, trailer);
                  ] )
            in
            let index =
              if version = 1 then
                O.index_entries_v1 Id.Sha1 ~pack_checksum:trailer [ (x, at) ]
              else
                O.index_entries_v2 Id.Sha1 ~pack_checksum:trailer [ (x, 0, at) ]
            in
            check label (held O.Blob content)
              (finder
                 (M.create
                    [
                      (pack_pathname "p", pack);
                      (index_pathname "p", M.File index);
                    ])
                 x))
          [
            ("version 1, 2^31 + 16", (1 lsl 31) + 16, 1);
            ("version 1, 2^32 - 8192", (1 lsl 32) - 8192, 1);
            ("version 2, 2^31 + 16", (1 lsl 31) + 16, 2);
            ("version 2, 2^32 + 16", (1 lsl 32) + 16, 2);
            ("version 2, 2^40 + 16", (1 lsl 40) + 16, 2);
          ]);
    case "a search reads two equal names: malformed" (fun () ->
        let names = [ name 1; name 1; name 1 ] in
        let trailer = String.make 20 '\003' in
        let nodes =
          [
            (pack_pathname "p", M.File (raw_pack ~count:3 "" trailer));
            ( index_pathname "p",
              M.File (index_v2_words ~names ~words:[ 12; 12; 12 ] trailer) );
          ]
        in
        check "after the names"
          (not_held ~damage:[ index_damaged ] ())
          (finder (M.create nodes) (name 9)));
    case "a search reads names out of the order of the index: malformed"
      (fun () ->
        List.iter
          (fun (label, bytes, target) ->
            let names = List.map name bytes in
            let trailer = String.make 20 '\003' in
            let nodes =
              [
                (pack_pathname "p", M.File (raw_pack ~count:4 "" trailer));
                ( index_pathname "p",
                  M.File
                    (index_v2_words ~names ~words:[ 12; 12; 12; 12 ] trailer) );
              ]
            in
            check label
              (not_held ~damage:[ index_damaged ] ())
              (finder (M.create nodes) (name target)))
          [
            ("above a name read before, on the left", [ 5; 6; 4; 7 ], 1);
            ("below a name read before, on the right", [ 1; 4; 3; 2 ], 9);
          ]);
    case "a search reads a name outside its fan-out entry: malformed" (fun () ->
        let trailer = String.make 20 '\003' in
        let wrong = "\005" ^ String.make 19 '\001' in
        let nodes =
          [
            (pack_pathname "p", M.File (raw_pack "" trailer));
            ( index_pathname "p",
              M.File
                (let fanout =
                   String.concat ""
                     (List.init 256 (fun n -> O.be32 (if n >= 4 then 1 else 0)))
                 in
                 "\255tOc" ^ O.be32 2 ^ fanout ^ wrong ^ O.be32 0 ^ O.be32 12
                 ^ trailer ^ String.make 20 '\000') );
          ]
        in
        check "a name of the byte 5 under the byte 4"
          (not_held ~damage:[ index_damaged ] ())
          (finder (M.create nodes) ("\004" ^ String.make 19 '\001')));
    case "a search of n names reads the index at most 3 + log2 n times"
      (fun () ->
        let n = 4096 in
        let names =
          List.sort String.compare
            (List.init n (fun i ->
                 "\000" ^ String.sub (O.hash Id.Sha1 (string_of_int i)) 0 19))
        in
        let trailer = String.make 20 '\004' in
        let system =
          M.create
            [
              ( pack_pathname "p",
                M.File
                  (raw_pack ~count:n
                     (O.entry_header 3 (String.length content) ^ O.zlib content)
                     trailer) );
              ( index_pathname "p",
                M.File
                  (index_v2_words ~names
                     ~words:(List.map (fun _ -> 12) names)
                     trailer) );
            ]
        in
        let find = finder system in
        ignore (find (List.hd names));
        let worst =
          List.fold_left
            (fun worst raw ->
              M.clear system;
              ignore (find raw);
              max worst (index_reads system (index_pathname "p")))
            0
            (("\000" ^ String.make 19 '\255')
            :: ("\000" ^ String.make 19 '\000')
            :: names)
        in
        Alcotest.(check bool)
          (Printf.sprintf "at most %d reads of an index of 4096 names" worst)
          true
          (worst <= 3 + 12));
    case "an OFS_DELTA of distance 1 has its base 1 byte before it" (fun () ->
        let pack, nodes =
          one_pack ~count:1
            [
              O.Raw_entry "\000";
              O.Ofs_delta_distance (1, delta_of content content);
            ]
            [ ""; x ]
        in
        check "the base at 12"
          (not_held
             ~damage:
               [
                 damage ~offset:(nth_offset pack 0) (pack_pathname "p")
                   Store.Malformed_entry_header;
               ]
             ())
          (finder (M.create nodes) x));
    case "a REF_DELTA whose base id ends at the trailer and has no data"
      (fun () ->
        let other = O.id Id.Sha1 O.Blob "other" in
        let pack, nodes =
          one_pack
            [
              O.Whole (O.Blob, "other");
              O.Header_and (7, String.length content, other);
            ]
            [ other; x ]
        in
        check "no delta data"
          (not_held
             ~damage:
               [
                 damage ~offset:(nth_offset pack 1) (pack_pathname "p")
                   Store.Not_zlib;
               ]
             ())
          (finder (M.create nodes) x));
    case "a REF_DELTA whose base id runs into the trailer" (fun () ->
        let other = O.id Id.Sha1 O.Blob "other" in
        let pack, nodes =
          one_pack
            [ O.Header_and (7, String.length content, String.sub other 0 10) ]
            [ x ]
        in
        check "the id is cut"
          (not_held
             ~damage:
               [
                 damage ~offset:(nth_offset pack 0) (pack_pathname "p")
                   Store.Malformed_entry_header;
               ]
             ())
          (finder (M.create nodes) x));
    case "a last stream that ends inside the trailer is not zlib" (fun () ->
        let base = "base bytes" in
        List.iter
          (fun (label, entries, ids, at) ->
            let pack = O.pack Id.Sha1 entries in
            let body =
              String.sub pack.bytes 0 (String.length pack.bytes - 20)
            in
            let n = String.length body in
            let trailer = String.sub body (n - 4) 4 ^ String.make 16 '\000' in
            let bytes = String.sub body 0 (n - 4) ^ trailer in
            let index =
              O.index_entries_v2 Id.Sha1 ~pack_checksum:trailer
                (List.sort compare
                   (List.filter_map
                      (fun (id, offset) ->
                        if id = "" then None else Some (id, 0, offset))
                      (List.combine ids pack.offsets)))
            in
            check label
              (not_held
                 ~damage:
                   [
                     damage ~offset:(nth_offset pack at) (pack_pathname "p")
                       Store.Not_zlib;
                   ]
                 ())
              (finder
                 (M.create
                    [
                      (pack_pathname "p", M.File bytes);
                      (index_pathname "p", M.File index);
                    ])
                 x))
          [
            ("a whole entry", [ O.Whole (O.Blob, content) ], [ x ], 0);
            ( "delta data",
              [ O.Whole (O.Blob, base); O.Ofs_delta (0, delta_of base content) ],
              [ O.id Id.Sha1 O.Blob base; x ],
              1 );
          ]);
    case "a stream that inflates past its size over two runs gives nothing"
      (fun () ->
        let size = 70_000 in
        let bytes = random_bytes (2 * size) in
        let base = "base bytes" in
        let base_entry = O.entry_header 3 (String.length base) ^ O.zlib base in
        List.iter
          (fun (label, entries, ids, at) ->
            let pack, nodes = one_pack entries ids in
            check label
              (not_held
                 ~damage:
                   [
                     damage ~offset:(nth_offset pack at) (pack_pathname "p")
                       Store.Size_differs;
                   ]
                 ())
              (finder (M.create nodes) x))
          [
            ("a whole entry", [ O.Header_and (3, size, O.zlib bytes) ], [ x ], 0);
            ( "delta data",
              [
                O.Raw_entry base_entry;
                O.Header_and
                  ( 6,
                    size,
                    O.offset_encoding (String.length base_entry) ^ O.zlib bytes
                  );
              ],
              [ O.id Id.Sha1 O.Blob base; x ],
              1 );
          ];
        let raw = O.id Id.Sha1 O.Blob (String.sub bytes 0 size) in
        check "loose"
          (not_held
             ~damage:[ damage (loose_pathname raw) Store.Size_differs ]
             ())
          (finder
             (M.create
                [
                  ( loose_pathname raw,
                    M.File (O.zlib (Printf.sprintf "blob %d\000" size ^ bytes))
                  );
                ])
             raw));
  ]

module Bits = struct
  type t = { buffer : Buffer.t; mutable bits : int; mutable count : int }

  let create () = { buffer = Buffer.create 64; bits = 0; count = 0 }

  let add t value width =
    for k = 0 to width - 1 do
      t.bits <- t.bits lor (((value lsr k) land 1) lsl t.count);
      t.count <- t.count + 1;
      if t.count = 8 then (
        Buffer.add_char t.buffer (Char.chr t.bits);
        t.bits <- 0;
        t.count <- 0)
    done

  let add_code t code length =
    for k = length - 1 downto 0 do
      add t ((code lsr k) land 1) 1
    done

  let contents t =
    if t.count > 0 then Buffer.add_char t.buffer (Char.chr t.bits);
    t.bits <- 0;
    t.count <- 0;
    Buffer.contents t.buffer
end

let canonical lengths =
  let longest = Array.fold_left max 0 lengths in
  let counts = Array.make (longest + 1) 0 in
  Array.iter (fun l -> if l > 0 then counts.(l) <- counts.(l) + 1) lengths;
  let next = Array.make (longest + 2) 0 in
  let code = ref 0 in
  for bits = 1 to longest do
    code := (!code + counts.(bits - 1)) lsl 1;
    next.(bits) <- !code
  done;
  Array.map
    (fun l ->
      if l = 0 then None
      else
        let c = next.(l) in
        next.(l) <- c + 1;
        Some (c land ((1 lsl l) - 1), l))
    lengths

let length_extra symbol =
  if symbol < 265 || symbol = 285 then 0 else (symbol - 261) / 4

let distance_extra symbol = if symbol < 4 then 0 else (symbol / 2) - 1

let code_length_order =
  [| 16; 17; 18; 0; 8; 7; 9; 6; 10; 5; 11; 4; 12; 3; 13; 2; 14; 1; 15 |]

type shape = {
  literal_lengths : int array;
  distance_lengths : int array;
  symbols : (int * int) list;
  extra : int;
  final : bool;
  checksum : int option;
}

let deflate_block shape =
  let w = Bits.create () in
  let extra = ref shape.extra in
  let bits n =
    extra := (!extra * 1103515245) + 12345;
    (!extra lsr 16) land ((1 lsl n) - 1)
  in
  let nlit = Array.length shape.literal_lengths
  and ndist = Array.length shape.distance_lengths in
  Bits.add w (if shape.final then 1 else 0) 1;
  Bits.add w 2 2;
  Bits.add w (nlit - 257) 5;
  Bits.add w (ndist - 1) 5;
  Bits.add w (19 - 4) 4;
  Array.iter
    (fun symbol -> Bits.add w (if symbol < 16 then 4 else 0) 3)
    code_length_order;
  Array.iter (fun l -> Bits.add_code w l 4) shape.literal_lengths;
  Array.iter (fun l -> Bits.add_code w l 4) shape.distance_lengths;
  let literal = canonical shape.literal_lengths
  and distance = canonical shape.distance_lengths in
  let write ~absent table symbol =
    match
      if symbol >= 0 && symbol < Array.length table then table.(symbol)
      else None
    with
    | Some (code, length) -> Bits.add_code w code length
    | None -> absent ()
  in
  let random () = Bits.add w (bits 3) (1 + (shape.extra land 3)) in
  List.iter
    (fun (symbol, d) ->
      write ~absent:random literal symbol;
      if symbol > 256 then (
        Bits.add w (bits (length_extra symbol)) (length_extra symbol);
        write ~absent:(fun () -> Bits.add w 1 1) distance d;
        Bits.add w (bits (distance_extra d)) (distance_extra d)))
    shape.symbols;
  write ~absent:random literal 256;
  Bits.contents w

let zlib_of_shape shape =
  let checksum = Option.value shape.checksum ~default:1 in
  "\x78\x9c" ^ deflate_block shape ^ O.be32 checksum

let shape_gen =
  Gen.(
    let* literal_kind = int_range 0 3 in
    let* nlit = int_range (if literal_kind < 2 then 272 else 257) 286 in
    let* ndist = int_range 1 30 in
    let* literal_random = array_size (return nlit) (int_range 0 9) in
    let literal_lengths =
      Array.init nlit (fun s ->
          match literal_kind with
          | 0 | 1 ->
              if s < 128 then 8
              else if s < 256 then 9
              else if s < 272 then 6
              else 0
          | 2 -> if s < 256 then 9 else if s = 256 then 1 else 0
          | _ -> literal_random.(s))
    in
    let* distance_kind = int_range 0 5 in
    let* one = int_range 0 (ndist - 1) in
    let* distance_random = array_size (return ndist) (int_range 0 3) in
    let distance_lengths =
      Array.init ndist (fun s ->
          match distance_kind with
          | 0 | 1 -> if s = one then 1 else 0
          | 2 -> if s = one then 2 else 0
          | 3 -> distance_random.(s)
          | _ -> 0)
    in
    let top = match literal_kind with 2 -> 255 | 3 -> 285 | _ -> 271 in
    let symbol =
      let* literal = int_range 0 top in
      let* d =
        oneof_weighted
          [ (1, return one); (1, return (-1)); (1, int_range 0 31) ]
      in
      return (literal, d)
    in
    let* first = list_size (int_range 1 4) (int_range 0 255) in
    let* rest = list_size (int_range 0 24) symbol in
    let symbols = List.map (fun l -> (l, -1)) first @ rest in
    let* extra = nat in
    let* final = oneof_weighted [ (9, return true); (1, return false) ] in
    let* checksum = option (int_range 0 0xffff) in
    return
      { literal_lengths; distance_lengths; symbols; extra; final; checksum })

let print_shape shape =
  let hex s =
    String.concat ""
      (List.map
         (fun c -> Printf.sprintf "%02x" (Char.code c))
         (List.of_seq (String.to_seq s)))
  in
  hex (zlib_of_shape shape)

let defect_stream =
  "\x78\x9c\x1d\xc9\xb1\x09\x80\x00\x00\xc4\xc0\xd4\x3f\x85\x43\xe8\x40\x49\x2d\xb8\x7f\x27\xda\x03\x1d\x5c\xf7\xd3\x71\x9d\xe8\x34\xd5\x2d\x6d\xfe\xb6\x14\xb3\xea\xfb\x01\x2a\x84\xf1\x02\x4a\xae\x11\x9a"

let inflater_fuzz_tests =
  let x = O.id Id.Sha1 O.Blob "abc" in
  let gives_damage bytes =
    let pathname = loose_pathname x in
    match finder (M.create [ (pathname, M.File bytes) ]) x with
    | Ok { held = None; damage = [ { pathname = p; offset = None; _ } ] } ->
        p = pathname
    | Ok { held = Some _; _ } -> true
    | Ok _ | Error _ -> false
  in
  [
    case "the stream of the decompress 1.6.1 defect gives damage" (fun () ->
        Alcotest.(check bool) "damage" true (gives_damage defect_stream));
    property ~count:3000
      ~name:
        "a stream with a dynamic block of short or incomplete codes gives \
         damage"
      ~print:print_shape shape_gen (fun shape ->
        gives_damage (zlib_of_shape shape));
  ]

let reads_of system pathname =
  List.filter_map
    (function
      | M.Read (p, offset, count) when p = pathname && count > 0 ->
          Some (offset, count)
      | _ -> None)
    (M.calls system)

let pairs_text reads =
  String.concat " " (List.map (fun (o, c) -> Printf.sprintf "%d+%d" o c) reads)

let check_reads name expected actual =
  Alcotest.(check string) name (pairs_text expected) (pairs_text actual)

let inflation_reads ~start ~stop =
  let rec go position length acc =
    if position >= stop then List.rev acc
    else
      let count = min length (stop - position) in
      go (position + count) (min 65536 (2 * length)) ((position, count) :: acc)
  in
  go start 4096 []

let read_size_tests =
  let h = 20 in
  [
    case
      "the first lookup that needs a pack reads its ends and those of its \
       index once" (fun () ->
        let content = "the content\n" in
        let x = O.id Id.Sha1 O.Blob content in
        let names =
          List.init 40 (fun i -> O.id Id.Sha1 O.Blob (string_of_int i))
        in
        let pack =
          O.pack Id.Sha1
            (List.map (fun _ -> O.Whole (O.Blob, content)) (x :: names))
        in
        let index = O.index_v2 Id.Sha1 ~pack (x :: names) in
        let system = M.create (pack_nodes "p" pack index) in
        let find = finder system in
        ignore (find x);
        let n = String.length index and p = String.length pack.bytes in
        (match reads_of system (index_pathname "p") with
        | first :: second :: _ ->
            check_reads "the index"
              [ (0, 1032); (n - (2 * h), h) ]
              [ first; second ]
        | other -> Alcotest.fail (pairs_text other));
        (match reads_of system (pack_pathname "p") with
        | first :: second :: _ ->
            check_reads "the pack" [ (0, 12); (p - h, h) ] [ first; second ]
        | other -> Alcotest.fail (pairs_text other));
        M.clear system;
        ignore (find x);
        Alcotest.(check bool)
          "not again" false
          (List.mem (0, 1032) (reads_of system (index_pathname "p"))
          || List.mem (0, 12) (reads_of system (pack_pathname "p"))));
    case
      "an inflation reads 4096 bytes, then twice as many each time, at most \
       65536" (fun () ->
        let content = random_bytes 400_000 in
        let raw, (pathname, node) = loose O.Blob content in
        let size = match node with M.File b -> String.length b | _ -> 0 in
        let system = M.create [ (pathname, node) ] in
        check "held" (held O.Blob content) (finder system raw);
        check_reads "the loose file"
          (inflation_reads ~start:0 ~stop:size)
          (reads_of system pathname));
    case "an entry header is read 64 bytes at a time, then its stream"
      (fun () ->
        let content = random_bytes 9000 in
        let x = O.id Id.Sha1 O.Blob content in
        let n = String.length content in
        let header =
          String.make 1 (Char.chr (0x80 lor (3 lsl 4) lor (n land 15)))
          ^ String.make 1 (Char.chr (0x80 lor ((n lsr 4) land 0x7f)))
          ^ String.make 1 (Char.chr (0x80 lor ((n lsr 11) land 0x7f)))
          ^ String.make 96 '\x80' ^ "\000"
        in
        let stream = O.zlib content in
        let pack = O.pack Id.Sha1 [ O.Raw_entry (header ^ stream) ] in
        let system =
          M.create (pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack [ x ]))
        in
        check "held" (held O.Blob content) (finder system x);
        let data = 12 + String.length header in
        let stop = String.length pack.bytes - h in
        let expected =
          [ (0, 12); (stop, h); (12, 64); (76, 64) ]
          @ List.filter
              (fun (o, _) -> o < data + String.length stream)
              (inflation_reads ~start:data ~stop)
        in
        check_reads "the pack" expected (reads_of system (pack_pathname "p")));
    case "a header near the trailer is read up to the trailer" (fun () ->
        let content = "abc" in
        let x = O.id Id.Sha1 O.Blob content in
        let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, content) ] in
        let system =
          M.create (pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack [ x ]))
        in
        check "held" (held O.Blob content) (finder system x);
        let stop = String.length pack.bytes - h in
        check_reads "the pack"
          [ (0, 12); (stop, h); (12, stop - 12); (13, stop - 13) ]
          (reads_of system (pack_pathname "p")));
    case "the object id of a REF_DELTA is read in h bytes after its size"
      (fun () ->
        let base = String.make 200 'b' and target = String.make 200 'b' ^ "t" in
        let base_id = O.id Id.Sha1 O.Blob base
        and target_id = O.id Id.Sha1 O.Blob target in
        let pack =
          O.pack Id.Sha1
            [
              O.Ref_delta (base_id, delta_of base target); O.Whole (O.Blob, base);
            ]
        in
        let system =
          M.create
            (pack_nodes "p" pack
               (O.index_v2 Id.Sha1 ~pack [ target_id; base_id ]))
        in
        check "held" (held O.Blob target) (finder system target_id);
        let size_bytes =
          String.length
            (O.entry_header 7 (String.length (delta_of base target)))
        in
        Alcotest.(check bool)
          "a read of h bytes after the size" true
          (List.mem (12 + size_bytes, h) (reads_of system (pack_pathname "p"))));
    case "no read of a pack touches its last h bytes after the first lookup"
      (fun () ->
        let content = random_bytes 20_000 in
        let x = O.id Id.Sha1 O.Blob content in
        let stream = O.zlib content in
        let cut = String.length stream - 4 in
        let header = O.entry_header 3 (String.length content) in
        let trailer = String.sub stream cut 4 ^ String.make 16 '\000' in
        let bytes = raw_pack (header ^ String.sub stream 0 cut) trailer in
        let index =
          O.index_entries_v2 Id.Sha1 ~pack_checksum:trailer [ (x, 0, 12) ]
        in
        let system =
          M.create
            [
              (pack_pathname "p", M.File bytes);
              (index_pathname "p", M.File index);
            ]
        in
        check "not zlib"
          (not_held
             ~damage:[ damage ~offset:12 (pack_pathname "p") Store.Not_zlib ]
             ())
          (finder system x);
        let stop = String.length bytes - h in
        match reads_of system (pack_pathname "p") with
        | _ :: _ :: rest ->
            List.iter
              (fun (o, c) ->
                Alcotest.(check bool)
                  (Printf.sprintf "%d+%d" o c)
                  true
                  (o + c <= stop))
              rest
        | other -> Alcotest.fail (pairs_text other));
  ]

let linear name small large =
  Alcotest.(check bool)
    (Printf.sprintf "%s: %d for n, %d for 4n" name small large)
    true
    (2 * large <= 9 * small)

let growth_tests =
  [
    case
      "the reads of a lookup grow as n log n with a chain of REF_DELTA entries"
      (fun () ->
        let reads length =
          let content = "sixteen bytes!!\n" in
          let delta =
            O.delta ~base_size:16 ~result_size:16 [ O.Copy (0, 16) ]
          in
          let x = O.id Id.Sha1 O.Blob content in
          let filler i = O.hash Id.Sha1 (Printf.sprintf "filler %d" i) in
          let ids = List.init length filler @ [ x ] in
          let entries =
            List.init length (fun i ->
                O.Ref_delta ((if i = 0 then x else filler (i - 1)), delta))
            @ [ O.Whole (O.Blob, content) ]
          in
          let pack = O.pack Id.Sha1 entries in
          let system =
            M.create (pack_nodes "r" pack (O.index_v2 Id.Sha1 ~pack ids))
          in
          let find =
            finder ~limits:{ limits with max_deltas = length } system
          in
          ignore (find (O.id Id.Sha1 O.Blob "warm"));
          M.clear system;
          (match find (filler (length - 1)) with
          | Ok { held = None; damage = [ { problem = Store.Wrong_id; _ } ] } ->
              ()
          | other -> Alcotest.fail (result_text other));
          read_calls system
        in
        let small = reads 100 and large = reads 400 in
        Alcotest.(check bool)
          (Printf.sprintf "%d reads for 100 deltas, %d for 400" small large)
          true
          (large <= 7 * small));
    case
      "the calls of a lookup grow linearly with the lines of an alternates file"
      (fun () ->
        let calls n =
          let text =
            String.concat ""
              (List.init n (fun i -> Printf.sprintf "/none/%d\n" i))
          in
          let system = M.create [ alternates text ] in
          ignore (finder system (O.id Id.Sha1 O.Blob "absent"));
          List.length (M.calls system)
        in
        linear "calls" (calls 250) (calls 1000));
    case "the calls of a lookup grow linearly with the packs of a database"
      (fun () ->
        let calls n =
          let nodes =
            List.concat
              (List.init n (fun i ->
                   let content = Printf.sprintf "object %d" i in
                   let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, content) ] in
                   pack_nodes (Printf.sprintf "%04d" i) pack
                     (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob content ])))
          in
          let system = M.create nodes in
          let find = finder ~limits:{ limits with max_packs = n } system in
          ignore (find (O.id Id.Sha1 O.Blob "warm"));
          M.clear system;
          check "absent" (not_held ()) (find (O.id Id.Sha1 O.Blob "absent"));
          List.length (M.calls system)
        in
        linear "calls" (calls 25) (calls 100));
    case "the reads of an entry header grow linearly with its length" (fun () ->
        let reads n =
          let content = "abc" in
          let x = O.id Id.Sha1 O.Blob content in
          let header = "\xb3" ^ String.make (64 * n) '\x80' ^ "\000" in
          let pack = O.pack Id.Sha1 [ O.Raw_entry (header ^ O.zlib content) ] in
          let system =
            M.create (pack_nodes "p" pack (O.index_v2 Id.Sha1 ~pack [ x ]))
          in
          check "held" (held O.Blob content) (finder system x);
          List.length (reads_of system (pack_pathname "p"))
        in
        linear "reads" (reads 25) (reads 100));
    case "the bytes that an inflation reads grow linearly with its stream"
      (fun () ->
        let given n =
          let x = O.id Id.Sha1 O.Blob "abc" in
          let empty =
            String.concat "" (List.init n (fun _ -> "\000\000\000\xff\xff"))
          in
          let stream = O.zlib_stored "blob 3\000abc" in
          let bytes =
            String.sub stream 0 2 ^ empty
            ^ String.sub stream 2 (String.length stream - 2)
          in
          let system = M.create [ (loose_pathname x, M.File bytes) ] in
          check "held" (held O.Blob "abc") (finder system x);
          M.bytes_given system
        in
        linear "bytes" (given 20_000) (given 80_000));
  ]

let unread pathname =
  Error (Store.Unread { pathname; failure = Files.Cannot_read })

let read_failure_tests =
  let content = "the content\n" in
  let x = O.id Id.Sha1 O.Blob content in
  let pack = O.pack Id.Sha1 [ O.Whole (O.Blob, content) ] in
  let index = O.index_v2 Id.Sha1 ~pack [ x ] in
  let n = String.length index and p = String.length pack.bytes in
  let with_pack ?(pack_node = M.File pack.bytes) ?(index_node = M.File index) ()
      =
    M.create
      [ (pack_pathname "p", pack_node); (index_pathname "p", index_node) ]
  in
  [
    case "a read that fails inside a loose file is Unread" (fun () ->
        let big = random_bytes 10_000 in
        List.iter
          (fun (label, content, low) ->
            let raw = O.id Id.Sha1 O.Blob content in
            let bytes = O.loose O.Blob content in
            check label
              (unread (loose_pathname raw))
              (finder
                 (M.create
                    [ (loose_pathname raw, M.Failing (bytes, low, max_int)) ])
                 raw))
          [ ("the first read", "abc", 0); ("a later read", big, 4096) ]);
    case "a read that fails inside an index is Unread" (fun () ->
        List.iter
          (fun (label, low, high) ->
            check label
              (unread (index_pathname "p"))
              (finder
                 (with_pack ~index_node:(M.Failing (index, low, high)) ())
                 x))
          [
            ("its first bytes", 0, 1);
            ("the copy of the pack checksum", n - 40, n - 20);
            ("a name of the search", 1032, 1052);
          ]);
    case "a read that fails inside a stream after the header is Unread"
      (fun () ->
        let big = random_bytes 5000 and base = random_bytes 3000 in
        let big_id = O.id Id.Sha1 O.Blob big in
        let whole = O.pack Id.Sha1 [ O.Whole (O.Blob, big) ] in
        check "a whole entry"
          (unread (pack_pathname "p"))
          (finder
             (M.create
                [
                  (pack_pathname "p", M.Failing (whole.bytes, 3000, 3001));
                  ( index_pathname "p",
                    M.File (O.index_v2 Id.Sha1 ~pack:whole [ big_id ]) );
                ])
             big_id);
        let target =
          String.map (fun c -> Char.chr ((Char.code c + 1) land 255)) base
        in
        let target_id = O.id Id.Sha1 O.Blob target in
        let deltas =
          O.pack Id.Sha1
            [ O.Whole (O.Blob, base); O.Ofs_delta (0, delta_of base target) ]
        in
        let at = nth_offset deltas 1 in
        check "delta data"
          (unread (pack_pathname "p"))
          (finder
             (M.create
                [
                  ( pack_pathname "p",
                    M.Failing (deltas.bytes, at + 2000, at + 2001) );
                  ( index_pathname "p",
                    M.File
                      (O.index_v2 Id.Sha1 ~pack:deltas
                         [ O.id Id.Sha1 O.Blob base; target_id ]) );
                ])
             target_id));
    case "a read that fails inside a pack is Unread" (fun () ->
        List.iter
          (fun (label, low, high) ->
            check label
              (unread (pack_pathname "p"))
              (finder
                 (with_pack ~pack_node:(M.Failing (pack.bytes, low, high)) ())
                 x))
          [
            ("its header", 0, 12);
            ("its trailer", p - 20, p);
            ("the header of the entry", 12, 13);
            ("the stream of the entry", 14, 15);
          ]);
    case "a read that fails inside delta data is Unread" (fun () ->
        let base = "base bytes" in
        let pack =
          O.pack Id.Sha1
            [ O.Whole (O.Blob, base); O.Ofs_delta (0, delta_of base content) ]
        in
        let at = nth_offset pack 1 in
        check "the delta data"
          (unread (pack_pathname "p"))
          (finder
             (M.create
                [
                  (pack_pathname "p", M.Failing (pack.bytes, at + 3, at + 4));
                  ( index_pathname "p",
                    M.File
                      (O.index_v2 Id.Sha1 ~pack [ O.id Id.Sha1 O.Blob base; x ])
                  );
                ])
             x));
    case "a REF_DELTA whose base search fails or reads a damaged index"
      (fun () ->
        let base = String.make 200 'b' in
        let base_id = O.id Id.Sha1 O.Blob base in
        let target = base ^ "t" in
        let target_id = O.id Id.Sha1 O.Blob target in
        Alcotest.(check bool) "two buckets" true (base_id.[0] <> target_id.[0]);
        let pack =
          O.pack Id.Sha1
            [
              O.Ref_delta (base_id, delta_of base target); O.Whole (O.Blob, base);
            ]
        in
        let index = O.index_v2 Id.Sha1 ~pack [ target_id; base_id ] in
        let slot = if base_id < target_id then 0 else 1 in
        check "the search of the base fails"
          (unread (index_pathname "p"))
          (finder
             (M.create
                [
                  (pack_pathname "p", M.File pack.bytes);
                  ( index_pathname "p",
                    M.Failing (index, 1032 + (20 * slot), 1052 + (20 * slot)) );
                ])
             target_id);
        let c = String.make 1 base_id.[0] in
        let high = c ^ String.make 19 '\255'
        and low = c ^ String.make 19 '\000' in
        let entries =
          List.stable_sort
            (fun (a, _) (b, _) -> compare a.[0] b.[0])
            [ (high, 12); (high, 12); (low, 12); (target_id, 12) ]
        in
        let body = String.sub pack.bytes 12 (String.length pack.bytes - 32) in
        let trailer = String.make 20 '\007' in
        check "the search of the base reads two equal names"
          (not_held
             ~damage:[ damage (index_pathname "p") Store.Malformed_index ]
             ())
          (finder
             (M.create
                [
                  (pack_pathname "p", M.File (raw_pack ~count:4 body trailer));
                  ( index_pathname "p",
                    M.File
                      (index_v2_words ~names:(List.map fst entries)
                         ~words:(List.map snd entries) trailer) );
                ])
             target_id));
    case "an index that is a dangling link holds nothing" (fun () ->
        check "absent" (not_held ())
          (finder
             (M.create
                [
                  (pack_pathname "p", M.File pack.bytes);
                  (index_pathname "p", M.Link "/gone");
                ])
             x));
    case "a folder of the object database or pack that cannot be read is Unread"
      (fun () ->
        check "objects" (unread db) (finder (M.create [ (db, M.Link db) ]) x);
        check "pack"
          (unread (db ^ "/pack"))
          (finder (M.create [ (db ^ "/pack", M.Link (db ^ "/pack")) ]) x));
    case "a loose stream that ends before the byte 0x00 is malformed" (fun () ->
        check "no 0x00"
          (not_held
             ~damage:[ damage (loose_pathname x) Store.Malformed_loose_header ]
             ())
          (finder
             (M.create [ (loose_pathname x, M.File (O.zlib "blob 12")) ])
             x));
    case "an OFS_DELTA distance that runs into the trailer is malformed"
      (fun () ->
        let pack =
          O.pack ~count:1 Id.Sha1
            [ O.Whole (O.Blob, noise 300); O.Raw_entry "\x63\x80" ]
        in
        let at = nth_offset pack 1 in
        let index =
          O.index_entries_v2 Id.Sha1 ~pack_checksum:pack.checksum [ (x, 0, at) ]
        in
        check "cut"
          (not_held
             ~damage:
               [
                 damage ~offset:at (pack_pathname "p")
                   Store.Malformed_entry_header;
               ]
             ())
          (finder
             (M.create
                [
                  (pack_pathname "p", M.File pack.bytes);
                  (index_pathname "p", M.File index);
                ])
             x));
  ]

let shrunk_gen =
  Gen.(
    let* plan = plan_gen in
    let nodes = build plan in
    let* which = int_range 0 (List.length nodes - 1) in
    let* keep = int_range 0 999_999 in
    let nodes =
      List.mapi
        (fun i (p, node) ->
          match node with
          | M.File bytes when i = which ->
              let n = String.length bytes in
              (p, M.Shrunk (String.sub bytes 0 (keep * n / 1_000_000), n))
          | _ -> (p, node))
        nodes
    in
    return (plan, nodes))

let shrunk_later_gen =
  Gen.(
    let* plan = plan_gen in
    let nodes = build plan in
    let* which = int_range 0 (List.length nodes - 1) in
    let* keep = int_range 0 999_999 in
    return (plan, nodes, which, keep))

let shrunk_properties =
  [
    property ~count:300
      ~name:
        "a file that another process shortened after a lookup gives no wrong \
         object"
      ~print:(fun (plan, _, _, _) -> print_plan plan)
      shrunk_later_gen
      (fun (plan, nodes, which, keep) ->
        let system = M.create nodes in
        let find = finder ~format:plan.format system in
        let lookups () =
          List.for_all
            (fun (kind, content, _) ->
              match find (O.id plan.format kind content) with
              | Ok { held = Some obj; _ } ->
                  obj = { Store.kind = store_kind kind; content }
              | Ok { held = None; _ } | Error _ -> true)
            plan.objects
        in
        let first = lookups () in
        (match List.nth nodes which with
        | p, M.File bytes ->
            let n = String.length bytes in
            M.remove system p;
            M.add system p
              (M.Shrunk (String.sub bytes 0 (keep * n / 1_000_000), n))
        | _ -> ());
        first && lookups ());
    property ~count:300
      ~name:"a file that another process shortened gives no wrong object"
      ~print:(fun (plan, _) -> print_plan plan)
      shrunk_gen
      (fun (plan, nodes) ->
        let find = finder ~format:plan.format (M.create nodes) in
        List.for_all
          (fun (kind, content, _) ->
            match find (O.id plan.format kind content) with
            | Ok { held = Some obj; _ } ->
                obj = { Store.kind = store_kind kind; content }
            | Ok { held = None; _ } | Error _ -> true)
          plan.objects);
  ]

let tests =
  loose_tests @ loose_damage_tests @ pack_tests @ ref_delta_tests
  @ entry_damage_tests @ index_damage_tests @ order_tests @ alternate_tests
  @ limit_tests @ reads_tests @ cost_tests @ held_tests @ form_tests
  @ inflater_fuzz_tests @ read_size_tests @ growth_tests @ read_failure_tests
  @ shrunk_properties @ generated_properties
