<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Read CommonMark with cmarkit
@decision commonmark-reader
@cites licensing
@cites current-dependencies
The library of the design Identifiers reads Markdown documents with the OCaml library `cmarkit` 0.4.0, and Sinter's own code adds the definitions of the design Identifiers that CommonMark 0.31.2 does not have.

## Context

The design Identifiers defines an inline citation as a Markdown link
whose destination starts with `sinter:`. It defines a link, its
destination, and the inline elements of its link text by citing
CommonMark 0.31.2. A program that conforms must therefore read the
whole document as CommonMark 0.31.2 reads it: the blocks, the inline
elements, the link reference definitions, the backslash escapes, and
the entity references. Today's code reads only the block structure of
Markdown, with a tree-sitter grammar through the bridge, and it has no
inline parser.

`cmarkit` 0.4.0 (2025-11-01) states support for CommonMark 0.31.2. Its
license is ISC, which is none of the licenses that `licensing`
rejects, and it has no runtime dependencies. With `~locs:true` it gives
each node of a document its byte positions and line numbers. With
OCaml 5.5.2 it installs as one package and changes no other version in
`sinter.opam.locked`. It keeps an autolink inside link text as a link
of its own. It replaces escapes and entity references in the
destination of an inline link or a reference link, as the design
requires. The tests of the library check both.

`cmarkit` 0.4.0 has one known performance defect, the nesting defect:
its time doubles with each level of square brackets nested in one
another, where CommonMark needs time in proportion to the length of
the text. On the text `[` × n, then `x`, then `]` × n, then `(u)`, one
read took 0.2 seconds for n = 22 and 1.9 seconds for n = 25. For
n = 30, the read was stopped after 120 seconds. The author of
`cmarkit` tracks the defect as its issue #5, open since April 2023,
with no plan for a fix.

## Decision

- The library of the design Identifiers reads a Markdown document with
  `cmarkit`, in its strict CommonMark mode, with source locations.
- Sinter moves `cmarkit` to each new release, as
  `current-dependencies` requires.
- The nesting defect is accepted for now. Today only the tests call
  the library, so the defect reaches no user. The remedy is chosen
  before any command of Sinter calls the library.

## Alternatives considered

- **A CommonMark reader of Sinter's own, in OCaml.** Rejected: by
  estimate, the block parser, the inline parser, the reference
  definitions, and the table of entity names come to several thousand
  lines, and a maintained library already reads the same version of
  the standard.
- **The tree-sitter inline grammar of Markdown, through the bridge.**
  Rejected: it would make the library depend on the bridge and
  wasmtime, and Sinter's code would still have to replace escapes and
  entity references and resolve reference links.
- **A fix of the nesting defect, in a changed copy of `cmarkit` that
  Sinter builds until the author of `cmarkit` takes the fix.** Not
  chosen now: it is work inside another project's parser, for a defect
  that reaches no user yet.
- **A limit, in Sinter's code, on the depth of nested brackets.** Not
  chosen now: the design reads every document as CommonMark does, so a
  limit needs a change of the design.

## Consequences

Sinter has one more OCaml dependency, and every tool that uses the
library of the design Identifiers needs it too. Sinter has two
Markdown readers until the old block reader goes: the tree-sitter
grammar and `cmarkit`. A defect of `cmarkit` against CommonMark 0.31.2
becomes a defect of Sinter until `cmarkit` fixes it or Sinter's code
works around it. Until the nesting defect is fixed, a Markdown text
with square brackets nested about 30 levels deep makes the reader of
inline citations run for minutes or longer, which looks like a hang.
