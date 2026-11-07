<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Write the user manual as a tested book
@decision user-manual
The user manual of Sinter is a book with the title "Using Sinter". A test runs the examples of the book against the tool.

## Context

Sinter has a short `README.md`, design notes in `docs/design-notes.md`,
and specifications in `spec/`. None of these texts teaches a person how
to use the tool. A person who is new to Sinter reads to solve a
problem. An experienced user looks up one exact fact, such as an exit
code. Many features that the specifications describe do not exist in
the tool yet. Each plan step in `.plans/` can change what the tool
prints.

A *tag* is a line of text, such as `@req session-length v1`, that
Sinter reads in a file. A *coding agent* is a program that writes and
changes code from a person's instructions.

## Decision

- The book teaches a developer who has a repository of their own. Each
  chapter adds one idea to the last. All chapters use one example
  project, which grows from chapter to chapter. The Rust book, "The
  Rust Programming Language" (https://doc.rust-lang.org/book/),
  teaches in this way.
- A reference part ends the book. Each reference page has a fixed file
  name, so that a reader can link to it.
- The program mdBook (https://rust-lang.github.io/mdBook/) builds the
  book as a website, from Markdown files in `docs/book/`. CI builds the
  book on each pull request. CI does not put the website on the
  internet. The maintainer, who owns the repository, decides when that
  starts.
- The book describes the tool as the specifications describe it. When
  the tool does not have a feature yet, a note says so above the text
  about that feature. The note is a Markdown block quote that starts
  with `[!NOTE]`. Text with no note is true of the tool at the same
  commit.
- A test program in `test/` reads each page of the book. It writes the
  files that the page shows, and it runs the commands that the page
  shows, in a new git repository. It then compares the output of each
  command, byte for byte, with the output that the page shows. A
  command under a note does not run. The program also checks each link
  from one page of the book to another.
- A reference page holds its tags in an HTML comment, so that the
  website does not show them. A chapter of the guide holds no tag,
  because its examples teach the reader, and a tag would only stop the
  reading.

## Alternatives considered

- **Reference pages first, and the guide later.** Not chosen: a reader
  who is new to Sinter gets no first page to start from.
- **One manual for people and one for coding agents.** Not chosen: two
  texts can disagree, and clear text serves both readers.
- **Plain Markdown files on GitHub, with no mdBook.** Not chosen: the
  reader then has no search and no list of all pages beside the text.
  A reader who looks up one fact needs both.
- **MkDocs or Docusaurus, two other programs that build a website from
  Markdown.** Not chosen: they need Python or Node.js. Nothing else in
  this repository uses those languages, and mdBook does all that the
  book needs.
- **Describe only the features that the tool has.** Not chosen: the
  book then cannot tell its full story until the tool is finished. Its
  authors also cannot see early how the finished tool is to explain.
- **Describe the finished tool with no notes, and publish the book when
  a release of the tool is ready.** Not chosen: until then, the
  repository holds text that is partly untrue, and no reader can tell
  which part.
- **The program `ocaml-mdx` (https://github.com/realworldocaml/mdx),
  which runs code in Markdown files, as the test.** Not chosen: it adds
  a tool that the build of this repository then needs, with several
  other packages that it needs in turn. Each new version of OCaml must
  wait for all of them.
- **Copy each example from the test cases in `test/cases/` by hand, or
  check the examples by hand.** Not chosen: no program then checks that
  the book is correct.
- **A new example in each chapter.** Not chosen: a reader then does not
  see how the parts of Sinter work together.

## Consequences

Each change that adds or changes a feature also changes the book. When
a change builds a feature, the note above that feature must go. No
program can find a note that stays after its feature exists, so a
person must find it. The work on the book also shows where the design
of a feature is hard to explain, while the design can still change.
