(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The tables of a stack of the reftable format, in its versions 1 and 2, from
    their contents, and the file [tables.list] of a stack, as the page reftable
    gives them and the term [ref-commit] of the design [changes=v1] takes them.
*)

(** {1 Tables} *)

type t
(** The ref records of a table. *)

(** The value of a ref record. *)
type record =
  | Deletion  (** the record deletes the ref of its name: value type 0 *)
  | Object of Sinter_git_objects.Object_id.t
      (** the ref points to the git object with this object id: value type 1, or
          value type 2, whose second object id, the peeled object id, the record
          does not give *)
  | Symbolic of string
      (** the ref names the ref with this name, byte for byte as the record
          holds it: value type 3 *)

type error =
  | Not_a_table
      (** the content is shorter than a header and a footer of its version, or
          it does not start with [REFT] and the version 1 or 2, or, in version
          2, the hash id is not [sha1] or [s256] *)
  | Other_object_format
      (** the object ids of the table are not in the format that the reader
          takes: the table holds SHA-1 object ids in version 1 and with the hash
          id [sha1], and SHA-256 object ids with the hash id [s256] *)
  | Bad_footer
      (** the footer, the last bytes of the content, does not start with the
          header, its CRC-32 is not the CRC-32 of the footer bytes before it, or
          a position that it gives is neither 0 nor a position p with
          [header_length <= p < footer_start], where the position of the obj
          blocks is the field of the obj blocks shifted right by 5 bits *)
  | Bad_block of int
      (** the block that starts at this byte position from the start of the
          content is not a ref block in its form, as {!parse} gives it *)
  | Names_too_large
      (** the names of the ref records hold more bytes than the maximum *)

val parse :
  Sinter_git_objects.Object_id.format ->
  max_names:int ->
  string ->
  (t, error) result
(** [parse format ~max_names content] is the ref records of the table whose
    content is [content], with object ids in [format]. The header is the first
    24 bytes in version 1 and the first 28 bytes in version 2, and the footer is
    the last 68 bytes in version 1 and the last 72 bytes in version 2. The ref
    blocks follow the header: the first ref block starts at the byte 0, holds
    the header, and counts its length and its restart offsets from the start of
    the content. Each other block starts at the end of the block before it, as
    its length gives that end, with one exception: when the block size of the
    header is not 0, the end is not a multiple of the block size, and the bytes
    from the end to the smallest multiple of the block size above it are all
    0x00, the next block starts at that multiple. The ref blocks end at the
    smallest position of the footer that is not 0, or at the start of the footer
    when all are 0, or at the first block of the type [i] when the footer gives
    a position of the ref index, or, when the footer gives the position 0 for
    the log blocks, at a block of the type [g] right after the header. A ref
    block is in its form when each of these holds:

    - its type is [r], and its length is not above the block size when the block
      size is not 0;
    - its restart count is 1 or more, its restart offsets are in strictly
      ascending order, the first names its first record, and each names the
      start of a record whose prefix length is 0;
    - its records fill the bytes between the block header and the restart
      offsets, and each has a prefix length not above the length of the name of
      the record before it in the block, 0 for the first, a value type from 0 to
      3, and a value that ends inside the records;
    - the names of the records are in ascending byte order, each greater than
      the one before it, also across blocks.

    The index blocks, the obj blocks, and the log blocks are not read. It gives
    [Names_too_large] when the names of the records hold more than [max_names]
    bytes in all. The time and the memory of a call grow linearly with the
    length of [content] and with [max_names]. It raises [Invalid_argument] when
    [max_names] is negative, and no other exception. *)

val find : t -> string -> record option
(** [find table name] is the value of the ref record of [table] whose name is
    [name] byte for byte, or [None] when [table] holds no record of that name.
*)

val names_size : t -> int
(** [names_size table] is the number of bytes that the names of the ref records
    of [table] hold in all. *)

(** {1 The file [tables.list]} *)

type list_error =
  | No_final_line_feed
      (** the content is not empty and does not end with the byte 0x0A *)
  | Bad_table_name of string
      (** a line is not a table name: it is empty, it is [.] or [..], or it
          holds the byte [/] or 0x00 *)
  | Repeated_table_name of string  (** two lines give this table name *)

val table_names : string -> (string list, list_error) result
(** [table_names content] is the names of the tables of a stack whose file
    [tables.list] holds [content], from the oldest table to the newest. The
    content is lines, each followed by the byte 0x0A, and each line is the name
    of a file in the folder of the stack. The empty content names no table. *)
