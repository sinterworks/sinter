(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The delta data of the page gitformat-pack, written by hand for the tests of
    deltas. Each function writes exactly the bytes that its arguments name, also
    when they break a rule of the format. *)

type instruction =
  | Copy of int * int
      (** [Copy (offset, size)] copies [size] bytes of the base from [offset]; a
          size of 0x10000 is written with no size byte *)
  | Insert of string  (** inserts 1 to 127 bytes *)
  | Raw_instruction of string  (** these bytes, as they are *)

val varint : int -> string
(** [varint n] is [n] in the size encoding of the page gitformat-pack. *)

val delta : base_size:int -> result_size:int -> instruction list -> string
(** [delta ~base_size ~result_size instructions] is the delta data: the two
    sizes in the size encoding, then each instruction. *)

val apply : string -> instruction list -> string
(** [apply base instructions] is the result that the page gitformat-pack defines
    for the instructions on [base]. It raises [Invalid_argument] for a copy
    outside [base] and for a [Raw_instruction]. *)

val delta_between : string -> string -> instruction list
(** [delta_between base target] is a list of instructions whose result on [base]
    is [target]: a copy of the longest common prefix, inserts of 127 bytes or
    fewer, and a copy of the longest common suffix that remains. *)
