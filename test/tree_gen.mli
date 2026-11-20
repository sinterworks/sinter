(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Generated trees of markdown files and code files with declarations, for the
    properties of the terms of the design [documents=v1] for declared items. *)

type code_file = {
  sigils : Code_reference.sigils;  (** the comment sigils of its pack *)
  nodes : Code_reference.node list;  (** the nodes of the reading of its text *)
}
(** The pack of a code file: its comment sigils and the reading of its text. *)

type case = {
  files : (string * string) list;
      (** each file of the tree, a valid path and its content, with no two files
          at one valid path *)
  code : (string * code_file) list;
      (** the code files of the tree, each with its valid path *)
}
(** A tree. Each file whose valid path ends with [.md] is a markdown file, each
    valid path of [code] is a code file, and no other file is a read file. *)

val case : case QCheck2.Gen.t
(** [case] gives trees of up to five markdown files and up to two code files.
    The markdown files have headings, paragraphs, lists, block quotes, code
    blocks, setext headings, front matter, and links, with declarations of each
    kind of a few names, so that names repeat, designs hold items in the same
    file and in other files, and some slugs have no design. The code files are
    those of {!Code_gen.mixed}, with declarations of these names in their
    comments. Some trees also have files at the vector paths of some of these
    names. *)

val print : case -> string
(** [print case] is [case] as text, for a failed property. *)

val namespaces : Sinter_identifiers.Binding.t
(** [namespaces] is the binding of [external-namespaces] with the one pair of
    the namespace name [gh] and the id pattern [[1-9][0-9]*]. *)

val read :
  case ->
  Sinter_tree.Tree.t * (string * Sinter_code_tag_texts.Readable_file.t) list
(** [read case] is the tree of [case], and each of its read files that can be
    read, under the binding of [file-readers] whose first pair is the reader
    [markdown] with the path set [*.md], [**/*.md], and whose second pair is a
    pack with the path set [lib/*.rs], [lib/*.ml], and under {!namespaces}, each
    with the text of its valid path, in the order of these texts. *)

val text_of : string -> Sinter_text.Text.t
(** [text_of bytes] is the text of [bytes]. It raises [Invalid_argument] when
    [bytes] is not valid UTF-8. *)

val path_of : string -> Sinter_paths.Path.t
(** [path_of text] is the valid path whose text is [text]. It raises
    [Invalid_argument] when [text] is no valid path. *)
