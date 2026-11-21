(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type 'id entry = { name : string; mode : string; id : 'id }
type 'id commit = { parents : 'id list; tree : 'id }

type ('id, 'e) objects = {
  commit : 'id -> ('id commit, 'e) result;
  tree : 'id -> ('id entry list, 'e) result;
  blob : 'id -> (string, 'e) result;
}

type 'id ledger_ref = Absent | No_commit | Commit of 'id
