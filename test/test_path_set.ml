(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Test_path
open Test_glob_fit
module Gen = QCheck2.Gen
module Path_set = Sinter_paths.Path_set

let valid_set members =
  match Path_set.of_texts members with
  | Error _ -> Alcotest.fail "a glob text is not a valid glob"
  | Ok set -> (
      match Path_set.validate set with
      | Ok valid -> valid
      | Error _ -> Alcotest.fail "the path set is not valid")

let is_valid_path_set members =
  match Path_set.of_texts members with
  | Ok set -> Result.is_ok (Path_set.validate set)
  | Error _ -> false

let in_set ~path members = Path_set.mem (valid_set members) (valid_path path)

let json_texts = function
  | `List members ->
      List.map (fun member -> text_of (json_string member)) members
  | other ->
      Alcotest.failf "not a JSON array: %s" (Yojson.Basic.to_string other)

let give_path_set (vector : Vectors.vector) =
  either (is_valid_path_set (json_texts vector.input)) "valid" "invalid"

let give_membership (vector : Vectors.vector) =
  let path = text_of (json_string (json_member "path" vector.input)) in
  let members = json_texts (json_member "path-set" vector.input) in
  either (in_set ~path members) "in the set" "not in the set"

(* @verifies files[path-sets]
   The vectors check "valid" and "invalid" for path sets. *)
let path_set_vectors =
  Vectors.group files_set ~name:"path-sets" ~form:"#path-set-vector=v1"
    give_path_set

(* @verifies files[memberships]
   The vectors check "in the set" and "not in the set" for a valid path and a
   valid path set. *)
let membership_vectors =
  Vectors.group files_set ~name:"memberships" ~form:"#membership-vector=v1"
    give_membership

let member_gen =
  Gen.map2
    (fun bang glob -> if bang then uchars_of_string "!" @ glob else glob)
    (Gen.oneof_weighted [ (3, Gen.return false); (1, Gen.return true) ])
    glob_gen

let dedup members =
  List.fold_left
    (fun kept member ->
      if List.mem member kept then kept else kept @ [ member ])
    [] members

let valid_path_set_gen =
  Gen.oneof_weighted
    [
      (1, Gen.return []);
      ( 5,
        Gen.map2
          (fun plain rest -> dedup (plain :: rest))
          glob_gen
          (Gen.list_size (Gen.int_bound 4) member_gen) );
    ]

let any_member_gen = Gen.oneof [ member_gen; text_gen ]

let print_members members =
  "[" ^ String.concat "; " (List.map print_text members) ^ "]"

(* @verifies files#validate-path-sets=v1
   A validation that differed from valid-path-set for a generated path set,
   repeated members included, fails the comparison with a direct reading of
   the term. *)
let validation_of_path_sets_follows_the_term =
  property ~count:1000 ~name:"a path set is valid as valid-path-set says"
    ~print:print_members
    (Gen.oneof
       [
         Gen.list_size (Gen.int_bound 4) any_member_gen;
         Gen.map
           (fun members -> members @ members)
           (Gen.list_size (Gen.int_range 1 2) member_gen);
       ])
    (fun members ->
      Bool.equal
        (is_valid_path_set (List.map of_uchars members))
        (Paths_reference.is_valid_path_set members))

let print_membership (path, members) =
  Printf.sprintf "path %s, path set %s" (print_text path)
    (print_members members)

(* @verifies files#decide-path-set-membership=v1
   A decision that differed from path-set-membership for a generated valid
   path and valid path set fails the comparison with a direct reading of the
   atom. *)
let membership_follows_the_atom =
  property ~count:1000
    ~name:"a valid path is in the set as path-set-membership says"
    ~print:print_membership (Gen.pair path_gen valid_path_set_gen)
    (fun (path, members) ->
      Bool.equal
        (in_set ~path:(of_uchars path) (List.map of_uchars members))
        (Paths_reference.in_set ~path members))

let order_does_not_change_the_set =
  property ~name:"the order of the path set members does not change the set"
    ~print:print_membership (Gen.pair path_gen valid_path_set_gen)
    (fun (path, members) ->
      Bool.equal
        (in_set ~path:(of_uchars path) (List.map of_uchars members))
        (in_set ~path:(of_uchars path) (List.rev_map of_uchars members)))

let empty_set_holds_no_path =
  property ~name:"no valid path is in the set of the empty path set"
    ~print:print_text path_gen (fun path ->
      not (in_set ~path:(of_uchars path) []))

let member_number members =
  let rec go number = function
    | [] -> None
    | member :: rest ->
        if Paths_reference.is_glob (Paths_reference.glob_text member) then
          go (number + 1) rest
        else Some number
  in
  go 1 members

let repeated members =
  let indexed = List.mapi (fun index member -> (index + 1, member)) members in
  List.find_map
    (fun (second, member) ->
      List.find_map
        (fun (first, other) ->
          if first < second && other = member then Some (first, second)
          else None)
        indexed)
    indexed

(* @verifies conformance#reject-invalid-inputs=v1
   A path set that is not valid gives no valid path set for membership and
   names the invalid member or fault of lowest number. *)
let path_set_names_its_first_fault =
  property ~count:1000
    ~name:"a path set names its member or its fault of the lowest number"
    ~print:print_members
    (Gen.oneof
       [
         Gen.list_size (Gen.int_bound 4) any_member_gen;
         Gen.map
           (fun members -> members @ List.rev members)
           (Gen.list_size (Gen.int_range 1 3) member_gen);
         Gen.list_size (Gen.int_range 1 3)
           (Gen.map (fun glob -> uchars_of_string "!" @ glob) glob_gen);
       ])
    (fun members ->
      match Path_set.of_texts (List.map of_uchars members) with
      | Error { member; _ } -> member_number members = Some member
      | Ok set -> (
          member_number members = None
          &&
          match (Path_set.validate set, repeated members) with
          | Error (Path_set.Repeated_member { first; second }), Some pair ->
              pair = (first, second)
          | Error Path_set.No_plain_member, None ->
              members <> []
              && List.for_all
                   (fun member ->
                     List.length (Paths_reference.glob_text member)
                     < List.length member)
                   members
          | Ok _, None -> Paths_reference.is_valid_path_set members
          | _ -> false))

(* @verifies conformance#reject-invalid-inputs=v1
   Each path set that is not valid, such as a repeated member, only bang
   members, or a bad glob, is rejected with its fault and gives no valid path
   set for membership. *)
let invalid_path_sets_are_rejected () =
  let check_fault name texts expected =
    match Path_set.of_texts (List.map text_of texts) with
    | Error _ -> Alcotest.failf "%s: expected valid globs" name
    | Ok set ->
        Alcotest.(check bool)
          name true
          (match Path_set.validate set with
          | Error found -> found = expected
          | Ok _ -> false)
  in
  check_fault "repeated member" [ "a/"; "a/" ]
    (Path_set.Repeated_member { first = 1; second = 2 });
  check_fault "repeated non-adjacent member" [ "a/"; "!b/"; "a/" ]
    (Path_set.Repeated_member { first = 1; second = 3 });
  check_fault "only bang members" [ "!a/" ] Path_set.No_plain_member;
  check_fault "repeated bang members report repetition first" [ "!a/"; "!a/" ]
    (Path_set.Repeated_member { first = 1; second = 2 });
  match Path_set.of_texts (List.map text_of [ "a/"; "docs/**.md" ]) with
  | Error { member; error } ->
      Alcotest.(check int) "bad glob member" 2 member;
      Alcotest.(check bool)
        "bad glob error" true
        (error = Sinter_paths.Glob.Adjacent_stars 2)
  | Ok _ -> Alcotest.fail "bad glob was accepted"

let vector_groups = [ path_set_vectors; membership_vectors ]

let tests =
  Vectors.tests "files" vector_groups
  @ [
      validation_of_path_sets_follows_the_term;
      membership_follows_the_atom;
      order_does_not_change_the_set;
      empty_set_holds_no_path;
      path_set_names_its_first_fault;
      Alcotest.test_case "invalid path sets are rejected with their fault"
        `Quick invalid_path_sets_are_rejected;
    ]
