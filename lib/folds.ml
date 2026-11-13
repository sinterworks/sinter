(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type t = {
  text_approvals : (string * int * string, Ledger.entry) Hashtbl.t;
  hash_approvals : (string * string, Ledger.entry) Hashtbl.t;
  declines : (string * string, Ledger.entry list) Hashtbl.t;
  with_set : (string, Ledger.entry * Ledger.entry) Hashtbl.t;
  closings : (string, Ledger.entry) Hashtbl.t;
  deliveries : (string * string, unit) Hashtbl.t;
  started : (string, unit) Hashtbl.t;
}

let table () =
  Hashtbl.create ~random:true 64
  [@mutaml.skip
    "the seed and the first size change only the time of a lookup on keys that \
     collide, and never its result; the code reads a table only by its keys, \
     never in its order"]

let create () =
  {
    text_approvals = table ();
    hash_approvals = table ();
    declines = table ();
    with_set = table ();
    closings = table ();
    deliveries = table ();
    started = table ();
  }

let empty = create ()

let of_entries entries =
  let folds = create () in
  let sets = table () in
  List.iter
    (fun (entry : Ledger.entry) ->
      match entry.body with
      | Ledger.Approval { subject; approved = Text { rev; xh }; _ } ->
          Hashtbl.replace folds.text_approvals (subject, rev, xh) entry
      | Ledger.Approval { subject; approved = Commitment csh; _ } -> (
          Hashtbl.replace folds.hash_approvals (subject, csh) entry;
          match Hashtbl.find_opt sets csh with
          | Some set -> Hashtbl.replace folds.with_set subject (entry, set)
          | None -> ())
      | Ledger.Commitment_set { csh; csh_holds; _ } ->
          if csh_holds then Hashtbl.replace sets csh entry
      | Ledger.Decline { subject; hash; _ } ->
          let key = (subject, hash) in
          Hashtbl.replace folds.declines key
            (entry
            :: Option.value (Hashtbl.find_opt folds.declines key) ~default:[])
      | Ledger.Delivered { subject; csh; _ } ->
          Hashtbl.replace folds.deliveries (subject, csh) ();
          Hashtbl.replace folds.started subject ()
      | Ledger.Completed { subject; _ } | Ledger.Abandoned { subject; _ } ->
          if not (Hashtbl.mem folds.closings subject) then
            Hashtbl.add folds.closings subject entry
      | Ledger.Void _ -> ())
    entries;
  folds

type judged = {
  approval : Ledger.entry option;
  latest_live : Ledger.entry option;
  after : int;
}

let declines folds key =
  Option.value (Hashtbl.find_opt folds.declines key) ~default:[]

let seq_of = function Some (entry : Ledger.entry) -> entry.seq | None -> 0

let judged latest_approval declines =
  let after = seq_of latest_approval in
  let latest_live =
    match declines with
    | (decline : Ledger.entry) :: _
      when (decline.seq > after)
           [@mutaml.skip
             "after is 0 or the seq of an approval; every seq is 1 or more, \
              and no two entries share a seq, so no decline has the seq after"]
      ->
        Some decline
    | _ -> None
  in
  {
    approval = (if Option.is_none latest_live then latest_approval else None);
    latest_live;
    after;
  }

let declaration folds ~subject ~rev ~xh =
  judged
    (Hashtbl.find_opt folds.text_approvals (subject, rev, xh))
    (declines folds (subject, xh))

let step folds ~subject ~hash =
  judged
    (Hashtbl.find_opt folds.hash_approvals (subject, hash))
    (declines folds (subject, hash))

let latest_approval_with_set folds ~subject =
  Hashtbl.find_opt folds.with_set subject

let plan folds ~subject ~hash =
  let latest = Option.map fst (latest_approval_with_set folds ~subject) in
  let judged = judged latest (declines folds (subject, hash)) in
  { judged with approval = latest }

let live folds ~subject ~hash ~after =
  let rec take found = function
    | (decline : Ledger.entry) :: rest when decline.seq > after ->
        take (decline :: found) rest
    | _ -> found
  in
  take [] (declines folds (subject, hash))

let closing folds ~subject = Hashtbl.find_opt folds.closings subject
let delivered folds ~subject ~hash = Hashtbl.mem folds.deliveries (subject, hash)
let started folds ~subject = Hashtbl.mem folds.started subject
