(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The values of the runner settings of a test runner under a valid binding of
    the parameter [runner-settings], as the specification [adapters] of the
    design [packs=v1] defines them.

    A binding of [runner-settings], for one test runner, is a finite set of
    pairs, each a name and a TOML value. It is valid when the name of each pair
    is the name of a runner setting of the test runner, no two pairs have the
    same name, and the TOML value of each pair is of the type of that runner
    setting: a TOML string for the type string, a TOML boolean for the type
    boolean, and a TOML array of TOML strings for the type array of strings.
    Under a valid binding, the value of a runner setting is the TOML value of
    the pair with its name, or its default value when no pair has its name. *)

type t
(** For each runner setting of one test runner, its name and its value. *)

(** Why a binding is not valid, or why a list gives no values. *)
type error =
  | Not_a_setting of string
      (** the name is the name of no runner setting of the test runner *)
  | Repeated_name of string  (** two pairs have this name *)
  | Wrong_type of string
      (** the TOML value of the pair with this name is not of the type of the
          runner setting *)
  | Not_utf_8 of string
      (** this name, or a text of the value of the setting with this name, is
          not valid UTF-8 *)

val bind :
  Sinter_pack_descriptor.Descriptor.runner ->
  (string * Sinter_data_forms_toml.Data_forms_toml.value) list ->
  (t, error) result
(** [bind runner binding] is the value of each runner setting of [runner] under
    [binding], each name a text as its UTF-8 encoding, when [binding] is valid.
    It is [Error] when [binding] is not valid, for the first pair, in the order
    of [binding], that breaks a rule, with the first of these that holds for it:
    [Not_a_setting]; [Repeated_name], when an earlier pair has the same name;
    [Wrong_type]; and [Not_utf_8], when a text of its TOML value is not valid
    UTF-8. *)

val of_list :
  (string * Sinter_pack_descriptor.Descriptor.setting_value) list ->
  (t, error) result
(** [of_list values] is the runner settings with the names and the values of
    [values], such as for a test runner whose runner settings have these values
    as their default values and an empty binding. It is [Error] for the first
    element, in the order of [values], whose name an earlier element has
    ([Repeated_name]), or whose name or a text of whose value is not valid UTF-8
    ([Not_utf_8]). *)

val to_list :
  t -> (string * Sinter_pack_descriptor.Descriptor.setting_value) list
(** [to_list values] is each runner setting of [values], with its name and its
    value, in the code point order of the names. *)

val to_json : t -> Sinter_json_lines.Json.t
(** [to_json values] is the JSON object with one member for each runner setting:
    its name as the key, and as the value a string of the text of a TOML string,
    a boolean for a TOML boolean, and, for a TOML array, an array of a string of
    the text of each of its TOML strings, in their order. *)
