(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Names = Map.Make (String)

type t = Id_pattern.t Names.t

type error =
  | Malformed_namespace_name of string
  | Repeated_namespace_name of string
  | Invalid_id_pattern of { namespace_name : string; error : Id_pattern.error }
  | Stopped_id_pattern of { namespace_name : string; limit : Id_pattern.limit }

(* @satisfies identifiers#validate-bindings=v1
   A binding at which the program stops at no limit gets exactly one result:
   [Ok] ("valid") when it meets the schema `external-namespaces`, and [Error]
   ("invalid") when a namespace name does not match `namespace-name`, two
   pairs have the same namespace name, or an id pattern is not valid. *)
(* @satisfies conformance#report-stops-at-limits=v1
   A stop at a limit on an id pattern gives the limit with the namespace name
   of its pair, and no result "valid" or "invalid". *)
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
          | Error (Id_pattern.Invalid error) ->
              Error (Invalid_id_pattern { namespace_name = name; error })
          | Error (Id_pattern.Stopped limit) ->
              Error (Stopped_id_pattern { namespace_name = name; limit }))
  in
  List.fold_left add (Ok Names.empty) pairs

let empty = Names.empty
let id_pattern binding name = Names.find_opt name binding
let pairs binding = Names.bindings binding
