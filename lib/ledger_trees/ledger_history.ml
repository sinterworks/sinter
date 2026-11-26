(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_lines
open Ledger_objects

let ( let* ) = Result.bind

let size_hint =
  (16 [@mutaml.skip "a size hint of a hash table changes no result"])

type t = Intact | Not_intact

let for_each items f =
  List.fold_left
    (fun done_ item -> Result.bind done_ (fun () -> f item))
    (Ok ()) items

let is_subset small large =
  let set = Hashtbl.create size_hint in
  List.iter (fun line -> Hashtbl.replace set line ()) large;
  List.for_all (Hashtbl.mem set) small

module Folders = Map.Make (String)

module Make (Id : Hashtbl.HashedType) = struct
  module Read = Tree_read.Make (Id)
  module Graph = Sinter_commit_graphs.Commit_graph.Make (Id)
  module Table = Hashtbl.Make (Id)

  let extends objects d c =
    let session = Read.session objects in
    let lines tree =
      Result.map
        (fun (analysis : Read.analysis) -> analysis.lines)
        (Read.analyse session tree)
    in
    let passed = Table.create size_hint in
    let rec from d =
      if Id.equal d c then Ok true
      else if Table.mem passed d then Ok false
      else (
        Table.add passed d ();
        let* commit = Read.commit session d in
        match commit.parents with
        | [ parent ] ->
            let* parent_commit = Read.commit session parent in
            let* parent_lines = lines parent_commit.tree in
            let* own_lines = lines commit.tree in
            if is_subset parent_lines own_lines then from parent else Ok false
        | [] | _ :: _ :: _ -> Ok false)
    in
    from d

  type chunk = { name : string; blob : Id.t }
  type folder = { tree : Id.t; chunks : chunk list }

  type layout = { folders : folder Folders.t; count : int }
  (** A valid ledger tree, by the git objects that make it: [folders], the git
      tree object at [entries/<hh>] for each [<hh>], with its chunks; and
      [count], the number of its lines. *)

  let empty = { folders = Folders.empty; count = 0 }

  let read_folder session hh tree =
    let* entries = Read.tree session tree in
    Ok
      (if Tree_read.fits (Hex hh) entries then
         Some
           {
             tree;
             chunks =
               List.map
                 (fun (entry : Id.t entry) ->
                   { name = entry.name; blob = entry.id })
                 entries;
           }
       else None)

  let read_folders session (layout : layout) tree =
    let* entries = Read.tree session tree in
    if not (Tree_read.fits Folder entries) then Ok None
    else
      List.fold_left
        (fun folders (entry : Id.t entry) ->
          let* folders = folders in
          match folders with
          | None -> Ok None
          | Some folders -> (
              match Folders.find_opt entry.name layout.folders with
              | Some folder when Id.equal folder.tree entry.id ->
                  Ok (Some (Folders.add entry.name folder folders))
              | Some _ | None ->
                  let* folder = read_folder session entry.name entry.id in
                  Ok
                    (Option.map
                       (fun folder -> Folders.add entry.name folder folders)
                       folder)))
        (Ok (Some Folders.empty)) entries

  (* @satisfies ledger#{validate-histories=v1, valid-ledger-tree=v1}
     Condition 1 of a valid ledger tree for the git objects that a commit
     does not share with its parent: the root holds nothing or the folder
     `entries`, which holds folders `<hh>` of chunks with the mode 100644; a
     git object that the commit shares with its parent at one byte path was
     checked with the parent. *)
  let read_layout session (layout : layout) tree =
    let* entries = Read.tree session tree in
    if not (Tree_read.fits Root entries) then Ok None
    else
      match entries with
      | [] -> Ok (Some Folders.empty)
      | (entry : Id.t entry) :: _ -> read_folders session layout entry.id

  let changed_chunks old_folders new_folders =
    let added = ref [] in
    let removed = ref [] in
    let differ hh old_folder new_folder =
      match (old_folder, new_folder) with
      | Some old_folder, Some new_folder
        when Id.equal old_folder.tree new_folder.tree ->
          ()
      | _ ->
          let chunks folder =
            Option.fold ~none:[] ~some:(fun folder -> folder.chunks) folder
          in
          let old_chunks = chunks old_folder in
          let new_chunks = chunks new_folder in
          let index chunks =
            let table = Hashtbl.create size_hint in
            List.iter
              (fun chunk -> Hashtbl.replace table chunk.name chunk.blob)
              chunks;
            table
          in
          let kept chunk others =
            match Hashtbl.find_opt others chunk.name with
            | Some blob -> Id.equal blob chunk.blob
            | None -> false
          in
          let old_index = index old_chunks in
          let new_index = index new_chunks in
          List.iter
            (fun chunk ->
              if not (kept chunk old_index) then added := (hh, chunk) :: !added)
            new_chunks;
          List.iter
            (fun chunk ->
              if not (kept chunk new_index) then removed := chunk :: !removed)
            old_chunks
    in
    ignore
      (Folders.merge
         (fun hh old_folder new_folder ->
           differ hh old_folder new_folder;
           None)
         old_folders new_folders
        : folder Folders.t);
    (!added, !removed)

  (* @satisfies ledger#{validate-histories=v1, valid-ledger-tree=v1}
     Conditions 2 to 5 for each chunk that the commit does not share with its
     parent at one byte path: at least one line, each a ledger line, and the
     name of the chunk is the `id` of its first line. *)
  let added_lines session added =
    List.fold_left
      (fun lines (hh, chunk) ->
        let* lines = lines in
        match lines with
        | None -> Ok None
        | Some lines -> (
            let* content = Read.chunk session chunk.blob in
            match content.Chunk_content.ledger_lines with
            | Some (first :: _ as ledger_lines)
              when Option.equal String.equal
                     (Some (Ledger_line.id first))
                     (Chunk_path.chunk_id ("entries/" ^ hh ^ "/" ^ chunk.name))
              ->
                Ok (Some (List.rev_append ledger_lines lines))
            | Some [] | Some (_ :: _) | None -> Ok None))
      (Ok (Some [])) added

  let removed_lines session removed =
    List.fold_left
      (fun lines chunk ->
        let* lines = lines in
        let* content = Read.chunk session chunk.blob in
        Ok (List.rev_append content.Chunk_content.lines lines))
      (Ok []) removed

  (* @satisfies ledger#{validate-histories=v1, valid-ledger-tree=v1}
     The commit extends its parent when each line of the parent is a line of
     the commit: the lines of the parent's chunks that the commit does not keep
     at their byte paths must stand among the lines of the commit's own new
     chunks; the lines of a valid parent are distinct, so each takes one line
     there at most once. The lines that remain there are the new lines, and
     the commit is a valid ledger tree, given a valid parent with n lines,
     when no new line has the `id` of another line and the `seq` of the k new
     lines are n + 1 to n + k, each once: conditions 6 and 7. *)
  let new_lines ids count added removed =
    let counts = Hashtbl.create size_hint in
    List.iter
      (fun line ->
        match Hashtbl.find_opt counts (Ledger_line.bytes line) with
        | Some (_, times) -> incr times
        | None -> Hashtbl.add counts (Ledger_line.bytes line) (line, ref 1))
      added;
    let extends =
      List.for_all
        (fun bytes ->
          match Hashtbl.find_opt counts bytes with
          | Some (_, times) ->
              decr times;
              true
          | None -> false)
        removed
    in
    let fresh =
      Hashtbl.fold
        (fun _ (line, times) fresh -> List.init !times (fun _ -> line) @ fresh)
        counts []
    in
    let number = List.length fresh in
    let seqs = Array.make number false in
    let fresh_ids = Hashtbl.create size_hint in
    let fits line =
      let place = Ledger_line.seq line - count - 1 in
      place >= 0 && place < number
      && (not seqs.(place))
      && (not (Hashtbl.mem ids (Ledger_line.id line)))
      && (not (Hashtbl.mem fresh_ids (Ledger_line.id line)))
      &&
      (seqs.(place) <- true;
       Hashtbl.add fresh_ids (Ledger_line.id line) ();
       true)
    in
    if extends && List.for_all fits fresh then (
      Hashtbl.iter (fun id () -> Hashtbl.add ids id ()) fresh_ids;
      Some number)
    else None

  let step session ids (layout : layout) tree =
    let* read = read_layout session layout tree in
    match read with
    | None -> Ok None
    | Some folders -> (
        let added, removed = changed_chunks layout.folders folders in
        let* added = added_lines session added in
        let* removed = removed_lines session removed in
        match added with
        | None -> Ok None
        | Some added ->
            Ok
              (Option.map
                 (fun number -> { folders; count = layout.count + number })
                 (new_lines ids layout.count added removed)))

  (* @satisfies ledger#validate-histories=v1
     The ledger commit extends a commit with no parent only through a chain of
     commits with exactly one parent each that ends at a commit with no
     parent; a commit with two or more parents, or a chain that comes back to
     a commit that it passed, extends no such commit. Then the commits that the
     ledger commit reaches are this chain. *)
  let chain session c =
    let passed = Table.create size_hint in
    let rec down id commits =
      if Table.mem passed id then Ok None
      else (
        Table.add passed id ();
        let* commit = Read.commit session id in
        match commit.parents with
        | [] -> Ok (Some (commit :: commits))
        | [ parent ] -> down parent (commit :: commits)
        | _ :: _ :: _ -> Ok None)
    in
    down c []

  let rec along session ids layout = function
    | [] -> Ok Intact
    | (commit : Id.t commit) :: commits -> (
        let* next = step session ids layout commit.tree in
        match next with
        | None -> Ok Not_intact
        | Some layout -> along session ids layout commits)

  (* @satisfies ledger#validate-histories=v1
     A newer ledger gives neither result, whatever else is missing; otherwise
     each history object is read before the result, so a missing one gives no
     result; an absent ledger ref is intact, and a ledger ref with no commit is
     not. *)
  let history ?entry_id objects (ledger_ref : Id.t ledger_ref) =
    match ledger_ref with
    | Absent -> Ok (Some Intact)
    | No_commit -> Ok (Some Not_intact)
    | Commit c -> (
        let session = Read.session ?entry_id objects in
        let* commit = Read.commit session c in
        let* analysis = Read.analyse session commit.tree in
        if analysis.newer then Ok None
        else
          let graph id =
            Result.map
              (fun (commit : Id.t commit) -> commit.parents)
              (Read.commit session id)
          in
          let* reached = Graph.range graph ~from:None c in
          let* () =
            for_each reached (fun id ->
                let* commit = Read.commit session id in
                Read.walk session commit.tree)
          in
          let* commits = chain session c in
          match commits with
          | None -> Ok (Some Not_intact)
          | Some commits ->
              Result.map Option.some
                (along session (Hashtbl.create size_hint) empty commits))
end
