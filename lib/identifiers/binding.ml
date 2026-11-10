(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Names = Map.Make (String)

type t = Id_pattern.t Names.t

type error =
  | Malformed_namespace_name of string
  | Repeated_namespace_name of string
  | Invalid_id_pattern of { namespace_name : string; error : Id_pattern.error }

(* @satisfies identifiers#{reject-malformed-namespace-names=v1, reject-repeated-namespace-names=v1, reject-invalid-binding-patterns=v1, accept-inputs=v1} *)
let make pairs =
  let add binding (name, pattern) =
    match binding with
    | Error _ -> binding
    | Ok binding -> (
        if not (Lexical.is_namespace_name name) then
          Error (Malformed_namespace_name name)
        else if Names.mem name binding then Error (Repeated_namespace_name name)
        else
          match Id_pattern.of_string pattern with
          | Ok p -> Ok (Names.add name p binding)
          | Error error ->
              Error (Invalid_id_pattern { namespace_name = name; error }))
  in
  List.fold_left add (Ok Names.empty) pairs

let empty = Names.empty
let id_pattern binding name = Names.find_opt name binding
let pairs binding = Names.bindings binding
