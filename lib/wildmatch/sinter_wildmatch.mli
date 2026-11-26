(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The match of a pathname against a glob pattern, as the page gitignore gives
    the patterns that are matched against a full pathname, with the rules of
    fnmatch(3) and its flag [FNM_PATHNAME] that the page cites.

    A pattern and a pathname are byte sequences, OCaml [string]s; each byte is
    one character. In a pattern, from its start:

    - [\ ] and the byte after it match that byte. A [\ ] that is the last byte
      of the pattern makes the pattern match no pathname.
    - [?] matches one byte that is not [/].
    - A run of two or more [*] is special when the pattern starts there or a [/]
      comes right before it, and the pattern ends right after it or a [/] or
      [\/] comes right after it. A special run with a [/] after it takes that
      [/] with it and matches zero or more names, each with a [/] after it: a
      byte sequence that is empty or that ends with [/]. A special run with [\/]
      after it, and a special run at the end of the pattern, match any byte
      sequence, [/] included; the [\/] then matches [/] by the first rule.
    - Any other run of one or more [*] matches a byte sequence that holds no
      [/], the empty one included.
    - [\[] starts a bracket expression, which ends at the first [\]] after its
      first member. When a [!] or a [^] comes right after the [\[], the bracket
      expression matches one byte that no member matches; otherwise it matches
      one byte that a member matches. It never matches [/]. A [\]] right after
      the [\[], or after the [!] or [^], is a member that matches [\]]. The
      members are: [\[:], a name, and the next [:\]], for the classes [alnum],
      [alpha], [blank], [cntrl], [digit], [graph], [lower], [print], [punct],
      [space], [upper], and [xdigit] of the bytes 0x00 to 0x7F; a byte, a [-],
      and a byte, for the first byte and for each byte from the first to the
      second, by their values; [\ ] and a byte, for that byte; and any other
      byte, for itself. A [-] right before the [\]] that ends the expression is
      a member for itself. A bracket expression with no end, or with a class
      name that is not in this list, makes the pattern match no pathname.
    - Each other byte matches itself.

    The pattern matches the pathname when its parts, in order, match the whole
    pathname. *)

type t
(** A pattern. *)

val compile : ?case_fold:bool -> string -> t
(** [compile ~case_fold pattern] is the pattern [pattern]. When [case_fold] is
    [true], a byte [A] to [Z] and the same letter [a] to [z] match each other,
    in each part of the pattern, the members of bracket expressions included.
    [case_fold] is [false] when it is not given. The time is linear in the
    length of [pattern]. *)

val matches : t -> string -> bool
(** [matches pattern pathname] is [true] when [pattern] matches [pathname]. The
    time is at most proportional to the product of the lengths of the pattern
    and of [pathname], and the stack space does not grow with them. *)
