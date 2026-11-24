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
- A task line, `Task: task:<32 hex>`, names a task that a commit works
  on without finishing it. Zero or more spaces may stand before
  `Delivers:` and before `Task:`, because a local `git merge --squash`
  indents the squashed messages. A tab before `Delivers:` gives a
  malformed delivery line, and a line with a tab before `Task:` is not a
  task line.
- At each push to the default branch, the job reads the original commits
  of the pull request of each landing commit, the commit through which
  the pull request lands on the default branch, through a host adapter, so
  that a squash merge on the host loses no line. When the host no longer
  holds those commits, the job reads the landing commit's own message and
  reports it. v0.1 ships the GitHub adapter and a local adapter, which
  takes a local branch or a series of patches.
- For each delivery line that passes its checks, the job writes a
  `delivered` observation on the log branch. When the task has a current
  definition whose scope is not withdrawn, the observation names that
  definition with one edge and holds an edge for each promise that the
  work kept. The job makes no judgment of its own.
- When a promise of an observed definition does not resolve or has no
  outcome, the job appends nothing for its range, reports each such
  promise, and ends with an error, so the next run covers the range
  again. When the `.sinter/` store of the tip commit of the run is not
  valid, the job stops, appends nothing, and reports the invalid store,
  because a later commit can fix it. When the tip commit's store is
  valid and the `.sinter/` store of an earlier landing commit in the
  range is not valid, the job records no delivery of that commit,
  appends the rest of the range and its `progress` observation, reports
  the commit, and ends with an error; a person records each lost
  delivery with a `done` judgment.
- On a branch, Sinter reads the delivery lines in the messages of the
  commits of the change. It never reads the history of the default
  branch.
- The definitions and scopes in `.sinter/` hold the agreement only. No
  text file records a delivery, and Sinter has no tag `@delivered`.
- This form applies when the code follows the designs (record
  `layered-designs`). Until then, a commit in this repository carries
  the form that record `commit-messages` gives.

## Alternatives considered

- **Users copy the delivery lines from the commits into the message of
  the landing commit.** Not chosen: reading the original commits through
  the host is the reliable way, and copying asks every user to do work
  that the job can do.
- **The GitHub adapter only.** Not chosen: the job also takes a local
  branch or a series of patches, and the roadmap already holds the other
  hosts.
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
- **For a promise with no outcome, append the observation without that
  promise, or skip the task for good.** Not chosen: the first records
  the promise as not kept for good, and the second loses the delivery.
- **For an invalid store at an earlier landing commit, stop the run, or
  read that commit's deliveries against the store at the tip.** Not
  chosen: every later run would meet the same commit, so the job would
  stop until the default branch is rewritten; and the second adds a
  second rule for where definitions come from, while a definition
  revised after the merge no longer matches the line's six digits.
- **Sinter reads the delivery lines from the history of the default
  branch.** Not chosen: the history becomes an input of every check, and
  a rewritten history changes the answer.

## Consequences

The job's inputs grow
by the host's record of each pull request, so the job needs an adapter
for the host of the repository. When a counting void withdraws a task's
scope, the job still records the task's delivery lines, with no edge to
the definition and no promise, because the scope that such edges rest on
is withdrawn. A `delivered` observation for a
work item with no current definition completes nothing. In a run that
could not read a file, the job appends nothing for its range and ends
with an error, and the next run covers that range again; after a limit
of its own, it appends nothing further.
