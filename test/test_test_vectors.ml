(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
open Sinter_test_vectors
module Gen = QCheck2.Gen
module V = Vector_json

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let rec basic_of_json : Json.t -> Yojson.Basic.t = function
  | Json.String text -> `String (Text.encode text)
  | Json.Integer number -> `Int number
  | Json.Boolean value -> `Bool value
  | Json.Array elements -> `List (List.map basic_of_json elements)
  | Json.Object members ->
      `Assoc
        (List.map
           (fun (name, value) -> (Text.encode name, basic_of_json value))
           members)

let canonical_of_json value = V.canonical (V.of_basic (basic_of_json value))

let text_of bytes =
  match Text.decode bytes with
  | Ok text -> text
  | Error _ -> invalid_arg "text_of"

let test_vectors_set = Vectors.read "data-forms.test-vectors"

let give_read_set (vector : Vectors.vector) =
  let bytes =
    match vector.input with
    | `String digits -> V.of_hex digits
    | other -> Alcotest.failf "not a string: %s" (Yojson.Basic.to_string other)
  in
  match Test_vector_set.read bytes with
  | Some set ->
      `Assoc
        [
          ("result", `String "valid");
          ( "values",
            `Assoc [ ("objects", `List (List.map basic_of_json set.objects)) ]
          );
        ]
  | None -> `Assoc [ ("result", `String "invalid"); ("values", `Assoc []) ]

(* @verifies data-forms#test-vectors[read-set][*]=v1
   read gives a result for every byte sequence; the test fails when that
   result, or the objects that read gives, differ from the result and the
   objects of a vector. *)
let read_set_vectors =
  Vectors.group test_vectors_set ~name:"read-set" ~rev:"v1" give_read_set

let library_version (version : Set_model.version) =
  match Test_vector_set.read (Set_model.write version.objects) with
  | None ->
      Alcotest.failf "not a test-vector set: %s"
        (Set_model.print_version version)
  | Some set -> (
      match
        Version_sequence.version set
          (List.map (fun (name, forms) -> (name, text_of forms)) version.forms)
      with
      | Ok version -> version
      | Error _ ->
          Alcotest.failf "the forms do not fit: %s"
            (Set_model.print_version version))

let model_version (json : Yojson.Basic.t) : Set_model.version =
  match json with
  | `Assoc members -> (
      match (List.assoc_opt "set" members, List.assoc_opt "forms" members) with
      | Some (`List objects), Some (`Assoc forms) ->
          {
            objects = List.map V.of_basic objects;
            forms =
              List.map
                (function
                  | name, `String text -> (name, text)
                  | name, _ ->
                      Alcotest.failf "the forms of %s are no string" name)
                forms;
          }
      | _ -> Alcotest.failf "not a version: %s" (Yojson.Basic.to_string json))
  | _ -> Alcotest.failf "not a version: %s" (Yojson.Basic.to_string json)

let give_validate_sequence (vector : Vectors.vector) =
  let versions =
    match vector.input with
    | `List versions -> List.map model_version versions
    | other -> Alcotest.failf "not an array: %s" (Yojson.Basic.to_string other)
  in
  let valid = Version_sequence.validate (List.map library_version versions) in
  `Assoc [ ("result", `String (if valid then "valid" else "invalid")) ]

(* @verifies data-forms#test-vectors[validate-sequence][*]=v1
   The test fails when validate gives a result other than the result of a
   vector for its sequence of versions. *)
let validate_sequence_vectors =
  Vectors.group test_vectors_set ~name:"validate-sequence" ~rev:"v1"
    give_validate_sequence

let text value = V.String (V.Text value)

let revision_gen =
  Gen.map
    (fun number -> "v" ^ string_of_int number)
    (Gen.oneof [ Gen.int_range 1 12; Gen.oneof_list [ 99; 100; 123456789 ] ])

let group_name_gen =
  Gen.oneof_list [ "a"; "b"; "g-2"; "a1"; "read-set"; "z9-x" ]

let vector_gen =
  let open Gen in
  let* group = group_name_gen in
  let* revision = revision_gen in
  let* input = V.value_gen in
  let* shape = int_range 0 2 in
  let* result = oneof_list [ "valid"; "invalid"; "" ] in
  let* values = V.value_gen in
  let* note = option V.text_gen in
  let* needs =
    option (oneof_list [ [ "b" ]; [ "a-1"; "b" ]; [ "no-privilege" ] ])
  in
  return (fun n ->
      V.Object
        (List.filter_map Fun.id
           [
             Some (V.Text "n", V.Number (string_of_int n));
             Some (V.Text "rev", text revision);
             Some (V.Text "group", text group);
             Some (V.Text "input", input);
             (if shape = 1 then None else Some (V.Text "result", text result));
             (if shape = 0 then None else Some (V.Text "values", values));
             Option.map (fun note -> (V.Text "note", text note)) note;
             Option.map
               (fun needs -> (V.Text "needs", V.Array (List.map text needs)))
               needs;
           ]))

let group_of = function
  | V.Object members -> (
      match List.assoc_opt (V.Text "group") members with
      | Some (V.String (V.Text name)) -> name
      | _ -> "")
  | _ -> ""

let set_objects_gen =
  let open Gen in
  let* set_revision = revision_gen in
  let* makers = list_size (int_range 0 6) vector_gen in
  let* gaps = list_size (return (List.length makers)) (int_range 1 3) in
  let* group_revisions = list_size (return 6) revision_gen in
  let numbers =
    List.rev
      (snd
         (List.fold_left
            (fun (last, numbers) gap -> (last + gap, (last + gap) :: numbers))
            (0, []) gaps))
  in
  let vectors = List.map2 (fun make n -> make n) makers numbers in
  let groups = List.sort_uniq V.compare_keys (List.map group_of vectors) in
  return
    (V.Object [ (V.Text "rev", text set_revision) ]
     :: List.mapi
          (fun index name ->
            V.Object
              [
                (V.Text "group", text name);
                (V.Text "rev", text (List.nth group_revisions index));
              ])
          groups
    @ vectors)

let print_objects objects = V.hex (Set_model.write objects)

let same_objects (set : Test_vector_set.t) objects =
  List.map canonical_of_json set.objects = List.map V.canonical objects

(* @verifies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1}
   The test fails when read gives "invalid" for a generated test-vector
   set, or objects other than all the objects of its lines, each once and
   in their order. *)
let read_gives_the_objects_of_each_set =
  property
    ~name:"read gives the objects of each test-vector set, in their order"
    ~print:print_objects set_objects_gen (fun objects ->
      match Test_vector_set.read (Set_model.write objects) with
      | Some set -> same_objects set objects
      | None -> false)

let line_corruption_gen objects =
  let lines = List.map (fun object_ -> Set_model.write [ object_ ]) objects in
  let count = List.length lines in
  let open Gen in
  let* first = int_range 0 (max 0 (count - 1)) in
  let* second = int_range 0 (max 0 (count - 1)) in
  let* kind = int_range 0 5 in
  let* replacement =
    oneof_list
      [
        "\n";
        "{}\n";
        "{\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"rev\":\"v1\"}\n";
        "{\"rev\":\"v1\"}\r\n";
        "[1]\n";
        "\"a\"\n";
        "1\n";
        "true\n";
        "{\"rev\":1}\n";
        "{\"rev\":true}\n";
        "{\"group\":1,\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"rev\":[]}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":true,\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"result\":[],\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"note\":{},\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"needs\":{},\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"needs\":[true],\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"needs\":[\"b\"],\"rev\":\"v1\",\"values\":1}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"n\":9,\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"group\":true,\"input\":1,\"n\":9,\"result\":\"valid\",\"rev\":\"v1\"}\n";
        "{\"group\":\"a\",\"input\":1,\"n\":9,\"result\":\"valid\",\"rev\":5}\n";
      ]
  in
  let indexed = List.mapi (fun index line -> (index, line)) lines in
  let lines =
    match kind with
    | 0 ->
        List.map
          (fun (index, line) ->
            if index = first then List.nth lines second
            else if index = second then List.nth lines first
            else line)
          indexed
    | 1 ->
        List.concat_map
          (fun (index, line) ->
            if index = first then [ line; line ] else [ line ])
          indexed
    | 2 ->
        List.filter_map
          (fun (index, line) -> if index = first then None else Some line)
          indexed
    | 3 ->
        List.concat_map
          (fun (index, line) ->
            if index = first then [ replacement; line ] else [ line ])
          indexed
    | 4 -> lines @ [ replacement ]
    | _ ->
        List.map
          (fun (index, line) -> if index = first then replacement else line)
          indexed
  in
  return (String.concat "" lines)

let corrupted_set_gen =
  Gen.(
    set_objects_gen >>= fun objects ->
    oneof
      [ V.corrupt_gen (Set_model.write objects); line_corruption_gen objects ])

(* @verifies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1}
   The test changes test-vector sets by a byte or a line, and fails when
   read gives "valid" and objects for a byte sequence that is not a
   test-vector set, "invalid" for one that is, or objects other than those
   of its lines. *)
let read_accepts_exactly_the_sets =
  property ~count:2000
    ~name:
      "read accepts a byte sequence when, and only when, it is a test-vector \
       set"
    ~print:V.hex corrupted_set_gen (fun bytes ->
      match (Test_vector_set.read bytes, Set_model.read bytes) with
      | Some set, Some objects -> same_objects set objects
      | None, None -> true
      | _ -> false)

(* @verifies data-forms#{read-test-vector-set=v1, give-objects-of-test-vector-sets=v1}
   The test gives any bytes, and bytes after a set line, and fails when
   read gives "valid" and objects for a byte sequence that is not a
   test-vector set, "invalid" for one that is, or objects other than those
   of its lines. *)
let read_answers_any_bytes =
  property ~count:1000 ~name:"read gives a set or nothing for any bytes"
    ~print:V.hex
    (Gen.oneof
       [
         Gen.string_size ~gen:Gen.char (Gen.int_range 0 40);
         Gen.map
           (fun tail -> "{\"rev\":\"v1\"}\n" ^ tail)
           (Gen.string_size ~gen:V.byte_gen (Gen.int_range 0 40));
       ])
    (fun bytes ->
      match Test_vector_set.read bytes with
      | Some set -> (
          match Set_model.read bytes with
          | Some objects -> same_objects set objects
          | None -> false)
      | None -> Option.is_none (Set_model.read bytes))

let member name = function
  | V.Object members -> List.assoc_opt (V.Text name) members
  | _ -> None

let text_member name object_ =
  match member name object_ with
  | Some (V.String (V.Text value)) -> Some value
  | _ -> None

let vector_fits (vector : Test_vector_set.vector) object_ =
  let json_fits value thing = canonical_of_json value = V.canonical thing in
  let option_fits fits value thing =
    match (value, thing) with
    | Some value, Some thing -> fits value thing
    | None, None -> true
    | _ -> false
  in
  member "n" object_ = Some (V.Number (string_of_int vector.number))
  && text_member "rev" object_ = Some (vector.revision :> string)
  && text_member "group" object_ = Some vector.group
  && option_fits json_fits (Some vector.input) (member "input" object_)
  && option_fits json_fits vector.values (member "values" object_)
  && Option.map Text.encode vector.result = text_member "result" object_
  && Option.map Text.encode vector.note = text_member "note" object_
  &&
  match member "needs" object_ with
  | Some (V.Array names) ->
      List.map (fun name -> Some name) vector.needs
      = List.map
          (function V.String (V.Text name) -> Some name | _ -> None)
          names
  | None -> vector.needs = []
  | Some _ -> false

let fields_describe_the_lines =
  property ~name:"the fields of a set describe its lines" ~print:print_objects
    set_objects_gen (fun objects ->
      match Test_vector_set.read (Set_model.write objects) with
      | None -> false
      | Some set -> (
          match objects with
          | [] -> false
          | set_object :: rest ->
              let groups =
                List.filteri
                  (fun index _ -> index < List.length set.groups)
                  rest
              in
              let vectors =
                List.filteri
                  (fun index _ -> index >= List.length set.groups)
                  rest
              in
              text_member "rev" set_object = Some (set.revision :> string)
              && List.length vectors = List.length set.vectors
              && List.for_all2
                   (fun (group : Test_vector_set.group) object_ ->
                     text_member "group" object_ = Some group.name
                     && text_member "rev" object_
                        = Some (group.revision :> string))
                   set.groups groups
              && List.for_all2 vector_fits set.vectors vectors))

let revision_of digits =
  match Test_vector_set.read (Printf.sprintf "{\"rev\":\"v%s\"}\n" digits) with
  | Some set -> set.revision
  | None -> Alcotest.failf "v%s is no revision" digits

let digits_gen =
  Gen.map2
    (fun first rest -> String.make 1 first ^ rest)
    (Gen.char_range '1' '9')
    (Gen.string_size ~gen:(Gen.char_range '0' '9') (Gen.int_range 0 30))

let compare_revisions_compares_the_numbers =
  property ~count:1000
    ~name:"compare_revisions compares the numbers of the revisions"
    ~print:(fun (a, b) -> a ^ " / " ^ b)
    Gen.(oneof [ pair digits_gen digits_gen; map (fun a -> (a, a)) digits_gen ])
    (fun (a, b) ->
      let sign number = compare number 0 in
      sign (Test_vector_set.compare_revisions (revision_of a) (revision_of b))
      = sign (compare (String.length a, a) (String.length b, b)))

let depth = 100_000
let deep_input () = String.make depth '[' ^ "1" ^ String.make depth ']'

let deep_sets_need_no_deep_stack () =
  let head =
    "{\"rev\":\"v1\"}\n\
     {\"group\":\"a\",\"rev\":\"v1\"}\n\
     {\"group\":\"a\",\"input\":"
  in
  let tail = ",\"n\":1,\"result\":\"valid\",\"rev\":\"v1\"}\n" in
  let deep = head ^ deep_input () ^ tail in
  let unclosed = head ^ String.make depth '[' ^ tail in
  let read_deep, read_unclosed =
    Small_stack.run (fun () ->
        (Test_vector_set.read deep, Test_vector_set.read unclosed))
  in
  Alcotest.(check bool)
    "the deep set" true
    (match read_deep with
    | Some { vectors = [ vector ]; _ } ->
        String.equal (Json.canonical_byte_sequence vector.input) (deep_input ())
    | _ -> false);
  Alcotest.(check bool) "the unclosed set" true (Option.is_none read_unclosed)

let print_sequence versions =
  String.concat "\n" (List.map Set_model.print_version versions)

(* @verifies data-forms#validate-version-sequences=v1
   The test fails when validate gives "invalid" for a generated version
   sequence, whose revisions rise by the rules. *)
let validate_takes_each_version_sequence =
  property ~count:500 ~name:"validate takes each version sequence"
    ~print:print_sequence Set_model.sequence_gen (fun versions ->
      Version_sequence.validate (List.map library_version versions))

let set_revision objects index change =
  List.mapi
    (fun at object_ ->
      if at <> index then object_
      else
        match object_ with
        | V.Object members ->
            V.Object
              (List.map
                 (function
                   | (V.Text "rev", V.String (V.Text revision)) as member ->
                       let number =
                         int_of_string
                           (String.sub revision 1 (String.length revision - 1))
                       in
                       let number = change number in
                       if number >= 1 then
                         (V.Text "rev", text ("v" ^ string_of_int number))
                       else member
                   | V.Text "input", _ when change 0 = 0 ->
                       (V.Text "input", text "changed")
                   | member -> member)
                 members)
        | other -> other)
    objects

let perturbed_gen =
  let open Gen in
  let* versions = Set_model.sequence_gen in
  let* which = int_range 0 (List.length versions - 1) in
  let* line = nat in
  let* kind = int_range 0 4 in
  let perturb (version : Set_model.version) =
    let index = line mod List.length version.objects in
    match kind with
    | 0 -> { version with objects = set_revision version.objects index succ }
    | 1 -> { version with objects = set_revision version.objects index pred }
    | 2 ->
        {
          version with
          objects = set_revision version.objects index (fun n -> n + 9);
        }
    | 3 ->
        {
          version with
          objects = set_revision version.objects index (fun _ -> 0);
        }
    | _ ->
        {
          version with
          forms =
            List.map
              (fun (name, forms) ->
                (name, if index mod 2 = 0 then forms ^ " changed" else forms))
              version.forms;
        }
  in
  return
    (List.mapi
       (fun at version -> if at = which then perturb version else version)
       versions)

(* @verifies data-forms#validate-version-sequences=v1
   The test changes a revision, an input, or the forms of a version
   sequence, and fails when validate does not give "valid" exactly when
   the result is still a version sequence. *)
let validate_takes_exactly_the_version_sequences =
  property ~count:1000
    ~name:
      "validate takes a sequence of versions when, and only when, it is a \
       version sequence"
    ~print:print_sequence
    (Gen.oneof
       [
         perturbed_gen; Gen.list_size (Gen.int_range 0 3) Set_model.version_gen;
       ])
    (fun versions ->
      Version_sequence.validate (List.map library_version versions)
      = Set_model.is_version_sequence versions)

let forms_gen =
  let open Gen in
  let* objects = set_objects_gen in
  let groups =
    List.sort_uniq V.compare_keys (List.map group_of (List.tl objects))
  in
  let groups = List.filter (fun name -> name <> "") groups in
  let* names =
    list_size (int_range 0 5) (oneof_list ([ "a"; "b"; "x" ] @ groups))
  in
  let* exact = bool in
  return (objects, if exact then groups else names)

let version_checks_the_forms =
  property ~count:1000
    ~name:"version refuses forms of other groups, then a group with no forms"
    ~print:(fun (objects, names) ->
      print_objects objects ^ " / " ^ String.concat "," names)
    forms_gen
    (fun (objects, names) ->
      match Test_vector_set.read (Set_model.write objects) with
      | None -> false
      | Some set ->
          let groups =
            List.map
              (fun (group : Test_vector_set.group) -> group.name)
              set.groups
          in
          let rec first_extra seen = function
            | [] -> None
            | name :: rest ->
                if List.mem name seen || not (List.mem name groups) then
                  Some name
                else first_extra (name :: seen) rest
          in
          let want =
            match first_extra [] names with
            | Some name -> Error (Version_sequence.Extra_forms name)
            | None -> (
                match
                  List.find_opt (fun name -> not (List.mem name names)) groups
                with
                | Some name -> Error (Version_sequence.Missing_forms name)
                | None -> Ok ())
          in
          let have =
            Result.map ignore
              (Version_sequence.version set
                 (List.map (fun name -> (name, text_of "forms")) names))
          in
          have = want)

let vector_groups = [ read_set_vectors; validate_sequence_vectors ]

let tests =
  Vectors.tests "data-forms.test-vectors" vector_groups
  @ [
      Vectors.covers "data-forms.test-vectors" test_vectors_set vector_groups;
      Alcotest.test_case "deep sets need no deep stack" `Quick
        deep_sets_need_no_deep_stack;
      read_gives_the_objects_of_each_set;
      read_accepts_exactly_the_sets;
      read_answers_any_bytes;
      fields_describe_the_lines;
      compare_revisions_compares_the_numbers;
      validate_takes_each_version_sequence;
      validate_takes_exactly_the_version_sequences;
      version_checks_the_forms;
    ]
