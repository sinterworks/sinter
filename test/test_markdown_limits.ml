(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_identifiers
open Sinter_file_readers
open Sinter_readings
open Sinter_markdown_limits
open Sinter_markdown_tag_texts
open Sinter_code_tag_texts
open Sinter_tree_inputs
open Sinter_tree_items
module Gen = QCheck2.Gen

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let text_of string =
  match Text.decode string with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let path_of string =
  match Path.of_text (text_of string) with
  | Ok path -> path
  | Error _ -> invalid_arg "path_of"

let lines_of string = Lines.of_text (text_of string)
let rep s n = String.concat "" (List.init (max n 0) (fun _ -> s))
let nest ~o ~c n = rep o n ^ "a" ^ rep c n

let no_limits =
  { Markdown_limits.size = max_int; brackets = max_int; containers = max_int }

let limit_name = function
  | Markdown_limits.Size -> "Size"
  | Markdown_limits.Brackets -> "Brackets"
  | Markdown_limits.Containers -> "Containers"

let limit_testable =
  Alcotest.testable
    (fun fmt l -> Format.pp_print_string fmt (limit_name l))
    ( = )

let with_small_stack run =
  let before = Gc.get () in
  Gc.set { before with stack_limit = 1 lsl 16 };
  Fun.protect ~finally:(fun () -> Gc.set before) run

type bracket_state = Open | In_code of int | In_html of int | Blocked

let backtick_runs s =
  let n = String.length s in
  let rec go acc i =
    if i >= n then List.rev acc
    else if s.[i] = '`' then
      let rec end_run j = if j < n && s.[j] = '`' then end_run (j + 1) else j in
      let j = end_run (i + 1) in
      go ((i, j - i) :: acc) j
    else go acc (i + 1)
  in
  go [] 0

let first_gt_after s i =
  let n = String.length s in
  let rec go j =
    if j >= n then None else if s.[j] = '>' then Some j else go (j + 1)
  in
  go (i + 1)

let has_blocking_char s from until =
  let rec go k =
    if k >= until then false
    else
      match s.[k] with
      | '\n' | '\r' | '"' | '\'' | '`' | '<' -> true
      | _ -> go (k + 1)
  in
  go from

let normalize_bracket i = function In_html g when g < i -> Open | st -> st

let ref_bracket_depth ~limit s =
  if limit < 0 then None
  else
    let n = String.length s in
    let runs = backtick_runs s in
    let has_later_run after len =
      List.exists (fun (pos, rlen) -> pos > after && rlen = len) runs
    in
    let rec loop i stack best bs blank =
      if i >= n then Some best
      else
        let c = s.[i] in
        match c with
        | '\n' | '\r' ->
            let ends = c = '\n' || i + 1 >= n || s.[i + 1] <> '\n' in
            let stack, blank =
              if ends then ((if blank then [] else stack), true)
              else (stack, blank)
            in
            loop (i + 1) stack best 0 blank
        | ' ' | '\t' -> loop (i + 1) stack best 0 blank
        | '[' ->
            if bs mod 2 = 0 then
              let stack = Open :: stack in
              let depth = List.length stack in
              if depth > limit then None
              else loop (i + 1) stack (max best depth) 0 false
            else loop (i + 1) stack best 0 false
        | ']' ->
            let stack =
              if bs mod 2 = 0 then
                match stack with
                | top :: rest when normalize_bracket i top = Open -> rest
                | _ -> stack
              else stack
            in
            loop (i + 1) stack best 0 false
        | '`' ->
            let rec end_run j =
              if j < n && s.[j] = '`' then end_run (j + 1) else j
            in
            let j = end_run (i + 1) in
            let raw_len = j - i in
            let open_len = if bs mod 2 = 1 then raw_len - 1 else raw_len in
            let opens = open_len > 0 && has_later_run i open_len in
            let stack =
              List.map
                (fun entry ->
                  match normalize_bracket i entry with
                  | In_code target ->
                      if raw_len = target then Open else In_code target
                  | Open -> if opens then In_code open_len else Open
                  | (In_html _ | Blocked) as st -> st)
                stack
            in
            loop j stack best 0 false
        | '<' ->
            let stack =
              if bs mod 2 = 0 then
                let next_for_open =
                  match first_gt_after s i with
                  | None -> Open
                  | Some g ->
                      if i + 1 < n && (s.[i + 1] = '!' || s.[i + 1] = '?') then
                        Blocked
                      else if has_blocking_char s (i + 1) g then Blocked
                      else In_html g
                in
                List.map
                  (fun entry ->
                    match normalize_bracket i entry with
                    | Open -> next_for_open
                    | st -> st)
                  stack
              else stack
            in
            loop (i + 1) stack best 0 false
        | '\\' -> loop (i + 1) stack best (bs + 1) false
        | _ -> loop (i + 1) stack best 0 false
    in
    loop 0 [] 0 0 true

let is_ascii_digit c = c >= '0' && c <= '9'

let ref_container_line_depth s from until =
  let rec go k col markers ws_cols q_ws seen_list =
    if k >= until then (markers, q_ws)
    else
      match s.[k] with
      | ' ' -> go (k + 1) (col + 1) markers (ws_cols + 1) q_ws seen_list
      | '\t' ->
          let next = (col + 4) land lnot 3 in
          go (k + 1) next markers (ws_cols + (next - col)) q_ws seen_list
      | '>' ->
          let q_ws = if seen_list then q_ws else Some ws_cols in
          go (k + 1) (col + 1) (markers + 1) ws_cols q_ws seen_list
      | '-' | '+' | '*' ->
          if k + 1 >= until || s.[k + 1] = ' ' || s.[k + 1] = '\t' then
            let q_ws = if seen_list then q_ws else Some ws_cols in
            go (k + 1) (col + 1) (markers + 1) ws_cols q_ws true
          else (markers, q_ws)
      | c when is_ascii_digit c ->
          let rec scan_digits d =
            if d < until && is_ascii_digit s.[d] then scan_digits (d + 1) else d
          in
          let d = scan_digits (k + 1) in
          let digits = d - k in
          if
            digits <= 9 && d < until
            && (s.[d] = '.' || s.[d] = ')')
            && (d + 1 >= until || s.[d + 1] = ' ' || s.[d + 1] = '\t')
          then
            let q_ws = if seen_list then q_ws else Some ws_cols in
            go (d + 1) (col + digits + 1) (markers + 1) ws_cols q_ws true
          else (markers, q_ws)
      | _ -> (markers, q_ws)
  in
  let markers, q_ws = go from 0 0 0 None false in
  if markers = 0 then 0
  else
    match q_ws with
    | Some w -> markers + (w / 2)
    | None -> invalid_arg "ref_container_line_depth"

let ref_container_depth ~limit s =
  if limit < 0 then None
  else
    let n = String.length s in
    let rec loop i best =
      if i >= n then Some best
      else
        let rec find_end j =
          if j >= n || s.[j] = '\n' || s.[j] = '\r' then j else find_end (j + 1)
        in
        let j = find_end i in
        let depth = ref_container_line_depth s i j in
        if depth > limit then None
        else
          let next =
            if j >= n then n
            else if s.[j] = '\r' && j + 1 < n && s.[j + 1] = '\n' then j + 2
            else j + 1
          in
          loop next (max best depth)
    in
    loop 0 0

let bracket_piece_gen =
  Gen.oneof_list
    [
      "[";
      "]";
      "![";
      "\\";
      "\\\\";
      "\\[";
      "\\]";
      "\\<";
      "`";
      "``";
      "```";
      "\\`";
      "\\``";
      "<";
      ">";
      "<!";
      "<?";
      "\"";
      "'";
      "a";
      " ";
      "\t";
      "\n";
      "\r\n";
      "\r";
      "\n\n";
      "\r\n\r\n";
      "\r\r";
      "\n \t \n";
      "[`]";
      "<http://x]>";
      "<a title=\"]\">";
    ]

let bracket_text_gen =
  Gen.map (String.concat "")
    (Gen.list_size (Gen.int_range 0 28) bracket_piece_gen)

let limit_gen = Gen.oneof_list [ -2; -1; 0; 1; 2; 3; 4; 5; 8; max_int ]

(* @cites commonmark-reader *)
let bracket_depth_follows_rule_s3 =
  property ~count:1500
    ~name:"bracket_depth gives the depth of rule S3 up to the limit"
    ~print:(fun (limit, s) -> Printf.sprintf "limit=%d %S" limit s)
    (Gen.pair limit_gen bracket_text_gen)
    (fun (limit, s) ->
      Markdown_limits.bracket_depth ~limit s = ref_bracket_depth ~limit s)

let bracket_depth_threshold_property =
  property ~count:600
    ~name:"bracket_depth accepts at the exact depth and stops one below it"
    ~print:(Printf.sprintf "%S") bracket_text_gen (fun s ->
      match Markdown_limits.bracket_depth ~limit:max_int s with
      | None -> false
      | Some d ->
          d >= 0
          && Markdown_limits.bracket_depth ~limit:d s = Some d
          && Markdown_limits.bracket_depth ~limit:(d - 1) s = None
          && Markdown_limits.bracket_depth ~limit:(d + 1) s = Some d)

let container_piece_gen =
  Gen.oneof_list
    [
      " ";
      "  ";
      "   ";
      "\t";
      ">";
      "> ";
      ">\t";
      "-";
      "- ";
      "-\t";
      "+ ";
      "* ";
      "1. ";
      "9) ";
      "123456789. ";
      "1234567890. ";
      "12";
      ". ";
      ") ";
      "-a";
      "1.a";
      "a";
      "\n";
      "\r\n";
      "\r";
    ]

let container_text_gen =
  Gen.map (String.concat "")
    (Gen.list_size (Gen.int_range 0 24) container_piece_gen)

(* @cites commonmark-reader *)
let container_depth_follows_rule_c =
  property ~count:1500
    ~name:"container_depth gives the depth of rule C up to the limit"
    ~print:(fun (limit, s) -> Printf.sprintf "limit=%d %S" limit s)
    (Gen.pair limit_gen container_text_gen)
    (fun (limit, s) ->
      Markdown_limits.container_depth ~limit s = ref_container_depth ~limit s)

let container_depth_threshold_property =
  property ~count:600
    ~name:"container_depth accepts at the exact depth and stops one below it"
    ~print:(Printf.sprintf "%S") container_text_gen (fun s ->
      match Markdown_limits.container_depth ~limit:max_int s with
      | None -> false
      | Some d ->
          d >= 0
          && Markdown_limits.container_depth ~limit:d s = Some d
          && Markdown_limits.container_depth ~limit:(d - 1) s = None
          && Markdown_limits.container_depth ~limit:(d + 1) s = Some d)

let utf8_body_gen =
  Gen.oneof
    [
      bracket_text_gen;
      container_text_gen;
      Gen.map (String.concat "")
        (Gen.list_size (Gen.int_range 0 12)
           (Gen.oneof_list
              [
                "[";
                "]";
                "- ";
                "> ";
                "\t";
                "\xc3\xa9";
                "\xf0\x9f\x98\x80";
                "\n";
                "a";
              ]));
    ]

let check_case_gen =
  let open Gen in
  let* bom = oneof_weighted [ (1, return true); (3, return false) ] in
  let* body = utf8_body_gen in
  let full = if bom then "\xef\xbb\xbf" ^ body else body in
  let size_choices =
    let len = String.length full in
    oneof_list [ -1; 0; max 0 (len - 1); len; len + 1; max_int ]
  in
  let* size = size_choices in
  let* brackets = oneof_list [ -1; 0; 1; 2; 3; 5; max_int ] in
  let* containers = oneof_list [ -1; 0; 1; 2; 3; 5; max_int ] in
  return (bom, body, full, { Markdown_limits.size; brackets; containers })

(* @cites commonmark-reader *)
let check_follows_its_promise =
  property ~count:1200
    ~name:"check enforces size, bracket depth, and container depth in order"
    ~print:(fun (bom, body, _, (l : Markdown_limits.t)) ->
      Printf.sprintf "bom=%b size=%d brackets=%d containers=%d body=%S" bom
        l.size l.brackets l.containers body)
    check_case_gen
    (fun (_bom, body, full, limits) ->
      let lines = lines_of full in
      let expected =
        if String.length full > limits.size then Error Markdown_limits.Size
        else if ref_bracket_depth ~limit:limits.brackets body = None then
          Error Markdown_limits.Brackets
        else if ref_container_depth ~limit:limits.containers body = None then
          Error Markdown_limits.Containers
        else Ok ()
      in
      match (Markdown_limits.check limits lines, expected) with
      | Ok text, Ok () -> Markdown_limits.lines text == lines
      | Error a, Error b -> a = b
      | _ -> false)

let check_bracket_case name text expected () =
  Alcotest.(check (option int))
    (name ^ " with high limit")
    (Some expected)
    (Markdown_limits.bracket_depth ~limit:max_int text);
  Alcotest.(check (option int))
    (name ^ " at its exact depth")
    (Some expected)
    (Markdown_limits.bracket_depth ~limit:expected text);
  Alcotest.(check (option int))
    (name ^ " one below its depth")
    None
    (Markdown_limits.bracket_depth ~limit:(expected - 1) text)

let bracket_rule_s3_step_cases =
  [
    ("the empty text has bracket depth 0", "", 0);
    ("an escaped opening bracket does not count", "\\[a]", 0);
    ("two backslashes let an opening bracket count", "\\\\[a]", 1);
    ("three backslashes hide an opening bracket", "\\\\\\[a]", 0);
    ("an escaped closing bracket does not pop the stack", "[a\\][", 2);
    ("two backslashes let a closing bracket pop the stack", "[a\\\\][", 1);
    ("an escaped less-than sign does not block the entry", "[a\\<!][", 1);
    ("two backslashes let a less-than sign block the entry", "[a\\\\<!>][", 2);
    ("a blank line of line feeds empties the stack", "[\n\n[", 1);
    ("a blank line of carriage returns empties the stack", "[\r\r[", 1);
    ("a blank line of CRLF pairs empties the stack", "[\r\n\r\n[", 1);
    ("a single CRLF does not empty the stack", "[\r\n[", 2);
    ("a single line feed does not empty the stack", "[\n[", 2);
    ("a single carriage return does not empty the stack", "[\r[", 2);
    ("a line of only a closing bracket is not blank", "[[\n]\n[[", 3);
    ("a line of only a greater-than sign is not blank", "[\n>\n[", 2);
    ("a line of only a less-than sign is not blank", "[\n<\n[", 2);
    ("a line of only a backtick is not blank", "[\n`\n[", 2);
    ("a line of only a quotation mark is not blank", "[\n\"\n[", 2);
    ("a line of only an apostrophe is not blank", "[\n'\n[", 2);
    ("spaces and tabs alone make a blank line", "[\n  \t \n[", 1);
    ("a form feed is not white space of a blank line", "[\n\x0c\n[", 2);
    ("an opening bracket inside a code span counts", "[`[`]", 2);
    ("an opening bracket inside HTML counts", "[<a b=\"c\">[a]", 2);
    ("an escaped single backtick does not open a code span", "[\\`][", 1);
    ("a backtick with no later match does not hide a closer", "[`][", 1);
    ("a later run of another length does not match", "[`]``[", 1);
    ("a matching code span hides a closing bracket inside it", "[`]`][", 1);
    ("a code span hides an unclosed closer until its closing run", "[`][`", 2);
    ("an escaped two-backtick run opens a span of length one", "[\\``]`][", 1);
    ( "an escaped two-backtick run hides a closer until a one-backtick run",
      "[\\``]`[",
      2 );
    ( "a closing backtick run matches on its full length after a backslash",
      "[`]\\`][",
      1 );
    ( "a run that closes a code span does not open a new span for that entry",
      "[`]`][`",
      1 );
    ("a less-than sign with no later greater-than does nothing", "[<!][", 1);
    ("a less-than sign with no later greater-than and question mark", "[<?][", 1);
    ("a comment start with a later greater-than blocks", "[<!>][", 2);
    ("a processing instruction with a later greater-than blocks", "[<?>][", 2);
    ("a line feed before greater-than blocks", "[<a\n>][", 2);
    ("a carriage return before greater-than blocks", "[<a\r>][", 2);
    ("a double quote before greater-than blocks", "[<a\">][", 2);
    ("a single quote before greater-than blocks", "[<a'>][", 2);
    ("a backtick before greater-than blocks", "[<a`>][", 2);
    ("another less-than before greater-than blocks", "[<a<>][", 2);
    ( "clean HTML hides a closing bracket and reopens after it",
      "[<http://x]>][",
      1 );
    ( "clean HTML hides a closing bracket without a second closer",
      "[<http://x]>[",
      2 );
    ( "a less-than sign inside a code span does not block the entry",
      "[`<!`][>",
      1 );
    ("a backtick run does not unblock a blocked entry", "[<!>`a`][", 2);
    ( "outer and inner stack entries keep independent code span lengths",
      "[``[`]`]``][[x]]",
      2 );
    ("a closing bracket on an empty stack does nothing", "]]][", 1);
    ("a blank line clears a blocked entry", "[<!>\n\n[", 1);
    ("a non-blank line keeps a blocked entry blocked", "[<!>\n][", 2);
    ( "a trailing backslash at end of line does not escape the next line",
      "\\\n[",
      1 );
    ("a lone trailing backslash has depth 0", "\\", 0);
    ("a less-than sign at end of text has no later greater-than", "[<", 1);
    ("an empty angle pair reopens immediately after greater-than", "[<>]][", 1);
    ("two consecutive HTML tags both hide closing brackets", "[<a><b]>[", 2);
    ( "a later backtick across a blank line still opens a code span",
      "[`][\n\n`",
      2 );
    ("a later greater-than across a blank line still blocks <!", "[<!][\n\n>", 2);
    ("no greater-than anywhere keeps <! open", "[<!][\n\n", 1);
    ( "an escaped four-backtick run opens a span of length three",
      "[\\````]```][",
      1 );
    ( "one backtick run closes an outer entry while opening an inner entry",
      "[`a[`][`",
      3 );
    ( "an inner bracket inside clean HTML opens and closes independently",
      "[<a[b]>][[c]]",
      2 );
    ( "stack growth past 64 preserves state and pops cleanly",
      rep "[" 70 ^ rep "]" 70 ^ rep "[" 70,
      70 );
  ]

let hostile_bracket_shapes_n5 =
  let n = 5 in
  [
    ("brk", nest ~o:"[" ~c:"]" n, 5);
    ("img", nest ~o:"![" ~c:"]" n, 5);
    ("inl", nest ~o:"[" ~c:"](u)" n, 5);
    ( "mix",
      String.concat ""
        (List.init n (fun i -> if i mod 2 = 0 then "[" else "!["))
      ^ "a" ^ rep "]" n,
      5 );
    ("ref", nest ~o:"[" ~c:"][x]" n ^ "\n\n[x]: /u\n", 5);
    ("brk-def", nest ~o:"[" ~c:"]" n ^ "\n\n[a]: /u\n", 5);
    ("brk-lines", nest ~o:"[\n" ~c:"\n]" n, 5);
    ("brk-heading", "# " ^ nest ~o:"[" ~c:"]" n, 5);
    ("lazy-quote", "> " ^ rep "[" n ^ "\na" ^ rep "]" n ^ "\n", 5);
    ("hide-code", nest ~o:"[`]`" ~c:"]" n, 5);
    ("hide-code2", nest ~o:"[`` ] ``" ~c:"]" n, 5);
    ("hide-auto", nest ~o:"[<http://x]>" ~c:"]" n, 5);
    ("hide-html", nest ~o:"[<a title=\"]\">" ~c:"]" n, 5);
    ("hide-esc", nest ~o:"[\\]" ~c:"]" n, 5);
    ("esc-open", nest ~o:"\\[" ~c:"]" n, 0);
    ("esc-close", nest ~o:"[" ~c:"\\]" n, 5);
    ("in-code", "`" ^ nest ~o:"[" ~c:"]" n ^ "`", 5);
    ("in-fence", "```\n" ^ nest ~o:"[" ~c:"]" n ^ "\n```\n", 5);
    ("in-indent", "    " ^ nest ~o:"[" ~c:"]" n ^ "\n", 5);
    ("in-html-block", "<div>\n" ^ nest ~o:"[" ~c:"]" n ^ "\n</div>\n", 5);
    ("in-raw-html", "x <a title=\"" ^ nest ~o:"[" ~c:"]" n ^ "\"> y", 5);
    ("in-autolink", "x <http://x" ^ nest ~o:"[" ~c:"]" n ^ "> y", 5);
    ("in-dest", "[x](u" ^ nest ~o:"[" ~c:"]" n ^ ")", 5);
    ("blank-split", rep "[" n ^ "\n\na" ^ rep "]" n, 5);
    ("quote-split", "> " ^ rep "[" n ^ "\n>\n> a" ^ rep "]" n ^ "\n", 5);
    ("list-split", rep "- [\n" n ^ "- a" ^ rep "]" n ^ "\n", 5);
    ("open", rep "[" n ^ "a", 5);
    ("open1", rep "[" n ^ "a]", 5);
    ("openers", rep "[a" n, 5);
    ("closers", rep "a]" n, 0);
    ("paren", rep "[ (](" n, 1);
    ("unclosedA", rep "[a](<b" n, 1);
    ("unclosedB", rep "[a](b" n, 1);
    ("title-open", rep "[a](b \"c" n, 1);
    ("dest-parens", "[a](" ^ rep "(" n ^ "b" ^ rep ")" n ^ ")", 1);
    ("label-long", "[a][" ^ rep "b" n ^ "]", 1);
    ("link-emph", rep "[ a_" n, 5);
    ("rep:4", rep (nest ~o:"[" ~c:"]" 4 ^ " ") 3, 4);
    ("deep:4", rep "[" 4 ^ rep "*a" 3 ^ rep "]" 4, 4);
    ("deepnl:4", rep "[" 4 ^ rep "a\n" 3 ^ rep "]" 4, 4);
    ("deeptick:4", rep "[" 4 ^ rep "`a` " 3 ^ rep "]" 4, 4);
    ("deepbrk:4", rep "[" 4 ^ rep "[a] " 3 ^ rep "]" 4, 5);
    ("deepalt:4", rep "[" 4 ^ rep "*_" 3 ^ "a" ^ rep "_*" 3 ^ rep "]" 4, 4);
    ("hidecode:4", rep "[`]`" 4 ^ nest ~o:"[" ~c:"]" 3 ^ rep "]" 4, 7);
  ]

let check_container_case name text expected () =
  Alcotest.(check (option int))
    (name ^ " with high limit")
    (Some expected)
    (Markdown_limits.container_depth ~limit:max_int text);
  Alcotest.(check (option int))
    (name ^ " at its exact depth")
    (Some expected)
    (Markdown_limits.container_depth ~limit:expected text);
  Alcotest.(check (option int))
    (name ^ " one below its depth")
    None
    (Markdown_limits.container_depth ~limit:(expected - 1) text)

let container_rule_c_cases =
  [
    ("the empty text has container depth 0", "", 0);
    ("plain lines have container depth 0", "Hello\n    indented\n\t\tcode\n", 0);
    ("a bare quote marker counts as 1", ">", 1);
    ("a quote marker without trailing space counts as 1", ">a", 1);
    ("three packed quote markers count as 3", ">>>a", 3);
    ("a quote marker with trailing spaces has W = 0", ">     a", 1);
    ("a bullet dash at end of line counts as 1", "-", 1);
    ("a bullet plus at end of line counts as 1", "+", 1);
    ("a bullet star at end of line counts as 1", "*", 1);
    ("a bullet plus with a tab counts as 1", "+\ta", 1);
    ("a bullet star with a space counts as 1", "* a", 1);
    ("a bullet dash before CRLF counts as 1", "-\r\na", 1);
    ("a bullet dash before CR counts as 1", "-\ra", 1);
    ("a dash before text is no bullet marker", "-a - b", 0);
    ("a plus before text is no bullet marker", "+a", 0);
    ("a star before text is no bullet marker", "*a", 0);
    ("an ordered marker starting with zero counts as 1", "0. a", 1);
    ("an ordered marker with one digit and dot counts as 1", "1.", 1);
    ("an ordered marker with one digit and paren counts as 1", "9) a", 1);
    ("an ordered marker followed by a tab counts as 1", "1.\ta", 1);
    ( "characters adjacent to ASCII digits are no ordered markers",
      "/. a\n:. a\n",
      0 );
    ("an ordered marker with nine digits counts as 1", "123456789. a", 1);
    ("ten digits make no ordered marker", "1234567890. a", 0);
    ("an ordered marker without space or end of line does not count", "1.a", 0);
    ( "a failed ordered marker ends the leading part before the digit",
      "> 1234567890. - a",
      1 );
    ("odd white space before a marker rounds down", "   - a", 2);
    ("one space before a marker adds nothing", " - a", 1);
    ("a tab at column 0 gives 4 columns of white space", "\t- a", 3);
    ("a space and a tab give 4 columns of white space", " \t- a", 3);
    ("two spaces and a tab give 4 columns of white space", "  \t- a", 3);
    ("three spaces and a tab give 4 columns of white space", "   \t- a", 3);
    ("a tab after a quote marker at column 0 gives 3 columns", ">\t- a", 3);
    ("a tab after quote and one space advances to column 4", "> \t- a", 3);
    ("a tab after quote and two spaces advances to column 4", ">  \t- a", 3);
    ("a tab after quote and three spaces advances to column 8", ">   \t- a", 5);
    ( "four quote markers and a tab before a dash give depth 7",
      ">>>>- - a\n>>>>\t- b\n",
      7 );
    ( "four quote markers and a tab before a quote marker give depth 7",
      ">>>>- - a\n>>>>\t> b\n",
      7 );
    ( "two quote markers, two spaces, and a tab before a dash give depth 6",
      ">>  \t- c\n",
      6 );
    ( "white space after the first list marker does not enter W",
      "  >   -   >   - a",
      6 );
    ( "white space after the last quote marker does not enter W",
      "  >   >   a",
      4 );
    ("a tab after a bullet marker does not enter W", "- \t- a", 2);
    ("line endings CRLF and CR separate lines", "- a\r\n- b\r- c\n", 1);
    ("the maximum over all lines is the container depth", "a\n- - - b\n- c\n", 3);
    ("hostile list-nest of 6 items", rep "- " 6 ^ "a\n", 6);
    ("hostile star-list-nest of 6 items", rep "* " 6 ^ "a\n", 6);
    ("hostile plus-list-nest of 6 items", rep "+ " 6 ^ "a\n", 6);
    ("hostile olist-nest of 6 items", rep "1. " 6 ^ "a\n", 6);
    ("hostile quote-nest of 5 quotes", rep "> " 5 ^ "a\n", 7);
    ( "hostile list-indent of 6 lines",
      String.concat ""
        (List.init 6 (fun i -> String.make (2 * i) ' ' ^ "* a\n")),
      6 );
    ( "hostile listlazy of 6 items and lazy lines",
      rep "- " 6 ^ "a\n" ^ rep "a\n" 10,
      6 );
    ( "hostile quotelazy of 5 quotes and lazy lines",
      rep "> " 5 ^ "a\n" ^ rep "a\n" 10,
      7 );
  ]

let check_limit_boundaries () =
  let check_result what expected actual =
    match (expected, actual) with
    | Ok (), Ok _ -> ()
    | Error a, Error b -> Alcotest.(check limit_testable) what a b
    | Ok (), Error b ->
        Alcotest.failf "%s: expected Ok, got Error %s" what (limit_name b)
    | Error a, Ok _ ->
        Alcotest.failf "%s: expected Error %s, got Ok" what (limit_name a)
  in
  let plain = lines_of "abcde" in
  check_result "exact byte size passes" (Ok ())
    (Markdown_limits.check { no_limits with size = 5 } plain);
  check_result "one byte over size stops with Size" (Error Markdown_limits.Size)
    (Markdown_limits.check { no_limits with size = 4 } plain);
  let utf8 = lines_of "\xc3\xa9" in
  check_result "UTF-8 byte size counts bytes, not characters (exact)" (Ok ())
    (Markdown_limits.check { no_limits with size = 2 } utf8);
  check_result "UTF-8 byte size stops at 1 byte for a 2-byte character"
    (Error Markdown_limits.Size)
    (Markdown_limits.check { no_limits with size = 1 } utf8);
  let with_bom_size = lines_of "\xef\xbb\xbf[a]" in
  check_result "size includes the 3-byte BOM (exact 6)" (Ok ())
    (Markdown_limits.check { no_limits with size = 6 } with_bom_size);
  check_result "size includes the 3-byte BOM (5 stops)"
    (Error Markdown_limits.Size)
    (Markdown_limits.check { no_limits with size = 5 } with_bom_size);
  let with_bom_list = lines_of "\xef\xbb\xbf- a\n" in
  check_result "container depth reads the body without the BOM"
    (Error Markdown_limits.Containers)
    (Markdown_limits.check { no_limits with containers = 0 } with_bom_list);
  check_result "container depth accepts the body at limit 1" (Ok ())
    (Markdown_limits.check { no_limits with containers = 1 } with_bom_list);
  let with_bom_brackets = lines_of "\xef\xbb\xbf[[a]]" in
  check_result "bracket depth reads the body without the BOM (exact 2)" (Ok ())
    (Markdown_limits.check { no_limits with brackets = 2 } with_bom_brackets);
  check_result "bracket depth stops one below (1)"
    (Error Markdown_limits.Brackets)
    (Markdown_limits.check { no_limits with brackets = 1 } with_bom_brackets);
  let all_over = lines_of "- - [[[a]]]\n" in
  check_result "Size wins over Brackets and Containers"
    (Error Markdown_limits.Size)
    (Markdown_limits.check { size = 1; brackets = 1; containers = 1 } all_over);
  check_result "Brackets wins over Containers when Size passes"
    (Error Markdown_limits.Brackets)
    (Markdown_limits.check
       { size = 100; brackets = 1; containers = 1 }
       all_over);
  check_result "Containers stops when Size and Brackets pass"
    (Error Markdown_limits.Containers)
    (Markdown_limits.check
       { size = 100; brackets = 5; containers = 1 }
       all_over);
  let empty = lines_of "" in
  check_result "negative size stops empty text with Size"
    (Error Markdown_limits.Size)
    (Markdown_limits.check { size = -1; brackets = 0; containers = 0 } empty);
  check_result "negative brackets stops empty text with Brackets"
    (Error Markdown_limits.Brackets)
    (Markdown_limits.check { size = 0; brackets = -1; containers = 0 } empty);
  check_result "negative containers stops empty text with Containers"
    (Error Markdown_limits.Containers)
    (Markdown_limits.check { size = 0; brackets = 0; containers = -1 } empty);
  match Markdown_limits.check no_limits plain with
  | Ok text ->
      Alcotest.(check bool)
        "lines returns the accepted Lines.t" true
        (Markdown_limits.lines text == plain)
  | Error _ -> Alcotest.fail "no_limits accepts plain text"

let read_file_of ~markdown path content =
  let reader =
    if markdown then File_readers.Markdown else File_readers.Pack ()
  in
  let readers =
    match File_readers.make [ (reader, [ text_of "**" ]) ] with
    | Ok r -> r
    | Error _ -> Alcotest.fail "valid readers"
  in
  let tree =
    match Tree.of_files [ (path_of path, content) ] with
    | Ok t -> t
    | Error _ -> Alcotest.fail "valid tree"
  in
  match Read_file.read_files readers tree with
  | [ file ] -> file
  | _ -> Alcotest.fail "one read file"

let check_stopped what expected_limit result =
  match result with
  | Error (Readable_file.Stopped { limit = actual; _ }) ->
      Alcotest.(check limit_testable) what expected_limit actual
  | Ok _ -> Alcotest.failf "%s: expected Stopped, got Ok" what
  | Error (Readable_file.Cannot_be_read (Readable_file.Not_utf_8 _)) ->
      Alcotest.failf "%s: expected Stopped, got Not_utf_8" what
  | Error (Readable_file.Cannot_be_read Readable_file.No_grammar) ->
      Alcotest.failf "%s: expected Stopped, got No_grammar" what
  | Error (Readable_file.Cannot_be_read Readable_file.Parse_failure) ->
      Alcotest.failf "%s: expected Stopped, got Parse_failure" what
  | Error (Readable_file.Invalid_reading _) ->
      Alcotest.failf "%s: expected Stopped, got Invalid_reading" what

(* @verifies documents#give-declared-items=v1
   Each markdown file whose size, bracket depth, or container depth exceeds its
   limit goes into the set of stopped files and gives Cannot_be_read (Stopped)
   with that limit, so it gives no declared items; a file at the limit can be
   read; invalid UTF-8 is reported before limits; code files are unaffected by
   markdown limits. *)
let readable_file_limits_cases () =
  let pack_called = ref 0 in
  let fail_pack () _path _text =
    incr pack_called;
    Alcotest.fail "pack must not be called for a markdown file"
  in
  let limits = { Markdown_limits.size = 20; brackets = 2; containers = 2 } in
  (match
     Readable_file.read limits fail_pack
       (read_file_of ~markdown:true "docs/ok.md" "- - [[a]]\n")
   with
  | Ok (Readable_file.Markdown_file text) ->
      let md = Markdown_file.read text in
      Alcotest.(check int)
        "the readable markdown file has 2 list items" 2
        (List.length (Markdown_file.list_items md))
  | _ -> Alcotest.fail "file at all three limits must be read");
  check_stopped "over size" Markdown_limits.Size
    (Readable_file.read limits fail_pack
       (read_file_of ~markdown:true "docs/big.md" (String.make 21 'a')));
  check_stopped "over brackets" Markdown_limits.Brackets
    (Readable_file.read limits fail_pack
       (read_file_of ~markdown:true "docs/brk.md" "[[[a]]]"));
  check_stopped "over containers" Markdown_limits.Containers
    (Readable_file.read limits fail_pack
       (read_file_of ~markdown:true "docs/ctr.md" "- - - a\n"));
  (match
     Readable_file.read
       { size = 1; brackets = 0; containers = 0 }
       fail_pack
       (read_file_of ~markdown:true "docs/bad.md" "\xff\xff\xff")
   with
  | Error (Readable_file.Cannot_be_read (Readable_file.Not_utf_8 _)) -> ()
  | _ -> Alcotest.fail "invalid UTF-8 must be checked before limits");
  Alcotest.(check int) "pack was never called for markdown" 0 !pack_called;
  let hostile_brackets = rep "[" 50 ^ "a" ^ rep "]" 50 in
  check_stopped "50 nested brackets stop before cmarkit runs"
    Markdown_limits.Brackets
    (Readable_file.read
       { size = 1024; brackets = 5; containers = 16 }
       fail_pack
       (read_file_of ~markdown:true "docs/hostile-brk.md" hostile_brackets));
  let hostile_lists = rep "- " 20_000 ^ "a\n" in
  check_stopped "20,000 nested list items stop before cmarkit runs"
    Markdown_limits.Containers
    (Readable_file.read
       { size = 100_000; brackets = 5; containers = 16 }
       fail_pack
       (read_file_of ~markdown:true "docs/hostile-ctr.md" hostile_lists));
  let code_content = rep "[" 10 ^ " " ^ rep "- " 10 ^ " // ok\n" in
  let code_pack () _path _text =
    incr pack_called;
    ( { Comment_sigils.line = [ text_of "//" ]; block = []; inner = [] },
      Reading.Parsed [] )
  in
  (match
     Readable_file.read
       { size = 5; brackets = 0; containers = 0 }
       code_pack
       (read_file_of ~markdown:false "lib/a.rs" code_content)
   with
  | Ok (Readable_file.Code_file _) -> ()
  | _ -> Alcotest.fail "markdown limits must not stop a code file");
  Alcotest.(check int) "pack was called once for the code file" 1 !pack_called

(* @verifies documents#give-declared-items=v1
   A stopped markdown file cannot be read and gives no declared items, while
   every other readable markdown file and code file in the tree is read and
   gives its declared items. *)
let stopped_files_do_not_prevent_reading_the_rest_of_the_tree () =
  let files =
    [
      ("docs/a.md", "# Design\n@design d=v1\nGood design.\n");
      ("docs/too-big.md", "# Big\n@req d#big=v1\n" ^ String.make 120 'x' ^ "\n");
      ("docs/too-deep-brackets.md", "# Brk\n@req d#brk=v1\n[[[[a]]]]\n");
      ("docs/too-deep-lists.md", "# Lst\n@req d#lst=v1\n\n- - - - a\n");
      ("docs/z.md", "# Req\n@req d#ok=v1\nGood requirement.\n");
      ("lib/s.rs", "// @spec d#s=v1\n// [[[[code]]]]\nfn f() {}\n");
    ]
  in
  let tree =
    match Tree.of_files (List.map (fun (p, c) -> (path_of p, c)) files) with
    | Ok t -> t
    | Error _ -> Alcotest.fail "valid tree"
  in
  let readers =
    match
      File_readers.make
        [
          (File_readers.Markdown, [ text_of "docs/*.md" ]);
          (File_readers.Pack (), [ text_of "lib/*.rs" ]);
        ]
    with
    | Ok r -> r
    | Error _ -> Alcotest.fail "valid readers"
  in
  let pack () _path _text =
    ( { Comment_sigils.line = [ text_of "//" ]; block = []; inner = [] },
      Reading.Parsed
        [
          {
            Reading.run = { Text.from = 0; until = 15 };
            comment = Some Reading.Tagged;
            body = None;
            decoration = false;
            test = None;
          };
        ] )
  in
  let limits = { Markdown_limits.size = 80; brackets = 3; containers = 3 } in
  let read_files = Read_file.read_files readers tree in
  let stopped = ref [] in
  let tree_files =
    List.filter_map
      (fun file ->
        let name = Text.encode (Path.to_text (Read_file.path file)) in
        match Readable_file.read limits pack file with
        | Ok readable ->
            Some (Tree_file.make Binding.empty (Read_file.path file) readable)
        | Error (Readable_file.Stopped { limit = lim; _ }) ->
            stopped := (name, lim) :: !stopped;
            None
        | Error _ -> Alcotest.fail ("unexpected error for " ^ name))
      read_files
  in
  Alcotest.(check (list (pair string limit_testable)))
    "the three stopped files with their limits"
    [
      ("docs/too-big.md", Markdown_limits.Size);
      ("docs/too-deep-brackets.md", Markdown_limits.Brackets);
      ("docs/too-deep-lists.md", Markdown_limits.Containers);
    ]
    (List.rev !stopped);
  match Declared_items.make tree tree_files with
  | Error _ -> Alcotest.fail "Declared_items.make failed"
  | Ok declared ->
      let names =
        List.map Declared_items.name (Declared_items.items declared)
      in
      Alcotest.(check (list string))
        "items come only from readable files in the tree" [ "d"; "d#ok"; "d#s" ]
        names

(* @cites commonmark-reader *)
let bracket_depth_grows_linearly_and_bounds_memory () =
  let worst_at_limit n = rep "[" 5 ^ rep "`a<b" n in
  let many_lt n = rep "[" 3 ^ rep "<a" n ^ ">" in
  let deep_past_limit n = rep "[" n in
  Alcotest.(check (option int))
    "worst_at_limit stays at depth 5" (Some 5)
    (Markdown_limits.bracket_depth ~limit:5 (worst_at_limit 10));
  Alcotest.(check (option int))
    "many_lt stays at depth 3" (Some 3)
    (Markdown_limits.bracket_depth ~limit:5 (many_lt 10));
  Alcotest.(check (option int))
    "deep_past_limit stops past limit 5" None
    (Markdown_limits.bracket_depth ~limit:5 (deep_past_limit 100));
  Time_growth.check ~bound:10. ~size:2_000 ~input:worst_at_limit (fun s ->
      Markdown_limits.bracket_depth ~limit:5 s);
  Time_growth.check ~bound:10. ~size:2_000 ~input:many_lt (fun s ->
      Markdown_limits.bracket_depth ~limit:5 s);
  Time_growth.check ~bound:10. ~size:5_000 ~input:deep_past_limit (fun s ->
      Markdown_limits.bracket_depth ~limit:5 s);
  Counted_work.check_growth ~exponent:0. ~margin:1.5 ~sizes:(2_000, 32_000)
    ~input:deep_past_limit (fun s -> Markdown_limits.bracket_depth ~limit:5 s);
  let deep_result =
    with_small_stack (fun () ->
        Markdown_limits.bracket_depth ~limit:max_int (rep "[" 100_000))
  in
  Alcotest.(check (option int))
    "100,000 open brackets do not overflow the stack" (Some 100_000) deep_result

(* @cites commonmark-reader *)
let container_depth_grows_linearly_and_bounds_memory () =
  let many_lines n = rep "  - a\n" n in
  let many_ordered n = rep "1. a\n" n in
  let long_digits n = String.make n '1' ^ ". a\n" in
  let deep_list_line n = rep "- " n ^ "a\n" in
  Alcotest.(check (option int))
    "many_lines has depth 2" (Some 2)
    (Markdown_limits.container_depth ~limit:5 (many_lines 10));
  Alcotest.(check (option int))
    "many_ordered has depth 1" (Some 1)
    (Markdown_limits.container_depth ~limit:5 (many_ordered 10));
  Alcotest.(check (option int))
    "long_digits has depth 0" (Some 0)
    (Markdown_limits.container_depth ~limit:5 (long_digits 20));
  Alcotest.(check (option int))
    "deep_list_line stops past limit 5" None
    (Markdown_limits.container_depth ~limit:5 (deep_list_line 100));
  Time_growth.check ~bound:10. ~size:2_000 ~input:many_lines (fun s ->
      Markdown_limits.container_depth ~limit:5 s);
  Time_growth.check ~bound:10. ~size:5_000 ~input:long_digits (fun s ->
      Markdown_limits.container_depth ~limit:5 s);
  Time_growth.check ~bound:10. ~size:2_000 ~input:deep_list_line (fun s ->
      Markdown_limits.container_depth ~limit:5 s);
  let early_stop n = rep "- " 6 ^ "a\n" ^ rep "a\n" n in
  Alcotest.(check (option int))
    "early_stop stops on the first line" None
    (Markdown_limits.container_depth ~limit:5 (early_stop 10));
  Counted_work.check_growth ~exponent:0. ~margin:1.5 ~sizes:(2_000, 32_000)
    ~input:deep_list_line (fun s -> Markdown_limits.container_depth ~limit:5 s);
  Counted_work.check_growth ~exponent:0. ~margin:1.5 ~sizes:(2_000, 32_000)
    ~input:many_lines (fun s -> Markdown_limits.container_depth ~limit:5 s);
  Counted_work.check_growth ~exponent:0. ~margin:1.5 ~sizes:(2_000, 32_000)
    ~input:many_ordered (fun s -> Markdown_limits.container_depth ~limit:5 s);
  let many_result =
    with_small_stack (fun () ->
        Markdown_limits.container_depth ~limit:10 (many_lines 150_000))
  in
  Alcotest.(check (option int))
    "150,000 lines do not overflow the stack" (Some 2) many_result;
  let long_result =
    with_small_stack (fun () ->
        Markdown_limits.container_depth ~limit:max_int (deep_list_line 100_000))
  in
  Alcotest.(check (option int))
    "100,000 nested list markers on one line do not overflow the stack"
    (Some 100_000) long_result

(* @cites commonmark-reader *)
let stopped_file_costs_at_most_linear_time () =
  let no_pack () _path _text = Alcotest.fail "no pack for markdown" in
  let make_file content =
    read_file_of ~markdown:true "docs/hostile.md" content
  in
  let size_limits = { no_limits with size = 50 } in
  let bracket_limits = { no_limits with brackets = 5 } in
  let container_limits = { no_limits with containers = 16 } in
  let over_size n = make_file (String.make (100 + n) 'a') in
  let over_brackets n =
    make_file (rep "[" 30 ^ rep "*_" n ^ "a" ^ rep "_*" n ^ rep "]" 30)
  in
  let over_containers n = make_file (rep "- " 100 ^ "a\n" ^ rep "a\n" n) in
  check_stopped "over_size stops with Size" Markdown_limits.Size
    (Readable_file.read size_limits no_pack (over_size 50));
  check_stopped "over_brackets stops with Brackets" Markdown_limits.Brackets
    (Readable_file.read bracket_limits no_pack (over_brackets 50));
  check_stopped "over_containers stops with Containers"
    Markdown_limits.Containers
    (Readable_file.read container_limits no_pack (over_containers 50));
  Time_growth.check ~bound:10. ~size:2_000 ~input:over_size (fun file ->
      Readable_file.read size_limits no_pack file);
  Time_growth.check ~bound:10. ~size:1_000 ~input:over_brackets (fun file ->
      Readable_file.read bracket_limits no_pack file);
  Time_growth.check ~bound:10. ~size:2_000 ~input:over_containers (fun file ->
      Readable_file.read container_limits no_pack file)

(* @verifies documents#give-declared-items=v1
   For generated markdown and code files, valid or invalid UTF-8, and varied
   limits, Readable_file.read checks UTF-8 first, stops markdown files past a
   limit with the limit that stopped them so they give no declared items,
   never stops code files for markdown limits, and calls the pack only for
   valid-UTF-8 code files. *)
let readable_file_read_with_limits_property =
  let content_gen =
    Gen.oneof_weighted
      [
        (4, utf8_body_gen);
        (1, Gen.map (fun s -> "\xef\xbb\xbf" ^ s) utf8_body_gen);
        (1, Gen.oneof_list [ "\xff"; "a\xc3"; "[[[\xff]]]" ]);
      ]
  in
  let limits_gen =
    Gen.map3
      (fun size brackets containers ->
        { Markdown_limits.size; brackets; containers })
      (Gen.oneof_list [ -1; 0; 3; 10; max_int ])
      (Gen.oneof_list [ -1; 0; 1; 3; max_int ])
      (Gen.oneof_list [ -1; 0; 1; 3; max_int ])
  in
  property ~count:600
    ~name:"Readable_file.read applies markdown limits as promised"
    ~print:(fun (markdown, content, (l : Markdown_limits.t)) ->
      Printf.sprintf "markdown=%b size=%d brackets=%d containers=%d content=%S"
        markdown l.size l.brackets l.containers content)
    (Gen.triple Gen.bool content_gen limits_gen)
    (fun (markdown, content, limits) ->
      let path = if markdown then "docs/a.md" else "lib/a.rs" in
      let rf = read_file_of ~markdown path content in
      let calls = ref 0 in
      let pack () _path _text =
        incr calls;
        ({ Comment_sigils.line = []; block = []; inner = [] }, Reading.Parsed [])
      in
      let outcome = Readable_file.read limits pack rf in
      match (Text.decode content, markdown, outcome) with
      | ( Error e,
          _,
          Error (Readable_file.Cannot_be_read (Readable_file.Not_utf_8 e')) ) ->
          e = e' && !calls = 0
      | Ok text, true, _ -> (
          !calls = 0
          &&
          let lines = Lines.of_text text in
          match (Markdown_limits.check limits lines, outcome) with
          | Ok _, Ok (Readable_file.Markdown_file accepted) ->
              Text.equal
                (Lines.text (Markdown_limits.lines accepted))
                (Lines.text lines)
          | Error l, Error (Readable_file.Stopped { limit = l'; _ }) -> l = l'
          | _ -> false)
      | Ok _, false, Ok (Readable_file.Code_file _) -> !calls = 1
      | _ -> false)

let tests =
  [
    bracket_depth_follows_rule_s3;
    bracket_depth_threshold_property;
    container_depth_follows_rule_c;
    container_depth_threshold_property;
    check_follows_its_promise;
    readable_file_read_with_limits_property;
    Alcotest.test_case "check enforces limit boundaries, BOM, and priority"
      `Quick check_limit_boundaries;
    Alcotest.test_case
      "readable files enforce limits and report which limit stopped them" `Quick
      readable_file_limits_cases;
    Alcotest.test_case
      "stopped files cannot be read and the rest of the tree is read" `Quick
      stopped_files_do_not_prevent_reading_the_rest_of_the_tree;
    Alcotest.test_case
      "bracket_depth is linear in length and bounds memory past the limit"
      `Quick bracket_depth_grows_linearly_and_bounds_memory;
    Alcotest.test_case
      "container_depth is linear in length and bounds memory past the limit"
      `Quick container_depth_grows_linearly_and_bounds_memory;
    Alcotest.test_case "a stopped file costs at most linear time" `Quick
      stopped_file_costs_at_most_linear_time;
  ]
  @ List.map
      (fun (name, text, expected) ->
        Alcotest.test_case name `Quick (check_bracket_case name text expected))
      bracket_rule_s3_step_cases
  @ List.map
      (fun (name, text, expected) ->
        Alcotest.test_case
          ("hostile bracket shape " ^ name)
          `Quick
          (check_bracket_case name text expected))
      hostile_bracket_shapes_n5
  @ List.map
      (fun (name, text, expected) ->
        Alcotest.test_case name `Quick (check_container_case name text expected))
      container_rule_c_cases
