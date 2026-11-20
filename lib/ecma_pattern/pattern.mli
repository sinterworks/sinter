(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** RegExp patterns of ECMA-262 2025 with the flag [u], and whether such a
    pattern finds a match in a text, as [RegExp.prototype.test] of ECMA-262 2025
    finds one.

    Each function works under limits of its own: the nesting of the groups of a
    pattern, the bytes that a compilation or a test holds at one time, and the
    work of a test. A function gives the same result for the same arguments on
    every run and on every machine. Two domains can use one pattern at the same
    time. *)

open Sinter_text

type t
(** A pattern that is valid with the flag [u], compiled. *)

(** Why a text gave no pattern. *)
type compile_error =
  | Not_valid of string
      (** the text is not a [Pattern] of ECMA-262 2025 that is valid with the
          flag [u] and no other flag; with the message of the compiler of
          QuickJS, in its own words, which has no fixed form *)
  | Too_deep
      (** the text has a group inside more than [depth] other groups; a group is
          each [(] that is not part of an escape and not inside a character
          class *)
  | Too_large
      (** the compilation needed more than [memory] bytes at one time; each
          compilation needs more than 0 bytes *)

val default_depth : int
(** [default_depth] is the default of [depth]: 100. *)

val default_compile_memory : int
(** [default_compile_memory] is the default of [memory] for {!compile}:
    67,108,864 (64 MiB). *)

val compile : ?depth:int -> ?memory:int -> Text.t -> (t, compile_error) result
(** [compile ?depth ?memory source] is the pattern whose source text is
    [source], with the flag [u] and no other flag. It is [Error Too_deep] when a
    group of [source] lies inside more than [depth] other groups, and the
    function then does not compile [source]; [Error Too_large] when the
    compilation needs more than [memory] bytes at one time; and
    [Error (Not_valid _)] when [source] is not a [Pattern] of ECMA-262 2025 that
    is valid with the flag [u]. A U+0000 of [source] is a character of the
    pattern as each other character is. The defaults are {!default_depth} and
    {!default_compile_memory}. The time grows at most quadratically with the
    length of [source], and the memory at most linearly.

    @raise Invalid_argument
      when [depth] is negative or more than 200, or when [memory] is negative.
*)

val size : t -> int
(** [size pattern] is the size in bytes of the compiled form of [pattern], more
    than 0. The compilation fixes it for each source text, and {!test} charges
    it for each poll. *)

val too_long : int -> bool
(** [too_long units] is [true] exactly when a subject of [units] UTF-16 code
    units is too long for {!test}: when [units] is more than 2,147,483,647. *)

(** Why a test gave no result. *)
type stop =
  | Steps  (** the work of the test reached its limit [steps] *)
  | Memory
      (** the test needed more than [memory] bytes at one time, the text in
          UTF-16 included *)

val default_steps : int
(** [default_steps] is the default of [steps]: 10,000. *)

val default_test_memory : int
(** [default_test_memory] is the default of [memory] for {!test}: 268,435,456
    (256 MiB). *)

val test : ?steps:int -> ?memory:int -> t -> Text.t -> (bool, stop) result
(** [test ?steps ?memory pattern subject] is [Ok true] when a RegExp of
    [pattern] with the flag [u] and no other flag finds a match in [subject], as
    a String of its UTF-16 code units, with the whole of [subject] as its input
    and the search starting at index 0, as [RegExp.prototype.test] of ECMA-262
    2025 does; and [Ok false] when it finds none.

    The test counts its work in polls: one poll for each backtrack, each jump,
    and each pass of a loop of the matcher. Between two polls, the matcher runs
    each instruction of the compiled pattern at most once, and only a back
    reference reads more than one character of [subject] at a time. So the test
    charges each poll the work [m + b * n]: [m] is {!size} of [pattern]; [b] is
    the number of back references of the source of [pattern], each backslash
    outside a character class that a digit from [1] to [9] or a [k] follows; and
    [n] is the number of UTF-16 code units of [subject]. It is [Error Steps]
    when its count of polls reaches 10,000 times ([a] + 1), where [a] is [steps]
    divided by [m + b * n], rounded down; so a test of more [steps] gives
    [Error Steps] for fewer inputs, and the count is the same on every run. It
    is [Error Memory] when the test needs more than [memory] bytes at one time:
    two bytes for each UTF-16 code unit of [subject], and the stack of the
    matcher; and when its number of UTF-16 code units is {!too_long}, whatever
    [memory] is. The defaults are {!default_steps} and {!default_test_memory}.
    For one pattern, the time is at most linear in [steps] plus linear in the
    length of [subject]: the test makes 10,000 polls before it can first stop,
    so even with [steps] 0 it can do the work of 10,000 times [(m + b * n)].

    @raise Invalid_argument when [steps] or [memory] is negative. *)
