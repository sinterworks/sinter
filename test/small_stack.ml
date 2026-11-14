(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let run f =
  let before = Gc.get () in
  Gc.set { before with stack_limit = 32_768 };
  Fun.protect
    ~finally:(fun () -> Gc.set before)
    (fun () -> Domain.join (Domain.spawn f))
