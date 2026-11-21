(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The files of an object database of git, written by hand for the tests of the
    object store, in the formats of the pages gitformat-loose and
    gitformat-pack. Each function writes exactly the bytes that its arguments
    name, also when they break a rule of a format. *)

type format = Sinter_git_objects.Object_id.format
type kind = Commit | Tree | Blob | Tag  (** the four kinds of git objects *)

val kind_name : kind -> string
(** [kind_name kind] is [commit], [tree], [blob], or [tag]. *)

val type_number : kind -> int
(** [type_number kind] is the object type of [kind] in a pack: 1 to 4. *)

val hash : format -> string -> string
(** [hash format bytes] is the SHA-1 ([Sha1]) or the SHA-256 ([Sha256]) of
    [bytes], as raw bytes. *)

val id : format -> kind -> string -> string
(** [id format kind content] is the object id of the object of [kind] with
    [content], as raw bytes: the hash of [<kind> <size>], the byte 0x00, and
    [content]. *)

val hex : string -> string
(** [hex bytes] is two lower-case hex digits for each byte of [bytes]. *)

val zlib : ?level:int -> string -> string
(** [zlib bytes] is a zlib stream of [bytes], compressed with [decompress] at
    [level] (default 6). *)

val zlib_stored : string -> string
(** [zlib_stored bytes] is a zlib stream of [bytes] in stored blocks, with no
    compression, written without [decompress]. *)

val adler32 : string -> int
(** [adler32 bytes] is the Adler-32 checksum of [bytes]. *)

val crc32 : string -> int
(** [crc32 bytes] is the CRC-32 of zlib of [bytes]. *)

val be32 : int -> string
(** [be32 n] is the low 32 bits of [n] in four bytes, the high byte first. *)

val be64 : int -> string
(** [be64 n] is [n] in eight bytes, the high byte first. *)

(** {1 Loose objects} *)

val loose_data : kind -> string -> string
(** [loose_data kind content] is [<kind> <size>], the byte 0x00, and [content]:
    the bytes that a loose object compresses. *)

val loose : ?stored:bool -> kind -> string -> string
(** [loose kind content] is the file of the loose object: {!zlib}, or
    {!zlib_stored} when [stored] is [true], of {!loose_data}. *)

val loose_path : string -> string
(** [loose_path id] is the pathname of the loose object of the raw id [id] in
    its object database: the first two hex digits, [/], and the rest. *)

(** {1 Deltas} *)

include module type of struct
  include Delta_data
end

(** {1 Packs} *)

(** One entry of a pack. *)
type entry =
  | Whole of kind * string  (** an object that is not a delta *)
  | Ofs_delta of int * string
      (** [Ofs_delta (base, delta)]: the base is the entry at the index [base]
          of the list; the index of the entry itself names the entry itself *)
  | Ofs_delta_distance of int * string
      (** [Ofs_delta_distance (distance, delta)]: the base is [distance] bytes
          before the entry *)
  | Ref_delta of string * string
      (** [Ref_delta (id, delta)]: the base is the object with the raw id [id]
      *)
  | Header_and of int * int * string
      (** [Header_and (type, size, bytes)]: the header of [type] and [size],
          then [bytes] as they are *)
  | Raw_entry of string  (** these bytes, as they are *)

val entry_header : int -> int -> string
(** [entry_header type size] is the n-byte type and length of a pack entry. *)

val offset_encoding : int -> string
(** [offset_encoding distance] is [distance] in the offset encoding of an
    OFS_DELTA. *)

type pack = {
  bytes : string;  (** the whole pack file *)
  offsets : int list;  (** the offset of each entry, in order *)
  crcs : int list;  (** the CRC-32 of the bytes of each entry, in order *)
  checksum : string;  (** the trailer: the hash of the bytes before it *)
}

val pack : ?version:int -> ?count:int -> format -> entry list -> pack
(** [pack format entries] is a pack of the [version] (default 2) with [count]
    (default the number of entries) in its header, then the entries, then the
    trailer. *)

val index_v1 : format -> pack:pack -> string list -> string
(** [index_v1 format ~pack ids] is a pack index of version 1 for [pack], where
    the raw id of the entry at each index of [pack] is the element of [ids] at
    the same index. An element [""] leaves the entry out of the index. *)

val index_v2 : ?large:int list -> format -> pack:pack -> string list -> string
(** [index_v2 format ~pack ids] is {!index_v1} in version 2. Each entry whose
    index is in [large] has its offset in the table of 8-byte offsets. *)

val index_entries_v1 :
  format -> pack_checksum:string -> (string * int) list -> string
(** [index_entries_v1 format ~pack_checksum entries] is a pack index of version
    1 of the raw ids and offsets of [entries], in the order given, with a fanout
    table from that order. *)

val index_entries_v2 :
  format -> pack_checksum:string -> (string * int * int) list -> string
(** [index_entries_v2 format ~pack_checksum entries] is a pack index of version
    2 of the raw ids, CRC-32 values, and offsets of [entries], in the order
    given. An offset of 2{^ 31} or more goes in the table of 8-byte offsets. *)

(** {1 Folders} *)

val write_file : string -> string -> unit
(** [write_file pathname bytes] writes [bytes] to the file at [pathname], and
    makes the folders in front of it. *)

val write_loose : ?stored:bool -> string -> format -> kind -> string -> string
(** [write_loose objects format kind content] writes the loose object in the
    object database at the pathname [objects], and gives its raw id. *)

val write_pack : string -> name:string -> pack -> string -> unit
(** [write_pack objects ~name pack index] writes [pack] and [index] as
    [pack/pack-<name>.pack] and [pack/pack-<name>.idx] in the object database at
    the pathname [objects]. *)
