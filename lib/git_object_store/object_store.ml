(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Files = Sinter_repository_files
module Object_id = Sinter_git_objects.Object_id

type kind = Commit | Tree | Blob | Tag
type obj = { kind : kind; content : string }

type limits = {
  max_content_size : int;
  max_deltas : int;
  max_databases : int;
  max_packs : int;
  max_alternates_size : int;
}

type problem =
  | Not_zlib
  | Size_differs
  | Bytes_after_stream
  | Malformed_loose_header
  | Malformed_entry_header
  | Malformed_delta of Delta.error
  | Malformed_index
  | Pack_does_not_match_index
  | Wrong_id
  | Base_not_in_pack of Object_id.t
  | Delta_cycle

type damage = { pathname : string; offset : int option; problem : problem }

type failure =
  | Unread of { pathname : string; failure : Files.failure }
  | Too_large of { pathname : string; offset : int option }
  | Too_many_deltas
  | Too_many_databases
  | Too_many_packs of string

type lookup = { held : obj option; damage : damage list }
type 'a attempt = Gives of 'a | Absent | Damaged of damage | Failed of failure

let kind_name = function
  | Commit -> "commit"
  | Tree -> "tree"
  | Blob -> "blob"
  | Tag -> "tag"

let kind_of_name = function
  | "commit" -> Some Commit
  | "tree" -> Some Tree
  | "blob" -> Some Blob
  | "tag" -> Some Tag
  | _ -> None

let kind_of_type = function
  | 1 -> Some Commit
  | 2 -> Some Tree
  | 3 -> Some Blob
  | 4 -> Some Tag
  | _ -> None

let digest format parts =
  match (format : Object_id.format) with
  | Sha1 -> Digestif.SHA1.(to_raw_string (digestv_string parts))
  | Sha256 -> Digestif.SHA256.(to_raw_string (digestv_string parts))

let is_object id obj =
  let prefix =
    Printf.sprintf "%s %d\000" (kind_name obj.kind) (String.length obj.content)
  in
  String.equal
    (digest (Object_id.format id) [ prefix; obj.content ])
    (Object_id.to_bytes id)

let big_endian text =
  String.fold_left (fun value byte -> (value lsl 8) lor Char.code byte) 0 text

let uint32 text position =
  (Char.code text.[position] lsl 24)
  lor (Char.code text.[position + 1] lsl 16)
  lor (Char.code text.[position + 2] lsl 8)
  lor Char.code text.[position + 3]

let parse_size digits =
  let length = String.length digits in
  if
    length = 0
    || (length > 1 && digits.[0] = '0')
    || not (String.for_all (function '0' .. '9' -> true | _ -> false) digits)
  then None
  else Some (Option.value (int_of_string_opt digits) ~default:max_int)

type entry =
  | Whole of { kind : kind; data : int; size : int }
  | Offset_delta of { base : int; data : int; size : int }
  | Name_delta of { base : Object_id.t; data : int; size : int }

type index = {
  version : int;
  count : int;
  fanout : int array;
  large : int;
  pack_size : int;
}

type pack = {
  index_path : string;
  pack_path : string;
  mutable checked : index attempt option;
}

type database = {
  folder : string;
  mutable packs : (pack array, failure) result option;
  mutable lines : string list option;
}

type step =
  | Apply of { at : int; data : int; size : int }
  | Check of { at : int; base : Object_id.t }

type cursor = { id : Object_id.t; mutable database : int; mutable stage : int }
type place = Loose of string | Packed of pack * index * int

let header_chunk = 64
let pack_header_size = 12

module Make (R : Files.READER) = struct
  type t = {
    limits : limits;
    format : Object_id.format;
    git_folder : string;
    databases : database Dynarray.t;
    identities : (Files.identity, unit) Hashtbl.t;
    mutable started : bool;
    mutable expanded : int;
    mutable full : bool;
  }

  let create limits format ~git_folder =
    if
      limits.max_content_size < 0
      || limits.max_deltas < 0 || limits.max_databases < 0
      || limits.max_packs < 0
      || limits.max_alternates_size < 0
    then invalid_arg "Object_store.create: a negative limit";
    {
      limits =
        {
          limits with
          max_content_size = min limits.max_content_size Sys.max_string_length;
        };
      format;
      git_folder;
      databases = Dynarray.create ();
      identities =
        Hashtbl.create
          (8
          [@mutaml.skip
            "the initial size of a hash table sets only when the table grows; \
             no result depends on it"]);
      started = false;
      expanded = 0;
      full = false;
    }

  let unread pathname failure = Unread { pathname; failure }
  let join folder name = folder ^ "/" ^ name

  let add_database store folder =
    match R.folder_identity folder with
    | Error (Files.No_file | Files.Not_a_folder) -> Ok ()
    | Error failure -> Error (unread folder failure)
    | Ok identity ->
        if Hashtbl.mem store.identities identity then Ok ()
        else if Dynarray.length store.databases >= store.limits.max_databases
        then (
          store.full <- true;
          Error Too_many_databases)
        else (
          Hashtbl.add store.identities identity ();
          Dynarray.add_last store.databases
            { folder; packs = None; lines = None };
          Ok ())

  let before_nul text =
    match String.index_opt text '\000' with
    | Some nul -> String.sub text 0 nul
    | None -> text

  let escape at j =
    match at j with
    | '\\' -> Some ('\\', 1)
    | '"' -> Some ('"', 1)
    | 'a' -> Some ('\007', 1)
    | 'b' -> Some ('\b', 1)
    | 'f' -> Some ('\012', 1)
    | 'n' -> Some ('\n', 1)
    | 'r' -> Some ('\r', 1)
    | 't' -> Some ('\t', 1)
    | 'v' -> Some ('\011', 1)
    | '0' .. '3' as high -> (
        match (at (j + 1), at (j + 2)) with
        | ('0' .. '7' as middle), ('0' .. '7' as low) ->
            let digit c = Char.code c - Char.code '0' in
            Some
              (Char.chr ((digit high * 64) + (digit middle * 8) + digit low), 3)
        | _ -> None)
    | _ -> None

  let unquote text start =
    let length = String.length text in
    let at k = if k < length then text.[k] else '\000' in
    let bytes = Buffer.create length in
    let rec from j =
      match at j with
      | '\000' -> None
      | '"' -> Some (Buffer.contents bytes, j + 1)
      | '\\' -> (
          match escape at (j + 1) with
          | Some (c, used) ->
              Buffer.add_char bytes c;
              from (j + 1 + used)
          | None -> None)
      | c ->
          Buffer.add_char bytes c;
          from (j + 1)
    in
    from (start + 1)

  let entries text =
    let text = before_nul text in
    let length = String.length text in
    let line_end k =
      Option.value ~default:length (String.index_from_opt text k '\n')
    in
    let rec from k found =
      if k >= length then List.rev found
      else
        let pathname, next =
          match if text.[k] = '"' then unquote text k else None with
          | Some (bytes, after) -> (before_nul bytes, after + 1)
          | None -> (String.sub text k (line_end k - k), line_end k + 1)
        in
        from next
          (if text.[k] = '#' || pathname = "" then found else pathname :: found)
    in
    from 0 []

  (* @satisfies changes#read-only-repository-files=v1
     The object databases are the folder [objects] of the git folder and the
     folders that the entries of the files [info/alternates] name, relative to
     the object database that holds the file: no other folder is read. *)
  let expand store database =
    let pathname = join database.folder "info/alternates" in
    let rec add = function
      | [] -> Ok ()
      | line :: rest as lines -> (
          match
            add_database store
              (if String.starts_with ~prefix:"/" line then line
               else join database.folder line)
          with
          | Error failure ->
              database.lines <- Some lines;
              Error failure
          | Ok () -> add rest)
    in
    match database.lines with
    | Some lines -> add lines
    | None -> (
        match R.read ~max_size:store.limits.max_alternates_size pathname with
        | Error Files.No_file -> add []
        | Error failure -> Error (unread pathname failure)
        | Ok text -> add (entries text))

  let rec database store number =
    if number < Dynarray.length store.databases then
      Ok (Some (Dynarray.get store.databases number))
    else if store.full then Error Too_many_databases
    else if not store.started then (
      match add_database store (join store.git_folder "objects") with
      | Error failure -> Error failure
      | Ok () ->
          store.started <- true;
          database store number)
    else if store.expanded < Dynarray.length store.databases then (
      match expand store (Dynarray.get store.databases store.expanded) with
      | Error failure -> Error failure
      | Ok () ->
          store.expanded <- store.expanded + 1;
          database store number)
    else Ok None

  let packs store database =
    match database.packs with
    | Some packs -> packs
    | None -> (
        let folder = join database.folder "pack" in
        let found =
          match R.list folder with
          | Error (Files.No_file | Files.Not_a_folder) -> Ok [||]
          | Error failure -> Error (unread folder failure)
          | Ok names ->
              let present = Hashtbl.create (List.length names) in
              List.iter (fun name -> Hashtbl.replace present name ()) names;
              Ok
                (Array.of_list
                   (List.filter_map
                      (fun name ->
                        match Filename.chop_suffix_opt ~suffix:".idx" name with
                        | Some stem
                          when String.starts_with ~prefix:"pack-" name
                               && Hashtbl.mem present (stem ^ ".pack") ->
                            Some
                              {
                                index_path = join folder name;
                                pack_path = join folder (stem ^ ".pack");
                                checked = None;
                              }
                        | _ -> None)
                      names))
        in
        match found with
        | Error failure -> Error failure
        | Ok packs ->
            let packs =
              if Array.length packs > store.limits.max_packs then
                Error (Too_many_packs folder)
              else Ok packs
            in
            database.packs <- Some packs;
            packs)

  let hash_length store = Object_id.length store.format

  exception Read_failed of Files.failure

  let read_exactly handle ~offset ~length =
    match R.read_range handle ~offset ~length with
    | Error failure -> raise (Read_failed failure)
    | Ok text -> if String.length text = length then Some text else None

  let reading pathname f =
    match R.with_file pathname f with
    | result -> result
    | exception Read_failed failure -> Error failure

  let malformed_index pack =
    { pathname = pack.index_path; offset = None; problem = Malformed_index }

  let pack_damage pack =
    Damaged
      {
        pathname = pack.pack_path;
        offset = None;
        problem = Pack_does_not_match_index;
      }

  let index_first_bytes = 8 + 1024

  let read_index store pack handle =
    let h = hash_length store in
    let size = R.size handle in
    match read_exactly handle ~offset:0 ~length:index_first_bytes with
    | None -> Error (malformed_index pack)
    | Some first -> (
        let version, start =
          if String.sub first 0 4 = "\255tOc" then
            ((if uint32 first 4 = 2 then Some 2 else None), 8)
          else (Some 1, 0)
        in
        match version with
        | None -> Error (malformed_index pack)
        | Some version -> (
            let fanout =
              Array.init 256 (fun k -> uint32 first (start + (4 * k)))
            in
            let ordered = ref true in
            for k = 1 to 255 do
              if fanout.(k) < fanout.(k - 1) then ordered := false
            done;
            let count = fanout.(255) in
            let fixed =
              if version = 1 then 1024 + (count * (4 + h)) + (2 * h)
              else 8 + 1024 + (count * (h + 8)) + (2 * h)
            in
            let large = (size - fixed) / 8 in
            if
              (not !ordered)
              || (version = 1 && size <> fixed)
              || version = 2
                 && (size < fixed
                    || size <> fixed + (8 * large)
                    || large > count)
            then Error (malformed_index pack)
            else
              match read_exactly handle ~offset:(size - (2 * h)) ~length:h with
              | None -> Error (malformed_index pack)
              | Some copy -> Ok (version, count, fanout, large, copy)))

  let read_pack_ends store handle =
    let h = hash_length store in
    let size = R.size handle in
    if size < pack_header_size + h then None
    else
      match
        ( read_exactly handle ~offset:0 ~length:pack_header_size,
          read_exactly handle ~offset:(size - h) ~length:h )
      with
      | Some header, Some trailer
        when String.sub header 0 4 = "PACK"
             && (uint32 header 4 = 2 || uint32 header 4 = 3) ->
          Some (uint32 header 8, trailer, size)
      | _ -> None

  let check_pack store pack =
    match pack.checked with
    | Some checked -> checked
    | None ->
        let checked =
          match reading pack.index_path (read_index store pack) with
          | Error Files.No_file -> Absent
          | Error failure -> Failed (unread pack.index_path failure)
          | Ok (Error damage) -> Damaged damage
          | Ok (Ok (version, count, fanout, large, copy)) -> (
              match reading pack.pack_path (read_pack_ends store) with
              | Error failure -> Failed (unread pack.pack_path failure)
              | Ok None -> pack_damage pack
              | Ok (Some (objects, trailer, pack_size)) ->
                  if objects <> count || not (String.equal trailer copy) then
                    pack_damage pack
                  else Gives { version; count; fanout; large; pack_size })
        in
        (match checked with
        | Failed _ -> ()
        | _ -> pack.checked <- Some checked);
        checked

  let name_position store index number =
    let h = hash_length store in
    if index.version = 1 then 1024 + (number * (4 + h)) + 4
    else 8 + 1024 + (number * h)

  let entry_offset store pack index handle number =
    let h = hash_length store in
    let small =
      if index.version = 1 then
        read_exactly handle ~offset:(1024 + (number * (4 + h))) ~length:4
      else
        read_exactly handle
          ~offset:(8 + 1024 + (index.count * (h + 4)) + (number * 4))
          ~length:4
    in
    let offset =
      match small with
      | None -> None
      | Some bytes -> (
          let value = big_endian bytes in
          if index.version = 1 || value land 0x80000000 = 0 then Some value
          else
            let slot = value land 0x7fffffff in
            if slot >= index.large then None
            else
              match
                read_exactly handle
                  ~offset:(8 + 1024 + (index.count * (h + 8)) + (slot * 8))
                  ~length:8
              with
              | Some bytes when Char.code bytes.[0] < 0x80 ->
                  Some (big_endian bytes)
              | _ -> None)
    in
    match offset with
    | Some offset
      when offset >= pack_header_size && offset < index.pack_size - h ->
        Ok (Some offset)
    | _ -> Error (malformed_index pack)

  let search store pack index id handle =
    let h = hash_length store in
    let target = Object_id.to_bytes id in
    let bucket = Char.code target.[0] in
    let rec go low high below above =
      if low >= high then Ok None
      else
        let middle = low + ((high - low) / 2) in
        match
          read_exactly handle
            ~offset:(name_position store index middle)
            ~length:h
        with
        | None -> Error (malformed_index pack)
        | Some name ->
            if
              Char.code name.[0] <> bucket
              || Option.fold ~none:false
                   ~some:(fun below -> String.compare below name >= 0)
                   below
              || Option.fold ~none:false
                   ~some:(fun above -> String.compare name above >= 0)
                   above
            then Error (malformed_index pack)
            else
              let order = String.compare target name in
              if order < 0 then go low middle below (Some name)
              else if order > 0 then go (middle + 1) high (Some name) above
              else entry_offset store pack index handle middle
    in
    go
      (if bucket = 0 then 0 else index.fanout.(bucket - 1))
      index.fanout.(bucket) None None

  let find_in_pack store pack id =
    match check_pack store pack with
    | (Absent | Damaged _ | Failed _) as other -> other
    | Gives index -> (
        match reading pack.index_path (search store pack index id) with
        | Error failure -> Failed (unread pack.index_path failure)
        | Ok (Ok (Some offset)) -> Gives (index, offset)
        | Ok (Ok None) -> Absent
        | Ok (Error damage) -> Damaged damage)

  let loose_path folder id =
    let hex = Object_id.to_hex id in
    join folder
      (String.sub hex 0 2 ^ "/" ^ String.sub hex 2 (String.length hex - 2))

  (* @satisfies changes#read-only-repository-files=v1
     The places of an object id are only the files of loose objects and of
     packs in the object databases of the git repository, which are
     repository files: the lookup tries no place outside them. *)
  let rec next_place store cursor record =
    match database store cursor.database with
    | Error failure -> Error failure
    | Ok None -> Ok None
    | Ok (Some database) -> (
        if cursor.stage = 0 then (
          cursor.stage <- 1;
          Ok (Some (Loose (loose_path database.folder cursor.id))))
        else
          match packs store database with
          | Error failure -> Error failure
          | Ok packs ->
              let number = cursor.stage - 1 in
              if number >= Array.length packs then (
                cursor.database <- cursor.database + 1;
                cursor.stage <- 0;
                next_place store cursor record)
              else (
                cursor.stage <- cursor.stage + 1;
                let pack = packs.(number) in
                match find_in_pack store pack cursor.id with
                | Failed failure -> Error failure
                | Gives (index, offset) ->
                    Ok (Some (Packed (pack, index, offset)))
                | Absent -> next_place store cursor record
                | Damaged damage ->
                    record damage;
                    next_place store cursor record))

  let copy_into buffer written output length =
    for k = 0 to length - 1 do
      Bytes.set buffer (written + k) (Bigarray.Array1.get output k)
    done

  let inflate_from handle ~start ~stop =
    Inflate.inflate
      ~read:(fun ~offset ~length -> R.read_range handle ~offset ~length)
      ~start ~stop

  let inflated handle ~start ~stop ~size =
    let buffer = Bytes.create size in
    let written = ref 0 in
    let sink output length =
      if length > size - !written then Error Size_differs
      else (
        copy_into buffer !written output length;
        written := !written + length;
        Ok ())
    in
    match inflate_from handle ~start ~stop ~sink with
    | Inflate.Unread failure -> Error failure
    | Inflate.Not_zlib -> Ok (Error Not_zlib)
    | Inflate.Stopped problem -> Ok (Error problem)
    | Inflate.Ended _ ->
        if !written <> size then Ok (Error Size_differs)
        else Ok (Ok (Bytes.unsafe_to_string buffer))

  type loose_stop = Bad_header | Above_limit | Too_long

  let max_header = 32

  let parse_header text =
    match String.index_opt text ' ' with
    | None -> None
    | Some space -> (
        match
          ( kind_of_name (String.sub text 0 space),
            parse_size
              (String.sub text (space + 1) (String.length text - space - 1)) )
        with
        | Some kind, Some size -> Some (kind, size)
        | _ -> None)

  let read_loose store pathname =
    let limit = store.limits.max_content_size in
    let damaged problem = Damaged { pathname; offset = None; problem } in
    let read handle =
      let size = R.size handle in
      let header = Buffer.create max_header in
      let parsed = ref None in
      let buffer = ref Bytes.empty and written = ref 0 in
      let rec take output start length =
        if start >= length then Ok ()
        else
          match !parsed with
          | Some _ ->
              let count = length - start in
              if count > Bytes.length !buffer - !written then Error Too_long
              else (
                copy_into !buffer !written
                  (Bigarray.Array1.sub output start count)
                  count;
                written := !written + count;
                Ok ())
          | None -> (
              match Bigarray.Array1.get output start with
              | '\000' -> (
                  match parse_header (Buffer.contents header) with
                  | None -> Error Bad_header
                  | Some (_, declared) when declared > limit ->
                      Error Above_limit
                  | Some (kind, declared) ->
                      parsed := Some kind;
                      buffer := Bytes.create declared;
                      take output (start + 1) length)
              | byte ->
                  if Buffer.length header >= max_header then Error Bad_header
                  else (
                    Buffer.add_char header byte;
                    take output (start + 1) length))
      in
      let outcome =
        inflate_from handle ~start:0 ~stop:size ~sink:(fun output length ->
            take output 0 length)
      in
      match (outcome, !parsed) with
      | Inflate.Unread failure, _ -> Failed (unread pathname failure)
      | Inflate.Stopped Above_limit, _ ->
          Failed (Too_large { pathname; offset = None })
      | Inflate.Stopped Bad_header, _ -> damaged Malformed_loose_header
      | Inflate.Stopped Too_long, _ -> damaged Size_differs
      | Inflate.Not_zlib, _ -> damaged Not_zlib
      | Inflate.Ended _, None -> damaged Malformed_loose_header
      | Inflate.Ended stream_end, Some kind ->
          if !written <> Bytes.length !buffer then damaged Size_differs
          else if stream_end <> size then damaged Bytes_after_stream
          else Gives { kind; content = Bytes.unsafe_to_string !buffer }
    in
    match reading pathname read with
    | Error Files.No_file -> Absent
    | Error failure -> Failed (unread pathname failure)
    | Ok attempt -> attempt

  let read_entry store index handle offset =
    let h = hash_length store in
    let stop = index.pack_size - h in
    let chunk = ref "" and chunk_start = ref offset in
    let byte position =
      if position >= stop then None
      else if position < !chunk_start + String.length !chunk then
        Some (Char.code !chunk.[position - !chunk_start])
      else
        match
          read_exactly handle ~offset:position
            ~length:(min header_chunk (stop - position))
        with
        | None -> None
        | Some text ->
            chunk := text;
            chunk_start := position;
            Some (Char.code text.[0])
    in
    let rec size position value shift last =
      if last land 0x80 = 0 then Some (value, position)
      else
        match byte position with
        | None -> None
        | Some next ->
            size (position + 1)
              (Saturating.add_bits value ~bits:(next land 0x7f) ~shift)
              (shift + 7) next
    in
    let rec distance position value =
      match byte position with
      | None -> None
      | Some next ->
          let value = value lor (next land 0x7f) in
          if value > offset - pack_header_size then None
          else if next land 0x80 = 0 then Some (value, position + 1)
          else
            distance (position + 1)
              (Saturating.add_bits 0 ~bits:(value + 1) ~shift:7)
    in
    match byte offset with
    | None -> None
    | Some first -> (
        match size (offset + 1) (first land 15) 4 first with
        | None -> None
        | Some (size, data) -> (
            match (first lsr 4) land 7 with
            | 6 -> (
                match distance data 0 with
                | Some (back, data) when back > 0 ->
                    Some (Offset_delta { base = offset - back; data; size })
                | _ -> None)
            | 7 -> (
                if data + h > stop then None
                else
                  match
                    Option.bind
                      (read_exactly handle ~offset:data ~length:h)
                      (Object_id.of_bytes store.format)
                  with
                  | None -> None
                  | Some base ->
                      Some (Name_delta { base; data = data + h; size }))
            | number -> (
                match kind_of_type number with
                | None -> None
                | Some kind -> Some (Whole { kind; data; size }))))

  type built = Built of obj | Nothing of damage | Stop of failure

  let too_large pack offset =
    Stop (Too_large { pathname = pack.pack_path; offset = Some offset })

  let apply store pack index handle kind base steps =
    let stop = index.pack_size - hash_length store in
    let limit = store.limits.max_content_size in
    let rec go base = function
      | [] -> Built { kind; content = base }
      | Check { at; base = id } :: rest ->
          if is_object id { kind; content = base } then go base rest
          else
            Nothing
              {
                pathname = pack.pack_path;
                offset = Some at;
                problem = Wrong_id;
              }
      | Apply { at; data; size } :: rest -> (
          let damaged problem =
            Nothing { pathname = pack.pack_path; offset = Some at; problem }
          in
          match inflated handle ~start:data ~stop ~size with
          | Error failure -> Stop (unread pack.pack_path failure)
          | Ok (Error problem) -> damaged problem
          | Ok (Ok delta) -> (
              match Delta.apply ~max_size:limit ~base delta with
              | Ok result -> go result rest
              | Error Delta.Too_large -> too_large pack at
              | Error error -> damaged (Malformed_delta error)))
    in
    go base steps

  type counter = { mutable deltas : int }

  let descend store counter pack index place handle =
    let stop = index.pack_size - hash_length store in
    let limit = store.limits.max_content_size in
    let visited =
      Hashtbl.create
        (8
        [@mutaml.skip
          "the initial size of a hash table sets only when the table grows; no \
           result depends on it"])
    in
    let damaged at problem =
      Nothing { pathname = pack.pack_path; offset = Some at; problem }
    in
    let rec go at steps =
      Hashtbl.replace visited at ();
      match read_entry store index handle at with
      | None -> damaged at Malformed_entry_header
      | Some (Whole { kind; data; size }) -> (
          if size > limit then too_large pack at
          else
            match inflated handle ~start:data ~stop ~size with
            | Error failure -> Stop (unread pack.pack_path failure)
            | Ok (Error problem) -> damaged at problem
            | Ok (Ok base) -> apply store pack index handle kind base steps)
      | Some (Offset_delta { base; data; size }) ->
          follow at data size steps (fun steps -> next at base steps)
      | Some (Name_delta { base = id; data; size }) ->
          follow at data size steps (fun steps ->
              match reading pack.index_path (search store pack index id) with
              | Error failure -> Stop (unread pack.index_path failure)
              | Ok (Error item) -> Nothing item
              | Ok (Ok None) -> damaged at (Base_not_in_pack id)
              | Ok (Ok (Some base)) ->
                  next at base (Check { at = base; base = id } :: steps))
    and follow at data size steps k =
      if size > limit then too_large pack at
      else if counter.deltas >= store.limits.max_deltas then
        Stop Too_many_deltas
      else (
        counter.deltas <- counter.deltas + 1;
        k (Apply { at; data; size } :: steps))
    and next at base steps =
      if Hashtbl.mem visited base then damaged at Delta_cycle else go base steps
    in
    go place []

  let find store id =
    if Object_id.format id <> store.format then
      invalid_arg "Object_store.find: an object id of another object format";
    let damage = ref [] in
    let record item = damage := item :: !damage in
    let counter = { deltas = 0 } in
    let cursor = { id; database = 0; stage = 0 } in
    let rec search () =
      match next_place store cursor record with
      | Error failure -> Error failure
      | Ok None -> Ok { held = None; damage = List.rev !damage }
      | Ok (Some (Loose pathname)) -> (
          match read_loose store pathname with
          | Gives obj -> check obj ~pathname ~offset:None
          | Absent -> search ()
          | Damaged item ->
              record item;
              search ()
          | Failed failure -> Error failure)
      | Ok (Some (Packed (pack, index, place))) -> (
          match
            reading pack.pack_path (descend store counter pack index place)
          with
          | Error failure -> Error (unread pack.pack_path failure)
          | Ok (Built obj) ->
              check obj ~pathname:pack.pack_path ~offset:(Some place)
          | Ok (Nothing item) ->
              record item;
              search ()
          | Ok (Stop failure) -> Error failure)
    and check obj ~pathname ~offset =
      if is_object id obj then Ok { held = Some obj; damage = List.rev !damage }
      else (
        record { pathname; offset; problem = Wrong_id };
        search ())
    in
    search ()
end

include Make (Files)
