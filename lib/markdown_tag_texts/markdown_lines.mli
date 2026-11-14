(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Markdown lines, as the term [markdown-line] of the design [documents=v1]
    defines them.

    A markdown line ending of a text is a run of its body that has only one of
    these: a line feed that no carriage return comes right before; a carriage
    return and the line feed right after it; or a carriage return that no line
    feed comes right after. The markdown line endings divide the body into runs.
    The markdown lines are these runs, except a last run that is empty. *)

open Sinter_text

val of_text : Text.t -> Text.run list
(** [of_text text] is the markdown lines of [text], as runs of [text], in the
    order of the boundaries where they start. Each run is a run of the body of
    [text] and holds no line feed and no carriage return. The time is linear in
    the length of [text]. *)
