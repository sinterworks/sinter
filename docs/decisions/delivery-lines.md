<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Name each delivered task in a commit message, and let the job read the original commits of each merge
@decision delivery-lines v2
@supersedes delivery-marks v1
@cites plans-span-branches
@cites agent-statements
@cites commit-messages
A commit that delivers a task carries the line `Delivers: task:<32 hex> <6 hex>`, which names the task's work item and the first six digits of the content hash of its scope, and the job on the default branch reads the original commits of each merge through a host adapter and records a `delivered` observation on the log branch.

## Context

A delivery is an event of a change, and the commits of the change and
the job that runs at each merge see that event. Record `delivery-marks`
put a mark in the plan file for each delivered step, so the plan file
became a second ledger. The first form of the delivery line named a
plan's step and the first six digits of a step hash, and the job read
the lines from the commits that a push brought. Two problems remained:

- A squash merge on a host can drop the messages of the branch's
  commits, and then the job loses the lines. A local `git merge
  --squash` indents each line of the squashed messages by four spaces.
- Work items are now objects in `.sinter/` with content ids, and a
  task's agreement is its `scope` object, so neither a plan's step nor
  a step hash names the thing that a commit delivers.

## Decision

- A commit that delivers a task carries a **delivery line**:
  `Delivers: task:<32 hex> <6 hex>`. The first part is the content id of
  the task's work item object. The six digits are the first six
  hexadecimal digits of the content hash of the task's current `scope`
  object, with no kind word. A rename of the task keeps a delivery, and a
  change of its scope makes the line stale.
- Zero or more spaces may stand before `Delivers:` and before `Task:`. A
  tab before `Delivers:` gives a malformed delivery line, and a line with
  a tab before `Task:` is not a task line.
- At each push to the default branch, the job reads the original commits
  of the pull request of each landing commit through a host adapter, so
  that a squash merge on the host loses no line. When the host no longer
  holds those commits, the job reads the landing commit's own message and
  reports it. v0.1 ships the GitHub adapter and a local adapter, which
  takes a local branch or a series of patches.
- For each delivery line that passes its checks, the job writes a
  `delivered` observation on the log branch. The observation names the
  definition that it observed with one edge, and holds an edge for each
  promise that the work kept. The job makes no judgment of its own.
- On a branch, Sinter reads the delivery lines in the messages of the
  commits of the change. It never reads the history of the default
  branch.
- The plan file and `.sinter/` hold the agreement only. The tag
  `@delivered` stays gone.

## Alternatives considered

- **Users copy the delivery lines from the commits into the message of
  the landing commit.** Not chosen: reading the original commits through
  the host is the reliable way, and copying asks every user to do work
  that the job can do.
- **The GitHub adapter only.** Not chosen: the local source was ruled in,
  and the roadmap already holds the other hosts.
- **Work item ids of 12 random hexadecimal digits, the content id of the
  first definition, or a random 32-digit id.** Put forward; the choice
  was a small work item object whose content id names the task, with a
  nonce of 32 hexadecimal digits. No further reason was recorded against
  the other two.
- **The kind words `task:` and `plan:` shared by work items and their
  definitions, or longer kind words for work items.** Not chosen: one
  kind word would name two kinds, with collisions under short prefixes,
  and the words that people type every day would get the longer name.
- **Keep the step hash, or let tasks share one scope object.** Not
  chosen: a step hash is a second hashing rule beside the content hash,
  and no edge or citation can name it; a shared scope object lets a void
  of one task's scope remove the scope of another.
- **No spaces before the line, as before.** Not chosen: git's squash
  message then needs an edit, while the rule for tabs keeps the earlier
  results.
- **Sinter reads the delivery lines from the history of the default
  branch.** Not chosen: the history becomes an input of every check, and
  a rewritten history changes the answer.

## Consequences

Delivery lines keep their length and their form. The job's inputs grow
by the host's record of each pull request, so the job needs an adapter
for the host of the repository. When a counting void withdraws a task's
scope, the job still records the task's delivery lines, with no observed
definition and no promise. A `delivered` observation for a
work item with no current definition completes nothing. In a run that
could not read a file, the job appends nothing for its range and ends
with an error, and the next run covers that range again; after a limit
of its own, it appends nothing further.
