<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Read TOML 1.1.0 with a library of Sinter's own that can be published apart from Sinter
@decision toml-library
@cites toml-reader
@cites licensing
@cites layered-designs
@cites toml-lang/1.1.0
The libraries of the layered designs read TOML with the OCaml library `sinter.toml` (not the manifest file of the same name), which is Sinter's own and uses only the OCaml standard library.

## Context

The specification `toml` of the design Data forms
(`docs/designs/data-forms.md`, section 5) says which byte sequences
are TOML documents, the root table of each one, and the spans of its
values and keys. It follows TOML 1.1.0, but its rules on tables replace
three statements of TOML 1.1.0.

The core library reads TOML with the Rust crate `toml_edit` 0.25.17,
through the parser bridge (record `toml-reader`). On the 312 vectors of
the specification, `toml_edit` gives the other result on four, and it
reads the offset `-00:00` of a fifth as `+00:00`:

| vector | input | `toml_edit` gives | the specification gives |
|---|---|---|---|
| 182 | arrays nested 200 deep | "invalid" | "valid" |
| 183 | a dotted key of 200 keys | "invalid" | "valid" |
| 21 | a newline between a key and `=` in an inline table | "valid" | "invalid" |
| 65 | `[[a.b]]`, then `[a]`, then `b.c.y = 2` | "valid" | "invalid" |
| 52 | the offset `-00:00` | `+00:00` | the unknown local offset, not the offset zero |

On vector 182, `toml_edit` stops at its limit of 80 levels of nesting,
and on vector 183 at its limit of 80 keys in a dotted key; on both it
gives "invalid". The specification lets a program stop at a limit
of its own only if it then gives no result.

The maintainer wants a TOML reader with the quality of a published
package, so that it can be published apart from Sinter later as the
OCaml package `tomlette`.

## Decision

- `sinter.toml` reads TOML 1.1.0 as the specification `toml` reads it.
  It uses no other library of Sinter, so that it can be published apart
  from Sinter.
- `sinter.toml` gets a specification of its own when it is published
  apart from Sinter.

The reasons: `toml_edit` differs from the specification. The record
`licensing` rules out the OCaml TOML readers on opam. A reader in OCaml
is inside Sinter's coverage measurement and mutation tests, and it needs
no parser bridge.

## Alternatives considered

- **The opam packages `toml` 7.1.0, `otoml` 1.0.5, and `drom_toml`
  0.8.0.** Not chosen. `toml` and `drom_toml` are LGPL, and `otoml`
  depends on `menhirLib`, which is LGPL. The record `licensing` rejects
  LGPL outside the OCaml runtime.
- **`toml_edit` through the parser bridge, with checks of Sinter's
  own.** Not chosen. Sinter's code would need a check for each case
  that the crate reads differently, and the library would depend on the
  parser bridge.
- **The C library `tomlc17`, release R261109.** Not chosen. It reads
  TOML 1.1, under MIT, but it gives no span of a key and no end of a
  value, so Sinter's code would still have to find the spans.

## Consequences

Sinter keeps a TOML reader of its own, of about 1,200 lines of OCaml.
Until the code changes to follow the designs (record `layered-designs`),
the core library keeps `toml_edit` under `toml-reader`, and Sinter has
two TOML readers that differ on the vectors above.
