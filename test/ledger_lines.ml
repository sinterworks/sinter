(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_core

let commit_id = String.make 40 'c'
let hash n = Sha256.hex (string_of_int n)

let common ?(kind = "approval") ?(seq = 1) () =
  [
    ("v", Json.Int 1);
    ("seq", Json.Int seq);
    ("kind", Json.String kind);
    ("by", Json.String "a@example.com");
    ("ts", Json.String "2026-10-31T14:05:09Z");
    ("head", Json.String commit_id);
    ("branch", Json.String "main");
    ("tool", Json.String "sinter 0.1.0");
  ]

let printed value =
  match Json.to_string value with
  | Ok text -> text
  | Error _ -> Alcotest.fail "the value does not print"

let with_id fields =
  match Ledger.id_of (Json.Object fields) with
  | Ok id -> ("id", Json.String id) :: fields
  | Error _ -> Alcotest.fail "the value does not print"

let line_of fields = printed (Json.Object (with_id fields))
let text value = Json.String value

let set_fields ?(seq = 1) ~csh scopes promises =
  common ~kind:"commitment-set" ~seq ()
  @ [
      ("csh", text csh);
      ( "scopes",
        Json.Array
          (List.map
             (fun (step, glob) ->
               Json.Object
                 (("glob", text glob)
                 ::
                 (match step with
                 | Some step -> [ ("step", text step) ]
                 | None -> [])))
             scopes) );
      ( "promises",
        Json.Array
          (List.map
             (fun (step, word, target) ->
               Json.Object
                 [
                   ("step", text step);
                   ("target", text target);
                   ("word", text word);
                 ])
             promises) );
    ]

let set_hash scopes promises =
  let plan_scope =
    List.filter_map
      (fun (step, glob) -> if Option.is_none step then Some glob else None)
      scopes
  in
  let own step =
    List.filter_map
      (fun (named, glob) -> if named = Some step then Some glob else None)
      scopes
  in
  Commitment_set.hash ~scope:plan_scope
    (List.map
       (fun (step, word, target) ->
         {
           Commitment_set.scope =
             (match own step with [] -> plan_scope | globs -> globs);
           promises = [ (word, target) ];
         })
       promises)

let approval_of_text ~seq subject ~rev ~xh =
  line_of
    (common ~seq ()
    @ [ ("subject", text subject); ("rev", Json.Int rev); ("xh", text xh) ])

let approval_of_hash ~seq subject ~csh =
  line_of (common ~seq () @ [ ("subject", text subject); ("csh", text csh) ])

let commitment_set ~seq scopes promises =
  line_of (set_fields ~seq ~csh:(set_hash scopes promises) scopes promises)

let decline ~seq subject ~hash ~reason =
  line_of
    (common ~kind:"decline" ~seq ()
    @ [
        ("subject", text subject); ("hash", text hash); ("reason", text reason);
      ])

let delivered ~seq subject ~csh =
  line_of
    (common ~kind:"delivered" ~seq ()
    @ [
        ("subject", text subject); ("csh", text csh); ("merge", text commit_id);
      ])

let completed ~seq ?approval subject =
  line_of
    (common ~kind:"completed" ~seq ()
    @ [
        ("subject", text subject);
        ("merge", text commit_id);
        ("report", text (hash 0));
      ]
    @
    match approval with
    | Some approval -> [ ("approval", text approval) ]
    | None -> [])

let abandoned ~seq subject ~reason =
  line_of
    (common ~kind:"abandoned" ~seq ()
    @ [ ("subject", text subject); ("reason", text reason) ])

let void ~seq ~dropped ~reason =
  line_of
    (common ~kind:"void" ~seq ()
    @ [ ("dropped", text dropped); ("reason", text reason) ])

let unknown ~seq kind = line_of (common ~kind ~seq ())

let read line =
  match Ledger.read_line Git.Sha1 line with
  | Ok read -> read
  | Error _ -> Alcotest.fail ("the line does not read: " ^ line)

let id_of_line line =
  match read line with
  | Ledger.Known { entry; _ } -> entry.id
  | Ledger.Unknown { id; _ } -> id

let entries lines =
  List.filter_map
    (fun line ->
      match read line with
      | Ledger.Known { entry; _ } -> Some entry
      | Ledger.Unknown _ -> None)
    lines
