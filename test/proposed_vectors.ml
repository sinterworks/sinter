(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let lines () =
  In_channel.with_open_bin "fixtures/changes-proposed/vectors.jsonl"
    In_channel.input_lines

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let test group give =
  Alcotest.test_case
    (Printf.sprintf "the proposed vectors of the group %s" group) `Quick
    (fun () ->
      let vectors =
        List.filter
          (fun json -> member "group" json = Some (`String group))
          (List.map Yojson.Basic.from_string (lines ()))
      in
      if vectors = [] then Alcotest.failf "no vector of the group %s" group;
      let differences =
        List.filter_map
          (fun vector ->
            let number =
              match member "n" vector with
              | Some (`Int n) -> n
              | _ -> Alcotest.fail "a vector with no number"
            in
            let input = Option.value (member "input" vector) ~default:`Null
            and values = Option.value (member "values" vector) ~default:`Null in
            match give input with
            | given when Vectors.equal_json given values -> None
            | given ->
                Some
                  (Printf.sprintf "vector %d holds %s, and the code gives %s"
                     number
                     (Yojson.Basic.to_string values)
                     (Yojson.Basic.to_string given))
            | exception error ->
                Some
                  (Printf.sprintf "vector %d: %s" number
                     (Printexc.to_string error)))
          vectors
      in
      if differences <> [] then Alcotest.fail (String.concat "\n" differences))
