(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Modules of the WebAssembly Core Specification 2.0 that an engine compiled,
    with the facts of their imports and their exports.

    A module lives as long as a value reaches it, or one of its instances; its
    engine lives at least as long. Two domains can use one module at the same
    time. *)

type t
(** A compiled module. *)

(** The value types of the WebAssembly Core Specification 2.0. *)
module Value_type : sig
  type t =
    | I32
    | I64
    | F32
    | F64
    | V128
    | Funcref
    | Externref
        (** The value types [i32], [i64], [f32], [f64], [v128], [funcref], and
            [externref]. *)
end

(** What an export of a module is, with the type of a function. *)
type extern =
  | Function of { params : Value_type.t list; results : Value_type.t list }
      (** a function, with its parameter types and its result types, in their
          order *)
  | Memory  (** a memory *)
  | Table  (** a table *)
  | Global  (** a global *)

(** Why a byte sequence gave no module. *)
type error =
  | Not_compiled of string
      (** the byte sequence is not a module in the binary format of the
          WebAssembly Core Specification 2.0 that is valid by that
          specification, or the engine stopped its decoding or its validation at
          a limit of its own; with the message of the engine for a person *)

val compile : Engine.t -> string -> (t, error) result
(** [compile engine bytes] is the module of the byte sequence [bytes]. It is
    [Error (Not_compiled _)] when [bytes] is not a module in the binary format
    of the WebAssembly Core Specification 2.0 that is valid by that
    specification, and it can be [Error (Not_compiled _)] when the engine stops
    the decoding or the validation of [bytes] at a limit of its own. A module
    that needs a feature of a later proposal, and a module in the text format,
    give [Error]. The function never raises. *)

val import_count : t -> int
(** [import_count m] is the number of imports of [m], 0 or more. *)

(** What an import of a module is, with its type. *)
type import_type =
  | Function_import of {
      params : Value_type.t list;
      results : Value_type.t list;
    }  (** a function, with its parameter types and its result types *)
  | Memory_import of { minimum : int; maximum : int option }
      (** a memory, with the limits of its type in pages of 65,536 bytes *)
  | Table_import of {
      element : Value_type.t;
      minimum : int;
      maximum : int option;
    }
      (** a table, with the type of its elements, [Funcref] or [Externref], and
          the limits of its type in elements *)
  | Global_import of { value_type : Value_type.t; mutable_ : bool }
      (** a global, with its value type and whether it is mutable *)

type import = { module_name : string; name : string; type_ : import_type }
(** An import: its module name, its name, and its type. *)

val imports : t -> import list
(** [imports m] is each import of [m], in the order of the import section of
    [m]. Its length is [import_count m]. *)

val exports : t -> (string * extern) list
(** [exports m] is each export of [m], its name and what it is, in the order of
    the export section of [m]. No two exports have the same name. *)
