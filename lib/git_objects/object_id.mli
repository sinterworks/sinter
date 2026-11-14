(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The object ids of git objects, in the object formats [sha1] and [sha256]
    that the term [git-folder] of the design [changes=v1] names.

    An object id is a byte sequence of 20 bytes in the object format [sha1] and
    of 32 bytes in [sha256]. Its hex form is two hex digits for each byte, in
    order, the high four bits first; a hex digit is one of the bytes [0] to [9]
    and [a] to [f]. *)

type format =
  | Sha1  (** the object format [sha1] *)
  | Sha256  (** the object format [sha256] *)

val length : format -> int
(** [length format] is the number of bytes of an object id in [format]: 20 for
    [Sha1] and 32 for [Sha256]. *)

type t
(** An object id, in one of the two object formats. *)

val of_bytes : format -> string -> t option
(** [of_bytes format bytes] is [Some id] when [bytes] has [length format] bytes,
    with [id] the object id of these bytes, and [None] otherwise. *)

val of_hex : format -> string -> t option
(** [of_hex format hex] is [Some id] when [hex] is exactly [2 * length format]
    hex digits, with [id] the object id that they write, and [None] otherwise. A
    byte [A] to [F] is not a hex digit. *)

val format : t -> format
(** [format id] is the object format of [id]. *)

val to_bytes : t -> string
(** [to_bytes id] is the bytes of [id]. [of_bytes (format id) (to_bytes id)] is
    [Some id]. *)

val to_hex : t -> string
(** [to_hex id] is the hex form of [id]. [of_hex (format id) (to_hex id)] is
    [Some id]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] when, and only when, [a] and [b] have the same bytes.
*)

val compare : t -> t -> int
(** [compare a b] orders object ids by their bytes, as {!String.compare} orders
    them. It is [0] when, and only when, [equal a b]. *)

val hash : t -> int
(** [hash id] is a whole number from 0 such that [equal a b] implies
    [hash a = hash b]. *)
