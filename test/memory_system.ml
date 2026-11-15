(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Files = Sinter_repository_files

type node =
  | File of string
  | Sparse of int * (int * string) list
  | Failing of string * int * int
  | Shrunk of string * int
  | Folder
  | Link of string
  | Fifo

type call =
  | Stat of string
  | Lstat of string
  | Open_file of string
  | Open_folder of string
  | Read of string * int * int
  | Readlink of string
  | Listing of string

type t = {
  nodes : (string, node) Hashtbl.t;
  mutable calls : call list;
  opened : (int, string * string * node) Hashtbl.t;
  mutable next : int;
}

let names pathname =
  List.filter
    (fun name -> name <> "" && name <> ".")
    (String.split_on_char '/' pathname)

let join parts = "/" ^ String.concat "/" parts

let rec add_folders t parts =
  match List.rev parts with
  | [] -> ()
  | _ :: up ->
      add_folders t (List.rev up);
      if not (Hashtbl.mem t.nodes (join parts)) then
        Hashtbl.replace t.nodes (join parts) Folder

let add t pathname node =
  let parts = List.filter (fun n -> n <> "..") (names pathname) in
  (match List.rev parts with
  | [] -> ()
  | _ :: up -> add_folders t (List.rev up));
  Hashtbl.replace t.nodes (join parts) node

let remove t pathname =
  let key = join (names pathname) in
  let doomed =
    Hashtbl.fold
      (fun name _ acc ->
        if name = key || String.starts_with ~prefix:(key ^ "/") name then
          name :: acc
        else acc)
      t.nodes []
  in
  List.iter (Hashtbl.remove t.nodes) doomed

let create nodes =
  let t =
    {
      nodes = Hashtbl.create 64;
      calls = [];
      opened = Hashtbl.create 16;
      next = 0;
    }
  in
  Hashtbl.replace t.nodes "/" Folder;
  List.iter (fun (pathname, node) -> add t pathname node) nodes;
  t

let fail error name = raise (Unix.Unix_error (error, "memory", name))

let resolve t ~follow_last pathname =
  if pathname = "" || String.contains pathname '\000' then
    fail Unix.ENOENT pathname;
  let links = ref 0 in
  let rec go done_ = function
    | [] -> done_
    | ".." :: rest -> (
        match List.rev done_ with
        | [] -> go [] rest
        | _ :: up -> go (List.rev up) rest)
    | name :: rest -> (
        let here = done_ @ [ name ] in
        match Hashtbl.find_opt t.nodes (join here) with
        | None -> fail Unix.ENOENT pathname
        | Some (Link target) when rest <> [] || follow_last ->
            incr links;
            if !links > 32 then fail Unix.ELOOP pathname;
            let start =
              if String.starts_with ~prefix:"/" target then [] else done_
            in
            go start (names target @ rest)
        | Some Folder -> go here rest
        | Some _ when rest <> [] -> fail Unix.ENOTDIR pathname
        | Some _ -> here)
  in
  join (go [] (names pathname))

let node t ~follow_last pathname =
  let key = resolve t ~follow_last pathname in
  match Hashtbl.find_opt t.nodes key with
  | Some node -> (key, node)
  | None -> fail Unix.ENOENT pathname

let kind_of = function
  | File _ | Sparse _ | Failing _ | Shrunk _ -> Files.Regular_file
  | Folder -> Files.Folder
  | Link _ -> Files.Symbolic_link
  | Fifo -> Files.Other_kind

let record t call = t.calls <- call :: t.calls

let system t =
  (module struct
    type descr = int

    let stat pathname =
      record t (Stat pathname);
      kind_of (snd (node t ~follow_last:true pathname))

    let lstat pathname =
      record t (Lstat pathname);
      kind_of (snd (node t ~follow_last:false pathname))

    let new_descr pathname key node =
      t.next <- t.next + 1;
      Hashtbl.replace t.opened t.next (pathname, key, node);
      t.next

    let open_file pathname =
      record t (Open_file pathname);
      let key, found = node t ~follow_last:true pathname in
      new_descr pathname key found

    let open_folder pathname =
      record t (Open_folder pathname);
      match node t ~follow_last:true pathname with
      | key, Folder -> new_descr pathname key Folder
      | _ -> fail Unix.ENOTDIR pathname

    let opened descr =
      match Hashtbl.find_opt t.opened descr with
      | Some entry -> entry
      | None -> fail Unix.EBADF "descriptor"

    let fstat descr =
      let _, key, found = opened descr in
      {
        Files.kind = kind_of found;
        size =
          (match found with
          | File content -> String.length content
          | Sparse (size, _) | Shrunk (_, size) -> size
          | Failing (content, _, _) -> String.length content
          | _ -> 0);
        identity = { Files.device = 1; inode = Hashtbl.hash key };
      }

    let read descr ~offset buffer start length =
      match opened descr with
      | pathname, _, File content ->
          let count = max 0 (min length (String.length content - offset)) in
          if count > 0 then Bytes.blit_string content offset buffer start count;
          record t (Read (pathname, offset, count));
          count
      | pathname, _, Failing (content, low, high)
        when offset < high && offset + length > low ->
          ignore content;
          fail Unix.EIO pathname
      | pathname, _, (Failing (content, _, _) | Shrunk (content, _)) ->
          let count = max 0 (min length (String.length content - offset)) in
          if count > 0 then Bytes.blit_string content offset buffer start count;
          record t (Read (pathname, offset, count));
          count
      | pathname, _, Sparse (size, pieces) ->
          let count = max 0 (min length (size - offset)) in
          Bytes.fill buffer start count '\000';
          List.iter
            (fun (at, piece) ->
              let first = max at offset
              and last = min (at + String.length piece) (offset + count) in
              if first < last then
                Bytes.blit_string piece (first - at) buffer
                  (start + first - offset)
                  (last - first))
            pieces;
          record t (Read (pathname, offset, count));
          count
      | pathname, _, _ -> fail Unix.EISDIR pathname

    let readlink pathname =
      record t (Readlink pathname);
      match node t ~follow_last:false pathname with
      | _, Link target -> target
      | _ -> fail Unix.EINVAL pathname

    let listing descr =
      let pathname, key, _ = opened descr in
      record t (Listing pathname);
      let prefix = if key = "/" then "/" else key ^ "/" in
      Hashtbl.fold
        (fun name _ acc ->
          if String.starts_with ~prefix name && name <> key then
            let rest =
              String.sub name (String.length prefix)
                (String.length name - String.length prefix)
            in
            if String.contains rest '/' then acc else rest :: acc
          else acc)
        t.nodes [ "."; ".." ]

    let close descr = Hashtbl.remove t.opened descr
    let eilseq = 92
  end : Files.SYSTEM)

let calls t = List.rev t.calls
let clear t = t.calls <- []
let open_descriptors t = Hashtbl.length t.opened

let pathname_of_call = function
  | Stat p | Lstat p | Open_file p | Open_folder p | Readlink p | Listing p -> p
  | Read (p, _, _) -> p

let bytes_given t =
  List.fold_left
    (fun sum -> function Read (_, _, n) -> sum + n | _ -> sum)
    0 t.calls

let largest_read t =
  List.fold_left
    (fun m -> function Read (_, _, n) -> max m n | _ -> m)
    0 t.calls
