<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Write a fixture ledger as the exact lines of its entries
@decision fixture-ledger
@cites ledger-layout
A fixture ledger is a file `ledger.jsonl` in the folder of a case, and each line is the exact canonical line of one entry, with its `id`, in `seq` order.

## Context

`spec/jsonl.md` section 11 names a fixture ledger and gave no form. A
real ledger lives in a git ref, which a case folder cannot easily
hold. The tests of this repository and the fixtures of the packs
repository need one form.

## Decision

- A case with no such file has no ledger.
- The harness builds the ref from the file, in one commit with fixed
  dates, and it accepts the file only in a case with a repository.
- A helper in `test/` computes the `id` of a line.

## Alternatives considered

- **Lines without `id` and `seq`, which the harness fills in.** Not
  chosen: it makes a second form of an entry, and it cannot express a
  ledger with a wrong `id`.
- **Keep the name reserved, and use only OCaml builders.** Not chosen:
  the new classes get no case folders, and the question comes back at
  the packs step that adds fixtures.

## Consequences

A fixture goes through the real checks of the reader. A person cannot
easily write a line by hand, and a change of the entry format means
that the files are generated again.
