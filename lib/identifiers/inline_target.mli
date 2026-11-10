(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The target of an inline citation, as the design [identifiers=v1] defines it.
*)

val read : Binding.t -> string -> Target.t option
(** [read binding target] is the values of [target], the text of the destination
    of an inline citation after [sinter:], when [target] matches the production
    [inline-destination] after [sinter:] under [binding]: an optional kind word
    and [:], then a name, [=], and a revision, or an external id with an
    optional [#] and part name. The values hold no vector selection and no
    every-part target. An external target matches only as an external id whose
    namespace name is in [binding] and whose id fits its id pattern. It is
    [None] otherwise. *)
