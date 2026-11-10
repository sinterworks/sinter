(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type vector_selection =
  | Vector_number of string
  | Group of string
  | Every_vector

type t =
  | Internal of {
      kind_word : Kind_word.t option;
      slug : string option;
      part_name : string option;
      vector_selection : vector_selection option;
      revision : string;
    }
  | Every_part of { slug : string; revision : string }
  | External of {
      kind_word : Kind_word.t option;
      namespace_name : string;
      id : string;
      part_name : string option;
    }

let custom_namespace slug =
  match String.rindex_opt slug '/' with
  | Some i -> Some (String.sub slug 0 i)
  | None -> None
