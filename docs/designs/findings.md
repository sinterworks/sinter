<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Findings
@design findings=v1
@cites {
    conformance=v1, text=v1, identifiers=v1, files=v1, data-forms=v1,
    ontology=v1,
}
Locations identify files and text spans in a tree, edit sets group text edits across files of a tree to produce edited texts and edited trees, and finding reports pair each reported condition with a finding ID, structured parts, and candidate fixes.

A finding reports a condition in a repository, such as a requirement
that no test cites. A location identifies a whole file or a span of
UTF-8 text in a tree, and line-and-column positions describe that span.
Edits replace spans in files of a tree and group into edit sets that
produce edited texts and an edited tree. A finding report pairs a
finding ID with a message and optional details such as a location, a
mark, related messages, and a fix.

## Locations and positions

@spec locations=v1

A location identifies a file in a tree, either as a whole file or as a
span of text within a UTF-8 file. Line-and-column positions describe
where a location's span starts and the position after the location,
including boundaries next to line endings and byte order marks.

### Definitions

#### Location

@term location=v1
@cites {
    files#path=v1,
    ontology#tree=v1,
    text#{
        text=v1, slice=v1, line=v1, position=v1, span=v1,
        valid-utf-8=v1, utf-8-text=v1,
    },
}

A boundary `b` of a `text` is **inside a line ending** when a line
ending of that text starts before `b` and ends after `b` (the boundary
between the carriage return and the line feed of a CRLF line ending).

A **location** in a `tree` is either:

- the valid `path` of a file of that tree alone (a location without a
  span); or
- the valid `path` of a file of that tree whose content is
  `valid-utf-8`, together with a `span` of the `utf-8-text` of that
  content whose start boundary and end boundary are not inside a line
  ending (a location with a span).

For a location with a span:

- The **start position** of the location is the start of its `span`
  (the `position` of the start boundary of that span).
- The **position after** the location is the `position` of the end
  boundary of its `span`.

A location without a span has no start position and no position after
it.

For a `text` `p` and two `position` values `s` and `a`, the **location
from `s` to `a` at `p`** in a `tree` is the unique location with a span
in that tree whose valid `path` is `p`, whose start position is `s`,
and for which the position after the location is `a`, when that tree
has such a location.

@example Start [positions](sinter:text#position=v1) and positions after
locations for [spans](sinter:text#span=v1) (written as
[slices](sinter:text#slice=v1) `(from, to)` of the
[text](sinter:text#text=v1)) across [lines](sinter:text#line=v1), CRLF
line endings, trailing line feeds, and a leading
[byte order mark](sinter:text#body=v1):

| text | span slice | start position | position after the location |
|---|---|---|---|
| `abc` | `(1, 2)` | line 1, column 2 | line 1, column 3 |
| `ab`, U+000A, `cd` | `(1, 4)` | line 1, column 2 | line 2, column 2 |
| `ab`, U+000A, `cd` | `(0, 3)` | line 1, column 1 | line 2, column 1 |
| `ab`, U+000D, U+000A, `cd` | `(2, 4)` | line 1, column 3 | line 2, column 1 |
| `a`, U+000A | `(0, 2)` | line 1, column 1 | line 2, column 1 |
| U+FEFF, `x` | `(1, 2)` | line 1, column 1 | line 1, column 2 |

In `ab`, U+000A, `cd`, the span `(0, 3)` ends after the line ending, so
the position after the location is line 2, column 1 (whereas the end of
that [span](sinter:text#span=v1) is line 1, column 3). In `ab`, U+000D,
U+000A, `cd`, boundary 3 lies inside the CRLF line ending, so no
location's span starts or ends at boundary 3; although boundaries 2 and
3 share line 1, column 3, that position uniquely identifies boundary 2.
In `a`, U+000A, the position after `(0, 2)` is line 2, column 1 even
though the text has only one line.

### Returning location positions

@req give-location-positions=v1
@cites {
    conformance#conforming-program=v1,
    text#{position=v1, span=v1},
    #location=v1,
}

For a `location` with a `span`:

- When returning the line number of the start position of the location,
  a conforming program must return the 1-based line number of that
  start position.
- When returning the column of the start position of the location, a
  conforming program must return the 1-based column of that start
  position.
- When returning the line number of the position after the location, a
  conforming program must return the 1-based line number of that
  position.
- When returning the column of the position after the location, a
  conforming program must return the 1-based column of that position.

For a `location` without a `span`, a conforming program must return no
line number and no column as the start position of that location or as
the position after that location.

### Test vectors

@schema location-position-vector=v1
@cites {
    data-forms#{
        json-value=v1, vector-line=v1, test-vector-set=v1,
        group-schema=v1, vector-meaning=v1,
    },
    text#{utf-8-text=v1, slice=v1, span=v1, position=v1},
    #{location=v1, give-location-positions=v1},
}

`location-position-vector` is a `group-schema` for group
`location-positions` in
[findings.test-vectors.jsonl](findings.test-vectors.jsonl) and tests
`give-location-positions`. That file is a `test-vector-set` of
`vector-line` entries whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.text` | string | `utf-8-text` of the content of the file of a `location` |
| `input.span` | object (optional) | `span` of a `location` with a span; absent for a location without a span |
| `input.span.from` | integer (`>= 0`) | start boundary (`from`) of the `span`, as a boundary (`slice`) of `input.text` |
| `input.span.to` | integer (`>= 0`) | end boundary (`to`) of the `span`, as a boundary (`slice`) of `input.text` |
| `values.start.line` | integer (`>= 1`, optional) | 1-based line number of the location's start `position` |
| `values.start.column` | integer (`>= 1`, optional) | 1-based column of the location's start `position` |
| `values.after.line` | integer (`>= 1`, optional) | 1-based line number of the `position` after the location |
| `values.after.column` | integer (`>= 1`, optional) | 1-based column of the `position` after the location |

In `values`, `start` and `after` either both appear (each with both
`line` and `column`, representing the expected start position and
position after the location) or both are absent (`values` is `{}`,
representing no line number and no column for either position). Each
`json-value` object in `input` and `values` holds only the members
listed in this table.

@example Sample lines testing
[give-location-positions](sinter:#give-location-positions=v1) for
[positions](sinter:text#position=v1) of a
[location](sinter:#location=v1) with a [span](sinter:text#span=v1)
and a location without a span
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#location-position-vector=v1","group":"location-positions","input":{"span":{"from":0,"to":3},"text":"ab\ncd"},"note":"the span ends right after a line ending, so the position after the location is in column 1 of line 2","values":{"after":{"column":1,"line":2},"start":{"column":1,"line":1}}}
{"form":"#location-position-vector=v1","group":"location-positions","input":{"text":"abc"},"note":"a location without a span has no start position and no position after it","values":{}}
```

## Text edits and edit sets

@spec edits=v1

An edit replaces one span of UTF-8 text in a file of a tree with new
text. An edit set groups edits in one or more files of the same tree to
produce edited texts and an edited tree.

### Definitions

#### Edit

@term edit=v1
@cites {
    files#path=v1,
    text#{text=v1, span=v1},
    ontology#tree=v1,
    #location=v1,
}

An **edit** in a `tree` is a `location` in that `tree` that has a
`span`, together with a `text` (its **new text**). The **span** of an
edit is the span of its location, and the **valid path** of an edit is
the valid `path` of its location.

#### Edit set

@term edit-set=v1
@cites {
    files#path=v1,
    text#{slice=v1, span=v1},
    ontology#tree=v1,
    #edit=v1,
}

An **edit set** in a `tree` is a finite set of one or more `edit`s in
that `tree` such that, for every two distinct edits with the same valid
`path`, exactly one of the two `span`s ends at or before the boundary
(`slice`) where the other `span` starts.

#### Edited text

@term edited-text=v1
@cites {
    files#path=v1,
    text#{text=v1, slice=v1, span=v1, utf-8-text=v1},
    ontology#tree=v1,
    #{edit=v1, edit-set=v1},
}

For an `edit-set` in a `tree` and a valid `path` `p` of at least one
`edit` in that `edit-set`, let `t` be the `utf-8-text` of the content of
the file at `p`. Let `e1` through `en` be the `edit`s of that `edit-set`
at `p`, ordered so that for each `k` from `1` to `n - 1`, the `span` of
`ek` ends at or before the boundary (`slice`) where the `span` of the
next edit starts.

The **edited text** of `p` for that `edit-set` is the single `text`
formed by concatenating these `text` values in order:

1. the text of the `slice` of `t` from boundary `0` to the start
   boundary of the `span` of `e1`;
2. when `n > 1`, for each `k` from `1` to `n - 1`, the new text of `ek`
   followed by the text of the `slice` of `t` from the end boundary of
   the `span` of `ek` to the start boundary of the `span` of the next
   edit;
3. the new text of `en` followed by the text of the `slice` of `t` from
   the end boundary of the `span` of `en` to the last boundary of `t`.

#### Edited tree

@term edited-tree=v1
@cites {
    files#path=v1,
    text#utf-8-encoding=v1,
    ontology#tree=v1,
    #{edit=v1, edit-set=v1, edited-text=v1},
}

The **edited tree** of an `edit-set` in a `tree` is the `tree` that
holds a file at every valid `path` present in that `tree` and no other
file. For each valid `path` of an `edit` in the `edit-set`, the file's
content in the edited tree is the `utf-8-encoding` of the `edited-text`
of that valid `path` for that `edit-set`. Every other file in the edited
tree keeps its content from that `tree`.

#### Edit-set description

@atom edit-set-description=v1
@cites {
    text#{text=v1, position=v1},
    ontology#tree=v1,
    #{location=v1, edit=v1, edit-set=v1},
}

An **edit description** consists of these parts:

- a `text` (its **path**);
- a first pair of integers, a line number and a column (its **start
  pair**);
- a second pair of integers, a line number and a column (its **after
  pair**); and
- a `text` (its **new text**).

An edit description **describes an edit** in a `tree` when its start
pair and its after pair are `position` values and that `tree` has the
`location` from its start pair to its after pair at its path. When such
a `location` exists, the `edit` that the edit description describes is
that `location` paired with the edit description's new text.

A finite sequence of edit descriptions **describes an edit set** in a
`tree` when all of these conditions hold:

- The sequence holds at least one edit description.
- Each edit description in the sequence describes an `edit` in that
  `tree`.
- No two edit descriptions in the sequence describe the same `edit`.
- Those edits form an `edit-set` in that `tree` (the **edit set that
  the sequence describes**).

For a `tree` and a finite sequence of edit descriptions, the
`edit-set-description` result is `"valid"` when the sequence describes
an `edit-set` in that `tree`, and `"invalid"` otherwise.

@example Suppose a [tree](sinter:ontology#tree=v1) holds one file at
`a.md` with the text in the first column. Each edit description targets
`a.md`, writes its start pair and after pair
([positions](sinter:text#position=v1)) as `line:column`, and names its
new text. The table shows whether each sequence describes an
[edit set](sinter:#edit-set=v1) over [locations](sinter:#location=v1)
with [spans](sinter:text#span=v1) at [slice](sinter:text#slice=v1)
boundaries, together with the resulting
[edited text](sinter:#edited-text=v1):

| file text | edit descriptions | result | edited text |
|---|---|---|---|
| `abc` | `1:2` to `1:3`, `X` | `"valid"` | `aXc` |
| `abc` | `1:2` to `1:2`, `X` | `"valid"` | `aXbc` |
| `abc` | `1:2` to `1:3`, empty text | `"valid"` | `ac` |
| `abc` | `1:2` to `1:2`, `X`; `1:2` to `1:3`, `Y` | `"valid"` | `aXYc` |
| `a`, U+000A, `b`, U+000A | `1:1` to `2:1`, empty text | `"valid"` | `b`, U+000A |
| `ab`, U+000D, U+000A, `c` | `1:3` to `2:1`, empty text | `"valid"` | `abc` |
| `abc` | `1:2` to `1:2`, `X`; `1:2` to `1:2`, `Y` | `"invalid"` | none (two insertions at one boundary) |
| `abc` | `1:1` to `1:3`, `X`; `1:2` to `1:4`, `Y` | `"invalid"` | none (spans share `b`) |
| `abc` | `1:1` to `1:4`, `X`; `1:2` to `1:2`, `Y` | `"invalid"` | none (insertion inside the other span) |
| `abc` | `1:5` to `1:5`, `X` | `"invalid"` | none (no boundary at line 1, column 5) |

### Validating edit sets

@req validate-edit-sets=v1
@cites {
    conformance#conforming-program=v1,
    ontology#tree=v1,
    #{edit-set=v1, edit-set-description=v1},
}

When a conforming program validates whether a finite sequence of edit
descriptions describes an `edit-set` in a `tree`, the program must
return `"valid"` when the sequence describes an `edit-set` in that
`tree` (`edit-set-description`), and must return `"invalid"` otherwise.

### Returning edited texts

@req give-edited-texts=v1
@cites {
    conformance#conforming-program=v1,
    files#path=v1,
    text#text=v1,
    ontology#tree=v1,
    #{edit=v1, edit-set=v1, edited-text=v1, edit-set-description=v1},
}

When a conforming program returns the edited texts of an `edit-set` in a
`tree`, the program must return the `edited-text` of each valid `path`
of an `edit` in that `edit-set`, and must return no edited text for any
other `text`.

When a conforming program returns the edited text of a `text` `p` for an
`edit-set` in a `tree`, the program must return the `edited-text` of `p`
for that `edit-set` when `p` is the valid `path` of an `edit` in that
`edit-set`, and must return no edited text otherwise.

When a conforming program returns edited texts for a finite sequence of
edit descriptions (`edit-set-description`) in a `tree`:

- If the sequence describes an `edit-set` in that `tree`, the program
  must return the `edited-text` of each valid `path` of an `edit` in
  that `edit-set`, and must return no edited text for any other `text`.
- Otherwise, the program must return no edited text for any `text`.

### Test vectors

@schema edit-set-vector=v1
@cites {
    files#path=v1,
    text#{
        byte-sequence=v1, text=v1, valid-utf-8=v1, utf-8-text=v1,
        utf-8-encoding=v1,
    },
    data-forms#{
        json-value=v1, hex-text=v1, vector-line=v1, test-vector-set=v1,
        group-schema=v1, vector-meaning=v1,
    },
    ontology#tree=v1,
    #{
        edit=v1, edit-set=v1, edited-text=v1, edit-set-description=v1,
        validate-edit-sets=v1, give-edited-texts=v1,
    },
}

`edit-set-vector` is a `group-schema` for group `edit-sets` in
[findings.test-vectors.jsonl](findings.test-vectors.jsonl) and tests
`validate-edit-sets` and `give-edited-texts`. That file is a
`test-vector-set` of `vector-line` entries whose meaning follows
`vector-meaning`. Each `json-value` string represents a `text`, each
integer is a `json-value` integer, and each array represents a finite
sequence in order.

| field | type | meaning |
|---|---|---|
| `input.files` | object | input `tree`: each key is a valid `path`; each value is either a string (the `utf-8-text` of a `valid-utf-8` file content, representing its `utf-8-encoding`) or `{"bytes": "<hex>"}` (the `hex-text` of a non-`valid-utf-8` `byte-sequence` content) |
| `input.edits` | array of objects | finite sequence of edit descriptions (`edit-set-description`), possibly empty |
| `input.edits[].path` | string | edit description's path `text` |
| `input.edits[].start.line` | integer | line number of the edit description's start pair |
| `input.edits[].start.column` | integer | column of the edit description's start pair |
| `input.edits[].after.line` | integer | line number of the edit description's after pair |
| `input.edits[].after.column` | integer | column of the edit description's after pair |
| `input.edits[].new-text` | string | edit description's new `text` |
| `result` | string | `"valid"` when `input.edits` describes an `edit-set` in `input.files`, `"invalid"` otherwise |
| `values.edited-texts` | object (optional) | when `result` is `"valid"`, maps each valid `path` of an `edit` in that `edit-set` to its `edited-text` string (with no member for any other path); absent (`values` is `{}` for no edited text returned) when `result` is `"invalid"` |

Each `input`, `values`, `input.edits[]`, `start`, and `after` object
holds only the members listed in this table, and each
`{"bytes": "<hex>"}` object holds only `bytes`.

@example Sample lines testing
[validate-edit-sets](sinter:#validate-edit-sets=v1) and
[give-edited-texts](sinter:#give-edited-texts=v1) on valid and invalid
[edit-set-description](sinter:#edit-set-description=v1) inputs,
including a file whose content is not
[valid UTF-8](sinter:text#valid-utf-8=v1) encoded as
[hex-text](sinter:data-forms#hex-text=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#edit-set-vector=v1","group":"edit-sets","input":{"edits":[{"after":{"column":3,"line":1},"new-text":"X","path":"a.md","start":{"column":2,"line":1}}],"files":{"a.md":"abc"}},"result":"valid","values":{"edited-texts":{"a.md":"aXc"}}}
{"form":"#edit-set-vector=v1","group":"edit-sets","input":{"edits":[{"after":{"column":1,"line":1},"new-text":"x","path":"a.md","start":{"column":1,"line":1}}],"files":{"a.md":{"bytes":"ff"}}},"note":"the content of the file is not valid UTF-8, so no location in the file has a span","result":"invalid","values":{}}
```

## Finding reports and fixes

@spec finding-reports=v1

A finding reports one condition in a repository. Each finding has a
finding class, a subject, and a message. A finding can also have a
location, a mark, related messages, and a fix. A finding ID names a
finding, and a fix holds edit sets that a person can apply.

### Definitions

#### Message

@term message=v1
@cites text#{character=v1, text=v1}

A **message** is a non-empty `text` for people that holds no line feed
(U+000A) and no carriage return (U+000D). The program that returns a
message chooses the words of that message.

#### Finding subject

@term finding-subject=v1
@cites {
    identifiers#ack-line=v1,
    text#{character=v1, text=v1, production=v1},
    ontology#finding-class=v1,
}

Each finding has one **subject**: a `text` that names what the finding
is about, matches the `production` `subject` of `ack-line` in
Identifiers, and holds no line feed (U+000A).

#### Finding ID

@term finding-id=v1
@cites {
    identifiers#slug=v1,
    text#text=v1,
    ontology#{finding-class=v1, tree=v1},
    #finding-subject=v1,
}

The **finding ID** of a finding is the `text` formed by `finding:`, the
`slug` that names the finding's finding class, `:`, and the finding's
subject, in that order.

Two findings are the **same finding** when the slugs that name their
finding classes are equal texts and their subjects are equal texts. Two
findings of different trees or from different runs of a program are
still the same finding when their finding-class slugs and subjects are
equal texts.

#### Related message

@term related-message=v1
@cites {
    ontology#{finding-class=v1, tree=v1},
    #{location=v1, message=v1},
}

A **related message** of a finding is a `message`, alone or paired with
a `location` in a `tree`, that helps explain the finding. When a related
message has a location, that location can belong to any tree, including
a tree other than the finding's tree.

The related messages of a finding form an unordered finite set, which
can be empty. Two related messages are equal when they have equal
messages and either neither has a location or both have the same
location in the same tree.

#### Mark

@term mark=v1
@cites {
    files#path=v1,
    text#{slice=v1, line=v1, span=v1},
    ontology#tree=v1,
    #{location=v1, message=v1},
}

Let `S` be a `location` with a `span` in a `tree` `T`, and let `b` be
the start boundary of `S`'s span. When `b` is a boundary of no `line`,
`S` has no mark.

Otherwise, let `L` be the line of which `b` is a boundary. A **mark** of
`S` pairs a `location` `M` in `T` with a `message`, where:

- `M` has the same valid `path` as `S`;
- `M` has a `span`; and
- both the start boundary and the end boundary of `M`'s span are
  boundaries of `S`'s span and boundaries of `L`.

#### Fix

@term fix=v1
@cites {
    files#path=v1,
    ontology#tree=v1,
    #{edit-set=v1, edited-tree=v1, message=v1},
}

To **apply the edits** of an `edit-set` in a `tree` is to replace the
files of that tree with the files of the `edited-tree` of that edit set:
the file at each valid `path` receives its content in the edited tree,
with no file added and no file removed.

A **fix** in a `tree` pairs a `message` that states what the fix does
with a finite sequence of one or more `edit-set`s in that tree in which
no two edit sets are the same set. The edit sets of a fix have 1-based
numbers in sequence order. To **apply a fix** in a `tree` is to apply
the edits of exactly one of the fix's edit sets in that tree.

#### Ackable finding

@term ackable-finding=v1
@cites ontology#{finding-class=v1, person=v1}

A `person` **acknowledges** a finding when that person states that they
know of the finding and accept that the finding remains. What that
person states is an **acknowledgment** of the finding by that person.

A finding is **ackable** when an acknowledgment of the finding by a
person can have effect.

#### Finding part

@term finding-part=v1
@cites {
    identifiers#slug=v1,
    files#path=v1,
    text#{slice=v1, span=v1},
    ontology#{finding-class=v1, tree=v1, ledger=v1, log-branch=v1},
    #{
        location=v1, edit=v1, edit-set=v1, message=v1,
        finding-subject=v1, related-message=v1, mark=v1, fix=v1,
        ackable-finding=v1,
    },
}

The **parts of a finding** are these:

- **tree**: the `tree` in which the finding reports its condition, or no
  tree when the finding reports a condition outside every tree (such as
  a condition of the `log-branch` of the ledger);
- **finding class**: the `slug` that names the finding's finding class;
- **subject**: the finding's `finding-subject`;
- **message**: a `message` that states what is wrong;
- **location**: one `location` in the finding's tree, or no location;
  when present, that location shows where the finding is, and a finding
  of no tree has no location;
- **mark**: one `mark` of the finding's location, or no mark; when
  present, the mark's `span` is the `slice` of the finding location's
  span that is at fault, and the mark's message states what is wrong
  there; a finding has no mark when the finding has no location, when
  that location has no span, or when that location has no mark;
- **related messages**: the set of the finding's `related-message`s, and
  each related message in that set;
- **fix**: one `fix` in the finding's tree, or no fix; a finding of no
  tree has no fix;
- **ackable**: whether the finding is `ackable` (`ackable-finding`).

When a finding has no tree, no location, no mark, or no fix, that part
is absent. Each part of a part of a finding is also a part of that
finding:

| part | sub-parts |
|---|---|
| `location` | its valid `path` and, when present, its `span` |
| `mark` | its `location` and its `message` |
| `related-message` | its `message` and, when present, its `location` and that location's `tree` |
| `fix` | its `message` and each `edit-set` of the fix together with its 1-based number |
| `edit-set` | the set of its `edit`s and each `edit` in that set |
| `edit` | its `location` and its new text |

@example Suppose a [finding class](sinter:ontology#finding-class=v1)
`no-test` reports a requirement that no test cites. In a
[tree](sinter:ontology#tree=v1), line 41 of `docs/designs/billing.md`
holds `@req due-date=v2`, declaring `billing#due-date`, and no test
cites that requirement. Using the start
[position](sinter:text#position=v1) and the position after the location
for each [location](sinter:#location=v1), the finding has these parts:

| part | value |
|---|---|
| [tree](sinter:ontology#tree=v1) | that tree |
| [finding class](sinter:ontology#finding-class=v1) | `no-test` |
| [subject](sinter:#finding-subject=v1) | `billing#due-date` |
| [message](sinter:#message=v1) | `no test cites this requirement` |
| [location](sinter:#location=v1) | `docs/designs/billing.md`, from line 41, column 1 to line 41, column 17 |
| [mark](sinter:#mark=v1) | `docs/designs/billing.md`, from line 41, column 6 to line 41, column 14 (`due-date`), with message `cited by no test` |
| [related messages](sinter:#related-message=v1) | empty set |
| [fix](sinter:#fix=v1) | none |
| [ackable](sinter:#ackable-finding=v1) | ackable |

#### Path finding subject

@term path-finding-subject=v1
@cites {
    files#path=v1,
    text#{character=v1, text=v1, algorithm=v1},
    #finding-subject=v1,
}

A valid `path` **needs path encoding** when the valid path holds a line
feed (U+000A), starts with a space (U+0020) or a tab (U+0009), or ends
with a space (U+0020) or a tab (U+0009). The path-finding subject of a
valid path is a `finding-subject` for that valid path.

The path-finding subject of a valid path *f* is the text that these
steps give.

1. If *f* does not need path encoding, give *f*.
2. Let *s* be `/`.
3. For each *ch* of *f*, in order:
   1. Let *out* be *ch*.
   2. If *ch* is `%`, set *out* to `%25`.
   3. If *ch* is a line feed (U+000A), set *out* to `%0A`.
   4. If *ch* is a space (U+0020), set *out* to `%20`.
   5. If *ch* is a tab (U+0009), set *out* to `%09`.
   6. Append *out* to *s*.
4. Give *s*.

@example Path-finding subjects of [valid paths](sinter:files#path=v1) as
[finding subjects](sinter:#finding-subject=v1):

| valid path | path-finding subject |
|---|---|
| `docs/a.md` | `docs/a.md` |
| `100%.md` | `100%.md` |
| ` 100%.md` (leading space) | `/%20100%25.md` |
| `tmp.txt ` (trailing space) | `/tmp.txt%20` |
| `a`, U+000A, `b` | `/a%0Ab` |

### Returning finding parts

@req give-finding-parts=v1
@cites {
    conformance#conforming-program=v1,
    ontology#finding-class=v1,
    #finding-part=v1,
}

When a conforming program returns something as a part (`finding-part`)
of a finding that has that part, the program must return that part of
that finding. When a finding does not have a part, a conforming program
must return nothing as that part of that finding.

### Returning finding IDs

@req give-finding-ids=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    ontology#finding-class=v1,
    #finding-id=v1,
}

When a conforming program returns a `text` as the finding ID of a
finding, the program must return the `finding-id` of that finding.

### Returning consistent findings

@req give-consistent-findings=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    ontology#{finding-class=v1, tree=v1},
    #{finding-id=v1, finding-part=v1},
}

In one run in which the `input` of a conforming program does not change,
the program must not return two different values as the same
`finding-part` of two findings that are the same finding (`finding-id`)
and that are either both of the same `tree` or both of no tree.

### Limiting fix edit sets

@req limit-fix-edit-sets=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{finding-class=v1, person=v1, tree=v1},
    #{
        edit-set=v1, edited-tree=v1, finding-id=v1, fix=v1,
        ackable-finding=v1, finding-part=v1,
    },
}

An `edit-set` in a `tree` **corrects** a finding of that tree when, in
the `edited-tree` of that edit set, the condition that the finding
reports no longer holds for what the finding is about, wherever the
edits of the edit set move what the finding is about.

An `edit-set` in a `tree` **adds an acknowledgment** of a finding when
the `edited-tree` of that edit set records an acknowledgment
(`ackable-finding`) of that finding by a `person` that the tree does not
record.

For a finding `F`, a conforming program must return an `edit-set` in the
`fix` (`finding-part`) of `F` only when that edit set meets both of
these conditions:

- the edit set corrects `F`, or `F` is `ackable` (`ackable-finding`) and
  the edit set adds an acknowledgment of `F`; and
- the edit set adds no acknowledgment of any finding that is not the
  same finding (`finding-id`) as `F`.

@example Suppose a [finding class](sinter:ontology#finding-class=v1)
`old-word` reports a word that a word list replaces, and line 3 of
`docs/guide.md` is `The stamp comes last.`, where the word list replaces
`stamp` with `review`. A [fix](sinter:#fix=v1) can hold one
[edit set](sinter:#edit-set=v1) containing one [edit](sinter:#edit=v1)
at the [location](sinter:#location=v1) `docs/guide.md` from line 3,
column 5 to line 3, column 10 (its start
[position](sinter:text#position=v1) and its position after the
location), with new text `review`: in the
[edited tree](sinter:#edited-tree=v1), line 3 is
`The review comes last.` and the reported condition no longer holds.
If the word list listed two replacements for `stamp`, the fix could hold
two numbered edit sets, one for each replacement. By contrast, an edit
set that only inserts a blank line before line 3 moves `stamp` to line 4
without clearing the condition, so that edit set does not correct the
finding.

### Applying no fixes on unreadable files

@req apply-no-fixes-on-unreadable-files=v1
@cites {
    conformance#{conforming-program=v1, input=v1, safety-obligation=v1},
    files#directory=v1,
    ontology#tree=v1,
    #fix=v1,
}

In a run in which a conforming program could not read content of a file
or a `directory`, and that content is a part that an `input` lacks, that
conforming program must apply no `fix` in any `tree`.

### Test vectors

@schema finding-id-vector=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    identifiers#slug=v1,
    ontology#finding-class=v1,
    data-forms#{
        json-value=v1, vector-line=v1, test-vector-set=v1,
        group-schema=v1, vector-meaning=v1,
    },
    #{finding-subject=v1, finding-id=v1, give-finding-ids=v1},
}

`finding-id-vector` is a `group-schema` for group `finding-ids` in
[findings.test-vectors.jsonl](findings.test-vectors.jsonl) and tests
`give-finding-ids`. That file is a `test-vector-set` of `vector-line`
entries whose meaning follows `vector-meaning`. Both `input` and
`values` are `json-value` objects holding only the members listed in
this table.

| field | type | meaning |
|---|---|---|
| `input.class` | string | `slug` naming the finding's `finding-class` |
| `input.subject` | string | the finding's `finding-subject` |
| `values.finding-id` | string | expected `finding-id` text when a conforming program returns a text as the finding ID of that finding |

@example Sample lines testing
[give-finding-ids](sinter:#give-finding-ids=v1) with
[slug](sinter:identifiers#slug=v1),
[finding-subject](sinter:#finding-subject=v1), and
[finding-id](sinter:#finding-id=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#finding-id-vector=v1","group":"finding-ids","input":{"class":"no-test","subject":"billing#due-date"},"values":{"finding-id":"finding:no-test:billing#due-date"}}
{"form":"#finding-id-vector=v1","group":"finding-ids","input":{"class":"a","subject":"b:c"},"note":"a slug holds no :, so the first : after finding: ends the slug","values":{"finding-id":"finding:a:b:c"}}
```
