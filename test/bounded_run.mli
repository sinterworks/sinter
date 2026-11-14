(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** A run of the program [wait_probe/wait_probe.exe] with a time limit, for the
    tests of a read that must not wait. A child process, and not a fork of the
    suite, makes the reads, because the suite runs domains. *)

val probe : seconds:float -> string list -> (string list, string) result
(** [probe ~seconds args] runs [wait_probe/wait_probe.exe] with [args]. It is
    [Ok lines], the lines of its standard output, when it exits with the status
    0 within [seconds], and [Error reason] when it gives no result within
    [seconds] or ends in another way; the run then kills the child with
    [SIGKILL] and waits for it. *)
