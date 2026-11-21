(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Pulls of ledger entries from a shared clone, as the term [pull-commit] and
    the requirements [pull-shared-entries], [refuse-unsafe-pulls], and
    [report-leaving-entries] of the design [ledger=v1] give them.

    A pull into a git repository A from a commit s of its shared clone is over
    the ledger commit a of A, or over no commit when A has no ledger commit. The
    lines of a for which the git tree object of s does not account are the
    provisional lines ({!Accounting}). For n the number of the lines of s, the
    line that comes from a line l with the [seq] p is the canonical line of the
    object that has each member of the object of l other than [seq] and [id],
    the member [seq] with p, and the member [id] with its entry id. In
    increasing order of their [seq], a provisional line l stays when the line
    that comes from it with the [seq] n + k + 1, for k the number of the lines
    that stayed before it, has a ledger entry of a kind other than [void] that
    is accepted at the end of the ledger of the ledger entries of the lines of s
    and of the lines that came from the lines that stayed before it; it leaves
    when it does not stay. A pull commit of s over a is s when no line stays,
    and otherwise a commit that extends s and holds the lines of s and, after
    them, the lines that come from the lines that stay. *)

open Sinter_ledger_lines
open Sinter_ledger_trees

(** The result of a pull. *)
type t =
  | Refused
      (** a conforming program does not pull into A from s: A has a ledger
          commit, the git tree object of s does not account for each line of a,
          and the ledger of A is not valid, or the git tree object of s is not a
          valid ledger tree, or a provisional line has a [kind] that is none of
          the eight kinds *)
  | Pulled of { added : Ledger_line.t list; left : string list }
      (** a conforming program can pull into A from s: [added] is the lines that
          come from the lines that stay, in increasing order of their [seq], so
          that the lines of a pull commit of s over a are the lines of s and
          then [added]; when [added] is [[]], the pull commit is s itself.
          [left] is the value of [id] of the object of each line that leaves,
          each once, in increasing order of the [seq] of these lines. *)

val pull :
  Acceptance.t -> clone:Ledger_tree.t option -> shared:Ledger_tree.t -> t
(** [pull acceptance ~clone ~shared] is the pull into A from s, with the
    acceptance rules [acceptance], when [clone] is the git tree object of a, or
    [None] when A has no ledger commit, and [shared] is the git tree object of
    s. It gives lines and ids, and no commit: the commit that holds them, and
    the layout of its chunks, are the caller's. The time is linear in the length
    of the lines of [clone] and of [shared], plus the time of one call of a rule
    of [acceptance] for each provisional line whose line that comes from it has
    a ledger entry of a kind other than [void]. *)
