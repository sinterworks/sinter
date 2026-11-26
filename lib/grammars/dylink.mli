(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The memory information of a WebAssembly module: the sizes and the alignments
    of the parts of a memory and of a table that the module needs when a program
    links it, as the custom section [dylink.0] of the convention of dynamic
    linking of WebAssembly gives them. *)

type t = private {
  memory_size : int;  (** the bytes of the memory that the module needs *)
  memory_alignment : int;
      (** the alignment of those bytes, as a power of 2: the bytes start at a
          multiple of 2 to the power [memory_alignment] *)
  table_size : int;  (** the elements of the table that the module needs *)
  table_alignment : int;  (** the alignment of those elements, as a power of 2 *)
}
(** Memory information. Each field is from 0 to 4,294,967,295. *)

(** Why a byte sequence gave no memory information. *)
type error =
  | Not_a_module
      (** the byte sequence does not start with the magic number and the version
          1 of the binary format of the WebAssembly Core Specification 2.0; or
          its sections are not each a section identifier, a size as an unsigned
          LEB128 number of at most 32 bits, and that number of bytes; or a
          custom section does not start with a name: a length as such a number,
          and that number of bytes *)
  | No_section  (** no custom section has the name [dylink.0] *)
  | Several_sections
      (** more than one custom section has the name [dylink.0] *)
  | Malformed_section
      (** the custom section [dylink.0] is not a sequence of subsections, each a
          type byte, a size as an unsigned LEB128 number of at most 32 bits, and
          that number of bytes *)
  | Other_subsection of int
      (** the section has a subsection of this type, which is not 1; a program
          links no module that needs other modules or other links *)
  | No_memory_subsection  (** the section has no subsection of the type 1 *)
  | Several_memory_subsections
      (** the section has more than one subsection of the type 1 *)
  | Malformed_memory_subsection
      (** the subsection of the type 1 is not exactly four unsigned LEB128
          numbers of at most 32 bits each *)

val read : string -> (t, error) result
(** [read bytes] is the memory information of the module [bytes]: the four
    numbers of the subsection of the type 1 (the memory information) of its only
    custom section named [dylink.0], in the order of the fields of {!t}. It is
    [Error] when [bytes] has no such section with exactly one subsection, which
    is of the type 1, with the first reason of {!error} in the order of its
    constructors that holds. It reads only the identifiers and the sizes of the
    sections, and the custom sections; it does not check that the other sections
    are valid. The function never raises, and its time is linear in the length
    of [bytes]. *)
