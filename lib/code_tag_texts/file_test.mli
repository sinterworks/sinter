(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The tests of a read file, and the comments on them, as the term [file-test]
    of the design [documents=v1] defines them.

    A markdown file has no test, and a read file that cannot be read has no
    test. For a code file that can be read, each test node of the reading of its
    text is the code of one test of the file, and the file has no other test. *)

open Sinter_text
open Sinter_paths
open Sinter_readings

type t = {
  file : Path.t;  (** the valid path of the file of the test *)
  name : Reading.name_path;  (** the name path of its test node *)
  code : Text.run;  (** the run of its test node *)
  comments : Text.run list;
      (** the comments on the test: the run, as {!Code_file.comment_run} gives
          it, of each run of comments of the file that attaches to an attachment
          target whose run is the run of its test node, in the order of the
          boundaries where these runs of comments start *)
}
(** A test of a read file. *)

val of_file : Readable_file.t -> t list
(** [of_file file] is the tests of [file], each once: none for a markdown file,
    and one for each test node of the reading of a code file. They are in the
    order of the boundaries where their codes start, and, of two whose codes
    start at one boundary, in the order of their test nodes in the list of the
    nodes of the reading. *)
