(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The requests and the results of calls of the specification [adapters] of the
    design [packs=v1], read directly from the terms [adapter-request] and
    [call-result], in the forms of the members of the groups [requests] and
    [responses]. *)

val request : Yojson.Basic.t -> string
(** [request input] is the request of the call that [input] gives, where [input]
    is the member [input] of a vector of the group [requests]. It raises
    [Invalid_argument] when [input] is not in that form. *)

type function_ =
  | Recognise
  | Bind of string list
      (** The function of a call, with the test entry ids of a call of bind. *)

val response : function_ -> string -> string * Yojson.Basic.t
(** [response function_ bytes] is the result of a call of [function_] whose
    response is [bytes], and the member [values] of a vector of the group
    [responses] for it. *)
