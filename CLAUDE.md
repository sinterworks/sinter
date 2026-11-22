# Working in this repository

This file orients a session in the Sinter repository, whether a
person, a person's coding agent, or a subagent runs the session.
`AGENTS.md` is a symbolic link to `CLAUDE.md`.

## Start here

Before you change anything, complete these three steps in order:

1. **Orient.** Read "What Sinter is" and "Layout" below. Sinter's
   design is being rewritten as a stack of layered designs (decision
   record `layered-designs`). Until that rewrite ends, the design notes
   (`docs/design-notes.md`), the specifications in `spec/`, and the
   decision records about the earlier design describe a design that no
   longer holds. Do not treat them as the current design. Follow the
   brief of your task: the written task that your session receives
   when it starts. Without a brief, follow the person you work with, or
   the plan step, the issue, or the request of step 3. `docs/roadmap.md`
   and `.plans/` still apply. So do the decision records that
   `CONTRIBUTING.md` and the files in `docs/contributing/` name for the
   project's procedures, such as commit messages and code comments
   (decision record `orient-on-brief`).
2. **Learn the rules.** Read `CONTRIBUTING.md` in full.
   `CONTRIBUTING.md` contains the writing rules for prose, for code
   comments, and for the messages that the tool prints.
   `CONTRIBUTING.md` also contains the build and check commands, the
   license headers, the commit rules, and the procedures for plans,
   decisions, and pull requests.
3. **Begin.** Find the plan step in `.plans/`, the issue, or the
   request that asks for the work. Work on a branch. Before every
   commit, run the checks.

If `CLAUDE.local.md` exists at the repository root, read that file
after `CLAUDE.md`. `CLAUDE.local.md` contains instructions for one
person's machine and method. Git ignores that file, and its
instructions bind only the sessions of the person who wrote it.

## What Sinter is

Sinter traces plans, requirements, decisions, and tests through a
repository. Sinter reads tags in the repository's own text files.
Sinter checks that code, tests, and documents keep the agreements
that a project made. Sinter reads the state of the work from files and
from test results. When an agent writes a statement in a file, that
statement counts only as a line of the diff. The statement stays tied
to the text that the statement describes, so that a person can check
the statement. Coding agents write most of Sinter. Sinter's own method
applies to Sinter.

## Layout

| path | content | license |
|---|---|---|
| `lib/` | the core library, `sinter.core`, and the bridge library | Apache-2.0 |
| `bin/` | the `sinter` executable | Apache-2.0 |
| `bridge/` | the Rust crate that loads grammars through wasmtime | Apache-2.0 |
| `test/` | the test suite and its fixtures | Apache-2.0 |
| `spec/` | the seven specifications of the earlier design | CC-BY-4.0 |
| `docs/` | the design notes, the roadmap, the decision records, and the procedures for contributors | CC-BY-4.0 |
| `.plans/` | plan files and their journals | Apache-2.0 |
| `plugins/` | the Claude Code plugin with the project's skills | Apache-2.0 |
| `.github/workflows/` | continuous integration (CI) workflows | Apache-2.0 |

## Which document wins

Until the rewrite ends, your brief, or without one the person you work
with, wins over the code and over the documents of the earlier design.
When your brief and such a document disagree, follow the brief, and
tell the person you work with about the disagreement. After the
rewrite, when the code and a specification disagree, the specification
wins. `docs/roadmap.md` lists agreed directions that do not
have designs yet. Until the maintainer asks, do not design a direction
from `docs/roadmap.md`.

## Writing

Follow the "Writing" section of `CONTRIBUTING.md` strictly. That
section applies to every text that you produce: documentation,
specifications, comments, commit messages, the tool's output, and
your replies to the person you work with. Write for the readers of the
repository, not for that person.
