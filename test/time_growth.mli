(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The growth of the processor time of a function, from an input of a size n to
    an input of the size 4n.

    The time is that of [Sys.time], the processor time of the program. It sees
    work that allocates nothing, which {!Counted_work} does not see, but it
    changes with the load of the machine. So each time is the least of three
    runs, and a bound must leave room for that change. *)

val repeat : int -> ('a -> 'b) -> 'a -> 'b
(** [repeat times f x] calls [f x] [times] times, or once when [times] is below
    2, and is the result of the last call. A time of a function that is too
    short to measure becomes one of [times] calls. *)

val check : bound:float -> size:int -> input:(int -> 'a) -> ('a -> 'b) -> unit
(** [check ~bound ~size ~input f] finds n: the least of [size], [2 * size],
    [4 * size], and so on up to [64 * size], at which [f (input n)] takes at
    least 20 milliseconds, or [64 * size]. It then fails the current test,
    through [Alcotest.fail], when [f (input (4 * n))] takes more than [bound]
    times the time of [f (input n)], with a message that gives both sizes, both
    times, and the bound. [input] makes each input before its time is taken. *)
