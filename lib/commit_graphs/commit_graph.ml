(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Make (Id : Hashtbl.HashedType) = struct
  module Table = Hashtbl.Make (Id)

  type 'e graph = Id.t -> (Id.t list, 'e) result
  type 'e line_error = Unread of 'e | First_parent_cycle of Id.t

  let run (type e) (graph : e graph) walk =
    let module Stop = struct
      exception Unread of e
    end in
    let read commit =
      match graph commit with
      | Ok parents -> parents
      | Error e -> raise (Stop.Unread e)
    in
    match walk read with
    | value -> Ok value
    | exception Stop.Unread e -> Error e

  (* @satisfies changes#give-commit-parents=v1
     A commit that the file `shallow` names has no parents; any other has the
     commits that its commit object names, in their order. *)
  let parents ~named ~shallow = if shallow then [] else named

  let fresh () =
    Table.create 64
    [@mutaml.skip
      "The first size of a table changes no result: a table grows as it needs."]

  let walker () =
    let seen = fresh () and pending = Stack.create () in
    let visit commit =
      if not (Table.mem seen commit) then begin
        Table.replace seen commit ();
        Stack.push commit pending
      end
    in
    (seen, pending, visit)

  let ancestry read start =
    let seen, pending, visit = walker () in
    visit start;
    while not (Stack.is_empty pending) do
      List.iter visit (read (Stack.pop pending))
    done;
    seen

  (* @satisfies changes#decide-reach=v1
     The walk takes the parents of each commit that it reaches, from [c], and
     answers that [c] reaches [c'] when, and only when, it meets [c']. *)
  let reaches graph c c' =
    run graph (fun read ->
        let _, pending, visit = walker () in
        let found = ref false in
        visit c;
        while (not !found) && not (Stack.is_empty pending) do
          let commit = Stack.pop pending in
          if Id.equal commit c' then found := true
          else List.iter visit (read commit)
        done;
        !found)

  (* @satisfies changes#{give-ranges=v1, give-parents-first-orders=v1}
     A commit is in the range when the walk from [h] meets it and the
     ancestry of [s] does not hold it. The walk takes the parents of each
     commit in their order, walks each that is in the range and not started,
     and gives a commit when it finishes it. *)
  let walk_range read ~from h =
    let excluded =
      match from with Some s -> ancestry read s | None -> fresh ()
    in
    let started = fresh () in
    let order = ref [] in
    let frames = Stack.create () in
    let start commit =
      Table.replace started commit ();
      Stack.push (commit, ref (read commit)) frames
    in
    if not (Table.mem excluded h) then start h;
    while not (Stack.is_empty frames) do
      let commit, rest = Stack.top frames in
      match !rest with
      | parent :: others ->
          rest := others;
          if not (Table.mem excluded parent || Table.mem started parent) then
            start parent
      | [] ->
          ignore (Stack.pop frames);
          order := commit :: !order
    done;
    List.rev !order

  let range graph ~from h = run graph (fun read -> walk_range read ~from h)

  (* @satisfies changes#give-merge-bases=v1
     The common ancestors are the commits of the ancestry of [b] that the
     ancestry of [a] holds. A common ancestor that another common ancestor
     reaches is a parent of a common ancestor other than itself, so the merge
     bases are the common ancestors that are no such parent. *)
  let common_bases read a b =
    let of_a = ancestry read a in
    let common = ref [] in
    let reached = fresh () in
    let _, pending, visit = walker () in
    visit b;
    while not (Stack.is_empty pending) do
      let commit = Stack.pop pending in
      let parents = read commit in
      if Table.mem of_a commit then begin
        common := commit :: !common;
        List.iter
          (fun parent ->
            if not (Id.equal parent commit) then Table.replace reached parent ())
          parents
      end;
      List.iter visit parents
    done;
    List.filter (fun commit -> not (Table.mem reached commit)) !common

  let merge_bases graph a b = run graph (fun read -> common_bases read a b)

  (* @satisfies changes#give-changes-of-commits=v1
     With a commit of the default branch, the change of [h] is the range from
     that commit to [h]; with none, [h] has no change. *)
  let change graph ~default h =
    match default with
    | None -> Ok None
    | Some d -> Result.map Option.some (range graph ~from:(Some d) h)

  (* @satisfies changes#give-change-bases=v1
     The change of [h] has a base only when the default branch has a commit
     and [h] and that commit have exactly one merge base, and then that merge
     base is the base. *)
  let change_base graph ~default h =
    match default with
    | None -> Ok None
    | Some d ->
        Result.map
          (function [ base ] -> Some base | _ -> None)
          (merge_bases graph h d)

  let unread = function Ok v -> Ok v | Error e -> Error (Unread e)

  (* @satisfies changes#give-first-parent-lines=v1
     The line follows the first parent of each commit until a commit has no
     parent; a first parent that the line already holds has no such end. *)
  let line graph c =
    let seen = fresh () in
    let rec follow commit acc =
      Table.replace seen commit ();
      match graph commit with
      | Error e -> Error (Unread e)
      | Ok [] -> Ok (List.rev (commit :: acc))
      | Ok (first :: _) ->
          if Table.mem seen first then Error (First_parent_cycle first)
          else follow first (commit :: acc)
    in
    follow c []

  let first_parent_line = line

  (* @satisfies changes#give-landing-commits=v1
     From the last commit of the first-parent line of [d] to [d], each commit
     marks the commits that it reaches and that no later commit of the line
     reaches. The commit of the line that marks [c] is the last commit of the
     line that reaches [c], and no commit marks [c] when [d] does not reach
     it. *)
  let landing_commit graph ~line_of c =
    match line graph line_of with
    | Error e -> Error e
    | Ok commits ->
        unread
          (run graph (fun read ->
               let marked, pending, mark = walker () in
               let rec down = function
                 | [] -> None
                 | m :: higher ->
                     mark m;
                     while not (Stack.is_empty pending) do
                       List.iter mark (read (Stack.pop pending))
                     done;
                     if Table.mem marked c then Some m else down higher
               in
               down (List.rev commits)))
end
