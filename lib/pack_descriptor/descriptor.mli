(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Descriptors, as the specification [descriptor] of the design [packs=v1]
    defines them: whether a byte sequence is a valid descriptor, the values of a
    valid descriptor, and the file grammar of a valid path.

    A valid descriptor is a byte sequence that is a TOML document, as
    {!Sinter_data_forms_toml.Data_forms_toml.read} decides, whose root table
    meets the ten rules of the term [valid-descriptor]. A text is an OCaml
    [string] that holds its UTF-8 encoding. Each list that comes from a TOML
    array is in the order of that array. *)

(** The default value of a runner setting, which also gives its type. *)
type setting_value =
  | String of string  (** a TOML string: the type string *)
  | Boolean of bool  (** a TOML boolean: the type boolean *)
  | Strings of string list
      (** a TOML array of TOML strings, by their texts: the type array of
          strings *)

type runner_setting = private {
  setting_name : string;  (** the text of the TOML key of the setting *)
  default : setting_value;  (** the default value *)
}
(** A runner setting of a test runner. *)

(* @satisfies packs#{omit-absent-adapter-values=v1, omit-absent-match-tables=v1}
   A test runner has an adapter hash and an adapter license, or a match
   table, and never both: a test runner with no adapter hash has no value that
   holds one, and a test runner with no match table has no table. *)

(** What a test runner binds its test results with. *)
type runner_source =
  | Adapter of { hash : Sinter_hashes.Hash.t; license : string }
      (** the adapter hash and the adapter license *)
  | Match of Sinter_data_forms_toml.Data_forms_toml.table
      (** the match table *)

type runner = private {
  runner_name : Pack_name.t;  (** the name of the test runner *)
  source : runner_source;  (** its adapter, or its match table *)
  settings : runner_setting list;
      (** its runner settings, in the code point order of their names *)
}
(** A test runner of a valid descriptor. *)

type grammar = private {
  grammar_name : Grammar_name.t;  (** the grammar name *)
  hash : Sinter_hashes.Hash.t;  (** the hash that the descriptor gives *)
  license : string;  (** the license *)
  globs : Sinter_paths.Glob.t list;  (** the file-name globs, in order *)
}
(** A grammar of a valid descriptor. *)

type t
(** A valid descriptor. *)

(** Why a byte sequence is not a valid descriptor. *)
type error =
  | Not_a_toml_document  (** the byte sequence is not a TOML document *)
  | Breaks_a_rule
      (** the byte sequence is a TOML document whose root table breaks a rule of
          a valid descriptor *)

(* @satisfies packs#omit-invalid-descriptor-values=v1
   The values below come only from a valid descriptor, which only [read] makes,
   so a byte sequence that is not a valid descriptor gives none of them. *)

val read : string -> (t, error) result
(** [read bytes] is [Ok descriptor] when [bytes] is a valid descriptor, and
    [Error] when it is not: [Not_a_toml_document] when [bytes] is not a TOML
    document, and [Breaks_a_rule] otherwise. The function never raises, and its
    use of the call stack does not grow with the depth of nesting of [bytes]. *)

val spec_version : t -> Spec_version.t
(** [spec_version descriptor] is the text of the TOML string of [sinter-spec].
*)

val name : t -> Pack_name.t
(** [name descriptor] is the text of the TOML string of [name]: the pack name.
*)

val release : t -> Release_number.t
(** [release descriptor] is the text of the TOML string of [version]: the
    release number. *)

val license : t -> string
(** [license descriptor] is the text of the TOML string of [license]. *)

val name_separator : t -> string
(** [name_separator descriptor] is the text of the TOML string of
    [name-separator], which is not empty. *)

val foreign_tag_words : t -> string list
(** [foreign_tag_words descriptor] is, for each TOML string of [foreign-tags],
    [@] followed by its text; the empty list when the root table does not hold
    [foreign-tags]. *)

val line_sigils : t -> string list
(** [line_sigils descriptor] is the texts of the TOML strings of [line] in the
    table [comments]; the empty list when that table does not hold [line]. *)

val block_pairs : t -> (string * string) list
(** [block_pairs descriptor] is, for each TOML array of [block] in the table
    [comments], the texts of its first and its second TOML string: the opening
    sigil and the closing sigil; the empty list when that table does not hold
    [block]. *)

val inner_sigils : t -> string list
(** [inner_sigils descriptor] is the texts of the TOML strings of [inner] in the
    table [comments]; the empty list when that table does not hold [inner]. *)

val grammars : t -> grammar list
(** [grammars descriptor] is one grammar for each table of the array [grammar],
    in order: one or more, no two with the same name. *)

val runners : t -> runner list
(** [runners descriptor] is one test runner for each text that the table
    [runner] holds, in the code point order of their names; the empty list when
    the root table does not hold [runner]. *)

val file_grammar : t -> Sinter_paths.Path.t -> grammar option
(** [file_grammar descriptor path] is [Some grammar] when [grammar] is the file
    grammar of [path]: the first grammar of [descriptor], in the order of
    {!grammars}, that has a file-name glob that the last file name of [path],
    taken as a valid path of one file name, fits. It is [None] when no grammar
    has such a glob. *)
