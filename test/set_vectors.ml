(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_json_lines
open Sinter_test_vectors

type t = Test_vector_set.t

let path design =
  Filename.concat "../docs/designs" (design ^ ".test-vectors.jsonl")

let read design =
  let content = In_channel.with_open_bin (path design) In_channel.input_all in
  match Test_vector_set.read content with
  | Some set -> set
  | None -> failwith (path design ^ " is not a test-vector set")

let revision (set : t) = (set.revision :> string)

let vectors (set : t) name =
  List.filter
    (fun (vector : Test_vector_set.vector) -> vector.group = name)
    set.vectors

let text t = Json.string t

let string bytes =
  match Text.decode bytes with
  | Ok t -> Json.string t
  | Error _ -> invalid_arg "Set_vectors.string"

let integer k =
  match Json.integer k with
  | Some value -> value
  | None -> invalid_arg "Set_vectors.integer"

let object_ members =
  match
    Json.object_
      (List.map
         (fun (key, value) ->
           match Text.decode key with
           | Ok key -> (key, value)
           | Error _ -> invalid_arg "Set_vectors.object_")
         members)
  with
  | Some value -> value
  | None -> invalid_arg "Set_vectors.object_"

let print value = Json.canonical_byte_sequence value

let members = function
  | Json.Object members -> members
  | other -> Alcotest.failf "not a JSON object: %s" (print other)

let member_opt key value =
  List.find_map
    (fun (name, member) ->
      if String.equal (Text.encode name) key then Some member else None)
    (members value)

let member key value =
  match member_opt key value with
  | Some member -> member
  | None -> Alcotest.failf "no member %s in %s" key (print value)

let elements = function
  | Json.Array elements -> elements
  | other -> Alcotest.failf "not a JSON array: %s" (print other)

let to_text = function
  | Json.String t -> t
  | other -> Alcotest.failf "not a JSON string: %s" (print other)

let to_int = function
  | Json.Integer k -> k
  | other -> Alcotest.failf "not a JSON number: %s" (print other)

type answer = { result : string option; values : Json.t }
type group_test = { name : string; run : unit -> unit }

let mismatch (vector : Test_vector_set.vector) =
  let held =
    Printf.sprintf "result %s, values %s"
      (match vector.result with Some r -> Text.encode r | None -> "-")
      (match vector.values with Some v -> print v | None -> "-")
  in
  fun gave -> Printf.sprintf "vector %d holds %s; %s" vector.number held gave

let check_vector give (vector : Test_vector_set.vector) =
  match give vector with
  | exception exn -> Some (mismatch vector ("raised " ^ Printexc.to_string exn))
  | answer ->
      let result_ok =
        match vector.result with
        | None -> true
        | Some held -> answer.result = Some (Text.encode held)
      in
      let values_ok =
        match vector.values with
        | None -> true
        | Some held -> Json.equal held answer.values
      in
      if result_ok && values_ok then None
      else
        Some
          (mismatch vector
             (Printf.sprintf "gave result %s, values %s"
                (Option.value answer.result ~default:"-")
                (print answer.values)))

let group (set : t) ~name ~rev give =
  let run () =
    (match
       List.find_opt
         (fun (group : Test_vector_set.group) -> group.name = name)
         set.groups
     with
    | None -> Alcotest.failf "no group line for %s" name
    | Some group ->
        if (group.revision :> string) <> rev then
          Alcotest.failf "group %s has revision %s, not %s" name
            (group.revision :> string)
            rev);
    match vectors set name with
    | [] -> Alcotest.failf "group %s holds no vector" name
    | held -> (
        match List.filter_map (check_vector give) held with
        | [] -> ()
        | failures -> Alcotest.fail (String.concat "\n" failures))
  in
  { name; run }

let tests design groups =
  List.map
    (fun group ->
      Alcotest.test_case
        (Printf.sprintf "%s vectors of %s" design group.name)
        `Quick group.run)
    groups

let covers design (set : t) groups =
  Alcotest.test_case
    (Printf.sprintf "each vector group of %s has one test" design) `Quick
    (fun () ->
      Alcotest.(check (list string))
        "the groups"
        (List.map
           (fun (group : Test_vector_set.group) -> group.name)
           set.groups)
        (List.map (fun group -> group.name) groups))
