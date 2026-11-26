(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The terms of the design [documents=v1] for declared items, read directly
    over the values of the tag texts, the inputs, the blocks, the sections, the
    list items, the runs of comments, and the file lines that the libraries of
    the read files give: the files of declared items, claims, scopes, innermost
    items, the designs of slugs, home designs, containment, extents, the names
    of declared items, and vector files. *)

open Sinter_text
open Sinter_identifiers
open Sinter_code_tag_texts
open Sinter_tag_inputs

type kind =
  | Design
  | Specification
  | Schema
  | Requirement
  | Atom
  | Term
  | Decision_record  (** The kind of a declared item. *)

val kind_text : kind -> string
(** [kind_text kind] is the text of [kind] in the member [items] of the vectors,
    such as ["decision record"]. *)

type item = {
  kind : kind;
  name : string;  (** its name, as UTF-8 *)
  file : string;  (** the valid path of its file, as UTF-8 *)
  at : Lines.position;
      (** the origin position of the text of its declaration *)
  claim : Text.run list;  (** the file lines of its claim, in their order *)
  scope : Text.run list option;
      (** the file lines of its scope, in their order, for an item of the kind
          design or specification *)
  extent : Text.run list;  (** the file lines of its extent, in their order *)
  design : int option;
      (** the index, from 1, of the item of the kind design to which it belongs
      *)
  specification : int option;
      (** the index, from 1, of the item of the kind specification to which it
          belongs *)
  vector_path : string option;  (** its vector path *)
  vector_file : string option;  (** the valid path of its vector file *)
}
(** A declared item. *)

type thing = {
  path : string;  (** the valid path of its file *)
  input : Input.t;  (** a tag line of a tag text, or a link *)
  home_design : int option;
      (** the index, from 1, of its home design, or [None] when it has none *)
}
(** A tag line or an inline citation of a file, with its home design. *)

type model = { items : item list; things : thing list }
(** The declared items of a tree, in the code point order of the valid paths of
    their files and then in the order of the origin positions of their
    declarations; and each tag line of a tag text and each inline citation of
    the tree, in the order of the files and then in the order in which
    {!Input.of_tag_text} and {!Input.of_links} give them. *)

val model : Binding.t -> (string * Readable_file.t) list -> string list -> model
(** [model binding files paths] is the model of the tree whose files that can be
    read are [files], each with its valid path, in the code point order of these
    paths, and whose files of all kinds have the valid paths [paths]. *)
