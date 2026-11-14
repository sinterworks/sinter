(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Files = Sinter_repository_files

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f
let big = 1 lsl 40

let failure_name = function
  | Files.No_file -> "no file"
  | Files.Not_a_regular_file -> "not a regular file"
  | Files.Not_a_folder -> "not a folder"
  | Files.Not_a_symbolic_link -> "not a symbolic link"
  | Files.Too_large -> "too large"
  | Files.Cannot_read -> "cannot read"

let kind_name = function
  | Files.Folder -> "folder"
  | Files.Regular_file -> "regular file"
  | Files.Symbolic_link -> "symbolic link"
  | Files.Other_kind -> "other kind"

let show show_ok = function
  | Ok value -> "Ok " ^ show_ok value
  | Error failure -> "Error " ^ failure_name failure

let check_result name show_ok expected actual =
  Alcotest.(check string) name (show show_ok expected) (show show_ok actual)

let quoted = Printf.sprintf "%S"

let identity_text (identity : Files.identity) =
  Printf.sprintf "%d:%d" identity.device identity.inode

let names list = "[" ^ String.concat "; " (List.map quoted list) ^ "]"

module Fake = struct
  type node = File of string | Dir of string list | Link of string | Other
  type descr = int

  let nodes : (string, node) Hashtbl.t = Hashtbl.create 16
  let calls : string list ref = ref []
  let chunk = ref max_int
  let fail : (string -> Unix.error option) ref = ref (fun _ -> None)
  let fstat_kind : Files.kind option ref = ref None
  let fstat_size : int option ref = ref None
  let opened : (int, node) Hashtbl.t = Hashtbl.create 16
  let closed : int list ref = ref []
  let next = ref 0
  let given = ref 0
  let eilseq = 92

  let reset entries =
    Hashtbl.reset nodes;
    List.iter (fun (name, node) -> Hashtbl.replace nodes name node) entries;
    calls := [];
    chunk := max_int;
    (fail := fun _ -> None);
    fstat_kind := None;
    fstat_size := None;
    Hashtbl.reset opened;
    closed := [];
    next := 0;
    given := 0

  let record call =
    calls := call :: !calls;
    match !fail call with
    | Some error -> raise (Unix.Unix_error (error, "fake", call))
    | None -> ()

  let rec resolve depth name =
    if depth > 8 then raise (Unix.Unix_error (Unix.ELOOP, "fake", name))
    else
      match Hashtbl.find_opt nodes name with
      | None -> raise (Unix.Unix_error (Unix.ENOENT, "fake", name))
      | Some (Link target) -> resolve (depth + 1) target
      | Some node -> node

  let kind_of = function
    | File _ -> Files.Regular_file
    | Dir _ -> Files.Folder
    | Link _ -> Files.Symbolic_link
    | Other -> Files.Other_kind

  let stat name =
    record ("stat " ^ name);
    kind_of (resolve 0 name)

  let lstat name =
    record ("lstat " ^ name);
    match Hashtbl.find_opt nodes name with
    | None -> raise (Unix.Unix_error (Unix.ENOENT, "fake", name))
    | Some node -> kind_of node

  let new_descr node =
    incr next;
    Hashtbl.replace opened !next node;
    !next

  let open_file name =
    record ("open_file " ^ name);
    new_descr (resolve 0 name)

  let open_folder name =
    record ("open_folder " ^ name);
    match resolve 0 name with
    | Dir _ as node -> new_descr node
    | _ -> raise (Unix.Unix_error (Unix.ENOTDIR, "fake", name))

  let node_of descr = Hashtbl.find opened descr

  let identity_of node =
    Hashtbl.fold
      (fun name candidate found ->
        if found = 0 && candidate == node then Hashtbl.hash name + 1 else found)
      nodes 0

  let fstat descr =
    record (Printf.sprintf "fstat %d" descr);
    let node = node_of descr in
    let size =
      match node with File content -> String.length content | _ -> 0
    in
    {
      Files.kind = Option.value !fstat_kind ~default:(kind_of node);
      size = Option.value !fstat_size ~default:size;
      identity = { Files.device = 7; inode = identity_of node };
    }

  let read descr ~offset buffer start length =
    record (Printf.sprintf "read %d" descr);
    match node_of descr with
    | File content ->
        let count =
          max 0 (min (min length !chunk) (String.length content - offset))
        in
        if count > 0 then Bytes.blit_string content offset buffer start count;
        given := !given + count;
        count
    | _ -> raise (Unix.Unix_error (Unix.EISDIR, "fake", "read"))

  let readlink name =
    record ("readlink " ^ name);
    match Hashtbl.find_opt nodes name with
    | Some (Link target) -> target
    | Some _ -> raise (Unix.Unix_error (Unix.EINVAL, "fake", name))
    | None -> raise (Unix.Unix_error (Unix.ENOENT, "fake", name))

  let listing descr =
    record (Printf.sprintf "listing %d" descr);
    match node_of descr with Dir names -> names | _ -> []

  let close descr =
    closed := descr :: !closed;
    record (Printf.sprintf "close %d" descr)
end

module Reader = Files.Make (Fake)

let calls () = List.rev !Fake.calls

let open_calls () =
  List.filter
    (fun call ->
      String.starts_with ~prefix:"open_file " call
      || String.starts_with ~prefix:"open_folder " call)
    (calls ())

let all_closed () =
  List.for_all
    (fun descr -> List.mem descr !Fake.closed)
    (Hashtbl.fold (fun descr _ acc -> descr :: acc) Fake.opened [])
  && List.length !Fake.closed = Hashtbl.length Fake.opened

let check_all_closed () =
  Alcotest.(check bool) "every descriptor is closed once" true (all_closed ())

let fake_tree =
  [
    ("f", Fake.File "content");
    ("empty", Fake.File "");
    ("d", Fake.Dir [ "b"; "."; "a"; ".."; "b"; "c" ]);
    ("link", Fake.Link "f");
    ("link2", Fake.Link "link");
    ("dlink", Fake.Link "d");
    ("dangling", Fake.Link "gone");
    ("loop", Fake.Link "loop");
    ("pipe", Fake.Other);
  ]

let fresh () = Fake.reset fake_tree

let fake_read_tests =
  [
    case "a read gives the whole content of a regular file" (fun () ->
        fresh ();
        check_result "f" quoted (Ok "content") (Reader.read ~max_size:big "f");
        check_result "empty" quoted (Ok "") (Reader.read ~max_size:big "empty");
        check_all_closed ());
    case "a read follows each symbolic link, the last name included" (fun () ->
        fresh ();
        check_result "link2" quoted (Ok "content")
          (Reader.read ~max_size:big "link2"));
    case "a read gives every byte up to the end, whatever size fstat gives"
      (fun () ->
        fresh ();
        Fake.fstat_size := Some 0;
        check_result "f" quoted (Ok "content") (Reader.read ~max_size:big "f");
        Fake.reset fake_tree;
        Fake.fstat_size := Some 2;
        check_result "f" quoted (Ok "content") (Reader.read ~max_size:big "f"));
    case "a read finds by stat that the file is regular before it opens it"
      (fun () ->
        fresh ();
        ignore (Reader.read ~max_size:big "f");
        match calls () with
        | first :: _ ->
            Alcotest.(check string) "the first call" "stat f" first;
            Alcotest.(check (list string))
              "the opens" [ "open_file f" ] (open_calls ())
        | [] -> Alcotest.fail "no call");
    case "a read of a folder or of another kind opens nothing" (fun () ->
        List.iter
          (fun name ->
            fresh ();
            check_result name quoted (Error Files.Not_a_regular_file)
              (Reader.read ~max_size:big name);
            Alcotest.(check (list string)) (name ^ ": opens") [] (open_calls ()))
          [ "d"; "dlink"; "pipe" ]);
    case "a read takes no byte when the open file is not regular" (fun () ->
        List.iter
          (fun kind ->
            fresh ();
            Fake.fstat_kind := Some kind;
            check_result (kind_name kind) quoted
              (Error Files.Not_a_regular_file)
              (Reader.read ~max_size:big "f");
            Alcotest.(check bool)
              (kind_name kind ^ ": no read")
              false
              (List.exists (String.starts_with ~prefix:"read ") (calls ()));
            check_all_closed ())
          [ Files.Folder; Files.Other_kind; Files.Symbolic_link ]);
    case "a read makes calls only on the pathname that it is given" (fun () ->
        fresh ();
        ignore (Reader.read ~max_size:big "link2");
        List.iter
          (fun call ->
            match String.index_opt call ' ' with
            | Some space ->
                let verb = String.sub call 0 space
                and rest =
                  String.sub call (space + 1) (String.length call - space - 1)
                in
                if List.mem verb [ "stat"; "lstat"; "open_file"; "readlink" ]
                then Alcotest.(check string) call "link2" rest
            | None -> Alcotest.failf "a call with no argument: %s" call)
          (calls ()));
    case "a missing file, a dangling link, and an empty pathname give no file"
      (fun () ->
        List.iter
          (fun name ->
            fresh ();
            check_result name quoted (Error Files.No_file)
              (Reader.read ~max_size:big name))
          [ "gone"; "dangling"; "" ]);
    case "a pathname with the byte 0x00 gives no file and no call" (fun () ->
        fresh ();
        check_result "read" quoted (Error Files.No_file)
          (Reader.read ~max_size:big "f\000x");
        check_result "list" names (Error Files.No_file) (Reader.list "d\000");
        check_result "link_kind" kind_name (Error Files.No_file)
          (Reader.link_kind "\000");
        check_result "link_text" quoted (Error Files.No_file)
          (Reader.link_text "link\000");
        check_result "with_file" Fun.id (Error Files.No_file)
          (Reader.with_file "f\000" (fun _ -> "opened"));
        Alcotest.(check (list string)) "calls" [] (calls ()));
    case "a link loop cannot be read" (fun () ->
        fresh ();
        check_result "loop" quoted (Error Files.Cannot_read)
          (Reader.read ~max_size:big "loop"));
  ]

let errors_of_no_file =
  [
    ("ENOENT", Unix.ENOENT);
    ("ENOTDIR", Unix.ENOTDIR);
    ("ENAMETOOLONG", Unix.ENAMETOOLONG);
    ("EILSEQ", Unix.EUNKNOWNERR Fake.eilseq);
  ]

let errors_of_cannot_read =
  [
    ("EACCES", Unix.EACCES);
    ("ELOOP", Unix.ELOOP);
    ("EIO", Unix.EIO);
    ("EPERM", Unix.EPERM);
    ("another unknown error", Unix.EUNKNOWNERR (Fake.eilseq + 1));
  ]

let error_tests =
  let each_call expected (label, error) =
    case
      (Printf.sprintf "the error %s of the first call gives %s" label
         (failure_name expected))
      (fun () ->
        let fail_first () =
          let first = ref true in
          Fake.fail :=
            fun _ ->
              if !first then (
                first := false;
                Some error)
              else None
        in
        fresh ();
        fail_first ();
        check_result "read" quoted (Error expected)
          (Reader.read ~max_size:big "f");
        fresh ();
        fail_first ();
        check_result "list" names (Error expected) (Reader.list "d");
        fresh ();
        fail_first ();
        check_result "link_kind" kind_name (Error expected)
          (Reader.link_kind "f");
        fresh ();
        fail_first ();
        check_result "folder_identity" identity_text (Error expected)
          (Reader.folder_identity "d");
        fresh ();
        fail_first ();
        check_result "link_text" quoted (Error expected)
          (Reader.link_text "link");
        fresh ();
        fail_first ();
        check_result "with_file" Fun.id (Error expected)
          (Reader.with_file "f" (fun _ -> "opened"));
        check_all_closed ())
  in
  List.map (each_call Files.No_file) errors_of_no_file
  @ List.map (each_call Files.Cannot_read) errors_of_cannot_read

let later_error_tests =
  let fail_on prefix error =
    Fake.fail :=
      fun call -> if String.starts_with ~prefix call then Some error else None
  in
  [
    case "an error of open, fstat, or read closes what it opened" (fun () ->
        List.iter
          (fun prefix ->
            fresh ();
            fail_on prefix Unix.EIO;
            check_result prefix quoted (Error Files.Cannot_read)
              (Reader.read ~max_size:big "f");
            check_all_closed ())
          [ "open_file"; "fstat"; "read" ]);
    case "an error of the listing closes the folder" (fun () ->
        List.iter
          (fun prefix ->
            fresh ();
            fail_on prefix Unix.EIO;
            check_result prefix names (Error Files.Cannot_read)
              (Reader.list "d");
            check_all_closed ())
          [ "open_folder"; "listing" ]);
    case "an error of the open or of fstat of a folder closes the folder"
      (fun () ->
        List.iter
          (fun prefix ->
            fresh ();
            fail_on prefix Unix.EIO;
            check_result prefix identity_text (Error Files.Cannot_read)
              (Reader.folder_identity "d");
            check_all_closed ())
          [ "open_folder"; "fstat" ]);
    case "an error of a ranged read is a failure, and the file stays open"
      (fun () ->
        fresh ();
        let inside =
          Reader.with_file "f" (fun handle ->
              fail_on "read" Unix.EIO;
              let range = Reader.read_range handle ~offset:0 ~length:3 in
              (range, all_closed ()))
        in
        match inside with
        | Ok (range, closed_inside) ->
            check_result "the range" quoted (Error Files.Cannot_read) range;
            Alcotest.(check bool) "not closed inside" false closed_inside;
            check_all_closed ()
        | Error failure -> Alcotest.failf "with_file: %s" (failure_name failure));
  ]

type step = { call : int; error : Unix.error }

let print_step { call; error } =
  Printf.sprintf "call %d fails with %s" call (Unix.error_message error)

let step_gen =
  Gen.map2
    (fun call error -> { call; error })
    (Gen.int_range 0 8)
    (Gen.oneof_list
       [
         Unix.ENOENT;
         Unix.EACCES;
         Unix.EIO;
         Unix.ENOTDIR;
         Unix.ELOOP;
         Unix.EINTR;
         Unix.EAGAIN;
         Unix.EUNKNOWNERR Fake.eilseq;
       ])

let fault_properties =
  [
    property ~name:"a failed call of the system never raises and closes all"
      ~print:print_step step_gen (fun { call; error } ->
        let run f =
          fresh ();
          let count = ref 0 in
          (Fake.fail :=
             fun _ ->
               let this = !count in
               incr count;
               if this = call then Some error else None);
          f ();
          all_closed ()
        in
        List.for_all run
          [
            (fun () -> ignore (Reader.read ~max_size:big "link"));
            (fun () -> ignore (Reader.list "dlink"));
            (fun () -> ignore (Reader.folder_identity "dlink"));
            (fun () -> ignore (Reader.link_kind "f"));
            (fun () -> ignore (Reader.link_text "link"));
            (fun () ->
              ignore
                (Reader.with_file "f" (fun handle ->
                     ignore (Reader.read_range handle ~offset:1 ~length:4))));
          ]);
  ]

let content_gen = Gen.string_size ~gen:Gen.char (Gen.int_range 0 300)

let chunked_properties =
  [
    property ~name:"a read in short pieces gives the whole content"
      ~print:(fun (content, chunk) ->
        Printf.sprintf "%S in pieces of %d" content chunk)
      (Gen.pair content_gen (Gen.int_range 1 17))
      (fun (content, chunk) ->
        Fake.reset [ ("f", Fake.File content) ];
        Fake.chunk := chunk;
        Reader.read ~max_size:big "f" = Ok content && all_closed ());
    property
      ~name:"a ranged read gives the bytes of the range that the file has"
      ~print:(fun (content, chunk, offset, length) ->
        Printf.sprintf "%S in pieces of %d, from %d, %d bytes" content chunk
          offset length)
      (Gen.quad content_gen (Gen.int_range 1 17) (Gen.int_range 0 320)
         (Gen.int_range 0 320))
      (fun (content, chunk, offset, length) ->
        Fake.reset [ ("f", Fake.File content) ];
        Fake.chunk := chunk;
        let size = String.length content in
        let expected =
          if offset >= size then ""
          else String.sub content offset (min length (size - offset))
        in
        Reader.with_file "f" (fun handle ->
            (Reader.size handle, Reader.read_range handle ~offset ~length))
        = Ok (size, Ok expected)
        && all_closed ());
    property ~name:"a listing gives each name once, sorted, without . and .."
      ~print:names
      (Gen.list_size (Gen.int_range 0 12)
         (Gen.oneof_list [ "."; ".."; "a"; "b"; "B"; "a b"; "\xff"; "z"; ".a" ]))
      (fun listing ->
        Fake.reset [ ("d", Fake.Dir listing) ];
        let expected =
          List.sort_uniq String.compare
            (List.filter (fun name -> name <> "." && name <> "..") listing)
        in
        Reader.list "d" = Ok expected && all_closed ());
  ]

let max_size_tests =
  [
    case "a whole read of a file larger than its maximum is too large"
      (fun () ->
        Fake.reset [ ("f", Fake.File (String.make 100 'x')) ];
        check_result "100 of 99" quoted (Error Files.Too_large)
          (Reader.read ~max_size:99 "f");
        Alcotest.(check bool) "at most 100 bytes read" true (!Fake.given <= 100);
        check_all_closed ();
        Fake.reset [ ("f", Fake.File (String.make 100 'x')) ];
        check_result "100 of 100" quoted
          (Ok (String.make 100 'x'))
          (Reader.read ~max_size:100 "f");
        Fake.reset [ ("f", Fake.File "") ];
        check_result "0 of 0" quoted (Ok "") (Reader.read ~max_size:0 "f"));
    property ~name:"a whole read takes at most its maximum and one bytes"
      ~print:(fun (content, chunk, max_size) ->
        Printf.sprintf "%d bytes in pieces of %d, at most %d"
          (String.length content) chunk max_size)
      Gen.(triple content_gen (int_range 1 17) (int_range 0 320))
      (fun (content, chunk, max_size) ->
        Fake.reset [ ("f", Fake.File content) ];
        Fake.chunk := chunk;
        Fake.fstat_size := Some 0;
        let result = Reader.read ~max_size "f" in
        !Fake.given <= max_size + 1
        && all_closed ()
        &&
        if String.length content <= max_size then result = Ok content
        else result = Error Files.Too_large);
    case "a negative maximum raises Invalid_argument" (fun () ->
        fresh ();
        match Reader.read ~max_size:(-1) "f" with
        | _ -> Alcotest.fail "no exception"
        | exception Invalid_argument _ -> ());
  ]

let with_file_tests =
  [
    case "with_file gives the size of the open file and closes it" (fun () ->
        fresh ();
        check_result "size" string_of_int (Ok 7)
          (Reader.with_file "f" Reader.size);
        check_all_closed ());
    case "with_file gives the identity that fstat gives" (fun () ->
        fresh ();
        let expected =
          Hashtbl.fold
            (fun name node found ->
              if name = "f" then
                match node with
                | Fake.File _ -> Some (Fake.identity_of node)
                | _ -> found
              else found)
            Fake.nodes None
        in
        check_result "identity" string_of_int
          (Ok (Option.value expected ~default:(-1)))
          (Reader.with_file "link" (fun handle ->
               let identity = Reader.identity handle in
               if identity.Files.device = 7 then identity.inode else -1));
        check_all_closed ());
    case "with_file opens only a regular file" (fun () ->
        List.iter
          (fun name ->
            fresh ();
            check_result name Fun.id (Error Files.Not_a_regular_file)
              (Reader.with_file name (fun _ -> "opened"));
            Alcotest.(check (list string)) (name ^ ": opens") [] (open_calls ()))
          [ "d"; "pipe" ];
        fresh ();
        Fake.fstat_kind := Some Files.Other_kind;
        check_result "swapped" Fun.id (Error Files.Not_a_regular_file)
          (Reader.with_file "f" (fun _ -> "opened"));
        check_all_closed ());
    case "an exception of the function goes through after the close" (fun () ->
        fresh ();
        (match Reader.with_file "f" (fun _ -> raise Exit) with
        | _ -> Alcotest.fail "no exception"
        | exception Exit -> ());
        check_all_closed ());
    case "a handle used after with_file raises Invalid_argument" (fun () ->
        fresh ();
        match Reader.with_file "f" Fun.id with
        | Error failure -> Alcotest.failf "with_file: %s" (failure_name failure)
        | Ok handle -> (
            (match Reader.size handle with
            | _ -> Alcotest.fail "size: no exception"
            | exception Invalid_argument _ -> ());
            (match Reader.identity handle with
            | _ -> Alcotest.fail "identity: no exception"
            | exception Invalid_argument _ -> ());
            match Reader.read_range handle ~offset:0 ~length:1 with
            | _ -> Alcotest.fail "read_range: no exception"
            | exception Invalid_argument _ -> ()));
    case
      "a negative offset raises Invalid_argument on the system of the process"
      (fun () ->
        let path = Filename.concat (Git_fixture.temp_dir ()) "f" in
        Out_channel.with_open_bin path (fun channel ->
            Out_channel.output_string channel "content");
        match
          Files.with_file path (fun handle ->
              match Files.read_range handle ~offset:(-1) ~length:1 with
              | _ -> false
              | exception Invalid_argument _ -> true)
        with
        | Ok raised -> Alcotest.(check bool) "raised" true raised
        | Error failure -> Alcotest.failf "with_file: %s" (failure_name failure));
    case "a negative offset or length raises Invalid_argument" (fun () ->
        fresh ();
        let raises f =
          match f () with _ -> false | exception Invalid_argument _ -> true
        in
        match
          Reader.with_file "f" (fun handle ->
              ( raises (fun () ->
                    Reader.read_range handle ~offset:(-1) ~length:1),
                raises (fun () ->
                    Reader.read_range handle ~offset:0 ~length:(-1)) ))
        with
        | Ok (offset, length) ->
            Alcotest.(check bool) "offset" true offset;
            Alcotest.(check bool) "length" true length;
            check_all_closed ()
        | Error failure -> Alcotest.failf "with_file: %s" (failure_name failure));
  ]

let list_tests =
  [
    case "a listing follows a link to a folder" (fun () ->
        fresh ();
        check_result "dlink" names (Ok [ "a"; "b"; "c" ]) (Reader.list "dlink");
        check_all_closed ());
    case "a listing of a file that is not a folder is not a folder" (fun () ->
        List.iter
          (fun name ->
            fresh ();
            check_result name names (Error Files.Not_a_folder)
              (Reader.list name))
          [ "f"; "link"; "pipe" ];
        Alcotest.(check bool)
          "no listing" false
          (List.exists (String.starts_with ~prefix:"listing ") (calls ())));
    case "a listing opens no file for reading" (fun () ->
        fresh ();
        ignore (Reader.list "d");
        Alcotest.(check bool)
          "no open_file" false
          (List.exists (String.starts_with ~prefix:"open_file ") (calls ())));
  ]

let folder_identity_tests =
  let identity name =
    match Reader.folder_identity name with
    | Ok identity -> identity_text identity
    | Error failure -> "Error " ^ failure_name failure
  in
  [
    case "two pathnames of one folder give one identity" (fun () ->
        fresh ();
        Alcotest.(check string) "dlink" (identity "d") (identity "dlink");
        check_all_closed ());
    case "two folders give two identities" (fun () ->
        Fake.reset (fake_tree @ [ ("e", Fake.Dir [ "x" ]) ]);
        Alcotest.(check bool) "d and e" false (identity "d" = identity "e");
        check_all_closed ());
    case "the identity of a folder is the identity that fstat gives" (fun () ->
        fresh ();
        let expected =
          match Hashtbl.find_opt Fake.nodes "d" with
          | Some node -> Printf.sprintf "7:%d" (Fake.identity_of node)
          | None -> "no d"
        in
        Alcotest.(check string) "d" expected (identity "d"));
    case "a file that is not a folder gives not a folder, and no file no file"
      (fun () ->
        List.iter
          (fun (name, expected) ->
            fresh ();
            Alcotest.(check string) name expected (identity name);
            check_all_closed ())
          [
            ("f", "Error not a folder");
            ("link", "Error not a folder");
            ("pipe", "Error not a folder");
            ("gone", "Error no file");
            ("dangling", "Error no file");
            ("", "Error no file");
            ("d\000", "Error no file");
          ]);
    case "folder_identity opens no file for reading and reads no name"
      (fun () ->
        List.iter
          (fun name ->
            fresh ();
            ignore (Reader.folder_identity name);
            Alcotest.(check (list string))
              name []
              (List.filter
                 (fun call ->
                   String.starts_with ~prefix:"open_file " call
                   || String.starts_with ~prefix:"listing " call
                   || String.starts_with ~prefix:"read " call)
                 (calls ())))
          [ "d"; "dlink"; "f"; "pipe" ]);
  ]

let link_tests =
  [
    case "link_kind gives the kind without the last link and opens nothing"
      (fun () ->
        fresh ();
        List.iter
          (fun (name, kind) ->
            check_result name kind_name (Ok kind) (Reader.link_kind name))
          [
            ("f", Files.Regular_file);
            ("d", Files.Folder);
            ("link", Files.Symbolic_link);
            ("dangling", Files.Symbolic_link);
            ("pipe", Files.Other_kind);
          ];
        check_result "gone" kind_name (Error Files.No_file)
          (Reader.link_kind "gone");
        Alcotest.(check (list string)) "opens" [] (open_calls ()));
    case "link_text gives the reference of a link and opens nothing" (fun () ->
        fresh ();
        check_result "link" quoted (Ok "f") (Reader.link_text "link");
        check_result "dangling" quoted (Ok "gone") (Reader.link_text "dangling");
        List.iter
          (fun name ->
            check_result name quoted (Error Files.Not_a_symbolic_link)
              (Reader.link_text name))
          [ "f"; "d"; "pipe" ];
        check_result "gone" quoted (Error Files.No_file)
          (Reader.link_text "gone");
        Alcotest.(check (list string)) "opens" [] (open_calls ()));
  ]

let ( / ) = Filename.concat

let write path content =
  Out_channel.with_open_bin path (fun channel ->
      Out_channel.output_string channel content)

let real_tree () =
  let root = Git_fixture.temp_dir () in
  write (root / "f") "content\n";
  Unix.mkdir (root / "d") 0o755;
  write (root / "d" / "a") "a";
  write (root / "d" / "b") "b";
  Unix.mkdir (root / "d" / "sub") 0o755;
  Unix.symlink "f" (root / "link");
  Unix.symlink "link" (root / "link2");
  Unix.symlink "d" (root / "dlink");
  Unix.symlink "gone" (root / "dangling");
  Unix.symlink "loop" (root / "loop");
  Unix.mkfifo (root / "pipe") 0o600;
  Unix.symlink "pipe" (root / "pipelink");
  Unix.symlink "/dev/zero" (root / "zero");
  Unix.symlink "/dev/null" (root / "null");
  root

let real_read_tests =
  [
    case "a read gives the content of a file, through links" (fun () ->
        let root = real_tree () in
        List.iter
          (fun name ->
            check_result name quoted (Ok "content\n")
              (Files.read ~max_size:big (root / name)))
          [ "f"; "link"; "link2" ];
        check_result "dlink/a" quoted (Ok "a")
          (Files.read ~max_size:big (root / "dlink" / "a")));
    case "a read of a missing file gives no file" (fun () ->
        let root = real_tree () in
        List.iter
          (fun name ->
            check_result name quoted (Error Files.No_file)
              (Files.read ~max_size:big name))
          [
            root / "gone";
            root / "dangling";
            root / "f" / "x";
            root / String.make 300 'n';
            root / "\xff\xfe";
            "";
          ]);
    case "a read of a link loop cannot be read" (fun () ->
        let root = real_tree () in
        check_result "loop" quoted (Error Files.Cannot_read)
          (Files.read ~max_size:big (root / "loop")));
    case "a read of a folder is not a read of a regular file" (fun () ->
        let root = real_tree () in
        check_result "d" quoted (Error Files.Not_a_regular_file)
          (Files.read ~max_size:big (root / "d"));
        check_result "dlink" quoted (Error Files.Not_a_regular_file)
          (Files.read ~max_size:big (root / "dlink")));
    case "a ranged read of a large file gives its bytes" (fun () ->
        let root = real_tree () in
        let content =
          String.init (3 * 1024 * 1024) (fun i -> Char.chr (i * 7 mod 251))
        in
        write (root / "large") content;
        match
          Files.with_file (root / "large") (fun handle ->
              ( Files.size handle,
                Files.read_range handle
                  ~offset:(2 * 1024 * 1024)
                  ~length:100_000,
                Files.read_range handle
                  ~offset:(String.length content - 10)
                  ~length:100 ))
        with
        | Ok (size, middle, last) ->
            Alcotest.(check int) "size" (String.length content) size;
            check_result "middle" quoted
              (Ok (String.sub content (2 * 1024 * 1024) 100_000))
              middle;
            check_result "last" quoted
              (Ok (String.sub content (String.length content - 10) 10))
              last
        | Error failure -> Alcotest.failf "with_file: %s" (failure_name failure));
    case "the identity of a file is its device and its file serial number"
      (fun () ->
        let root = real_tree () in
        let stat = Unix.stat (root / "f") in
        let identity name =
          match Files.with_file (root / name) Files.identity with
          | Ok identity -> (identity.Files.device, identity.inode)
          | Error failure -> Alcotest.failf "%s: %s" name (failure_name failure)
        in
        Alcotest.(check (pair int int))
          "f" (stat.st_dev, stat.st_ino) (identity "f");
        Alcotest.(check (pair int int))
          "link2" (stat.st_dev, stat.st_ino) (identity "link2");
        Alcotest.(check bool)
          "another file" false
          (identity "d/a" = (stat.st_dev, stat.st_ino)));
    case "the identity of a folder is its device and its file serial number"
      (fun () ->
        let root = real_tree () in
        let stat = Unix.stat (root / "d") in
        let expected = Printf.sprintf "%d:%d" stat.st_dev stat.st_ino in
        let identity name =
          match Files.folder_identity (root / name) with
          | Ok identity -> identity_text identity
          | Error failure -> "Error " ^ failure_name failure
        in
        List.iter
          (fun name -> Alcotest.(check string) name expected (identity name))
          [ "d"; "dlink"; "d/sub/.."; "dlink/." ];
        Alcotest.(check bool) "d/sub" false (identity "d/sub" = expected);
        Alcotest.(check string) "f" "Error not a folder" (identity "f");
        Alcotest.(check string) "gone" "Error no file" (identity "gone"));
    case "a listing gives the names of a folder, through a link" (fun () ->
        let root = real_tree () in
        check_result "d" names
          (Ok [ "a"; "b"; "sub" ])
          (Files.list (root / "d"));
        check_result "dlink" names
          (Ok [ "a"; "b"; "sub" ])
          (Files.list (root / "dlink"));
        check_result "sub" names (Ok []) (Files.list (root / "d" / "sub"));
        check_result "f" names (Error Files.Not_a_folder)
          (Files.list (root / "f"));
        check_result "gone" names (Error Files.No_file)
          (Files.list (root / "gone")));
    case "link_kind and link_text do not follow the last name" (fun () ->
        let root = real_tree () in
        List.iter
          (fun (name, kind) ->
            check_result name kind_name (Ok kind)
              (Files.link_kind (root / name)))
          [
            ("f", Files.Regular_file);
            ("d", Files.Folder);
            ("link", Files.Symbolic_link);
            ("dangling", Files.Symbolic_link);
            ("pipe", Files.Other_kind);
            ("dlink/a", Files.Regular_file);
          ];
        check_result "link" quoted (Ok "f") (Files.link_text (root / "link"));
        check_result "dangling" quoted (Ok "gone")
          (Files.link_text (root / "dangling"));
        check_result "f" quoted (Error Files.Not_a_symbolic_link)
          (Files.link_text (root / "f"));
        check_result "gone" quoted (Error Files.No_file)
          (Files.link_text (root / "gone")));
    case "a file without the permission to read cannot be read" (fun () ->
        if Unix.geteuid () = 0 then ()
        else
          let root = real_tree () in
          Unix.chmod (root / "f") 0o000;
          Unix.chmod (root / "d") 0o000;
          Fun.protect
            ~finally:(fun () ->
              Unix.chmod (root / "f") 0o644;
              Unix.chmod (root / "d") 0o755)
            (fun () ->
              check_result "f" quoted (Error Files.Cannot_read)
                (Files.read ~max_size:big (root / "f"));
              check_result "d/a" quoted (Error Files.Cannot_read)
                (Files.read ~max_size:big (root / "d" / "a"));
              check_result "d" names (Error Files.Cannot_read)
                (Files.list (root / "d"))));
  ]

let probe name args =
  match Bounded_run.probe ~seconds:5. args with
  | Ok lines -> lines
  | Error reason -> Alcotest.failf "%s: %s" name reason

let no_wait_tests =
  [
    case "no read waits on a FIFO or a device, as the interface promises"
      (fun () ->
        let root = real_tree () in
        List.iter
          (fun (name, link) ->
            Alcotest.(check (list string))
              name
              [
                "Error not a regular file";
                "Error not a regular file";
                "Error not a folder";
                "Error not a folder";
                (match link with
                | None -> "Ok other kind"
                | Some _ -> "Ok symbolic link");
                (match link with
                | None -> "Error not a symbolic link"
                | Some target -> Printf.sprintf "Ok %S" target);
              ]
              (probe name [ "files"; root / name ]))
          [
            ("pipe", None);
            ("pipelink", Some "pipe");
            ("zero", Some "/dev/zero");
            ("null", Some "/dev/null");
          ]);
    case "no read waits on a socket, as the interface promises" (fun () ->
        let root = real_tree () in
        Alcotest.(check (list string))
          "the results"
          [
            "Error not a regular file";
            "Error not a folder";
            "Error not a folder";
          ]
          (probe "socket" [ "socket"; root ]));
  ]

type state = {
  name : string;
  inode : int;
  kind : Unix.file_kind;
  perm : int;
  mtime : float;
  ctime : float;
  content : string;
}

let rec states root name =
  let path = if name = "" then root else root / name in
  let stat = Unix.lstat path in
  let content =
    match stat.st_kind with
    | Unix.S_REG -> In_channel.with_open_bin path In_channel.input_all
    | Unix.S_LNK -> Unix.readlink path
    | _ -> ""
  in
  let here =
    {
      name;
      inode = stat.st_ino;
      kind = stat.st_kind;
      perm = stat.st_perm;
      mtime = stat.st_mtime;
      ctime = stat.st_ctime;
      content;
    }
  in
  match stat.st_kind with
  | Unix.S_DIR ->
      here
      :: List.concat_map
           (fun entry ->
             states root (if name = "" then entry else name / entry))
           (List.sort String.compare (Array.to_list (Sys.readdir path)))
  | _ -> [ here ]

let read_everything root =
  check_result "read" quoted (Ok "content\n")
    (Files.read ~max_size:big (root / "f"));
  check_result "read d/a" quoted (Ok "a")
    (Files.read ~max_size:big (root / "dlink" / "a"));
  check_result "range" quoted (Ok "ont")
    (match
       Files.with_file (root / "link") (fun handle ->
           Files.read_range handle ~offset:1 ~length:3)
     with
    | Ok range -> range
    | Error failure -> Error failure);
  check_result "list" names (Ok [ "a"; "b"; "sub" ]) (Files.list (root / "d"));
  List.iter
    (fun name ->
      ignore (Files.read ~max_size:big (root / name));
      ignore (Files.with_file (root / name) Files.size);
      ignore (Files.list (root / name));
      ignore (Files.link_kind (root / name));
      ignore (Files.link_text (root / name)))
    [
      "f";
      "d";
      "link";
      "link2";
      "dlink";
      "dangling";
      "loop";
      "pipe";
      "pipelink";
      "zero";
      "null";
      "gone";
    ]

let unchanged root before =
  let after = states root "" in
  Alcotest.(check (list string))
    "the files"
    (List.map (fun s -> s.name) before)
    (List.map (fun s -> s.name) after);
  List.iter2
    (fun a b -> Alcotest.(check bool) ("unchanged: " ^ a.name) true (a = b))
    before after

(* @verifies changes#leave-repositories-unchanged=v1
   The reads run on a tree whose files and folders are writable, so that a
   creation, a deletion, or a change by a read would take place. The test
   compares the names of the files, the kind and the inode of each file, the
   content of each regular file, and the reference of each symbolic link before
   and after the reads, so a file that a read creates, deletes, or changes, as
   the term undisturbed-read gives these words, fails it. No read makes an own
   change: none of these files is a loose object, a pack, git's index, or a
   lock file. The test also compares the permissions and the times of change of
   each file, by the promise of the interface of the reads that nothing changes
   an attribute of a file. It cannot see a change that is made and undone
   during the reads, nor a read that takes the data of a FIFO. *)
let unchanged_tests =
  [
    case "the reads create, delete, or change no file" (fun () ->
        let root = real_tree () in
        let before = states root "" in
        read_everything root;
        unchanged root before);
    case "no read opens a file for writing, as the interface promises"
      (fun () ->
        let root = real_tree () in
        List.iter
          (fun name -> Unix.chmod (root / name) 0o444)
          [ "f"; "d" / "a"; "d" / "b" ];
        List.iter
          (fun name -> Unix.chmod (root / name) 0o555)
          [ "d" / "sub"; "d" ];
        Fun.protect
          ~finally:(fun () ->
            Unix.chmod (root / "d") 0o755;
            Unix.chmod (root / "d" / "sub") 0o755)
          (fun () ->
            let before = states root "" in
            read_everything root;
            unchanged root before));
    case "no read takes the data of a FIFO, as the interface promises"
      (fun () ->
        let root = real_tree () in
        let fifo = root / "pipe" and data = "the data of the FIFO" in
        let reader =
          Unix.openfile fifo
            [ Unix.O_RDONLY; Unix.O_NONBLOCK; Unix.O_CLOEXEC ]
            0
        in
        Fun.protect
          ~finally:(fun () -> Unix.close reader)
          (fun () ->
            let writer =
              Unix.openfile fifo
                [ Unix.O_WRONLY; Unix.O_NONBLOCK; Unix.O_CLOEXEC ]
                0
            in
            Fun.protect
              ~finally:(fun () -> Unix.close writer)
              (fun () ->
                ignore (Unix.write_substring writer data 0 (String.length data));
                List.iter
                  (fun name -> ignore (probe name [ "files"; root / name ]))
                  [ "pipe"; "pipelink" ];
                let buffer = Bytes.create 256 in
                let count =
                  try Unix.read reader buffer 0 (Bytes.length buffer)
                  with
                  | Unix.Unix_error ((Unix.EAGAIN | Unix.EWOULDBLOCK), _, _) ->
                    0
                in
                Alcotest.(check string)
                  "the data" data
                  (Bytes.sub_string buffer 0 count))));
  ]

(* @verifies changes#read-only-repository-files=v1
   On a system in memory that records each call, a read, a ranged read, a
   listing, and a link read through a chain of links make calls only on the
   pathname that the caller gives, so the reads take bytes only from the file
   at that pathname and the symbolic links on it, item 1 of the list of the
   requirement; a call on another pathname fails the test. The test does not
   see which pathnames the callers of the reads give, nor the files that the
   system or a C library reads by itself. *)
let only_given_pathnames_tests =
  [
    case "each read makes calls only on the pathname that its caller gives"
      (fun () ->
        let check_calls label run =
          fresh ();
          run ();
          List.iter
            (fun call ->
              match String.index_opt call ' ' with
              | Some space ->
                  let verb = String.sub call 0 space
                  and rest =
                    String.sub call (space + 1) (String.length call - space - 1)
                  in
                  if
                    List.mem verb
                      [
                        "stat"; "lstat"; "open_file"; "open_folder"; "readlink";
                      ]
                  then
                    Alcotest.(check string) (label ^ ": " ^ call) "link2" rest
              | None -> ())
            (calls ())
        in
        check_calls "read" (fun () ->
            ignore (Reader.read ~max_size:big "link2"));
        check_calls "with_file" (fun () ->
            ignore
              (Reader.with_file "link2" (fun handle ->
                   Reader.read_range handle ~offset:0 ~length:3)));
        check_calls "link_kind" (fun () -> ignore (Reader.link_kind "link2"));
        check_calls "link_text" (fun () -> ignore (Reader.link_text "link2"));
        Fake.reset (fake_tree @ [ ("link2", Fake.Link "dlink") ]);
        check_calls "list" (fun () -> ignore (Reader.list "link2"));
        check_calls "folder_identity" (fun () ->
            ignore (Reader.folder_identity "link2")));
  ]

let tests =
  fake_read_tests @ error_tests @ later_error_tests @ fault_properties
  @ chunked_properties @ max_size_tests @ with_file_tests @ list_tests
  @ folder_identity_tests @ link_tests @ real_read_tests @ no_wait_tests
  @ unchanged_tests @ only_given_pathnames_tests
