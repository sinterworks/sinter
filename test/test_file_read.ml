(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen

type answer = { result : string; text : string option }

let answer_of = function
  | Sinter_file_read.Invalid -> { result = "invalid"; text = None }
  | Sinter_file_read.Found text ->
      { result = "found"; text = Some (Text.encode text) }
  | Sinter_file_read.No_file -> { result = "no file"; text = None }
  | Sinter_file_read.Symbolic_link -> { result = "symbolic link"; text = None }
  | Sinter_file_read.Not_a_regular_file ->
      { result = "not a regular file"; text = None }
  | Sinter_file_read.Not_utf_8 -> { result = "not UTF-8"; text = None }
  | Sinter_file_read.Cannot_read -> { result = "cannot read"; text = None }

let limit_name = function
  | Sinter_file_read.Descriptors -> "Descriptors"
  | Sinter_file_read.Memory -> "Memory"
  | Sinter_file_read.File_size -> "File_size"
  | Sinter_file_read.Pathname_length -> "Pathname_length"

let show_failure = function
  | Sinter_file_read.Stopped { limit; names } ->
      Printf.sprintf "Stopped (%s, [%s])" (limit_name limit)
        (String.concat "; " (List.map String.escaped names))
  | Sinter_file_read.Failed { names; error } ->
      Printf.sprintf "Failed ([%s], %s)"
        (String.concat "; " (List.map String.escaped names))
        (Unix.error_message error)
  | Sinter_file_read.Changed names ->
      Printf.sprintf "Changed [%s]"
        (String.concat "; " (List.map String.escaped names))

let read_text ~root text =
  match Sinter_file_read.read ~root text with
  | Ok outcome -> answer_of outcome
  | Error failure ->
      Alcotest.failf "the file read gave no result: %s" (show_failure failure)

let uchars_of_string string =
  let rec go index acc =
    if index >= String.length string then List.rev acc
    else
      let decode = String.get_utf_8_uchar string index in
      go
        (index + Uchar.utf_decode_length decode)
        (Uchar.utf_decode_uchar decode :: acc)
  in
  go 0 []

let text_of string = Text.of_uchars (uchars_of_string string)

let json_member name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other ->
      Alcotest.failf "not a JSON object: %s" (Yojson.Basic.to_string other)

let json_string = function
  | `String text -> text
  | other ->
      Alcotest.failf "not a JSON string: %s" (Yojson.Basic.to_string other)

let files_set = Vectors.read "files"

let tree_of (vector : Vectors.vector) =
  Files_tree.of_json (json_member "tree" vector.input)

let need_holds =
  [
    ("names-kept", true);
    ("no-privilege", true);
    ("non-utf-8-names", not (String.equal (Files_tree.system ()) "macos"));
    ("other-owner", Files_tree.effective_root ());
  ]

let unmet_needs (vector : Vectors.vector) =
  List.filter
    (fun need ->
      not (Option.value (List.assoc_opt need need_holds) ~default:true))
    vector.needs

let skipped =
  List.filter_map
    (fun (vector : Vectors.vector) ->
      match unmet_needs vector with
      | [] -> None
      | needs -> Some (vector.line, needs))
    (Vectors.vectors files_set "file-reads")

let outcomes = Hashtbl.create 64

let outcome (vector : Vectors.vector) =
  match Hashtbl.find_opt outcomes vector.line with
  | Some outcome -> outcome
  | None ->
      let text = text_of (json_string (json_member "text" vector.input)) in
      let outcome =
        Files_tree.run (tree_of vector) (fun root -> read_text ~root text)
      in
      Hashtbl.replace outcomes vector.line outcome;
      outcome

let one_piece text =
  `List [ `Assoc [ ("text", `String text); ("times", `Int 1) ] ]

let values_json (vector : Vectors.vector) answer =
  match (answer.text, vector.values) with
  | None, _ -> `Assoc []
  | Some text, Some (`Assoc [ ("text", pieces) ])
    when String.equal text (Files_tree.text_of_pieces pieces) ->
      `Assoc [ ("text", pieces) ]
  | Some text, _ when String.length text > 1000 ->
      `Assoc [ ("text", one_piece (String.sub text 0 1000 ^ "...")) ]
  | Some text, _ -> `Assoc [ ("text", one_piece text) ]

let answer_json vector answer =
  `Assoc
    [ ("result", `String answer.result); ("values", values_json vector answer) ]

let give_file_read (vector : Vectors.vector) =
  match outcome vector with
  | Files_tree.Not_stored reason ->
      Alcotest.failf "no file system stores the folder tree: %s" reason
  | Files_tree.Read { changes = []; value } -> answer_json vector value
  | Files_tree.Read { changes; _ } ->
      Alcotest.failf "the file read changed the folder tree: %s"
        (String.concat "; " changes)

(* @verifies files[file-reads]
   The vectors check the result of a file read, and the text of the content
   with "found", for a text in a folder tree that the test makes. *)
let file_read_vectors =
  Vectors.group files_set ~name:"file-reads" ~form:"#file-read-vector=v1"
    ~needs:need_holds ~skipped give_file_read

let reference text (tree : Files_tree.file) =
  let open Files_tree in
  let answer result = { result; text = None } in
  let rec walk (folder : file) = function
    | [] -> answer "no file"
    | name :: rest -> (
        match folder.kind with
        | Folder entries -> (
            if not (folder.permissions.search && folder.permissions.read) then
              answer "cannot read"
            else
              let bytes = Text.encode (Text.of_uchars name) in
              match List.assoc_opt bytes entries with
              | None -> answer "no file"
              | Some file -> (
                  match (file.kind, rest) with
                  | Link _, _ -> answer "symbolic link"
                  | Folder _, _ :: _ -> walk file rest
                  | (Regular _ | Pipe), _ :: _ -> answer "no file"
                  | (Folder _ | Pipe), [] -> answer "not a regular file"
                  | Regular _, [] when not file.permissions.read ->
                      answer "cannot read"
                  | Regular pieces, [] ->
                      let content = bytes_of_pieces pieces in
                      if String.is_valid_utf_8 content then
                        { result = "found"; text = Some content }
                      else answer "not UTF-8"))
        | Regular _ | Link _ | Pipe -> answer "no file")
  in
  let uchars = uchars_of_string text in
  if Paths_reference.is_path uchars then
    walk tree (Paths_reference.file_names uchars)
  else answer "invalid"

let permissions_gen ~folder =
  let flag weight =
    Gen.oneof_weighted [ (weight, Gen.return true); (1, Gen.return false) ]
  in
  Gen.map3
    (fun read search write : Files_tree.permissions ->
      { read; search = (if folder then search else true); write })
    (flag 6) (flag 6) (flag 9)

let content_gen =
  Gen.map (String.concat "")
    (Gen.list_size (Gen.int_bound 4)
       (Gen.oneof_list
          [
            "hi";
            "\xff";
            "\xc3\xa9";
            "\xc3";
            "\r\n";
            "\xef\xbb\xbf";
            "\xed\xa0\x80";
            "\xc0\xaf";
            "\x00";
          ]))

let name_classes =
  [ [ "a" ]; [ "b" ]; [ "\xc3\xa9"; "e\xcc\x81" ]; [ "..." ]; [ "d" ] ]

let file_gen =
  Gen.fix (fun self depth ->
      let leaf =
        [
          ( 3,
            Gen.map2
              (fun content permissions ->
                {
                  Files_tree.kind = Regular [ (content, 1) ];
                  permissions;
                  owned_by_other = false;
                })
              content_gen
              (permissions_gen ~folder:false) );
          ( 1,
            Gen.map
              (fun reference ->
                {
                  Files_tree.kind = Link reference;
                  permissions = { read = true; search = true; write = true };
                  owned_by_other = false;
                })
              (Gen.oneof_list [ "a"; "."; ".."; "d/a"; "missing" ]) );
          ( 1,
            Gen.map
              (fun permissions ->
                { Files_tree.kind = Pipe; permissions; owned_by_other = false })
              (permissions_gen ~folder:false) );
        ]
      in
      if depth = 0 then Gen.oneof_weighted leaf
      else
        Gen.oneof_weighted
          (( 3,
             Gen.map2
               (fun entries permissions ->
                 {
                   Files_tree.kind = Folder entries;
                   permissions;
                   owned_by_other = false;
                 })
               ( self (depth - 1) |> fun file ->
                 Gen.map List.concat
                   (Gen.flatten_list
                      (List.map
                         (fun names ->
                           Gen.oneof_weighted
                             [
                               (1, Gen.return []);
                               ( 1,
                                 Gen.map2
                                   (fun name file -> [ (name, file) ])
                                   (Gen.oneof_list names) file );
                             ])
                         name_classes)) )
               (permissions_gen ~folder:true) )
          :: leaf))

let tree_gen =
  Gen.map2
    (fun file permissions ->
      match file.Files_tree.kind with
      | Folder _ -> { file with permissions }
      | _ -> { file with kind = Folder [ ("a", file) ] })
    (file_gen 3)
    (permissions_gen ~folder:true)

let path_text_gen =
  Gen.oneof_weighted
    [
      ( 6,
        Gen.map (String.concat "/")
          (Gen.list_size (Gen.int_range 1 4)
             (Gen.oneof_list
                [ "a"; "A"; "b"; "\xc3\xa9"; "e\xcc\x81"; "..."; "d"; "x" ])) );
      ( 1,
        Gen.oneof_list
          [ ""; "/a"; "a/"; "./a"; "a//b"; ".."; "a\x00"; "d/../a" ] );
    ]

let rec print_file (file : Files_tree.file) =
  let flags =
    (if file.permissions.read then "" else " -r")
    ^ (if file.permissions.search then "" else " -x")
    ^ if file.permissions.write then "" else " -w"
  in
  match file.kind with
  | Folder entries ->
      Printf.sprintf "{%s%s }" flags
        (String.concat ""
           (List.map
              (fun (name, file) ->
                Printf.sprintf " %s: %s;" (String.escaped name)
                  (print_file file))
              entries))
  | Regular pieces ->
      Printf.sprintf "%S%s" (Files_tree.bytes_of_pieces pieces) flags
  | Link reference -> Printf.sprintf "-> %s" (String.escaped reference)
  | Pipe -> "pipe" ^ flags

let print_case (tree, text) =
  Printf.sprintf "text %S in %s" text (print_file tree)

(* @verifies files#{
       give-invalid-for-non-paths=v1, give-file-read-results=v1,
       give-file-text=v1, omit-texts-of-other-results=v1,
       keep-folder-trees-unchanged=v1,
   }
   A result, or a text of the content, that differs from a direct reading of
   file-read-result for a generated folder tree and text fails the
   comparison, and a change to a file of the folder tree fails the check
   after the read. *)
let file_read_follows_the_file_read_result =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:200
       ~name:
         "a file read in a generated folder tree gives the file-read result \
          and changes no file" ~print:print_case
       (Gen.pair tree_gen path_text_gen) (fun (tree, text) ->
         match
           Files_tree.run tree (fun root ->
               Sinter_file_read.read ~root (text_of text))
         with
         | Files_tree.Not_stored reason ->
             QCheck2.Test.fail_reportf "not stored: %s" reason
         | Files_tree.Read { value = Error failure; _ } ->
             QCheck2.Test.fail_reportf "unexpected failure: %s"
               (show_failure failure)
         | Files_tree.Read { value = Ok outcome; changes } ->
             changes = [] && answer_of outcome = reference text tree))

let every : Files_tree.permissions =
  { read = true; search = true; write = true }

let file kind : Files_tree.file =
  { kind; permissions = every; owned_by_other = false }

let read_in tree action =
  match Files_tree.run tree action with
  | Files_tree.Not_stored reason -> Alcotest.failf "not stored: %s" reason
  | Files_tree.Read { value; changes = [] } -> value
  | Files_tree.Read { changes; _ } ->
      Alcotest.failf "the file read changed the folder tree: %s"
        (String.concat "; " changes)

let check_result expected answer =
  Alcotest.(check string) "the result" expected answer.result;
  Alcotest.(check (option string)) "the text of the content" None answer.text

(* @verifies files#read-only-named-files=v1
   A program that took a byte from the pipe `p`, which is not a regular file
   that the last file name names, leaves the test no byte to read from the
   pipe. *)
let pipe_keeps_its_data () =
  let outcome =
    Files_tree.run
      (file (Folder [ ("p", file Pipe) ]))
      (fun root ->
        let pipe = Filename.concat root "p" in
        let reader = Unix.openfile pipe [ Unix.O_RDONLY; Unix.O_NONBLOCK ] 0 in
        let writer = Unix.openfile pipe [ Unix.O_WRONLY; Unix.O_NONBLOCK ] 0 in
        Fun.protect
          ~finally:(fun () ->
            Unix.close writer;
            Unix.close reader)
          (fun () ->
            ignore (Unix.write_substring writer "x" 0 1);
            let answers =
              List.map
                (fun text -> read_text ~root (text_of text))
                [ "p"; "p/x" ]
            in
            let buffer = Bytes.create 8 in
            let length = Unix.read reader buffer 0 8 in
            (answers, Bytes.sub_string buffer 0 length)))
  in
  let answers, data =
    match outcome with
    | Files_tree.Not_stored reason -> Alcotest.failf "not stored: %s" reason
    | Files_tree.Read { value; changes } ->
        let times_of_p change =
          List.mem change
            [
              "root/p: the time of last change of the data";
              "root/p: the time of last change of the status";
            ]
        in
        Alcotest.(check (list string))
          "the changes other than the times of the pipe that the test wrote" []
          (List.filter (fun change -> not (times_of_p change)) changes);
        value
  in
  (match answers with
  | [ last; inside ] ->
      check_result "not a regular file" last;
      check_result "no file" inside
  | _ -> Alcotest.fail "two answers");
  Alcotest.(check string) "the data in the pipe" "x" data

(* @verifies files#avoid-waits=v1
   A program that waited for a process to open the other end of a pipe that
   no process opens gives no result before the time limit, and the test
   fails. *)
let pipe_with_no_opener_ends_the_read () =
  let answers =
    read_in
      (file
         (Folder [ ("p", file Pipe); ("d", file (Folder [ ("q", file Pipe) ])) ]))
      (fun root ->
        List.map
          (fun text -> read_text ~root (text_of text))
          [ "p"; "d/q"; "p/x" ])
  in
  List.iter2 check_result
    [ "not a regular file"; "not a regular file"; "no file" ]
    answers

let with_outside_pipe action =
  let outside = Filename.temp_dir "sinter-outside-" "" in
  let pipe = Filename.concat outside "p" in
  Fun.protect
    ~finally:(fun () ->
      Sys.remove pipe;
      Unix.rmdir outside)
    (fun () ->
      Unix.mkfifo pipe 0o600;
      Unix.chmod outside 0o755;
      Unix.chmod pipe 0o666;
      action outside pipe)

(* @verifies files#{follow-no-symbolic-links=v1, read-only-named-files=v1}
   A program that found the pipe outside the folder tree by the reference of
   the symbolic link `d` and opened it would end the wait of its writer, and
   the test checks that the writer still waits. *)
let link_out_of_the_tree_finds_no_pipe () =
  with_outside_pipe (fun outside pipe ->
      let answer, waiting =
        read_in
          (file (Folder [ ("d", file (Link outside)) ]))
          (fun root ->
            match Unix.fork () with
            | 0 ->
                (try ignore (Unix.openfile pipe [ Unix.O_WRONLY ] 0)
                 with _ -> ());
                Unix._exit 0
            | writer ->
                Fun.protect
                  ~finally:(fun () ->
                    (try Unix.kill writer Sys.sigkill
                     with Unix.Unix_error _ -> ());
                    ignore (Unix.waitpid [] writer))
                  (fun () ->
                    Unix.sleepf 0.2;
                    let answer = read_text ~root (text_of "d/p") in
                    Unix.sleepf 0.1;
                    let pid, _ = Unix.waitpid [ Unix.WNOHANG ] writer in
                    (answer, pid = 0)))
      in
      check_result "symbolic link" answer;
      Alcotest.(check bool) "the writer still waits" true waiting)

let identity () =
  ( Unix.getuid (),
    Unix.geteuid (),
    Unix.getgid (),
    Unix.getegid (),
    List.sort compare (Array.to_list (Unix.getgroups ())) )

(* @verifies files#{gain-no-privileges=v1, keep-folder-trees-unchanged=v1}
   A program that changed the mode or the owner of `docs`, or the user IDs or
   the group IDs of its process, to read `docs/a.md` fails the check of the
   folder tree or of the IDs after the read. *)
let folder_with_no_permissions_stays_as_it_is () =
  let docs : Files_tree.file =
    {
      kind = Folder [ ("a.md", Files_tree.regular "hi") ];
      permissions = { read = false; search = false; write = true };
      owned_by_other = false;
    }
  in
  let answer, same =
    read_in
      (file (Folder [ ("docs", docs) ]))
      (fun root ->
        let before = identity () in
        let answer = read_text ~root (text_of "docs/a.md") in
        (answer, before = identity ()))
  in
  check_result "cannot read" answer;
  Alcotest.(check bool)
    "the user IDs and the group IDs of the process" true same

(* @verifies files#give-file-read-results=v1
   @verifies conformance#report-missing-parts=v1
   The result for the valid path `docs` does not need the folder entries of
   `docs`, so a program that reports "cannot read" when `docs` lacks read and
   search permissions fails the check. *)
let folder_without_permissions_as_last_name_is_not_a_regular_file () =
  let docs : Files_tree.file =
    {
      kind = Folder [ ("a.md", Files_tree.regular "hi") ];
      permissions = { read = false; search = false; write = true };
      owned_by_other = false;
    }
  in
  let answer =
    read_in
      (file (Folder [ ("docs", docs) ]))
      (fun root -> read_text ~root (text_of "docs"))
  in
  check_result "not a regular file" answer

(* @verifies files#give-file-read-results=v1
   A program that took the error of a lookup of a long name for "no file",
   and did not check the search permission of `docs` first, gives "no file"
   in place of "cannot read". *)
let long_name_in_a_folder_with_no_search_permission () =
  let docs : Files_tree.file =
    {
      kind = Folder [ ("a.md", Files_tree.regular "hi") ];
      permissions = { read = true; search = false; write = true };
      owned_by_other = false;
    }
  in
  let answers =
    read_in
      (file (Folder [ ("docs", docs) ]))
      (fun root ->
        List.map
          (fun length ->
            read_text ~root (text_of ("docs/" ^ String.make length 'a')))
          [ 255; 256; 300; 1025; 5000 ])
  in
  List.iter (check_result "cannot read") answers

let open_descriptors () = Array.length (Sys.readdir "/dev/fd")

let read_closes_each_descriptor () =
  let tree =
    file
      (Folder
         [
           ("a.md", Files_tree.regular "hi");
           ("bad", Files_tree.regular "\xff");
           ("d", file (Folder [ ("a.md", Files_tree.regular "hi") ]));
           ("l", file (Link "a.md"));
           ("p", file Pipe);
         ])
  in
  let counts =
    read_in tree (fun root ->
        let before = open_descriptors () in
        List.iter
          (fun text -> ignore (read_text ~root (text_of text)))
          [
            "a.md";
            "bad";
            "d/a.md";
            "d/b";
            "d";
            "l";
            "l/x";
            "p";
            "p/x";
            "a.md/x";
            "/x";
            "x";
          ];
        (before, open_descriptors ()))
  in
  Alcotest.(check int) "the open file descriptors" (fst counts) (snd counts)

let root_that_is_no_folder_fails () =
  let file_root = Filename.temp_file "sinter-root-" "" in
  Fun.protect
    ~finally:(fun () -> Sys.remove file_root)
    (fun () ->
      List.iter
        (fun root ->
          (match Sinter_file_read.read ~root (text_of "a.md") with
          | Error (Sinter_file_read.Failed { names = []; _ }) -> ()
          | Error failure ->
              Alcotest.failf "read of %s gave %s" (String.escaped root)
                (show_failure failure)
          | Ok outcome ->
              Alcotest.failf "read of %s gave %s" (String.escaped root)
                (answer_of outcome).result);
          (match Sinter_file_read.walk ~root with
          | Error (Sinter_file_read.Failed { names = []; _ }) -> ()
          | Error failure ->
              Alcotest.failf "walk of %s gave %s" (String.escaped root)
                (show_failure failure)
          | Ok _ ->
              Alcotest.failf "walk of %s gave a tree" (String.escaped root));
          (match Sinter_file_read.walk_contents ~root Fun.id with
          | Error (Sinter_file_read.Failed { names = []; _ }) -> ()
          | Error failure ->
              Alcotest.failf "walk_contents of %s gave %s" (String.escaped root)
                (show_failure failure)
          | Ok _ ->
              Alcotest.failf "walk_contents of %s gave a tree"
                (String.escaped root));
          match Sinter_file_read.content ~root [ "a.md" ] with
          | Error (Sinter_file_read.Failed { names = []; _ }) -> ()
          | Error failure ->
              Alcotest.failf "content of %s gave %s" (String.escaped root)
                (show_failure failure)
          | Ok _ ->
              Alcotest.failf "content of %s gave a result" (String.escaped root))
        [
          file_root;
          file_root ^ ".missing";
          Filename.get_temp_dir_name () ^ "/a\x00b";
        ])

(* @verifies files#give-file-read-results=v1
   @verifies conformance#report-stops-at-limits=v1
   A root pathname longer than the system allows stops at the pathname length
   limit at the root and gives none of the file-read results. *)
let root_pathname_too_long_stops_at_limit () =
  let long_root = String.concat "/" (List.init 2500 (fun _ -> "a")) in
  let check_stopped what = function
    | Error
        (Sinter_file_read.Stopped
           { limit = Sinter_file_read.Pathname_length; names = [] }) ->
        ()
    | Error failure -> Alcotest.failf "%s gave %s" what (show_failure failure)
    | Ok _ -> Alcotest.failf "%s gave a result" what
  in
  check_stopped "read" (Sinter_file_read.read ~root:long_root (text_of "a.md"));
  check_stopped "walk" (Sinter_file_read.walk ~root:long_root);
  check_stopped "walk_contents"
    (Sinter_file_read.walk_contents ~root:long_root Fun.id);
  check_stopped "content" (Sinter_file_read.content ~root:long_root [ "a.md" ])

let invalid_text_is_invalid_with_any_root () =
  List.iter
    (fun root -> check_result "invalid" (read_text ~root (text_of "../a.md")))
    [ Filename.get_temp_dir_name () ^ "/sinter-no-such-root"; "a\x00b"; "" ]

(* @cites files#file-object=v1
   Files_tree.of_json rejects every entry name that is empty, holds 0x00 or
   0x2F, or equals "." or "..". It rejects every symbolic link reference that
   is empty or holds 0x00. It accepts boundary valid entry names and symbolic
   link references, including a reference that holds "/". *)
let file_object_rejects_invalid_names_and_references () =
  let regular_json =
    `Assoc [ ("type", `String "regular file"); ("content", `List []) ]
  in
  let dir_with_name hex =
    `Assoc
      [
        ("type", `String "directory");
        ( "entries",
          `List [ `Assoc [ ("name", `String hex); ("file", regular_json) ] ] );
      ]
  in
  let link_with_ref hex =
    `Assoc [ ("type", `String "symbolic link"); ("reference", `String hex) ]
  in
  let check_rejected label json =
    match Files_tree.of_json json with
    | _ -> Alcotest.failf "%s was accepted" label
    | exception Failure _ -> ()
  in
  let check_accepted label json =
    match Files_tree.of_json json with
    | _ -> ()
    | exception Failure message ->
        Alcotest.failf "%s was rejected: %s" label message
  in
  List.iter
    (fun (label, hex) -> check_rejected label (dir_with_name hex))
    [
      ("empty entry name", "");
      ("entry name with NUL", "610062");
      ("entry name with slash", "612f62");
      ("entry name dot", "2e");
      ("entry name dot-dot", "2e2e");
    ];
  List.iter
    (fun (label, hex) -> check_rejected label (link_with_ref hex))
    [ ("empty reference", ""); ("reference with NUL", "610062") ];
  List.iter
    (fun (label, hex) -> check_accepted label (dir_with_name hex))
    [
      ("entry name three dots", "2e2e2e");
      ("entry name leading dot", "2e61");
      ("entry name non-UTF-8 byte", "ff");
    ];
  List.iter
    (fun (label, hex) -> check_accepted label (link_with_ref hex))
    [
      ("reference with slash", "612f62");
      ("reference dot", "2e");
      ("reference dot-dot", "2e2e");
      ("reference non-UTF-8 byte", "ff");
    ]

type call =
  | Open_root
  | Open_folder
  | Open_file
  | Kind
  | Check_search
  | Listing
  | Is_regular_file
  | Content
  | Close

type fault = Fails of Unix.error | Sys_fails | Raises of exn | Not_regular

module type FAULTS = sig
  val tree : Files_tree.file
  val fault : call -> string -> fault option
end

let fake_eilseq = 4242
let fake_estale = 4243
let fold name = String.lowercase_ascii name

module Fake (F : FAULTS) = struct
  type descr = int

  let opened : (int, Files_tree.file) Hashtbl.t = Hashtbl.create 8
  let calls = ref []
  let targets = ref []
  let paths : (int, string list) Hashtbl.t = Hashtbl.create 8
  let next = ref 0
  let peak = ref 0
  let double_closes = ref 0
  let path_of descr = Option.value (Hashtbl.find_opt paths descr) ~default:[]

  let enter call path =
    calls := call :: !calls;
    targets := (call, path) :: !targets;
    let name = String.concat "/" path in
    match F.fault call name with
    | Some (Fails error) -> raise (Unix.Unix_error (error, "fake", name))
    | Some Sys_fails -> raise (Sys_error "fake")
    | Some (Raises error) -> raise error
    | Some Not_regular | None -> ()

  let node descr =
    match Hashtbl.find_opt opened descr with
    | Some file -> file
    | None -> raise (Unix.Unix_error (Unix.EBADF, "fake", ""))

  let fresh ?(path = []) file =
    incr next;
    Hashtbl.replace opened !next file;
    Hashtbl.replace paths !next path;
    peak := max !peak (Hashtbl.length opened);
    !next

  let entries (folder : Files_tree.file) =
    match folder.kind with
    | Files_tree.Folder entries -> entries
    | _ -> raise (Unix.Unix_error (Unix.ENOTDIR, "fake", ""))

  let lookup descr name =
    let folder = node descr in
    if not folder.permissions.search then
      raise (Unix.Unix_error (Unix.EACCES, "fake", name));
    let entries = entries folder in
    match List.assoc_opt name entries with
    | Some file -> file
    | None -> (
        match
          List.find_opt (fun (entry, _) -> fold entry = fold name) entries
        with
        | Some (_, file) -> file
        | None -> raise (Unix.Unix_error (Unix.ENOENT, "fake", name)))

  let readable (file : Files_tree.file) =
    if not file.permissions.read then
      raise (Unix.Unix_error (Unix.EACCES, "fake", ""))

  let open_root name =
    ignore name;
    enter Open_root [];
    readable F.tree;
    fresh F.tree

  let open_folder descr name =
    let path = path_of descr @ [ name ] in
    enter Open_folder path;
    let file = lookup descr name in
    (match file.kind with
    | Files_tree.Link _ -> raise (Unix.Unix_error (Unix.ELOOP, "fake", name))
    | Files_tree.Folder _ -> ()
    | _ -> raise (Unix.Unix_error (Unix.ENOTDIR, "fake", name)));
    readable file;
    fresh ~path file

  let open_file descr name =
    let path = path_of descr @ [ name ] in
    enter Open_file path;
    let file = lookup descr name in
    (match file.kind with
    | Files_tree.Link _ -> raise (Unix.Unix_error (Unix.ELOOP, "fake", name))
    | _ -> ());
    readable file;
    fresh ~path file

  let kind descr name : Sinter_file_read.kind =
    enter Kind (path_of descr @ [ name ]);
    match (lookup descr name).kind with
    | Files_tree.Folder _ -> Folder
    | Files_tree.Regular _ -> Regular_file
    | Files_tree.Link _ -> Symbolic_link
    | Files_tree.Pipe -> Other_kind

  let check_search descr =
    enter Check_search (path_of descr);
    if not (node descr).permissions.search then
      raise (Unix.Unix_error (Unix.EACCES, "fake", "."))

  let listing descr =
    enter Listing (path_of descr);
    ".." :: List.rev ("." :: List.map fst (entries (node descr)))

  let is_regular_file descr =
    enter Is_regular_file (path_of descr);
    match
      ( (node descr).kind,
        F.fault Is_regular_file (String.concat "/" (path_of descr)) )
    with
    | _, Some Not_regular -> false
    | Files_tree.Regular _, _ -> true
    | _ -> false

  let content descr =
    enter Content (path_of descr);
    match (node descr).kind with
    | Files_tree.Regular pieces -> Files_tree.bytes_of_pieces pieces
    | _ -> raise (Unix.Unix_error (Unix.EISDIR, "fake", ""))

  let close descr =
    if not (Hashtbl.mem opened descr) then (
      incr double_closes;
      raise (Unix.Unix_error (Unix.EBADF, "fake", "")));
    let path = path_of descr in
    Hashtbl.remove opened descr;
    enter Close path

  let eilseq = fake_eilseq
  let estale = fake_estale
  let enotsup = 4244
end

type fake_read = {
  answer : ((answer, Sinter_file_read.failure) result, exn) result;
  open_after : int;
  double_closes : int;
  calls : call list;
  targets : (call * string list) list;
}

let fake_read ?(fault = fun _ _ -> None) tree text =
  let module S = Fake (struct
    let tree = tree
    let fault = fault
  end) in
  let module W = Sinter_file_read.Walk (S) in
  let answer =
    match W.read ~root:"root" (text_of text) with
    | Ok outcome -> Ok (Ok (answer_of outcome))
    | Error failure -> Ok (Error failure)
    | exception error -> Error error
  in
  {
    answer;
    open_after = Hashtbl.length S.opened;
    double_closes = !S.double_closes;
    calls = List.rev !S.calls;
    targets = List.rev !S.targets;
  }

let check_fake_result expected read =
  (match read.answer with
  | Ok (Ok answer) -> check_result expected answer
  | Ok (Error failure) ->
      Alcotest.failf "the read gave failure %s" (show_failure failure)
  | Error error ->
      Alcotest.failf "the read raised %s" (Printexc.to_string error));
  Alcotest.(check int) "the descriptors left open" 0 read.open_after;
  Alcotest.(check int) "the double closes" 0 read.double_closes

let check_fake_failure expected read =
  (match read.answer with
  | Ok (Error failure) ->
      if failure <> expected then
        Alcotest.failf "expected %s, got %s" (show_failure expected)
          (show_failure failure)
  | Ok (Ok answer) ->
      Alcotest.failf "expected %s, got result %s" (show_failure expected)
        answer.result
  | Error error ->
      Alcotest.failf "the read raised %s" (Printexc.to_string error));
  Alcotest.(check int) "the descriptors left open" 0 read.open_after;
  Alcotest.(check int) "the double closes" 0 read.double_closes

let fake_tree =
  file
    (Folder
       [
         ("a.md", Files_tree.regular "hi");
         ("d", file (Folder [ ("a.md", Files_tree.regular "hi") ]));
       ])

let on call error = fun called _ -> if called = call then Some error else None

let at call path =
 fun called name ->
  if called = call && String.equal name (String.concat "/" path) then Some ()
  else None

let call_name = function
  | Open_root -> "open_root"
  | Open_folder -> "open_folder"
  | Open_file -> "open_file"
  | Kind -> "kind"
  | Check_search -> "check_search"
  | Listing -> "listing"
  | Is_regular_file -> "is_regular_file"
  | Content -> "content"
  | Close -> "close"

let name_rejected_errors =
  [ Unix.ENOENT; Unix.ENAMETOOLONG; Unix.EINVAL; Unix.EUNKNOWNERR fake_eilseq ]

let missing_part_errors =
  [
    Unix.EACCES;
    Unix.EPERM;
    Unix.EIO;
    Unix.ENXIO;
    Unix.ENODEV;
    Unix.ETIMEDOUT;
    Unix.ECONNABORTED;
    Unix.ECONNRESET;
    Unix.ENOTCONN;
    Unix.ENETDOWN;
    Unix.ENETRESET;
    Unix.ENETUNREACH;
    Unix.EHOSTUNREACH;
    Unix.EUNKNOWNERR fake_estale;
  ]

let limit_errors =
  [
    (Unix.EMFILE, Sinter_file_read.Descriptors);
    (Unix.ENFILE, Sinter_file_read.Descriptors);
    (Unix.ENOMEM, Sinter_file_read.Memory);
    (Unix.EOVERFLOW, Sinter_file_read.File_size);
  ]

let other_unix_errors =
  [
    Unix.ENOTDIR;
    Unix.ELOOP;
    Unix.EINTR;
    Unix.ENOSYS;
    Unix.EOPNOTSUPP;
    Unix.EBADF;
    Unix.EISDIR;
    Unix.EAGAIN;
    Unix.EPIPE;
    Unix.EHOSTDOWN;
    Unix.EUNKNOWNERR (fake_eilseq + 10);
  ]

let is_name_rejected error = List.mem error name_rejected_errors
let is_missing_part_error error = List.mem error missing_part_errors

let limit_of_error call error =
  match (call, error) with
  | _, (Unix.EMFILE | Unix.ENFILE) -> Some Sinter_file_read.Descriptors
  | _, Unix.ENOMEM -> Some Sinter_file_read.Memory
  | _, Unix.EOVERFLOW -> Some Sinter_file_read.File_size
  | Open_root, Unix.ENAMETOOLONG -> Some Sinter_file_read.Pathname_length
  | _ -> None

let parent_of = function
  | [] -> []
  | names -> List.rev (List.tl (List.rev names))

let expected_read_error call names error =
  if call = Kind && is_name_rejected error then
    Ok { result = "no file"; text = None }
  else if is_missing_part_error error then
    Ok { result = "cannot read"; text = None }
  else
    match limit_of_error call error with
    | Some limit -> Error (Sinter_file_read.Stopped { limit; names })
    | None -> Error (Sinter_file_read.Failed { names; error })

let expected_content_error call names error =
  if call = Kind && is_name_rejected error then
    Ok (Error Sinter_file_read.No_content_file)
  else if is_missing_part_error error then
    let part = if call = Kind then parent_of names else names in
    Ok (Error (Sinter_file_read.Cannot_take part))
  else
    match limit_of_error call error with
    | Some limit -> Error (Sinter_file_read.Stopped { limit; names })
    | None -> Error (Sinter_file_read.Failed { names; error })

(* @verifies files#give-file-read-results=v1
   A program that took a name that the file system does not accept, or that
   is too long for one folder entry, for a missing part or a limit gives a
   result other than "no file". *)
let name_not_accepted_gives_no_file () =
  List.iter
    (fun error ->
      List.iter
        (fun text ->
          check_fake_result "no file"
            (fake_read ~fault:(on Kind (Fails error)) fake_tree text))
        [ "a.md"; "d/a.md"; "b" ])
    name_rejected_errors

(* @verifies files#give-file-read-results=v1
   @verifies conformance#report-missing-parts=v1
   Every refused permission and every input or output error that the
   interface names gives "cannot read" on every call of a file read and
   closes each descriptor. *)
let missing_part_errors_give_cannot_read () =
  let calls =
    [
      (Open_root, [], "a.md");
      (Check_search, [], "a.md");
      (Listing, [], "a.md");
      (Kind, [ "a.md" ], "a.md");
      (Open_file, [ "a.md" ], "a.md");
      (Is_regular_file, [ "a.md" ], "a.md");
      (Content, [ "a.md" ], "a.md");
      (Kind, [ "d" ], "d/a.md");
      (Open_folder, [ "d" ], "d/a.md");
      (Check_search, [ "d" ], "d/a.md");
      (Listing, [ "d" ], "d/a.md");
      (Kind, [ "d"; "a.md" ], "d/a.md");
      (Open_file, [ "d"; "a.md" ], "d/a.md");
      (Is_regular_file, [ "d"; "a.md" ], "d/a.md");
      (Content, [ "d"; "a.md" ], "d/a.md");
    ]
  in
  List.iter
    (fun (call, path, text) ->
      List.iter
        (fun error ->
          let fault called name =
            Option.map (fun () -> Fails error) (at call path called name)
          in
          check_fake_result "cannot read" (fake_read ~fault fake_tree text))
        missing_part_errors)
    calls

(* @verifies files#give-file-read-results=v1
   @verifies conformance#report-stops-at-limits=v1
   Every limit error that the interface names stops the file read with no
   file-read result, names the limit and the file where the read stopped,
   and closes each descriptor. *)
let limit_errors_stop_the_read () =
  let calls =
    [
      (Open_root, [], "a.md");
      (Check_search, [], "a.md");
      (Listing, [], "a.md");
      (Kind, [ "a.md" ], "a.md");
      (Open_file, [ "a.md" ], "a.md");
      (Is_regular_file, [ "a.md" ], "a.md");
      (Content, [ "a.md" ], "a.md");
      (Kind, [ "d" ], "d/a.md");
      (Open_folder, [ "d" ], "d/a.md");
      (Check_search, [ "d" ], "d/a.md");
      (Listing, [ "d" ], "d/a.md");
      (Kind, [ "d"; "a.md" ], "d/a.md");
      (Open_file, [ "d"; "a.md" ], "d/a.md");
      (Is_regular_file, [ "d"; "a.md" ], "d/a.md");
      (Content, [ "d"; "a.md" ], "d/a.md");
    ]
  in
  List.iter
    (fun (call, path, text) ->
      List.iter
        (fun (error, limit) ->
          let fault called name =
            Option.map (fun () -> Fails error) (at call path called name)
          in
          check_fake_failure
            (Sinter_file_read.Stopped { limit; names = path })
            (fake_read ~fault fake_tree text))
        limit_errors;
      let oom_fault called name =
        Option.map (fun () -> Raises Out_of_memory) (at call path called name)
      in
      check_fake_failure
        (Sinter_file_read.Stopped
           { limit = Sinter_file_read.Memory; names = path })
        (fake_read ~fault:oom_fault fake_tree text))
    calls;
  check_fake_failure
    (Sinter_file_read.Stopped
       { limit = Sinter_file_read.Pathname_length; names = [] })
    (fake_read ~fault:(on Open_root (Fails Unix.ENAMETOOLONG)) fake_tree "a.md")

(* @verifies files#give-file-read-results=v1
   Errors outside the missing-part, name-rejected, and limit cases give
   Failed with the file and error number, and never "cannot read". *)
let other_errors_fail_the_read () =
  List.iter
    (fun error ->
      check_fake_failure
        (Sinter_file_read.Failed { names = [ "d"; "a.md" ]; error })
        (fake_read
           ~fault:(fun called name ->
             Option.map
               (fun () -> Fails error)
               (at Kind [ "d"; "a.md" ] called name))
           fake_tree "d/a.md"))
    other_unix_errors;
  List.iter
    (fun (call, path, text) ->
      List.iter
        (fun error ->
          let fault called name =
            Option.map (fun () -> Fails error) (at call path called name)
          in
          check_fake_failure
            (Sinter_file_read.Failed { names = path; error })
            (fake_read ~fault fake_tree text))
        (Unix.ENOENT :: Unix.EINVAL :: Unix.EUNKNOWNERR fake_eilseq
       :: other_unix_errors);
      if call <> Open_root then
        let fault called name =
          Option.map
            (fun () -> Fails Unix.ENAMETOOLONG)
            (at call path called name)
        in
        check_fake_failure
          (Sinter_file_read.Failed { names = path; error = Unix.ENAMETOOLONG })
          (fake_read ~fault fake_tree text))
    [
      (Open_root, [], "a.md");
      (Open_folder, [ "d" ], "d/a.md");
      (Open_file, [ "d"; "a.md" ], "d/a.md");
      (Check_search, [ "d" ], "d/a.md");
      (Listing, [ "d" ], "d/a.md");
      (Is_regular_file, [ "d"; "a.md" ], "d/a.md");
      (Content, [ "d"; "a.md" ], "d/a.md");
    ]

let unix_error_gen =
  Gen.oneof_list
    (name_rejected_errors @ missing_part_errors @ List.map fst limit_errors
   @ other_unix_errors)

(* @verifies files#give-file-read-results=v1
   @verifies conformance#report-missing-parts=v1
   @verifies conformance#report-stops-at-limits=v1
   For generated system calls and error numbers on a file read, the result
   matches the mapping of the interface, gives no file-read result on a stop
   at a limit, and closes each descriptor. *)
let read_error_mapping_property =
  let call_site_gen =
    Gen.oneof_list
      [
        (Open_root, [], "a.md");
        (Check_search, [], "a.md");
        (Listing, [], "a.md");
        (Kind, [ "a.md" ], "a.md");
        (Open_file, [ "a.md" ], "a.md");
        (Is_regular_file, [ "a.md" ], "a.md");
        (Content, [ "a.md" ], "a.md");
        (Kind, [ "d" ], "d/a.md");
        (Open_folder, [ "d" ], "d/a.md");
        (Check_search, [ "d" ], "d/a.md");
        (Listing, [ "d" ], "d/a.md");
        (Kind, [ "d"; "a.md" ], "d/a.md");
        (Open_file, [ "d"; "a.md" ], "d/a.md");
        (Is_regular_file, [ "d"; "a.md" ], "d/a.md");
        (Content, [ "d"; "a.md" ], "d/a.md");
        (Close, [], "a.md");
        (Close, [ "d" ], "d/a.md");
        (Close, [ "d"; "a.md" ], "d/a.md");
      ]
  in
  let print ((call, path, text), error) =
    Printf.sprintf "%s at %s reading %S fails with %s" (call_name call)
      (String.concat "/" path) text (Unix.error_message error)
  in
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1500
       ~name:
         "the file read maps each system error number as the interface states \
          and closes each descriptor" ~print
       (Gen.pair call_site_gen unix_error_gen)
       (fun ((call, path, text), error) ->
         let fault called name =
           Option.map (fun () -> Fails error) (at call path called name)
         in
         let read = fake_read ~fault fake_tree text in
         let expected =
           if call = Close then Ok { result = "found"; text = Some "hi" }
           else expected_read_error call path error
         in
         read.open_after = 0 && read.double_closes = 0
         && read.answer = Ok expected))

(* @verifies files#give-file-read-results=v1
   @verifies conformance#report-stops-at-limits=v1
   When UTF-8 decoding raises Out_of_memory after the content read finishes,
   read stops at Memory with the entry names of the file. It gives no
   file-read result and closes each descriptor exactly once. *)
let utf_8_decode_out_of_memory_stops_with_memory () =
  let content = String.make 1000 'a' in
  let tree =
    file
      (Folder [ ("d", file (Folder [ ("a.md", Files_tree.regular content) ])) ])
  in
  let fired = ref false in
  let tracker = ref None in
  let stop () =
    match !tracker with
    | None -> ()
    | Some t ->
        tracker := None;
        Gc.Memprof.stop ();
        Gc.Memprof.discard t
  in
  let arm () =
    let t =
      Gc.Memprof.start ~sampling_rate:1.0 ~callstack_size:0
        {
          Gc.Memprof.null_tracker with
          alloc_major =
            (fun _ ->
              fired := true;
              stop ();
              raise Out_of_memory);
        }
    in
    tracker := Some t
  in
  let module Base = Fake (struct
    let tree = tree
    let fault _ _ = None
  end) in
  let module S = struct
    include Base

    let close descr =
      let path = Base.path_of descr in
      Base.close descr;
      if path = [ "d"; "a.md" ] then arm ()
  end in
  let module W = Sinter_file_read.Walk (S) in
  let result =
    Fun.protect ~finally:stop (fun () -> W.read ~root:"root" (text_of "d/a.md"))
  in
  Alcotest.(check bool) "Out_of_memory fired during UTF-8 decoding" true !fired;
  Alcotest.(check int)
    "the descriptors left open" 0
    (Hashtbl.length Base.opened);
  Alcotest.(check int) "the double closes" 0 !Base.double_closes;
  Alcotest.(check bool)
    "read stopped at Memory with the entry names of the file" true
    (result
    = Error
        (Sinter_file_read.Stopped
           { limit = Sinter_file_read.Memory; names = [ "d"; "a.md" ] }))

(* @verifies files#give-file-read-results=v1
   A program that read the content of a last file that is no longer a
   regular file once open gives a result other than "not a regular file". *)
let last_file_that_is_no_regular_file_once_open () =
  check_fake_result "not a regular file"
    (fake_read ~fault:(on Is_regular_file Not_regular) fake_tree "d/a.md")

let large_and_empty_regular_files_read_whole () =
  let large = String.make 150_000 'z' in
  let tree =
    file
      (Folder
         [
           ("empty", Files_tree.regular ""); ("large", Files_tree.regular large);
         ])
  in
  let r_empty, r_large, c_empty, c_large, w =
    read_in tree (fun root ->
        ( read_text ~root (text_of "empty"),
          read_text ~root (text_of "large"),
          Sinter_file_read.content ~root [ "empty" ],
          Sinter_file_read.content ~root [ "large" ],
          Sinter_file_read.walk_contents ~root Fun.id ))
  in
  Alcotest.(check bool)
    "read empty" true
    (r_empty = { result = "found"; text = Some "" });
  Alcotest.(check bool)
    "read large" true
    (r_large = { result = "found"; text = Some large });
  Alcotest.(check bool) "content empty" true (c_empty = Ok (Ok ""));
  Alcotest.(check bool) "content large" true (c_large = Ok (Ok large));
  Alcotest.(check bool)
    "walk_contents empty and large" true
    (w
    = Ok
        (Sinter_file_read.Tree.Folder
           [
             {
               Sinter_file_read.Tree.name = "empty";
               file = Sinter_file_read.Tree.Regular_file "";
             };
             {
               Sinter_file_read.Tree.name = "large";
               file = Sinter_file_read.Tree.Regular_file large;
             };
           ]))

let close_error_is_ignored () =
  List.iter
    (fun error ->
      let read = fake_read ~fault:(on Close (Fails error)) fake_tree "d/a.md" in
      (match read.answer with
      | Ok (Ok answer) ->
          Alcotest.(check string) "the result" "found" answer.result
      | Ok (Error failure) ->
          Alcotest.failf "the read failed: %s" (show_failure failure)
      | Error error ->
          Alcotest.failf "the read raised %s" (Printexc.to_string error));
      Alcotest.(check int) "the descriptors left open" 0 read.open_after;
      Alcotest.(check int) "the double closes" 0 read.double_closes)
    [ Unix.EIO; Unix.EMFILE; Unix.EBADF ]

exception Other_failure

let other_exception_goes_through () =
  List.iter
    (fun call ->
      List.iter
        (fun (fault, check_exn) ->
          let read = fake_read ~fault:(on call fault) fake_tree "d/a.md" in
          (match read.answer with
          | Error exn when check_exn exn -> ()
          | Error error ->
              Alcotest.failf "the read raised %s" (Printexc.to_string error)
          | Ok (Ok answer) -> Alcotest.failf "the read gave %s" answer.result
          | Ok (Error failure) ->
              Alcotest.failf "the read gave %s" (show_failure failure));
          Alcotest.(check int) "the descriptors left open" 0 read.open_after;
          Alcotest.(check int) "the double closes" 0 read.double_closes)
        [
          (Raises Other_failure, fun exn -> exn = Other_failure);
          (Sys_fails, function Sys_error _ -> true | _ -> false);
        ])
    [
      Open_root;
      Open_folder;
      Open_file;
      Kind;
      Check_search;
      Listing;
      Is_regular_file;
      Content;
    ]

(* @verifies files#read-only-named-files=v1
   A program that made any call of the system for a text that is not a
   valid path could take bytes from a file of the folder tree; the fake
   system records each call. *)
let invalid_text_makes_no_call () =
  List.iter
    (fun text ->
      let read = fake_read fake_tree text in
      (match read.answer with
      | Ok (Ok answer) -> check_result "invalid" answer
      | Ok (Error failure) ->
          Alcotest.failf "the read gave %s" (show_failure failure)
      | Error error ->
          Alcotest.failf "the read raised %s" (Printexc.to_string error));
      Alcotest.(check int) "the calls" 0 (List.length read.calls))
    [ ""; "/a.md"; "a.md/"; "../a.md"; "d/./a.md"; "a\x00" ]

let fake_tree_gen =
  let name_gen =
    Gen.oneof_list
      [ "a"; "A"; "b"; "\xc3\xa9"; "e\xcc\x81"; "\xe9"; "..."; "d" ]
  in
  Gen.map
    (fun (tree : Files_tree.file) ->
      let rec unique (file : Files_tree.file) =
        match file.kind with
        | Folder entries ->
            let rec keep seen = function
              | [] -> []
              | (name, child) :: rest ->
                  if List.mem name seen then keep seen rest
                  else (name, unique child) :: keep (name :: seen) rest
            in
            { file with kind = Folder (keep [] entries) }
        | _ -> file
      in
      unique tree)
    (Gen.map2
       (fun tree extra ->
         match tree.Files_tree.kind with
         | Folder entries -> { tree with kind = Folder (extra @ entries) }
         | _ -> tree)
       tree_gen
       (Gen.list_size (Gen.int_bound 3)
          (Gen.map2
             (fun name content -> (name, Files_tree.regular content))
             name_gen content_gen)))

(* @verifies files#give-file-read-results=v1
   On a fake system whose lookups ignore case, and which holds entry names
   that no one real file system holds together, a result that differs from a
   direct reading of file-read-result fails the comparison. *)
let walk_follows_the_file_read_result =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1000
       ~name:
         "the walk on a fake system gives the file-read result and closes each \
          descriptor" ~print:print_case (Gen.pair fake_tree_gen path_text_gen)
       (fun (tree, text) ->
         let read = fake_read tree text in
         read.open_after = 0 && read.double_closes = 0
         &&
         match read.answer with
         | Ok (Ok answer) -> answer = reference text tree
         | _ -> false))

module Tree = Sinter_file_read.Tree

let by_name entries =
  List.sort (fun (a, _) (b, _) -> String.compare a b) entries

let rec tree_file value (file : Files_tree.file) : 'a Tree.file =
  match file.kind with
  | Folder entries -> Tree.Folder (tree_entries value entries)
  | Regular pieces -> Tree.Regular_file (value pieces)
  | Link _ -> Tree.Symbolic_link
  | Pipe -> Tree.Other_kind

and tree_entries value entries =
  List.map
    (fun (name, file) -> { Tree.name; file = tree_file value file })
    (by_name entries)

let rec walk_reference_file ~with_contents value (file : Files_tree.file) :
    'a Tree.file =
  match file.kind with
  | Folder entries ->
      if
        (not file.permissions.read)
        || (entries <> [] && not file.permissions.search)
      then Tree.Unread_folder
      else
        Tree.Folder
          (List.map
             (fun (name, child) ->
               {
                 Tree.name;
                 file = walk_reference_file ~with_contents value child;
               })
             (by_name entries))
  | Regular pieces ->
      if with_contents && not file.permissions.read then Tree.Unread_file
      else Tree.Regular_file (value pieces)
  | Link _ -> Tree.Symbolic_link
  | Pipe -> Tree.Other_kind

let walk_reference (tree : Files_tree.file) =
  walk_reference_file ~with_contents:false (fun _ -> ()) tree

let contents_reference (tree : Files_tree.file) =
  walk_reference_file ~with_contents:true Files_tree.bytes_of_pieces tree

let rec folder_depth (file : Files_tree.file) =
  match file.kind with
  | Folder entries ->
      1
      + List.fold_left
          (fun deepest (_, child) -> max deepest (folder_depth child))
          0 entries
  | Regular _ | Link _ | Pipe -> 0

let rec file_at (file : Files_tree.file) = function
  | [] -> Some file
  | name :: rest -> (
      match file.kind with
      | Folder entries -> (
          match List.assoc_opt name entries with
          | Some child -> file_at child rest
          | None -> None)
      | Regular _ | Link _ | Pipe -> None)

(* @verifies conformance#report-missing-parts=v1
   A walk of a folder tree marks every unreadable folder as Unread_folder and
   continues walking the rest of the tree without changing any file. *)
let walk_follows_the_folder_tree =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:200
       ~name:
         "a walk of a generated folder tree gives its folder entries with \
          Unread_folder for each unread folder and changes no file"
       ~print:print_file
       (Gen.oneof [ tree_gen; Pack_trees.tree_gen ])
       (fun tree ->
         match
           Files_tree.run tree (fun root -> Sinter_file_read.walk ~root)
         with
         | Files_tree.Not_stored reason ->
             QCheck2.Test.fail_reportf "not stored: %s" reason
         | Files_tree.Read { value; changes } ->
             changes = [] && value = Ok (walk_reference tree)))

(* @verifies conformance#report-stops-at-limits=v1
   A deep walk either gives the whole folder tree or stops at the descriptor
   limit, and closes each descriptor. *)
let deep_walk_closes_each_descriptor () =
  let tree = Pack_trees.deep_tree 600 in
  let value, before, after =
    read_in tree (fun root ->
        let before = open_descriptors () in
        let value = Sinter_file_read.walk ~root in
        (value, before, open_descriptors ()))
  in
  Alcotest.(check int) "the open file descriptors" before after;
  match value with
  | Ok found ->
      Alcotest.(check bool)
        "the folder entries" true
        (found = walk_reference tree)
  | Error (Sinter_file_read.Stopped { limit = Descriptors; _ }) -> ()
  | Error failure ->
      Alcotest.failf "the deep walk failed with %s" (show_failure failure)

type 'a fake_run = {
  value : ('a, exn) result;
  left_open : int;
  double_closes : int;
  peak : int;
  run_targets : (call * string list) list;
}

let fake_walk ?(fault = fun _ _ -> None) tree =
  let module S = Fake (struct
    let tree = tree
    let fault = fault
  end) in
  let module W = Sinter_file_read.Walk (S) in
  let value =
    match W.walk ~root:"root" with v -> Ok v | exception e -> Error e
  in
  {
    value;
    left_open = Hashtbl.length S.opened;
    double_closes = !S.double_closes;
    peak = !S.peak;
    run_targets = List.rev !S.targets;
  }

let fake_content ?(fault = fun _ _ -> None) tree names =
  let module S = Fake (struct
    let tree = tree
    let fault = fault
  end) in
  let module W = Sinter_file_read.Walk (S) in
  let value =
    match W.content ~root:"root" names with v -> Ok v | exception e -> Error e
  in
  {
    value;
    left_open = Hashtbl.length S.opened;
    double_closes = !S.double_closes;
    peak = !S.peak;
    run_targets = List.rev !S.targets;
  }

let fake_walk_contents ?(fault = fun _ _ -> None) tree value =
  let module S = Fake (struct
    let tree = tree
    let fault = fault
  end) in
  let module W = Sinter_file_read.Walk (S) in
  let result =
    match W.walk_contents ~root:"root" value with
    | v -> Ok v
    | exception e -> Error e
  in
  {
    value = result;
    left_open = Hashtbl.length S.opened;
    double_closes = !S.double_closes;
    peak = !S.peak;
    run_targets = List.rev !S.targets;
  }

let rec opens_after_kind seen = function
  | [] -> true
  | (Kind, path) :: rest -> opens_after_kind (path :: seen) rest
  | ((Open_folder | Open_file), path) :: rest ->
      List.mem path seen && opens_after_kind seen rest
  | _ :: rest -> opens_after_kind seen rest

let only_folders_open tree targets =
  List.for_all
    (fun (call, path) ->
      match call with
      | Open_file | Content | Is_regular_file -> false
      | Open_folder -> (
          match file_at tree path with
          | Some { Files_tree.kind = Folder _; _ } -> true
          | _ -> false)
      | _ -> true)
    targets

let walk_on_a_fake_system =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1000
       ~name:
         "the walk on a fake system gives the folder entries with \
          Unread_folder, opens only folders after their kind, and closes each \
          descriptor" ~print:print_file fake_tree_gen (fun tree ->
         let run = fake_walk tree in
         run.left_open = 0 && run.double_closes = 0
         && run.peak <= folder_depth tree
         && opens_after_kind [] run.run_targets
         && only_folders_open tree run.run_targets
         && run.value = Ok (Ok (walk_reference tree))))

let rec mark_unread target replacement (file : 'a Tree.file) =
  match (target, file) with
  | [], _ -> replacement
  | name :: rest, Tree.Folder entries ->
      Tree.Folder
        (List.map
           (fun (entry : 'a Tree.entry) ->
             if String.equal entry.name name then
               { entry with file = mark_unread rest replacement entry.file }
             else entry)
           entries)
  | _ -> file

(* @verifies conformance#report-missing-parts=v1
   @verifies conformance#report-stops-at-limits=v1
   On a missing-part error from open_root, open_folder, listing, or kind, a
   walk marks the folder Unread_folder and continues. On a limit error or
   Out_of_memory from a call other than close, the walk stops with the limit
   and entry names. On any other Unix error, it gives Failed with that error,
   and it lets other exceptions through. On every path, it closes each opened
   descriptor exactly once. *)
let walk_error_mapping_property =
  let fault_gen =
    Gen.oneof_weighted
      [
        (8, Gen.map (fun e -> Fails e) unix_error_gen);
        (1, Gen.return (Raises Out_of_memory));
        (1, Gen.return Sys_fails);
        (1, Gen.return (Raises Other_failure));
      ]
  in
  let print (tree, fault) =
    let f =
      match fault with
      | Fails e -> Unix.error_message e
      | Sys_fails -> "Sys_error"
      | Raises Out_of_memory -> "Out_of_memory"
      | Raises e -> Printexc.to_string e
      | Not_regular -> "Not_regular"
    in
    Printf.sprintf "%s in %s" f (print_file tree)
  in
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:150
       ~name:
         "a walk maps each system error and exception at each call as the \
          interface states and closes each descriptor exactly once" ~print
       (Gen.pair fake_tree_gen fault_gen) (fun (tree, fault) ->
         let baseline = fake_walk tree in
         let expected_tree =
           if baseline.left_open <> 0 || baseline.double_closes <> 0 then
             QCheck2.Test.fail_report "baseline walk leaked or double-closed"
           else
             match baseline.value with
             | Ok (Ok t) -> t
             | _ -> QCheck2.Test.fail_report "baseline walk failed"
         in
         List.for_all
           (fun (call, path) ->
             let invalid_close_fault =
               call = Close
               &&
               match fault with
               | Fails _ | Not_regular -> false
               | Sys_fails | Raises _ -> true
             in
             if invalid_close_fault then true
             else
               let run =
                 fake_walk
                   ~fault:(fun called name ->
                     Option.map (fun () -> fault) (at call path called name))
                   tree
               in
               let ok =
                 run.left_open = 0 && run.double_closes = 0
                 &&
                 match (call, fault) with
                 | Close, (Fails _ | Not_regular) ->
                     run.value = Ok (Ok expected_tree)
                 | Close, (Sys_fails | Raises _) -> false
                 | _, Raises Out_of_memory ->
                     run.value
                     = Ok
                         (Error
                            (Sinter_file_read.Stopped
                               { limit = Memory; names = path }))
                 | _, Sys_fails -> (
                     match run.value with
                     | Error (Sys_error _) -> true
                     | _ -> false)
                 | _, Raises exn -> run.value = Error exn
                 | _, Fails error when is_missing_part_error error ->
                     let folder =
                       if call = Kind then parent_of path else path
                     in
                     run.value
                     = Ok
                         (Ok
                            (mark_unread folder Tree.Unread_folder expected_tree))
                 | _, Fails error -> (
                     match limit_of_error call error with
                     | Some limit ->
                         run.value
                         = Ok
                             (Error
                                (Sinter_file_read.Stopped
                                   { limit; names = path }))
                     | None ->
                         run.value
                         = Ok
                             (Error
                                (Sinter_file_read.Failed { names = path; error }))
                     )
                 | _, Not_regular -> run.value = Ok (Ok expected_tree)
               in
               ok
               || QCheck2.Test.fail_reportf "walk fault of %s at %s"
                    (call_name call) (String.concat "/" path))
           baseline.run_targets))

(* @verifies conformance#report-missing-parts=v1
   When kind raises a missing-part error for one entry of a folder during a
   walk, the walk marks that folder Unread_folder with none of its entries
   kept and still reads sibling folders. *)
let walk_kind_missing_part_marks_whole_folder_unread () =
  let tree =
    file
      (Folder
         [
           ("a.md", Files_tree.regular "hi");
           ( "d",
             file
               (Folder
                  [
                    ("x.md", Files_tree.regular "x");
                    ("y.md", Files_tree.regular "y");
                  ]) );
         ])
  in
  let run_sub =
    fake_walk
      ~fault:(fun called name ->
        Option.map
          (fun () -> Fails Unix.EIO)
          (at Kind [ "d"; "x.md" ] called name))
      tree
  in
  Alcotest.(check int) "open descriptors (sub)" 0 run_sub.left_open;
  Alcotest.(check int) "double closes (sub)" 0 run_sub.double_closes;
  Alcotest.(check bool)
    "sub folder marked Unread_folder and sibling kept" true
    (run_sub.value
    = Ok
        (Ok
           (Tree.Folder
              [
                { Tree.name = "a.md"; file = Tree.Regular_file () };
                { Tree.name = "d"; file = Tree.Unread_folder };
              ])));
  let run_root =
    fake_walk
      ~fault:(fun called name ->
        Option.map (fun () -> Fails Unix.EIO) (at Kind [ "a.md" ] called name))
      tree
  in
  Alcotest.(check int) "open descriptors (root)" 0 run_root.left_open;
  Alcotest.(check int) "double closes (root)" 0 run_root.double_closes;
  Alcotest.(check bool)
    "root marked Unread_folder" true
    (run_root.value = Ok (Ok Tree.Unread_folder))

let in_fiber action =
  Effect.Deep.match_with action ()
    { retc = Fun.id; exnc = raise; effc = (fun _ -> None) }

let with_small_stack action =
  let before = Gc.get () in
  Fun.protect
    ~finally:(fun () -> Gc.set before)
    (fun () ->
      Gc.set { before with stack_limit = 8192 };
      in_fiber action)

let deep_walk_needs_no_deep_stack () =
  let tree = Pack_trees.deep_tree 4000 in
  let run = with_small_stack (fun () -> fake_walk tree) in
  (match run.value with
  | Ok value ->
      Alcotest.(check bool)
        "the folder entries" true
        (value = Ok (walk_reference tree))
  | Error error ->
      Alcotest.failf "the walk raised %s" (Printexc.to_string error));
  Alcotest.(check int) "the descriptors left open" 0 run.left_open;
  Alcotest.(check int) "the double closes" 0 run.double_closes

let content_reference names (tree : Files_tree.file) :
    (string, Sinter_file_read.content_failure) result =
  let open Files_tree in
  let rec walk rev_prefix (folder : file) = function
    | [] -> Error Sinter_file_read.No_content_file
    | name :: rest -> (
        match folder.kind with
        | Folder entries -> (
            if not (folder.permissions.search && folder.permissions.read) then
              Error (Cannot_take (List.rev rev_prefix))
            else
              match List.assoc_opt name entries with
              | None -> Error No_content_file
              | Some file -> (
                  let next_prefix = name :: rev_prefix in
                  match (file.kind, rest) with
                  | Link _, _ -> Error Content_symbolic_link
                  | Folder _, _ :: _ -> walk next_prefix file rest
                  | (Regular _ | Pipe), _ :: _ -> Error No_content_file
                  | (Folder _ | Pipe), [] -> Error Not_regular
                  | Regular _, [] when not file.permissions.read ->
                      Error (Cannot_take (List.rev next_prefix))
                  | Regular pieces, [] -> Ok (bytes_of_pieces pieces)))
        | Regular _ | Link _ | Pipe -> Error No_content_file)
  in
  let entry_name name =
    name <> "" && name <> "." && name <> ".."
    && not (String.exists (fun c -> c = '/' || c = '\x00') name)
  in
  if names <> [] && List.for_all entry_name names then walk [] tree names
  else Error Not_entry_names

let names_gen =
  Gen.oneof_weighted
    [
      ( 8,
        Gen.list_size (Gen.int_range 1 4)
          (Gen.oneof_list
             [
               "a";
               "A";
               "b";
               "d";
               "x";
               "...";
               "\xc3\xa9";
               "e\xcc\x81";
               "\xe9";
               "\xff";
               "pack.toml";
             ]) );
      ( 1,
        Gen.oneof_list
          [ []; [ "" ]; [ "." ]; [ ".." ]; [ "a/b" ]; [ "a\x00" ]; [ "d"; "" ] ]
      );
    ]

let print_names names = String.concat " / " (List.map String.escaped names)

let content_follows_the_folder_tree =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:200
       ~name:
         "the content of entry names in a generated folder tree is the bytes \
          of the regular file that they lead to, or why not, and changes no \
          file"
       ~print:(fun (tree, names) ->
         print_names names ^ " in " ^ print_file tree)
       (Gen.pair (Gen.oneof [ tree_gen; Pack_trees.tree_gen ]) names_gen)
       (fun (tree, names) ->
         match
           Files_tree.run tree (fun root ->
               Sinter_file_read.content ~root names)
         with
         | Files_tree.Not_stored reason ->
             QCheck2.Test.fail_reportf "not stored: %s" reason
         | Files_tree.Read { value; changes } ->
             changes = [] && value = Ok (content_reference names tree)))

let content_of_no_entry_names_makes_no_call () =
  List.iter
    (fun names ->
      let run = fake_content fake_tree names in
      (match run.value with
      | Ok (Ok (Error Sinter_file_read.Not_entry_names)) -> ()
      | _ -> Alcotest.failf "the content of %s" (print_names names));
      Alcotest.(check int) "the calls" 0 (List.length run.run_targets))
    [
      [];
      [ "" ];
      [ "." ];
      [ ".." ];
      [ "a/b" ];
      [ "a\x00" ];
      [ "d"; "" ];
      [ "d"; ".." ];
    ]

let content_makes_the_calls_of_read =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1000
       ~name:
         "the content of the names of a valid path makes the calls of read in \
          their order and gives the case of read" ~print:print_case
       (Gen.pair fake_tree_gen path_text_gen) (fun (tree, text) ->
         QCheck2.assume (Paths_reference.is_path (uchars_of_string text));
         let names = String.split_on_char '/' text in
         let read = fake_read tree text in
         let run = fake_content tree names in
         run.left_open = 0 && run.double_closes = 0
         && run.run_targets = read.targets
         &&
         match (read.answer, run.value) with
         | Ok (Ok { result = "found"; text = Some bytes }), Ok (Ok (Ok content))
           ->
             String.equal bytes content
         | Ok (Ok { result = "not UTF-8"; _ }), Ok (Ok (Ok content)) ->
             not (String.is_valid_utf_8 content)
         | Ok (Ok { result = "no file"; _ }), Ok (Ok (Error No_content_file))
         | ( Ok (Ok { result = "symbolic link"; _ }),
             Ok (Ok (Error Content_symbolic_link)) )
         | ( Ok (Ok { result = "not a regular file"; _ }),
             Ok (Ok (Error Not_regular)) )
         | ( Ok (Ok { result = "cannot read"; _ }),
             Ok (Ok (Error (Cannot_take _))) ) ->
             true
         | _ -> false))

(* @verifies conformance#report-missing-parts=v1
   @verifies conformance#report-stops-at-limits=v1
   For generated system calls and error numbers on content, Cannot_take names
   the missing folder or file. Limit errors give Stopped, other errors give
   Failed, and content closes each opened descriptor exactly once. *)
let content_error_mapping_property =
  let call_site_gen =
    Gen.oneof_list
      [
        (Open_root, [], [ "d"; "a.md" ]);
        (Check_search, [], [ "d"; "a.md" ]);
        (Listing, [], [ "d"; "a.md" ]);
        (Kind, [ "d" ], [ "d"; "a.md" ]);
        (Open_folder, [ "d" ], [ "d"; "a.md" ]);
        (Check_search, [ "d" ], [ "d"; "a.md" ]);
        (Listing, [ "d" ], [ "d"; "a.md" ]);
        (Kind, [ "d"; "a.md" ], [ "d"; "a.md" ]);
        (Open_file, [ "d"; "a.md" ], [ "d"; "a.md" ]);
        (Is_regular_file, [ "d"; "a.md" ], [ "d"; "a.md" ]);
        (Content, [ "d"; "a.md" ], [ "d"; "a.md" ]);
        (Close, [], [ "d"; "a.md" ]);
        (Close, [ "d" ], [ "d"; "a.md" ]);
        (Close, [ "d"; "a.md" ], [ "d"; "a.md" ]);
      ]
  in
  let print ((call, path, names), error) =
    Printf.sprintf "%s at %s taking %s fails with %s" (call_name call)
      (String.concat "/" path) (print_names names) (Unix.error_message error)
  in
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1000
       ~name:
         "content maps each system error number as the interface states, names \
          the missing part in Cannot_take, and closes each descriptor exactly \
          once" ~print (Gen.pair call_site_gen unix_error_gen)
       (fun ((call, path, names), error) ->
         let fault called name =
           Option.map (fun () -> Fails error) (at call path called name)
         in
         let run = fake_content ~fault fake_tree names in
         let expected =
           if call = Close then Ok (Ok "hi")
           else expected_content_error call path error
         in
         run.left_open = 0 && run.double_closes = 0 && run.value = Ok expected))

let content_out_of_memory_stops_with_memory () =
  let not_reg =
    fake_content
      ~fault:(on Is_regular_file Not_regular)
      fake_tree [ "d"; "a.md" ]
  in
  Alcotest.(check int) "open descriptors (Not_regular)" 0 not_reg.left_open;
  Alcotest.(check int) "double closes (Not_regular)" 0 not_reg.double_closes;
  Alcotest.(check bool)
    "content gives Not_regular" true
    (not_reg.value = Ok (Ok (Error Sinter_file_read.Not_regular)));
  List.iter
    (fun (call, path) ->
      let run =
        fake_content
          ~fault:(fun called name ->
            Option.map
              (fun () -> Raises Out_of_memory)
              (at call path called name))
          fake_tree [ "d"; "a.md" ]
      in
      Alcotest.(check int) "open descriptors" 0 run.left_open;
      Alcotest.(check int) "double closes" 0 run.double_closes;
      Alcotest.(check bool)
        "stopped with Memory" true
        (run.value
        = Ok (Error (Sinter_file_read.Stopped { limit = Memory; names = path }))
        ))
    [
      (Open_root, []);
      (Check_search, [ "d" ]);
      (Listing, [ "d" ]);
      (Kind, [ "d"; "a.md" ]);
      (Open_folder, [ "d" ]);
      (Open_file, [ "d"; "a.md" ]);
      (Is_regular_file, [ "d"; "a.md" ]);
      (Content, [ "d"; "a.md" ]);
    ]

(* @verifies conformance#report-missing-parts=v1
   A walk with contents marks each unread folder as Unread_folder and each
   unread regular file as Unread_file, continues walking the rest of the
   tree, and changes no file. *)
let walk_contents_follows_the_folder_tree =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:200
       ~name:
         "a walk with contents of a generated folder tree gives its folder \
          entries and contents with Unread_folder and Unread_file, and changes \
          no file"
       ~print:print_file
       (Gen.oneof [ tree_gen; Pack_trees.tree_gen ])
       (fun tree ->
         match
           Files_tree.run tree (fun root ->
               Sinter_file_read.walk_contents ~root Fun.id)
         with
         | Files_tree.Not_stored reason ->
             QCheck2.Test.fail_reportf "not stored: %s" reason
         | Files_tree.Read { value; changes } ->
             changes = [] && value = Ok (contents_reference tree)))

let rec values_in_order = function
  | Tree.Regular_file value -> [ value ]
  | Tree.Folder entries ->
      List.concat_map
        (fun (entry : 'a Tree.entry) -> values_in_order entry.file)
        entries
  | Tree.Symbolic_link | Tree.Other_kind | Tree.Unread_folder | Tree.Unread_file
    ->
      []

let regular_at tree path =
  match file_at tree path with
  | Some { Files_tree.kind = Regular _; _ } -> true
  | _ -> false

let walk_contents_on_a_fake_system =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:1000
       ~name:
         "the walk with contents on a fake system takes each readable content \
          once in walk order, marks unread folders and files, opens only \
          folders and regular files after their kind, and closes each \
          descriptor" ~print:print_file fake_tree_gen (fun tree ->
         let count = ref 0 in
         let run =
           fake_walk_contents tree (fun bytes ->
               incr count;
               (!count, bytes))
         in
         let contents =
           List.filter_map
             (function Content, path -> Some path | _ -> None)
             run.run_targets
         in
         run.left_open = 0 && run.double_closes = 0
         && opens_after_kind [] run.run_targets
         && List.for_all
              (fun (call, path) ->
                match call with
                | Open_folder -> (
                    match file_at tree path with
                    | Some { Files_tree.kind = Folder _; _ } -> true
                    | _ -> false)
                | Open_file | Content | Is_regular_file -> regular_at tree path
                | _ -> true)
              run.run_targets
         && List.length (List.sort_uniq compare contents) = List.length contents
         &&
         match run.value with
         | Ok (Ok root_file) ->
             let values = values_in_order root_file in
             let numbered = ref 0 in
             let rec number = function
               | Tree.Folder entries ->
                   Tree.Folder
                     (List.map
                        (fun (e : string Tree.entry) ->
                          { e with file = number e.file })
                        entries)
               | Tree.Regular_file bytes ->
                   incr numbered;
                   Tree.Regular_file (!numbered, bytes)
               | Tree.Symbolic_link -> Tree.Symbolic_link
               | Tree.Other_kind -> Tree.Other_kind
               | Tree.Unread_folder -> Tree.Unread_folder
               | Tree.Unread_file -> Tree.Unread_file
             in
             List.map fst values
             = List.init (List.length values) (fun index -> index + 1)
             && List.length values = !count
             && root_file = number (contents_reference tree)
         | _ -> false))

(* @verifies conformance#report-missing-parts=v1
   @verifies conformance#report-stops-at-limits=v1
   A walk with contents maps missing-part errors to Unread_folder or
   Unread_file. It maps limit errors and Out_of_memory from a call other than
   close to Stopped, maps is_regular_file false to Changed, and maps other
   Unix errors to Failed. It lets Sys_error and other exceptions through, and
   it closes each opened descriptor exactly once. *)
let walk_contents_error_mapping_property =
  let fault_gen =
    Gen.oneof_weighted
      [
        (8, Gen.map (fun e -> Fails e) unix_error_gen);
        (1, Gen.return (Raises Out_of_memory));
        (1, Gen.return Sys_fails);
        (1, Gen.return (Raises Other_failure));
        (1, Gen.return Not_regular);
      ]
  in
  let print (tree, fault) =
    let f =
      match fault with
      | Fails e -> Unix.error_message e
      | Sys_fails -> "Sys_error"
      | Raises Out_of_memory -> "Out_of_memory"
      | Raises e -> Printexc.to_string e
      | Not_regular -> "Not_regular"
    in
    Printf.sprintf "%s in %s" f (print_file tree)
  in
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count:150
       ~name:
         "a walk with contents maps each system error, change, and exception \
          at each call as the interface states and closes each descriptor \
          exactly once" ~print (Gen.pair fake_tree_gen fault_gen)
       (fun (tree, fault) ->
         let baseline = fake_walk_contents tree Fun.id in
         let expected_tree =
           if baseline.left_open <> 0 || baseline.double_closes <> 0 then
             QCheck2.Test.fail_report
               "baseline walk_contents leaked or double-closed"
           else
             match baseline.value with
             | Ok (Ok t) -> t
             | _ -> QCheck2.Test.fail_report "baseline walk_contents failed"
         in
         List.for_all
           (fun (call, path) ->
             let invalid_close_fault =
               call = Close
               &&
               match fault with
               | Fails _ | Not_regular -> false
               | Sys_fails | Raises _ -> true
             in
             if invalid_close_fault then true
             else
               let run =
                 fake_walk_contents
                   ~fault:(fun called name ->
                     Option.map (fun () -> fault) (at call path called name))
                   tree Fun.id
               in
               let ok =
                 run.left_open = 0 && run.double_closes = 0
                 &&
                 match (call, fault) with
                 | Close, (Fails _ | Not_regular) ->
                     run.value = Ok (Ok expected_tree)
                 | Close, (Sys_fails | Raises _) -> false
                 | Is_regular_file, Not_regular ->
                     run.value = Ok (Error (Sinter_file_read.Changed path))
                 | _, Not_regular -> run.value = Ok (Ok expected_tree)
                 | _, Raises Out_of_memory ->
                     run.value
                     = Ok
                         (Error
                            (Sinter_file_read.Stopped
                               { limit = Memory; names = path }))
                 | _, Sys_fails -> (
                     match run.value with
                     | Error (Sys_error _) -> true
                     | _ -> false)
                 | _, Raises exn -> run.value = Error exn
                 | (Open_file | Is_regular_file | Content), Fails error
                   when is_missing_part_error error ->
                     run.value
                     = Ok (Ok (mark_unread path Tree.Unread_file expected_tree))
                 | _, Fails error when is_missing_part_error error ->
                     let folder =
                       if call = Kind then parent_of path else path
                     in
                     run.value
                     = Ok
                         (Ok
                            (mark_unread folder Tree.Unread_folder expected_tree))
                 | _, Fails error -> (
                     match limit_of_error call error with
                     | Some limit ->
                         run.value
                         = Ok
                             (Error
                                (Sinter_file_read.Stopped
                                   { limit; names = path }))
                     | None ->
                         run.value
                         = Ok
                             (Error
                                (Sinter_file_read.Failed { names = path; error }))
                     )
               in
               ok
               || QCheck2.Test.fail_reportf "walk_contents fault of %s at %s"
                    (call_name call) (String.concat "/" path))
           baseline.run_targets))

let exception_of_value_goes_through () =
  List.iter
    (fun exn ->
      let calls = ref 0 in
      let run =
        fake_walk_contents fake_tree (fun _ ->
            incr calls;
            raise exn)
      in
      (match run.value with
      | Error raised when raised = exn -> ()
      | _ ->
          Alcotest.failf "the exception %s of the value did not go through"
            (Printexc.to_string exn));
      Alcotest.(check int) "the calls of the value" 1 !calls;
      Alcotest.(check int) "the descriptors left open" 0 run.left_open;
      Alcotest.(check int) "the double closes" 0 run.double_closes)
    [ Other_failure; Out_of_memory ]

let tests =
  Vectors.tests "files" [ file_read_vectors ]
  @ [
      Vectors.covers "files" files_set
        (Test_path.vector_groups @ Test_glob_fit.vector_groups
       @ Test_path_set.vector_groups @ [ file_read_vectors ]);
      file_read_follows_the_file_read_result;
      Alcotest.test_case "a file read takes no byte from a pipe" `Quick
        pipe_keeps_its_data;
      Alcotest.test_case "a pipe with no opener ends the file read" `Quick
        pipe_with_no_opener_ends_the_read;
      Alcotest.test_case
        "a symbolic link out of the folder tree leads to no pipe" `Quick
        link_out_of_the_tree_finds_no_pipe;
      Alcotest.test_case "a folder with no permissions keeps its mode and owner"
        `Quick folder_with_no_permissions_stays_as_it_is;
      Alcotest.test_case
        "a folder without permissions as the last name is not a regular file"
        `Quick folder_without_permissions_as_last_name_is_not_a_regular_file;
      Alcotest.test_case
        "a long name in a folder with no search permission cannot be read"
        `Quick long_name_in_a_folder_with_no_search_permission;
      Alcotest.test_case "read closes each file descriptor that it opens" `Quick
        read_closes_each_descriptor;
      Alcotest.test_case "a text that is no valid path is invalid with any root"
        `Quick invalid_text_is_invalid_with_any_root;
      Alcotest.test_case
        "a file object rejects invalid entry names and symlink references"
        `Quick file_object_rejects_invalid_names_and_references;
      Alcotest.test_case
        "a name that the file system does not accept gives no file" `Quick
        name_not_accepted_gives_no_file;
      Alcotest.test_case
        "each refused permission and input or output error gives cannot read"
        `Quick missing_part_errors_give_cannot_read;
      Alcotest.test_case "each limit error stops the file read with no result"
        `Quick limit_errors_stop_the_read;
      Alcotest.test_case "other system errors fail the file read" `Quick
        other_errors_fail_the_read;
      read_error_mapping_property;
      Alcotest.test_case
        "Out_of_memory during UTF-8 decoding stops read at Memory" `Quick
        utf_8_decode_out_of_memory_stops_with_memory;
      Alcotest.test_case "a last file that is no regular file once open" `Quick
        last_file_that_is_no_regular_file_once_open;
      Alcotest.test_case
        "read, content, and walk_contents read empty and multi-chunk regular \
         files whole"
        `Quick large_and_empty_regular_files_read_whole;
      Alcotest.test_case "an error of close is ignored" `Quick
        close_error_is_ignored;
      Alcotest.test_case
        "Sys_error and other exceptions go through and close each descriptor"
        `Quick other_exception_goes_through;
      Alcotest.test_case "a text that is no valid path makes no call" `Quick
        invalid_text_makes_no_call;
      walk_follows_the_file_read_result;
      Alcotest.test_case "a root that is no folder fails with Failed" `Quick
        root_that_is_no_folder_fails;
      Alcotest.test_case
        "a root pathname that is too long stops at Pathname_length" `Quick
        root_pathname_too_long_stops_at_limit;
      walk_follows_the_folder_tree;
      Alcotest.test_case "a deep walk closes each descriptor" `Quick
        deep_walk_closes_each_descriptor;
      walk_on_a_fake_system;
      walk_error_mapping_property;
      Alcotest.test_case
        "a missing-part error from kind marks the whole folder unread in a walk"
        `Quick walk_kind_missing_part_marks_whole_folder_unread;
      Alcotest.test_case "a deep walk needs no deep stack" `Quick
        deep_walk_needs_no_deep_stack;
      content_follows_the_folder_tree;
      Alcotest.test_case "the content of no entry names makes no call" `Quick
        content_of_no_entry_names_makes_no_call;
      content_makes_the_calls_of_read;
      content_error_mapping_property;
      Alcotest.test_case "Out_of_memory in content stops with Memory" `Quick
        content_out_of_memory_stops_with_memory;
      walk_contents_follows_the_folder_tree;
      walk_contents_on_a_fake_system;
      walk_contents_error_mapping_property;
      Alcotest.test_case
        "an exception of value, Out_of_memory included, goes through" `Quick
        exception_of_value_goes_through;
    ]
