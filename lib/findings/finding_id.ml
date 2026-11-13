(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text

type t = { class_slug : Class_slug.t; subject : Subject.t }

let make class_slug subject = { class_slug; subject }
let class_slug id = id.class_slug
let subject id = id.subject

let finding =
  Text.of_uchars
    (List.map Uchar.of_char [ 'f'; 'i'; 'n'; 'd'; 'i'; 'n'; 'g'; ':' ])

let colon = Text.of_uchars [ Uchar.of_char ':' ]

(* @satisfies findings#give-finding-ids=v1
   The finding id is the text finding:, the slug, :, and the subject, in that
   order and with nothing between them. *)
let to_text id =
  Text.concat
    [
      finding;
      Class_slug.to_text id.class_slug;
      colon;
      Subject.to_text id.subject;
    ]

let equal a b =
  Text.equal (Class_slug.to_text a.class_slug) (Class_slug.to_text b.class_slug)
  && Text.equal (Subject.to_text a.subject) (Subject.to_text b.subject)
