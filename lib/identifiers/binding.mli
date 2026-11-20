(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Bindings of the parameter [external-namespaces], as the design
    [identifiers=v1] defines them: finite sets of pairs of a namespace name and
    an id pattern. *)

(* @satisfies identifiers#give-no-results-under-rejected-bindings=v1 *)
type t
(** A binding that the program accepts. Each namespace name of it matches the
    production [namespace-name], no two of its pairs have the same namespace
    name, and each of its id patterns is accepted. *)

(** Why a binding is invalid. Each error names a pair of the list that {!make}
    took for which the condition holds. *)
type error =
  | Malformed_namespace_name of string
      (** the namespace name does not match the production [namespace-name] *)
  | Repeated_namespace_name of string
      (** another pair of the list has the same namespace name *)
  | Invalid_id_pattern of { namespace_name : string; error : Id_pattern.error }
      (** the id pattern of the pair with this namespace name is invalid *)

(* @satisfies identifiers#give-no-results-under-rejected-bindings=v1 *)
val make : (string * string) list -> (t, error) result
(** [make pairs] is the binding of [pairs], each a namespace name and an id
    pattern, when the program accepts it. The order of [pairs] has no effect on
    [Ok]. It is [Error] for a pair of [pairs] that makes the binding invalid. *)

val empty : t
(** [empty] is the binding with no pair. Under it, no target is external. *)

val id_pattern : t -> string -> Id_pattern.t option
(** [id_pattern binding name] is the id pattern of the pair of [binding] whose
    namespace name is [name], or [None] when [binding] has no such pair. *)

val pairs : t -> (string * Id_pattern.t) list
(** [pairs binding] is the pairs of [binding], in the order of their namespace
    names in code point order. *)
