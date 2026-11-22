(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Instances of modules, each with no import, in a store of its own, under
    limits of its own.

    An instance shares nothing with another instance: no memory, no table, no
    global, no function, and no fuel. The program gives an instance no import,
    so its code reaches only its own memories, tables, globals, and functions,
    and the values that an invocation gives it. Its code runs as the WebAssembly
    Core Specification 2.0 defines, with the program as its embedder, on a
    thread of its own whose native stack the engine sizes from the stack of the
    engine, so the stack of the caller does not change what the code gives. The
    only choices of the program in an instance are its limits, the stack of its
    engine, and the bits of a NaN.

    An instance holds its memories until {!release}. The caller releases each
    instance that it makes, on every path, with [Fun.protect]. A value that
    reaches an instance that the caller did not release also releases it when
    the garbage collector frees it. When a domain uses an instance while another
    domain uses it, the second use gives [Error Busy] and changes nothing.

    A function of this module raises [Failure] only when the engine stops on an
    internal fault. *)

(** A value of the type [i32] or [i64], as its bits. *)
module Value : sig
  type t = I32 of int32 | I64 of int64  (** a value of [i32] or of [i64] *)
end

type limits = private {
  fuel : int;
      (** the units of fuel for the instantiation and for all invocations of the
          instance together; most instructions cost 1 unit, and an instruction
          of bulk memory or of a table also costs 1 unit for each byte or
          element that it touches, after it ran *)
  memory : int;
      (** the most bytes that the memories of the instance can hold together *)
  table : int;
      (** the most elements that the tables of the instance can hold together *)
}
(** The limits of one instance. Each is 0 or more. *)

(** A limit of an instance. *)
type limit = Fuel | Memory | Table  (** fuel, memory, and table *)

(** Why numbers give no limits. *)
type limits_error =
  | Negative of limit  (** the value of this limit is negative *)

val limits :
  fuel:int -> memory:int -> table:int -> (limits, limits_error) result
(** [limits ~fuel ~memory ~table] is the limits with these values. It is
    [Error (Negative l)] for the first of [fuel], [memory], and [table] that is
    negative, in that order. *)

(** Why an instantiation or an invocation failed. [Stack_exhausted] and
    [Stopped _] are stops at limits of the program, which code that never ends
    can also give: a caller cannot tell such a stop from code that never ends.
*)
type failure =
  | Trap of string  (** the code trapped, with the message of the engine *)
  | Stack_exhausted
      (** the code exhausted its call stack: a stop at the limit of the program
          on the stack *)
  | Stopped of limit
      (** the program stopped the code at this limit: the code used all of its
          fuel, or the instantiation or an instruction [memory.grow] or
          [table.grow] asked for a size within the maximum of the memory or of
          the table that would pass the limit of memory or of table elements *)
  | Busy
      (** another domain used the instance at the same time; the use did nothing
      *)
  | Fault of string
      (** the engine could not run the code, such as when the system gave no
          memory, with its message for a person *)

type t
(** An instance. *)

(* @satisfies packs#isolate-adapters=v1
   Each instance is a new instance of its module, made with no import in a new
   store, and its code runs as the WebAssembly Core Specification 2.0 defines,
   with the program as its embedder and these limits as its only choices. *)

(* @satisfies text#report-stops-at-limits=v1
   A stop of the code at a limit of the program gives [Stack_exhausted] or
   [Stopped] with the limit, apart from a trap, so the caller can report the
   limit at which the program stopped. *)

(* @satisfies packs#end-adapter-code=v1
   Every instance has limits, and its fuel bounds all of its code: the
   instantiation and each invocation stop when the fuel is used, and the limit
   of memory bounds the work of one instruction. So the code of an instance
   always ends. *)

val create : Wasm_module.t -> limits -> (t, failure) result
(** [create m limits] is a new instance of [m], with no import, in a new store,
    under [limits]: the instantiation of [m], which runs its start function when
    it has one. It is [Error] when the instantiation fails.

    An instruction [memory.grow] or [table.grow] that asks for a size past the
    maximum of the type of its memory or its table gives -1 to the code, and the
    code goes on. The maximum of a memory whose type gives none is 65,536 pages,
    and that of a table whose type gives none is 4,294,967,295 elements. When
    the instantiation makes, or such an instruction asks for, a size within that
    maximum that would pass a limit of [limits], the program stops the code with
    [Stopped Memory] or [Stopped Table].

    @raise Invalid_argument when [Wasm_module.import_count m] is more than 0. *)

(** The result type of a function that {!invoke} invokes, with the OCaml type of
    its result. *)
module Result_type : sig
  type _ t =
    | Nothing : unit t  (** no result *)
    | I32 : int32 t  (** one result of the type [i32] *)
    | I64 : int64 t  (** one result of the type [i64] *)
end

val invoke :
  t -> string -> Value.t list -> 'a Result_type.t -> ('a, failure) result
(** [invoke i name arguments result_type] invokes the function export [name] of
    [i] with [arguments], and gives its result. It is [Error] when the
    invocation fails, and [Error Busy] when another domain uses [i] at the same
    time. Each invocation of [i] takes its fuel from what is left of the fuel of
    [i].

    @raise Invalid_argument
      when [i] was released, when [i] exports no function named [name], when the
      types of [arguments] are not the parameter types of that function, or when
      its result types are not those of [result_type]. *)

val memory_size : t -> string -> (int, failure) result
(** [memory_size i name] is the number of bytes of the memory export [name] of
    [i] now. It is [Error Busy] when another domain uses [i] at the same time.

    @raise Invalid_argument
      when [i] was released, or when [i] exports no memory named [name]. *)

val read :
  t -> memory:string -> address:int -> length:int -> (string, failure) result
(** [read i ~memory ~address ~length] is the [length] bytes of the memory export
    [memory] of [i] from [address] on, in their order. It is [Error Busy] when
    another domain uses [i] at the same time.

    @raise Invalid_argument
      when [i] was released, when [i] exports no memory named [memory], or when
      [address] or [length] is negative or [address + length] is more than the
      size of that memory. *)

val write :
  t -> memory:string -> address:int -> string -> (unit, failure) result
(** [write i ~memory ~address bytes] puts [bytes] into the memory export
    [memory] of [i], in their order, from [address] on. It changes no other byte
    of the memories of [i], and runs no code. It is [Error Busy], and writes
    nothing, when another domain uses [i] at the same time.

    @raise Invalid_argument
      when [i] was released, when [i] exports no memory named [memory], or when
      [address] is negative or [address + String.length bytes] is more than the
      size of that memory. *)

val release : t -> unit
(** [release i] frees the store of [i], with its memories and its tables. A
    release of an instance that was released does nothing. When another domain
    uses [i] at the same time, that domain frees the store at the end of its
    use. *)
