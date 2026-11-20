(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_trees
module Model = Ledger_model

type t = {
  commits : (string, string Ledger_objects.commit) Hashtbl.t;
  trees : (string, string Ledger_objects.entry list) Hashtbl.t;
  blobs : (string, string) Hashtbl.t;
  ledger_ids : (string, string list) Hashtbl.t;
  other_ids : (string, string list) Hashtbl.t;
  reads : (string, int) Hashtbl.t;
}

let create () =
  {
    commits = Hashtbl.create 16;
    trees = Hashtbl.create 16;
    blobs = Hashtbl.create 16;
    ledger_ids = Hashtbl.create 16;
    other_ids = Hashtbl.create 16;
    reads = Hashtbl.create 16;
  }

let is_tree mode = Changes_model.entry_kind mode = Changes_model.Tree_kind

let is_regular mode =
  Changes_model.entry_kind mode = Changes_model.Regular_file_kind

let digest s = Digest.to_hex (Digest.string s)

let tree_id listed =
  "tree:"
  ^ digest
      (String.concat ""
         (List.map
            (fun (x : string Ledger_objects.entry) ->
              x.mode ^ " " ^ x.name ^ "\000" ^ x.id ^ "\n")
            listed))

let add_tree_object store listed =
  let id = tree_id listed in
  Hashtbl.replace store.trees id listed;
  id

let set_tree store id listed = Hashtbl.replace store.trees id listed

let add_blob store content =
  let id = "chunk:" ^ digest content in
  Hashtbl.replace store.blobs id content;
  id

let walk store tree =
  let ledger = ref [] and others = ref [] in
  let rec add prefix entries =
    let listed =
      List.map
        (fun (e : Model.entry) ->
          let path = if prefix = "" then e.name else prefix ^ "/" ^ e.name in
          let id =
            if is_tree e.mode then (
              let id = add path e.entries in
              ledger := id :: !ledger;
              id)
            else
              let chunk = is_regular e.mode && Model.is_chunk_path path in
              let id =
                match e.content with
                | Some c ->
                    let id = (if chunk then "chunk:" else "blob:") ^ digest c in
                    Hashtbl.replace store.blobs id c;
                    id
                | None -> "absent:" ^ path
              in
              if chunk then ledger := id :: !ledger else others := id :: !others;
              id
          in
          { Ledger_objects.name = e.name; mode = e.mode; id })
        entries
    in
    add_tree_object store listed
  in
  let root = add "" tree in
  (root, root :: List.rev !ledger, List.rev !others)

let add_tree store tree =
  let root, _, _ = walk store tree in
  root

let add_commit store name (commit : Model.commit) =
  let root, ledger, others = walk store commit.tree in
  Hashtbl.replace store.commits name
    { Ledger_objects.parents = commit.parents; tree = root };
  Hashtbl.replace store.ledger_ids name (name :: ledger);
  Hashtbl.replace store.other_ids name others

let of_history commits =
  let store = create () in
  List.iter (fun (name, commit) -> add_commit store name commit) commits;
  store

let ledger_object_ids store name =
  Option.value ~default:[] (Hashtbl.find_opt store.ledger_ids name)

let other_blob_ids store name =
  Option.value ~default:[] (Hashtbl.find_opt store.other_ids name)

let objects ?(fail = fun _ -> false) store :
    (string, string) Ledger_objects.objects =
  let read kind table id =
    Hashtbl.replace store.reads id
      (1 + Option.value ~default:0 (Hashtbl.find_opt store.reads id));
    if fail id then Error (Printf.sprintf "the %s %s fails" kind id)
    else
      match Hashtbl.find_opt table id with
      | Some value -> Ok value
      | None -> Error (Printf.sprintf "no %s %s" kind id)
  in
  {
    commit = read "commit" store.commits;
    tree = read "tree" store.trees;
    blob = read "blob" store.blobs;
  }

let most_reads store = Hashtbl.fold (fun _ n m -> max n m) store.reads 0

let add_commit_object store name parents tree =
  Hashtbl.replace store.commits name { Ledger_objects.parents; tree }

let read_ids store = Hashtbl.fold (fun id _ acc -> id :: acc) store.reads []
