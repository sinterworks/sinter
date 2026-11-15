<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Write each scope once in the hash text of a commitment set
@decision commitment-set-form
@cites ledger-event-log
The canonical bytes of a commitment-set hash group the promises by their scope and write each scope once, and the hash has no limit on the length of those bytes.

## Context

The canonical bytes repeated the whole scope of a step in each of its
promises, so their length grew with promises times globs. One ledger
line of 552 KB cost `sinter ledger log` 21.5 s and 8.1 GB. A limit of
1 MiB on the bytes stopped that cost for a ledger entry, but not for a
plan file: a plan file of about 190 KB cost 2.4 s on each scan. The
form can change at no cost only until the first approval exists.

## Decision

- The canonical object has two keys. `groups` holds one object for
  each distinct effective scope that holds a promise, with `promises`
  and `scope`. `scope` holds the plan's globs.
- The new form tells apart exactly the sets that the old form told
  apart.
- The limit of 1 MiB and the count of the length before the build are
  removed, because the length of the bytes now follows the length of
  the line.

## Alternatives considered

- **A table of scopes, and an index in each promise.** Not chosen: a
  reader must follow an index, and the canonical order is harder to
  state.
- **The SHA-256 of the scope in each promise.** Not chosen: it adds 64
  bytes to each promise and a second layer of hashes.
- **Keep the form.** Not chosen: the limit stays the only guard, a
  plan file still costs 2.4 s, and an approval of a large plan cannot
  count.
- **Change the form and keep the limit.** Not chosen: the limit then
  stops only a plan about 470 times the size of Sinter's largest, it
  protects little memory, and the approval command needs its own error
  for it.

## Consequences

The change lands before "Record approvals, declines, and closings".
After that step, a change of the form would stop every approval from
matching. A later form that grows faster than its line needs a new
guard.
