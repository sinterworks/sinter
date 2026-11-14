(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Seen = Map.Make (String)

type member = { text : Text.t; excluding : bool; glob : Glob.t }
type t = member list
type glob_error = { member : int; error : Glob.error }

type fault =
  | Repeated_member of { first : int; second : int }
  | No_plain_member

(* @satisfies files#{validate-path-sets=v1, decide-path-set-membership=v1}
   A path set member that starts with `!` is a `!` member whose glob text is
   the text after the `!`; each other path set member is its own glob text,
   and each glob text must be a valid glob. *)
let member_of number text =
  let excluding = String.starts_with ~prefix:"!" (Text.encode text) in
  let glob_text =
    if excluding then
      Option.value ~default:Text.empty
        (Text.sub text { from = 1; until = Text.length text })
    else text
  in
  match Glob.of_text glob_text with
  | Ok glob -> Ok { text; excluding; glob }
  | Error error -> Error { member = number; error }

let of_texts texts =
  let rec read number members = function
    | [] -> Ok (List.rev members)
    | text :: texts -> (
        match member_of number text with
        | Ok member -> read (number + 1) (member :: members) texts
        | Error error -> Error error)
  in
  read 1 [] texts

(* @satisfies files#validate-path-sets=v1
   A path set whose glob texts are valid globs is valid unless two path set
   members are the same text, or it holds path set members and none of them is
   a plain member. *)
let validate set =
  let rec repeated seen number = function
    | [] -> None
    | member :: members -> (
        let key = Text.encode member.text in
        match Seen.find_opt key seen with
        | Some first -> Some (Repeated_member { first; second = number })
        | None -> repeated (Seen.add key number seen) (number + 1) members)
  in
  match repeated Seen.empty 1 set with
  | Some fault -> Error fault
  | None ->
      if set <> [] && List.for_all (fun member -> member.excluding) set then
        Error No_plain_member
      else Ok ()

(* @satisfies files#decide-path-set-membership=v1
   A valid path is in the set when it fits the glob text of a plain member and
   the glob text of no `!` member. *)
let mem set path =
  let fits excluding =
    List.exists
      (fun member -> member.excluding = excluding && Glob.fits member.glob path)
      set
  in
  fits false && not (fits true)
