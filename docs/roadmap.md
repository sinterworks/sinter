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
- **Ideas from OpenSpec** — OpenSpec (openspec.dev) is a framework in
  which an AI coding assistant, a program such as Claude Code that
  writes code, writes a specification of each change before the
  assistant writes the code. A person reviews the specification. The
  checks of OpenSpec test only the form of the specifications, and
  nothing ties a specification to the code or to the tests. The ideas
  below are to explore when the work reaches them. Not designed, and
  not decided.
  - A view of the requirements that a change adds, changes, removes,
    or replaces. In OpenSpec, the assistant writes this view by hand
    for each change, as a "delta spec". Sinter knows each item and its
    revision at the diff base and in the working tree, so it can
    compute the view from the diff. The view can serve the item **Show
    the approval delta so that a person reads it**.
  - An example for each requirement. OpenSpec checks that each
    requirement has at least one scenario: a condition and its outcome.
    Sinter could report each requirement of a design that no group of
    conformance vectors and no test with a `@verifies` covers.
  - A reason when a requirement goes out of force. OpenSpec asks for a
    reason and a migration for each requirement that a change removes.
    Sinter could ask for one line of description on a status tag that
    takes a requirement out of force, and on a `@supersedes` that
    replaces a requirement. The line says why the requirement goes, and
    what a user of the requirement does instead.
  - A reader of OpenSpec repositories. The reader takes the
    requirements and the scenarios of OpenSpec specifications as Sinter
    items. A project that plans its changes with OpenSpec can then cite
    those requirements from its code and its tests with Sinter's tags.
    Sinter then reports the suspect citations of those requirements,
    and it reads the test evidence for them. Which part of Sinter
    reads OpenSpec specifications is undecided.
  - Citations across repositories. In OpenSpec, a "store" keeps the
    specifications in a repository of their own, and code repositories
    refer to the store and only read it. Nothing copies a change from
    one repository to another by itself. OpenSpec never finds a store
    by its name alone, because two repositories in different
    organizations can have the same name. The same shape could serve
    citations from one repository to the items of another, and it
    agrees with the rule that `sinter check` never reads the network.
  - A guided first change. The `onboard` workflow of OpenSpec takes a
    person through one small, real change in a repository that already
    exists, from start to end, in about 15 minutes. The user manual
    (plan `sinter-user-manual`) could start the same way, on a
    repository that the reader already has.
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
- **Assumptions about dependencies** — a design can rest on the
  behavior of something that the project runs but does not control: a
  library, a grammar, or a tool, each at a version. Today a design
  states such behavior, with the version, in a term or a requirement.
  Not designed.
  - A new kind of declared item, an assumption, states one such fact and
    names the dependency and its version.
  - A test that observes the fact verifies the assumption with
    `@verifies`, as a test verifies a requirement. When an update of the
    dependency breaks the fact, the test fails, and Sinter reports the
    assumption as not verified.
  - Sinter reports an assumption that no test verifies, as it reports an
    untraced requirement.
  - An assumption has a revision, and citations pin it as they pin any
    other item.
  - A team that writes Sinter again from the designs (the item **A
    clean-room implementation as the acceptance test of the designs**)
    learns from the assumptions what each design takes from outside the
    repository.
  - It needs the design of test evidence, and a revision of the designs
    Identifiers and Ontology for the new kind.
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
- **Run the examples of the user manual in the browser** — a reader
  of the user manual, which the plan `sinter-user-manual` builds, runs
  each example command on the web page, and edits the files of the
  example. Not designed.
  - Sinter runs in the browser of the reader. wasm_of_ocaml compiles
    Sinter to WebAssembly, the program format that browsers run.
  - A second bridge, in JavaScript, loads the tree-sitter grammars with
    web-tree-sitter. The bridge in `bridge/` uses wasmtime, which
    cannot run in a browser.
  - A layer in `lib/git.ml` lets Sinter use a git written in
    JavaScript, such as isomorphic-git. Today Sinter starts the `git`
    program as a separate process, and a browser cannot start a
    process.
  - A preprocessor of mdBook, the program that builds the manual,
    turns each example command into an element that the reader can
    run. The setting `additional-js` adds the editor and the terminal
    to each page.
  - Ways that were put forward and not chosen: Linux and the `sinter`
    program in one WebAssembly image, made with container2wasm, which
    is a large download and slow to start; WebVM, because its engine,
    CheerpX, needs a commercial license for use by an organization;
    and a server that runs the examples, which needs hosting and a
    secure sandbox.
- **"Developing With Sinter"** — a second text beside the user manual,
  "Using Sinter". The user manual teaches the tool. This text teaches a
  way of working: how a person who works at the level of design uses
  Sinter with coding agents, and why. Such a person sets the direction,
  writes the contracts, gives the work to agents, and reviews by
  intent. The text has an opinion, and it reads as a long essay in
  sections more than as a manual. Its readers decide how a team works,
  and many of them do not use Sinter yet. Not designed.
  - Where it lives: a second mdBook book beside the user manual, one
    long page, or a post outside the repository. Undecided.
  - Its voice: the rules of the section "Writing" in `CONTRIBUTING.md`
    apply to every text in the repository. An essay with an opinion may
    need a freer voice. Undecided.
  - When to write it: after the method of work and the design of Sinter
    stop changing. Undecided.
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
  - In Python, the decorator takes the selection as an expression, not
    as a string: `@verifies(data_forms.toml["offsets"][:] @ "v2")`.
    Attributes name the design and its specification, a subscript
    selects a group or one vector, `[:]` selects every vector, and the
    operator `@` pins the revision. The language pack for Python can read
    the call as the citation `data-forms#toml[offsets][*]=v2`, so the
    test needs no separate comment.
  - It needs citable conformance vectors and the format of their lines,
    which the redesign of Sinter decides.
- **A clean-room implementation as the acceptance test of the designs**
  — before the release of v0.1, a new implementation of the core
  features of Sinter, in another language, written from the designs
  alone. Probably done once. Not designed.
  - The people or agents that write it read only the designs, their
    conformance vectors, and the standards that the designs cite. They
    do not read Sinter's code, its tests, or the history of the designs.
  - The new implementation passes every conformance vector of the
    designs that it implements.
  - Both implementations then run on Sinter's own repository and on a
    corpus of small example repositories. Each example holds a known
    issue that Sinter must report, such as a citation that pins an old
    revision. Both implementations must report the same findings.
  - Each disagreement is a gap in a design or a defect in one of the
    implementations. A gap is fixed in the design.
  - Which features count as the core, and which language the new
    implementation uses, are not decided.
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
- **Fuzz targets for the readers of text** — `crowbar` under AFL over
  the readers that Sinter builds from the designs Text and Identifiers:
  the UTF-8 decoder, the reader of tag lines, the reader of id patterns
  and bindings, and the reader of inline citations in Markdown. Built
  outside the test suite, as the target for the bridge boundary is.
  Not designed.
  - A target feeds a reader generated input and reports each input
    that makes the reader raise an exception or run past a time limit.
  - Inputs that take time out of proportion to their length are a main
    aim, such as square brackets nested many levels deep in Markdown.
- **A generated third-party list** — `THIRD_PARTY.md` built in CI from
  `bridge/Cargo.lock` and `sinter.opam.locked` (`cargo about` or
  `cargo license` for the Rust tree), with a drift check. `cargo deny`
  checks the Rust licences against an allowlist until then.
