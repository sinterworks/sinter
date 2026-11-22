(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Bindings of the parameter [external-namespaces], as the design
    [identifiers=v1] defines them: finite sets of pairs of a namespace name and
    an id pattern. *)

(* @satisfies identifiers#give-no-results-under-rejected-bindings=v1
   Only a binding with the result "valid" is a value of this type, so no line,
   link, or image is read under a binding with the result "invalid". *)
type t
(** A binding that the program accepts: it meets the schema
    [external-namespaces], and the program stops at no limit of its own on it.
    Each namespace name of it matches the production [namespace-name], no two of
    its pairs have the same namespace name, and each of its id patterns is a
    valid id pattern that {!Id_pattern.of_string} accepts. *)

(** Why {!make} gives no binding. Each error names a pair of the list that
    {!make} took for which the condition holds. *)
type error =
  | Malformed_namespace_name of string
      (** the namespace name does not match the production [namespace-name] *)
  | Repeated_namespace_name of string
      (** another pair of the list has the same namespace name *)
  | Invalid_id_pattern of { namespace_name : string; error : Id_pattern.error }
      (** the id pattern of the pair with this namespace name is not a valid id
          pattern *)
  | Stopped_id_pattern of { namespace_name : string; limit : Id_pattern.limit }
      (** the program stops at this limit of its own on the id pattern of the
          pair with this namespace name: no result "valid" or "invalid" for the
          binding *)

(* @satisfies identifiers#{validate-bindings=v1, give-no-results-under-rejected-bindings=v1}
   A binding at which the program stops at no limit gets "valid" as [Ok] and
   "invalid" as [Error] with one of the first three errors, and only [Ok]
   gives a binding under which a text can be read. *)
(* @satisfies conformance#reject-invalid-inputs=v1
   A binding that does not meet the schema gives an error that names the pair
   that makes it not valid, and no value of the type [t], so nothing that
   needs a binding comes from it. *)
val make : (string * string) list -> (t, error) result
(** [make pairs] is the binding of [pairs], each a namespace name and an id
    pattern, when the program accepts it. The order of [pairs] has no effect on
    [Ok]. It is [Error] for a pair of [pairs] that makes the binding invalid,
    and [Error (Stopped_id_pattern _)] for a pair at whose id pattern the
    program stops at a limit of its own. *)

val empty : t
(** [empty] is the binding with no pair. Under it, no target is external. *)

val id_pattern : t -> string -> Id_pattern.t option
(** [id_pattern binding name] is the id pattern of the pair of [binding] whose
    namespace name is [name], or [None] when [binding] has no such pair. *)

val pairs : t -> (string * Id_pattern.t) list
(** [pairs binding] is the pairs of [binding], in the order of their namespace
    names in code point order. *)
