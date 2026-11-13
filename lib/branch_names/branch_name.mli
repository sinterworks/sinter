(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Branch names, as the term [branch-name] of the design [changes=v1] defines
    them.

    The parts of a text are the texts between its characters [/]. A branch name
    is a text that meets each of eight conditions:

    + it is not empty, it does not start or end with [/], and it does not hold
      [//];
    + no part starts with [.] or ends with [.lock];
    + it does not hold [..] or [@{];
    + it does not end with [.];
    + it holds no character whose code point is from 0 to 31 or is 127;
    + it holds no space and none of the characters [~], [^], [:], [?], [*],
      [[], and [\ ];
    + it is not [HEAD], and it does not start with [-];
    + it does not start with [refs/]. *)

type t
(** A branch name. *)

type error =
  | Condition of int
      (** The text does not meet condition [k] of the eight, and it meets each
          condition with a lower number. [k] is from 1 to 8. *)

val of_text : Sinter_text.Text.t -> (t, error) result
(** [of_text text] is [Ok name] when [text] is a branch name, and [name] then
    holds [text]. It is [Error] when [text] is not a branch name. The time is
    linear in the length of [text]. *)

val to_text : t -> Sinter_text.Text.t
(** [to_text name] is the text of [name]. *)
