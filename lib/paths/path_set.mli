(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Path sets, their validity, and the valid paths in their sets, as the design
    [files=v1] defines them.

    A path set is a finite sequence of texts, its path set members, with numbers
    from 1 in order. A path set member that starts with [!] is a [!] member, and
    its glob text is the text after that [!]. Each other path set member is a
    plain member, and its glob text is the path set member. A path set is valid
    when the glob text of each path set member is a valid glob, no two path set
    members are the same text, and at least one path set member is a plain
    member when the path set holds a path set member. *)

type t
(** A path set in which the glob text of each path set member is a valid glob.
    The path set need not be valid. *)

type glob_error = { member : int; error : Glob.error }
(** Path set member [member] has a glob text that is not a valid glob, and
    [error] is what {!Glob.of_text} gives for that glob text. *)

type fault =
  | Repeated_member of { first : int; second : int }
      (** path set members [first] and [second] are the same text, and
          [first < second] *)
  | No_plain_member
      (** the path set holds at least one path set member, and each path set
          member is a [!] member *)

val of_texts : Sinter_text.Text.t list -> (t, glob_error) result
(** [of_texts members] is [Ok set] when the glob text of each element of
    [members] is a valid glob, and [set] is then the path set whose path set
    members are [members], in order. It is [Error] otherwise, with the path set
    member of the lowest number whose glob text is not a valid glob. *)

val validate : t -> (unit, fault) result
(** [validate set] is [Ok ()] when [set] is a valid path set, and [Error] with a
    fault when it is not. A path set member repeated is the fault before
    [No_plain_member]. [Repeated_member] names the path set member [second] of
    the lowest number that is the same text as a path set member before it, and
    the path set member [first] of the lowest number that is that text. So a
    sequence of texts is a valid path set when, and only when, {!of_texts} gives
    [Ok set] for it, and [validate set] gives [Ok ()]. *)

val mem : t -> Path.t -> bool
(** [mem set path] is [true] when [path] is in the set of [set]: when [path]
    fits the glob text of at least one plain member of [set], and fits the glob
    text of no [!] member of [set]. It is [false] otherwise. The order of the
    path set members does not change the result. *)
