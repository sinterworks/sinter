<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Roadmap

- **Scanner** — the language-pack interface, design notes section 5.2.
- **`sinter scan`**
  - Conformance fixtures.
  - Print the `setting` records and the `gate` records of
    `spec/jsonl.md` section 7. `config-changed` already uses their ids.
  - `sinter scan --diff`: print the `hunk` records and the `tombstone`
    records. Not designed.
- **`sinter check`**
  - The built-in finding classes, `spec/algebra.md` section 9.
- **Rule files** — the rules and the finding classes that a
  repository writes, `spec/manifest.md` section 14.
  - Decide, when rule files are built, whether an edit of a rule file
    needs a revision bump (`unbumped`), and whether `config-changed`
    covers rule files.
- **A dictionary of terms** — one definition for each term of a
  repository, in any file that Sinter reads. Every text, and every
  agent, then uses a term with one meaning. Not designed.
  - A new tag, `@term`, declares one term and its definition. A term has
    a slug, such as `default-branch` for the term "default branch".
  - The definition is normative: it fixes what the term means in every
    text of the repository.
  - The slugs of terms form one namespace for the whole repository,
    apart from the slug namespaces of `spec/vocabulary.md` section 4.1.
  - A slug of a term can start with a prefix and `/`, as in
    `ledger/claim`, to group the terms of one area. Today the slug
    pattern does not allow `/`. Also, `<ns>/<id>` is the form of an
    external id (`spec/vocabulary.md` section 4.2).
  - A citation of a term states the kind of its target, as in
    `@cites term:ledger/claim`. Today a citation never states a kind
    (`spec/vocabulary.md` section 4.1).
  - A term has no revision. Today every declaration has a revision
    (`spec/vocabulary.md` sections 5 and 9). The ledger also binds each
    approval to a revision (`spec/ledger.md` section 5.2).
  - A command that searches the terms and prints a definition. The same
    search can be a tool of the MCP server that the item
    **`sinter serve --mcp`** describes. The command overlaps with the
    item **`sinter search`**.
  - How Sinter shows a person that a definition changed. A changed
    definition changes the meaning of each text that uses the term. A
    possible way: Sinter compares the extent hash of each definition
    (`spec/vocabulary.md` section 6.1) at the diff base and in the
    working tree. It then reports each text that cites a term whose
    definition changed. That way does not find a text
    that uses a term with no citation. Undecided.
- **`sinter patch`** — print the mechanical fixes of the findings as a
  diff for `git apply`, design notes section 11.10. Sinter itself
  writes no file.
  - Among its fixes: move a citation of a superseded item to its
    successor, and bump the revision of the citing declaration (record
    `cite-the-successor`).
- **Ledger commands and evidence import**
- **`sinter explain`** — design notes section 11.7. `sinter explain
  --short <class>` prints the sentence of the class that SARIF also
  writes (record `sarif-output`). Without `--short`, a paragraph of
  explanation and an example follow. SARIF can then take that
  paragraph for the full description and the help of each rule.
- **Show the approval delta so that a person reads it** — a person
  approves the changes to a set of items since their last approval
  (design notes section 6.4). How to show those changes so that the
  person actually reads what they approve is open. Not designed.
- **The coverage of each test for Rust and Go** — rung 4 of the
  evidence ladder needs the coverage of each test (design notes
  section 4). To run each test that carries a `@verifies` in its own
  process is correct and slow. A driver could merge the coverage files
  of `cargo llvm-cov` by test name, or run `go test -run` for each
  test. Whether either can be fast enough for the hook after each
  edit, and not only for CI, is unknown. Until then, these packs
  report rung 4 as `unmeasured` on a local machine, and as
  `unexercised` or `passing` in CI. Not designed.
- **Issue trackers** — plans and steps that point at issues in a
  tracker such as GitHub, GitLab, or Jira.
  - A pointer from a plan or a step to an issue that is not a promise.
    Today every tag in a plan file is a promise, so `@cites gh/42` in a
    step promises a citation; it does not say that the step carries out
    the issue. It shares its design with `@pin`.
  - The state of an issue, read by a routine outside Sinter and written
    into a file, as the next item describes; `sinter check` never reads
    the network.
  - A converter outside Sinter that turns a sequence of issues into a
    plan file and opens a pull request, or into a draft that a person
    records in the ledger.
  - Nothing flows back to the tracker when a plan closes. Not designed.
- **Observations of the outside world** — an obligation that a
  decision record makes and that never ends, where the work depends on
  events outside the repository. An example is a decision to keep
  every dependency at its newest release.
  - A routine outside Sinter checks outside sources on a schedule,
    for example new releases and security advisories. It writes what
    it finds into a file in the repository, as evidence import does.
    `sinter check` never reads the network.
  - A rule (design notes section 7) whose origin is the record
    triggers on that file. A plan that cites the observation, or an
    `@ack`, clears the obligation.
  - It shares its design with `@pin` (`spec/vocabulary.md` section
    7.4) and with evidence import. Not designed.
- **Plans with their journals** — show each plan step with the
  journal entries for the step (record `plan-journals`): the step and
  its promises by default, the journal entries on request. Not
  designed.
- **Plans made of plans**: a step of one plan names another plan as
  its work, so that a large plan can split into smaller plans. The
  step is done when the plan it names is completed. For example, a
  step of `sinter-v0.1` would name the plan `readable-output`. Not
  designed.
- **Branches that deliver one plan at the same time** — two branches
  that deliver steps of one plan at once are not reported as an
  overlap, because the plan is no claim on either branch (record
  `plans-span-branches`). Not designed.
- **Commit trailers** — read the `Step:`, `Record:`, `Issue:`, and
  `Meets:` trailers of the commits on a branch (record
  `commit-messages`) and check them against the plan and the diff.
  Not designed.
- **jj repositories without `.git`** — support a jj repository that
  is not colocated, and a jj workspace that has no `.git`. A small
  locator asks `jj` for the git folder and for the parent of the
  working-copy commit, and Sinter then runs git as it does today. Not
  designed.
- **`sinter search`**
  - Keyword search over titles, descriptions, and extents.
  - Semantic search: a bundled local model, an external service
    behind an opt-in, or a pluggable backend. Undecided.
  - Scope: all declaration kinds and plans, or decisions only.
    Undecided.
- **`sinter serve --mcp`**
  - An MCP server over stdio; tools named after the CLI verbs.
  - The decision record answers the "no MCP server" argument in the
    design notes, section 9.1.
  - A richer Claude Code plugin on top of the server: MCP Apps UI that
    shows plans, decisions, and other Sinter information to the user
    inside the client. A desired outcome, not yet designed.
- **`sinter serve --detach`** — a mode that outlives its caller, on a
  socket, for several clients.
- **`sinter serve --lsp`** — a Language Server Protocol adapter on the
  serve loop, after the MCP adapter. A child of the editor; it informs
  and never blocks a save.
  - Diagnostics on edit from the findings, and code actions from the
    mechanical fixes of `sinter patch`: re-pin, bump, rename fix-up,
    `@ack` insertion.
  - Hover, go to definition, and find references over the graph: a
    citation to its declaration, a declaration to its citing sites and
    tests, a `@verifies` to its rung, a `@decision` to its record.
  - Completion: the tag words, the slugs in the index, the test names
    a pack captures.
  - Rename as deletion plus declaration across the repository.
  - One server for a person's editor and for the Claude Code plugin
    (`.lsp.json`), so an agent gets diagnostics on every edit through
    the same protocol.
- **`spec/protocol.md`** — the `serve` request and response protocol,
  as a specification of its own.
- **Rank the items of the brief** — the brief ranks its items by
  their distance in the graph from the step's scope (design notes
  section 8.1). A wrong brief is worse than a short one, because it
  fills the budget with the wrong requirements. Other weights are
  possible: the number of citations, the recency of approval, or the
  declarations that the step's promises reach through `@refines`.
  Measurements of real sessions will decide; the metrics of the
  ledger (design notes section 6.4) will show the answer as fewer
  violations in each turn report. Not designed.
- **`sinter-packs` repository** — the language packs, in the
  repository `sinterworks/sinter-packs`, with the licenses that
  `docs/licensing-setup.md` describes.
- **Test evidence for Sinter itself** — JUnit output from the test
  suite, for `evidence import`.
- **Tests with no name** — the OCaml tests of `ppx_expect` and
  `ppx_inline_test` are anonymous extension nodes, and the runner
  reports no name for them. The OCaml pack needs a way to bind their
  results before it can read them as tests. This matters because
  Sinter checks its own code. Not designed.
- **Test adapters for conformance vectors** — a library for each test
  framework that loads the conformance vectors of a design and runs one
  test case for each vector, so that a test of an implementation cites
  the vectors that it checks. Not designed.
  - A test names its vectors with a citation, such as
    `data-forms#toml[offsets][*]=v2`. The adapter loads exactly those
    vectors from the file `data-forms.toml.test-vectors.jsonl`.
  - Each vector becomes one test case, so a failure names the vector by
    its number and its group.
  - The adapter fails a test whose pinned revision no longer matches
    the revision of the vectors that it selects.
  - Sinter traces each such test to the vectors that it cites, and
    reports each vector that no test exercises. The language pack of the
    test's language must read the citation, in a comment or in the call
    of the adapter.
  - The first adapter is for Python and pytest, as a decorator. Others
    follow for the test frameworks of the language packs.
  - It needs citable conformance vectors and the format of their lines,
    which the redesign of Sinter decides.
- **Tags in Python docstrings** — in Python, a docstring is a statement
  that consists of one string literal, not an f-string, and that is
  the first statement of a module, a class, or a function. Python
  keeps the documentation of that module, class, or function in its
  docstring. The language pack for Python (`spec/packs.md` section 2)
  reads tags only in `#` comments:
  its query file `tags.scm` (`spec/packs.md` section 4.2) captures no
  string literal, and `spec/vocabulary.md` section 2 forbids tags in a
  string literal. So Sinter reads no tag line (`spec/vocabulary.md`
  section 3.1) in a docstring. A new release of the pack could read
  tag lines in docstrings too. Not designed. This list is a sketch of
  the places that such a change would probably touch, and it is not
  complete:
  - `spec/vocabulary.md` section 2: an exception for docstrings to the
    rule against tags in string literals.
  - `spec/packs.md` section 4.2: a way for `tags.scm` to capture a
    docstring and no other string literal. A query captures a node of
    the syntax tree (`spec/packs.md` section 4.1). The grammar that
    the pack pins, tree-sitter-python v0.25.0, has no kind of node for
    a docstring.
  - `spec/packs.md` section 3.4: the quotes of a docstring as comment
    sigils, the texts that open a comment, close it, or start an inner
    line of it. A sigil is a fixed text, and a string literal can start
    with a prefix such as `r`, `R`, `u`, or `U`, so the sigils need a
    new form or a new rule.
  - `spec/packs.md` sections 6.1 and 6.2: a docstring would become a
    comment and stop being code. A `#` comment on the line before or
    after a docstring would then join its run, the sequence of
    comments that Sinter reads as one unit.
  - `spec/packs.md` section 6.4: the attachment of a docstring's run
    to the class or function whose docstring it is. A run attaches
    only to an attachment target that starts after the run. A
    docstring is part of the body of its class or function, so its run
    starts inside its target and cannot attach to it. It can attach
    instead to the next attachment target, such as the first method of
    a class, when the three conditions of section 6.4 hold. Otherwise
    it is unattached. An attachment target is a definition, a test,
    or a group (`spec/packs.md` section 6.4). The docstring of a
    module needs a target of a new kind, because a file is not an
    attachment target.
  - `spec/vocabulary.md` section 6.2: the code hash of a definition is
    taken over its body, and the section says that a body contains no
    comment sigils and no tag lines. A docstring with tag lines would
    break that statement.
  - `spec/packs.md` section 2.5: the kind of the new release. A minor
    release changes no extent hash (`spec/vocabulary.md` section 6.1).
    The extent of a block of tag lines (`spec/vocabulary.md` sections
    3.1 and 6.1) is the tag-bearing text of its run. So a `#` comment
    that joins the run of a docstring changes the extent of each block
    in that comment, and the release may need to be a major release.
  - The code of Sinter's scanner, and its tests.
- **Drop the pins on the measuring tools** when upstream `bisect_ppx`
  and `mutaml` release versions that install beside the lock file
  (`docs/decisions/instrumented-tooling.md`).
- **A fuzz target for the bridge boundary** — `crowbar` under AFL over
  the result-buffer decoder and the wasm export reader, built outside
  the test suite. `docs/decisions/test-rigor.md` notes the choice.
- **A generated third-party list** — `THIRD_PARTY.md` built in CI from
  `bridge/Cargo.lock` and `sinter.opam.locked` (`cargo about` or
  `cargo license` for the Rust tree), with a drift check. `cargo deny`
  checks the Rust licences against an allowlist until then.
