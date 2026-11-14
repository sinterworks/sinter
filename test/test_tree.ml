(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen
module Path = Sinter_paths.Path
module Tree = Sinter_tree.Tree

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let path_of string =
  match Text.decode string with
  | Error _ -> invalid_arg "path_of"
  | Ok text -> (
      match Path.of_text text with
      | Ok path -> path
      | Error _ -> invalid_arg "path_of")

let path_names = [ "a"; "b"; "a/b"; "b/a"; "\xc3\xa9"; "A"; "a.md"; "z/a" ]

let contents =
  [ ""; "x"; "\xff"; "a\r\nb"; "\xef\xbb\xbfx"; "\xc3\xa9\n"; "a\x00b" ]

let path_text path = Text.encode (Path.to_text path)
let file_gen = Gen.pair (Gen.oneof_list path_names) (Gen.oneof_list contents)
let files_gen = Gen.list_size (Gen.int_range 0 6) file_gen

let print_files files =
  String.concat "; "
    (List.map
       (fun (path, content) -> Printf.sprintf "%S %S" path content)
       files)

let paths_of files =
  List.map (fun (name, content) -> (path_of name, content)) files

let rec first_repeat seen = function
  | [] -> None
  | (name, _) :: rest ->
      if List.mem name seen then Some name else first_repeat (name :: seen) rest

let distinct files =
  List.fold_left
    (fun kept (name, content) ->
      if List.mem_assoc name kept then kept else kept @ [ (name, content) ])
    [] files

let tree_of files =
  match Tree.of_files (paths_of files) with
  | Ok tree -> tree
  | Error _ -> Alcotest.fail "the files have no repeated valid path"

let of_files_refuses_a_repeated_path =
  property ~name:"of_files gives an error for the first repeated valid path"
    ~print:print_files files_gen (fun files ->
      match (Tree.of_files (paths_of files), first_repeat [] files) with
      | Ok _, None -> true
      | Error (Tree.Repeated_path path), Some name -> path_text path = name
      | _ -> false)

let files_gives_each_file_once_in_order =
  property ~name:"files gives each file once, in the byte order of the paths"
    ~print:print_files files_gen (fun files ->
      let files = distinct files in
      let given =
        List.map
          (fun (path, content) -> (path_text path, content))
          (Tree.files (tree_of files))
      in
      given = List.sort (fun (a, _) (b, _) -> String.compare a b) files)

let order_does_not_change_the_tree =
  property ~name:"the order of the files does not change the tree"
    ~print:print_files files_gen (fun files ->
      let files = distinct files in
      Tree.equal (tree_of files) (tree_of (List.rev files))
      && Tree.equal (tree_of (List.rev files)) (tree_of files))

let content_gives_the_bytes_of_each_file =
  property ~name:"content gives the content of each file and none for others"
    ~print:print_files files_gen (fun files ->
      let files = distinct files in
      let tree = tree_of files in
      List.for_all
        (fun name ->
          Tree.content tree (path_of name) = List.assoc_opt name files)
        path_names)

let text_follows_the_content =
  property ~name:"text gives the text of a content that is valid UTF-8"
    ~print:print_files files_gen (fun files ->
      let files = distinct files in
      let tree = tree_of files in
      List.for_all
        (fun name ->
          let path = path_of name in
          match (List.assoc_opt name files, Tree.text tree path) with
          | None, Error Tree.No_file -> true
          | Some content, Ok text -> (
              match Text.decode content with
              | Ok decoded -> Text.equal text decoded
              | Error _ -> false)
          | Some content, Error (Tree.Not_utf_8 error) ->
              Text.decode content = Error error
          | _ -> false)
        path_names)

let lines_follow_the_text =
  property ~name:"lines gives the lines of the text, with the same errors"
    ~print:print_files files_gen (fun files ->
      let tree = tree_of (distinct files) in
      List.for_all
        (fun name ->
          let path = path_of name in
          let check () =
            match (Tree.text tree path, Tree.lines tree path) with
            | Ok text, Ok lines ->
                Text.equal (Lines.text lines) text
                && Lines.all lines = Lines.all (Lines.of_text text)
            | Error a, Error b -> a = b
            | _ -> false
          in
          check () && check ())
        path_names)

let same name_contents = List.sort compare (distinct name_contents)

let equal_compares_paths_and_contents =
  property ~count:500
    ~name:"equal holds when, and only when, the paths and contents are the same"
    ~print:(fun (a, b) -> print_files a ^ " / " ^ print_files b)
    (Gen.pair
       (Gen.list_size (Gen.int_range 0 3)
          (Gen.pair
             (Gen.oneof_list [ "a"; "b" ])
             (Gen.oneof_list [ "x"; "\xff" ])))
       (Gen.list_size (Gen.int_range 0 3)
          (Gen.pair
             (Gen.oneof_list [ "a"; "b" ])
             (Gen.oneof_list [ "x"; "\xff" ]))))
    (fun (a, b) ->
      Bool.equal
        (Tree.equal (tree_of (distinct a)) (tree_of (distinct b)))
        (same a = same b))

let corrupted_gen =
  Gen.(
    oneof_list [ "abc"; "a\r\nb\n"; "\xef\xbb\xbfx\xc3\xa9"; "\xe2\x80\xa8z" ]
    >>= Vector_json.corrupt_gen)

let text_and_lines_answer_every_content =
  property ~count:1000
    ~name:"text and lines give a value or the error of decode for any content"
    ~print:String.escaped corrupted_gen (fun content ->
      let tree = tree_of [ ("a", content) ] in
      let path = path_of "a" in
      match
        (Text.decode content, Tree.text tree path, Tree.lines tree path)
      with
      | Ok decoded, Ok text, Ok lines ->
          Text.equal decoded text && Text.equal (Lines.text lines) text
      | Error want, Error (Tree.Not_utf_8 a), Error (Tree.Not_utf_8 b) ->
          want = a && want = b
      | _ -> false)

let empty_has_no_file () =
  Alcotest.(check int) "the files" 0 (List.length (Tree.files Tree.empty));
  Alcotest.(check bool)
    "the empty list gives the empty tree" true
    (Tree.equal Tree.empty (tree_of []));
  Alcotest.(check bool)
    "no content" true
    (Tree.content Tree.empty (path_of "a") = None)

let two_domains_read_one_tree () =
  let files =
    List.init 50 (fun index ->
        (Printf.sprintf "f%d" index, String.make (index + 1) 'x' ^ "\n"))
  in
  let tree = tree_of files in
  let read () =
    List.map
      (fun (name, _) ->
        match Tree.lines tree (path_of name) with
        | Ok lines -> Lines.count lines
        | Error _ -> -1)
      files
  in
  let other = Domain.spawn read in
  let here = read () in
  Alcotest.(check (list int)) "the counts" here (Domain.join other);
  Alcotest.(check (list int)) "one line each" (List.map (fun _ -> 1) files) here

let tests =
  [
    of_files_refuses_a_repeated_path;
    files_gives_each_file_once_in_order;
    order_does_not_change_the_tree;
    content_gives_the_bytes_of_each_file;
    text_follows_the_content;
    lines_follow_the_text;
    equal_compares_paths_and_contents;
    text_and_lines_answer_every_content;
    Alcotest.test_case "the empty tree has no file" `Quick empty_has_no_file;
    Alcotest.test_case "two domains read the lines of one tree" `Quick
      two_domains_read_one_tree;
  ]
