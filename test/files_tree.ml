(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type permissions = { read : bool; search : bool; write : bool }

type kind =
  | Folder of (string * file) list
  | Regular of (string * int) list
  | Link of string
  | Pipe

and file = { kind : kind; permissions : permissions; owned_by_other : bool }

let every = { read = true; search = true; write = true }

let regular content =
  {
    kind = Regular [ (content, 1) ];
    permissions = every;
    owned_by_other = false;
  }

let folder entries =
  { kind = Folder entries; permissions = every; owned_by_other = false }

let fail format = Printf.ksprintf failwith format

let of_hex digits =
  let length = String.length digits in
  if length mod 2 <> 0 then fail "an odd number of hex digits: %s" digits;
  let digit index =
    match digits.[index] with
    | '0' .. '9' as c -> Char.code c - Char.code '0'
    | 'a' .. 'f' as c -> Char.code c - Char.code 'a' + 10
    | _ -> fail "not a lower-case hex digit in %s" digits
  in
  String.init (length / 2) (fun index ->
      Char.chr ((16 * digit (2 * index)) + digit ((2 * index) + 1)))

let fields = function
  | `Assoc fields -> fields
  | other -> fail "not a JSON object: %s" (Yojson.Basic.to_string other)

let string_of = function
  | `String text -> text
  | other -> fail "not a JSON string: %s" (Yojson.Basic.to_string other)

let pieces bytes_member json =
  match json with
  | `List pieces ->
      List.map
        (fun piece ->
          let fields = fields piece in
          if List.length fields <> 2 then
            fail "a piece with other members: %s" (Yojson.Basic.to_string piece);
          let times =
            match List.assoc_opt "times" fields with
            | Some (`Int times) when times >= 1 -> times
            | _ -> fail "no times in %s" (Yojson.Basic.to_string piece)
          in
          match List.assoc_opt bytes_member fields with
          | Some value -> (string_of value, times)
          | None ->
              fail "no %s in %s" bytes_member (Yojson.Basic.to_string piece))
        pieces
  | other -> fail "not pieces: %s" (Yojson.Basic.to_string other)

let bytes_of_pieces pieces =
  let buffer = Buffer.create 64 in
  List.iter
    (fun (bytes, times) ->
      for _ = 1 to times do
        Buffer.add_string buffer bytes
      done)
    pieces;
  Buffer.contents buffer

let text_of_pieces json = bytes_of_pieces (pieces "text" json)

let rec of_json json =
  let own_fields = fields json in
  let flag name default =
    match List.assoc_opt name own_fields with
    | None -> default
    | Some (`Bool value) when value <> default -> value
    | Some other -> fail "member %s with %s" name (Yojson.Basic.to_string other)
  in
  let member name =
    match List.assoc_opt name own_fields with
    | Some value -> value
    | None -> fail "no member %s in %s" name (Yojson.Basic.to_string json)
  in
  let kind, own =
    match member "type" with
    | `String "directory" ->
        let entries =
          match member "entries" with
          | `List entries ->
              List.map
                (fun entry ->
                  let entry_fields = fields entry in
                  if List.length entry_fields <> 2 then
                    fail "an entry object with other members";
                  ( of_hex (string_of (List.assoc "name" entry_fields)),
                    of_json (List.assoc "file" entry_fields) ))
                entries
          | other -> fail "entries: %s" (Yojson.Basic.to_string other)
        in
        (Folder entries, [ "entries" ])
    | `String "regular file" ->
        ( Regular
            (List.map
               (fun (hex, times) -> (of_hex hex, times))
               (pieces "bytes" (member "content"))),
          [ "content" ] )
    | `String "symbolic link" ->
        (Link (of_hex (string_of (member "reference"))), [ "reference" ])
    | `String "FIFO special file" -> (Pipe, [])
    | other -> fail "type %s" (Yojson.Basic.to_string other)
  in
  let allowed =
    ("type" :: own)
    @ (match kind with
      | Link _ -> []
      | Folder _ -> [ "read"; "search"; "write" ]
      | Regular _ | Pipe -> [ "read"; "write" ])
    @ [ "owned-by-other" ]
  in
  List.iter
    (fun (name, _) ->
      if not (List.mem name allowed) then fail "member %s is not allowed" name)
    own_fields;
  {
    kind;
    permissions =
      {
        read = flag "read" true;
        search = flag "search" true;
        write = flag "write" true;
      };
    owned_by_other = flag "owned-by-other" false;
  }

let effective_root () = Unix.geteuid () = 0

let system () =
  let channel = Unix.open_process_in "uname -s" in
  let name =
    Fun.protect
      ~finally:(fun () -> ignore (Unix.close_process_in channel))
      (fun () -> In_channel.input_all channel)
  in
  if String.equal name "Darwin\n" then "macos" else "linux"

type change = string

type 'a outcome =
  | Not_stored of string
  | Read of { value : 'a; changes : change list }

exception Not_stored_because of string

let not_stored format =
  Printf.ksprintf (fun reason -> raise (Not_stored_because reason)) format

let show names = String.concat "/" (List.rev_map String.escaped names)
let error_text error = Unix.error_message error

let inside name action =
  Unix.chdir name;
  Fun.protect ~finally:(fun () -> Unix.chdir "..") action

let read_whole name = In_channel.with_open_bin name In_channel.input_all

let make names name file =
  let here = show (name :: names) in
  try
    match file.kind with
    | Folder _ -> Unix.mkdir name 0o700
    | Regular pieces ->
        Out_channel.with_open_gen
          [ Open_wronly; Open_creat; Open_excl; Open_binary ] 0o600 name
          (fun channel ->
            List.iter
              (fun (bytes, times) ->
                for _ = 1 to times do
                  Out_channel.output_string channel bytes
                done)
              pieces)
    | Link reference -> Unix.symlink reference name
    | Pipe -> Unix.mkfifo name 0o600
  with
  | Unix.Unix_error (error, call, _) ->
      not_stored "%s: %s gives %s" here call (error_text error)
  | Sys_error message -> not_stored "%s: %s" here message

let rec build names name file =
  make names name file;
  match file.kind with
  | Folder entries ->
      inside name (fun () ->
          List.iter
            (fun (entry, file) -> build (name :: names) entry file)
            entries)
  | Regular _ | Link _ | Pipe -> ()

let kind_name = function
  | Unix.S_DIR -> "a folder"
  | Unix.S_REG -> "a regular file"
  | Unix.S_LNK -> "a symbolic link"
  | Unix.S_FIFO -> "a pipe"
  | Unix.S_CHR -> "a character special file"
  | Unix.S_BLK -> "a block special file"
  | Unix.S_SOCK -> "a socket"

let rec check_stored device names name file =
  let here = show (name :: names) in
  let stat = Unix.LargeFile.lstat name in
  if stat.st_dev <> device then not_stored "%s is on another file system" here;
  let expected =
    match file.kind with
    | Folder _ -> Unix.S_DIR
    | Regular _ -> Unix.S_REG
    | Link _ -> Unix.S_LNK
    | Pipe -> Unix.S_FIFO
  in
  if stat.st_kind <> expected then
    not_stored "%s is %s" here (kind_name stat.st_kind);
  match file.kind with
  | Folder entries ->
      let listing =
        List.sort String.compare (Array.to_list (Sys.readdir name))
      in
      let names_of_entries = List.sort String.compare (List.map fst entries) in
      if listing <> names_of_entries then
        not_stored "the listing of %s is [%s]" here
          (String.concat "; " (List.map String.escaped listing));
      inside name (fun () ->
          List.iter
            (fun (entry, file) ->
              check_stored device (name :: names) entry file)
            entries)
  | Regular pieces ->
      if not (String.equal (read_whole name) (bytes_of_pieces pieces)) then
        not_stored "%s has another content" here
  | Link reference ->
      let stored = Unix.readlink name in
      if not (String.equal stored reference) then
        not_stored "%s has the reference %s" here (String.escaped stored)
  | Pipe -> ()

let mode file =
  let bits =
    (if file.permissions.read then 4 else 0)
    + (if file.permissions.write then 2 else 0)
    + match file.kind with Folder _ when file.permissions.search -> 1 | _ -> 0
  in
  if file.owned_by_other then (bits lsl 6) lor bits else bits lsl 6

let has_permission name permission =
  match Unix.access name [ permission ] with
  | () -> true
  | exception Unix.Unix_error ((Unix.EACCES | Unix.EPERM), _, _) -> false

type snapshot = {
  stat : Unix.LargeFile.stats;
  content : string option;
  listing : string list option;
  reference : string option;
}

let snapshot name file =
  let stat = Unix.LargeFile.lstat name in
  let readable = file.permissions.read in
  {
    stat;
    content =
      (match file.kind with
      | Regular _ when readable -> Some (Digest.to_hex (Digest.file name))
      | _ -> None);
    listing =
      (match file.kind with
      | Folder _ when readable ->
          Some (List.sort String.compare (Array.to_list (Sys.readdir name)))
      | _ -> None);
    reference =
      (match file.kind with Link _ -> Some (Unix.readlink name) | _ -> None);
  }

let check_permissions names name file =
  let here = show (name :: names) in
  let owner_differs = (Unix.LargeFile.lstat name).st_uid <> Unix.geteuid () in
  if owner_differs <> file.owned_by_other then
    not_stored
      "%s: the owner %s the user of the program, and owned-by-other is %b" here
      (if owner_differs then "is not" else "is")
      file.owned_by_other;
  match file.kind with
  | Link _ -> ()
  | Folder _ | Regular _ | Pipe ->
      List.iter
        (fun (word, permission, wanted) ->
          if has_permission name permission <> wanted then
            not_stored "%s: the program %s the %s permission" here
              (if wanted then "does not have" else "has")
              word)
        ([
           ("read", Unix.R_OK, file.permissions.read);
           ("write", Unix.W_OK, file.permissions.write);
         ]
        @
        match file.kind with
        | Folder _ -> [ ("search", Unix.X_OK, file.permissions.search) ]
        | _ -> [])

let rec apply_modes record names name file =
  (match file.kind with
  | Folder entries ->
      inside name (fun () ->
          List.iter
            (fun (entry, file) -> apply_modes record (name :: names) entry file)
            entries)
  | Regular _ | Link _ | Pipe -> ());
  (match file.kind with
  | Link _ -> ()
  | _ ->
      if (Unix.LargeFile.lstat name).st_uid = Unix.geteuid () then
        Unix.chmod name (mode file));
  check_permissions names name file;
  Hashtbl.replace record (show (name :: names)) (snapshot name file)

let compare_snapshots here before after =
  let changes = ref [] in
  let differs what = changes := Printf.sprintf "%s: %s" here what :: !changes in
  let b = before.stat and a = after.stat in
  if b.st_dev <> a.st_dev || b.st_ino <> a.st_ino then differs "another file";
  if b.st_kind <> a.st_kind then differs "the file type";
  if b.st_perm <> a.st_perm then differs "the mode";
  if b.st_uid <> a.st_uid || b.st_gid <> a.st_gid then differs "the owner";
  if b.st_nlink <> a.st_nlink then differs "the number of links";
  if b.st_size <> a.st_size then differs "the size";
  if b.st_mtime <> a.st_mtime then differs "the time of last change of the data";
  if b.st_ctime <> a.st_ctime then
    differs "the time of last change of the status";
  if before.content <> after.content then differs "the content";
  if before.listing <> after.listing then differs "the listing";
  if before.reference <> after.reference then differs "the reference";
  List.rev !changes

let rec restore record names name file =
  let here = show (name :: names) in
  let changes =
    match Hashtbl.find_opt record here with
    | None -> [ here ^ ": no record" ]
    | Some before -> (
        match snapshot name file with
        | after -> compare_snapshots here before after
        | exception Unix.Unix_error (error, call, _) ->
            [ Printf.sprintf "%s: %s gives %s" here call (error_text error) ])
  in
  match file.kind with
  | Folder entries ->
      if (Unix.LargeFile.lstat name).st_uid = Unix.geteuid () then
        Unix.chmod name 0o700;
      changes
      @ inside name (fun () ->
          List.concat_map
            (fun (entry, file) -> restore record (name :: names) entry file)
            entries)
  | Regular _ | Pipe ->
      if (Unix.LargeFile.lstat name).st_uid = Unix.geteuid () then
        Unix.chmod name 0o600;
      changes
  | Link _ -> changes

let rec remove name =
  match (Unix.LargeFile.lstat name).st_kind with
  | Unix.S_DIR ->
      (try Unix.chmod name 0o700 with Unix.Unix_error _ -> ());
      inside name (fun () -> Array.iter remove (Sys.readdir "."));
      Unix.rmdir name
  | _ -> Unix.unlink name
  | exception Unix.Unix_error (Unix.ENOENT, _, _) -> ()

exception Timed_out

let with_limit limit action =
  let previous =
    Sys.signal Sys.sigalrm (Sys.Signal_handle (fun _ -> raise Timed_out))
  in
  Fun.protect
    ~finally:(fun () ->
      ignore (Unix.alarm 0);
      Sys.set_signal Sys.sigalrm previous)
    (fun () ->
      ignore (Unix.alarm limit);
      match action () with
      | value -> value
      | exception Timed_out ->
          fail "the file read gave no result after %d seconds" limit)

let nobody () =
  let entry = Unix.getpwnam "nobody" in
  (entry.pw_uid, entry.pw_gid)

let rec give_away (uid, gid) name file =
  (match file.kind with
  | Folder entries ->
      inside name (fun () ->
          List.iter
            (fun (entry, file) -> give_away (uid, gid) entry file)
            entries)
  | _ -> ());
  if file.owned_by_other then
    match file.kind with Link _ -> () | _ -> Unix.chmod name (mode file)
  else
    match file.kind with
    | Link _ -> (
        let pid =
          Unix.create_process "chown"
            [| "chown"; "-h"; Printf.sprintf "%d:%d" uid gid; name |]
            Unix.stdin Unix.stdout Unix.stderr
        in
        match Unix.waitpid [] pid with
        | _, Unix.WEXITED 0 -> ()
        | _ -> fail "chown -h failed on %s" (String.escaped name))
    | _ -> Unix.chown name uid gid

let in_child (uid, gid) step =
  let output, input = Unix.pipe ~cloexec:true () in
  match Unix.fork () with
  | 0 ->
      Unix.close output;
      let result =
        try
          Unix.setgroups [| gid |];
          Unix.setgid gid;
          Unix.setuid uid;
          Ok (step ())
        with error -> Error (Printexc.to_string error)
      in
      let channel = Unix.out_channel_of_descr input in
      Marshal.to_channel channel result [];
      close_out channel;
      Unix._exit 0
  | pid -> (
      Unix.close input;
      let channel = Unix.in_channel_of_descr output in
      let result =
        Fun.protect
          ~finally:(fun () -> close_in channel)
          (fun () ->
            match Marshal.from_channel channel with
            | result -> Some result
            | exception End_of_file -> None)
      in
      let _, status = Unix.waitpid [] pid in
      match (result, status) with
      | Some (Ok value), Unix.WEXITED 0 -> value
      | Some (Error text), _ -> failwith text
      | _ -> fail "the reading process ended with no value")

let run ?(limit = 10) tree read =
  let start = Sys.getcwd () in
  let parent = Filename.temp_dir "sinter-files-" "" in
  let root = Filename.concat parent "root" in
  Fun.protect
    ~finally:(fun () ->
      Unix.chdir parent;
      remove "root";
      Unix.chdir start;
      Unix.rmdir parent)
    (fun () ->
      Unix.chdir parent;
      let step () =
        let record = Hashtbl.create 16 in
        match apply_modes record [] "root" tree with
        | exception Not_stored_because reason -> Not_stored reason
        | () -> (
            let value =
              match with_limit limit (fun () -> read root) with
              | value -> Ok value
              | exception error -> Error error
            in
            let changes = restore record [] "root" tree in
            match value with
            | Ok value -> Read { value; changes }
            | Error error -> raise error)
      in
      match
        build [] "root" tree;
        check_stored (Unix.LargeFile.lstat ".").st_dev [] "root" tree
      with
      | exception Not_stored_because reason -> Not_stored reason
      | () ->
          if effective_root () then (
            let owner = nobody () in
            give_away owner "root" tree;
            Unix.chown parent (fst owner) (snd owner);
            in_child owner step)
          else step ())
