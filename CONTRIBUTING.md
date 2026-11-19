# Contributing to Sinter

## Writing

All text in this repository follows the rules below. They take
Simplified Technical English (ASD-STE100), in the style of Simple
English Wikipedia, as their model. They set no limit on the number of
words in a sentence. The rules apply to documentation,
specifications, code comments, commit messages, pull requests, and the
tool's own output. The rules:

- Write for the people who use Sinter or contribute to it. Assume
  they do not share your context.
- Give each sentence one idea: one fact, one rule, or one
  instruction, with the conditions that belong to it.
- Let a sentence be as long as its idea needs. Do not cut words that
  the idea needs.
- Split a sentence that holds two ideas.
- When one sentence cannot hold an idea clearly, divide the idea into
  parts that each make sense alone, such as a rule and then each of its
  conditions. Give each part its own sentence.
- Use the active voice and simple tenses.
- Use one term for one meaning, and use it the same way every time. A
  term is a word or a fixed phrase, such as "boundary rule" or "git's
  index". When a word has more than one meaning in the project, give
  each meaning a fixed phrase, and do not use a synonym in its place.
- Do not invent terms. When a technical term is necessary, define it
  at first use.
- Give every pronoun one clear referent. Repeat the noun when in
  doubt.
- Give the context before the detail, so that each sentence makes
  sense on its own.
- Use a numbered list for a sequence of steps.
- Use a table for facts that a reader can enumerate.
- Do not add notes that explain why a sentence or a file exists, or
  that restate what a reader can infer from the stated facts.
- Do not open a document with prose that explains what the document
  is, what it is not, or how a reader will use it. Start with the
  content.
- Do not narrate the process that produced a document or a change.
  Say what the thing is, not how it came to be.
- A list document — a roadmap, a checklist — is a flat list of items
  with brief names and their subtasks beneath them. Do not group the
  items under relative time headings.

We reproduce some text from elsewhere: license texts, the DCO, and
quoted standards. That text stays exactly as it is in the source.

### Code comments

A comment is permitted only in these cases
(`docs/decisions/code-comments.md`):

- Sinter reads it: a tag block, with the prose that follows the tags
  as their description. A choice that rests on a decision record cites
  it with a tag line: `(* @cites <slug> *)` in OCaml, `// @cites <slug>`
  in Rust, `/* @cites <slug> */` in C, `# @cites <slug>` in shell,
  YAML, and TOML.
- The community of the language expects it: the API comment on an
  exported value (`(** *)` in an `.mli` file, `///` and `//!` in Rust,
  with the `# Safety` section of an `unsafe` function, a comment on a
  declaration in a C header), and the license header of a file.

A permitted comment states what the code takes, what it gives, what
it guarantees, who owns the result, when the result stops being
valid, and what can go wrong. It never states why the code is as it
is, what it replaced, or what else was possible. Reasons go in
decision records, in the specifications, and in commit messages. The
reason of a `[@mutaml.skip "reason"]` attribute is written in the
same form.

The rule applies to every file of code: OCaml, Rust, C, shell, the CI
workflows, the build files, the TOML files, and the tests. Write no
other comment.

### Messages that the tool prints

An error message or a help text addresses the person who runs the
tool. It says what is wrong and, when useful, what to do. It never
names a repository file or a document section, and it never explains
the tool's internal reasons.

## Code

Sinter's code holds to the standard of a library that other OCaml
projects depend on. The rules:

- Every module has an `.mli` file. The interface exports the smallest
  set of types and functions that its callers need. A type whose
  values a caller must not build by hand is abstract.
- Every exported value has an API comment, as the "Code comments"
  section describes.
- A function's type says what can go wrong. A failure that a caller
  handles is a value of a `result` type with a variant error type. An
  exception is for a failure that ends the whole operation. The `.mli`
  declares every exception a function raises and the condition that
  raises it.
- A function is total over its declared input type. When the type
  admits inputs the function cannot handle, the function returns an
  error value, or the `.mli` states the precondition and the function
  checks it and raises `Invalid_argument`. Do not use `assert false`,
  `Obj.magic`, `Option.get`, `List.hd`, or `failwith` on data that
  came from outside the module.
- State is local. A module holds no global mutable state. A resource
  such as an engine, a channel, or a temporary file has a type, an
  owner, and a lifetime rule in the `.mli`. Code releases a resource on
  every path, the error paths included; use `Fun.protect`.
- Data from outside the process (a file, standard input, the bridge's
  buffer, a wasm module) is decoded and validated in one module. The
  rest of the code sees typed values.
- Each module does one thing and depends only on the modules below it.
  The core library does not read the command line, the terminal, or
  the process environment; the executable in `bin/` does.
- The build is clean under dune's development profile, which turns
  warnings into errors. Do not silence a warning with a flag or an
  attribute; change the code.
- Prefer the standard library. Add a dependency only when the code it
  replaces would be larger than a module of our own, and record the
  choice in a decision record.
- Keep each dependency at its newest release. When a crate, a
  toolchain, an OCaml package, a tool pin, an action, or a grammar has
  a new release, move to it as soon as the build and the checks pass
  with it (`docs/decisions/current-dependencies.md`).

## Tests

- Every function that an `.mli` exports has a test. The test calls
  the function through the interface.
- Every property that a specification or an `.mli` states about an
  output is a property-based test: the test generates inputs with
  `qcheck` and checks the property for each input. A round trip, an
  ordering, an invariant, and a bound are properties.
- Every decoder of data from outside the process has a property test
  that feeds it generated and corrupted inputs. The decoder returns a
  value or an error for every input, and never crashes.
- Every exit code and every error message of a command has a test
  through the built binary.
- A bug fix comes with the test that failed before the fix.
- A test states one fact, and its name says which.
- CI measures coverage with `bisect_ppx`. A change does not lower the
  number.

## Build and check

Install [opam](https://opam.ocaml.org/), and create a switch with the
compiler that `sinter.opam.locked` pins, 5.5.2, for example with
`opam switch create 5.5.2`. The install below fails on any other
compiler. The parser bridge in `bridge/` is a Rust crate, so also
install the Rust toolchain with [rustup](https://rustup.rs) and
install `cmake`, which a build script of wasmtime runs. Then, from the
repository root:

```
eval $(opam env --switch=5.5.2)
opam install . --deps-only --with-test --with-dev-setup --locked
dune build
dune test
dune fmt
```

The `--with-dev-setup` flag installs `ocamlformat`, and `--locked`
installs the versions in `sinter.opam.locked`, the same versions CI
uses. When you change the dependencies in `dune-project`, run
`dune build` and then `opam lock ./sinter.opam`, and commit both
`sinter.opam` and `sinter.opam.locked`.

Before you commit, check that all of these pass:

- `dune build`, `dune test`, and `dune build @fmt`. `dune fmt`
  rewrites files in place; commit the files it changes.
- `reuse lint`. Install the tool once, for example with
  `pipx install reuse`.
- In `bridge/`: `cargo fmt --check` and
  `cargo clippy --all-targets -- -D warnings`.

CI runs all of them.

### The bridge's build directory

The dune rule that builds the bridge runs cargo outside `_build`, in a
directory of its own for each checkout, so that two checkouts never
link each other's library. The directory sits under the first of
these that is set: `CARGO_TARGET_DIR`; `$XDG_CACHE_HOME/sinter-bridge-build`;
`~/.cache/sinter-bridge-build`. Its name is a hash of the checkout's
path, and a file named `checkout` inside it holds that path. Each one
is about 500 MB. `dune clean` does not remove them, so a machine with
many worktrees collects them. This loop removes every directory whose
checkout is gone:

```
for d in "${XDG_CACHE_HOME:-$HOME/.cache}"/sinter-bridge-build/*/; do
  p=$(cat "$d/checkout" 2>/dev/null) || continue
  [ -d "$p" ] || rm -rf "$d"
done
```

A directory with no `checkout` file predates the file; remove it by
hand, and the next build writes a new one.

### Coverage

`bisect_ppx` measures how much of `lib/` and `bin/` the tests run. No
released version of it installs beside the versions in
`sinter.opam.locked`. The last release, 2.8.3, needs `ppxlib` below
0.36 and `cmdliner` below 2. The lock file pins the compiler 5.5.2,
which no `ppxlib` below 0.36 supports, and it pins `cmdliner` 2.1.1.
An open pull request of `bisect_ppx` builds against the newer
`ppxlib` and the newer `cmdliner`, so a coverage run pins one commit
of it. Pin it into the project's switch once:

```
opam pin add -y -n bisect_ppx \
  git+https://github.com/aantron/bisect_ppx.git#7061d643ff492b0045796357ee6917ded21fb1f0
opam install bisect_ppx
```

The pin names a commit and never a branch, so that every run installs
the same code. The install adds five packages: `bisect_ppx`, `ppxlib`,
and three packages that `ppxlib` needs. It changes no version that the
lock file pins. Remove the pin with `opam pin remove bisect_ppx` when
`bisect_ppx` makes a release that installs beside the lock file.
Install that release instead, and take the pin out of this section and
out of the `coverage` job. That job pins the same commit, for the same
reason.

`docs/contributing/coverage.md` says how to measure the coverage on your
machine. CI measures it with the same commands on `ubuntu-26.04` and
fails below the minimum that the `coverage` job sets. That job holds the
number. A change does not lower the coverage.

### Mutation testing

Coverage counts the lines that the tests run. It cannot see whether a
test checks what it runs. Mutation testing measures that. A tool makes
one small change to the source, such as `<=` where the code says `<`,
and runs the suite with that change switched on. The changed program
is a **mutant**. A mutant that makes a test fail is **killed**. A
mutant that the whole suite passes on **survives**, and it names a
behaviour that no test checks. A mutant that makes the suite run past
its time limit counts as killed. The **mutation score** is the
percentage of the mutants that were killed.

Sinter measures `lib/` and `bin/` with the project's fork of `mutaml`;
`docs/decisions/mutation-testing.md` gives the reasons for the fork.
The fork needs no other command, except `git` for the option
`--changed-since`. Pin it into the project's switch once:

```
opam pin add -y -n mutaml \
  git+https://github.com/sinterworks/mutaml.git#b41eaafd112350ec4d0e2ee9f2336eb37e7b8fd7
opam install mutaml
```

The pin names a commit and never a branch, as the pin of `bisect_ppx`
does, and the CI workflow pins the same commit. The pin is not in
`dune-project` or in the lock file, because the tool is not a
dependency of the package. The install changes no version that the
lock file pins. A move of the pin is a pull request of its own that
names the new commit.

`docs/contributing/mutation-testing.md` says how to run a pass on the
whole tree or on a branch, what each command and option does, how the
`mutation` job splits a pass into parts, how to test a survivor again
under the seeds of a run, and the rules for running a pass.

Two rules keep the suite and the measured code fit for a pass:

1. Keep the suite safe to run in parallel, or set `-j` to 1. Three
   facts make it safe: the test command is a script and not `dune`,
   which locks the build folder; every file that the suite writes has
   a name from `Filename.temp_file`, under the worker's own `TMPDIR`,
   which the runner removes at the end of the pass; and neither `lib/`
   nor `bin/` keeps a cache on disk. A cache added later must write
   whole files, by writing a temporary file and renaming it, or live
   under `TMPDIR`.
2. Keep a value that only a release build can set out of the measured
   code. A branch of the code that only a release build takes is a
   branch that no test can reach. Read such a value in `bin/` and pass
   it to a function of the library, as `bin/main.ml` passes the package
   version and the output of `git describe` to
   `Sinter_core.Version.render`, and test that function with each
   value.

**The gate.** `mutaml-report` exits 0 when the score is at or above
`--fail-under`, 2 when it is below, and 1 when the tool could not do its
work. Give it the number that the job "Report the mutation score" holds
in `MUTATION_MINIMUM`, so that a pass on your own machine answers as the
job does. The five jobs of the mutation pass are not required checks:
they never hold a merge, and a failure stays red on the pull request for
the author and the reviewer to read. The number is fixed at 95 by a
ruling of the maintainer (`docs/decisions/mutation-gate.md`). It does
not rise when the score rises, it does not fall, and it changes only on
another ruling of the maintainer.

95 is the gate and not the target. **The score to aim for is 100.** The
job "Report the mutation score" prints the score of every run in its
summary and names every mutant that survived. The gap between 95 and 100
is there so that one mutant that nobody has got to yet does not stop a
pull request that is sound in every other way; it is not room to leave
survivors in.

**Read every survivor.** Read the survivors that a report names on
every run, green or not: a run above the gate can still hold a
survivor, and nothing else draws a reader to it. Read a survivor as a
question: which test would have failed on this change? That test is
the answer. A few survivors have no answer, because no input can tell
the change from the original. Those are **equivalent mutants**, and
the next paragraph says how to mark one.

**How to mark a mutant that no test can kill.** Write
`[@mutaml.skip "reason"]` on the smallest expression that holds the
mutant, and put that expression in parentheses:

```
let is_ready count = ((count >= 1) [@mutaml.skip "..."])
```

The attribute binds to the expression right in front of it, and it
binds tighter than an operator, so `count >= 1 [@mutaml.skip "..."]`
marks the `1` alone and leaves the comparison to be mutated. A mark
takes out every mutant inside the expression it names, the mutants
that the tests kill among them, so name no larger an expression than
the place needs. The reason is a string, and it is not optional: a
mark with no reason, with an empty reason, or with a payload that is
not a string stops the build with a message that names the file and
the line. A marked place is no mutant: it is outside the score, and
every report names it, its line, and its reason. The JSON report
gives it the status `Ignored` and the reason in `statusReason`.

A mark is a claim: that no input can tell the changed program from
the original. A mark that is wrong hides a gap in the tests for as
long as it stands, and no later pass will find that gap again. So
write the reason as a reader can check it against the code, name the
property that makes the two programs one, and read a mark in review
as closely as you read the code around it. Never mark a gap. When a
test could kill the mutant, that test is the answer, and the mark is
a way of not writing it.

### Performance

The benchmark measures the peak memory, the words that each phase
allocates, and the instruction count of `sinter scan` and
`sinter check`. It runs each command on Sinter's own checkout and on
generated trees: git repositories of a given number of declarations,
made from a fixed seed. The same seed and the same number give the
same tree on every run. It also measures `sinter ledger log` and
`sinter ledger verify` on generated ledgers of 10, 1,000, and 100,000
entries, with one commit for each entry. From the repository root:

```
dune build @bench
dune build @bench-large
```

`docs/contributing/performance.md` says what the run measures, which
phases each command has, how to compare two builds, and how the CI job
finds its baseline. The words of a phase are the words of memory that
the OCaml runtime allocates in that phase.

`bench/budgets.toml` holds one budget for each command, the growth
limit (`docs/decisions/performance-budgets.md`). The growth of a phase
is the words on the tree of 10,000 declarations, divided by the words
on the tree of 1,000 declarations. For the commands of the ledger, it
is the words on the ledger of 100,000 entries, divided by the words on
the ledger of 1,000 entries. A step whose cost grows faster than
the tree raises the growth of its phase. The limit applies to each
phase, on every platform. A command can give one phase a limit of its
own, under `phases`: the findings phase of `sinter check` has the limit
16. A name under `phases` that is not a phase of the command stops the
run. No budget applies to the peak memory.

The CI job "Measure performance" makes the same measures as `@bench`
on `ubuntu-26.04`. It fails only when the growth of a phase exceeds
its limit. The job is not a required check. A growth limit changes
only in the pull request that needs the change, so that the reviewer
sees it.

## New files

A new file under `lib/`, `bin/`, `bridge/`, `test/`, `spec/`,
`docs/`, or `.github/` needs an SPDX header with the license of its
directory, and the line `Copyright <year> The Sinter Authors`:

<!-- REUSE-IgnoreStart -->
- OCaml: `(* SPDX-License-Identifier: Apache-2.0 *)`
- Rust: `// SPDX-License-Identifier: Apache-2.0`
- C: `/* SPDX-License-Identifier: Apache-2.0 */`
- dune files: `; SPDX-License-Identifier: Apache-2.0`
- YAML, TOML, and shell: `# SPDX-License-Identifier: Apache-2.0`
- Markdown in `spec/` and `docs/`:
  `<!-- SPDX-License-Identifier: CC-BY-4.0 -->`
<!-- REUSE-IgnoreEnd -->

Four kinds of file carry no header, and `REUSE.toml` gives each the
license of its directory: files at the repository root; files whose
format has no comment, such as JSON; files that a tool generates,
such as `bridge/Cargo.lock` and `sinter.opam`; and the plan files
under `.plans/` and the skill files under `plugins/`. Keep the two
ignore markers around the list above. The markers
stop the `reuse` tool from reading the examples as license tags for
this file.

## Commits

- Sign off every commit with `git commit -s`. The line certifies
  that your contribution satisfies the Developer Certificate of
  Origin; the DCO file holds the full text. CI rejects a commit that
  has no sign-off.
- Use an imperative subject line and a short body that says what
  changed and why.
- End the message with the trailers of
  `docs/decisions/commit-messages.md`, before the sign-off: one
  `Step:`, `Record:`, or `Issue:` line that names what allows the
  change; one `Meets:` line for each promise of the step that the
  commit carries out; and one `Delivers: <plan>/<step> <hash>` line for
  each step that the commit completes. Take that line from the field
  `delivery` of the record of the step that `sinter scan` gives. A step
  without promises needs the line too. Sinter reads every line of a
  message that starts with `Delivers: `, so start no other line with
  those words.
- Do not commit build output. `.gitignore` covers `_build/`.

### Changes written by agents

Coding agents write much of this codebase. We expect this practice and
we welcome it. The human who runs the agent signs off the commit. That
human is the contributor of record. When an agent wrote a large part of
a change, add a trailer to the commit message that names the agent. You
can use either of these two trailers:

- `Assisted-by: Claude Code` — the agent helped; the human is the
  author.
- `Co-Authored-By: Claude Code <noreply@anthropic.com>` — the agent is
  named as a co-author. GitHub shows co-authors next to the commit.

Both trailers keep the record of authorship in the git history. Do not
sign off code that you did not review.

## Decisions, plans, and rulings

- Decisions that shape the project live in `docs/decisions/`, one file
  per decision, with a `@decision` tag. Read the record before you
  re-argue a choice. To record a new decision, use the
  `/sinter:decision` skill or follow its format. A record that still
  decides the same question is revised in place, with a higher
  revision; a different choice gets a new record that supersedes the
  old one (`docs/decisions/revise-or-supersede.md`). A pull request that
  supersedes a record moves the citations of the old record to the
  new one, with the revision bumps that the move needs, and adds no
  `@ack` for those citations. The journals of plans record the past,
  so their citations stay as they are. "Alternatives
  considered" lists only the alternatives that someone put forward
  and that were deliberated: in an issue, a pull request, a plan, the
  design notes, or with the maintainer. When nobody put one forward,
  the section says so. A decision that rests on measurements carries
  them.
- A record states a choice, the options that were put forward, and
  the reasons. It holds no format, no protocol, no interface, and no
  account of how something is built; those belong in `spec/`, in the
  interface files, and in the help text. A record fits on one screen.
- A record is written from a ruling of the maintainer: an issue, a
  comment on a pull request, or a plan the maintainer approved.
  Nobody writes a record for a choice the maintainer did not make.
- Implementation work follows a plan in `.plans/`, written with the
  `/sinter:plan` skill. A change to a plan's promises or scopes is an
  amendment. Make it a separate, small pull request, so that the
  maintainer's merge is the approval.
- While you carry out a plan step, append brief entries to the plan's
  journal, `.plans/<slug>.log.md`, under a `##` heading that repeats
  the step's heading: a few lines each, for a decision taken, an
  approach that failed and why, a deviation from the step's design,
  or an item left for later. Revise the entries before the pull
  request is ready for review: before you mark a draft ready, or before
  you open a pull request that is not a draft. Ship the entries in the
  pull request (`docs/decisions/plan-journals.md`).
- Ask a design question in a GitHub issue, with the options and their
  costs. The maintainer rules; the ruling is then carried out in a
  pull request.

## Pull requests

Every change reaches `main` through a pull request. The maintainer
reviews and merges; merges are squash merges.

A pull request description names the plan step, with its plan file,
or the issue that the change carries out, and each decision record or
rule that the change adds, with what it decides in a few words. It
holds nothing else (`docs/decisions/pull-request-descriptions.md`).

Before you open a pull request that touches `lib/` or `bin/`, run the
mutation pass on your branch with `--changed-since origin/main`, as "A
pass on a branch" in `docs/contributing/mutation-testing.md` says, and
read every survivor. The `mutation` job makes the same pass on the pull
request, and its result does not hold the merge, so the pass on your
machine is the one that catches a gap before a reviewer sees it.

A review comment names an example of a defect, not its only instance.
When you address a comment, find and fix every instance of the same
defect across the whole change.

## Licensing of contributions

Sinter uses two licenses:

- The code, and every other file outside `spec/` and `docs/`, uses the
  Apache-2.0 license. See the LICENSE file.
- The specifications in `spec/` and the documents in `docs/` use the
  CC-BY-4.0 license. See the LICENSE-SPEC file.

When you contribute, you agree to one condition: your contribution uses
the same license as the file that it changes. People call this model
"inbound = outbound". We do not use a Contributor License Agreement (CLA).

## Third-party code

Do not copy code from other projects, unless both conditions below are
true:

1. The license of the code is compatible with Apache-2.0.
2. You add the code to THIRD_PARTY.md.

Never copy GPL or AGPL code into this repository.
