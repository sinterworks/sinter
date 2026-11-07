<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Introduction

Your project has a requirement: a user session ends after 30 minutes
without activity. A guide for users repeats this fact. Then the
requirement changes to 15 minutes, and nobody edits the guide.

The guide is now wrong. No compiler reports the mistake, because a
compiler does not read a guide. No test fails, because no test reads
the guide. You learn about the mistake when a user follows the guide,
and the session ends sooner than the guide says.

Sinter is a command-line tool that reports this kind of mistake. You
add short lines to the text files of your repository. These lines give
names to parts of your text, and they say which text depends on which
other text. Sinter reads the lines, and it tells you which text can be
out of date.

Each of these lines is a *tag*. A tag is a line of text in your own
file. It is not a git tag, which is a name that a person gives to a
commit in git.

## Get Sinter

Sinter has no prebuilt release. You build it from its source code. You
need these programs:

- git 2.43.7 or later.
- [opam](https://opam.ocaml.org/), the package manager of OCaml.
- The Rust toolchain, from [rustup](https://rustup.rs).
- `cmake`.

Then run these commands in a terminal:

```sh
git clone https://github.com/sinterworks/sinter.git
cd sinter
opam switch create 5.5.2
eval $(opam env --switch=5.5.2)
opam install . --deps-only --locked
dune build @install
export PATH="$PWD/_build/install/default/bin:$PATH"
```

The last command puts `sinter` on the `PATH` of this terminal only. In
a new terminal, run it again in the folder `sinter`, or copy the file
`_build/install/default/bin/sinter` to a folder that is on your `PATH`.

## An example

Make an empty folder, and run `git init -b main` in it. Run all the
commands below in that folder.

Sinter reads its settings from the file `sinter.toml` in the top folder
of the repository. Write this text in the file `sinter.toml`:

```toml,file=sinter.toml
[scan]
packs.markdown.files = ["**/*.md"]
```

The file uses the TOML format. The line `[scan]` starts the settings
that tell Sinter which files to read. A *pack* is the part of Sinter
that reads one kind of file, such as Markdown. The line
`packs.markdown.files` gives the files that the Markdown pack reads.
The pattern `"**/*.md"` means each file whose name ends in `.md`, in
each folder.

Write the requirement in the file `docs/requirements.md`:

```markdown,file=docs/requirements.md
# Requirements

## Session length
@req session-length v1
A session ends after 30 minutes without activity.
```

A *revision* is a number that you raise each time you change the
meaning of a text. In a tag, `v1` means revision 1.

The line `@req session-length v1` is a tag. It says three things about
the section that holds it, "Session length":

- The section is a requirement.
- The name of the requirement is `session-length`.
- The section is at revision 1.

The requirement is the whole section, from its heading to the next
heading with the same number of `#` marks or fewer.

Write the guide in the file `docs/guide.md`:

```markdown,file=docs/guide.md
# User guide

## When a session ends
@cites session-length v1
Your session ends after 30 minutes without activity.
```

The tag `@cites session-length v1` says that the section "When a
session ends" depends on revision 1 of the requirement.

Commit the three files:

```console,run
$ git add .
$ git commit --quiet --message "Add the requirement and the guide"
```

Now the requirement changes. Change the time to 15 minutes, change the
revision to 2, and commit the change:

```markdown,file=docs/requirements.md
# Requirements

## Session length
@req session-length v2
A session ends after 15 minutes without activity.
```

```console,run
$ git commit --quiet --all --message "Make sessions shorter"
```

Nobody edited the guide, so the guide still says 30 minutes. Run Sinter:

```console,run
$ sinter check
suspect: the @cites names v1, and req:session-length is at v2
 --> docs/guide.md:4:1
  |
4 | @cites session-length v1
  |                       ^^ names v1
  |
 ::: docs/requirements.md:4:1
  |
4 | @req session-length v2
  | ---------------------- now at v2
  |
help: check that the citation still holds, then pin it to the current revision
  |
4 - @cites session-length v1
4 + @cites session-length v2
  |

untraced: nothing satisfies req:session-length, and nothing verifies it
 --> docs/requirements.md:4:1
  |
4 | @req session-length v2
  |      ^^^^^^^^^^^^^^ nothing satisfies it, and nothing verifies it
  |
2 findings in 2 files; 1 has a fix
```

Each problem that Sinter reports is a *finding*. Sinter writes the
requirement as `req:session-length`: the word of its tag without the
`@`, then its name.

The finding `suspect` says that the guide names revision 1 of the
requirement. The requirement is now at revision 2. Sinter cannot read
the meaning of the guide, so it does not say that the guide is wrong.
It tells you where to look.

The output uses some words of its own. A *citation* is a `@cites` tag.
To *pin* a citation is to write a revision in it. The lines after
`help` show a change to the tag: the line with `-` is the line as it is
now, and the line with `+` is the new line. "1 has a fix" means that Sinter
shows such a change for one finding. Sinter does not make the change.
You make it by hand, after you correct the text.

The finding `untraced` says that nothing satisfies the requirement, and
nothing verifies it. A `@satisfies` tag in code says that the code does
what a requirement asks. A `@verifies` tag in a test says that the test
checks it. This example has no code and no tests, so this finding is
expected here.

Correct the time in the guide, change the tag to revision 2, and commit
the change:

```markdown,file=docs/guide.md
# User guide

## When a session ends
@cites session-length v2
Your session ends after 15 minutes without activity.
```

```console,run
$ git commit --quiet --all --message "Correct the guide"
```

Run Sinter again:

```console,run
$ sinter check
untraced: nothing satisfies req:session-length, and nothing verifies it
 --> docs/requirements.md:4:1
  |
4 | @req session-length v2
  |      ^^^^^^^^^^^^^^ nothing satisfies it, and nothing verifies it
  |
1 finding in 1 file
```

The finding `suspect` is gone. The finding `untraced` stays, because
the example still has no code and no tests.

Each time, `sinter check` reports its findings and exits with the code
0, which means success. A finding does not make the command fail. With
the option `--gate`, some findings make the command fail with the code
1.
