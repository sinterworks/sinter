# Working in this repository

This file orients a session in the Sinter repository, whether a
person, a person's coding agent, or a subagent runs the session.
`AGENTS.md` is a symbolic link to `CLAUDE.md`.

## Start here

Before you change anything, complete these three steps in order:

1. **Orient.** Read "What Sinter is" and "Layout" below. Then read the
   documents that apply to your task: `docs/design-notes.md` for the
   design, `spec/` for the formats, `docs/roadmap.md` for the work
   ahead, and `docs/decisions/` for what is already decided.
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
| `spec/` | the seven normative specifications | CC-BY-4.0 |
| `docs/` | the design notes, the roadmap, and the decision records | CC-BY-4.0 |
| `contributing/` | the procedures for coverage, mutation testing, and performance | Apache-2.0 |
| `.plans/` | plan files and their journals | Apache-2.0 |
| `plugins/` | the Claude Code plugin with the project's skills | Apache-2.0 |
| `.github/workflows/` | continuous integration (CI) workflows | Apache-2.0 |

## Which document wins

When the code and a specification disagree, the specification wins.
When a specification and the design notes disagree, the specification
is the newer document. Tell the person you work with about that
disagreement. `docs/roadmap.md` lists agreed directions that do not
have designs yet. Until the maintainer asks, do not design a direction
from `docs/roadmap.md`.

## Writing

Follow the "Writing" section of `CONTRIBUTING.md` strictly. That
section applies to every text that you produce: documentation,
specifications, comments, commit messages, the tool's output, and
your replies to the person you work with. Write for the readers of the
repository, not for that person.
