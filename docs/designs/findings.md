<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Findings
@design findings=v1
@cites conformance=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
Specifies the parts of a finding: its tree, finding class, subject, message, spot, mark, related messages, fix, and whether it is ackable; spots, their start positions, and the positions after them; edits, edit descriptions, edit sets, edited texts, and edited trees; fixes, corrections, and acknowledgments; finding ids and the identity of findings; and requirements for conforming programs that give the parts of findings, finding ids, the positions of spots, and edited texts, and that validate sequences of edit descriptions.

A finding reports one condition at one part of a repository, such as an
item of the kind requirement that no test cites. Each finding has a
finding class and a subject. A slug names that finding class. That
subject is a text that names what the finding is about. The finding id
of a finding is made from the slug and the subject. Two findings with
the same slug and the same subject are the same finding, in any tree. A
finding also has a message for people. A finding can have a spot, a
mark, related messages, and a fix. A spot is the valid path of a file,
alone or with a span of the text of the content of that file. A fix is a
message and one or more edit sets. Each edit set changes the texts of
files. Each edit set corrects the finding or adds an acknowledgment of
the finding by a person.

From Conformance (`conformance`), the design takes conforming programs,
inputs, and the general requirements that bind every conforming program.
From Text and notation, the design takes whole numbers, decimal
numerals, 0x numerals, U+ numerals, and hex digits; bytes and byte
sequences; texts, characters, spaces, tabs, line feeds, carriage
returns, code spans, and productions; places, runs, boundaries, byte
order marks, bodies, line endings, lines, line numbers, columns,
positions, and spans, with the start and the end of a span; valid UTF-8,
UTF-8 encodings, and the text of a byte sequence; and results. From Identifiers, it takes slugs and the
form of `@ack` lines. From Files and paths, it takes valid paths. From
the Ontology, it takes findings and finding classes, items, schemas,
trees, people, and the ledger. From Data forms, the design takes JSON
values, with the members of objects and their keys, and hex texts. From
the specification `test-vectors` of Data forms, the design takes
test-vector sets. The file that holds the conformance vectors of the
design is a test-vector set. From that specification, it also takes
vector lines, the forms of a group, needs and need names, and what a
vector line states.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [finding](sinter:ontology#finding-class=v1) | a report of one condition at one part of a repository |
| [finding class](sinter:ontology#finding-class=v1) | a kind of finding, which a slug names |
| [item](sinter:ontology#item=v1) | a thing that Sinter traces, such as an item of the kind requirement, a test, or a task |
| [schema](sinter:ontology#schema=v1) | a declared item whose declaration word is `@schema`; the schema gives the form of a thing that crosses the boundary of a conforming program: the layout of the thing and every constraint that is a property of the thing itself |
| [slug](sinter:identifiers#slug=v1) | one segment, such as `late-fee`, or several segments joined by `/`, such as `billing/late-fee`; a segment is ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them; so a slug holds no `:` |
| [tree](sinter:ontology#tree=v1) | a set of files, such as the files at a commit or the files in a working tree; each file has a valid path and a content, which is a byte sequence, and no two files in the set have the same valid path |
| [ledger](sinter:ontology#ledger=v1) | the sequence of the ledger entries of a repository, each a record of one event, such as one approval |
| [person](sinter:ontology#person=v1) | a human who works on a repository |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [line feed](sinter:text#line-feed=v1), [carriage return](sinter:text#carriage-return=v1) | the characters U+000A and U+000D |
| [place](sinter:text#place=v1) | a whole number, from 1 to the number of the characters of a text, at which a character is in the text |
| [boundary](sinter:text#boundary=v1) | a whole number from 0 to the number of characters of a text: boundary 0 is before the first character, and each other boundary k is right after the k-th character |
| [run](sinter:text#run=v1) | the characters of a text from one boundary to the same boundary or a later boundary; a run can be empty |
| [byte order mark](sinter:text#byte-order-mark=v1) | the character U+FEFF when it is the first character of a text |
| [body](sinter:text#body=v1) | the run of a text after its byte order mark, or the whole text when it has no byte order mark |
| [line ending](sinter:text#line-ending=v1) | a line feed of the body, with the carriage return right before it when there is one |
| [line](sinter:text#line=v1) | one of the runs into which the line endings divide a body, except an empty run at the end of the body |
| [position](sinter:text#position=v1) | a pair of whole numbers, the line number and the column, such as line 3, column 7; each boundary of the body has one |
| [span](sinter:text#span=v1) | a run of a text that starts and ends at boundaries of the body |
| [start of a span, end of a span](sinter:text#span=v1) | the position of the boundary where a span starts; and the position of the boundary right after the last place of the span that is a place of a line, or the start of the span when the span has no such place |
| [valid UTF-8](sinter:text#valid-utf-8=v1) | a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| execution | the work of a program from its start to its end |
| [conforming program](sinter:conformance#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |
| [input](sinter:conformance#input=v1) | a thing that a conforming program takes |
| [result](sinter:text#result=v1) | a text that a requirement shows between two double quotes, such as "valid", as one of the cases of what a conforming program gives for an input |
| [forms of a group](sinter:data-forms#group-form-list=v1) | five things that a schema that a specification declares under a name, or that a design declares under a name outside its specifications, gives for a group: the requirements of the group; what the value of `input` stands for, and its fixed form; the question that the value of `result` answers, the inputs that it is about, and the conditions under which the requirements oblige that result (the forms can name no question instead); what the value of `values` stands for, and its fixed form (the forms can give no fixed form for `values`); and the need names that the group uses, each with the need that it stands for |
| [need](sinter:data-forms#group-form-list=v1) | a condition on the environment in which a conforming program operates that a check of the vectors can be unable to make hold, such as that the file system stores a given entry name; the forms of a group give each need with a need name |
| [need name](sinter:data-forms#group-form-list=v1) | a text that matches the production `group-name`, such as `no-privilege`, that stands for a need; the member `needs` of a vector object holds texts of this form, and the forms of the group give the need that each of them stands for, if any |
| [message](sinter:#message=v1) | a text for people, not empty, with no line feed and no carriage return, whose words the program that gives it chooses |
| [`@ack` line](sinter:identifiers#ack-line=v1) | a tag line with the tag word `@ack`, then a slug, then, as an option, a text that matches the production `subject`, then a hash prefix of 8 to 64 hex digits, such as `@ack old-word docs/guide.md@L3C5 3f2a9c1d`; a text that matches `subject` is not empty and does not start or end with a space or a tab |
| [subject of a finding](sinter:#finding-subject=v1) | the text that names what a finding is about; it matches the production `subject` of the schema `ack-line` of Identifiers and holds no line feed |
| [finding id](sinter:#finding-id=v1) | the text `finding:`, then the slug that names the finding class of a finding, then `:`, then the subject of the finding |
| [same finding](sinter:#same-finding=v1) | two findings are the same finding when, and only when, the slugs that name their finding classes are the same text and their subjects are the same text, in any tree and in any execution of a program |
| [spot](sinter:#spot=v1) | a valid path of a file of a tree, alone, or, when the content of the file is valid UTF-8, with a span of the text of that content that starts at no boundary inside a line ending and ends at no boundary inside a line ending |
| [inside a line ending](sinter:#spot=v1) | a boundary is inside a line ending when a line ending starts before it and ends after it: the boundary between the carriage return and the line feed of a line ending |
| [start position](sinter:#start-position=v1) | the start of the span of a spot: the position of the boundary where that span starts |
| [position after a spot](sinter:#position-after-spot=v1) | the position of the boundary where the span of a spot ends; it is not always the end of the span |
| [spot from one position to another](sinter:#positioned-spot=v1) | the spot that has a given text as its valid path, the first position as its start position, and the second position as the position after the spot, when the tree has such a spot |
| [related message](sinter:#related-message=v1) | a message, alone or with a spot in a tree, that helps to explain a finding; when the related message has a spot, the tree of that spot can be another tree than the tree in which the finding reports its condition; the related messages of a finding are a set, and two of them are the same when they have the same message and either no spot or the same spot in the same tree |
| [mark of a spot](sinter:#mark=v1) | for a spot S with a span, a spot M with a span, and a message, where the span of M lies in the span of S and on the line where the span of S starts; S has no mark when the boundary where the span of S starts is a boundary of no line |
| [edit](sinter:#edit=v1) | a spot with a span, together with a text, its new text |
| [edit set](sinter:#edit-set=v1) | one or more edits in one tree, in which, for each two edits at the same valid path, exactly one of the two spans ends at or before the boundary where the other starts |
| [edited text](sinter:#edited-text=v1) | for an edit set and the valid path of one edit of that edit set, the text of the content of the file at that valid path, with the text of the span of each edit at that valid path replaced by the new text of that edit |
| [edited tree](sinter:#edited-tree=v1) | the tree with the same valid paths as the tree of an edit set, in which the content of the file at each valid path of an edit of the set is the UTF-8 encoding of the edited text of that valid path, and each other file has the content of that file in the tree of the edit set |
| [make the edits of an edit set](sinter:#fix=v1) | change the files of the tree of the edit set into the files of the edited tree, with no file added or removed |
| [edit description](sinter:#edit-description=v1) | a text (its path), a first position, a second position, and a text (its new text); an edit description can describe the edit of the spot from the first position to the second position at that path, with that new text |
| [describe an edit set](sinter:#edit-set-description=v1) | a finite sequence of edit descriptions describes an edit set in a tree when it has one or more edit descriptions, each edit description of the sequence describes an edit in that tree, no two edit descriptions of the sequence describe the same edit, and these edits are the edits of an edit set in that tree |
| [fix](sinter:#fix=v1) | a message and one or more edit sets in one tree, where no two of those edit sets are the same and those edit sets have numbers from 1; to make a fix is to make the edits of exactly one of its edit sets |
| [acknowledge](sinter:#acknowledgment=v1) | a person acknowledges a finding when the person says that they know of the finding and that it may stay |
| [acknowledgment](sinter:#acknowledgment=v1) | what a person says when the person acknowledges a finding |
| [add an acknowledgment](sinter:#added-acknowledgment=v1) | an edit set in a tree adds an acknowledgment of a finding when the edited tree of the edit set records an acknowledgment of the finding by a person and the tree of the edit set does not record that acknowledgment |
| [ackable](sinter:#ackable-finding=v1) | a finding is ackable when an acknowledgment of it by a person can have effect |
| [parts of a finding](sinter:#finding-part=v1) | its tree, its finding class, its subject, its message, its spot, its mark, its related messages, its fix, and whether it is ackable, with the parts of these parts |
| [tree of a finding](sinter:#finding-part=v1) | the tree in which a finding reports its condition, or no tree |
| [correct](sinter:#correction=v1) | an edit set in a tree corrects a finding of that tree when, in the edited tree of the edit set, the condition that the finding reports no longer holds for what the finding is about, wherever the edits move that thing |

## 2. Findings, spots, edits, and fixes

### 2.1 The parts of a finding

A finding is a report of one condition at one part of a repository. Its
finding class is the kind of finding, which a slug names. Each finding
has the parts that the term `finding-part` gives, such as its subject,
its message, and its spot. The parts of a finding can have parts of
their own.

For example, the finding class `no-test` reports an item of the kind
requirement that no test cites. In a tree, the tag line
`@req due-date=v2` on line 41 of `docs/designs/billing.md` declares the
item of the kind requirement `billing#due-date`. In that tree, no test
cites that item. The finding has these parts:

| part | this finding |
|---|---|
| tree | that tree |
| finding class | `no-test` |
| subject | `billing#due-date` |
| message | `no test cites this requirement` |
| spot | `docs/designs/billing.md`, from line 41, column 1 to line 41, column 17 |
| mark | from line 41, column 6 to line 41, column 14, the text `due-date`, with the message `cited by no test` |
| related messages | none |
| fix | none |
| ackable | ackable |

A message is a text for people. A message is not empty. A message holds
no line feed and no carriage return. Therefore, a message holds no line
ending. The program that gives a message chooses the words of that
message. Therefore, two conforming programs can give the same finding
with different messages.

The subject of a finding names what the finding is about. The subject of
a finding matches the production `subject` of the form of `@ack` lines
and holds no line feed. Therefore, an `@ack` line can hold the subject
of each finding. So a subject is not empty, and it does not start or end
with a space or a tab. A subject that names an item, such as
`billing#due-date`, stays the same when lines move in a file. A thing
that no name names, such as one word on one line, can have a subject
that holds the valid path of the file of that thing and the position of
that thing, such as `docs/guide.md@L3C5`. Such a subject changes when
lines move.

### 2.2 Spots and their positions

A spot is a valid path of a file of a tree, alone or with a span of the
text of the content of that file. A spot with a span shows a run of the
text of the content of a file, such as one tag line. A spot without a
span shows a whole file, such as a file whose content is not valid UTF-8
and so has no text. Only a file whose content is valid UTF-8 has spots
with spans.

The span of a spot starts and ends at boundaries of the body. That span
starts at no boundary inside a line ending and ends at no boundary
inside a line ending. A boundary is inside a line ending when a line
ending starts before that boundary and ends after that boundary. A
boundary inside a line ending is the boundary between the carriage
return and the line feed of a line ending.

The start position of a spot is the position of the boundary where the
span of the spot starts. The position after a spot is the position of
the boundary where the span of the spot ends. The start position is
always the start of the span. The position after a spot is not always
the end of the span. The end of the span is the position of the boundary
right after the last place of the span that is a place of a line, or the
start of the span when the span has no such place. The position after
the spot and the end of the span differ only when the span is not empty
and ends right after a line ending. When the span ends right after a
line ending, the position after the spot has the column 1, and a line
number 1 more than the line number of the line before that line ending.
A valid path and two positions name the spot from the first position to
the second position at that valid path, when the tree has such a spot.
The tree has at most one such spot.

The examples show a span as the boundary where it starts, "to", and the
boundary where it ends, such as "1 to 4":

| text | span | start position | position after the spot |
|---|---|---|---|
| `abc` | 1 to 2 | line 1, column 2 | line 1, column 3 |
| `ab`, a line feed, `cd` | 1 to 4 | line 1, column 2 | line 2, column 2 |
| `ab`, a line feed, `cd` | 0 to 3 | line 1, column 1 | line 2, column 1 |
| `ab`, a carriage return, a line feed, `cd` | 2 to 4 | line 1, column 3 | line 2, column 1 |
| `a`, a line feed | 0 to 2 | line 1, column 1 | line 2, column 1 |
| U+FEFF, `x` | 1 to 2 | line 1, column 1 | line 1, column 2 |

In the text `ab`, a line feed, `cd`, the span 0 to 3 ends right after
the line ending, so the position after the spot is line 2, column 1, and
the end of the span is line 1, column 3. In the text `ab`, a carriage
return, a line feed, `cd`, boundary 3 is inside a line ending, so no
span of a spot starts or ends there. Boundary 2 and boundary 3 have the
same position, line 1, column 3. That position names boundary 2. In the
text `a`, a line feed, the position after the spot with the span 0 to 2
is line 2, column 1, although the text has only one line. A spot without
a span has no start position, and there is no position after that spot.

### 2.3 Marks and related messages

The mark of a finding is a mark of its spot: a spot with a span, and a
message. The span of the spot of the mark is the run of the span of the
spot of the finding that is at fault, such as the name or the revision
of a tag line. The spot of the mark is in the same file. The span of the
spot of the mark starts and ends at boundaries of the span of the spot
of the finding, and at boundaries of the line on which the span of the
spot of the finding starts. The message of the mark says what is wrong
there. A finding has a mark only when its spot has a span. When the
boundary where the span of the spot of the finding starts is a boundary
of no line, that spot has no mark.

A related message of a finding is a message, alone or with a spot, that
helps to explain the finding. The spot of a related message is in the
tree of the finding or in another tree, such as an earlier tree of the
repository. The tree of that spot is a part of the related message. For
example, a finding about a citation that names an old revision can have,
as a related message, the message `declared here` with the spot of the
declaration of the item that the citation names. A related message
without a spot can tell of something that is in no file, such as an
entry of the ledger. The related messages of a finding are a set. That
set is also a part of the finding. Those related messages have no order.
No two of those related messages are the same message with the same spot
in the same tree, or the same message with no spot.

### 2.4 Edits and edit sets

An edit is a spot with a span, together with a text, its new text,
which replaces the text of the span (term `edit`).

An edit set is one or more edits in one tree, such as two edits at one
valid path, one after the other (term `edit-set`).

The edited text of a valid path, and the edited tree of an edit set, are
the text and the tree that the edits of the set give (terms
`edited-text` and `edited-tree`).

An edit description is a path, two positions, and a new text, which
describe the edit of the spot from the first position to the second
position at the path, when the tree has that spot (term
`edit-description`).

In the examples, each edit description has the valid path of the one
file. In the examples, each edit description shows its first position
and its second position as "line:column", and shows its new text. When
the edit description describes an edit, the first position and the
second position of the edit description are the start position of the
spot of the edit and the position after that spot.

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
of a fix have numbers from 1, in their order. No two edit sets of a fix
are the same set. The message of the fix says what the fix does. To make
a fix is to make the edits of exactly one of its edit sets. So when a
fix has two or more edit sets, someone chooses one of them. The fix of a
finding is a fix in the tree of the finding.

An edit set in a tree corrects a finding of that tree when, in the
edited tree of the edit set, the condition that the finding reports no
longer holds for what the finding is about. The edits can move that
thing, such as a word that a new line above it moves down one line. An
edit set corrects a finding only when the condition no longer holds for
the thing itself, wherever the edits move it. So a new line above the
word does not correct the finding: the condition still holds for the
word after the move.

A person acknowledges a finding when the person says that they know of
the finding and that it may stay. What the person says is an
acknowledgment of the finding. An edit set in a tree adds an
acknowledgment of a finding when the edited tree of the edit set records
an acknowledgment of the finding by a person and the tree of the edit
set does not record that acknowledgment. A finding is ackable when an
acknowledgment of it by a person can have effect. An acknowledgment of a
finding that is not ackable has no effect. Each edit set of the fix of a
finding corrects the finding, or adds an acknowledgment of it when the
finding is ackable.

For example, the finding class `old-word` reports a word that a word
list replaces. Line 3 of `docs/guide.md` is `The stamp comes last.`. The
word list replaces `stamp` with `approval`. The finding has the spot
from line 3, column 1 to line 3, column 22, and the mark from line 3,
column 5 to line 3, column 10. Its fix has one edit set, with one edit
at `docs/guide.md`, from line 3, column 5 to line 3, column 10, with the
new text `approval`. After the edit, line 3 is
`The approval comes last.`, and the condition no longer holds. If the
word list gave two words for `stamp`, the fix would have two edit sets,
one for each word.

### 2.6 The identity of a finding

The finding id of a finding is made from the slug that names its
finding class and from its subject, such as
`finding:no-test:billing#due-date` for the finding of the class
`no-test` with the subject `billing#due-date` (term `finding-id`).

Two findings with the same slug and the same subject are the same
finding, in any tree and in any execution (term `same-finding`).
Therefore, a finding whose subject does not change stays the same
finding when lines move in a file.

In one execution, a conforming program never gives two different things
as one part of two findings with the same slug and the same subject,
when both are findings of one tree or both are findings of no tree, such
as one finding that it gives once in a text for people and once in a
JSON text (requirement `give-consistent-findings`). What a program gives
when its input changes while it runs is a matter of quality of
implementation.

## 3. Definitions

### 3.1 Messages

@term message=v1
@cites text#{text=v1, line-feed=v1, carriage-return=v1}

A message is a text for people that is not empty and that holds no line
feed and no carriage return. The program that gives a message chooses
the words of that message.

### 3.2 Subjects of findings

@term finding-subject=v1
@cites {
    identifiers#{ack-line=v1},
    text#{text=v1, line-feed=v1, production=v1, code-span=v1},
    ontology#{finding-class=v1},
}

Each finding has exactly one subject: a text that names what the
finding is about, that matches the production `subject` of the schema
`ack-line` of Identifiers, and that holds no line feed.

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
        boundary=v1, body=v1, line-ending=v1,
    },
    ontology#{tree=v1},
}

A boundary of a text is inside a line ending when, and only when, a line
ending of the text starts before that boundary and ends after it. A spot
in a tree is the valid path of a file of the tree, alone, or, when the
content of that file is valid UTF-8, together with a span of the text of
that content that starts at no boundary inside a line ending and ends at
no boundary inside a line ending.

### 3.6 Start positions

@term start-position=v1
@cites {text#{span=v1}, #{spot=v1}}

The start position of a spot with a span is the start of its span. A
spot without a span has no start position.

### 3.7 Positions after spots

@term position-after-spot=v1
@cites {text#{position=v1, boundary=v1, span=v1}, #{spot=v1}}

The position after a spot with a span is the position of the boundary
where its span ends. There is no position after a spot without a span.

### 3.8 Positioned spots

@term positioned-spot=v1
@cites {
    files#{path=v1},
    text#{position=v1, text=v1},
    ontology#{tree=v1},
    #{spot=v1, start-position=v1, position-after-spot=v1},
}

For a text p and two positions s and a, the spot from s to a at p in a
tree is the spot in that tree whose valid path is p, whose start
position is s, and for which the position after the spot is a, when that
tree has such a spot.

### 3.9 Related messages

@term related-message=v1
@cites {ontology#{finding-class=v1, tree=v1}, #{message=v1, spot=v1}}

A related message of a finding is a message, alone or together with a
spot in a tree, that helps to explain the finding. When a related
message of a finding has a spot, the tree of that spot can be another
tree than the tree in which that finding reports its condition. The
related messages of a finding are a finite set. That set can be empty.
The related messages of a finding have no order. No two related messages
of a finding are the same message with the same spot in the same tree,
and no two related messages of a finding are the same message with no
spot.

### 3.10 Marks

@term mark=v1
@cites {
    files#{path=v1},
    text#{span=v1, boundary=v1, run=v1, line=v1},
    ontology#{tree=v1},
    #{message=v1, spot=v1},
}

Let S be a spot with a span in a tree T, and let b be the boundary where
the span of S starts. When b is a boundary of no line, S has no mark.
Otherwise, let L be the line of which b is a boundary. A mark of S is a
spot M in T and a message. M has the valid path of S. M has a span. The
span of M starts and ends at boundaries of the span of S, and at
boundaries of L.

### 3.11 Edits

@term edit=v1
@cites {text#{text=v1, span=v1}, ontology#{tree=v1}, #{spot=v1}}

An edit in a tree is a spot in the tree that has a span, together with a
text, the new text of the edit. The span of the edit is the span of its
spot.

### 3.12 Edit sets

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

### 3.13 Edited texts

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

For an edit set in a tree and a valid path p of one of the edits of that
edit set, let t be the text of the content of the file at p. Let e1, …,
en be the edits of that edit set whose spots have the valid path p, in
the order in which the span of each edit ends at or before the boundary
where the span of the next edit starts. The edited text of p for the
edit set is one text that consists of these texts in order, with nothing
between them:

1. the text of the run of t from boundary 0 to the boundary where the span of e1 starts;
2. when n is greater than 1, for each k from 1 to n - 1, the new text of ek, and then the text of the run of t from the boundary where the span of ek ends to the boundary where the span of ek+1 starts;
3. the new text of en, and then the text of the run of t from the boundary where the span of en ends to the last boundary of t.

### 3.14 Edited trees

@term edited-tree=v1
@cites {
    files#{path=v1},
    text#{utf-8-encoding=v1},
    ontology#{tree=v1},
    #{edit=v1, edit-set=v1, edited-text=v1},
}

The edited tree of an edit set in a tree is the tree that has a file at
each valid path at which that tree has a file, and no other file. The
content of each file at a valid path of an edit of the set is the UTF-8
encoding of the edited text of that valid path for the edit set, and the
content of each other file is its content in that tree.

### 3.15 Edit descriptions

@term edit-description=v1
@cites {
    text#{text=v1, position=v1},
    ontology#{tree=v1},
    #{positioned-spot=v1, edit=v1},
}

An edit description is a text, its path; a first position; a second
position; and a text, its new text. An edit description describes an
edit in a tree when, and only when, that tree has the spot from the
first position of the edit description to the second position of the
edit description at the path of the edit description. When that tree has
that spot, the edit that the edit description describes is that spot,
with the new text of the edit description as the new text of that edit.

### 3.16 Descriptions of edit sets

@atom edit-set-description=v1
@cites {
    ontology#{tree=v1},
    text#{result=v1},
    #{edit-description=v1, edit=v1, edit-set=v1},
}

A finite sequence of edit descriptions describes an edit set in a tree
when, and only when, it has one or more edit descriptions, each edit
description of the sequence describes an edit in that tree, no two edit
descriptions of the sequence describe the same edit, and these edits are
the edits of an edit set in that tree, which is the edit set that the
sequence describes. For a tree and a finite sequence of edit
descriptions, the result for whether the sequence describes an edit set
in the tree is "valid" when it does, and "invalid" when it does not.

### 3.17 Fixes

@term fix=v1
@cites {
    files#{path=v1},
    ontology#{tree=v1},
    #{message=v1, edit-set=v1, edited-tree=v1},
}

To make the edits of an edit set in a tree is to change the files of
that tree into the files of the edited tree of the edit set. That change
gives the file at each valid path the content of the file at that valid
path in the edited tree. That change adds no file and removes no file. A
fix in a tree is a message and a finite sequence of one or more edit
sets in that tree. The message of the fix says what the fix does. No two
edit sets in that sequence are the same set. The edit sets of a fix have
numbers from 1, in their order. To make a fix in a tree is to make the
edits of exactly one of the edit sets of that fix in that tree.

### 3.18 Acknowledgments

@term acknowledgment=v1
@cites ontology#{finding-class=v1, person=v1}

A person acknowledges a finding when, and only when, the person says
that they know of the finding and that it may stay. What the person then
says is an acknowledgment of the finding by that person.

### 3.19 Added acknowledgments

@term added-acknowledgment=v1
@cites {
    ontology#{finding-class=v1, person=v1, tree=v1},
    #{edit-set=v1, edited-tree=v1, acknowledgment=v1},
}

An edit set in a tree adds an acknowledgment of a finding when, and only
when, its edited tree records an acknowledgment of the finding by a
person that the tree does not record.

### 3.20 Ackable findings

@term ackable-finding=v1
@cites {ontology#{finding-class=v1, person=v1}, #{acknowledgment=v1}}

A finding is ackable when, and only when, an acknowledgment of the
finding by a person can have effect.

### 3.21 The parts of a finding

@term finding-part=v1
@cites {
    identifiers#{slug=v1},
    files#{path=v1},
    text#{span=v1, run=v1},
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
- its finding class, by the slug that names that finding class;
- its subject;
- its message: a message that says what is wrong;
- its spot: one spot in the tree of the finding, or no spot; when the
  finding has a spot, that spot shows where the finding is; a finding of
  no tree has no spot;
- its mark: one mark of the spot of the finding, or no mark; when the
  finding has a mark, the span of that mark is the run of the span of
  the spot of the finding that is at fault, and the message of that mark
  says what is wrong there; a finding has no mark when the finding has
  no spot, when the spot of the finding has no span, or when the spot of
  the finding has no mark;
- the set of its related messages, and each of its related messages;
- its fix: one fix in its tree, or no fix; a finding of no tree has no
  fix;
- whether it is ackable.

When a finding has no tree, no spot, no mark, or no fix, that part of
the finding is none. Each part of a part of a finding is also a part of
the finding. The parts of a spot are its valid path and, when the spot
has a span, that span. The parts of a mark are its spot and its message.
The parts of a related message are its message and, when the related
message has a spot, that spot and the tree of that spot. The parts of a
fix are the message of the fix and each edit set of the fix, each with
the number of that edit set. The parts of an edit set are the set of its
edits and each of its edits. The parts of an edit are its spot and its
new text.

### 3.22 Corrections

@term correction=v1
@cites {
    ontology#{finding-class=v1, tree=v1},
    #{edit-set=v1, edited-tree=v1, finding-part=v1},
}

An edit set in a tree corrects a finding of that tree when, and only
when, in the edited tree of the edit set, the condition that the finding
reports no longer holds for what the finding is about, wherever the
edits of the edit set move that thing.

## 4. Requirements

### 4.1 The parts of each finding

@req give-finding-parts=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{finding-class=v1},
    #{finding-part=v1},
}

When a conforming program gives something as a part of a finding, and
that finding has that part, the conforming program must give that part
of that finding, and nothing else, as that part.

### 4.2 No part that a finding does not have

@req omit-absent-finding-parts=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{finding-class=v1},
    #{finding-part=v1},
}

A conforming program must give nothing as a part of a finding when that
finding does not have that part.

### 4.3 Finding ids

@req give-finding-ids=v1
@cites {
    conformance#{conforming-program=v1},
    text#{text=v1},
    ontology#{finding-class=v1},
    #{finding-id=v1},
}

When a conforming program gives a text as the finding id of a finding,
it must give the finding id of that finding, and no other text, as the
finding id of that finding.

### 4.4 One set of parts for each finding

@req give-consistent-findings=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    ontology#{finding-class=v1, tree=v1},
    #{same-finding=v1, finding-part=v1},
}

In one execution in which the input of a conforming program does not
change, that conforming program must give no two different things as the
same part of two findings that are the same finding and that are both of
one tree or both of no tree.

### 4.5 The start positions of spots

@req give-start-positions=v1
@cites {
    conformance#{conforming-program=v1},
    text#{position=v1, line-number=v1},
    #{spot=v1, start-position=v1},
}

When a conforming program gives a line number for the start position of
a spot, it must give the line number of the start position of that spot,
and no other line number, for that start position. When a conforming
program gives a column for the start position of a spot, it must give
the column of the start position of that spot, and no other column, for
that start position.

### 4.6 The positions after spots

@req give-positions-after-spots=v1
@cites {
    conformance#{conforming-program=v1},
    text#{position=v1, line-number=v1},
    #{spot=v1, position-after-spot=v1},
}

When a conforming program gives a line number for the position after a
spot, it must give the line number of the position after that spot, and
no other line number, for that position. When a conforming program gives
a column for the position after a spot, it must give the column of the
position after that spot, and no other column, for that position.

### 4.7 No positions for a spot without a span

@req omit-positions-without-spans=v1
@cites {
    conformance#{conforming-program=v1},
    text#{position=v1, line-number=v1, span=v1},
    #{spot=v1, start-position=v1, position-after-spot=v1},
}

A conforming program must give no line number and no column as the start
position of a spot that has no span, or as the position after that
spot.

### 4.8 The validation of edit sets

@req validate-edit-sets=v1
@cites {
    conformance#{conforming-program=v1},
    text#{result=v1},
    ontology#{tree=v1},
    #{edit-description=v1, edit-set-description=v1, edit-set=v1},
}

For each tree and each finite sequence of edit descriptions, a
conforming program that gives a result for whether the sequence
describes an edit set in the tree must give exactly one result: "valid"
when the sequence describes an edit set in the tree, and "invalid" when
the sequence does not describe an edit set in the tree.

### 4.9 The edited texts of edit sets

@req give-edited-texts=v1
@cites {
    files#{path=v1},
    conformance#{conforming-program=v1},
    text#{text=v1},
    ontology#{tree=v1},
    #{
        edit-description=v1, edit-set-description=v1, edit-set=v1,
        edited-text=v1,
    },
}

When a conforming program gives a text as the edited text of a valid
path for an edit set in a tree, the conforming program must give the
edited text of that valid path for that edit set, and no other text.
When a conforming program gives a text as the edited text of a valid
path for a finite sequence of edit descriptions that describes an edit
set in a tree, the conforming program must give the edited text of that
valid path for that edit set, and no other text.

### 4.10 No other edited text

@req omit-edited-texts=v1
@cites {
    files#{path=v1},
    conformance#{conforming-program=v1},
    text#{text=v1},
    ontology#{tree=v1},
    #{
        edit-description=v1, edit-set-description=v1, edit=v1,
        edit-set=v1, edited-text=v1,
    },
}

For each tree and each text p, a conforming program must give a text as
the edited text of p for an edit set in the tree only when p is the
valid path of an edit of that edit set. For each tree and each text p, a
conforming program must give a text as the edited text of p for a finite
sequence of edit descriptions only when the sequence describes an edit
set in the tree and p is the path of an edit description of the
sequence.

### 4.11 The edit sets of fixes

@req limit-fix-edit-sets=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{finding-class=v1},
    #{
        finding-part=v1, fix=v1, edit-set=v1, correction=v1,
        added-acknowledgment=v1, ackable-finding=v1, same-finding=v1,
    },
}

For a finding F, a conforming program must give, as an edit set of the
fix of F, only an edit set that adds no acknowledgment of a finding that
is not the same finding as F. For a finding F, a conforming program must
give, as an edit set of the fix of F, only an edit set that corrects F
or, when F is ackable, adds an acknowledgment of F.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 4.

The vectors of this design are in the file
[`findings.test-vectors.jsonl`](findings.test-vectors.jsonl), in the
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives a test-vector set. A vector is an input and what a
conforming program gives for that input. Each vector follows from the
requirements and adds nothing to them. The vectors are in groups. Each
group has a name, such as `edit-sets`, and a schema below. That schema
gives the forms of the group: the requirements that the vectors of the
group follow from, and the inputs, results, and values of those vectors.
No group of this design uses a need, so the forms of each group give no
need names. These requirements have no vectors: `give-finding-parts`,
`omit-absent-finding-parts`, `give-consistent-findings`, and
`limit-fix-edit-sets`.

### 5.1 The edits of edit sets

@schema edit-set-vector=v1
@cites {
    conformance#{conforming-program=v1},
    text#{
        text=v1, character=v1, line-feed=v1, whole-number=v1,
        decimal-numeral=v1, 0x-numeral=v1, boundary=v1, position=v1,
        line-number=v1, sequence=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1, result=v1, code-span=v1,
    },
    files#{path=v1},
    ontology#{tree=v1},
    data-forms#{
        json-value=v1, hex-text=v1, vector-line=v1,
        group-form-list=v1, vector-meaning=v1,
    },
    #{
        edit-description=v1, edit-set-description=v1, edit-set=v1,
        edited-text=v1, validate-edit-sets=v1, give-edited-texts=v1,
        omit-edited-texts=v1,
    },
}

Inside the members `input`, `result`, and `values`, each JSON value that
the forms of this group name as a text, a whole number, a position, a
sequence, or a tree has this form:

- A text, such as a result, a valid path, a new text, or an edited text,
  is a JSON string whose characters are the characters of the text, in
  order. So the text `a`, a line feed, `b` is `"a\nb"`, and the empty
  text is `""`.
- A whole number, such as a boundary, a line number, or a column, is a
  JSON number written as the decimal numeral of that whole number, such
  as `12`.
- A position is a JSON object with two members: `line`, the line number
  of the position, and `column`, the column of the position. So the
  position line 3, column 7 is `{"column":7,"line":3}`.
- A sequence is a JSON array of its elements, in order.
- A tree is a JSON object with one member for each file of the tree. The
  key is the valid path of the file. When the content of the file is
  valid UTF-8, the value is the text of that content, as a JSON string.
  When the content of the file is not valid UTF-8, the value is a JSON
  object with one member, `bytes`: the
  [hex text](sinter:data-forms#hex-text=v1) of the content, as a JSON
  string, such as `{"bytes":"ff"}` for the content 0xFF.

The group `edit-sets` holds the vectors of the requirements
`validate-edit-sets`, `give-edited-texts`, and `omit-edited-texts`. Each
vector gives a tree, a sequence of edit descriptions, and what a
conforming program gives for that tree and that sequence.

- `input`: a JSON object with two members. `files` is the tree. `edits`
  is the sequence of edit descriptions, which can be empty. Each edit
  description in `edits` is a JSON object with four members: `path`, the
  path of the edit description, as a text; `start`, the first position;
  `after`, the second position; and `new-text`, the new text.
- `result`: the result of the tree and the sequence together, when a
  conforming program gives a result for whether the sequence describes
  an edit set in the tree: "valid" when the sequence describes an edit
  set in the tree, and "invalid" when the sequence does not describe an
  edit set in the tree.
- `values`: with the result "valid", a JSON object with one member,
  `edited-texts`. With the result "valid", `edited-texts` is a JSON
  object with one member for each path of an edit description of the
  sequence: the key of that member is that path, and the value of that
  member is the edited text of that valid path for the edit set that the
  sequence describes. With the result "invalid", `values` is the empty
  JSON object, `{}`. Each vector of the group has the member `values`.

When a conforming program gives a result for whether the sequence
describes an edit set in the tree, the conforming program gives the
result that `result` holds, and no other result. A conforming program
gives a text as the edited text of a path for the sequence only when the
path is a key of `edited-texts`. When a conforming program gives a text
as the edited text of a path for the sequence, and the path is a key of
`edited-texts`, that text is the value of that key. When `values` is
`{}`, a conforming program gives no text as an edited text for the
sequence.

```
{"form":"#edit-set-vector=v1","group":"edit-sets","input":{"edits":[{"after":{"column":3,"line":1},"new-text":"X","path":"a.md","start":{"column":2,"line":1}}],"files":{"a.md":"abc"}},"result":"valid","values":{"edited-texts":{"a.md":"aXc"}}}
```

### 5.2 Finding ids

@schema finding-id-vector=v1
@cites {
    conformance#{conforming-program=v1},
    text#{text=v1, code-span=v1},
    identifiers#{slug=v1},
    ontology#{finding-class=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    #{
        edit-set-vector=v1, finding-subject=v1, finding-id=v1,
        give-finding-ids=v1,
    },
}

The group `finding-ids` holds the vectors of the requirement
`give-finding-ids`. Each vector gives the slug that names the finding
class of a finding, the subject of the finding, and the finding id of
the finding. Inside the members `input` and `values`, each JSON value
that the forms of this group name as a text, a slug, a subject, or a
finding id has the form of a text that `edit-set-vector` gives.

- `input`: a JSON object with two members: `class`, the slug that names
  the finding class, and `subject`, the subject.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `finding-id`: the finding id
  of the finding.

When a conforming program gives a text as the finding id of the finding,
the conforming program gives the text that `finding-id` holds, and no
other text.

```
{"form":"#finding-id-vector=v1","group":"finding-ids","input":{"class":"no-test","subject":"billing#due-date"},"values":{"finding-id":"finding:no-test:billing#due-date"}}
```

### 5.3 The positions of spots

@schema spot-position-vector=v1
@cites {
    conformance#{conforming-program=v1},
    text#{
        text=v1, whole-number=v1, run=v1, boundary=v1, span=v1,
        position=v1, line-number=v1, code-span=v1,
    },
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    #{
        edit-set-vector=v1, spot=v1, start-position=v1,
        position-after-spot=v1, give-start-positions=v1,
        give-positions-after-spots=v1, omit-positions-without-spans=v1,
    },
}

The group `spot-positions` holds the vectors of the requirements
`give-start-positions`, `give-positions-after-spots`, and
`omit-positions-without-spans`. Each vector gives the text of the
content of the file of a spot. When the spot has a span, the vector also
gives the span of the spot, the start position of the spot, and the
position after that spot. Inside the members `input` and `values`, each
JSON value that the forms of this group name as a text, a whole number,
or a position has the form that `edit-set-vector` gives. A run is a JSON
object with two members: `from`, the boundary where the run starts, and
`to`, the boundary where the run ends. So the run that starts at
boundary 1 and ends at boundary 4 is `{"from":1,"to":4}`.

- `input`: a JSON object with the member `text`, the text, and, for a
  spot with a span, the member `span`, the span of the spot, as a run.
  For a spot without a span, the object has no other member.
- `result`: no vector of the group has this member.
- `values`: for a spot with a span, a JSON object with two members:
  `start`, the start position of the spot, and `after`, the position
  after the spot. For a spot without a span, `values` is the empty JSON
  object, `{}`.

When a conforming program gives a line number for the start position of
the spot, the conforming program gives the line number of `start`, and
no other line number. When a conforming program gives a column for the
start position, the conforming program gives the column of `start`, and
no other column. When a conforming program gives a line number for the
position after the spot, the conforming program gives the line number of
`after`, and no other line number. When a conforming program gives a
column for the position after the spot, the conforming program gives the
column of `after`, and no other column. When `values` is `{}`, a
conforming program gives no line number and no column as the start
position of the spot or as the position after that spot.

```
{"form":"#spot-position-vector=v1","group":"spot-positions","input":{"span":{"from":0,"to":3},"text":"ab\ncd"},"note":"the span ends right after a line ending, so the position after the spot is in column 1 of line 2","values":{"after":{"column":1,"line":2},"start":{"column":1,"line":1}}}
```
