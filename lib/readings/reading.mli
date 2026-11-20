(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Readings of texts, as the term [reading-of-a-text] of the design [packs=v1]
    gives them, with the parts of a reading that the design [documents=v1] uses:
    the result of the reading, and, for the result "parsed", the comment nodes,
    the definition nodes with their body nodes, the decoration nodes, and the
    test nodes with their name paths, each with its run.

    The producer of a reading, such as a program that reads a text with a pack,
    gives a value of {!result}. The producer guarantees that the nodes of a
    reading with the result "parsed" are the nodes that the terms of the design
    [packs=v1] give for the text, each once, in the order of the parse tree,
    each with its run as the term [node-run] gives it. {!check} checks a part of
    this guarantee: the cases that a term forbids. It does not check the rest:
    it accepts a node with no role, and it takes the order of the list as the
    order of the parse tree. *)

open Sinter_text

(** A piece of the own name of a test node, as the term [test-name] gives it. *)
type piece =
  | Text_piece of Text.t
      (** a text piece, which stands for its text as the text of the file writes
          it *)
  | Placeholder of Text.t
      (** a placeholder, which stands for text that a test runner puts in the
          name of the test; the text is the text of the run of its node *)

type own_name = piece list
(** The own name of a test node: its pieces, in their order. It can have no
    piece. *)

type name_path = own_name list
(** The name path of a test node: the own names of the test suites that enclose
    it, in the order of the parse tree, and then its own name. *)

(** Whether a comment node is tagged, as the term [comment-node] gives it. *)
type comment = Tagged  (** a comment node that can carry tags *) | Untagged

type node = {
  run : Text.run;  (** the run of the node in the text *)
  comment : comment option;
      (** [Some c] when the node is a comment node, and [None] otherwise *)
  body : Text.run list option;
      (** [Some runs] when the node is a definition node: the runs of its body
          nodes, in the order of the parse tree; [None] otherwise *)
  decoration : bool;  (** [true] when the node is a decoration node *)
  test : name_path option;
      (** [Some path] when the node is a test node, with its name path; [None]
          otherwise *)
}
(** A node of a reading. One node can have any mix of these roles. A node with
    no role is a node of no kind that the design [documents=v1] uses. *)

(** The result of a reading of a text. *)
type result =
  | No_grammar  (** the result "no grammar" *)
  | Parse_failure  (** the result "parse failure" *)
  | Parsed of node list
      (** the result "parsed", with the nodes, in the order of the parse tree *)

type t
(** A reading of one text with the result "parsed", whose nodes passed {!check}.
*)

(** Why the nodes of a reading fail {!check}. Each error names a node by its
    number, from 1, in the list of nodes. *)
type error =
  | Not_a_run of { node : int }
      (** the run of the node is not a run of the text that starts at or after
          the boundary where the body of the text starts *)
  | Body_not_a_run of { node : int; body : int }
      (** the run of the body node with the number [body], from 1, of the node
          is not a run of the text that starts at or after the boundary where
          the body of the text starts *)
  | Not_nested of { node : int }
      (** the run of the node and the run of a node before it in the list break
          the order of the term [node-run]: the run of the node does not start
          at or after the boundary where the run of the earlier node starts and
          end at or before the boundary where that run ends, and it does not
          start at or after the boundary where the run of the earlier node ends
      *)
  | Body_not_nested of { node : int; body : int }
      (** the run of the body node with the number [body], from 1, of the node
          and the run of a body node before it among the body nodes of that node
          break the order of the term [node-run], as for {!Not_nested} *)
  | No_body_node of { node : int }
      (** the node is a definition node with no body node *)
  | No_own_name of { node : int }
      (** the node is a test node whose name path has no own name *)

val check : Lines.t -> node list -> (t, error) Stdlib.result
(** [check lines nodes] is [Ok reading] when each node of [nodes] passes these
    checks, and [reading] is then the reading of [Lines.text lines] with the
    result "parsed" and the nodes [nodes]:
    - its run is a run of the text that starts at or after the boundary where
      the body of the text starts;
    - for each node before it in [nodes], its run starts at or after the
      boundary where the run of that node starts and ends at or before the
      boundary where that run ends, or its run starts at or after the boundary
      where the run of that node ends;
    - when it is a definition node, it has at least one body node, and each body
      node passes these two checks, in this order: its run is a run of the text
      that starts at or after the boundary where the body of the text starts;
      and, for each body node before it among the body nodes of the node, its
      run starts at or after the boundary where the run of that body node starts
      and ends at or before the boundary where that run ends, or its run starts
      at or after the boundary where the run of that body node ends;
    - when it is a test node, its name path has at least one own name.

    It is [Error] for the node of the lowest number that fails a check, with the
    first check that it fails in the order of this list, and, for the third
    check, for the body node of the lowest number among those of that node that
    fail a check, with the first check that it fails. The time is linear in the
    number of the nodes and of their body nodes. *)

val lines : t -> Lines.t
(** [lines reading] is the lines of the text of [reading]. *)

val nodes : t -> node list
(** [nodes reading] is the nodes of [reading], in the order of the parse tree:
    the list that {!check} took. *)
