(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The member [items] of the vectors of the design [documents=v1], without the
    member [extent-hash] of each element, from the declared items that the
    library gives and from those that {!Items_reference} gives. *)

open Sinter_tree_items

val of_declared : Declared_items.t -> Yojson.Basic.t
(** [of_declared declared] is the member [items] for the declared items
    [declared], each element without [extent-hash]. *)

val of_reference : Items_reference.item list -> Yojson.Basic.t
(** [of_reference items] is the member [items] for [items], each element without
    [extent-hash]. *)
