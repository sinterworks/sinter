(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** What the response of a call of an adapter gives, as the specification
    [adapters] of the design [packs=v1] defines it: the result of the call and
    its values, for a call of a valid adapter whose invocation of the function
    gives the response with no failure before it. A call that fails before it
    gives a response has the result "failed", with no error text. *)

open Sinter_text

(** The status of a test result. *)
module Status : sig
  type t =
    | Pass
    | Fail
    | Error
    | Skip  (** the strings [pass], [fail], [error], and [skip] *)
end

type test_result = private {
  name : Text.t;  (** the name, as the report content writes it *)
  status : Status.t;  (** the status *)
  file : Text.t option;  (** the file, when the result object has one *)
  line : int option;  (** the line, 1 or more, when the result object has one *)
  ms : int option;
      (** the duration in whole milliseconds, 0 or more, when the result object
          has one *)
}
(** A test result of a call with the result "bound". *)

type binding = private {
  result : int;
      (** 1 less than the index of the test result in the test results: 0 for
          the first test result *)
  test : Text.t;  (** a test entry id of the call *)
  reason : Text.t;  (** why the test result binds to the test entry *)
}
(** A binding object of a call with the result "bound". *)

type bound = private {
  results : test_result list;  (** the test results, in their order *)
  bindings : binding list;  (** the binding objects, in their order *)
  warnings : Text.t list;  (** the warnings, in their order *)
}
(** The values of a call with the result "bound". *)

(* @satisfies packs#{omit-call-values=v1, omit-adapter-error-texts=v1}
   Only the result "bound" carries test results, binding objects, and
   warnings, and only the result "failed" carries an error text. *)

(** The result of a call of the function recognise. *)
type recognition =
  | Recognised  (** "recognised" *)
  | Not_recognised  (** "not recognised" *)
  | Recognition_failed of Text.t option
      (** "failed", with the error text of the adapter when the call gives one
      *)

(** The result of a call of the function bind. *)
type binding_result =
  | Bound of bound  (** "bound", with its values *)
  | Bind_failed of Text.t option
      (** "failed", with the error text of the adapter when the call gives one
      *)

val recognise : string -> recognition
(** [recognise response] is the result of a call of recognise that gives the
    byte sequence [response]. It is [Recognised] when the JSON value of
    [response] is an object with exactly one member, [recognised], whose value
    is true, and [Not_recognised] when that value is false. Otherwise it is
    [Recognition_failed (Some text)] when the JSON value is an object with
    exactly one member, [error], whose value is the string [text], and
    [Recognition_failed None] in each other case. The JSON value of a byte
    sequence is as {!Sinter_json_lines.Json.read_json_text} gives it. The
    function never raises. *)

val bind : ids:Text.t list -> string -> binding_result
(** [bind ~ids response] is the result of a call of bind with the test entry ids
    [ids] that gives the byte sequence [response]. It is [Bound] when the JSON
    value of [response] is an object with exactly the members [results],
    [bindings], and [warnings], and each rule of the term [call-result] holds:
    [results] is an array of result objects; [bindings] is an array of binding
    objects, each with a [result] less than the number of test results and a
    [test] among [ids]; no two binding objects have the same [result] and the
    same [test]; and [warnings] is an array of strings. Otherwise it is
    [Bind_failed] with the error text, as {!recognise} gives it. The function
    never raises, and its time grows no faster than the length of [response]
    times the logarithm of that length, and the number of [ids] times its
    logarithm. *)
