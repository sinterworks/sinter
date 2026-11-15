<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Report a decline of a step, and refuse one of a step with promises
@decision step-declines
@cites last-judgment-wins
A live decline of a step gives the finding `declined` and sets a field of the step record, and the decline command refuses a step with promises.

## Context

The specifications allowed a decline of any step. The step record had
no `declined` field, and the class `declined` did not cover steps. The
approval command refuses a step with promises, so only a change of the
text could end a decline of such a step.

## Decision

- The step record has the field `declined`.
- The class `declined` covers steps.
- The subject of a decline is a declaration, a plan, or a step without
  promises.

## Alternatives considered

- **The field and the class, with no refusal.** Not chosen: a person
  who declines a step with promises cannot approve over their own
  refusal.
- **The field only.** Not chosen: the refusal then stops nothing at any
  gate.

## Consequences

The decline command and the approval command accept the same steps. To
refuse one step with promises, a person declines the plan and names the
step in the reason. A line for such a step that another writer adds
still gives the finding, and only a change of the text ends it.
