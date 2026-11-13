<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Read JSON in the library of JSON lines of the design Data forms with readers of Sinter's own
@decision canonical-json-reader
@cites json-handling
@cites rfc/8259
The library `sinter.json_lines` of the design Data forms reads JSON with two readers of its own, a strict reader of canonical byte sequences and a reader of JSON texts, and it does not use the OCaml library `yojson`.

## Context

The design Data forms gives each JSON value exactly one canonical byte
sequence: keys in a fixed order, a fixed set of escapes, no white space
outside strings, and integers only. A program that answers whether a
byte sequence is the canonical line of a line object must answer
"valid" exactly for the canonical lines: the canonical byte sequence of
a line object, then the byte 0x0A. A line object is an object in which
the value of each member is a string, an integer, a boolean, or an
array of these, or an array of objects whose member values are strings,
integers, or booleans. A test-vector set is a byte sequence, defined by
the design, that holds vectors; each vector is an input and what a
conforming program must give for that input. The reader of test-vector sets
needs the same strict reading, for JSON values of any depth.

The design also defines when a byte sequence has a JSON value: when the
byte sequence is valid UTF-8, and its text is a JSON text of RFC 8259
that holds no `null`, only numbers with no fraction and no exponent that
write a whole number from −(2^53 − 1) to 2^53 − 1, no unpaired surrogate
escape, and no two member names that stand for one text. An unpaired
surrogate escape is an escape `\u` of a number from 0xD800 to 0xDFFF
that is not one of a pair: an escape of a number from 0xD800 to 0xDBFF
right before an escape of a number from 0xDC00 to 0xDFFF. The design
sets no limit on the depth of such a text. A program may give no result
for a text past a nesting limit of its own, but never "invalid" for a
byte sequence that has a JSON value.

The record `json-handling` makes the core library read JSON with
`yojson`. `yojson` 3.0.0 reads an unpaired surrogate escape from 0xDC00
to 0xDFFF, such as `\ude00`, as bytes that are not UTF-8. It keeps
repeated member names, it passes bytes that are not UTF-8, and it takes
a tab in a string. So a reader built on it must check each of these
cases itself.

## Decision

- The library has a strict reader of its own. It accepts a byte
  sequence exactly when the byte sequence is the canonical byte
  sequence of a JSON value of the design.
- The library has a reader of JSON texts of its own. It gives the JSON
  value of a byte sequence as the design defines it, with no limit on
  depth.
- The writer of the canonical form and both readers are in the one
  library `sinter.json_lines`.
- The library does not depend on `yojson`. The tests can use it to read
  the inputs of the vectors.

## Alternatives considered

- **`yojson`, then checks of Sinter's own, for the strict reader.** Not
  chosen. The reader would check UTF-8, repeated member names, and the
  range of integers, then write the value again and compare the bytes
  with the input. Whether it is correct would then depend on how
  `yojson` reads cases at the edge, which can change in a new release.
- **`yojson`, then checks of Sinter's own, for the reader of JSON
  texts.** Not chosen, for the same reason: each case that `yojson`
  takes and the design refuses would need a check of Sinter's own.

## Consequences

The library holds two readers and a writer of its own. Sinter reads and
writes JSON in two ways: the core library reads with `yojson` and writes
with the printer of `json-handling`, and `sinter.json_lines` reads and
writes with its own code. The record `json-handling` still says that
every JSON reader in Sinter depends on `yojson` and that one printer in
`sinter.core` writes all of Sinter's JSON; both hold for the core
library only, until the core library is replaced.
