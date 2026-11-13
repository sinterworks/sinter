(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The term of valid paths of the design [files=v1], read directly, over texts
    as lists of characters. *)

val is_path : Uchar.t list -> bool
(** [is_path text] holds when [text] matches the production [path]. *)

val file_names : Uchar.t list -> Uchar.t list list
(** [file_names path] is the file names of the valid path [path], in the order
    of their numbers. *)
