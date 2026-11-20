(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The declared items of a tree, with their files, claims, scopes, extents,
    containment, names, and vector files, as the terms [item-file], [claim],
    [item-scope], [innermost-item], [slug-design], [home-design],
    [tree-containment], [extent], [name-set], and [vector-file] of the design
    [documents=v1] define them, and the order of positions of the term
    [position-order].

    Each accepted input of a tree that is a declaration declares one declared
    item, and the tree has no other declared item. A set of file lines is given
    as runs of the text of its file, in the order of the file lines; a thing of
    a file, such as the text of a tag line or an inline citation, is given by
    its file lines, as {!Sinter_tag_inputs.Input.file_lines} gives them. A thing
    is in a set of file lines when each of its file lines is a line of that set.

    The vector set of an item, the content of its vector file read as a
    test-vector set, is not in this module. *)

open Sinter_text
open Sinter_paths
open Sinter_tree
open Sinter_tag_inputs
open Sinter_tree_inputs

(** The kind of a declared item, which the declaration word of its declaration
    alone gives. *)
type kind =
  | Design  (** [@design] *)
  | Specification  (** [@spec] *)
  | Schema  (** [@schema] *)
  | Requirement  (** [@req] *)
  | Atom  (** [@atom] *)
  | Term  (** [@term] *)
  | Decision_record  (** [@decision] *)

type item
(** A declared item of a tree. *)

type t
(** The declared items of one tree. A value never changes after {!make}. *)

(* @satisfies documents#give-nothing-under-invalid-bindings=v1
   The declared items come only from read files that can be read, and these
   exist only under a valid binding of file-readers and a binding of
   external-namespaces that the program accepts, so under any other binding no
   declared item, extent, containment, or vector file exists. *)

(** Why {!make} gives no value. *)
type error =
  | Repeated_path of Path.t
      (** two elements of the list of files have this valid path; it is the
          least such valid path in the code point order *)

val make : Tree.t -> Tree_file.t list -> (t, error) result
(** [make tree files] is [Ok declared] when no two elements of [files] have the
    same valid path. For the read files of [tree] that can be read, each read
    under one binding of [external-namespaces], [declared] is then the declared
    items of [tree]. For any list, the declarations are the accepted inputs that
    are declarations among the inputs of the tag texts of the elements of
    [files], each as {!Tree_file.tag_texts} gives them, so a file read under
    another binding gives the declarations of its own inputs. [tree] gives only
    the files that can be vector files: a vector file is a file of [tree],
    whether or not [tree] has a file at the valid path of an element of [files].

    Let n be the number of the file lines of all the files, d the number of the
    declarations, f the number of the files, and r the number of the runs, as
    {!Line_set} counts them, of the claims, the scopes, and the extents of the
    items. The time grows as n log n, as f log f, as r log r, and as d log d
    times the number of the runs of the largest claim, scope, or extent. For
    each declaration, it also grows as (k + 1) log r, and as k times the number
    of the runs of the largest claim or scope, where k is the number of the
    distinct scopes and claims of the items of its file that have the first file
    line of the declaration: the number of the scopes and claims that hold it,
    when they nest. So, for example, n requirements in the innermost of n
    specifications on n nested nodes of a code file take a time that grows as
    n^2, the number of the requirements times the number of the scopes that hold
    each one, though the input and the result grow as n: the nodes of a reading
    are not known to nest, so each scope that holds a declaration is checked. It
    also grows as the number of the pairs of two items of one file of which the
    claim of one is a subset of the claim of the other, and it takes the time of
    {!Sinter_code_tag_texts.Block.of_tag_text} for the tag texts of the code
    files. *)

val items : t -> item list
(** [items declared] is each declared item of the tree once, and no other: in
    the code point order of the valid paths of their files, and then in the
    order of the origin positions of the texts of their declarations, by
    {!Position_order.compare}. *)

val number : item -> int
(** [number item] is the number of [item] in {!items}, from 1. *)

val files : t -> Tree_file.t list
(** [files declared] is the files that {!make} took, in the code point order of
    their valid paths. *)

val file_items : t -> Path.t -> item list
(** [file_items declared path] is the declared items whose file has the valid
    path [path], in the order of {!items}. The time is logarithmic in the number
    of the files, other than the length of the list. *)

val kind : item -> kind
(** [kind item] is the kind of [item]. *)

val file : item -> Tree_file.t
(** [file item] is the file of [item]: the read file whose tag text has its
    declaration. *)

val declaration : item -> Input.t
(** [declaration item] is the declaration of [item], an accepted input of the
    tree. *)

val at : item -> Lines.position
(** [at item] is the origin position of the text of the declaration of [item]:
    the position of the place that the [@] of its line comes from. *)

val target_name : item -> string * string option
(** [target_name item] is the name in the target of the declaration of [item]:
    [(slug, None)] for a slug, which is also a segment for a specification, and
    [(slug, Some part_name)] for the full name [slug#part_name]. *)

val name : item -> string
(** [name item] is the name of [item], as the term [item-name] of the design
    [ontology=v1] gives it: for an item of the kind specification, schema,
    requirement, atom, or term whose declaration names it by one segment and
    that belongs to an item of the kind design, the name of that design, [#],
    and that segment; for each other item, the name in the target of its
    declaration. *)

val claim : item -> Text.run list
(** [claim item] is the claim of [item], a set of file lines of its file, as the
    term [claim] gives it. *)

val scope : item -> Text.run list option
(** [scope item] is [Some lines] for an item of the kind design or of the kind
    specification, with [lines] its scope, as the term [item-scope] gives it,
    and [None] for each other item. *)

val design : item -> item option
(** [design item] is the item of the kind design to which [item] belongs, or
    [None] when it belongs to none. *)

val specification : item -> item option
(** [specification item] is the item of the kind specification to which [item]
    belongs, or [None] when it belongs to none. *)

val extent : item -> Text.run list
(** [extent item] is the extent of [item], a set of file lines of its file, as
    the term [extent] gives it. *)

val vector_path : item -> Path.t option
(** [vector_path item] is the vector path of [item], an item of the kind design
    or of the kind specification, as the term [vector-file] gives it, or [None]
    when it has none: for each item of another kind, and for an item of the kind
    specification that belongs to no item of the kind design. *)

val vector_file : item -> Path.t option
(** [vector_file item] is the vector file of [item]: its vector path, when the
    tree has a file at that valid path and that valid path is the vector path of
    no other item. It is [None] otherwise. *)

val equal : item -> item -> bool
(** [equal a b] is [true] when, and only when, [a] and [b] are the same item of
    one value of {!t}. *)

val slug_design : t -> string -> item option
(** [slug_design declared slug] is the design of [slug]: the item of the kind
    design whose name is [slug], when no other item of the kind design and no
    decision record has [slug] as its name. It is [None] otherwise. The time is
    logarithmic in the number of the items. *)

val home_design : t -> Path.t -> Text.run list -> item option
(** [home_design declared path lines] is the home design, as the term
    [home-design] gives it, of a tag line of a tag text, or of an inline
    citation, of the file at [path] whose file lines are [lines]:
    + the innermost, by their scopes, of the items of the kind design in whose
      scopes it is, when there is one;
    + otherwise, when the file is a code file, the design of the slug of the
      name in the target of the declaration of the innermost, by their claims,
      of the items of the kind requirement, the schemas, the atoms, and the
      terms in whose claims it is, when that name is a full name and that slug
      has a design;
    + otherwise, the design of the slug of the name in the target of the
      declaration of the innermost, by their scopes, of the items of the kind
      specification in whose scopes it is, when that name is a full name and
      that slug has a design;
    + otherwise, [None].

    It is [None] when [path] is the valid path of no file of [declared]. An
    element of [lines] that is no file line of the file counts as no line. The
    time is that of three calls of {!Line_set.Index.innermost}, for the scopes
    of the designs, the claims of the requirements, the schemas, the atoms, and
    the terms, and the scopes of the specifications of the file, and logarithmic
    in the number of the files, of the items, and of the file lines of the file
    for each element of [lines]. *)

val part_of : t -> Path.t -> Text.run list -> item option
(** [part_of declared path lines] is the innermost, by their extents, of the
    declared items whose file has the valid path [path] and in whose extents a
    thing with the file lines [lines] is: the declared item of which it is a
    part, by the term [item-part]. It is [None] when there is no such item, or
    no innermost one. An element of [lines] that is no file line of the file
    counts as no line. The time is that of {!Line_set.Index.innermost} for the
    extents of the items of the file, and logarithmic in the number of the files
    and of the file lines of the file for each element of [lines]. *)

val extent_holders : t -> Path.t -> Text.run list -> item list
(** [extent_holders declared path lines] is the declared items whose file has
    the valid path [path] and in whose extents a thing with the file lines
    [lines] is, in the order of {!items}. So a file line is a line of an extent
    when, and only when, [extent_holders declared path [line]] is not empty. An
    element of [lines] that is no file line of the file counts as no line. The
    time is that of {!part_of}. *)

(** A set of names of a tree, as the term [name-set] gives it. *)
type name_set =
  | Shared
      (** the items of the kind design, the decision records, and the items of
          the kind specification, the schemas, the items of the kind
          requirement, the atoms, and the terms that belong to no item of the
          kind design and whose names are slugs *)
  | Of_design of item
      (** the items of the kind specification, the schemas, the items of the
          kind requirement, the atoms, and the terms that belong to this item of
          the kind design *)

val members : t -> name_set -> item list
(** [members declared set] is the items of [set], in the order of {!items}. It
    is [[]] for [Of_design d] when [d] is not of the kind design. The time is
    logarithmic in the number of the items of the kind design, other than the
    length of the list. *)

val named : t -> name_set -> string -> item list
(** [named declared set name] is the items of [set] whose name is the same text
    as [name], in the order of {!items}. The time is logarithmic in the number
    of the items, other than the length of the list. *)
