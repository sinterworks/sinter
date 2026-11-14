(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type vector = {
  number : int;
  group : string;
  input : Yojson.Basic.t;
  result : string option;
  values : Yojson.Basic.t option;
  needs : string list;
}

type t = {
  revision : string;
  groups : (string * string) list;
  vectors : vector list;
}

let path design =
  Filename.concat "../docs/designs" (design ^ ".test-vectors.jsonl")

let fail_at design line format =
  Printf.ksprintf
    (fun message ->
      failwith (Printf.sprintf "%s line %d: %s" design line message))
    format

let member name fields = List.assoc_opt name fields

let only_members design line allowed fields =
  List.iter
    (fun (name, _) ->
      if not (List.mem name allowed) then
        fail_at design line "an unknown member %s" name)
    fields

let string_member design line name fields =
  match member name fields with
  | Some (`String text) -> text
  | _ -> fail_at design line "no string member %s" name

let read design =
  let content = In_channel.with_open_bin (path design) In_channel.input_all in
  let lines = String.split_on_char '\n' content in
  let lines =
    match List.rev lines with
    | "" :: rest -> List.rev rest
    | _ -> fail_at design (List.length lines) "the file does not end with LF"
  in
  let objects =
    List.mapi
      (fun index line ->
        let number = index + 1 in
        match Yojson.Basic.from_string line with
        | `Assoc fields -> (number, fields)
        | _ -> fail_at design number "not a JSON object"
        | exception Yojson.Json_error message ->
            fail_at design number "not JSON: %s" message)
      lines
  in
  match objects with
  | [] -> fail_at design 1 "no set line"
  | (number, set) :: rest ->
      if List.length set <> 1 then fail_at design number "not the set line";
      let revision = string_member design number "rev" set in
      let rec read_groups groups = function
        | (number, fields) :: rest when not (List.mem_assoc "n" fields) ->
            only_members design number [ "group"; "rev" ] fields;
            let name = string_member design number "group" fields in
            if List.mem_assoc name groups then
              fail_at design number "a second group line for %s" name;
            let rev = string_member design number "rev" fields in
            read_groups ((name, rev) :: groups) rest
        | rest -> (List.rev groups, rest)
      in
      let groups, rest = read_groups [] rest in
      let _, vectors =
        List.fold_left
          (fun (last, vectors) (line, fields) ->
            only_members design line
              [
                "n";
                "rev";
                "group";
                "input";
                "result";
                "values";
                "note";
                "needs";
              ]
              fields;
            let number =
              match member "n" fields with
              | Some (`Int number) -> number
              | _ -> fail_at design line "no member n"
            in
            if number <= last then fail_at design line "n does not rise";
            ignore (string_member design line "rev" fields);
            let group = string_member design line "group" fields in
            if not (List.mem_assoc group groups) then
              fail_at design line "the group %s has no group line" group;
            let input =
              match member "input" fields with
              | Some input -> input
              | None -> fail_at design line "no member input"
            in
            let values = member "values" fields in
            let result =
              match member "result" fields with
              | Some (`String result) -> Some result
              | None -> None
              | Some _ -> fail_at design line "a result that is not a string"
            in
            if result = None && values = None then
              fail_at design line "neither result nor values";
            let needs =
              match member "needs" fields with
              | None -> []
              | Some (`List names) ->
                  List.map
                    (function
                      | `String name -> name
                      | _ -> fail_at design line "a need that is not a string")
                    names
              | Some _ -> fail_at design line "needs that are not an array"
            in
            (number, { number; group; input; result; values; needs } :: vectors))
          (0, []) rest
      in
      { revision; groups; vectors = List.rev vectors }

let revision set = set.revision
let count set = List.length set.vectors
let group_names set = List.map fst set.groups

let rec normal = function
  | `Assoc fields ->
      `Assoc
        (List.sort
           (fun (a, _) (b, _) -> String.compare a b)
           (List.map (fun (key, value) -> (key, normal value)) fields))
  | `List items -> `List (List.map normal items)
  | other -> other

let equal_json a b = normal a = normal b

type group_test = { name : string; test : unit -> unit }

let expected vector =
  let result =
    Option.to_list
      (Option.map (fun result -> ("result", `String result)) vector.result)
  in
  `Assoc
    (result @ Option.to_list (Option.map (fun v -> ("values", v)) vector.values))

let compared vector = function
  | `Assoc fields ->
      `Assoc
        (List.filter
           (fun (key, _) ->
             not
               ((key = "values" && vector.values = None)
               || (key = "result" && vector.result = None)))
           fields)
  | other -> other

let print_skips skips =
  String.concat "; "
    (List.map
       (fun (number, needs) ->
         Printf.sprintf "vector %d needs %s" number (String.concat ", " needs))
       skips)

let group set ~name ~rev ?(needs = []) ?(skipped = []) give =
  let test () =
    (match List.assoc_opt name set.groups with
    | Some found when String.equal found rev -> ()
    | Some found ->
        Alcotest.failf "the group %s has the revision %s, not %s" name found rev
    | None -> Alcotest.failf "the file has no group %s" name);
    let vectors =
      List.filter (fun vector -> String.equal vector.group name) set.vectors
    in
    if vectors = [] then Alcotest.failf "the group %s holds no vector" name;
    let skips =
      List.filter_map
        (fun vector ->
          match
            List.filter
              (fun need -> List.assoc_opt need needs = Some false)
              vector.needs
          with
          | [] -> None
          | unmet -> Some (vector.number, unmet))
        vectors
    in
    List.iter
      (fun (number, needs) ->
        Printf.printf "vector %d of %s skipped: it needs %s\n" number name
          (String.concat ", " needs))
      skips;
    if skips <> skipped then
      Alcotest.failf "the group %s skips %s, not %s" name
        (if skips = [] then "no vector" else print_skips skips)
        (if skipped = [] then "no vector" else print_skips skipped);
    let vectors =
      List.filter
        (fun vector -> not (List.mem_assoc vector.number skips))
        vectors
    in
    let failures =
      List.filter_map
        (fun vector ->
          let want = expected vector in
          match compared vector (give vector) with
          | have when equal_json want have -> None
          | have ->
              Some
                (Printf.sprintf
                   "vector %d of %s\n  input: %s\n  want:  %s\n  have:  %s"
                   vector.number name
                   (Yojson.Basic.to_string vector.input)
                   (Yojson.Basic.to_string (normal want))
                   (Yojson.Basic.to_string (normal have)))
          | exception error ->
              Some
                (Printf.sprintf "vector %d of %s\n  input: %s\n  raised: %s"
                   vector.number name
                   (Yojson.Basic.to_string vector.input)
                   (Printexc.to_string error)))
        vectors
    in
    match failures with
    | [] -> ()
    | failures ->
        Alcotest.failf "%d of %d vectors fail:\n%s" (List.length failures)
          (List.length vectors)
          (String.concat "\n" failures)
  in
  { name; test }

let vectors set name =
  List.filter (fun vector -> String.equal vector.group name) set.vectors

let tests design groups =
  List.map
    (fun group ->
      Alcotest.test_case
        (Printf.sprintf "%s vectors of the group %s" design group.name)
        `Quick group.test)
    groups

let covers design set groups =
  Alcotest.test_case
    (Printf.sprintf "%s vectors have a test for each group" design) `Quick
    (fun () ->
      Alcotest.(check (list string))
        "one test for each group line"
        (List.sort String.compare (group_names set))
        (List.sort String.compare (List.map (fun group -> group.name) groups)))
