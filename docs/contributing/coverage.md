<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Coverage

Install `bisect_ppx` as the section "Coverage" of `CONTRIBUTING.md`
says. Then, from the repository root:

```
QCHECK_SEED=1 dune build @runtest --force --instrument-with bisect_ppx
bisect-ppx-report summary --per-file
```

`--instrument-with` is the switch. Without it, the build carries no
instrumentation and costs nothing. `bisect-ppx-report` reads the
counts under `_build`, so it needs no path. For a page per file, run
`bisect-ppx-report html -o _build/coverage` and open
`_build/coverage/index.html`. Write the pages under `_build`, which
git already ignores.

`QCHECK_SEED` fixes the seed of the property tests. Without it, the
properties draw a new seed on each run, and the total moves between
runs of the same tree. The `coverage` job sets the same seed, 1, so
that its total changes only when the tree changes.

An instrumented build writes over `_build`. The next ordinary
`dune build` compiles the whole OCaml tree again. It does not build
the Rust crate again: cargo builds outside `_build`, so it finds its
work done.
