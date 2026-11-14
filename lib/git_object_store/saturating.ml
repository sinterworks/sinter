(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let add_bits value ~bits ~shift =
  let shift = min shift Sys.int_size in
  let shifted = bits lsl shift in
  if shifted < 0 || shifted lsr shift <> bits then max_int
  else value lor shifted
