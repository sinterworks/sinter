(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type ('s, 'e) outcome = Ended of int | Not_zlib | Stopped of 's | Unread of 'e

let chunk = 65536
let first_chunk = 4096

let blit_string text input =
  String.iteri (fun index byte -> Bigarray.Array1.set input index byte) text

(* @satisfies changes#take-objects-only-from-repositories=v1
   A loose object is one zlib stream as RFC 1950 defines it: a stream whose
   window is above 32768 bytes, or that needs a preset dictionary, is refused
   before it is inflated, also when the inflater could give bytes that hash to
   the object id. *)
let refused_header first =
  (String.length first < 2)
  [@mutaml.skip
    "a mutant refuses also a first read of exactly 2 bytes, which gives \
     Not_zlib with or without the test: a read gives fewer bytes than it asks \
     for only before the stop or the end of the file, and a zlib stream has 2 \
     header bytes and 4 checksum bytes"]
  || Char.code first.[0] lsr 4 > 7
  || Char.code first.[1] land 0x20 <> 0

let inflate ~read ~start ~stop ~sink =
  let input = De.bigstring_create chunk in
  let output = De.bigstring_create chunk in
  let window = De.make_window ~bits:15 in
  let used decoder = De.bigstring_length output - Zl.Inf.dst_rem decoder in
  let give decoder resume =
    match sink output (used decoder) with
    | Ok () -> resume ()
    | Error reason -> Stopped reason
  in
  let rec go decoder position length =
    match Zl.Inf.decode decoder with
    | exception Invalid_argument _ -> Not_zlib
    | `Await decoder -> (
        match read ~offset:position ~length:(min length (stop - position)) with
        | Error error -> Unread error
        | Ok text when position = start && refused_header text -> Not_zlib
        | Ok text ->
            blit_string text input;
            go
              (Zl.Inf.src decoder input 0 (String.length text))
              (position + String.length text)
              (min chunk (2 * length)))
    | `Flush decoder ->
        give decoder (fun () -> go (Zl.Inf.flush decoder) position length)
    | `End decoder ->
        give decoder (fun () -> Ended (position - Zl.Inf.src_rem decoder))
    | `Malformed _ -> Not_zlib
  in
  go
    (Zl.Inf.decoder `Manual ~o:output ~allocate:(fun _ -> window))
    start first_chunk
