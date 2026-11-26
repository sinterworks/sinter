(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_ecma_pattern
module Gen = QCheck2.Gen

let text s =
  match Text.decode s with
  | Ok t -> t
  | Error _ -> invalid_arg "Test_ecma_pattern.text"

let compile_error_text = function
  | Pattern.Not_valid message -> "not valid: " ^ message
  | Too_deep -> "too deep"
  | Too_large -> "too large"

let stop_text = function Pattern.Steps -> "steps" | Memory -> "memory"

let compiled ?depth ?memory source =
  match Pattern.compile ?depth ?memory (text source) with
  | Ok p -> p
  | Error e -> Alcotest.failf "the pattern %S: %s" source (compile_error_text e)

let found ?steps ?memory pattern subject =
  match Pattern.test ?steps ?memory pattern (text subject) with
  | Ok b -> b
  | Error s -> Alcotest.failf "the test of %S stopped: %s" subject (stop_text s)

let case name f = Alcotest.test_case name `Quick f

let raises_invalid_argument what f =
  match f () with
  | exception Invalid_argument _ -> ()
  | _ -> Alcotest.failf "%s did not raise Invalid_argument" what

type node_result = Gives of bool | Syntax_error

let results_of_node_v24 =
  [
    ("^\\(\\*\\*[^*]", "(** doc *)", Gives true);
    ("^\\(\\*\\*[^*]", "(* plain *)", Gives false);
    ("abc", "xxabcxx", Gives true);
    ("^abc$", "abc", Gives true);
    ("^abc$", "abcd", Gives false);
    ("b", "abc", Gives true);
    ("^b", "abc", Gives false);
    ("\\w", "\xc3\xa9", Gives false);
    ("\\w", "_", Gives true);
    ("^\\w+$", "abc_19", Gives true);
    ("\\p{L}", "\xc3\xa9", Gives true);
    ("\\P{L}", "\xc3\xa9", Gives false);
    ("\\p{Lu}", "\xc3\x89", Gives true);
    ("\\p{Script=Greek}", "\xce\xb1", Gives true);
    ("\\p{Script=Greek}", "a", Gives false);
    ("\\d", "7", Gives true);
    ("\\d", "\xd9\xa1", Gives false);
    ("^.$", "\xf0\x9f\x98\x80", Gives true);
    ("^..$", "\xf0\x9f\x98\x80", Gives false);
    ("^[^a]$", "\xf0\x9f\x98\x80", Gives true);
    ("[^\\uDE00]", "\xf0\x9f\x98\x80", Gives true);
    ("\\uD83D", "\xf0\x9f\x98\x80", Gives false);
    ("^\\u{1F600}$", "\xf0\x9f\x98\x80", Gives true);
    ("^\\uD83D\\uDE00$", "\xf0\x9f\x98\x80", Gives true);
    ("^\xf0\x9f\x98\x80$", "\xf0\x9f\x98\x80", Gives true);
    ("^.{2}$", "\xc3\xa9\xf0\x9f\x98\x80", Gives true);
    ("\xc3\xa9", "caf\xc3\xa9", Gives true);
    ("\\s", "\xc2\xa0", Gives true);
    ("\\s", "\xef\xbb\xbf", Gives true);
    ("^\\s$", "x", Gives false);
    ("^.$", "\n", Gives false);
    ("^.$", "\r", Gives false);
    ("^.$", "\xe2\x80\xa8", Gives false);
    ("^.$", "\xe2\x80\xa9", Gives false);
    ("^.$", "\xc2\x85", Gives true);
    ("^[\\s\\S]$", "\n", Gives true);
    ("(?i:abc)", "ABC", Gives true);
    ("(?i)abc", "ABC", Syntax_error);
    ("(?i:s)", "\xc5\xbf", Gives true);
    ("(?<=a)b", "ab", Gives true);
    ("(?<=a)b", "cb", Gives false);
    ("(?<!a)b", "ab", Gives false);
    ("(?<!a)b", "b", Gives true);
    ("(?<x>a)\\k<x>", "aa", Gives true);
    ("(?<x>a)\\k<x>", "ab", Gives false);
    ("\\bfoo\\b", "a foo b", Gives true);
    ("\\bfoo\\b", "afoob", Gives false);
    ("a(?=b)", "ab", Gives true);
    ("a(?!b)", "ab", Gives false);
    ("(?:a{2}){3}", "aaaaaa", Gives true);
    ("^(?:a{2}){3}$", "aaaaa", Gives false);
    ("", "", Gives true);
    ("(?:)", "x", Gives true);
    ("^$", "", Gives true);
    ("-", "-", Gives true);
    ("\\\\((a))", "\\a", Gives true);
    ("[(](a)", "(a", Gives true);
    ("\\((a)", "(a", Gives true);
    ("^(a+)+$", "aaaaaaaaaaaaaaaaaa!", Gives false);
    ("^(?:a|aa)*$", "aaaaaaaaaaaaaaaaaaaaaaaab", Gives false);
    ("\\p{RGI_Emoji}", "x", Syntax_error);
    ("[\\p{L}--[a-z]]", "x", Syntax_error);
    ("a{", "a{", Syntax_error);
    ("\\-", "-", Syntax_error);
    ("(", "(", Syntax_error);
    ("[z-a]", "a", Syntax_error);
    ("\\c", "c", Syntax_error);
    ("]", "]", Syntax_error);
    ("}", "}", Syntax_error);
    ("a**", "a", Syntax_error);
    ("\\p{Foo}", "a", Syntax_error);
    ("(?<x>a)(?<x>b)", "ab", Syntax_error);
    ("\\k<y>", "a", Syntax_error);
    ("[\\d-z]", "-", Syntax_error);
    ("x{2,1}", "xx", Syntax_error);
    ("\\u{110000}", "a", Syntax_error);
    ("\000", "a\000b", Gives true);
    ("\000", "ab", Gives false);
    ("a\000b", "a\000b", Gives true);
    ("a\000b", "ab", Gives false);
    ("^\000", "\000", Gives true);
    ("^\000", "a", Gives false);
    ("[\000]", "\000", Gives true);
    ("[\000]", "a", Gives false);
    ("\000\000", "a\000\000", Gives true);
    ("\000\000", "\000", Gives false);
    ("\\\000", "\000", Syntax_error);
    ("\\\\\000", "\\\000", Gives true);
    ("\\\\\000", "\000", Gives false);
    ("[\\\000]", "\000", Syntax_error);
    ("\\\\\\\000", "\\\000", Syntax_error);
    ("^\\u{10000}$", "\xf0\x90\x80\x80", Gives true);
    ("^\\uD800\\uDC00$", "\xf0\x90\x80\x80", Gives true);
    ("^.$", "\xf0\x90\x80\x80", Gives true);
    ("\\uD800", "\xf0\x90\x80\x80", Gives false);
    ("^[\\u{10000}-\\u{10001}]$", "\xf0\x90\x80\x81", Gives true);
    ("^\\uFFFF$", "\xef\xbf\xbf", Gives true);
    ("^.$", "\xef\xbf\xbf", Gives true);
    ("^(a+)+$", String.make 15 'a' ^ "!" ^ String.make 50_000 'z', Gives false);
  ]

let cases_that_the_flags_i_m_s_g_or_y_change =
  [
    ("A", "a", false);
    ("^b", "a\nb", false);
    ("a$", "a\n", false);
    ("a.b", "a\nb", false);
  ]

let ecma_tests =
  [
    case
      "each pattern gives the result of RegExp.prototype.test with the flag u"
      (fun () ->
        List.iter
          (fun (source, subject, expected) ->
            match (Pattern.compile (text source), expected) with
            | Ok p, Gives b ->
                Alcotest.(check bool)
                  (Printf.sprintf "%S on %S" source subject)
                  b (found p subject)
            | Error (Not_valid _), Syntax_error -> ()
            | Ok _, Syntax_error ->
                Alcotest.failf "%S is not valid with the flag u, and compiled"
                  source
            | Error e, _ ->
                Alcotest.failf "%S: %s" source (compile_error_text e))
          results_of_node_v24);
    case "a pattern has no flag but u" (fun () ->
        List.iter
          (fun (source, subject, expected) ->
            Alcotest.(check bool)
              (Printf.sprintf "%S on %S" source subject)
              expected
              (found (compiled source) subject))
          cases_that_the_flags_i_m_s_g_or_y_change);
    case "each test of one pattern searches from index 0 again" (fun () ->
        let p = compiled "a" in
        List.iter
          (fun _ ->
            Alcotest.(check bool) "a match of a in a" true (found p "a"))
          [ 1; 2; 3 ]);
  ]

let depth_tests =
  let nested n = String.make n '(' ^ "a" ^ String.make n ')' in
  [
    case "the default depth is 100" (fun () ->
        Alcotest.(check int) "default_depth" 100 Pattern.default_depth);
    case "a group inside 100 other groups compiles with the default depth"
      (fun () -> ignore (compiled (nested 101)));
    case "a group inside 101 other groups is too deep with the default depth"
      (fun () ->
        match Pattern.compile (text (nested 102)) with
        | Error Too_deep -> ()
        | Ok _ -> Alcotest.fail "it compiled"
        | Error e -> Alcotest.fail (compile_error_text e));
    case "a group inside a group is too deep with the depth 0" (fun () ->
        List.iter
          (fun source ->
            match Pattern.compile ~depth:0 (text source) with
            | Error Too_deep -> ()
            | Ok _ -> Alcotest.failf "%S compiled" source
            | Error e -> Alcotest.failf "%S: %s" source (compile_error_text e))
          [ "((a))"; "(?:(?:a))"; "(?=(a))"; "\\\\((a))"; "((" ]);
    case "a parenthesis in an escape or a class is no group" (fun () ->
        List.iter
          (fun source -> ignore (compiled ~depth:0 source))
          [ "(a)(b)"; "[(](a)"; "\\((a)"; "[\\](](a)"; "[[(](a)"; "a" ]);
    case "the depth 200 is allowed, and nothing above it" (fun () ->
        ignore (compiled ~depth:200 (nested 201));
        raises_invalid_argument "the depth 201" (fun () ->
            Pattern.compile ~depth:201 (text "a")));
    case "a negative depth or memory raises Invalid_argument" (fun () ->
        raises_invalid_argument "the depth -1" (fun () ->
            Pattern.compile ~depth:(-1) (text "a"));
        raises_invalid_argument "the memory -1" (fun () ->
            Pattern.compile ~memory:(-1) (text "a")));
    case "a compilation with no memory is too large, unless it is too deep"
      (fun () ->
        List.iter
          (fun source ->
            match Pattern.compile ~memory:0 (text source) with
            | Error Too_large -> ()
            | Ok _ -> Alcotest.failf "%S compiled" source
            | Error e -> Alcotest.failf "%S: %s" source (compile_error_text e))
          [ ""; "a"; "(a)"; "(" ];
        match Pattern.compile ~depth:0 ~memory:0 (text "((a))") with
        | Error Too_deep -> ()
        | Ok _ -> Alcotest.fail "it compiled"
        | Error e -> Alcotest.fail (compile_error_text e));
    case "the default memory of a compilation is 64 MiB" (fun () ->
        Alcotest.(check int)
          "default_compile_memory" 67_108_864 Pattern.default_compile_memory);
  ]

let catastrophic = "^(a+)+$"
let thirty = String.make 30 'a' ^ "!"

let limit_tests =
  [
    case "the defaults of a test are 10,000 steps and 256 MiB" (fun () ->
        Alcotest.(check int) "default_steps" 10_000 Pattern.default_steps;
        Alcotest.(check int)
          "default_test_memory" 268_435_456 Pattern.default_test_memory);
    case "the step limit stops a pattern that backtracks without end" (fun () ->
        let p = compiled catastrophic in
        List.iter
          (fun steps ->
            match Pattern.test ?steps p (text thirty) with
            | Error Steps -> ()
            | Ok b -> Alcotest.failf "the test ended with %b" b
            | Error Memory -> Alcotest.fail "the test stopped for memory")
          [ Some 0; Some 1; Some 100; None ]);
    case "a test with few polls ends under the step limit 0" (fun () ->
        Alcotest.(check bool) "a in a" true (found ~steps:0 (compiled "a") "a"));
    case "the same pattern, text, and steps give the same result each time"
      (fun () ->
        let p = compiled "^(?:a|aa)*$" in
        let subject = String.make 22 'a' ^ "b" in
        let results =
          List.init 3 (fun _ ->
              List.map
                (fun steps -> Pattern.test ~steps p (text subject))
                [ 0; 1; 3; 10; 30; 100 ])
        in
        match results with
        | first :: rest ->
            List.iter
              (fun r -> if r <> first then Alcotest.fail "the results differ")
              rest
        | [] -> ());
    case "a subject of more UTF-16 code units than half the memory stops"
      (fun () ->
        let p = compiled "x" in
        let subject =
          "abcdef"
          ^ String.concat "" (List.init 4 (fun _ -> "\xf0\x9f\x98\x80"))
        in
        match Pattern.test ~memory:27 p (text subject) with
        | Error Memory -> ()
        | Ok b -> Alcotest.failf "the test gave %b" b
        | Error Steps -> Alcotest.fail "the test stopped for steps");
    case "a negative step limit or memory raises Invalid_argument" (fun () ->
        let p = compiled "a" in
        raises_invalid_argument "the steps -1" (fun () ->
            Pattern.test ~steps:(-1) p (text "a"));
        raises_invalid_argument "the memory -1" (fun () ->
            Pattern.test ~memory:(-1) p (text "a")));
  ]

let uchar_of_int n = Uchar.of_int n

let any_char =
  Gen.oneof
    [
      Gen.map uchar_of_int (Gen.int_range 0 0x7f);
      Gen.map uchar_of_int (Gen.int_range 0x80 0x7ff);
      Gen.map uchar_of_int (Gen.int_range 0x800 0xd7ff);
      Gen.map uchar_of_int (Gen.int_range 0xe000 0xffff);
      Gen.map uchar_of_int (Gen.int_range 0x10000 0x10ffff);
    ]

let text_of chars = Text.of_uchars chars

let gen_text ?(max = 12) chars =
  Gen.map text_of (Gen.list_size (Gen.int_range 0 max) chars)

let pattern_piece =
  Gen.oneof_list
    [
      "a";
      "b";
      ".";
      "*";
      "+";
      "?";
      "|";
      "(";
      ")";
      "(?:";
      "(?=";
      "(?<=";
      "(?<n>";
      "\\k<n>";
      "[";
      "]";
      "^";
      "-";
      "{";
      "}";
      "{2}";
      "{1,3}";
      "\\";
      "\\w";
      "\\d";
      "\\s";
      "\\b";
      "\\p{L}";
      "\\u{1F600}";
      "\\uD83D";
      "$";
      "\xc3\xa9";
      "\xf0\x9f\x98\x80";
      "\x00";
      "/";
    ]

let gen_pattern_source =
  Gen.oneof
    [
      Gen.map (String.concat "")
        (Gen.list_size (Gen.int_range 0 10) pattern_piece);
      Gen.map (fun t -> Text.encode t) (gen_text ~max:8 any_char);
    ]

let subject_char =
  Gen.oneof
    [
      Gen.oneof_list
        (List.map Uchar.of_int
           [ 0x61; 0x62; 0x0a; 0x0d; 0xe9; 0x1f600; 0x2028; 0x00; 0x41 ]);
      any_char;
    ]

let print_pair (source, subject) =
  Printf.sprintf "%S on %S" source (Text.encode subject)

let char_that_matches_itself =
  Gen.oneof_list
    (List.map Uchar.of_int
       [ 0x61; 0x62; 0x63; 0x30; 0x2d; 0x2c; 0x20; 0xe9; 0x3b1; 0x1f600; 0x00 ])

let contains ~sub s =
  let n = String.length sub and m = String.length s in
  let rec go i = i + n <= m && (String.sub s i n = sub || go (i + 1)) in
  go 0

let is_line_terminator u =
  match Uchar.to_int u with 0x0a | 0x0d | 0x2028 | 0x2029 -> true | _ -> false

let property_tests =
  [
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:500 ~name:"compile never raises on any text"
         ~print:(fun s -> Printf.sprintf "%S" s)
         gen_pattern_source
         (fun source ->
           match Text.decode source with
           | Error _ -> true
           | Ok t -> ( match Pattern.compile t with Ok _ | Error _ -> true)));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:500
         ~name:"a test gives a result or a stop, the same one each time"
         ~print:print_pair
         Gen.(pair gen_pattern_source (gen_text subject_char))
         (fun (source, subject) ->
           match Text.decode source with
           | Error _ -> true
           | Ok t -> (
               match Pattern.compile t with
               | Error _ -> true
               | Ok p ->
                   let r = Pattern.test ~steps:2 p subject in
                   r = Pattern.test ~steps:2 p subject)));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:300
         ~name:"a result under a step limit stays under a higher one"
         ~print:print_pair
         Gen.(pair gen_pattern_source (gen_text subject_char))
         (fun (source, subject) ->
           match Text.decode source with
           | Error _ -> true
           | Ok t -> (
               match Pattern.compile t with
               | Error _ -> true
               | Ok p -> (
                   match Pattern.test ~steps:0 p subject with
                   | Error _ -> true
                   | Ok b -> Pattern.test ~steps:5 p subject = Ok b))));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:500
         ~name:"a pattern of literal characters matches where its text occurs"
         ~print:(fun (p, s) ->
           Printf.sprintf "%S in %S"
             (Text.encode (text_of p))
             (Text.encode (text_of s)))
         Gen.(
           pair
             (list_size (int_range 0 3) char_that_matches_itself)
             (list_size (int_range 0 8) char_that_matches_itself))
         (fun (p, s) ->
           let sub = Text.encode (text_of p)
           and whole = Text.encode (text_of s) in
           let pattern = compiled sub in
           Pattern.test pattern (text_of s) = Ok (contains ~sub whole)
           && Pattern.test (compiled ("^" ^ sub ^ "$")) (text_of s)
              = Ok (sub = whole)));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:500
         ~name:"the dot matches one code point that ends no line"
         ~print:(fun s -> Printf.sprintf "%S" (Text.encode (text_of s)))
         (Gen.list_size (Gen.int_range 0 6) subject_char)
         (fun chars ->
           let n = List.length chars in
           let source = Printf.sprintf "^.{%d}$" n in
           Pattern.test (compiled source) (text_of chars)
           = Ok (not (List.exists is_line_terminator chars))));
  ]

let growth_tests =
  [
    case "the work of a test grows linearly with the length of the subject"
      (fun () ->
        let p = compiled "^x" in
        Counted_work.check_growth ~margin:2.0 ~sizes:(2_000, 16_000)
          ~input:(fun n ->
            text (String.concat "" (List.init n (fun _ -> "\xf0\x9f\x98\x80"))))
          (fun subject -> Pattern.test p subject));
    case
      "the work of a compilation grows linearly with the length of the source"
      (fun () ->
        Counted_work.check_growth ~margin:2.0 ~sizes:(1_000, 8_000)
          ~input:(fun n ->
            text (String.concat "" (List.init n (fun _ -> "(?:a)"))))
          (fun source -> Pattern.compile source));
  ]

let least_steps p subject =
  let ends steps =
    match Pattern.test ~steps p (text subject) with
    | Ok _ -> true
    | Error Steps -> false
    | Error Memory -> Alcotest.fail "memory"
  in
  let rec high steps = if ends steps then steps else high (2 * steps) in
  let rec least low high =
    if low >= high then high
    else
      let middle = (low + high) / 2 in
      if ends middle then least low middle else least (middle + 1) high
  in
  let top = high 1 in
  least (top / 2) top

let exact_charge_tests =
  [
    case "the size of a compiled pattern is more than 0" (fun () ->
        List.iter
          (fun source ->
            Alcotest.(check bool)
              source true
              (Pattern.size (compiled source) > 0))
          [ ""; "a"; "^(a+)+$"; "()\\1" ]);
    case "the least steps that let a test end are a multiple of size + b * n"
      (fun () ->
        let catastrophic = String.make 20 'a' ^ "!" in
        List.iter
          (fun (source, b, subject) ->
            let p = compiled source in
            let n = String.length subject in
            let work = Pattern.size p + (b * n) in
            let steps = least_steps p subject in
            Alcotest.(check bool)
              (source ^ ": more than one poll")
              true (steps > 0);
            Alcotest.(check int) (source ^ ": a multiple") 0 (steps mod work))
          [
            ("^(a+)+$", 0, catastrophic ^ "zzzz");
            ("^()\\1(a+)+$", 1, catastrophic);
            ("^()\\1()\\2(a+)+$", 2, catastrophic ^ "zz");
            ("^(?<x>)\\k<x>(a+)+$", 1, catastrophic ^ "z");
          ]);
    case "a subject of more than 2^31 - 1 code units is too long" (fun () ->
        Alcotest.(check (list bool))
          "2^31 - 1, 2^31" [ false; true ]
          (List.map Pattern.too_long [ 2_147_483_647; 2_147_483_648 ]));
  ]

let charge_tests =
  let ab = String.concat "" (List.init 25_000 (fun _ -> "ab")) in
  let outcome source =
    match Pattern.test (compiled source) (text ab) with
    | Ok b -> string_of_bool b
    | Error s -> stop_text s
  in
  [
    case "a back reference makes each poll cost the length of the subject"
      (fun () ->
        Alcotest.(check string)
          "no back reference" "false" (outcome "^()(?:a|b)*c");
        Alcotest.(check string)
          "a back reference" "steps"
          (outcome "^()\\1(?:a|b)*c"));
    case
      "a longer subject stops at the least steps with which a shorter one ends"
      (fun () ->
        let p = compiled "^()\\1(a+)+$" in
        let short = String.make 20 'a' ^ "!" in
        let ends steps subject =
          match Pattern.test ~steps p (text subject) with
          | Ok _ -> true
          | Error Steps -> false
          | Error Memory -> Alcotest.fail "memory"
        in
        let steps = least_steps p short in
        Alcotest.(check bool) "the shorter subject" true (ends steps short);
        Alcotest.(check bool)
          "the longer subject" false
          (ends steps (short ^ "zzzz")));
    case "a long compiled pattern makes each poll cost its size" (fun () ->
        Alcotest.(check string)
          "a short pattern" "false" (outcome "^(?:a|b)*c|d");
        Alcotest.(check string)
          "a long pattern" "steps"
          (outcome ("^(?:a|b)*c|" ^ String.make 20_000 'd')));
  ]

let time_tests =
  [
    case
      "the time of a test with a back reference grows linearly with the \
       subject, at the default steps" (fun () ->
        let p = compiled "(a+)b(?:(?=\\1)a)*x" in
        Timed_work.check_growth ~margin:3. ~runs:3 ~sizes:(5_000, 40_000)
          ~input:(fun k ->
            text (String.make k 'a' ^ "b" ^ String.make (2 * k) 'a'))
          (fun subject -> Pattern.test p subject));
    case
      "the time of a test with a long literal pattern grows linearly with its \
       length, at the default steps" (fun () ->
        Timed_work.check_growth ~margin:3. ~runs:3 ~sizes:(2_000, 16_000)
          ~input:(fun k ->
            (compiled (String.make k 'a' ^ "b"), text (String.make (4 * k) 'a')))
          (fun (p, subject) -> Pattern.test p subject));
  ]

let tests =
  ecma_tests @ depth_tests @ limit_tests @ property_tests @ growth_tests
  @ charge_tests @ exact_charge_tests @ time_tests
