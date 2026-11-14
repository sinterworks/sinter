(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_ledger_lines
open Ledger_objects

let ( let* ) = Result.bind

let size_hint =
  (16 [@mutaml.skip "a size hint of a hash table changes no result"])

type level = Root | Folder | Hex of string
type place = At of level | Elsewhere

let prefix = function
  | Root -> ""
  | Folder -> "entries/"
  | Hex hh -> "entries/" ^ hh ^ "/"

let place_of_path path =
  if String.equal path "entries" then At Folder
  else if
    String.length path = 10
    && String.starts_with ~prefix:"entries/" path
    && Chunk_path.is_hex_folder (String.sub path 8 2)
  then At (Hex (String.sub path 8 2))
  else Elsewhere

let is_tree_entry entry =
  match Sinter_git_model.Commit_files.kind entry.mode with
  | Tree_entry -> true
  | Regular_file_entry | Symbolic_link_entry | Submodule_entry -> false

let is_regular_file_entry entry =
  match Sinter_git_model.Commit_files.kind entry.mode with
  | Regular_file_entry -> true
  | Tree_entry | Symbolic_link_entry | Submodule_entry -> false

(* @satisfies ledger#{validate-histories=v1, validate-ledgers=v1}
   Condition 3 of a valid ledger tree: the root holds only the tree entry
   `entries`, that folder only tree entries of two hex digits, and each such
   folder only chunks with the mode 100644. *)
let allowed level entry =
  match level with
  | Root -> String.equal entry.name "entries" && is_tree_entry entry
  | Folder -> is_tree_entry entry && Chunk_path.is_hex_folder entry.name
  | Hex hh ->
      Chunk_path.is_chunk_mode entry.mode
      && Option.is_some
           (Chunk_path.chunk_id ("entries/" ^ hh ^ "/" ^ entry.name))

(* @satisfies ledger#{validate-histories=v1, validate-ledgers=v1}
   Conditions 1 and 2 of a valid ledger tree: no name holds the byte `/`, and
   no git tree object lists one name twice; with no `/` in a name, two
   entries at any depth have one byte path only when a git tree object on the
   way to them lists one name twice. *)
let distinct_names (entries : _ entry list) =
  let names = Hashtbl.create size_hint in
  List.for_all
    (fun entry ->
      (not (String.contains entry.name '/'))
      && (not (Hashtbl.mem names entry.name))
      &&
      (Hashtbl.add names entry.name ();
       true))
    entries

(* @satisfies ledger#{validate-histories=v1, validate-ledgers=v1}
   Condition 3 for one git tree object: the folders `entries` and
   `entries/<hh>` hold at least one entry, since a folder with no chunk is not
   allowed; and each entry is allowed at its level. *)
let fits level entries =
  (match level with
    | Root -> true
    | Folder | Hex _ -> not (List.is_empty entries))
  && distinct_names entries
  && List.for_all (allowed level) entries

module Make (Id : Hashtbl.HashedType) = struct
  module Table = Hashtbl.Make (Id)

  module Places = Hashtbl.Make (struct
    type t = Id.t * place

    let equal (a, place_a) (b, place_b) = Id.equal a b && place_a = place_b
    let hash (id, place) = Hashtbl.hash (Id.hash id, place)
  end)

  type 'e session = {
    objects : (Id.t, 'e) objects;
    commits : Id.t commit Table.t;
    trees : Id.t entry list Table.t;
    chunks : Chunk_content.t Table.t;
    walked : unit Places.t;
  }

  let session objects =
    {
      objects;
      commits = Table.create size_hint;
      trees = Table.create size_hint;
      chunks = Table.create size_hint;
      walked = Places.create size_hint;
    }

  let cached table read id =
    match Table.find_opt table id with
    | Some value -> Ok value
    | None ->
        let* value = read id in
        Table.add table id value;
        Ok value

  let commit session id = cached session.commits session.objects.commit id
  let tree session id = cached session.trees session.objects.tree id

  let chunk session id =
    cached session.chunks
      (fun id -> Result.map Chunk_content.read (session.objects.blob id))
      id

  (* @satisfies ledger#{
         give-stored-ledgers=v1, validate-histories=v1, validate-ledgers=v1,
     }
     The ledger objects of a git tree object are each git tree object that a
     tree entry names, at any depth, and the blob of each chunk: each regular-file
     entry whose byte path is a chunk path, whatever its mode. Each one is read,
     and the first that cannot be read gives the error. A chunk path has two
     bytes `/`, so a chunk lies only in the root, in a folder `entries`, or in
     a folder `entries/<hh>`; every other folder is read for its git tree
     objects alone. *)
  let traverse session visited root ~on_tree ~on_chunk =
    let rec next = function
      | [] -> Ok ()
      | (id, place) :: rest ->
          if Places.mem visited (id, place) then next rest
          else (
            Places.add visited (id, place) ();
            match tree session id with
            | Error error -> Error error
            | Ok entries ->
                on_tree place entries;
                each rest place entries)
    and each pending place = function
      | [] -> next pending
      | entry :: entries -> (
          match place with
          | Elsewhere ->
              if is_tree_entry entry then
                each ((entry.id, Elsewhere) :: pending) place entries
              else each pending place entries
          | At level ->
              let path = prefix level ^ entry.name in
              if is_tree_entry entry then
                each ((entry.id, place_of_path path) :: pending) place entries
              else if
                is_regular_file_entry entry
                && Option.is_some (Chunk_path.chunk_id path)
              then (
                match chunk session entry.id with
                | Error error -> Error error
                | Ok content ->
                    on_chunk path content;
                    each pending place entries)
              else each pending place entries)
    in
    next [ (root, At Root) ]

  type analysis = {
    newer : bool;
    lines : string list;
    valid : Ledger_line.t list option;
  }

  let distinct lines =
    let seen = Hashtbl.create size_hint in
    List.filter
      (fun line ->
        if Hashtbl.mem seen line then false
        else (
          Hashtbl.add seen line ();
          true))
      lines

  let check_tree bad place entries =
    match place with
    | At level -> if not (fits level entries) then bad ()
    | Elsewhere -> ()

  (* @satisfies ledger#validate-ledgers=v1
     Conditions 4 to 7: each chunk has at least one line, each line is a ledger
     line, and the chunk path after its first 11 characters is the `id` of the
     first line of the chunk, then `.jsonl`. *)
  let rec gather lines = function
    | [] -> Some lines
    | (path, (content : Chunk_content.t)) :: chunks -> (
        match content.ledger_lines with
        | Some (first :: _ as ledger_lines)
          when Option.equal String.equal
                 (Some (Ledger_line.id first))
                 (Chunk_path.chunk_id path) ->
            gather (List.rev_append ledger_lines lines) chunks
        | Some [] | Some (_ :: _) | None -> None)

  (* @satisfies ledger#{validate-ledgers=v1, give-stored-ledgers=v1}
     Conditions 8 and 9: no two lines have one `id`, and the values of `seq`
     are 1 to n, each once; the lines are then put in increasing order of
     their `seq`. *)
  let order lines =
    let count = List.length lines in
    let places = Array.make count None in
    let ids = Hashtbl.create size_hint in
    let fits line =
      let seq = Ledger_line.seq line in
      seq <= count
      && Option.is_none places.(seq - 1)
      && (not (Hashtbl.mem ids (Ledger_line.id line)))
      &&
      (places.(seq - 1) <- Some line;
       Hashtbl.add ids (Ledger_line.id line) ();
       true)
    in
    if List.for_all fits lines then
      Some (List.filter_map Fun.id (Array.to_list places))
    else None

  let analyse session root =
    let visited = Places.create size_hint in
    let layout = ref true in
    let bad () = layout := false in
    let chunks = ref [] in
    let* () =
      traverse session visited root ~on_tree:(check_tree bad)
        ~on_chunk:(fun path content -> chunks := (path, content) :: !chunks)
    in
    let chunks = List.rev !chunks in
    let newer =
      List.exists (fun (_, (content : Chunk_content.t)) -> content.newer) chunks
    in
    let valid =
      if newer || not !layout then None
      else Option.bind (gather [] chunks) order
    in
    let lines =
      match valid with
      | Some lines -> List.map Ledger_line.bytes lines
      | None ->
          distinct
            (List.concat_map
               (fun (_, (content : Chunk_content.t)) -> content.lines)
               chunks)
    in
    Ok { newer; lines; valid }

  let walk session root =
    traverse session session.walked root
      ~on_tree:(fun _ _ -> ())
      ~on_chunk:(fun _ _ -> ())
end
