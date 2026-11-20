(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Object_id = Sinter_git_objects.Object_id

type record = Deletion | Object of Object_id.t | Symbolic of string
type t = { names : string array; records : record array; names_size : int }

type error =
  | Not_a_table
  | Other_object_format
  | Bad_footer
  | Bad_block of int
  | Names_too_large

exception Fail of error

let crc32 s ~start ~length =
  let c = ref 0xFFFFFFFF in
  for i = start to start + length - 1 do
    c := !c lxor Char.code s.[i];
    for _ = 1 to 8 do
      c := if !c land 1 = 1 then 0xEDB88320 lxor (!c lsr 1) else !c lsr 1
    done
  done;
  !c lxor 0xFFFFFFFF

let uint s at width =
  let v = ref 0 in
  for i = at to at + width - 1 do
    v := (!v lsl 8) lor Char.code s.[i]
  done;
  !v

let position s at =
  if Char.code s.[at] >= 0x80 then raise (Fail Bad_footer) else uint s at 8

type header = {
  header_length : int;
  footer_length : int;
  block_size : int;
  format : Object_id.format;
}

(* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
   A table is in version 1, with a header of 24 bytes and SHA-1 object ids,
   or in version 2, with a header of 28 bytes that ends with the hash id
   sha1 or s256; its object ids must be in the object format of the
   repository. *)
let header format s =
  let header_length, footer_length =
    if String.starts_with ~prefix:"REFT\001" s then (24, 68)
    else if String.starts_with ~prefix:"REFT\002" s then (28, 72)
    else raise (Fail Not_a_table)
  in
  if String.length s < header_length + footer_length then
    raise (Fail Not_a_table);
  let table_format =
    match (s.[4], String.sub s 24 4) with
    | '\001', _ | '\002', "sha1" -> Object_id.Sha1
    | '\002', "s256" -> Object_id.Sha256
    | _ -> raise (Fail Not_a_table)
  in
  if table_format <> format then raise (Fail Other_object_format);
  { header_length; footer_length; block_size = uint s 5 3; format }

(* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
   The footer repeats the header, ends with the CRC-32 of the footer bytes
   before it, and gives positions inside the table; the ref blocks end at the
   smallest position that it gives, or at the footer. *)
let footer h s =
  let start = String.length s - h.footer_length in
  if String.sub s start h.header_length <> String.sub s 0 h.header_length then
    raise (Fail Bad_footer);
  let crc_at = start + h.footer_length - 4 in
  if crc32 s ~start ~length:(h.footer_length - 4) <> uint s crc_at 4 then
    raise (Fail Bad_footer);
  let field n = start + h.header_length + (8 * n) in
  let ref_index = position s (field 0) in
  let log = position s (field 3) in
  let positions =
    [ ref_index; position s (field 1) lsr 5; position s (field 2); log ]
    @ [ position s (field 4) ]
  in
  let given = List.filter (fun p -> p <> 0) positions in
  if List.exists (fun p -> p < h.header_length || p >= start) given then
    raise (Fail Bad_footer);
  (List.fold_left min start given, ref_index <> 0, log = 0)

type cursor = { s : string; block : int; limit : int; mutable at : int }

let bad c = raise (Fail (Bad_block c.block))

let byte c =
  if c.at >= c.limit then bad c;
  let b = Char.code c.s.[c.at] in
  c.at <- c.at + 1;
  b

let varint c =
  let b = byte c in
  let rec more v b =
    if b land 0x80 = 0 then v
    else if
      v
      >= max_int
         lsr (7
             [@mutaml.skip
               "8 gives the same results: a varint whose value goes above \
                max_int lsr 8 holds a prefix length, a suffix length, or a \
                target length above the length of the content, and the checks \
                of the record reject each of those with the same error"])
    then bad c
    else
      let b = byte c in
      more (((v + 1) lsl 7) lor (b land 0x7F)) b
  in
  more (b land 0x7F) b

let rec skip_varint c = if byte c land 0x80 <> 0 then skip_varint c

let bytes c n =
  if n > c.limit - c.at then bad c;
  let v = String.sub c.s c.at n in
  c.at <- c.at + n;
  v

type names = {
  max_names : int;
  mutable size : int;
  mutable last : string option;
  mutable entries : (string * record) list;
}

let value h c = function
  | 0 -> Deletion
  | (1 | 2) as kind -> (
      let length = Object_id.length h.format in
      let id = bytes c length in
      if kind = 2 then ignore (bytes c length);
      match Object_id.of_bytes h.format id with
      | Some id -> Object id
      | None -> bad c)
  | 3 -> Symbolic (bytes c (varint c))
  | _ -> bad c

let record h names c ~previous ~restart =
  let prefix = varint c in
  if prefix > String.length previous || (restart && prefix <> 0) then bad c;
  let packed = varint c in
  let name = String.sub previous 0 prefix ^ bytes c (packed lsr 3) in
  if String.length name > names.max_names - names.size then
    raise (Fail Names_too_large);
  skip_varint c;
  let v = value h c (packed land 7) in
  (match names.last with
  | Some last when String.compare last name >= 0 -> bad c
  | _ -> ());
  names.size <- names.size + String.length name;
  names.last <- Some name;
  names.entries <- (name, v) :: names.entries;
  name

(* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
   A ref block starts with the type r and its length, ends with its restart
   offsets and their count, and holds between them records whose names are
   prefix-compressed and in strictly ascending byte order; each restart
   offset, the first at the first record, names a record with no prefix. *)
let ref_block h names s ~block ~type_at ~bound =
  let length = uint s (type_at + 1) 3 in
  let block_end = block + length in
  let c = { s; block; limit = block_end; at = type_at + 4 } in
  if
    block_end > bound
    || (h.block_size <> 0 && length > h.block_size)
    || (block_end < c.at)
       [@mutaml.skip
         "any bound from 2 to c.at + 8 gives the same results: the bound keeps \
          the read of the restart count inside the content, and a block that \
          ends before c.at + 8 cannot hold a record of 3 bytes, one restart \
          offset, and the restart count, so the checks below reject it with \
          the same error"]
  then bad c;
  let count = uint s (block_end - 2) 2 in
  let restarts_at = block_end - 2 - (3 * count) in
  if
    (restarts_at < c.at)
    [@mutaml.skip
      "any bound from 0 to c.at + 3 gives the same results: the bound keeps \
       the reads of the restart offsets inside the content, and when the \
       restart offsets start before c.at + 3, no record of 3 bytes fits before \
       them, so the checks below reject the block with the same error"]
  then bad c;
  let restarts =
    List.init count (fun n -> block + uint s (restarts_at + (3 * n)) 3)
  in
  (match restarts with first :: _ when first = c.at -> () | _ -> bad c);
  let c = { c with limit = restarts_at } in
  let rec records previous restarts =
    if c.at >= c.limit then (if restarts <> [] then bad c)
    else
      let restart, rest =
        match restarts with
        | next :: rest when next = c.at -> (true, rest)
        | _ -> (false, restarts)
      in
      records (record h names c ~previous ~restart) rest
  in
  records "" restarts;
  block_end

(* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
   The ref blocks follow the header, each at the end of the block before it
   or, after padding of 0x00 bytes, at the next multiple of the block size;
   they end at the bound that the footer gives, at the first index block
   when the table has a ref index, or at the first log block when the footer
   gives the position 0 for the log blocks. *)
let parse format ~max_names s =
  if max_names < 0 then invalid_arg "Reftable.parse: a negative maximum";
  let names = { max_names; size = 0; last = None; entries = [] } in
  match
    let h = header format s in
    let bound, has_index, no_log = footer h s in
    let rec blocks block ~type_at =
      if type_at < bound then
        match s.[type_at] with
        | 'r' ->
            let block_end = ref_block h names s ~block ~type_at ~bound in
            let next =
              if
                h.block_size = 0
                || block_end mod h.block_size = 0
                || block_end = bound
                || s.[block_end] <> '\000'
              then block_end
              else
                let next = ((block_end / h.block_size) + 1) * h.block_size in
                if next > bound then raise (Fail (Bad_block block));
                for i = block_end to next - 1 do
                  if s.[i] <> '\000' then raise (Fail (Bad_block block))
                done;
                next
            in
            blocks next ~type_at:next
        | 'i' when has_index -> ()
        | 'g' when no_log -> ()
        | _ -> raise (Fail (Bad_block block))
    in
    blocks 0 ~type_at:h.header_length
  with
  | () ->
      let entries = Array.of_list (List.rev names.entries) in
      Ok
        {
          names = Array.map fst entries;
          records = Array.map snd entries;
          names_size = names.size;
        }
  | exception Fail error -> Error error

let find table name =
  let rec search low high =
    if low >= high then None
    else
      let middle = (low + high) / 2 in
      let order = String.compare name table.names.(middle) in
      if order < 0 then search low middle
      else if order > 0 then search (middle + 1) high
      else Some table.records.(middle)
  in
  search 0 (Array.length table.names)

let names_size table = table.names_size

type list_error =
  | No_final_line_feed
  | Bad_table_name of string
  | Repeated_table_name of string

module Names = Set.Make (String)

(* @satisfies changes#{give-ref-commits=v1, give-head-commits=v1}
   The file tables.list names the tables of the stack, one file name of the
   stack folder on each line, from the oldest to the newest. *)
let table_names content =
  if content = "" then Ok []
  else if content.[String.length content - 1] <> '\n' then
    Error No_final_line_feed
  else
    let lines =
      String.split_on_char '\n'
        (String.sub content 0 (String.length content - 1))
    in
    let rec check seen = function
      | [] -> Ok lines
      | line :: rest ->
          if
            line = "" || line = "." || line = ".." || String.contains line '/'
            || String.contains line '\000'
          then Error (Bad_table_name line)
          else if Names.mem line seen then Error (Repeated_table_name line)
          else check (Names.add line seen) rest
    in
    check Names.empty lines
