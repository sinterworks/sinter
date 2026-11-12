<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Findings
@design findings=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites ontology=v1
@cites rfc/8259
Specifies the parts of a finding: its tree, finding class, subject, message, spot, mark, related messages, fix, and whether it is ackable; spots and their start and end positions; edits, edit descriptions, edit sets, edited texts, and edited trees; fixes, corrections, acknowledgments, and mechanical fixes; finding ids and the identity of findings; and requirements for conforming programs that give the parts of findings, finding ids, the positions of spots, and edited texts, and that validate edit sets.

A finding reports one condition at one part of a repository, such as a
requirement that no test cites. Each finding has a finding class, which
a slug names, and a subject, a text that names what the finding is
about. The finding id of a finding is made from the slug and the
subject, and two findings with the same slug and the same subject are
the same finding, in any tree. A finding also has a message for people.
It can have a spot, which is the valid path of a file, alone or with a
span of the text of that file; a mark; related messages; and a fix. A
fix is a message and one or more edit sets. Each edit set changes the
texts of files, and it corrects the finding or records that a person
acknowledges it.

From Text and notation, the design takes whole numbers, decimal
numerals, and hex digits; texts, characters, line feeds, carriage
returns, and code spans; runs, boundaries, byte order marks, bodies,
line endings, lines, line numbers, columns, positions, and spans, with
the start and the end of a span; valid UTF-8, UTF-8 encodings, and the
text of a byte sequence; and conforming programs, inputs, and results.
From Identifiers, it takes slugs. From Files and paths, it takes valid
paths and regular files. From the Ontology, it takes findings and
finding classes, items, trees, persons, and the ledger.

From RFC 8259, the design takes JSON texts, with their objects, members,
arrays, strings, and numbers: each line of the file that holds the
conformance vectors of the design is a JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [finding](sinter:ontology#finding-class=v1) | a report of one condition at one part of a repository |
| [finding class](sinter:ontology#finding-class=v1) | a kind of finding, which a slug names |
| [item](sinter:ontology#item=v1) | a thing that Sinter traces, such as a requirement or a test |
| [slug](sinter:identifiers#slug=v1) | one segment, such as `late-fee`, or several segments joined by `/`, such as `billing/late-fee`; a segment is ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them; so a slug holds no `:` |
| [tree](sinter:ontology#tree=v1) | the set of the files of a repository, with their contents, at one commit or in one working tree |
| [ledger](sinter:ontology#ledger=v1) | the sequence of the ledger entries of a repository, each a record of one event, such as one approval |
| [person](sinter:ontology#person=v1) | a human who works on a repository |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [regular file](sinter:files#regular-file=v1) | a file that holds a content, which is a byte sequence |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [line feed](sinter:text#line-feed=v1), [carriage return](sinter:text#carriage-return=v1) | the characters U+000A and U+000D |
| [boundary](sinter:text#boundary=v1) | a whole number from 0 to the number of characters of a text: boundary 0 is before the first character, and each other boundary k is right after the k-th character |
| [run](sinter:text#run=v1) | the characters of a text from one boundary to the same boundary or a later boundary; a run can be empty |
| [byte order mark](sinter:text#byte-order-mark=v1) | the character U+FEFF when it is the first character of a text |
| [body](sinter:text#body=v1) | the run of a text after its byte order mark, or the whole text when it has no byte order mark |
| [line ending](sinter:text#line-ending=v1) | a line feed of the body, with the carriage return right before it when there is one |
| [line](sinter:text#line=v1) | one of the runs into which the line endings divide a body, except an empty run at the end of the body |
| [position](sinter:text#position=v1) | a pair of whole numbers, the line number and the column, such as line 3, column 7; each boundary of the body has one |
| [span](sinter:text#span=v1) | a run of a text that starts and ends at boundaries of the body |
| [start of a span, end of a span](sinter:text#span=v1) | the position of the boundary where a span starts; and the position of the boundary right after the last character of the span that is a character of a line, or the start of the span when it has no such character |
| [valid UTF-8](sinter:text#valid-utf-8=v1) | a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| [conforming program](sinter:text#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |
| [input](sinter:text#input=v1) | a thing that a conforming program takes |
| [result](sinter:text#result=v1) | a text that a requirement shows between two double quotes, such as "valid", as one of the cases of what a conforming program gives for an input |
| [message](sinter:#message=v1) | a text for people, not empty, with no line feed and no carriage return, whose words the program that gives it chooses |
| [subject of a finding](sinter:#finding-subject=v1) | the text, not empty, that names what a finding is about |
| [finding id](sinter:#finding-id=v1) | the text `finding:`, then the slug that names the finding class of a finding, then `:`, then the subject of the finding |
| [same finding](sinter:#same-finding=v1) | two findings are the same finding when, and only when, the slugs that name their finding classes are the same text and their subjects are the same text, in any tree and in any execution of a program |
| [spot](sinter:#spot=v1) | a valid path of a file of a tree, alone, or, when the file is a regular file and its content is valid UTF-8, with a span of its text that starts and ends at no boundary inside a line ending |
| [inside a line ending](sinter:#spot=v1) | a boundary is inside a line ending when a line ending starts before it and ends after it: the boundary between the carriage return and the line feed of a line ending |
| [start position, end position](sinter:#spot-position=v1) | the positions of the boundaries where the span of a spot starts and ends |
| [spot from one position to another](sinter:#spot-position=v1) | the spot at a valid path whose start position and end position are those two positions, when the tree has such a spot |
| [related message](sinter:#related-message=v1) | a message, alone or with a spot, that helps to explain a finding; the related messages of a finding are a set |
| [mark of a spot](sinter:#mark=v1) | a spot with a span, and a message, where that span lies in the span of the first spot and on the line where the span of the first spot starts |
| [edit](sinter:#edit=v1) | a spot with a span, together with a text, its new text |
| [edit set](sinter:#edit-set=v1) | one or more edits in one tree, in which, for each two edits of one file, exactly one of the two spans ends at or before the boundary where the other starts |
| [edited text](sinter:#edited-text=v1) | the text of a file after the edits of an edit set: its text, with the text of the span of each edit of that file replaced by the new text of that edit |
| [edited tree](sinter:#edited-tree=v1) | the tree in which the content of each file that an edit of an edit set names is the UTF-8 encoding of its edited text, and each other file is as it was |
| [make the edits of an edit set](sinter:#edited-tree=v1) | change a tree into the edited tree of the edit set |
| [edit description](sinter:#edit-description=v1) | a text, its path, a first position, a second position, and a text, its new text, which can describe the edit of the spot from the first position to the second at the path, with that new text |
| [fix](sinter:#fix=v1) | a message and one or more edit sets in one tree, no two the same, which have numbers from 1; to make a fix is to make the edits of exactly one of its edit sets |
| [acknowledge](sinter:#acknowledgment=v1) | a person acknowledges a finding when the person says that they know of the finding and that it may stay; an edit set acknowledges a finding when its edited tree records that a person acknowledges the finding |
| [acknowledgment](sinter:#acknowledgment=v1) | what a person says when the person acknowledges a finding |
| [ackable](sinter:#ackable-finding=v1) | a finding is ackable when an acknowledgment of it by a person can have effect |
| [parts of a finding](sinter:#finding-part=v1) | its tree, its finding class, its subject, its message, its spot, its mark, its related messages, its fix, and whether it is ackable, with the parts of these parts |
| [tree of a finding](sinter:#finding-part=v1) | the tree in which a finding reports its condition, or no tree |
| [correct](sinter:#correction=v1) | an edit set corrects a finding of a tree when, in its edited tree, the condition that the finding reports no longer holds for what the finding is about, wherever the edits move that thing |
| [mechanical fix](sinter:#mechanical-fix=v1) | the fix of a finding when it has exactly one edit set, which corrects the finding and acknowledges no finding |

## 2. Findings, spots, edits, and fixes

### 2.1 The parts of a finding

A finding is a report of one condition at one part of a repository. Its
finding class is the kind of finding, which a slug names. Each finding
has these parts:

| part | what it is | how many |
|---|---|---|
| tree | the tree in which the finding reports its condition | one tree, or none for a condition outside every tree, such as a condition of the ledger alone |
| finding class | the kind of the finding, by the slug that names it | exactly one |
| subject | a text that names what the finding is about | exactly one |
| message | a text for people that says what is wrong | exactly one |
| spot | where the finding stands in its tree: the valid path of a file, alone or with a span of the text of that file | one or none; none for a finding of no tree |
| mark | the part of the spot that is at fault, with a message | one or none; none when the finding has no spot with a span |
| related messages | other messages that help to explain the finding, each alone or with a spot | zero or more |
| fix | a message and one or more edit sets in the tree of the finding | one or none; none for a finding of no tree |
| ackable | whether an acknowledgment of the finding by a person can have effect | exactly one: ackable or not ackable |

Each part can have parts of its own. The parts of a spot are its valid
path and its span. The parts of a mark and of a related message are a
spot and a message. The parts of a fix are its message and its edit
sets, each with its number. The parts of an edit set are its edits, and
the parts of an edit are its spot and its new text.

For example, a repository declares the finding class `no-test`, which
reports a requirement that no test cites. In a tree, the requirement
`packs#limit-size` is declared on line 41 of `docs/designs/packs.md`, by
the tag line `@req limit-size=v2`, and no test cites it. The finding has
these parts:

| part | value |
|---|---|
| tree | that tree |
| finding class | `no-test` |
| subject | `packs#limit-size` |
| message | `no test cites this requirement` |
| spot | `docs/designs/packs.md`, from line 41, column 1 to line 41, column 19 |
| mark | from line 41, column 6 to line 41, column 16, the text `limit-size`, with the message `cited by no test` |
| related messages | none |
| fix | none |
| ackable | ackable |

A message is a text for people. It is not empty, and it holds no line
feed and no carriage return, so it is one line. The program that gives
a message chooses its words, so two conforming programs can give the
same finding with different messages.

The subject of a finding names what the finding is about. A subject
that names an item, such as `packs#limit-size`, stays the same when
lines move in a file. A thing that no name names, such as one word on
one line, can have a subject that holds its path and its position, such
as `docs/guide.md@L3C5`. Such a subject changes when lines move.

### 2.2 Spots and their positions

A spot is a valid path of a file of a tree, alone or with a span of the
text of the content of that file. A spot with a span shows a part of a
file, such as one tag line. A spot without a span shows a whole file,
such as a file whose content is not valid UTF-8 and so has no text. Only
a regular file whose content is valid UTF-8 has spots with spans.

The span of a spot starts and ends at boundaries of the body, and at no
boundary inside a line ending. A boundary is inside a line ending when
a line ending starts before it and ends after it: that is the boundary
between the carriage return and the line feed of a line ending. Of the
other boundaries of the body, no two have the same position. So the
position of each boundary where the span of a spot can start or end
names that boundary alone.

The start position of a spot is the position of the boundary where its
span starts, and the end position of a spot is the position of the
boundary where its span ends. The start position is always the start of
the span. The end position is the end of the span, except when the span
ends right after a line ending. Then the end position has the column 1,
and a line number 1 more than the line number of the line before that
line ending. The end of the span is the end of the line before that line
ending. A valid path and two positions name the spot from the first
position to the second position at that valid path, when the tree has
such a spot, and the tree has at most one.

The examples show a span as the boundary where it starts, "to", and the
boundary where it ends, such as "1 to 4":

| text | span | start position | end position |
|---|---|---|---|
| `abc` | 1 to 2 | line 1, column 2 | line 1, column 3 |
| `ab`, a line feed, `cd` | 1 to 4 | line 1, column 2 | line 2, column 2 |
| `ab`, a line feed, `cd` | 0 to 3 | line 1, column 1 | line 2, column 1 |
| `ab`, a carriage return, a line feed, `cd` | 2 to 4 | line 1, column 3 | line 2, column 1 |
| `a`, a line feed | 0 to 2 | line 1, column 1 | line 2, column 1 |
| U+FEFF, `x` | 1 to 2 | line 1, column 1 | line 1, column 2 |

In the text `ab`, a line feed, `cd`, the span 0 to 3 ends right after
the line ending, so its end position is line 2, column 1, and the end of
the span is line 1, column 3. In the text `ab`, a carriage return, a
line feed, `cd`, boundary 3 is inside a line ending, so no span of a
spot starts or ends there. Boundary 2 and boundary 3 have the same
position, line 1, column 3, and that position names boundary 2. In the
text `a`, a line feed, the end position of the span 0 to 2 is line 2,
column 1, although the text has only one line. A spot without a span
has no start position and no end position.

### 2.3 Marks and related messages

The mark of a finding is a mark of its spot: a spot with a span, and a
message. The spot of the mark is the part of the spot of the finding
that is at fault, such as the name or the revision of a tag line. It is
in the same file. Its span starts and ends at boundaries of the span of
the spot of the finding, and at boundaries of the line on which the span
of the spot of the finding starts. The message of the mark says what is
wrong there. A finding has a mark only when its spot has a span.

A related message of a finding is a message, alone or with a spot, that
helps to explain the finding. For example, a finding about a citation
that names an old revision can have, as a related message, the message
`declared here` with the spot of the declaration of the item that the
citation names. A related message without a spot tells of something
that is in no file. The related messages of a finding are a set: they
have no order, and no two of them are the same message with the same
spot, or the same message with no spot.

### 2.4 Edits and edit sets

An edit is a spot with a span, together with a text, its new text. In
the edited text, the new text replaces the text of the span. An edit
with an empty span inserts its new text at the boundary of the span. An
edit with an empty new text removes the text of its span.

An edit set is one or more edits in one tree. For each two edits of an
edit set at the same valid path, exactly one of the two spans ends at or
before the boundary where the other starts. So two edits of one file
have no character in common, no two edits of one file insert at the
same boundary, and no edit of one file inserts at a boundary inside the
span of another. Two edits of one file can be next to each other: one
can end at the boundary where the other starts. An insertion at the
boundary where a non-empty span starts comes before the new text of
that span, and an insertion at the boundary where a non-empty span ends
comes after it.

The edited text of a file for an edit set is its text, in which the text
of the span of each edit of that file is replaced by the new text of
that edit. The text before the first span, between each two spans, and
after the last span stays as it was, a byte order mark included. The
edited tree of an edit set is the tree in which the content of each
file that an edit of the set names is the UTF-8 encoding of its edited
text. The other files do not change. To make the edits of an edit set is
to change the tree into the edited tree.

An edit description is a text, its path, a first position, a second
position, and a text, its new text. It describes an edit when the tree
has the spot from the first position to the second position at the
path: the edit is that spot, with the new text of the edit description.
A sequence of edit descriptions describes an edit set when it has one
or more edit descriptions, each of them describes an edit, no two
describe the same edit, and these edits are an edit set.

In the examples, each edit description has the valid path of the one
file, and it shows its first position and its second position as
"line:column", and its new text:

| text | edit descriptions | edited text |
|---|---|---|
| `abc` | 1:2 to 1:3, `X` | `aXc` |
| `abc` | 1:2 to 1:2, `X` | `aXbc` |
| `abc` | 1:2 to 1:3, the empty text | `ac` |
| `abc` | 1:1 to 1:2, `X`; 1:3 to 1:3, `Y` | `XbYc` |
| `a`, a line feed, `b`, a line feed | 1:1 to 2:1, the empty text | `b`, a line feed |
| `ab`, a carriage return, a line feed, `c` | 1:3 to 2:1, the empty text | `abc` |
| `abc` | 1:2 to 1:2, `X`; 1:2 to 1:2, `Y` | none: two insertions at one boundary |
| `abc` | 1:1 to 1:3, `X`; 1:2 to 1:4, `Y` | none: the two spans have `b` in common |
| `abc` | 1:1 to 1:4, `X`; 1:2 to 1:2, `Y` | none: the insertion is at a boundary inside the other span |
| `abc` | 1:5 to 1:5, `X` | none: no boundary has the position line 1, column 5 |

### 2.5 Fixes

A fix is a message and one or more edit sets in one tree. The edit sets
of a fix have numbers from 1, in their order, and no two of them are
the same set. The message of the fix says what the fix does. To make a
fix is to make the edits of exactly one of its edit sets. So when a fix
has two or more edit sets, someone chooses one of them. The fix of a
finding is a fix in the tree of the finding.

An edit set corrects a finding of a tree when, in its edited tree, the
condition that the finding reports no longer holds for what the finding
is about. The edits can move that thing, such as a word that a new line
above it moves down one line. A correction is judged at the thing,
wherever the edits move it, so an edit set that only moves the thing
does not correct the finding.

A person acknowledges a finding when the person says that they know of
the finding and that it may stay. What the person says is an
acknowledgment of the finding. An edit set acknowledges a finding when
its edited tree records that a person acknowledges the finding. A
finding is ackable when an acknowledgment of it by a person can have
effect. An acknowledgment of a finding that is not ackable has no
effect. Each edit set of the fix of a finding corrects the finding, or
acknowledges it when the finding is ackable.

The fix of a finding is mechanical when it has exactly one edit set, and
that edit set corrects the finding and acknowledges no finding. So the
edits of a mechanical fix can be made with no choice between edit sets,
and they record no acknowledgment of a person.

For example, a repository declares the finding class `old-word`, which
reports a word that its word list replaces. Line 3 of `docs/guide.md` is
`The stamp comes last.`, and the word list replaces `stamp` with
`approval`. The finding has the spot from line 3, column 1 to line 3,
column 22, and the mark from line 3, column 5 to line 3, column 10. Its
fix has one edit set, with one edit at `docs/guide.md`, from line 3,
column 5 to line 3, column 10, with the new text `approval`. After the
edit, line 3 is `The approval comes last.`, and the condition no longer
holds. So the fix is mechanical. If the word list gave two words for
`stamp`, the fix would have two edit sets, one for each word.

### 2.6 The identity of a finding

The finding id of a finding is the text `finding:`, then the slug that
names its finding class, then `:`, then its subject. So the finding of
the class `no-test` with the subject `packs#limit-size` has the finding
id `finding:no-test:packs#limit-size`. A slug holds no `:`, so the first
`:` after `finding:` ends the slug, and the subject can hold `:`.

Two findings are the same finding when the slugs that name their
finding classes are the same text and their subjects are the same text.
This holds for two findings of two trees, and for two findings that a
program gives in two executions. The spot, the mark, the related
messages, the message, the fix, and whether a finding is ackable do not
change which finding it is. So when lines move in a file, a finding
whose subject does not change stays the same finding.

In one execution, for one input, a conforming program gives no two
findings of one tree that are the same finding, and no two findings of
no tree that are the same finding. So, in one tree, each subject names
at most one finding of each finding class.

## 3. Definitions

### 3.1 Messages

@term message=v1
@cites text#{text=v1, line-feed=v1, carriage-return=v1}

A message is a text for people that is not empty and that holds no line
feed and no carriage return. The program that gives a message chooses
its words.

### 3.2 Subjects of findings

@term finding-subject=v1
@cites {text#{text=v1}, ontology#{finding-class=v1}}

Each finding has exactly one subject: a text that is not empty and that
names what the finding is about.

### 3.3 Finding ids

@term finding-id=v1
@cites {
    identifiers#{slug=v1},
    text#{text=v1, code-span=v1},
    ontology#{finding-class=v1},
    #{finding-subject=v1},
}

The finding id of a finding is the text `finding:`, then the slug that
names the finding class of the finding, then `:`, then the subject of
the finding.

### 3.4 The same finding

@term same-finding=v1
@cites {
    identifiers#{slug=v1},
    text#{text=v1},
    ontology#{finding-class=v1, tree=v1},
    #{finding-subject=v1},
}

Two findings are the same finding when, and only when, the slugs that
name their finding classes are the same text and their subjects are the
same text. This holds also for two findings of two different trees, and
for two findings that a program gives in two different executions.

### 3.5 Spots

@term spot=v1
@cites {
    files#{path=v1, regular-file=v1},
    text#{
        text=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1, span=v1,
        boundary=v1, body=v1, line-ending=v1,
    },
    ontology#{tree=v1},
}

A boundary of a text is inside a line ending when a line ending of the
text starts before that boundary and ends after it. A spot in a tree is
a valid path that is the path of a file of the tree, alone, or, when
that file is a regular file and its content is valid UTF-8, together
with a span of the text of that content that starts at no boundary
inside a line ending and ends at no boundary inside a line ending.

### 3.6 Start and end positions

@term spot-position=v1
@cites {
    files#{path=v1},
    text#{position=v1, boundary=v1, span=v1},
    ontology#{tree=v1},
    #{spot=v1},
}

The start position of a spot with a span is the position of the boundary
where its span starts. The end position of a spot with a span is the
position of the boundary where its span ends. A spot without a span has
no start position and no end position. For a valid path p and two
positions s and e, the spot from s to e at p in a tree is the spot in
that tree with the valid path p whose start position is s and whose end
position is e, when that tree has such a spot.

### 3.7 Related messages

@term related-message=v1
@cites {ontology#{finding-class=v1}, #{message=v1, spot=v1}}

A related message of a finding is a message, alone or together with a
spot, that helps to explain the finding. The related messages of a
finding are a finite set, which can be empty: they have no order, and
no two of them are the same message with the same spot, or the same
message with no spot.

### 3.8 Marks

@term mark=v1
@cites {
    files#{path=v1},
    text#{span=v1, boundary=v1, run=v1, line=v1},
    ontology#{tree=v1},
    #{message=v1, spot=v1},
}

A mark of a spot with a span is a spot and a message. The spot of the
mark is in the same tree, it has the valid path of that spot, and it has
a span. That span starts and ends at boundaries of the span of that
spot, and at boundaries of the line that starts at or before the
boundary where the span of that spot starts and ends at or after that
boundary.

### 3.9 Edits

@term edit=v1
@cites {text#{text=v1, span=v1}, #{spot=v1}}

An edit in a tree is a spot in the tree that has a span, together with a
text, the new text of the edit. The span of the edit is the span of its
spot.

### 3.10 Edit sets

@term edit-set=v1
@cites {
    files#{path=v1},
    text#{boundary=v1, span=v1},
    ontology#{tree=v1},
    #{edit=v1, spot=v1},
}

An edit set in a tree is a finite set of one or more edits in the tree
in which, for each two edits whose spots have the same valid path,
exactly one of the two spans ends at or before the boundary where the
other span starts.

### 3.11 Edited texts

@term edited-text=v1
@cites {
    files#{path=v1},
    text#{
        text=v1, run=v1, boundary=v1, span=v1,
        text-of-a-byte-sequence=v1,
    },
    ontology#{tree=v1},
    #{edit=v1, edit-set=v1, spot=v1},
}

For an edit set in a tree and a valid path p of one of its edits, let t
be the text of the content of the file at p, and let e1, …, en be the
edits of the set whose spots have the valid path p, in the order in
which the span of each ends at or before the boundary where the span of
the next starts. The edited text of p for the edit set is the text of
the run of t from boundary 0 to the boundary where the span of e1
starts; then, for each k from 1 to n, the new text of ek, and then the
text of the run of t from the boundary where the span of ek ends to the
boundary where the span of ek+1 starts, or, for k = n, to the last
boundary of t.

### 3.12 Edited trees

@term edited-tree=v1
@cites {
    files#{path=v1},
    text#{utf-8-encoding=v1},
    ontology#{tree=v1},
    #{edit=v1, edit-set=v1, edited-text=v1},
}

The edited tree of an edit set in a tree is the tree with the same
files, in which the content of each file at a valid path of an edit of
the set is the UTF-8 encoding of the edited text of that valid path for
the edit set, and the content of each other file is as it was. To make
the edits of an edit set in a tree is to change that tree into the
edited tree of the edit set.

### 3.13 Edit descriptions

@term edit-description=v1
@cites {
    text#{text=v1, position=v1},
    ontology#{tree=v1},
    #{spot-position=v1, edit=v1, edit-set=v1},
}

An edit description is a text, its path; a first position; a second
position; and a text, its new text. An edit description describes an
edit in a tree when that tree has the spot from its first position to
its second position at its path: the edit is that spot, with the new
text of the edit description as its new text. A finite sequence of edit
descriptions describes an edit set in a tree when it has one or more
edit descriptions, each edit description of the sequence describes an
edit in that tree, no two edit descriptions of the sequence describe the
same edit, and these edits are the edits of an edit set in that tree,
which is the edit set that the sequence describes.

### 3.14 Fixes

@term fix=v1
@cites {ontology#{tree=v1}, #{message=v1, edit-set=v1, edited-tree=v1}}

A fix in a tree is a message, which says what the fix does, and a finite
sequence of one or more edit sets in that tree, in which no two edit
sets are the same set. The edit sets of a fix have numbers from 1, in
their order. To make a fix in a tree is to make the edits of exactly one
of its edit sets in that tree.

### 3.15 Acknowledgments

@term acknowledgment=v1
@cites {
    ontology#{finding-class=v1, person=v1},
    #{edit-set=v1, edited-tree=v1},
}

A person acknowledges a finding when the person says that they know of
the finding and that it may stay, and what the person says is an
acknowledgment of the finding by that person. An edit set acknowledges a
finding when its edited tree records an acknowledgment of the finding
by a person.

### 3.16 Ackable findings

@term ackable-finding=v1
@cites {ontology#{finding-class=v1, person=v1}, #{acknowledgment=v1}}

A finding is ackable when an acknowledgment of the finding by a person
can have effect. An acknowledgment of a finding that is not ackable has
no effect.

### 3.17 The parts of a finding

@term finding-part=v1
@cites {
    identifiers#{slug=v1},
    ontology#{finding-class=v1, tree=v1, ledger=v1},
    #{
        finding-subject=v1, message=v1, spot=v1, mark=v1,
        related-message=v1, fix=v1, edit-set=v1, edit=v1,
        ackable-finding=v1,
    },
}

The parts of a finding are these:

- its tree: the tree in which it reports its condition, when it is a
  finding of a tree; or no tree, when it reports a condition outside
  every tree, such as a condition of the ledger alone;
- its finding class, by the slug that names it;
- its subject;
- its message: a message that says what is wrong;
- its spot: one spot in its tree, where the finding stands, or no spot;
  a finding of no tree has no spot;
- its mark: one mark of its spot, the part of its spot that is at fault
  with what is wrong there, or no mark; a finding whose spot has no
  span, or that has no spot, has no mark;
- each of its related messages;
- its fix: one fix in its tree, or no fix; a finding of no tree has no
  fix;
- whether it is ackable.

Each part of a part of a finding is also a part of the finding. The
parts of a spot are its valid path and its span, when it has one. The
parts of a mark are its spot and its message. The parts of a related
message are its message and its spot, when it has one. The parts of a
fix are its message and each of its edit sets, each with its number.
The parts of an edit set are its edits. The parts of an edit are its
spot and its new text.

### 3.18 Corrections

@term correction=v1
@cites {
    ontology#{finding-class=v1, tree=v1},
    #{edit-set=v1, edited-tree=v1, finding-part=v1},
}

An edit set corrects a finding of a tree when, in the edited tree of the
edit set, the condition that the finding reports no longer holds for
what the finding is about, wherever the edits of the edit set move that
thing.

### 3.19 Mechanical fixes

@term mechanical-fix=v1
@cites #{fix=v1, correction=v1, acknowledgment=v1, finding-part=v1}

The fix of a finding is mechanical when it has exactly one edit set, and
that edit set corrects the finding and acknowledges no finding.

## 4. Requirements

### 4.1 The parts of each finding

@req give-finding-parts=v1
@cites {
    text#{conforming-program=v1},
    ontology#{finding-class=v1},
    #{finding-part=v1},
}

When a conforming program gives a value as a part of a finding, it must
give that part of that finding, and no other value, as that part.

### 4.2 No part that a finding does not have

@req omit-absent-finding-parts=v1
@cites {
    text#{conforming-program=v1},
    ontology#{finding-class=v1, tree=v1},
    #{finding-part=v1, spot=v1, mark=v1, related-message=v1, fix=v1},
}

A conforming program must give no tree, no spot, no mark, no related
message, and no fix as a part of a finding that does not have that part.

### 4.3 Finding ids

@req give-finding-ids=v1
@cites {
    text#{conforming-program=v1, text=v1},
    ontology#{finding-class=v1},
    #{finding-id=v1},
}

When a conforming program gives a text as the finding id of a finding,
it must give the finding id of that finding, and no other text, as the
finding id of that finding.

### 4.4 No finding given twice

@req give-findings-once=v1
@cites {
    text#{conforming-program=v1, input=v1},
    ontology#{finding-class=v1, tree=v1},
    #{same-finding=v1, finding-part=v1},
}

In one execution, for one input, a conforming program must give no two
findings of one tree that are the same finding, and no two findings of
no tree that are the same finding.

### 4.5 The start positions of spots

@req give-start-positions=v1
@cites {
    text#{conforming-program=v1, position=v1, line-number=v1},
    #{spot=v1, spot-position=v1},
}

When a conforming program gives a line number for the start position of
a spot, it must give the line number of the start position of that
spot, and no other line number, for that start position. When it gives
a column for the start position of a spot, it must give the column of
the start position of that spot, and no other column, for that start
position.

### 4.6 The end positions of spots

@req give-end-positions=v1
@cites {
    text#{conforming-program=v1, position=v1, line-number=v1},
    #{spot=v1, spot-position=v1},
}

When a conforming program gives a line number for the end position of a
spot, it must give the line number of the end position of that spot,
and no other line number, for that end position. When it gives a column
for the end position of a spot, it must give the column of the end
position of that spot, and no other column, for that end position.

### 4.7 No positions for a spot without a span

@req omit-positions-without-spans=v1
@cites {
    text#{conforming-program=v1, position=v1, line-number=v1},
    #{spot=v1, spot-position=v1},
}

A conforming program must give no line number and no column as the start
position or the end position of a spot that has no span.

### 4.8 The validation of edit sets

@req validate-edit-sets=v1
@cites {
    text#{conforming-program=v1, result=v1},
    ontology#{tree=v1},
    #{edit-description=v1, edit-set=v1},
}

For each tree and each finite sequence of edit descriptions, a
conforming program that gives a result for whether the sequence
describes an edit set in the tree must give exactly one result: "valid"
when the sequence describes an edit set in the tree, and "invalid" when
it does not.

### 4.9 The edited texts of edit sets

@req give-edited-texts=v1
@cites {
    files#{path=v1},
    text#{conforming-program=v1, text=v1},
    ontology#{tree=v1},
    #{edit-description=v1, edit-set=v1, edited-text=v1},
}

For each tree and each finite sequence of edit descriptions that
describes an edit set in the tree, when a conforming program gives a
text as the edited text of a valid path for the sequence, it must give
the edited text of that valid path for the edit set that the sequence
describes, and no other text.

### 4.10 No edited text without an edit set

@req omit-edited-texts=v1
@cites {
    text#{conforming-program=v1, text=v1},
    ontology#{tree=v1},
    #{edit-description=v1, edit-set=v1, edited-text=v1},
}

For each tree and each finite sequence of edit descriptions that
describes no edit set in the tree, a conforming program must give no
text as an edited text for the sequence.

### 4.11 The edit sets of fixes

@req limit-fix-edit-sets=v1
@cites {
    text#{conforming-program=v1},
    ontology#{finding-class=v1},
    #{
        finding-part=v1, fix=v1, edit-set=v1, correction=v1,
        acknowledgment=v1, ackable-finding=v1,
    },
}

A conforming program must give, as an edit set of the fix of a finding,
only an edit set that corrects that finding or, when that finding is
ackable, an edit set that acknowledges that finding.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 4.

The vectors of this design are in the file
[`findings.test-vectors.jsonl`](findings.test-vectors.jsonl), in the
same directory as this design. A vector is an input and what a
conforming program gives for it. Each vector follows from the
requirements and adds nothing to them. The vectors are in groups. Each
group has a name, such as `edit-sets`, and a subsection below. The
subsection names the requirements that the vectors of the group follow
from, and it describes their inputs, results, and values.

Several requirements apply only when a program gives the thing that they
name, such as a line number. So a vector holds a program only to what
the program gives for the input: a program that gives a line number for
a start position, and no column, is held only to the line number.

The file is valid UTF-8. Its text has no byte order mark and no carriage
return, and it ends with a line feed. Each line of the text of the file
is a JSON text, as RFC 8259 defines it, that holds one JSON object. So
only a line feed ends a line of the file. U+0085, U+2028, and U+2029 can
be in JSON strings of the file, and they do not end a line. The file has
three kinds of line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `edit-sets`,
   `finding-ids`, `spot-positions`. Its JSON object has two members:
   `group`, the name of the group, as a JSON string, and `rev`, the
   revision of the group.
3. Then each vector has a vector line, in increasing order of the
   numbers of the vectors.

The JSON object of a vector line has these members:

- `n`: the number of the vector, a JSON number written as the decimal
  numeral of a whole number of 1 or more. No other vector of the file
  has this number. A number is given to one vector only: when a vector
  leaves the file, no later vector gets its number, and a new vector
  gets a number greater than each number before it.
- `rev`: the revision of the vector.
- `group`: the name of the group of the vector, as a JSON string.
- `input`: the input.
- `result`: the result that a conforming program gives when it gives a
  result for the input. Only a vector of the group `edit-sets` has this
  member.
- `values`: a JSON object that holds what a conforming program gives
  for the input, other than the result. Each vector has this member. An
  empty JSON object, `{}`, says that a conforming program gives none of
  the things that the subsection of the group names for `values`.
- `note`: an explanation of the vector, as a JSON string, which a
  conforming program does not give. A vector has this member only when
  it has an explanation.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of the set line is the
revision of the whole set, the revision of a group line is the revision
of the group, and the revision of a vector line is the revision of the
vector. A revision rises, to a greater number after its `v`, when the
vectors that it covers change, join, or leave. When the text of this
section changes, the revisions of every vector, every group, and the set
rise. A change of a note alone changes no revision. A program does not
need the revisions to run the vectors.

Inside the members `input`, `result`, and `values`, each JSON value that
the subsection of a group names as a text, a slug, a whole number, a
run, a position, a sequence, or a tree has this form:

- A text, such as a result, a valid path, or a slug, is a JSON string
  whose characters are the characters of the text, in order. So the
  text `a`, a line feed, `b` is `"a\nb"`, and the empty text is `""`.
- A whole number, such as a boundary, a line number, or a column, is a
  JSON number written as its decimal numeral, such as `12`.
- A run is a JSON object with two members: `from`, the boundary where
  the run starts, and `to`, the boundary where the run ends. So the run
  that starts at boundary 1 and ends at boundary 4 is
  `{"from":1,"to":4}`.
- A position is a JSON object with two members: `line`, the line number
  of the position, and `column`, the column of the position. So the
  position line 3, column 7 is `{"column":7,"line":3}`.
- A sequence is a JSON array of its elements, in order.
- A tree is a JSON object with one member for each file of the tree.
  Each file of the tree is a regular file. The key is the valid path of
  the file. When the content of the file is valid UTF-8, the value is
  the text of that content, as a JSON string. When it is not, the value
  is a JSON object with one member, `bytes`: a JSON string of hex
  digits, for each byte of the content, in order, the hex digit of the
  whole-number quotient of the byte divided by 16, then the hex digit of
  the remainder. So the content 0xFF is `{"bytes":"ff"}`.

### 5.1 The edits of edit sets

The group `edit-sets` holds the vectors of the requirements
`validate-edit-sets`, `give-edited-texts`, and `omit-edited-texts`. Each
vector gives a tree, a sequence of edit descriptions, and what a
conforming program gives for them.

- `input`: a JSON object with two members. `files` is the tree. `edits`
  is the sequence of edit descriptions: each is a JSON object with four
  members, `path`, the path of the edit description, as a text; `start`,
  the first position; `end`, the second position; and `new-text`, the
  new text.
- `result`: the result of the tree and the sequence together, when a
  conforming program gives a result for whether the sequence describes
  an edit set in the tree: "valid" when it does, and "invalid" when it
  does not.
- `values`: with the result "valid", a JSON object with one member,
  `edited-texts`: a JSON object with one member for each path of an edit
  description of the sequence, whose key is that path and whose value is
  the edited text of that valid path for the edit set that the sequence
  describes. With the result "invalid", the empty JSON object, `{}`.

When a conforming program gives a result for whether the sequence
describes an edit set in the tree, it gives the result that `result`
holds, and no other result. When it gives a text as the edited text of a
valid path for the sequence, the valid path is a key of `edited-texts`,
and the text is the value of that key. When `values` is `{}`, it gives
no text as an edited text for the sequence.

```
{"group":"edit-sets","input":{"edits":[{"end":{"column":3,"line":1},"new-text":"X","path":"a.md","start":{"column":2,"line":1}}],"files":{"a.md":"abc"}},"n":1,"result":"valid","rev":"v1","values":{"edited-texts":{"a.md":"aXc"}}}
```

### 5.2 Finding ids

The group `finding-ids` holds the vectors of the requirement
`give-finding-ids`. Each vector gives the slug that names the finding
class of a finding, the subject of the finding, and its finding id.

- `input`: a JSON object with two members: `class`, the slug that names
  the finding class, and `subject`, the subject.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `finding-id`: the finding id
  of the finding.

When a conforming program gives a text as the finding id of the finding,
it gives the text that `finding-id` holds, and no other text.

```
{"group":"finding-ids","input":{"class":"no-test","subject":"packs#limit-size"},"n":39,"rev":"v1","values":{"finding-id":"finding:no-test:packs#limit-size"}}
```

### 5.3 The positions of spots

The group `spot-positions` holds the vectors of the requirements
`give-start-positions`, `give-end-positions`, and
`omit-positions-without-spans`. Each vector gives the text of the
content of the file of a spot and the span of the spot, when it has
one, and the start position and the end position of the spot, when it
has a span.

- `input`: a JSON object with the member `text`, the text, and, for a
  spot with a span, the member `span`, the span of the spot, as a run.
  For a spot without a span, the object has no other member.
- `result`: no vector of the group has this member.
- `values`: for a spot with a span, a JSON object with two members:
  `start`, the start position of the spot, and `end`, the end position
  of the spot. For a spot without a span, the empty JSON object, `{}`.

When a conforming program gives a line number for the start position of
the spot, it gives the line number of `start`. When it gives a column
for the start position, it gives the column of `start`. When it gives a
line number for the end position of the spot, it gives the line number
of `end`. When it gives a column for the end position, it gives the
column of `end`. When `values` is `{}`, it gives no line number and no
column as the start position or the end position of the spot.

```
{"group":"spot-positions","input":{"span":{"from":0,"to":3},"text":"ab\ncd"},"n":47,"note":"the span ends right after a line ending, so the end position is in column 1 of line 2","rev":"v1","values":{"end":{"column":1,"line":2},"start":{"column":1,"line":1}}}
```
