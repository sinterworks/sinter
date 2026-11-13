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

let read_text ~root text = answer_of (Sinter_file_read.read ~root text)

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
    ("long-names", true);
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
      | needs -> Some (vector.number, needs))
    (Vectors.vectors files_set "file-reads")

let outcomes = Hashtbl.create 64

let outcome (vector : Vectors.vector) =
  match Hashtbl.find_opt outcomes vector.number with
  | Some outcome -> outcome
  | None ->
      let text = text_of (json_string (json_member "text" vector.input)) in
      let outcome =
        Files_tree.run (tree_of vector) (fun root -> read_text ~root text)
      in
      Hashtbl.replace outcomes vector.number outcome;
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

(* @verifies files[file-reads][*]=v1
   The vectors check the result of a file read, and the text of the content
   with "found", for a text in a folder tree that the test makes. *)
let file_read_vectors =
  Vectors.group files_set ~name:"file-reads" ~rev:"v1" ~needs:need_holds
    ~skipped give_file_read

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
           Files_tree.run tree (fun root -> read_text ~root (text_of text))
         with
         | Files_tree.Not_stored reason ->
             QCheck2.Test.fail_reportf "not stored: %s" reason
         | Files_tree.Read { value; changes } ->
             changes = [] && value = reference text tree))

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

let root_that_is_no_folder_cannot_be_read () =
  let file_root = Filename.temp_file "sinter-root-" "" in
  Fun.protect
    ~finally:(fun () -> Sys.remove file_root)
    (fun () ->
      List.iter
        (fun root ->
          check_result "cannot read" (read_text ~root (text_of "a.md")))
        [
          file_root;
          file_root ^ ".missing";
          Filename.get_temp_dir_name () ^ "/a\x00b";
        ])

let invalid_text_is_invalid_with_any_root () =
  List.iter
    (fun root -> check_result "invalid" (read_text ~root (text_of "../a.md")))
    [ Filename.get_temp_dir_name () ^ "/sinter-no-such-root"; "a\x00b"; "" ]

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
let fold name = String.lowercase_ascii name

module Fake (F : FAULTS) = struct
  type descr = int

  let opened : (int, Files_tree.file) Hashtbl.t = Hashtbl.create 8
  let calls = ref []
  let next = ref 0

  let enter call name =
    calls := call :: !calls;
    match F.fault call name with
    | Some (Fails error) -> raise (Unix.Unix_error (error, "fake", name))
    | Some Sys_fails -> raise (Sys_error "fake")
    | Some (Raises error) -> raise error
    | Some Not_regular | None -> ()

  let node descr =
    match Hashtbl.find_opt opened descr with
    | Some file -> file
    | None -> raise (Unix.Unix_error (Unix.EBADF, "fake", ""))

  let fresh file =
    incr next;
    Hashtbl.replace opened !next file;
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
    enter Open_root name;
    readable F.tree;
    fresh F.tree

  let open_folder descr name =
    enter Open_folder name;
    let file = lookup descr name in
    (match file.kind with
    | Files_tree.Link _ -> raise (Unix.Unix_error (Unix.ELOOP, "fake", name))
    | Files_tree.Folder _ -> ()
    | _ -> raise (Unix.Unix_error (Unix.ENOTDIR, "fake", name)));
    readable file;
    fresh file

  let open_file descr name =
    enter Open_file name;
    let file = lookup descr name in
    (match file.kind with
    | Files_tree.Link _ -> raise (Unix.Unix_error (Unix.ELOOP, "fake", name))
    | _ -> ());
    readable file;
    fresh file

  let kind descr name : Sinter_file_read.kind =
    enter Kind name;
    match (lookup descr name).kind with
    | Files_tree.Folder _ -> Folder
    | Files_tree.Regular _ -> Regular_file
    | Files_tree.Link _ -> Symbolic_link
    | Files_tree.Pipe -> Other_kind

  let check_search descr =
    enter Check_search "";
    if not (node descr).permissions.search then
      raise (Unix.Unix_error (Unix.EACCES, "fake", "."))

  let listing descr =
    enter Listing "";
    ".." :: List.rev ("." :: List.map fst (entries (node descr)))

  let is_regular_file descr =
    enter Is_regular_file "";
    match ((node descr).kind, F.fault Is_regular_file "") with
    | _, Some Not_regular -> false
    | Files_tree.Regular _, _ -> true
    | _ -> false

  let content descr =
    enter Content "";
    match (node descr).kind with
    | Files_tree.Regular pieces -> Files_tree.bytes_of_pieces pieces
    | _ -> raise (Unix.Unix_error (Unix.EISDIR, "fake", ""))

  let close descr =
    if not (Hashtbl.mem opened descr) then
      raise (Unix.Unix_error (Unix.EBADF, "fake", ""));
    Hashtbl.remove opened descr;
    enter Close ""

  let eilseq = fake_eilseq
end

type fake_read = {
  answer : (answer, exn) result;
  open_after : int;
  calls : call list;
}

let fake_read ?(fault = fun _ _ -> None) tree text =
  let module S = Fake (struct
    let tree = tree
    let fault = fault
  end) in
  let module W = Sinter_file_read.Walk (S) in
  let answer =
    match W.read ~root:"root" (text_of text) with
    | outcome -> Ok (answer_of outcome)
    | exception error -> Error error
  in
  { answer; open_after = Hashtbl.length S.opened; calls = List.rev !S.calls }

let check_fake_result expected read =
  (match read.answer with
  | Ok answer -> check_result expected answer
  | Error error ->
      Alcotest.failf "the read raised %s" (Printexc.to_string error));
  Alcotest.(check int) "the descriptors left open" 0 read.open_after

let fake_tree =
  file
    (Folder
       [
         ("a.md", Files_tree.regular "hi");
         ("d", file (Folder [ ("a.md", Files_tree.regular "hi") ]));
       ])

let on call error = fun called _ -> if called = call then Some error else None

(* @verifies files#give-file-read-results=v1
   A program that took a name that the file system does not accept, or that
   is too long, for a failure of the system gives "cannot read" in place of
   "no file". *)
let name_not_accepted_gives_no_file () =
  List.iter
    (fun error ->
      List.iter
        (fun text ->
          check_fake_result "no file"
            (fake_read ~fault:(on Kind (Fails error)) fake_tree text))
        [ "a.md"; "d/a.md"; "b" ])
    [
      Unix.ENOENT; Unix.ENAMETOOLONG; Unix.EINVAL; Unix.EUNKNOWNERR fake_eilseq;
    ]

(* @verifies files#give-file-read-results=v1
   A program that took an input or output error, or another failure of the
   system, for a missing folder entry gives "no file" in place of "cannot
   read". *)
let failure_of_a_lookup_cannot_read () =
  List.iter
    (fun error ->
      check_fake_result "cannot read"
        (fake_read ~fault:(on Kind (Fails error)) fake_tree "d/a.md"))
    [
      Unix.EIO;
      Unix.EACCES;
      Unix.ENOMEM;
      Unix.EMFILE;
      Unix.ELOOP;
      Unix.EUNKNOWNERR (fake_eilseq + 1);
    ]

(* @verifies files#give-file-read-results=v1
   A program that gave another result when the system fails to open a
   folder or the file, to check the search permission, to find the kind of
   a file, to list a folder, to check that the open file is a regular file,
   or to read the content gives other than "cannot read". *)
let failure_of_a_call_cannot_read () =
  List.iter
    (fun (call, text) ->
      List.iter
        (fun fault ->
          check_fake_result "cannot read"
            (fake_read ~fault:(on call fault) fake_tree text))
        [ Fails Unix.EIO; Fails Unix.EMFILE; Sys_fails ])
    [
      (Open_root, "a.md");
      (Kind, "a.md");
      (Open_folder, "d/a.md");
      (Open_file, "a.md");
      (Open_file, "d/a.md");
      (Check_search, "a.md");
      (Check_search, "d/a.md");
      (Listing, "a.md");
      (Listing, "d/a.md");
      (Is_regular_file, "a.md");
      (Content, "a.md");
      (Content, "d/a.md");
    ]

(* @verifies files#give-file-read-results=v1
   A program that read the content of a last file that is no longer a
   regular file once open gives a result other than "not a regular file". *)
let last_file_that_is_no_regular_file_once_open () =
  check_fake_result "not a regular file"
    (fake_read ~fault:(on Is_regular_file Not_regular) fake_tree "d/a.md")

let close_error_is_ignored () =
  List.iter
    (fun fault ->
      let read = fake_read ~fault:(on Close fault) fake_tree "d/a.md" in
      (match read.answer with
      | Ok answer -> Alcotest.(check string) "the result" "found" answer.result
      | Error error ->
          Alcotest.failf "the read raised %s" (Printexc.to_string error));
      Alcotest.(check int) "the descriptors left open" 0 read.open_after)
    [ Fails Unix.EIO; Sys_fails ]

exception Other_failure

let other_exception_goes_through () =
  List.iter
    (fun call ->
      let read =
        fake_read ~fault:(on call (Raises Other_failure)) fake_tree "d/a.md"
      in
      (match read.answer with
      | Error Other_failure -> ()
      | Error error ->
          Alcotest.failf "the read raised %s" (Printexc.to_string error)
      | Ok answer -> Alcotest.failf "the read gave %s" answer.result);
      Alcotest.(check int) "the descriptors left open" 0 read.open_after)
    [
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
      | Ok answer -> check_result "invalid" answer
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
         read.open_after = 0
         &&
         match read.answer with
         | Ok answer -> answer = reference text tree
         | Error _ -> false))

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
        "a long name in a folder with no search permission cannot be read"
        `Quick long_name_in_a_folder_with_no_search_permission;
      Alcotest.test_case "read closes each file descriptor that it opens" `Quick
        read_closes_each_descriptor;
      Alcotest.test_case "a text that is no valid path is invalid with any root"
        `Quick invalid_text_is_invalid_with_any_root;
      Alcotest.test_case
        "a name that the file system does not accept gives no file" `Quick
        name_not_accepted_gives_no_file;
      Alcotest.test_case "a failure of a lookup cannot read" `Quick
        failure_of_a_lookup_cannot_read;
      Alcotest.test_case "a failure of another call cannot read" `Quick
        failure_of_a_call_cannot_read;
      Alcotest.test_case "a last file that is no regular file once open" `Quick
        last_file_that_is_no_regular_file_once_open;
      Alcotest.test_case "an error of close is ignored" `Quick
        close_error_is_ignored;
      Alcotest.test_case
        "another exception goes through and closes each descriptor" `Quick
        other_exception_goes_through;
      Alcotest.test_case "a text that is no valid path makes no call" `Quick
        invalid_text_makes_no_call;
      walk_follows_the_file_read_result;
      Alcotest.test_case "a root that is no folder cannot be read" `Quick
        root_that_is_no_folder_cannot_be_read;
    ]
