(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_json_lines
open Sinter_ledger_lines
module Gen = QCheck2.Gen
module Model = Ledger_model
module V = Vector_json

let property ?(count = 500) ?print ~name generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ?print generator check)

let print_line = Printf.sprintf "%S"

let line_object line =
  match Json_line.read line with
  | Some line_object -> line_object
  | None -> Alcotest.failf "not a canonical line: %S" line

let reference line =
  match V.json_value_of_bytes line with
  | Some value -> value
  | None -> Alcotest.failf "no JSON value: %S" line

let task_line =
  "{\"by\":\"Ada Lovelace \
   <ada@example.com>\",\"id\":\"e-0001d7a41cb7db6191dc42c69bda336b\",\"kind\":\"task\",\"seq\":1,\"v\":1}\n"

let void_line =
  "{\"by\":\"Ada Lovelace \
   <ada@example.com>\",\"dropped\":\"e-5b1c0a9d2e114f0c8a6b3d9e7f21a05c\",\"id\":\"e-0dc878fd2dc3c179e4b8fa1829666011\",\"kind\":\"void\",\"reason\":\"the \
   entry holds a secret\",\"seq\":7,\"v\":1}\n"

let kind_tests =
  let texts =
    [
      "task";
      "plan";
      "approval";
      "decline";
      "done";
      "abandoned";
      "delivered";
      "void";
    ]
  in
  [
    Alcotest.test_case "each of the eight texts is a kind with that text" `Quick
      (fun () ->
        List.iter
          (fun text ->
            match Entry_kind.of_string text with
            | Some kind ->
                Alcotest.(check string) text text (Entry_kind.to_string kind)
            | None -> Alcotest.failf "%s is no kind" text)
          texts;
        Alcotest.(check int)
          "eight kinds" 8
          (List.length
             (List.sort_uniq compare
                (List.filter_map Entry_kind.of_string texts))));
    Alcotest.test_case "another text is no kind, and case matters" `Quick
      (fun () ->
        List.iter
          (fun text ->
            Alcotest.(check bool) text true (Entry_kind.of_string text = None))
          [
            "Task";
            "VOID";
            "pin";
            "";
            "task ";
            " task";
            "commitment-set";
            "completed";
          ]);
  ]

let entry_id_tests =
  [
    Alcotest.test_case "the entry id of the void of the design" `Quick
      (fun () ->
        Alcotest.(check string)
          "the id" "e-0dc878fd2dc3c179e4b8fa1829666011"
          (Entry_id.of_line_object (line_object void_line) :> string));
    property ~name:"the entry id is the hash id of the object without its id"
      ~print:print_line Model.line_gen (fun line ->
        String.equal
          (Entry_id.of_line_object (line_object line) :> string)
          (Model.entry_id (reference line)));
    property ~name:"the entry id does not depend on the member id"
      ~print:(fun (line, id) -> Printf.sprintf "%S %S" line id)
      Gen.(
        pair Model.line_gen (oneof_list [ "e-" ^ String.make 32 '0'; ""; "x" ]))
      (fun (line, id) ->
        let changed =
          Model.canonical_line
            (match reference line with
            | V.Object members ->
                V.Object
                  ((V.Text "id", V.String (V.Text id))
                  :: List.filter (fun (k, _) -> k <> V.Text "id") members)
            | other -> other)
        in
        String.equal
          (Entry_id.of_line_object (line_object line) :> string)
          (Entry_id.of_line_object (line_object changed) :> string));
  ]

let id_text_gen =
  Gen.(
    let* line = Model.line_gen in
    let id = (Entry_id.of_line_object (line_object line) :> string) in
    oneof
      [
        return id;
        map (fun t -> t) (V.corrupt_gen id);
        return (String.uppercase_ascii id);
        return (id ^ "0");
        return (String.sub id 0 (String.length id - 1));
        return ("f" ^ String.sub id 1 (String.length id - 1));
        return ("e" ^ String.sub id 2 (String.length id - 2) ^ "0");
        return "";
        return "e-";
        string_of V.byte_gen;
      ])

let is_entry_id_tests =
  [
    property ~name:"is_entry_id is the form of the term entry-id"
      ~print:print_line id_text_gen (fun text ->
        Entry_id.is_entry_id text = Model.is_id text);
    property ~name:"each entry id has the form of an entry id" ~print:print_line
      Model.line_gen (fun line ->
        Entry_id.is_entry_id
          (Entry_id.of_line_object (line_object line) :> string));
  ]

let member_tests =
  let value =
    Json_line.read task_line |> Option.get |> fun l -> (l :> Json.t)
  in
  [
    Alcotest.test_case "find gives the value of a member" `Quick (fun () ->
        Alcotest.(check bool)
          "kind" true
          (match Member.find value "kind" with
          | Some v -> String.equal (Json.canonical_byte_sequence v) "\"task\""
          | None -> false);
        Alcotest.(check bool) "no member" true (Member.find value "x" = None);
        Alcotest.(check bool)
          "not an object" true
          (Member.find (Json.boolean true) "kind" = None));
    Alcotest.test_case "a key that is not valid UTF-8 finds no member" `Quick
      (fun () ->
        Alcotest.(check bool) "find" true (Member.find value "\xff" = None);
        Alcotest.(check int)
          "without" 5
          (List.length (Member.without value [ "\xff"; "k\xffind" ])));
    Alcotest.test_case "without leaves out the members of the keys" `Quick
      (fun () ->
        let keys members =
          List.map (fun (k, _) -> Sinter_text.Text.encode k) members
        in
        Alcotest.(check (list string))
          "the keys" [ "by"; "kind"; "v" ]
          (keys (Member.without value [ "id"; "seq"; "absent" ]));
        Alcotest.(check (list string))
          "not an object" []
          (keys (Member.without (Json.boolean true) [ "id" ])));
  ]

(* @verifies ledger#valid-ledger-tree=v1
   `of_line_object` accepts a generated canonical line object when, and only
   when, that object meets conditions 3 and 4 of the schema
   `valid-ledger-tree`: that object has string `id` and `kind`, `v` equal to 1,
   `seq` equal to 1 or more, and `id` equal to its entry id. *)
let ledger_line_tests =
  [
    property
      ~name:"a line object is the object of a ledger line by conditions 3 and 4"
      ~print:print_line Model.line_gen (fun line ->
        Option.is_some (Ledger_line.of_line_object (line_object line))
        = Model.is_ledger_line line);
    property ~name:"a ledger line gives its bytes, id, kind, seq, and object"
      ~print:print_line Model.line_gen (fun line ->
        match Ledger_line.of_line_object (line_object line) with
        | None -> true
        | Some l ->
            let o = reference line in
            String.equal (Ledger_line.bytes l) line
            && Some (Ledger_line.id l) = Model.string_member "id" o
            && Some (Ledger_line.kind l) = Model.string_member "kind" o
            && Some (Ledger_line.seq l) = Model.integer_member "seq" o
            && String.equal
                 (Json_line.canonical_line (Ledger_line.line_object l))
                 line);
  ]

let entry_of line =
  match Ledger_line.of_line_object (line_object line) with
  | Some l -> Entry.of_line l
  | None -> Alcotest.failf "not a ledger line: %S" line

let entry_tests =
  [
    property
      ~name:"a ledger line has an entry when its kind is one of the eight"
      ~print:print_line Model.line_gen (fun line ->
        match Ledger_line.of_line_object (line_object line) with
        | None -> true
        | Some l -> (
            let kind = Ledger_line.kind l in
            match Entry.of_line l with
            | None -> not (List.mem kind Model.kinds)
            | Some e ->
                List.mem kind Model.kinds
                && String.equal (Entry_kind.to_string (Entry.kind e)) kind
                && String.equal (Entry.id e) (Ledger_line.id l)
                && Entry.seq e = Ledger_line.seq l
                && String.equal (Ledger_line.bytes (Entry.line e)) line
                && String.equal
                     (Json_line.canonical_line (Entry.line_object e))
                     line));
    Alcotest.test_case "a void gives its dropped and its reason" `Quick
      (fun () ->
        match entry_of void_line with
        | Some e ->
            Alcotest.(check bool)
              "dropped" true
              (Option.map Json.canonical_byte_sequence (Entry.dropped e)
              = Some "\"e-5b1c0a9d2e114f0c8a6b3d9e7f21a05c\"");
            Alcotest.(check bool)
              "reason" true
              (Option.map Json.canonical_byte_sequence (Entry.reason e)
              = Some "\"the entry holds a secret\"")
        | None -> Alcotest.fail "a void has an entry");
    Alcotest.test_case "an entry of another kind gives no dropped and no reason"
      `Quick (fun () ->
        let line =
          Model.canonical_line
            (Model.with_id
               (V.Object
                  [
                    (V.Text "by", V.String (V.Text "b"));
                    ( V.Text "dropped",
                      V.String (V.Text "e-5b1c0a9d2e114f0c8a6b3d9e7f21a05c") );
                    (V.Text "kind", V.String (V.Text "task"));
                    (V.Text "reason", V.String (V.Text "r"));
                    (V.Text "seq", V.Number "1");
                    (V.Text "v", V.Number "1");
                  ]))
        in
        match entry_of line with
        | Some e ->
            Alcotest.(check bool) "dropped" true (Entry.dropped e = None);
            Alcotest.(check bool) "reason" true (Entry.reason e = None)
        | None -> Alcotest.fail "a task has an entry");
    Alcotest.test_case "a void without dropped and reason gives neither" `Quick
      (fun () ->
        let line =
          Model.canonical_line
            (Model.with_id
               (V.Object
                  [
                    (V.Text "kind", V.String (V.Text "void"));
                    (V.Text "seq", V.Number "1");
                    (V.Text "v", V.Number "1");
                  ]))
        in
        match entry_of line with
        | Some e ->
            Alcotest.(check bool) "dropped" true (Entry.dropped e = None);
            Alcotest.(check bool) "reason" true (Entry.reason e = None)
        | None -> Alcotest.fail "a void has an entry");
  ]

let tests =
  kind_tests @ entry_id_tests @ is_entry_id_tests @ member_tests
  @ ledger_line_tests @ entry_tests
