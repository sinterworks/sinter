(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Parse trees of texts, with their nodes in the order of the parse tree, as
    the terms [parse-tree], [parse-tree-order], [node-type], and [node-run] of
    the design [packs=v1] define them, and the reading of a parse tree from the
    record that the core of tree-sitter writes for it. *)

open Sinter_text

type t
(** The parse tree of a text, with that text. Two domains can use one parse tree
    at the same time. *)

type node = private int
(** A node of a parse tree: its index in the order of the parse tree, from 0 for
    the root node. A function that takes a parse tree and a node reads the node
    of that parse tree at the index of the node: so a node of another parse tree
    gives the node of this parse tree at the same index. *)

(** Why a record gave no parse tree. *)
type error =
  | Wrong_length
      (** the record is shorter than 8 bytes, or its length is not 8 + 16 n
          bytes for its node count n, or n is 0 *)
  | Wrong_flags of int  (** the word of the flags is this number, not 0 or 1 *)
  | Wrong_depth of int
      (** the node at this index has a depth that the order of the parse tree
          does not allow *)
  | Unknown_symbol of int  (** the node at this index has no node type *)
  | Wrong_bytes of int
      (** the node at this index has a start byte more than its end byte, or a
          start byte or an end byte that is not the number of bytes of the UTF-8
          encoding of the characters of the parse text before one of its
          boundaries *)
  | Not_nested of int
      (** the run in the text of the node at this index does not start at or
          after the boundary where the run of its parent starts, or does not end
          at or before the boundary where the run of its parent ends *)
  | Not_in_order of int
      (** the run in the text of the node at this index starts before the
          boundary where the run of the child before it, among the children of
          its parent, ends *)

val parse_text : Text.t -> string
(** [parse_text text] is the UTF-8 encoding of the parse text of [text]: [text],
    followed by a line feed when [text] does not end with a line feed. The time
    is linear in the length of [text]. *)

val decode : node_types:Text.t array -> Text.t -> string -> (t, error) result
(** [decode ~node_types text record] is the parse tree of [text] that [record]
    gives, where the node type of a node whose symbol in the record is [k] is
    [node_types.(k)]; the record of a parse with {!Grammar} gives each [ERROR]
    node the index of the node type [ERROR] of {!Grammar.node_types}. A record
    is a sequence of 32-bit words, each an unsigned number in 4 bytes, least
    significant byte first:

    + the node count n, 1 or more;
    + the flags: 1 when the root node has an error, and 0 when it has none;
    + for each node, in the order of the parse tree, four words: its depth (0
      for the root node, and 1 more than the depth of its parent for each other
      node), its symbol, its start byte, and its end byte. The start byte and
      the end byte are in the UTF-8 encoding of the parse text of [text].

    It is [Error] when [record] is not such a record of a tree of [text]. It is
    also [Error] when the runs of the nodes in [text], as {!run} gives them,
    break a condition of the term [parse-tree]: [Not_nested] when the run of a
    child does not lie inside the run of its parent, and [Not_in_order] when the
    run of a child starts before the end of the run of the child before it. The
    error is the first reason that holds, in the order of the record; for one
    node, the reasons hold in the order of the constructors of {!error}. The
    function never raises. The time is in O(m + n log m), for n nodes and a
    parse text of m bytes. *)

val text : t -> Text.t
(** [text tree] is the text of [tree]. *)

val node_count : t -> int
(** [node_count tree] is the number of nodes of [tree], 1 or more. *)

val root : t -> node
(** [root tree] is the root node of [tree]. *)

val node : t -> int -> node option
(** [node tree k] is the node of [tree] at the index [k] in the order of the
    parse tree, from 0, or [None] when [k] is negative or is not below
    [node_count tree]. *)

val children : t -> node -> node list
(** [children tree n] is the children of [n], in their order. The time is in
    O(c) for c children.

    @raise Invalid_argument
      when the index of [n] is not below [node_count tree]. *)

val node_type : t -> node -> Text.t
(** [node_type tree n] is the node type of [n]: the text of the name of its
    symbol.

    @raise Invalid_argument
      when the index of [n] is not below [node_count tree]. *)

val start_byte : t -> node -> int
(** [start_byte tree n] is the start byte of [n].

    @raise Invalid_argument
      when the index of [n] is not below [node_count tree]. *)

val end_byte : t -> node -> int
(** [end_byte tree n] is the end byte of [n].

    @raise Invalid_argument
      when the index of [n] is not below [node_count tree]. *)

val run : t -> node -> Text.run
(** [run tree n] is the run of [n] in the text of [tree]: the run that starts at
    the greater of b and the lesser of s and l, and that ends at the greater of
    b and the lesser of e and l, where s and e are the boundaries of the parse
    text before which the start byte and the end byte of [n] lie, b is the
    boundary where the body of the text starts, and l is the last boundary of
    the text. The time is constant.

    @raise Invalid_argument
      when the index of [n] is not below [node_count tree]. *)

val root_has_error : t -> bool
(** [root_has_error tree] is [true] when the root node of [tree] has an error:
    when it, or a node that the parsing gives inside it, nodes of hidden symbols
    included, is an [ERROR] node or a [MISSING] node. *)
