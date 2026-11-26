(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let irregular =
  [
    "AUTO_MERGE";
    "BISECT_EXPECTED_REV";
    "NOTES_MERGE_PARTIAL";
    "NOTES_MERGE_REF";
    "MERGE_AUTOSTASH";
  ]

let is_root_name name =
  name = "HEAD" || List.mem name irregular
  || String.ends_with ~suffix:"_HEAD" name
     && String.for_all (fun c -> (c >= 'A' && c <= 'Z') || c = '_') name

let byte_fits c =
  let code = Char.code c in
  code > 0x20 && code <> 0x7F && not (String.contains "~^:?*[\\" c)

let holds text pattern =
  List.exists
    (fun at -> String.sub text at (String.length pattern) = pattern)
    (List.init (max 0 (String.length text - String.length pattern + 1)) Fun.id)

(* @satisfies changes#{give-ref-commits=v1, read-only-repository-files=v1}
   A text names a ref only when it is a ref name of the term ref-name, so that
   no ref name gives a pathname with an empty part, a part "." or "..", or a
   byte 0x00, and no pathname leaves the folder in which it is read. *)
let is_ref_name name =
  (String.starts_with ~prefix:"refs/" name || is_root_name name)
  && (not (String.ends_with ~suffix:"/" name))
  && (not (String.ends_with ~suffix:"." name))
  && (not (String.ends_with ~suffix:".lock" name))
  && (not (holds name "//"))
  && (not (holds name "/."))
  && (not (holds name ".lock/"))
  && (not (holds name ".."))
  && (not (holds name "@{"))
  && String.for_all byte_fits name
  && Result.is_ok (Sinter_text.Text.decode name)
