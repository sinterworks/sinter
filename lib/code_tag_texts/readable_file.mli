(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Whether a read file can be read, as the term [unreadable-file] of the design
    [documents=v1] defines it, with the reading of the text of each code file.

    A read file cannot be read when its content is not valid UTF-8, or when it
    is a code file and the reading of its text, as the text of a file at its
    valid path, with its pack has the result "no grammar" or the result "parse
    failure". Each other read file can be read. When a limit of the caller stops
    the text of a markdown file, as {!Markdown_limits.check} decides it, the
    program stops at a limit of its own at that file: the file is neither a file
    that can be read nor a file that cannot be read. *)

open Sinter_text
open Sinter_paths
open Sinter_file_readers
open Sinter_readings
open Sinter_markdown_limits

(** A read file that can be read. *)
type t =
  | Markdown_file of Markdown_limits.text
      (** a markdown file, with the lines of its text, which no limit stopped *)
  | Code_file of Code_file.t  (** a code file, with the reading of its text *)

(** Why a read file cannot be read. *)
type unreadable =
  | Not_utf_8 of Text.decode_error
      (** its content is not valid UTF-8, with the error that {!Text.decode}
          gives for it *)
  | No_grammar  (** the reading of its text has the result "no grammar" *)
  | Parse_failure  (** the reading of its text has the result "parse failure" *)

(** Why {!read} gives no file. *)
type error =
  | Cannot_be_read of unreadable  (** the read file cannot be read *)
  | Stopped of { path : Path.t; limit : Markdown_limits.limit }
      (** the read file at the valid path [path] is a markdown file whose
          content is valid UTF-8, and the limit [limit] of the caller stops its
          text: the program stops at a limit of its own at that file, and gives
          no readable file for it *)
  | Invalid_reading of Reading.error
      (** the reading of the text of the code file has the result "parsed", and
          its nodes fail {!Reading.check}: the producer of the reading broke its
          guarantee. The file is then neither a file that can be read nor a file
          that cannot be read, and this library gives no result for it, and none
          that it builds from a part of the reading. *)

val read :
  Markdown_limits.t ->
  ('pack -> Path.t -> Text.t -> Comment_sigils.t * Reading.result) ->
  'pack Read_file.t ->
  (t, error) result
(** [read limits pack file] is [Ok readable] when [file] can be read and no
    limit of [limits] stops it. For a markdown file whose content is valid
    UTF-8, it is [Error (Stopped { path; limit = l })], with [path] the valid
    path of [file], when {!Markdown_limits.check} gives [Error l] for [limits]
    and the lines of its text. For a code file whose pack is [p],
    [pack p path text] gives the comment sigils of the descriptor of [p] and the
    reading of [text], the text of [file], as the text of a file at the valid
    path [path] of [file], with [p]. [read] calls [pack] once for a code file
    whose content is valid UTF-8, and never for another file. *)
