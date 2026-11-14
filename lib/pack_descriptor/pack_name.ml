(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = string

(* @satisfies packs#read-descriptor=v1
   A pack name is a lower-case letter, then groups of lower-case letters and
   digits that one [-] joins: a [-] at the end, two [-] side by side, or any
   other character fails. *)
let of_string text =
  match String.split_on_char '-' text with
  | first :: rest
    when first <> ""
         && Forms.lower first.[0]
         && List.for_all
              (fun part ->
                part <> ""
                && String.for_all (fun c -> Forms.lower c || Forms.digit c) part)
              (first :: rest) ->
      Some text
  | _ -> None
