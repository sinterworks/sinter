<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Let `revises` edges decide which judgments count, and let a conflict decide nothing
@decision judgments-by-edges
@supersedes last-judgment-wins v1
@cites ledger-event-log
A new judgment names with `revises` the earlier judgments of the same thing that it replaces; the latest counting judgments decide a state only when they agree, and a conflict between them decides nothing until a person settles it.

## Context

Record `last-judgment-wins` let the approval or decline with the greatest
`seq` decide whether a subject was approved. Under the split ledger
(record `ledger-event-log`), statements live in `.sinter/` on ordinary
branches and carry no `seq`, and no state depends on the order of
records. Two persons on two branches can judge the same object, and
neither saw the other's judgment. A judgment can also come from a writer
whom the project does not trust to judge, such as an agent. The
question stays which judgments of one thing count, but the earlier
choice, an order of judgments, has nothing left to read.

## Decision

- **Edges replace an order.** A new judgment names with `revises` each
  earlier judgment of the same thing that it replaces. The latest
  judgments of a thing are the counting judgments that no other counting
  judgment of that thing replaces. An approval may replace an approval.
  After a void of the only latest judgment, a new judgment names no
  judgment with `revises`.
- **A conflict decides nothing.** When latest judgments of one thing
  disagree, the thing gets neither state, and a conflict finding names
  both judgments. An approval and a decline in conflict leave the subject
  awaiting approval. A completing `delivered` observation and a latest
  `abandoned` of the same definition are a conflict, and the task stays
  delivered until a person settles it.
- **A statement that does not count leaves the graph.** It replaces
  nothing and is never a latest statement. A judgment or a void with the
  member `agent` does not count.
- **The list of persons.** Approval declares an optional list of persons.
  When the list is bound, a judgment or a void counts only when its `by`
  is exactly the text of an entry of the list. An empty list counts no
  person. Under a binding of the list that is not valid, the program
  withholds only the results whose value depends on whether such a
  judgment or void counts.
- **Judgments name exact objects.** A judgment judges one object by its
  content id, never an identity, so a judgment of another revision counts
  for nothing for the current revision.
- **A withdrawn scope.** A live task definition that names a withdrawn
  `scope` object keeps its current definition, and every result that
  reads its paths or promises is withheld, with a finding.

## Alternatives considered

- **`supersedes` for judgments, a third word such as `replaces`, or
  `revises` only for declared items.** Not chosen: `supersedes` keeps two
  meanings, a third word adds a near-synonym, and each leaves two kinds
  of replacement by the kind of the source.
- **A negative judgment wins a conflict.** Not chosen: a plan could
  become done while a person still holds that the work is finished.
- **No state at all during a conflict.** Not chosen: it contradicts the
  rule that a subject in conflict counts as not approved.
- **In a conflict of an observation and a judgment, the judgment wins,
  or the observation wins.** Not chosen: finished work would become
  abandoned with no report, or a person's judgment would change nothing
  and nothing would say so.
- **A statement that does not count stays in the graph but is silent, or
  its effect depends on its cause.** Not chosen: anyone could erase a
  listed person's judgment by writing a statement that does not count.
- **A judgment or a void with `agent` counts.** Not chosen: a merge that
  passes despite the finding on writers would let an agent's judgment
  decide a state.
- **The Ledger declares the list of persons.** Put forward and not
  chosen, in favor of Approval; no further reason was recorded.
- **The list limits judgments but not voids.** Not chosen: the list
  would limit who approves but not who withdraws approvals.
- **After a void, a new judgment names the withdrawn judgment or the
  void.** Not chosen: the check of latest targets would need an
  exception and could no longer tell whether the writer saw the void,
  and a void is about no thing.
- **A task whose scope is withdrawn has no current definition.** Not
  chosen: withdrawing one task's scope would hide its plan, its waits,
  and its external item, and hold back the states of unrelated plans.
- **An approval never replaces an approval.** Not chosen: a second
  person's approval names the first one that the person saw, and the rule
  of acceptance then needs no test for a conflict.
- **Signing keys for judgments.** Left for the roadmap or the Security
  design.

## Consequences

In a conflict, the finding `declined` does not show the reason of the
decline; the conflict finding names both judgments. A person who
abandons a plan with open tasks sees findings until the person deals
with each task. Statements that do not count stay in `.sinter/`, and
each has a finding. The list of persons does not stop forgery of `by`;
signed judgments are a later choice.
