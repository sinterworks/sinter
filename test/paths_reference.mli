(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of valid paths, valid globs, and glob fit of the design
    [files=v1], read directly, over texts as lists of characters. The time of
    [fits] can grow exponentially with the number of glob segments [**]. *)

val is_path : Uchar.t list -> bool
(** [is_path text] holds when [text] matches the production [path]. *)

val file_names : Uchar.t list -> Uchar.t list list
(** [file_names path] is the file names of the valid path [path], in the order
    of their numbers. *)

val is_glob : Uchar.t list -> bool
(** [is_glob text] holds when [text] matches the production [glob]. *)

val glob_segments : Uchar.t list -> Uchar.t list list
(** [glob_segments glob] is the glob segments of the valid glob [glob], in the
    order of their numbers. *)

val fits : path:Uchar.t list -> glob:Uchar.t list -> bool
(** [fits ~path ~glob] holds when the valid path [path] fits the valid glob
    [glob], as the term [glob-fit] defines it. *)
