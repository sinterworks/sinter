(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type vector = {
  line : int;
  group : string;
  input : Yojson.Basic.t;
  result : string option;
  values : Yojson.Basic.t option;
  needs : string list;
}

type t = { lines : (string * vector) list }

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

let is_alnum c =
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')

let schema_of design line form =
  let fail () = fail_at design line "the form %s is not a form pin" form in
  match String.index_opt form '=' with
  | Some equals when String.length form > 0 && form.[0] = '#' ->
      let segment = String.sub form 1 (equals - 1)
      and label =
        String.sub form (equals + 1) (String.length form - equals - 1)
      in
      let parts =
        String.split_on_char '-'
          (String.map (function '_' | '.' -> '-' | c -> c) segment)
      in
      if
        List.for_all
          (fun part -> part <> "" && String.for_all is_alnum part)
          parts
        && label <> ""
        && String.for_all
             (fun c ->
               c >= '!' && c <= '~' && not (String.contains "#*,/=@[]{}" c))
             label
      then segment
      else fail ()
  | _ -> fail ()

let vector_of design line fields =
  only_members design line
    [ "form"; "group"; "input"; "needs"; "note"; "result"; "values" ]
    fields;
  let form = string_member design line "form" fields in
  let group = string_member design line "group" fields in
  let input =
    match member "input" fields with
    | Some input -> input
    | None -> fail_at design line "no member input"
  in
  (match member "note" fields with
  | None | Some (`String _) -> ()
  | Some _ -> fail_at design line "a note that is not a string");
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
  (form, { line; group; input; result; values; needs })

let read design =
  let content = In_channel.with_open_bin (path design) In_channel.input_all in
  let lines =
    match List.rev (String.split_on_char '\n' content) with
    | "" :: rest -> List.rev rest
    | rest -> fail_at design (List.length rest) "the file does not end with LF"
  in
  let lines =
    List.mapi
      (fun index text ->
        let line = index + 1 in
        match Yojson.Basic.from_string text with
        | `Assoc fields -> vector_of design line fields
        | _ -> fail_at design line "not a JSON object"
        | exception Yojson.Json_error message ->
            fail_at design line "not JSON: %s" message)
      lines
  in
  let schemas = Hashtbl.create 16 in
  List.iter
    (fun (form, vector) ->
      let schema = schema_of design vector.line form in
      match Hashtbl.find_opt schemas vector.group with
      | None -> Hashtbl.replace schemas vector.group schema
      | Some earlier when String.equal earlier schema -> ()
      | Some earlier ->
          fail_at design vector.line
            "the group %s has the schema %s here and %s before" vector.group
            schema earlier)
    lines;
  { lines }

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
         Printf.sprintf "the vector of line %d needs %s" number
           (String.concat ", " needs))
       skips)

let group set ~name ~form ?(needs = []) ?(skipped = []) give =
  let test () =
    let lines =
      List.filter (fun (_, vector) -> String.equal vector.group name) set.lines
    in
    List.iter
      (fun (found, vector) ->
        if not (String.equal found form) then
          Alcotest.failf
            "the vector of line %d of the group %s has the form %s, not %s"
            vector.line name found form)
      lines;
    let vectors = List.map snd lines in
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
          | unmet -> Some (vector.line, unmet))
        vectors
    in
    List.iter
      (fun (number, needs) ->
        Printf.printf "the vector of line %d of %s is skipped: it needs %s\n"
          number name (String.concat ", " needs))
      skips;
    if skips <> skipped then
      Alcotest.failf "the group %s skips %s, not %s" name
        (if skips = [] then "no vector" else print_skips skips)
        (if skipped = [] then "no vector" else print_skips skipped);
    let vectors =
      List.filter (fun vector -> not (List.mem_assoc vector.line skips)) vectors
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
                   "the vector of line %d of %s\n\
                   \  input: %s\n\
                   \  want:  %s\n\
                   \  have:  %s"
                   vector.line name
                   (Yojson.Basic.to_string vector.input)
                   (Yojson.Basic.to_string (normal want))
                   (Yojson.Basic.to_string (normal have)))
          | exception error ->
              Some
                (Printf.sprintf
                   "the vector of line %d of %s\n  input: %s\n  raised: %s"
                   vector.line name
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
  List.filter_map
    (fun (_, vector) ->
      if String.equal vector.group name then Some vector else None)
    set.lines

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
        "one test for each group"
        (List.sort_uniq String.compare
           (List.map (fun (_, vector) -> vector.group) set.lines))
        (List.sort String.compare (List.map (fun group -> group.name) groups)))
