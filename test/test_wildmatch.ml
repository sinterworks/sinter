(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Wildmatch = Sinter_wildmatch

let property ?(count = 1000) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f

let matches ?case_fold pattern pathname =
  Wildmatch.matches (Wildmatch.compile ?case_fold pattern) pathname

module Reference = struct
  type member = Byte of char | Range of char * char | Class of (char -> bool)

  type token =
    | Literal of char
    | One
    | Star
    | Names
    | Everything
    | Bracket of bool * member list
    | Never

  let classes =
    let ascii c = Char.code c < 0x80 in
    let lower c = c >= 'a' && c <= 'z' and upper c = c >= 'A' && c <= 'Z' in
    let digit c = c >= '0' && c <= '9' in
    let alpha c = lower c || upper c in
    let graph c = Char.code c > 0x20 && Char.code c < 0x7F in
    [
      ("alnum", fun c -> alpha c || digit c);
      ("alpha", alpha);
      ("blank", fun c -> c = ' ' || c = '\t');
      ("cntrl", fun c -> ascii c && (Char.code c < 0x20 || Char.code c = 0x7F));
      ("digit", digit);
      ("graph", graph);
      ("lower", lower);
      ("print", fun c -> graph c || c = ' ');
      ("punct", fun c -> graph c && not (alpha c || digit c));
      ("space", fun c -> c = ' ' || (Char.code c >= 9 && Char.code c <= 13));
      ("upper", upper);
      ( "xdigit",
        fun c -> digit c || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F') );
    ]

  let find_from s start sub =
    let n = String.length s and m = String.length sub in
    let rec go i =
      if i + m > n then None
      else if String.sub s i m = sub then Some i
      else go (i + 1)
    in
    go start

  let bracket p i =
    let n = String.length p in
    let negated, i =
      if i < n && (p.[i] = '!' || p.[i] = '^') then (true, i + 1) else (false, i)
    in
    let rec members i first acc =
      if i >= n then None
      else if p.[i] = ']' && not first then Some (List.rev acc, i + 1)
      else if p.[i] = '[' && i + 1 < n && p.[i + 1] = ':' then
        match find_from p (i + 2) ":]" with
        | None -> None
        | Some close -> (
            match
              List.assoc_opt (String.sub p (i + 2) (close - i - 2)) classes
            with
            | Some test -> members (close + 2) false (Class test :: acc)
            | None -> None)
      else
        let byte, next =
          if p.[i] = '\\' && i + 1 < n then (p.[i + 1], i + 2)
          else (p.[i], i + 1)
        in
        if next + 1 < n && p.[next] = '-' && p.[next + 1] <> ']' then
          let last, after =
            if p.[next + 1] = '\\' && next + 2 < n then (p.[next + 2], next + 3)
            else (p.[next + 1], next + 2)
          in
          members after false (Range (byte, last) :: acc)
        else members next false (Byte byte :: acc)
    in
    match members i true [] with
    | None -> None
    | Some (list, next) -> Some (Bracket (negated, list), next)

  let tokens p =
    let n = String.length p in
    let rec go i acc =
      if i >= n then List.rev acc
      else
        match p.[i] with
        | '\\' ->
            if i + 1 >= n then List.rev (Never :: acc)
            else go (i + 2) (Literal p.[i + 1] :: acc)
        | '?' -> go (i + 1) (One :: acc)
        | '*' ->
            let j = ref i in
            while !j < n && p.[!j] = '*' do
              incr j
            done;
            let run = !j - i in
            let before = i = 0 || p.[i - 1] = '/' in
            let slash_after =
              if !j < n && p.[!j] = '/' then Some 1
              else if !j + 1 < n && p.[!j] = '\\' && p.[!j + 1] = '/' then
                Some 2
              else None
            in
            if run >= 2 && before && !j = n then List.rev (Everything :: acc)
            else if run >= 2 && before && slash_after <> None then
              go (!j + Option.value slash_after ~default:0) (Names :: acc)
            else go !j (Star :: acc)
        | '[' -> (
            match bracket p (i + 1) with
            | None -> List.rev (Never :: acc)
            | Some (token, next) -> go next (token :: acc))
        | c -> go (i + 1) (Literal c :: acc)
    in
    go 0 []

  let fold c = Char.lowercase_ascii c

  let member_matches case_fold c member =
    let test c =
      match member with
      | Byte b -> b = c
      | Range (a, b) -> a <= c && c <= b
      | Class f -> f c
    in
    test c
    || case_fold
       && (test (Char.lowercase_ascii c) || test (Char.uppercase_ascii c))

  let matches ?(case_fold = false) pattern s =
    let tokens = Array.of_list (tokens pattern) in
    let n = String.length s in
    let memo = Hashtbl.create 64 in
    let rec go t i =
      match Hashtbl.find_opt memo (t, i) with
      | Some r -> r
      | None ->
          let r =
            if t = Array.length tokens then i = n
            else
              match tokens.(t) with
              | Never -> false
              | Literal c ->
                  i < n
                  && (s.[i] = c || (case_fold && fold s.[i] = fold c))
                  && go (t + 1) (i + 1)
              | One -> i < n && s.[i] <> '/' && go (t + 1) (i + 1)
              | Star -> go (t + 1) i || (i < n && s.[i] <> '/' && go t (i + 1))
              | Everything -> true
              | Names ->
                  go (t + 1) i
                  || List.exists
                       (fun j -> s.[j] = '/' && go (t + 1) (j + 1))
                       (List.init (n - i) (fun k -> i + k))
              | Bracket (negated, members) ->
                  i < n
                  && s.[i] <> '/'
                  && List.exists (member_matches case_fold s.[i]) members
                     <> negated
                  && go (t + 1) (i + 1)
          in
          Hashtbl.replace memo (t, i) r;
          r
    in
    go 0 0
end

let table =
  [
    ("**/foo", "foo", true);
    ("**/foo", "a/foo", true);
    ("**/foo", "a/b/foo", true);
    ("**/foo", "afoo", false);
    ("**/foo/bar", "x/foo/bar", true);
    ("abc/**", "abc/x", true);
    ("abc/**", "abc/x/y", true);
    ("abc/**", "abc/", true);
    ("abc/**", "abc", false);
    ("a/**/b", "a/b", true);
    ("a/**/b", "a/x/b", true);
    ("a/**/b", "a/x/y/b", true);
    ("a/**/b", "ab", false);
    ("a/**/b", "a/xb", false);
    ("a/***/b", "a/x/y/b", true);
    ("a**", "abc", true);
    ("a**", "a/b", false);
    ("**a", "x/a", false);
    ("**\\/x", "a/x", true);
    ("**\\/x", "x", true);
    ("*", "", true);
    ("*", "a/b", false);
    ("*.md", "a.md", true);
    ("*.md", "d/a.md", false);
    ("?", "/", false);
    ("?", "\xff", true);
    ("??", "\xc3\xa9", true);
    ("[a-c]", "b", true);
    ("[a-c]", "d", false);
    ("[!a-c]", "d", true);
    ("[^a-c]", "b", false);
    ("[!a]", "/", false);
    ("[/]", "/", false);
    ("[]]", "]", true);
    ("[!]]", "]", false);
    ("[a-]", "-", true);
    ("[c-a]", "b", false);
    ("[!c-a]", "b", true);
    ("[[:digit:]]", "7", true);
    ("[[:digit:]x]", "x", true);
    ("[[:upper:]]", "a", false);
    ("[[:alpha:]]", "\xe9", false);
    ("[\\]]", "]", true);
    ("\\*", "*", true);
    ("\\*", "a", false);
    ("\\a", "a", true);
    ("foo\\", "foo\\", false);
    ("foo\\", "foo", false);
    ("[abc", "[abc", false);
    ("[abc", "a", false);
    ("[[:foo:]]", "f", false);
    ("[[:alpha:", "a", false);
    ("[[:alpha_]]", "a", false);
    ("[[:digitx]:]]", "5", false);
    ("\\*a", "*a", true);
    ("\\*a", "*", false);
    ("[[a]", "[", true);
    ("[[a]", "a", true);
    ("[a:]", ":", true);
    ("[a:]", "a", true);
    ("\\ab", "ab", true);
    ("\\ab", "a", false);
    ("[[:a:", "a", false);
    ("**\\", "a", false);
    ("a/**\\", "a/b", false);
    ("**\\x", "ax", true);
    ("**\\x", "a/x", false);
    ("a/b", "a/b", true);
    ("a/b", "a/b/", false);
  ]

let fold_table =
  [
    ("A*", "abc", true, false);
    ("[A-C]", "b", true, false);
    ("[[:upper:]]", "a", true, false);
    ("[!A]", "a", false, true);
    ("\xc3\x89", "\xc3\xa9", false, false);
  ]

(* @verifies changes#give-default-branch-commits=v1
   The patterns of the conditions `gitdir:`, `gitdir/i:`, `onbranch:`, and
   `hasconfig:remote.*.url:` decide which included files give settings of the
   git configuration, and so the upstream of the default branch. Each pattern
   of the table must match each pathname of the table as the patterns of the
   page gitignore match a full pathname, and, with case folding, as the
   condition `gitdir/i:` of the page git-config matches. *)
let table_tests =
  [
    case "the patterns of the table match as the rules give" (fun () ->
        List.iter
          (fun (pattern, pathname, expected) ->
            Alcotest.(check bool)
              (Printf.sprintf "%S against %S" pattern pathname)
              expected (matches pattern pathname);
            Alcotest.(check bool)
              (Printf.sprintf "the reference: %S against %S" pattern pathname)
              expected
              (Reference.matches pattern pathname))
          table);
    case "with case_fold, the letters A to Z match a to z" (fun () ->
        List.iter
          (fun (pattern, pathname, folded, plain) ->
            Alcotest.(check bool)
              (Printf.sprintf "%S against %S" pattern pathname)
              folded
              (matches ~case_fold:true pattern pathname);
            Alcotest.(check bool)
              (Printf.sprintf "without case_fold: %S against %S" pattern
                 pathname)
              plain (matches pattern pathname))
          fold_table);
  ]

(* @verifies changes#give-default-branch-commits=v1
   In a pattern of a condition of the git configuration, a class of a bracket
   expression must match exactly its bytes of 0x00 to 0x7F, and a range must
   match each byte from its first byte to its second byte, by their values,
   other than `/`. *)
let class_tests =
  [
    case "each class matches exactly its bytes of 0x00 to 0x7F" (fun () ->
        List.iter
          (fun (name, test) ->
            let pattern = Wildmatch.compile ("[[:" ^ name ^ ":]]") in
            let negated = Wildmatch.compile ("[![:" ^ name ^ ":]]") in
            for code = 0 to 255 do
              let byte = String.make 1 (Char.chr code) in
              let expected =
                code < 0x80 && byte <> "/" && test (Char.chr code)
              in
              Alcotest.(check bool)
                (Printf.sprintf "%s and 0x%02x" name code)
                expected
                (Wildmatch.matches pattern byte);
              Alcotest.(check bool)
                (Printf.sprintf "not %s and 0x%02x" name code)
                (byte <> "/" && not (code < 0x80 && test (Char.chr code)))
                (Wildmatch.matches negated byte)
            done)
          Reference.classes);
    case "with case_fold, each class also matches the other case of its letters"
      (fun () ->
        List.iter
          (fun (name, test) ->
            let pattern =
              Wildmatch.compile ~case_fold:true ("[[:" ^ name ^ ":]]")
            in
            for code = 0 to 255 do
              let c = Char.chr code in
              let expected =
                code < 0x80 && c <> '/'
                && (test c
                   || test (Char.lowercase_ascii c)
                   || test (Char.uppercase_ascii c))
              in
              Alcotest.(check bool)
                (Printf.sprintf "%s and 0x%02x" name code)
                expected
                (Wildmatch.matches pattern (String.make 1 c))
            done)
          Reference.classes);
    case "a range matches each byte between its ends, by their values"
      (fun () ->
        List.iter
          (fun (low, high) ->
            let pattern =
              Wildmatch.compile
                (Printf.sprintf "[%c-%c]" (Char.chr low) (Char.chr high))
            in
            for code = 0 to 255 do
              Alcotest.(check bool)
                (Printf.sprintf "0x%02x-0x%02x and 0x%02x" low high code)
                (code >= low && code <= high && code <> Char.code '/')
                (Wildmatch.matches pattern (String.make 1 (Char.chr code)))
            done)
          [ (0x01, 0x7e); (0x80, 0xff); (0x30, 0x39); (0x41, 0x41) ]);
  ]

let pattern_gen =
  Gen.(
    map (String.concat "")
      (list_size (int_range 0 7)
         (oneof_list
            [
              "a";
              "b";
              "A";
              "/";
              "*";
              "**";
              "?";
              "[ab]";
              "[!a]";
              "[a-c]";
              "[[:digit:]]";
              "[[:upper:]]";
              "\\*";
              "1";
              "[]]";
              "[^/]";
              "\\";
              "[";
              "-";
              "]";
              "\\/";
              "[a-]";
              "[c-a]";
            ])))

let pathname_gen =
  Gen.(
    map (String.concat "")
      (list_size (int_range 0 7)
         (oneof_list
            [ "a"; "b"; "A"; "B"; "/"; "*"; "1"; "]"; "-"; "\xff"; "c" ])))

(* @verifies changes#give-default-branch-commits=v1
   Over generated patterns and pathnames, a pattern of a condition of the git
   configuration must match a pathname exactly when a direct reading of the
   rules of the page gitignore for a full pathname gives a match, with case
   folding and without it, and a pattern of any bytes must give a result. *)
let reference_properties =
  [
    property ~name:"a match agrees with a direct reading of the rules"
      ~print:(fun (p, s) -> Printf.sprintf "%S against %S" p s)
      (Gen.pair pattern_gen pathname_gen)
      (fun (pattern, pathname) ->
        matches pattern pathname = Reference.matches pattern pathname);
    property ~name:"a match with case_fold agrees with a direct reading"
      ~print:(fun (p, s) -> Printf.sprintf "%S against %S" p s)
      (Gen.pair pattern_gen pathname_gen)
      (fun (pattern, pathname) ->
        matches ~case_fold:true pattern pathname
        = Reference.matches ~case_fold:true pattern pathname);
    property ~count:2000
      ~name:"a pattern of any bytes compiles and never raises"
      ~print:(fun (p, s) -> Printf.sprintf "%S against %S" p s)
      Gen.(
        pair
          (string_size ~gen:char (int_range 0 20))
          (string_size ~gen:char (int_range 0 20)))
      (fun (pattern, pathname) ->
        ignore (matches pattern pathname);
        ignore (matches ~case_fold:true pattern pathname);
        true);
  ]

let cost_tests =
  [
    case "a match takes time at most the product of the two lengths" (fun () ->
        match
          Timed_work.growth ~exponent:2. ~margin:8. ~runs:3 ~sizes:(40, 400)
            ~input:(fun n ->
              ( Wildmatch.compile
                  (String.concat "" (List.init n (fun _ -> "*a")) ^ "b"),
                String.make n 'a' ))
            (fun (pattern, pathname) -> Wildmatch.matches pattern pathname)
        with
        | Ok () -> ()
        | Error message -> Alcotest.fail message);
    case "a compile takes time linear in the length of the pattern" (fun () ->
        Counted_work.check_growth ~margin:4. ~sizes:(1_000, 100_000)
          ~input:(fun n -> String.concat "" (List.init n (fun _ -> "[a-c]")))
          (fun pattern -> Wildmatch.compile pattern));
    case "a match of long inputs needs no deep stack" (fun () ->
        let n = 5_000 in
        let pattern =
          Wildmatch.compile (String.concat "" (List.init n (fun _ -> "?")))
        in
        let deep =
          Wildmatch.compile
            (String.concat "/" (List.init 2_000 (fun _ -> "**")) ^ "/x")
        in
        let pathname = String.make n 'a' in
        Alcotest.(check bool)
          "matched" true
          (Small_stack.run (fun () ->
               Wildmatch.matches pattern pathname
               && Wildmatch.matches deep
                    (String.concat "/" (List.init 1000 (fun _ -> "d")) ^ "/x"))));
  ]

let tests = table_tests @ class_tests @ reference_properties @ cost_tests
