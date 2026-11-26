(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The specification [descriptor] of the design [packs=v1], read directly from
    its rules over the root table that [Sinter_data_forms_toml] gives: whether a
    byte sequence is a valid descriptor, its values in the form of the member
    [values] of the group [descriptors], and the file grammars of valid paths.
*)

val form_of_toml :
  Sinter_data_forms_toml.Data_forms_toml.value -> Yojson.Basic.t
(** [form_of_toml value] is the form of [value] of section 5.9 of the design: an
    object [{"string": ...}], [{"boolean": ...}], [{"array": [...]}], or
    [{"table": {...}}], and, for a kind that the vectors do not use, an object
    with one member named after that kind. Two TOML values are equal when, and
    only when, their forms are the same JSON value, with the members of each
    object in any order. *)

val values : string -> Yojson.Basic.t option
(** [values bytes] is [Some form] when [bytes] is a valid descriptor, where
    [form] is the member [values] of a vector of the group [descriptors] with
    the result "valid" for [bytes], with [runners] in the code point order of
    the names and the [settings] of each in the code point order of the names.
    It is [None] when [bytes] is not a valid descriptor. *)

val file_grammar : string -> path:string -> string option
(** [file_grammar bytes ~path] is the name of the file grammar of the valid path
    [path] for the valid descriptor [bytes], or [None] when [path] has none. It
    raises [Invalid_argument] when [bytes] is not a valid descriptor or [path]
    is not a valid path. *)

val is_pack_name : string -> bool
(** [is_pack_name text] holds when [text] matches the production [pack-name]. *)

val is_grammar_name : string -> bool
(** [is_grammar_name text] holds when [text] matches the production
    [grammar-name]. *)

val is_numerals : int -> string -> bool
(** [is_numerals count text] holds when [text] is [count] decimal numerals with
    [.] between each two of them: [is_numerals 3] is the production
    [release-number], and [is_numerals 2] is the production [spec-version]. *)
