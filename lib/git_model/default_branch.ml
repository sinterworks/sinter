(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
open Sinter_branch_names

(* @satisfies changes#give-default-branch-commits=v1
   A binding that is not a branch name gives no commit. Otherwise the first
   of the upstream, the branch, and the remote-tracking branch of `origin`
   that exists decides, and its commit, or its lack of one, is the result. *)
let commit ~upstream ~refs binding =
  match Branch_name.of_text binding with
  | Error _ -> Ok None
  | Ok branch -> (
      let name = Text.encode (Branch_name.to_text branch) in
      match upstream branch with
      | Error e -> Error e
      | Ok tracked ->
          let rec first = function
            | [] -> Ok None
            | ref_name :: later -> (
                match refs ref_name with
                | Error e -> Error e
                | Ok None -> first later
                | Ok (Some _) -> Ref_commit.commit refs ref_name)
          in
          first
            (Option.to_list tracked
            @ [ "refs/heads/" ^ name; "refs/remotes/origin/" ^ name ]))
