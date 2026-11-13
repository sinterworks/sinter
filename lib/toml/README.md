<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# sinter.toml

`sinter.toml` is a reader of TOML documents in OCaml. It reads TOML 1.1.0 as
the specification `toml` of the design Data forms reads it: the table rules of
that specification replace three statements of TOML 1.1.0 on tables. It
accepts each byte sequence that the specification calls a TOML document, and
it refuses every other byte sequence. It uses only the OCaml standard library.

For a valid document, the reader gives the root table: each value, with
integers as `int64` and floats as binary64 values, the order of the keys in
the document, and the byte span of each value, each key, and each part of a
dotted key. For a byte sequence that is not a valid document, it gives the
kind of the fault and a byte offset. A caller can set limits on the depth of
nesting and on the number of parts of a key. Past a limit, the reader gives a
third outcome, "limit reached", which never says that a document is invalid.

The interface is in `sinter_toml.mli`. At each point where TOML 1.1.0 lets an
implementation choose, the reader follows the specification `toml` of the
design Data forms, `docs/designs/data-forms.md`. The library will leave Sinter
as an OCaml package of its own, named `tomlette`.
