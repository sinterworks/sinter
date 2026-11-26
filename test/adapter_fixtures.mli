(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Adapters for the tests of the decision whether a byte sequence is a valid
    adapter and of calls, as bytes. *)

val text :
  ?imports:string ->
  ?interface:string ->
  ?alloc:string ->
  ?recognise:string ->
  ?bind:string ->
  ?memory:string ->
  string ->
  string
(** [text ~imports ~interface ~alloc ~recognise ~bind ~memory rest] is the bytes
    of the module whose text has the imports [imports], none by default, the
    five exports of the interface, with these bodies, and the fields [rest].
    [interface] has the type [[] -> [i32]] and is [(i32.const 1)] by default.
    [alloc] has the type [[i32] -> [i32]], with the parameter [$n], and gives
    [16] by default. [recognise] and [bind] have the type
    [[i32 i32 i32 i32] -> [i64]], with the parameters [$ra], [$rn], [$ca], and
    [$cn], and give [0] by default. [memory] is the memory field without its
    export, [(memory 1)] by default. It raises [Failure] when the module is not
    valid. *)

val core_2_features : (string * string) list
(** One valid adapter for each feature of Core 2.0 beyond the first version of
    WebAssembly, each with the name of the feature. The [sinter_interface] of
    each runs code of the feature and gives 1 only when each value that the code
    computes is the one that Core 2.0 defines. *)

val later_proposals : (string * string) list
(** For each proposal of WebAssembly that came after Core 2.0, other than
    multiple memories, a byte sequence that is a valid adapter except for one
    construct of the proposal, with the name of the proposal. Core 2.0 makes
    each of them not valid. *)

val bump : string
(** [bump] is the fields of an allocator: a global [$next], first 4096, and a
    function [$bump] of the type [[i32] -> [i32]] that gives [$next] and adds
    the number of bytes and 8 to it. *)

val pointer : string -> string -> string
(** [pointer address length] is the expression of the type [i64] whose high 32
    bits are the [i32] expression [address] and whose low 32 bits are the [i32]
    expression [length]. *)

val data_string : string -> string
(** [data_string bytes] is [bytes] as a string of the text format. *)

val echo : string
(** [echo] is an adapter whose [sinter_alloc] is [$bump] in a memory of 16
    pages, and whose recognise and bind each give back the report content. *)

val responds : string -> string
(** [responds response] is an adapter whose [sinter_alloc] is [$bump], and whose
    recognise and bind each give the bytes [response], which lie in its memory
    at the address 1024. [response] has at most 3,000 bytes. *)

val request_is : string -> string
(** [request_is request] is an adapter whose recognise gives
    [{"recognised":true}] when the request of the call is the bytes [request],
    and [{"recognised":false}] otherwise; and whose bind gives
    [{"bindings":[],"results":[],"warnings":[]}] when the request is [request],
    and [{"error":"another request"}] otherwise. *)
