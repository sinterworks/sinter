(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type vector_selection = Group of string | Every_vector
type suffix = Revision of string | Vector_selection of vector_selection

type t =
  | Internal of {
      kind_word : Kind_word.t option;
      slug : string option;
      part_name : string option;
      suffix : suffix;
    }
  | External of {
      kind_word : Kind_word.t option;
      namespace_name : string;
      id : string;
      part_name : string option;
    }
  | Content_id of string

let custom_namespace slug =
  match String.rindex_opt slug '/' with
  | Some i -> Some (String.sub slug 0 i)
  | None -> None
