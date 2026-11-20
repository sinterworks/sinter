(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The inflation of one zlib stream of RFC 1950 from a range of a file. *)

type ('s, 'e) outcome =
  | Ended of int
      (** the stream ended, with its checksum, before the byte at this offset
          from the start of the file *)
  | Not_zlib
      (** the bytes are not a zlib stream that ends before the stop, or the
          stream has a window of more than 32768 bytes or a preset dictionary,
          or its checksum is not that of its bytes, or the inflater raised
          [Invalid_argument] on the bytes *)
  | Stopped of 's  (** the sink asked to stop, for this reason *)
  | Unread of 'e  (** a read gave this error *)

val inflate :
  read:(offset:int -> length:int -> (string, 'e) result) ->
  start:int ->
  stop:int ->
  sink:(Zl.bigstring -> int -> (unit, 's) result) ->
  ('s, 'e) outcome
(** [inflate ~read ~start ~stop ~sink] inflates the zlib stream whose first byte
    is at [start], from the bytes that [read ~offset ~length] gives, and reads
    no byte at or after [stop]. It gives each run of inflated bytes, in order,
    to [sink buffer length], as the first [length] bytes of [buffer], which stay
    valid only until [sink] returns; [sink] gives [Error reason] to stop the
    inflation. Its first call of [read] asks for at most 4096 bytes, and each
    later call for at most twice as many as the call before it, and never more
    than 65536. It holds one buffer of input and one of output, of 65536 bytes
    each, and a window of 32768 bytes. *)
