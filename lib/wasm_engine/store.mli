(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Stores that hold several instances, linked by their imports, under limits of
    their own.

    A store shares nothing with another store, or with an instance of
    {!Instance}: no memory, no table, no global, no function, and no fuel. The
    instances of one store share what their imports name: an instance can import
    an export of an instance that was made before it in the same store, a new
    global of the type [i32], or a function that traps. The code of the
    instances runs as the WebAssembly Core Specification 2.0 defines, with the
    program as its embedder, on a thread of its own whose native stack the
    engine sizes from the stack of the engine.

    The limits of a store bound all of its instances together. An instruction
    [memory.grow] or [table.grow] never gives -1 in a store: each growth that
    the store does not make stops the code (see {!create}).

    A store holds its memories until {!release}. The caller releases each store
    that it makes, on every path, with [Fun.protect]. When no value reaches a
    store that the caller did not release, the garbage collector releases the
    store. When a domain uses a store while another domain uses it, the second
    use gives [Error Busy] and changes nothing. *)

type t
(** A store. *)

type instance
(** An instance in a store. It is valid only with the store that made it. *)

(** Where the value of an import comes from. *)
type import =
  | Export of instance * string
      (** the export of this name of this instance of the same store *)
  | Global of { mutable_ : bool; value : int32 }
      (** a new global of the type [i32], mutable or not, with this value *)
  | Trap
      (** a new function of the type of the import that traps each time that
          code invokes it *)

val create : Engine.t -> Instance.limits -> t
(** [create engine limits] is a new store of [engine], with no instance, under
    [limits]. The fuel of [limits] is for all instantiations and invocations in
    the store together. The memories and the tables of the store hold at most
    the bytes and the elements of [limits], all instances together.

    An instantiation, an instruction [memory.grow] or [table.grow], or a growth
    by {!grow_memory} or {!grow_table} that asks for a size past the maximum of
    the type of its memory or of its table, or that would pass a limit of
    [limits], stops: with [Stopped Memory] for a memory and [Stopped Table] for
    a table. The maximum of a memory whose type gives none is 65,536 pages, and
    that of a table whose type gives none is 4,294,967,295 elements.

    @raise Failure when the engine stops on an internal fault. *)

val instantiate :
  t -> Wasm_module.t -> import list -> (instance, Instance.failure) result
(** [instantiate store m imports] is a new instance of [m] in [store], whose
    imports, in the order of {!Wasm_module.imports}[ m], come from [imports]:
    the instantiation of [m], which runs its start function when it has one. It
    is [Error] when the instantiation fails. It is [Error (Fault _)] when the
    value of an import does not have the type of that import: here [Fault] also
    means that the engine could not instantiate [m] with those values. It is
    [Error Busy] when another domain uses [store] at the same time.

    @raise Invalid_argument
      when [store] was released, when [m] is not a module of the engine of
      [store], when the length of [imports] is not [Wasm_module.import_count m],
      or when an [Export (i, name)] names an instance of another store or a name
      that [i] does not export. *)

val invoke :
  t ->
  instance ->
  string ->
  Instance.Value.t list ->
  'a Instance.Result_type.t ->
  ('a, Instance.failure) result
(** [invoke store i name arguments result_type] invokes the function export
    [name] of [i] with [arguments], and gives its result. It is [Error] when the
    invocation fails, and [Error Busy] when another domain uses [store] at the
    same time. Each invocation in [store] takes its fuel from what is left of
    the fuel of [store].

    @raise Invalid_argument
      when [store] was released, when [i] is not an instance of [store], when
      [i] exports no function named [name], when the types of [arguments] are
      not the parameter types of that function, or when its result types are not
      those of [result_type]. *)

val grow_memory :
  t -> instance -> string -> int -> (int, Instance.failure) result
(** [grow_memory store i name pages] adds [pages] pages of 65,536 bytes, each
    byte 0, to the memory export [name] of [i], and gives the number of pages
    that it had before. It runs no code. It is [Error (Stopped Memory)] when the
    growth stops, as {!create} says, and then the memory does not change; and
    [Error Busy] when another domain uses [store] at the same time.

    @raise Invalid_argument
      when [store] was released, when [i] is not an instance of [store], when
      [i] exports no memory named [name], or when [pages] is negative. *)

val grow_table :
  t -> instance -> string -> int -> (int, Instance.failure) result
(** [grow_table store i name elements] adds [elements] null elements to the
    table export [name] of [i], and gives the number of elements that it had
    before. It runs no code. It is [Error (Stopped Table)] when the growth
    stops, as {!create} says, and then the table does not change; and
    [Error Busy] when another domain uses [store] at the same time.

    @raise Invalid_argument
      when [store] was released, when [i] is not an instance of [store], when
      [i] exports no table named [name], when that table does not hold
      functions, or when [elements] is negative. *)

val memory_size : t -> instance -> string -> (int, Instance.failure) result
(** [memory_size store i name] is the number of bytes of the memory export
    [name] of [i] now. It is [Error Busy] when another domain uses [store] at
    the same time.

    @raise Invalid_argument
      when [store] was released, when [i] is not an instance of [store], or when
      [i] exports no memory named [name].
    @raise Failure when the engine stops on an internal fault. *)

val read :
  t ->
  instance ->
  memory:string ->
  address:int ->
  length:int ->
  (string, Instance.failure) result
(** [read store i ~memory ~address ~length] is the [length] bytes of the memory
    export [memory] of [i] from [address] on, in their order. It is [Error Busy]
    when another domain uses [store] at the same time.

    @raise Invalid_argument
      when [store] was released, when [i] is not an instance of [store], when
      [i] exports no memory named [memory], or when [address] or [length] is
      negative or [address + length] is more than the size of that memory.
    @raise Failure when the engine stops on an internal fault. *)

val write :
  t ->
  instance ->
  memory:string ->
  address:int ->
  string ->
  (unit, Instance.failure) result
(** [write store i ~memory ~address bytes] puts [bytes] into the memory export
    [memory] of [i], in their order, from [address] on. It changes no other byte
    of the memories of [store], and runs no code. It is [Error Busy], and writes
    nothing, when another domain uses [store] at the same time.

    @raise Invalid_argument
      when [store] was released, when [i] is not an instance of [store], when
      [i] exports no memory named [memory], or when [address] is negative or
      [address + String.length bytes] is more than the size of that memory.
    @raise Failure when the engine stops on an internal fault. *)

val release : t -> unit
(** [release store] frees [store], with its instances, memories, and tables. A
    release of a store that was released does nothing. When another domain uses
    [store] at the same time, that domain frees the store at the end of its use.
*)
