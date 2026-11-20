(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type 'id target = Commit of 'id | Other | Broken | Ref of string
type ('id, 'e) refs = string -> ('id target option, 'e) result

module Names = Set.Make (String)

(* @satisfies changes#give-ref-commits=v1
   A ref resolves through the refs that it names in turn: a commit is its
   commit, and another git object, a broken loose ref, a name of no ref, or
   a name met before on the way gives no commit. *)
let resolve refs target =
  let rec follow seen = function
    | Commit c -> Ok (Some c)
    | Other | Broken -> Ok None
    | Ref name -> (
        if Names.mem name seen then Ok None
        else
          match refs name with
          | Error e -> Error e
          | Ok None -> Ok None
          | Ok (Some next) -> follow (Names.add name seen) next)
  in
  follow Names.empty target

let commit refs name = resolve refs (Ref name)

(* @satisfies changes#give-head-commits=v1
   The head commit is the commit to which HEAD resolves, from what HEAD
   points to or names, as any ref resolves. *)
let head_commit refs head = resolve refs head
