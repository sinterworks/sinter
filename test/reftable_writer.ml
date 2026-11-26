(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type version = V1 | V2_sha1 | V2_sha256

type value =
  | Deletion
  | Object of string
  | Peeled of string * string
  | Symbolic of string
  | Raw of int * string

type record = { name : string; update_index_delta : int64; value : value }

type config = {
  version : version;
  block_size : int;
  min_update_index : int64;
  max_update_index : int64;
  restart_interval : int;
  max_records_per_block : int option;
  pad_single_block : bool;
  write_ref_index : bool;
  log_block : string option;
}

let default_config =
  {
    version = V1;
    block_size = 4096;
    min_update_index = 1L;
    max_update_index = 1L;
    restart_interval = 16;
    max_records_per_block = None;
    pad_single_block = false;
    write_ref_index = true;
    log_block = None;
  }

let crc32_table =
  Array.init 256 (fun i ->
      let c = ref (Int32.of_int i) in
      for _ = 0 to 7 do
        if Int32.logand !c 1l <> 0l then
          c := Int32.logxor (Int32.shift_right_logical !c 1) 0xedb88320l
        else c := Int32.shift_right_logical !c 1
      done;
      !c)

let crc32_sub s off len =
  let c = ref 0xffffffffl in
  for i = off to off + len - 1 do
    let b = Char.code (String.unsafe_get s i) in
    let idx =
      Int32.to_int (Int32.logand (Int32.logxor !c (Int32.of_int b)) 0xffl)
    in
    c := Int32.logxor (Int32.shift_right_logical !c 8) crc32_table.(idx)
  done;
  Int32.logxor !c 0xffffffffl

let crc32 s = crc32_sub s 0 (String.length s)

let add_u16 buf n =
  Buffer.add_char buf (Char.chr ((n lsr 8) land 0xff));
  Buffer.add_char buf (Char.chr (n land 0xff))

let add_u24 buf n =
  Buffer.add_char buf (Char.chr ((n lsr 16) land 0xff));
  Buffer.add_char buf (Char.chr ((n lsr 8) land 0xff));
  Buffer.add_char buf (Char.chr (n land 0xff))

let add_u32 buf n =
  Buffer.add_char buf
    (Char.chr
       (Int32.to_int (Int32.logand (Int32.shift_right_logical n 24) 0xffl)));
  Buffer.add_char buf
    (Char.chr
       (Int32.to_int (Int32.logand (Int32.shift_right_logical n 16) 0xffl)));
  Buffer.add_char buf
    (Char.chr
       (Int32.to_int (Int32.logand (Int32.shift_right_logical n 8) 0xffl)));
  Buffer.add_char buf (Char.chr (Int32.to_int (Int32.logand n 0xffl)))

let add_u64 buf n =
  for shift = 7 downto 0 do
    let b =
      Int64.to_int
        (Int64.logand (Int64.shift_right_logical n (shift * 8)) 0xffL)
    in
    Buffer.add_char buf (Char.chr b)
  done

let encode_varint n =
  if Int64.compare n 0L < 0 then
    invalid_arg "Reftable_writer.encode_varint: negative";
  let rec loop acc v =
    let byte = Int64.to_int (Int64.logand v 0x7fL) in
    let acc = (byte lor if acc = [] then 0 else 0x80) :: acc in
    if Int64.compare v 0x7fL <= 0 then acc
    else loop acc (Int64.sub (Int64.shift_right_logical v 7) 1L)
  in
  let bytes = loop [] n in
  String.init (List.length bytes) (fun i -> Char.chr (List.nth bytes i))

let header_len = function V1 -> 24 | V2_sha1 | V2_sha256 -> 28
let footer_len = function V1 -> 68 | V2_sha1 | V2_sha256 -> 72

let encode_header cfg =
  let buf = Buffer.create (header_len cfg.version) in
  Buffer.add_string buf "REFT";
  Buffer.add_char buf
    (Char.chr (match cfg.version with V1 -> 1 | V2_sha1 | V2_sha256 -> 2));
  add_u24 buf cfg.block_size;
  add_u64 buf cfg.min_update_index;
  add_u64 buf cfg.max_update_index;
  (match cfg.version with
  | V1 -> ()
  | V2_sha1 -> Buffer.add_string buf "sha1"
  | V2_sha256 -> Buffer.add_string buf "s256");
  Buffer.contents buf

let common_prefix_len a b =
  let limit = min (String.length a) (String.length b) in
  let rec loop i = if i >= limit || a.[i] <> b.[i] then i else loop (i + 1) in
  loop 0

let encode_ref_record ~prev ~restart (rec_ : record) =
  let plen = if restart then 0 else common_prefix_len prev rec_.name in
  let slen = String.length rec_.name - plen in
  let vtype, payload =
    match rec_.value with
    | Deletion -> (0, "")
    | Object id -> (1, id)
    | Peeled (id, peeled) -> (2, id ^ peeled)
    | Symbolic target ->
        (3, encode_varint (Int64.of_int (String.length target)) ^ target)
    | Raw (vt, data) -> (vt, data)
  in
  let buf = Buffer.create 64 in
  Buffer.add_string buf (encode_varint (Int64.of_int plen));
  Buffer.add_string buf
    (encode_varint
       (Int64.logor
          (Int64.shift_left (Int64.of_int slen) 3)
          (Int64.of_int (vtype land 7))));
  Buffer.add_substring buf rec_.name plen slen;
  Buffer.add_string buf (encode_varint rec_.update_index_delta);
  Buffer.add_string buf payload;
  Buffer.contents buf

let encode_index_record ~prev ~restart ~name ~block_pos =
  let plen = if restart then 0 else common_prefix_len prev name in
  let slen = String.length name - plen in
  let buf = Buffer.create 32 in
  Buffer.add_string buf (encode_varint (Int64.of_int plen));
  Buffer.add_string buf (encode_varint (Int64.shift_left (Int64.of_int slen) 3));
  Buffer.add_substring buf name plen slen;
  Buffer.add_string buf (encode_varint (Int64.of_int block_pos));
  Buffer.contents buf

let finish_block ~prefix ~kind ~records_buf ~restarts =
  let restarts = List.rev restarts in
  let restart_count = List.length restarts in
  let block_len =
    String.length prefix + 4 + Buffer.length records_buf + (3 * restart_count)
    + 2
  in
  let out = Buffer.create block_len in
  Buffer.add_string out prefix;
  Buffer.add_char out kind;
  add_u24 out block_len;
  Buffer.add_buffer out records_buf;
  List.iter (add_u24 out) restarts;
  add_u16 out restart_count;
  Buffer.contents out

let pack_blocks ~header_prefix ~block_size ~restart_interval
    ~max_records_per_block ~kind ~encode_one ~name_of items =
  let interval = max 1 restart_interval in
  let blocks = ref [] in
  let prefix = ref header_prefix in
  let records_buf = Buffer.create 256 in
  let restarts = ref [] in
  let count_in_block = ref 0 in
  let prev = ref "" in
  let last_name = ref "" in
  let flush () =
    if !count_in_block > 0 then (
      let bytes =
        finish_block ~prefix:!prefix ~kind ~records_buf ~restarts:!restarts
      in
      blocks := (bytes, !last_name) :: !blocks;
      prefix := "";
      Buffer.clear records_buf;
      restarts := [];
      count_in_block := 0;
      prev := "")
  in
  List.iter
    (fun item ->
      let name = name_of item in
      let want_restart = !count_in_block mod interval = 0 in
      let encoded = encode_one ~prev:!prev ~restart:want_restart item in
      let restart_extra = if want_restart then 3 else 0 in
      let next_len =
        String.length !prefix + 4 + Buffer.length records_buf
        + String.length encoded
        + (3 * List.length !restarts)
        + restart_extra + 2
      in
      let hit_cap =
        match max_records_per_block with
        | Some cap -> !count_in_block >= max 1 cap
        | None -> false
      in
      let must_split =
        !count_in_block > 0
        && (hit_cap || (block_size > 0 && next_len > block_size))
      in
      if must_split then flush ();
      let restart = !count_in_block mod interval = 0 in
      let encoded =
        if must_split then encode_one ~prev:"" ~restart:true item else encoded
      in
      (if restart then
         let off = String.length !prefix + 4 + Buffer.length records_buf in
         restarts := off :: !restarts);
      Buffer.add_string records_buf encoded;
      incr count_in_block;
      prev := name;
      last_name := name)
    items;
  flush ();
  List.rev !blocks

let pad_to_block_size buf block_size =
  if block_size > 0 then
    let rem = Buffer.length buf mod block_size in
    if rem <> 0 then
      Buffer.add_string buf (String.make (block_size - rem) '\000')

let encode ?(config = default_config) records =
  let header = encode_header config in
  let out = Buffer.create 512 in
  let ref_index_pos = ref 0 in
  (match records with
  | [] -> Buffer.add_string out header
  | _ ->
      let ref_blocks =
        pack_blocks ~header_prefix:header ~block_size:config.block_size
          ~restart_interval:config.restart_interval
          ~max_records_per_block:config.max_records_per_block ~kind:'r'
          ~encode_one:(fun ~prev ~restart r ->
            encode_ref_record ~prev ~restart r)
          ~name_of:(fun r -> r.name)
          records
      in
      let multi = List.length ref_blocks > 1 in
      let block_entries = ref [] in
      List.iter
        (fun (bytes, last_name) ->
          let pos = Buffer.length out in
          Buffer.add_string out bytes;
          if multi || config.pad_single_block then
            pad_to_block_size out config.block_size;
          block_entries := (last_name, pos) :: !block_entries)
        ref_blocks;
      let entries = List.rev !block_entries in
      if config.write_ref_index && multi then
        let rec build_levels current =
          let idx_blocks =
            pack_blocks ~header_prefix:"" ~block_size:config.block_size
              ~restart_interval:config.restart_interval
              ~max_records_per_block:None ~kind:'i'
              ~encode_one:(fun ~prev ~restart (name, block_pos) ->
                encode_index_record ~prev ~restart ~name ~block_pos)
              ~name_of:fst current
          in
          let next_entries = ref [] in
          List.iter
            (fun (bytes, last_name) ->
              let pos = Buffer.length out in
              Buffer.add_string out bytes;
              pad_to_block_size out config.block_size;
              next_entries := (last_name, pos) :: !next_entries)
            idx_blocks;
          let next_entries = List.rev !next_entries in
          match next_entries with
          | [ (_, root_pos) ] -> ref_index_pos := root_pos
          | many when List.length many < List.length current ->
              build_levels many
          | (_, root_pos) :: _ -> ref_index_pos := root_pos
          | [] -> ()
        in
        build_levels entries);
  let log_pos =
    match config.log_block with
    | None -> 0
    | Some body ->
        let pos = Buffer.length out in
        Buffer.add_char out 'g';
        Buffer.add_string out body;
        pos
  in
  let footer_body = Buffer.create (footer_len config.version) in
  Buffer.add_string footer_body header;
  add_u64 footer_body (Int64.of_int !ref_index_pos);
  add_u64 footer_body 0L;
  add_u64 footer_body 0L;
  add_u64 footer_body (Int64.of_int log_pos);
  add_u64 footer_body 0L;
  let body_str = Buffer.contents footer_body in
  let crc = crc32 body_str in
  Buffer.add_string out body_str;
  add_u32 out crc;
  Buffer.contents out

let patch_footer_crc version table =
  let fl = footer_len version in
  let len = String.length table in
  if len < fl then invalid_arg "Reftable_writer.patch_footer_crc: too short";
  let fstart = len - fl in
  let crc = crc32_sub table fstart (fl - 4) in
  let buf = Bytes.of_string table in
  let set i v = Bytes.set buf (len - 4 + i) (Char.chr v) in
  set 0 (Int32.to_int (Int32.logand (Int32.shift_right_logical crc 24) 0xffl));
  set 1 (Int32.to_int (Int32.logand (Int32.shift_right_logical crc 16) 0xffl));
  set 2 (Int32.to_int (Int32.logand (Int32.shift_right_logical crc 8) 0xffl));
  set 3 (Int32.to_int (Int32.logand crc 0xffl));
  Bytes.to_string buf

let write_u24_at buf off n =
  Bytes.set buf off (Char.chr ((n lsr 16) land 0xff));
  Bytes.set buf (off + 1) (Char.chr ((n lsr 8) land 0xff));
  Bytes.set buf (off + 2) (Char.chr (n land 0xff))

let write_u64_at buf off n =
  for shift = 7 downto 0 do
    let b =
      Int64.to_int
        (Int64.logand (Int64.shift_right_logical n (shift * 8)) 0xffL)
    in
    Bytes.set buf (off + (7 - shift)) (Char.chr b)
  done

let patch_header_and_footer version ?block_size ?min_update_index
    ?max_update_index table =
  let fl = footer_len version in
  let len = String.length table in
  if len < header_len version + fl then
    invalid_arg "Reftable_writer.patch_header_and_footer: too short";
  let buf = Bytes.of_string table in
  let fstart = len - fl in
  let apply base =
    Option.iter (fun bs -> write_u24_at buf (base + 5) bs) block_size;
    Option.iter (fun v -> write_u64_at buf (base + 8) v) min_update_index;
    Option.iter (fun v -> write_u64_at buf (base + 16) v) max_update_index
  in
  apply 0;
  apply fstart;
  patch_footer_crc version (Bytes.to_string buf)
