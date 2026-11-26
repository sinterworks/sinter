(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** A test-only encoder of git reftable files, versions 1 and 2, from the page
    reftable and the runs of git 2.54.0.

    All fields longer than one byte use big-endian order. Object ids are raw
    byte sequences of 20 bytes (SHA-1) or 32 bytes (SHA-256). *)

type version =
  | V1  (** version 1, 24-byte header, 68-byte footer, SHA-1 *)
  | V2_sha1  (** version 2, 28-byte header, 72-byte footer, [sha1] *)
  | V2_sha256  (** version 2, 28-byte header, 72-byte footer, [s256] *)

type value =
  | Deletion  (** value type 0: deletes the ref in older tables *)
  | Object of string  (** value type 1: one raw object id *)
  | Peeled of string * string
      (** value type 2: raw object id and raw peeled object id *)
  | Symbolic of string  (** value type 3: symbolic ref target name *)
  | Raw of int * string
      (** arbitrary value type in 0..7 and raw value bytes, for damaged inputs
      *)

type record = {
  name : string;  (** ref name bytes *)
  update_index_delta : int64;
      (** non-negative offset from [min_update_index] *)
  value : value;  (** record value *)
}

type config = {
  version : version;  (** table version and hash format *)
  block_size : int;
      (** alignment block size in bytes; [0] writes unaligned blocks *)
  min_update_index : int64;  (** header [min_update_index] *)
  max_update_index : int64;  (** header [max_update_index] *)
  restart_interval : int;
      (** number of records per restart point; clamped to at least 1 *)
  max_records_per_block : int option;
      (** optional cap on records per ref block, to force multi-block tables
          also when [block_size = 0] *)
  pad_single_block : bool;
      (** when [false] and only one ref block exists, omits trailing block
          padding even when [block_size > 0] *)
  write_ref_index : bool;
      (** when [true] and more than one ref block exists, writes a ref index *)
  log_block : string option;
      (** when [Some bytes], appends a raw log block (type ['g'] and [bytes])
          after ref and ref-index blocks, and sets [log_position] in the footer
      *)
}

val default_config : config
(** Version 1, [block_size = 4096], update indexes [1L..1L],
    [restart_interval = 16], [pad_single_block = false],
    [write_ref_index = true], [log_block = None]. *)

val crc32 : string -> int32
(** [crc32 bytes] is the IEEE 802.3 (zlib) CRC-32 of [bytes]. *)

val encode_varint : int64 -> string
(** [encode_varint n] is the pack ofs-delta varint encoding of the non-negative
    integer [n]. Raises [Invalid_argument] when [n < 0L]. *)

val encode : ?config:config -> record list -> string
(** [encode ?config records] encodes [records] in the given order into a
    reftable file. When [records] is empty and [log_block] is [None], produces
    an empty table (header followed directly by footer). *)

val patch_footer_crc : version -> string -> string
(** [patch_footer_crc version table] recomputes and replaces the trailing 4-byte
    CRC-32 of [table] for [version]. Raises [Invalid_argument] when [table] is
    shorter than the footer of [version]. *)

val patch_header_and_footer :
  version ->
  ?block_size:int ->
  ?min_update_index:int64 ->
  ?max_update_index:int64 ->
  string ->
  string
(** [patch_header_and_footer version ?block_size ?min_update_index
     ?max_update_index table] updates the named fields in both the header and
    the footer copy of the header, and recomputes the footer CRC-32. *)
