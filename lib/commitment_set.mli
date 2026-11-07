(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The commitment-set hash of a plan. *)

type step = {
  scope : string list;  (** the effective scope of the step *)
  promises : (string * string) list;
      (** the promises of the step: the tag word and the tag target of each, for
          example [("req", "auth-lockout")] *)
}
(** The promises of one step, with the scope that they share. *)

val bytes : scope:string list -> step list -> string
(** [bytes ~scope steps] is the canonical bytes that the commitment-set hash
    covers, for a plan whose plan scope is [scope] and whose steps are [steps]:
    one object in the canonical form of RFC 8785, with no line feed, with the
    keys [groups] and [scope]. [groups] holds one object for each distinct
    effective scope that holds a promise, with the keys [promises] and [scope].
    [promises] holds one object for each promise of the steps with that scope,
    with the keys [target] and [word], in the order of the word and then the
    target, each in byte order. Each array of globs holds each glob once, in
    byte order. The groups are in the byte order of the canonical bytes of their
    scope. The order of [scope], of [steps], of the promises of a step, and of
    the globs of a step changes nothing, and nor does the step that holds a
    promise when two steps have one scope. A step with no promise adds nothing.

    The length of the result is at most a constant, plus a constant for each
    glob and for each promise, plus a constant times the bytes of the globs, the
    words, and the targets. A scope that many promises share stands once.

    @raise Invalid_argument
      if a glob of [scope], a glob of a step that holds a promise, a word, or a
      target is not valid UTF-8. A glob of a step with no promise is not read.
*)

val hash : scope:string list -> step list -> string
(** [hash ~scope steps] is the commitment-set hash: the 64 lowercase hexadecimal
    digits of the SHA-256 of {!bytes}[ ~scope steps].

    @raise Invalid_argument
      if a glob of [scope], a glob of a step that holds a promise, a word, or a
      target is not valid UTF-8. A glob of a step with no promise is not read.
    @raise Sinter_bridge.Error if the bridge stops on an internal fault. *)
