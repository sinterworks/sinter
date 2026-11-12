<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Findings
@design findings=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites ontology=v1
@cites rfc/8259
Specifies the parts of a finding: its finding class, subject, message, spot, mark, related spots, fix, and whether it is ackable; spots and their start and end positions; edits, edit sets, and the edited texts that they give; fixes and mechanical fixes; finding ids and the identity of findings; and requirements for conforming programs that give findings, finding ids, and the positions of spots, and that make the edits of edit sets.

A finding reports one condition at one part of a repository, such as a
requirement that no test cites. Each finding has a finding class, which
a slug names, and a subject, a text that names what the finding is
about. The finding id of a finding is made from these two, and two
findings with the same finding class and the same subject are the same
finding, in any tree. A finding also has a message for people, and it
can have a spot, which is a file and a span of its text, a mark, related
spots, and a fix. The fix of a finding is one or more edit sets: each
edit set changes the texts of files, and it corrects the finding or
records that a person acknowledges it.

From Text and notation, the design takes texts, characters, line feeds,
and carriage returns; runs, boundaries, bodies, line endings, lines,
positions, and spans; valid UTF-8, UTF-8 encodings, and the text of a
byte sequence; and conforming programs, inputs, and results. From
Identifiers, it takes slugs. From Files and paths, it takes valid paths.
From the Ontology, it takes findings and finding classes, trees, and
persons.

From RFC 8259, the design takes JSON texts, with their objects, members,
arrays, strings, and numbers: each line of the file that holds the
conformance vectors of the design is a JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [finding](sinter:ontology#finding-class=v1) | a report of one condition at one part of a repository |
| [finding class](sinter:ontology#finding-class=v1) | a kind of finding, which a slug names |
| [slug](sinter:identifiers#slug=v1) | one segment, such as `late-fee`, or several segments joined by `/`, such as `billing/late-fee`; a segment is ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them; so a slug holds no `:` |
| [tree](sinter:ontology#tree=v1) | the set of the files of a repository, with their contents, at one commit or in one working tree |
| [person](sinter:ontology#person=v1) | a human who works on a repository |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [line feed](sinter:text#line-feed=v1), [carriage return](sinter:text#carriage-return=v1) | the characters U+000A and U+000D |
| [boundary](sinter:text#boundary=v1) | a whole number from 0 to the number of characters of a text: boundary 0 is before the first character, and each other boundary k is right after the k-th character |
| [run](sinter:text#run=v1) | the characters of a text from one boundary to the same boundary or a later boundary; a run can be empty |
| [body](sinter:text#body=v1) | the run of a text after its byte order mark, the character U+FEFF at the start of the text, or the whole text when it has none |
| [line ending](sinter:text#line-ending=v1) | a line feed of the body, with the carriage return right before it when there is one |
| [line](sinter:text#line=v1) | one of the runs into which the line endings divide a body, except an empty run at the end of the body |
| [position](sinter:text#position=v1) | a pair of whole numbers, the line number and the column, such as line 3, column 7; each boundary of the body has one |
| [span](sinter:text#span=v1) | a run of a text that starts and ends at boundaries of the body |
| [valid UTF-8](sinter:text#valid-utf-8=v1) | a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| [conforming program](sinter:text#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |
| [input](sinter:text#input=v1) | a thing that a conforming program takes |
| [result](sinter:text#result=v1) | a text that a requirement shows between two double quotes, such as "valid", as one of the cases of what a conforming program gives for an input |
| [message](sinter:#message=v1) | a text for people, not empty, with no line feed and no carriage return, whose words the program that gives it chooses |
| [message of a finding](sinter:#message=v1) | the message that says what is wrong |
| [subject](sinter:#finding-subject=v1) | the text, not empty, that names what a finding is about |
| [finding id](sinter:#finding-id=v1) | the text `finding:`, then the slug that names the finding class of a finding, then `:`, then the subject of the finding |
| [same finding](sinter:#same-finding=v1) | two findings are the same finding when the slugs that name their finding classes are the same text and their subjects are the same text, in any tree and in any execution of a program |
| [spot](sinter:#spot=v1) | a valid path of a file of a tree, alone or with a span of the text of the content of that file that starts and ends at no boundary inside a line ending |
| [spot of a finding](sinter:#spot=v1) | the spot where a finding stands; a finding has one spot or none |
| [inside a line ending](sinter:#spot=v1) | a boundary is inside a line ending when a line ending starts before it and ends after it: the boundary between the carriage return and the line feed of a line ending |
| [start position, end position](sinter:#spot=v1) | the positions of the boundaries where the span of a spot starts and ends |
| [spot from one position to another](sinter:#spot=v1) | the spot at a valid path whose start position and end position are those two positions, when the tree has one |
| [related spot](sinter:#related-spot=v1) | a message, alone or with a spot, that helps to explain a finding |
| [mark](sinter:#mark=v1) | a spot and a message: the part of the spot of a finding that is at fault, on the line where the span of that spot starts, and what is wrong there |
| [edit](sinter:#edit=v1) | a spot with a span, together with a text, its new text, which takes the place of the text of the span |
| [new text](sinter:#edit=v1) | the text that an edit puts in the place of the text of its span |
| [edit set](sinter:#edit-set=v1) | one or more edits in one tree, in which no two edits of one file have a character in common and no two edits of one file insert at one boundary |
| [edited text](sinter:#edit-set=v1) | the text of a file after the edits of an edit set: its text, with the text of the span of each edit of that file replaced by the new text of that edit |
| [make the edits of an edit set](sinter:#edit-set=v1) | change the content of each file that an edit of the set names to the UTF-8 encoding of its edited text |
| [acknowledge](sinter:#ackable-finding=v1) | a person acknowledges a finding when the person records that they know of the finding and that it may stay |
| [ackable](sinter:#ackable-finding=v1) | a finding is ackable when a person can acknowledge it |
| [fix](sinter:#fix=v1) | a message and one or more edit sets, which have numbers from 1; when there are two or more, a person chooses one |
| [correct](sinter:#fix=v1) | an edit set corrects a finding when, after its edits are made, the condition that the finding reports no longer holds |
| [mechanical fix](sinter:#mechanical-fix=v1) | a fix with exactly one edit set, which corrects the finding |

## 2. Findings, spots, edits, and fixes

### 2.1 The parts of a finding

A finding is a report of one condition at one part of a repository. Its
finding class is the kind of finding, which a slug names. Each finding
has these parts:

| part | what it is | how many |
|---|---|---|
| finding class | the kind of the finding, by the slug that names it | exactly one |
| subject | a text that names what the finding is about | exactly one |
| message | a text for people that says what is wrong | exactly one |
| spot | where the finding stands: a file, alone or with a span of its text | one or none |
| mark | the part of the spot that is at fault, with a message | one or none; none when the finding has no spot with a span |
| related spots | other places that help to explain the finding, each with a message | zero or more |
| fix | a message and one or more edit sets | one or none |
| ackable | whether a person can acknowledge the finding | exactly one: ackable or not ackable |

For example, a repository declares the finding class `no-test`, which
reports a requirement that no test cites. The requirement
`packs#limit-size` is declared on line 41 of `docs/designs/packs.md`, by
the tag line `@req limit-size=v2`, and no test cites it. The finding has
these parts:

| part | value |
|---|---|
| finding class | `no-test` |
| subject | `packs#limit-size` |
| message | `no test cites this requirement` |
| spot | `docs/designs/packs.md`, from line 41, column 1 to line 41, column 19 |
| mark | from line 41, column 6 to line 41, column 16, the text `limit-size`, with the message `cited by no test` |
| related spots | none |
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
such as a file whose content is not valid UTF-8 and so has no text.

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
ends right after a line ending: then the end position is in column 1 of
the next line. A valid path and two positions give the spot from the
first position to the second position at that valid path, when the tree
has such a spot.

The examples show a span as the boundary where it starts, "to", and the
boundary where it ends, such as "1 to 4":

| text | span | start position | end position |
|---|---|---|---|
| `abc` | 1 to 2 | line 1, column 2 | line 1, column 3 |
| `ab`, a line feed, `cd` | 1 to 4 | line 1, column 2 | line 2, column 2 |
| `ab`, a line feed, `cd` | 0 to 3 | line 1, column 1 | line 2, column 1 |
| `ab`, a carriage return, a line feed, `cd` | 2 to 4 | line 1, column 3 | line 2, column 1 |
| `a`, a line feed | 2 to 2 | line 2, column 1 | line 2, column 1 |
| U+FEFF, `x` | 1 to 2 | line 1, column 1 | line 1, column 2 |

In the text `ab`, a carriage return, a line feed, `cd`, boundary 3 is
inside a line ending, so no span of a spot starts or ends there.
Boundary 2 and boundary 3 have the same position, line 1, column 3, and
that position names boundary 2.

### 2.3 Marks and related spots

The mark of a finding is a spot and a message. The spot of the mark is
the part of the spot of the finding that is at fault, such as the name
or the revision of a tag line. It is in the same file. Its span starts
and ends at boundaries of the span of the spot of the finding, and at
boundaries of the line on which that span starts. The message of the
mark says what is wrong there. A finding has a mark only when its spot
has a span.

A related spot of a finding is a message, alone or with a spot, that
helps to explain the finding. For example, a finding about a citation
that names an old revision can have, as a related spot, the declaration
of the item that the citation names, with the message `declared here`.
A related spot without a spot tells of something that is in no file, by
its message alone. No two related spots of one finding have the same
message and the same spot.

### 2.4 Edits and edit sets

An edit is a spot with a span, together with a text, its new text. The
edit puts the new text in the place of the text of the span. An edit
with an empty span inserts its new text at the boundary of the span. An
edit with an empty new text removes the text of its span.

An edit set is one or more edits in one tree. For each two edits of an
edit set at the same valid path, exactly one of the two spans ends at or
before the boundary where the other starts. So two edits of one file
have no character in common, and no two edits of one file insert at the
same boundary. Two edits of one file can be next to each other: one can
end at the boundary where the other starts. An insertion at the boundary
where a non-empty span starts comes before the new text of that span.

The edited text of a file for an edit set is its text, in which the text
of the span of each edit of that file is replaced by the new text of
that edit. The text before the first span, between each two spans, and
after the last span stays as it was, a byte order mark included. To make
the edits of an edit set in a tree is to change the content of each file
that an edit of the set names to the UTF-8 encoding of its edited text.
The other files do not change.

In the examples, each edit shows its start position and its end
position as "line:column", and its new text:

| text | edits | edited text |
|---|---|---|
| `abc` | 1:2 to 1:3, `X` | `aXc` |
| `abc` | 1:2 to 1:2, `X` | `aXbc` |
| `abc` | 1:2 to 1:3, the empty text | `ac` |
| `abc` | 1:1 to 1:2, `X`; 1:3 to 1:3, `Y` | `XbYc` |
| `a`, a line feed, `b`, a line feed | 1:1 to 2:1, the empty text | `b`, a line feed |
| `ab`, a carriage return, a line feed, `c` | 1:3 to 2:1, the empty text | `abc` |
| `abc` | 1:2 to 1:2, `X`; 1:2 to 1:2, `Y` | none: two insertions at one boundary |
| `abc` | 1:1 to 1:3, `X`; 1:2 to 1:4, `Y` | none: the two spans have `b` in common |
| `abc` | 1:5 to 1:5, `X` | none: no boundary has the position line 1, column 5 |

### 2.5 Fixes

A fix of a finding is a message and one or more edit sets in one tree.
The edit sets of a fix have numbers from 1, in their order, and no two
of them are the same set. The message of the fix says what the fix
does. When a fix has two or more edit sets, a person chooses one of
them, and the edits of that one edit set are made.

Each edit set of a fix corrects the finding or acknowledges it. An edit
set corrects a finding when, after its edits are made, the condition
that the finding reports no longer holds, so there is no finding that
is the same finding. An edit set acknowledges a finding when its edits
record that a person acknowledges the finding. A person acknowledges a
finding when the person records that they know of the finding and that
it may stay. A finding is ackable when a person can acknowledge it. So
an edit set can acknowledge only an ackable finding.

A fix is mechanical when it has exactly one edit set, and that edit set
corrects the finding. A program can make the edits of a mechanical fix
with no choice and no decision of a person. A fix with two or more edit
sets needs the choice of a person. A fix whose edit set acknowledges the
finding records a decision of a person.

For example, a repository declares the finding class `old-word`, which
reports a word that its word list replaces. Line 3 of `docs/guide.md` is
`The stamp comes last.`, and the word list replaces `stamp` with
`approval`. The finding has the spot from line 3, column 1 to line 3,
column 22, and the mark from line 3, column 5 to line 3, column 10. Its
fix has one edit set, with one edit at `docs/guide.md`, from line 3,
column 5 to line 3, column 10, with the new text `approval`. After the
edit, line 3 is `The approval comes last.`, and the condition no longer
holds. So the fix is mechanical. If the word list gave two words for
`stamp`, the fix would have two edit sets, one for each word, and a
person would choose one.

### 2.6 The identity of a finding

The finding id of a finding is the text `finding:`, then the slug that
names its finding class, then `:`, then its subject. So the finding of
the class `no-test` with the subject `packs#limit-size` has the finding
id `finding:no-test:packs#limit-size`. A slug holds no `:`, so the first
`:` after `finding:` ends the slug, and the subject can hold `:`.

Two findings are the same finding when the slugs that name their
finding classes are the same text and their subjects are the same text.
This holds for two findings of two trees, and for two findings that a
program gives in two executions. The spot, the mark, the related spots,
the message, and the fix of a finding do not change which finding it
is. So when lines move in a file, a finding whose subject does not
change stays the same finding.

For one input, a conforming program gives no two findings that are the
same finding. So for each finding class, each subject names at most one
finding that a program gives for that input.

## 3. Definitions

### 3.1 Messages

@term message=v1
@cites {
    text#{text=v1, line-feed=v1, carriage-return=v1},
    ontology#{finding-class=v1},
}

A message is a text for people that is not empty and that holds no line
feed and no carriage return. The program that gives a message chooses
its words. Each finding has exactly one message, the message of the
finding, which says what is wrong.

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
    files#{path=v1},
    text#{
        text=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1, span=v1,
        boundary=v1, body=v1, line-ending=v1, position=v1,
    },
    ontology#{tree=v1, finding-class=v1},
}

A spot in a tree is a valid path that is the path of a file of the tree,
alone or together with a span of the text of the content of that file,
when that content is valid UTF-8. A boundary of a text is inside a line
ending when a line ending of the text starts before that boundary and
ends after it. The span of a spot starts at no boundary inside a line
ending, and it ends at no boundary inside a line ending.

The start position of a spot with a span is the position of the boundary
where its span starts. The end position of a spot with a span is the
position of the boundary where its span ends. For a valid path p and two
positions s and e, the spot from s to e at p in a tree is the spot in
that tree with the valid path p whose start position is s and whose end
position is e, when that tree has such a spot.

Each finding has one spot or none: the spot of the finding, where the
finding stands.

### 3.6 Related spots

@term related-spot=v1
@cites {ontology#{finding-class=v1}, #{message=v1, spot=v1}}

A related spot of a finding is a message, alone or together with a spot,
that helps to explain the finding. A finding has zero or more related
spots. No two related spots of one finding have the same message and the
same spot, and no two have the same message and no spot.

### 3.7 Marks

@term mark=v1
@cites {
    text#{span=v1, boundary=v1, run=v1, line=v1},
    ontology#{finding-class=v1},
    #{message=v1, spot=v1},
}

The mark of a finding is a spot and a message: the part of the spot of
the finding that is at fault, and what is wrong there. A finding has a
mark only when its spot has a span, and it has at most one mark. The
spot of the mark has the valid path of the spot of the finding. Its span
starts and ends at boundaries of the span of the spot of the finding,
and at boundaries of the line that starts at or before the boundary
where that span starts and ends at or after that boundary.

### 3.8 Edits

@term edit=v1
@cites {text#{text=v1, span=v1}, #{spot=v1}}

An edit in a tree is a spot in the tree that has a span, together with a
text, the new text of the edit. The span of the edit is the span of its
spot.

### 3.9 Edit sets

@term edit-set=v1
@cites {
    files#{path=v1},
    text#{
        text=v1, run=v1, boundary=v1, span=v1, utf-8-encoding=v1,
        text-of-a-byte-sequence=v1,
    },
    ontology#{tree=v1},
    #{edit=v1, spot=v1},
}

An edit set in a tree is a finite set of one or more edits in the tree
in which, for each two edits whose spots have the same valid path,
exactly one of the two spans ends at or before the boundary where the
other span starts.

For an edit set and a valid path p of one of its edits, let t be the
text of the content of the file at p, and let e1, …, en be the edits of
the set whose spots have the valid path p, in the order in which the
span of each ends at or before the boundary where the span of the next
starts. The edited text of p for the edit set is the text of the run of
t from boundary 0 to the boundary where the span of e1 starts; then, for
each k from 1 to n, the new text of ek, and then the text of the run of
t from the boundary where the span of ek ends to the boundary where the
span of ek+1 starts, or, for k = n, to the last boundary of t.

To make the edits of an edit set in a tree is to give the tree with the
same files, in which the content of each file at a valid path of an edit
of the set is the UTF-8 encoding of the edited text of that valid path,
and the content of each other file is as it was.

### 3.10 Ackable findings

@term ackable-finding=v1
@cites ontology#{finding-class=v1, person=v1}

A person acknowledges a finding when the person records that they know
of the finding and that it may stay. A finding is ackable when a person
can acknowledge it. Each finding is ackable or not ackable.

### 3.11 Fixes

@term fix=v1
@cites {
    ontology#{finding-class=v1, tree=v1, person=v1},
    #{message=v1, edit-set=v1, same-finding=v1, ackable-finding=v1},
}

A fix of a finding is a message and a finite sequence of one or more
edit sets in one tree, in which no two edit sets are the same set. The
message of the fix says what the fix does. The edit sets of a fix have
numbers from 1, in their order. When a fix has two or more edit sets, a
person chooses one of them. Each finding has one fix or none.

An edit set corrects a finding when, in the tree that making its edits
gives, the condition that the finding reports no longer holds, so that
there is no finding that is the same finding. An edit set acknowledges a
finding when its edits record that a person acknowledges the finding.

### 3.12 Mechanical fixes

@term mechanical-fix=v1
@cites #{fix=v1, edit-set=v1}

A fix is mechanical when it has exactly one edit set and that edit set
corrects the finding.

## 4. Requirements

### 4.1 The parts of each finding

@req give-finding-parts=v1
@cites {
    identifiers#{slug=v1},
    text#{conforming-program=v1},
    ontology#{finding-class=v1},
    #{
        finding-subject=v1, message=v1, spot=v1, mark=v1,
        related-spot=v1, fix=v1, ackable-finding=v1,
    },
}

For each finding that it gives, a conforming program must give these
parts of the finding: the slug that names its finding class; its
subject; its message; its spot, when it has one; its mark, when it has
one; each of its related spots, and no other related spot; its fix, when
it has one, with the message of the fix and the edit sets of the fix in
their order; and whether it is ackable.

### 4.2 Finding ids

@req give-finding-ids=v1
@cites {
    text#{conforming-program=v1, text=v1},
    ontology#{finding-class=v1},
    #{finding-id=v1},
}

When a conforming program gives a text as the finding id of a finding,
it must give the finding id of that finding, and no other text, as the
finding id of that finding.

### 4.3 No finding given twice

@req give-findings-once=v1
@cites {
    text#{conforming-program=v1, input=v1},
    ontology#{finding-class=v1},
    #{same-finding=v1},
}

For one input, a conforming program must give no two findings that are
the same finding.

### 4.4 The positions of spots

@req give-spot-positions=v1
@cites {text#{conforming-program=v1, position=v1}, #{spot=v1}}

When a conforming program gives a line number or a column as the start
position or the end position of a spot, it must give the line number or
the column of that position of that spot, and no other line number or
column, as that position.

### 4.5 The edits of edit sets

@req make-edit-sets=v1
@cites {
    files#{path=v1},
    text#{conforming-program=v1, text=v1, position=v1, result=v1},
    ontology#{tree=v1},
    #{spot=v1, edit=v1, edit-set=v1},
}

For each tree and each finite sequence of one or more elements, each
element a valid path, a first position, a second position, and a text,
a conforming program that makes the elements as the edits of one edit
set must give exactly one result. The result is "valid" when, for each
element, the tree has the spot from its first position to its second
position at its valid path, and these spots, each with the text of its
element as its new text, are the edits of an edit set in the tree, each
edit given by exactly one element. Otherwise, the result is "invalid".
With "valid", the program must give, for each valid path of an element,
the edited text of that valid path for that edit set, and no other text
as that edited text. With "invalid", it must give no edited text.

### 4.6 Fixes that correct or acknowledge

@req give-resolving-fixes=v1
@cites {
    text#{conforming-program=v1},
    ontology#{finding-class=v1},
    #{fix=v1, edit-set=v1, ackable-finding=v1},
}

A conforming program must give, as an edit set of the fix of a finding,
only an edit set that corrects that finding or acknowledges it.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 4.

The vectors of this design are in the file
[`findings.test-vectors.jsonl`](findings.test-vectors.jsonl), in the
same directory as this design. A vector is an
input and what a conforming program gives for it. Each vector follows
from the requirements and adds nothing to them. The vectors are in
groups. Each group has a name, such as `edit-sets`, and a subsection
below. The subsection names the requirements that the vectors of the
group follow from, and it describes their inputs, results, and values.
The requirements `give-finding-parts`, `give-findings-once`, and
`give-resolving-fixes` hold for each finding that a conforming program
gives, and no group holds vectors for them.

The file is valid UTF-8. Its text has no byte order mark and no carriage
return, and it ends with a line feed. Each line of the text of the file
is a JSON text, as RFC 8259 defines it, that holds one JSON object, with
no space, tab, or line feed outside its strings and with the members of
each object in the order of their keys. So only a line feed ends a line
of the file. U+0085, U+2028, and U+2029 can be in JSON strings of the
file, and they do not end a line. The file has three kinds of line, in
this order:

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
- `result`: the result that a conforming program gives for the input.
  Only a vector of the group `edit-sets` has this member.
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
the subsection of a group names as a text, a valid path, a slug, a
whole number, a run, a position, a sequence, or a tree has this form:

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
- A tree is a JSON object with one member for each file of the tree:
  the key is the valid path of the file, and the value is the text of
  its content, whose UTF-8 encoding is that content.

### 5.1 The edits of edit sets

The group `edit-sets` holds the vectors of the requirement
`make-edit-sets`. Each vector gives a tree, a sequence of elements, and
what a conforming program gives when it makes the elements as the edits
of one edit set.

- `input`: a JSON object with two members. `files` is the tree. `edits`
  is the sequence of elements: each element is a JSON object with four
  members, `path`, the valid path; `start`, the first position; `end`,
  the second position; and `new-text`, the text.
- `result`: "valid" when the tree has, for each element, the spot from
  its first position to its second position at its valid path, and
  these spots, with the texts of the elements as their new texts, are
  the edits of an edit set, each given by exactly one element; "invalid"
  otherwise.
- `values`: with the result "valid", a JSON object with one member,
  `edited-texts`: a JSON object with one member for each valid path of
  an element, whose key is that valid path and whose value is the
  edited text of that valid path. With the result "invalid", the empty
  JSON object, `{}`.

A conforming program that makes the elements as the edits of one edit
set gives the result that `result` holds, and no other result. With
"valid", it gives, as the edited text of each valid path, the text that
`edited-texts` holds for that valid path, and no other text. When
`values` is `{}`, it gives no edited text.

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

The group `spot-positions` holds the vectors of the requirement
`give-spot-positions`. Each vector gives the text of the content of the
file of a spot, the span of the spot, and the start position and the
end position of the spot.

- `input`: a JSON object with two members: `text`, the text, and `span`,
  the span of the spot, as a run.
- `result`: no vector of the group has this member.
- `values`: a JSON object with two members: `start`, the start position
  of the spot, and `end`, the end position of the spot.

When a conforming program gives a line number for the start position of
the spot, it gives the line number of `start`. When it gives a column
for the start position, it gives the column of `start`. When it gives a
line number for the end position of the spot, it gives the line number
of `end`. When it gives a column for the end position, it gives the
column of `end`.

```
{"group":"spot-positions","input":{"span":{"from":0,"to":3},"text":"ab\ncd"},"n":47,"note":"the span ends right after a line ending, so the end position is in column 1 of line 2","rev":"v1","values":{"end":{"column":1,"line":2},"start":{"column":1,"line":1}}}
```
