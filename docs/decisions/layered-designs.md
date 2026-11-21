<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Design Sinter as a stack of layered designs before other work
@decision layered-designs v2
@cites branch-workflow
Sinter is described by a stack of designs in layers, from "Text and notation" at the bottom to the design "Sinter" at the top; other work waits until the designs are complete, apart from the early implementation of approved lower layers, and then the old texts move into the designs.

## Context

A design is a document that declares requirements under one name.
Today the description of Sinter is spread over the seven
specifications in `spec/`, the design notes, the decision records, the
plan files, and requirements outside any design. These texts often
define a thing and the way Sinter computes it in the same section.

The draft design "The work model of Sinter" changed many of these
texts at once, and it grew to about 3,300 lines. A cold read is a
review by a reader with no earlier context. Five cold reads of the
draft found between 32 and 41 problems each, and the count did not
fall.

Other people can build tools on Sinter, such as an editor extension or
a language server. Such a tool needs a text that defines only the part
that it implements.

## Decision

- Sinter is described by a stack of designs in layers. As far as is
  reasonable, a design cites only designs in lower layers.
- The design "Text and notation" is at the bottom. It defines the
  terms that the other designs share, such as texts, bytes, UTF-8,
  lines, positions, and spans, and the notation of grammars and
  algorithms. It cites no other design of Sinter.
- The design "Identifiers" defines the forms of names, declarations,
  and citations, and what a parser must accept and reject. Among the
  designs of Sinter, it cites only "Text and notation", so a project can
  publish those two designs without the other designs.
- The design "Ontology" defines the things of Sinter and how they
  relate, with nothing about how Sinter builds or computes them.
- Higher layers define how Sinter reads documents, stores and computes
  state, and checks the work. At the top, the design "Sinter" defines
  the tool in terms of the layers below it. A tool that uses only some
  lower layers is another top.
- The designs are written bottom up, one layer at a time. The designs
  of one layer are written at the same time. When a design
  shows a gap in a lower layer, the work goes back down and fills the
  gap first. The map of the layers is a sketch, and it changes as the
  work shows more.
- Each design goes through rounds of critique by readers who did not
  write it: a critique of its requirements and a cold read. The rounds
  stop after a round in which no reader finds a contradiction, or a
  real input for which the design gives a wrong result. A later change
  to a finished design gets a critique of the changed parts.
- The checked work on the designs collects on one feature branch,
  which starts from `main`. That branch has one draft pull request,
  which runs the checks of continuous integration (CI). The work on
  each design stays in commits of its own. Work is committed and pushed
  often. A merge into a feature branch keeps the commits of the merged
  branch. A merge into `main` stays a squash merge.
- When the designs are complete, each design reaches `main` in its own
  pull request, bottom up. No design reaches `main` before then, so a
  design can change without a new revision.
- Other work on Sinter waits until the designs are complete. The pull
  requests that were open when the design work started wait too.
- Then the text of `spec/`, the design notes, the plan files, the
  decision records, and the requirements outside a design moves into
  the designs, and the code changes to follow the designs. The
  migration does not need to keep the old forms working on the way.
- The one exception to the wait is early implementation. When the
  designs of a lower layer are approved for early implementation, the
  code for those designs can be written before the designs are
  complete. That code collects on a feature branch of its own, which
  starts from the feature branch of the designs. The feature branch of
  the code takes in the later changes of the feature branch of the
  designs, and it has one draft pull request for CI. The code reaches
  `main` in pull requests of its own, only after every design reaches
  `main`.

## Alternatives considered

- **One design for the work model** — the draft "The work model of
  Sinter". Rejected: it held many topics in one text, and five cold
  reads did not reach a clean result.
- **A split of that design by topic** — nine designs, such as "Names
  and citations", "Approval", and "Tasks and delivery", and one short
  design that ties them together. Rejected: two of the designs cited
  each other, the split covered only the work model, and no design was
  a lower layer that another tool could use alone.
- **Layers only where the work model changes them** — write now only
  "Identifiers", the "Ontology", and the designs that the work model
  adds to, and the rest of the layers later, when `spec/` is
  rewritten. Rejected: gaps show in order only
  when the layers are written bottom up, and the old texts and the
  designs would describe the same things for a long time.
- **A migration that keeps the old forms working** — a transition
  document with the end conditions of the migration, and the steps as a
  plan. Rejected: other work waits, so nothing needs the old forms
  during the migration.
- **One stacked draft pull request for each design** — the branch of
  each design starts from the branch of the design below it. Revision 1
  of this record chose stacked draft pull requests. Replaced: a change
  in a lower design needed a rebase of every pull request above that
  design.
- **No code until the designs are complete** — revision 1 of this
  record chose that rule as well. Replaced: code for an approved lower
  layer finds the gaps of its designs while the layers above can still
  change. That code stays off `main` until every design reaches `main`.

## Consequences

No feature or fix of Sinter reaches `main`, and no release happens,
until the designs are complete. The pull requests that were open when
the design work started wait. Those pull requests can need rework when
other work starts again. Until the migration, `spec/` stays the text
that the code on `main` follows, and the designs describe Sinter as it
will be. The two feature branches stay open until the designs are
complete. Each pull request to `main` then takes its commits from
those feature branches. A gap in a lower layer can send the work back
down. Code written early follows the designs, and a later change that
fills a gap in a lower design can need a change in that code. The
lower designs can serve tools other than Sinter.
