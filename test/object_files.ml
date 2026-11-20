(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Id = Sinter_git_objects.Object_id

type format = Id.format
type kind = Commit | Tree | Blob | Tag

let kind_name = function
  | Commit -> "commit"
  | Tree -> "tree"
  | Blob -> "blob"
  | Tag -> "tag"

let type_number = function Commit -> 1 | Tree -> 2 | Blob -> 3 | Tag -> 4

let hash format bytes =
  match format with
  | Id.Sha1 -> Digestif.SHA1.(to_raw_string (digest_string bytes))
  | Id.Sha256 -> Digestif.SHA256.(to_raw_string (digest_string bytes))

let loose_data kind content =
  Printf.sprintf "%s %d\000%s" (kind_name kind) (String.length content) content

let id format kind content = hash format (loose_data kind content)

let hex bytes =
  String.concat ""
    (List.map
       (fun c -> Printf.sprintf "%02x" (Char.code c))
       (List.of_seq (String.to_seq bytes)))

let be32 n = String.init 4 (fun i -> Char.chr ((n lsr (8 * (3 - i))) land 0xff))
let be64 n = String.init 8 (fun i -> Char.chr ((n lsr (8 * (7 - i))) land 0xff))

let adler32 bytes =
  let a = ref 1 and b = ref 0 in
  String.iter
    (fun c ->
      a := (!a + Char.code c) mod 65521;
      b := (!b + !a) mod 65521)
    bytes;
  (!b lsl 16) lor !a

let crc_table =
  Array.init 256 (fun n ->
      let c = ref n in
      for _ = 1 to 8 do
        if !c land 1 = 1 then c := 0xedb88320 lxor (!c lsr 1) else c := !c lsr 1
      done;
      !c)

let crc32 bytes =
  let c = ref 0xffffffff in
  String.iter
    (fun ch -> c := crc_table.(!c lxor Char.code ch land 0xff) lxor (!c lsr 8))
    bytes;
  !c lxor 0xffffffff

let to_bigstring text =
  let b = De.bigstring_create (max 1 (String.length text)) in
  String.iteri (fun i c -> Bigarray.Array1.unsafe_set b i c) text;
  b

let zlib ?(level = 6) text =
  let i = De.bigstring_create De.io_buffer_size in
  let o = De.bigstring_create De.io_buffer_size in
  let w = De.Lz77.make_window ~bits:15 in
  let q = De.Queue.create 0x1000 in
  let r = Buffer.create 0x1000 in
  let p = ref 0 in
  let source = to_bigstring text in
  let refill buf =
    let len = min (String.length text - !p) De.io_buffer_size in
    for k = 0 to len - 1 do
      Bigarray.Array1.unsafe_set buf k
        (Bigarray.Array1.unsafe_get source (!p + k))
    done;
    p := !p + len;
    len
  in
  let flush buf len =
    for k = 0 to len - 1 do
      Buffer.add_char r (Bigarray.Array1.unsafe_get buf k)
    done
  in
  Zl.Higher.compress ~level ~dynamic:true ~w ~q ~refill ~flush i o;
  Buffer.contents r

let le16 n = String.init 2 (fun i -> Char.chr ((n lsr (8 * i)) land 0xff))

let zlib_stored text =
  let buffer = Buffer.create (String.length text + 16) in
  Buffer.add_string buffer "\x78\x01";
  let length = String.length text in
  let rec blocks start =
    let size = min 65535 (length - start) in
    let final = start + size >= length in
    Buffer.add_char buffer (if final then '\001' else '\000');
    Buffer.add_string buffer (le16 size);
    Buffer.add_string buffer (le16 (size lxor 0xffff));
    Buffer.add_string buffer (String.sub text start size);
    if not final then blocks (start + size)
  in
  blocks 0;
  Buffer.add_string buffer (be32 (adler32 text));
  Buffer.contents buffer

let loose ?(stored = false) kind content =
  let data = loose_data kind content in
  if stored then zlib_stored data else zlib data

let loose_path id =
  let h = hex id in
  String.sub h 0 2 ^ "/" ^ String.sub h 2 (String.length h - 2)

include Delta_data

type entry =
  | Whole of kind * string
  | Ofs_delta of int * string
  | Ofs_delta_distance of int * string
  | Ref_delta of string * string
  | Header_and of int * int * string
  | Raw_entry of string

let entry_header typ size =
  let buffer = Buffer.create 4 in
  let first = (typ lsl 4) lor (size land 0x0f) and rest = size lsr 4 in
  if rest = 0 then Buffer.add_char buffer (Char.chr first)
  else (
    Buffer.add_char buffer (Char.chr (first lor 0x80));
    Buffer.add_string buffer (varint rest));
  Buffer.contents buffer

let offset_encoding distance =
  let bytes = ref [ Char.chr (distance land 0x7f) ] in
  let n = ref (distance lsr 7) in
  while !n > 0 do
    decr n;
    bytes := Char.chr (0x80 lor (!n land 0x7f)) :: !bytes;
    n := !n lsr 7
  done;
  String.of_seq (List.to_seq !bytes)

type pack = {
  bytes : string;
  offsets : int list;
  crcs : int list;
  checksum : string;
}

let pack ?(version = 2) ?count format entries =
  let count = Option.value count ~default:(List.length entries) in
  let buffer = Buffer.create 256 in
  Buffer.add_string buffer "PACK";
  Buffer.add_string buffer (be32 version);
  Buffer.add_string buffer (be32 count);
  let offsets = ref [] and crcs = ref [] in
  List.iter
    (fun entry ->
      let offset = Buffer.length buffer in
      let previous = Array.of_list (List.rev (offset :: !offsets)) in
      let bytes =
        match entry with
        | Whole (kind, content) ->
            entry_header (type_number kind) (String.length content)
            ^ zlib content
        | Ofs_delta (base, data) ->
            entry_header 6 (String.length data)
            ^ offset_encoding (offset - previous.(base))
            ^ zlib data
        | Ofs_delta_distance (distance, data) ->
            entry_header 6 (String.length data)
            ^ offset_encoding distance ^ zlib data
        | Ref_delta (base, data) ->
            entry_header 7 (String.length data) ^ base ^ zlib data
        | Header_and (typ, size, bytes) -> entry_header typ size ^ bytes
        | Raw_entry bytes -> bytes
      in
      Buffer.add_string buffer bytes;
      offsets := offset :: !offsets;
      crcs := crc32 bytes :: !crcs)
    entries;
  let body = Buffer.contents buffer in
  let checksum = hash format body in
  {
    bytes = body ^ checksum;
    offsets = List.rev !offsets;
    crcs = List.rev !crcs;
    checksum;
  }

let fanout ids =
  String.concat ""
    (List.init 256 (fun n ->
         be32 (List.length (List.filter (fun id -> Char.code id.[0] <= n) ids))))

let index_entries_v1 format ~pack_checksum entries =
  let body =
    fanout (List.map fst entries)
    ^ String.concat "" (List.map (fun (id, offset) -> be32 offset ^ id) entries)
    ^ pack_checksum
  in
  body ^ hash format body

let index_body_v2 format ~pack_checksum ~is_large entries =
  let large = ref [] in
  let offsets =
    List.mapi
      (fun i (_, _, offset) ->
        if is_large i offset then (
          let at = List.length !large in
          large := offset :: !large;
          be32 ((1 lsl 31) lor at))
        else be32 offset)
      entries
  in
  let body =
    "\255tOc" ^ be32 2
    ^ fanout (List.map (fun (id, _, _) -> id) entries)
    ^ String.concat "" (List.map (fun (id, _, _) -> id) entries)
    ^ String.concat "" (List.map (fun (_, crc, _) -> be32 crc) entries)
    ^ String.concat "" offsets
    ^ String.concat "" (List.map be64 (List.rev !large))
    ^ pack_checksum
  in
  body ^ hash format body

let index_entries_v2 format ~pack_checksum entries =
  index_body_v2 format ~pack_checksum
    ~is_large:(fun _ offset -> offset >= 1 lsl 31)
    entries

let indexed ~pack ids =
  List.sort
    (fun (a, _, _, _) (b, _, _, _) -> String.compare a b)
    (List.filter
       (fun (id, _, _, _) -> id <> "")
       (List.mapi
          (fun i ((id, offset), crc) -> (id, offset, crc, i))
          (List.combine (List.combine ids pack.offsets) pack.crcs)))

let index_v1 format ~pack ids =
  index_entries_v1 format ~pack_checksum:pack.checksum
    (List.map (fun (id, offset, _, _) -> (id, offset)) (indexed ~pack ids))

let index_v2 ?(large = []) format ~pack ids =
  let entries = indexed ~pack ids in
  let entry_numbers =
    Array.of_list (List.map (fun (_, _, _, i) -> i) entries)
  in
  index_body_v2 format ~pack_checksum:pack.checksum
    ~is_large:(fun position _ -> List.mem entry_numbers.(position) large)
    (List.map (fun (id, offset, crc, _) -> (id, crc, offset)) entries)

let rec make_folders path =
  if path <> "" && path <> "/" && path <> "." && not (Sys.file_exists path) then (
    make_folders (Filename.dirname path);
    Unix.mkdir path 0o755)

let write_file pathname bytes =
  make_folders (Filename.dirname pathname);
  Out_channel.with_open_bin pathname (fun channel ->
      Out_channel.output_string channel bytes)

let write_loose ?stored objects format kind content =
  let id = id format kind content in
  write_file
    (Filename.concat objects (loose_path id))
    (loose ?stored kind content);
  id

let write_pack objects ~name pack index =
  let base = Filename.concat objects ("pack/pack-" ^ name) in
  write_file (base ^ ".pack") pack.bytes;
  write_file (base ^ ".idx") index
