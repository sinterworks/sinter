(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The delta data of a deltified git object in a pack, as the page
    gitformat-pack defines it.

    Delta data is a byte sequence, an OCaml [string]: the size of the base, then
    the size of the result, each in the size encoding of the page, then
    instructions. In the size encoding, each byte gives its low seven bits, the
    first byte the least significant bits, and a byte whose high bit is 1 has
    one more byte after it. An instruction whose first byte has its high bit 1
    copies bytes of the base: bits 0 to 3 of that byte say which of four bytes
    of the offset follow, and bits 4 to 6 which of three bytes of the size, each
    little-endian, with an absent byte 0, and with the size 0 read as 65536. An
    instruction whose first byte is 1 to 127 adds that many bytes, which follow
    it. The first byte 0 is reserved. *)

type error =
  | Truncated
      (** the data ends inside a size, inside an instruction, or inside the
          bytes that an instruction adds *)
  | Base_size_differs
      (** the size of the base that the data states is not the length of the
          base *)
  | Too_large
      (** the size of the result that the data states is above the maximum size
      *)
  | Copy_outside_base
      (** an instruction copies bytes that lie, in part or in whole, after the
          end of the base *)
  | Reserved_instruction  (** an instruction starts with the byte 0 *)
  | Result_size_differs
      (** the instructions give more or fewer bytes than the size of the result
          that the data states *)

val apply : max_size:int -> base:string -> string -> (string, error) result
(** [apply ~max_size ~base delta] is the byte sequence that the instructions of
    [delta] give from [base]: the bytes that each instruction copies or adds, in
    the order of the instructions. Its length is the size of the result that
    [delta] states.

    It gives [Too_large] when that size is above [max_size] or above
    {!Sys.max_string_length}, before it takes memory for the result. It never
    takes memory for more bytes than that size, also when the instructions give
    more. It gives [Error] for the first problem that it meets, in this order:
    the size of the base ([Truncated], then [Base_size_differs]); the size of
    the result ([Truncated], then [Too_large]); each instruction in order, where
    an instruction that would give more bytes than that size gives
    [Result_size_differs]; and at the end [Result_size_differs] when the
    instructions gave fewer bytes. It raises [Invalid_argument] when [max_size]
    is negative. The time is linear in the length of [delta] and of the result.
*)
