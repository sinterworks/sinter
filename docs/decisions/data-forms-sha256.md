<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Compute SHA-256 with digestif in the library of hashes of the design Data forms
@decision data-forms-sha256
@cites sha256
@cites commonmark-reader
@cites layered-designs
@cites licensing
@cites current-dependencies
The library `sinter.hashes` of the design Data forms computes SHA-256 with the opam library `digestif` 1.4.1.

## Context

The design Data forms defines the hash of a byte sequence as the hex
text of its SHA-256 digest, as FIPS 180-4 defines SHA-256, and a hash id
as an id prefix, then the first n hex digits of a hash, for an n from
1 to 64. A hex text is a text of the digits `0` to `9` and the letters
`a` to `f`. The `Digest`
module of OCaml 5.5 has MD5 and BLAKE2, and no SHA-256.

A layered design is one of the designs in layers of the record
`layered-designs`. The design Data forms is one of these designs. The
libraries of the layered designs so far depend on no library in the
repository except the libraries of other layered designs; they do not
depend on the core library or on the bridge. The core library computes SHA-256 with the Rust crate `sha2`,
through the parser bridge, by the record `sha256`. That record rejected
`digestif` for the core library because it was a new dependency, while
the bridge already shipped `sha2`. The record `commonmark-reader` did
not choose a grammar through the bridge for the library of the design
Identifiers; one of its reasons was that the library would then depend
on the bridge and on wasmtime. So for the library of a layered design,
every option adds something: a new package in the lock file (`digestif`
or `sha`), a dependency of the library on the bridge and wasmtime
(`sha2`), or new code of Sinter's own.

`digestif` 1.4.1 has the MIT license and needs one other package,
`eqaf` 0.10, also MIT. With OCaml 5.5.2, the opam solver accepts both
packages and changes no other version in `sinter.opam.locked`.

## Decision

- The library `sinter.hashes` computes SHA-256 with `digestif`.
- The library does not fix whether SHA-256 runs in C or in OCaml. Each
  program that links the library can choose the C code (`digestif.c`)
  or the OCaml code (`digestif.ocaml`) of `digestif`. A program that
  chooses neither gets the C code, which is the default of `digestif`.
- Sinter moves `digestif` to each new release, as
  `current-dependencies` requires.

## Alternatives considered

- **The crate `sha2` through the bridge, as the record `sha256` does.**
  Not chosen. The library would depend on the bridge and on wasmtime,
  which the record `commonmark-reader` counted against the same kind of
  option.
- **A SHA-256 of Sinter's own, in OCaml.** Not chosen. It is
  cryptographic code to maintain, and its bit arithmetic gives the
  mutation tests many places to cover.
- **The opam package `sha` 1.15.4** (ISC). Not chosen. Fewer opam
  packages depend on it: 14, against 91 for `digestif`, in the opam
  index of 2026-10-26.

## Consequences

Sinter has two more OCaml dependencies. Until the core library is
replaced, Sinter gets SHA-256 from two sources: `sha2` through the
bridge, for the core library, and `digestif`, with the C code or the
OCaml code that each program links, for `sinter.hashes`. A
program that links both libraries, such as the test suite, holds both.
