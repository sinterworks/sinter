<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Read git repositories with Sinter's own readers
@decision git-format-readers
The libraries that implement the design Changes read the files of a git repository with Sinter's own OCaml code and inflate zlib data with `decompress`; they run no git program and link no git library.

## Context

The design Changes (`docs/designs/changes.md`) cites git's manual pages
for the formats of a repository: its objects, loose or in packs, with
SHA-1 or SHA-256 ids; its refs, in the files format or in reftable; its
configuration; git's index; and the ignore rules. It specifies Sinter's
own results on them, and a program may read the files in any way that
meets the design's requirements. Four of these requirements are about
the reads: `run-no-configured-programs`, `avoid-working-tree-waits`,
`keep-repositories-unchanged`, and `follow-no-working-tree-links`.

Runs of git 2.54 on test repositories, in November 2026: git waited
without end on a named pipe in the place of an included configuration
file or of an ignore file (against `avoid-working-tree-waits`), and it
changed a repository whose index was split (against
`keep-repositories-unchanged`).

## Decision

- Sinter's own OCaml libraries read git's objects, packs and their
  indexes, refs, configuration, git's index, and the ignore rules.
- `decompress` (MIT, in OCaml), with its dependencies `checkseum` (MIT)
  and `optint` (ISC), inflates zlib data. Only the library that reads
  objects depends on them.

## Alternatives considered

- **Run the git program**, as today's `lib/git.ml` does. Not chosen: it
  breaks `avoid-working-tree-waits` and `keep-repositories-unchanged`,
  and `run-no-configured-programs` would rest on a list of settings and
  environment variables to turn off, while a new release of git can add
  a setting that runs a program.
- **A git library.** Not chosen, for these reasons:
  - libgit2 is under the GPL with a linking exception, which the record
    `licensing` does not allow. It has no OCaml binding on opam, it
    calls its SHA-256 support experimental, and its reftable code is
    only in a release candidate.
  - ocaml-git depends on `ocamlgraph`, which is under LGPL-2.1-only with
    no linking exception, and `licensing` allows LGPL only for the OCaml
    runtime. It mentions neither SHA-256 nor reftable.
  - gitoxide is in Rust, does not read reftable, and would need a second
    Rust crate beside the Rust parser bridge.
  - Each library would also leave the hunks, the walk of the working
    tree, the upstream rules, and the merge-base rule to Sinter.
- **For inflation, the `zlib` binding, or an inflater of Sinter's own.**
  Not chosen: the binding needs the system zlib, and an own inflater is
  about 400 lines with a risk of its own.

## Consequences

These libraries are Sinter's code to keep, about 4,000 lines of `lib/`
in November 2026. Each rule of a reader rests on a manual page or on a
run of git on a test repository, never on git's source code, and a rule
that a run does not confirm is corrected. A new git format needs new
reader code. `decompress` 1.6.1 raises `Invalid_argument` on some
damaged streams: the reader catches it and reports the stream as
damaged, and Sinter's tests fuzz the inflater. The tests still make
their repositories with the git program. The record `git-versions`
covers only the code that runs the git program.
