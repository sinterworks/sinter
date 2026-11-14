(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_id_patterns
open Sinter_identifiers
module Gen = QCheck2.Gen

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let str text = `String text

let json_string = function
  | `String text -> text
  | other ->
      Alcotest.failf "not a JSON string: %s" (Yojson.Basic.to_string other)

let json_member name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.failf "no member %s" name)
  | other ->
      Alcotest.failf "not a JSON object: %s" (Yojson.Basic.to_string other)

let pairs_of_json = function
  | `List pairs ->
      List.map
        (fun pair ->
          ( json_string (json_member "namespace-name" pair),
            json_string (json_member "id-pattern" pair) ))
        pairs
  | other -> Alcotest.failf "not a binding: %s" (Yojson.Basic.to_string other)

let set = Vectors.read "identifiers"

let give_id_pattern (vector : Vectors.vector) =
  let result =
    match Id_pattern.of_string (json_string vector.input) with
    | Ok _ -> "valid"
    | Error _ -> "invalid"
  in
  `Assoc [ ("result", str result); ("values", `Assoc []) ]

let give_fit (vector : Vectors.vector) =
  match
    Id_pattern.of_string (json_string (json_member "id-pattern" vector.input))
  with
  | Error _ -> `Assoc [ ("result", str "the id pattern is invalid") ]
  | Ok pattern ->
      let id = json_string (json_member "id" vector.input) in
      `Assoc
        [
          ( "result",
            str (if Id_pattern.fits pattern id then "fits" else "does not fit")
          );
          ("values", `Assoc []);
        ]

let give_binding (vector : Vectors.vector) =
  let result =
    match Binding.make (pairs_of_json vector.input) with
    | Ok _ -> "valid"
    | Error _ -> "invalid"
  in
  `Assoc [ ("result", str result); ("values", `Assoc []) ]

(* @verifies identifiers[id-patterns][*]=v1 *)
let id_pattern_vectors =
  Vectors.group set ~name:"id-patterns" ~rev:"v1" give_id_pattern

(* @verifies identifiers[fit][*]=v1 *)
let fit_vectors = Vectors.group set ~name:"fit" ~rev:"v1" give_fit

(* @verifies identifiers[bindings][*]=v1 *)
let binding_vectors = Vectors.group set ~name:"bindings" ~rev:"v1" give_binding

(* @verifies identifiers#{reject-unmatched-id-patterns=v1, reject-oversized-id-patterns=v1} *)
let id_pattern_errors () =
  List.iter
    (fun (pattern, want) ->
      Alcotest.(check bool)
        (Printf.sprintf "the error of %S" pattern)
        true
        (Id_pattern.of_string pattern = Error want))
    [
      ("[" ^ String.make 999 'a' ^ "]", Id_pattern.Too_long);
      ("^", Id_pattern.Unmatched);
      ("", Id_pattern.Unmatched);
      ("a b", Id_pattern.Unmatched);
      ("[]", Id_pattern.Unmatched);
      ("[^a]", Id_pattern.Unmatched);
      ("[a-Z]", Id_pattern.Unmatched);
      ("[a-9]", Id_pattern.Unmatched);
      ("a{,3}", Id_pattern.Unmatched);
      ("a{1,2,3}", Id_pattern.Unmatched);
      ("a{ 1}", Id_pattern.Unmatched);
      ("{1}", Id_pattern.Unmatched);
      ("|a", Id_pattern.Unmatched);
      ("(|a)", Id_pattern.Unmatched);
      ("a||b", Id_pattern.Unmatched);
      ("a?+", Id_pattern.Unmatched);
      ("(a", Id_pattern.Unmatched);
      ("a)", Id_pattern.Unmatched);
      ("\\d", Id_pattern.Unmatched);
      ("a\xff", Id_pattern.Unmatched);
      ("[a-", Id_pattern.Unmatched);
      ("[0-", Id_pattern.Unmatched);
      ("x[A-", Id_pattern.Unmatched);
      ("[9-0]", Id_pattern.Reversed_range);
      ("[Z-A]", Id_pattern.Reversed_range);
      ("x[b-a]", Id_pattern.Reversed_range);
      ("a{256}", Id_pattern.Large_count);
      ("a{1,256}", Id_pattern.Large_count);
      ("a{256,}", Id_pattern.Large_count);
      ("a{99999999999999999999999}", Id_pattern.Large_count);
      ("a{2,1}", Id_pattern.Reversed_bounds);
      ("a{255,0}", Id_pattern.Reversed_bounds);
      ("((a|b){250}){2}c", Id_pattern.Oversized);
      ("(a{250,}){4}", Id_pattern.Oversized);
      ("(((a|b){250}){2}){1,}", Id_pattern.Oversized);
      ("((a{1,}){250}){2}b", Id_pattern.Oversized);
      ("(((a|b){250}){2})?c", Id_pattern.Oversized);
      ("((a?){250}){4}b", Id_pattern.Oversized);
      ("((a*){250}){4}b", Id_pattern.Oversized);
      ("((a+){250}){4}b", Id_pattern.Oversized);
      ("((a{0,0}){250}){4}b", Id_pattern.Oversized);
      ("(((a|b){250}){2})*c", Id_pattern.Oversized);
      ("(((a|b){250}){2})+c", Id_pattern.Oversized);
      ("((a|b){250}){2}c{0,0}", Id_pattern.Oversized);
      ( String.concat "" (List.init 600 (fun _ -> "\xc3\xa9")),
        Id_pattern.Unmatched );
      ("a{0}", Id_pattern.Empty_id_fits);
      ("a?", Id_pattern.Empty_id_fits);
      ("a{0,}", Id_pattern.Empty_id_fits);
      ("a{0,3}", Id_pattern.Empty_id_fits);
      ("(a*)+", Id_pattern.Empty_id_fits);
      ("a|b*", Id_pattern.Empty_id_fits);
      ("(a?b?)", Id_pattern.Empty_id_fits);
      ("a{0}b{0}", Id_pattern.Empty_id_fits);
    ]

let id_patterns_that_are_valid () =
  List.iter
    (fun pattern ->
      Alcotest.(check bool)
        (Printf.sprintf "%S is valid" pattern)
        true
        (match Id_pattern.of_string pattern with
        | Ok accepted -> String.equal (Id_pattern.to_string accepted) pattern
        | Error _ -> false))
    [
      "[--]";
      "[-a-]";
      "[|]";
      "[*+?().$]";
      "[!\"$%&'()*+.:;<>?_`|~]";
      "%&'!\"-:;<>_`~";
      "a-b";
      "(a)";
      "((a))";
      "[a-a]";
      "[0-9a-fA-F]";
      "a{255}";
      "a{1,}";
      "a{0,0}b";
      "a{0}b";
      "((a|b){250}){2}";
      String.make 1000 'a';
      "(a|b)c";
      "(a?b?)c";
      "a|b|c";
    ]

let fit_cases () =
  List.iter
    (fun (pattern, id, want) ->
      match Id_pattern.of_string pattern with
      | Error _ -> Alcotest.failf "%S is a valid id pattern" pattern
      | Ok accepted ->
          Alcotest.(check bool)
            (Printf.sprintf "%S fits %S" id pattern)
            want
            (Id_pattern.fits accepted id))
    [
      ("a{2,3}", "aaa", true);
      ("a{2,3}", "a", false);
      ("x(a|bc)y", "xay", true);
      ("ab|cd", "abd", false);
      ("ab|cd", "cd", true);
      ("[a-c]", "b", true);
      ("[a-c]", "d", false);
      ("(a{2}){3}", "aaaaaa", true);
      ("(a{2}){3}", "aaaaa", false);
      ("[--]", "a", false);
      ("[-a-]", "-", true);
      ("[|]", "|", true);
      ("[|]", "a", false);
      ("[.]", ".", true);
      ("a-b", "a-b", true);
      ("a", "", false);
      ("a", "aa", false);
      ("[a-z]+", "\xc3\xa9", false);
      ("[a-z]+", "a\xff", false);
      ("(a|ab)c", "abc", true);
    ]

let fit_takes_no_exponential_time () =
  List.iter
    (fun (pattern, id) ->
      match Id_pattern.of_string pattern with
      | Error _ -> Alcotest.failf "%S is a valid id pattern" pattern
      | Ok accepted ->
          Alcotest.(check bool)
            (Printf.sprintf "%S does not fit" pattern)
            false
            (Id_pattern.fits accepted id))
    [
      ("(a*)*b", String.make 5000 'a' ^ "c");
      ("(a|aa)+b", String.make 5000 'a' ^ "c");
      ("(a|a)*b", String.make 5000 'a');
      ("((a+)+)+b", String.make 5000 'a');
      ("(a{0,255}){0,3}b", String.make 5000 'a');
    ]

let binding_cases () =
  List.iter
    (fun (pairs, want) ->
      Alcotest.(check bool)
        (String.concat ", "
           (List.map (fun (name, pattern) -> name ^ " " ^ pattern) pairs))
        true
        (match (Binding.make pairs, want) with
        | Ok _, None -> true
        | Error error, Some want -> error = want
        | _ -> false))
    [
      ([ ("a", "x") ], None);
      ([ ("a1", "x"); ("a-b", "x"); ("ab-c1-d", "x") ], None);
      ([ ("a-", "x") ], Some (Binding.Malformed_namespace_name "a-"));
      ([ ("-a", "x") ], Some (Binding.Malformed_namespace_name "-a"));
      ([ ("", "x") ], Some (Binding.Malformed_namespace_name ""));
      ([ ("a_b", "x") ], Some (Binding.Malformed_namespace_name "a_b"));
      ([ ("a/b", "x") ], Some (Binding.Malformed_namespace_name "a/b"));
      ([ ("\xc3\xa9", "x") ], Some (Binding.Malformed_namespace_name "\xc3\xa9"));
      ([ ("a\xff", "x") ], Some (Binding.Malformed_namespace_name "a\xff"));
      ( [ ("a", "x"); ("b", "y"); ("a", "x") ],
        Some (Binding.Repeated_namespace_name "a") );
      ( [ ("a", "^") ],
        Some
          (Binding.Invalid_id_pattern
             { namespace_name = "a"; error = Id_pattern.Unmatched }) );
      ( [ ("a", "[z-a]") ],
        Some
          (Binding.Invalid_id_pattern
             { namespace_name = "a"; error = Id_pattern.Reversed_range }) );
      ( [ ("a", "x{256}") ],
        Some
          (Binding.Invalid_id_pattern
             { namespace_name = "a"; error = Id_pattern.Large_count }) );
      ( [ ("a", "x{2,1}") ],
        Some
          (Binding.Invalid_id_pattern
             { namespace_name = "a"; error = Id_pattern.Reversed_bounds }) );
      ( [ ("a", "((a|b){250}){2}c") ],
        Some
          (Binding.Invalid_id_pattern
             { namespace_name = "a"; error = Id_pattern.Oversized }) );
      ( [ ("a", "[" ^ String.make 999 'x' ^ "]") ],
        Some
          (Binding.Invalid_id_pattern
             { namespace_name = "a"; error = Id_pattern.Too_long }) );
      ( [ ("b", "x"); ("a", "x?") ],
        Some
          (Binding.Invalid_id_pattern
             { namespace_name = "a"; error = Id_pattern.Empty_id_fits }) );
    ]

let binding_gives_its_pairs () =
  match Binding.make [ ("rfc", "[1-9][0-9]*"); ("gh", "[a-z]+") ] with
  | Error _ -> Alcotest.fail "the binding is valid"
  | Ok binding ->
      Alcotest.(check (list (pair string string)))
        "the pairs in code point order of their names"
        [ ("gh", "[a-z]+"); ("rfc", "[1-9][0-9]*") ]
        (List.map
           (fun (name, pattern) -> (name, Id_pattern.to_string pattern))
           (Binding.pairs binding));
      Alcotest.(check (option string))
        "the id pattern of gh" (Some "[a-z]+")
        (Option.map Id_pattern.to_string (Binding.id_pattern binding "gh"));
      Alcotest.(check (option string))
        "no id pattern of GH" None
        (Option.map Id_pattern.to_string (Binding.id_pattern binding "GH"));
      Alcotest.(check int)
        "the empty binding" 0
        (List.length (Binding.pairs Binding.empty));
      Alcotest.(check bool)
        "the order of the pairs has no effect" true
        (match Binding.make [ ("gh", "[a-z]+"); ("rfc", "[1-9][0-9]*") ] with
        | Ok other ->
            List.map fst (Binding.pairs other)
            = List.map fst (Binding.pairs binding)
        | Error _ -> false)

let concat = String.concat ""
let one_of list = Gen.oneof_list list
let chars text = List.map (String.make 1) (List.of_seq (String.to_seq text))

type atom =
  | Literal of string
  | Class of string * string list
  | Group of branch list

and piece = atom * (string * int * int) option
and branch = piece list

let literal_gen = one_of (chars "abcXYZ019-_%!:")

let class_gen =
  let open Gen in
  let* members =
    list_size (int_range 1 3)
      (one_of
         [
           ("a-c", [ "a"; "b"; "c" ]);
           ("0-5", [ "0"; "3"; "5" ]);
           ("A-C", [ "A"; "C" ]);
           (".", [ "." ]);
           ("+", [ "+" ]);
           ("*", [ "*" ]);
           ("|", [ "|" ]);
           ("(", [ "(" ]);
           ("$", [ "$" ]);
         ])
  and* dash = bool in
  let text = concat (List.map fst members) in
  let options = List.concat_map snd members in
  return
    (if dash then Class ("-" ^ text, "-" :: options) else Class (text, options))

let quantifier_gen =
  one_of
    [
      None;
      None;
      Some ("?", 0, 1);
      Some ("*", 0, 2);
      Some ("+", 1, 3);
      Some ("{2}", 2, 2);
      Some ("{0}", 0, 0);
      Some ("{1,}", 1, 3);
      Some ("{0,2}", 0, 2);
      Some ("{1,3}", 1, 3);
    ]

let rec pattern_gen depth = Gen.list_size (Gen.int_range 1 2) (branch_gen depth)

and branch_gen depth =
  Gen.list_size (Gen.int_range 1 3)
    (Gen.pair
       (if depth = 0 then
          Gen.oneof [ Gen.map (fun c -> Literal c) literal_gen; class_gen ]
        else
          Gen.oneof
            [
              Gen.map (fun c -> Literal c) literal_gen;
              class_gen;
              Gen.map (fun p -> Group p) (pattern_gen (depth - 1));
            ])
       quantifier_gen)

let rec render branches = String.concat "|" (List.map render_branch branches)

and render_branch pieces =
  concat
    (List.map
       (fun (atom, quantifier) ->
         (match atom with
           | Literal c -> c
           | Class (text, _) -> "[" ^ text ^ "]"
           | Group inner -> "(" ^ render inner ^ ")")
         ^ match quantifier with Some (text, _, _) -> text | None -> "")
       pieces)

let rec nullable branches = List.exists nullable_branch branches

and nullable_branch pieces =
  List.for_all
    (fun (atom, quantifier) ->
      (match quantifier with Some (_, low, _) -> low = 0 | None -> false)
      || match atom with Group inner -> nullable inner | _ -> false)
    pieces

let rec sample_gen branches = Gen.(oneof_list branches >>= sample_branch)

and sample_branch pieces =
  Gen.map concat (Gen.flatten_list (List.map sample_piece pieces))

and sample_piece (atom, quantifier) =
  let low, high =
    match quantifier with Some (_, low, high) -> (low, high) | None -> (1, 1)
  in
  Gen.(
    int_range low high >>= fun times ->
    map concat (flatten_list (List.init times (fun _ -> sample_atom atom))))

and sample_atom = function
  | Literal c -> Gen.return c
  | Class (_, options) -> one_of options
  | Group inner -> sample_gen inner

let valid_pattern_gen =
  Gen.map
    (fun branches ->
      if nullable branches then
        [ [ (Group branches, None); (Literal "x", None) ] ]
      else branches)
    (pattern_gen 2)

let pattern_and_id_gen =
  Gen.(
    valid_pattern_gen >>= fun branches ->
    pair (return (render branches)) (sample_gen branches))

let accepts text =
  match Id_pattern.of_string text with
  | Ok pattern -> Some pattern
  | Error _ -> None

(* @verifies identifiers#{accept-inputs=v1, decide-fit=v1} *)
let generated_patterns_are_valid_and_fit_their_ids =
  property ~count:1000
    ~name:
      "an id pattern made from the grammar is valid, and each id it makes fits"
    ~print:(fun (pattern, id) -> Printf.sprintf "%S %S" pattern id)
    pattern_and_id_gen
    (fun (text, id) ->
      match accepts text with
      | None -> false
      | Some pattern ->
          String.equal (Id_pattern.to_string pattern) text
          && Id_pattern.fits pattern id
          && not (Id_pattern.fits pattern ""))

(* @verifies identifiers#decide-fit=v1 *)
let ids_with_a_foreign_character_do_not_fit =
  property ~count:500
    ~name:
      "an id that holds a character that the id pattern never gives does not \
       fit"
    ~print:(fun ((pattern, id), at) -> Printf.sprintf "%S %S %d" pattern id at)
    Gen.(pair pattern_and_id_gen nat)
    (fun ((text, id), at) ->
      let at = at mod (String.length id + 1) in
      let id =
        String.sub id 0 at ^ "~" ^ String.sub id at (String.length id - at)
      in
      match accepts text with
      | None -> false
      | Some pattern -> not (Id_pattern.fits pattern id))

let pattern_bytes_gen =
  Gen.map concat
    (Gen.list_size (Gen.int_range 0 14)
       (one_of
          [
            "[";
            "]";
            "(";
            ")";
            "{";
            "}";
            ",";
            "|";
            "?";
            "*";
            "+";
            "-";
            "a";
            "z";
            "0";
            "9";
            "1";
            "255";
            "256";
            "^";
            "$";
            ".";
            "\\";
            "#";
            "/";
            "=";
            "@";
            " ";
            "\xc3\xa9";
            "\xff";
            "\x00";
            "~";
          ]))

(* @verifies identifiers#{reject-long-id-patterns=v1, reject-empty-id-fit=v1} *)
let id_pattern_answers_every_text =
  property ~count:2000
    ~name:
      "of_string gives a pattern or an error for every text, and never raises"
    ~print:(Printf.sprintf "%S")
    (Gen.oneof
       [ pattern_bytes_gen; Gen.string_size ~gen:Gen.char (Gen.int_range 0 20) ])
    (fun text ->
      match Id_pattern.of_string text with
      | Error _ -> true
      | Ok pattern ->
          String.equal (Id_pattern.to_string pattern) text
          && (not (Id_pattern.fits pattern ""))
          && String.length text <= 1000)

let namespace_name_matches text =
  let length = String.length text in
  let lower c = c >= 'a' && c <= 'z' in
  let digit c = c >= '0' && c <= '9' in
  length > 0
  && lower text.[0]
  && text.[length - 1] <> '-'
  &&
  let rec ok index =
    index >= length
    ||
    let c = text.[index] in
    (lower c || digit c || (c = '-' && text.[index - 1] <> '-'))
    && ok (index + 1)
  in
  ok 1

let binding_gen =
  Gen.list_size (Gen.int_range 0 4)
    (Gen.pair
       (one_of
          [
            "gh";
            "rfc";
            "a";
            "a-b";
            "a--b";
            "-a";
            "a-";
            "A";
            "9a";
            "";
            "a_b";
            "\xc3\xa9";
            "a1";
          ])
       (one_of
          [
            "[1-9][0-9]*";
            "x";
            "[0-9]*";
            "^";
            "[z-a]";
            "a{256}";
            "a{2,1}";
            "a?";
            "(a|b)+";
          ]))

(* @verifies identifiers#{reject-malformed-namespace-names=v1, reject-repeated-namespace-names=v1, reject-invalid-binding-patterns=v1, accept-inputs=v1} *)
let bindings_follow_their_pairs =
  property ~count:1000
    ~name:
      "a binding is valid when, and only when, its names are well formed and \
       distinct and its patterns valid"
    ~print:(fun pairs ->
      String.concat ", "
        (List.map
           (fun (name, pattern) -> Printf.sprintf "%S %S" name pattern)
           pairs))
    (Gen.oneof
       [
         binding_gen;
         Gen.list_size (Gen.int_range 0 3)
           (Gen.pair
              (Gen.string_size ~gen:Gen.char (Gen.int_range 0 4))
              (Gen.string_size ~gen:Gen.char (Gen.int_range 0 6)));
       ])
    (fun pairs ->
      let names = List.map fst pairs in
      let want =
        List.for_all namespace_name_matches names
        && List.length (List.sort_uniq String.compare names) = List.length names
        && List.for_all
             (fun (_, pattern) -> Option.is_some (accepts pattern))
             pairs
      in
      match Binding.make pairs with
      | Ok binding ->
          want
          && List.map fst (Binding.pairs binding)
             = List.sort String.compare names
          && List.for_all
               (fun (name, pattern) ->
                 Option.map Id_pattern.to_string
                   (Binding.id_pattern binding name)
                 = Some pattern)
               pairs
      | Error _ -> not want)

let vector_groups = [ id_pattern_vectors; fit_vectors; binding_vectors ]

let tests =
  Vectors.tests "identifiers" vector_groups
  @ [
      Alcotest.test_case "id patterns give the error of their one fault" `Quick
        id_pattern_errors;
      Alcotest.test_case "id patterns that the grammar allows are valid" `Quick
        id_patterns_that_are_valid;
      Alcotest.test_case "ids fit id patterns" `Quick fit_cases;
      Alcotest.test_case "fit takes no exponential time" `Quick
        fit_takes_no_exponential_time;
      Alcotest.test_case "bindings give the error of their bad pair" `Quick
        binding_cases;
      Alcotest.test_case "a binding gives its pairs" `Quick
        binding_gives_its_pairs;
      generated_patterns_are_valid_and_fit_their_ids;
      ids_with_a_foreign_character_do_not_fit;
      id_pattern_answers_every_text;
      bindings_follow_their_pairs;
    ]
