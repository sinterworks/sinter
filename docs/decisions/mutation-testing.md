<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Measure the tests with mutation testing, through a fork of mutaml
@decision mutation-testing v3
@cites test-rigor
@cites gh/25
@cites gh/27
Sinter runs mutation testing over `lib/` and `bin/` with a fork of `mutaml` that the project maintains; the CI job fails below a minimum score; timeouts count as killed; an equivalent mutant is marked in the source with a reason.

## Context

Coverage reports which lines the tests ran. It cannot tell a test
that checks a result from a test that only runs code, so a coverage
number rises with tests that check nothing. Mutation testing measures
the tests: a tool makes one small change to the source, a mutant, and
runs the suite against it. A mutant that a test fails on is killed. A
mutant that no test fails on survives, and it shows a behavior that no
test checks. The mutation score is the percentage of the tested
mutants that the tests kill. The first run over Sinter's code found 23
such gaps behind a coverage number of 91 percent.

OCaml has one mutation testing tool, `mutaml`. Its release does not
build on the compiler Sinter uses, it loses its working files under
current dune, its set of mutations omits the comparison operators, and
its upstream is quiet. Eleven tools in other languages were surveyed
for the choices below.

## Decision

- Sinter maintains a fork of `mutaml` at `sinterworks/mutaml`. The fork
  keeps upstream's layout, names, and test style, so that a change can
  go upstream. Changes that upstream would take are offered there.
- A mutant that makes the suite exceed its time limit counts as
  killed. The limit derives from the unmutated baseline run, with a
  floor.
- An equivalent mutant, one that no input could distinguish from the
  original, is marked in the source on the expression, with a reason
  that the report prints. The marked mutant is not generated. No list
  of mutants lives outside the source.
- The runner, the program `mutaml-runner` of the fork, passes seeds to
  the property tests, more than one for each mutant, and a mutant is
  killed when any seed kills it. The baseline runs twice with different
  seeds, and a disagreement stops the run.
- The gate is a minimum score in the CI job, and a score equal to the
  minimum passes. The record `mutation-gate` sets the minimum.
- The record `mutation-job-scope` decides which mutants each run tests,
  how many seeds each mutant runs under, and how each run draws the
  seeds.
- A mutant is named by its file, its enclosing top-level binding, the
  kind of mutation, the original and replacement text, and an ordinal
  among identical mutants in that binding, so that the name survives
  moved and reformatted code.
- The report writes the JSON format that Stryker, Infection, and Mull
  share.
- The mutations on by default preserve the type of the expression they
  change: comparisons, equality, boolean connectives, `not`, arithmetic,
  literals, and `Some` to `None`. Forcing a condition to a constant and
  changing string literals are off by default.

## Alternatives considered

- **A mutation testing tool of the project's own** — rejected. Days of
  work and a tool to maintain, while a working tool exists.
- **Wait for upstream to support the compiler** — rejected. The last
  upstream change was in September 2025, and upstream gives no date for
  support of the compiler.
- **A timeout counted as a survivor, or as its own outcome outside the
  score** — not chosen. One surveyed tool counts it as a survivor and
  one keeps it apart; nearly all count it as killed, because the tests
  noticed the change in the only way a hang can be noticed.
- **A list file of equivalent mutants** — rejected. After any edit that
  changes a mutant's name, the list silently excuses the wrong
  mutants. The marker in the source stays with the code.
- **No seed, or one seed** — not chosen. No surveyed tool seeds its
  tests. All of them assume a deterministic suite. Sinter's property
  tests draw random inputs from a seed. With no seed, each property test
  draws a seed of its own, which the runner cannot repeat. One seed lost
  two kills in the first run.
- **Mutants named by position** — rejected. Most surveyed tools do
  this, and the name breaks when an unrelated line moves, which breaks
  the gate's comparison and the markers with it.

## Consequences

The project maintains a fork, with the cost of keeping it alive until
upstream takes its changes or forever. For a pull request that adds
untested behavior, the CI job names each mutant that survives.
Some survivors need a person's judgment, and each judgment is recorded
in the source as a marker with its reason.
