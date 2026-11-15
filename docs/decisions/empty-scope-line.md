<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Report a `@scope` line with no glob, and read it as no line
@decision empty-scope-line
A `@scope` line that holds no glob counts as no `@scope` line, and Sinter reports it as `invalid-target`.

## Context

A step with a `@scope` line and no glob had an empty scope in the
hash of its plan. Its `commitment-set` entry held no object for the
step, so a reader gave the step the plan scope. The two hashes
differed, so no approval of that plan could count. Sinter did not say
why.

## Decision

- `spec/vocabulary.md` section 10.4 says that such a line counts as no
  `@scope` line, for a step and for a plan.
- The finding is a case of the class `invalid-target`.

## Alternatives considered

- **Count the line as no line, with no finding.** Not chosen: an author
  who meant "no paths" would learn nothing.
- **A finding, with no meaning for the line.** Not chosen: the two
  hashes must still agree while the finding is open.
- **Let an object of `scopes` hold a `step` with no `glob`.** Not
  chosen: it changes the format for one rare case, and it keeps a scope
  in which no promise can be met.
- **Keep the behavior.** Not chosen: such a plan can never be approved.

## Consequences

The hash of the plan and the hash of its entry agree. The finding blocks
at every gate.
