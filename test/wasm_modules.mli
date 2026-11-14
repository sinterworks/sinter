(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** WebAssembly modules for the tests, written as text or as bytes, and the
    verdicts of the reference interpreter of the WebAssembly Core Specification
    2.0 on them. *)

val of_text : string -> string
(** [of_text text] is the binary format of the module that the text [text]
    writes. It raises [Failure] when the reference interpreter cannot parse
    [text], or when the module is not valid. *)

val of_text_unchecked : string -> string
(** [of_text_unchecked text] is [of_text text] with no validation, for a module
    that the text format can write but that Core 2.0 does not allow. *)

val hex : string -> string
(** [hex bytes] is the lower-case hex text of [bytes]. *)

val of_hex : string -> string
(** [of_hex text] is the bytes of the hex text [text]. It raises [Failure] when
    [text] is not a hex text. *)

(** {1 The binary format} *)

val u32 : int -> string
(** [u32 n] is the unsigned LEB128 encoding of [n], from 0 to 2^32 - 1. *)

val s32 : int32 -> string
(** [s32 n] is the signed LEB128 encoding of [n]. *)

val s64 : int64 -> string
(** [s64 n] is the signed LEB128 encoding of [n]. *)

val vec : string list -> string
(** [vec items] is the number of [items] as a [u32], then each item. *)

val name : string -> string
(** [name text] is the length of [text] as a [u32], then [text]. *)

val section : int -> string -> string
(** [section id payload] is the section [id] with the content [payload]. *)

val module_ : string list -> string
(** [module_ sections] is the magic number, the version 1, then [sections]. *)

(** {1 Adapters as bytes} *)

type part = {
  types : string list;
      (** the encoded function types after the four of the adapter *)
  memory : string;  (** the content of the memory section *)
  extra_sections : (int * string) list;
      (** sections, each with its id, placed in the order of the ids *)
  feature : string;
      (** the encoded expression of the function [feature], of the type
          [[] -> []], without its [end]; [sinter_interface] calls it first *)
  extra_funcs : (int * string) list;
      (** functions after [feature], each a type index and an encoded body
          without its [end] and with no locals *)
  globals : string list;  (** the encoded globals *)
}
(** The parts of an adapter that a test changes. The type indexes 0 to 3 are
    [[] -> [i32]], [[i32] -> [i32]], [[i32 i32 i32 i32] -> [i64]], and
    [[] -> []]. The functions are [sinter_interface] (0), [sinter_alloc] (1),
    [sinter_recognise] (2), [sinter_bind] (3), and [feature] (4). *)

val base : part
(** [base] is the parts of an adapter that is valid: one memory of one page, a
    feature that does nothing, and no other type, section, function, or global.
*)

val adapter : part -> string
(** [adapter part] is the bytes of the adapter with [part]. *)

(** {1 The reference interpreter} *)

type verdict =
  | Refused of string  (** the module does not decode or does not validate *)
  | Accepted  (** the module is a WebAssembly module of Core 2.0 *)

val reference : string -> verdict
(** [reference bytes] is the verdict of the reference interpreter on [bytes]. It
    never raises. *)

type decision =
  | Valid
  | Invalid
  | Unknown
      (** the reference cannot decide without a choice of a program, such as
          when the call stack is exhausted *)

val reference_decision : string -> decision
(** [reference_decision bytes] is whether [bytes] is a valid adapter, by the
    conditions of the design, with the reference interpreter as the program. It
    runs the code of [bytes]; give it only modules whose code ends. *)
