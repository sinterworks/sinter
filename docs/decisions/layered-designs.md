<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Design Sinter as a stack of layered designs before other work
@decision layered-designs
@cites branch-workflow
Sinter is described by a stack of designs in layers, from Identifiers at the bottom to the design "Sinter" at the top; other work waits until the designs are complete, and then the old texts move into the designs.

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
- The design "Identifiers" is at the bottom. It defines the forms of
  names, declarations, and citations, and what a parser must accept
  and reject. It cites no other design, so it can be published alone.
- The design "Ontology" defines the things of Sinter and how they
  relate, with nothing about how Sinter builds or computes them.
- Higher layers define how Sinter reads documents, stores and computes
  state, and checks the work. At the top, the design "Sinter" defines
  the tool in terms of the layers below it. A tool that uses only some
  lower layers is another top.
- The designs are written bottom up, one at a time. When a design
  shows a gap in a lower layer, the work goes back down and fills the
  gap first. The map of the layers is a sketch, and it changes as the
  work shows more.
- Each design gets cold reads until a cold read finds no problem.
- Each design goes into a draft pull request as soon as work on it
  starts. The pull requests form a stack: the branch of each design
  starts from the branch of the design below it. Work is committed and
  pushed often. No design merges until the maintainer decides, so a
  design can change without a new revision.
- Other work on Sinter waits until the designs are complete. This
  includes the pull requests that are open.
- Then the text of `spec/`, the design notes, the plan files, the
  decision records, and the requirements outside a design moves into
  the designs, and the code changes to follow the designs. The
  migration does not need to keep the old forms working on the way.

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

## Consequences

No feature, fix, or release of Sinter happens until the designs are
complete. The open pull requests wait, and they can need rework when
work starts again. Until the migration, `spec/` stays the text that
the code of today follows, and the designs describe Sinter as it will
be. Many draft pull requests stay open at the same time, and a change
in a low design needs a rebase of each pull request above it. A gap in
a lower layer can send the work back down. The lower designs can serve
tools other than Sinter.
