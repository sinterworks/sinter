(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let least_time f x =
  let best = ref infinity in
  for _ = 1 to 3 do
    let start = Sys.time () in
    ignore (Sys.opaque_identity (f x));
    best := Float.min !best (Sys.time () -. start)
  done;
  !best

let repeat times f x =
  for _ = 2 to times do
    ignore (Sys.opaque_identity (f x))
  done;
  f x

let check ~bound ~size ~input f =
  let rec calibrate n =
    let time = least_time f (input n) in
    if time >= 0.02 || n >= 64 * size then (n, time) else calibrate (2 * n)
  in
  let n, small = calibrate size in
  let large = least_time f (input (4 * n)) in
  let ratio = large /. Float.max small 1e-6 in
  if ratio > bound then
    Alcotest.failf
      "the size %d took %.4f s and the size %d took %.4f s, %.1f times as \
       long, over the bound %.1f"
      n small (4 * n) large ratio bound
