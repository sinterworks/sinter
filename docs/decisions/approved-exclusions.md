<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Keep each approved `!` glob when a plan's scope changes
@decision approved-exclusions
@cites last-judgment-wins
A new scope is inside an approved scope only when its plain globs are contained in the approved plain globs and each approved `!` glob appears in it verbatim, and a new `!` glob needs no case.

## Context

`spec/ledger.md` section 11.2 checked each glob of the new scope by
itself. When a plan removed `!src/secret/**`, the remaining `src/**`
passed, and the plan stayed approved for paths that the person had
left out.

## Decision

- Each plain glob of the new scope satisfies one of the three cases of
  section 11.2 against the approved plain globs.
- Each `!` glob of the approved scope appears verbatim in the new
  scope.
- A `!` glob that only the new scope has needs no case, because it only
  leaves paths out.

## Alternatives considered

- **Any `!` glob in either scope needs a new approval unless the lists
  are equal.** Not chosen: a change that only narrows a scope also needs
  a new approval.
- **Check the plain globs alone, as `scope-outside-plan` does.** Not
  chosen: the widening stays.

## Consequences

Removing a `!` glob needs a new approval, also when the new plain globs
no longer reach its paths.
