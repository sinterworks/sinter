<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Follow the brief while the layered designs replace the earlier design
@decision orient-on-brief v1
@cites layered-designs
Until the rewrite into layered designs ends, a session follows the brief of its task, not the documents of the earlier design.

## Context

The design notes (`docs/design-notes.md`), the seven specifications in
`spec/`, and most decision records describe an earlier design of
Sinter. The decision record `layered-designs` rewrites that design as a
stack of layered designs. The rulings of that rewrite already reverse
parts of the earlier documents. For example, the design notes say that
the JSON lines of Sinter are "always derived, never a source", and the
rewrite makes one JSON line the canonical form of every object.

`CLAUDE.md` sent each new session to the earlier documents to orient.
So a session oriented on a design that no longer holds.

## Decision

- Until the rewrite ends, a session does not treat the design notes,
  the specifications in `spec/`, or the decision records about the
  earlier design as the current design.
- A session follows the brief of its task. A brief is the written task
  that a session receives when it starts.
- A session without a brief follows the person it works with, or the
  plan step, the issue, or the request that asks for the work.
- When the brief and a document of the earlier design disagree, the
  session follows the brief and tells the person it works with about
  the disagreement.
- These documents still apply:
  - the decision records that `CONTRIBUTING.md` and the files in
    `docs/contributing/` name for the project's procedures, such as
    commit messages, code comments, and testing, and the decision
    records that those records cite;
  - `docs/roadmap.md` and the plans in `.plans/`.
- The rule also covers each place where `CONTRIBUTING.md` points to
  `spec/` or to a decision record about the earlier design.

## Alternatives considered

- **Update the design notes and the specifications as the rewrite
  goes.** Not chosen: the layered designs replace these documents, and
  the design notes will be retired, so the work of updating them would
  be lost.
- **Leave `CLAUDE.md` as it was.** Not chosen: each new session would
  keep orienting on a design that the rewrite reverses.

## Consequences

`CLAUDE.md` says in step 1 that sessions follow their brief, calls the
files in `spec/` the specifications of the earlier design, and lets the
brief win over the code and over the documents of the earlier design.
When the layered designs reach `main`, `CLAUDE.md` points to them, and
the design notes are deleted.
