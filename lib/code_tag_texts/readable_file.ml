(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_file_readers
open Sinter_readings
open Sinter_markdown_limits

type t = Markdown_file of Markdown_limits.text | Code_file of Code_file.t

type unreadable =
  | Not_utf_8 of Text.decode_error
  | No_grammar
  | Parse_failure
  | Stopped of Markdown_limits.limit

type error = Cannot_be_read of unreadable | Invalid_reading of Reading.error

(* @satisfies documents#give-tests=v1
   A code file whose reading has the result "no grammar" or "parse failure"
   gives no code file, so it gives no test, as for a content that is not valid
   UTF-8. *)
let read limits pack file =
  match Read_file.lines file with
  | Error error -> Error (Cannot_be_read (Not_utf_8 error))
  | Ok lines -> (
      match Read_file.reader file with
      | File_readers.Markdown -> (
          (* @satisfies documents#unreadable-file=v1
             A markdown file whose text a limit of the caller stops is in the
             set of stopped files, so it gives no readable file and the error
             names that limit. *)
          match Markdown_limits.check limits lines with
          | Ok text -> Ok (Markdown_file text)
          | Error limit -> Error (Cannot_be_read (Stopped limit)))
      | File_readers.Pack p -> (
          let path = Read_file.path file in
          let sigils, result = pack p path (Lines.text lines) in
          match result with
          | Reading.No_grammar -> Error (Cannot_be_read No_grammar)
          | Reading.Parse_failure -> Error (Cannot_be_read Parse_failure)
          | Reading.Parsed nodes -> (
              match Reading.check lines nodes with
              | Ok reading ->
                  Ok (Code_file (Code_file.make path sigils reading))
              | Error error -> Error (Invalid_reading error))))
