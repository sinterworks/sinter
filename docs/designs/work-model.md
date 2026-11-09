<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# The work model
@design work-model
@cites ledger-event-log
@cites ledger-layout
@cites agent-statements
@cites delivery-lines
@cites plans-span-branches
@cites plan-ids
@cites rule-files
Sinter models work as designs and decision records in the tree, and as plans and tasks in the ledger.

## 1. Context

### 1.1 Terms

| term | meaning | defined in |
|---|---|---|
| tag | a line such as `@req ledger-decline v2` in a comment or in a markdown paragraph, which Sinter reads | `spec/vocabulary.md` section 3 |
| tag target | the text after the tag word: the slug, the external id, or the other name that the tag declares or points at | `spec/vocabulary.md` section 3 |
| slug | the name of a declared item, such as `ledger-decline` | `spec/vocabulary.md` section 4.1 |
| declaration | a tag that defines a declared item, such as `@req` or `@design` | `spec/vocabulary.md` section 7.1 |
| requirement | a statement of behavior that code must satisfy and tests must verify, declared with `@req` | `spec/vocabulary.md` section 7.1 |
| citation | a tag that links its source to a declaration or to an external id: `@satisfies`, `@verifies`, `@refines`, `@cites`, or `@supersedes` | `spec/vocabulary.md` section 7.2 |
| extent | the text that the revision of a declaration applies to; in markdown, the section or the list item that holds its tag | `spec/vocabulary.md` section 6 |
| extent hash | the SHA-256 of the normalized text of an extent | `spec/vocabulary.md` section 6.1 |
| revision | the version of a declaration, `v1`, `v2`, and so on, which must rise when its extent changes | `spec/vocabulary.md` sections 5 and 9 |
| pin, suspect | a revision on a citation pins the citation to that revision of its target; the citation is suspect when the target now has another revision | `spec/vocabulary.md` sections 5 and 9 |
| plan file, step of a plan file | today, a markdown file under `.plans/`; each `##` section of it with tags is a step, one unit of work | `spec/vocabulary.md` section 10 |
| promise of a step | today, a tag in a step of a plan file, which the step will produce | `spec/vocabulary.md` section 10.2 |
| scope of a step | today, the paths that a step of a plan file can change, written with `@scope` | `spec/vocabulary.md` section 10.4 |
| delivery line of a step | today, a line `Delivers: <plan>/<step> <hash>` in a commit message | `spec/vocabulary.md` section 10.8 |
| ledger | the log of entries that Sinter keeps on the git ref `refs/sinter/ledger`; each entry is one JSON line | `spec/ledger.md` |
| chunk | one file of entries in the tree of a commit of the ledger | `spec/ledger.md` section 2.1 |
| `seq` | the number of an entry; Sinter reads the entries of the ledger in the order of their `seq` | `spec/ledger.md` section 3.4 |
| fold | a computation that reads the entries of the ledger one by one, in the order of `seq`, and gives a state | `spec/ledger.md` section 2.3 |
| provisional entry | an entry that a clone wrote and has not pushed; its `seq` and its entry id can still change | `spec/ledger.md` section 3.2 |
| replay | what a writer does after its push loses: it checks its entries again against the new tip of the remote and appends the ones that still hold | `spec/ledger.md` section 3.2 |
| the job on the default branch | the command that runs at each push to the default branch and records deliveries in the ledger | `spec/ledger.md` section 8 |
| agent marker | an environment variable, such as `CLAUDECODE`, that shows that a coding agent runs a command | `spec/manifest.md` section 10.2 |
| external id | a tag target of the form `<ns>/<id>`, such as `gh/42`, that points at something outside the repository | `spec/vocabulary.md` section 4.2 |
| exempt path | a path that a change can touch with no work that allows it, such as a lock file | `spec/manifest.md` section 9.1 |
| finding, finding class | a fact that `sinter check` reports, and the kind of that fact | `spec/algebra.md` section 9 |
| gate, tier | a gate is the point at which a check runs: `review`, on a pull request; `merged`, on the default branch. Today a third gate, `turn`, runs before a coding agent ends its turn; this design removes it (section 3.14). A tier is what a finding class does at one gate: `off`, `warn`, or `block` | `spec/manifest.md` section 11 |
| the base | the git revision that a check compares its tree against; by default, the merge base of `HEAD` and the default branch | `docs/design-notes.md` section 11 |
| hunk | one block of changed lines in the diff between the base and the tree that a check reads | `spec/algebra.md` section 3 |
| in force | a declaration that carries no status tag and that no effective `@supersedes` retires | `spec/vocabulary.md` section 8.1 |
| live decline | a decline of the current text of its subject that no later approval ends | `spec/ledger.md` section 7.2 |
| test evidence | the results of the tests that Sinter imports for one tree: which tests ran, passed, or failed, and which code they covered | `spec/algebra.md` section 2; `docs/design-notes.md` section 4 |
| rung | the level of the test evidence of a `@verifies` citation, such as `passing` or `never-ran` | `spec/algebra.md` section 6.7 |
| session | the state of one run of an agent, which Sinter keeps in `.sinter/` of the working tree of that agent | `docs/design-notes.md` section 6.1 |
| git common dir | the folder that `git rev-parse --git-common-dir` prints, which all working trees of one clone share | git |
| output record | one JSON line in the output of a command | `spec/jsonl.md` |

More terms:

- **task** and **plan:** the units of work of this design; a task is
  one piece of work, and a plan says how a set of tasks gets done
  (section 3.1);
- **harness:** the program that starts and runs coding agents, for
  example Claude Code;
- **external tracker:** an issue tracker outside the repository, such
  as GitHub Issues or Jira;
- **MCP** (Model Context Protocol): the protocol that a coding agent
  uses to call the functions of a tool.

### 1.2 The problems

This design answers three problems in how the Sinter project has
worked.

1. **No document holds one part of Sinter.** Each file in `spec/`
   defines a format or a behavior, such as the ledger in
   `spec/ledger.md`. `docs/design-notes.md` is one long document for
   all of Sinter. No document holds, for one part of Sinter, its
   context, its analysis, the alternatives that were weighed, its
   requirements, and its test plan. The reasons are spread over 63
   decision records in `docs/decisions/`, and each record holds one
   small choice. The tag `@design` exists, but the specifications in
   `spec/` and the design notes declare no `@design`. Only
   `spec/ledger.md` declares requirements with `@req`.
2. **Plan files describe what to build.** Each step of a plan file says
   what the step builds, for example the steps of `.plans/ledger.md`.
   That is the role of a design. The text then lives in a plan file,
   which ends when its work ends, and not in a design that lives with
   the code. To widen the scope of a plan file, the project opens a
   pull request that changes the file.
3. **Long runs of agents.** An agent that runs for a long time builds
   up context, and the text that it writes then assumes that context.
   When many agents work at once, a person cannot follow all the work
   in progress.

This design answers problems 1 and 2 directly. It answers problem 3 in
two ways:

1. The brief of a task, which `sinter brief` prints, gives an agent its
   context from the design (section 3.14), so an agent can live for one
   task. The harness decides how long an agent lives.
2. Sinter shows the state of all work in one place (section 3.15).

### 1.3 The aim

Sinter is for agentic programming: people work mainly through designs
and requirements, and agents write most of the code. The person who
uses Sinter works as a principal engineer works. That person sets the
direction, defines the contracts, delegates, and reviews at the level
of intent. The scarce resource is a person's judgment on an exact
text. Each agreement must cost little, because people skip an
agreement that costs too much ceremony.

This design does not design two features that touch it. The first is
the inbox of `docs/design-notes.md` section 6.8: a list of what needs a
person's judgment. The second is a command with which an agent asks
Sinter which agreements apply to a file before the agent changes it.
Section 7 lists what this design gives them.

### 1.4 Sinter today

- Sinter reads tags in the text files of a repository. Citations link
  code, tests, and documents to declarations.
- Requirements, designs, and decisions share one namespace of slugs, so
  a citation never states the kind of its target. Only the tag target
  of `@plan` can hold `@`. No tag target can hold `/`, except an
  external id (`spec/vocabulary.md` sections 4.1 to 4.3).
- Today `@design` declares a design item: a part of the architecture
  that code can satisfy and tests can verify (`spec/vocabulary.md`
  sections 7.1 and 7.2). Under this design, `@design` declares a whole
  document whose prose is not normative (section 3.2).
- A declaration in the first paragraph of a markdown section claims the
  whole section as its extent. A declaration in a nested section
  removes that section from the enclosing extent: boundary rule 2
  (`spec/vocabulary.md` section 6).
- Sinter does not read tags inside code fences (`spec/vocabulary.md`
  section 2).
- People approve and decline declarations, plan files, and the steps
  of plan files in the ledger. Sinter judges a plan file by its
  commitment set: its promises and its scopes.
- Only a person or the job on the default branch writes entries
  (requirement `ledger-writers`). A statement that an agent writes in a
  file changes a state only when it is a line of the diff, tied to the
  text that it is about (record `agent-statements`).
- Sinter is a pure function of a snapshot of its inputs and of the
  ledger (record `ledger-event-log`).
- A claim is an open plan file that the ledger holds an approval of,
  with its commitment set, and whose full form the current tree does
  not hold (`spec/ledger.md` section 10.2).
- The design notes say "No database": Sinter's index lives in memory,
  with a cache on disk that Sinter can rebuild (`docs/design-notes.md`
  section 9). The code keeps no cache on disk.
- The roadmap item "Issue trackers" says that a routine outside Sinter
  reads a tracker and writes a file, and that `sinter check` never
  reads the network.
- The code holds these commands: `sinter parse`, `sinter serve`,
  `sinter scan`, `sinter check`, `sinter ledger verify`, and
  `sinter ledger log` (`bin/main.ml`). The design notes and the
  specifications design `sinter status`, `sinter approve`,
  `sinter decline`, `sinter brief`, `sinter declare`, and
  `sinter ledger push`, and the code does not have them yet. The
  commands `sinter task`, `sinter plan`, and `sinter tracker fetch` are
  new in this design.

## 2. Analysis

### 2.1 Evidence from other tools

Many tools keep issues, reviews, or tasks inside a repository. Four of
them are close to Sinter's ledger:

- **Gerrit NoteDb.** The code review server Gerrit keeps each review as
  a chain of commits on its own git ref. Its only atomic step is a
  compare-and-swap of a ref, and a writer that loses runs again on the
  new state. Its search index is built from the commits and can be
  built again.
- **Fossil tickets.** Fossil, a version control system, keeps each
  change of a ticket as a record that never changes, and builds SQL
  tables from the records. Its tickets are the same on every branch.
- **git-bug.** A bug tracker that keeps each issue as a chain of
  commits on its own ref, with a local SQLite index since version
  0.12.0 (git-bug release v0.12.0).
- **Beads.** A task tracker for coding agents.

The evidence gives these lessons:

1. **Trackers that lived only in git mostly faded.** People who are not
   developers could not take part, and the tools had no web view. The
   tools that survived also run their own server and web view, as
   Fossil and Gerrit do.
2. **Two-way sync with an external tracker failed in every tool that
   had it.** git-bug's bridge added one more copy of each comment at
   each cycle of push and pull (git-bug issue 1582). A full import of
   581 GitHub issues gave 96 issues a wrong state, with no error
   (git-bug issue 1638). A reference only, or an import with a mapping
   and a checkpoint, costs less. The connections also broke when a
   tracker changed its interface: Jira removed an endpoint of its
   search (git-bug issue 1718), and GitLab changed the form of its
   tokens (git-bug issue 1587).
3. **A local cache works under five conditions.** The log is the only
   truth. The cache records the exact version of the log that it
   reflects. It expects other programs to change the log. It stores the
   version of its own layout. Someone has measured the time of a full
   rebuild. git-bug before 0.12.0 assumed that it was the only program
   that touched the repository, and its cache went stale (git-bug
   release v0.12.0). After a failed sync, Beads offered a closed task to
   a second agent (Beads issue 885).
4. **Sequential task numbers clash across branches.** Backlog.md, a
   task tool that keeps one markdown file for each task, got duplicate
   ids (Backlog.md issue 1146).
5. **A different state on each branch confuses people.** Fossil keeps
   its tickets the same on every branch for that reason.
6. **Files of tasks in the working tree conflict.** Task Master, a task
   tool for coding agents that keeps its tasks in one JSON file,
   reports merge conflicts when several branches add tasks (Task Master
   issue 11).

No tool has measured how often frequent writes collide on one shared
ref. No one has measured how long a SQLite index takes to build from a
ledger of Sinter's form.

Sources: <https://github.com/git-bug/git-bug/issues/1582>,
<https://github.com/git-bug/git-bug/issues/1638>,
<https://github.com/git-bug/git-bug/issues/1718>,
<https://github.com/git-bug/git-bug/issues/1587>,
<https://github.com/git-bug/git-bug/releases/tag/v0.12.0>,
<https://github.com/gastownhall/beads/issues/885>,
<https://github.com/gastownhall/beads/issues/2573>,
<https://github.com/MrLesk/Backlog.md/issues/1146>,
<https://fossil-scm.org/home/doc/trunk/www/tickets.wiki>,
<https://gerrit-review.googlesource.com/Documentation/note-db.html>,
<https://github.com/eyaltoledano/claude-task-master/issues/11>.

### 2.2 What the design must answer

Plans and tasks move into the ledger, and agents write them. Eight
forces follow. A **force** is a fact that the design must answer.

1. **Plans and tasks leave the pull request diff.** Today a plan file
   reaches the default branch in a pull request of its own, and a
   person reads its text in the diff. GitHub shows nothing of a custom
   ref. People need another way to see plans and tasks.
2. **Agents become writers of the ledger.** Today only a person and the
   job on the default branch write entries, and the commands that record
   a person's judgment refuse under an agent. An agent that can write
   any state can spread a wrong state to other agents, as in Beads issue
   885.
3. **Many writers compete for one ref.** Every write moves
   `refs/sinter/ledger`. Today a writer that loses a push asks the
   person again at the terminal when a check needs to ask. That suits
   rare judgments by a person, and it does not suit frequent writes by
   agents, which have no terminal.
4. **An entry is provisional until its push wins.** A replay gives the
   entry a new `seq` and a new entry id. An agent needs a name for a
   task that holds from its first write.
5. **A done state must stay done.** A state that Sinter reads from the
   tree changes when the tree changes, and a task that is done must not
   become open again.
6. **The plan files exist.** Moving their work into the ledger is a
   migration, and a migration of this kind lost data in Beads (Beads
   issue 2573).
7. **Agents must read plans and tasks.** An agent reads a file easily.
   Plans and tasks in the ledger need commands and MCP tools that print
   them.
8. **Each agreement must cost little** (section 1.3).

## 3. The vision

### 3.1 Four kinds of text

| kind | its role | where it lives | lifetime |
|---|---|---|---|
| design | what is built and why, for one part of a system; it can run to tens of pages | a section of a markdown file in the tree, with parts that can live in other files and in code | lives with the code, and has revisions |
| decision record | one standing practice of the project, or one choice with its reason, in a few lines | a markdown file in the tree | permanent; section 3.6 gives one exception for this repository before version 0.1 |
| plan | how a set of tasks gets done | the ledger | done while all its work is done; ends when a person abandons it |
| task | one piece of work that one agent or one person can finish alone | the ledger | ends when it is done or a person abandons it |

A design says what to build. A plan and a task point at the design and
say in which order the work happens. A person approves designs and
decision records, and never a plan.

### 3.2 Designs, specifications, and requirements

A **design** holds the context and the analysis of a problem or of a
set of features, one vision of how they are built, the alternatives
that someone really weighed, the requirements that it places on
behavior, and the test plan of those requirements. `@design` and a slug
declare a design. A design has no id: its slug is unique in the shared
namespace of section 3.4.

A **specification** is a declaration of a new kind, `spec`, written
`@spec`. It specifies one thing: a format, a protocol, or a set of
behaviors. It has a name, a revision, and an extent, and it belongs to
exactly one design. Its **contract** is its normative text. A design
can hold specifications. A small design can hold its requirements
directly, with no specification.

Containment has three levels: design, specification, and requirement.
The **full name** of a specification or of a requirement inside a design
has the form `<design>#<name>`, such as `packs#descriptor`: the slug of
the design, `#`, and a **name inside the design**. The slug of a design
can hold segments joined by `/`, and the segments before the last one
are its custom namespace (section 3.4). A name inside a design follows
the slug pattern of `spec/vocabulary.md` section 4.1, so it holds no `/`
(section 3.4). The full name of a design is its slug, and the full name
of a requirement outside every design is its slug. Within one design,
specifications and requirements share one set of names. Two of them
whose names are equal, or differ only in case, are the finding
`duplicate`, as two slugs are (`spec/vocabulary.md` section 4.1). A
requirement that moves from one specification to another of the same
design keeps its name.

When a check compares a tree with the base, the key of a specification
or of a requirement is its full name. So a rename of a design is, for
each specification and each requirement of the design, a deletion and a
new declaration, as every rename is (`spec/vocabulary.md` section 4.1).

Every requirement must live in a design. A requirement outside every
design is the finding `req-outside-design`. Such a requirement still
declares its slug, in the shared namespace of section 3.4, so its
citations resolve and the other checks still work on it. One fault gives
one finding, so a citation of such a requirement is not also the finding
`unapproved-req` (section 3.5).

A sketch of a design with one specification:

```markdown
# Language packs
@design packs v4
Context, analysis, vision, alternatives, test plan ...

## The pack descriptor
@spec descriptor v2
### Size limit
@req descriptor-size v1
A descriptor has at most 1 MiB.
```

**Extents and revisions.**

- The extent of a design is its own prose: its section, without the
  extents of its specifications and of the requirements that it holds
  directly. This is boundary rule 2 (`spec/vocabulary.md` section 6).
  Every change of that prose raises the revision of the design. Sinter
  has no exception for an edit that keeps the meaning
  (`spec/vocabulary.md` section 9).
- The prose of a design is not normative: no code satisfies it, and no
  test verifies it. In a design with no specification, only the text of
  its requirements is normative.
- The extent of a specification holds all its requirements, and all
  prose inside that extent is normative. Boundary rule 2 does not apply
  to the extent of a specification.
- Inside a specification, the extent of each requirement is its own
  section without the requirements nested in it. Boundary rule 2 applies
  to the extents of requirements.
- So an edit of a requirement raises two revisions: that of the
  requirement and that of its specification. A tool or a team can pin a
  whole contract, such as `packs#descriptor v2`. Because each edit of a
  requirement of that contract raises the revision of the
  specification, the citation then becomes suspect.
- The extent hash of a specification drops the revision token on the
  tag line of each requirement inside it, as step 6 of
  `spec/vocabulary.md` section 6.1 drops the revision of a citation.
  The name of the requirement stays in the hash. So a bare raise of the
  revision of a requirement does not change the hash of its
  specification, and a rename does.

**Where the parts of a design live.** The **section of a design** is the
markdown section whose first paragraph holds its `@design`. A file can
hold more than one design, so the section of a design, not its file,
decides which declared items belong to it. Designs do not nest: a
`@design` inside the section of another design is the finding
`misplaced-declaration`. A `@design` in a code comment is also the
finding `misplaced-declaration` (section 3.3). A declared item of a
design is **out-of-line** when it is declared outside the section of its
design. A specification hangs together as one text in one place, so that
a reader can read the whole contract there. A specification lives wholly
in one of these places:

- in the section of its design, where it declares its name alone, as
  `@spec descriptor`;
- in a markdown file of its own, where it declares its full name, as
  `@spec packs#descriptor`;
- in the comments of code (section 3.3), where it also declares its
  full name.

A `@spec` with its name alone belongs to the design whose section holds
it. Specifications do not nest. A `@spec` inside the section of another
specification is the finding `misplaced-declaration`, in markdown as in
code. The markdown file of a specification holds that one
specification and its requirements, and no other declaration. These
cases are also the finding `misplaced-declaration`:

- a `@spec` with a full name in the section of its own design, or in
  the section of another design;
- a `@spec` with its name alone outside the section of every design,
  because no design holds it;
- a `@spec` with a full name whose design does not exist. Such a
  specification still declares its full name, so its citations
  resolve;
- a declaration other than a requirement inside the section of a
  specification;
- any declaration in the markdown file of a specification other than
  that specification and its requirements.

A requirement belongs to the design whose section holds its tag line,
and to the specification whose section holds it, when one does. A
requirement in the markdown file of a specification belongs to that
specification and its design, and declares its name alone. A
requirement inside the body of a specification in code also declares
its name alone (section 3.3). A requirement in code outside every body
declares its full name, and its design holds it directly. In markdown,
a requirement stands only in the section of its design or in the
markdown file of one of its specifications. A `@req` with its name
alone outside the section of every design and outside every
specification is the finding `req-outside-design`. These cases are the
finding `misplaced-declaration`:

- a `@req` with a full name in markdown, outside the section of its
  design and outside the markdown file of each of its specifications;
- a `@req` with a full name in the section of its own design, or inside
  the body of a specification in code;
- a `@req` in the markdown file of a specification, with a full name
  that names another design. The requirement still belongs to that
  specification;
- a `@req` with a full name whose design does not exist. Such a
  requirement still declares its full name, so its citations resolve.
  One fault gives one finding, so it is not also the finding
  `req-outside-design`.

No syntax lets a requirement name a specification that stands somewhere
else, so no specification can be partly in one place and partly in
another.

**Marks for out-of-line items.** The section of a design marks each
out-of-line item of the design with the tag word `@extern` and the kind
of the declared item: `@extern spec:descriptor`,
`@extern req:chunk-size`. A mark stands in the design's own prose: in
its section, outside the extent of each of its specifications and
requirements. A mark names a declared item of the design whose section
holds it. A mark must state the kind. A mark gives the name only, not
the path, so a move of a file needs no edit of the design. A mark takes
no revision. A requirement inside an out-of-line specification needs no
mark of its own. A mark is part of the prose of the design, so adding or
removing a mark raises the revision of the design. The finding
`extern-mismatch` reports three cases: an out-of-line item with no mark
in its design; a mark with no such declared item; and a mark for a
declared item that the section of the design itself declares. These
cases are other findings:

- an `@extern` that stands in the own prose of no design is
  `misplaced-declaration`;
- a mark with no kind word is `invalid-target`;
- a mark with a kind other than `spec` or `req` is `wrong-kind`.

A sketch of a design whose specification lives in its own file:

```markdown
# Language packs
@design packs v5
@extern spec:descriptor
Context, analysis, vision, alternatives, test plan ...
```

```markdown
# The pack descriptor
@spec packs#descriptor v3
### Size limit
@req descriptor-size v1
A descriptor has at most 1 MiB.
```

**Retirement.** A design and a specification retire as other
declarations do: by a status tag, or by an effective `@supersedes`
(`spec/vocabulary.md` section 8). The status tag `@deprecated` also
applies to a specification.

A `@supersedes` is effective only when its source is approved, where
the kind of the source needs approval (`spec/vocabulary.md` section
8.1). The source of a `@supersedes` is the innermost declaration whose
extent holds its tag line (`spec/vocabulary.md` section 7.2). So a
`@supersedes` in the extent of a requirement inside a specification has
that requirement as its source. Where `proof.req` requires approval, a
`@supersedes` is effective at these times, by the kind of its source:

- a specification: when the specification is approved;
- a requirement inside a specification: when that specification is
  approved, because the requirement then counts as approved (section
  3.5);
- a requirement that a design holds directly: when that requirement is
  approved;
- a requirement outside every design: never. No subject of approval
  holds such a requirement, and the requirement is already the finding
  `req-outside-design`.

Where `proof.design` requires approval, a `@supersedes` whose source is
a design, such as a `@supersedes` in its tag block, is effective when
the prose of the design is approved. A `@supersedes` whose source is a
decision record keeps the rule of `spec/vocabulary.md` section 8.1,
with the key `proof.decision`.

The retirement of a design or of a specification also retires the
declared items inside it:

- When a design retires, each specification and each requirement of
  the design retires.
- When a specification retires, each requirement of the specification
  retires.

This is an exception to `spec/vocabulary.md` section 8.2, which says
that retirement does not cascade. A citation of a retired declared item
still retires nothing. To keep a requirement in force while its design
or its specification retires, a person first moves the requirement out
of that design or specification.

By default, only a `@supersedes` that names a declared item gives that
declared item a successor. So when a design `media` supersedes a design
`docs`, the requirement `docs#size` has no successor unless a
`@supersedes` names it. A new design can opt in, in its tag block, to
successors by name:

```markdown
# Media
@design media v1
@supersedes docs#* v3
```

This `@supersedes` retires the design `docs`, and with it each
specification and requirement of `docs`, as `@supersedes docs v3`
does. It also gives successors by name: each declared item `docs#x`
gets the successor `media#x` when `media` holds a declared item `x` of
the same kind. Its revision `v3` pins the old design. The open question
"Revisions as labels" (section 7) has a candidate form of this line,
`@supersedes docs/v3#*`, in which the revision follows the name of the
design that it pins. A person whose names changed meaning writes
`@supersedes docs v3` instead, and one `@supersedes` for each declared
item that has a real successor.

### 3.3 Specifications in code

A specification can live in the comments of code, beside the code that
carries it out. In code, Sinter reads tags in a **run**: a sequence of
comments on consecutive lines, with no blank line and no code between
them. A run **attaches** to the code right after it, such as a module,
a function, or a class (`spec/vocabulary.md` section 2). That code is
the **attached code** of the run. Each language pack says which kinds
of code a run can attach to.

1. **Body.** A `@spec` in a run that attaches to code owns the attached
   code: the **body** of the specification. A `@spec` in a run that
   attaches to no code, and that comes before all the code of its file
   that a run can attach to, owns the whole file. In a repository whose
   files start with a license header, the `@spec` stands in a run of
   its own after that header. A `@spec` in any other run that attaches
   to no code is the finding `misplaced-declaration`.
2. **Membership.** A `@req` in a comment inside the body of a
   specification belongs to that specification. Two bodies hold one
   comment only when a `@spec` stands inside the body of another
   specification, which is the finding `misplaced-declaration` (point
   5). In that case, the `@req` belongs to the nearest body.
3. **Extent.** The extent of a requirement in code, inside a body or
   outside every body, is its block: its tag lines and its trailing
   prose (`spec/vocabulary.md` section 3.1). The extent of a
   specification in code is the block of the specification and the
   block of each of its requirements. Neither extent is the whole run.
   Other comments in the run, and other comments in the body, such as
   the API comment of a function, are no part of either. For the extent
   hash of a specification, Sinter normalizes each of these blocks as
   `spec/vocabulary.md` section 6.1 says, and joins them in the order of
   the file, with one LF between two blocks.
4. **Anchor.** A specification in code declares its full name, and its
   design must exist as a markdown document. The design can be short: a
   heading, its tag block with the marks of its out-of-line items, and
   one sentence of prose are enough. A `@design` in a code comment is
   the finding `misplaced-declaration`.
5. **No nesting.** A `@spec` inside the body of another specification
   is the finding `misplaced-declaration`.
6. **Requirements outside a body.** A requirement in code outside the
   body of every specification declares its full name, as
   `@req ledger#chunk-size v1`, and its design holds it directly.

A sketch in OCaml:

```ocaml
(* @spec ledger#entry-ids v2
   Each entry of the ledger has an id that its own bytes fix. *)
module Entry_id = struct
  (* @req id-form v1
     An id is "e-" and the first twelve lowercase hex digits of a SHA-256. *)
  let of_line line = ...

  (* @req id-retry v1
     A writer whose new id is already in the tip moves ts one second and computes the id again. *)
  let fresh tip entry = ...
end
```

The design `ledger` then holds the mark `@extern spec:entry-ids`.

### 3.4 Names and citations

**Names inside a design.** A citation names a specification or a
requirement inside a design by its full name: the slug of the design,
`#`, and the name, as `ledger#id-form`. The **home design** of a
citation is the design that its place belongs to: the section of a
design, a markdown file of one of its specifications, or, for one of its
specifications in code, the run that holds the `@spec` and the body of
that specification. In such a place, a citation target `#name` names a
declared item of the home design. A citation target with no `#` never
resolves to a name inside a design. So a reader always knows from the
text alone where a name points, and no new name anywhere changes the
meaning of an existing citation. In the section of a design, a
specification and a requirement declare their name alone.

**Custom namespaces.** `/` only joins segments. A slug can hold one or
more segments joined by `/`, as `billing/auth`, and each segment
follows the slug pattern of today. The segments before the last one
are the **custom namespace** of the slug. Every slug can hold a custom
namespace, as requirement `target-reading` reads it: the slugs of
designs, of decision records, of requirements outside every design
(section 3.2), of the finding classes of finding-class files (section
3.6), and of the terms of the later dictionary of terms (section 7). A
name inside a design holds no `/` (section 3.2). A custom namespace
needs no declaration. An external id, such as `gh/42`, has an
**external namespace**, `gh`, which the manifest declares.

**The kind of a target.** Any citation can state the kind of its target,
as `kind:target`. A citation must state the kind only when Sinter cannot
work it out. A stated kind is an assertion, and Sinter checks it. The
kind words are `decision`, `design`, `finding-class`, `req`, `spec`, and
`term`. The words `plan` and `task` are reserved. A target holds a kind
word when the text before its first `:` is a kind word. A kind word
holds no `/`, so an external id whose id holds `:` stays an external id.
A kind word states the kind of what the whole target names. With `#`,
that is the named part: `spec:ledger#entry-ids` says that `entry-ids` is
a specification, `spec:rfc/8259#section-6` says that the section is
specification text, and `term:rfc/8259#value` says that `value` is a
term. The kind word `finding-class` names the finding class of a
finding-class file. A rule, the check of a practice, lives in a decision
record (section 3.6), and a citation names it as that decision record.
The kind word `term` names a term of an external document. When the
design of the dictionary of terms (section 7) exists, `term` also names
a term of that dictionary, and that design decides which set of names
those terms belong to and how a citation names one.

**External ids.** An external id has no revision, no extent, and no
approval. Its kind can be `spec` or `term`, and a citation states that
kind outright: `@cites spec:rfc/8259`. Namespaces have no default kind.
An external id with no kind word is a plain pointer, such as an issue.
An external id can take `#name` to name one part of the external
document: `term:rfc/8259#value`, `spec:rfc/8259#section-6`. Sinter
checks only the form of such a name, because it cannot know which names
an external document holds. So `#` has one meaning everywhere: a name
inside a design or inside an external document.

The manifest declares each external namespace as a table under
`scan.namespaces`. The table has three keys:

- `pattern`: the pattern of the ids of the namespace; required;
- `tracker`: the kind of its tracker; optional; the only value now is
  `"github"`;
- `repository`: the repository on GitHub, as `owner/name`; required
  when `tracker` is `"github"`.

An unknown key, or a value of the wrong type, is an error of the
manifest, and the message gives its place. A `pattern` that can match
an id that holds `#` or `@` is also an error of the manifest.

```toml
[scan.namespaces.gh]
pattern = "[1-9][0-9]*"
tracker = "github"
repository = "sinterworks/sinter"

[scan.namespaces.rfc]
pattern = "[1-9][0-9]*"
```

**How Sinter reads a target.** Sinter reads the tag target of a
declaration or of a citation in this order:

1. It splits off a `#name` at the first `#`.
2. A kind word and `:` at the start give the kind.
3. A target that holds `@` is the finding `invalid-target`. The `@` is
   reserved, and the design of references across repositories will
   give it a meaning (section 7).
4. When the first segment of the rest is an external namespace that
   the manifest declares, the rest is an external id.
5. Otherwise the rest is a slug, with or without segments.

The name after `#` follows the slug pattern of `spec/vocabulary.md`
section 4.1, inside a design and inside an external document. So it
holds no `/` and no second `#`. The name `*` is valid only in the form
of section 3.2: a `@supersedes` in the tag block of a design, whose
target is the slug of another design and `#*`. A name that fails the
slug pattern, and a `*` in any other place, are the finding
`invalid-target`.

A declaration whose first segment is an external namespace that the
manifest declares is the finding `invalid-target`, so an external id
never hides a declared item, and a declared item never hides an
external id. A citation target that starts with `#`, in a place with
no home design, is also `invalid-target`. A `#name` after a target
that resolves to a declared item other than a design is the finding
`wrong-kind`. When the part before `#` resolves to nothing, the target
is the finding `dangling` only, and not also `wrong-kind`: one fault
gives one finding.

The target of an `@ack` keeps its own grammar (`spec/vocabulary.md`
section 7.4). The subject of the finding in that target is written as
the finding reports it, a full name such as `ledger#id-form` included.

**What a citation can name.**

| citation | its target |
|---|---|
| `@satisfies`, `@verifies` | a requirement only |
| `@refines` | a requirement, a specification, or a design |
| `@cites` | any declaration, a specification and a design included, or an external id |
| `@supersedes` | a declaration of the same kind as its source; a specification can supersede a specification; in the tag block of a design, the declared items of another design by the form `#*` of section 3.2 |

A citation whose target is of a kind that the citation cannot take is
the finding `wrong-kind`. For `@satisfies` and `@verifies`, this keeps
coverage, in the sense of tests and code, exact: each such citation
names one requirement. A stated kind that differs from the kind of the
target is also `wrong-kind`, and so is an external id with a kind other
than `spec` or `term`. A citation that
states `plan` or `task` is `invalid-target`. No citation names a plan
or a task: plans and tasks live in the ledger, and Sinter resolves
every citation from the tree alone. The link from work to text goes the
other way, from a task to the requirements that it promises.

**The shared namespace.** Designs and decision records keep one shared
namespace of slugs, so a citation of either needs no kind word. A
requirement outside every design also takes its slug from this
namespace, and it is always the finding `req-outside-design` (section
3.2). The finding classes of finding-class files keep their own set of
names, so a citation of one states the kind `finding-class`.

**Classes that change.**

- `dangling` reports every citation whose target does not resolve,
  except the citations that `renamed` or `invalid-target` reports.
  Today `dangling` also leaves out each citation whose target a claim
  promises to declare (`spec/algebra.md` section 9). That exception
  goes, because claims go.
- `unbumped` and `wrong-source` treat `spec` as a kind of declaration.
- `untraced` reports requirements only. A design and a specification
  are never `untraced`, because no `@satisfies` or `@verifies` can name
  them.

### 3.5 Approval

An approval in the ledger binds to the exact text of one **subject of
approval**, the unit that a person approves: its name, its revision,
and its extent hash (`spec/ledger.md` section 5.2). A decline names one
subject of approval and binds to its extent hash alone, with no
revision (`spec/ledger.md` section 7). The subjects of approval are:

- the prose of a design;
- a specification as a whole, which includes its requirements;
- a requirement that a design holds directly, outside every
  specification;
- a decision record.

A requirement inside a specification counts as approved when its
specification is approved. So an edit of such a requirement needs one
new approval, of its specification. A design counts as approved when
its prose, each of its specifications, and each requirement that it
holds directly are approved. No entry records that state; Sinter
computes it.

Before it asks the person, the approval command shows the change of the
text of each subject of approval since its **latest approval entry**: of
the `approval` entries whose `subject` names the subject of approval,
the one with the greatest `seq`, whatever its revision and its extent
hash. So the person reads only the changed requirement of a
specification. The text of that entry is the extent of the subject of
approval in the tree of the commit that the field `head` of the entry
names. The command shows the whole text when the ledger holds no
approval entry of the subject of approval, when the clone does not hold
that commit, or when that tree does not hold the subject of approval
with the extent hash of the entry.

A subject of approval is **awaiting approval** when its kind needs
approval, it is in force, and it is not approved. The approval command
can approve a whole design in one act. Given a design, it writes one
approval entry for each subject of approval of the design that is
awaiting approval. Given one specification, or one requirement that a
design holds directly, it approves that subject of approval alone.
Given a requirement inside a specification, it refuses, and names the
specification to approve. Each entry binds to the text of one subject
of approval, so a later edit of one specification ends only the
approval of that specification.

The key `proof.req` decides whether specifications and requirements
need approval. The key `proof.design` decides whether the prose of
designs needs approval. The key `proof.decision` keeps its meaning.

- `unapproved-req` reports a `@satisfies` or a `@verifies` of a
  requirement that does not count as approved, when `proof.req` is
  `"approval"`. It does not report a citation of a requirement outside
  every design, because that requirement is already the finding
  `req-outside-design` (section 3.2).
- `awaiting-approval` reports each subject of approval that is
  awaiting approval. So `proof.design` shows its effect in this
  finding.
- `declined` reports each subject of approval with a live decline.

### 3.6 Decision records and rules

A decision record states one standing practice of the project, or one
choice with its reason. A long weighing of alternatives belongs in a
design.

A decision record holds these parts:

- **required:** a title that states the decision in one line; the tag
  block, with `@decision <slug>` and one sentence that states the
  decision; a `@cites` line for the design or the decision record that
  the decision rests on, whenever one exists; and a section "Reason",
  of a few sentences;
- **suggested,** written only when it has real content: a section
  "Alternatives considered", with the alternatives that someone put
  forward and weighed, each with the reason that it lost; a section
  "Context", when no cited design holds the context and the reason
  cannot be understood without it; and a section "Consequences", when
  the decision commits the project to something that the decision
  itself does not say.

The skill `/sinter:decision` tells an agent never to write a suggested
section to fill the form, and never to invent an alternative, a piece
of context, or a consequence. The required and the suggested parts are
a form that people and the skill follow when they write. Sinter does not
check them.

A sketch:

```markdown
# Keep plans and tasks in the ledger
@decision ledger-work
@cites work-model
Plans and tasks live only in the ledger, never as files in the tree.

## Reason

A plan file needs a pull request for each change of its scope, and task files
conflict when several branches add tasks at the same time.
```

**A practice with a check.** A **rule** is the check of a practice. A
decision record of a standing practice can carry its rule in TOML
front matter, in the form that rule files use today
(`spec/manifest.md` section 14). Such a decision record is the rule
itself. The front matter of a decision record belongs to the extent of
its `@decision`, as the front matter of a rule file belongs to the
extent of its `@rule` today (`spec/manifest.md` section 14, part 4).
When a practice gets a check later, its decision record gains the front
matter, and its revision rises. So each practice keeps one home, one
reason, and one revision for its whole life. An approval of the
decision record includes its check.

A rule file then holds only a finding class that a repository defines,
so it becomes a **finding-class file**. The tag word `@finding-class`
declares it, in place of `@rule`, and a citation of it states the kind
word `finding-class` (section 3.4).

In the algebra (`spec/algebra.md` section 3), the kind `finding-class`
takes the place of the kind `rule` for the facts of finding-class files.
The facts of the rules that live in decision records, the selector
`rule(n)`, the kind `rule` in the expression of `wrong-source`, and the
origin edge of a rule depend on the open question "The design of rules"
(section 7).

Until that design exists, Sinter evaluates no rule. So `unmet-rule`
reports nothing, and the check in the front matter of a decision record
changes no finding: it is only part of the extent of the decision
record. A finding-class file whose front matter holds a rule in place of
a finding class is an error of the file, as an unknown key is
(`spec/manifest.md` section 14, part 7).

**Existing decision records.** When a design takes up the question that
an existing decision record decides, and holds the weighing of its
alternatives, the same pull request revises that decision record in
place into the form above. The decision record keeps its slug and cites
the design. When the design changes the choice, a new decision record
supersedes the old one (record `revise-or-supersede`). A decision record
that no design takes up stays as it is.

A decision record is never deleted (`spec/vocabulary.md` section 8.3),
with one exception for this repository. Before the first release of
Sinter, version 0.1, this repository can delete a decision record that
a design wholly absorbs, or that does not fit the form above, after
anything worth keeping moves into a design. The **maintainer**, the
person who directs the Sinter project and merges its pull requests,
approves the list of decision records to delete, each with its reason,
before they are deleted. The specification text does not change; this
repository makes a one-time exception to it before version 0.1.

### 3.7 Tasks

A **task** is one piece of work that one agent or one person can finish
alone. Tasks are the main unit of work. A person or an agent defines
each task in Sinter, and a task can refer to an **external item**: an
issue or a ticket of an external tracker. A task exists apart from any
plan. A task belongs to at most one plan. A task holds no plan.

A task has:

- a **task id**, which Sinter generates when it creates the task, and
  which never changes;
- a **display name**, which people and agents can change, and which can
  be empty when the task has an external item;
- its **paths**: the paths that the task can change, as a path set of
  globs, with `!` to leave paths out (`spec/manifest.md` section 7.2);
  a task with no paths covers no change;
- its **promises**: the requirements that it satisfies or verifies,
  each as a pair of a word, `satisfies` or `verifies`, and the full
  name of a requirement;
- at most one external item, which the task names by its external id;
- at most one **plan**;
- the tasks and plans that it **waits for**.

A task has no description. The text that says what to build lives in
the design that the task carries out, or in its external item.

The **definition** of a task is the set of all these parts except its
id: its display name, its paths, its promises, its external item, its
plan, and its waits. A change of any part gives the task a new
definition, which a new entry of the ledger records (section 3.11). The
**current definition** of a task is the latest of its accepted
definitions; section 3.11 says when a definition is accepted. In the
same way, the definition of a plan is the set of all the parts of a plan
that section 3.8 lists, except its id.

**Ids.** A task id is `t-` and twelve lowercase hex digits from a random
source, for example `t-3f2a9c1d7e0b`. A plan id is `p-` and twelve
digits. Sinter checks a new id against its copy of the ledger and draws
again on a clash. A replay checks it again, and drops the creation of a
task or a plan whose id the remote already holds. The id is a field of
the entry that creates the task or the plan, so a replay does not change
it, and an agent can name the task in a commit before its push wins. A
command takes a **prefix** of four or more digits in place of a full id,
written with the **kind letter**, `t` for a task or `p` for a plan, and
the hyphen, such as `t-3f2a`, when exactly one task or plan of that kind
starts with it. Sinter prints the shortest prefix that is unique in its
copy of the ledger, and never fewer than six digits. Text that lasts
holds the full id: a delivery line, a `Task:` line, and each field of a
ledger entry.

**States.** A task is open, delivered, done, or abandoned.

| state | meaning |
|---|---|
| open | defined, and no delivery or judgment ends it yet |
| delivered | a commit with its delivery line reached the default branch, and the delivery did not make the task done; a person looks at it |
| done | a delivery line whose six characters are the start of the current task hash reached the default branch with every promise met, or a person recorded the task as done |
| abandoned | a person abandoned the task |

| move | from | to | who |
|---|---|---|---|
| create | — | open | an agent or a person |
| create, when the ledger already holds a `delivered` entry for the task | — | delivered | an agent or a person; the fold sets the state (section 3.9) |
| a delivery line whose six characters are the start of the current task hash (section 3.9), with every promise met | open, delivered | done | the fold, from the `delivered` entry of the job on the default branch |
| any other delivery line | open | delivered | the fold, from the `delivered` entry of the job on the default branch |
| record as done | open, delivered | done | a person |
| abandon | open, delivered | abandoned | a person |

Section 3.9 gives the steps of the fold for a `delivered` entry.

A task is **unfinished** while it is open or delivered. Done and
abandoned are final. A task with no promise meets every promise, so its
first delivery line whose six characters are the start of its current
task hash makes it done. An unfinished task stays unfinished when a
person abandons its plan.

The state of a task records a piece of work that happened. It does not
say that the code stays correct. The findings show the current health
of a requirement: a suspect citation, a failed test, a requirement that
no code satisfies. Rework of a done task is a new task. More work on a
delivered task can still make it done, through a later delivery.

**Ready.** A task is **ready** when it is open, each task and plan that
it waits for is done, each task and plan that a plan which holds it
waits for is done, at any level, and the ledger holds no `delivered`
entry for the task. The last condition follows from the first. A task
for which the ledger holds a `delivered` entry is never open: the entry
makes an open task done or delivered, and a task whose first definition
comes after the entry starts delivered (section 3.9). The done state of
a plan is not final (section 3.8). So a wait for a plan can be met and
later stop being met, and a ready task can stop being ready. A wait for
an abandoned task or plan is never met. `sinter status` names the
abandoned task or plan that blocks the task. A person or an agent then
removes the wait, or a person abandons the waiting task.

Sinter records no start of a task, and has no concept of who works on
which task. Assignment between people belongs to the external tracker.
Coordination between agents belongs to the harness, or to a separate
tool that coordinates agents and their working copies.

**Promises.** A promise of a task is met as a promised `@satisfies` or
`@verifies` of a step is met today (`spec/vocabulary.md` section 10.5),
with the paths of the task in place of the scope of the step. A promise
of a task of the change (section 3.10) that only a citation outside the
paths of the task would meet is the finding `promise-outside-paths`. The
job on the default branch records once, for each promised requirement,
whether its promises are met in the tree of the head of its run, with
the test evidence of that run (section 3.9). Sinter judges the promises
against that tree, never against the current tree, so a done task stays
done when the tree changes later.

**Branches.** Tasks are global: the ledger is one ref for the whole
repository. A task that an agent defines on a branch exists for every
branch at once. Each entry records the branch and the commit of its
writer in its fields `branch` and `head`. One fold reads these fields:
the start of a run of the job on the default branch (`spec/ledger.md`
sections 2.3 and 8.4). No state of a task or of a plan depends on them.
`spec/ledger.md` section 8.4 gives two **start rules**, and the first
start rule that gives a `head` decides the start. Today, start rule 1
takes the `head` of the latest `delivered` or `completed` entry, which
only the job on the default branch writes. Under this design, the
`completed` entry goes, so start rule 1 takes the `head` of the latest
`delivered` entry (section 3.9). Start rule 2 takes the `head` of the
first entry whose `branch` is the default branch, from any writer. Start
rule 2 stays as it is, and it decides only where a run starts when no
`delivered` entry gives a start, as for the first run. After the fold
gives the start, the job on the default branch compares the head of its
run with the start of rule 1. That comparison reads git's commit graph,
so it is a step of a command, and no fold. Commands such as
`sinter status` and `sinter ledger log` filter entries by `branch`. A
task that depends on the work of a branch waits for the task that the
branch delivers. When a branch is given up, the tasks that it defined
stay open. A ready task can promise a requirement that the current tree
does not hold, for example one that a branch is still writing. Its
output record and `sinter status` flag that case, and the ready
condition stays as it is.

### 3.8 Plans

A **plan** says how a set of tasks gets done. It has a plan id, a
display name that people and agents can change, the plan that holds it,
the tasks and plans that it waits for, and the requirements,
specifications, and designs that it **carries out**. Its **parts** are
the tasks and the smaller plans whose definitions name it and that have
not left it. A plan is part of at most one larger plan. A plan is
**open** while it is neither done nor abandoned.

No one approves a plan. A plan only says how work gets done. The person
who directs the work agrees to the plan outside Sinter, by starting the
work. Sinter records no approval of a plan and no start.

Plans have two relations. **Composition:** a plan holds tasks and
smaller plans. **Order:** a task or a plan waits for another task or
plan. A wait of a plan applies to each of its tasks, at every level.

- A plan is **done** while it has at least one part and every part is
  done. Sinter computes this state again at each entry; no entry
  records it. A plan with no part is not done. A done plan is not
  final: a new part that is not done makes it open again. So a person
  or an agent can add tasks to a plan as the work goes on, also after
  its first tasks are done.
- A person abandons a plan. Each of its parts that is not done then
  leaves it, smaller plans included, and a later plan can take them.
  Its done parts stay, as its history.
- An abandoned task leaves its plan, so that the plan can still become
  done.
- When a task or a plan leaves a plan, the fold clears its plan: Sinter
  shows it with no plan, and its next definition names no plan, or a
  plan that is not abandoned.
- An abandoned plan is final. Sinter refuses a definition that adds a
  part to it, or changes it.
- What a plan carries out gives context to its tasks (section 3.14) and
  can account for a requirement (section 3.16). It makes nothing done
  and nothing ready.

**Cycles.** Sinter refuses each definition after which composition holds
a cycle, order holds a cycle, or the combined graph holds a cycle. The
**combined graph** is the union of these edges:

- the edges of composition: from each plan to each of its parts;
- the edges of order: from each task to each task and plan that it
  waits for, and from each plan to each task and plan that it waits
  for;
- from each task to each task and plan that a plan which holds it waits
  for, at any level.

For example, a task that waits for the plan that holds it makes a
cycle in the combined graph: the plan is done only when the task is
done, and the task waits until the plan is done.

### 3.9 Delivery

The ledger stores only what Sinter cannot compute. Whether a task is
done comes from evidence: a commit on the default branch with its
delivery line.
The ledger holds definitions, the judgments of people, and the evidence
that the job on the default branch records.

**The delivery line.** A commit names each task that it completes with
one line:

```
Delivers: t-3f2a9c1d7e0b 05ef56
```

The **six characters** of the line, after the task id, are the start of
the **task hash**: the SHA-256 of the canonical JSON (`spec/jsonl.md`
section 2) of the paths and the promises of a definition of the task.
The task hash does not include the display name, the external item, the
plan, or the waits, because those do not change what a delivery says
that it does. So the six characters name the paths and the promises that
the commit carries out, and not one definition: several definitions of a
task can share one task hash, for example after a change of the display
name alone. The **current task hash** of a task is the task hash of its
current definition. A delivery line **counts for** a task while the
ledger holds the task, the task is unfinished, and the six characters
are the start of its current task hash. When an agent changes the paths
or the promises of the task after the commit, the line no longer counts
for the task, and the check shows `stale-delivery`. `sinter task show`
prints the line to copy. A commit can carry several delivery lines. The
**finishing commit** of a delivery line is the commit whose message
holds it.

**The `Task:` line.** A commit that does part of a task without
finishing it names the task with a line `Task: t-3f2a9c1d7e0b`. The
line carries no hash: it states no result, and it only says which task
allows the change.

**The checks of a branch.** The delivery classes keep the tiers that
they have today at the gates `review` and `merged`:

- `stale-delivery` reports each line of a commit message that starts
  with `Delivers: ` and does not count for a task, the old form of a
  step included; it is `block` at `review`;
- `delivery-on-unmet-task` reports a delivery line that counts for a
  task with a promise that is not met; it is `block` at `review`;
- `missing-delivery` reports an unfinished task whose promises the diff
  makes met, when no delivery line of the change counts for it: each
  promise is met in the tree of the last commit, and some promise is
  not met in the base. It is `block` at `review`;
- `delivery-without-change` reports a task for which a delivery line
  of the change counts, when no hunk of the change lies in its paths;
  it is `warn` at `review`.

When no test evidence exists for the tree, `delivery-on-unmet-task` and
`missing-delivery` read a promised `verifies` of a task as
`spec/algebra.md` section 9.2 reads a promised `@verifies` of a step:
it counts as met when a `verifies` citation with its target exists
inside the paths of the task, its source is a test, its target
resolves, and it is not suspect.

**The job on the default branch.** The ledger records facts, and Sinter
computes states from them. The job on the default branch stores no state
that it computed. The **range** of a run is the set of commits that the
run reads (`spec/ledger.md` section 8.4). For each delivery line of a
task in the commits of its range, the job on the default branch appends
one `delivered` entry, whatever the state of the task. The common field
`head` of the entry holds the head of the run. The **first-parent line**
of the default branch is the set of commits that its head reaches when
it follows only the first parent of each commit. The entry holds only
facts:

- `subject`: the task that the line names;
- `hash_prefix`: the six characters of the line, as written;
- `commit`: the finishing commit of the line;
- `merge`: the commit of the first-parent line of the default branch
  that brought the finishing commit to the default branch. After a
  squash merge, `merge` is the finishing commit itself;
- `revisions`: one **element** for each requirement that the current
  definition of the task promises, with its full name, its revision
  `rev` in the tree of `head`, and `met_at_head`. The value of
  `met_at_head` says whether each promise of that requirement is met,
  as section 5.5.4 says, with the test evidence of the run, in the tree
  of `head`. For a promised requirement that the tree of `head` does
  not hold, the element holds its full name, no `rev`, and
  `met_at_head` false. For a task that the ledger does not hold at the
  run, `revisions` is empty.

The job on the default branch observes each promised requirement in the
tree of `head`, because the test evidence of the run covers only that
tree. The test evidence exists only during the run, so Sinter cannot
compute `met_at_head` again later. The entry holds no field that says
whether the task is done, and no field that says whether the line was
stale. The job on the default branch writes no entry whose fields
`subject`, `commit`, and `hash_prefix` equal those of an entry that the
ledger holds. It writes no entry that closes a plan. Start rule 1
(section 3.7) then reads only `delivered` entries, because the
`completed` entry goes.

**The fold of a `delivered` entry.** For each `delivered` entry, the
fold takes the current definition of the task at that point of the
fold: the definition that was current when the entry was appended. It
compares the six characters of the entry with the start of the task
hash of that definition. Then:

1. For a task that is done or abandoned, the entry is a recorded fact
   that changes nothing.
2. For a task that the ledger does not hold at that point of the fold,
   the fold keeps the entry. When the first definition of the task
   comes later, the task starts in the state delivered, not open,
   because the run could not judge its promises. `sinter status` lists
   it with the other delivered tasks, which a person looks at.
3. When the six characters are the start of that task hash, and
   `met_at_head` is true for each element of `revisions`, the task
   becomes done.
4. Otherwise the task becomes delivered, and a person looks at it. When
   the six characters differ from the start of that task hash,
   `sinter status` lists the task as "changed after its finishing
   commit".

The specification of the ledger fixes these steps, because the state
of an old task depends on them.

### 3.10 Tracing a change to its task

The **path check** compares each hunk of a change with the work that
allows it. It takes the place of the plan check of `spec/manifest.md`
section 9.1, which compares the hunks with the scopes of the open plan
files. The path check compares them with the paths of the tasks of the
change. The **tasks of the change** are the tasks that the commit
messages of the change name in `Delivers:` lines and in `Task:` lines,
and no other tasks. A delivery line gives the change its task whether or
not it counts for the task, when the ledger holds the task and the task
is unfinished. So a line whose six characters are not the start of the
current task hash still gives the change its task, and `stale-delivery`
reports the line (section 3.9). At the gate `review`, with or without
`--preview`, the findings come from the commits only, and no finding
reads work that is not committed (section 3.14).

A hunk of the change is the finding `unplanned-change` when all of these
hold: the paths of none of those tasks cover it; no exempt path holds
it; no triggered rule covers it (`spec/algebra.md` section 6.8); and it
is no mechanical repair (`spec/algebra.md` section 9.1). Which rule is
triggered, and which paths it applies to, depend on the design of rules,
an open question (section 7). Until that design exists, no rule covers a
hunk. So every change names a task, unless an exempt path covers it or
it is a mechanical repair. A change that a decision record or an issue
allows also needs a task, and that task can refer to the issue. A
`Task:` line or a delivery line that names no unfinished task gives the
change no task. A `Task:` line that names an unknown or a finished task
gives no finding of its own, because the hunks that it would allow
already show as `unplanned-change`.

The same tasks decide one more finding class and one exit code:

- `unmet-promise` reports the promises of the tasks of the change that
  are not met. It keeps its tiers of today: `off` at `review`, and no
  tier at `merged`;
- `sinter status --done` exits with code 0 when every promise of every
  task of the change is met. It reads the commits only, as the check at
  the gate `review` does.

An agent can change the paths of a task as it changes any other part of
a definition, with no pull request. The summary of the change shows
each task of the change with every definition of it, from whatever
branch the definition was written, and each other definition whose
field `branch` names the branch of the change (section 3.15).

**The declared task.** `sinter declare --task <id>` records a task in
the session of the agent, in `.sinter/` of its working tree. The
declared task gives no allowed paths, and it changes no finding and no
state. Sinter uses it only to narrow the brief to that task. This
design keeps the principle of `docs/design-notes.md`
section 6.1 for the active step: a declaration in the session can only
narrow what the brief covers, and it never allows a change.

**In the algebra.** Tasks and plans become facts of the universe
(`spec/algebra.md` section 2), folded from the ledger, with the kinds
`task` and `plan`. `scope()` of a task gives the located facts and the
hunks inside its paths. The tasks of the change are a selector of the
universe, with the meaning above. The kinds `step`, `promise`, and
`claim` go, and the kind `spec` joins.

### 3.11 The ledger and its writers

Plans and tasks live only in the ledger, never as files in the tree.
People and agents author them with the command line or through MCP
tools.

**Entries.** The sketch shows only the fields of each kind:

```json
{"def":1,"item":"gh/42","kind":"task","name":"Read task entries","paths":["lib/ledger.ml","test/**"],"plan":"p-5b1c0a9d2e11","promises":[{"target":"ledger#id-form","word":"verifies"}],"subject":"task:t-3f2a9c1d7e0b","waits":["t-81c0de44a1f0"]}
{"carries":["work-model"],"def":1,"kind":"plan","name":"Tasks in the ledger","subject":"plan:p-5b1c0a9d2e11","waits":[]}
{"commit":"4b7a10…","hash_prefix":"05ef56","kind":"delivered","merge":"9d2e11…","revisions":[{"met_at_head":true,"rev":2,"target":"ledger#id-form"}],"subject":"task:t-3f2a9c1d7e0b"}
{"kind":"done","note":"…","revisions":[…],"subject":"task:t-81c0de44a1f0"}
{"kind":"abandoned","reason":"…","subject":"plan:p-5b1c0a9d2e11"}
```

A plan that another plan holds names it in the field `plan`, as a task
does. A field with no value is left out, and an empty array is written
`[]`. The field `note` of a `done` entry is optional. The field
`reason` of an `abandoned` entry is required, for a task and for a
plan.

The field `revisions` of a `done` entry holds one element for each
requirement that the current definition of the task promises, with its
full name and its revision `rev` in the tree of the commit that the
writer had checked out, which the common field `head` names. For a
promised requirement that this tree does not hold, the element holds its
full name and no `rev`. The field `revisions` holds no `met_at_head`,
because a person, not a run of the job on the default branch, records
the task as done.

| class | kinds | written by |
|---|---|---|
| definitions | `task` and `plan`: the whole definition of one task or one plan, with its definition number `def` | an agent or a person |
| judgments | `approval` and `decline` of a subject of approval (section 3.5); `done` of a task; `abandoned` of a task or a plan | a person only |
| evidence | `delivered` of a task | the job on the default branch |
| repair | `void` | a person only |

The field `subject` of an entry names what the entry is about, by its
kind and its full name or its id: `design:billing/auth`,
`spec:ledger#entry-ids`, `req:ledger#chunk-size`, `decision:plan-ids`,
`task:t-3f2a9c1d7e0b`, `plan:p-5b1c0a9d2e11`.

**Definitions.** A definition entry holds the whole definition of one
task or one plan. Its **definition number** is 1 for the entry that
creates the task or the plan, and one more for each later definition. A
definition is **accepted** when all of these hold:

1. its definition number is one more than that of the last accepted
   definition of the same task or plan, or 1 when the task or the plan
   has no accepted definition;
2. it does not define a task that is done or abandoned, or a plan that
   is abandoned;
3. the plan that it names, when it names one, exists and is not
   abandoned;
4. each task and plan that it waits for exists;
5. it makes no cycle (section 3.8).

A definition that is not accepted changes nothing. It is a fault of the
fold, not of the format. The command that writes a definition refuses
one that would not be accepted. So when two writers change one task at
the same time, the second change is not accepted, and the replay tells
its writer, who makes the change again on top of the first. No change
is lost in silence.

**Who writes what.** The requirement `ledger-writers` changes:

- The commands that write definitions run for a person or an agent, on
  the command line or through MCP.
- The commands that write judgments run for a person only. They read
  their confirmation from the controlling terminal, and they refuse
  with exit code 4 when an agent marker is set.
- Only the job on the default branch writes evidence.
- A repair refuses under an agent marker, as it does today.
- No definition makes a task done, or approves or declines a subject of
  approval.

Judgments come only from a person, and the commands that write them
enforce it. Definitions come from a person or an agent, and the field
`agent` tells them apart. A reader does not check who wrote an entry.
The threat model of Sinter assumes that the agent cooperates
(`docs/design-notes.md` section 1).

The design notes name a way to harden the ledger: put its ref under the
push rules of the host (`docs/design-notes.md` section 6.4). Under this
design, agents push definitions to the same ref, so the push rules no
longer keep agents apart from people. Signing stays the way to harden
the ledger (section 7).

**Authors.** Every entry names in the field `by` the person who wrote
it, or who runs the agent that wrote it, in the form `Name <email>` that
git uses, from the settings `user.name` and `user.email` at the time of
the write. An entry of the job on the default branch holds the identity
that git reports in CI. The CI workflow sets git's identity (`user.name`
and `user.email`) for the job on the default branch. A command refuses
when git has no identity, as `git commit` does. When an agent marker is
set, a command that writes a definition also requires the identity of
the agent, in the same form, and writes it in the field `agent`. The
identity comes from the environment variable `SINTER_AGENT`, which the
harness sets once, or from the option `--agent`, which wins over the
variable. Without it, the command refuses. The MCP server reads
`SINTER_AGENT` when it starts, and it refuses each call of a tool that
writes a definition when the variable gives no identity. So a definition
that the MCP server writes always carries `agent`. A judgment never
carries `agent`. The ledger keeps every entry, so the email that git
reports stays in it.

**How an entry reaches the remote.** The remote is `origin`, as
`spec/ledger.md` section 10.3 already assumes. A command that writes a
definition fetches the ledger ref of the remote, appends its entries,
and pushes. When the push loses, it replays. A fetch or a push that
fails because the remote cannot be reached counts as a lost try.

A replay covers every unpushed entry of the clone, in the order of
`seq`, and applies to each entry the steps of its kind. A replay of a
definition asks no one. It checks the definition again against the new
tip. It drops the definition, with a message to the writer, when the
definition would not be accepted at the new tip, by the five conditions
above.

When the replay drops a definition, it also drops every later unpushed
definition of the same task or plan, and tells the writer of each.
Every other definition gets a new `seq` and a new entry id, and keeps
all its other fields.

A replay of a judgment follows `spec/ledger.md` section 3.2, with one
exception under an agent marker:

- A replay that needs to ask no one moves a judgment unchanged, except
  its `seq` and its entry id. That is not a new judgment.
- A judgment **needs the person** when the replay would ask the person
  again or would drop the judgment (steps 4 and 5 of `spec/ledger.md`
  section 3.2).
- When no agent marker is set, the replay asks the person again at the
  terminal, as today, and it refuses the judgment when no terminal
  exists.
- When an agent marker is set, a push or a replay that meets an
  unpushed judgment that needs the person stops before that judgment.
  Every unpushed entry then stays in the clone. The command warns that
  a person must run `sinter ledger push` at a terminal, and it exits
  with code 0.

The commands that write judgments keep what that specification says.

A push that wins moves entries to the remote and writes no entry. So an
agent can run `sinter ledger push` to carry the judgments of a person to
the remote with no terminal.

A command that writes a definition tries five times. Five is a fixed
number: it limits the time that a command waits for the remote.
Measurement 2 of section 6 can change the design. When the tries run
out, or the clone has no remote, the entries stay in the clone. A
warning and a flag in the JSON output say so, and the exit code is 0,
because the write itself succeeded.

With the option `--local`, a command writes only in the clone, and the
push happens later, with `sinter ledger push`, which pushes and replays
as above. Sinter keeps the ref
`refs/sinter/remotes/origin/ledger`, which records the tip of the
remote at the last fetch or push. When the local tip holds entries
beyond that tip, or the two have diverged, the ledger is out of sync.
Sinter decides the **state of sync** in this order:

1. When the clone holds no ledger ref, the state is `absent`.
2. Otherwise, when the ref `refs/sinter/remotes/origin/ledger` is
   absent, as in CI, Sinter cannot compare the two tips, and the state
   is `unknown`, not out of sync.
3. Otherwise, when the ledger is out of sync, the state is
   `out-of-sync`.
4. Otherwise the state is `in-sync`.

`sinter status`, the commands that write the ledger, and `sinter check`
report a ledger out of sync. `sinter check` reports it as a warning.
The warning also says that CI does not see the entries that the clone
has not pushed until `sinter ledger push` runs. The warning does not
change the exit code of `sinter check`, with or without `--preview`
(section 3.14). When the state is `absent`, `sinter check` warns that
it found no ledger, and its help gives the command that fetches the
ledger from `origin` (`spec/ledger.md` section 10.3). `sinter check`
writes each of these two warnings, a ledger out of sync and an absent
ledger, as a line on standard error. The JSON `summary` record
(`spec/jsonl.md` section 10) gains the field `ledger_sync`, which holds
the state of sync: `in-sync`, `out-of-sync`, `unknown`, or `absent`.
Sinter cannot see entries that the remote has and the clone has not
fetched.

All working trees of one clone share the ledger ref, so the agents that
work in one clone see each definition at once.

**The decision `agent-statements`.** The record `agent-statements`
changes to this text:

> An agent's statement changes a state of Sinter in one of two ways
> only:
>
> 1. as a line of the change — a line of the diff, or a line of a
>    commit message such as a delivery line or a `Task:` line — that
>    names what it is about by a hash, a revision, or an id; or
> 2. as a definition in the ledger, which names work and records no
>    judgment.
>
> The person who merges a change can see both: the lines in the change
> itself, and, in the summary of the change, every definition of the
> tasks of the change and every definition written from its branch. A
> statement that exists only outside these, such as an agent's message
> that its work is done, changes no state. The task that an agent
> declares with `sinter declare --task` changes no state. Sinter uses it
> only to narrow the brief.

### 3.12 External trackers

A task can refer to one external item by its external id, and one
external item can serve several tasks.

- Content that Sinter reads from a tracker, such as a title or a state,
  lives only in the index file (section 3.13), never in the ledger. The
  ledger is permanent, and refreshed copies of the edits in a tracker
  would make it grow too fast.
- Sinter does not write to a tracker.
- No check, and no state of a task or a plan, depends on content from a
  tracker. A command reads that content only to show it, as
  `sinter status`, `sinter task list`, `sinter brief`, and the MCP tools
  do. So every state and every check stays a function of the snapshot
  and the ledger, as the record `ledger-event-log` says. That record
  gains the content of trackers as an input for display only.

The command `sinter tracker fetch` reads each external item that a task
names and writes its title, its state, its address, and the time of the
read into the index file. It writes nothing to the ledger. It supports
GitHub first, and other trackers when a project needs them. It finds the
tracker of an external namespace in the table of that namespace (section
3.4). It takes its token from the environment variable `GH_TOKEN`, or
else from `GITHUB_TOKEN`, and never from the manifest. `sinter check`
never reads the network.

No command copies the title of an external item into the display name of
a task. A task with an external item and no display name shows the title
from the index file, or its external id when the index file holds no
title. A person or an agent can still write a display name of its own.

### 3.13 Sinter's index

**Sinter's index** is all the facts that Sinter knows. It holds the
facts of one run, which `spec/algebra.md` section 2 calls the universe:
the facts of the tree that the check reads, of the base, of the commit
messages of a change, of the ledger, of the test evidence, and of the
session. It also holds the content of trackers. The **index file**
`index.db`, at `<git common dir>/sinter/index.db`, holds the parts of
Sinter's index that all working trees of one clone share: the **states
of the ledger**, which the folds compute from its entries, such as the
state of each task; and the content of trackers. It sits in the common
folder of the git repository, beside the ledger ref.

The principle "No database" of `docs/design-notes.md` section 9
changes: the index file is a SQLite database. For the states of the
ledger, it is a cache that Sinter can always build again from the
ledger. For the content of trackers, it is the only copy, which
`sinter tracker fetch` can always read again, and which is for display
only. A person or a tool can delete the file at any time.

The index file meets the five conditions of section 2.1:

1. The ledger is the only truth for the states of the ledger. The index
   file takes no write that is not in the ledger, and the content of
   trackers comes only from `sinter tracker fetch`.
2. The index file records the commit of the ledger tip that it
   reflects, and the greatest `seq` of that tip. It also records that
   this tip passed the check of the tip (`spec/ledger.md` section
   13.3). One commit id names the same objects, so a command that
   answers from the index file for that same tip does not repeat the
   check. When the recorded tip is an ancestor of the current tip, the
   command first checks that the newer commits only add lines: they
   change and remove no line of the recorded tip. When they only add
   lines, the command runs the check of the tip only over the lines
   that they add, against the state that the index file records. When
   the recorded tip is not an ancestor of the current tip, or the newer
   commits change or remove a line, the command runs the whole check of
   the tip, and builds the states of the ledger again (condition 3). The
   check of the history at the gate `merged` (`spec/ledger.md` section
   13.4) does not change.
3. Before each read, a command compares the current tip with the
   recorded tip. When the recorded tip is the current tip, or an
   ancestor of it whose newer commits only add lines (condition 2), only
   appends happened since. The command then reads only the chunks that
   the newer commits change, and applies the entries with a `seq` above
   the recorded one. Otherwise it builds the
   states of the ledger again. A repair rewrites the history of the
   ledger (`spec/ledger.md` section 14), and so does a replay of entries
   that were not pushed, so both cause a rebuild. A clone that lacks the
   recorded commit, such as a shallow clone, builds them again too. This
   comparison is a step of a command, not a fold, so it can read the
   history of git. A build of the states of the ledger alone keeps the
   content of trackers.
4. The index file records the version of its layout. A different
   version makes a command build the whole file again, and the content
   of trackers is then empty until the next `sinter tracker fetch`.
5. The test plan measures a full build (section 6).

The commands that read the index file, other than `sinter check`, build
it when it is absent and bring it up to date before they read it. These
are `sinter status`, the commands `sinter task` and `sinter plan`,
`sinter brief`, `sinter tracker fetch`, and the MCP tools. Two processes
that use the index file at the same time rely on the locking of SQLite.
When a command cannot take a lock within five seconds, it computes the
states of the ledger from the ledger, and it shows no content of
trackers, as when the index file holds none. In that case,
`sinter tracker fetch` writes nothing, says that another process holds
the index file, and exits with code 3. Five seconds is a fixed number:
it limits the time that a command waits for another process, and the
states of the ledger that a command computes from the ledger are the
same states. A later measurement can change the design. Each state of
the ledger that a command reads from the index file equals the state
that the folds compute from the ledger.

A build never reads the network. After a build of the whole file, the
content of trackers is empty until the next `sinter tracker fetch`.
`sinter status` says when the index file holds no content of trackers,
and otherwise gives the time of the oldest read.

`sinter check` uses the states of the ledger from the index file only
when the file exists, its recorded tip is the current tip, and its
layout version is the version that the tool writes. Otherwise it
computes them from the ledger. It never writes the index file. The
option `--no-cache` makes it ignore the index file.

Sinter reads SQLite through the bridge in `bridge/`, with the Rust
crate `rusqlite` and the SQLite library that the crate carries, so the
build needs no system library. The change that adds SQLite to the
bridge also adds a decision record for that choice.

### 3.14 The harness

Sinter gives the harness the tasks that are ready, with the context that
an agent needs. The harness gives Sinter no state of the work: no
start, no assignment, and no statement that work is done. It gives only
the identity of the agent, which Sinter writes into the field `agent`.
Work comes back as evidence: a commit with a delivery line reaches the
default branch, and the job on the default branch records it.

`sinter task list --ready -o json` prints one output record for each
ready task:

- its full id, and its display name, or the title of its external item;
- its task hash, its paths, its promises, and its external item;
- the chain of plans that hold it;
- the ids of the other unfinished tasks whose paths overlap its paths.
  Two path sets overlap when some file of the tree matches both. The
  overlap compares only the files that exist, so two tasks that create
  the same new file do not overlap. The overlap is information in the
  output record, and no check and no state depends on it;
- a flag when it promises a requirement that the current tree does not
  hold.

`sinter brief --task <id>` prints the **brief** of one task: its
context, in this order:

1. for each requirement that the task promises, the extent of its
   specification, which holds the requirement, or the extent of the
   requirement when its design holds it directly; and the prose of its
   design. The brief prints each extent once, and it does not print a
   requirement again when it prints the extent of its specification;
2. the requirements, specifications, and designs that the plans which
   hold the task carry out;
3. for a task with no promise, and with no plan above it that carries
   anything out, its display name and its external item, with the
   content of the external item from the index file;
4. the rest of the brief of `docs/design-notes.md` section 8.1: the
   decision records in force that the paths of the task reach, with
   their checks; the live declines of the subjects of approval that the
   brief prints; and the findings that block at the gate `review`.

The brief has a size limit: the budget of bytes of
`docs/design-notes.md` section 8.1, which the option `--budget` sets
(`docs/design-notes.md` section 11.6). The limit cuts from the end, so
the requirements and the design come first. The flag `--no-limit`
removes the limit.

The MCP server offers tools that read (the ready tasks, the brief of a
task, a task, a plan) and tools that write definitions. It offers no
tool for a judgment.

**The check at hand-back.** The gate `turn` goes, with its tiers, so
the gates are `review` and `merged`. A harness runs
`sinter check --gate review --preview` when an agent hands back its
work.

**When Sinter runs during the work.** A **hook** is a command that a
program, such as the harness or git, runs at a fixed event. The hook
of the harness that prints the brief stays (`docs/design-notes.md`
section 11.18): at the start of a session, with the event
`session-start`, and on request with the event `user-prompt-submit`. A
new hook of the harness runs the preview at the hand-back, with a new
event `stop`, which fires when the agent ends its work and hands it
back. The hook of the harness after each edit, with the event
`post-tool-use`, goes, and so does the git hook before a commit. An
agent runs Sinter at a time of its own choosing. The brief tells the
agent that it can run a check at any time: the preview after a commit,
or a plain `sinter check` before a commit. A plain `sinter check`, with
no gate, reads the working tree and prints every finding with no tier.

`sinter check --gate review` computes its findings from the commits
only: the tree of the last commit, and the commit messages of the
change, as the check in CI does. No finding reads work that is not
committed.

The option `--preview` changes only three things: the exit code, the
marks of the findings, and the treatment of work that is not committed:

- The check prints every finding that it prints without `--preview`,
  with the same tiers.
- The exit code depends only on the findings that block, except two
  groups: the findings of incomplete work, of the classes `untraced`,
  `unmet-promise`, and `awaiting-approval`; and the findings that only
  a person can clear, which are the findings of `unapproved-req`. Only
  an approval clears such a finding while the work keeps its citation,
  and only a person writes an approval (section 3.11).
- Each finding of these two groups carries the mark "does not block at
  preview". The mark matters only for a class that blocks at `review`.
  With the built-in tiers of `review`, only `unapproved-req` blocks:
  `untraced` and `awaiting-approval` warn, and `unmet-promise` is `off`.
  So for those three classes, the mark matters only where `check.tiers`
  raises them at `review`.
- The preview detects whether work that is not committed exists, and
  it reads nothing else of that work. Such work is a change of a
  tracked file, in the working tree or in git's index, that the last
  commit does not hold, or a file that git neither tracks nor ignores.
  When such work exists, the preview tells the person to commit it
  first, and it exits with code 1, whatever its findings.

`--preview` reads the same commits as the check in CI. Its answer can
still differ from the answer in CI in three cases:

- the ledger of the clone differs from the ledger of the remote. When
  the ledger is out of sync, the preview warns as section 3.11 says,
  and the warning does not change the exit code of the preview;
- the test evidence differs;
- the default branch has moved, so the base differs.

Outside these cases, when the preview exits with code 0, the check of
the same commits in CI finds nothing that blocks, except findings of
these two groups. The record `incompleteness-at-turn` keeps its
principle: Sinter never holds a turn for incomplete work.

### 3.15 How people see the work

A pull request does not show plans and tasks as a diff. People see them
in these places:

- `sinter status` prints each open plan with its parts and their
  states; the open plans with no part; the ready tasks; the delivered
  tasks, which need a person, with the tasks that "changed after their
  finishing commit" (section 3.9); the tasks that a wait for an
  abandoned task or plan blocks; the ready tasks that promise a
  requirement that the tree does not hold; the requirements that no
  work accounts for (section 3.16); the definitions that were written
  from the current branch; and whether the ledger is out of sync.
- `sinter task show`, `sinter task list`, `sinter plan show`, and
  `sinter plan list` print one task or plan, or a set of them.
  `sinter ledger log` filters entries by branch (`--branch`), by the
  field `subject` (`--subject`), and by kind (`--kind`). Each command
  has JSON output.
- `sinter status --change -o markdown` prints the **summary of the
  change**. The tasks of the change are the tasks that the `Delivers:`
  lines and the `Task:` lines of the change name (section 3.10). For
  each of them, the summary shows the current definition of the task:
  its paths and its promises. It also shows every definition of that
  task, and of each plan that holds it, from the first to the last,
  from any branch or from none. Each definition shows its person, its
  agent, and its branch, and the summary marks the definitions whose
  field `branch` names the branch of the change. Sinter does not use
  the field `head` to choose definitions: it cannot tell when a
  definition came relative to the start of a branch, and after a squash
  merge `head` can give the wrong answer in both directions. The
  summary also shows each other definition whose field `branch` names
  the branch of the change. So the reviewer sees each definition of a
  task that judges the change, also a definition written from another
  branch. A CI workflow can show the summary on the page of its run on
  each pull request, so that a reviewer sees it next to the diff. A
  reviewer can always run the command too.
- The plan file `.plans/mcp-apps.md` describes pages that MCP clients
  show, among them a view of plans and tasks. Its work moves to tasks
  or to a design in step 3 of the migration (section 3.21).

### 3.16 Requirements that work accounts for

Work **accounts for** a requirement when someone does, or did, the
work for it. This differs from the finding `untraced`, which says
whether code satisfies the requirement and a test verifies it. A
requirement is **accounted for** when one of these holds:

- an unfinished task promises it;
- an open plan carries out the requirement, its specification, or its
  design;
- a done task promised it, and the requirement still has the revision
  that it had when the task became done.

An open plan with no part still accounts for what it carries out, and
`sinter status` lists such plans. Nothing abandoned accounts for
anything. A done plan accounts for nothing by itself; only its done
tasks can account for a requirement. The third case reads the revisions
that the entries record. A `delivered` entry records the revision of
each promised requirement in the tree of its `head`, the head of the run
of the job on the default branch. A `done` entry records it in the tree
of the commit that its writer had checked out, which its field `head`
names. `sinter status`, and `sinter status -o json`, list the
requirements of each design that no work accounts for. No finding
reports them.

### 3.17 Building to see

A project can build a feature on one branch to see whether a draft
design works, before a person approves the design. A design whose
subjects of approval are not all approved is a draft, and no status
tag records it. The branch changes the design and the code together,
and what the work shows goes into the design on the same branch. Where
`proof.req` is
`"approval"`, the finding `unapproved-req` keeps the branch from merging
until a person approves the requirements as the branch leaves them.
Where approval is not required, the review and the merge of the pull
request are the point at which a person agrees to the design. A design
can merge before its code exists.

### 3.18 Review

Sinter does not check that a person reviewed the commit that delivers a
task. It relies on the protection that the project sets on its host
for the default branch. The `delivered` entry names the finishing
commit in `commit`, and in `merge` the commit of the first-parent line
of the default branch that brought it (section 3.9), so an audit can
find the review on the host.

### 3.19 Commands and findings

| command | writes |
|---|---|
| `sinter task new`, `sinter task edit <id>` | a definition; the options of `edit` set the display name, the paths, the promises, the external item, the plan, and the waits, and one call writes one entry |
| `sinter plan new`, `sinter plan edit <id>` | a definition |
| `sinter task show` (with the delivery line to copy), `sinter task list` (with `--ready`), `sinter plan show`, `sinter plan list` | nothing |
| `sinter task done <id>`, `sinter task abandon <id>`, `sinter plan abandon <id>` | a judgment |
| `sinter tracker fetch` | the index file only |
| `sinter ledger log` (with `--branch`, `--subject`, and `--kind`) | nothing |

The design notes and the specifications design `sinter approve`,
`sinter decline`, `sinter brief`, `sinter declare`, and
`sinter ledger push`, and the code does not have them yet. They keep
their names. `sinter brief` gains `--task` and `--no-limit`, keeps
`--budget`, and loses `--plan`. `sinter declare` gains `--task`.
`sinter task abandon` and `sinter plan abandon` take the place of
`sinter ledger abandon`. `sinter check` gains `--preview` and loses
`--plan`, and its option `--gate` takes `review` or `merged` (section
3.14). The MCP tools follow the names of the commands.

| new finding class | what it reports | tiers (review, merged) |
|---|---|---|
| `misplaced-declaration` | a `@design` inside the section of another design, or in a code comment; a `@spec` with a full name in the section of its own design or of another design; a `@spec` with its name alone outside the section of every design; a `@spec` with a full name whose design does not exist, which still declares its full name; a `@spec` inside the section or the body of another specification; a `@spec` in a run that attaches to no code, other than a run that owns the whole file (section 3.3); a declaration other than a requirement inside the section of a specification; any declaration in the markdown file of a specification other than that specification and its requirements; a `@req` with a full name in markdown, outside the section of its design and outside the markdown file of each of its specifications; a `@req` with a full name in the section of its own design or inside the body of a specification in code; a `@req` in the markdown file of a specification, with a full name that names another design; a `@req` with a full name whose design does not exist, which still declares its full name; an `@extern` that stands in the own prose of no design | block, block |
| `req-outside-design` | a requirement outside every design; the requirement still declares its slug, so its citations resolve | block, block |
| `wrong-kind` | a stated kind that differs from the kind of the target; a citation whose target is of a kind that the citation cannot take; an external id with a kind other than `spec` or `term`; a `#name` after a target that resolves to a declared item other than a design; a mark with a kind other than `spec` or `req` | block, block |
| `extern-mismatch` | an out-of-line item with no mark in its design; a mark with no such declared item; a mark for a declared item that the section of the design declares. The detail names the case | block, block |

`invalid-target` also reports a target that holds `@`, a citation
target that starts with `#` in a place with no home design, a name
after `#` that fails the slug pattern, a `#*` outside the form of
section 3.2, a declaration whose first segment is a declared external
namespace, a citation that states `plan` or `task`, and a mark with no
kind word. Two classes take new names: `delivery-on-unmet-step` becomes
`delivery-on-unmet-task`, and `promise-out-of-scope` becomes
`promise-outside-paths`. Sections 3.4, 3.5, 3.7, 3.9, and 3.10 give the
new expressions of `dangling`, `unbumped`, `untraced`,
`unapproved-req`, `awaiting-approval`, `declined`, the delivery
classes, `promise-outside-paths`, `unplanned-change`, and
`unmet-promise`. Of `wrong-source`, only the part that treats `spec` as
a kind of declaration is fixed now (section 3.4); the kind `rule` in its
expression waits for the design of rules (section 3.6). Until that
design exists, `unmet-rule` reports nothing. Section 3.2 gives the new
case of `duplicate`: two declared items of one design with one name,
with the equality of names of `spec/vocabulary.md` section 4.1.
`never-ran` loses its expression at the gate `turn`, and keeps its
expression of today at the gates `review` and `merged`.

### 3.20 What changes and what goes

| part | where it is today | what takes its place |
|---|---|---|
| `@design` as a design item that code satisfies and tests verify | `spec/vocabulary.md` sections 7.1 and 7.2 | `@design` declares a whole design, whose prose is not normative; its specifications and requirements hold the contract |
| plan files, steps, `@plan`, `@scope`, and promises in plan files | `spec/vocabulary.md` sections 7.1, 7.5, and 10 | plans and tasks in the ledger |
| the approval of plan files and steps, the `commitment-set` entry, `proof.plan`, and `proof.step` | `spec/ledger.md` sections 5, 6, and 11; `spec/manifest.md` section 10 | nothing: no one approves a plan |
| the planned `plan-version` entry | `spec/ledger.md` section 4.1 | nothing |
| glob containment | `spec/ledger.md` section 11.2 | nothing: no part of this design compares two path sets by containment |
| the `completed` entry | `spec/ledger.md` section 8.1 | a plan that Sinter computes as done |
| claims, the `claim` record, `waiting-on`, and `branch-overlap` | `spec/ledger.md` sections 9.2 and 10.2; `spec/jsonl.md` section 7; `spec/algebra.md` section 9 | waits between tasks and plans; the overlap of paths in the output record of a ready task |
| `scope-outside-plan`, `scope-overlap`, `step-without-promises`, `unverified-promise`, `merged-incomplete`, `renamed-step`, `misplaced-plan`, `missing-plan-id`, `unapproved-plan`, `unapproved-design`, and `promise-collision` | `spec/algebra.md` section 9 | the checks of tasks; `misplaced-declaration`; a task promises no declaration, so `promise-collision` has nothing to report |
| global rule 4 (`spec/algebra.md` section 9): a closed plan makes no findings | `spec/algebra.md` section 9 | nothing |
| plan files as built-in exempt paths, the built-in folder of plans, and the check of a plan file that the pack `markdown` does not read | `spec/manifest.md` sections 8.2, 9.1, and 12 | nothing |
| the default locations of kinds, `paths.<kind>` | `spec/manifest.md` section 9.3 | nothing: a task promises no declaration |
| the plan journals `.plans/<slug>.log.md`, and the built-in historical path that holds them | record `plan-journals`; `spec/manifest.md` section 9.2 | what a task finds about the design goes into the design; a choice goes to the person who directs the work, and then into a decision record; work left over becomes a new task; small reasoning goes into the body of the commit message |
| the `Step:` line of commit messages | record `commit-messages` | the `Task:` line |
| the `Record:` and `Issue:` lines as an allowance of a change | record `commit-messages` | a task; a change needs a task, which can refer to an issue |
| `sinter ledger abandon` | `spec/manifest.md` section 10.2; `docs/design-notes.md` section 11.13 | `sinter task abandon` and `sinter plan abandon` |
| the option `--plan` of `sinter check` and of `sinter brief`, which names a plan file | `docs/design-notes.md` sections 11.3 and 11.6 | for `sinter brief`, the option `--task`; for `sinter check`, nothing |
| the plan check, which compares the hunks of a diff with the scopes of the open plan files | `spec/manifest.md` sections 3.2 and 9.1 | the path check, which compares the hunks of a change with the paths of the tasks of the change (section 3.10) |
| the code that judges the approval of plan files and steps from the ledger | the unmerged branch `feat/check-approvals` of the remote, which holds the work of the step "Check approvals" of `.plans/ledger.md` | nothing; the folds of declarations, the folds of closings and deliveries, the fixture ledgers, and the builders of the tests carry over |
| the gate `turn`, its tiers, the keys `check.tiers.turn.*`, and the `turn` column of each finding class | `spec/manifest.md` sections 11.1 and 11.2; `spec/algebra.md` section 9; `Turn` in `lib/finding_class.ml` | `sinter check --gate review --preview` at hand-back (section 3.14) |
| the hook of the harness after each edit (the event `post-tool-use`) and the git hook before a commit | `docs/design-notes.md` sections 8 and 11.18 | an agent runs Sinter at a time of its own choosing (section 3.14) |
| `@rule`, the rule file, and the kind word `rule` | `spec/vocabulary.md` section 7.1; `spec/manifest.md` section 14; `lib/findings.ml` and `lib/markdown.ml` | `@finding-class`, the finding-class file, and the kind word `finding-class`; a rule of a practice lives in a decision record (section 3.6) |

These texts change when the design is built:

| text | change |
|---|---|
| `spec/vocabulary.md` | `@spec`, `@extern`, names with `#`, custom namespaces with `/`, kind words, the reserved `@`, the extents of designs and specifications, the citations that each kind can take; in section 5, the table of revisions: `@spec` and `@finding-class` take a revision as the other declarations do, and `@extern` takes none; in section 6, the extent of a specification in code, which holds only the blocks of the specification and of its requirements and not the whole run, the extent of a requirement in code, which is its block, and the front matter of a decision record, which belongs to the extent of its `@decision`; in section 7.1, `@finding-class` takes the place of `@rule` and declares the finding class of a finding-class file, and a rule of a practice lives in a decision record; the kind word `finding-class`; in section 7.3, `@deprecated` also applies to `spec`; in section 8.1, the approval that makes a `@supersedes` effective, for each kind of its source (section 3.2); in section 8.2, the retirement of a design or a specification retires the declared items inside it, as an exception to the statement that retirement does not cascade, and a `@supersedes` with `#*` gives successors by name |
| `spec/ledger.md` | section 2.3: the list of folds loses an open plan, a claim, and the approved commitment set of a plan, and gains the states of tasks and plans; the list of the commands that write judgments gains `sinter task done`, the abandon command becomes `sinter task abandon` and `sinter plan abandon`, the `commitment-set` entry and the `completed` entry go, and the commands that write definitions join as a new class of writer; sections 4.1 and 4.2: the list of kinds, the paragraph on `plan-version`, the fields `by` and `agent`, and the types of the fields of each kind, among them `hash_prefix`, `commit`, and `revisions` of `delivered`; the writers; the replay of definitions, one replay for definitions and judgments, and the stop of a push or a replay under an agent marker before a judgment that needs the person; the push of a command that writes a definition, its five tries, the option `--local`, and the ref `refs/sinter/remotes/origin/ledger`; the `delivered` entry of a task with its facts and the steps of its fold, and the new meaning of its field `merge`: the commit of the first-parent line that brought the finishing commit; in section 8.4, start rule 1 (section 3.7), which reads only `delivered` entries; section 10.3, where the warning for an absent ledger no longer depends on plans; section 13.5, where the gate `turn` goes |
| `spec/jsonl.md` | the output records of tasks and plans; section 4, the node records of `spec`, `task`, and `plan`; section 7, where the field `gate` of the `gate` record takes `review` or `merged`, and the field `planned` of the `hunk` record, which names the steps and the rules that cover a hunk; section 9, the ids of the facts of `spec`, `task`, and `plan`, and full names in the ids of specifications and requirements; section 10, where the `summary` record counts findings under the tiers of the gate `review` in place of `turn`, and its fields `plan`, `step`, `steps_done`, `steps_total`, `claims`, and `waiting`, which describe plan files, steps, and claims, and where the `summary` record gains the field `ledger_sync`, which holds the state of sync of the ledger (section 3.11) |
| `spec/porcelain.md` | section 7, where the header `gate` takes `review`, `merged`, or `none` |
| `spec/algebra.md` | section 2: at the gate `review`, the tree `T` is the tree of the last commit; section 3: the kinds `task`, `plan`, and `spec` join, `plan` takes a new meaning, `step`, `promise`, and `claim` go, and the kind `finding-class` takes the place of the kind `rule` for the facts of finding-class files, while the facts of rules in decision records, `rule(n)`, the kind `rule` in the expression of `wrong-source`, and the origin edge of a rule wait for the design of rules (section 3.6); section 4: the name form `fullform`, the full form of a plan file; section 6.1: the selectors `active`, `plan(n)`, and `step(p/s)`, which read plan files, steps, and the active step; section 6.4: the plan functions; section 6.5: `waiting` goes; section 7: `untraced` reads requirements only; section 8.1: `changed(b)`, which compares the base with the working tree, compares the base with the tree of the last commit at the gate `review`, and the rows of `changed()` for plans, steps, and promises go; section 8.2: the classes that compare with the base; section 9: the finding classes of section 3.19, the classes that go, the `turn` column of every class, the expression of `never-ran` at `turn`, and the sentences on the classes of incomplete work at `turn` |
| `spec/manifest.md` | the table of a namespace, in which a `pattern` that can match an id that holds `#` or `@` is an error; the keys of `proof`; sections 8.2, 9.1, 9.2, 9.3, and 12, where plan files and journals stop being built-in members; sections 3.2 and 9.1, where the plan check becomes the path check (section 3.10); sections 11.1 and 11.2, where the gates are `review` and `merged` and the keys `check.tiers.turn.*` go; sections 13.1 and 13.4, where plan files and journals stop being built-in setting facts, and where each key of the table of a namespace gives its setting fact and its entry of the comparison set; sections 13.2 and 13.4, where the gate `turn` goes; section 14, where a rule file becomes a finding-class file, declared with `@finding-class`, that holds only a finding class, and a decision record can carry a check |
| `sinter.toml` | `namespaces.gh` becomes a table, and the key `decision` under `[paths]` goes |
| `docs/design-notes.md` | the thesis (the decision `agent-statements`), the sections on plans, the brief, "No database", section 6.4 (the push rules of the host no longer keep agents off the ledger), the absences of section 9.1 (which say that Sinter has no `new` command, and that no configuration exists outside the manifest and the rule files), the bullet of section 9.1 "Four commands change durable state", and the flag `--no-cache`, which section 11.1 designs and the code does not have yet; section 8, the turn report, the gate `turn`, and the working tree that every check reads, since the gate `review` reads the commits only; in section 8, the layer "After each edit", the git hook before a commit, and the sentence "The hook before a commit uses the tiers of the gate `turn`" go, the layer of the turn report becomes the preview at the hand-back (section 3.14), and the layers "A check with a fresh context" and CI stay; section 8.1, where the brief tells the agent that it can run a check at any time; sections 9.1 and 11.3, which name the turn report, and section 11.3, which names the check before a commit; sections 6.1 and 11.5, where the declared task takes the place of the active step, and section 11.5, where the declared task only narrows the brief; section 11.18, where the event `post-tool-use` goes and a new hook with the new event `stop` runs the preview at the hand-back; sections 11.3 and 11.6, where the option `--plan` of `sinter check` and of `sinter brief` goes; section 11.13, where `push --replay` goes, because `sinter ledger push` always replays after a lost push (section 3.11) |
| `docs/versioning.md` | the rewrite of `spec/` and of the design notes into designs decides what holds the versioned set of specifications |
| `docs/roadmap.md` | the roadmap items "Issue trackers", "Plans made of plans", "Plans with their journals", and "Branches that deliver one plan at the same time" leave the roadmap; "Commit trailers" changes, because the path check reads `Task:` lines; "A dictionary of terms" changes, because the kind word `term` names terms of external documents now; "Rank the items of the brief" changes, because the brief of a task puts its requirements and its design first; "`sinter serve --mcp`" changes, because this design adds MCP tools that write definitions; "Observations of the outside world" changes, because it clears an obligation with a plan that cites the observation; "Rule files" changes, because a rule file becomes a finding-class file that holds only a finding class |
| decision records | `agent-statements`, `commit-messages` (the `Task:` line in place of `Step:`; `Meets:` names a promise of a task; `Record:` and `Issue:` no longer allow a change alone), `delivery-lines`, `plan-ids`, `plans-span-branches`, `plan-journals`, `rule-files`, `manifest-questions` (`proof.plan`, `proof.step`, and `paths.<kind>`), `pull-request-descriptions`, `branch-workflow` (a pull request description names its tasks in place of a plan step), `ledger-event-log` (its inputs gain the content of trackers, for display only), `last-judgment-wins` (what it says about plans and steps), `current-dependencies` ("a pull request or a plan step"), `incompleteness-at-turn` (it describes `--preview`; its sentence "not even as a warning" goes; its principle that Sinter never holds a turn for incomplete work stays), `ledger-layout` (its sentence on the checks at the gates `turn` and `review`), `manifest-names` (the names of the gates), `exit-codes-by-gate` (with `--preview`, code 1 no longer follows from every finding at tier `block`), and `output-forms` (the form `-o markdown` of `sinter status --change`) are revised or superseded |
| `CONTRIBUTING.md` | the form of decision records; plans and journals; the trailers of commits; the section "Pull requests", which names the plan step; the sentence that says that neither `lib/` nor `bin/` keeps a cache on disk; and each use of the word "rule" in a meaning other than the check of a practice, which takes a qualifier, such as "writing rule" |
| `CLAUDE.md`, `README.md` | the decision `agent-statements`; the layout of the repository |
| `.github/workflows/` | the workflow of the job on the default branch sets git's identity (`user.name` and `user.email`) for the job on the default branch (section 3.11) |
| the skills of the Claude Code plugin | the skills `decision` and `plan` |
| `.plans/mcp-apps.md` | its work moves to tasks or to a design in step 3 of the migration (section 3.21); there, its sentence that the tools only read changes, because the tools write definitions |
| `lib/finding_class.ml` | the gate `Turn` and the `turn` tier of each class go |
| `lib/findings.ml`, `lib/markdown.ml` | the declaration word `rule` becomes `finding-class` |

### 3.21 Migration

This repository moves to the new forms in one migration period. No
version of Sinter reads both plan files and plans in the ledger.

1. The period starts when the work of adding tasks and plans to the
   ledger starts. The manifest of this repository sets
   `check.warn-only = true`, so no finding blocks, and the findings stay
   visible as warnings.
2. The code switches to the new forms. The code that reads plan files
   goes in the same period.
3. The open work of the plan files moves by hand. For each step that is
   not done, a person decides whether it becomes a task, becomes part of
   a design, or is dropped. Anything else worth keeping in a plan file
   or a journal becomes a design, a decision record, or a task.
4. A person then deletes the plan files and the journals. They are not
   decision records, and git keeps their history.
5. The period lasts until the rewrite of `docs/design-notes.md` and of
   the files in `spec/` into designs ends, so that every requirement of
   the repository lives in a design. The rewrite gives the requirements
   new full names. In the same change, new definitions write the new
   full names into the promises of each unfinished task, and into what
   each open plan carries out (its field `carries`). A done task keeps
   the old names, so after the rewrite it accounts for nothing (section
   3.16). That is information only, and no finding reports it.
6. Before the blocking checks come back on, a person fixes the findings
   that the period left. Then `check.warn-only` returns to `false`.

Old commits keep their `Step:` and `Delivers: <plan>/<step>` lines as
history. The checks of a branch read delivery lines only in the commits
of the change, and the job on the default branch reads them only in the
commits of its range, so those old lines never count for a task again.
The specifications that this design leads to do not describe plan files.

The kinds of entries change in place. The field `v` of every entry, the
version of the entries (`spec/ledger.md` section 13.2), stays 1. Until
`spec/v1.0.0`, `docs/versioning.md` puts no condition on a change of
the entries. When a ledger holds entries before version 0.1 of Sinter,
and a form of the entries must change, the project migrates that
ledger once by hand and moves the ref `refs/sinter/ledger` with force.

**The end of the migration.** These must be gone before
`check.warn-only` returns to `false`:

1. the code that reads plan files, `@plan`, and `@scope`;
2. the old form `Delivers: <plan>/<step>`, the tag word `@rule`, and
   the finding classes, the names, and the keys that go (sections 3.19
   and 3.20), gone from the code and the specifications;
3. claims, and the approval of plans;
4. the gate `turn`: its tiers in `spec/manifest.md` sections 11.1 and
   11.2, the keys `check.tiers.turn.*`, the `turn` column of
   `spec/algebra.md` section 9, `Turn` in `lib/finding_class.ml`, every
   other text of section 3.20 that names the gate, and the old text of
   the record `incompleteness-at-turn`;
5. every plan file and every journal of this repository;
6. every requirement of this repository outside a design;
7. the flat slugs of this design: each of its requirements takes its
   slug as its name inside the design, and the citations of them use
   the new form;
8. in the designs that take the place of `spec/`, in the designs that
   take the place of the design notes, and in `CONTRIBUTING.md`, each
   use of the word "rule" with no qualifier in a meaning other than the
   check of a practice (section 3.6);
9. each finding that the period left.

After that point, no part of Sinter keeps a form of the transition.
The finding `req-outside-design`, and the slug that such a requirement
still declares (section 3.2), are the behavior of the target, not a
form of the transition.

During the rewrite, this repository can delete decision records under
the one exception of section 3.6.

### 3.22 Where designs live

The kind of a declaration lives on its tag, so a repository can keep
its designs anywhere. This repository keeps each design in
`docs/designs/<slug>.md`, with the license of `docs/`. The seven files
in `spec/` share one version (`docs/versioning.md`), and a design is
not one of them. `docs/decisions/` holds one decision record in each
file, and `docs/designs/` holds one design in each file in the same
way. The slug of this design is `work-model`. The rewrite of `spec/`
and of the design notes decides whether the designs of this repository
use custom namespaces, with the whole set of designs in view.

## 4. Alternatives

**Plans and tasks.**

- **Plans and tasks as files in the tree,** as plan files are today and
  as these tools keep them: ticket, which keeps each task as a markdown
  file in the tree; Backlog.md; Task Master; and CCPM, a set of Claude
  Code skills that keeps its plans as markdown files. Not chosen: a
  change of the scope of a plan file needs a pull request, and the task
  files of several branches conflict.
- **One ref for each task or plan,** as git-bug and Gerrit keep one ref
  for each issue or review, which spreads the writes. Not chosen: the
  folds read all entries in one order of `seq`, which one ref gives
  (record `ledger-layout`), and many refs slow `git fetch`.
- **The approval of plans,** as `spec/ledger.md` section 11 defines it
  for plan files. Not chosen: a plan only says how work gets done, and
  the approval of a plan file costs a judgment for each change of its
  scope.
- **A task that belongs to its branch until the branch merges.** Not
  chosen: a fold would have to read which branch merged, each branch
  would show a different state of the work, and the harness on the
  default branch would not see new tasks.
- **A description in each task.** Not chosen: the text that says what
  to build belongs in a design, which a pull request shows and a
  revision governs, or in the external item.
- **Promises of declarations in a task,** as a step of a plan file can
  promise a decision record today. Not chosen: a declaration is text
  that the pull request shows, and the promises that need a check are
  the ones that tie code and tests to a requirement.
- **No promises in a task.** Not chosen: Sinter could not check that a
  delivery carries out the requirements that the task names.

**States and delivery.**

- **Three states of a task, with a `delivered` entry only when every
  promise is met,** as the job on the default branch does for a step
  today. Not chosen: a delivery whose promises were not met would leave
  no entry, so the task would stay ready although its delivery line
  reached the default branch.
- **A done state that Sinter reads from the current tree.** Not chosen:
  a task would become not done when a test fails later, and a done task
  must stay done.
- **A task, or an abandoned plan, that a person can open again.** Not
  chosen: a done task must stay done. A person who wants the work of an
  abandoned task or plan again defines a new one, so a mistake costs
  only a new id, and the delivery lines and the entries of the old one
  stay tied to the work that they describe.
- **An entry that records a done plan,** as `completed` does today. Not
  chosen: Sinter can compute the state from the parts.
- **A done plan that stays done, so that a later task goes into a new
  plan.** Not chosen: a plan whose first task is done before its other
  tasks exist would become done at once, the work that belongs together
  would split over plans, and a writer who adds a task later would find
  the plan closed.
- **A field of a plan that says that the plan is complete,** so that
  the plan is done only when the field is set and every part is done.
  Not chosen: it adds one more field and one more step, and a plan whose
  field nobody sets is never done.
- **A wait for an abandoned task or plan that ends by itself,** as an
  abandoned plan file releases its `waiting-on` promises today. Not
  chosen: the waiting task would become ready although what it needs
  will never exist.
- **A field `met` that is false, and a field `stale`, in the `delivered`
  entry of a line whose six characters are not the start of the current
  task hash.** Not chosen: the ledger records facts, and Sinter computes
  states from them; a state that the job on the default branch computed
  would stay in the ledger forever.
- **A judgment of the earlier paths and promises that the six
  characters of such a line name.** Not chosen: the task would become
  done for paths and promises that it no longer has.
- **For a line whose six characters are not the start of the current
  task hash, a warning only, with no change of state.** Not chosen: the
  task would stay open and ready, so a second agent could take it,
  although its work reached the default branch.
- **A delivery line with the task id alone.** Not chosen: the line
  would count for a task whose paths or promises changed after the
  commit, and the person who merges would not see the change.
- **A task hash over the whole definition.** Not chosen: a new display
  name would make a delivery line no longer count for its task.
- **A path check against the paths of all unfinished tasks,** as today's
  plan check uses all open plan files. Not chosen: with many open tasks
  that have broad paths, the check catches little, and the open plan
  file `.plans/sinter-v0.1.md`, whose scope covers almost every path,
  already shows this today.
- **No path check.** Not chosen: it loses the signal of work that no
  task asked for.
- **A gate `turn` as an early `review`, with the tasks that the commits
  name and the task that the session declares.** Not chosen: the
  declared task would then change a state, although no check in CI
  reads it and the person who merges cannot see it.
- **A gate `turn` that checks only the hunks that are not committed.**
  Not chosen: a pass would say nothing about the commits that the check
  in CI reads.
- **Hunks that are not committed, exempt from `unplanned-change`.** Not
  chosen: the agent can commit the work first.
- **A preview that hides incomplete work.** Not chosen: then a clean
  preview would not mean that the check in CI passes.
- **A promise met anywhere in the tree.** Not chosen: a promise met
  outside the paths of its task would not show that the task did the
  work that it named.
- **A check that a person reviewed each delivering commit,** by asking
  the host or by a judgment in the ledger for each merge. Not chosen:
  the host already enforces reviews, and the check would depend on an
  interface of the host that can break, or add one act of a person to
  every merge.

**Ids and entries.**

- **Sequential task numbers.** Not chosen: two clones take the same
  number, and only the remote could give one.
- **The entry id as the task id.** Not chosen: a replay gives an entry
  a new id.
- **A hash of the creating entry as the task id.** Not chosen: it gives
  nothing that a random id does not give.
- **Six digits in storage.** Not chosen: twelve digits make a clash
  negligible, and a prefix keeps the id short where a person types it.
- **One entry for each change of a definition.** Not chosen: it needs a
  kind of entry for each kind of change, and checks of each change
  against the others.
- **The last writer wins,** as Beads and git-native-issue, a tracker
  that keeps each issue on its own git ref, do. Not chosen: the change
  of the first writer is lost, and no one is told.
- **A push by hand only, or pushes in batches.** Not chosen as the
  default: other machines would see new tasks late, and batches need a
  timer or a process that Sinter does not have. `--local` keeps the
  push by hand for a writer who asks for it.
- **Signatures required on judgments, or a server that writes for a
  logged-in user.** Not chosen: each person would need a key before any
  approval, and a server changes what kind of tool Sinter is. Signing
  stays a later option (section 7).
- **`by` names the agent when an agent writes.** Not chosen: the person
  who runs the agent answers for the entries of their clone, as for a
  commit.

**Designs and names.**

- **An id in the name of a design,** as the full form `<slug>@<id>` of
  a plan file holds a plan id today (`spec/vocabulary.md` section 4.3).
  Not chosen: revisions already make the reuse of a slug safe, so an id
  adds nothing within one repository. A new design that takes the slug
  of a deleted design continues the old declared item, and its revision
  must be higher than every revision of the slug that the ledger holds
  (`spec/vocabulary.md` section 4.1). So every citation pinned to a
  revision of the old declared item becomes suspect, and a person pins
  it again. A `@cites` with no revision pins no revision, so it follows
  the new declared item, by design. A reference that the checks of one
  repository do not see belongs to the design of references across
  repositories.
- **`/` for names inside a design.** Not chosen: it would clash with
  external ids and custom namespaces, and it needs a way to resolve
  clashes.
- **The extent of a design as its whole section, with its
  specifications and requirements.** Not chosen: an edit of a
  requirement inside a specification would raise three revisions, and
  each citation of the design would become suspect at almost every edit.
- **All the text of a design as normative.** Not chosen: nothing would
  tell the reasons apart from the contract.
- **Requirements outside designs,** for good, or as an option of the
  manifest. Not chosen: a requirement exists because a design considered
  a problem; on its own it has no source and no reason that a reader can
  find.
- **A requirement outside every design that declares nothing.** Not
  chosen: one fault would give a finding at every citation, and no
  check would work on those requirements until they move.
- **Requirements declared in code one at a time, as the only form in
  code.** Not chosen: a component could then state no whole contract
  beside its code, and its requirements would have no specification in
  common.
- **One specification continued in several places.** Not chosen now:
  it needs an order of the parts, one place for the revision, and a way
  to resolve parts that disagree. Section 7 keeps it.
- **Marks in the file of a specification,** so that a specification in
  markdown could take requirements that code declares. Not chosen now:
  the file of the specification would no longer hold the whole contract,
  and an extent across files, with revisions that couple across files,
  needs a design of its own. Section 7 keeps it.
- **A requirement with a full name in any markdown file.** Not chosen:
  requirements would scatter over documents that are neither a design
  nor a specification.
- **A required citation, or a `@spec` line with a keyword, as the mark
  of an out-of-line item.** Not chosen: a citation links to a declared
  item, and a mark says that a declared item belongs to the design; a
  keyword after a target is a description, which has no meaning for the
  machine.
- **A path in a mark.** Not chosen: every move of a file would break the
  mark.
- **A bare name for a declared item of the home design.** Not chosen: a
  name could hide another, and a new name elsewhere could change the
  meaning of an existing citation.
- **A default kind for an external namespace.** Not chosen: the kind
  would be implicit, and a citation should say what it means.
- **No name inside an external id.** Not chosen: Sinter could not tell
  two terms of one document apart.
- **A custom namespace that must be declared.** Not chosen: a misspelled
  custom namespace in a citation already shows, because the citation
  names no declared item.
- **`@satisfies` and `@verifies` of a specification or a design.** Not
  chosen: one citation would stand for dozens of requirements.
- **One set of slugs for each kind of declaration.** Not chosen: every
  citation would need a kind word.
- **A citation of a plan or a task.** Not chosen: whether a citation
  resolves would depend on the ledger, and text in the tree would depend
  on the state of the work.

**Approval.**

- **An approval of each requirement on its own text, also inside a
  specification, with the prose of the design apart.** Not chosen: an
  edit of a requirement inside a specification changes two texts, so it
  would need two approvals, or a new kind of hash over a specification
  without its requirements.
- **One approval of the whole design.** Not chosen: any edit anywhere
  would end it.
- **One key, `proof.design`, for everything inside a design.** Not
  chosen: a repository could not require approval of the contract
  without also requiring approval of the reasons.
- **A status tag `@draft`.** Not chosen: it adds a second way to say
  "not agreed yet" beside approval, and the two can disagree.
- **An experiment task whose branch never merges.** Not chosen: the
  work is done twice.

**Decision records and rules.**

- **The four sections of today ("Context", "Decision", "Alternatives
  considered", and "Consequences"), only shorter.** Not chosen: a
  section "Context" repeats the design and invites length.
- **A required section "Alternatives considered".** Not chosen: the
  section too often fills with text that records nothing.
- **A rule in a file of its own beside each decision record of a
  checked practice, or a rule in a file of its own alone.** Not chosen:
  either way, some practice ends up with its reason in one file and its
  check in another.
- **Decision records that stay in their long form when a design takes
  up their question, or that the status tag `@deprecated` retires, or
  that one sweep rewrites.** Not chosen: in the long form, the weighing
  would sit in both the decision record and the design; `@deprecated`
  says that a decision no longer applies; and a sweep apart from the
  designs would lose reasons that no design holds yet.
- **A change of `spec/vocabulary.md` section 8.3 that allows the
  deletion of an absorbed decision record.** Not chosen: other
  repositories would lose the guarantee that a decision stays findable.

**Trackers and Sinter's index.**

- **Two-way sync with external trackers,** as git-bug does. Not chosen:
  it failed in every tool that had it (section 2.1).
- **Copies of the content of trackers in the ledger.** Not chosen: the
  ledger is permanent, and refreshed copies would make it grow too fast.
- **A routine outside Sinter that reads the tracker.** Not chosen: each
  repository would have to write or find one.
- **A read of the tracker inside every command that shows an external
  item.** Not chosen: `sinter status` would wait on the network.
- **Several external items for one task.** Not chosen: a task is one
  piece of work, and several tasks can share one external item.
- **An index file in `.sinter/` of each working tree, or in the cache
  folder of the user.** Not chosen: the ledger and the trackers are the
  same for every working tree, and a move of the repository would lose
  a cache keyed by its path.
- **SQLite through an OCaml binding to the system library.** Not chosen:
  each platform would need the library to build Sinter.
- **An index file that is current while the entry at its recorded
  `seq` keeps its id.** Not chosen: a repair that drops an entry below
  that `seq` keeps every later entry as it was, so the index file would
  keep the effect of the dropped entry.
- **A check of every entry id up to the recorded `seq`.** Not chosen:
  the check that the newer commits only add lines (section 3.13) finds
  each changed or removed entry, and it reads only the chunks that the
  newer commits change. A check of every entry id would read the whole
  ledger on each read, which loses the speed that the index file exists
  for.
- **A repair that deletes the index file.** Not chosen: a repair runs on
  one machine, and it cannot reach the index files of the other clones.
- **A read of the trackers inside a build of the index file.** Not
  chosen: any command that found the file missing would wait on the
  network.
- **A `sinter check` that never reads the index file.** Not chosen: at
  a large ledger, every check would read the whole ledger again, and
  `--no-cache` keeps that plain read for anyone who wants it.

**Seeing the work, and the transition.**

- **A web server in Sinter.** Not chosen now: it conflicts with the
  absence of a web interface in `docs/design-notes.md` section 9.1, and
  it is much larger than the other ways. It stays possible later
  (section 7).
- **A summary of the definitions written from the branch only.** Not
  chosen: a definition of a task of the change written from another
  branch would not show, and such a definition can clear a finding of
  the change.
- **A summary by branch, and a finding when a task of the change
  changed from another branch.** Not chosen: it adds a finding class,
  and noise each time two branches touch one task.
- **A summary of the definitions of a task from the first definition
  that the branch of the change wrote.** Not chosen: an earlier
  definition from another branch, or from no branch, would not show,
  and it still shapes the task that judges the change.
- **A summary of the definitions after the last definition whose task
  hash the delivery line names.** Not chosen: a `Task:` line names no
  task hash, and a definition before that one would not show.
- **The brief of each task inside each output record of the list.** Not
  chosen: the output would become very large.
- **A brief with only the requirements and the design.** Not chosen:
  the decision records and the findings that block are what an agent
  otherwise breaks without knowing.
- **A finding for requirements that no work accounts for.** Not chosen:
  whether work accounts for a requirement is a signal for planning, not
  a fault of a change.
- **Accounting for a requirement with no condition on the revision.**
  Not chosen: the list would hide the requirements that need rework.
- **Plan files and the ledger side by side.** Not chosen: one migration
  period is simpler.
- **A command that imports plan files.** Not chosen: the specifications
  have no released version yet (`docs/versioning.md`), so the migration
  concerns the plan files of this repository, and a person should look
  at each open step.
- **A migration period that lasts only for the move of the plan files.**
  Not chosen: a longer period is simpler, and a person fixes what it
  misses before the blocking checks come back on.

## 5. Requirements

In this section, "must" states a requirement, "must not" states a
prohibition, and "can" states a permission.

### 5.1 Designs and specifications

#### 5.1.1 The declaration of a design

@req design-declaration

`@design` must declare a design by its slug, with no id. The slug of a
design must be unique in the shared namespace: among the slugs of
designs, decision records, and requirements outside designs. It can
hold a custom namespace (requirement `target-reading`). A `@design`
inside the section of another design, and a `@design` in a code
comment, must be the finding `misplaced-declaration`.

#### 5.1.2 The extent of a design

@req design-extent

The extent of a design must be its section, without the extent of each
specification and of each requirement that the design holds. A change
of that extent must raise the revision of the design.

#### 5.1.3 The declaration of a specification

@req spec-declaration

`@spec` must declare a specification, which belongs to exactly one
design. In the section of its design, a specification must declare its
name alone, and it must belong to the design whose section holds it. In
a markdown file of its own, or in a comment of code, it must declare
the slug of its design, `#`, and its name. A specification must live
wholly in one of these places. The markdown file of a specification
must hold that one specification and its requirements, and no other
declaration. These cases must be the finding `misplaced-declaration`:
a `@spec` with a full name in the section of its own design or of
another design; a `@spec` with its name alone outside the section of
every design; a `@spec` with a full name whose design does not exist,
which must still declare its full name; a `@spec` inside the section of
another specification; a declaration other than a requirement inside
the section of a specification; and any declaration in the markdown
file of a specification other than that specification and its
requirements.

#### 5.1.4 The extent of a specification

@req spec-extent

The extent of a specification must include the extent of each
requirement that it holds, so an edit of such a requirement changes
both extents. Boundary rule 2 (`spec/vocabulary.md` section 6) must not
apply to the extent of a specification. Inside a specification, the
extent of each requirement must be its own section without the
requirements nested in it, as boundary rule 2 says. The extent hash of a
specification must drop the revision token on the tag line of each
requirement inside it, and must keep the name of that requirement.

#### 5.1.5 Specifications in code

@req spec-in-code

A `@spec` in a run that attaches to code must own the attached code. A
`@spec` in a run that attaches to no code, and that comes before all the
code of its file that a run can attach to, must own the whole file. A
`@req` in a comment inside a body must belong to the specification of
that body. When a `@spec` inside another body, which is the finding
`misplaced-declaration`, puts two bodies around the `@req`, the `@req`
must belong to the nearest body. The extent of a requirement in code,
inside a body or outside every body, must be its block, with its tag
lines and its trailing prose, and no other part of its run. The extent
of a specification in code must be the block of the specification and
the block of each of its requirements, each with its tag lines and its
trailing prose, and no other part of a run or of the body. Its extent
hash must normalize each of these blocks as `spec/vocabulary.md` section
6.1 says, and join them in the order of the file, with one LF between
two blocks. A `@spec` in any other run that attaches to no code, and a
`@spec` inside the body of another specification, must be the finding
`misplaced-declaration`.

#### 5.1.6 The design of a requirement

@req requirement-membership

A requirement must belong to the design whose section holds its tag
line, and to the specification whose section holds it, when one does.
A requirement in the markdown file of a specification must belong to
that specification and its design, and must declare its name alone. A
requirement inside the body of a specification in code must belong to
that specification and its design, and must declare its name alone. A
requirement in code outside every body must declare the slug of its
design, `#`, and its name, and its design then holds it directly.
These cases must be the finding `misplaced-declaration`: a `@req` with
a full name in markdown, outside the section of its design and outside
the markdown file of each of its specifications; a `@req` with a full
name in the section of its own design, or inside the body of a
specification in code; a `@req` in the markdown file of a
specification, with a full name that names another design, which must
still belong to that specification; and a `@req` with a full name whose
design does not exist, which must still declare its full name, and
which must not also be the finding `req-outside-design`. A `@req` with
its name alone outside the section of every design and outside every
specification must be the finding `req-outside-design`, and it must
still declare its slug in the shared namespace, so that its citations
resolve. The full name of such a requirement must be its slug.

#### 5.1.7 Names inside a design

@req design-names

The specifications and the requirements of one design must share one
set of names. Two of them whose names are equal, or differ only in
case, must be the finding `duplicate`, as for slugs
(`spec/vocabulary.md` section 4.1). A name inside a design must match
the slug pattern of `spec/vocabulary.md` section 4.1, so it must not
hold `/`.

#### 5.1.8 Marks of out-of-line items

@req extern-marks

The own prose of a design, its section outside the extent of each of its
specifications and requirements, must hold one `@extern <kind>:<name>`
line for each out-of-line item of the design: each specification
declared outside the section of the design, and each requirement that
the design holds directly and that code declares. A mark must name a
declared item of the design whose section holds it. A mark must state
the kind, must not give a path, and must take no revision. These cases
must be the finding `extern-mismatch`, with the case in its detail: an
out-of-line item with no mark; a mark with no such declared item; and a
mark for a declared item that the section of the design declares. An
`@extern` that stands in the own prose of no design must be the finding
`misplaced-declaration`. A mark with no kind word must be the finding
`invalid-target`, and a mark with a kind other than `spec` or `req` must
be the finding `wrong-kind`.

#### 5.1.9 A deprecated specification

@req deprecated-spec

The status tag `@deprecated` must apply to a specification, as it
applies to a requirement, a design, and a decision record.

#### 5.1.10 Retirement of the declared items inside

@req retirement-cascade

When a design is retired, each specification and each requirement of
the design must be retired. When a specification is retired, each
requirement of the specification must be retired. A citation of a
retired declared item must not retire the declared item that holds the
citation.

#### 5.1.11 Successors by name

@req successor-by-name

A declared item must get a successor only from a `@supersedes` that
names it, except in one case. A `@supersedes` in the tag block of a
design, whose target is the slug of another design, `#*`, and a
revision of that other design, must retire the other design, as a
`@supersedes` of its slug alone does, and must give each declared item
`x` of the other design the successor `x` of the design that holds the
`@supersedes`, when that design holds a declared item `x` of the same
kind.

#### 5.1.12 When a `@supersedes` is effective

@req effective-supersedes

The source of a `@supersedes` must be the innermost declaration whose
extent holds its tag line (`spec/vocabulary.md` section 7.2). Where
`proof.req` is `"approval"`, a `@supersedes` whose source is a
specification must be effective only when that specification is
approved; one whose source is a requirement inside a specification,
only when that specification is approved; one whose source is a
requirement that a design holds directly, only when that requirement is
approved; and one whose source is a requirement outside every design,
never. Where `proof.design` is `"approval"`, a `@supersedes` whose
source is a design must be effective only when the prose of that design
is approved. Every other condition of `spec/vocabulary.md` section 8.1
must still hold.

### 5.2 Names and citations

#### 5.2.1 How Sinter reads a target

@req target-reading

Sinter must read the tag target of a declaration or of a citation in
this order: it splits off the text from the first `#` as a name inside a
design or an external document; a kind word and `:` at the start give
the kind; a target that holds `@` is the finding `invalid-target`; when
the first segment of the rest is an external namespace that the manifest
declares, the rest is an external id; otherwise the rest is a slug of
one or more segments joined by `/`, each segment matching the slug
pattern of `spec/vocabulary.md` section 4.1. A kind word must state the
kind of what the whole target names: with a `#name`, the kind of the
named part. The name after `#` must match the slug pattern of
`spec/vocabulary.md` section 4.1, or be `*` in the form of requirement
`successor-by-name`. A name that fails the pattern, and a `*` in any
other place, must be the finding `invalid-target`. A declaration whose
first segment is a declared external namespace must be the finding
`invalid-target`. A `#name` after a target that resolves to a declared
item other than a design must be the finding `wrong-kind`. A target
whose part before `#` resolves to nothing must be the finding
`dangling`, and not also `wrong-kind`. The target of an `@ack` must keep
the grammar of `spec/vocabulary.md` section 7.4, and the subject of the
finding in it can hold a full name such as `ledger#id-form`.

#### 5.2.2 Names of the home design

@req relative-names

The home design of a citation must be the design that holds the place of
the citation: its section, the markdown file of one of its
specifications, or, for one of its specifications in code, the run that
holds the `@spec` or the body of that specification. A citation target
that starts with `#` must name the declared item of that name in the
home design. Such a target in a place with no home design must be the
finding `invalid-target`. A citation target with no `#` must not resolve
to a name inside a design.

#### 5.2.3 Kind words

@req kind-words

The kind words must be `decision`, `design`, `finding-class`, `req`,
`spec`, and `term`, and `plan` and `task` must be reserved. A target
holds a kind word only when the text before its first `:` is a kind
word. A stated kind that differs from the kind of the target must be
the finding `wrong-kind`. A citation that states `plan` or `task` must
be the finding `invalid-target`. A citation of the finding class of a
finding-class file must state the kind `finding-class`.

#### 5.2.4 The kind of an external id

@req external-kinds

An external id can take the kind `spec` or `term`, and only when its
citation states it. Any other stated kind of an external id must be the
finding `wrong-kind`. An external id can take a `#name`, and a stated
kind then states the kind of the named part. Sinter must check only
that the name matches the slug pattern.

#### 5.2.5 The declaration of a namespace

@req namespace-declaration

The manifest must declare each external namespace as a table under
`scan.namespaces`, with a required key `pattern`, an optional key
`tracker` whose only value is `"github"`, and a key `repository` of the
form `owner/name`, which is required when `tracker` is `"github"`. An
unknown key, or a value of the wrong type, must be an error of the
manifest that gives its place. A `pattern` that can match an id that
holds `#` or `@` must be an error of the manifest. The manifest must
not give a namespace a default kind.

#### 5.2.6 The targets of each citation

@req citation-targets

`@satisfies` and `@verifies` must name a requirement. `@cites` can name
any declaration or an external id. `@refines` can link a requirement, a
specification, or a design to another of these. `@supersedes` must link
two declarations of one kind, except in the form of requirement
`successor-by-name`. A citation whose target is of a kind that
the citation cannot take must be the finding `wrong-kind`. A citation
must not name a plan or a task.

#### 5.2.7 Classes that read the kinds

@req declaration-classes

`dangling` must report every citation whose target does not resolve,
except the citations that `renamed` or `invalid-target` reports.
`unbumped` and `wrong-source` must treat `spec` as a kind of
declaration. `untraced` must report requirements only.

#### 5.2.8 Finding-class files

@req finding-class-files

`@finding-class` must declare the finding class that a finding-class
file defines, in the place of `@rule`, and the kind of that
declaration must be `finding-class`. A finding-class file must hold
only a finding class that the repository defines. A finding-class file
whose front matter holds a rule in place of a finding class must be an
error of the file, as an unknown key is (`spec/manifest.md` section 14,
part 7). Until the design of rules (section 7) exists, Sinter must
evaluate no rule, and `unmet-rule` must report nothing.

### 5.3 Approval

#### 5.3.1 The subjects of approval

@req approval-subjects

An approval must bind to the name, the revision, and the extent hash of
one subject of approval: the prose of a design, a specification, a
requirement that a design holds outside every specification, or a
decision record. A decline must name one subject of approval and bind to
its extent hash alone, with no revision. A requirement inside a
specification must count as approved when its specification is approved.
A design must count as approved when its prose, each of its
specifications, and each requirement that it holds directly are
approved, and no entry records that state. A subject of approval is
awaiting approval when its kind needs approval, it is in force, and it
is not approved.

#### 5.3.2 What needs approval

@req approval-keys

`proof.req` must decide whether specifications and requirements need
approval. `proof.design` must decide whether the prose of designs needs
approval.

#### 5.3.3 Approving a whole design

@req approve-design

Given a design, the approval command must write one approval entry for
each subject of approval of the design that is awaiting approval. Given
one specification or one requirement that a design holds directly, it
must approve that subject of approval alone. Given a requirement inside
a specification, it must refuse, and name the specification to approve.

#### 5.3.4 The change since the latest approval entry

@req approval-delta

Before it asks the person, the approval command must show, for each
subject of approval, the change of its text since its latest approval
entry. The latest approval entry of a subject of approval must be, of
the `approval` entries whose `subject` names it, the one with the
greatest `seq`, whatever its `rev` and its `xh`. The text of that entry
must be the extent of the subject of approval in the tree of the commit
that the field `head` of the entry names. The command must show the
whole text when the ledger holds no approval entry of the subject of
approval, when the clone does not hold that commit, or when that tree
does not hold the subject of approval with the `xh` of the entry.

#### 5.3.5 Classes that read approvals

@req approval-classes

When `proof.req` is `"approval"`, `unapproved-req` must report each
`@satisfies` and each `@verifies` of a requirement that does not count
as approved. It must not report a citation of a requirement outside
every design, because that requirement is already the finding
`req-outside-design`. `awaiting-approval` must report each subject of
approval that is awaiting approval. `declined` must report each subject
of approval with a live decline.

### 5.4 Tasks and plans

#### 5.4.1 Ids

@req work-ids
@cites plan-ids

Sinter must give each task an id `t-` and each plan an id `p-`, each
followed by twelve lowercase hex digits from a random source, when it
creates the task or the plan. It must draw again when its copy of the
ledger holds the id. The id must be a field of the entry that creates
the task or the plan, and a replay must not change it. A replay must
drop the creation of a task or a plan whose id the new tip holds, and
tell the writer.

#### 5.4.2 Prefixes of ids

@req id-prefixes

A command must take a prefix of four or more digits in place of a full
id, written with the kind letter, `t` or `p`, and the hyphen, such as
`t-3f2a`, when exactly one task or plan of that kind starts with it. It
must report a prefix that matches several of them as an error that lists
them. Sinter must print the shortest prefix that is unique in its copy
of the ledger, with at least six digits. A delivery line, a `Task:`
line, and each field of a ledger entry must hold the full id.

#### 5.4.3 The definition of a task

@req task-definition

A task must have a display name, which can be empty only when the task
has an external item; its paths, a path set in the glob language of
`spec/manifest.md` section 7, which can be empty; its promises, each a
word, `satisfies` or `verifies`, and the full name of a requirement; at
most one external item; at most one plan; and a set of tasks and plans
that it waits for.

#### 5.4.4 The definition of a plan

@req plan-definition

A plan must have a display name that is not empty; at most one plan
that holds it; a set of tasks and plans that it waits for; and a set of
requirements, specifications, and designs that it carries out, by their
full names. The parts of a plan must be the tasks and the plans whose
definitions name it and that have not left it.

#### 5.4.5 Definition entries

@req definition-entries

A definition entry must hold the whole definition of one task or one
plan, and a definition number: 1 for the entry that creates the task or
the plan, and one more for each later definition. A definition must be
accepted when all of these hold, and only then: its number is one more
than that of the last accepted definition of the same task or plan, or 1
when the task or the plan has no accepted definition; it does not define
a task that is done or abandoned, or a plan that is abandoned; the plan
that it names, when it names one, exists and is not abandoned; each task
and plan that it waits for exists; and requirement `work-cycles` allows
it. The current definition of a task or a plan must be its latest
accepted definition. A definition that is not accepted must change
nothing, and it is a fault of the fold, not of the format. A definition
that names a done plan is accepted, and it makes that plan open again
when it adds a part that is not done. The command that writes a
definition must refuse a definition that would not be accepted, before
it writes.

#### 5.4.6 Cycles

@req work-cycles

Sinter must refuse a definition after which composition holds a cycle,
order holds a cycle, or the combined graph holds a cycle. The combined
graph must be the union of the edges of composition, from each plan to
each of its parts; the edges of order, from each task and from each
plan to each task and plan that it waits for; and the edges from each
task to each task and plan that a plan which holds it waits for, at any
level.

#### 5.4.7 The states of a task

@req task-states

The state of a task must be the result of a fold that applies these
steps to the entries: the entry that creates a task makes it open, or
delivered when the ledger already holds a `delivered` entry for the
task; a `delivered` entry changes the state as requirement
`delivered-fold` says; a `done` entry makes an open or delivered task
done; an `abandoned` entry makes an open or delivered task abandoned. An
entry must not change the state of a done or abandoned task.

#### 5.4.8 The states of a plan

@req plan-states
@cites ledger-open-plans v4

A plan must be done while it has at least one part and every part is
done, and no entry records that state. Sinter must compute the state
again after each entry, so a part that is not done makes a done plan
open again. The first `abandoned` entry of a plan must make the plan
abandoned, and each part of that plan that is not done must then leave
it. An abandoned task must leave its plan. When a task or a plan leaves
a plan, the fold must clear its plan. An abandoned plan must not change,
and a definition must not add a part to it.

#### 5.4.9 Ready tasks

@req ready-tasks

A task must be ready when it is open, each task and plan that it waits
for is done, each task and plan that a plan which holds it waits for is
done, at any level, and the ledger holds no `delivered` entry for the
task. A wait for an abandoned task or plan must never be met.

### 5.5 Delivery and tracing

#### 5.5.1 The task hash

@req task-hash

The task hash must be the SHA-256 of one JSON object in the canonical
form of `spec/jsonl.md` section 2, with no LF at its end, with two keys:
`paths`, the globs of the paths of the task, each once, in byte order;
and `promises`, one object with the keys `target` and `word` for each
promise, sorted by `word` and then by `target`.

#### 5.5.2 The delivery line of a task

@req task-delivery-line
@cites delivery-lines

Sinter must read each line of a commit message of the change of the form
`Delivers: <task id> <hash>`, where `<hash>` is the six characters of
the line, each a lowercase hex digit, as a delivery line of that task.
The line must count for the task when the ledger holds the task, the
task is unfinished, and the six characters are the first six characters
of its current task hash, the task hash of its current definition. Each
line of a commit message that starts with `Delivers: ` and does not
count for a task must be the finding `stale-delivery`.

#### 5.5.3 The `Task:` line

@req task-line

A commit that does part of a task can name it with a line
`Task: <task id>`, which carries no hash. Such a line must give the
change its task only when the ledger holds the task and the task is
unfinished. A `Task:` line that names an unknown or a finished task
must give no finding of its own.

#### 5.5.4 Met promises of a task

@req task-promises-met

A promise of a task must be met when a citation of its word exists
inside the paths of the task, its target resolves to the requirement of
the promise, the citation is not suspect, and, for `verifies`, the
citation is at a rung that `proof.verifies` allows
(`spec/manifest.md` section 10.3). A promise of a task of the change
(requirement `planned-changes`) that only a citation outside the paths
of the task would meet must be the finding `promise-outside-paths`. A
promise of any other task must not give that finding.

#### 5.5.5 The checks of a delivery

@req task-delivery-checks

Sinter must report a delivery line that counts for a task with a
promise that is not met as `delivery-on-unmet-task`; an unfinished task
whose promises are met in the tree of the last commit and not all met
in the base,
when no delivery line of the change counts for it, as
`missing-delivery`; and a task for which a delivery line counts, when no
hunk of the change lies in its paths, as `delivery-without-change`.
These classes and `stale-delivery` must keep the tiers that the
delivery classes of steps have. When no test evidence exists for the
tree, `delivery-on-unmet-task` and `missing-delivery` must count a
promised `verifies` as met when a `verifies` citation with its target
exists inside the paths of the task, its source is a test, its target
resolves, and it is not suspect.

#### 5.5.6 The `delivered` entry of a task

@req task-delivered-entry
@cites ledger-delivered v2

For each delivery line of a task in the commits of the range of its run
(`spec/ledger.md` section 8.4), the job on the default branch must
append one `delivered` entry, whatever the state of the task. The common
field `head` of the entry must hold the head of the run. The entry must
hold only these facts: the task that the line names in `subject`; the
six characters of the line, as written, in `hash_prefix`; the finishing
commit of the line in `commit`; in `merge`, the commit of the
first-parent line of the default branch that brought the finishing
commit, which is the finishing commit itself after a squash merge; and
in `revisions`, one element for each requirement that the current
definition of the task promises, with its full name, its revision `rev`
in the tree of `head`, and `met_at_head`. The value of `met_at_head`
must say whether each promise of that requirement is met, as requirement
`task-promises-met` says, with the test evidence of the run, in the tree
of `head`. For a promised requirement that the tree of `head` does not
hold, the element must hold its full name, no `rev`, and `met_at_head`
false. For a task that the ledger does not hold, `revisions` must be
empty. The entry must not hold a field that says whether the task is
done or whether the line was stale. The job on the default branch must
not append an entry whose fields `subject`, `commit`, and `hash_prefix`
equal those of an entry of the ledger, or an entry that closes a plan.

#### 5.5.7 The fold of a `delivered` entry

@req delivered-fold

For each `delivered` entry, the fold must compare the six characters of
`hash_prefix` with the first six characters of the task hash of the
current definition of the task at that point of the fold, which is the
definition that was current when the entry was appended. An entry for a
task that is done or abandoned must change nothing. An entry for a task
that the ledger does not hold at that point of the fold must stay in the
fold, and the first definition of that task must then make the task
delivered. An entry whose six characters equal those of that task hash,
with `met_at_head` true for each element of `revisions`, must make an
open or delivered task done. Every other entry must make an open task
delivered. When the six characters differ from those of that task hash,
and only then, `sinter status` must list the task as changed after its
finishing commit. The fold must read the promises only as the entry
records them for the tree of its `head`, and never in the current tree.

#### 5.5.8 Changes that tasks cover

@req planned-changes

The tasks of a change must be the tasks that the `Delivers:` lines and
the `Task:` lines of the commits of the change give it, and only those.
A delivery line must give the change its task when the ledger holds the
task and the task is unfinished, whether or not the line counts for the
task. A line that does not count for its task must still be the finding
`stale-delivery`, as requirement `task-delivery-line` says. A hunk of
the change that the paths of none of those tasks cover, that no exempt
path holds, that no triggered rule covers, and that is no mechanical
repair must be the finding `unplanned-change`. Until the design of rules
(section 7) exists, Sinter must count no hunk as covered by a triggered
rule.

#### 5.5.9 Classes that read the tasks of a change

@req task-classes

`unmet-promise` must report each promise of a task of the change that is
not met, with the tier `off` at `review` and no tier at `merged`.
`sinter status --done` must read the commits only, as requirement
`review-reads-commits` says, and must exit with code 0 only when every
promise of every task of the change is met.

### 5.6 The ledger

#### 5.6.1 Kinds of entry

@req entry-kinds
@cites ledger-common-fields v4

The ledger must hold these kinds of entry: `task` and `plan`, which are
definitions; `approval`, `decline`, `done`, and `abandoned`, which are
judgments; `delivered`, which is evidence; and `void`. The field
`subject` of an entry must name what the entry is about by its kind and
its full name or its id, such as `req:ledger#chunk-size` or
`task:t-3f2a9c1d7e0b`. A plan that another plan holds must name it in
the field `plan`. A field with no value must be left out, and a field
whose value is an empty array must be written `[]`. The field `note` of
a `done` entry is optional, and the field `reason` of an `abandoned`
entry is required.

#### 5.6.2 The writers of the ledger

@req ledger-writer-classes
@cites ledger-writers v7
@cites agent-statements

The commands that write definitions must run for a person and for an
agent. The commands that write judgments must read their confirmation
from the controlling terminal, and must refuse with exit code 4 when the
environment holds an agent marker. A command other than the job on the
default branch must not write a `delivered` entry. A repair must refuse
when the environment holds an agent marker. A definition must not make
a task done, and must not approve or decline a subject of approval.

#### 5.6.3 Authors of entries

@req entry-authors

Each entry must hold in `by` the identity that git reports, as
`Name <email>`, from `user.name` and `user.email` at the time of the
write: the person who wrote the entry, or who runs the agent that wrote
it. A command must refuse to write when git reports none. When an
agent marker is set, a command that writes a definition must write the
identity of the agent in `agent`, from the option `--agent` or else
from the environment variable `SINTER_AGENT`, and must refuse to write
when neither gives one. The MCP server must read `SINTER_AGENT` when it
starts, must write that identity in `agent` of each definition that it
writes, and must refuse each call of a tool that writes a definition
when the variable gives no identity. A judgment must not hold
`agent`.

#### 5.6.4 The replay of a definition

@req definition-replay
@cites ledger-push-recovery v2

A replay after a lost push must check each definition again against the
folds of the new tip, with no question to anyone. It must keep each
definition that would be accepted there, with a new `seq` and a new
entry id and every other field as it was. It must drop each definition
that would not be accepted there, and each later unpushed definition of
the same task or plan. It must tell the writer of each dropped
definition which task or plan it dropped.

#### 5.6.5 Writing a definition

@req definition-push

A command that writes a definition must fetch the ledger ref of the
remote `origin` before it writes, and push after it writes. When the
push loses, it must replay and push again, up to five tries in all. A
replay must cover every unpushed entry of the clone, in the order of
`seq`: it must replay each definition as requirement `definition-replay`
says, and each judgment as `spec/ledger.md` section 3.2 says. A replay
that needs to ask no one must move a judgment unchanged, except its
`seq` and its entry id. When an agent marker is set, a push or a replay
that meets an unpushed judgment that needs the person, because the
replay would ask the person again or drop the judgment (steps 4 and 5
of `spec/ledger.md` section 3.2), must stop before that judgment, keep
every unpushed entry in the clone, warn that a person must run
`sinter ledger push` at a terminal, and exit with code 0. A push that
wins must write no entry. A fetch or a push that fails because the
remote cannot be reached must count as a lost try. When the tries run
out, or the clone has no remote, it must keep the entries in the clone,
warn, flag them in its JSON output as not pushed, and exit with code 0.
With `--local`, it must not fetch and must not push.

#### 5.6.6 Pushing later

@req ledger-push

`sinter ledger push` must push the entries that the clone holds and
the remote does not, and must replay as requirement `definition-push`
says when the push loses. It must not refuse to run when an agent
marker is set.

#### 5.6.7 A ledger out of sync

@req ledger-sync-state

Sinter must keep the ref `refs/sinter/remotes/origin/ledger`, which
records the tip of the remote at the last fetch or push of the ledger.
When the local tip holds entries beyond that tip, or the two have
diverged, `sinter status` and the commands that write the ledger must
report that the ledger is out of sync, and `sinter check` must warn of
it. The warning of `sinter check` must also say that CI does not see
the entries that the clone has not pushed until `sinter ledger push`
runs, and it must not change the exit code of `sinter check`, with or
without `--preview`. The state of sync must be `absent` when the clone
holds no ledger ref; otherwise `unknown` when the ref
`refs/sinter/remotes/origin/ledger` is absent; otherwise `out-of-sync`
when the ledger is out of sync; and otherwise `in-sync`. `sinter check`
must write its warning for a ledger out of sync, and its warning for an
absent ledger, each as a line on standard error. The JSON `summary`
record must hold the state of sync in the field `ledger_sync`.

### 5.7 External items and the index file

#### 5.7.1 External items

@req external-items

A task can name one external item. Sinter must not write content of an
external tracker into the ledger, and must not write to an external
tracker. A check, and a state of a task or of a plan, must not depend on
the content of an external tracker. `sinter check` must not read the
network.

#### 5.7.2 Reading a tracker

@req tracker-fetch

`sinter tracker fetch` must read, for each external item that a task
names, its title, its state, and its address from the tracker that the
table of its namespace names, and must write them into the index file
with the time of the read. It must take its token from the environment
variable `GH_TOKEN`, or else from `GITHUB_TOKEN`, and must not take a
credential from the manifest. It must not write the ledger. It must
support GitHub.

#### 5.7.3 Names from external items

@req item-names

A command must not copy the title of an external item into the display
name of a task. A task with an external item and an empty display name
must show the title of the external item from the index file, or its
external id when the index file holds no title.

#### 5.7.4 The age of the content of trackers

@req tracker-staleness

`sinter status` must say when the index file holds no content of
trackers, and must otherwise print the time of the oldest read of that
content.

#### 5.7.5 The index file

@req index-file

Sinter must keep the states of the ledger and the content of trackers in
the SQLite file `sinter/index.db` under the common folder of the git
repository. `sinter status`, `sinter task`, `sinter plan`,
`sinter brief`, `sinter tracker fetch`, and the MCP tools must build the
file from the ledger when it is absent, and must bring it up to date as
requirement `index-freshness` says before they read it. A build must not
read the network. A command that cannot take a lock on the file within
five seconds must compute the states of the ledger from the ledger, and
must show no content of trackers, as when the file holds none.
`sinter tracker fetch` must then write nothing, must say that another
process holds the file, and must exit with code 3.

#### 5.7.6 A current index file

@req index-freshness
@cites ledger-event-log

The index file must record the commit of the ledger tip that it
reflects, the greatest `seq` of that tip, that this tip passed the check
of `spec/ledger.md` section 13.3, and the version of its layout. Before
it reads the index file, a command that requirement `index-file` names
must compare the current tip with the recorded tip. When the recorded
tip is an ancestor of the current tip, the command must check that the
newer commits only add lines, and change and remove no line of the
recorded tip. When the recorded tip is the current tip, or an ancestor
of it whose newer commits only add lines, the command must read only the
chunks that the newer commits change, apply the entries with a `seq`
above the recorded one, and run the check of `spec/ledger.md` section
13.3 only over the lines that the newer commits add, against the state
that the index file records. Otherwise, or when the clone does not hold
the recorded commit, it must run the whole check of the tip, build the
states of the ledger again, and keep the content of trackers. When the
version of the layout differs, it must build the whole file again, with
no content of trackers. Each state of the ledger that a command reads
from the index file must equal the state that the folds compute from the
ledger.

#### 5.7.7 The check and the index file

@req check-index

`sinter check` must use the states of the ledger from the index file
only when the file exists, its recorded tip is the current tip, and its
layout version is the version that the tool writes, and must compute
them from the ledger otherwise. When it uses them, it must not repeat
the check of the tip of `spec/ledger.md` section 13.3, and at the gate
`merged` it must still check the history as `spec/ledger.md` section
13.4 says. It must not write the index file. With `--no-cache`, it must
not read the index file.

### 5.8 Reading the work

#### 5.8.1 The output records of ready tasks

@req ready-task-records

`sinter task list --ready -o json` must print one output record for each
ready task, with its full id, its display name or the title of its
external item, its task hash, its paths, its promises, its external
item, the chain of plans that hold it, the ids of the other unfinished
tasks whose paths overlap its paths, and a flag when it promises a
requirement that the current tree does not hold. Two path sets overlap
when some file of the tree matches both; a file that the tree does not
hold makes no overlap.

#### 5.8.2 The brief of a task

@req task-brief

`sinter brief --task <id>` must print, in this order: for each
requirement that the task promises, the extent of its specification,
which holds the requirement, or the extent of the requirement when its
design holds it directly, and the prose of its design, each extent once,
with no requirement printed again apart from the extent of its
specification; the extents of the requirements, specifications, and
designs that the plans which hold the task carry out; for a task with no
promise and with no plan above it that carries anything out, its display
name and its external item, with the content of the item from the index
file; and then the decision records in force that the paths of the task
reach, the live declines of the subjects of approval that it prints, and
the findings that block at the gate `review`. The size limit of the
brief, which `--budget` sets, must cut from the end. With `--no-limit`,
it must print the whole brief. The brief must also tell the agent that
it can run `sinter check --gate review --preview` after a commit, and a
plain `sinter check` before a commit.

#### 5.8.3 The tools of the MCP server

@req mcp-work-tools

The MCP server must offer tools that list the ready tasks, print the
brief of a task, show a task and a plan, and write definitions, with the
same output as the commands of the same names. It must not offer a tool
that writes a judgment.

#### 5.8.4 The status of the work

@req work-status

`sinter status` must print each open plan with its parts and their
states, the open plans with no part, the ready tasks, the delivered
tasks, with the tasks that changed after their finishing commit, the
tasks that a wait for an abandoned task or plan blocks, the ready tasks
that promise a requirement that the tree does not hold, the
requirements that no work accounts for, the definitions whose field
`branch` names the current branch, and whether the ledger is out of
sync.

#### 5.8.5 The summary of a change

@req change-summary

`sinter status --change -o markdown` must print, for each task of the
change, the current paths and promises of the task, and every
definition of that task and of each plan that holds it, from the first
to the last, whatever its field `branch` holds, with the fields `by`,
`agent`, and `branch` of each. It must mark each such definition whose
field `branch` names the branch of the change. It must also print each
other definition whose field `branch` names the branch of the change.
It must not use the field `head` to choose definitions.

#### 5.8.6 Requirements accounted for

@req accounted-for

A requirement must count as accounted for when an unfinished task
promises it; when an open plan carries out the requirement, its
specification, or its design; or when a done task promised it and the
requirement has the revision that the entry which made the task done
records. A `delivered` entry must record the revision of each promised
requirement in the tree of its `head`, the head of the run, and a
`done` entry in the tree of the commit that its writer had checked
out, which its `head` names. `sinter status` and
`sinter status -o json` must list the requirements that no work
accounts for. A finding class must not report them.

#### 5.8.7 The commands of the work

@req work-commands

`sinter task new`, `sinter task edit`, `sinter plan new`, and
`sinter plan edit` must write definitions, and one call must write one
entry. `sinter task show`, `sinter task list`, `sinter plan show`, and
`sinter plan list` must not write. `sinter task done`,
`sinter task abandon`, and `sinter plan abandon` must write judgments.

#### 5.8.8 The delivery line to copy

@req task-show

`sinter task show <id>` must print the delivery line of the task, with
its full id and the first six characters of its current task hash.

#### 5.8.9 The filters of the ledger log

@req ledger-log-filters

`sinter ledger log` must print only the entries whose field `branch`
names the branch of `--branch`, whose field `subject` is the value of
`--subject`, and whose kind is the value of `--kind`, for each of these
options that the command line gives.

#### 5.8.10 The tiers of the new classes

@req new-class-tiers

`misplaced-declaration`, `req-outside-design`, `wrong-kind`, and
`extern-mismatch` must block at the gates `review` and `merged`.

### 5.9 The check at hand-back

#### 5.9.1 The gates

@req check-gates

The gates must be `review` and `merged`. The option `--gate` of
`sinter check` must take only these two. A key
`check.tiers.turn.<class>` in the manifest must be an error, as for
every other gate that does not exist.

#### 5.9.2 The commits at review

@req review-reads-commits

`sinter check --gate review` must compute its findings from the tree of
the last commit and the commit messages of the change. It must not
compute a finding from work that is not committed.

#### 5.9.3 The preview

@req preview-check

With `--preview`, `sinter check --gate review` must print every finding
that it prints without `--preview`, with the same tiers. Its exit code
must not depend on a finding of `untraced`, `unmet-promise`,
`awaiting-approval`, or `unapproved-req`, and it must mark each such
finding "does not block at preview". It must detect whether work that
is not committed exists: a change of a tracked file, in the working tree
or in git's index, that the last commit does not hold, or a file that
git neither tracks nor ignores. When such work exists, it must tell the
person to commit that work first, and it must exit with code 1,
whatever its findings.

#### 5.9.4 The declared task

@req declared-task

`sinter declare --task <id>` must record the task in the session. The
declared task must not change a finding or a state, and must not allow
a path. Sinter must use it only to narrow the brief to that task.

## 6. Test plan

The section "Tests" of `CONTRIBUTING.md` applies: every exported
function has a test through its interface; every property of an output
is a property test with generated inputs; every decoder of outside data
has a test with generated and corrupted inputs; and every exit code and
every error message has a test through the built binary. The mutation
pass runs on each change to `lib/` or `bin/`, as the section "Mutation
testing" of `CONTRIBUTING.md` says.

These levels of test verify the requirements of section 5:

- **property tests** of the folds, with generated sequences of
  definitions, judgments, and deliveries;
- **case folders** with a tree, a fixture ledger (`ledger.jsonl`, one
  canonical line for each entry), and the expected output;
- **tests through the binary**, for commands, exit codes, refusals, and
  messages;
- **repository tests**: temporary git repositories with a bare remote,
  for pushes, replays, and the job on the default branch;
- **measurements** in the benchmark of `CONTRIBUTING.md`, section
  "Performance".

| requirements | level | what the tests show |
|---|---|---|
| `design-declaration`, `design-extent`, `spec-declaration`, `spec-extent`, `requirement-membership`, `design-names` | case folders; property tests of the extent hash | the extent of a design leaves out its specifications and requirements; an edit of a requirement changes the hash of its specification; a bare raise of the revision of a requirement does not; each misplaced declaration gives its finding, a specification inside another specification and a requirement with a full name in another markdown file included; a `@spec` with a full name in the section of another design, a `@spec` with its name alone outside the section of every design, a declaration other than a requirement inside the section of a specification, and a second declaration in the markdown file of a specification each give `misplaced-declaration`; a `@spec` with a full name whose design does not exist gives `misplaced-declaration`, and its citations still resolve; a file that holds two designs gives each design the declared items of its own section; the extent of a requirement inside a specification leaves out the requirements nested in it, and the extent of the specification holds them all; a requirement outside every design gives `req-outside-design`, and its citations still resolve; a `@req` with a full name whose design does not exist gives `misplaced-declaration` and no `req-outside-design`, and its citations still resolve; a `@req` with a full name of another design in the markdown file of a specification gives `misplaced-declaration`, and belongs to that specification; a `@design` inside the section of another design and a `@design` in a code comment each give `misplaced-declaration`; two names of one design that differ only in case give `duplicate`; a name inside a design that fails the slug pattern gives `invalid-target` |
| `spec-in-code` | case folders in each language pack | the body of a specification follows the code that its run attaches to; when a nested specification gives `misplaced-declaration`, a requirement belongs to the nearest body; an API comment in the body changes no hash, and neither does a comment in the same run outside the blocks of the specification and its requirements; the extent of a requirement in code is its block, so a comment in its run outside its block changes neither its extent hash nor that of its specification; the hash joins the blocks in the order of the file; a nested specification gives its finding; a file-level `@spec` after a license header owns the file; a `@spec` in a later run that attaches to no code gives `misplaced-declaration` |
| `extern-marks` | case folders | each of the three cases gives `extern-mismatch` with its detail; a correct mark gives none; adding a mark changes the hash of the design; a mark that stands in the own prose of no design, a mark with no kind word, and a mark with another kind give their findings |
| `deprecated-spec`, `retirement-cascade`, `successor-by-name`, `effective-supersedes` | case folders | a specification with `@deprecated` is retired; a retired design retires each of its specifications and requirements, and a retired specification each of its requirements; a requirement moved out first stays in force; a citation of a retired declared item retires nothing; a `@supersedes` of a design gives a declared item of it no successor; `@supersedes docs#* v3` retires `docs` and each of its specifications and requirements, gives each declared item the declared item of the same name and kind as its successor, and gives a declared item with no match none; where `proof.req` or `proof.design` requires approval, a `@supersedes` retires nothing until its source counts as approved, whether its source is a design, a specification, a requirement inside a specification, or a requirement that a design holds directly; a `@supersedes` whose source is a requirement inside a specification retires its target when that specification is approved; a `@supersedes` whose source is a requirement outside every design never retires anything where `proof.req` requires approval |
| `target-reading`, `relative-names`, `kind-words`, `external-kinds`, `citation-targets`, `declaration-classes` | property tests of the parser; case folders | generated targets read the same after printing; each target has exactly one reading; a kind word with `#` states the kind of the named part; `#name` resolves only in its home design; each wrong kind gives `wrong-kind`; a citation target with no `#` never resolves inside a design; a citation `#name` in the run of a `@spec` in code resolves in the design of that specification; a name after `#` that fails the slug pattern, and a `#*` outside the form of `successor-by-name`, give `invalid-target`; a `#name` after a decision record gives `wrong-kind`; a `#name` after a target that resolves to nothing gives `dangling` and no `wrong-kind`; `unbumped` applies to a specification; a design is never `untraced`; an `@ack` with a full name in the subject of its finding still reads |
| `namespace-declaration` | tests of the manifest reader | a namespace as a string is an error; an unknown key, a wrong type, and a `tracker` with no `repository` are errors with their place; a `pattern` that can match an id that holds `#` or `@` is an error |
| `finding-class-files` | case folders; tests of the reader of finding-class files | `@finding-class` declares the finding class of a finding-class file; a citation of it with the kind `finding-class` resolves; a finding-class file that holds a rule is an error with its place and exit code 3; `unmet-rule` reports nothing |
| `approval-subjects`, `approval-keys`, `approve-design`, `approval-delta`, `approval-classes` | property tests of the folds; tests through the binary | a requirement inside an approved specification counts as approved; an edit ends only the approval of its subject of approval; one run on a design writes one entry for each subject of approval that is awaiting approval; a requirement inside a specification is refused with the name of the specification; the change since the latest approval entry shows before the question, also when that entry approved an earlier revision; the whole text shows when the subject of approval has no approval entry, or when the tree of the `head` of that entry does not hold the approved text; a decline holds the extent hash of its subject of approval and no revision; `unapproved-req` reports nothing when `proof.req` is not `"approval"`; a citation of a requirement outside every design gives `req-outside-design` and no `unapproved-req`; `awaiting-approval` reports the prose of a design when `proof.design` is `"approval"` |
| `work-ids`, `id-prefixes` | property tests; tests through the binary | ids follow the pattern; a clash draws again; a replay keeps the id; a replay drops the creation of a task or a plan whose id the new tip holds, and tells the writer; a unique prefix such as `t-3f2a` resolves, and an ambiguous one lists its matches |
| `task-definition`, `plan-definition`, `definition-entries`, `work-cycles` | property tests of the folds; tests through the binary | for every generated sequence, no accepted definition makes a cycle in any of the three graphs; a definition with a stale number is not accepted; a definition of a done or abandoned task, or of an abandoned plan, is not accepted; a definition that names a plan that does not exist or that is abandoned, and a definition that waits for a task or a plan that does not exist, are not accepted, and the command refuses them; a definition that is not accepted changes nothing; a definition that adds a part to a done plan is accepted; a plan with an empty display name is refused |
| `task-states`, `plan-states`, `ready-tasks` | property tests of the folds, against a plain model of the states | for a task, done and abandoned stay so for every extension of the sequence; a task whose first definition comes after a `delivered` entry for it starts delivered, and is never ready; a plan is done exactly when it has a part and every part is done; a new part that is not done makes a done plan open again; an abandoned plan never changes; a task or a plan that leaves a plan shows no plan; ready matches the model; a wait for an abandoned task or plan is never met |
| `task-hash`, `task-delivery-line`, `task-line` | property tests; case folders | the hash does not change when the order of paths or promises changes, or when the display name, the external item, the plan, or the waits change; it changes when a path or a promise changes; a stale line, and a line of the old form, give `stale-delivery` |
| `task-promises-met`, `task-delivery-checks`, `planned-changes`, `task-classes` | case folders with commit messages | each delivery finding at its gates; a promised `verifies` with no evidence counts as met when its test exists; a promise of a task of the change that only a citation outside the paths of the task meets gives `promise-outside-paths`, and a promise of a done task gives none; a delivery line that does not count for its unfinished task still gives the change that task, and gives `stale-delivery`; a hunk outside the paths of the tasks of the change gives `unplanned-change`, and a hunk inside them gives none; `status --done` exits 0 only when every promise is met; work that is not committed changes no finding, and no result of `status --done`; a task declared in the session gives no allowed path |
| `task-delivered-entry`, `delivered-fold` | repository tests of the job on the default branch; property tests of the folds, against a plain model of its steps | the job on the default branch writes one entry for each delivery line, also for a done or abandoned task; the entry holds in `head` the head of the run, in `hash_prefix` the six characters as written, in `commit` the finishing commit, in `merge` the commit of the first-parent line that brought it, after a merge commit and after a squash merge, and for each promised requirement its revision and `met_at_head` in the tree of `head`; a promised requirement that the tree of `head` does not hold gives an element with its full name, no `rev`, and `met_at_head` false; an entry for a task that the ledger does not hold has empty `revisions`; a second run writes no second entry; an entry whose six characters equal those of the task hash of the definition that was current when the entry was appended, with every promise shown met, makes the task done; a promise not shown met makes it delivered; an entry whose six characters differ from those of that task hash makes it delivered, and `sinter status` lists it as changed after its finishing commit; a change of the display name alone after the finishing commit does not keep the task from becoming done, and gives no such listing; an entry for a done or abandoned task changes nothing; an entry for a task that the ledger does not hold yet makes the task delivered when its first definition comes, and `sinter status` lists it with the delivered tasks; a later change of the tree changes no state |
| `entry-kinds`, `ledger-writer-classes`, `entry-authors` | tests through the binary | each judgment refuses with exit code 4 under an agent marker; a repair refuses under an agent marker; a definition under an agent marker refuses without an identity of the agent; the MCP server refuses a tool that writes a definition when `SINTER_AGENT` gives no identity; `by` holds the identity of git; a command refuses to write when git has no identity; a judgment holds no `agent`; a `done` entry without `note` reads, an `abandoned` entry of a task or of a plan without `reason` is a fault of its line, a field with no value is left out, and a field whose value is an empty array is written `[]` |
| `definition-replay`, `definition-push`, `ledger-push`, `ledger-sync-state` | repository tests with two clones | two writers that change one task at once end with one change accepted and one writer told; a replay asks no one; a replay that drops a definition also drops each later unpushed definition of the same task or plan, and tells the writer of each; a replay of a clone that holds definitions and judgments handles them in the order of `seq`, each by the steps of its kind; `sinter ledger push` under an agent marker pushes a judgment when its push wins; a replay that needs to ask no one moves a judgment with a new `seq` and a new entry id and no other change; under an agent marker, a push or a replay that meets a judgment that needs the person stops before it, keeps every unpushed entry in the clone, warns that a person must run `sinter ledger push` at a terminal, and exits with code 0; a remote that cannot be reached counts as a lost try; when the tries run out, the entries stay in the clone, the command warns, its JSON output flags them, and it exits with code 0; with `--local`, no fetch and no push happen, and `sinter ledger push` later pushes the entries; an unpushed entry gives the report of a ledger out of sync; `sinter check`, with and without `--preview`, warns of it on standard error with the sentence that CI does not see the unpushed entries until `sinter ledger push` runs, and exits with the code that it gives with no unpushed entry; the field `ledger_sync` holds `in-sync`, `out-of-sync`, `unknown`, or `absent` in each case; with no ref `refs/sinter/remotes/origin/ledger`, the state of sync is unknown, not out of sync; with no ledger ref, the state of sync is `absent`, also when the ref `refs/sinter/remotes/origin/ledger` is absent |
| `external-items`, `tracker-fetch`, `item-names`, `tracker-staleness` | tests through the binary against a recorded answer of the tracker | the command writes the index file and never the ledger; it takes its token from `GH_TOKEN`, else from `GITHUB_TOKEN`, and never from the manifest; no other command reads a tracker; a task with an empty display name shows the title; `sinter status` says when the index file holds no content of trackers |
| `index-file`, `index-freshness`, `check-index` | property tests; repository tests with two processes | for generated sequences and generated points of deletion and change of the tip, every state of the ledger from the index file equals the state that the folds compute from the ledger; a repair that drops an entry below the recorded `seq` causes a rebuild, and so does a replay; a newer commit that changes or removes a line of the recorded tip causes the whole check of the tip and a rebuild; a different layout version builds the whole file again; `sinter check` never writes the file, and on a current index file it skips only the check of the tip; a held lock makes a command compute the states of the ledger from the ledger and show no content of trackers, and makes `sinter tracker fetch` write nothing and exit with code 3 |
| `ready-task-records`, `task-brief`, `mcp-work-tools`, `work-status`, `accounted-for`, `work-commands`, `task-show`, `ledger-log-filters` | tests through the binary; tests of whole MCP exchanges, byte for byte | each output record and each brief holds its parts in order; each brief tells the agent when it can run a check; `--no-limit` prints the whole brief; the MCP tools give the same output as the commands; no MCP tool writes a judgment; a requirement whose revision rose after its delivery shows among the requirements that no work accounts for; `sinter task show` prints the current delivery line; each filter of `sinter ledger log` keeps only its entries |
| `new-class-tiers` | tests through the binary | each new class blocks at each gate |
| `change-summary` | repository tests with two branches | every definition of a task of the change, and of each plan that holds it, shows in the summary of the change, from the first to the last, whether it was written from the branch of the change, from another branch, from the default branch, or from no branch; the definitions from the branch of the change carry the mark; each definition shows its person, its agent, and its branch; a definition written from the branch of the change, of a task or a plan that is not of the change, also shows; the field `head` changes nothing in the summary |
| `check-gates`, `review-reads-commits`, `preview-check`, `declared-task` | tests through the binary; repository tests | `--gate turn` and a key `check.tiers.turn.<class>` are errors; the check at `review` gives the same findings with and without uncommitted work; with `--preview`, each finding prints with its tier, the four classes carry the mark and do not change the exit code, a blocking finding of another class gives exit code 1, and uncommitted work gives exit code 1 with the message to commit it first, while the findings stay those of the commits; a declared task changes no finding and no state |

**Measurements.**

1. The time and the memory of a full build of the index file from
   ledgers of 1,000, 100,000, and 1,000,000 entries, with a growth
   limit (`CONTRIBUTING.md`, section "Performance"), as the other
   commands of the ledger have.
2. How often pushes collide when several writer processes write
   definitions to one bare remote, and how long a write takes to reach
   the remote. The rates of writes are still to be set. No tool has
   published this measurement. Its result can change the design of the
   five tries of a command that writes a definition (section 3.11).
3. The time of `sinter task list --ready` from the index file and from
   the ledger, at 100,000 entries.

## 7. Open questions

- **Edits that keep the meaning.** A way to make an edit that does not
  change the meaning, such as a fix of formatting, of the order of
  sections, or of a typo, without a new revision.
- **A dictionary of terms.** A later feature with a design of its own,
  declared with `@term`. Section 3.4 gives what this design fixes for
  it: the kind word `term`, and a slug of a term that can hold a custom
  namespace. That design decides the rest, such as which set of names
  its terms belong to and how a citation names one.
- **Writing to external trackers.** Sinter does not write to a tracker
  now.
- **References across repositories,** and the meaning of the reserved
  `@` in a tag target. One candidate is an exact pin by the first digits
  of an extent hash. It closes the case that this design leaves to that
  work: a reference that the checks of one repository do not see. The
  namespaces of section 3.4 already give a form for such a reference: a
  namespace that the manifest declares could stand for another
  repository, as the external namespace `gh` stands for a tracker. The
  later work on references across repositories starts from that form.
- **Signing.** The design notes already describe a check of signed
  ledger commits, `sinter ledger verify --signers`
  (`docs/design-notes.md` section 6.4). Open: which entries are signed,
  and how a replay, which writes new commits, keeps a signature valid.
- **A specification in several places.** Two forms of one question: a
  specification continued in several places, for example begun in a
  client module and continued in a server module; and marks in the file
  of a specification for requirements that code declares. Both need an
  extent across files, whose order the places of the marks could give,
  revisions that couple across files, and a view that Sinter compiles,
  so that a reader still sees the whole contract. The guiding principle
  is that a specification hangs together as one text in one place.
- **A cache of the facts of the working tree** in its own table of the
  index file. Sinter builds the table again, or changes it, when git
  reports a state of the working tree that differs from the state that
  the table was built from.
- **A static web page** of plans and tasks, together with the views that
  `.plans/mcp-apps.md` describes (section 3.15). A web server in Sinter
  is not designed now, and it is not ruled out.
- **Reviews from the host.** The job on the default branch could record
  what the host says about the review of a delivering commit, as
  information only, together with the connection to GitHub.
- **Other trackers** than GitHub, and their keys in the table of a
  namespace.
- **The `pin` entry,** which is deferred (`spec/ledger.md` section 12),
  to find a change of an external item.
- **The inbox and the question of an agent before it writes.** The lists
  of `sinter status` (delivered tasks, blocked tasks, requirements that
  no work accounts for) are inputs of the inbox (`docs/design-notes.md`
  section 6.8). The brief of a task answers part of the question that
  an agent asks before it writes.
- **Inline citations in prose.** A citation inside the prose of an
  extent, read only inside the extent of a declaration, written as a
  markdown link with Sinter's own scheme, for example
  `[the size limit](sinter:req:packs#descriptor-size)`. The text then
  reads as its label wherever it is shown, and the markdown parser gives
  a link node. The design of names and citations decides the rest:
  whether such a citation can pin a revision, what a citation with no
  label shows, what happens to one outside the extent of a declaration,
  and whether a label is required.
- **Revisions as labels.** The design of names and citations decides
  this question, as it decides inline citations. The declarations of
  this design follow today's syntax: they carry no revision token, so
  each one is `v1` (`spec/vocabulary.md` section 5). The answer to this
  question would change that. Its points:
  - **The proposal.** A revision is a free-form label of ASCII
    characters that are not whitespace and not `/`. The form `vN` is
    recommended, not required. Sinter does not order labels. Today a
    revision must rise (`spec/vocabulary.md` section 9). Under the
    proposal, a changed extent takes a label that the declared item
    never had. Sinter checks a label against the earlier labels of the
    declared item. The job on the default branch records the label of a
    declared item, with its extent hash, in the ledger at each change on
    the default branch. Sinter's index holds those labels, so the check
    costs little. When the ledger holds no history of the declared item,
    the label must differ from the label of the declared item in the
    base.
  - **Points the later design takes as given:** Every revision is
    spelled exactly. There is no default `v1`.
  - **Points the later design weighs first:** The syntax is
    `target/rev`, and `/` also joins the segments of a slug (section
    3.4). A `@cites` with no pin writes `/*`, which means "any
    revision". The tag word decides whether its target always carries a
    revision or never does. An external id carries none. A revision
    follows the name that it pins: `docs#size/v2` pins the requirement
    `size`, and `docs/v3#*` pins the design `docs`. To parse a target,
    Sinter splits off the part after `#` first. When that inner part is
    `*`, the revision is the last segment of the head. Otherwise the
    revision is the last segment of the inner part, and the head carries
    none. So `docs/v3#size` is invalid.
- **Which citations of a retired declared item give `retired`.**
  `spec/vocabulary.md` section 8.2 says that a citation of a retired
  declared item is the finding `retired`. `spec/algebra.md` section 9
  defines `retired` over `@cites` edges only. Under section 3.2, a
  `@satisfies` or a `@verifies` of a requirement of a retired design
  also cites a retired declared item.
- **The design of rules:** when the check of a decision record runs,
  and which paths it applies to (record `rule-files`); how `@ack` and
  `unmet-rule` name a rule that lives in a decision record; and how a
  decision record carries both its license header and the front matter
  of its check, since the front matter of a finding-class file starts
  on its first line (`spec/manifest.md` section 14).
- **The versioned set of specifications.** The rewrite of `spec/` and of
  the design notes into designs decides what takes the place of the
  seven files that share one version (`docs/versioning.md`).
- **Namespaces for the designs of this repository,** decided during the
  rewrite of `spec/` and of the design notes (section 3.22).
