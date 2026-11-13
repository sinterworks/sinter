(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_spots
open Sinter_findings
module Gen = QCheck2.Gen
module Path = Sinter_paths.Path
module Tree = Sinter_tree.Tree
module M = Findings_model
module S = Set_vectors

let property ?(count = 500) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let text_of string = M.to_text (M.of_string string)
let string_of text = Text.encode text

let path_of string =
  match Path.of_text (text_of string) with
  | Ok path -> path
  | Error _ -> invalid_arg "path_of"

let tree_of files =
  match
    Tree.of_files (List.map (fun (name, bytes) -> (path_of name, bytes)) files)
  with
  | Ok tree -> tree
  | Error _ -> invalid_arg "tree_of"

let ok = function Ok value -> value | Error _ -> invalid_arg "ok"
let some = function Some value -> value | None -> invalid_arg "some"
let message string = ok (Message.of_text (text_of string))
let subject string = ok (Subject.of_text (text_of string))
let class_slug string = some (Class_slug.of_text (text_of string))

(* The finding ids. *)

let findings_set = S.read "findings"

let give_finding_ids (vector : Sinter_test_vectors.Test_vector_set.vector) =
  let slug = Class_slug.of_text (S.to_text (S.member "class" vector.input)) in
  let subject = Subject.of_text (S.to_text (S.member "subject" vector.input)) in
  match (slug, subject) with
  | Some slug, Ok subject ->
      {
        S.result = None;
        values =
          S.object_
            [
              ( "finding-id",
                S.text (Finding_id.to_text (Finding_id.make slug subject)) );
            ];
      }
  | None, _ -> Alcotest.fail "the class is a slug"
  | _, Error _ -> Alcotest.fail "the subject is a subject of a finding"

(* @verifies findings[finding-ids][*]=v1
   Each vector gives a slug, a subject, and the finding id; the test fails when
   the finding id that the code gives is another text. *)
let finding_id_vectors =
  S.group findings_set ~name:"finding-ids" ~rev:"v1" give_finding_ids

let segment_gen =
  Gen.map (String.concat "")
    (Gen.list_size (Gen.int_range 1 3)
       (Gen.oneof_list [ "a"; "Z"; "0"; "a-b"; "a_b"; "a.b" ]))

let slug_gen =
  Gen.map (String.concat "/") (Gen.list_size (Gen.int_range 1 3) segment_gen)

let character_gen =
  Gen.oneof_weighted
    [
      (5, Gen.return "a");
      (2, Gen.return ":");
      (2, Gen.return " ");
      (2, Gen.return "\t");
      (2, Gen.return "\n");
      (2, Gen.return "\r");
      (1, Gen.return "\x00");
      (1, Gen.return "\xc3\xa9");
      (1, Gen.return "\xe2\x80\xa8");
      (1, Gen.return "#");
    ]

let free_text_gen =
  Gen.map (String.concat "") (Gen.list_size (Gen.int_range 0 6) character_gen)

let subject_gen =
  Gen.map
    (fun text ->
      let trimmed = String.trim text in
      let no_lf = String.map (fun c -> if c = '\n' then 'x' else c) trimmed in
      if no_lf = "" || not (M.is_subject (M.of_string no_lf)) then
        "s" ^ no_lf ^ "s"
      else no_lf)
    free_text_gen

let split_finding_id text =
  let prefix = "finding:" in
  let length = String.length prefix in
  if String.length text < length || String.sub text 0 length <> prefix then None
  else
    let rest = String.sub text length (String.length text - length) in
    match String.index_opt rest ':' with
    | None -> None
    | Some colon ->
        Some
          ( String.sub rest 0 colon,
            String.sub rest (colon + 1) (String.length rest - colon - 1) )

(* @verifies findings#give-finding-ids=v1
   For generated slugs and subjects, the test fails when the finding id is
   not the text finding:, then the slug, then :, then the subject, or when the
   first : after finding: does not end the slug. *)
let finding_id_is_the_slug_and_the_subject =
  property ~count:1000
    ~name:"the finding id is finding:, the slug, :, and the subject"
    ~print:(fun (slug, subject) -> Printf.sprintf "%s %S" slug subject)
    (Gen.pair slug_gen subject_gen)
    (fun (slug, subject_text) ->
      let id = Finding_id.make (class_slug slug) (subject subject_text) in
      let text = string_of (Finding_id.to_text id) in
      text = "finding:" ^ slug ^ ":" ^ subject_text
      && split_finding_id text = Some (slug, subject_text)
      && string_of (Class_slug.to_text (Finding_id.class_slug id)) = slug
      && string_of (Subject.to_text (Finding_id.subject id)) = subject_text)

let finding_ids_are_the_same_finding_by_slug_and_subject =
  property ~count:1000
    ~name:
      "two identities are equal when, and only when, slug and subject are the \
       same"
    ~print:(fun ((a, b), (c, d)) -> Printf.sprintf "%s %S / %s %S" a b c d)
    Gen.(
      pair
        (pair (oneof_list [ "a"; "b"; "A" ]) (oneof_list [ "x"; "y"; "x:y" ]))
        (pair (oneof_list [ "a"; "b"; "A" ]) (oneof_list [ "x"; "y"; "x:y" ])))
    (fun ((a, b), (c, d)) ->
      Bool.equal
        (Finding_id.equal
           (Finding_id.make (class_slug a) (subject b))
           (Finding_id.make (class_slug c) (subject d)))
        (a = c && b = d))

let message_error = function
  | Message.Empty -> "Empty"
  | Message.Line_break { place } -> Printf.sprintf "Line_break %d" place

let messages_hold_no_line_break =
  property ~count:1000
    ~name:"of_text gives a message for a text that is a message"
    ~print:String.escaped free_text_gen (fun text ->
      let characters = M.of_string text in
      let lowest =
        List.find_index
          (fun u -> Uchar.to_int u = 0x0A || Uchar.to_int u = 0x0D)
          characters
      in
      match (Message.of_text (M.to_text characters), lowest) with
      | Ok message, None ->
          M.is_message characters && string_of (Message.to_text message) = text
      | Error error, Some index when characters <> [] ->
          message_error error = Printf.sprintf "Line_break %d" (index + 1)
      | Error Message.Empty, _ -> characters = []
      | _ -> false)

let message_equal_compares_texts =
  property
    ~name:"two messages are equal when, and only when, their texts are the same"
    ~print:(fun (a, b) -> a ^ " / " ^ b)
    Gen.(pair (oneof_list [ "a"; "b"; "a b" ]) (oneof_list [ "a"; "b"; "a b" ]))
    (fun (a, b) -> Bool.equal (Message.equal (message a) (message b)) (a = b))

let blank u = Uchar.to_int u = 0x20 || Uchar.to_int u = 0x09

let subjects_follow_the_production =
  property ~count:1000
    ~name:"of_text gives a subject for a text that is a subject"
    ~print:String.escaped free_text_gen (fun text ->
      let characters = M.of_string text in
      let expected =
        match (characters, List.rev characters) with
        | [], _ | _, [] -> Error Subject.Empty
        | first :: _, _ when blank first -> Error Subject.Blank_start
        | _, last :: _ when blank last -> Error Subject.Blank_end
        | _ -> (
            match
              List.find_index (fun u -> Uchar.to_int u = 0x0A) characters
            with
            | Some index -> Error (Subject.Line_feed { place = index + 1 })
            | None -> Ok text)
      in
      match (Subject.of_text (M.to_text characters), expected) with
      | Ok subject, Ok text ->
          M.is_subject characters && string_of (Subject.to_text subject) = text
      | Error have, Error want -> have = want && not (M.is_subject characters)
      | _ -> false)

let a_subject_can_hold_a_carriage_return_and_u_0000 () =
  List.iter
    (fun text ->
      Alcotest.(check bool)
        (String.escaped text) true
        (Result.is_ok (Subject.of_text (text_of text))))
    [ "a\rb"; "\x00"; "\r"; "a:b"; "finding:y:z" ]

let class_slugs_are_slugs =
  property ~count:1000
    ~name:"of_text gives a class slug for a text that is a slug"
    ~print:String.escaped
    (Gen.oneof [ slug_gen; free_text_gen ])
    (fun text ->
      match Class_slug.of_text (text_of text) with
      | Some slug ->
          Sinter_identifiers.Slug_form.is_slug text
          && string_of (Class_slug.to_text slug) = text
      | None -> not (Sinter_identifiers.Slug_form.is_slug text))

(* The marks. *)

let mark_text_gen =
  Gen.map
    (fun (bom, parts) ->
      M.of_string ((if bom then "\xef\xbb\xbf" else "") ^ String.concat "" parts))
    (Gen.pair Gen.bool
       (Gen.list_size (Gen.int_range 0 6)
          (Gen.oneof_list [ "a"; "b"; "\n"; "\r\n"; "\r" ])))

let mark_case_gen =
  Gen.(
    mark_text_gen >>= fun t ->
    let n = List.length t in
    map
      (fun (s, m) -> (t, s, m))
      (pair
         (option (pair (int_range 0 n) (int_range 0 n)))
         (pair (int_range (-1) (n + 1)) (int_range (-1) (n + 1)))))

let print_mark_case (t, s, (mf, mu)) =
  Printf.sprintf "%s; spot %s; mark %d to %d" (M.print t)
    (match s with None -> "-" | Some (f, u) -> Printf.sprintf "%d to %d" f u)
    mf mu

let mark_error = function
  | Mark.No_span -> "No_span"
  | Mark.No_line -> "No_line"
  | Mark.Not_a_spot _ -> "Not_a_spot"
  | Mark.Outside -> "Outside"

(* @verifies findings#omit-absent-finding-parts=v1
   A spot whose span starts at a boundary of no line has no mark, and a run
   outside the span of the spot or outside the line where it starts is the span
   of no mark; the test fails when the code gives a mark in either case, or for
   a spot without a span. *)
let marks_lie_in_the_spot_and_its_first_line =
  property ~count:2000
    ~name:"make gives a mark only for a run in the spot and its first line"
    ~print:print_mark_case mark_case_gen (fun (t, spot_run, (mf, mu)) ->
      let tree = tree_of [ ("a.md", M.to_string t) ] in
      let path = path_of "a.md" in
      let spot =
        match spot_run with
        | None -> Spot.of_file tree path
        | Some (from, until) -> Spot.of_run tree path { from; until }
      in
      match spot with
      | Error _ -> true
      | Ok spot -> (
          let note = message "here" in
          let have = Mark.make spot { from = mf; until = mu } note in
          let expected =
            match spot_run with
            | None -> Error "No_span"
            | Some (sf, su) -> (
                match M.line_of_boundary t sf with
                | None -> Error "No_line"
                | Some (ls, le) -> (
                    match Spot.of_run tree path { from = mf; until = mu } with
                    | Error _ -> Error "Not_a_spot"
                    | Ok _ ->
                        if sf <= mf && mu <= su && ls <= mf && mu <= le then
                          Ok ()
                        else Error "Outside"))
          in
          match (have, expected) with
          | Ok mark, Ok () ->
              Spot.equal (Mark.marked mark) spot
              && Spot.span (Mark.spot mark) = Some { from = mf; until = mu }
              && Spot.equal (Mark.spot mark)
                   (ok (Spot.of_run tree path { from = mf; until = mu }))
              && Message.equal (Mark.message mark) note
          | Error (Mark.Not_a_spot error), Error "Not_a_spot" ->
              Spot.of_run tree path { from = mf; until = mu } = Error error
          | Error error, Error want -> mark_error error = want
          | _ -> false))

(* A world of two trees with equal contents, one other tree, and parts in
   each. *)

let content = "abc\ndef"
let tree_t = tree_of [ ("a.md", content); ("b.md", "x") ]
let tree_t' = tree_of [ ("b.md", "x"); ("a.md", content) ]
let tree_u = tree_of [ ("a.md", "abc\ndeX"); ("b.md", "x") ]

let spot_in tree from until =
  ok (Spot.of_run tree (path_of "a.md") { from; until })

let mark_of spot from until =
  ok (Mark.make spot { from; until } (message "at fault"))

let edit_set_in tree from until replacement =
  ok
    (Edit_set.of_edits
       [ ok (Edit.make (spot_in tree from until) (text_of replacement)) ])

let fix_in tree =
  ok (Finding_fix.make (message "fix it") [ edit_set_in tree 1 2 "X" ])

type choice = {
  tree : int;  (** 0 no tree, 1 tree_t *)
  spot : int;  (** 0 no spot, 1 in tree_t', 2 in tree_u *)
  mark : int;  (** 0 no mark, 1 of the spot, 2 of another spot *)
  fix : int;  (** 0 no fix, 1 in tree_t', 2 in tree_u *)
  ackable : bool;
}

let choice_gen =
  Gen.map
    (fun ((tree, spot), (mark, fix), ackable) ->
      { tree; spot; mark; fix; ackable })
    Gen.(
      triple
        (pair (int_range 0 1) (int_range 0 2))
        (pair (int_range 0 2) (int_range 0 2))
        bool)

let print_choice c =
  Printf.sprintf "tree %d spot %d mark %d fix %d ackable %b" c.tree c.spot
    c.mark c.fix c.ackable

let spot_of_choice c =
  match c.spot with
  | 0 -> None
  | 1 -> Some (spot_in tree_t' 0 3)
  | _ -> Some (spot_in tree_u 0 3)

let mark_of_choice c =
  let marked =
    match spot_of_choice c with
    | Some spot -> spot
    | None -> spot_in tree_t' 0 3
  in
  match c.mark with
  | 0 -> None
  | 1 -> Some (mark_of marked 1 2)
  | _ -> Some (mark_of (spot_in tree_t' 0 2) 1 2)

let fix_of_choice c =
  match c.fix with
  | 0 -> None
  | 1 -> Some (fix_in tree_t')
  | _ -> Some (fix_in tree_u)

let related_pool =
  [|
    Related_message.make (message "declared here") None;
    Related_message.make (message "declared here") (Some (spot_in tree_t 0 3));
    Related_message.make (message "declared here") (Some (spot_in tree_t' 0 3));
    Related_message.make (message "declared here") (Some (spot_in tree_u 0 3));
    Related_message.make (message "used here") None;
  |]

let related_key = [| 0; 1; 1; 2; 3 |]

let build ?(related = []) c =
  Finding_parts.make
    ~tree:(if c.tree = 1 then Some tree_t else None)
    ~class_slug:(class_slug "no-test")
    ~subject:(subject "billing#due-date")
    ~message:(message "no test cites this requirement")
    ~spot:(spot_of_choice c) ~mark:(mark_of_choice c)
    ~related:(List.map (fun index -> related_pool.(index)) related)
    ~fix:(fix_of_choice c) ~ackable:c.ackable

let parts_error = function
  | Finding_parts.Spot_outside_tree -> "Spot_outside_tree"
  | Finding_parts.Mark_of_other_spot -> "Mark_of_other_spot"
  | Finding_parts.Fix_outside_tree -> "Fix_outside_tree"

let expected_parts c =
  if c.spot <> 0 && (c.tree = 0 || c.spot = 2) then Error "Spot_outside_tree"
  else if c.mark <> 0 && (c.spot = 0 || c.mark = 2) then
    Error "Mark_of_other_spot"
  else if c.fix <> 0 && (c.tree = 0 || c.fix = 2) then Error "Fix_outside_tree"
  else Ok ()

let option_equal equal a b =
  match (a, b) with
  | None, None -> true
  | Some a, Some b -> equal a b
  | _ -> false

(* @verifies findings#{give-finding-parts=v1, omit-absent-finding-parts=v1, limit-fix-edit-sets=v1}
   For each choice of parts, the test fails when a finding gets a spot, a mark,
   or a fix that it cannot have (a spot or fix outside its tree or for no tree,
   a mark of another spot), or when a part that the finding has comes back
   other than it was given. For limit-fix-edit-sets it checks only that a fix
   is in the tree of the finding; whether an edit set corrects the finding
   depends on its finding class. *)
let findings_have_their_parts_and_no_other =
  property ~count:1000
    ~name:"make gives a finding with its parts, and no part it cannot have"
    ~print:print_choice choice_gen (fun c ->
      match (build c, expected_parts c) with
      | Error error, Error want -> parts_error error = want
      | Ok finding, Ok () ->
          option_equal Tree.equal
            (Finding_parts.tree finding)
            (if c.tree = 1 then Some tree_t else None)
          && string_of (Class_slug.to_text (Finding_parts.class_slug finding))
             = "no-test"
          && string_of (Subject.to_text (Finding_parts.subject finding))
             = "billing#due-date"
          && Finding_id.equal (Finding_parts.id finding)
               (Finding_id.make (class_slug "no-test")
                  (subject "billing#due-date"))
          && Message.equal
               (Finding_parts.message finding)
               (message "no test cites this requirement")
          && option_equal Spot.equal
               (Finding_parts.spot finding)
               (spot_of_choice c)
          && option_equal Mark.equal
               (Finding_parts.mark finding)
               (mark_of_choice c)
          && option_equal Finding_fix.equal
               (Finding_parts.fix finding)
               (fix_of_choice c)
          && Finding_parts.related finding = []
          && Bool.equal (Finding_parts.ackable finding) c.ackable
          && (c.tree = 1
             || Finding_parts.spot finding = None
                && Finding_parts.fix finding = None)
      | _ -> false)

let valid_choice = { tree = 1; spot = 1; mark = 1; fix = 1; ackable = true }

let related_messages_are_a_set =
  property ~count:500
    ~name:"the related messages are a set, each once in its first order"
    ~print:(fun indexes -> String.concat " " (List.map string_of_int indexes))
    (Gen.list_size (Gen.int_range 0 6) (Gen.int_range 0 4))
    (fun indexes ->
      let finding = ok (build ~related:indexes valid_choice) in
      let rec firsts seen = function
        | [] -> []
        | index :: rest ->
            if List.mem related_key.(index) seen then firsts seen rest
            else index :: firsts (related_key.(index) :: seen) rest
      in
      let expected = firsts [] indexes in
      let given = Finding_parts.related finding in
      List.length given = List.length expected
      && List.for_all2
           (fun have index -> Related_message.equal have related_pool.(index))
           given expected
      && Finding_parts.equal finding
           (ok (build ~related:(List.rev indexes) valid_choice)))

let mark_equal_compares_marked_spot_spot_and_message () =
  let mark = mark_of (spot_in tree_t 0 3) 1 2 in
  let check name want other =
    Alcotest.(check bool) name want (Mark.equal mark other)
  in
  check "the same mark in a tree of the same files" true
    (mark_of (spot_in tree_t' 0 3) 1 2);
  check "another span" false (mark_of (spot_in tree_t 0 3) 0 2);
  check "another marked spot" false (mark_of (spot_in tree_t 0 2) 1 2);
  check "another message" false
    (ok
       (Mark.make (spot_in tree_t 0 3) { from = 1; until = 2 } (message "other")));
  check "another tree" false (mark_of (spot_in tree_u 0 3) 1 2)

let related_message_equal_compares_message_and_spot () =
  let check name want a b =
    Alcotest.(check bool)
      name want
      (Related_message.equal related_pool.(a) related_pool.(b))
  in
  check "the same message with no spot" true 0 0;
  check "a spot and no spot" false 0 1;
  check "spots in two trees of the same files" true 1 2;
  check "spots in two trees of other files" false 1 3;
  check "two messages with no spot" false 0 4;
  Alcotest.(check bool)
    "the spot" true
    (option_equal Spot.equal
       (Related_message.spot related_pool.(1))
       (Some (spot_in tree_t 0 3)));
  Alcotest.(check bool)
    "the message" true
    (Message.equal
       (Related_message.message related_pool.(4))
       (message "used here"))

let equal_compares_every_part () =
  let finding = ok (build ~related:[ 0; 1 ] valid_choice) in
  let check name want other =
    Alcotest.(check bool) name want (Finding_parts.equal finding (ok other))
  in
  check "the same parts" true (build ~related:[ 2; 0 ] valid_choice);
  check "another ackable" false
    (build ~related:[ 0; 1 ] { valid_choice with ackable = false });
  check "no fix" false (build ~related:[ 0; 1 ] { valid_choice with fix = 0 });
  check "no mark" false (build ~related:[ 0; 1 ] { valid_choice with mark = 0 });
  check "another related message" false (build ~related:[ 0; 4 ] valid_choice);
  check "fewer related messages" false (build ~related:[ 0 ] valid_choice);
  check "another message" false
    (Finding_parts.make ~tree:(Some tree_t) ~class_slug:(class_slug "no-test")
       ~subject:(subject "billing#due-date")
       ~message:(message "other")
       ~spot:(spot_of_choice valid_choice)
       ~mark:(mark_of_choice valid_choice)
       ~related:[ related_pool.(0); related_pool.(1) ]
       ~fix:(fix_of_choice valid_choice)
       ~ackable:true);
  check "another tree" false
    (Finding_parts.make ~tree:(Some tree_u) ~class_slug:(class_slug "no-test")
       ~subject:(subject "billing#due-date")
       ~message:(message "no test cites this requirement")
       ~spot:None ~mark:None
       ~related:[ related_pool.(0); related_pool.(1) ]
       ~fix:None ~ackable:true)

(* The fixes. *)

let edit_set_pool =
  [|
    edit_set_in tree_t 1 2 "X";
    edit_set_in tree_t' 1 2 "X";
    edit_set_in tree_t 1 2 "Y";
    edit_set_in tree_u 1 2 "X";
  |]

let edit_set_key = [| 0; 0; 1; 2 |]

let fix_error = function
  | Finding_fix.No_edit_set -> "No_edit_set"
  | Finding_fix.Different_trees -> "Different_trees"
  | Finding_fix.Repeated_edit_set { first; second } ->
      Printf.sprintf "Repeated_edit_set %d %d" first second

let expected_fix indexes =
  let keys = List.map (fun index -> edit_set_key.(index)) indexes in
  let in_u = List.map (fun key -> key = 2) keys in
  if indexes = [] then Error "No_edit_set"
  else if List.mem true in_u && List.mem false in_u then Error "Different_trees"
  else
    let numbered = List.mapi (fun index key -> (index + 1, key)) keys in
    match
      List.find_map
        (fun (second, key) ->
          List.find_map
            (fun (first, other) ->
              if first < second && other = key then Some (first, second)
              else None)
            numbered)
        numbered
    with
    | Some (first, second) ->
        Error (Printf.sprintf "Repeated_edit_set %d %d" first second)
    | None -> Ok ()

(* @verifies findings#limit-fix-edit-sets=v1
   A fix holds one or more edit sets in one tree, no two the same set, with
   numbers from 1 in their order; the test fails when the code gives a fix
   that breaks one of these, or numbers its edit sets otherwise. It does not
   check that an edit set corrects the finding: that depends on its finding
   class. *)
let fixes_hold_distinct_edit_sets_of_one_tree =
  property ~count:1000
    ~name:"make gives a fix of distinct edit sets of one tree, numbered from 1"
    ~print:(fun indexes -> String.concat " " (List.map string_of_int indexes))
    (Gen.list_size (Gen.int_range 0 4) (Gen.int_range 0 3))
    (fun indexes ->
      let sets = List.map (fun index -> edit_set_pool.(index)) indexes in
      match
        (Finding_fix.make (message "fix it") sets, expected_fix indexes)
      with
      | Error error, Error want -> fix_error error = want
      | Ok fix, Ok () ->
          List.length (Finding_fix.edit_sets fix) = List.length sets
          && List.for_all2 Edit_set.equal (Finding_fix.edit_sets fix) sets
          && Message.equal (Finding_fix.message fix) (message "fix it")
          && List.for_all
               (fun set ->
                 Tree.equal (Finding_fix.tree fix) (Edit_set.tree set))
               sets
          && Finding_fix.equal fix
               (ok (Finding_fix.make (message "fix it") sets))
          && (List.length sets < 2
             || not
                  (Finding_fix.equal fix
                     (ok (Finding_fix.make (message "fix it") (List.rev sets))))
             )
      | _ -> false)

(* The finding sets. *)

type pick = { id : int; scope : int; words : int; ack : bool }

let pick_gen =
  Gen.map
    (fun ((id, scope), (words, ack)) -> { id; scope; words; ack })
    Gen.(
      pair (pair (int_range 0 1) (int_range 0 3)) (pair (int_range 0 1) bool))

let finding_of pick =
  ok
    (Finding_parts.make
       ~tree:
         (match pick.scope with
         | 0 -> None
         | 1 -> Some tree_t
         | 2 -> Some tree_t'
         | _ -> Some tree_u)
       ~class_slug:(class_slug "no-test")
       ~subject:(subject (if pick.id = 0 then "a" else "b"))
       ~message:(message (if pick.words = 0 then "one" else "two"))
       ~spot:None ~mark:None ~related:[] ~fix:None ~ackable:pick.ack)

let scope_key pick = match pick.scope with 0 -> 0 | 1 | 2 -> 1 | _ -> 2

let print_pick p =
  Printf.sprintf "id %d scope %d words %d ack %b" p.id p.scope p.words p.ack

(* @verifies findings#give-consistent-findings=v1
   Findings that are the same finding and of one scope (both of no tree, or of
   trees of the same files) must have the same parts; the test fails when the
   set takes a second finding with one part that differs, or keeps two such
   findings. *)
let finding_sets_hold_one_set_of_parts =
  property ~count:1000
    ~name:"a finding set holds one set of parts for each finding and scope"
    ~print:(fun picks -> String.concat "; " (List.map print_pick picks))
    (Gen.list_size (Gen.int_range 0 6) pick_gen)
    (fun picks ->
      let rec go set kept = function
        | [] ->
            let elements = Finding_set.elements set in
            List.length elements = List.length kept
            && List.for_all2
                 (fun element pick ->
                   Finding_parts.equal element (finding_of pick))
                 elements (List.rev kept)
            && List.for_all
                 (fun pick ->
                   option_equal Finding_parts.equal
                     (Finding_set.find set
                        (Finding_parts.tree (finding_of pick))
                        (Finding_parts.id (finding_of pick)))
                     (Some (finding_of pick)))
                 kept
        | pick :: rest -> (
            let same =
              List.find_opt
                (fun other ->
                  other.id = pick.id && scope_key other = scope_key pick)
                kept
            in
            match (Finding_set.add (finding_of pick) set, same) with
            | Ok set, None -> go set (pick :: kept) rest
            | Ok set, Some other ->
                Finding_parts.equal (finding_of other) (finding_of pick)
                && go set kept rest
            | Error (Finding_set.Conflict found), Some other ->
                (not (Finding_parts.equal (finding_of other) (finding_of pick)))
                && Finding_parts.equal found (finding_of other)
            | Error _, None -> false)
      in
      go Finding_set.empty [] picks)

let find_gives_no_finding_of_another_scope () =
  let set =
    ok
      (Finding_set.add
         (finding_of { id = 0; scope = 1; words = 0; ack = true })
         Finding_set.empty)
  in
  let id =
    Finding_parts.id (finding_of { id = 0; scope = 1; words = 0; ack = true })
  in
  let other_id =
    Finding_parts.id (finding_of { id = 1; scope = 1; words = 0; ack = true })
  in
  Alcotest.(check bool) "no tree" true (Finding_set.find set None id = None);
  Alcotest.(check bool)
    "another tree" true
    (Finding_set.find set (Some tree_u) id = None);
  Alcotest.(check bool)
    "another id" true
    (Finding_set.find set (Some tree_t) other_id = None);
  Alcotest.(check bool)
    "a tree of the same files" true
    (Option.is_some (Finding_set.find set (Some tree_t') id));
  Alcotest.(check int)
    "the empty set" 0
    (List.length (Finding_set.elements Finding_set.empty))

let vector_groups = [ finding_id_vectors ]

let tests =
  S.tests "findings" vector_groups
  @ [
      S.covers "findings" findings_set
        (Test_edit_sets.vector_groups @ vector_groups @ Test_spots.vector_groups);
      finding_id_is_the_slug_and_the_subject;
      finding_ids_are_the_same_finding_by_slug_and_subject;
      messages_hold_no_line_break;
      message_equal_compares_texts;
      subjects_follow_the_production;
      Alcotest.test_case "a subject can hold a carriage return and U+0000"
        `Quick a_subject_can_hold_a_carriage_return_and_u_0000;
      class_slugs_are_slugs;
      marks_lie_in_the_spot_and_its_first_line;
      findings_have_their_parts_and_no_other;
      related_messages_are_a_set;
      Alcotest.test_case
        "marks compare the marked spot, the spot, and the message" `Quick
        mark_equal_compares_marked_spot_spot_and_message;
      Alcotest.test_case "related messages compare message and spot" `Quick
        related_message_equal_compares_message_and_spot;
      Alcotest.test_case "equal compares every part" `Quick
        equal_compares_every_part;
      fixes_hold_distinct_edit_sets_of_one_tree;
      finding_sets_hold_one_set_of_parts;
      Alcotest.test_case "find gives no finding of another scope or id" `Quick
        find_gives_no_finding_of_another_scope;
    ]
