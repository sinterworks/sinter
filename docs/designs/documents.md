<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Documents
@design documents=v1
@cites {
    conformance=v1,
    text=v1,
    identifiers=v1,
    files=v1,
    data-forms=v1,
    ontology=v1,
    object-store=v1,
    ledger=v1,
    packs=v1,
    findings=v1,
    commonmark/0.31.2,
    rfc/5234,
    rfc/7405,
    rfc/8259,
}
Conforming programs read Markdown files, code files, explicitly mapped
test-vector files, and `.sinter/` object stores of a tree to derive
declared items, example blocks, tests, code hashes, sites, canonical
objects, containment, edges, extern directives, and tree findings.

A tree stores objects at rest in two encodings: text in Markdown and
code files outside `.sinter/`, and canonical JSON objects in `.sinter/`
object files. Parameter bindings select which files outside `.sinter/`
are read with CommonMark 0.31.2 or with a language pack (`file-readers`)
and map design and specification names to test-vector files
(`vector-files`). A caller can also supply kept objects from the log
branch (`kept-object-set`) to resolve exact pins and content-ID
citations to earlier revisions.

From parsed Markdown blocks and language-pack parse trees, a program
extracts tag texts, trailing example blocks, code tests, and code
hashes, resolves declarations into extents, sites, containment, and
canonical objects, and produces citation edges, extern directives, and
tree findings. The grammar productions use ABNF (RFC 5234) with the
case-sensitive strings of RFC 7405.

## Parameters

### File readers

@schema file-readers=v1
@cites {
    conformance#own-store=v1,
    files#path-set=v1,
    ontology#{encoding=v1, parameter=v1},
    packs#{pack=v1, valid-pack=v1},
    text#text=v1,
}

A binding of the `parameter` `file-readers` is a finite sequence of
pairs (which can be empty). Each pair holds a **reader** and a
`path-set`. A reader is either the `text` `markdown` or a `pack`.

A binding meets the schema `file-readers` when every `path-set` in the
binding is valid and every `pack` in the binding is a `valid-pack`.
Otherwise, the binding is invalid.

`file-readers` binds only the text `encoding` outside `.sinter/` and
never applies to files inside `.sinter/` or to a program's own store
(`own-store`). A program that reads objects only from a valid program's
own store needs no binding of `file-readers`.

### Vector files

@schema vector-files=v1
@cites {
    files#path=v1,
    identifiers#{full-name=v1, slug=v1},
    ontology#parameter=v1,
    text#text=v1,
}

A binding of the `parameter` `vector-files` is a finite set (which can
be empty) of pairs, each pairing a **target name** (a `text`) with a
**file path** (a `text`).

A binding meets the schema `vector-files` when all four of these
conditions hold:

- Every target name is a `slug` (for a design) or a `full-name` (for a
  specification).
- No two pairs in the binding have equal target names.
- Every file path is a valid `path` whose path segment 1 is not
  `.sinter`.
- No two pairs in the binding have equal file paths.

Otherwise, the binding is invalid. A valid binding of `vector-files` is
a finite one-to-one partial map from target names to valid paths, and
**maps** a target name `k` to a valid `path` `p` when the binding holds
the pair `(k, p)`.

## Definitions

### Read files

@term read-file=v1
@cites {
    files#{path=v1, path-set=v1, path-set-membership=v1},
    ontology#{parameter=v1, tree=v1},
    packs#pack=v1,
    text#{character=v1, text=v1},
    #file-readers=v1,
}

This term applies under a valid binding of the `parameter`
`file-readers`.

The **reader** of a valid `path` is the reader of the first pair in the
binding whose `path-set` has that valid path in its set
(`path-set-membership`). A valid path that is in the set of no path set
of the binding has no reader.

A **read file** of a `tree` is a file of that tree whose valid `path`
meets all four of these conditions:

- its valid path has a reader;
- its valid path does not start with `.sinter/` (it does not have two
  or more path segments with path segment 1 equal to `.sinter`);
- its valid path holds no line feed (U+000A); and
- its valid path neither starts nor ends with a space (U+0020) or a tab
  (U+0009).

The **reader** of a read file is the reader of its valid path. A read
file is a **markdown file** when its reader is the `text` `markdown`,
and a **code file** when its reader is a `pack` (the **pack** of that
code file).

### Unreadable files

@term unreadable-file=v1
@cites {
    files#path=v1,
    ontology#{parameter=v1, tree=v1},
    packs#{file-parse=v1, parse-result=v1},
    text#{text=v1, utf-8-text=v1, valid-utf-8=v1},
    #{file-readers=v1, read-file=v1},
}

For a `tree` and a valid binding of the `parameter` `file-readers`, a
`read-file` of the tree is **unreadable** when either of these
conditions holds:

- the content of the read file is not `valid-utf-8`; or
- the read file is a code file, and the `file-parse` of its
  `utf-8-text` (taken as the text of a file at its valid `path`) with
  its pack has `parse-result` `"no grammar"` or `"parse failure"`.

Every other read file of the tree is **readable**.

### Position subjects

@term position-subject=v1
@cites {
    files#path=v1,
    ontology#tree=v1,
    text#{decimal-numeral=v1, position=v1, text=v1},
}

For a file of a `tree` at valid `path` `p` and a `position` with
1-based line number `l` and 1-based column `c`, the **position
subject** of that position in that file is the `text` formed by `p`,
then `@L`, then the `decimal-numeral` of `l`, then `C`, then the
`decimal-numeral` of `c` (`<path>@L<line>C<column>`).

### Position order

@term position-order=v1
@cites text#position=v1

A `position` `a` **comes before** a `position` `b` in **position
order** when either of these conditions holds:

- the line number of `a` is less than the line number of `b`; or
- both positions have the same line number and the column of `a` is
  less than the column of `b`.

### Slice locations

@term slice-location=v1
@cites {
    files#path=v1,
    findings#location=v1,
    ontology#tree=v1,
    text#{body=v1, slice=v1, span=v1, utf-8-text=v1, valid-utf-8=v1},
}

For a file of a `tree` at valid `path` `p` whose content is
`valid-utf-8` and a `slice` `r` of its `utf-8-text` whose start
boundary and end boundary are boundaries of the `body` (so `r` is a
`span`) and are not inside a line ending (`findings#location`), the
**slice location** of `r` in that file is the `location` in that tree
with valid path `p` and `span` `r`.

### Tree findings

@term tree-finding=v1
@cites {
    findings#{
        ackable-finding=v1, finding-part=v1, finding-subject=v1,
        fix=v1, location=v1, mark=v1, message=v1, related-message=v1,
    },
    identifiers#slug=v1,
    ontology#{finding-class=v1, tree=v1},
}

A **tree finding** of a `tree`, of the `finding-class` named by a
`slug` `c`, with a `finding-subject` `s` and either a `location` `p` in
that tree or no location, is a finding with these `finding-part`
values:

- **tree:** that `tree`;
- **finding class:** `c`;
- **subject:** `s`;
- **location:** `p` when a location `p` is supplied, and no location
  otherwise;
- **ackable:** not ackable (`ackable-finding`);
- **message, mark, related messages, and fix:** the `message`, `mark`,
  `related-message` values, and `fix` chosen by the program that returns
  the finding.

### Kept object set

@term kept-object-set=v1
@cites {
    conformance#input=v1,
    ontology#{
        object=v1, object-kind=v1, content-id=v1, log-branch=v1,
        declared-item=v1, computed-identity=v1,
    },
}

`kept-object-set` is a caller `input` holding a set of canonical
`object`s from the `log-branch`: kept `declared-item` objects (the
seven declared-item kinds) and kept `computed-identity` objects (the
five computed identity kinds), each conforming to its row of
`ontology#object-kind` without `seq` or `by`, and deduplicated by
`content-id`. When a caller supplies no kept objects, `kept-object-set`
is the empty set. A `kept-object-set` is valid when, and only when,
each of its objects is a canonical object of one of those twelve kinds
that meets its row of `ontology#object-kind`.

## Code files

@spec code-files=v1

A code file is parsed with the grammar of its pack into comment,
definition, decoration, and test nodes. From those parse nodes, a
program groups adjacent comments into comment sequences, strips comment
sigils and shared indentation, attaches comment sequences to
definitions and tests, and derives code texts, code hashes, and file
tests.

### Definitions

#### Code characters

@term code-character=v1
@cites {
    packs#{comment-node=v1, file-parse=v1, node-slice=v1},
    text#{body=v1, character=v1, line=v1, slice=v1, text=v1},
    #{read-file=v1, unreadable-file=v1},
}

A **code character** of a readable (`unreadable-file`) code file
(`read-file`) is a `character` at a 1-based character index (`text`) of
the `body` of the file's text such that all three of these conditions
hold:

- that 1-based character index is not a character index of the
  `node-slice` (`slice`) of any `comment-node` in the `file-parse` of
  the file's text with its pack;
- that character is neither a space (U+0020) nor a tab (U+0009); and
- that 1-based character index is not a character index of any line
  ending (`line`) of the file's text.

#### Slice lines

@term slice-line=v1
@cites text#{line=v1, slice=v1, text=v1}

The **slice lines** of a `slice` `r` of a `text`, where `r` has start
boundary `from_r` and end boundary `to_r`, are these slices of that
text, ordered by their start boundaries:

- for each `line` `L` of the text (with start boundary `from_L` and end
  boundary `to_L`) that shares at least one 1-based character index
  with `r`, the slice `(max(from_r, from_L), min(to_r, to_L))`; and
- each empty `line` `(b, b)` of the text whose boundary `b` satisfies
  `from_r < b < to_r`.

#### Comment sequences

@term comment-sequence=v1
@cites {
    packs#{
        comment-node=v1, enclosed-node=v1, file-parse=v1,
        node-slice=v1, parse-tree-order=v1,
    },
    text#{character=v1, line=v1, position=v1, slice=v1, text=v1},
    #{code-character=v1, read-file=v1, unreadable-file=v1},
}

This term applies to a readable (`unreadable-file`) code file
(`read-file`) and the `comment-node`s of the `file-parse` of its text
with its pack.

The **first line number** of a comment node is the 1-based line number
of the `position` of the start boundary of its `node-slice`. The **last
line number** of a comment node is the 1-based line number of the
`line` holding the last 1-based character index of its `node-slice`
that belongs to a `line`, or the first line number of that comment node
when no character index of its `node-slice` belongs to a `line`. Thus,
when a comment node's `node-slice` includes the line ending after its
last line, its last line number is still the line number of that last
line.

A line number **has a code character** when the file's text has a
`line` with that line number and that line holds a `code-character`. An
**outer comment node** is a `comment-node` that no other `comment-node`
encloses (`enclosed-node`). A comment node enclosed by another comment
node belongs to no comment sequence.

The **comment sequences** of the file are sequences of outer comment
nodes formed by processing each outer comment node in turn, ordered
first by the start boundary of its `node-slice` and then, for two outer
comment nodes starting at the same boundary, by `parse-tree-order`:

1. When the first line number of the comment node has a code character,
   the comment node starts a new comment sequence, and no other comment
   node joins that comment sequence.
2. Otherwise, when an outer comment node `P` immediately precedes the
   comment node in that order and all three of these conditions hold,
   the comment node joins the comment sequence of `P`:
   - the first line number of the comment node equals the last line
     number of `P` or is 1 greater than the last line number of `P`;
   - the start boundary of the comment node's `node-slice` is at or
     after the end boundary of `P`'s `node-slice`, and the `slice` of
     the file's text between those two boundaries holds only spaces
     (U+0020), tabs (U+0009), and characters of line endings (`line`);
     and
   - rule 1 did not start the comment sequence of `P`.
3. Otherwise, the comment node starts a new comment sequence.

A comment sequence **starts** at the start boundary of its first
comment node's `node-slice` and **ends** at the end boundary of its
last comment node's `node-slice`; the **slice** of the comment sequence
is the `slice` from that start boundary to that end boundary. The
**first line number** of a comment sequence is the first line number of
its first comment node, and the **last line number** of a comment
sequence is the last line number of its last comment node.

#### Comment lines

@term comment-line=v1
@cites {
    packs#{
        comment-node=v1, comment-sigil=v1, node-slice=v1,
        valid-descriptor=v1, valid-pack=v1,
    },
    text#{character=v1, slice=v1, text=v1},
    #{read-file=v1, slice-line=v1, unreadable-file=v1},
}

This term applies to a tagged `comment-node` of a readable
(`unreadable-file`) code file (`read-file`), using the `comment-sigil`s
of the `valid-descriptor` of the file's pack (`valid-pack`).

To **remove** a text from the start of a `slice` is to make that slice
start immediately after that text. To **remove** a text from the end of
a `slice` is to make that slice end immediately before that text. The
**comment lines** of the comment node are the `slice-line`s of its
`node-slice`, each shortened by these sigil-removal rules and then by
shared-indentation removal:

- **First slice line:** Remove all leading spaces (U+0020) and tabs
  (U+0009) from the start of the first slice line. Then remove the
  longest text, among the line sigils and the opening sigils of the
  block pairs, with which the remaining text starts.
  - When that removed text is a line sigil, the comment node is a
    **line comment**.
  - When that removed text is an opening sigil and not a line sigil,
    the comment node is a **block comment** of the first block pair (in
    block-pair order) whose opening sigil equals that removed text.
  - When the remaining text starts with no line sigil and no opening
    sigil, the comment node is a **comment with no sigil**.
  - When the first slice line is also the last slice line of the
    comment node's `node-slice`, the comment node is a block comment,
    and the remaining text ends with the closing sigil of the comment
    node's block pair, remove that closing sigil from the end of the
    remaining slice.
- **Each later slice line of a block comment:** When the slice line is
  the last slice line of the comment node's `node-slice` and its text
  ends with the closing sigil of the block comment's block pair, remove
  that closing sigil from the end of the slice line. Then, when the
  remaining text starts, after any leading spaces (U+0020) and tabs
  (U+0009), with an inner sigil, remove those leading spaces and tabs
  and then remove the longest inner sigil with which the rest starts.
- **Each later slice line of a line comment:** Remove all leading
  spaces (U+0020) and tabs (U+0009) from the start of the slice line.
  Then, when the remaining text starts with a line sigil, remove the
  longest line sigil with which that remaining text starts.

The **margin** of a finite sequence `r` of texts is the empty text when
no text in `r` holds a `character` other than a space (U+0020) or a tab
(U+0009). Otherwise, the margin of `r` is the longest text holding only
spaces (U+0020) and tabs (U+0009) with which every text in `r` that
holds a character other than a space or a tab starts.

The **bare lines** of the comment node are each later slice line of a
block comment from which those sigil-removal rules remove no inner
sigil, and each later slice line of a comment with no sigil. Let `m` be
the margin of the sequence of texts of the bare lines, in order, after
applying those sigil-removal rules. From each bare line whose text
after those rules starts with `m`, remove `m` from the start of that
bare line. From each other bare line, remove all leading spaces
(U+0020) and tabs (U+0009) from the start of that bare line.

@example With the block pair `/*` and `*/` and the inner sigil `*`
([comment-sigil](sinter:packs#comment-sigil=v1)), this tagged
[comment-node](sinter:packs#comment-node=v1) has three
[slice-line](sinter:#slice-line=v1)s:

```c
/* @req a=v1
 * A text.
 */
```

Removing `/*` from the first line leaves ` @req a=v1`. Removing the
leading space and `*` from the second line leaves ` A text.`. Removing
`*/` from the third line leaves one space (` `), which has no inner
sigil and is the sole bare line. No bare line holds a character other
than a space or a tab, so the margin is the empty text, and the third
comment line stays a single space.

#### Attachment

@term attachment=v1
@cites {
    packs#{
        comment-node=v1, decoration-node=v1, definition-node=v1,
        file-parse=v1, node-slice=v1, parse-tree-order=v1,
        test-node=v1,
    },
    text#{line=v1, position=v1, slice=v1, text=v1},
    #{
        code-character=v1, comment-sequence=v1, read-file=v1,
        slice-line=v1, unreadable-file=v1,
    },
}

This term applies to a readable (`unreadable-file`) code file
(`read-file`). Its **attachment targets** are the `definition-node`s
and `test-node`s of the `file-parse` of its text with its pack. The
**first line number** of an attachment target is the 1-based line
number of the `position` of the start boundary of its `node-slice`.

A `comment-sequence` `R` **attaches** to an attachment target `T` when
all three of these conditions hold:

1. Among all attachment targets whose `node-slice` starts at or after
   the end boundary of `R`, `T` starts at the earliest boundary; among
   those starting at that boundary, `T` ends at the latest boundary;
   and among those starting and ending at those boundaries, `T` comes
   first in `parse-tree-order`.
2. No `code-character` lies at a 1-based character index before the
   start boundary of `R` on the `line` of the file's text whose line
   number is the first line number of `R`.
3. Every `code-character` at a 1-based character index of the `slice`
   from the end boundary of `R` to the start boundary of `T`'s
   `node-slice` lies at a character index of the `node-slice` of a
   `decoration-node`. In addition, every `line` `L` of the file's text
   whose 1-based line number is strictly greater than the last line
   number of `R` and strictly less than the first line number of `T`
   either holds a `code-character` at a character index of the
   `node-slice` of a `decoration-node`, or contains a `slice-line` of
   the `node-slice` of a `comment-node` (a slice line whose start and
   end boundaries are boundaries of `L`).

A comment sequence that attaches to no attachment target is
**unattached**. Two or more comment sequences can attach to one
attachment target.

@example When `#[test]` is a
[decoration-node](sinter:packs#decoration-node=v1) and `fn t() {}` is a
[test-node](sinter:packs#test-node=v1) (or a
[definition-node](sinter:packs#definition-node=v1)), both
[comment-sequence](sinter:#comment-sequence=v1)s attach to `fn t() {}`:

```rust
// @verifies x#y=v1
#[test]
// @satisfies a#b=v1
fn t() {}
```

Inserting a blank line between the first comment and `#[test]` leaves
the first comment sequence unattached.

#### Tests of a read file

@term file-test=v1
@cites {
    ontology#test=v1,
    packs#{file-parse=v1, node-slice=v1, test-name=v1, test-node=v1},
    #{
        attachment=v1, comment-sequence=v1, read-file=v1,
        unreadable-file=v1,
    },
}

A markdown file has no `test`. An unreadable (`unreadable-file`)
`read-file` has no `test`.

For a readable code file, each `test-node` of the `file-parse` of its
text with its pack defines one `test` of the file, and the file has no
other test:

- its **name** is the name path (`test-name`) of that `test-node`;
- its **code** is the `node-slice` of that `test-node`; and
- each **comment on** that test is a `comment-sequence` of the file
  that attaches (`attachment`) to an attachment target whose
  `node-slice` equals that `test-node`'s `node-slice`.

#### Code hashes

@term code-hash=v1
@cites {
    data-forms#hash=v1,
    packs#{comment-node=v1, definition-node=v1, node-slice=v1},
    text#{
        algorithm=v1, character=v1, line=v1, slice=v1, text=v1,
        utf-8-encoding=v1,
    },
    #{
        attachment=v1, comment-line=v1, comment-sequence=v1,
        read-file=v1, slice-line=v1, unreadable-file=v1,
    },
}

For a `slice` `r` of the text of a readable (`unreadable-file`) code
file (`read-file`):

- When a `line` of that text starts at the start boundary of `r`, the
  **measured lines** of `r` are the `slice-line`s of `r` that hold at
  least one `character` other than a space (U+0020) or a tab (U+0009),
  in order.
- When no `line` of that text starts at the start boundary of `r`, the
  **measured lines** of `r` are the `slice-line`s of `r`, excluding the
  first slice line of `r`, that hold at least one `character` other
  than a space (U+0020) or a tab (U+0009), in order.

The code text of an attachment target *a* is the text that these steps
give.

1. Let *r* be the node slice of *a*.
2. If *a* is a definition node, set *r* to the slice of the text of the
   file of *a* from the least boundary where the node slice of a body
   node of *a* starts to the greatest boundary where the node slice of
   a body node of *a* ends.
3. Let *l* be the line of the text of the file of *a* that starts at or
   before the start boundary of *r* and ends at or after the start
   boundary of *r*.
4. If every character of the slice of the text of the file of *a* from
   the start boundary of *l* to the start boundary of *r* is a space
   (U+0020) or a tab (U+0009), set *r* to the slice of the text of the
   file of *a* from the start boundary of *l* to the end boundary of
   *r*.
5. Let *shared* be the margin of the sequence of the texts of the
   measured lines of *r*, in order.
6. Let *c* be the empty text.
7. For each *x* of the slice lines of *r*, in order:
   1. Let *t* be the text of *x* without any trailing spaces (U+0020)
      and tabs (U+0009).
   2. If *x* is a measured line of *r*, remove the first characters of
      *t*, as many characters as *shared* holds, from *t*.
   3. Append *t* to *c*.
   4. Append a line feed (U+000A) to *c*.
8. Give *c*.

A `comment-sequence` that holds at least one tagged `comment-node` and
attaches (`attachment`) to an attachment target `a` has a **code
hash**: the `hash` of the `utf-8-encoding` of the code text of `a`.
Every other comment sequence has no code hash.

### Computing code hashes and code texts

@req compute-code-hashes=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{parameter=v1, tree=v1},
    text#slice=v1,
    #{
        attachment=v1, code-hash=v1, comment-sequence=v1,
        file-readers=v1, read-file=v1, unreadable-file=v1,
    },
}

When a conforming program computes the code hashes of a `tree` under a
binding of the `parameter` `file-readers`, the program must return once
each `comment-sequence` of each readable (`unreadable-file`) code file
(`read-file`) of the tree that has a `code-hash`, together with its
file, its `slice`, its `code-hash`, and, when the program returns code
texts, the code text (`code-hash`) of the attachment target to which
that comment sequence attaches (`attachment`).

### Returning tests

@req give-tests=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{parameter=v1, test=v1, tree=v1},
    packs#{node-slice=v1, test-name=v1},
    #{
        comment-sequence=v1, file-readers=v1, file-test=v1,
        read-file=v1, unreadable-file=v1,
    },
}

When a conforming program returns the `test`s of a `tree` under a
binding of the `parameter` `file-readers`, the program must return once
each `file-test` of each readable (`unreadable-file`) code file
(`read-file`) of the tree, together with its file, its name path
(`test-name`), its code `node-slice`, and each `comment-sequence` that
is a comment on that test.

## Tag extraction

@spec tag-extraction=v1

Markdown files and code files supply tag texts, file lines, origins,
and trailing example blocks from single-file syntax. Findings of three
classes flag unreadable files, misspelled tag words, and tag lines
that declare nothing.

### Definitions

#### Markdown lines

@term markdown-line=v1
@cites {
    commonmark/0.31.2,
    text#{character=v1, text=v1, slice=v1, body=v1},
}

A **markdown line ending** of a `text` is a `slice` of its `body` that
is a line ending as CommonMark 0.31.2 defines it: a carriage return
(U+000D) immediately followed by a line feed (U+000A), a line feed not
immediately preceded in the `body` by a carriage return, or a carriage
return not immediately followed in the `body` by a line feed.

A **markdown line** of a `text` is a `slice` of its `body` that meets
all three of these conditions:

- The slice starts at the start boundary of the `body` or at the end
  boundary of a markdown line ending.
- The slice ends at the earliest boundary at or after its start where a
  markdown line ending starts, or at the end boundary of the `body` when
  no markdown line ending starts at or after its start.
- When the slice ends at the end boundary of the `body`, the slice is
  non-empty.

A leading byte order mark (U+FEFF) lies outside the `body` and belongs
to no markdown line and no markdown line ending. The markdown lines of a
`text` stand in the order of their start boundaries.

#### Front matter and markdown text

@term front-matter=v1
@cites {
    rfc/5234,
    identifiers#link=v1,
    text#{character=v1, text=v1, slice=v1, production=v1},
    #{read-file=v1, unreadable-file=v1, markdown-line=v1},
}

A **front-matter line** is a `markdown-line` whose text matches the
`production` `front-matter-line`:

```abnf
front-matter-line  = ( "+++" / "---" ) *WSP
```

A readable markdown file (`read-file`, `unreadable-file`) starts with
**front matter** when its first `markdown-line` is a front-matter line
and a later `markdown-line` of its text is a front-matter line whose
first three characters equal the first three characters of that first
markdown line. The **front matter** of that markdown file is the
sequence of `markdown-line` slices from the first markdown line through
the earliest such later markdown line.

The **markdown slice** of a readable markdown file is a `slice` of the
file's text that ends at the last boundary of that text:

- When the file has no front matter, its markdown slice starts at
  boundary 0.
- When the file has front matter, its markdown slice starts at the end
  boundary of the markdown line ending immediately after the last line
  of its front matter, or at the last boundary of the file's text when
  no markdown line ending follows that line.

The **markdown text** of a readable markdown file is the text of its
markdown slice. The **markdown lines of the markdown text** are the
`markdown-line` slices of the file's text whose start boundary is at or
after the start boundary of the markdown slice, in order. The **markdown
document** of the file is the Markdown document (`identifiers#link`) of
its markdown text.

#### Markdown sections

@term markdown-section=v1
@cites {
    commonmark/0.31.2,
    text#slice=v1,
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1,
        front-matter=v1,
    },
}

For a readable markdown file (`read-file`, `unreadable-file`),
CommonMark 0.31.2 parses its markdown document (`front-matter`) into
blocks. A blank line is not a block, and a link reference definition is
a block. A **top-level block** of the markdown document is a block that
no block quote, no list, and no list item contains. The `k`-th
CommonMark 0.31.2 line of the markdown document comes from the `k`-th
`markdown-line` of the markdown text. The **markdown lines that a block
takes** are the `markdown-line` slices from which the CommonMark 0.31.2
lines of that block come.

A **section-opening heading** is a top-level block that is an ATX
heading or a setext heading. The **line** of a section-opening heading
is the first `markdown-line` that the heading takes. For a
section-opening heading `H`, the **section** of `H` is the sequence of
`markdown-line` slices of the markdown text from the line of `H` through
the `markdown-line` immediately before the line of the next
section-opening heading whose level is less than or equal to the level
of `H`, or through the last `markdown-line` of the markdown text when no
such heading follows `H`. The **section of level 0** is the sequence of
`markdown-line` slices of the markdown text before the line of the first
section-opening heading, or all `markdown-line` slices of the markdown
text when no heading opens a section. The section of level 0 can be
empty. The **first line** of a non-empty section is its first
`markdown-line`, and the **last line** of a non-empty section is its
last `markdown-line`.

The **first paragraph** of the section of a section-opening heading `H`
is the first top-level block after `H`, when that block is a paragraph.
The **first paragraph** of the section of level 0 is the first top-level
block of the markdown document, when that block is a paragraph. Every
other section has no first paragraph.

#### Markdown list items

@term markdown-list-item=v1
@cites {
    commonmark/0.31.2,
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1,
        front-matter=v1, markdown-section=v1,
    },
}

For a readable markdown file (`read-file`, `unreadable-file`), the
**list items** of the file are the list items of CommonMark 0.31.2 of
its markdown document (`front-matter`), at every nesting depth of lists,
that no block quote contains.

The **markdown lines** of a list item are the `markdown-line` slices of
the markdown text from the first `markdown-line` that the list item
takes (`markdown-section`) through the last `markdown-line` of the last
block that the list item contains, or through that first `markdown-line`
when the list item contains no block. The **first line** of a list item
is the first of its markdown lines, and the **last line** of a list item
is the last of its markdown lines.

The **first paragraph** of a list item is the first block that the list
item contains and that no block quote, no list, and no inner list item
contains, when that block is a paragraph. Otherwise, the list item has
no first paragraph.

#### Paragraph lines

@term paragraph-line=v1
@cites {
    rfc/5234,
    rfc/7405,
    commonmark/0.31.2,
    text#{character=v1, text=v1, slice=v1, production=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1,
        front-matter=v1, markdown-section=v1, markdown-list-item=v1,
    },
}

A **task marker** is a `text` that matches the `production`
`task-marker`:

```abnf
task-marker  = "[" ( SP / %s"x" / %s"X" ) "]" 1*WSP
```

The **lines of a paragraph** of the markdown document (`front-matter`)
of a readable markdown file (`read-file`, `unreadable-file`) are `slice`
values of the file's text, one for each `markdown-line` that the
paragraph takes (`markdown-section`), in order:

- The first line of the paragraph is a `slice` of the first
  `markdown-line` that the paragraph takes. That `slice` starts at the
  boundary immediately before the first character of that
  `markdown-line` that CommonMark 0.31.2 assigns to the content of the
  paragraph and that is neither a space (U+0020) nor a tab (U+0009), and
  ends at the end boundary of that `markdown-line`. When the paragraph
  is the first paragraph of a `markdown-list-item` and that `slice`
  starts with a prefix `slice` whose text matches `task-marker`, the
  first line of the paragraph starts instead at the end boundary of the
  longest such prefix `slice` and ends at the end boundary of that
  `markdown-line`.
- Each remaining line of the paragraph is the whole corresponding
  `markdown-line`.

#### Tag texts

@term tag-text=v1
@cites {
    packs#comment-node=v1,
    text#{character=v1, text=v1, slice=v1},
    #{
        file-readers=v1, read-file=v1, unreadable-file=v1,
        markdown-section=v1, markdown-list-item=v1, paragraph-line=v1,
        comment-sequence=v1, comment-line=v1,
    },
}

Under a valid binding of `file-readers`, a readable file (`read-file`,
`unreadable-file`) has these **tag texts**, and no other tag text:

- For a markdown file: one tag text for each first paragraph of a
  `markdown-section` and one tag text for each first paragraph of a
  `markdown-list-item`. That tag text joins the `paragraph-line` slices
  of that paragraph, in order.
- For a code file: one tag text for each `comment-sequence` that holds
  at least one tagged `comment-node`. That tag text joins the
  `comment-line` slices of the tagged comment nodes of that
  `comment-sequence`, with the comment lines of each tagged comment node
  in order and the tagged comment nodes in their order in that
  `comment-sequence`.

A tag text that joins a sequence of `slice` values is the `text` formed
by concatenating the texts of those slices in order, with one line feed
(U+000A) between each adjacent pair. Those slices are the **lines that
the tag text joins**. The `k`-th line of a tag text (1-based) comes from
the `k`-th line that the tag text joins. An unreadable file
(`unreadable-file`) has no tag text.

@example In this Markdown file, only the first paragraph of the
[section](sinter:#markdown-section=v1) and the first paragraph of the
[list item](sinter:#markdown-list-item=v1) form tag texts:

```markdown
# Billing
@design billing=v1
Invoices ask a customer to pay.

@req stray=v1

- [x] @req limit=v1
  Reject amounts over 10,000.
```

The first tag text joins `@design billing=v1` and
`Invoices ask a customer to pay.`. After
[paragraph-line](sinter:#paragraph-line=v1) strips the task marker
`[x] `, the second tag text joins `@req limit=v1` and
`  Reject amounts over 10,000.`. The second paragraph `@req stray=v1`
forms no tag text.

#### Origins

@term origin=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        link=v1, tag-line=v1, tag-line-text=v1, continuation-line=v1,
        citation=v1, citation-entry=v1, citation-line=v1, match=v1,
    },
    text#{character=v1, text=v1, slice=v1, body=v1},
    #{read-file=v1, unreadable-file=v1, front-matter=v1, tag-text=v1},
}

For a readable file (`read-file`, `unreadable-file`), each character of
the following texts comes from one 1-based character index (`text#text`)
in the file's text, or from no character index:

- Each character of the file's text comes from its own 1-based character
  index in the file's text.
- In a `tag-text` of the file, each line feed (U+000A) inserted between
  two adjacent lines that the tag text joins comes from no character
  index. Each other character of the tag text is a character of one of
  the `slice` values that the tag text joins and comes from that
  character's 1-based character index in the file's text.
- The character at 1-based character index `k` of the markdown text
  (`front-matter`) of a markdown file comes from the `k`-th 1-based
  character index of the file's markdown slice.
- The character at 1-based character index `k` of the Markdown document
  (`identifiers#link`) of a `tag-text` or of a markdown text comes from
  the same 1-based character index in the file's text as the `k`-th
  character of the `body` of that tag text or markdown text, or from no
  character index when that character comes from none.
- Each character of the `tag-line-text` of a `tag-line` of a `tag-text`
  is a character of that tag line's line, a character of one of its
  `continuation-line`s (after removing leading spaces and tabs), or the
  line feed (U+000A) inserted before a `continuation-line`; it comes
  from the same 1-based character index in the file's text as the
  corresponding character of that `tag-text`, or from no character index
  when that character comes from none.

For a `citation` of a `tag-text` whose `tag-line-text` has a `match` by
the production `citation-line`, each `citation-entry` has a `slice` in
that `tag-line-text`: the `slice` matched by `cites-single`,
`verifies-single`, or `fixed-single` for a single target, or the `slice`
matched by `cites-part`, `verifies-part`, or `fixed-part` for a part of
a scoped list. A `link` of a Markdown document is the `slice` of that
Markdown document from the boundary immediately before the opening `[`
or `<` at which CommonMark 0.31.2 starts the link to the boundary
immediately after the last character of the link.

The **origin** of a `slice` `r` of any of these texts (the file's text,
a `tag-text`, a `tag-line-text`, or the Markdown document of a
`tag-text` or of a markdown text) is the set of 1-based character
indices in the file's text from which the characters of `r` come. When
the origin of `r` is non-empty, let `min` be its least 1-based character
index and let `max` be its greatest 1-based character index. The **slice
of `r` in the file's text** is the `slice` `(min - 1, max)` of the
file's text. For the `tag-line-text` of a `tag-line`, the slice in the
file's text starts instead at the boundary immediately before the
1-based character index from which the `@` of that tag line comes, and
ends at boundary `max`.

#### Origin positions

@term origin-position=v1
@cites {
    identifiers#{tag-line=v1, tag-line-text=v1},
    text#{text=v1, slice=v1, position=v1},
    #{
        read-file=v1, unreadable-file=v1, front-matter=v1, tag-text=v1,
        origin=v1,
    },
}

For a `slice` `r` of a readable file's text (`read-file`,
`unreadable-file`), of a `tag-text`, of a `tag-line-text`, or of the
Markdown document of a `tag-text` or of a markdown text
(`front-matter`), when the `origin` of `r` is non-empty, the **origin
position** of `r` is the `position` in the file's text of the least
1-based character index in the `origin` of `r`.

For the `tag-line-text` of a `tag-line`, the **origin position** is
instead the `position` in the file's text of the 1-based character index
from which the `@` of that tag line comes.

#### File lines

@term file-line=v1
@cites {
    identifiers#{tag-line=v1, tag-line-text=v1, continuation-line=v1},
    text#{text=v1, slice=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1,
        front-matter=v1, tag-text=v1, origin=v1,
    },
}

The **file lines** of a readable file (`read-file`, `unreadable-file`)
are `slice` values of the file's text:

- For a markdown file, its file lines are its `markdown-line` slices.
- For a code file, its file lines are the distinct `slice` values that
  its `tag-text` values join.

The file lines of a readable file stand in the order of their start
boundaries, with two file lines that share a start boundary ordered by
their end boundaries.

The **file lines** of a part of a readable file are:

- of a file line: the set holding only that file line;
- of a line `l` of a `tag-text` of a code file: the set holding only the
  file line from which `l` comes;
- of a line `l` of a `tag-text` of a markdown file: the set holding only
  the `markdown-line` whose start boundary is at or before the start
  boundary of the `slice` from which `l` comes and whose end boundary is
  at or after the end boundary of that `slice`;
- of the `tag-line-text` of a `tag-line` of a `tag-text`: the union of
  the file lines of the line of that tag line and of its
  `continuation-line`s;
- of any other `slice` `r` of a `tag-text`, of a `tag-line-text`, or of
  the Markdown document of a `tag-text` or of a markdown text
  (`front-matter`): the set of file lines that hold at least one 1-based
  character index in the `origin` of `r`.

A part is **in** a set of file lines when its set of file lines is
non-empty and is a subset of that set. A part is **outside** a set of
file lines when none of its file lines belongs to that set.

#### Tree inputs and accepted inputs

@term accepted-input=v1
@cites {
    conformance#conforming-program=v1,
    identifiers#{
        external-namespaces=v1, citation=v1, continuation-line=v1,
        line-result=v1, give-line-results=v1, link=v1, link-result=v1,
        give-link-results=v1,
    },
    ontology#tree=v1,
    text#text=v1,
    #{
        file-readers=v1, read-file=v1, unreadable-file=v1,
        front-matter=v1, tag-text=v1,
    },
}

For a `tree` under valid bindings of `file-readers` and
`external-namespaces`, the **inputs of the tree** are the line inputs
and link inputs evaluated by a conforming program of Identifiers
(`give-line-results`, `give-link-results`) under that binding of
`external-namespaces` across every readable file (`read-file`,
`unreadable-file`) of the tree:

- each line of each `tag-text` of a readable file that is not a
  `continuation-line` of a preceding `citation`, paired with its
  `continuation-line`s when that line is a `citation`;
- each `link` of the markdown document (`front-matter`) of each readable
  markdown file;
- each `link` of the Markdown document (`identifiers#link`) of each
  `tag-text` of each readable code file.

The **result** of an input of the tree is the `line-result` or
`link-result` that a conforming program of Identifiers returns for that
input under that binding of `external-namespaces`. An **accepted input**
of the tree is an input of the tree whose result is `"valid"`. The
**file** of an input of the tree is the readable file whose `tag-text`
or markdown text holds that input.

#### Raw extents

@term raw-extent=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        tag-line=v1, citation=v1, example-tag=v1, continuation-line=v1,
        declaration-line=v1, example-line=v1, link=v1,
    },
    text#{text=v1, slice=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1,
        markdown-section=v1, markdown-list-item=v1, tag-text=v1,
        file-line=v1,
    },
}

A `markdown-line`, a line of a `tag-text`, or a `file-line` is a
**blank line** (and is **blank**) when its `text` is a blank line as
`continuation-line` defines it.

In a `tag-text` of a readable file (`read-file`, `unreadable-file`), a
line is an **example-tag opener** when it is an `example-tag` whose text
meets `example-line` and, for a code file, that line also belongs to a
paragraph of the Markdown document (`identifiers#link`) of that
`tag-text` that no block quote contains. Scanning the lines of a
`tag-text` that are not `continuation-line`s of a preceding `citation`
in line order, a line is a **text declaration** of that `tag-text` when
its text meets `declaration-line` and no earlier line of that `tag-text`
is an example-tag opener that follows an earlier text declaration of
that `tag-text`.

In a `tag-text` of a readable code file, a **tag-text block** starts at
each `tag-line` of that `tag-text` that meets both of these conditions:

- The line is the first line of the `tag-text` or comes immediately
  after a line that is neither a `tag-line` nor a `continuation-line` of
  a preceding `citation`.
- The line does not stand at or after an example-tag opener that follows
  a text declaration of that `tag-text`.

For such a starting line, let `H` be that line together with every
immediately following line that is a `tag-line` or a `continuation-line`
of a preceding `citation`, stopping before any example-tag opener that
follows a text declaration in `H`. The **trailing prose** of the
tag-text block consists of every immediately following line after `H`,
one after another, stopping before the next `tag-line`—except that when
`H` holds a text declaration and the line immediately after `H`, or a
line of the trailing prose, is an example-tag opener, that example-tag
opener and every remaining line of the `tag-text` belong to the trailing
prose of that tag-text block. The lines of the tag-text block are the
lines of `H` followed by its trailing prose, in their order in the
`tag-text`.

For a text declaration `d` in a `tag-text` `T` of a readable file, with
the text declarations of `T` ordered by their line in `T`, the **raw
extent** of `d` is a set of `file-line` `slice`s of that file:

1. For a markdown file, `T` comes from the first paragraph of a
   `markdown-section` or `markdown-list-item` `S`. The raw extent starts
   at the first line of `S` when `d` is the first text declaration of
   `T`, and at the `file-line` of `d` otherwise. The raw extent ends at
   the `markdown-line` immediately before the `file-line` of the next
   text declaration of `T` when one follows `d`, and at the last line of
   `S` otherwise. The initial raw extent holds every `markdown-line`
   from that start line through that end line.
2. For a code file, `d` lies in one tag-text block `B` of `T`, with the
   text declarations in `B` ordered by their line in `B`. The raw extent
   starts at the first line of `B` when `d` is the first text
   declaration in `B`, and at the line of `d` in `B` otherwise. The raw
   extent ends at the line of `B` immediately before the next text
   declaration in `B` when one follows `d`, and at the last line of `B`
   otherwise. The initial raw extent holds the `file-line` of each line
   of `B` from that start line through that end line.
3. Remove every trailing blank line from the initial raw extent: every
   `file-line` that comes after the last non-blank `file-line` of the
   initial raw extent in `file-line` order.

#### Example blocks

@term example-block=v1
@cites {
    commonmark/0.31.2,
    identifiers#{example-tag=v1, example-line=v1},
    packs#{valid-pack=v1, valid-descriptor=v1, foreign-tag-word=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1,
        front-matter=v1, paragraph-line=v1, tag-text=v1, file-line=v1,
        raw-extent=v1,
    },
}

For a readable file `f` (`read-file`, `unreadable-file`) and a text
declaration `d` in `f` (`raw-extent`), the **own file lines** of `d` are
the `file-line` slices in the `raw-extent` of `d` that belong to the
`raw-extent` of no other text declaration `e` in `f` whose `raw-extent`
is a subset of the `raw-extent` of `d`.

An **example opener** of `d` is a `file-line` in the own file lines of
`d` that comes strictly after the `file-line` of `d` in `file-line`
order and meets the rule for the file's reader:

- For a markdown file: that `file-line` is a `markdown-line` that holds
  a `paragraph-line` of a paragraph of the markdown document
  (`front-matter`) of `f` that no block quote contains, and that
  `paragraph-line` is an `example-tag` whose text meets `example-line`.
- For a code file: that `file-line` is the `file-line` of a line of
  `d`'s `tag-text` that is an example-tag opener (`raw-extent`).

Order the example openers of `d` in `file-line` order of `f`, assigning
them 1-based indices `1, 2, ...`. Each example opener `op` with 1-based
index `k` opens one **example block** of `d` with 1-based index `k`. The
`file-line` slices of that example block are the maximal contiguous
sequence, in `file-line` order of `f`, of `file-line` slices starting at
`op` such that every line belongs to the own file lines of `d` and no
line after `op` is an example opener of `d`.

In a code file whose `valid-pack` has a `valid-descriptor` listing
`@example` as a `foreign-tag-word`, Sinter's `@example` takes precedence
over the foreign tag word, and each example opener of a text declaration
opens an example block of that text declaration.

@example In this Markdown file, the [raw extent](sinter:#raw-extent=v1)
of `r` is removed from the own [file lines](sinter:#file-line=v1) of
`d`:

```markdown
# D
@design d=v1
Intro.

@example Intro example.

## R
@req r=v1
Norm.
@example
@req fake=v1
See [r](sinter:#r=v1).

## After
Trailing.
```

Example block 1 of `d` stops before `## R` and leaves `## After` outside
every example block of `d`. Inside example block 1 of `r`, `@req
fake=v1` is plain example text and declares no item, while
`[r](sinter:#r=v1)` remains an active
[inline citation](sinter:identifiers#inline-citation=v1) link input
([accepted-input](sinter:#accepted-input=v1)).

In a code file whose pack lists `@example` as a
[foreign tag word](sinter:packs#foreign-tag-word=v1), an `@example` line
in the trailing prose of the tag-text block
([raw-extent](sinter:#raw-extent=v1)) that holds `@req d#r=v1` opens an
example block of that declaration, whereas a standalone `@example`
comment outside every text declaration, or a JSDoc `@example` after a
`@param` line that starts a new tag-text block, opens no example block.

#### Edit distance

@term edit-distance=v1
@cites text#{character=v1, text=v1}

An **edit** of a `text` inserts one `character`, removes one
`character`, replaces one `character` with another `character`, or swaps
two adjacent characters. The **edit distance** between two `text` values
`a` and `b` is the least non-negative integer `n` such that a sequence
of `n` edits transforms `a` into `b`, where each edit acts on the `text`
produced by the preceding edits.

#### Findings of the class `parse-error`

@atom parse-error-finding=v1
@cites {
    files#path=v1,
    findings#{location=v1, path-finding-subject=v1},
    ontology#tree=v1,
    #{read-file=v1, unreadable-file=v1, tree-finding=v1},
}

A `tree` has one `tree-finding` of the class `parse-error` for each
`read-file` of the tree that is an `unreadable-file`. Its subject is the
`path-finding-subject` of the file's valid `path`. Its `location` is the
file's valid `path` alone, with no span.

#### Findings of the class `typo-tag`

@atom typo-tag-finding=v1
@cites {
    identifiers#{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, tag-line-text=v1,
    },
    ontology#tree=v1,
    packs#{valid-pack=v1, valid-descriptor=v1, foreign-tag-word=v1},
    #{
        read-file=v1, unreadable-file=v1, tag-text=v1, origin=v1,
        origin-position=v1, file-line=v1, example-block=v1,
        edit-distance=v1, position-subject=v1, slice-location=v1,
        tree-finding=v1,
    },
}

A `tree` has one `tree-finding` of the class `typo-tag` for each line of
a `tag-text` of a readable file (`read-file`, `unreadable-file`) of the
tree when all four of these conditions hold:

- The line is a `tag-line` whose `file-line` belongs to no
  `example-block` of that file.
- Its `tag-word` is not a `sinter-tag-word`.
- When the file is a code file, its `tag-word` is not a
  `foreign-tag-word` of the `valid-descriptor` of the file's
  `valid-pack`.
- The `edit-distance` between its `tag-word` and at least one
  `sinter-tag-word` is 1 or 2.

Its subject is the `position-subject` of the `origin-position` of the
`tag-line-text` of that tag line. Its `location` is the `slice-location`
of the slice of that `tag-line-text` in the file's text (`origin`).

#### Findings of the class `ignored-tag`

@atom ignored-tag-finding=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, declaration=v1,
        citation=v1, status-tag=v1, directive=v1, tag-line-text=v1,
        inline-description=v1, link=v1,
    },
    ontology#tree=v1,
    text#{character=v1, text=v1, slice=v1, production=v1},
    #{
        read-file=v1, unreadable-file=v1, markdown-line=v1,
        front-matter=v1, markdown-section=v1, markdown-list-item=v1,
        paragraph-line=v1, tag-text=v1, origin=v1, origin-position=v1,
        file-line=v1, example-block=v1, edit-distance=v1,
        position-subject=v1, slice-location=v1, tree-finding=v1,
    },
}

The **heading lines** of a setext heading of a readable markdown file
are `slice` values of the file's text, one for each `markdown-line` that
the setext heading takes (`markdown-section`) other than its last
`markdown-line`. For each such `markdown-line`, take the characters of
that `markdown-line` that CommonMark 0.31.2 assigns to the content of
the setext heading; the heading line is the `slice` of that
`markdown-line` from the boundary immediately before the first of those
characters that is neither a space (U+0020) nor a tab (U+0009) to the
end boundary of that `markdown-line`.

A `tree` has one `tree-finding` of the class `ignored-tag` for each
`slice` `L` of each block `B` of the markdown document (`front-matter`)
of a readable markdown file (`read-file`, `unreadable-file`) of the tree
when all of these conditions hold:

- `B` is a paragraph and `L` is one of its `paragraph-line` slices, or
  `B` is a setext heading and `L` is one of its heading lines.
- No block quote contains `B`.
- `B` is a top-level block of the markdown document
  (`markdown-section`), or `B` is a block that a `markdown-list-item`
  contains and that no block quote, no list, and no inner list item
  contains.
- When `B` is a paragraph, `B` is neither the first paragraph of a
  `markdown-section` nor the first paragraph of a `markdown-list-item`.
- The `markdown-line` holding `L` belongs to no `example-block` of that
  file.
- `L` is a `tag-line` whose `tag-word` is a `sinter-tag-word` or has an
  `edit-distance` of 1 or 2 from a `sinter-tag-word`.

Let `A` be the `slice` of the file's text from the boundary immediately
before the first `@` of `L` to the end boundary of `L`. Its subject is
the `position-subject` of the `origin-position` of `A`, and its
`location` is the `slice-location` of `A`.

A **tag word of an inline description** is the text of a `slice` of an
`inline-description` that starts at boundary 0 of that
`inline-description` or immediately after a space (U+0020) or a tab
(U+0009), and that is the longest `slice` starting there whose text
matches the `production` `tag-word`.

A `tree` also has one `tree-finding` of the class `ignored-tag` for each
`tag-line` `M` of a `tag-text` of a readable file (`read-file`,
`unreadable-file`) of the tree when all three of these conditions hold:

- No `file-line` of the `tag-line-text` of `M` belongs to any
  `example-block` of that file.
- `M` is a `declaration`, a `citation`, a `status-tag`, or an `@extern`
  `directive`.
- At least one tag word of the `inline-description` of `M` is a
  `sinter-tag-word` whose `@` comes (`origin`) from a 1-based character
  index in the file's text from which no character of a CommonMark
  0.31.2 code span comes.

For a markdown file, those code spans are the CommonMark 0.31.2 code
spans of the markdown document (`front-matter`) of the file. For a code
file, those code spans are the CommonMark 0.31.2 code spans of the
Markdown document (`identifiers#link`) of the `tag-text` of `M`. Let `R`
be the `slice` of the `tag-line-text` of `M` from the boundary
immediately before the `@` of the first such tag word to the end
boundary of the `tag-line-text` of `M`, and let `C` be the slice of `R`
in the file's text (`origin`). Its subject is the `position-subject` of
the `origin-position` of `C`, and its `location` is the `slice-location`
of `C`.

### Returning read files

@req give-read-files=v1
@cites {
    conformance#conforming-program=v1,
    ontology#tree=v1,
    #{file-readers=v1, read-file=v1},
}

Given a `tree` and a valid binding of `file-readers`, when a conforming
program returns the read files of that tree, the program must return
each `read-file` of the tree once, paired with its reader, and no other
file.

### Returning file findings

@req give-file-findings=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{tree=v1, finding-class=v1},
    #{
        file-readers=v1, tree-finding=v1, parse-error-finding=v1,
        typo-tag-finding=v1, ignored-tag-finding=v1,
    },
}

Given a `tree` and a valid binding of `file-readers`, when a conforming
program returns the findings of that tree of one of the finding classes
(`finding-class`) `parse-error`, `typo-tag`, or `ignored-tag`, the
program must return once each `tree-finding` of that class that the tree
has (`parse-error-finding`, `typo-tag-finding`, `ignored-tag-finding`),
and no other finding of that class.

## Declarations

@spec declarations=v1

Declarations in text files and declared-item objects in `.sinter/`
supply the declared items of a tree. Each text declared item occupies
lines of one file, and lines outside every declared item and every
comment on a test form sites.

### Definitions

#### Declared items and files

@term item-file=v1
@cites {
    identifiers#{declaration=v1, label=v1, external-namespaces=v1},
    ontology#{
        declared-item=v1, tree=v1, object=v1, object-kind=v1,
        object-withdrawal=v1, revised-content=v1, encoding=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    ledger#accepted-record=v1,
    #{
        file-readers=v1, read-file=v1, tag-text=v1, accepted-input=v1,
        example-block=v1,
    },
}

For a `tree` with valid bindings of `file-readers` and
`external-namespaces`, each `accepted-input` that is a `declaration` and
does not lie inside an `example-block` declares one **text declared
item** of the tree, and the tree has no other text declared item. That
accepted input is the **declaration** of that text declared item. The
**file** of that text declared item is the `read-file` whose `tag-text`
holds that declaration. The declaration word determines the item's kind
(`declared-item`), and its revision `label` (when present) follows
`revised-content`.

When the `tree-object-store` of the tree is valid, each declared-item
`object` (`declared-item`, `object-kind`) in a `valid-object-file` of
`.sinter/` of the tree that is neither withdrawn nor replaced in that
tree (`object-withdrawal`, using the acceptance rule for `"void"` in
`ledger#accepted-record`) is one **stored declared item** of the tree,
and the tree has no other stored declared item. The **file** of that
stored declared item is that valid object file. Its member `kind`
determines its kind of item, and its member `label` (when present) is
its revision `label` (`revised-content`).

When the `tree-object-store` of the tree is valid, the **declared
items** of the tree are its text declared items together with its stored
declared items (spanning both encodings under `ontology#encoding`), and
the tree has no other declared item.

#### Declaration scopes

@term declaration-scope=v1
@cites {
    ontology#{tree=v1, declared-item=v1},
    text#{text=v1, slice=v1},
    packs#node-slice=v1,
    #{
        read-file=v1, item-file=v1, raw-extent=v1, file-line=v1,
        tag-text=v1, comment-sequence=v1, attachment=v1,
        code-character=v1, markdown-line=v1, markdown-section=v1,
        markdown-list-item=v1,
    },
}

The **declaration scope** of a text declared item `d` of the kind
`design` or `spec` of a tree is a set of `file-line`s of the file of
`d`:

- When the file of `d` is a markdown file (`read-file`), and `S` is the
  `markdown-section` or `markdown-list-item` whose first paragraph
  produces the `tag-text` holding the declaration of `d`, the
  declaration scope of `d` is the `markdown-line`s of `S`.
- When the file of `d` is a code file and `d` is of the kind `design`,
  the declaration scope of `d` is the lines of the `raw-extent` of `d`.
- When the file of `d` is a code file, `d` is of the kind `spec`, and
  `R` is the `comment-sequence` whose `tag-text` holds the declaration
  of `d`:
  - when `R` attaches (`attachment`) to an attachment target `T`, the
    lines that the `tag-text` of `R` joins, together with each
    `file-line` of the file whose `slice` starts at or after the start
    boundary of the `node-slice` of `T` and ends at or before the end
    boundary of the `node-slice` of `T`;
  - when `R` is unattached and no `code-character` of the file lies at a
    1-based character index (`text#text`) before the start boundary of
    `R`, every `file-line` of the file;
  - otherwise, the lines that the `tag-text` of `R` joins.

A thing lies **in the declaration scope** of `d` when every `file-line`
of that thing belongs to this set of file lines.

#### Innermost items

@term innermost-item=v1
@cites {
    ontology#declared-item=v1,
    #{file-line=v1, item-file=v1, declaration-scope=v1},
}

Take a thing and a collection of text declared items (`item-file`), each
paired with a set of `file-line`s that contains the thing. When exactly
one of these text declared items has a set of file lines that is a
subset of the set of every other item in the collection, that text
declared item is the **innermost** of these items by those sets.
Otherwise, none of these items is the innermost.

The **innermost text `design`** (or **innermost text `spec`**) in whose
`declaration-scope` a thing lies is the innermost, by their declaration
scopes, of the text declared items of that kind in whose declaration
scopes the thing lies.

#### Designs of slugs

@term slug-design=v1
@cites {
    identifiers#slug=v1,
    ontology#{tree=v1, declared-item=v1, item-name=v1, encoding=v1},
    #item-file=v1,
}

In a `tree`, the **design of a slug** is the declared item of the kind
`design` of the tree (in either the text encoding or the `.sinter/`
encoding, `ontology#encoding`) whose name (`item-name`) is that `slug`,
when no other declared item of the kind `design` and no declared item of
the kind `decision` of the tree has that slug as its name. Otherwise,
that slug has no design.

#### Home designs

@term home-design=v1
@cites {
    identifiers#{
        tag-line=v1, tag-line-text=v1, inline-citation=v1, full-name=v1,
        slug=v1, target=v1, declaration=v1,
    },
    ontology#{tree=v1, declared-item=v1},
    #{
        read-file=v1, tag-text=v1, file-line=v1, raw-extent=v1,
        item-file=v1, declaration-scope=v1, innermost-item=v1,
        slug-design=v1,
    },
}

The **home design** of a `tag-line` of a `tag-text` (by its
`tag-line-text`) or of an `inline-citation` in a `tree` is determined
by the first matching case:

1. When the text declared items of the kind `design` in whose
   `declaration-scope`s the tag line or inline citation lies have an
   `innermost-item`, the home design is that innermost item.
2. When all four of these conditions hold, the home design is `D`:
   - the tag line or inline citation lies in a code file (`read-file`);
   - the text declared items of the kinds `req`, `schema`, `atom`, and
     `term` in whose `raw-extent`s the tag line or inline citation lies
     have an `innermost-item` by their raw extents;
   - the name in the `target` of the `declaration` of that innermost
     item is a `full-name`;
   - the `slug` of that full name has a design (`slug-design`), and that
     design is `D`.
3. When all three of these conditions hold, the home design is `D`:
   - the text declared items of the kind `spec` in whose
     `declaration-scope`s the tag line or inline citation lies have an
     `innermost-item`;
   - the name in the `target` of the `declaration` of that innermost
     item is a `full-name`;
   - the `slug` of that full name has a design (`slug-design`), and that
     design is `D`.
4. Otherwise, the tag line or inline citation has no home design.

#### Text containment and design containment

@term text-containment=v1
@cites {
    identifiers#{target=v1, full-name=v1, slug=v1, segment=v1},
    ontology#{tree=v1, containment=v1, declared-item=v1},
    #{
        item-file=v1, home-design=v1, declaration-scope=v1,
        innermost-item=v1, slug-design=v1,
    },
}

In a `tree`, design containment across both encodings and text
specification containment (`containment`) hold only as follows:

- **Design containment:** A declared item `d` of one of the kinds
  `spec`, `req`, `schema`, `atom`, and `term` belongs to an item of the
  kind `design` as follows:
  - when `d` is a stored declared item (`item-file`) whose member `name`
    is a `full-name` and the `slug` of that full name has a design
    (`slug-design`), `d` belongs to that design;
  - when `d` is a text declared item whose declaration `target` holds a
    `full-name` and the `slug` of that full name has a design
    (`slug-design`), `d` belongs to that design;
  - when `d` is a text declared item whose declaration `target` holds a
    single `segment` and the declaration of `d` has a `home-design`, `d`
    belongs to that home design;
  - otherwise, `d` belongs to no item of the kind `design`.
- **Text specification containment:** A text declared item `d` of one of
  the kinds `req`, `schema`, `atom`, and `term` belongs to a text
  declared item `S` of the kind `spec` **by text containment** when, and
  only when, `S` is the `innermost-item` among the text declared items
  of the kind `spec` in whose `declaration-scope` the declaration of `d`
  lies, and either `d` and `S` belong to the same item of the kind
  `design` or both `d` and `S` belong to no item of the kind `design`.

@example In this code file, the
[comment sequence](sinter:#comment-sequence=v1) holding
`@spec journal#entry-ids=v2` attaches
([attachment](sinter:#attachment=v1)) to the module definition:

```ocaml
(* @spec journal#entry-ids=v2
   Each entry of the journal has an id fixed by its bytes. *)
module Entry_id = struct
  (* @req id-form=v1
     An id starts with "e-" and SHA-256 hex digits. *)
  let of_line line = digest line
end
```

The [declaration scope](sinter:#declaration-scope=v1) of
`journal#entry-ids` covers its comment lines and the
[file lines](sinter:#file-line=v1) inside the module's
[node slice](sinter:packs#node-slice=v1). When the
[slug](sinter:identifiers#slug=v1) `journal` has a
[design](sinter:#slug-design=v1) in the tree, case 3 of
[home-design](sinter:#home-design=v1) assigns that design as the home
design of `@req id-form=v1`. Because `id-form` is a single
[segment](sinter:identifiers#segment=v1), the requirement belongs to
`journal` and by text containment to `journal#entry-ids`, so its
resolved [item name](sinter:ontology#item-name=v1) is `journal#id-form`.

#### Extents

@term extent=v1
@cites {
    ontology#{tree=v1, containment=v1, declared-item=v1},
    #{item-file=v1, raw-extent=v1, file-line=v1, text-containment=v1},
}

The **extent** of a text declared item `d` of a `tree` is the set of
these `file-line`s of the file of `d`, in file-line order:

- each line of the `raw-extent` of `d` that is not a line of the
  `raw-extent` of another text declared item `e` of the file of `d`
  whose `raw-extent` is a subset of the `raw-extent` of `d` and that
  does not belong to `d` under `text-containment`;
- each line of the `extent` of each text declared item `h` of the file
  of `d` that belongs to `d` under `text-containment`.

#### Hashed lines

@term hashed-line=v1
@cites {
    ontology#{tree=v1, declared-item=v1, containment=v1},
    #{
        item-file=v1, extent=v1, text-containment=v1, file-line=v1,
        example-block=v1,
    },
}

The **hashed lines** of a text declared item `d` of a `tree` are these
`file-line`s of the file of `d`, in file-line order:

- When `d` is of the kind `design` or `spec`, the lines of the `extent`
  of `d`, excluding the lines of the `extent` of each text declared item
  that belongs to `d` under `text-containment`, and excluding every
  `file-line` of each `example-block` of `d`.
- When `d` is of another kind (`req`, `schema`, `atom`, `term`, or
  `decision`), the lines of the `extent` of `d`, excluding every
  `file-line` of each `example-block` of `d`.

@example In this Markdown file, `d` holds `d#r1` by
[text containment](sinter:#text-containment=v1) and both items carry
trailing [example blocks](sinter:#example-block=v1):

```markdown
# D
@design d=v1
Intro.

@example Design intro example.

## R1
@req r1=v1
Must hold.

@example Requirement example.

## After
Trailing under D.
```

The [extent](sinter:#extent=v1) of `d` spans all fourteen lines,
including both example blocks and `d#r1`. The hashed lines of `d`
exclude the design's intro example block and the entire extent of
`d#r1`, keeping `# D`, `@design d=v1`, `Intro.`, `## After`, and
`Trailing under D.` (with separating blank lines). The extent of `d#r1`
spans `## R1` through `@example Requirement example.`, whereas the
hashed lines of `d#r1` exclude `@example Requirement example.`.

#### Sets of names

@term name-set=v1
@cites {
    identifiers#{slug=v1, full-name=v1},
    text#text=v1,
    ontology#{tree=v1, item-name=v1, declared-item=v1, encoding=v1},
    #{item-file=v1, slug-design=v1, text-containment=v1},
}

The **sets of names** of a `tree` span both encodings
(`ontology#encoding`) and consist of:

- the **shared set**, holding every declared item of the tree of the
  kind `design`, every declared item of the tree of the kind `decision`,
  and every declared item of the tree of the kinds `spec`, `req`,
  `schema`, `atom`, and `term` that belongs to no item of the kind
  `design` (`text-containment`) and whose name (`item-name`) is a
  `slug`;
- for each declared item `D` of the kind `design` of the tree, the **set
  of `D`**, holding every declared item of the tree of the kinds `spec`,
  `req`, `schema`, `atom`, and `term` that belongs to `D`
  (`text-containment`).

For a `slug` `n`, its **name set** is the shared set. For a `full-name`
`n` whose `slug` has a design `D` (`slug-design`), its **name set** is
the set of `D`; when that slug has no design, `n` has no name set. A
name `n` (a `slug` or `full-name`) **names** a declared item `d` in the
tree when `n` has a name set and `d` is the unique declared item in that
name set whose name equals `n` (`text#text`). When zero items, or two
or more items, in that name set have exact name `n`, `n` names no item.

#### Vector files

@term vector-file=v1
@cites {
    files#path=v1,
    data-forms#test-vector-set=v1,
    ontology#{
        tree=v1, item-name=v1, vector-set=v1, declared-item=v1,
        encoding=v1,
    },
    #{
        vector-files=v1, item-file=v1, text-containment=v1,
        name-set=v1,
    },
}

For a `tree` and a valid binding of `vector-files`, a declared item `x`
of the tree (in either the text encoding or the `.sinter/` encoding,
`ontology#encoding`) is eligible for a vector file when `x` meets both
of these conditions:

- `x` is either an item of the kind `design`, or an item of the kind
  `spec` that belongs to an item of the kind `design`
  (`text-containment`);
- the name (`item-name`) of `x` uniquely names `x` in its `name-set`
  (in the shared set for a `design`, or in the set of its unique design
  for a `spec`).

When an eligible item `x` has its name mapped by `vector-files` to a
valid `path` `p` and the tree holds a file at `p`, that file is the
**vector file** of `x` in the tree. When `x` has a vector file and the
content of that file is a `test-vector-set`, that content is the
**vector set** (`ontology#vector-set`) of `x` in the tree; otherwise,
`x` has no vector set. A pair of `vector-files` whose path names no file
of the tree, or whose target name names no eligible item, produces no
vector file.

#### Sites

@term tree-site=v1
@cites {
    identifiers#{
        tag-line=v1, tag-line-text=v1, citation=v1, inline-citation=v1,
        directive=v1,
    },
    packs#{comment-node=v1, node-slice=v1},
    ontology#{tree=v1, site=v1, test=v1},
    text#{text=v1, line=v1, slice=v1},
    #{
        read-file=v1, unreadable-file=v1, tag-text=v1, front-matter=v1,
        markdown-section=v1, markdown-line=v1, comment-sequence=v1,
        file-test=v1, file-line=v1, extent=v1, item-file=v1,
    },
}

In a `tree`, a **line of an extent** is a `file-line` that belongs to
the `extent` of at least one text declared item (`item-file`) of the
tree. A thing is **outside every extent** when none of its `file-line`s
is a line of an extent. The **sites** (`ontology#site`) of a readable
`read-file` (`unreadable-file`) of the tree are these sets of
`file-line`s of the file, each ordered in file-line order:

- **In a markdown file:** Take each `citation` (accepted or not) of a
  `tag-text` of the file, each `@ack` line (`directive`, accepted or
  not) of a `tag-text` of the file, and each `inline-citation` (accepted
  or not) of the markdown document of the markdown text (`front-matter`)
  of the file that is outside every extent. For each such thing `X`, the
  **site lines** of `X` are the `markdown-line`s of the markdown text
  that are not lines of an extent and that run from a first line to a
  last line:
  - When a heading that opens a section (`markdown-section`) has its
    line at or before the first `file-line` of `X`, the first line is
    the line of the last such heading; otherwise, the first line is the
    first `markdown-line` of the markdown text.
  - The last line is the `markdown-line` immediately before the line of
    the next heading that opens a section after that first line, or the
    last `markdown-line` of the markdown text when no such heading
    follows.
  Two such sets of site lines are **linked** when a `line` of the `text`
  of the file shares a 1-based character index (`slice`) with a
  `markdown-line` of each set. For each maximal connected group of such
  sets of site lines linked directly or through others of the group, the
  union of the `markdown-line`s of its sets is one site of the file.
- **In a code file:** Take each `comment-sequence` of the file that is
  not a comment on a test (`file-test`) and whose `tag-text` holds a
  `citation` (accepted or not), an `@ack` line (`directive`, accepted or
  not), or an `inline-citation` (accepted or not) of the markdown
  document of that `tag-text` that is outside every extent. The **site
  lines** of such a comment sequence are the `file-line`s that its
  `tag-text` joins and that are not lines of an extent. Two such comment
  sequences are **linked** when a `line` of the `text` of the file
  shares a 1-based character index (`slice`) with the `node-slice` of a
  `comment-node` of each comment sequence. For each maximal connected
  group of such comment sequences linked directly or through others of
  the group, the union of the site lines of its comment sequences is one
  site of the file.

A site **holds** a `markdown-line`, a line of a `tag-text`, the
`tag-line-text` of a `tag-line`, or an `inline-citation` when, and only
when, that thing has at least one `file-line` and every `file-line` of
that thing belongs to that site.

#### Parts of declared items

@term item-part=v1
@cites {
    identifiers#{tag-line=v1, tag-line-text=v1, inline-citation=v1},
    text#slice=v1,
    packs#node-slice=v1,
    ontology#{
        tree=v1, edge-source=v1, declared-item=v1, test=v1, site=v1,
    },
    #{
        item-file=v1, extent=v1, example-block=v1, innermost-item=v1,
        file-line=v1, file-test=v1, comment-sequence=v1, tag-text=v1,
        markdown-line=v1, tree-site=v1,
    },
}

In a `tree`, take a thing that is a `file-line` (including a
`markdown-line`), a line of a `tag-text`, the `tag-line-text` of a
`tag-line`, or an `inline-citation`, and that has at least one
`file-line`:

- The thing is **a part of** a text declared item `d` when, and only
  when, every `file-line` of the thing belongs to the `extent` of `d`.
- A comment on a test (`file-test`, a `comment-sequence` attached to
  that test) **holds** the thing when, and only when, every `file-line`
  of the thing is a line that the `tag-text` of that comment sequence
  joins.

Under `ontology#edge-source`, such a thing **stands in** the first
matching target:

1. When the thing is a part of one or more text declared items, let `d`
   be the unique `innermost-item` among them by their `extent`s. If
   every `file-line` of the thing belongs to an `example-block` `E` of
   `d`, the thing stands in `E` rather than in `d`; otherwise, the thing
   stands in `d`.
2. Otherwise, when one or more tests (`file-test`) have a comment on
   that test that holds the thing, and exactly one of those tests `T`
   has no other such test whose code `node-slice` lies within the code
   `node-slice` of `T` (start boundary of `T` less than or equal to the
   other's start boundary, and the other's end boundary less than or
   equal to the end boundary of `T`, `text#slice`), the thing stands in
   `T`.
3. Otherwise, when a `site` of the file (`tree-site`) holds the thing,
   the thing stands in that site.
4. Otherwise, the thing stands in no item and no `example-block`.

### Returning declared items and extents

@req give-declared-items=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        read-defined-encodings=v1,
    },
    identifiers#{external-namespaces=v1, label=v1, tag-line-text=v1},
    ontology#{
        tree=v1, declared-item=v1, item-name=v1, revised-content=v1,
        encoding=v1,
    },
    object-store#tree-object-store=v1,
    #{
        file-readers=v1, item-file=v1, text-containment=v1,
        origin-position=v1, extent=v1, file-line=v1,
    },
}

A conforming program (`conforming-program`, `read-defined-encodings`)
must return each declared item of a `tree` (`item-file`, across both the
text encoding and the `.sinter/` encoding, `ontology#encoding`) once,
and must return no other declared item. For each declared item, the
program must return:

- its kind of item (`declared-item`);
- its name (`item-name`, under `text-containment`);
- its file (`item-file`);
- its revision `label` (`revised-content`), or that it carries no
  revision label when absent; and
- for each text declared item, the `origin-position` of the
  `tag-line-text` of its declaration and its `extent` (its `file-line`s
  in file-line order).

When `file-readers`, `external-namespaces`, or `tree-object-store` is
invalid, a conforming program must withhold all declared items and
extents (`reject-invalid-inputs`).

### Returning sites

@req give-sites=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    identifiers#external-namespaces=v1,
    ontology#{tree=v1, site=v1},
    object-store#tree-object-store=v1,
    #{file-readers=v1, read-file=v1, file-line=v1, tree-site=v1},
}

A conforming program (`conforming-program`) must return each site
(`tree-site`, `ontology#site`) of each `read-file` of a `tree` once,
with its file and its `file-line`s in file-line order, and must return
no other site. When `file-readers`, `external-namespaces`, or
`tree-object-store` is invalid, a conforming program must withhold all
sites (`reject-invalid-inputs`).

### Returning status-tag sources

@req give-status-tag-items=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    identifiers#{
        external-namespaces=v1, status-tag=v1, tag-line-text=v1,
    },
    ontology#{tree=v1, edge-source=v1},
    object-store#tree-object-store=v1,
    #{
        file-readers=v1, read-file=v1, accepted-input=v1,
        example-block=v1, origin-position=v1, item-part=v1,
        tree-site=v1, file-test=v1,
    },
}

A conforming program (`conforming-program`) must return once each
`accepted-input` of a `tree` that is a `status-tag` and does not lie
inside an `example-block`, and must return no other status tag. For each
such status tag, the program must return its `read-file`, the
`origin-position` of its `tag-line-text`, and the item in which it
stands (`item-part`, `file-test`, `tree-site`, `edge-source`) or that it
stands in no item. When `file-readers`, `external-namespaces`, or
`tree-object-store` is invalid, a conforming program must withhold all
status-tag results (`reject-invalid-inputs`).

### Returning vector files

@req give-vector-files=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        read-defined-encodings=v1,
    },
    identifiers#external-namespaces=v1,
    files#path=v1,
    data-forms#test-vector-set=v1,
    ontology#{tree=v1, declared-item=v1, vector-set=v1},
    object-store#tree-object-store=v1,
    #{file-readers=v1, vector-files=v1, vector-file=v1},
}

A conforming program (`conforming-program`, `read-defined-encodings`)
must return once each declared item of a `tree` of the kind `design` or
`spec` that has a `vector-file`, together with the valid `path` of that
vector file and its `vector-set` (when that file's content is a
`test-vector-set`, or that it has no vector set otherwise), and must
return no vector file for any other item. When `file-readers`,
`external-namespaces`, `vector-files`, or `tree-object-store` is
invalid, a conforming program must withhold all vector-file and
vector-set results (`reject-invalid-inputs`).

## Canonical objects

@spec canonical-objects=v1

Each declared item, example block, and test-vector group of a tree maps
to a deterministic canonical JSON object with a content hash and content
ID. Text declared items and example blocks normalize CommonMark blocks
and inline elements to a line-oriented form so markup rewrites that keep
the same structure keep the same canonical object, while exact pins
resolve across current items, replaced `.sinter/` objects, and kept
objects from the log branch.

### Definitions

#### Normalized inline text

@term normalized-inline-text=v1
@cites {
    commonmark/0.31.2,
    identifiers#{
        external-namespaces=v1, link=v1, destination=v1,
        inline-citation=v1, link-text=v1, plain-string-content=v1,
        link-result=v1,
    },
    ontology#content-id=v1,
    text#{character=v1, text=v1, algorithm=v1},
    #{markdown-line=v1, accepted-input=v1},
}

This term is for a valid binding of `external-namespaces`
(`accepted-input`) and a target mapping *m* that maps each valid inline
citation to a canonical target `content-id`. Inline elements are those
of CommonMark 0.31.2: textual content, code spans, emphasis, strong
emphasis, links (`identifiers#link`), images, raw HTML, hard line
breaks, and soft line breaks. Inline markup is encoded in braced forms
(`{code:...}`, `{em:...}`, `{strong:...}`, `{link{...}{...}}`,
`{image{...}{...}}`, `{html:...}`, and `{br}`). An `inline-citation` is
**valid** when an inline citation with the same `destination` and the
same `plain-string-content` of its `link-text` has outcome `"valid"`
under `identifiers#link-result` for that binding of
`external-namespaces`.

The text of textual content is its characters, with each backslash
escape, entity reference, and numeric character reference replaced by
the characters that CommonMark 0.31.2 defines for it. The content of a
code span of CommonMark 0.31.2 is its content as CommonMark 0.31.2
defines it. The destination of an image is the destination that
`identifiers#destination` defines for an inline link with the same link
destination. The **normalized destination** of an inline link, a
reference link, or an image is its destination; of a URI autolink is the
text of that autolink between `<` and `>`; and of an email autolink is
`mailto:` followed by the text of that autolink between `<` and `>`. The
title of a link or an image that has a link title is that link title as
CommonMark 0.31.2 defines it, without its enclosing characters, with
each backslash escape, entity reference, and numeric character reference
replaced by the characters that CommonMark 0.31.2 defines for it, and
then with each markdown line ending (`markdown-line`) replaced by a line
feed (U+000A). Another link or image, and each autolink, has no title.
The raw text of raw HTML is its characters, with each markdown line
ending (`markdown-line`) replaced by a line feed (U+000A).

The inline elements of emphasis and of strong emphasis are the inline
elements that they hold. The inline elements of an inline link or a
reference link are the inline elements between the `[` that starts that
link and the `]` that closes that `[`, in their order. The inline
elements of an image are the inline elements of the description of that
image, in their order.

The escaped text of a text *t* is the text that these steps give.

1. Let *u* be the empty text.
2. For each *c* of *t*, in order:
   1. If *c* is a line feed (U+000A), append `\n` to *u*.
   2. Otherwise:
      1. If *c* is `\`, `{`, or `}`, append `\` to *u*.
      2. Append *c* to *u*.
3. Give *u*.

The single-spaced text of a text *t* is the text that these steps give.

1. Let *u* be the empty text.
2. For each *c* of *t*, in order:
   1. If *c* is a space (U+0020) or a tab (U+0009), then:
      1. If *u* is empty or the last character of *u* is not a space
         (U+0020), append a space (U+0020) to *u*.
   2. Otherwise, append *c* to *u*.
3. Give *u*.

The normalized inline text of a sequence *s* of inline elements under
target mapping *m* is the text that these steps give.

1. Let *w* be the empty text.
2. Let *pending* be the empty text.
3. For each *x* of *s*, in order:
   1. If *x* is textual content, append the text of *x* to *pending*.
   2. If *x* is a soft line break, append a space (U+0020) to *pending*.
   3. If *x* is neither textual content nor a soft line break, then:
      1. Append the escaped text of the single-spaced text of *pending*
         to *w*.
      2. Set *pending* to the empty text.
   4. If *x* is a code span of CommonMark 0.31.2, then:
      1. Append `{code:` to *w*.
      2. Append the escaped text of the content of *x* to *w*.
      3. Append `}` to *w*.
   5. If *x* is emphasis, then:
      1. Append `{em:` to *w*.
      2. Append the normalized inline text of the inline elements of *x*
         under *m* to *w*.
      3. Append `}` to *w*.
   6. If *x* is strong emphasis, then:
      1. Append `{strong:` to *w*.
      2. Append the normalized inline text of the inline elements of *x*
         under *m* to *w*.
      3. Append `}` to *w*.
   7. If *x* is a link or an image, then:
      1. Let *to* be the normalized destination of *x*.
      2. If *x* is a valid inline citation, set *to* to `sinter:`
         followed by the canonical target content ID that *m* maps *x*
         to.
      3. If *x* is a link, append `{link{` to *w*.
      4. Otherwise, append `{image{` to *w*.
      5. If *x* is an autolink, then:
         1. Let *shown* be the text of *x* between `<` and `>`.
         2. If *x* is a valid inline citation, set *shown* to *to*.
         3. Append the escaped text of *shown* to *w*.
      6. Otherwise, append the normalized inline text of the inline
         elements of *x* under *m* to *w*.
      7. Append `}{` to *w*.
      8. Append the escaped text of *to* to *w*.
      9. If *x* has a title, then:
         1. Append `}{` to *w*.
         2. Append the escaped text of the title of *x* to *w*.
      10. Append `}}` to *w*.
   8. If *x* is raw HTML, then:
      1. Append `{html:` to *w*.
      2. Append the escaped text of the raw text of *x* to *w*.
      3. Append `}` to *w*.
   9. If *x* is a hard line break, append `{br}` to *w*.
4. Append the escaped text of the single-spaced text of *pending* to
   *w*.
5. Give *w*.

#### Normalized lines

@term normalized-line=v1
@cites {
    commonmark/0.31.2,
    rfc/5234,
    identifiers#{
        external-namespaces=v1, tag-line=v1, declaration=v1,
        citation=v1, status-tag=v1, directive=v1, continuation-line=v1,
        tag-line-text=v1, inline-description=v1, link-text=v1,
    },
    ontology#{tree=v1, declared-item=v1},
    text#{
        character=v1, text=v1, slice=v1, production=v1,
        decimal-numeral=v1, algorithm=v1,
    },
    #{
        file-readers=v1, read-file=v1, unreadable-file=v1,
        comment-line=v1, markdown-line=v1, front-matter=v1,
        markdown-section=v1, markdown-list-item=v1, paragraph-line=v1,
        tag-text=v1, file-line=v1, accepted-input=v1, example-block=v1,
        item-file=v1, hashed-line=v1, normalized-inline-text=v1,
    },
}

A **section number** is a `text` that matches the `production`
`section-number`:

```abnf
section-number  = 1*DIGIT "." [ 1*DIGIT *( "." 1*DIGIT ) [ "." ] ] 1*WSP
```

This term is for a `tree`, a valid binding of `file-readers`, a valid
binding of `external-namespaces` (`accepted-input`), and a target
mapping *m* (`normalized-inline-text`). Normalized lines encode blocks
and tag clusters with a leading **prefix** (`heading `, `paragraph: `,
`code`, `html:`, `break`, `quote:`, `bullet list:`,
`ordered list from `, `item:`, `task: `, `tag: `, or `| `) after depth
indentation.

A block in this term is a block of CommonMark 0.31.2 of a Markdown
document: either the Markdown document of a readable Markdown file
(`markdown-section`, `front-matter`) or a Markdown document parsed by
the steps of this term. A blank line is not a block, and a link
reference definition is a block. A heading of a Markdown document parsed
by the steps of this term opens no section and is no text declared
item's own heading, and no paragraph of such a Markdown document
produces a `tag-text`.

When the file of a text declared item *d* (`item-file`) is a Markdown
file and a heading that opens a section has a line before the file line
of the declaration of *d*, the **base level** of *d* is the level of the
last such heading. Otherwise, the **base level** of *d* is `0`. The
**own heading** of *d* is the heading that opens a section whose first
paragraph produces the `tag-text` holding the declaration of *d* (none
when *d* is not declared in a section's first paragraph). When the
declaration of *d* stands in the `tag-text` of the first paragraph of a
`markdown-list-item`, the **list indentation** of *d* is the number of
characters on the first markdown line of that paragraph before the first
character of that markdown line that CommonMark 0.31.2 assigns to the
content of that paragraph and that is not a space (U+0020) or a tab
(U+0009); otherwise, the **list indentation** of *d* is `0`.

The children of a block quote or of a list item are the blocks that it
contains and that no other block inside it contains, in their order. The
children of a list are its list items, in their order. The start number
of an ordered list is the start number that CommonMark 0.31.2 defines
for it. The info string of a fenced code block is the info string that
CommonMark 0.31.2 defines for that fenced code block, without leading
and trailing spaces (U+0020) and tabs (U+0009), and with each backslash
escape, entity reference, and numeric character reference replaced by
the characters that CommonMark 0.31.2 defines for it. A code block has
an info string only when it is a fenced code block and that text is not
empty.

The content lines of a code block or of an HTML block are the markdown
lines of the content that CommonMark 0.31.2 produces for the block, in
their order. CommonMark 0.31.2 produces each content line from one
CommonMark line that the block takes, which comes from one markdown line
of the file. A block of the Markdown document of a Markdown file starts
in a set of file lines when the first markdown line that the block takes
is in that set. A content line of a block of the Markdown document of a
Markdown file comes from a set of file lines when its source markdown
line is in that set. Every block of a Markdown document parsed by the
steps of this term starts in every set of file lines, and every content
line of such a block comes from every set of file lines.

The **raw content lines** of a paragraph are, for each CommonMark
0.31.2 line that the paragraph takes in order, the characters of that
line that CommonMark 0.31.2 assigns to the content of the paragraph,
without leading spaces (U+0020) and tabs (U+0009). A raw content line of
a paragraph of the Markdown document of a Markdown file comes from a set
of file lines when its source markdown line is in that set; every raw
content line of a paragraph of a Markdown document parsed by the steps
of this term comes from every set of file lines.

The **content text** of a line of a Markdown `tag-text` is the text of
the characters of that file line that CommonMark 0.31.2 assigns to the
content of the paragraph, in their order, without leading spaces
(U+0020) and tabs (U+0009). The **content text** of a line of a code
`tag-text` is the text of that line as a line of that `tag-text`.

A line of a Markdown `tag-text` has a task marker when it comes from the
first line of the first paragraph of a `markdown-list-item` and
`paragraph-line` produces that first line as the part of its `slice`
after the longest `slice` at the start whose text matches `task-marker`.
The task marker of the line is then the text of that longest `slice`
without trailing spaces (U+0020) and tabs (U+0009). The **normalized
task marker** of the line is its task marker with each `X` replaced by
`x`.

The indent of a non-negative integer *k* is the text that these steps
give.

1. If *k* is less than 1, give the empty text.
2. Let *j* be *k* minus 1.
3. Let *pad* be the indent of *j*.
4. Append a space (U+0020) to *pad*.
5. Append a space (U+0020) to *pad*.
6. Give *pad*.

The normalized lines of a block *b* at depth *k* with base level *base*
for a text declared item *d* in a set *e* of file lines under *m* is the
sequence that these steps give.

1. Let *lines* be the empty sequence.
2. Let *pad* be the indent of *k*.
3. If *b* is an ATX heading or a setext heading, *b* starts in *e*, and
   no text declared item of the tree has *b* as its own heading, then:
   1. Let *inlines* be the inline elements of *b*.
   2. If *b* is a heading that opens a section, then:
      1. Let *content* be the raw content of *b* (`link-text`).
      2. Remove the characters of the longest `slice` at the start of
         *content* whose text, with each line feed (U+000A) replaced by
         a space (U+0020), is a section number from *content*.
      3. Set *inlines* to the inline elements that CommonMark 0.31.2
         produces for a heading whose raw content is *content*, with the
         link reference definitions of the Markdown document that holds
         *b*.
   3. Let *line* be *pad*.
   4. Append `heading ` to *line*.
   5. If the level of *b* is greater than *base*, then:
      1. Append `+` to *line*.
      2. Append the decimal numeral of the level of *b* minus *base* to
         *line*.
   6. If the level of *b* equals *base*, append `0` to *line*.
   7. If the level of *b* is less than *base*, then:
      1. Append `-` to *line*.
      2. Append the decimal numeral of *base* minus the level of *b* to
         *line*.
   8. Append `: ` to *line*.
   9. Append the normalized inline text of *inlines* under *m* to
      *line*.
   10. Append *line* to *lines*.
4. If *b* is a paragraph of the Markdown document of a Markdown file
   that produces a `tag-text` holding a `tag-line`, then:
   1. For each *w* of the normalized tag lines of the `tag-text` that
      *b* produces at depth *k* for *d* in *e* under *m*, in order:
      1. Append *w* to *lines*.
5. If *b* is a paragraph that does not meet the condition of step 4, and
   *b* starts in *e*, then:
   1. Let *inlines* be the inline elements of *b*.
   2. If *b* is a paragraph of the Markdown document of a Markdown file
      and not every markdown line that *b* takes lies in *e*, then:
      1. Let *raw* be the empty text.
      2. Let *gap* be the empty text.
      3. For each *rc* of the raw content lines of *b*, in order:
         1. If *rc* comes from *e*, then:
            1. Append *gap* to *raw*.
            2. Append *rc* to *raw*.
            3. Set *gap* to a line feed (U+000A).
      4. Remove trailing spaces (U+0020) and tabs (U+0009) from *raw*.
      5. Set *inlines* to the inline elements that CommonMark 0.31.2
         produces when it parses *raw* as inlines (as it parses the raw
         content of a paragraph) with the link reference definitions of
         the Markdown document of the file of *d*.
   3. Let *norm* be the normalized inline text of *inlines* under *m*.
   4. If *norm* is not empty, then:
      1. Let *line* be *pad*.
      2. Append `paragraph: ` to *line*.
      3. Append *norm* to *line*.
      4. Append *line* to *lines*.
6. If *b* is a code block and *b* starts in *e*, then:
   1. Let *line* be *pad*.
   2. Append `code` to *line*.
   3. If *b* has an info string, then:
      1. Append a space (U+0020) to *line*.
      2. Append the info string of *b* to *line*.
   4. Append `:` to *line*.
   5. Append *line* to *lines*.
   6. For each *c* of the content lines of *b*, in order:
      1. If *c* comes from *e*, then:
         1. Let *row* be *pad*.
         2. Append `| ` to *row*.
         3. Append the text of *c* to *row*.
         4. Append *row* to *lines*.
7. If *b* is an HTML block and *b* starts in *e*, then:
   1. Let *line* be *pad*.
   2. Append `html:` to *line*.
   3. Append *line* to *lines*.
   4. For each *c* of the content lines of *b*, in order:
      1. If *c* comes from *e*, then:
         1. Let *row* be *pad*.
         2. Append `| ` to *row*.
         3. Append the text of *c* to *row*.
         4. Append *row* to *lines*.
8. If *b* is a thematic break and *b* starts in *e*, then:
   1. Let *line* be *pad*.
   2. Append `break` to *line*.
   3. Append *line* to *lines*.
9. If *b* is a block quote, a list, or a list item, then:
   1. Let *inner* be the empty sequence.
   2. For each *child* of the children of *b*, in order:
      1. For each *w* of the normalized lines of *child* at depth *k*
         plus 1 with base level *base* for *d* in *e* under *m*, in
         order:
         1. Append *w* to *inner*.
   3. If *inner* is not empty, then:
      1. Let *line* be *pad*.
      2. If *b* is a block quote, append `quote:` to *line*.
      3. If *b* is a bullet list, append `bullet list:` to *line*.
      4. If *b* is an ordered list, then:
         1. Append `ordered list from ` to *line*.
         2. Append the decimal numeral of the start number of *b* to
            *line*.
         3. Append `:` to *line*.
      5. If *b* is a list item, append `item:` to *line*.
      6. Append *line* to *lines*.
      7. For each *w* of *inner*, in order:
         1. Append *w* to *lines*.
10. Give *lines*.

A `tag-line` of a `tag-text` is **accepted** when the input of the tree
formed by that line together with its `continuation-line`s is an
`accepted-input`.

The **clusters** of a `tag-text` *t* in a set *e* of file lines are
sequences of lines. Let *L* be the sequence of the lines of *t* that lie
in *e* and that are neither `@ack` lines (`directive`), accepted
`@extern` lines (`directive`), nor `continuation-line`s, in their order.
*L* is cut immediately before each `tag-line` of *L* that immediately
follows a line of *L* that is not a `tag-line`, and immediately before
each `declaration` of a text declared item when the lines of *L* from
the last cut before it (or from the first line of *L* when no earlier
cut exists) hold another `declaration` of a text declared item. The
clusters of *t* in *e* are the contiguous sequences of the lines of *L*
from the first line of *L* or a cut to the next cut or the last line of
*L*, in their order.

The normalized tag lines of a tag text *t* at depth *k* for a text
declared item *d* in a set *e* of file lines under *m* is the sequence
that these steps give.

1. Let *lines* be the empty sequence.
2. For each *c* of the clusters of *t* in *e*, in order:
   1. Let *tags* be the empty sequence.
   2. Let *notes* be the empty sequence.
   3. Let *shared* be the empty text.
   4. If the file of *d* is a code file, set *shared* to the margin
      (`comment-line`) of the sequence of the texts of the lines of *c*,
      as lines of *t*, in their order.
   5. For each *l* of *c*, in order:
      1. If *l* is a `tag-line`, then:
         1. Append *l* to *tags*.
         2. If *l* is accepted and is a `declaration`, a `citation`, or
            a `status-tag`, and the `inline-description` of *l* is not
            empty, append the `inline-description` of *l* to *notes*.
      2. Otherwise:
         1. Let *y* be the content text of *l*.
         2. If *y* starts with *shared*, remove the first characters of
            *y*, as many as *shared* has, from *y*.
         3. Otherwise, set *y* to the empty text.
         4. Append *y* to *notes*.
   6. For each *w* of the normalized cluster of *tags* and *notes* for
      *t* at depth *k*, *d*, and *e* under *m*, in order:
      1. Append *w* to *lines*.
3. Give *lines*.

The normalized cluster of a sequence *p* of tag lines and a sequence *r*
of texts for a tag text *t* at depth *k*, a text declared item *d*, and
a set *e* of file lines under *m* is the sequence that these steps give.

1. Let *lines* be the empty sequence.
2. Let *pad* be the indent of *k*.
3. For each *l* of *p*, in order:
   1. If *l* has a task marker and *l* is not the declaration of *d*,
      then:
      1. Let *line* be *pad*.
      2. Append `task: ` to *line*.
      3. Append the normalized task marker of *l* to *line*.
      4. Append *line* to *lines*.
4. For each *l* of *p*, in order:
   1. If *l* is not accepted, then:
      1. Let *flat* be the empty text.
      2. For each *c* of the `tag-line-text` of *l*, in order:
         1. If *c* is a line feed (U+000A), append a space (U+0020) to
            *flat*.
         2. Otherwise, append *c* to *flat*.
      3. Set *flat* to the single-spaced text of *flat*.
      4. Remove leading and trailing spaces (U+0020) from *flat*.
      5. Let *line* be *pad*.
      6. Append `tag: ` to *line*.
      7. Append *flat* to *line*.
      8. Append *line* to *lines*.
5. For each *w* of the normalized prose of *r* after *p* for *t* at
   depth *k*, *d*, and *e* under *m*, in order:
   1. Append *w* to *lines*.
6. Give *lines*.

The normalized prose of a sequence *r* of texts after a sequence *p* of
tag lines for a tag text *t* at depth *k*, a text declared item *d*, and
a set *e* of file lines under *m* is the sequence that these steps give.

1. Let *lines* be the empty sequence.
2. Let *raw* be the empty text.
3. Let *gap* be the empty text.
4. For each *note* of *r*, in order:
   1. Append *gap* to *raw*.
   2. Append *note* to *raw*.
   3. Set *gap* to a line feed (U+000A).
5. If the file of *d* is a Markdown file, then:
   1. Remove leading and trailing spaces (U+0020) and tabs (U+0009) from
      *raw*.
   2. If *raw* is not empty, then:
      1. Let *line* be the indent of *k*.
      2. Append `paragraph: ` to *line*.
      3. Let *inner* be the inline elements that CommonMark 0.31.2
         produces when it parses *raw* as inlines (as it parses the raw
         content of a paragraph) with the link reference definitions of
         the Markdown document of the file of *d*.
      4. Append the normalized inline text of *inner* under *m* to
         *line*.
      5. Append *line* to *lines*.
6. If the file of *d* is a code file, then:
   1. Let *doc* be the empty text.
   2. If *p* is not empty, then:
      1. Append `x` to *doc*.
      2. Append a line feed (U+000A) to *doc*.
   3. Append *raw* to *doc*.
   4. For each *b* of the blocks of the Markdown document of *doc* that
      no other block contains, as CommonMark 0.31.2 parses that document
      with the link reference definitions of the Markdown document of
      *t* before its own so that a link label takes the first of these
      definitions whose link label it matches, in order:
      1. If *p* is not empty and *b* takes the first line of *doc*,
         then:
         1. Let *rest* be the raw content of *b* (`link-text`).
         2. Remove the first character of *rest* from *rest*.
         3. Remove leading and trailing line feeds (U+000A), spaces
            (U+0020), and tabs (U+0009) from *rest*.
         4. Let *inner* be the inline elements that CommonMark 0.31.2
            produces when it parses *rest* as inlines (as it parses the
            raw content of a paragraph) with the link reference
            definitions of the Markdown document of *t* before those of
            the Markdown document of *doc*.
         5. Let *line* be the indent of *k*.
         6. If *b* is a setext heading, then:
            1. Append `heading +` to *line*.
            2. Append the decimal numeral of the level of *b* minus the
               base level of *d* to *line*.
            3. Append `: ` to *line*.
            4. Append the normalized inline text of *inner* under *m* to
               *line*.
            5. Append *line* to *lines*.
         7. If *b* is a paragraph and *rest* is not empty, then:
            1. Append `paragraph: ` to *line*.
            2. Append the normalized inline text of *inner* under *m* to
               *line*.
            3. Append *line* to *lines*.
      2. Otherwise:
         1. For each *w* of the normalized lines of *b* at depth *k*
            with base level equal to the base level of *d* for *d* in
            *e* under *m*, in order:
            1. Append *w* to *lines*.
7. Give *lines*.

The normalized text of a text declared item *d* under target mapping *m*
is the text that these steps give.

1. Let *e* be the hashed lines (`hashed-line`) of *d*.
2. Let *lines* be the empty sequence.
3. If the file of *d* is a Markdown file, then:
   1. Let *blocks* be the sequence of the top-level blocks of the
      Markdown document of the file of *d* in their order, or, when the
      declaration of *d* stands in the `tag-text` of the first paragraph
      of a `markdown-list-item`, the children of that list item in their
      order.
   2. For each *b* of *blocks*, in order:
      1. For each *w* of the normalized lines of *b* at depth 0 with
         base level equal to the base level of *d* for *d* in *e* under
         *m*, in order:
         1. Append *w* to *lines*.
4. If the file of *d* is a code file, then:
   1. Let *texts* be the sequence of the `tag-text`s of the file of *d*
      in the order of the boundaries where their first lines start.
   2. For each *t* of *texts*, in order:
      1. For each *w* of the normalized tag lines of *t* at depth 0 for
         *d* in *e* under *m*, in order:
         1. Append *w* to *lines*.
5. Let *out* be the empty text.
6. For each *w* of *lines*, in order:
   1. Append *w* to *out*.
   2. Append a line feed (U+000A) to *out*.
7. Give *out*.

The normalized text of an `example-block` *x* of a text declared item
*d* under target mapping *m* is the text that these steps give.

1. Let *raw-lines* be the empty sequence.
2. If the file of *d* is a Markdown file, then:
   1. Let *indent* be the list indentation of *d*.
   2. Let *first-md* be true.
   3. For each *fl* of the file lines of *x*, in order:
      1. Let *s* be the text of *fl*.
      2. Let *n* be 0.
      3. While *n* is less than *indent* and *s* is not empty and the
         character at 1-based character index 1 of *s* is a space
         (U+0020) or a tab (U+0009):
         1. Remove the character at 1-based character index 1 of *s*
            from *s*.
         2. Set *n* to *n* plus 1.
      4. If *first-md* is true, then:
         1. Set *first-md* to false.
         2. While *s* is not empty and the character at 1-based
            character index 1 of *s* is a space (U+0020) or a tab
            (U+0009):
            1. Remove the character at 1-based character index 1 of *s*
               from *s*.
         3. If *s* starts with `@example`, remove the first 8 characters
            of *s* from *s*.
         4. While *s* is not empty and the character at 1-based
            character index 1 of *s* is a space (U+0020) or a tab
            (U+0009):
            1. Remove the character at 1-based character index 1 of *s*
               from *s*.
         5. If *s* is not empty, append *s* to *raw-lines*.
      5. Otherwise, append *s* to *raw-lines*.
3. If the file of *d* is a code file, then:
   1. Let *kept* be the empty sequence.
   2. Let *first-code* be true.
   3. For each *l* of the lines of *x* as lines of the `tag-text` of
      *d*, in order:
      1. Let *cs* be the text of *l*.
      2. If *first-code* is true, then:
         1. Set *first-code* to false.
         2. While *cs* is not empty and the character at 1-based
            character index 1 of *cs* is a space (U+0020) or a tab
            (U+0009):
            1. Remove the character at 1-based character index 1 of *cs*
               from *cs*.
         3. If *cs* starts with `@example`, remove the first 8
            characters of *cs* from *cs*.
         4. While *cs* is not empty and the character at 1-based
            character index 1 of *cs* is a space (U+0020) or a tab
            (U+0009):
            1. Remove the character at 1-based character index 1 of *cs*
               from *cs*.
         5. If *cs* is not empty, append *cs* to *kept*.
      3. Otherwise, append *cs* to *kept*.
   4. Let *shared* be the margin (`comment-line`) of *kept*.
   5. For each *ks* of *kept*, in order:
      1. Let *line* be *ks*.
      2. If *line* starts with *shared*, remove the first characters of
         *line*, as many as *shared* has, from *line*.
      3. Otherwise, set *line* to the empty text.
      4. Append *line* to *raw-lines*.
4. Let *doc* be the empty text.
5. Let *gap* be the empty text.
6. For each *rl* of *raw-lines*, in order:
   1. Append *gap* to *doc*.
   2. Append *rl* to *doc*.
   3. Set *gap* to a line feed (U+000A).
7. Let *defs* be the Markdown document of the file of *d* when the file
   of *d* is a Markdown file, or the Markdown document of the `tag-text`
   of *d* when the file of *d* is a code file.
8. Let *lines* be the empty sequence.
9. For each *b* of the blocks of the Markdown document of *doc* that no
   other block contains, as CommonMark 0.31.2 parses that document with
   the link reference definitions of *defs* before its own so that a
   link label takes the first of these definitions whose link label it
   matches, in order:
   1. For each *w* of the normalized lines of *b* at depth 0 with base
      level 0 for *d* in the empty set under *m*, in order:
      1. Append *w* to *lines*.
10. Let *out* be the empty text.
11. For each *w* of *lines*, in order:
    1. Append *w* to *out*.
    2. Append a line feed (U+000A) to *out*.
12. Give *out*.

@example Under a level-1 design heading (`# Q` and `@design qa=v1`), the
two Markdown blocks

```markdown
Use *x*, __y__, and [l]( http://a.org ).
One  
two.

~~~json
{"k": 1}
~~~
```

produce the normalized text (using prefixes and
[normalized inline text](sinter:#normalized-inline-text=v1) braced
forms):

```text
paragraph: Use {em:x}, {strong:y}, and {link{l}{http://a.org}}. One{br}two.
code json:
| {"k": 1}
```

#### Canonical targets

@term canonical-target=v1
@cites {
    conformance#{encoding=v1, input=v1, report-missing-parts=v1},
    data-forms#{vector-line=v1, form-pin=v1},
    identifiers#{
        citation=v1, citation-entry=v1, inline-citation=v1,
        content-id=v1, external-id=v1, external-target=v1,
        vector-selection=v1, label=v1, external-namespaces=v1,
        canonical-entry=v1,
    },
    ontology#{
        tree=v1, encoding=v1, object=v1, object-kind=v1,
        content-id=v1, computed-identity=v1, object-withdrawal=v1,
        declared-item=v1, item-name=v1, edge=v1, pinned-edge=v1,
        vector-set=v1, conformance-vector-group=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    ledger#accepted-record=v1,
    #{
        file-readers=v1, vector-files=v1, read-file=v1,
        accepted-input=v1, example-block=v1, item-file=v1,
        home-design=v1, text-containment=v1, vector-file=v1,
        item-part=v1, kept-object-set=v1, normalized-inline-text=v1,
    },
}

In the sense of `conformance#encoding` and `ontology#encoding`, the read
files of a `tree` (`read-file`), together with its vector files under
`vector-files`, constitute one input in the text encoding. That input is
valid when the bindings of `file-readers` and `external-namespaces`
(and, for vector files and `vector-group-def` objects, `vector-files`)
are valid. Canonical targets are defined over that valid text encoding
together with a valid `object-store#tree-object-store`, a valid
`kept-object-set`, and an object mapping *c* that assigns each declared
item of the tree its canonical `object` or no object (withheld because
of a missing part).

**Known computed identity objects.** An input of the run supplies a
`computed-identity` object (`name`, `pin`, `ext`, `vector-set`, or
`vector-group`, as `ontology#computed-identity` defines its canonical
line object) when any of these conditions holds:

- a `valid-object-file` of `.sinter/` of the tree holds that computed
  identity object;
- `kept-object-set` holds that computed identity object;
- a declared item of the tree (text or `.sinter/`), a replaced or
  withdrawn declared-item object in a `valid-object-file` of `.sinter/`,
  or a kept declared-item object in `kept-object-set` holds its own
  `name` key, supplying `{"kind":"name","name":n,"v":1}`;
- an accepted `citation-entry` (`accepted-input`), a valid
  `inline-citation` (`normalized-inline-text`, including one inside an
  `example-block`), or a `vector-line` in a `vector-file` of the tree
  writes that key (an expanded name for `name`, an exact pin `(n, l)` or
  a vector line's `form-pin` for `pin`, an `external-ref` for `ext`, or
  a `vector-selection` or a `vector-set` of the tree with each of its
  groups for `vector-set` or `vector-group`).

**Expanded name.** For an accepted `citation-entry` or valid
`inline-citation` with `home-design` *h* (or none), its **expanded
name** is its entry name (`identifiers#canonical-entry`), prefixed by
the name of *h* when that entry name starts with `#` and *h* is present.

**Pin-dependency graph.** In the directed graph whose nodes are the
declared items of the tree (`item-file`, `ontology#edge`), add an arrow:

- from each text `spec` to each text declared item that belongs to it
  under `text-containment`, and from each stored `spec` to each stored
  declared item of the tree whose content ID is the `to` of one of its
  `items` edges;
- from each text declared item *u* to each declared item *v* of the tree
  whose name is *n* and whose label is *l*, whenever *u* holds (standing
  in *u* under `item-part`) an exact pin with expanded name *n* and
  label *l*, or holds a text citation or valid inline citation written
  as a `pin:` content ID whose `pin` object `(n, l)` an input of the run
  supplies;
- from each stored declared item *u* to each stored declared item *v* of
  the tree whose content ID is the `to` of a citation edge of *u*, and
  from each stored declared item *u* to each declared item *v* of the
  tree whose name is *n* and whose label is *l* when a citation edge of
  *u* has `to` equal to a `pin:` content ID whose `pin` object `(n, l)`
  an input of the run supplies.

A pinned citation edge (`pinned-edge`) from a declared item *u*
targeting `(n, l)` **lies on a cycle of the tree's own objects** when at
least one declared item *v* of the tree with name *n* and label *l* can
reach *u* in that graph (including `u = v`, a cycle of length 1). Every
`items` edge of a `spec` keeps its exact target. An `example` object is
uncitable and is not a declared item, so an inline citation standing in
an `example-block` has no declared-item source and never lies on a cycle
of the tree's own objects.

**Canonical target of an accepted citation entry or valid inline
citation.** For an accepted `citation-entry` or valid `inline-citation`
with `home-design` *h* (or none) standing in source *s* (`item-part`,
where *u* is that declared item when *s* is a declared item, and none
otherwise — including when *s* is an `example-block`, a test, a site, or
nothing):

1. **Exact pin `(n, l)`** (where *n* is the expanded name and *l* is the
   `label`; also for an accepted citation entry or valid inline citation
   written by a `pin:` content ID whose `pin` object `(n, l)` an input
   of the run supplies):
   - When *u* is a declared item and `(n, l)` lies on a cycle of the
     tree's own objects, the canonical target is the content ID of
     `{"kind":"pin","label":l,"name":n,"v":1}`.
   - Otherwise, check these three sets in order:
     1. the distinct canonical `object`s that *c* assigns to the
        declared items of the tree whose name is *n* and whose label is
        *l* (when *c* assigns no object to at least one such declared
        item, this pin is also a missing part under `conformance#input`);
     2. when the first set is empty, the distinct canonical objects of
        the replaced, unwithdrawn declared-item objects in
        `valid-object-file`s of `.sinter/` of the tree
        (`ontology#object-withdrawal`, with the acceptance rule of
        `void` in `ledger#accepted-record`) whose name is *n* and whose
        label is *l*;
     3. when the first two sets are empty, the distinct canonical
        objects of the unwithdrawn declared-item objects in
        `kept-object-set` (`ontology#object-withdrawal`,
        `ledger#accepted-record`) whose name is *n* and whose label is
        *l*.
     In the first non-empty set among those three: when it holds one
     canonical object, the canonical target is that object's content ID;
     when it holds two or more distinct canonical objects, the pin is
     **ambiguous** and its canonical target is the content ID of
     `{"kind":"pin","label":l,"name":n,"v":1}`.
   - When all three sets are empty: when no declared item of the tree
     has name *n* (including `#<part-name>` with no `home-design`), the
     canonical target is the content ID of
     `{"kind":"pin","label":l,"name":n,"v":1}`; otherwise (a declared
     item of the tree has name *n*, for example at another label while a
     matching kept object is withdrawn by a counting void), the pin
     resolves to no object and is a missing part (`conformance#input`,
     `conformance#report-missing-parts`).
2. **Unknown `pin:` content ID in text** (no input of the run supplies a
   `pin` object with that content ID): the canonical target is that
   `pin:` content ID directly; it is not a missing part and resolves to
   no object.
3. **Unpinned citation (`=*`) or `name:` content ID:** for `=*` with
   expanded name *n*, the canonical target is the content ID of
   `{"kind":"name","name":n,"v":1}`; for a written `name:` content ID,
   that content ID directly.
4. **External target or `ext:` content ID:** for an `external-target`
   with `external-ref` *r* (dropping any written kind word), the
   canonical target is the content ID of
   `{"external-ref":r,"kind":"ext","v":1}`; for a written `ext:`
   content ID, that content ID directly.
5. **Vector selection or `vector-set:` / `vector-group:` content ID:**
   for a `vector-selection` `[*]` on expanded name *owner*, the content
   ID of `{"kind":"vector-set","owner":owner,"v":1}`; for `[g]`, the
   content ID of
   `{"group":g,"kind":"vector-group","owner":owner,"v":1}`;
   for a written `vector-set:` or `vector-group:` content ID, that
   content ID directly.
6. **Non-identity content ID** (any of the other twenty-one object kinds
   in `ontology#object-kind`, including `example:`): the canonical
   target is that content ID directly (not a missing part; under
   `ontology#object-kind` and `ontology#edge`, an `example:` content ID
   is uncitable and resolves to no object).

**Canonical target of a vector-line form pin.** Under a valid binding of
`vector-files`, for a `vector-line` of a `vector-set` of a `design` *D*
or of a `spec` *S* belonging to *D* (`vector-file`), with `form-pin`
`#<part>=<label>`, its canonical target is the canonical target that
rule 1 of this term defines for the exact pin
`(<D.name> + "#" + <part>, <label>)` with no declared-item source.

**Canonical target of a stored declared item's citation edge.** For a
citation edge of a stored declared item in `.sinter/`, its canonical
target is the `to` content ID that the stored object holds. When `to` is
a `pin:` content ID and an input of the run supplies that `pin` object
`(n, l)`, the edge resolves in the tree under rule 1 (for pin cycles,
ambiguity, and missing parts), while keeping its stored `pin:` content
ID. When a stored object's edge targets a computed identity content ID
that no input of the run supplies, that computed identity object is a
missing part (`object-store#tree-object-store`), and only results that
need its key are withheld.

#### Canonical objects of a tree

@term canonical-object=v1
@cites {
    conformance#report-missing-parts=v1,
    data-forms#{
        line-object=v1, canonical-form=v1, canonical-byte-sequence=v1,
        vector-line=v1, form-pin=v1, group-name=v1,
    },
    identifiers#{
        citation=v1, citation-entry=v1, inline-citation=v1,
        status-tag=v1, external-namespaces=v1,
    },
    ontology#{
        tree=v1, object=v1, object-kind=v1, content-hash=v1,
        content-id=v1, computed-identity=v1, declared-item=v1,
        item-name=v1, revised-content=v1, edge=v1, vector-set=v1,
        conformance-vector-group=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    text#code-point-order=v1,
    #{
        file-readers=v1, vector-files=v1, accepted-input=v1,
        example-block=v1, item-file=v1, home-design=v1,
        text-containment=v1, hashed-line=v1, vector-file=v1,
        item-part=v1, kept-object-set=v1, normalized-inline-text=v1,
        normalized-line=v1, canonical-target=v1,
    },
}

Over a `tree` with valid bindings of `file-readers` and
`external-namespaces`, a valid `object-store#tree-object-store`, and a
valid `kept-object-set`, the canonical objects of the tree, each with a
`content-hash` and a `content-id`, are these canonical JSON
`line-object`s (without `id`). Every `canonical-target` in this term
uses the object mapping *c* that assigns each declared item of the tree
the canonical `object` defined by item 1 of this term, or no object when
item 1 withholds it.

1. **Declared items (`declared-item`, `revised-content`).**
   - For a stored declared item (`item-file`), its canonical object is
     the canonical object of its `valid-object-file` in `.sinter/`.
   - For a text declared item *d* (`item-file`), let *m* be the target
     mapping (`normalized-inline-text`) that maps each valid inline
     citation in the `hashed-line`s of *d* to its `canonical-target`
     content ID (using the `home-design` of that inline citation when it
     is a link input of the file, or the `home-design` of *d*'s
     declaration otherwise, with declared-item source *d*). When no
     accepted `citation-entry` standing in *d* (`item-part`), no valid
     inline citation in the `hashed-line`s of *d*, and (when *d* is a
     `spec`) no text declared item belonging to *d* under
     `text-containment` has a missing-part canonical target or withheld
     canonical object, the canonical object of *d* is the `line-object`
     holding:
     - `kind`: the short object kind word of *d* (`design`, `spec`,
       `schema`, `req`, `atom`, `term`, or `decision`);
     - `v`: the integer `1`;
     - `name`: the `item-name` of *d*;
     - `label`: the label of *d* when its declaration carries a label
       (omitted for a `term` with no label);
     - `text`: the normalized text of *d* (`normalized-line`) under *m*;
     - `status`: the duplicate-free set of tag words without `@` of the
       accepted `status-tag`s standing in *d* (`item-part`), sorted in
       `code-point-order` of their `canonical-form`s, omitted when
       empty;
     - `edges`: the duplicate-free set of `{"kind","to"}` flat objects,
       sorted in `code-point-order` of their `canonical-form`s, holding
       `{"kind":"about","to":a}` where *a* is the content ID of
       `{"kind":"name","name":d.name,"v":1}`, plus
       `{"kind":"items","to":h}` for the content ID *h* of each text
       declared item belonging to *d* under `text-containment` when *d*
       is a `spec`, plus `{"kind":k,"to":t}` for each accepted
       `citation-entry` and each valid `inline-citation` standing in *d*
       (`item-part`), with no `revises` edge.
     When any such pin or held item is a missing part or is withheld,
     the canonical object (and content hash and content ID) of *d* is
     withheld (`conformance#report-missing-parts`).
2. **Example objects (`example`).** For each text declared item *d* and
   each `example-block` *x* of *d* (with 1-based index *i* `>= 1` among
   the `example-block`s of *d*), let *m* be the target mapping
   (`normalized-inline-text`) that maps each valid inline citation in
   *x* to its `canonical-target` content ID (with no declared-item
   source, using the `home-design` of that inline citation when it is a
   link input of the file, or the `home-design` of *d*'s declaration
   otherwise). When no valid `inline-citation` standing in *x*
   (`item-part`) has a missing-part canonical target, the canonical
   `example` object of *x* is the `line-object` holding:
   - `kind`: `"example"`;
   - `v`: the integer `1`;
   - `index`: the integer *i*;
   - `text`: the normalized text of *x* (`normalized-line`) under *m*
     (the empty string `""` when *x* produces zero normalized lines);
   - `edges`: the duplicate-free set of `{"kind","to"}` flat objects,
     sorted in `code-point-order` of their `canonical-form`s, holding
     `{"kind":"about","to":a}` where *a* is the content ID of
     `{"kind":"name","name":d.name,"v":1}`, plus
     `{"kind":"cites","to":t}` for the `canonical-target` *t* of each
     valid `inline-citation` standing in *x* (`item-part`).
   When any such inline citation has a missing-part canonical target,
   the canonical `example` object (and content hash and content ID) of
   *x* is withheld (`conformance#report-missing-parts`). An `example`
   object is anonymous and uncitable (`ontology#object-kind`).
3. **Group description objects (`vector-group-def`).** Under a valid
   binding of `vector-files`, for each `design` or `spec` *x* of the
   tree that has a `vector-set` (`vector-file`), and for each group *g*
   (`group-name`) of that vector set (`conformance-vector-group`), when
   no `vector-line` of *g* has a missing-part `form-pin`
   (`canonical-target`), the canonical `vector-group-def` object of *g*
   is the `line-object` holding `kind` (`"vector-group-def"`), `v`
   (`1`), `owner` (the `item-name` of *x*), `group` (*g*), and `edges`
   (the duplicate-free set of `{"kind","to"}` flat objects, sorted in
   `code-point-order` of their `canonical-form`s, holding
   `{"kind":"about","to":vg}` where *vg* is the content ID of
   `{"group":g,"kind":"vector-group","owner":x.name,"v":1}`, plus
   `{"kind":"cites","to":t}` for the `canonical-target` *t* of each
   vector line of *g*). When any vector line of *g* has a missing-part
   form pin, that `vector-group-def` object (and its content hash and
   content ID) is withheld (`conformance#report-missing-parts`).
4. **Computed identity objects (`computed-identity`).** Each `name`,
   `pin`, `ext`, `vector-set`, or `vector-group` object supplied by the
   inputs of the run (`canonical-target`) has the canonical
   `line-object` defined by `ontology#computed-identity`.

The `content-hash` and `content-id` of every canonical object follow
`ontology#content-hash` and `ontology#content-id` over its
`canonical-byte-sequence`.

@example For this Markdown design with a requirement and a trailing
[example block](sinter:#example-block=v1):

```markdown
# D
@design d=v1

## R1
@req r1=v1
Norm.

@example Uses [r1](sinter:#r1=v1) and [missing](sinter:#nope=v1).
```

The parent requirement `d#r1` excludes the `@example` block from its
[hashed lines](sinter:#hashed-line=v1) and `edges`, producing
`req:9859c32159a091e78fb70cc00a397214`:

```json
{"edges":[{"kind":"about","to":"name:1e78c58765669d51857b196ddab3a206"}],"kind":"req","label":"v1","name":"d#r1","text":"paragraph: Norm.\n","v":1}
```

Its 1-based `example` object
(`example:639482096cbffd539ba2e35bf87593e2`) holds its own
[normalized lines](sinter:#normalized-line=v1) and resolves both inline
citations through [canonical-target](sinter:#canonical-target=v1) (with
no pin cycle on `#r1=v1`, as an `example` object is uncitable):

```json
{"edges":[{"kind":"about","to":"name:1e78c58765669d51857b196ddab3a206"},{"kind":"cites","to":"pin:f4d2ccd399516b5e635b5d4fbef36c7b"},{"kind":"cites","to":"req:9859c32159a091e78fb70cc00a397214"}],"index":1,"kind":"example","text":"paragraph: Uses {link{r1}{sinter:req:9859c32159a091e78fb70cc00a397214}} and {link{missing}{sinter:pin:f4d2ccd399516b5e635b5d4fbef36c7b}}.\n","v":1}
```

#### Containment in a tree

@term tree-containment=v1
@cites {
    ontology#{
        containment=v1, item-name=v1, declared-item=v1,
        item-revision=v1, content-id=v1, edge=v1,
    },
    #{item-file=v1, text-containment=v1, canonical-object=v1},
}

In a tree, a declared item belongs to a declared item
(`ontology#containment`) only in these ways:

- Every design containment relation and every text specification
  containment relation of `text-containment` holds.
- Take a declared item *d* (text or stored, `item-file`) of one of the
  kinds `req`, `schema`, `atom`, and `term` that belongs to no text
  specification and whose `canonical-object` is the current
  declared-item object of its name in the tree
  (`ontology#item-revision`). When there is exactly one stored declared
  item *S* of the kind `spec` in the tree such that *d* and *S* belong
  to the same item of the kind `design` (or both belong to no item of
  the kind `design`) and *S* holds an `items` `edge` whose `to` is the
  `content-id` of *d*, then *d* belongs to *S*.

### Returning canonical objects

@req give-canonical-objects=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1, give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        tree=v1, declared-item=v1, object=v1, content-hash=v1,
        content-id=v1,
    },
    object-store#tree-object-store=v1,
    #{
        file-readers=v1, vector-files=v1, example-block=v1,
        kept-object-set=v1, canonical-object=v1,
    },
}

Given a `tree`, valid bindings of `file-readers` and
`external-namespaces`, a valid `tree-object-store`, and a valid
`kept-object-set` (`read-defined-encodings`,
`give-results-over-canonical-objects`):

- When a conforming program returns the canonical object, content hash,
  and content ID of a declared item of the tree whose `canonical-object`
  is not withheld by a missing part, the conforming program must return
  that canonical object, content hash, and content ID, and nothing else.
  When the canonical object of a text declared item is withheld by a
  missing part, the conforming program must return no canonical object,
  content hash, or content ID for that item (`report-missing-parts`).
- When a conforming program returns the canonical `example` objects of
  the tree, the conforming program must return once each `example-block`
  of each text declared item of the tree, identified by its parent
  declared item and 1-based index, and, when the canonical object of
  that `example-block` is not withheld by a missing part, its canonical
  object, content hash, and content ID; when the canonical object of
  that `example-block` is withheld by a missing part, the conforming
  program must return no canonical object, content hash, or content ID
  for that `example-block` (`report-missing-parts`).
- Under a valid binding of `vector-files`, when a conforming program
  returns the group description objects (`vector-group-def`) of the
  tree, the conforming program must return once each `vector-group-def`
  `canonical-object` of the tree whose vector lines have no missing-part
  form pin, with its canonical object, content hash, and content ID, and
  must return no other `vector-group-def` object. Under an invalid
  binding of `vector-files`, the conforming program must return no
  `vector-group-def` object (`reject-invalid-inputs`), while
  declared-item objects and `example` objects remain unaffected.

### Returning containment

@req give-containment=v1
@cites {
    conformance#conforming-program=v1,
    identifiers#external-namespaces=v1,
    ontology#{tree=v1, declared-item=v1, containment=v1},
    object-store#tree-object-store=v1,
    #{file-readers=v1, kept-object-set=v1, tree-containment=v1},
}

Given a `tree`, valid bindings of `file-readers` and
`external-namespaces`, a valid `tree-object-store`, and a valid
`kept-object-set`, when a conforming program returns the item of the
kind `design`, or the item of the kind `spec`, to which a declared item
of the tree belongs (`tree-containment`), the conforming program must
return the item of that kind to which the declared item belongs, or
return that the declared item belongs to no item of that kind when it
belongs to none.

## Edges, extern directives, and tree findings

@spec edges-and-findings=v1

Citation edges link declared items, examples, tests, sites, and groups
of conformance vectors across files and `.sinter/`, while `@extern`
directives connect text designs to held items in other files. Tree
findings flag invalid targets, name duplicates, broken or disallowed
edges, misplaced declarations, extern mismatches, pin cycles, and
ambiguous pins.

### Definitions

#### Tree edges

@term tree-edge=v1
@cites {
    rfc/8259,
    identifiers#{
        citation=v1, citation-entry=v1, inline-citation=v1,
        full-name=v1, content-id=v1, external-id=v1,
        external-namespaces=v1, id-match=v1,
    },
    data-forms#{
        canonical-form=v1, vector-line=v1, vector-object=v1,
        form-pin=v1,
    },
    ontology#{
        edge=v1, edge-source=v1, tree=v1, declared-item=v1,
        containment=v1, item-name=v1, vector-set=v1,
        conformance-vector-group=v1, computed-identity=v1,
        object-withdrawal=v1, object=v1, object-kind=v1,
        external-item=v1,
    },
    object-store#valid-object-file=v1,
    ledger#accepted-record=v1,
    text#{text=v1, line=v1, slice=v1, position=v1},
    #{
        vector-files=v1, accepted-input=v1, example-block=v1,
        vector-file=v1, kept-object-set=v1, canonical-target=v1,
        tree-containment=v1, item-part=v1,
    },
}

The **tree edges** of a `tree` are the citation edges (`cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`) from these four
sources:

- each `citation-entry` of each accepted `citation` in a read file that
  does not lie on any file line of an `example-block`, with edge kind
  equal to the citation word without `@` and source equal to the item,
  `example` object, test, or site in which the citation stands
  (`item-part`), or none;
- each accepted `inline-citation` in a read file, with edge kind
  `cites` and source equal to the item, `example` object, test, or site
  in which the inline citation stands (`item-part`), or none, including
  any accepted inline citation inside an `example-block`, whose source
  is that `example` object rather than its parent declared item
  (`edge-source`);
- each `vector-line` of the `vector-set` of each `design` or `spec` of
  the tree that has a `vector-file` under a valid binding of
  `vector-files`, with edge kind `cites` and source equal to the
  `conformance-vector-group` named by that vector line's `group`;
- each edge of one of the five citation kinds in the member `edges` of
  each stored declared item in `.sinter/` of the tree, with that stored
  declared item as its source.

Edges of structural, scope, and record kinds (`items`, `about`,
`revises`, and all edges of records and `scope` objects) are not tree
edges.

The **file** of a text citation or inline citation edge is the read
file of its `accepted-input`; the file of a vector-line edge is that
`vector-file`; the file of a stored edge is the `valid-object-file` of
its stored declared item.

For a vector-line edge of the `vector-set` of an item, the **form
slice** of that edge is the `slice` of the text of that item's
`vector-file`, on the `line` of that vector line, starting at the
boundary immediately after the opening `"` of the RFC 8259 JSON string
value of the member `form` of that vector line's `vector-object` and
ending at the boundary immediately before the closing `"` of that JSON
string (covering any JSON escape sequences in that string). The **form
position** of that edge is the `position` of the start boundary of its
form slice in the text of that vector file (column 10 on that line
under `data-forms#canonical-form`).

For a tree edge that is neither an ambiguous pin nor a missing part
under `canonical-target` (nor a stored edge whose target is a computed
identity object lacking its key in the inputs of the run), these rules
determine its **cited item** in the tree (or none when they produce no
item or object):

- **Vector-line edge:** For a vector line of the `vector-set` of a
  `spec` `S` belonging to a `design` `D`, or of a `design` `D`, let `n`
  be the `full-name` formed by the name of `D`, `#`, and the schema
  part name of the `form-pin` of that vector line. When exactly one
  declared item `x` of the tree has the name `n` and either the vector
  set belongs to `S` and `S` holds `x` (`tree-containment`), or the
  vector set belongs to `D` and `D` holds `x` (`tree-containment`,
  directly or through a `spec` that belongs to `D`), the cited item is
  `x`; otherwise none.
- **Target `pin:`:** For a text edge citing an unknown `pin:` content
  ID (no input of the run supplies that `pin` object), none. When an
  input of the run supplies the `pin` object `(n, l)`, the one declared
  item of the tree whose name is `n`, or none when zero or two or more
  exist.
- **Target `name:`:** When an input of the run supplies the `name`
  object with member `name` `n`, the one declared item of the tree
  whose name is `n`, or none when zero or two or more exist (the
  presence of a `name` object never implies that a declared item of
  that name exists in the tree). For a text citation of an unknown
  `name:` content ID, none.
- **Target `ext:`:** When an input of the run supplies the `ext` object
  with member `external-ref` `r`, and the namespace of `r` is in the
  binding of `external-namespaces` with its `id-text` (`external-id`)
  having outcome `"matches"` under `id-match` against that namespace's
  ID pattern, the `external-item` named by `r`; otherwise none.
- **Target `vector-set:` or `vector-group:`:** When an input of the run
  supplies that computed identity object with `owner` (and `group` for
  `vector-group`), and exactly one declared item `x` of the tree has
  name `owner` and `x` is a `design` or `spec` with a `vector-set`
  (and, for `vector-group`, that group exists in that vector set), that
  `vector-set` or `conformance-vector-group`; otherwise none.
- **Target non-identity content ID:** When the target content ID has
  object kind word `example`, none (not a missing part, per
  `object-kind` and `ontology#edge`). Otherwise, look first in the tree
  (current text declared items, valid unwithdrawn `.sinter/` objects of
  any kind, and `vector-group-def` objects of the tree), and otherwise
  in unwithdrawn objects of `kept-object-set`. When the target is not a
  text declared item of the tree and a counting void in `.sinter/`
  (`object-withdrawal`, `accepted-record`) withdraws it, resolving that
  edge is a missing part and its cited item is withheld. Otherwise,
  when the target resolves to a declared-item object `O`, the cited
  item is the one declared item of the tree whose name is the member
  `name` of `O` (or none when zero or two or more exist); when it
  resolves to any other object `O` (`task`, `plan`, `scope`,
  `vector-group-def`, or a record), the cited item is `O`; when it
  resolves to no object, none.

When a tree edge is an ambiguous pin, lacks its canonical target or a
needed computed identity key as a missing part, is a stored `pin:` edge
whose resolution under `canonical-target` is a missing part, or targets
a withdrawn non-text object, its cited item is withheld.

#### Extern directives

@term extern-directive=v1
@cites {
    identifiers#{
        extern-line=v1, directive=v1, kind-word=v1, part-name=v1,
        match=v1,
    },
    ontology#{declared-item=v1, containment=v1, item-name=v1},
    #{
        accepted-input=v1, example-block=v1, tag-text=v1, item-file=v1,
        item-part=v1, tree-containment=v1,
    },
}

An `@extern` line (`directive`, `extern-line`) that is a line of a
`tag-text`, that is an `accepted-input` of a tree, that does not lie on
any file line of an `example-block`, and that stands in a text declared
item of the kind `design` `D` (`item-part`) states one **extern
directive** of `D`. Its **kind word** is the text that `kind-word`
matches in the match of that line by `extern-line`. Its **part name**
is the text that `part-name` matches in that match. Its **name** is the
name of `D`, `#`, and its part name.

An `@extern` line that stands in no text declared item of the kind
`design` states no extern directive. A stored `design` in `.sinter/`
carries no extern directive.

An extern directive of a text `design` `D` is **valid** when, and only
when, one of these conditions holds for a text declared item `x` (never
a stored declared item in `.sinter/`):

- its kind word is `spec`, and `D` holds (`tree-containment`) a text
  declared item `x` of the kind `spec` whose name equals the extern
  directive's name and whose file (`item-file`) is not the file of `D`;
- its kind word is `req`, `schema`, `atom`, or `term`, and `D` holds
  directly (`tree-containment`) a text declared item `x` of that kind
  whose name equals the extern directive's name and whose file
  (`item-file`) is not the file of `D`.

#### Edge finding subjects

@term edge-finding-subject=v1
@cites {
    conformance#own-store=v1,
    findings#{finding-subject=v1, location=v1},
    files#path=v1,
    identifiers#{citation-entry=v1, inline-citation=v1},
    ontology#{content-id=v1, edge=v1, declared-item=v1, object-kind=v1},
    object-store#valid-object-file=v1,
    text#{character=v1, text=v1},
    #{
        origin=v1, slice-location=v1, canonical-target=v1,
        canonical-object=v1,
    },
}

For a canonical citation edge of one of the five citation kinds whose
source is a declared item or an `example` object with content ID `s`
and whose `canonical-target` is content ID `t`, the **edge finding
subject** of that canonical edge is `s`, then a space (U+0020), then
the edge kind `k`, then a space (U+0020), then `t`:
`<source-content-id> <edge-kind> <target-content-id>` (such as
`example:<32 hex> cites <target-content-id>` when the source is an
`example` object).

The **object edge location** of that canonical edge in a tree is:

- when the source is a text declared item or an `example` object of a
  text declared item, and exactly one `citation-entry` or
  `inline-citation` across the tree produces that canonical edge (with
  no second occurrence in that item or example, no other declared item
  or example with an equal `canonical-object`, and no stored item
  producing that same canonical edge): the `slice-location` of the
  `origin` slice of that citation entry or inline citation in the text
  of that read file;
- when two or more occurrences in the tree (in text, in `.sinter/`, or
  across both) produce that same canonical edge: no location;
- when the source is a stored declared item in a `valid-object-file` of
  `.sinter/` and no other declared item in the tree produces that same
  canonical edge: the valid `path` of that valid object file alone,
  with no span (`location`);
- when the source comes from a program's own store (`own-store`): no
  location.

#### Invalid-target findings

@atom invalid-target-finding=v1
@cites {
    identifiers#{
        tag-line=v1, link=v1, citation=v1, citation-entry=v1,
        inline-citation=v1, inline-destination=v1, part-name=v1,
        tag-line-text=v1, line-result=v1, link-result=v1, match=v1,
    },
    #{
        accepted-input=v1, example-block=v1, origin=v1,
        origin-position=v1, home-design=v1, position-subject=v1,
        slice-location=v1, tree-finding=v1,
    },
}

A tree has one `tree-finding` of the class `invalid-target` for each
`X` among these four cases:

- each tag-line input of the tree (a tag line with its continuation
  lines) that does not lie on any file line of an `example-block` and
  whose `line-result` is `"invalid"` (`accepted-input`);
- each `link` input of the tree whose `link-result` is `"invalid"`
  (`accepted-input`);
- each `citation-entry` of an accepted `citation` (outside every
  `example-block`) whose entry name is `#` and a `part-name`, when that
  citation has no `home-design`;
- each accepted `inline-citation` for which the text that `name`
  matches in the match of its destination by `inline-destination` is
  `#` followed by a `part-name`, when that inline citation has no
  `home-design`.

When `X` is a tag-line input, let `Y` be its `tag-line-text`; otherwise
let `Y` be `X` itself (the link, the citation entry, or the inline
citation). The subject of the finding is the `position-subject` of the
`origin-position` of `Y`, and the location of the finding is the
`slice-location` of the `origin` slice of `Y` in the text of its file.

#### Duplicate findings

@atom duplicate-finding=v1
@cites {
    ontology#{declared-item=v1, item-name=v1},
    text#{character=v1, text=v1},
    #{name-set=v1, tree-finding=v1},
}

The **ASCII lowercase folding** of a `text` replaces each ASCII
uppercase letter (`U+0041` to `U+005A`, `character`) with the
corresponding ASCII lowercase letter (`U+0061` to `U+007A`).

For each `name-set` of a tree (spanning both text and `.sinter/`) and
each maximal group of two or more declared items in that set whose
names have equal ASCII lowercase foldings (including two declarations
with equal canonical objects, or one in text and one in `.sinter/`),
the tree has one `tree-finding` of the class `duplicate`, with no
location:

- for the shared set, the subject is the ASCII lowercase folding of
  their names;
- for the set of a `design` `D`, the subject is the exact name of `D`,
  then `#`, then the ASCII lowercase folding of their part names.

#### Dangling findings

@atom dangling-finding=v1
@cites {
    identifiers#{citation-entry=v1, inline-citation=v1, part-name=v1},
    data-forms#vector-line=v1,
    ontology#{edge=v1, declared-item=v1, object-kind=v1},
    #{
        tree-edge=v1, canonical-object=v1, home-design=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, slice-location=v1, tree-finding=v1,
    },
}

A tree has one `tree-finding` of the class `dangling` for each
`tree-edge` whose cited item is neither present nor withheld (not an
ambiguous pin, not lacking its canonical target or needed computed
identity key, and not targeting a withdrawn non-text object), excluding
the two no-home-design cases (a citation entry or inline citation whose
entry name is `#` and a `part-name` with no `home-design`). An edge
whose target is an `example` content ID has no cited item and is not
withheld (`tree-edge`).

- When the source of the edge is a declared item (in text, in
  `.sinter/`, or from a program's own store) or an `example` object,
  when the canonical object of that source is not withheld: one finding
  per distinct canonical edge
  `<source-content-id> <edge-kind> <target-content-id>`, with its
  `edge-finding-subject` and object edge location
  (`edge-finding-subject`).
- When the source of the edge is a test, a site, or none: subject is
  the `position-subject` of the `origin-position` of its citation entry
  or inline citation, and location is the `slice-location` of the
  `origin` slice of that citation entry or inline citation in its file.
- When the edge comes from a `vector-line`: subject is the
  `position-subject` of its form position in its vector file, and
  location is the `slice-location` of its form slice in the text of its
  vector file.

#### Wrong-source findings

@atom wrong-source-finding=v1
@cites {
    identifiers#{citation-entry=v1, inline-citation=v1},
    ontology#{
        edge=v1, edge-source=v1, declared-item=v1, cites-edge=v1,
        satisfies-edge=v1, verifies-edge=v1, refines-edge=v1,
        supersedes-edge=v1,
    },
    #{
        tree-edge=v1, canonical-object=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, slice-location=v1, tree-finding=v1,
    },
}

A tree has one `tree-finding` of the class `wrong-source` for each
`tree-edge` that has no source, or whose source is not of a kind that
its edge kind permits as its source (`cites-edge`, `satisfies-edge`,
`verifies-edge`, `refines-edge`, `supersedes-edge`).

- When the source of the edge is a declared item (in text, in
  `.sinter/`, or from a program's own store) whose canonical object and
  canonical edge target are not withheld: one finding per distinct
  canonical edge `<source-content-id> <edge-kind> <target-content-id>`
  (for example, a `verifies` edge whose source is a declared item, even
  when its target is a missing identity file in `.sinter/`), with its
  `edge-finding-subject` and object edge location
  (`edge-finding-subject`).
- When the edge has no source or its source is a test or a site:
  subject is the `position-subject` of the `origin-position` of its
  citation entry or inline citation, and location is the
  `slice-location` of the `origin` slice of that citation entry or
  inline citation in its file.

#### Wrong-kind findings

@atom wrong-kind-finding=v1
@cites {
    identifiers#{
        citation-entry=v1, inline-citation=v1, external-target=v1,
        kind-word=v1,
    },
    data-forms#vector-line=v1,
    ontology#{
        edge=v1, edge-source=v1, declared-item=v1, external-item=v1,
        conformance-vector-group=v1, vector-set=v1, object-kind=v1,
        cites-edge=v1, satisfies-edge=v1, verifies-edge=v1,
        refines-edge=v1, supersedes-edge=v1,
    },
    #{
        tree-edge=v1, canonical-object=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, slice-location=v1, tree-finding=v1,
    },
}

A written `kind-word` states the item kinds in this table, and states
no `conformance-vector-group`, no `vector-set`, and no object of
another kind:

| written kind word | stated item kinds |
|---|---|
| `design` | `design` |
| `spec` | `spec`, or `external-item` |
| `req` | `req` |
| `schema` | `schema` |
| `atom` | `atom` |
| `term` | `term`, or `external-item` |
| `decision` | `decision` |

Two conditions apply to each `tree-edge` that has a cited item (neither
ambiguous nor withheld by a missing part):

1. **Cited kind condition (both encodings, examples, tests, sites,
   vector lines, and no source):** the cited item is not of a kind that
   the edge's kind permits as its cited item (`cites-edge`,
   `satisfies-edge`, `verifies-edge`, `refines-edge`,
   `supersedes-edge`, including a vector-line edge whose cited item in
   scope is not a `schema`). For a `refines` or `supersedes` edge that
   has no source, or whose source is not a declared item, this
   condition is instead that the cited item is not a declared item.
2. **Written kind word condition (text encoding only):** the edge comes
   from a text citation entry or inline citation (including one
   standing in an `example` object) that starts with a written
   `kind-word` that does not state the kind of that cited item per the
   table in this item (including before an `external-target`).

A tree has these `tree-finding` values of the class `wrong-kind`:

- When the source of the edge is a declared item (in text, in
  `.sinter/`, or from a program's own store) or an `example` object,
  when the canonical object of that source is not withheld: condition 1
  produces one finding per distinct canonical edge
  `<source-content-id> <edge-kind> <target-content-id>`, with its
  `edge-finding-subject` and object edge location
  (`edge-finding-subject`); condition 2 (in text only) produces one
  finding whose subject is the `position-subject` of the
  `origin-position` of its citation entry or inline citation and whose
  location is the `slice-location` of the `origin` slice of that
  citation entry or inline citation in its file.
- When the source of the edge is a test, a site, or none, and condition
  1 or condition 2 (or both) holds: one finding whose subject is the
  `position-subject` of the `origin-position` of its citation entry or
  inline citation and whose location is the `slice-location` of the
  `origin` slice of that citation entry or inline citation in its file.
- When the edge comes from a `vector-line` and condition 1 holds: one
  finding whose subject is the `position-subject` of its form position
  in its vector file and whose location is the `slice-location` of its
  form slice in the text of its vector file.

#### Misplaced-declaration findings

@atom misplaced-declaration-finding=v1
@cites {
    identifiers#{
        declaration=v1, extern-line=v1, target=v1, full-name=v1,
        tag-line-text=v1,
    },
    ontology#{declared-item=v1, containment=v1, edge-source=v1},
    #{
        read-file=v1, accepted-input=v1, example-block=v1,
        item-file=v1, tag-text=v1, declaration-scope=v1,
        tree-containment=v1, item-part=v1, innermost-item=v1,
        origin=v1, origin-position=v1, position-subject=v1,
        slice-location=v1, tree-finding=v1,
    },
}

A tree has one `tree-finding` of the class `misplaced-declaration` for
each `declaration` of a text declared item `d` of the tree that meets
one or more of the first seven conditions, and for each `@extern` line
that meets the eighth condition:

1. `d` is of the kind `design`, and its file is a code file
   (`read-file`).
2. `d` is of the kind `design`, and its declaration lies in the
   `declaration-scope` of another text `design` in the same file.
3. `d` is of the kind `spec`, `req`, `schema`, `atom`, or `term`; the
   innermost text `design` in whose `declaration-scope` its declaration
   lies (`innermost-item`) is `D`; and `d` belongs (`tree-containment`)
   to a `design` other than `D`.
4. `d` is of the kind `req`, `schema`, `atom`, or `term`; its
   declaration lies in the `declaration-scope` of a text `spec` `S`
   that is the innermost text `spec` in whose `declaration-scope` that
   declaration lies; and `d` belongs to a `design` to which `S` does
   not belong.
5. `d` is of the kind `spec`, and its declaration lies in the
   `declaration-scope` of another text `spec` in the same file.
6. `d` is of the kind `spec`, `schema`, `atom`, or `term`, and `d`
   belongs to no `design`.
7. `d` is of the kind `req`, `schema`, `atom`, or `term`; `d` belongs
   to a `design` `D`; the name in the `target` of the declaration of
   `d` is a `full-name`; the file of `d` is a Markdown file; the file
   of `d` is not the file of `D`; and, when `d` belongs to a `spec`
   (`tree-containment`), the file of `d` is not the file of that
   `spec`.
8. The line is an `@extern` line (`extern-line`) that is a line of a
   `tag-text`, that is an `accepted-input`, that does not lie on any
   file line of an `example-block`, and that stands in no text `design`
   (`item-part`).

The subject of the finding is the `position-subject` of the
`origin-position` of the `tag-line-text` of the declaration or
`@extern` line. The location of the finding is the `slice-location` of
the `origin` slice of that text in its file.

#### Requirement-outside-design findings

@atom req-outside-design-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    findings#location=v1,
    identifiers#tag-line-text=v1,
    ontology#{declared-item=v1, containment=v1, content-id=v1},
    object-store#valid-object-file=v1,
    #{
        item-file=v1, canonical-object=v1, tree-containment=v1,
        origin=v1, slice-location=v1, tree-finding=v1,
    },
}

A tree has one `tree-finding` of the class `req-outside-design` for
each distinct `content-id` of a declared item of the kind `req` of the
tree (in text, in `.sinter/`, or from a program's own store) that
belongs to no `design` (`tree-containment`) and whose canonical object
is not withheld by a missing part. The subject of the finding is that
content ID (`req:<32 hex>`). The location of the finding is:

- when exactly one declared item of the tree has that content ID and it
  is a text declared item: the `slice-location` of the `origin` slice
  of the `tag-line-text` of its declaration in the text of its file;
- when exactly one declared item of the tree has that content ID and it
  is a stored declared item in `.sinter/`: the valid `path` of its
  `valid-object-file` alone, with no span (`location`);
- when two or more declared items of the tree share that content ID, or
  when the item comes from a program's own store (`own-store`): no
  location.

#### Extern-mismatch findings

@atom extern-mismatch-finding=v1
@cites {
    identifiers#{tag-line-text=v1, kind-word=v1, part-name=v1},
    ontology#{
        containment=v1, item-name=v1, declared-item=v1, object-kind=v1,
    },
    #{
        item-file=v1, tree-containment=v1, extern-directive=v1,
        origin=v1, origin-position=v1, position-subject=v1,
        slice-location=v1, tree-finding=v1,
    },
}

A tree has these `tree-finding` values of the class `extern-mismatch`:

- one for each `extern-directive` of the tree that is not valid
  (including an extern directive whose part name names a held item
  stored in `.sinter/`). Its subject is the `position-subject` of the
  `origin-position` of the `tag-line-text` of that `@extern` line, and
  its location is the `slice-location` of the `origin` slice of that
  text in the file of that `@extern` line.
- one for each text `design` `D` and each text declared item `x` (never
  a stored declared item in `.sinter/`) that is either a `spec` that
  `D` holds, or an item of the kind `req`, `schema`, `atom`, or `term`
  that `D` holds directly (`tree-containment`), when both of these
  conditions hold: the file of `x` (`item-file`) is not the file of
  `D`, and `D` has no `extern-directive` whose part name equals the
  part name of the name of `x` and whose kind word equals the object
  kind word of `x` (`spec`, `req`, `schema`, `atom`, or `term`). Its
  subject is the `position-subject` of the `origin-position` of the
  `tag-line-text` of the declaration of `x`, and its location is the
  `slice-location` of the `origin` slice of that text in the file of
  `x`.

#### Pin-cycle findings

@atom pin-cycle-finding=v1
@cites {
    ontology#{edge=v1, declared-item=v1, computed-identity=v1},
    #{
        canonical-target=v1, canonical-object=v1,
        edge-finding-subject=v1, tree-finding=v1,
    },
}

A tree has one `tree-finding` of the class `pin-cycle` for each
distinct canonical pinned citation edge
`<source-content-id> <edge-kind> <pin-content-id>` of a declared item
(in text, in `.sinter/`, or from a program's own store, whose canonical
object is not withheld) whose exact pin or resolved `pin:` edge lies on
a directed cycle of the tree's own objects (`canonical-target`,
`ontology#edge`). Its subject is its `edge-finding-subject`, and its
location is its object edge location (`edge-finding-subject`).

#### Ambiguous-pin findings

@atom ambiguous-pin-finding=v1
@cites {
    data-forms#vector-line=v1,
    ontology#{
        edge=v1, declared-item=v1, computed-identity=v1, object-kind=v1,
    },
    #{
        tree-edge=v1, canonical-target=v1, canonical-object=v1,
        kept-object-set=v1, origin=v1, origin-position=v1,
        position-subject=v1, edge-finding-subject=v1,
        slice-location=v1, tree-finding=v1,
    },
}

A tree has one `tree-finding` of the class `ambiguous-pin` for each
`tree-edge` (citation edge or vector-line edge) whose exact pin or
resolved `pin:` edge is ambiguous under `canonical-target` (matching
two or more distinct canonical objects in its winning candidate set:
current declared items of the tree, replaced unwithdrawn declared-item
objects in `.sinter/`, or unwithdrawn objects in `kept-object-set`).

- When the source of the edge is a declared item (in text, in
  `.sinter/`, or from a program's own store) or an `example` object,
  when the canonical object of that source is not withheld: one finding
  per distinct canonical edge
  `<source-content-id> <edge-kind> <pin-content-id>`, with its
  `edge-finding-subject` and object edge location
  (`edge-finding-subject`).
- When the source of the edge is a test, a site, or none: subject is
  the `position-subject` of the `origin-position` of its citation entry
  or inline citation, and location is the `slice-location` of the
  `origin` slice of that citation entry or inline citation in its file.
- When the edge comes from a `vector-line`: subject is the
  `position-subject` of its form position in its vector file, and
  location is the `slice-location` of its form slice in the text of its
  vector file.

### Returning edges

@req give-edges=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    identifiers#{
        external-namespaces=v1, citation-entry=v1, inline-citation=v1,
    },
    data-forms#vector-line=v1,
    ontology#{edge=v1, edge-source=v1, tree=v1, content-id=v1},
    object-store#tree-object-store=v1,
    #{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        tree-edge=v1, origin-position=v1,
    },
}

Given a `tree`, valid bindings of `file-readers`,
`external-namespaces`, and `vector-files`, a valid `tree-object-store`,
and a valid `kept-object-set`, when returning the edges of that tree, a
conforming program must return each `tree-edge` of the tree once (and
no other edge) with:

- the file of that edge;
- for a text `citation-entry`, `inline-citation`, or `vector-line`
  edge, the `origin-position` of its citation entry or inline citation
  or the form position of its vector line;
- the kind of edge;
- its canonical target `content-id` (unless withheld as a missing part
  under `report-missing-parts`);
- its source (`edge-source`), or that the edge has no source; and
- its cited item, or that the edge has no cited item (unless withheld
  under `tree-edge` because the pin is ambiguous or a part is missing).

When any of those inputs is invalid, the program must return no edges
(`reject-invalid-inputs`).

### Returning extern directives

@req give-extern-directives=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    identifiers#{external-namespaces=v1, tag-line-text=v1},
    ontology#{tree=v1, declared-item=v1},
    object-store#tree-object-store=v1,
    #{file-readers=v1, extern-directive=v1, origin-position=v1},
}

Given a `tree`, valid bindings of `file-readers` and
`external-namespaces`, and a valid `tree-object-store`, when returning
the extern directives of that tree, a conforming program must return
each `extern-directive` of the tree once (and no other extern
directive) with the file and `origin-position` of the `tag-line-text`
of its `@extern` line, the `design` of that extern directive, and
whether that extern directive is valid. When any of those inputs is
invalid, the program must return no extern directives
(`reject-invalid-inputs`).

### Returning tree findings

@req give-tree-findings=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1, give-results-over-canonical-objects=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{finding-class=v1, tree=v1, computed-identity=v1},
    object-store#tree-object-store=v1,
    #{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        tree-finding=v1, invalid-target-finding=v1,
        duplicate-finding=v1, dangling-finding=v1,
        wrong-source-finding=v1, wrong-kind-finding=v1,
        misplaced-declaration-finding=v1,
        req-outside-design-finding=v1, extern-mismatch-finding=v1,
        pin-cycle-finding=v1, ambiguous-pin-finding=v1,
    },
}

Given a `tree`, valid bindings of `file-readers` and
`external-namespaces`, a valid `tree-object-store`, and a valid
`kept-object-set`:

- When returning findings of the tree of any of the six classes
  `invalid-target`, `duplicate`, `misplaced-declaration`,
  `req-outside-design`, `extern-mismatch`, and `pin-cycle`, a
  conforming program must return each `tree-finding` of that class that
  the tree has once, and no other finding of that class (independent of
  whether `vector-files` is valid).
- When `vector-files` is valid and returning findings of the tree of
  any of the four classes `dangling`, `wrong-source`, `wrong-kind`, and
  `ambiguous-pin`, a conforming program must return each `tree-finding`
  of that class that the tree has once, and no other finding of that
  class. When `vector-files` is invalid, the program must return no
  finding of those four classes (`reject-invalid-inputs`).

When any of `file-readers`, `external-namespaces`, `tree-object-store`,
or `kept-object-set` is invalid, the program must return no finding of
any of these ten classes (`reject-invalid-inputs`). When a
`computed-identity` object absent from `.sinter/` or `kept-object-set`
is supplied by another input of the run, no finding of these ten
classes is withheld because of that object; when no input supplies its
key, only findings that need its key are withheld
(`report-missing-parts`).

## Test vectors

Test vectors for this design live in
[`documents.test-vectors.jsonl`](documents.test-vectors.jsonl) as a
test-vector set under
[test-vectors](sinter:data-forms#test-vectors=v1). Three groups cover
pure Markdown trees (`markdown`), trees with code files (`code`), and
trees with `.sinter/` object stores and caller-supplied kept objects
(`objects`). No group uses `result` or `needs`.

### Shared vector encoding

@schema vector-encoding=v1
@cites {
    rfc/8259,
    text#{
        text=v1, slice=v1, position=v1, byte-sequence=v1,
        valid-utf-8=v1, utf-8-text=v1, code-point-order=v1,
    },
    files#path=v1,
    data-forms#{line-object=v1, index=v1, hex-text=v1},
    identifiers#{
        external-namespaces=v1, slug=v1, full-name=v1,
        external-id=v1, status-tag=v1,
    },
    ontology#{
        tree=v1, declared-item=v1, containment=v1, site=v1, test=v1,
        edge=v1, edge-source=v1, external-item=v1,
        conformance-vector-group=v1, vector-set=v1, finding-class=v1,
        object=v1, content-id=v1, object-kind=v1,
    },
    object-store#tree-object-store=v1,
    findings#{location=v1, finding-subject=v1},
    #{
        file-readers=v1, vector-files=v1, read-file=v1,
        origin-position=v1, position-order=v1, example-block=v1,
        extent=v1, canonical-object=v1, tree-containment=v1,
        tree-site=v1, tree-edge=v1, extern-directive=v1,
        vector-file=v1, tree-finding=v1,
    },
}

The three vector groups of this design share these RFC 8259 JSON
encodings in `input` and `values` (every JSON object holds only its
listed members):

- **file content:** a `utf-8-text` string when `valid-utf-8`, or
  `{"bytes": "<hex>"}` (`hex-text` of the `byte-sequence`) otherwise.
- **slice:** `{"from": int, "to": int}` (boundaries of the file's
  `text`, `text#slice`).
- **position:** `{"line": int, "column": int}` (1-based line and
  column, `text#position`).
- **location:** `{"path": string}` (valid `path` with no span) or
  `{"path": string, "span": slice}` (`findings#location`).
- **reference:** one of `{"item": k}` (1-based `index` `k` in
  `values.items`), `{"example": i, "of": k}` (1-based `index` `i` of an
  `example-block` on item `k`), `{"site": k}` (1-based `index` `k` in
  `values.sites`), `{"test": k}` (1-based `index` `k` in
  `values.tests`, in group `code` only), `{"external": t}`
  (`external-ref` text `t` of an `external-item`),
  `{"group": g, "of": k}` (group `g` of item `k`'s `vector-set`),
  `{"vector-set": k}` (item `k`'s `vector-set`), or `{"object": c}`
  (non-declared-item `object` with `content-id` `c`, in group `objects`
  only).

Shared `input` and `values` members across all three groups:

| field | type | meaning |
|---|---|---|
| `input.files` | object | input `tree`, mapping each file's valid `path` to its file content |
| `input.vector-files` | object | binding of `vector-files`, mapping target name strings (`slug` or `full-name`) to `path` strings (`{}` when empty) |
| `input.external-namespaces` | array of objects | binding of `external-namespaces` (`{"namespace-name": string, "id-pattern": string}`; element order has no meaning) |
| `values.read-files` | object (optional) | maps each `read-file` valid `path` to the 1-based `index` in `input.file-readers` of the first matching pair |
| `values.items[]` | array of objects (optional) | declared items sorted by `code-point-order` of `file`, then `position-order` of `at` |
| `values.items[].kind` | string | object kind word: `design`, `spec`, `req`, `schema`, `atom`, `term`, or `decision` |
| `values.items[].name` | string | resolved item name |
| `values.items[].file` | string | valid `path` of the item's file |
| `values.items[].at` | position (optional) | `origin-position` of the declaration (present for text declared items, absent for stored `.sinter/` items) |
| `values.items[].extent` | array of slices (optional) | file lines of the item's `extent`, in order (present for text declared items, absent for stored `.sinter/` items) |
| `values.items[].content-id` | string (optional) | `content-id` of the item's `canonical-object`; absent when withheld by a missing part |
| `values.items[].object` | `line-object` (optional) | item's canonical object; absent when withheld by a missing part |
| `values.items[].design` | integer (optional) | 1-based `index` in `items` of the containing `design` (`tree-containment`) |
| `values.items[].specification` | integer (optional) | 1-based `index` in `items` of the containing `spec` (`tree-containment`) |
| `values.items[].vector-file` | string (optional) | valid `path` of the item's `vector-file`; present only under valid `vector-files` when the item has one |
| `values.examples[]` | array of objects (optional) | `example` objects of text declared items, sorted by `(of, index)` |
| `values.examples[].of` | integer | 1-based `index` in `items` of the parent declared item |
| `values.examples[].index` | integer (`>= 1`) | 1-based index of the `example-block` on its parent |
| `values.examples[].content-id` | string (optional) | `content-id` of the `example` object; absent when withheld by a missing part |
| `values.examples[].object` | `line-object` (optional) | canonical `example` object; absent when withheld by a missing part |
| `values.sites[]` | array of objects (optional) | `tree-site` values sorted by `code-point-order` of `file`, then start boundary of first line |
| `values.sites[].file` | string | valid `path` of the site's file |
| `values.sites[].lines` | array of slices | file lines of the site, in order |
| `values.edges[]` | array of objects (optional) | `tree-edge` values sorted by `code-point-order` of `file`, edges with `at` before edges without `at`, `position-order` of `at`, `code-point-order` of `kind`, then `code-point-order` of `to` (absent `to` first) |
| `values.edges[].kind` | string | citation edge kind (`cites`, `satisfies`, `verifies`, `refines`, or `supersedes`) |
| `values.edges[].file` | string | valid `path` of the edge's file |
| `values.edges[].at` | position (optional) | `origin-position` of the citation entry or inline citation, or form position of the vector line (absent for stored `.sinter/` edges) |
| `values.edges[].to` | string (optional) | canonical target `content-id`; absent when withheld by a missing part |
| `values.edges[].source` | reference (optional) | edge source (`edge-source`, including `{"example": i, "of": k}` for inline citations inside `@example`); absent when no source |
| `values.edges[].cited` | reference (optional) | cited item; absent when none or withheld by an ambiguous pin or missing part |
| `values.vector-group-defs` | object (optional) | maps each non-withheld `vector-group-def` `content-id` to its canonical `line-object` |
| `values.status-tags[]` | array of objects (optional) | accepted `status-tag` inputs outside `example-block`s, sorted by `code-point-order` of `file`, then `position-order` of `at` |
| `values.status-tags[].file` | string | valid `path` of the status tag's file |
| `values.status-tags[].at` | position | `origin-position` of the status tag |
| `values.status-tags[].item` | reference (optional) | what the status tag stands in; absent when none |
| `values.extern-directives[]` | array of objects (optional) | `extern-directive` values sorted by `code-point-order` of `file`, then `position-order` of `at` |
| `values.extern-directives[].file` | string | valid `path` of the `@extern` line's file |
| `values.extern-directives[].at` | position | `origin-position` of the `@extern` line |
| `values.extern-directives[].design` | integer | 1-based `index` in `items` of the directive's `design` |
| `values.extern-directives[].valid` | boolean | whether the `extern-directive` is valid |
| `values.findings[]` | array of objects (optional) | non-withheld `tree-finding` values of applicable classes sorted by `code-point-order` of `class`, then `subject` |
| `values.findings[].class` | string | `finding-class` slug |
| `values.findings[].subject` | string | `finding-subject` |
| `values.findings[].location` | location (optional) | finding `location`; absent when no location |

Each group schema specifies which members `values` omits for invalid
inputs. For any member of `values` omitted due to an invalid binding or
an invalid `tree-object-store`, a conforming program returns none of
the outputs that member represents. When a program returns an output
represented by a present member, its output matches that member, and
for any absent optional field on an element, the program returns that
the element has no such value or withholds it when a missing part or
ambiguous pin applies.

### Markdown vectors

@schema markdown-vector=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    files#path-set=v1,
    data-forms#{
        test-vector-set=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    identifiers#external-namespaces=v1,
    #{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        vector-file=v1, vector-encoding=v1,
        give-read-files=v1, give-file-findings=v1,
        give-declared-items=v1, give-sites=v1,
        give-status-tag-items=v1, give-vector-files=v1,
        give-canonical-objects=v1, give-containment=v1,
        give-edges=v1, give-extern-directives=v1,
        give-tree-findings=v1,
    },
}

`markdown-vector` is a `group-schema` for group `markdown` on trees
with no code files, no `.sinter/` files, and an empty
`kept-object-set`. Each line is a `vector-line` in the
`test-vector-set`, omits `result` and `needs`, follows `vector-meaning`,
and uses the encodings and shared `input` and `values` members of
`vector-encoding`, testing `give-read-files`, `give-file-findings`,
`give-declared-items`, `give-sites`, `give-status-tag-items`,
`give-vector-files`, `give-canonical-objects`, `give-containment`,
`give-edges`, `give-extern-directives`, `give-tree-findings`,
`reject-invalid-inputs`, and `report-missing-parts`.

| field | type | meaning |
|---|---|---|
| `input.file-readers` | array of arrays | one `path-set` string array per pair in `file-readers` order, each paired with reader `"markdown"` |

All items and edges are from text or vector files, so `items[].at`,
`items[].extent`, and `edges[].at` are always present.

Invalid-input omission in `values`:

- When `file-readers` is invalid, `values` is `{}` (no output returned).
- When `file-readers` is valid and `external-namespaces` is invalid,
  `values` holds only `read-files` and `findings` (classes
  `parse-error`, `typo-tag`, and `ignored-tag` only).
- When `file-readers` and `external-namespaces` are valid and
  `vector-files` is invalid, `values` omits `edges` and
  `vector-group-defs`, each element of `items` omits `vector-file`, and
  `findings` holds only the three file finding classes plus the six
  `vector-files`-independent classes (`invalid-target`, `duplicate`,
  `misplaced-declaration`, `req-outside-design`, `extern-mismatch`, and
  `pin-cycle`).
- Otherwise, `values` holds all nine shared members of
  `vector-encoding`.

@example Sample lines testing
[give-read-files](sinter:#give-read-files=v1),
[give-file-findings](sinter:#give-file-findings=v1), and
[reject-invalid-inputs](sinter:conformance#reject-invalid-inputs=v1)
for an invalid [file-readers](sinter:#file-readers=v1) binding and for
an [example-block](sinter:#example-block=v1) suppressing file findings
under an invalid
[external-namespaces](sinter:identifiers#external-namespaces=v1)
binding ([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#markdown-vector=v1","group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["!docs/old/"]],"files":{"docs/a.md":"# A\n@design a=v1\n"},"vector-files":{}},"note":"a path set whose members are all ! members is not valid","values":{}}
{"form":"#markdown-vector=v1","group":"markdown","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"BAD"}],"file-readers":[["docs/"]],"files":{"docs/d.md":"# D\n@design d=v1\n\n## R\n@req r=v1\nNorm.\n\n@example\n@rqe typo\nExample text.\n"},"vector-files":{}},"note":"an @example block inside a text declaration still suppresses ignored-tag and typo-tag under an invalid binding of external-namespaces","values":{"findings":[],"read-files":{"docs/d.md":1}}}
```

### Code vectors

@schema code-vector=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    text#{slice=v1, valid-utf-8=v1, code-point-order=v1},
    files#{path=v1, path-set=v1},
    data-forms#{
        test-vector-set=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    identifiers#external-namespaces=v1,
    packs#{
        valid-pack=v1, comment-sigil=v1, foreign-tag-word=v1,
        file-parse=v1, parse-result=v1, node-slice=v1,
        parse-tree-order=v1, comment-node=v1, definition-node=v1,
        decoration-node=v1, test-node=v1, test-name=v1,
    },
    #{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        comment-sequence=v1, attachment=v1, file-test=v1, code-hash=v1,
        vector-encoding=v1,
        give-read-files=v1, give-file-findings=v1,
        give-tests=v1, compute-code-hashes=v1,
        give-declared-items=v1, give-sites=v1,
        give-status-tag-items=v1, give-vector-files=v1,
        give-canonical-objects=v1, give-containment=v1,
        give-edges=v1, give-extern-directives=v1,
        give-tree-findings=v1,
    },
}

`code-vector` is a `group-schema` for group `code` on trees that can
hold code files, with no `.sinter/` files and an empty
`kept-object-set`. Each line is a `vector-line` in the
`test-vector-set`, omits `result` and `needs`, follows `vector-meaning`,
and uses the encodings and shared `input` and `values` members of
`vector-encoding`, testing `give-read-files`, `give-file-findings`,
`give-tests`, `compute-code-hashes`, `give-declared-items`,
`give-sites`, `give-status-tag-items`, `give-vector-files`,
`give-canonical-objects`, `give-containment`, `give-edges`,
`give-extern-directives`, `give-tree-findings`,
`reject-invalid-inputs`, and `report-missing-parts`.

A **name path** (`test-name`) is an array of own names in order, where
each own name is an array of piece objects (`{"text": string}` for a
text piece or `{"placeholder": string}` for a placeholder). References
can use `{"test": k}` (1-based index in `values.tests`), and all items
and edges are from text or vector files (`items[].at`,
`items[].extent`, and `edges[].at` are always present).

| field | type | meaning |
|---|---|---|
| `input.file-readers[]` | array of objects | pairs of `file-readers` in order |
| `input.file-readers[].paths` | array of strings | `path-set` of the pair |
| `input.file-readers[].reader` | string or object | `"markdown"`, or a pack object standing for a `valid-pack` |
| `input.file-readers[].reader.line` | array of strings | line `comment-sigil` strings of the pack's descriptor, in order |
| `input.file-readers[].reader.inner` | array of strings | inner `comment-sigil` strings of the pack's descriptor, in order |
| `input.file-readers[].reader.foreign-tags` | array of strings | `foreign-tag-word` strings of the pack's descriptor, in order |
| `input.file-readers[].reader.block` | array of 2-string arrays | `[opening-sigil, closing-sigil]` pairs of the pack's descriptor, in order |
| `input.file-readers[].reader.parses` | object | maps each `valid-utf-8` read file matched by this pair (and no earlier pair) to its `file-parse` object: `{"result": parse-result}` plus `nodes[]` only when `result` is `"parsed"` |
| `input.file-readers[].reader.parses.<path>.nodes[]` | array of objects | every `comment-node`, `definition-node`, `decoration-node`, and `test-node` in `parse-tree-order`, each holding `slice` (`node-slice`) plus applicable kind members: `comment` (`"tagged"` or `"untagged"`), `body` (array of `slice`s of body nodes in `parse-tree-order`), `decoration` (`true`), and `test` (name path); a node that is both a definition node and a test node carries both `body` and `test` |
| `values.tests[]` | array of objects (optional) | `file-test` entries sorted by `code-point-order` of `file`, start boundary of `code`, then `parse-tree-order` of `test-node` |
| `values.tests[].file` | string | valid `path` of the test's file |
| `values.tests[].name` | name path | `test-name` of the test |
| `values.tests[].code` | slice | code slice of the test |
| `values.tests[].comments` | array of slices | slices of attached `comment-sequence`s on the test, sorted by start boundary |
| `values.code-hashes[]` | array of objects (optional) | `code-hash` entries sorted by `code-point-order` of `file`, then start boundary of `comments` |
| `values.code-hashes[].file` | string | valid `path` of the comment sequence's file |
| `values.code-hashes[].comments` | slice | slice from start to end boundary of the `comment-sequence` |
| `values.code-hashes[].code-text` | string | normalized code text of the `attachment` target |
| `values.code-hashes[].code-hash` | string | 64-character SHA-256 hex digest of `code-text` |

In `nodes[]`, for every element and every later element, either the
later element's `slice` lies within the earlier element's `slice` or
the earlier element's `slice` ends at or before the later element's
`slice` starts (`node-slice`, `parse-tree-order`). The input stands for
every binding of `file-readers` whose pairs have those path sets,
`"markdown"` readers, and valid packs with those comment sigils and
foreign tag words that produce those `file-parse` results on those
files.

Invalid-input omission in `values`:

- When `file-readers` is invalid, `values` is `{}` (including no tests,
  no code texts, and no code hashes).
- When `file-readers` is valid and `external-namespaces` is invalid,
  `values` holds only `read-files`, `findings` (classes `parse-error`,
  `typo-tag`, and `ignored-tag` only), `tests`, and `code-hashes`.
- When `file-readers` and `external-namespaces` are valid and
  `vector-files` is invalid, `values` omits `edges`,
  `vector-group-defs`, and `items[].vector-file`, and `findings` omits
  the four `vector-files`-dependent classes (`dangling`,
  `wrong-source`, `wrong-kind`, `ambiguous-pin`), keeping all other
  members including `tests` and `code-hashes`.
- Otherwise, `values` holds `tests`, `code-hashes`, and all nine shared
  members of `vector-encoding`.

@example Sample lines testing
[give-file-findings](sinter:#give-file-findings=v1) on unreadable code
files and [give-tests](sinter:#give-tests=v1) with an empty
[test-name](sinter:packs#test-name=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#code-vector=v1","group":"code","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[{"paths":["lib/"],"reader":{"block":[],"foreign-tags":[],"inner":[],"line":["//"],"parses":{"lib/a.rs":{"result":"parse failure"},"lib/b.rs":{"result":"no grammar"}}}}],"files":{"lib/a.rs":"// @req a=v1\n","lib/b.rs":"// @req b=v1\n","lib/c.rs":{"bytes":"2f2f20ff0a"}},"vector-files":{}},"note":"a code file cannot be read when its parse has the result no grammar or parse failure, or when its content is not valid UTF-8","values":{"code-hashes":[],"edges":[],"examples":[],"extern-directives":[],"findings":[{"class":"parse-error","location":{"path":"lib/a.rs"},"subject":"lib/a.rs"},{"class":"parse-error","location":{"path":"lib/b.rs"},"subject":"lib/b.rs"},{"class":"parse-error","location":{"path":"lib/c.rs"},"subject":"lib/c.rs"}],"items":[],"read-files":{"lib/a.rs":1,"lib/b.rs":1,"lib/c.rs":1},"sites":[],"status-tags":[],"tests":[],"vector-group-defs":{}}}
{"form":"#code-vector=v1","group":"code","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[{"paths":["tests/"],"reader":{"block":[],"foreign-tags":[],"inner":[],"line":["//"],"parses":{"tests/a.test.ts":{"nodes":[{"slice":{"from":0,"to":4},"test":[[]]}],"result":"parsed"}}}}],"files":{"tests/a.test.ts":"it()\n"},"vector-files":{}},"note":"a test node whose kept matches capture no node under name or placeholder has an own name with no piece (packs test-name), and that is the name of its test (file-test)","values":{"code-hashes":[],"edges":[],"examples":[],"extern-directives":[],"findings":[],"items":[],"read-files":{"tests/a.test.ts":1},"sites":[],"status-tags":[],"tests":[{"code":{"from":0,"to":4},"comments":[],"file":"tests/a.test.ts","name":[[]]}],"vector-group-defs":{}}}
```

### Object-store vectors

@schema objects-vector=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1, give-results-over-canonical-objects=v1,
    },
    text#code-point-order=v1,
    files#path-set=v1,
    data-forms#{
        line-object=v1, test-vector-set=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{object-withdrawal=v1, computed-identity=v1},
    object-store#{
        tree-object-store=v1, store-file=v1,
        invalid-object-file-finding=v1,
        missing-identity-file-finding=v1, give-store-objects=v1,
        give-store-findings=v1,
    },
    ledger#accepted-record=v1,
    #{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        extent=v1, vector-encoding=v1,
        give-read-files=v1, give-file-findings=v1,
        give-declared-items=v1, give-sites=v1,
        give-status-tag-items=v1, give-vector-files=v1,
        give-canonical-objects=v1, give-containment=v1,
        give-edges=v1, give-extern-directives=v1,
        give-tree-findings=v1,
    },
}

`objects-vector` is a `group-schema` for group `objects` on trees with
no code files that can hold `.sinter/` store files (`store-file`) and
caller-supplied `kept-object-set` objects. Each line is a `vector-line`
in the `test-vector-set`, omits `result` and `needs`, follows
`vector-meaning`, and uses the encodings and shared `input` and
`values` members of `vector-encoding`, testing `give-read-files`,
`give-file-findings`, `give-declared-items`, `give-sites`,
`give-status-tag-items`, `give-vector-files`, `give-canonical-objects`,
`give-containment`, `give-edges`, `give-extern-directives`,
`give-tree-findings`, `give-store-objects`, `give-store-findings`,
`reject-invalid-inputs`, `report-missing-parts`, and
`give-results-over-canonical-objects`.

Each input stands for every tree in which no list of persons is bound
and `accepted-record` holds for every valid `void` object in `.sinter/`
that carries no `agent` member (`object-withdrawal`).

| field | type | meaning |
|---|---|---|
| `input.file-readers` | array of arrays | one `path-set` string array per pair in `file-readers` order, each paired with reader `"markdown"` |
| `input.kept-objects` | array of `line-object`s | caller-supplied `kept-object-set` of valid canonical declared-item and `computed-identity` objects |
| `values.findings[]` | array of objects | always present; non-withheld tree findings of applicable classes merged with object-store findings (`invalid-object-file-finding` and `missing-identity-file-finding` from `give-store-findings`), sorted by `code-point-order` of `class`, then `subject` |

In this group, `input.files` can hold `.sinter/` store files,
references can use `{"object": c}`, `values.items[]` includes both text
declared items and unwithdrawn, unreplaced `.sinter/` declared items
(omitting `at` and `extent` on stored items), and `values.edges[]`
includes citation edges of stored `.sinter/` items (omitting `at` on
stored edges, with edges that carry `at` sorted before edges without
`at`).

Invalid-input omission in `values`:

- When `file-readers` is invalid, `values` holds only `findings`,
  containing the object-store findings of the tree.
- When `file-readers` is valid and either `tree-object-store` is
  invalid (`.sinter/` has an `invalid-object-file` finding) or
  `external-namespaces` is invalid, `values` holds only `read-files`
  and `findings` (object-store findings plus file findings
  `parse-error`, `typo-tag`, and `ignored-tag`).
- When `file-readers`, `external-namespaces`, and `tree-object-store`
  are valid and `vector-files` is invalid, `values` omits `edges`,
  `vector-group-defs`, and `items[].vector-file`, and `findings` holds
  the object-store findings, the three file finding classes, and the
  six `vector-files`-independent tree finding classes
  (`invalid-target`, `duplicate`, `misplaced-declaration`,
  `req-outside-design`, `extern-mismatch`, and `pin-cycle`).
- Otherwise, `values` holds all nine shared members of
  `vector-encoding`.

@example Sample lines testing
[give-tree-findings](sinter:#give-tree-findings=v1) on a stored
requirement in `.sinter/`
([req-outside-design-finding](sinter:#req-outside-design-finding=v1))
and [give-vector-files](sinter:#give-vector-files=v1) on valid
[vector-files](sinter:#vector-files=v1) entries whose target or path is
absent from the tree ([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#objects-vector=v1","group":"objects","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["docs/"]],"files":{".sinter/df/df59249b3b1ad50fa9c412ab7e186654.json":"{\"edges\":[{\"kind\":\"about\",\"to\":\"name:028f43ed275ca6cea9c9a735561a6353\"}],\"kind\":\"req\",\"label\":\"v1\",\"name\":\"lone\",\"text\":\"paragraph: Standalone.\\n\",\"v\":1}"},"kept-objects":[],"vector-files":{}},"note":"same requirement moved to .sinter/: identical canonical object, content-id, and req-outside-design subject, changing only location to path alone","values":{"edges":[],"examples":[],"extern-directives":[],"findings":[{"class":"req-outside-design","location":{"path":".sinter/df/df59249b3b1ad50fa9c412ab7e186654.json"},"subject":"req:df59249b3b1ad50fa9c412ab7e186654"}],"items":[{"content-id":"req:df59249b3b1ad50fa9c412ab7e186654","file":".sinter/df/df59249b3b1ad50fa9c412ab7e186654.json","kind":"req","name":"lone","object":{"edges":[{"kind":"about","to":"name:028f43ed275ca6cea9c9a735561a6353"}],"kind":"req","label":"v1","name":"lone","text":"paragraph: Standalone.\n","v":1}}],"read-files":{},"sites":[],"status-tags":[],"vector-group-defs":{}}}
{"form":"#objects-vector=v1","group":"objects","input":{"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["docs/"]],"files":{"docs/d.md":"# D\n@design d=v1\n"},"kept-objects":[],"vector-files":{"d":"docs/missing.jsonl","ghost":"docs/ghost.jsonl"}},"note":"valid vector-files entries whose path is absent from the tree or whose target matches no declared item produce no vector-file and no documents finding","values":{"edges":[],"examples":[],"extern-directives":[],"findings":[],"items":[{"at":{"column":1,"line":2},"content-id":"design:24af7bd7bbc2a5147415610fde95c778","extent":[{"from":0,"to":3},{"from":4,"to":16}],"file":"docs/d.md","kind":"design","name":"d","object":{"edges":[{"kind":"about","to":"name:cd4cd021e421cfa87cc98279597862f7"}],"kind":"design","label":"v1","name":"d","text":"","v":1}}],"read-files":{"docs/d.md":1},"sites":[],"status-tags":[],"vector-group-defs":{}}}
```
