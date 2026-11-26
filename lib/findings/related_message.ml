(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_spots

type t = { message : Message.t; spot : Spot.t option }

let make message spot = { message; spot }
let message related = related.message
let spot related = related.spot

let equal a b =
  Message.equal a.message b.message && Option.equal Spot.equal a.spot b.spot
