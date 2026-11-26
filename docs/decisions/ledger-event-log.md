<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Make Sinter a pure function of a snapshot and one log that only the job writes
@decision ledger-event-log v2
@cites delivery-lines
Every state and every result of a check is a pure function of a snapshot of the repository and one log: statements live in `.sinter/` on ordinary branches, only the job on the default branch writes the log branch, every check before a merge only reads, and states follow from the edges between records, not from their order.

## Context

Sinter's inputs are the working tree, the base, the commit messages of
the change, the test evidence, the session, and the records of the work.
The earlier model kept every record in one ledger under a ref of its own,
ordered by a number that each writer gave, and folded every state over
that order. A walk through 18 workflows of that model found 2 that
worked, 4 that worked with friction, 6 that failed, and 6 that no text
specified. Three causes stood out:

- No host protects a ref such as `refs/sinter/ledger`, and a plain clone
  does not fetch it.
- A check of a pull request runs code that nobody reviewed yet. When
  such a check writes the ledger, the code gets a token that can write
  it.
- A pull can drop a person's approval, because the approval no longer
  fits after the entries of another clone.

The terms of this record come from the designs in `docs/designs/`,
chiefly the Ontology (`ontology.md`) and the Ledger (`ledger.md`).

## Decision

- Every state and every result of a check is a pure function of a
  snapshot and one log. The snapshot is the tree of a commit with its
  `.sinter/` folder, the commit messages of the change, the test
  evidence, and the session. The log is the log branch.
- The job is a run of Sinter on the default branch after each push. It
  is the one part of Sinter that reads beyond the snapshot: it reads the
  host's record of each merged pull request (record `delivery-lines`),
  and what it writes becomes part of the log.
- Persons and agents write definitions of work, and only persons write
  judgments (approvals, declines, `done`, and `abandoned`) and voids.
  Each is a statement object in `.sinter/` on an ordinary branch. A
  statement reaches the default branch in the pull request that brings
  it, so its review is the review of that pull request.
- Only the job, which runs reviewed code after a push to the default
  branch, writes outside the tree. It writes one dedicated branch, the
  log branch, and that branch only grows. The log branch holds
  observations (`delivered` and `progress`) and kept objects: a copy of
  every merged revision of every declared item, and of each computed
  identity object that such a kept object needs. Each line of the log
  branch wraps its object in the plain envelope `{"id","object"}`, and
  each kept object is written once for each content id, with no order
  number and no writer.
- Every check before a merge only reads. Checks read the log branch from
  its remote-tracking ref and use git's reflog of that ref, so that a
  check can see that the log branch went back to an earlier tip.
- States follow from edges. Each record names by content id the records
  that it rests on, so the records form a Merkle graph. Two
  records conflict only when they disagree about the same thing. No
  state depends on the order of records or on a number in them.
- Each run of the job covers a range of commits and ends it with a
  `progress` observation. A counting void in the tree withdraws a
  record, and the job's bookkeeping reads it: a withdrawn `progress`
  observation marks no range, and a withdrawn `delivered` observation
  records no delivery. Among the unwithdrawn `progress` observations,
  the next range starts after the one whose commit reaches the commits
  of all the others, so a run that retries late never moves the range
  back to an earlier commit.
- Nothing rewrites the log. A wrong record is withdrawn by a void.
- When the log branch is missing, a check reports that the job's records
  are missing and gives every result that depends only on the tree. A
  computed identity object that the log branch lacks holds back only the
  results that need it, with a report.

## Alternatives considered

- **Keep the ledger under a ref of its own, such as
  `refs/sinter/ledger`.** Not chosen: no host protects such a ref, and a
  plain clone does not fetch it.
- **Approval as a standing judgment in a shared log that persons
  write.** Put forward and not chosen, in favor of approval that travels
  in the pull request that brings it; no further reason was recorded.
- **Checks of branches in the same repository write a ref for each
  branch.** Not chosen: forks need the read-only mechanism anyway, and
  the write gives code that nobody reviewed a token for refs that no host
  protects.
- **Required signatures on the log.** Not chosen: they guard against
  forgery, which v0.1 does not defend against, and cannot show that a
  branch went back to an earlier tip. Signed judgments are on the
  roadmap.
- **The job records one merged order, and states fold over it.** Put
  forward and not chosen; no reason beyond the choice of edges was
  recorded.
- **Every pair of latest records is a conflict.** Put forward and not
  chosen; no reason was recorded.
- **Copies on the log branch carry an order number and a writer, or the
  job appends every declared item at every merge.** Not chosen: no state
  or check reads a number or a writer on a copy, a retry would renumber
  the copies, and appending at every merge breaks the rule of one line
  for each content id and grows the log branch with every merge.
- **A void reaches only states, not the job's bookkeeping.** Not chosen:
  then nothing can make the job observe again.
- **Checks keep the last tip that they saw in a file of `.sinter/local/`
  or in a ref of Sinter's own.** Not chosen: a check would write, a
  fetch between two checks would lose the tip, and a ref of Sinter's own
  writes into git's folder.
- **A missing identity object makes the log branch not valid.** Not
  chosen: one absent object would hold back every result that depends on
  observations, although the program knows which results the absent
  object affects.
- **Call all of Sinter event sourced.** Not chosen: the main input, the
  tree, is a snapshot, not a log.

## Consequences

Open pull requests cannot see each other's statements until they merge,
and a withdrawn record stays in git's history. A fresh clone cannot see
that an unprotected log branch went back to an earlier tip, and an entry
of git's reflog that expires no longer counts. The log branch does not
record which run of the job first kept an item. Before the first run of
the job, every check reports that the job's records are missing, and the
results that depend on observations wait for that run. Two clones with
the same tree and the same log branch give the same states, whatever
else their histories hold.
