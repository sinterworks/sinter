(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

(* @satisfies changes#give-message-texts=v1
   The message starts after the first two bytes 0x0A that follow one another,
   and is empty when the content holds no two such bytes. *)
let message content =
  let length = String.length content in
  let rec from place =
    if place + 1 >= length then ""
    else if content.[place] = '\n' && content.[place + 1] = '\n' then
      String.sub content (place + 2) (length - place - 2)
    else from (place + 1)
  in
  from 0

(* @satisfies changes#give-message-texts=v1
   The message has a text only when its bytes are valid UTF-8, whatever the
   header `encoding` names. *)
let text content = Result.to_option (Text.decode (message content))
