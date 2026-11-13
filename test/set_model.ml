(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module V = Vector_json
module Gen = QCheck2.Gen

let is_digit char = char >= '0' && char <= '9'
let is_lower char = char >= 'a' && char <= 'z'

let is_revision text =
  String.length text >= 2
  && text.[0] = 'v'
  && text.[1] >= '1'
  && text.[1] <= '9'
  && String.for_all is_digit (String.sub text 1 (String.length text - 1))

let is_group_name text =
  match String.split_on_char '-' text with
  | [] -> false
  | first :: _ as parts ->
      first <> ""
      && is_lower first.[0]
      && List.for_all
           (fun part ->
             part <> ""
             && String.for_all (fun char -> is_lower char || is_digit char) part)
           parts

let fields = function
  | V.Object members ->
      List.filter_map
        (function V.Text name, value -> Some (name, value) | _ -> None)
        members
  | _ -> []

let names object_ = List.sort String.compare (List.map fst (fields object_))

let string_member name object_ =
  match List.assoc_opt name (fields object_) with
  | Some (V.String (V.Text text)) -> Some text
  | _ -> None

let has_revision object_ =
  match string_member "rev" object_ with
  | Some text -> is_revision text
  | None -> false

let is_set_object object_ = names object_ = [ "rev" ] && has_revision object_

let has_group_name object_ =
  match string_member "group" object_ with
  | Some text -> is_group_name text
  | None -> false

let is_group_object object_ =
  names object_ = [ "group"; "rev" ]
  && has_revision object_ && has_group_name object_

let number object_ =
  match List.assoc_opt "n" (fields object_) with
  | Some (V.Number number) -> V.integer number
  | _ -> None

let rec strictly_rising compare = function
  | a :: (b :: _ as rest) -> compare a b < 0 && strictly_rising compare rest
  | _ -> true

let has_needs object_ =
  match List.assoc_opt "needs" (fields object_) with
  | Some (V.Array (_ :: _ as names)) ->
      let texts =
        List.filter_map
          (function V.String (V.Text text) -> Some text | _ -> None)
          names
      in
      List.length texts = List.length names
      && List.for_all is_group_name texts
      && strictly_rising V.compare_keys texts
  | _ -> false

let is_vector_object object_ =
  let present = names object_ in
  let has name = List.mem name present in
  List.for_all
    (fun name ->
      List.mem name
        [ "n"; "rev"; "group"; "input"; "result"; "values"; "note"; "needs" ])
    present
  && has "n" && has "rev" && has "group" && has "input"
  && (has "result" || has "values")
  && (match number object_ with Some n -> n >= 1 | None -> false)
  && has_revision object_ && has_group_name object_
  && ((not (has "result")) || Option.is_some (string_member "result" object_))
  && ((not (has "note")) || Option.is_some (string_member "note" object_))
  && ((not (has "needs")) || has_needs object_)

let line_object line =
  match V.read line with
  | V.Object _ as object_ when V.canonical object_ = Some line -> Some object_
  | _ -> None
  | exception _ -> None

let group object_ = Option.value (string_member "group" object_) ~default:""

let read bytes =
  let length = String.length bytes in
  if length = 0 || bytes.[length - 1] <> '\n' then None
  else
    let lines = String.split_on_char '\n' (String.sub bytes 0 (length - 1)) in
    let objects = List.map line_object lines in
    if List.exists Option.is_none objects then None
    else
      let objects = List.filter_map Fun.id objects in
      match objects with
      | [] -> None
      | set :: rest ->
          let rec split groups = function
            | object_ :: rest when is_group_object object_ ->
                split (object_ :: groups) rest
            | rest -> (List.rev groups, rest)
          in
          let groups, vectors = split [] rest in
          let group_names = List.map group groups in
          let vector_groups =
            List.sort_uniq String.compare (List.map group vectors)
          in
          if
            is_set_object set
            && List.for_all is_vector_object vectors
            && strictly_rising V.compare_keys group_names
            && List.sort String.compare group_names = vector_groups
            && strictly_rising Int.compare (List.filter_map number vectors)
          then Some objects
          else None

let write objects =
  String.concat ""
    (List.map
       (fun object_ ->
         match V.canonical object_ with
         | Some bytes -> bytes ^ "\n"
         | None -> invalid_arg "write")
       objects)

type version = { objects : Vector_json.t list; forms : (string * string) list }

type view = {
  set_revision : int;
  groups : (string * int) list;
  vectors : (int * Vector_json.t) list;
  forms_of : string -> string;
}

let revision_number object_ =
  match string_member "rev" object_ with
  | Some text -> int_of_string (String.sub text 1 (String.length text - 1))
  | None -> invalid_arg "revision_number"

let view version =
  match read (write version.objects) with
  | None -> invalid_arg "view: no test-vector set"
  | Some [] -> invalid_arg "view: no set line"
  | Some (set :: rest) ->
      let groups =
        List.filter_map
          (fun object_ ->
            if is_group_object object_ then
              Some (group object_, revision_number object_)
            else None)
          rest
      in
      let vectors =
        List.filter_map
          (fun object_ -> Option.map (fun n -> (n, object_)) (number object_))
          rest
      in
      if
        List.sort String.compare (List.map fst groups)
        <> List.sort String.compare (List.map fst version.forms)
      then invalid_arg "view: the forms do not match the groups";
      {
        set_revision = revision_number set;
        groups;
        vectors;
        forms_of = (fun name -> List.assoc name version.forms);
      }

let member_bytes name object_ =
  Option.map V.canonical (List.assoc_opt name (fields object_))

let changes e l (n, vector) =
  match List.assoc_opt n e.vectors with
  | None -> false
  | Some earlier ->
      List.exists
        (fun name -> member_bytes name earlier <> member_bytes name vector)
        [ "group"; "input"; "result"; "values" ]
      || e.forms_of (group earlier) <> l.forms_of (group vector)

let numbers_of_group view name =
  List.filter_map
    (fun (n, vector) -> if group vector = name then Some n else None)
    view.vectors

let pair_holds before e l =
  let earlier_numbers =
    List.concat_map (fun view -> List.map fst view.vectors) (before @ [ e ])
  in
  let new_numbers_rise =
    List.for_all
      (fun (n, _) ->
        List.mem_assoc n e.vectors
        || List.for_all (fun old -> n > old) earlier_numbers)
      l.vectors
  in
  let vector_revisions =
    List.for_all
      (fun ((n, vector) as line) ->
        match List.assoc_opt n e.vectors with
        | None -> true
        | Some earlier ->
            if changes e l line then
              revision_number vector > revision_number earlier
            else revision_number vector = revision_number earlier)
      l.vectors
  in
  let any_change = List.exists (changes e l) l.vectors in
  let group_revisions =
    List.for_all
      (fun (name, revision) ->
        match List.assoc_opt name e.groups with
        | Some old ->
            let in_e = numbers_of_group e name
            and in_l = numbers_of_group l name in
            let rises =
              List.exists
                (fun ((_, vector) as line) ->
                  group vector = name && changes e l line)
                l.vectors
              || List.exists (fun n -> not (List.mem n in_e)) in_l
              || List.exists (fun n -> not (List.mem n in_l)) in_e
            in
            if rises then revision > old else revision = old
        | None ->
            List.for_all
              (fun view ->
                match List.assoc_opt name view.groups with
                | Some old -> revision > old
                | None -> true)
              (before @ [ e ]))
      l.groups
  in
  let joins_or_leaves =
    List.exists (fun (n, _) -> not (List.mem_assoc n e.vectors)) l.vectors
    || List.exists (fun (n, _) -> not (List.mem_assoc n l.vectors)) e.vectors
  in
  let set_revision =
    if any_change || joins_or_leaves then l.set_revision > e.set_revision
    else l.set_revision = e.set_revision
  in
  new_numbers_rise && vector_revisions && group_revisions && set_revision

let is_version_sequence versions =
  let views = List.map view versions in
  let rec go before = function
    | e :: (l :: _ as rest) -> pair_holds before e l && go (before @ [ e ]) rest
    | _ -> true
  in
  go [] views

let text value = V.String (V.Text value)
let revision_text number = text ("v" ^ string_of_int number)

let vector_object ~n ~revision ~group_name ~input ~result ~values ~note ~needs =
  V.Object
    (List.filter_map Fun.id
       [
         Some (V.Text "n", V.Number (string_of_int n));
         Some (V.Text "rev", revision_text revision);
         Some (V.Text "group", text group_name);
         Some (V.Text "input", text input);
         Option.map (fun result -> (V.Text "result", text result)) result;
         Option.map (fun values -> (V.Text "values", values)) values;
         Option.map (fun note -> (V.Text "note", text note)) note;
         Option.map
           (fun needs -> (V.Text "needs", V.Array (List.map text needs)))
           needs;
       ])

type content = {
  c_group : string;
  c_input : string;
  c_result : string option;
  c_values : Vector_json.t option;
  c_note : string option;
  c_needs : string list option;
}

let content_gen =
  let open Gen in
  let* c_group = oneof_list [ "a"; "b" ] in
  let* c_input = oneof_list [ "x"; "y" ] in
  let* shape = int_range 0 2 in
  let* c_result = oneof_list [ "valid"; "invalid" ] in
  let* c_values =
    oneof_list [ V.Array [ V.Number "1" ]; V.Array []; V.Object [] ]
  in
  let* c_note = option (oneof_list [ "a note"; "another note" ]) in
  let* c_needs =
    option (oneof_list [ [ "b" ]; [ "a-1"; "b" ]; [ "no-privilege" ] ])
  in
  return
    {
      c_group;
      c_input;
      c_result = (if shape = 1 then None else Some c_result);
      c_values = (if shape = 0 then None else Some c_values);
      c_note;
      c_needs;
    }

let make_version ~set_revision ~group_revision ~vector_revision ~forms contents
    =
  let groups =
    List.sort_uniq V.compare_keys (List.map (fun (_, c) -> c.c_group) contents)
  in
  {
    objects =
      V.Object [ (V.Text "rev", revision_text set_revision) ]
      :: List.map
           (fun name ->
             V.Object
               [
                 (V.Text "group", text name);
                 (V.Text "rev", revision_text (group_revision name));
               ])
           groups
      @ List.map
          (fun (n, c) ->
            vector_object ~n ~revision:(vector_revision n) ~group_name:c.c_group
              ~input:c.c_input ~result:c.c_result ~values:c.c_values
              ~note:c.c_note ~needs:c.c_needs)
          contents;
    forms = List.map (fun name -> (name, forms name)) groups;
  }

let forms_texts = [ "text 1"; "text 2" ]

let version_gen =
  let open Gen in
  let* present = list_size (return 5) bool in
  let* contents = list_size (return 5) content_gen in
  let* revisions = list_size (return 5) (int_range 1 3) in
  let* set_revision = int_range 1 3 in
  let* group_a = int_range 1 3 in
  let* group_b = int_range 1 3 in
  let* forms_a = oneof_list forms_texts in
  let* forms_b = oneof_list forms_texts in
  let contents =
    List.filteri
      (fun index _ -> List.nth present index)
      (List.mapi (fun index c -> (index + 1, c)) contents)
  in
  return
    (make_version ~set_revision
       ~group_revision:(fun name -> if name = "a" then group_a else group_b)
       ~vector_revision:(fun n -> List.nth revisions (n - 1))
       ~forms:(fun name -> if name = "a" then forms_a else forms_b)
       contents)

let content_of object_ =
  {
    c_group = group object_;
    c_input = Option.value (string_member "input" object_) ~default:"";
    c_result = string_member "result" object_;
    c_values = List.assoc_opt "values" (fields object_);
    c_note = string_member "note" object_;
    c_needs =
      (match List.assoc_opt "needs" (fields object_) with
      | Some (V.Array names) ->
          Some
            (List.filter_map
               (function V.String (V.Text name) -> Some name | _ -> None)
               names)
      | _ -> None);
  }

let next_gen earlier =
  let open Gen in
  let views = List.map view earlier in
  let e = List.nth views (List.length views - 1) in
  let highest =
    List.fold_left
      (fun high view ->
        List.fold_left (fun high (n, _) -> max high n) high view.vectors)
      0 views
  in
  let* kept =
    flatten_list
      (List.map
         (fun (n, vector) ->
           let* fate = int_range 0 3 in
           let* fresh = content_gen in
           return
             (match fate with
             | 0 -> None
             | 1 -> Some (n, fresh)
             | 2 -> Some (n, content_of vector)
             | _ ->
                 Some
                   ( n,
                     {
                       (content_of vector) with
                       c_note = fresh.c_note;
                       c_needs = fresh.c_needs;
                     } )))
         e.vectors)
  in
  let* added = list_size (int_range 0 2) content_gen in
  let* forms_a = oneof_list forms_texts in
  let* forms_b = oneof_list forms_texts in
  let* steps = list_size (return 20) (int_range 1 2) in
  let step index = List.nth steps (index mod 20) in
  let contents =
    List.filter_map Fun.id kept
    @ List.mapi (fun index c -> (highest + index + 1, c)) added
  in
  let forms name =
    match
      List.assoc_opt name (List.map (fun (g, _) -> (g, e.forms_of g)) e.groups)
    with
    | Some old when step (Char.code name.[0]) = 1 -> old
    | _ -> if name = "a" then forms_a else forms_b
  in
  let draft =
    make_version ~set_revision:1
      ~group_revision:(fun _ -> 1)
      ~vector_revision:(fun _ -> 1)
      ~forms contents
  in
  let l = view draft in
  let vector_revision n =
    match List.assoc_opt n e.vectors with
    | Some earlier ->
        let line = (n, List.assoc n l.vectors) in
        revision_number earlier + if changes e l line then step n else 0
    | None -> step n
  in
  let group_revision name =
    match List.assoc_opt name e.groups with
    | Some old ->
        let in_e = numbers_of_group e name and in_l = numbers_of_group l name in
        let rises =
          List.exists
            (fun ((_, vector) as line) ->
              group vector = name && changes e l line)
            l.vectors
          || List.exists (fun n -> not (List.mem n in_e)) in_l
          || List.exists (fun n -> not (List.mem n in_l)) in_e
        in
        old + if rises then step (Char.code name.[0] + 1) else 0
    | None ->
        1
        + List.fold_left
            (fun high view ->
              match List.assoc_opt name view.groups with
              | Some old -> max high old
              | None -> high)
            0 views
  in
  let any_change = List.exists (changes e l) l.vectors in
  let joins_or_leaves =
    List.exists (fun (n, _) -> not (List.mem_assoc n e.vectors)) l.vectors
    || List.exists (fun (n, _) -> not (List.mem_assoc n l.vectors)) e.vectors
  in
  let set_revision =
    e.set_revision + if any_change || joins_or_leaves then step 7 else 0
  in
  return
    (make_version ~set_revision ~group_revision ~vector_revision ~forms contents)

let sequence_gen =
  let open Gen in
  let* first = version_gen in
  let* length = int_range 0 4 in
  let rec grow versions count =
    if count = 0 then return versions
    else
      let* next = next_gen versions in
      grow (versions @ [ next ]) (count - 1)
  in
  grow [ first ] length

let print_version version =
  Printf.sprintf "{\"forms\":{%s},\"set\":[%s]}"
    (String.concat ","
       (List.map
          (fun (name, forms) -> Printf.sprintf "%S:%S" name forms)
          version.forms))
    (String.concat "," (List.map V.print version.objects))
