(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Bindings of the parameter [file-readers], as the schema [file-readers] and
    the term [file-reader] of the design [documents=v1] define them.

    A binding of [file-readers] is a finite sequence of pairs, with numbers from
    1 in order. Each pair has a reader and a path set. A reader is the text
    [markdown] or a pack. A binding is valid when each of its path sets is a
    valid path set and each of its packs is a valid pack. Under a valid binding,
    the reader of a valid path is the reader of the first pair whose path set
    has that valid path in its set. A valid path that is in the set of no path
    set of the binding has no reader. *)

open Sinter_text
open Sinter_paths

(** A reader. The type ['pack] is the type of the packs of the caller, and each
    value of it stands for a valid pack. *)
type 'pack reader =
  | Markdown  (** the text [markdown] *)
  | Pack of 'pack  (** a valid pack *)

type 'pack t
(** A valid binding of [file-readers] whose packs have the type ['pack]. *)

(** Why a binding is not valid. Each error names the pair, by its number, of the
    lowest number whose path set is not a valid path set. *)
type error =
  | Invalid_glob of { pair : int; error : Path_set.glob_error }
      (** the glob text of a path set member of the path set of this pair is not
          a valid glob, and {!Path_set.of_texts} gives [error] for that path set
      *)
  | Invalid_path_set of { pair : int; fault : Path_set.fault }
      (** the glob text of each path set member of the path set of this pair is
          a valid glob, and {!Path_set.validate} gives [fault] for that path set
      *)

(* @satisfies conformance#reject-invalid-inputs=v1
   A binding of file-readers that is not valid gives an error that names the
   pair whose path set is not valid, and no value of the type [t], so no read
   file, and nothing that a read file gives, depends on it. *)
val make : ('pack reader * Text.t list) list -> ('pack t, error) result
(** [make pairs] is [Ok binding] when the binding of [pairs] is valid: each
    element of [pairs] is a reader and the path set members of a path set, in
    order, and the [k]-th element is the pair with the number [k]. It is [Error]
    when the path set of a pair is not a valid path set. *)

val pairs : 'pack t -> ('pack reader * Path_set.valid) list
(** [pairs binding] is the pairs of [binding], in the order of their numbers. *)

val reader : 'pack t -> Path.t -> (int * 'pack reader) option
(** [reader binding path] is [Some (k, reader)] when the pair with the number
    [k] is the first pair of [binding] whose path set has [path] in its set, and
    [reader] is then the reader of that pair, which is the reader of [path]. It
    is [None] when [path] is in the set of no path set of [binding]. *)
