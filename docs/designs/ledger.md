<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# The ledger
@design ledger=v1
@cites text=v1
@cites data-forms=v1
@cites ontology=v1
@cites changes=v1
@cites rfc/3339
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies how a git repository stores its ledger on the ref `refs/sinter/ledger`: chunks of canonical lines, entry ids, `seq`, the common fields of ledger entries, versions, and voids; when a stored ledger is valid, broken, or newer, and when its history is intact; acceptance, appends, the shared clone, taking in, and repairs; agent markers and the writers of ledger entries; and requirements for conforming programs that read, append to, take in, and repair the ledger.

The ledger of a repository is a sequence of ledger entries. Each ledger
entry records one event, such as one approval that a person gave. A git
repository stores its ledger in git objects, on the ref
`refs/sinter/ledger`. The commit of that ref holds files of canonical
lines, and each line holds one ledger entry. Each clone of a repository
stores a ledger of its own. One clone, the shared clone, holds the ledger
of the repository. The other clones push their new ledger entries to it,
and they take in its ledger entries.

Each kind of ledger entry has an acceptance rule: the condition under
which a ledger entry of that kind can stand at a point of a ledger. A
program appends a ledger entry only at a point at which the ledger entry
is accepted. When another clone pushed first, a clone takes in the
ledger entries of the shared clone, and each ledger entry that it has
not pushed moves to a later point or leaves the ledger.

From the Ontology (`ontology`), the design takes ledger entries, the
ledger with its order and its points, the eight kinds of ledger entry,
definition entries, judgments, records of the job, voids, and repairs;
persons, agents, and the job; states, states at a point of a ledger, and
external items; and parameters with their bindings. From Changes
(`changes`), it takes git repositories, commits and their parents, the
file `shallow`, refs and the commits of refs, git tree objects with their
entries, the byte paths and the modes of these entries, tree entries,
regular-file entries, blobs and their contents, reach and ancestry,
branch names, repository reads, and undisturbed repository reads. From
Data forms (`data-forms`), it takes JSON values, objects and their
members, line objects, canonical byte sequences, canonical lines, the
JSON values of byte sequences, hash ids with their id prefixes, and
test-vector sets: the file that holds the conformance vectors of the
design is one. From Text and notation (`text`), it takes texts,
characters, hex digits, whole numbers, bytes, byte sequences, UTF-8
encodings, code spans, productions, and what a conforming program, an
input, and a result are.

From RFC 3339, the design takes the rule `date-time` of its ABNF, for the
time at which a ledger entry was written. Its one production is written
in ABNF, the notation of RFC 5234, with the case-sensitive strings
`%s"…"` of RFC 7405. From RFC 8259, it takes JSON texts, with their
objects, members, arrays, strings, and numbers: each line of the file
that holds the conformance vectors of the design is a JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [ledger](sinter:ontology#ledger=v1) | the sequence of the ledger entries of a repository, in the order in which they were appended |
| [point of a ledger](sinter:ontology#ledger=v1) | a place between two ledger entries of a ledger, before the first, or after the last; the point of a ledger entry is the point right before it |
| [ledger entry](sinter:ontology#ledger-entry=v1) | a record of one event, such as one approval; each ledger entry has one of the eight kinds `task`, `plan`, `approval`, `decline`, `done`, `abandoned`, `delivered`, and `void` |
| [definition entry](sinter:ontology#definition-entry=v1) | a ledger entry of the kind `task` or `plan` |
| [judgment](sinter:ontology#judgment=v1) | a ledger entry of the kind `approval`, `decline`, `done`, or `abandoned`: a decision of a person |
| [record of the job](sinter:ontology#job-record=v1) | a ledger entry of the kind `delivered` |
| [repair](sinter:ontology#repair=v1), [void](sinter:ontology#repair=v1) | a repair removes ledger entries from a ledger and puts one void, a ledger entry of the kind `void`, where each of them was |
| [person](sinter:ontology#person=v1), [agent](sinter:ontology#agent=v1), [job](sinter:ontology#job=v1) | a human who works on a repository; a program that uses a language model to write texts as one person runs it; the execution of a conforming program that continuous integration starts at each push to the default branch |
| [state](sinter:ontology#state=v1) | a named condition of an item, an edge, a wait, or a subject of approval, such as approved or done; a state at a point of a ledger depends on the ledger entries before that point |
| [parameter](sinter:ontology#parameter=v1) | a word whose value a design leaves open; configuration gives its binding |
| clone | a git repository made as a copy of another git repository; each git repository of one repository is a clone of it |
| push, fetch | to send git objects to another clone and change one of its refs; to take git objects from another clone |
| [ref](sinter:changes#ref-commit=v1), [commit of a ref](sinter:changes#ref-commit=v1) | a name, such as `refs/heads/main`, that points to a git object or names another ref; the commit to which a ref resolves, when it resolves to a commit |
| [git tree object](sinter:changes#commit-file=v1), [entry of a git tree object](sinter:changes#commit-file=v1), [byte path](sinter:changes#commit-file=v1) | a git object that lists entries; each entry has a name, a mode, and a git object; the byte path of an entry is the names on the way to it, with the byte of `/` between each two of them |
| [tree entry](sinter:changes#commit-file=v1), [regular-file entry](sinter:changes#commit-file=v1) | an entry of a git tree object that names a git tree object; an entry that names the blob of a regular file |
| [reach](sinter:changes#ancestry=v1) | a commit reaches itself, each of its parents, each parent of each of them, and so on |
| [ledger ref](sinter:#ledger-ref=v1), [ledger commit](sinter:#ledger-ref=v1) | the ref `refs/sinter/ledger` of a git repository; the commit of that ref |
| [chunk](sinter:#chunk=v1), [chunk path](sinter:#chunk-path=v1) | a regular file of a git tree object at a path of the form `entries/<hh>/<id>.jsonl`, which holds lines of ledger entries |
| [line of a chunk](sinter:#chunk=v1), [object of a line](sinter:#chunk=v1) | a part of the content of a chunk that ends with the byte 0x0A, or the part after the last 0x0A; the line object whose canonical line the line of a chunk is |
| [canonical line](sinter:data-forms#canonical-line=v1), [line object](sinter:data-forms#line-object=v1) | the canonical byte sequence of a line object, then the byte 0x0A; an object whose members each hold a string, an integer, a boolean, or an array of these or of objects of them |
| [member](sinter:data-forms#json-value=v1) | a key and a value of an object, such as the member `seq` with the value 7 |
| [entry id](sinter:#entry-id=v1) | `e-` and the first 12 hex digits of the SHA-256 hash of the canonical byte sequence of an object without its member `id` |
| [field](sinter:#entry-field=v1), [common field](sinter:#entry-field=v1), [field of a kind](sinter:#entry-field=v1) | a member of the object of a ledger entry that a design names; the fields `id`, `kind`, `v`, `seq`, `by`, `agent`, `branch`, and `ts`, which are the same for each kind; the other fields that a design gives for one kind |
| [writer that a ledger entry records](sinter:#entry-field=v1) | the agent that its `agent` names, or else the person or the job that its `by` names |
| [newer line](sinter:#newer-line=v1) | a line of a chunk whose JSON value is an object with a `v` greater than 1 |
| [ledger objects](sinter:#ledger-object=v1), [history objects](sinter:#ledger-object=v1) | the git objects that a program reads to read the ledger of a git repository, or to check its history |
| [valid ledger tree](sinter:#ledger-validity=v1) | a git tree object that holds chunks of ledger entries, and nothing else, in the form of section 2.3 |
| [valid](sinter:#ledger-validity=v1), [broken](sinter:#ledger-validity=v1), [newer](sinter:#ledger-validity=v1) | the three conditions of the ledger of a git repository: a program can read it; it fails a check; it holds a newer line |
| [stored ledger](sinter:#stored-ledger=v1) | the ledger entries of the lines of the ledger commit of a git repository, in the order of their `seq` |
| [extend](sinter:#ledger-extension=v1) | a commit extends an earlier commit when the chain of its single parents leads to it, and each commit of the chain holds each line of its parent |
| [intact](sinter:#intact-history=v1) | the history of a ledger is intact when its ledger commit extends a commit with no parent, and the git tree object of each commit that it reaches is a valid ledger tree |
| [acceptance rule](sinter:#accepted-entry=v1), [accepted](sinter:#accepted-entry=v1) | the condition under which a ledger entry of one kind can stand at a point of a ledger; a ledger entry is accepted at a point when the acceptance rule of its kind holds for it there |
| [shared clone](sinter:#shared-clone=v1) | the clone of a repository whose stored ledger is the ledger of the repository, such as the clone on the host of the repository |
| provisional | a ledger entry of the stored ledger of a clone is provisional while the stored ledger of the shared clone does not hold it, because the clone has not pushed it yet |
| [account for](sinter:#take-in-commit=v1) | a git tree object accounts for a line of a chunk when it holds that line, or a void that replaces it |
| [take in](sinter:#take-in-commit=v1), [take-in commit](sinter:#take-in-commit=v1) | a clone takes in the ledger entries of another clone when its ledger ref changes to a take-in commit: a commit that holds the lines of the other clone and, after them, some of its own lines that the other clone does not account for |
| [agent marker](sinter:#agent-marker=v1) | an environment variable whose name the parameter `agent-markers` gives, which shows that an agent runs a program |
| environment | the environment variables of a process |
| tracker | a service that holds external items, such as the issues of the host of a repository |

## 2. The ledger and its storage

### 2.1 The ledger ref and its chunks

A git repository stores the ledger entries of its ledger in git objects.
The ledger ref of a git repository is its ref `refs/sinter/ledger`. The
commit of the ledger ref is the ledger commit. No branch and no working
tree holds the ledger, so a file tool that edits the files of a working
tree does not change it. When the ledger ref does not exist, the ledger
of the git repository is empty.

The git tree object of the ledger commit holds the ledger entries in
chunks. A chunk is a regular file with the mode 100644, in base 8, at a
chunk path: `entries/`, two hex digits, `/`, an entry id, and `.jsonl`,
such as `entries/5b/e-5b1c0a9d2e11.jsonl`. The entry id in the chunk path
is the `id` of the first line of the chunk, and the two hex digits are
the two hex digits right after its `e-`. The git tree object holds only
these things:

| byte path | git object |
|---|---|
| `entries` | a git tree object, when the git tree object holds at least one chunk |
| `entries/<hh>` | a git tree object, for each two hex digits `<hh>` of the chunk path of a chunk |
| `entries/<hh>/<id>.jsonl` | a chunk |

So each folder holds at least one chunk. A git tree object with no chunk
holds nothing. A symbolic link, a submodule, an executable file, and a
file with another mode are not chunks. For example, a ledger of 87
ledger entries can have two chunks:

```
entries/5b/e-5b1c0a9d2e11.jsonl    50 lines
entries/a0/e-a03f77c1d9e2.jsonl    37 lines
```

A chunk holds one or more lines. Each line of a chunk ends with the byte
0x0A and is the canonical line of a line object: the object of the line.
Each line holds one ledger entry. The number of lines in a chunk is
free, and the lines of a chunk need not be in the order of the ledger. A
commit can move a line from one chunk to another chunk, as long as the
line keeps its bytes.

### 2.2 The fields of ledger entries

A field is a member of the object of a ledger entry that a design names.
The common fields are the same for each kind of ledger entry:

| field | value | what it holds |
|---|---|---|
| `id` | a string | the entry id of the object |
| `kind` | a string | the kind of the ledger entry, such as `approval` |
| `v` | an integer | the version of the form of the ledger entry: 1 |
| `seq` | an integer of 1 or more | the number of the ledger entry in the order of the ledger |
| `by` | a string | the person who wrote the ledger entry, the person for whom the agent that wrote it acts, or the job |
| `agent` | a string, which a ledger entry can leave out | the agent that wrote the ledger entry |
| `branch` | a string, which a ledger entry can leave out | the branch name of the branch from which the ledger entry was written, such as `main` |
| `ts` | a string, which a ledger entry can leave out | the time of the write, in UTC, to the second, such as `2026-10-31T14:05:09Z` |

The writer that a ledger entry records is the agent that its `agent`
names, when it has `agent`. Otherwise, it is the person or the job that
its `by` names. A program can take the values of `by` and `agent` from
any source, such as the settings of git, because no state depends on
them.

The entry id of an object is `e-`, then the first 12 hex digits of the
SHA-256 hash of the canonical byte sequence of the object without its
member `id`. For example, the object of this void has the canonical byte
sequence

```
{"by":"Ada Lovelace <ada@example.com>","dropped":"e-5b1c0a9d2e11","kind":"void","reason":"the entry holds a secret","seq":7,"v":1}
```

and the entry id `e-9f4ed52acf42`. So its line is:

```
{"by":"Ada Lovelace <ada@example.com>","dropped":"e-5b1c0a9d2e11","id":"e-9f4ed52acf42","kind":"void","reason":"the entry holds a secret","seq":7,"v":1}
```

The entry id depends on `seq`, so two ledger entries with the same other
members, at two places of a ledger, have different ids.

In the git tree object of a ledger commit with n lines, the values of
`seq` are the whole numbers from 1 to n, each once. The order of `seq`
is the order of the ledger. The time `ts` orders nothing: the clock of a
writer can be wrong.

Each ledger entry has one of eight kinds: `task` and `plan`, the
definition entries; `approval`, `decline`, `done`, and `abandoned`, the
judgments; `delivered`, the records of the job; and `void`, the voids.
The fields of a kind are the fields that a design gives for the ledger
entries of that kind, other than the common fields. The fields of the
kind `void` are `dropped`, the entry id of the ledger entry that a
repair removed, and `reason`, the reason for the removal (section 2.7).

A line of a chunk whose `kind` is none of the eight kinds records no
ledger entry, so it changes no state. Its `id` and its `seq` still count
in the checks of section 2.3. A member that is neither a common field
nor a field of the kind of its ledger entry also changes no state.

The field `v` gives the version of the form of a ledger entry. The form
of this section is the version 1. A newer line is a line of a chunk
whose JSON value is an object with a `v` greater than 1. A program gives
no state from a ledger that holds a newer line, because it cannot know
how the newer form changes the states.

### 2.3 Valid, broken, and newer ledgers

A program reads the ledger of a git repository from the git objects of
its ledger ref: the ledger objects. A git repository can lack some of
them, as a partial clone can lack blobs. For such a git repository, a
program gives no result for its ledger, and no state at a point of it.

The ledger of a git repository that holds its ledger objects is newer,
valid, or broken. It is newer when a line of a chunk of the git tree
object of the ledger commit is a newer line. Otherwise, it is valid when
the ledger ref does not exist, or when the git tree object of the ledger
commit is a valid ledger tree. A valid ledger tree meets each of these
conditions:

1. No two of its entries, at any depth, have the same byte path.
2. Each of its entries, at any depth, is a chunk with the mode 100644 in
   base 8, the tree entry `entries/<hh>` for the two hex digits `<hh>`
   of the chunk path of a chunk, or the tree entry `entries`.
3. The content of each chunk has at least one line, and each line of a
   chunk is a canonical line.
4. The object of each line has the member `id` with a string, the
   member `kind` with a string, the member `v` with the integer 1, and
   the member `seq` with an integer of 1 or more.
5. The `id` of the object of each line is the entry id of that object.
6. The chunk path of each chunk ends with the `id` of its first line and
   then `.jsonl`.
7. No two lines of its chunks have the same `id`.
8. For its number n of lines, the values of `seq` are the whole numbers
   from 1 to n, each once.

A ledger that is neither newer nor valid is broken: its ledger ref
exists and resolves to a git object that is not a commit, or the git
tree object of the ledger commit fails one of the conditions. A program
gives no state from a broken ledger, and a repair (section 2.7) makes it
valid again. A program that checks the ledger of a git repository can
give one of three results: "valid", "broken", or "newer".

The stored ledger of a git repository whose ledger is valid is the
sequence of the ledger entries of the lines of its ledger commit, in the
order of their `seq`. The ledger of a clone is its stored ledger, so a
program that gives the states of a clone gives the states at the points
of its stored ledger. For example, a ledger commit holds three lines:
the `seq` 3 in the first chunk, the `seq` 1 and the `seq` 2 in the
second chunk. The line with the `seq` 2 has the kind `pin`, which is not
one of the eight kinds. The stored ledger then holds two ledger entries:
the ledger entry of the `seq` 1, and then the ledger entry of the `seq`
3.

When another process changes the ledger ref or a git object of the
ledger during a read, what a program gives in that read is not
specified, and each guarantee of section 5 still holds.

### 2.4 Extensions and intact histories

Each commit of a ledger, other than the first, has one parent: the
ledger commit before it. A commit d extends a commit c when d is c, or
when d has exactly one parent, that parent extends c, and the git tree
object of d holds each line of the git tree object of that parent with
the same bytes. So when a commit extends another commit, it holds each
of its ledger entries, with the same `seq` and the same `id`.

The history of the ledger of a git repository is intact when the ledger
commit extends a commit that has no parent, and the git tree object of
each commit that the ledger commit reaches is a valid ledger tree. A
program that checks the history gives the result "valid" when the
history is intact, and "invalid" when it is not. For a newer ledger, it
gives neither result. The check reads the history objects: the ledger
objects of each commit that the ledger commit reaches, and the git
objects that these commits name as parents. A commit that the file
`shallow` names has no parents, so in a shallow clone the history ends
at such a commit.

The states at the points of a ledger depend only on the lines of the
ledger commit. So two clones whose ledger commits hold the same lines
give the same states, whatever history each of them holds.

### 2.5 Appends and acceptance

A program appends ledger entries in a new commit. The parent of the new
commit is the ledger commit, or the new commit has no parent when the
ledger ref does not exist. Its git tree object holds each line of the
ledger commit with the same bytes, and one new line for each new ledger
entry. When the ledger commit has n lines, the new ledger entries take
the `seq` n + 1, n + 2, and so on, in the order in which the program
appends them. The git tree object of the new commit is a valid ledger
tree. The program then changes the ledger ref to the new commit, which
extends the ledger commit.

Each kind of ledger entry has an acceptance rule: the condition, which a
design gives for that kind, under which a ledger entry of that kind can
stand at a point of a ledger. For example, an acceptance rule can refuse
a ledger entry that the ledger entries before the point make out of
date. A ledger entry is accepted at a point when the acceptance rule of
its kind holds for it at that point. A program appends a ledger entry
only at a point at which it is accepted. A void, and a ledger entry of a
kind for which no design gives an acceptance rule, are accepted at no
point, so a program never appends them. Voids come only from repairs.

A program gives each ledger entry that it appends the field `v` with the
value 1 and the field `by`, and the field `agent` when an agent runs the
program (section 2.8). It can give the fields `branch` and `ts`.

### 2.6 Clones and the shared clone

Each clone of a repository has a ledger ref and a stored ledger of its
own. The shared clone of a repository is the one clone whose stored
ledger the people who work on the repository use as the ledger of the
repository, such as the clone on the host of the repository. The other
clones push their new ledger entries to the shared clone, and they take
in its ledger entries. A ledger entry of a clone is provisional while
the stored ledger of the shared clone does not hold it.

A push makes the shared clone take in the ledger entries of a clone: the
ledger ref of the shared clone changes to the ledger commit of the
clone. A program pushes only when that ledger commit extends the ledger
commit of the shared clone. So each ledger entry of the ledger of the
repository keeps its place, and the ledger of the repository changes
only at its end, other than in a repair.

When another clone pushed first, the ledger commit of a clone does not
extend the ledger commit of the shared clone. The clone then takes in
the ledger entries of the shared clone. Its new ledger commit extends
the ledger commit of the shared clone, so it holds each line of the
shared clone. After these lines, it holds one new line for each
provisional ledger entry that stays, in their order. Such a new line
keeps each member of the old line other than `seq` and `id`; it takes
the next `seq`, and so a new `id`. A provisional ledger entry stays only
when it is accepted at its new point; otherwise, it leaves the ledger.

A git tree object accounts for a line of a chunk when it holds that
line, or when it holds a void whose `dropped` is the `id` of that line.
A line for which the ledger commit of the shared clone accounts is not
provisional: the clone takes the line, or its void, from the shared
clone, and does not put the line after them again.

Taking in is not appending. A program needs no confirmation of a person
to take in a judgment, and a program that an agent runs can take in
ledger entries. A program makes a clone take in ledger entries only
from the shared clone, or the shared clone from another clone. A program
changes the ledger ref of a
git repository only to append, to make a repair, or to take in, and it
never deletes the ledger ref.

For example, the shared clone S holds five ledger entries. The clone A
took them in, and then appended a sixth ledger entry, a. Before A
pushes, the clone B pushes its own sixth ledger entry, b. Now the ledger
commit of A does not extend the ledger commit of S. A takes in the
ledger entries of S: its new ledger holds the five ledger entries, then
b with the `seq` 6, then a with the `seq` 7 and a new `id`, when a is
accepted at the point after b. A program that appended a only when a
person confirmed it does not ask that person again. Then the ledger
commit of A extends the ledger commit of S, and A can push.

### 2.7 Repairs and voids

A repair removes one or more ledger entries from a ledger, and puts a
void where each of them was. A person makes a repair, for example to
remove a ledger entry that holds a secret, or to make a broken ledger
valid. The repair gives the git repository a new ledger commit whose
history is intact:

- Each line that the repair keeps has the same bytes.
- Each ledger entry that the repair removes gives its place to a void
  with the same `seq`, whose `dropped` is the `id` of the removed ledger
  entry, and whose `reason` says why the repair removed it.
- In a broken ledger, a line that holds no ledger entry, such as a line
  that is not a canonical line, gives its place to a void too.

So no ledger entry that stays changes its `seq` or its `id`. Because the
new history is intact, no commit of it holds a ledger entry that the
repair removed: the repair writes each commit of the history again. A
repair of the ledger of the shared clone is the one change of its ledger
ref that does not go to a commit that extends its ledger commit.

A void changes no state, and it cancels no other ledger entry: a void
whose `dropped` names a ledger entry that is still in the ledger changes
nothing. After a repair, each clone takes in the ledger entries of the
shared clone, its voids included. A void accounts for the line that it
replaces, so that line is not provisional, and the clone does not put
it back. Taking in voids is not a repair.

### 2.8 Agents, the job, and trackers

An agent marker is an environment variable that shows that an agent runs
a program, such as a variable that the program that runs an agent sets
for it. The parameter `agent-markers` gives the
names of the agent markers. An agent runs a program when the environment
of its process holds an agent marker, whatever its value. A program
that an agent runs appends no ledger entry other than a definition
entry, and it makes no repair. It can still take in ledger entries.

Only the job appends ledger entries of the kind `delivered`.

A ledger entry can name an external item by its external id, such as
`gh/42`. It holds no data that a program took from a tracker, such as
the title or the state of an issue.

## 3. Parameters

### 3.1 `agent-markers`

The parameter `agent-markers` gives the names of the agent markers. A
binding of it is a finite set of texts, each the name of an environment
variable.

## 4. Definitions

### 4.1 The ledger ref

@term ledger-ref=v1
@cites {changes#{ref-commit=v1, commit=v1}, text#{code-span=v1}}

The ledger ref of a git repository is its ref whose name is
`refs/sinter/ledger`. The ledger commit of a git repository is the commit
of its ledger ref, when its ledger ref has a commit.

### 4.2 Chunk paths

@term chunk-path=v1
@cites text#{
    production=v1, rule-name=v1, hex-digit=v1, text=v1, character=v1,
    code-span=v1,
}

A chunk path is a text that matches the production `chunk-path`, and in
which the two hex digits right after `entries/` are the same as the two
hex digits right after `e-`:

```abnf
chunk-path  = %s"entries/" 2hex-digit "/" %s"e-" 12hex-digit %s".jsonl"
```

### 4.3 Chunks and their lines

@term chunk=v1
@cites {
    changes#{commit-file=v1},
    data-forms#{line-object=v1, canonical-line=v1},
    text#{byte=v1, byte-sequence=v1, utf-8-encoding=v1, 0x-numeral=v1},
    #{chunk-path=v1},
}

A chunk of a git tree object is a regular-file entry among the entries
of that git tree object, at any depth, whose byte path is the UTF-8
encoding of a chunk path. The chunk path of the chunk is that chunk
path. The content of a chunk is the content of the blob that it names.
The lines of a chunk are the byte sequences that remain when its content
is cut right after each byte 0x0A, without an empty byte sequence at the
end. So each line of a chunk, other than the last, ends with the byte
0x0A, and holds no other byte 0x0A. The lines of a git tree object are
the lines of its chunks. The object of a line of a chunk is the line
object whose canonical line the line is, when the line is the canonical
line of a line object.

### 4.4 Entry ids

@term entry-id=v1
@cites {
    data-forms#{
        json-value=v1, canonical-byte-sequence=v1, id-prefix=v1,
        hash-id=v1,
    },
    text#{code-span=v1},
}

The entry id of an object is the hash id, with the id prefix `e-` and 12
hex digits, of the canonical byte sequence of the object that has each
member of that object other than the member `id`, and no other member.

### 4.5 Fields

@term entry-field=v1
@cites {
    rfc/3339,
    ontology#{ledger-entry=v1, person=v1, agent=v1, job=v1, repair=v1},
    changes#{branch-name=v1},
    data-forms#{json-value=v1},
    text#{text=v1, code-span=v1},
    #{entry-id=v1, chunk=v1},
}

A field of a ledger entry is a member of the object of its line that a
design names for ledger entries. The common fields of ledger entries are
these eight fields, with these values:

- `id`, a string: the entry id of the object;
- `kind`, a string: the kind of the ledger entry;
- `v`, an integer of 1 or more: the version of the form of the ledger
  entry, which is 1 for the form of these eight fields;
- `seq`, an integer of 1 or more: the number of the ledger entry in the
  order of the ledger;
- `by`, a string: the person who wrote the ledger entry, the person for
  whom the agent that wrote it acts, or the job;
- `agent`, a string: the agent that wrote the ledger entry;
- `branch`, a string that is a branch name: the branch from which the
  ledger entry was written;
- `ts`, a string: the time at which the ledger entry was written, a text
  that matches the rule `date-time` of RFC 3339, with the letters `T`
  and `Z` in upper case, with `Z` as its time offset, and with no
  fraction of a second, such as `2026-10-31T14:05:09Z`.

The fields of a kind of ledger entry are the fields that a design gives
for the ledger entries of that kind, other than the common fields. The
fields of the kind `void` are `dropped`, a string, the entry id of the
ledger entry that a repair removed, and `reason`, a string, the reason
for which the repair removed it. The writer that a ledger entry records
is the agent that its `agent` names, when it has the member `agent`, and
otherwise the person or the job that its `by` names.

### 4.6 Newer lines

@term newer-line=v1
@cites {
    data-forms#{json-value=v1, json-value-of-a-byte-sequence=v1},
    text#{code-span=v1, whole-number=v1},
    #{chunk=v1},
}

A newer line is a line of a chunk whose JSON value is an object that has
the member `v` with an integer greater than 1 as its value.

### 4.7 Ledger objects

@term ledger-object=v1
@cites {
    changes#{commit=v1, ref-commit=v1, commit-file=v1, ancestry=v1},
    text#{code-span=v1},
    #{ledger-ref=v1, chunk=v1},
}

The ledger objects of a commit are the commit, its git tree object, each
git tree object that a tree entry among the entries of that git tree
object names, at any depth, and each blob that a chunk of that git tree
object names. The ledger objects of a git repository are, when its
ledger ref exists, the git object to which its ledger ref resolves,
through the refs that it names in turn, and, when that git object is a
commit, the ledger objects of that commit. The history objects of a git
repository are its ledger objects, and, for each commit that the ledger
commit reaches, the ledger objects of that commit and each git object
whose object id that commit names on a line of its header that starts
with `parent`, when the file `shallow` does not name that commit.

### 4.8 Valid, broken, and newer ledgers

@term ledger-validity=v1
@cites {
    changes#{commit=v1, ref-commit=v1, commit-file=v1},
    data-forms#{canonical-line=v1, line-object=v1, json-value=v1},
    text#{
        whole-number=v1, character=v1, utf-8-encoding=v1, code-span=v1,
    },
    #{
        ledger-ref=v1, chunk-path=v1, chunk=v1, entry-id=v1,
        newer-line=v1, ledger-object=v1,
    },
}

A git tree object is newer when one of its lines is a newer line. A git
tree object that is not newer is a valid ledger tree when, and only
when, each of these is true:

1. No two of its entries, at any depth, have the same byte path.
2. Each of its entries, at any depth, is one of these: a chunk whose
   mode is the whole number that 100644 writes in base 8; for a chunk,
   the tree entry whose byte path is the UTF-8 encoding of the first 10
   characters of its chunk path; or the tree entry whose byte path is
   the UTF-8 encoding of `entries`.
3. The content of each of its chunks has at least one line, and each
   line of each of its chunks is the canonical line of a line object.
4. The object of each of its lines has the member `id` with a string,
   the member `kind` with a string, the member `v` with the integer 1,
   and the member `seq` with an integer of 1 or more.
5. The value of `id` of the object of each of its lines is the entry id
   of that object.
6. The chunk path of each of its chunks is the value of `id` of the
   object of the first line of that chunk, then `.jsonl`, after its
   first 11 characters.
7. No two of its lines have objects with the same value of `id`.
8. For the number n of its lines, the values of `seq` of the objects of
   its lines are the whole numbers from 1 to n, each once.

The ledger of a git repository that holds its ledger objects is newer,
valid, or broken:

- It is newer when, and only when, its ledger ref has a commit whose git
  tree object is newer.
- It is valid when, and only when, its ledger ref does not exist, or its
  ledger ref has a commit whose git tree object is a valid ledger tree.
- It is broken when, and only when, it is neither newer nor valid: its
  ledger ref exists and has no commit, or the git tree object of its
  ledger commit is neither newer nor a valid ledger tree.

### 4.9 Stored ledgers

@term stored-ledger=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1},
    text#{code-span=v1},
    #{ledger-ref=v1, chunk=v1, ledger-validity=v1},
}

The ledger entry of a line of a valid ledger tree whose object has, as
its `kind`, one of the eight texts `task`, `plan`, `approval`, `decline`,
`done`, `abandoned`, `delivered`, and `void`, is the ledger entry of that
kind whose object is the object of that line. Each other line of a valid
ledger tree has no ledger entry. The stored ledger of a git repository
whose ledger is valid is the sequence of the ledger entries of the lines
of the git tree object of its ledger commit, in increasing order of the
`seq` of their objects, or the empty sequence when its ledger ref does
not exist. The ledger of a clone of a repository is the stored ledger of
that clone.

### 4.10 Extensions

@term ledger-extension=v1
@cites {changes#{commit=v1}, #{chunk=v1}}

A commit d extends a commit c when, and only when, d is c, or d has
exactly one parent, that parent extends c, and each line of the git tree
object of that parent is a line of the git tree object of d.

### 4.11 Intact histories

@term intact-history=v1
@cites {
    changes#{commit=v1, ancestry=v1},
    #{ledger-ref=v1, ledger-validity=v1, ledger-extension=v1},
}

The history of the ledger of a git repository is intact when, and only
when, its ledger ref does not exist, or its ledger ref has a commit c
such that c extends a commit that has no parent, and the git tree object
of each commit that c reaches is a valid ledger tree.

### 4.12 Accepted ledger entries

@term accepted-entry=v1
@cites ontology#{ledger=v1, ledger-entry=v1, repair=v1}

The acceptance rule of a kind of ledger entry is the condition, which a
design gives for that kind, under which a ledger entry of that kind can
stand at a point of a ledger. A ledger entry is accepted at a point of a
ledger when, and only when, the acceptance rule of its kind holds for
that ledger entry at that point. A ledger entry of the kind `void`, and
a ledger entry of a kind for which no design gives an acceptance rule,
are accepted at no point.

### 4.13 The shared clone

@term shared-clone=v1
@cites {
    ontology#{ledger=v1, person=v1},
    #{stored-ledger=v1},
}

The shared clone of a repository is the one clone of the repository
whose stored ledger the people who work on the repository use as the
ledger of the repository, such as the clone on the host of the
repository. The ledger of a repository is the stored ledger of its
shared clone.

### 4.14 Take-in commits

@term take-in-commit=v1
@cites {
    changes#{commit=v1, ancestry=v1},
    text#{whole-number=v1, code-span=v1},
    #{
        ledger-ref=v1, chunk=v1, entry-id=v1, ledger-validity=v1,
        ledger-extension=v1,
    },
}

A git tree object accounts for a line of a chunk when, and only when,
one of its lines is that line, or the object of one of its lines has the
member `kind` with the value `void` and the member `dropped` with the
value of `id` of the object of that line.

For a clone A and another clone B of a repository, let b be the ledger
commit of B, and let n be the number of the lines of the git tree object
of b. A commit d is a take-in commit of B into A when, and only when, d
is b, or each of these is true:

1. d extends b, and the git tree object of each commit that d reaches
   and that b does not reach is a valid ledger tree.
2. The lines of the git tree object of d are the lines of the git tree
   object of b, and k more lines, for a whole number k of 1 or more.
3. The objects of these k lines are, in increasing order of their
   `seq`, the objects that come from k lines of the git tree object of
   the ledger commit of A for which the git tree object of b does not
   account, in increasing order of the `seq` of their objects. The object that
   comes from a line has each member of the object of that line other
   than `seq` and `id`, the member `seq` with the value n + i for the
   i-th of these k objects, and the member `id` with its entry id as
   its value.

A clone A takes in the ledger entries of a clone B when its ledger ref
changes to a take-in commit of B into A.

### 4.15 Agent markers

@term agent-marker=v1
@cites {ontology#{parameter=v1, agent=v1}, text#{text=v1, code-span=v1}}

An agent marker of a process is an environment variable of the process
whose name is a text of the binding of the parameter `agent-markers`,
whatever the value of that variable. An agent runs a program when, and
only when, the environment of the process of the program holds an agent
marker.

## 5. Requirements

### 5.1 The ledger entries of a stored ledger

@req give-stored-ledgers=v1
@cites {
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1},
    #{stored-ledger=v1, ledger-validity=v1, ledger-object=v1},
}

When it gives the ledger entries of the stored ledger of a git
repository that holds its ledger objects, in an undisturbed repository
read, a conforming program must give exactly the ledger entries of that
stored ledger, in their order, when the ledger of the git repository is
valid, and no ledger entry when that ledger is broken or newer.

### 5.2 The validation of ledgers

@req validate-ledgers=v1
@cites {
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1, result=v1},
    #{ledger-validity=v1, ledger-object=v1},
}

When it gives a result for whether the ledger of a git repository that
holds its ledger objects is valid, in an undisturbed repository read, a
conforming program must give exactly one result: "valid" when that
ledger is valid, "broken" when it is broken, and "newer" when it is
newer.

### 5.3 The validation of histories

@req validate-histories=v1
@cites {
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1, result=v1},
    #{intact-history=v1, ledger-validity=v1, ledger-object=v1},
}

When it gives a result for whether the history of the ledger of a git
repository that holds its history objects is intact, in an undisturbed
repository read, a conforming program must give exactly one result when
that ledger is not newer: "valid" when that history is intact, and
"invalid" when it is not. When that ledger is newer, it must give
neither result.

### 5.4 No state from a ledger that a program cannot read

@req give-no-states-from-unreadable-ledgers=v1
@cites {
    ontology#{state=v1, ledger=v1},
    text#{conforming-program=v1},
    #{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
}

A conforming program must give no state at a point of the ledger of a
clone whose ledger is broken or newer, or that does not hold its ledger
objects.

### 5.5 Members that no design names

@req ignore-unknown-members=v1
@cites {
    ontology#{state=v1, ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1, code-span=v1},
    #{entry-field=v1, stored-ledger=v1},
}

A conforming program must give the same states at the same points of two
ledgers that differ only in members of the objects of their ledger
entries that are neither common fields nor fields of the kinds of these
ledger entries, and in the values of `id` that these members change.

### 5.6 Appends at the end of the ledger

@req append-entries-at-end=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1},
    changes#{commit=v1},
    text#{conforming-program=v1, whole-number=v1, code-span=v1},
    #{ledger-ref=v1, chunk=v1, ledger-validity=v1},
}

When a conforming program appends ledger entries to the stored ledger of
a git repository, it must change the ledger ref of that git repository,
from its commit c or from not existing, to a commit d such that each of
these is true:

1. d has c as its only parent, or no parent when the ledger ref did not
   exist.
2. The git tree object of d is a valid ledger tree.
3. The lines of the git tree object of d are the lines of the git tree
   object of c, when the ledger ref existed, and one line for each
   ledger entry that the program appends.
4. For the number n of the lines of the git tree object of c, or 0 when
   the ledger ref did not exist, the objects of the lines of the
   appended ledger entries have the values n + 1, n + 2, and so on of
   `seq`, in the order in which the program appends these ledger
   entries.

### 5.7 Only accepted ledger entries

@req append-only-accepted-entries=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1},
    #{accepted-entry=v1},
}

A conforming program must append a ledger entry to a ledger only at a
point of that ledger at which that ledger entry is accepted.

### 5.8 The common fields of appended ledger entries

@req write-entry-fields=v1
@cites {
    ontology#{ledger-entry=v1},
    text#{conforming-program=v1, code-span=v1},
    #{entry-field=v1, agent-marker=v1},
}

A conforming program must append only ledger entries whose objects have
the member `v` with the integer 1 and the member `by` with a string,
whose members `agent`, `branch`, and `ts`, each when they have it, hold
a value of the form of that common field, and which have the member
`agent` when the environment of the process of the program holds an
agent marker.

### 5.9 The ways in which a ledger ref changes

@req limit-ledger-ref-changes=v1
@cites {
    ontology#{repair=v1},
    text#{conforming-program=v1},
    #{ledger-ref=v1, shared-clone=v1, take-in-commit=v1},
}

A conforming program must change the ledger ref of a git repository only
to append ledger entries, to make a repair, or to make the git
repository, as a clone of a repository, take in the ledger entries of
another clone of that repository when one of these two clones is the
shared clone. It must not delete a ledger ref.

### 5.10 The ledger of the repository

@req keep-shared-ledger-entries=v1
@cites {
    ontology#{repair=v1},
    text#{conforming-program=v1},
    #{ledger-ref=v1, shared-clone=v1, ledger-extension=v1},
}

Other than in a repair, a conforming program must change the ledger ref
of the shared clone of a repository from a commit c only to a commit that
extends c.

### 5.11 Taking in

@req take-in-ledgers=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1},
    #{
        ledger-ref=v1, take-in-commit=v1, stored-ledger=v1,
        accepted-entry=v1,
    },
}

When a conforming program makes a clone A take in the ledger entries of
another clone B, it must change the ledger ref of A to a take-in commit
of B into A in which each line that is not a line of the ledger commit
of B has a ledger entry, and that ledger entry is accepted at its
point.

### 5.12 Repairs in place

@req repair-in-place=v1
@cites {
    ontology#{repair=v1},
    text#{conforming-program=v1, code-span=v1},
    #{ledger-ref=v1, chunk=v1, ledger-validity=v1, intact-history=v1},
}

When a conforming program makes a repair of the ledger of a git
repository, it must change the ledger ref of that git repository from
its commit c to a commit d such that each of these is true:

1. The git tree object of d is a valid ledger tree, and the history of
   the ledger of the git repository is intact after the change.
2. Each line of the git tree object of c that the repair keeps is a line
   of the git tree object of d.
3. The object of each other line of the git tree object of d has the
   member `kind` with the value `void`.
4. When the git tree object of c is a valid ledger tree, the git tree
   object of d has, for each line of the git tree object of c that the
   repair removes, exactly one line whose object has the member `kind`
   with the value `void`, the `seq` of the object of the removed line,
   and the member `dropped` with the `id` of the object of the removed
   line, and no other line that is not a line of the git tree object of
   c.

### 5.13 The ledger entries that agents write

@req limit-agents-to-definitions=v1
@cites {
    ontology#{definition-entry=v1, repair=v1, ledger=v1},
    text#{conforming-program=v1},
    #{agent-marker=v1},
}

When the environment of its process holds an agent marker, a conforming
program must append to a ledger no ledger entry other than a definition
entry, and must make no repair.

### 5.14 The writer of `delivered` ledger entries

@req leave-delivered-entries-to-job=v1
@cites {
    ontology#{job=v1, job-record=v1, ledger=v1},
    text#{conforming-program=v1},
}

A conforming program must append a ledger entry of the kind `delivered`
to a ledger only in an execution that is the job.

### 5.15 No data from trackers

@req keep-tracker-data-out=v1
@cites {
    ontology#{external-item=v1, ledger-entry=v1},
    text#{conforming-program=v1},
}

A conforming program must append to a ledger no ledger entry that holds
data that the program took from a service that holds external items,
such as the title or the state of an issue.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`ledger.test-vectors.jsonl`](ledger.test-vectors.jsonl), in the same
folder as this design. A vector is an input and what a conforming
program gives for it. Each vector follows from the requirements and adds
nothing to them. The vectors are in two groups, `histories` and
`ledgers`, and each group has a subsection below. The subsection names
the requirements that the vectors of the group follow from, and it
describes their inputs, results, and values. No vector follows from the
requirements `give-no-states-from-unreadable-ledgers`,
`ignore-unknown-members`, `append-entries-at-end`,
`append-only-accepted-entries`, `write-entry-fields`,
`limit-ledger-ref-changes`, `keep-shared-ledger-entries`,
`take-in-ledgers`, `repair-in-place`, `limit-agents-to-definitions`,
`leave-delivered-entries-to-job`, and `keep-tracker-data-out`.

Each requirement from which vectors follow applies only when a program
gives the thing that it names, such as a result for whether a ledger is
valid. So a vector holds a program only to what the program gives for
the input. The input of each vector stands for a git repository that
holds its ledger objects, or its history objects for the group
`histories`, and for an undisturbed repository read of it.

The file is a [test-vector set](sinter:data-forms#test-vector-set=v1).
Each line of the file is the
[canonical byte sequence](sinter:data-forms#canonical-byte-sequence=v1)
of one JSON object, then the byte 0x0A, so each line is a JSON text, as
RFC 8259 defines it. The file has three kinds of line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `histories`,
   `ledgers`. Its JSON object has two members: `group`, the name of the
   group, as a JSON string, and `rev`, the revision of the group.
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
  result for the input.
- `values`: a JSON object that holds what a conforming program gives for
  the input, other than the result. The subsection of the group says
  which of these things a conforming program gives in each case.
- `note`: an explanation of the vector, as a JSON string, which a
  conforming program does not give. A vector has this member only when
  it has an explanation.

No vector has the member `needs`: the vectors of this design have no
need names.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of the set line is the
revision of the whole set, the revision of a group line is the revision
of the group, and the revision of a vector line is the revision of the
vector. A revision rises, to a greater number after its `v`, when the
vectors that it covers change, join, or leave. When the text of this
section, other than its headings and the vector lines that it shows,
changes, the revisions of every vector, every group, and the set rise.
When only the note of a vector changes, no revision rises. A program
does not need the revisions to run the vectors.

Inside the members `input`, `result`, and `values`, each JSON value that
the subsection of a group names as a text, a byte sequence, a git tree
object, or a sequence has this form:

- A text, such as a result, the name of a commit, or an entry id, is a
  JSON string whose characters are the characters of the text, in
  order.
- A byte sequence, such as the name of an entry of a git tree object or
  the content of a blob, is a JSON string when it is the UTF-8 encoding
  of a text: the JSON string of that text. Otherwise, it is a JSON
  object with one member, `bytes`, whose value is a JSON string of hex
  digits: for each byte, in order, the hex digit of the whole-number
  quotient of the byte divided by 16, then the hex digit of the
  remainder.
- A git tree object is a JSON array with one JSON object for each entry
  that the git tree object lists, in the order in which it lists them.
  The JSON object of an entry has the member `name`, the name of the
  entry, a byte sequence, and the member `mode`, the characters of the
  mode of the entry, as the git tree object holds them, as a text, such
  as `100644` or `40000`. The JSON object of a tree entry also has the
  member `entries`: the git tree object that the tree entry names, in
  the same form. The JSON object of a regular-file entry can also have
  one of two members for the content of its blob: `content`, the
  content, a byte sequence; or `lines`, a JSON array of JSON objects,
  each of which stands for a line object, for the content that is the
  canonical lines of these line objects, one after another, in the
  order of the array. Only a regular-file entry whose byte path is not
  the UTF-8 encoding of a chunk path has neither member, and its content
  has no effect on the vector.
- A sequence, such as the ledger entries of a stored ledger, is a JSON
  array of its elements, in order.

### 6.1 Ledgers

The group `ledgers` holds the vectors of the requirements
`give-stored-ledgers` and `validate-ledgers`. Each vector gives the
ledger ref of a git repository, whether its ledger is valid, broken, or
newer, and the ledger entries of its stored ledger.

- `input`: a JSON object. When the ledger ref exists, its member `ref`
  is a JSON object with one member: `entries`, the git tree object of
  the ledger commit, when the ledger ref has a commit; or `other`, the
  name of the git object to which the ledger ref resolves, a text, when
  that git object is not a commit. When the ledger ref does not exist,
  the input has no member `ref`.
- `result`: "valid" when the ledger is valid, "broken" when it is
  broken, and "newer" when it is newer.
- `values`: when the ledger is valid, a JSON object with one member,
  `entries`: the ledger entries of the stored ledger, as a sequence, in
  which each ledger entry is its entry id. When the ledger is broken or
  newer, the empty JSON object, `{}`.

When a conforming program gives a result for whether the ledger is
valid, it gives the result that `result` holds, and no other result.
When it gives the ledger entries of the stored ledger, it gives the
ledger entries that `entries` names, in their order, and no other
ledger entry, and it gives no ledger entry when `values` is `{}`.

```
{"group":"ledgers","input":{"ref":{"entries":[{"entries":[{"entries":[{"lines":[{"by":"Ada Lovelace <ada@example.com>","id":"e-0001d7a41cb7","kind":"task","seq":1,"v":1}],"mode":"100644","name":"e-0001d7a41cb7.jsonl"}],"mode":"40000","name":"00"}],"mode":"40000","name":"entries"}]}},"n":4,"note":"one chunk with one line","result":"valid","rev":"v1","values":{"entries":["e-0001d7a41cb7"]}}
{"group":"ledgers","input":{"ref":{"entries":[{"entries":[{"entries":[{"content":"{\"by\":\"Ada Lovelace <ada@example.com>\",\"id\":\"e-0001d7a41cb7\",\"kind\":\"task\",\"seq\":1,\"v\":1}\r\n","mode":"100644","name":"e-0001d7a41cb7.jsonl"}],"mode":"40000","name":"00"}],"mode":"40000","name":"entries"}]}},"n":20,"note":"a carriage return before the line feed","result":"broken","rev":"v1","values":{}}
```

### 6.2 Histories

The group `histories` holds the vectors of the requirement
`validate-histories`. Each vector gives the commits of the history of a
ledger, each with its parents and its git tree object, and whether the
history is intact.

- `input`: a JSON object with two members. `commit` is the ledger
  commit, a text. `commits` is a JSON object with one member for each
  commit that the ledger commit reaches: its key is the name of the
  commit, and its value is a JSON object with two members: `parents`,
  the parents of the commit, as a sequence of the names of the commits;
  and `entries`, the git tree object of the commit.
- `result`: "valid" when the history is intact, and "invalid" when it is
  not. A vector whose ledger is newer has no member `result`.
- `values`: only a vector whose ledger is newer has this member: the
  empty JSON object, `{}`.

When a conforming program gives a result for whether the history is
intact, it gives the result that `result` holds, and no other result. It
gives neither result when `values` is `{}`.

```
{"group":"histories","input":{"commit":"b","commits":{"a":{"entries":[{"entries":[{"entries":[{"lines":[{"by":"Ada Lovelace <ada@example.com>","id":"e-0001d7a41cb7","kind":"task","seq":1,"v":1}],"mode":"100644","name":"e-0001d7a41cb7.jsonl"}],"mode":"40000","name":"00"}],"mode":"40000","name":"entries"}],"parents":[]},"b":{"entries":[{"entries":[{"entries":[{"lines":[{"by":"Ada Lovelace <ada@example.com>","id":"e-0001d7a41cb7","kind":"task","seq":1,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-a428b9073a24","kind":"task","seq":2,"v":2}],"mode":"100644","name":"e-0001d7a41cb7.jsonl"}],"mode":"40000","name":"00"}],"mode":"40000","name":"entries"}],"parents":["a"]}}},"n":52,"note":"the ledger is newer, so a program gives no result for its history","rev":"v1","values":{}}
```
