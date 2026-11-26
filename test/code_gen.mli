(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Generated code files with their readings, for the properties of the terms of
    the design [documents=v1] for code files. *)

type case = {
  sigils : Code_reference.sigils;  (** the comment sigils of the pack *)
  source : string;  (** the text of the file, as UTF-8 *)
  nodes : Code_reference.node list;  (** the nodes of its reading *)
}
(** A code file and a reading of its text. *)

val shaped : case QCheck2.Gen.t
(** [shaped] gives texts made of line comments, block comments with inner lines,
    code, decorations, and definitions and tests with bodies, joined by spaces,
    tabs, line endings, blank lines, and lone carriage returns, some with a byte
    order mark; the reading has a node for each comment, decoration, definition,
    and test, in the order of a parse tree. *)

val mixed : case QCheck2.Gen.t
(** [mixed] gives the cases of {!shaped} with their readings changed: nodes
    added at other runs of the body, empty runs among them, and roles added to
    nodes, so that one node can have several roles. Each run is a run of the
    body of the text, each node has a role, each name path has an own name, and
    each definition node has a body node. For each two nodes A before B in the
    list, A starts at or before B starts, and B ends at or before A ends or
    starts at or after A ends, as in the order of a parse tree. *)

val print : case -> string
(** [print case] is [case] as text, for a failed property. *)
