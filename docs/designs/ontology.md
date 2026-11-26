<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites {
    conformance=v1, data-forms=v1, files=v1, identifiers=v1, text=v1,
}
Sinter traces declared items, examples, vector sets, groups of conformance vectors, tests, sites, external items, work items, scope objects, computed identity objects, and records as canonical objects linked by typed edges, deriving item and work-item states from repository trees, the log branch, test evidence, and parameter bindings.

Sinter represents declared items, examples, work-item objects, computed
identity objects, group description objects, scope objects, and records
as canonical objects governed by one schema table. Each canonical object
has a content hash and a content ID, and two encodings store objects at
rest in a tree: text in files of the tree and canonical byte sequences
in files of `.sinter/`. Typed, directed edges connect objects and items
across trees, and pinned citation edges track specific revisions of
declared items. Statements in `.sinter/` and observations and kept
objects on the log branch form the ledger of a repository, and states
such as approved, retired, ready, and done depend only on canonical
objects and state inputs without depending on the order of records.

## Definitions

### Tree

@term tree=v1
@cites {
    files#{path=v1, directory=v1, directory-tree=v1},
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1,
        line=v1, text=v1,
    },
}

A **tree** is a set whose members are the **files of the tree**. A
**file of a tree** pairs a valid path (`files#path`) with a **content**,
which is a byte sequence (`text#byte-sequence`). No two files of a tree
have the same valid path.

A commit of a git repository has one tree, the **tree of the commit**. A
working tree of a git repository has one tree, the **tree of the working
tree**. A working tree of a git repository also has a directory tree
(`files#directory-tree`), holding directories (`files#directory`) and
files, in which the files of the tree of the working tree stand.

The **text of a file of a tree** is the UTF-8 text (`text#utf-8-text`)
of the content of that file when that content is valid UTF-8
(`text#valid-utf-8`). A **line of a file of a tree** is a line
(`text#line`) of that text, numbered by its 1-based line number. A
**file of `.sinter/` of a tree** is a file of that tree whose valid path
starts with `.sinter/` and does not start with `.sinter/local/`.

### Person

@term person=v1

A **person** is a human who works on a repository.

### Agent

@term agent=v1
@cites {text#text=v1, #person=v1}

An **agent** is a program that uses a language model to write texts
(`text#text`), such as code, as one person runs that program. Several
people can run one program, and each of them then runs a different
agent. Each agent acts for one person: the person who runs that agent.

### Default branch

@term default-branch=v1
@cites #person=v1

The **default branch** of a git repository is the branch into which the
people who work on the repository bring their work.

### Job

@term job=v1
@cites {
    conformance#conforming-program=v1,
    #{tree=v1, default-branch=v1, person=v1},
}

The **job** is an execution of a conforming program that runs after a
merge into the default branch of a repository. Continuous integration
can start the job on a push to the default branch or on a merged pull
request, using the continuous integration configuration in the tree of
the commit of the default branch that the push or the merge produces, or
a person can run the job by hand.

A **run of the job** covers commits of the default branch up to one
commit of the default branch, the **head of the run**. The **landing
commit** of a commit `c` is the commit on the first-parent line of the
default branch through which `c` joined that line: the commit on that
line that reaches `c` and either has no parent or has a first parent
that does not reach `c`.

### Parameter

@term parameter=v1
@cites {
    conformance#design=v1,
    identifiers#{external-namespaces=v1, part-name=v1},
}

A **parameter** is a word, such as `external-namespaces`, whose value a
design (`conformance#design`) leaves open. A **binding** of a parameter
is a value that configuration supplies for that parameter. When a design
declares a schema whose part name (`identifiers#part-name`) is the name
of a parameter, a binding of that parameter is valid when that binding
meets that schema, and invalid otherwise. A binding of
`external-namespaces` is a binding as `identifiers#external-namespaces`
defines that binding.

### Finding class

@term finding-class=v1
@cites identifiers#slug=v1

A **finding** is a report of one condition at one part of a repository.
A finding is a result and not an object. A **finding class** is a kind
of finding, named by a slug (`identifiers#slug`).

## Canonical objects and withdrawal

@spec objects=v1

Sinter stores declared items, examples, work-item objects, computed
identity objects, group description objects, scope objects, and records
as canonical objects that one schema table governs. Each canonical
object has a content hash and a content ID. A counting `"void"` can
withdraw an object or replace a declared-item object in a tree.

### Definitions

#### Object kind

@term object-kind=v1
@cites {
    data-forms#{
        json-value=v1, line-object=v1, canonical-form=v1,
        id-prefix=v1, hash-id-form=v1, group-name=v1,
    },
    text#{text=v1, hex-digit=v1, code-point-order=v1},
    files#path-set=v1,
    identifiers#{
        slug=v1, full-name=v1, name=v1, label=v1, external-id=v1,
        content-id=v1, sinter-tag-word=v1,
    },
    #{tree=v1, agent=v1},
}

Sinter defines twenty-six **object kinds**. Each object kind has one
object kind word (`identifiers#content-id`), which is both the value of
the object's member `kind` and the object kind word of its content ID;
the twenty-six rows of the schema table hold the twenty-six object kind
words. Each object kind also has one object category, a set of members
and types, a boolean stating whether objects of the kind carry `by`, a
set of allowed edge kinds with their allowed target kinds, a boolean
stating whether a file of `.sinter/` can hold an object of the kind, and
a boolean stating whether a line of the log branch can hold an object of
the kind.

Every canonical object holds the required members `kind` (the string
equal to its row's object kind word) and `v` (the integer `1`), and
holds no member `id`. Every array member that its row of `object-kind`
does not declare a sequence is a set with no duplicates, sorted in code
point order (`text#code-point-order`) of the canonical forms
(`data-forms#canonical-form`) of its elements (`edges`, `paths`, and
`status` are sets). A text **matches the content-ID form** for an object
kind word `k` from `object-kind` when that text matches the hash-id form
(`data-forms#hash-id-form`) with ID prefix (`data-forms#id-prefix`) `k:`
and length `32`, and does not match otherwise.

For any kind whose row allows edges, the member `edges` is optional and
is absent when empty (`"edges":[]` is not a valid canonical form). Each
element of `edges` is a flat object (`data-forms#line-object`) holding
exactly `kind` (a string naming an edge kind allowed by the row) and
`to` (a string that matches the content-ID form for an object kind word
among the target kinds allowed by the row for that edge kind). For any
kind whose row lists `none` for edges, the member `edges` is absent.

In the schema table:

- **any declared-item kind** means any of `"design"`, `"spec"`,
  `"schema"`, `"req"`, `"atom"`, `"term"`, and `"decision"`;
- **any computed identity kind** means any of `"name"`, `"pin"`,
  `"ext"`, `"vector-set"`, and `"vector-group"`;
- **any object kind** means any of the twenty-six kinds in the table;
- **citation edges** means `cites`, `satisfies`, `verifies`, `refines`,
  and `supersedes`, each targeting any object kind;
- **withdrawable kind** means any of the sixteen kinds other than
  `"void"`, `"task"`, `"plan"`, any computed identity kind,
  `"vector-group-def"`, and `"example"`;
- **status words** means the status words of
  `identifiers#sinter-tag-word` without the leading `@`;
- `(1: ...)` means exactly one edge of that kind, `(0 or 1: ...)` means
  at most one, and an edge kind with no count can occur any number of
  times.

| kind | category | members (beyond `kind`, `v`, and optional `edges`) | `by` | allowed edges and target kinds | in `.sinter/` | on log branch |
|---|---|---|---|---|---|---|
| `"design"` | declared item | `name` (string that is a `slug`, required), `label` (string that is a `label`, required), `text` (string, required), `status` (set of status words, optional; absent when empty) | no | `about` (1: `"name"`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `"spec"` | declared item | `name` (string that is a `slug` or a `full-name`, required), `label` (string that is a `label`, required), `text` (string, required), `status` (set of status words, optional; absent when empty) | no | `about` (1: `"name"`, matching member `name`); `items` (`"schema"`, `"req"`, `"atom"`, `"term"`); `revises` (any declared-item kind); citation edges | yes | yes |
| `"schema"` | declared item | `name` (string that is a `slug` or a `full-name`, required), `label` (string that is a `label`, required), `text` (string, required), `status` (set of status words, optional; absent when empty) | no | `about` (1: `"name"`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `"req"` | declared item | `name` (string that is a `slug` or a `full-name`, required), `label` (string that is a `label`, required), `text` (string, required), `status` (set of status words, optional; absent when empty) | no | `about` (1: `"name"`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `"atom"` | declared item | `name` (string that is a `slug` or a `full-name`, required), `label` (string that is a `label`, required), `text` (string, required), `status` (set of status words, optional; absent when empty) | no | `about` (1: `"name"`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `"term"` | declared item | `name` (string that is a `slug` or a `full-name`, required), `label` (string that is a `label`, optional), `text` (string, required), `status` (set of status words, optional; absent when empty) | no | `about` (1: `"name"`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `"decision"` | declared item | `name` (string that is a `slug`, required), `label` (string that is a `label`, required), `text` (string, required), `status` (set of status words, optional; absent when empty) | no | `about` (1: `"name"`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `"example"` | example | `index` (integer `>= 1`, required), `text` (string, required) | no | `about` (1: `"name"`, naming the parent declared item's `"name"` object); `cites` (any object kind) | no | no |
| `"task"` | work-item object | `nonce` (string of 32 `hex-digit` characters, required) | no | none | yes | no |
| `"plan"` | work-item object | `nonce` (string of 32 `hex-digit` characters, required) | no | none | yes | no |
| `"name"` | computed identity | `name` (string that matches `identifiers#name`, required) | no | none | yes | yes |
| `"pin"` | computed identity | `name` (string that matches `identifiers#name`, required), `label` (string that is a `label`, required) | no | none | yes | yes |
| `"ext"` | computed identity | `external-ref` (string that matches `external-ref` of `identifiers#external-id`, required) | no | none | yes | yes |
| `"vector-set"` | computed identity | `owner` (string that is a `slug` or a `full-name`, required) | no | none | yes | yes |
| `"vector-group"` | computed identity | `owner` (string that is a `slug` or a `full-name`, required), `group` (string that is a `group-name`, required) | no | none | yes | yes |
| `"vector-group-def"` | group description | `owner` (string that is a `slug` or a `full-name`, required), `group` (string that is a `group-name`, required) | no | `about` (1: `"vector-group"`, matching `owner` and `group`); `cites` (any declared-item kind or `"pin"`) | no | no |
| `"scope"` | scope object | `paths` (set of strings that, in code point order, form a valid `path-set`, required) | no | `about` (1: `"task"`); `promises-satisfies` (`"name"`, `"req"`); `promises-verifies` (`"name"`, `"req"`) | yes | no |
| `"task-def"` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `name` (string, required) | yes | `about` (1: `"task"`); `scoped-by` (1: `"scope"`); `revises` (`"task-def"`); `part-of` (0 or 1: `"plan"`); `waits-for` (`"task"`, `"plan"`); `tracks` (0 or 1: `"ext"`) | yes | no |
| `"plan-def"` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `name` (string, required) | yes | `about` (1: `"plan"`); `revises` (`"plan-def"`); `part-of` (0 or 1: `"plan"`); `waits-for` (`"task"`, `"plan"`); `carries-out` (`"name"`, `"design"`, `"spec"`, `"req"`) | yes | no |
| `"approval"` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional) | yes | `about` (1: any declared-item kind); `judges` (1: same content ID as `about`); `revises` (`"approval"`, `"decline"`) | yes | no |
| `"decline"` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `reason` (string, optional) | yes | `about` (1: any declared-item kind); `judges` (1: same content ID as `about`); `revises` (`"approval"`, `"decline"`) | yes | no |
| `"done"` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional) | yes | `about` (1: `"task"`); `judges` (1: `"task-def"`); `revises` (`"done"`, `"abandoned"`); `records` (`"req"`) | yes | no |
| `"abandoned"` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `reason` (string, required) | yes | `about` (1: `"task"` or `"plan"`); `judges` (1: `"task-def"` when `about` targets `"task"`, `"plan-def"` when `about` targets `"plan"`); `revises` (`"done"`, `"abandoned"`) | yes | no |
| `"void"` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `withdrawn-kind` (string, required), `reason` (string, required) | yes | `withdraws` (1: any withdrawable kind); copies of edges that an object of a withdrawable kind can hold, each with a target of a kind other than a computed identity kind (as the table rule on `"void"` states) | yes | no |
| `"delivered"` | record | `by` (string, required), `seq` (integer `>= 1`, required), `ts` (string, optional), `commit` (string, required), `merge` (string, required), `head` (string, required), `hash` (string of 6 `hex-digit` characters, required) | yes | `about` (1: `"task"`); `observes` (0 or 1: `"task-def"`); `kept-satisfies` (`"req"`); `kept-verifies` (`"req"`) | no | yes |
| `"progress"` | record | `by` (string, required), `seq` (integer `>= 1`, required), `ts` (string, optional), `head` (string, required) | yes | none | no | yes |

These five **table rules** bind every row:

- A `"design"` holds no `items` edge.
- An `items` edge on a `"spec"` carries no position or order.
- A `judges` edge names a declared-item object, a `"task-def"`, or a
  `"plan-def"`, never a work-item object or a computed identity object.
- A `withdraws` edge on a `"void"` names no `"void"`, no work-item
  object (`"task"` or `"plan"`), no computed identity object (`"name"`,
  `"pin"`, `"ext"`, `"vector-set"`, or `"vector-group"`), no
  `"vector-group-def"`, and no `"example"`; the member `withdrawn-kind`
  of the `"void"` equals the object kind word of the content ID in its
  `withdraws` edge.
- A `"void"` has no topic and holds no edge to a computed identity
  object. Each edge of a `"void"` other than its one `withdraws` edge is
  a copy of an edge of the withdrawn object: for a withdrawn declared
  item, a copy of each of its `revises` edges; for each other withdrawn
  object, a copy of each of its edges whose target is not a computed
  identity object (including any `about` edge).

These four **cross-object rules** bind definition statements
(`"task-def"`, `"plan-def"`) and judgments (`"approval"`, `"decline"`,
`"done"`, `"abandoned"`):

- The `"scope"` object that a `"task-def"` names with `scoped-by` names,
  with its `about` edge, the `"task"` object that the `"task-def"` names
  with `about`.
- The `"task-def"` or `"plan-def"` that a `"done"` or `"abandoned"`
  judgment names with `judges` names, with its `about` edge, the
  `"task"` or `"plan"` object that the judgment names with `about`.
- Each `revises` edge of a `"task-def"` or `"plan-def"` names a
  `"task-def"` or `"plan-def"` whose `about` edge names the same
  `"task"` or `"plan"` object.
- Each `revises` edge of an `"approval"`, `"decline"`, `"done"`, or
  `"abandoned"` judgment names a judgment whose `about` edge names the
  same object.

An object **meets its row of `object-kind`** when all of these
conditions hold, and does not meet its row otherwise:

- its member `kind` names one of the twenty-six rows;
- its member `v` is the integer `1` and it holds no member `id`;
- every required member of that row is present, and every member listed
  by that row that is present has its declared `json-value` type and
  value constraint;
- it holds no member that its row does not list, unless its category is
  record;
- `by` is present when the row marks `by` as `yes`, and absent when the
  row marks `by` as `no`;
- every array member that its row does not declare a sequence stands in
  code point order of the canonical forms of its elements with no
  duplicates;
- `edges` is absent when empty, and otherwise holds only flat objects
  each with exactly `kind` and `to` permitted by the row's allowed edges
  and target kinds;
- every agreement and cardinality rule of the row that reads only that
  object holds, and every part of the five table rules of this term that
  reads only that object holds.

@example An `"example"` object for `billing#amount`, with its `edges` in
[code point order](sinter:text#code-point-order=v1) of their
[canonical forms](sinter:data-forms#canonical-form=v1) and its `to`
values in [content-ID](sinter:identifiers#content-id=v1) form:

```json
{"edges":[{"kind":"about","to":"name:6b0304008f2b8f613ff8a27edbf38909"},{"kind":"cites","to":"term:0123456789abcdef0123456789abcdef"}],"index":1,"kind":"example","text":"Amount 100 passes.","v":1}
```

#### Object

@term object=v1
@cites {
    conformance#object=v1,
    data-forms#line-object=v1,
    identifiers#content-id=v1,
    #{finding-class=v1, person=v1, agent=v1, object-kind=v1},
}

Entities of each of the twenty-six kinds in `object-kind` are
**objects** in the sense of `conformance#object`. Findings
(`finding-class`), persons (`person`), agents (`agent`), and git commits
are not objects (commit object names are scalar values).

The **canonical form** of an object is a line object
(`data-forms#line-object`) with no member `id` that meets its row of
`object-kind` and obeys all five **rules of regularity**:

1. **One word for each kind:** the member `kind` and the object kind
   word (`identifiers#content-id`) of the object's content ID are the
   same object kind word from `object-kind`.
2. **Every list is a set unless declared a sequence:** every array
   member that its row of `object-kind` does not declare a sequence is a
   duplicate-free sorted set as `object-kind` defines (`edges`, `paths`,
   and `status`).
3. **One topic edge:** every declared item, example, group description
   object, scope object, definition statement, judgment, and
   `"delivered"` observation names its topic with its `about` edge.
4. **One schema table:** every object meets its row of `object-kind`.
5. **Authorship by a fixed rule:** an object carries `by` when its row
   of `object-kind` marks `by` as `yes` (the nine record kinds), and
   omits `by` when its row marks `by` as `no` (all other seventeen
   kinds).

Every object belongs to one of seven categories from `object-kind`:
declared items (seven kinds), examples (`"example"`), work-item objects
(`"task"` and `"plan"`), computed identity objects (`"name"`, `"pin"`,
`"ext"`, `"vector-set"`, and `"vector-group"`), group description
objects (`"vector-group-def"`), scope objects (`"scope"`), and records
(nine kinds: seven statement kinds and two observation kinds). Objects
of the kinds `"example"`, `"name"`, `"pin"`, `"vector-group-def"`,
`"scope"`, and all nine record kinds are objects and not items.

#### Content hash

@term content-hash=v1
@cites {
    data-forms#{canonical-byte-sequence=v1, hash=v1},
    #object=v1,
}

The **content hash** of an object is the hash (`data-forms#hash`, 64 hex
digits from SHA-256) of the canonical byte sequence
(`data-forms#canonical-byte-sequence`) of its canonical object, with no
member `id` and no final line feed.

#### Content ID

@term content-id=v1
@cites {
    data-forms#{
        canonical-byte-sequence=v1, id-prefix=v1, hash-id=v1,
    },
    identifiers#content-id=v1,
    #{object=v1, object-kind=v1, content-hash=v1},
}

The **content ID** of an object is the hash ID (`data-forms#hash-id`) of
the canonical byte sequence (`data-forms#canonical-byte-sequence`) of
its canonical object with the ID prefix (`data-forms#id-prefix`) made of
the object's object kind word from `object-kind` followed by `:` and
with length `32`: `<kind>:<first 32 hex digits of its content hash>`.
For any of the twenty-six object kinds in `object-kind`, the content ID
of an object of that kind matches the content-ID form for its object
kind word and is a content ID in the sense of `identifiers#content-id`.
The ID prefix is not part of the canonical byte sequence hashed for the
content hash; the member `kind` is part of that canonical byte sequence.

@example The `"name"` [object](sinter:#object=v1)
`{"kind":"name","name":"billing#amount","v":1}`
([object kind](sinter:#object-kind=v1)) has the
[canonical byte sequence](sinter:data-forms#canonical-byte-sequence=v1)
of those 45 UTF-8 bytes, with no `id` and no final line feed. Its
[content hash](sinter:#content-hash=v1) is
`6b0304008f2b8f613ff8a27edbf389094c5ef0616e3df2103aae85792d67f093`. With
[ID prefix](sinter:data-forms#id-prefix=v1) `name:` and length `32`, its
[hash ID](sinter:data-forms#hash-id=v1), which is also its content ID,
is `name:6b0304008f2b8f613ff8a27edbf38909`.

#### Object withdrawal

@term object-withdrawal=v1
@cites {
    conformance#{design=v1, object=v1, encoding=v1, input=v1},
    text#text=v1,
    #{
        tree=v1, person=v1, agent=v1, parameter=v1,
        object-kind=v1, object=v1, content-id=v1,
    },
}

A `"void"` object that a valid file of `.sinter/` of a tree holds
**counts** in that tree (is a **counting void** in that tree) when all
four of these conditions hold, and does not count otherwise:

- a design (`conformance#design`) defines an acceptance rule for
  `"void"` that holds for that `"void"` object in that tree;
- the `"void"` object does not carry the member `agent`;
- when a valid binding of a parameter that a design names supplies the
  list of persons whose judgments and voids count, the `"void"` object's
  `by` value equals a text in that list (an empty list means that no
  person's voids count; when no list is bound, every person's voids
  count);
- when the inputs (`conformance#input`) hold the object that the
  `withdraws` edge of the `"void"` object names, each edge of the
  `"void"` object other than its `withdraws` edge is a copy that the
  table rule on `"void"` of `object-kind` permits for that withdrawn
  object.

Under an invalid binding of that parameter, whether a `"void"` object
that meets the other three conditions counts in that tree is withheld,
and each result whose value depends on whether such a `"void"` object
counts in that tree is withheld (while each result whose value does not
depend on that `"void"` object is unaffected). A `"void"` object that
does not count withdraws nothing.

A withdrawable object (`object-kind`) that a valid file of `.sinter/` of
a tree holds, or any other withdrawable object in the inputs (other than
a declared item in the text encoding, `conformance#encoding`), is
**withdrawn** in that tree when a counting void in that tree names its
content ID with a `withdraws` edge, and is not withdrawn otherwise. A
counting void withdraws no declared item in the text encoding, even one
whose canonical object has the content ID that its `withdraws` edge
names.

A declared-item object of a name in a valid file of `.sinter/` of a tree
is **replaced** in that tree when either of these conditions holds, and
is not replaced otherwise:

- a declared-item object of that name in a valid file of `.sinter/` of
  that tree that is not withdrawn in that tree names that declared-item
  object with a `revises` edge; or
- a counting void in that tree whose member `withdrawn-kind` is one of
  the seven declared-item kinds holds a `revises` edge that names that
  declared-item object.

@example Suppose a [tree](sinter:#tree=v1) holds `.sinter/` `"req"`
objects `A` and `B` of the same name, where `B` holds a `revises` edge
naming `A`, and a counting `"void"` withdraws `B` (carrying
`"withdrawn-kind":"req"` and a copy of `B`'s `revises` edge naming `A`
per [object kind](sinter:#object-kind=v1)). In that tree, `B` is
withdrawn and `A` remains replaced through the counting `"void"`'s
copied `revises` edge. By contrast, if a declared item in the text
[encoding](sinter:conformance#encoding=v1) produces the same
[content ID](sinter:#content-id=v1) as `B`, that counting `"void"`
withdraws nothing from the text encoding.

## Traceable items, identity, and encodings

@spec items=v1

Sinter traces declared items, vector sets, groups of conformance
vectors, tests, sites, external items, and work items across the trees
of a repository. Each declared item has a name, revisions, and a subject
of approval. A computed identity object stands for a name, a pin, an
external item, a vector set, or a group of conformance vectors, and any
program computes that object from its key. The text encoding and the
`.sinter/` encoding store objects at rest in a tree.

### Definitions

#### Declared item

@term declared-item=v1
@cites {
    identifiers#{
        declaration=v1, sinter-tag-word=v1, external-namespaces=v1,
        line-result=v1, give-line-results=v1,
    },
    conformance#{design=v1, conforming-program=v1, encoding=v1},
    #{tree=v1, object-kind=v1, object=v1, object-withdrawal=v1},
}

A **declared item** is an item of one of seven declared-item kinds:

| kind | object kind word | declaration word | role |
|---|---|---|---|
| design | `"design"` | `@design` | a design (`conformance#design`) |
| specification | `"spec"` | `@spec` | declares one specification (`conformance#design`) of the design of which it is a part |
| schema | `"schema"` | `@schema` | defines the layout and self-contained constraints of an input or output crossing the boundary of a conforming program, or of a test-vector file for a design |
| requirement | `"req"` | `@req` | declares one requirement (`conformance#design`) of the design of which it is a part |
| atom | `"atom"` | `@atom` | defines a named result, state, or classification that a conforming program returns, with the condition under which the conforming program returns that name |
| term | `"term"` | `@term` | defines a word or fixed phrase, a grammar rule used by other rules, a form, or a computed value for other items to use |
| decision record | `"decision"` | `@decision` | records one standing practice of a repository, or one choice with the reason for that choice |

A **schema**, an **atom**, a **term**, or a **decision record** is a
declared item of the corresponding kind in the table. A declared item
can stand in the text encoding or in the `.sinter/` encoding.

In the text encoding, a declared item is what a declaration declares,
occupying a part of one file of a tree that holds that declaration. The
declaration word of that declaration alone determines the kind of the
declared item, as shown in the table. Only a declaration for which a
conforming program of Identifiers returns `"valid"` (`line-result`,
`give-line-results`) under the binding of `external-namespaces` declares
a declared item in the text encoding.

In the `.sinter/` encoding, an object of one of the seven declared-item
kinds that a valid file of `.sinter/` of a tree holds (whose member
`kind` determines its kind) is a **declared-item object** in that tree.
A declared item in the `.sinter/` encoding is a declared-item object in
a valid file of `.sinter/` of that tree that is neither withdrawn nor
replaced in that tree (`object-withdrawal`).

#### Containment

@term containment=v1
@cites {
    identifiers#segment=v1,
    #{tree=v1, object=v1, declared-item=v1},
}

**Containment** is a relation in which one declared item **holds**
another declared item, and that other declared item **belongs to** the
first declared item:

- An item of the kind design holds items of the kind specification,
  schemas, items of the kind requirement, atoms, and terms.
- An item of the kind specification holds schemas, items of the kind
  requirement, atoms, and terms.
- No other declared item holds a declared item.

Each declared item belongs to at most one item of the kind design and to
at most one item of the kind specification. When an item of the kind
specification belongs to an item of the kind design, every schema, item
of the kind requirement, atom, or term that belongs to that
specification also belongs to that design. When an item of the kind
specification belongs to no item of the kind design, every schema, item
of the kind requirement, atom, or term that belongs to that
specification belongs to no item of the kind design. An item of the kind
design **holds directly** a schema, an item of the kind requirement, an
atom, or a term when that declared item belongs to that design and
belongs to no item of the kind specification.

In canonical form, an item of the kind specification names each declared
item that it holds with an `items` edge carrying no position or order.
An item of the kind design holds no `items` edge, so the declared items
that a design holds are not part of its canonical object.

In the `.sinter/` encoding, an item of the kind specification holds each
declared item of the tree whose current canonical object is the target
of one of its `items` edges. An item of the kind design (in either
encoding) holds each declared item in `.sinter/` of the tree whose
member `name` is the member `name` of that item of the kind design, `#`,
and one segment—directly when no item of the kind specification holds
it, or through an item of the kind specification that belongs to that
item of the kind design.

#### Item name

@term item-name=v1
@cites {
    identifiers#{
        slug=v1, full-name=v1, segment=v1, declaration=v1, target=v1,
    },
    #{tree=v1, declared-item=v1, containment=v1},
}

In a tree, the canonical member `name` of a declared item holds its
**name**.

In the text encoding, the name of an item of the kind design or of a
decision record is the name in the target of its declaration (a `slug`,
such as `billing`). The name of an item of the kind specification, a
schema, an item of the kind requirement, an atom, or a term in the text
encoding is:

- when the name in the target of its declaration is a `full-name`, that
  full name;
- when the name in the target of its declaration is one `segment` and
  the item belongs to an item of the kind design in that tree, the name
  of that item of the kind design, `#`, and that segment (such as
  `billing#amount`);
- otherwise, the name in the target of its declaration.

In the `.sinter/` encoding, the name of a declared item is the value of
its member `name`.

@example In this text-encoded design, the
[declared items](sinter:#declared-item=v1) form a
[containment](sinter:#containment=v1) hierarchy in which `billing` holds
specification `invoice`, and `invoice` holds term `amount` and
requirement `limit-amount`:

```markdown
# Billing
@design billing=v4

## Invoices
@spec invoice=v2

### Amount
@term amount=v1

### Amount limit
@req limit-amount=v2
```

Their resolved names are `billing`, `billing#invoice`, `billing#amount`,
and `billing#limit-amount`. In canonical form
([object](sinter:#object=v1)), `billing#invoice` holds `items` edges to
`billing#amount` and `billing#limit-amount`, while `billing` holds no
`items` edge.

#### Vector set

@term vector-set=v1
@cites {
    data-forms#{test-vector-set=v1, group-schema=v1},
    #{tree=v1, declared-item=v1},
}

In a tree, each item of the kind design and each item of the kind
specification has at most one **vector set**: the `test-vector-set` of
that item in that tree, when the tree holds one, whether or not a schema
in scope of that item is a group schema (`group-schema`) for each group
of that test-vector set.

#### Conformance vector

@term conformance-vector=v1
@cites {
    data-forms#{
        vector-line=v1, vector-object=v1, group-schema=v1,
        vector-meaning=v1,
    },
    conformance#{design=v1, conforming-program=v1, input=v1},
    #{declared-item=v1, containment=v1, vector-set=v1},
}

Each vector line of a vector set is the **vector line** of one
**conformance vector** of that vector set. That vector set has no other
conformance vector.

The test-vector scope (`group-schema`) of a vector set is the design
that is its item, or the specification that its item declares. The
schemas and requirements in scope are the schemas and items of the kind
requirement that that design or specification holds (`containment`,
including items held through any specification that belongs to that
design).

When the object of its vector line states a vector (`vector-meaning`) of
that test-vector scope, the conformance vector **states a vector**: one
or more inputs of a conforming program of that design or specification
paired with what the requirements in scope directly cited by that
vector's group schema oblige that program to return or withhold for
those inputs. Otherwise, the conformance vector **states no vector**.

#### Conformance vector group

@term conformance-vector-group=v1
@cites {
    data-forms#{vector-line=v1, vector-object=v1},
    #{vector-set=v1, conformance-vector=v1},
}

For each group that appears as the value of the member `group` on a
vector line of a vector set, the set of the conformance vectors of that
vector set whose vector lines carry that group is a **group of
conformance vectors** of that vector set. The **name** of that group of
conformance vectors is that group value. A vector set has no other group
of conformance vectors.

#### Test

@term test=v1
@cites {
    identifiers#declaration=v1,
    #{tree=v1, object=v1},
}

A **test** is a unit of code that a test runner runs and that can pass
or fail, such as a test function, or a set of such units that the code
groups under one name, such as the tests of one `describe` block. No
declaration declares a test. A test is an item and not an object.

Each test lies in one file of a tree, the **file of the test**. Each
test has an **own name**, such as `t` for the test function `t`. The
**name of a test** is a sequence of own names: the own names of the
enclosing tests of which the test is a part, from outermost to
innermost, followed by the own name of the test. Thus, the test function
`t` in the `describe` block `a` and the test function `t` in the
`describe` block `b` of one file of a tree have different names.

The **code of a test** is the part of the file of the test that the test
occupies. A **comment on a test** is a comment attached to the code of
the test, such as the comment immediately before a test function.

#### Test results and evidence

@term test-evidence=v1
@cites #test=v1

A **test result** is what a test runner returns for one test that the
test runner runs. Each test result names no test, one test, or more than
one test, and states the same outcome for every test that the test
result names. The **test evidence** of one execution of test runners is
the set of the test results of that execution that state that their
named tests passed or that their named tests failed.

#### Site

@term site=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1, directive=v1},
    text#line=v1,
    #{tree=v1, object=v1, declared-item=v1, test=v1},
}

A **site** is a part of a file of a tree that lies outside every
declared item (including its trailing `@example` blocks) and every
comment on a test, and that holds a citation, an inline citation, or an
`@ack` line, such as one section of a Markdown file or one comment in
code. No two sites of a file of a tree share a line. A site has no name.
A site is an item and not an object.

#### External item

@term external-item=v1
@cites identifiers#{external-id=v1, part-name=v1}

An **external item** is an entity outside the repository that an
external ID names, even when nothing outside the repository holds that
external ID. An external ID followed by `#` and a part name (such as
`rfc/8259#section-6`) names a part of such an entity, and that part is
also an external item.

#### Computed identity object

@term computed-identity=v1
@cites {
    conformance#{design=v1, input=v1},
    data-forms#canonical-byte-sequence=v1,
    identifiers#kind-word=v1,
    #{
        tree=v1, object-kind=v1, object=v1, content-id=v1,
        declared-item=v1, item-name=v1, vector-set=v1,
        conformance-vector-group=v1, external-item=v1,
    },
}

A **computed identity object** is an object of one of the five kinds
`"name"`, `"pin"`, `"ext"`, `"vector-set"`, and `"vector-group"`. Each
computed identity object holds only `kind`, `v` (the integer 1), and its
key, with no `edges`, no `by`, and no `ts`. Any program computes a
computed identity object from its key alone, so two computed identity
objects with the same kind and key have equal canonical byte sequences
and one content ID:

- **`"name"`** (`{"kind":"name","name":<name>,"v":1}`): stands for the
  identity of a declared item's name across revisions and across kinds.
  Unpinned citations (`=*`), `about` edges of declared items and
  `"example"` objects, and promises and `carries-out` edges that are not
  written by the content ID of an exact object name a `"name"` object.
  The presence of a `"name"` object never implies that a current
  declared-item object of that name exists in a tree.
- **`"pin"`** (`{"kind":"pin","label":<label>,"name":<name>,"v":1}`):
  stands for a pinned citation in the text encoding—whether written as a
  name and a label, or written by that `"pin"` object's content ID when
  an input holds that `"pin"` object—only in the cases in which an exact
  pin written as that name and label names a `"pin"` object (when it
  names no exact object and is not a missing part). A stored edge of an
  object in `.sinter/` whose target is a `pin:` content ID keeps that
  content ID as its canonical target, and when an input holds that
  `"pin"` object, its target resolves in a tree as a pinned citation of
  that `"pin"` object's `name` at its `label`.
- **`"ext"`** (`{"external-ref":<ref>,"kind":"ext","v":1}`): stands for
  an external item and carries no written kind word (`kind-word`).
- **`"vector-set"`** (`{"kind":"vector-set","owner":<owner>,"v":1}`):
  stands for the vector set of the design or specification named by
  `owner`.
- **`"vector-group"`**
  (`{"group":<group>,"kind":"vector-group","owner":<owner>,"v":1}`):
  stands for one group of conformance vectors of the vector set of
  `owner`. The `cites` edges from the `form` members of its vector lines
  live on its group description object `"vector-group-def"` (holding
  `owner`, `group`, an `about` edge naming the `"vector-group"` object,
  and those `cites` edges).

#### Task

@term task=v1
@cites {
    files#{path=v1, path-set=v1, path-set-membership=v1},
    #{tree=v1, person=v1, agent=v1, external-item=v1},
}

A **task** is one piece of work that one person or one agent can finish
alone. The **work of a task** is what people and agents change in the
trees of the repository to finish the task. The **paths of a task** are
a valid `path-set` whose set (`path-set-membership`) holds the valid
paths of the files of a tree that the work of the task is to add,
change, or remove. A task names at most one external item, which can
state what the work is; several tasks can name the same external item. A
task has no prose body of its own and no branch of its own.

#### Plan

@term plan=v1
@cites #task=v1

A **plan** is one piece of work made up of tasks and plans.

#### Work item

@term work-item=v1
@cites {
    text#hex-digit=v1,
    #{tree=v1, object-kind=v1, content-id=v1, task=v1, plan=v1},
}

A **work item** is a task or a plan. Each work item is represented at
rest by one nonce object of the kind `"task"` or `"plan"` in a valid
file of `.sinter/` of a tree, holding only `kind`, `v` (1), and `nonce`
(32 hex digits), with no `edges`, no `by`, and no `ts`. The **work-item
ID** of a work item is the content ID of that work-item object
(`task:<32 hex>` or `plan:<32 hex>`), which never changes and names
exactly one work item. Each work item has a **display name** in its
definitions, which can change.

#### Item

@term item=v1
@cites #{
    object=v1, declared-item=v1, vector-set=v1,
    conformance-vector-group=v1, test=v1, site=v1, external-item=v1,
    task=v1, plan=v1,
}

An **item** is an entity that Sinter traces. Each item has exactly one
of fourteen **kinds of item**:

- the seven declared-item kinds: design, specification, schema,
  requirement, atom, term, and decision record;
- vector set and group of conformance vectors;
- task and plan;
- test, site, and external item.

An `"example"` object is an object and not an item.

#### Item identity across trees

@term same-item=v1
@cites {
    files#path=v1,
    #{
        tree=v1, declared-item=v1, item-name=v1, vector-set=v1,
        conformance-vector-group=v1, test=v1, external-item=v1,
        computed-identity=v1, work-item=v1, item=v1,
    },
}

An item of one tree and an item of another tree are the **same item**
when one of these conditions holds, and in no other case:

- both are declared items with the same name, regardless of their kinds
  of item and their encodings;
- both are groups of conformance vectors with the same name, and their
  vector sets are the same item;
- both are vector sets of declared items that are the same item;
- both are work items with the same work-item ID;
- both are external items whose `"ext"` objects hold the same member
  `external-ref`;
- both are tests whose files have the same valid path and whose test
  names are equal.

#### Revised content

@term revised-content=v1
@cites {
    identifiers#{
        label=v1, declaration=v1, declaration-line=v1, match=v1,
    },
    text#text=v1,
    #{
        tree=v1, object=v1, content-hash=v1, content-id=v1,
        declared-item=v1, containment=v1, vector-set=v1,
        conformance-vector-group=v1, test=v1, site=v1,
        external-item=v1, task=v1, plan=v1, item=v1, same-item=v1,
    },
}

In the text encoding, the **label** of a declared item is the text that
`label` matches in the match of its declaration by `declaration-line`,
when that match uses `label`. In the `.sinter/` encoding and in
canonical form, the **label** of a declared item is the value of its
member `label`, when present.

The **revised content** of a declared item is the content that its
canonical object represents: its `v`, its `label` when present, its
`status` when present, its `text`, and its `edges` (which for an item of
the kind specification include `items` edges to the exact objects of its
held items, and for an item of the kind design include no `items` edge).
Two revised contents of the same declared item (in two trees or in
either encoding) are the **same revised content** when their canonical
objects have the same content hash (and therefore the same content ID),
and not otherwise.

Each declared item has a revised content. A vector set, a group of
conformance vectors, a task, a plan, a test, a site, and an external
item have no revised content.

#### Item revision

@term item-revision=v1
@cites {
    identifiers#label=v1,
    #{
        tree=v1, object=v1, declared-item=v1, item-name=v1, item=v1,
        revised-content=v1,
    },
}

A **revision** of a declared item is a label that the item carries,
naming a revised content (canonical object) of the item with that label.
The **current declared-item objects** of a name in a tree are the
canonical objects of the declared items of that name in that tree,
across both the text encoding and the `.sinter/` encoding
(`declared-item`). When exactly one such canonical object exists in a
tree, it is the **current declared-item object** of that name, and of
each declared item of that name, in that tree. When two or more
different canonical objects of that name exist in a tree, they are
duplicates rather than revisions of each other, and that name has no
current declared-item object in that tree.

The **current revision** of a declared item in a tree is the label of
its current declared-item object in that tree, regardless of what its
revised content is (for example, `v2` in `@req limit-amount=v2`). A term
with no label has a revised content and no revision. An item that has no
revised content has no revision.

#### Subject of approval

@term subject-of-approval=v1
@cites #{
    tree=v1, person=v1, declared-item=v1, containment=v1, same-item=v1,
    revised-content=v1,
}

A **subject of approval** is a unit that a person approves, or that a
merge approves, as a whole. Each subject of approval belongs to one of
seven **kinds of subject of approval**:

| kind of subject of approval | declared item of the subject of approval |
|---|---|
| an item of the kind design, without the declared items that it holds | that item of the kind design |
| an item of the kind specification, with the schemas, items of the kind requirement, atoms, and terms that it holds | that item of the kind specification |
| a schema that an item of the kind design holds directly | that schema |
| an item of the kind requirement that an item of the kind design holds directly | that item of the kind requirement |
| an atom that an item of the kind design holds directly | that atom |
| a term that an item of the kind design holds directly | that term |
| a decision record | that decision record |

The **kind** of a subject of approval is the one of these seven kinds
that the subject of approval is. When a declared item is the declared
item of a subject of approval, the **subject of approval** of that
declared item is that subject of approval. The **subject of approval**
of a schema, an item of the kind requirement, an atom, or a term that an
item of the kind specification holds is the subject of approval of that
item of the kind specification. Every other declared item has no subject
of approval.

The **revised content** of a subject of approval is the revised content
of its declared item. A subject of approval of one tree and a subject of
approval of another tree are the **same subject of approval** when their
declared items are the same item (`same-item`), and not otherwise.

#### Encoding

@term encoding=v1
@cites {
    conformance#{design=v1, encoding=v1, own-store=v1},
    data-forms#canonical-byte-sequence=v1,
    #{
        tree=v1, object-kind=v1, object=v1, content-hash=v1,
        declared-item=v1, vector-set=v1, computed-identity=v1,
    },
}

Two encodings, in the sense of `conformance#encoding`, store objects at
rest in a tree:

- **The text encoding:** text in files of a tree, holding declared items
  (as tag blocks and prose), `"example"` objects (from trailing
  `@example` blocks of declared items in the text encoding), test-vector
  sets (producing `"vector-set"`, `"vector-group"`, and
  `"vector-group-def"` objects), and keys from which computed identity
  objects derive. No record uses the text encoding. A design defines
  what constitutes an input in the text encoding, when that input is
  valid, and which canonical objects it holds, including the value of
  the member `text` of each declared item and each `"example"` object.
- **The `.sinter/` encoding:** fixed files of `.sinter/` of a tree
  (`tree`), each holding the canonical byte sequence of one object with
  no `id` and no final line feed. A design defines when a file of
  `.sinter/` is valid and which canonical object it holds; every such
  object meets its row of `object-kind` and has a kind that
  `object-kind` marks as allowed in `.sinter/`.

A declared item can use either encoding and has the same canonical
object and content hash in either encoding. Moving a declared item
between the text encoding and the `.sinter/` encoding adds no `revises`
edge. Objects can also come from a valid program's own store
(`conformance#own-store`).

## Edges and citations

@spec edges=v1

Objects and items link to one another through typed, directed edges.
Citation edges connect declared items, `"example"` objects, tests,
sites, and groups of conformance vectors to the items and objects on
which they depend. Structural, scope, and record edges bind containment,
revisions, withdrawals, definition statements, judgments, and
observations. Pinned citation edges track specific revisions of declared
items. A change to the cited item of a pinned edge can make that edge
suspect.

### Definitions

#### Edge source

@term edge-source=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1, example-tag=v1},
    text#line=v1,
    #{
        tree=v1, object=v1, object-kind=v1, declared-item=v1, test=v1,
        site=v1, item=v1, encoding=v1,
    },
}

A line of a file of a tree, a citation, or an inline citation stands in
one item, in one `"example"` object, or in nothing, according to the
first matching case (the item or `"example"` object in which it stands
is its **edge source**):

1. When the line, citation, or inline citation lies inside a trailing
   `@example` block of a declared item in the text encoding, it belongs
   to that `"example"` object and stands in that `"example"` object
   rather than in the parent declared item.
2. Otherwise, when the line, citation, or inline citation is part of a
   declared item, it stands in the innermost declared item of which it
   is a part. That innermost declared item is the declared item of which
   the line, citation, or inline citation is a part and that has no
   other such declared item in the part of the file of the tree that
   this declared item takes up.
3. Otherwise, when a comment on a test holds the line, citation, or
   inline citation, it stands in the innermost test whose comment holds
   it. That innermost test is the test that has no other such test in
   the code of that test.
4. Otherwise, when a site holds the line, citation, or inline citation,
   it stands in that site.
5. Otherwise, the line, citation, or inline citation stands in no item
   and no `"example"` object.

#### Edge

@term edge=v1
@cites {
    identifiers#{
        citation=v1, citation-entry=v1, canonical-entry=v1,
        sinter-tag-word=v1, example-tag=v1, inline-citation=v1,
        external-namespaces=v1, give-line-results=v1,
        give-link-results=v1, line-result=v1, link-result=v1,
        kind-word=v1, label=v1, revision=v1, citation-line=v1,
        inline-destination=v1, destination=v1, match=v1,
        external-target=v1, vector-selection=v1, content-id=v1,
    },
    data-forms#{vector-line=v1, form-pin=v1},
    conformance#{
        design=v1, conforming-program=v1, input=v1,
        report-missing-parts=v1,
    },
    text#text=v1,
    #{
        tree=v1, default-branch=v1, job=v1, object=v1, object-kind=v1,
        content-id=v1, object-withdrawal=v1, declared-item=v1,
        containment=v1, item-name=v1, vector-set=v1,
        conformance-vector-group=v1, test=v1, site=v1,
        external-item=v1, work-item=v1, task=v1, plan=v1, item=v1,
        item-revision=v1, subject-of-approval=v1, computed-identity=v1,
        encoding=v1, edge-source=v1,
    },
}

An **edge** is a directed relation of one **kind of edge** from a
**source** to a **target**. The twenty-one kinds of edge form two
groups:

- the five citation kinds: `cites`, `satisfies`, `verifies`, `refines`,
  and `supersedes`;
- the sixteen structural, scope, and record kinds: `items`, `revises`,
  `withdraws`, `about`, `part-of`, `waits-for`, `promises-satisfies`,
  `promises-verifies`, `carries-out`, `tracks`, `judges`, `observes`,
  `records`, `kept-satisfies`, `kept-verifies`, and `scoped-by`.

On every object, every edge lives in its member `edges` (absent when
empty) as a flat object holding exactly `kind` (one of the twenty-one
edge kinds) and `to` (a content ID). The source of each edge in an
object's `edges` is that object (for a `"vector-group-def"`, its `cites`
edges are the `cites` edges of its group of conformance vectors).

In the text encoding, a citation or an inline citation produces edges
only when a conforming program of `identifiers` returns `"valid"` for
that citation or inline citation under a valid binding of
`external-namespaces`:

- Outside a trailing `@example` block, each citation entry of a valid
  citation produces one edge whose kind of edge is the citation word
  without `@`, regardless of the kinds of its source and target. Inside
  a trailing `@example` block, non-`@example` tag lines count as plain
  example text and produce no edges.
- Each valid inline citation produces one `cites` edge.
- The source of an edge produced by a citation or inline citation is the
  edge source in which it stands (or none when it stands in no edge
  source).
- When a citation or inline citation stands in a test or a site (neither
  of which is an object), it produces a **claim from code** in what a
  program returns for that citation: the edge (`kind` and `to`) together
  with its location (file and line) beside the edge, never inside the
  edge.

In the text encoding, the **name** of a citation entry, or of the target
of an inline citation, in a tree is its entry name
(`identifiers#canonical-entry`) when that entry name does not start with
`#`. When its entry name starts with `#` and the design that defines the
text encoding assigns it a home design `D`, its name is the name of `D`
followed by that entry name; otherwise, its name is that entry name. A
written kind word (`identifiers#kind-word`) changes neither the name nor
the target.

In the text encoding, its match determines the **revision** of a
citation entry or an inline citation:

- When the match of a citation entry uses `revision`, the revision of
  that citation entry is the text that `revision` matches in that match.
- When the match of a citation entry does not use `revision` and uses
  `label`, the revision of that citation entry is the text that `label`
  matches in that match.
- A citation entry whose match uses neither `revision` nor `label` has
  no revision.
- When the match of the destination of an inline citation by
  `inline-destination` uses `revision`, the revision of that inline
  citation is the text that `revision` matches in that match; otherwise
  that inline citation has no revision.

An **exact pin** is a citation entry or an inline citation whose
revision is a `label` (`identifiers#label`); its name and its label are
its name and its revision. The member `owner` of the computed identity
object that a vector selection (`identifiers#vector-selection`) names is
the name of its citation entry.

For a name `n` and a label `l` in a tree, the **candidate set** of
`(n, l)` is the first non-empty set among these three:

1. the canonical objects of name `n` and label `l` among the declared
   items of the tree;
2. the replaced (`object-withdrawal`), unwithdrawn declared-item objects
   of name `n` and label `l` in valid files of `.sinter/` of the tree;
3. the unwithdrawn kept objects of name `n` and label `l` on the log
   branch.

When the candidate set holds exactly one canonical object, that object
is the **resolved object** of `(n, l)` in that tree. When the candidate
set holds two or more different canonical objects, `(n, l)` is
**ambiguous** and resolves to no exact target (so each result needing
its target lacks that target). When all three sets are empty, `(n, l)`
has no resolved object: if no declared item of the tree has name `n`,
`(n, l)` resolves to no declared item; otherwise (such as a pin to a
revision that never merged into the default branch, or to a kept object
withdrawn by a counting void under `object-withdrawal`), `(n, l)` is a
missing part (`conformance#report-missing-parts`).

A pin **lies on a cycle of the tree's own objects** when a cycle passes
through that pin's arrow in the directed graph whose nodes are the
declared items of the tree and whose arrows are:

- every `items` edge between declared items of the tree; and
- every exact pin between declared items of the tree whose label equals
  the current revision of the target declared item in that tree,
  directed from the item in which the pin stands to the item of its name
  (including a text citation written by a `pin:` content ID whose
  `"pin"` object an input holds).

An `items` edge always keeps its exact target.

In canonical form, each target of a citation edge is a content ID:

- **Exact pin `(n, l)` in the text encoding:** when `(n, l)` has a
  resolved object in that tree and the pin lies on no cycle of the
  tree's own objects, the target is the content ID of that resolved
  object. Otherwise, the target is the content ID of the `"pin"`
  computed identity object for `(n, l)` in these three cases only: the
  pin lies on a cycle of the tree's own objects; no declared item of the
  tree has name `n`; or `(n, l)` is ambiguous. In every other case (when
  all three candidate sets are empty and a declared item of the tree has
  name `n`), the pin names no object and its citation is a missing part.
- **Citation by a `pin:` content ID:** in the text encoding, when an
  input holds a `"pin"` object with that content ID (with `name` `n` and
  `label` `l`), the citation produces the same canonical edge and the
  same results in that tree as an exact pin `(n, l)` in the text
  encoding; when no input holds such a `"pin"` object, that text
  citation keeps that `pin:` content ID as its canonical target, is not
  a missing part, resolves to no object, and has no cited item in that
  tree. On an object stored in `.sinter/`, an edge whose `to` is a
  `pin:` content ID always keeps that `pin:` content ID as its canonical
  target: when an input holds that `"pin"` object `(n, l)`, its target
  resolves in a tree by the candidate-set lookup for `(n, l)` (to its
  resolved object, to no exact target when ambiguous, to no declared
  item when no declared item of the tree has name `n`, or as a missing
  part when all three sets are empty and a declared item of the tree has
  name `n`); when no input holds that `"pin"` object, that stored edge
  has no `name` and no `label` in the inputs, and each result needing
  them lacks them (a missing part).
- **Unpinned citation (`=*`):** the target is the `"name"` computed
  identity object for that name, and a citation written by `name:…`
  means what `=*` of that name means.
- **External target or vector selection:** an external target names its
  `"ext"` computed identity object (dropping any written kind word), and
  a vector selection names its `"vector-set"` or `"vector-group"`
  computed identity object. A citation written by the content ID of an
  `"ext"`, `"vector-set"`, or `"vector-group"` object produces the same
  canonical edge and the same results as citing its key.
- **Content ID of any other object kind:** a citation written by the
  content ID of an object of a kind other than the five computed
  identity kinds names that content ID directly. A citation edge whose
  target is an `"example"` content ID resolves to no object, has no
  cited item in any tree, and is not a missing part. For any other
  non-computed-identity object kind, the citation resolves to the object
  with that content ID in the tree when that object is not withdrawn in
  that tree (`object-withdrawal`), and otherwise to the unwithdrawn kept
  object with that content ID on the log branch; a citation whose target
  is no object of the text encoding of that tree and is withdrawn in
  that tree (`object-withdrawal`) is a missing part.

The **cited item** of a citation edge in a tree is one item or object,
or none:

- for a target that is a declared-item object, a `"pin"` object, or a
  `"name"` object: the one declared item of that tree whose name is the
  member `name` of that target object, when exactly one exists;
- for an `"ext"` object: the external item that its member
  `external-ref` names;
- for a `"vector-set"` object or a `"vector-group"` object: the vector
  set or the group of conformance vectors of that tree for which that
  object stands;
- for a `"task"` or `"plan"` object: that work item;
- for an `"example"` content ID: none;
- for an object of any other kind: that object.

When that tree holds no such item or object, the edge has no cited item
in that tree. An edge has at most one source and at most one cited item.

Each vector line of a vector set in a tree also produces one `cites`
edge from the group of conformance vectors of that vector line (held on
its `"vector-group-def"`). An item `x` is the cited item of that edge in
that tree when all three of these conditions hold:

- the vector set belongs to a specification `S` that belongs to a design
  `D` in that tree, or the vector set belongs to a design `D`;
- `x` is the one declared item of that tree whose name is `n`, where `n`
  is the name of `D`, `#`, and the schema part name of the form of that
  vector line;
- the vector set belongs to `S` and `S` holds `x` in that tree, or the
  vector set belongs to `D` and `D` holds `x` in that tree (directly or
  through a specification that belongs to `D`).

In every other case, that edge has no cited item in that tree. The label
`l` of that edge is the schema label of the form of that vector line. In
canonical form, the target of that edge is the content ID that an exact
pin `(n, l)` in the text encoding names.

For the five citation kinds of edge, each kind of edge is **for**
certain kinds of item or object as its source and as its cited item,
which can depend on whether a declared item, an `"example"` object, a
test, a site, or a vector line produces the edge. A citation edge **fits
its kind** when its source and its cited item are of those kinds;
otherwise it does not fit its kind and states nothing.

The sixteen structural, scope, and record kinds of edge have these
meanings:

- `items`: from a `"spec"` to each declared item (`"schema"`, `"req"`,
  `"atom"`, `"term"`) that it holds, by exact object, with no position
  or order.
- `revises`: from a declared item in `.sinter/` to another revision of
  the same name, from a `"task-def"` or `"plan-def"` to another
  definition of the same work item, or from a judgment to another
  judgment whose `about` edge names the same object.
- `withdraws`: from a `"void"` to the one withdrawable object that the
  void withdraws.
- `about`: from a declared item, an `"example"` object, a
  `"vector-group-def"`, a `"scope"`, a definition statement, a judgment,
  or a `"delivered"` observation to the object that the source is about.
- `part-of`: from a `"task-def"` or `"plan-def"` to the `"plan"` that
  the work item belongs to.
- `waits-for`: from a `"task-def"` or `"plan-def"` to a work item
  (`"task"` or `"plan"`) that it waits for.
- `promises-satisfies` and `promises-verifies`: from a `"scope"` to a
  promised requirement (`"name"` or `"req"`).
- `carries-out`: from a `"plan-def"` to an item (`"name"`, `"design"`,
  `"spec"`, or `"req"`) that the plan carries out.
- `tracks`: from a `"task-def"` to an `"ext"` object (at most one
  external item).
- `judges`: from a judgment of a subject of approval to the judged
  declared-item object (matching `about`), or from a `"done"` or
  `"abandoned"` judgment to the judged `"task-def"` or `"plan-def"`;
  never to a work-item object or a computed identity object.
- `observes`: from a `"delivered"` observation to the `"task-def"` that
  was current at the landing commit (absent when the task had no current
  definition at that commit or a counting void withdrew that
  definition's `"scope"` object in the tree of that commit).
- `records`: from a `"done"` judgment to each promised `"req"` object
  that the tree declares once.
- `kept-satisfies` and `kept-verifies`: from a `"delivered"` observation
  to the `"req"` object at which the job found a promise kept (present
  only for kept promises).
- `scoped-by`: from a `"task-def"` to its `"scope"` object.

@example In a [design](sinter:#declared-item=v1) `billing` that holds a
term `billing#amount=v1` and a requirement `billing#limit-amount=v2`
([item-name](sinter:#item-name=v1),
[item-revision](sinter:#item-revision=v1)):

- `@cites #{amount=v1}` on `billing#limit-amount` is an exact pin whose
  canonical target is the [content ID](sinter:#content-id=v1) of the
  canonical `"term"` object for `billing#amount=v1` (or the `"pin"`
  [computed identity](sinter:#computed-identity=v1) object for
  `(billing#amount, v1)` if a cycle passes through that pin).
- `@cites billing#amount=*` targets the `"name"` computed identity
  object for `billing#amount`.
- An [inline citation](sinter:identifiers#inline-citation=v1)
  `[amount](sinter:#amount=v1)` inside a trailing `@example` block of
  `billing#limit-amount` ([edge-source](sinter:#edge-source=v1))
  produces a `cites` edge whose source is that `"example"` object, and
  produces no edge whose source is `billing#limit-amount`.

#### Pinned edge

@term pinned-edge=v1
@cites {
    identifiers#{label=v1, citation-entry=v1, inline-citation=v1},
    data-forms#vector-line=v1,
    #{
        content-id=v1, declared-item=v1, item-revision=v1,
        revised-content=v1, computed-identity=v1, encoding=v1, edge=v1,
    },
}

Over canonical objects, a citation edge is **pinned** when its target
content ID names a declared-item object (an exact object of kind
`"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, or
`"decision"`) or a `"pin"` object; otherwise the edge is not pinned. In
the text encoding, a citation entry or inline citation whose revision is
a label, a citation by the content ID of a declared-item object, a
citation by a `pin:` content ID, and an edge that a vector line produces
all yield pinned edges.

A citation edge targeting a `"name"` object (from `=*` or from citing
`name:…`) is not pinned and relates its source to its cited item at
every revision of that item. A pinned edge relates its source to the
specific revised content (exact object) that it names, or, for a `"pin"`
object, to the revised content named by that `"pin"` object's `name` and
`label`.

#### Cites edge

@term cites-edge=v1
@cites {
    data-forms#vector-line=v1,
    #{
        object=v1, object-kind=v1, content-id=v1, declared-item=v1,
        test=v1, site=v1, external-item=v1,
        conformance-vector-group=v1, vector-set=v1,
        computed-identity=v1, encoding=v1, edge=v1, pinned-edge=v1,
    },
}

A `cites` edge states that its source refers to its cited item and rests
on what its cited item states.

- For an edge from a declared item (in either encoding), an `"example"`
  object, a test, or a site, the kind of edge `cites` is for a declared
  item, an `"example"` object, a test, or a site as its source, and for
  any of these as its cited item: a declared item (pinned by exact
  object or `"pin"`, or unpinned by `"name"`), an external item
  (`"ext"`), a group of conformance vectors (`"vector-group"`), a vector
  set (`"vector-set"`), or any object other than an `"example"` object
  named by its content ID.
- For an edge that a vector line produces (held on
  `"vector-group-def"`), the kind of edge `cites` is for a group of
  conformance vectors as its source, and for a schema as its cited item.

#### Satisfies edge

@term satisfies-edge=v1
@cites #{declared-item=v1, test=v1, site=v1, encoding=v1, edge=v1}

A `satisfies` edge states that its source does what its cited item
states. The kind of edge `satisfies` is for a declared item (in either
encoding), a test, or a site as its source, and for an item of the kind
requirement or a schema as its cited item.

#### Verifies edge

@term verifies-edge=v1
@cites {
    conformance#{conforming-program=v1, design=v1},
    #{
        declared-item=v1, test=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1, edge=v1,
    },
}

A `verifies` edge states that its source checks code. The kind of edge
`verifies` is for a test as its source, and for an item of the kind
requirement, a schema, a group of conformance vectors, or a vector set
as its cited item.

When the cited item of a `verifies` edge is an item of the kind
requirement, the edge states that the code that the source runs meets
that requirement. When the cited item of a `verifies` edge is a group of
conformance vectors or a vector set, the edge states, for each
conformance vector in it, that the code that the source runs returns
what that conformance vector states that a conforming program of its
specification or its design returns, which is nothing when that
conformance vector states no vector.

#### Refines edge

@term refines-edge=v1
@cites #{declared-item=v1, item=v1, encoding=v1, edge=v1}

A `refines` edge states that its source specifies all or part of its
cited item in more detail. The kind of edge `refines` is for a declared
item (in either encoding) as its source and for a declared item as its
cited item when the kind of item of its source and the kind of item of
its cited item belong to the same group among these three:

- design, specification, and requirement;
- schema, atom, and term;
- decision record.

#### Supersedes edge

@term supersedes-edge=v1
@cites #{declared-item=v1, item=v1, encoding=v1, edge=v1}

A `supersedes` edge states that its source replaces a different declared
item (its cited item). The kind of edge `supersedes` is for a declared
item (in either encoding) as its source and for a declared item of the
same kind of item as its cited item. Only a `supersedes` edge states
that one declared item replaces another declared item; a new revision of
the same declared item in `.sinter/` uses `revises` and never
`supersedes`.

@example Writing `@supersedes billing#old-limit=v1` on an item of the
kind requirement `billing#limit-amount=v2`
([declared-item](sinter:#declared-item=v1)) produces a `supersedes`
[edge](sinter:#edge=v1) stating that `billing#limit-amount` replaces the
different declared item `billing#old-limit`. By contrast, storing a new
[revision](sinter:#item-revision=v1) of `billing#limit-amount` in
`.sinter/` uses a `revises` edge rather than a `supersedes` edge.

#### Suspect edge

@atom suspect-edge=v1
@cites #{
    tree=v1, declared-item=v1, item-name=v1, item-revision=v1,
    revised-content=v1, computed-identity=v1, edge=v1, pinned-edge=v1,
}

An edge is **suspect** in a tree when all three of these conditions
hold:

- the edge is pinned;
- a declared item with name `n` exists in that tree, where `n` is the
  member `name` of the edge's target object;
- either the edge targets an exact declared-item object other than the
  current declared-item object of `n` in that tree (or `n` has no
  current declared-item object in that tree), or the edge targets a
  `"pin"` object whose `label` differs from the label of the current
  declared-item object of `n` in that tree (or `n` has no current
  declared-item object in that tree, or that current declared-item
  object has no label).

Otherwise, the edge is not suspect in that tree.

@example Suppose a [pinned edge](sinter:#pinned-edge=v1) targets an
exact `"req"` object for `billing#limit-amount` at label `v1`
([item-revision](sinter:#item-revision=v1)). If the current `"req"`
object for `billing#limit-amount` in the [tree](sinter:#tree=v1) still
carries label `v1` but has a different
[revised content](sinter:#revised-content=v1), its target object differs
from the current declared-item object, so the edge is suspect. If no
[declared item](sinter:#declared-item=v1) named `billing#limit-amount`
exists in that tree, the edge is not suspect.

## Work definitions and scopes

@spec work-definitions=v1

Work-item definitions describe tasks and plans through display names,
plan membership, waits between work items, external items, carried-out
items, and task scopes. A task's scope object groups its file paths and
its requirement promises under one content hash. Commit messages carry
delivery lines and task lines that link commits to tasks and task
scopes.

### Definitions

#### Wait

@term wait=v1
@cites #work-item=v1

A **wait** is a relation from one work item, the **waiting item**, to
another work item, the work item that the waiting item waits for.

#### Promise

@term promise=v1
@cites {
    conformance#{design=v1, input=v1, dependence=v1},
    identifiers#citation=v1,
    files#{path=v1, path-set-membership=v1},
    data-forms#group-schema=v1,
    #{
        tree=v1, object-kind=v1, content-id=v1, declared-item=v1,
        item-name=v1, vector-set=v1, conformance-vector=v1,
        conformance-vector-group=v1, test=v1, test-evidence=v1,
        task=v1, computed-identity=v1, edge=v1, satisfies-edge=v1,
        verifies-edge=v1, suspect-edge=v1,
    },
}

A **promise** of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and the name of an item of the kind requirement. On a
`"scope"` object (`object-kind`) of the task, a `promises-satisfies`
edge represents a `satisfies` promise, and a `promises-verifies` edge
represents a `verifies` promise. Each promise edge names either a
`"name"` object or an exact `"req"` object by its content ID, and the
promise's name is the member `name` of that target object. When no input
holds the object that a promise edge names by its content ID, that
promise has no name, and each result that needs that promise lacks it.

A promise links the task to the item of the kind requirement that has
that name: a **promised edge** of the task is an edge of that kind
(`satisfies` or `verifies`) to that item of the kind requirement, from a
citation in a text file of a tree whose valid path is in the set of the
paths of the task. An edge of an item stored in `.sinter/` keeps no
promise. For a `verifies` promise, a `verifies` edge from a citation in
such a text file to a group of conformance vectors or a vector set is
also a promised edge when that cited item holds a conformance vector
that meets both of these conditions:

- that conformance vector states a vector; and
- the promised item of the kind requirement is among the requirements of
  the group of conformance vectors of that conformance vector for that
  vector set's test-vector scope (`data-forms#group-schema`).

A promise of a task is **kept** in a tree when that tree holds a
promised edge that meets all of these conditions:

- the edge comes from a citation in a text file of that tree whose valid
  path is in the set of the paths of the task;
- the edge fits its kind (`satisfies-edge` or `verifies-edge`);
- the edge is not suspect in that tree (`suspect-edge`); and
- for a `verifies` promise, test evidence of an execution of test
  runners on the code of that tree shows that the test that is the
  source of that edge passed.

Test evidence shows that a test of which no other test is a part passed
when that test evidence holds a test result that names that test and
states that the test passed, and holds no test result that names that
test and states that the test failed. Test evidence shows that a test of
which one or more other tests are a part passed when the rule that a
design names for such a test returns that the test passed, from the test
results that name that test or any of those other tests.

@example Suppose a [task](sinter:#task=v1) has paths `test/` and a
`verifies` promise for `billing#limit-amount`. A
[test](sinter:#test=v1) in `test/limits_test.ml` carries
`@verifies billing#limits[bounds]`
([verifies-edge](sinter:#verifies-edge=v1)). If the `bounds`
[group of conformance vectors](sinter:#conformance-vector-group=v1) of
the [vector set](sinter:#vector-set=v1) of the specification
`billing#limits`, which declares `billing#limit-amount`, holds a
[conformance vector](sinter:#conformance-vector=v1) that states a
vector, the group's schema directly cites `billing#limit-amount`
([group-schema](sinter:data-forms#group-schema=v1)), the edge is not
suspect ([suspect-edge](sinter:#suspect-edge=v1)), and
[test evidence](sinter:#test-evidence=v1) shows that the test passed,
then that edge keeps the `verifies` promise. A matching `verifies` edge
from a test in `bench/limits_bench.ml` (outside `test/` under
[path-set-membership](sinter:files#path-set-membership=v1)) does not
keep the promise.

#### Scope object

@term scope-object=v1
@cites {
    files#path-set=v1,
    #{
        object=v1, object-kind=v1, content-hash=v1, task=v1, edge=v1,
        promise=v1,
    },
}

A **scope object** is an object of kind `"scope"` (`object-kind`) that
carries no `by` and no `ts`. A scope object holds the task's `paths` (a
set of path set members that form a valid path set, `files#path-set`),
the task's promise edges (`promises-satisfies` and `promises-verifies`),
and one `about` edge naming its `"task"` object. The content hash of a
scope object identifies one **scope** of its task. Two definitions of
one task with equal `paths` and equal promise edges share one scope
object, whereas two distinct tasks have distinct scope objects.

#### Work-item definition

@term work-item-definition=v1
@cites {
    conformance#{input=v1, dependence=v1},
    #{
        tree=v1, object-kind=v1, object-withdrawal=v1, content-id=v1,
        declared-item=v1, item-name=v1, external-item=v1, work-item=v1,
        task=v1, plan=v1, computed-identity=v1, edge=v1, wait=v1,
        promise=v1, scope-object=v1,
    },
}

A **definition of a task** consists of a display name, one scope object
named with `scoped-by`, at most one external item named with `tracks`,
at most one plan named with `part-of`, and waits named with `waits-for`.
When no counting void in a tree (`object-withdrawal`) withdraws the
scope object that a task definition names with `scoped-by`, the paths of
the task in that definition in that tree are the `paths` of that scope
object, and the promises of the task in that definition in that tree are
the promises represented by the `promises-satisfies` and
`promises-verifies` edges of that scope object.

When a counting void in a tree withdraws the scope object that a task
definition names with `scoped-by`, that scope object decides nothing in
that tree:

- the definition remains a definition of the task, with its display
  name, plan, waits, and external item readable;
- the definition has no readable paths and no readable promises in that
  tree; and
- each result that reads the paths, the promises, or the scope object of
  that definition in that tree is withheld.

A **definition of a plan** consists of a display name, at most one plan
named with `part-of`, waits named with `waits-for`, and the items of the
kind requirement, specification, or design that the plan **carries
out**, named with `carries-out`. The work of the tasks that make up the
plan, directly or through other plans, is for the items that the plan
carries out. A plan definition names each carried-out item with a
`carries-out` edge targeting either the content ID of its `"name"`
identity object or the content ID of an exact `"design"`, `"spec"`, or
`"req"` object. When a `carries-out` edge names an exact `"design"`,
`"spec"`, or `"req"` object by its content ID, that edge carries out the
item with that target object's member `name`; when no input holds that
exact object, that edge has no name, and each result that needs that
edge lacks it.

Each alteration of a definition produces a new definition. The **plan of
a work item in a definition** is the plan, or none, that the definition
names with `part-of`. The **waits of a work item in a definition** are
the waits from that work item to each work item that the definition
names with `waits-for`. The work-item ID of a work item is not part of a
definition.

#### Delivery line

@term delivery-line=v1
@cites {
    text#{line=v1, hex-digit=v1},
    #{
        object-kind=v1, content-hash=v1, content-id=v1, work-item=v1,
        task=v1, scope-object=v1,
    },
}

A **delivery line** is a line of a commit message that states that the
commit completes the work of one task. A delivery line names that task
by its work-item ID (the content ID of its `"task"` object,
`task:<32 hex>`) and names a scope of that task by the first six hex
digits of the content hash of a scope object of that task, with no
object kind word on that six-digit prefix.

#### Task line

@term task-line=v1
@cites {text#line=v1, #{work-item=v1, task=v1}}

A **task line** is a line of a commit message that names one task by its
work-item ID and states that the commit does part of the work of that
task without finishing that task.

## Ledger and records

@spec ledger-records=v1

Persons and agents write statements as fixed object files of `.sinter/`,
and the job writes observations and kept objects on a dedicated log
branch. The latest counting statements of each topic, and the conflicts
between them, decide the states that a tree records.

### Definitions

#### Record

@term record=v1
@cites #{
    object=v1, object-kind=v1, content-id=v1, edge=v1, person=v1,
    agent=v1, job=v1, tree=v1, work-item=v1, scope-object=v1,
    computed-identity=v1, declared-item=v1,
}

A **record** is an object of one of the nine record kinds in
`object-kind`: the seven statement kinds (the two definition statement
kinds `"task-def"` and `"plan-def"`, the four judgment kinds
`"approval"`, `"decline"`, `"done"`, and `"abandoned"`, and `"void"`)
and the two observation kinds (`"delivered"` and `"progress"`). Every
record has a content ID, holds any links in `edges`, and carries the
member `by`, which records its writer (a person, the person for whom an
agent acts, or the job). A statement can carry `agent` (when an agent
wrote the statement) and `ts` (a timestamp), and carries no `seq`. An
observation carries `seq` (an integer of 1 or more) and can carry `ts`.

These actors write the kinds of record:

- a person or an agent writes definition statements (`"task-def"` and
  `"plan-def"`), along with non-record objects (work-item objects, scope
  objects, computed identity objects, and declared items), in files of
  `.sinter/` of a tree;
- only a person writes judgments and voids in files of `.sinter/` of a
  tree;
- only the job writes observations (`"delivered"` and `"progress"`),
  along with kept objects of declared items and their referenced
  computed identity objects, on the log branch.

#### Statement

@term statement=v1
@cites #{
    record=v1, object-kind=v1, encoding=v1, person=v1, agent=v1,
    tree=v1,
}

A **statement** is a record of one of the seven statement kinds in
`object-kind` (a definition statement, a judgment, or a void) that a
person or an agent writes as a fixed file of `.sinter/` of a tree. No
statement uses the text encoding, and no statement carries `seq`.

#### Void statement

@term void-statement=v1
@cites #{
    statement=v1, object-kind=v1, object-withdrawal=v1,
    declared-item=v1, work-item=v1, computed-identity=v1,
    scope-object=v1, work-item-definition=v1, edge=v1, content-id=v1,
    person=v1, tree=v1,
}

A **void statement** (also called a **void**) is a statement of the kind
`"void"` with which a person withdraws one withdrawable object
(`object-kind`): a statement in a file of `.sinter/`, a `"scope"`
object, a declared-item object in `.sinter/` (replaced or not), an
observation on the log branch, or a kept declared-item object on the log
branch. No void withdraws a `"void"`, a work-item object (`"task"` or
`"plan"`), a computed identity object (`"name"`, `"pin"`, `"ext"`,
`"vector-set"`, or `"vector-group"`), a `"vector-group-def"`, or an
`"example"`.

Whether a `"void"` counts in a tree (is a counting void in that tree)
and when a counting void withdraws an object in that tree follow
`object-withdrawal`. Which edges a `"void"` copies from its withdrawn
object follows `object-kind` and `object-withdrawal`.

A counting void takes the place of the object that its `withdraws` edge
names. The withdrawn object decides nothing: a withdrawn kept
declared-item object counts as absent for pin and content-ID resolution
while remaining on the log branch, and the effect of withdrawing a task
definition's `"scope"` object follows `work-item-definition`. Objects
that the withdrawn object replaced stay replaced through the void's
copied `revises` edges. When no file of `.sinter/` of a tree holds an
object whose content ID a counting void in that tree names with
`withdraws`, that counting void stands in `.sinter/` of that tree as the
record of that content ID's withdrawal and holds the copied edges of
that object. A void has no topic, although its copied edges can include
an `about` edge.

#### Definition statement

@term definition-statement=v1
@cites #{
    statement=v1, work-item=v1, task=v1, plan=v1, scope-object=v1,
    work-item-definition=v1, edge=v1,
}

A **definition statement** is a statement of the kind `"task-def"` or
`"plan-def"`. A definition statement names one work item (`"task"` or
`"plan"`) with an `about` edge, names zero or more definitions of that
work item that the statement replaces with `revises` edges, and records
one whole definition of its work item. A `"task-def"` records a
definition of a task and names its `"scope"` object with a `scoped-by`
edge. A `"plan-def"` records a definition of a plan. A definition
statement records no judgment.

#### Judgment

@term judgment=v1
@cites #{
    statement=v1, definition-statement=v1, person=v1,
    subject-of-approval=v1, revised-content=v1, work-item=v1, task=v1,
    plan=v1, work-item-definition=v1, promise=v1, declared-item=v1,
    computed-identity=v1, item-name=v1, tree=v1, edge=v1, content-id=v1,
}

A **judgment** is a statement that records a decision of a person. Every
judgment names its topic with `about`, names the exact judged
declared-item object, `"task-def"`, or `"plan-def"` (never a work-item
object or a computed identity object) with `judges`, and names zero or
more judgments of its topic that the judgment replaces with `revises`. A
judgment is one of these four kinds of statement:

- An **`"approval"` judgment** records that a person approved one
  revised content (the exact declared-item object, named by both `about`
  and `judges`) of one subject of approval.
- A **`"decline"` judgment** records that a person declined one revised
  content (the exact declared-item object, named by both `about` and
  `judges`) of one subject of approval, with an optional `reason`.
- A **`"done"` judgment** records that a person judged the work of one
  task (`about` naming `"task"`) finished under one task definition
  (`judges` naming `"task-def"`) in a tree. For each promised
  requirement of that definition, when that tree declares exactly one
  item of the kind requirement with that name, that `"done"` judgment
  holds a `records` edge naming the content ID of that requirement's
  object in that tree; when that tree declares no such requirement, or
  declares two or more such requirements, that `"done"` judgment holds
  no `records` edge for that name.
- An **`"abandoned"` judgment** records that a person ended one task or
  one plan (`about` naming `"task"` or `"plan"`) under one definition
  (`judges` naming `"task-def"` or `"plan-def"`), with a `reason`.

#### Observation

@term observation=v1
@cites {
    conformance#design=v1,
    #{
        record=v1, job=v1, delivery-line=v1, promise=v1, task=v1,
        scope-object=v1, work-item-definition=v1,
        definition-statement=v1, declared-item=v1, item-name=v1,
        tree=v1, edge=v1, content-hash=v1, content-id=v1,
        object-withdrawal=v1, void-statement=v1,
    },
}

An **observation** is a record of the kind `"delivered"` or `"progress"`
on the log branch.

A **`"delivered"` observation** records what the job observed about one
delivery line of one task (`about` naming `"task"`). The `"delivered"`
observation holds the six-digit scope hash prefix of that delivery line
in its member `hash`, and holds the commit object names `commit` (the
commit whose message holds the delivery line), `merge` (the landing
commit of that commit), and `head` (the head of the run of the job that
wrote the observation).
When the task had a current definition `D` at the landing commit and no
counting void in the tree of the landing commit withdrew the `"scope"`
object that `D` names with `scoped-by`, the `"delivered"` observation
holds an `observes` edge naming `D`, and for each promise of `D` that
the job found kept in the tree of the head of the run (with a unique
requirement object in that tree), the `"delivered"` observation holds a
`kept-satisfies` or `kept-verifies` edge naming the content ID of that
requirement object; a promise that was not kept, or whose requirement
was absent or duplicated in that tree, gets no edge. When the task had
no current definition at the landing commit, or a counting void in the
tree of the landing commit withdrew the `"scope"` object that its
current definition at the landing commit names with `scoped-by`, the
`"delivered"` observation holds no `observes` edge and no
`kept-satisfies` or `kept-verifies` edge.

When no counting void in a tree (`object-withdrawal`) withdraws the
`"scope"` object that a task definition `D` names with `scoped-by`, a
`"delivered"` observation **completes `D`** in that tree (is a
**completing `"delivered"` observation** of `D` in that tree) when all
five conditions hold:

1. the `"delivered"` observation decides a state in that tree;
2. the `"delivered"` observation names with `about` the task that `D`
   names with `about`;
3. the `"delivered"` observation holds an `observes` edge naming `D`;
4. the member `hash` of the `"delivered"` observation is the first six
   hex digits of the content hash of the `"scope"` object that `D` names
   with `scoped-by`;
5. for each promise of `D`, the `"delivered"` observation holds a
   matching `kept-satisfies` or `kept-verifies` edge to a requirement
   object whose name is the name of that promise.

When a counting void in that tree withdraws the `"scope"` object that
`D` names with `scoped-by`, the `"delivered"` observation does not
complete `D` in that tree if any of the first three conditions does not
hold; if all three of the first three conditions hold, whether that
`"delivered"` observation completes `D` in that tree is withheld (the
observation neither completes `D` nor fails to complete `D` in that
tree).

A **`"progress"` observation** holds in its member `head` the commit
object name of the head of the run of the job, and holds no edges.

An observation **decides a state** in a tree when all four conditions
hold:

- a design defines an acceptance rule for its kind of observation;
- that acceptance rule holds for the observation;
- no counting void in that tree withdraws the observation;
- for a `"delivered"` observation with an `observes` edge, that tree
  holds the definition that the `observes` edge names or a counting void
  in that tree names that definition with its `withdraws` edge.

@example Suppose a task has a current
[work-item definition](sinter:#work-item-definition=v1) `D` at the
[landing commit](sinter:#job=v1) `M`, and no counting
[void statement](sinter:#void-statement=v1) in the tree of `M` withdraws
`D`'s [scope object](sinter:#scope-object=v1). The `"delivered"`
observation carries an `observes` edge naming `D` and checks `D`'s
[promises](sinter:#promise=v1) in the tree of the head of the run `H`.
If a counting void later withdraws `D`'s `"scope"` object in a tree `T`
in which the observation still decides a state
([object-withdrawal](sinter:#object-withdrawal=v1)), the first three
completion conditions hold in `T`, so whether the observation completes
`D` in `T` is withheld rather than false.

#### Log branch

@term log-branch=v1
@cites {
    conformance#design=v1,
    #{
        object=v1, object-kind=v1, job=v1, observation=v1,
        declared-item=v1, computed-identity=v1, edge=v1, content-id=v1,
        parameter=v1, default-branch=v1,
    },
}

The **log branch** of a repository is a dedicated branch, named by a
binding of a parameter that a design names, that holds only the
observations (`"delivered"` and `"progress"`) and the kept objects that
the job writes. A **kept object** is either a copy of a declared item
merged into the default branch or a copy of a computed identity object
named by an edge of a kept declared item (other than the kept declared
item's own `"name"` identity object), stored on the log branch with no
`seq` and no `by` and deduplicated by content ID. Every line of the log
branch holds an object of one of the fourteen kinds that `object-kind`
marks as allowed on the log branch. Only the job writes the log branch,
and the log branch only grows: each commit adds lines and removes or
changes no existing line.

#### Repository ledger

@term ledger=v1
@cites #{
    object=v1, record=v1, statement=v1, observation=v1, log-branch=v1,
    content-id=v1, edge=v1, item=v1, wait=v1, subject-of-approval=v1,
    tree=v1,
}

The **ledger** of a repository consists of two parts:

- the statements stored as fixed files of `.sinter/` of a tree, which
  form a Merkle graph with the other objects of `.sinter/`, with every
  edge naming its target by content ID;
- the observations and kept objects on the log branch.

No state of an item, an edge, a wait, or a subject of approval depends
on the order of records or on the member `seq`.

#### Topic

@term topic=v1
@cites {
    conformance#{design=v1, input=v1},
    #{
        object-kind=v1, object-withdrawal=v1, content-id=v1,
        computed-identity=v1, scope-object=v1, statement=v1,
        definition-statement=v1, judgment=v1, void-statement=v1,
        observation=v1, declared-item=v1, work-item=v1, edge=v1,
        parameter=v1, person=v1, agent=v1, tree=v1,
    },
}

The **topic** of a declared item, an `"example"` object, a
`"vector-group-def"`, a `"scope"` object, a definition statement, a
judgment, or a `"delivered"` observation is the object that its own
`about` edge names:

- a work item for a definition statement, a `"done"` judgment, an
  `"abandoned"` judgment, a `"scope"` object, and a `"delivered"`
  observation;
- the judged declared-item object for an `"approval"` judgment and a
  `"decline"` judgment;
- a `"name"` computed identity object for a declared item, and the
  parent declared item's `"name"` computed identity object for an
  `"example"` object;
- a `"vector-group"` computed identity object for a
  `"vector-group-def"`.

A `"void"`, a `"progress"` observation, a work-item object, and a
computed identity object have no topic; a `"void"` has no topic even
when it holds a copy of an `about` edge of the object that it withdraws.
The **statements of a topic** fall into separate groups: for a work
item, one group holds its definition statements (`"task-def"` or
`"plan-def"`), and a separate group holds its work-item judgments
(`"done"` and `"abandoned"`); for a declared-item object, one group
holds its `"approval"` and `"decline"` judgments. Neither a
`"delivered"` observation nor an `"example"` object is a statement of
its topic.

A statement is **accepted** in a tree when all three conditions hold:

- the statement meets each cross-object rule of `object-kind` that binds
  its kind;
- a design defines an acceptance rule for its kind of statement;
- that acceptance rule holds for that statement in that tree.

When a cross-object rule reads an object that no input holds and that a
counting void in that tree withdraws, the copied edges of that counting
void stand in place of the edges of that object.

A statement **counts** in a tree when all four of these conditions hold
(and, for a void, the copy condition of `object-withdrawal` also holds):

1. the statement is accepted in that tree;
2. no counting void in that tree withdraws the statement (names the
   statement's content ID with its `withdraws` edge);
3. when the statement is a judgment or a void, the statement does not
   carry the member `agent`;
4. when the statement is a judgment or a void, and a valid binding of a
   parameter that a design names lists the persons whose judgments and
   voids count, the statement's `by` value is equal to a text in that
   list (an empty list means that no person's judgments or voids count;
   when no list is bound, every person's judgments and voids count).

Under an invalid binding of that parameter, whether a judgment or a void
that meets the other conditions counts in that tree is withheld, and
each result whose value depends on whether such a judgment or void
counts in that tree is withheld (while each result whose value does not
depend on it is unaffected). A statement that does not count takes no
part in the graph of `revises` and `judges` edges of its topic: the
statement replaces nothing, is never a latest statement, and an edge
naming that statement replaces nothing. Whether a void counts follows
`object-withdrawal`; a void that does not count withdraws nothing.

Within one group of statements of a topic, a counting statement replaces
each counting statement of that group that the counting statement names
with a `revises` edge, and each statement that a withdrawn statement
replaced stays replaced through the copied `revises` edges of the
counting void that withdrew it. A **latest statement** of a group is a
counting statement of that group that no other counting statement of
that group replaces (directly or through a counting void's copied
edges). When a counting void withdraws the only latest statement of a
group, that group has no latest statement.

#### Conflict

@term conflict=v1
@cites #{
    topic=v1, statement=v1, definition-statement=v1, judgment=v1,
    void-statement=v1, observation=v1, work-item-definition=v1,
    declared-item=v1, work-item=v1, scope-object=v1, edge=v1, tree=v1,
}

Two or more latest statements of one group of statements of a topic
**agree** when those statements assign their topic the same state:

- two `"approval"` judgments of the same declared-item object agree;
- two `"decline"` judgments of the same declared-item object agree;
- two definition statements of one work item agree when they record the
  same definition (equal display name, equal scope object or carried-out
  items, equal plan, equal waits, and equal external item), whoever
  wrote them;
- two `"done"` judgments that judge the same task definition agree;
- two `"abandoned"` judgments that judge the same work-item definition
  agree.

Latest `"done"` and `"abandoned"` judgments of one work item that judge
different definitions neither agree nor conflict; each judgment decides
only for the definition that it judges.

A **conflict** exists in a tree in either of these two cases:

- two or more latest statements of one group of statements of a topic
  neither agree nor fall under the rule for judgments of different
  definitions (an `"approval"` judgment and a `"decline"` judgment of
  the same declared-item object; two latest definition statements of one
  work item that record different definitions; or a `"done"` judgment
  and an `"abandoned"` judgment that are both latest for the same task
  definition);
- a completing `"delivered"` observation of a task definition `D` that
  decides a state in that tree and any latest counting `"abandoned"`
  judgment that judges `D` both exist (whether or not a `"done"`
  judgment also judges `D`).

When a `"delivered"` observation of a task definition `D` has whether it
completes `D` in that tree withheld (`observation`) and at least one
latest counting `"abandoned"` judgment judges `D`, whether the second
case of conflict holds for `D` in that tree is withheld (and when no
conflict holds for those judgments under the first case, whether a
conflict exists for those judgments in that tree is withheld).

A conflict decides nothing: no latest statement that takes part in a
conflict decides a state. One new counting statement of the group whose
`revises` edges name every latest statement that takes part in the
conflict settles a conflict of statements. For a conflict between a
completing `"delivered"` observation of `D` and one or more latest
`"abandoned"` judgments of `D`, any of these settles the conflict: a
`"done"` judgment whose `revises` edges name every latest `"abandoned"`
judgment of `D`, a counting void for each latest `"abandoned"` judgment
of `D`, or a counting void that withdraws the `"delivered"` observation.

@example Suppose a task has two
[definition statements](sinter:#definition-statement=v1) `D1` and `D2`.
In the task's judgment group ([topic](sinter:#topic=v1)), a latest
counting `"abandoned"` [judgment](sinter:#judgment=v1) judging `D1` and
a latest counting `"done"` judgment judging `D2` judge different
definitions, so they neither agree nor conflict. In another tree where
the only latest judgment judging `D2` is a counting `"abandoned"`
judgment, a completing `"delivered"`
[observation](sinter:#observation=v1) of `D2` that decides a state in
that tree conflicts with that judgment; writing a `"done"` judgment
whose `revises` edge names that `"abandoned"` judgment, or writing a
counting [void statement](sinter:#void-statement=v1) withdrawing either
the `"abandoned"` judgment or the `"delivered"` observation, settles the
conflict.

### Writing judgments and voids only for persons

@req write-judgments-only-for-persons=v1
@cites {
    conformance#conforming-program=v1,
    #{judgment=v1, void-statement=v1, person=v1},
}

A conforming program must write a judgment or a void only to record a
decision that a person supplies to the program through a confirmation
that the standard input, the arguments, and the environment of the
program cannot supply.

## Derived states

@spec states=v1

A state is a named condition of an item, an edge, a wait, or a subject
of approval in a tree, such as approved, retired, ready, or done. A
program derives each state—whether declared items apply and how work
items progress—from the repository's canonical objects and state inputs.
Quality of implementation governs program behavior while another process
changes a state input.

### Definitions

#### Work-item state

@atom work-item-state=v1
@cites #{
    work-item=v1, task=v1, plan=v1, work-item-definition=v1,
    statement=v1, definition-statement=v1, judgment=v1, observation=v1,
    log-branch=v1, topic=v1, conflict=v1, tree=v1, edge=v1,
}

In a tree, the `"task"` and `"plan"` objects in valid files of
`.sinter/`, the counting statements in `.sinter/`, and the observations
on the log branch that decide a state in that tree determine the work
items that exist, the current definition of each work item, the parts of
each plan, and the state of each task and each plan:

1. A work item **exists** in a tree when its `"task"` or `"plan"` object
   is in a valid file of `.sinter/` of that tree; otherwise, that work
   item does not exist in that tree. The **current definition** of a
   work item is the definition recorded by its latest counting
   definition statements when at least one latest counting definition
   statement exists and all latest counting definition statements agree.
   When a work item has no latest counting definition statement, or when
   its latest counting definition statements conflict, the work item
   exists and has no current definition (so each result that needs its
   current definition lacks that definition). A work item with no
   current definition can be a part of any plan. While such a work item
   exists in a tree, each plan that has a current definition, that is
   not abandoned, and that has no part that is not done has no state in
   that tree.
2. A work item is a **part of** a plan when, and only when, the current
   definition of the work item names that plan with `part-of` and the
   work item is not abandoned. When the current definition of a task
   names a plan with `part-of` and whether that task is abandoned in
   that tree is withheld under item 3, whether that task is a part of
   that plan (and whether that task is under that plan or under any plan
   that that plan is under) is withheld in that tree. A work item stays
   a part of its plan when the plan is abandoned. A part of a plan is a
   task or a plan. A work item `W` is **under** a plan `P` when `W` is a
   part of `P`, or when a finite chain of one or more work items runs
   from `W` to `P` in which each work item is a part of the next.
3. For a task with a current definition `D`, judgments whose `judges`
   edge names a replaced definition other than `D` do not decide the
   state of the task under `D`. When a `"delivered"` observation has
   whether it completes `D` in that tree withheld (`observation`) and no
   latest counting `"done"` judgment of the task judges `D`, the task
   has no state in that tree: when no latest counting `"abandoned"`
   judgment judges `D`, whether the task is done or delivered is
   withheld and the task is not abandoned; when at least one latest
   counting `"abandoned"` judgment judges `D`, whether the task is
   abandoned or delivered is withheld and whether the task is abandoned
   is withheld. Otherwise, the task has one of four states:
   - **abandoned**: at least one latest counting judgment of the task
     judges `D`, every latest counting judgment of the task that judges
     `D` is an `"abandoned"` judgment, and no completing `"delivered"`
     observation that decides a state in that tree observes `D`;
   - **done**: either at least one latest counting judgment of the task
     judges `D` and every latest counting judgment of the task that
     judges `D` is a `"done"` judgment, or a completing `"delivered"`
     observation that decides a state in that tree observes `D` and no
     latest counting judgment of the task that judges `D` is an
     `"abandoned"` judgment;
   - **delivered**: the task is neither abandoned nor done, and a
     `"delivered"` observation of the task that decides a state in that
     tree exists (including when a completing `"delivered"` observation
     that decides a state in that tree observes `D` and a latest
     counting `"abandoned"` judgment judges `D`, or when a `"done"`
     judgment and an `"abandoned"` judgment conflict and a `"delivered"`
     observation of the task that decides a state in that tree exists);
   - **open**: the task is none of abandoned, done, and delivered.
4. A task is **unfinished** when it is open or delivered. When a task
   has no state in a tree, no result is returned for whether that task
   is unfinished in that tree.
5. A **cycle of plans** in a tree is a finite sequence of one or more
   plans in which each plan is a part of the next and the last plan is a
   part of the first. Except when the no-state conditions of this item
   hold, each plan with a current definition `D`, other than a plan that
   has no state under item 1, has one of three states (judgments whose
   `judges` edge names a replaced definition other than `D` do not
   decide the state of the plan under `D`):
   - **abandoned**: at least one latest counting judgment of the plan
     judges `D` and every latest counting judgment of the plan that
     judges `D` is an `"abandoned"` judgment;
   - **done**: the plan is not abandoned, has at least one part, every
     part of the plan is done, no task whose current definition names
     the plan with `part-of` has whether that task is a part of the plan
     withheld under item 2, and neither the plan nor any plan under it
     lies on a cycle of plans;
   - **open**: the plan is neither abandoned nor done and does not meet
     the no-state conditions of this item.

   A plan with a current definition `D` meets the no-state conditions of
   this item (and has no state in that tree) when the plan is not
   abandoned, has no part that is open or delivered, neither the plan
   nor any plan under it lies on a cycle of plans, and either (a) the
   plan has a part that has no state in that tree, or (b) the plan has
   at least one part (every part of which is done) and at least one task
   whose current definition names the plan with `part-of` has whether
   that task is a part of the plan withheld under item 2.

@example Suppose a task has current definition `D`, a completing
`"delivered"` [observation](sinter:#observation=v1) that decides a state
in the tree observes `D`, and a [latest counting](sinter:#topic=v1)
`"abandoned"` [judgment](sinter:#judgment=v1) also judges `D`. Those
records form a [conflict](sinter:#conflict=v1), so the task is neither
**done** nor **abandoned**; a `"delivered"` observation of the task
decides a state in that tree, so the task has state **delivered**. A
`"done"` [judgment](sinter:#judgment=v1) whose `judges`
[edge](sinter:#edge=v1) names an earlier replaced definition does not
decide the task's state under `D`.

#### Deprecated item

@atom deprecated-item=v1
@cites {
    conformance#{design=v1, conforming-program=v1},
    identifiers#{
        status-tag=v1, external-namespaces=v1, give-line-results=v1,
        line-result=v1,
    },
    #{declared-item=v1, tree=v1, edge-source=v1, encoding=v1},
}

A declared item is **deprecated** in a tree when the member `status` of
its canonical object holds `"deprecated"` (in the text encoding, when a
`@deprecated` status tag stands in that declared item in that tree and a
conforming program of the design Identifiers returns `"valid"` for that
status tag under the binding of `external-namespaces`); otherwise, that
declared item is not deprecated in that tree. That status tag marks that
the declared item no longer applies and that nothing replaces that item.

#### Approved and declined

@term approval-state=v1
@cites {
    conformance#design=v1,
    #{
        subject-of-approval=v1, person=v1, revised-content=v1,
        item-revision=v1, containment=v1, declared-item=v1,
        default-branch=v1, tree=v1, judgment=v1, topic=v1, conflict=v1,
        parameter=v1, edge=v1,
    },
}

In a repository, a binding of a parameter that a design names specifies
the kinds of subject of approval that need approval by a person. Every
other kind of subject of approval needs no approval by a person. Whether
a judgment counts follows `topic` (including the persons that a binding
of a parameter that a design names specifies, when bound). In a tree,
these rules determine the approval states **approved**, **declined**,
**neither**, and **draft**:

- For a subject of approval of a kind that needs approval by a person,
  consider the latest counting judgments whose `about` and `judges`
  edges name the current declared-item object (revised content) of that
  subject of approval in that tree:
  - the subject of approval is **approved** when at least one such
    latest counting judgment exists and every such latest counting
    judgment is an `"approval"` judgment;
  - the subject of approval is **declined** when at least one such
    latest counting judgment exists and every such latest counting
    judgment is a `"decline"` judgment;
  - the subject of approval is **neither** (neither approved nor
    declined) when no such latest counting judgment exists, or when
    those latest counting judgments conflict (at least one `"approval"`
    judgment and at least one `"decline"` judgment).
- A subject of approval of a kind that needs no approval by a person is
  not declined. That subject of approval is **approved** when the merge
  rule that a design names determines that the current declared-item
  object (revised content) of that subject of approval in that tree
  merged into the default branch; otherwise, that subject of approval is
  **neither**.
- A declared item other than an item of the kind design is **approved**
  when it has a subject of approval that is approved, and is
  **declined** when it has a subject of approval that is declined.
- An item of the kind design is **approved** in a tree when all of these
  conditions hold:
  - the item of the kind design without the declared items that it holds
    is approved in that tree;
  - each item of the kind specification that the item of the kind design
    holds is approved in that tree;
  - each schema, each item of the kind requirement, each atom, and each
    term that the item of the kind design holds directly is approved in
    that tree.
- An item of the kind design is a **draft** in a tree when it is not
  approved in that tree.

#### Effective supersedes edge

@atom effective-supersedes-edge=v1
@cites #{
    edge=v1, supersedes-edge=v1, declared-item=v1,
    containment=v1, deprecated-item=v1, approval-state=v1, tree=v1,
}

A `supersedes` edge is **effective** in a tree when all of these
conditions hold:

- the edge fits its kind in that tree;
- neither the source of the edge nor any declared item that holds that
  source is deprecated in that tree;
- the source of the edge is approved in that tree.

Otherwise, the `supersedes` edge is not effective in that tree.

#### Retired item

@atom retired-item=v1
@cites #{
    declared-item=v1, deprecated-item=v1, supersedes-edge=v1,
    effective-supersedes-edge=v1, edge=v1, containment=v1, tree=v1,
}

A **cycle of `supersedes` edges** in a tree is a finite sequence of one
or more pairs `(x, y)` of declared items in that tree that meets both of
these conditions:

- for each pair `(x, y)` in the sequence, some `supersedes` edge in that
  tree fits its kind in that tree with `x` as its source and `y` as its
  cited item;
- for each pair before the last, its second item is the first item of
  the next pair, and the second item of the last pair is the first item
  of the first pair.

A declared item is **on a cycle of `supersedes` edges** in a tree when
it is the first item of a pair in a cycle of `supersedes` edges in that
tree.

In a tree, each declared item is either **retired** or **in force**:

- A declared item is **retired** in that tree when any of these
  conditions holds:
  - the declared item is deprecated in that tree;
  - the declared item is the cited item of an effective `supersedes`
    edge in that tree and is on no cycle of `supersedes` edges in that
    tree;
  - the declared item belongs to a retired item of the kind design or to
    a retired item of the kind specification in that tree.
- A declared item is **in force** in that tree when it is not retired in
  that tree.

A retired item no longer applies in that tree.

@example Suppose two declared items `A` and `B` of the same kind each
hold an [effective](sinter:#effective-supersedes-edge=v1) `supersedes`
edge ([supersedes-edge](sinter:#supersedes-edge=v1)) naming the other,
and neither item is [deprecated](sinter:#deprecated-item=v1) or belongs
to a retired design or specification
([containment](sinter:#containment=v1)). Both `A` and `B` lie on a cycle
of `supersedes` edges, so neither `supersedes` edge retires its target
and both `A` and `B` remain **in force**.

#### Met wait

@atom met-wait=v1
@cites #{wait=v1, work-item=v1, work-item-state=v1, tree=v1}

A wait states that the work of the waiting item starts only after the
work item that the waiting item waits for is done. A wait is **met** in
a tree when, and only when, the work item that it waits for is done in
that tree. When the work item that a wait waits for has no state in a
tree, no result is returned for that wait in that tree.

#### Ready task

@atom ready-task=v1
@cites #{
    task=v1, plan=v1, work-item=v1, wait=v1, met-wait=v1,
    work-item-definition=v1, work-item-state=v1, tree=v1,
}

A task is **ready** in a tree when, and only when, all of these
conditions hold:

- the task is open in that tree;
- each wait of the current definition of the task is met in that tree;
- each wait of the current definition of each plan that the task is
  under is met in that tree.

When the task, a work item that a wait of these definitions waits for,
or a plan that the task is under has no current definition or no state
in that tree, no result is returned for that task in that tree.

#### Accounted-for requirement

@atom requirement-accounted-for=v1
@cites #{
    declared-item=v1, containment=v1, item-name=v1, item-revision=v1,
    content-id=v1, task=v1, plan=v1, promise=v1, scope-object=v1,
    work-item-definition=v1, work-item-state=v1, judgment=v1,
    observation=v1, object-withdrawal=v1, topic=v1, edge=v1, tree=v1,
}

An item of the kind requirement, with current declared-item object `O`
and name `N` in a tree, is **accounted for** in that tree when, and only
when, any of these conditions holds:

- the current definition of an unfinished task has a promise whose name
  is `N`;
- the current definition of an open plan names, as carried out, the name
  `N`, the name of the item of the kind specification that holds that
  item of the kind requirement in that tree, or the name of the item of
  the kind design that holds that item of the kind requirement in that
  tree;
- for a task that is done in that tree with current definition `D`,
  either some latest counting `"done"` judgment of that task that judges
  `D` holds a `records` edge naming the content ID of `O`, or a
  completing `"delivered"` observation of `D` that decides a state in
  that tree holds a `kept-satisfies` or `kept-verifies` edge naming the
  content ID of `O`.

When none of those conditions holds, no result is returned for that item
of the kind requirement in that tree if any of these conditions holds:

- a task with no current definition exists in that tree;
- a task that is unfinished or has no state in that tree has a current
  definition whose `"scope"` object a counting void in that tree
  withdraws;
- a plan that has no state in that tree has a current definition that
  names, as carried out, the name `N`, the name of the item of the kind
  specification that holds that item of the kind requirement in that
  tree, or the name of the item of the kind design that holds that item
  of the kind requirement in that tree;
- for a task with current definition `D` that is done or has no state in
  that tree, a `"delivered"` observation whose completion of `D` in that
  tree is withheld (`observation`) holds a `kept-satisfies` or
  `kept-verifies` edge naming the content ID of `O`.

#### State input

@term state-input=v1
@cites {
    conformance#{design=v1, encoding=v1, own-store=v1},
    #{
        tree=v1, default-branch=v1, delivery-line=v1, task-line=v1,
        observation=v1, log-branch=v1, test-evidence=v1, parameter=v1,
        object=v1,
    },
}

A **state input** of a repository is one of these:

- which commits the repository has, each with its parents and its tree;
- the commit to which each branch points;
- the commit of the default branch;
- the tree of each working tree;
- the delivery lines and task lines of the messages of commits;
- the observations and kept objects on the log branch (without regard to
  their order);
- test evidence;
- the bindings of the parameters that designs name.

When a program takes objects from a valid program's own store in place
of inputs in encodings, the canonical objects that those inputs hold
determine the states.

### Computing states from repository artifacts

@req compute-states-from-artifacts=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    #{
        state-input=v1, item=v1, edge=v1, wait=v1,
        subject-of-approval=v1, suspect-edge=v1, work-item-state=v1,
        deprecated-item=v1, approval-state=v1,
        effective-supersedes-edge=v1, retired-item=v1, met-wait=v1,
        ready-task=v1, requirement-accounted-for=v1,
    },
}

A conforming program must return the same states for each item, edge,
wait, and subject of approval for which the program returns states, for
two inputs that meet both of these conditions:

- the two inputs agree in each state input, as each state input stands
  when the program returns those states;
- no other process changes either input while the program runs.

### Treating equivalent records alike

@req treat-records-alike=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    #{
        item=v1, edge=v1, wait=v1, subject-of-approval=v1, record=v1,
        object-kind=v1, content-id=v1, judgment=v1,
        definition-statement=v1, observation=v1, void-statement=v1,
        log-branch=v1, topic=v1, person=v1, agent=v1, parameter=v1,
        suspect-edge=v1, work-item-state=v1, deprecated-item=v1,
        approval-state=v1, effective-supersedes-edge=v1,
        retired-item=v1, met-wait=v1, ready-task=v1,
        requirement-accounted-for=v1,
    },
}

A conforming program must return the same states for each item, edge,
wait, and subject of approval for which the program returns states, for
two inputs that meet both of these conditions:

- one input turns into the other by changing only one or more of the
  following on records, together with the matching update of every
  content ID (in edges, object file paths, and log-branch lines, and
  transitively for every record whose edges change) that names each
  changed record:
  - the `ts` values of records;
  - members of records that no row of `object-kind` names;
  - the `seq` values of observations;
  - the `by` values of records that are neither judgments nor voids, or
    the `by` values of judgments and voids where each changed `by`
    remains either inside the bound list of persons whose judgments and
    voids count or outside that list (or any `by` when no list is
    bound);
  - the `agent` member of definition statements, or changing one `agent`
    string to another `agent` string on a judgment or a void without
    adding or removing `agent`;
- no other process changes either input while the program runs.

### Using declared tasks only for briefs

@req use-declared-tasks-only-for-briefs=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #{agent=v1, task=v1, state-input=v1},
}

A **session** is one execution of an agent on its work. The **declared
task** of a session is the task that the agent declares as the work of
that session. The **brief** of a session is the text about the work of
the session that a conforming program returns to the agent of that
session outside every state input. A conforming program must use the
declared task of a session for nothing other than the brief of that
session.
