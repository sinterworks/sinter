<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Read CommonMark with cmarkit, behind limits on depth and size
@decision commonmark-reader v2
@cites licensing
@cites current-dependencies
The library of the design Identifiers reads Markdown documents with the OCaml library `cmarkit` 0.4.0. Sinter's own code adds the definitions of the design Identifiers that CommonMark 0.31.2 does not have. Before `cmarkit` reads a file, Sinter's code checks the size of the file, the depth of its nested square brackets, and the depth of its nested containers, and it does not read a file in which one of them is greater than the limit that the calling code gives.

## Context

The design Identifiers defines an inline citation as a Markdown link
whose destination starts with `sinter:`. It defines a link, its
destination, and the inline elements of its link text by citing
CommonMark 0.31.2. A program that conforms must therefore read the
whole document as CommonMark 0.31.2 reads it: the blocks, the inline
elements, the link reference definitions, the backslash escapes, and
the entity references.

`cmarkit` 0.4.0 (2025-11-01) states support for CommonMark 0.31.2. Its
license is ISC, which is none of the licenses that `licensing`
rejects, and it has no runtime dependencies. With `~locs:true` it gives
each node of a document its byte positions and line numbers. With
OCaml 5.5.2 it installs as one package and changes no other version in
`sinter.opam.locked`. It keeps an autolink inside link text as a link
of its own. It replaces escapes and entity references in the
destination of an inline link or a reference link, as the design
requires. The tests of the library check both.

`cmarkit` 0.4.0 is slow on two kinds of input, and it uses much memory
on every input. A CommonMark parser can read every text in time that
is linear in its length, but `cmarkit` 0.4.0 does not:

- **Nested square brackets.** Each byte inside L levels of square
  brackets costs about 2 to the power of L times its cost outside
  brackets. A short text shows the growth: on L `[`, then `a`, then L
  `]`, one read took 0.10 seconds for L = 20, 0.64 seconds for L = 22,
  and 12.6 seconds for L = 27. A hostile file can put almost all of its
  bytes inside L levels. The slowest such text that was measured is a
  run of alternating emphasis markers. Inside L levels, each of its
  bytes costs 0.62 to 0.83 microseconds times 2 to the power of L. The
  author of `cmarkit` tracks the defect as issue #5 of the repository
  of `cmarkit`, open since April 2023. On 2026-11-19, no release fixed
  it, and the unreleased changes did not mention it.
- **Nested containers.** List items and block quotes nested in one
  another are also slow. A line of n nested list items with the
  marker `-` or `*` takes time that grows as n squared: about 10
  seconds for a line of about 140 KiB. Another slow text is k nested
  containers followed by n lines that continue a paragraph without
  container markers. Its time grows as k times n. 1,000 nested list
  items followed by such lines took 12.8 seconds for a file of about
  510 KiB.
- **Memory.** `cmarkit` takes up to about 350 bytes of memory for each
  byte of input.

These figures come from `cmarkit` 0.4.0 under OCaml 5.5.2, with the
call that Sinter makes (`Cmarkit.Doc.of_string ~strict:true
~locs:true`), on one development machine that other work shared. The
load of that machine changed the times by up to about a factor of 2.

The design Documents lets a program stop the reading of a file for
limits of its own. The files whose reading the program stops are in
its set of stopped files. A file in that set cannot be read, and the
design gives a finding of the class `parse-error` for each file that
cannot be read. The program reads the rest of the tree.

The greatest depth of nested square brackets in the Markdown files of
Sinter, as the count of brackets in the Decision section gives that
depth, is 4. That depth comes from JSON in fenced code blocks of three
designs. The largest Markdown file of Sinter is the design Documents,
at about 168 KiB.

The greatest depth of nested containers in the Markdown files of
Sinter, as the count of containers in the Decision section gives that
depth, is 8. That depth comes from an ordered list item at 15 columns
of indentation in the design Documents, where the real nesting is 6
list items.

The hostile texts of nested containers that were measured are 512 KiB
long and hold no square brackets. They are lines of nested list items,
nested containers followed by lines that continue a paragraph, by
blank lines, or by indented lines, list items nested by indentation,
and lines of block quotes. With a depth of nested containers of at
most 16, `cmarkit` took at most 0.31 seconds on each of these texts.
With a depth of at most 32, it took at most 0.40 seconds. The slowest
of these texts above a depth of 16 is nested list items followed by
blank lines. Its time grows with the depth: 0.80 seconds at a depth of
64, 1.6 seconds at 128, and 3.6 seconds at 256. These figures come
from the same release, call, and machine as the figures above.

## Decision

- The library of the design Identifiers reads a Markdown document with
  `cmarkit`, in its strict CommonMark mode, with source locations.
- Sinter moves `cmarkit` to each new release, as
  `current-dependencies` requires.
- Before `cmarkit` reads a Markdown file, Sinter's code checks three
  limits. When the size or a depth of the file is greater than its
  limit, the file goes into the set of stopped files. Each limit is a
  required argument of the code that reads Markdown files, so the
  calling code always chooses the limit.
  - **The size of the file.** Sinter's commands give a limit of
    512 KiB (524,288 bytes).
  - **The depth of nested square brackets.** Sinter's commands give a
    limit of 5. The count takes time that is at most proportional to
    the length of the text times one more than the limit. The count
    follows the scan with which `cmarkit` 0.4.0 looks for the closing
    bracket of each opening bracket, so the depth that the count gives
    is never less than the nesting that makes `cmarkit` slow.
    A `[` or a `]` counts only when an even number of backslashes comes
    right before it. A `]` inside a code span or a piece of HTML that
    starts after a `[` does not close that `[`. The count also includes
    the brackets in code spans, code blocks, and HTML blocks. Only a
    full parse of CommonMark finds code blocks and HTML blocks
    correctly, and that parse is the slow step that the limit protects.
  - **The depth of nested containers** (list items and block quotes).
    Sinter's commands give a limit of 32. The count reads the text
    once, in linear time. For each line, the count adds the list
    markers and block quote markers at the start of the line to one
    level for each two columns of white space before the first list
    marker of the line. On a line without a list marker, it counts the
    white space before the last block quote marker. Two columns is the
    least indentation that a nested list item takes, so the depth that
    the count gives is never less than the nesting of list items and
    block quotes that `cmarkit` 0.4.0 builds (the real nesting). The
    depth can be greater than the real nesting, for example for list
    items whose markers take three columns or more. Like the count of
    brackets, the count of containers also reads the lines of code
    blocks and HTML blocks.
- Under the limits on size and on brackets, a hostile Markdown file
  costs at most about 10 to 14 seconds for its brackets
  (524,288 bytes × 2^5 × 0.62 to 0.83 microseconds) and about 180 MiB of
  memory. Under the limits on size and on containers, its nested
  containers cost at most about 0.40 seconds on the measured texts.
- When Sinter moves to a new release of `cmarkit`, Sinter's developers
  measure the counts and their limits again against that release, as a
  part of the upgrade. The measurement delays the upgrade only when a
  limit must change. When a release removes the defect of nested
  brackets, Sinter can raise or remove the limit on brackets. When a
  release removes the defect of nested containers, Sinter can raise or
  remove the limit on containers. The limit on size stays, because it
  also bounds the memory.
- Users cannot change the limits. The code that reads Markdown files
  already takes each limit as an argument, so a setting of a project
  needs no new code in that library.

## Alternatives considered

- **A CommonMark reader of Sinter's own, in OCaml.** Rejected: by
  estimate, the block parser, the inline parser, the reference
  definitions, and the table of entity names come to several thousand
  lines, and a maintained library already reads the same version of
  the standard.
- **The tree-sitter inline grammar of Markdown, through the bridge.**
  Rejected: it would make the library depend on the bridge and
  wasmtime, and Sinter's code would still have to replace escapes and
  entity references and resolve reference links.
- **A fix of the defects, in a changed copy of `cmarkit` that Sinter
  builds until the author of `cmarkit` takes the fix.** Rejected: it is
  work inside another project's parser, and the limits bound the cost
  without such a fix.
- **A limit on a weighted sum, in place of the depth of brackets.** The
  sum counts each byte as 2 to the power of its depth of brackets. On
  every measured text except nested containers, `cmarkit` took at most
  about 0.92 microseconds for each unit of the sum. A limit of 4 times
  the size of the file, plus 2^20, would therefore bound the worst time
  to about 3.7 microseconds for each byte plus about 1 second: about 3
  seconds for a file of 512 KiB. It would also read a short JSON block
  with square brackets nested 10 deep. Rejected: together, the limits on
  size and on the depth of brackets already keep the worst time near 10
  to 14 seconds. A weighted sum is harder to state and to explain to a
  user, and its constant depends on how the current release of
  `cmarkit` behaves.
- **A depth limit of 4 or 6 on brackets.** Rejected: 4 leaves no room
  above the deepest Markdown file of Sinter, so one more level of JSON
  in a design would make that design unreadable. 6 doubles the worst
  time, to about 21 to 28 seconds for a file of 512 KiB.
- **A size limit of 256 KiB or 1 MiB.** Rejected: 256 KiB leaves only
  about 1.5 times the size of the largest Markdown file of Sinter, and
  1 MiB doubles the worst time and memory, to about 21 to 28 seconds and
  about 350 MiB.
- **A depth limit of 16 or 64 on containers.** Rejected: 16 leaves
  only twice the greatest depth of containers in the Markdown files of
  Sinter (8). The count of containers can be greater than the real
  nesting, so that room is small. A limit of 32 adds only about 0.1
  seconds to the worst measured time of nested containers: 0.40 seconds
  in place of 0.31 seconds. No file of Sinter needs the room of 64, and
  above a depth of 32 the time grows with the depth.
- **No limit on nested containers.** Rejected: under the limit on size
  alone, a line of nested list items could take about 2 minutes, because
  its time grows as the square of its length.

## Consequences

Sinter has one more OCaml dependency, and every tool that uses the
library of the design Identifiers needs it too. Sinter has two
Markdown readers until the old block reader goes: the tree-sitter
grammar and `cmarkit`. A defect of `cmarkit` against CommonMark 0.31.2
becomes a defect of Sinter until `cmarkit` fixes it or Sinter's code
works around it.

A Markdown file larger than 512 KiB, or with brackets or containers
nested deeper than their limits, cannot be read. It gives a finding of
the class `parse-error` whose message names the limit, and Sinter reads
the rest of the tree. Such a file can still be valid CommonMark.
Because the count of brackets includes the brackets in code blocks, a
fenced block of JSON with square brackets nested 6 deep also stops the
reading of its file. Because the count of containers can be greater
than the real nesting, list items and block quotes nested fewer than 32
levels deep can also stop the reading of their file. For example, an
ordered list whose markers take three columns stops the reading at its
23rd level. Because the count of containers also reads code blocks, a
code block with deeply indented list markers can stop the reading too.
