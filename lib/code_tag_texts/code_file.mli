(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** A code file that can be read, with what the reading of its text gives: its
    code characters, its runs of comments, its tag texts, its file lines, and
    the attachment of its runs of comments, as the terms [code-character],
    [comment-run], [tag-text], [file-line], and [attachment] of the design
    [documents=v1] define them. *)

open Sinter_text
open Sinter_paths
open Sinter_origins
open Sinter_readings

type t
(** A code file that can be read, with the reading of its text with its pack. *)

type comment_run = {
  run : Text.run;
      (** the run of the text from the boundary where the run of comments
          starts, which is the boundary where the run of its first comment node
          starts, to the boundary where it ends, which is the boundary where the
          run of its last comment node ends *)
  first_line : int;
      (** the first line number of the run of comments: the line number of the
          position of the boundary where the run of its first comment node
          starts *)
  last_line : int;
      (** the last line number of the run of comments: that of its last comment
          node, the line number of the line that has the last place of its run
          that is a place of a line, or its first line number when no place of
          its run is a place of a line *)
  comment_nodes : Reading.node list;
      (** the comment nodes of the run of comments, in their order in it *)
  tag_text : Tag_text.t option;
      (** [Some tag_text] when a comment node of the run of comments is tagged:
          the tag text that joins the comment lines of its tagged comment nodes,
          as {!Comment_line.of_node} gives them, the comment lines of each node
          in their order and the nodes in their order in the run of comments.
          Its text is the text of the tagged comments without their comment
          sigils. [None] when no comment node of the run is tagged. *)
  target : Reading.node option;
      (** [Some node] when the run of comments attaches to the attachment target
          [node], and [None] when it is unattached *)
}
(** A run of comments of a code file. *)

val make : Path.t -> Comment_sigils.t -> Reading.t -> t
(** [make path sigils reading] is the code file at the valid path [path], whose
    text is the text of [reading], read with a pack whose descriptor has the
    comment sigils [sigils] and whose reading of the text is [reading]. The time
    is linear in the length of the text and in the number of the lines of the
    comment nodes, and grows as n log n in the number n of the nodes. *)

val path : t -> Path.t
(** [path file] is the valid path of [file]. *)

val reading : t -> Reading.t
(** [reading file] is the reading of the text of [file], which holds its lines.
*)

val is_code_character : t -> int -> bool
(** [is_code_character file p] is [true] when, and only when, [p] is a place of
    the body of the text of [file] that is a place of the run of no comment
    node, that is a place of no line ending, and whose character is not a space
    or a tab. *)

val comment_runs : t -> comment_run list
(** [comment_runs file] is the runs of comments of [file], in the order of the
    boundaries where they start, and, of two that start at one boundary, in the
    order of the parse tree of their first comment nodes. They are the sequences
    of the outer comment nodes, the comment nodes that no other comment node
    encloses, that these rules give, for each outer comment node in turn, in the
    order of the boundaries where their runs start, and, of two whose runs start
    at one boundary, in the order of the parse tree:
    + When the line with the first line number of the comment node has a code
      character, the comment node starts a new run of comments, and no other
      comment node joins it.
    + Otherwise, the comment node joins the run of comments of the outer comment
      node right before it when its first line number is the last line number of
      that comment node or 1 more, the boundary where its run starts is not
      before the boundary where the run of that comment node ends, the run of
      the text between these two boundaries has no character other than spaces,
      tabs, and the characters at places of line endings, and rule 1 did not
      start that run of comments.
    + Otherwise, the comment node starts a new run of comments.

    A comment node A encloses a different comment node B when the run of A
    starts at or before the boundary where the run of B starts, ends at or after
    the boundary where the run of B ends, and A comes before B in the list of
    the nodes of the reading. The first line number of a comment node is the
    line number of the position of the boundary where its run starts.

    A run of comments attaches to the attachment target T, a definition node or
    a test node, when, and only when, each of these is true:
    + Of the attachment targets whose runs start at or after the boundary where
      the run of comments ends, T is one whose run starts at the first such
      boundary; of these, one whose run ends at the last boundary; and of these,
      the first in the list of the nodes of the reading.
    + No code character is at a place before the boundary where the run of
      comments starts on the line with its first line number.
    + Each code character at a place after the boundary where the run of
      comments ends and before the boundary where the run of T starts is at a
      place of the run of a decoration node. Each line of the text whose line
      number is greater than the last line number of the run of comments and
      less than the line number of the position of the boundary where the run of
      T starts has a code character at a place of the run of a decoration node,
      or has in it a line, as {!Comment_line.run_lines} gives it, of the run of
      a comment node. *)

val tag_texts : t -> Tag_text.t list
(** [tag_texts file] is the tag texts of [file]: the tag text of each run of
    comments that has one, in the order of {!comment_runs}. *)

val file_lines : t -> File_lines.t
(** [file_lines file] is the file lines of [file]: the lines that its tag texts
    join, as {!File_lines.of_tag_texts} gives them. *)
