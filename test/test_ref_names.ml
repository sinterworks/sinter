(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Ref_name = Sinter_ref_names.Ref_name

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f

let contains text sub =
  let n = String.length text and m = String.length sub in
  let rec go i = i + m <= n && (String.sub text i m = sub || go (i + 1)) in
  go 0

let reference_root_name name =
  name = "HEAD"
  || List.mem name
       [
         "AUTO_MERGE";
         "BISECT_EXPECTED_REV";
         "NOTES_MERGE_PARTIAL";
         "NOTES_MERGE_REF";
         "MERGE_AUTOSTASH";
       ]
  || String.length name >= 5
     && String.ends_with ~suffix:"_HEAD" name
     && String.for_all (fun c -> (c >= 'A' && c <= 'Z') || c = '_') name

let reference_ref_name name =
  String.is_valid_utf_8 name
  && (String.starts_with ~prefix:"refs/" name || reference_root_name name)
  && (not (String.ends_with ~suffix:"/" name))
  && (not (contains name "//"))
  && (not (contains name "/."))
  && (not (contains name ".lock/"))
  && (not (String.ends_with ~suffix:".lock" name))
  && (not (contains name ".."))
  && (not (contains name "@{"))
  && (not (String.ends_with ~suffix:"." name))
  && String.for_all
       (fun c ->
         let code = Char.code c in
         code > 31 && code <> 127 && not (String.contains " ~^:?*[\\" c))
       name

let names =
  [
    "refs/heads/main";
    "main";
    "HEAD";
    "a/b";
    "refs/heads/.x";
    "refs/heads/x.lock";
    "refs/heads/x.lock/y";
    "refs/heads/a..b";
    "refs/heads/a b";
    "refs/heads/a~";
    "refs/heads/a^";
    "refs/heads/a:b";
    "refs/heads/a?";
    "refs/heads/a*";
    "refs/heads/a[";
    "/refs/heads/a";
    "refs/heads/a/";
    "refs//heads";
    "refs/heads/a.";
    "refs/heads/a@{b";
    "@";
    "refs/heads/a\\b";
    "refs/heads/\x7f";
    "refs/heads/\x01";
    "refs/heads/\xc3\xa9";
    "refs/heads/\xff";
    "refs/heads/a@b";
    "refs/heads/@";
    "refs/heads/-x";
    "refs/heads/..";
    "refs/./x";
    "refs/heads/a.b";
    "refs/heads/a{b}";
    "refs/heads/a]";
    "refs/heads/a\tb";
    "refs/heads/lock";
    "refs/heads/x.lockx";
    "x/.lock";
    "";
    "/";
    "refs/heads/a/.b";
    "refs/heads/a.lock.b";
    "refs/heads/\x80";
    "refs/heads/\xc2\x80";
    "refs/heads/~";
    "refs/heads/\x1f";
    "refs/heads/\x20";
    "refs/heads/x//y";
    "refs/heads/xy//";
    "refs/heads/a.x..y";
    "refs/heads/x@x@{";
    "refs/heads/a!b";
    "@{a/b";
    "refs/heads/!";
    "refs/heads/a./b";
    "refs/";
    "refs";
    "REFS/heads/x";
    "FETCH_HEAD";
    "ORIG_HEAD";
    "_HEAD";
    "A_B_HEAD";
    "HEADX";
    "head";
    "Fetch_HEAD";
    "X_HEAD/y";
    "AUTO_MERGE";
    "BISECT_EXPECTED_REV";
    "NOTES_MERGE_PARTIAL";
    "NOTES_MERGE_REF";
    "MERGE_AUTOSTASH";
    "MERGE_AUTOSTASHX";
    "Z_HEAD";
    "ZZ_HEAD";
    "AZ_HEAD";
    "Z";
    "HEAD/x";
    "refs/heads/HEAD";
    "refs/heads/\xe2\x82\xac";
    "refs/heads/\xed\xa0\x80";
    "refs/heads/a/b.lock/c";
  ]

let git_accepts name =
  let devnull = Unix.openfile "/dev/null" [ Unix.O_WRONLY ] 0 in
  Fun.protect
    ~finally:(fun () -> Unix.close devnull)
    (fun () ->
      let pid =
        Unix.create_process "git"
          [| "git"; "check-ref-format"; name |]
          Unix.stdin devnull devnull
      in
      match Unix.waitpid [] pid with
      | _, Unix.WEXITED 0 -> true
      | _, Unix.WEXITED 1 -> false
      | _ -> Alcotest.failf "git check-ref-format %S did not end" name)

let name_gen =
  Gen.(
    map (String.concat "")
      (list_size (int_range 0 8)
         (oneof_list
            [
              "refs";
              "refs/";
              "/";
              ".";
              "..";
              "a";
              "\000";
              "lock";
              ".lock";
              "-";
              "@";
              "{";
              "\xff";
              "\xc3\xa9";
              "HEAD";
              "_";
              "A";
              " ";
              "~";
              "\x7f";
              "\x1f";
              "!";
            ])))

let tests =
  [
    case "a ref name meets the seven rules of the term" (fun () ->
        List.iter
          (fun name ->
            Alcotest.(check bool)
              (Printf.sprintf "%S" name) (reference_ref_name name)
              (Ref_name.is_ref_name name))
          names);
    case
      "a root name is HEAD, a name of A to Z and _ ending in _HEAD, or one of \
       five" (fun () ->
        List.iter
          (fun name ->
            Alcotest.(check bool)
              (Printf.sprintf "%S" name) (reference_root_name name)
              (Ref_name.is_root_name name))
          names);
    case "a ref name under refs/ is one that git check-ref-format accepts"
      (fun () ->
        List.iter
          (fun name ->
            if
              String.starts_with ~prefix:"refs/" name
              && String.is_valid_utf_8 name
            then
              Alcotest.(check bool)
                (Printf.sprintf "%S" name) (git_accepts name)
                (Ref_name.is_ref_name name))
          names);
    case "a name with the byte 0x00 is no ref name" (fun () ->
        Alcotest.(check bool)
          "0x00" false
          (Ref_name.is_ref_name "refs/heads/a\000b"));
    property ~count:3000 ~name:"a ref name meets the rules, for generated names"
      ~print:(Printf.sprintf "%S") name_gen (fun name ->
        Ref_name.is_ref_name name = reference_ref_name name
        && Ref_name.is_root_name name = reference_root_name name);
    property ~count:3000 ~name:"a ref name gives a pathname inside a folder"
      ~print:(Printf.sprintf "%S") name_gen (fun name ->
        (not (Ref_name.is_ref_name name))
        || (not (String.contains name '\000'))
           && (not (String.starts_with ~prefix:"/" name))
           && List.for_all
                (fun part -> part <> "" && part <> "." && part <> "..")
                (String.split_on_char '/' name));
  ]
