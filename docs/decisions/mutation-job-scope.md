<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Measure a pull request on the lines it changed, a dependency move whole, and main whole
@decision mutation-job-scope v7
@cites gh/158
@cites ci-main-runs
@cites mutation-testing
@cites mutation-gate
A pull request measures the mutants on the lines that it changed, a pull request that changes a dependency measures the full set, and `main` is measured whole each day; the `mutation` job never holds a merge; the job runs as parts whose number follows the count of mutants, and in the job each mutant runs only the test groups that can reach its code, under two random seeds, while a canary checks that selection.

## Context

The record `mutation-testing` said that every pull request runs the
full set of mutants "while a pass takes a few minutes". By
2026-09-17 the set held 380 mutants, each run under three seeds, and
the job took about seven and a half minutes on a pull request. Six
minutes of that was the mutant run itself, and the number grows with
every mutant. The maintainer found the wait too long for each pull
request. The fork of `mutaml` already had the option that tests only
the mutants on changed lines, `--changed-since`, built for this use.
On 2026-10-26 the move to OCaml 5.5.2 changed no line under `lib/` or
`bin/`, so its pull request ran no mutant, and nothing showed that the
mutation build worked on the new compiler.

On 2026-11-01 the full set held 4,726 mutants. Its pass on `main`
stopped at the time limit of a GitHub job, six hours, after 4,041
mutants. Until 2026-11-01 a benchmark test failed under every mutant
(issue gh/158), so each mutant stopped at that first failure, and the
pass looked short. With that test fixed, a mutant that survives runs
the whole suite once for each seed. The job then ran as four parts:
four GitHub jobs at the same time, each with a share of the mutants.

On 2026-11-16 the stacked pull requests of the project's redesign held
about 8,350 mutants, and each mutant ran the whole suite of about 2,800
tests. A full pass needed about 37 hours of GitHub runner time, more than four
parts of six hours can give: the mutation job of pull request #233
stopped at the six-hour limit. The daily run on `main` would stop in
the same way once those pull requests merge. Most tests cannot reach
the code of a given mutant, so most of that time ran tests that could
not kill the mutant.

## Decision

- On a pull request, the `mutation` job runs the mutants that sit on
  a line the pull request changed since its base, with two seeds and
  the same gate as the full set. Every other mutant stays outside the
  score.
- A pull request that changes a dependency runs the full set. A
  dependency can change the behavior of lines that the pull request
  did not change. The dependencies are these files:
  - the lock file and the package files of the OCaml build;
  - the CI workflow, which pins the compiler and the mutation tool;
  - the crate files and the toolchain file of the bridge;
  - the embedded grammar;
  - every script of the mutation job: `test/run-mutants.sh`,
    `test/mutant-shares.sh`, `test/run-mutant-share.sh`,
    `test/join-mutant-reports.sh`, `test/mutant-groups.sh`,
    `test/mutant-count.sh`, and `test/mutant-canary.sh`.
- A pull request that changed no dependency and no file under `lib/`
  or `bin/` runs no mutant. The job ends at once and passes.
- The full set runs once a day on `main`, in the scheduled run of the
  workflow, so that `main` is measured whole each day. A push to
  `main` runs no mutant (record `ci-main-runs`).
- No GitHub job of the `mutation` job is a required check, so the job
  never holds a merge. A failure stays red on the pull request, with
  the survivors in the summary of the job "Report the mutation
  score", for the author and the reviewer to read.
- Before opening a pull request that touches `lib/` or `bin/`, the
  author runs the pass on the branch with `--changed-since` and reads
  every survivor. `docs/contributing/mutation-testing.md` gives the
  command.
- Three statements of `mutation-testing` no longer apply: that every
  pull request runs the full set, that each mutant runs under three
  seeds, and that `mutaml-runner` passes fixed seeds. The rest of that
  record stands, and the gate of `mutation-gate` applies to whichever
  set ran.
- The number of parts follows the count of mutants that the run
  tests, so that each part has about 3 hours of work, half of the time
  limit of a GitHub job. The workflow names the largest number of
  mutants for one part, and the number of parts is the count divided
  by that number, rounded up. Today that number is 2,500. It comes from a run on the
  tree of pull request #207, on GitHub runners, with the selection
  of tests below and two seeds: 6,179 mutants in three parts of about
  2,060 mutants took 2 h 30 min, 1 h 52 min, and 1 h 16 min. The
  slowest part, scaled from 2,060 to 2,500 mutants, takes about 3 hours.
- In the `mutation` job, each mutant runs only the **test groups**
  whose code can call into the source file of the mutant. A test group
  is one entry of the list of groups of the test suite. The groups come
  from the **map of imports**: the interfaces that each compiled module
  of the build imports. The selection cuts the runner time of a full
  pass, so that a few parts suffice. A pass on a machine still runs
  every test for each mutant.
- The run stops when the list of test groups in the source of the
  suite differs from the list that the suite prints, or when a test
  starts a program that the selection does not know. Such an error
  then never makes a mutant survive or die falsely in silence. The map
  cannot see a call that goes through no import. The canary looks for
  such a call, and for a mutant that the selected groups kill but the
  whole suite does not.
- The **canary** compares the selection with the whole suite. On the
  daily run, and on a pull request that changes a script of the
  mutation job, each part tests 5 drawn mutants twice: once under every
  test, and once under the selected groups. The canary fails when the
  two results differ for a mutant. The number 5 comes from the ruling
  of 2026-11-16 on the selection.
- Each mutant runs under two seeds of the property tests, not three.
  Each part draws a random number, makes its two seeds from that
  number, and prints them, so that a survivor can run again under the
  same seeds.

## Alternatives considered

- **Split the full set over several jobs, with three seeds** — chosen
  in part. The split is kept, with two seeds in place of three, so
  that each part has more time to spare.
- **Run each mutant under one seed** — not chosen. One seed would save
  the most time, but a property test can miss under one seed a change
  that another seed finds. Two seeds keep the second chance.
- **Run the full set once a night on a runner of the project's own,
  with a longer time limit** — not chosen. It needs a machine to set
  up and keep.
- **Run the full set only when the OCaml toolchain or its packages
  change** — not chosen. The move to tree-sitter 0.26 changed the
  bridge's crates and changed parse results across Sinter; such a
  move needs the full set as much as a move of the OCaml toolchain.
- **Run the full set once a day against `main`, and not on pull
  requests** — the maintainer's first proposal. Not chosen alone. The
  check would then run after a merge and not before it, a pull
  request that lowers the score would merge unseen, and the failure
  would appear the next day with no author attached. The daily run is
  kept, as the measurement of `main` whole.
- **Keep the full set on every pull request, but stop waiting for
  it** — chosen in part: the job never holds a merge. The full set on
  every pull request is not chosen. Most pull requests change few
  lines, and a full set on each one costs hours of GitHub runner time
  and a long wait.
- **Split the mutants in the runner, with an option `--shard K/N` in
  the fork of `mutaml`** — deferred (sinterworks/mutaml
  issue 10). It balances the parts better and runs the tests without
  a mutant once for each part, not once for each file. With the
  selection, each file has its own test command, so a shard must keep
  one command for each file. The split in the workflow comes first
  because it needs no change to the fork.
- **Choose the tests of each mutant from a trace of the code that each
  test group runs** — deferred. A trace is finer than the map of
  imports, and it can see calls that go through no import. It needs a
  traced run of the suite and a store of its result. It comes only if
  the canary finds calls that the map misses, or if the map selects
  too many tests.
- **Size the parts by the count of mutants times the time of their
  selected tests** — deferred. It balances the parts better, because
  the measured parts took from 1 h 16 min to 2 h 30 min with about the
  same count. The count alone comes first because it needs no measured
  time.

## Consequences

A pull request that only adds, changes, or removes tests runs no
mutant, so a test removed there can leave a survivor that the next
daily run on `main` reports. A survivor found on `main` is then a fix
to make, with no pull request to attach it to. The gate is harsher on a
small set than on the whole: one survivor in a run of few mutants
lowers the score a lot. The author should still see that survivor.
GitHub sends the notice of a failed scheduled run to the person who
last changed the workflow file. GitHub also stops a schedule after
sixty days without a commit to the repository.

The seeds change from run to run, so the score can move between two
runs of the same tree: a mutant that only some seeds kill survives in
one run and not in another. Such a mutant is a gap in the tests, and
the printed seeds let an author run it again. The parts use several
GitHub runners at the same time. Each part runs the selected tests
twice without a mutant for each of its source files, which costs time
that the option `--shard` of the fork would save.

A mutant behind a call that the map of imports cannot see can survive
falsely. The canary draws only 5 mutants in each part, so it finds
such a call by chance and over many daily runs, not at once. Today two
test groups, `mode` and `cases`, reach every file, because the map
cannot read their entries, so every selection pays their time.
