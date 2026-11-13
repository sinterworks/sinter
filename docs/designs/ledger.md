<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# The ledger
@design ledger=v1
@cites text=v1
@cites data-forms=v1
@cites ontology=v1
@cites changes=v1
@cites gitdoc/git-config
@cites rfc/3339
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies how a git repository stores its ledger on the ref `refs/sinter/ledger`: chunks of canonical lines, entry ids, `seq`, the common fields of ledger entries, versions, and voids; when a stored ledger is valid, broken, or newer, and when its history is intact; acceptance, appends, the shared clone, taking in, and repairs; agent markers and the writers of ledger entries; and requirements for conforming programs that read, append to, take in, and repair the ledger.

The ledger is a sequence of ledger entries. Each ledger entry records one
event, such as one approval that a person gave. A git repository stores
its ledger in git objects, on the ref `refs/sinter/ledger`. The commit
of that ref holds files of canonical lines, and each line holds one
ledger entry. Each clone stores a ledger of its own. The shared clone of
a clone, such as the git repository on the host of the project, holds
the shared ledger. A clone pushes its new ledger entries to its shared
clone, and it takes in the ledger entries of its shared clone.

A kind of ledger entry has an acceptance rule: the condition under which
a ledger entry of that kind can stand at a point of a ledger. A program
appends a ledger entry only at a point at which the ledger entry is
accepted. When another clone pushed first, a clone takes in the ledger
entries of its shared clone, and each ledger entry that it has not
pushed moves to a later point or leaves its ledger.

From the Ontology (`ontology`), the design takes ledger entries, the
ledger with its order and its points, the eight kinds of ledger entry,
definition entries, judgments, records of the job, voids, and repairs;
persons, agents, and the job; states, states at a point of a ledger, and
external items; and parameters with their bindings. From Changes
(`changes`), it takes git repositories, commits and their parents, the
file `shallow`, refs and the commits of refs, git tree objects with their
entries, the names, byte paths, and modes of these entries, tree entries,
regular-file entries, blobs and their contents, reach and ancestry,
branch names, the git configuration, repository reads, and undisturbed
repository reads. From Data forms (`data-forms`), it takes JSON values,
objects and their members, line objects, canonical byte sequences,
canonical lines, the JSON values of byte sequences, hash ids with their
id prefixes, and test-vector sets: the file that holds the conformance
vectors of the design is one. From Text and notation (`text`), it takes
texts, characters, hex digits, whole numbers, bytes, byte sequences,
UTF-8 encodings, code spans, productions, and what a conforming program,
an input, and a result are.

From the page git-config of git's documentation, the design takes the
remotes of a git repository and the setting `remote.<name>.url`. From
RFC 3339, it takes the rule `date-time` of its ABNF, for the time at
which a ledger entry was written. The production `chunk-path` is
written in ABNF, the notation of RFC 5234, with the case-sensitive
strings `%s"…"` of RFC 7405. From RFC 8259, the design takes JSON texts,
with their objects, members, arrays, strings, and numbers: each line of
the file that holds the conformance vectors of the design is a JSON
text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [ledger](sinter:ontology#ledger=v1) | a sequence of ledger entries, in the order in which they were appended |
| [point of a ledger](sinter:ontology#ledger=v1) | a place between two ledger entries of a ledger, before the first, or after the last; the point of a ledger entry is the point right before it |
| [ledger entry](sinter:ontology#ledger-entry=v1) | a record of one event, such as one approval; each ledger entry has one of the eight kinds `task`, `plan`, `approval`, `decline`, `done`, `abandoned`, `delivered`, and `void` |
| [definition entry](sinter:ontology#definition-entry=v1) | a ledger entry of the kind `task` or `plan` |
| [judgment](sinter:ontology#judgment=v1) | a ledger entry of the kind `approval`, `decline`, `done`, or `abandoned`: a decision of a person |
| [record of the job](sinter:ontology#job-record=v1) | a ledger entry of the kind `delivered` |
| [repair](sinter:ontology#repair=v1), [void](sinter:ontology#repair=v1) | a repair removes ledger entries from a ledger and puts one void, a ledger entry of the kind `void`, where each of them was |
| [person](sinter:ontology#person=v1), [agent](sinter:ontology#agent=v1), [job](sinter:ontology#job=v1) | a human who works on a repository; a program that uses a language model to write texts as one person runs it; the execution of a conforming program that continuous integration starts at each push to the default branch |
| [state](sinter:ontology#state=v1) | a named condition of an item, an edge, a wait, or a subject of approval, such as approved or done; a state at a point of a ledger depends on the ledger entries before that point |
| [parameter](sinter:ontology#parameter=v1) | a word whose value a design leaves open; configuration gives its binding |
| clone | a git repository that holds a copy of the history of another git repository, such as the git repository in which a person works, made from the git repository on the host of a project |
| push | to send git objects to another git repository and change one of its refs |
| remote | a name, such as `origin`, by which the git configuration of a git repository gives another git repository |
| [ref](sinter:changes#ref-commit=v1), [commit of a ref](sinter:changes#ref-commit=v1) | a name, such as `refs/heads/main`, that points to a git object or names another ref; the commit to which a ref resolves, when it resolves to a commit |
| [git tree object](sinter:changes#commit-file=v1), [entry of a git tree object](sinter:changes#commit-file=v1), [byte path](sinter:changes#commit-file=v1) | a git object that lists entries; each entry has a name, a mode, and a git object; the byte path of an entry is the names on the way to it, with the byte of `/` between each two of them |
| [tree entry](sinter:changes#commit-file=v1), [regular-file entry](sinter:changes#commit-file=v1) | an entry of a git tree object that names a git tree object; an entry that names the blob of a regular file, with a mode such as 100644 or 100755 |
| [reach](sinter:changes#ancestry=v1) | a commit reaches itself, each of its parents, each parent of each of them, and so on |
| [ledger ref](sinter:#ledger-ref=v1), [ledger commit](sinter:#ledger-ref=v1) | the ref `refs/sinter/ledger` of a git repository; the commit of that ref |
| [chunk](sinter:#chunk=v1), [chunk path](sinter:#chunk-path=v1) | a regular-file entry of a git tree object at a byte path of the form `entries/<hh>/<id>.jsonl`, which holds lines of ledger entries |
| [line of a chunk](sinter:#chunk=v1), [object of a line](sinter:#chunk=v1) | a part of the content of a chunk that ends with the byte 0x0A, or the part after the last 0x0A; the line object whose canonical line the line of a chunk is |
| [canonical line](sinter:data-forms#canonical-line=v1), [line object](sinter:data-forms#line-object=v1) | the canonical byte sequence of a line object, then the byte 0x0A; an object in which the value of each member is a string, an integer, a boolean, an array of these, or an array of objects whose members hold these |
| [member](sinter:data-forms#json-value=v1) | a key and a value of an object, such as the member `seq` with the value 7 |
| [entry id](sinter:#entry-id=v1) | `e-` and the first 12 hex digits of the SHA-256 hash of the canonical byte sequence of an object without its member `id` |
| [field](sinter:#entry-field=v1), [common field](sinter:#entry-field=v1), [field of a kind](sinter:#entry-field=v1) | a member of the object of a ledger entry that a design names; the fields `id`, `kind`, `v`, `seq`, `by`, `agent`, `branch`, and `ts`, which are the same for each kind; the other fields that a design gives for one kind |
| [writer that a ledger entry records](sinter:#entry-field=v1) | the agent that its `agent` names, or else the person or the job that its `by` names |
| [newer line](sinter:#newer-line=v1) | a line of a chunk whose JSON value is an object with a `v` greater than 1 |
| [ledger objects](sinter:#ledger-object=v1), [history objects](sinter:#ledger-object=v1) | the git objects of the ledger of a git repository: the object of its ledger ref, the git tree objects of that commit, and the blobs of its chunks; and these git objects for each commit that the ledger commit reaches, with their parents |
| [valid ledger tree](sinter:#ledger-validity=v1) | a git tree object that holds chunks of ledger entries, and nothing else, in the form of section 2.3 |
| [valid](sinter:#ledger-validity=v1), [broken](sinter:#ledger-validity=v1), [newer](sinter:#ledger-validity=v1) | the three conditions of the ledger of a git repository: its ledger ref does not exist or its ledger commit holds a valid ledger tree; it fails a check; its ledger commit holds a newer line |
| [stored ledger](sinter:#stored-ledger=v1) | the ledger entries of the lines of the ledger commit of a git repository, in the order of their `seq`: the ledger of that git repository |
| [extend](sinter:#ledger-extension=v1) | a commit extends a commit c when it is c, or when the chain of its single parents leads to c and each commit of the chain holds each line of its parent |
| [intact](sinter:#intact-history=v1) | the history of a ledger is intact when its ledger ref does not exist, or when its ledger commit extends a commit with no parent and the git tree object of each commit that it reaches is a valid ledger tree |
| [acceptance rule](sinter:#accepted-entry=v1), [accepted](sinter:#accepted-entry=v1) | the condition under which a ledger entry of one kind can stand at a point of a ledger; a ledger entry is accepted at a point when the acceptance rule of its kind holds for it there |
| [shared clone](sinter:#shared-clone=v1), [shared ledger](sinter:#shared-clone=v1) | the git repository that a clone names by the remote whose name the parameter `ledger-remote` gives, such as the git repository on the host of a project; the stored ledger of that git repository |
| [account for](sinter:#take-in-commit=v1) | a git tree object accounts for a line of a chunk when it holds that line, or a void that replaces it |
| provisional | a line of the ledger commit of a clone is provisional while the ledger commit of its shared clone does not account for it, because the clone has not pushed it yet |
| [take in](sinter:#take-in-commit=v1), [take-in commit](sinter:#take-in-commit=v1) | a clone takes in the ledger entries of its shared clone when its ledger ref changes to a take-in commit: a commit that holds the lines of the shared clone and, after them, a new line for each provisional line that stays; a shared clone takes in the ledger entries of a clone when a push changes its ledger ref to the ledger commit of that clone |
| [agent marker](sinter:#agent-marker=v1) | an environment variable whose name the parameter `agent-markers` gives, which shows that an agent runs a program |
| environment | the environment variables of a process |
| tracker | a service that holds external items, such as the issues of the host of a project |

## 2. The ledger and its storage

### 2.1 The ledger ref and its chunks

A git repository stores the ledger entries of its ledger in git objects.
The ledger ref of a git repository is its ref `refs/sinter/ledger`. The
commit of the ledger ref is the ledger commit. No branch and no working
tree holds the ledger, so a file tool that edits the files of a working
tree does not change it. When the ledger ref does not exist, the ledger
of the git repository is empty.

The git tree object of the ledger commit holds the ledger entries in
chunks. A chunk is a regular file at a chunk path: `entries/`, two hex
digits, `/`, an entry id, and `.jsonl`, such as
`entries/5b/e-5b1c0a9d2e11.jsonl`. The entry id in the chunk path is the
`id` of the first line of the chunk, and the two hex digits are the two
hex digits right after its `e-`. The mode of each chunk is 100644, in
base 8. The git tree object holds only these things:

| byte path | git object |
|---|---|
| `entries` | a git tree object, when the git tree object holds at least one chunk |
| `entries/<hh>` | a git tree object, for each two hex digits `<hh>` of the chunk path of a chunk |
| `entries/<hh>/<id>.jsonl` | a chunk |

So each folder holds at least one chunk. A git tree object with no chunk
holds nothing. A symbolic link and a submodule at a chunk path are not
chunks. A regular file at a chunk path with another mode, such as an
executable file, is a chunk, and it makes the ledger broken. For
example, a ledger of 87 ledger entries can have two chunks:

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
any source, such as the settings of git.

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
no state from a ledger that holds a newer line, and it appends nothing
to such a ledger, because it cannot know how the newer form changes the
states.

### 2.3 Valid, broken, and newer ledgers

The ledger objects of a git repository are the git object to which its
ledger ref resolves, and, when that git object is a commit, its git tree
object, the git tree objects inside it, and the blobs of its chunks. A
git repository can lack some of them, as a partial clone can lack
blobs. For such a git repository, a program gives no result for whether
its ledger is valid, no ledger entry of it, and no state at a point of
it.

The ledger of a git repository that holds its ledger objects is newer,
valid, or broken. It is newer when a line of a chunk of the git tree
object of the ledger commit is a newer line. Otherwise, it is valid when
the ledger ref does not exist, or when the git tree object of the ledger
commit is a valid ledger tree. A valid ledger tree meets each of these
conditions:

1. No two of its entries, at any depth, have the same byte path.
2. The name of none of its entries, at any depth, holds the byte of `/`.
3. Its entries, at any depth, are its chunks, each with the mode 100644
   in base 8; for each chunk, the tree entry `entries/<hh>` for the two
   hex digits `<hh>` of its chunk path; and, when it has a chunk, the
   tree entry `entries`.
4. The content of each chunk has at least one line, and each line of a
   chunk is a canonical line.
5. The object of each line has the member `id` with a string, the
   member `kind` with a string, the member `v` with the integer 1, and
   the member `seq` with an integer of 1 or more.
6. The `id` of the object of each line is the entry id of that object.
7. The chunk path of each chunk ends with the `id` of its first line and
   then `.jsonl`.
8. No two lines of its chunks have the same `id`.
9. For its number n of lines, the values of `seq` are the whole numbers
   from 1 to n, each once.

The ledger of a git repository that is neither newer nor valid is
broken: its ledger ref exists and has no commit, such as a ledger ref
that points to a tag object, or the git tree object of the ledger commit
fails one of the conditions. A program gives no state from a broken
ledger, and a repair (section 2.7) makes it valid again. A program that
checks the ledger of a git repository can give one of three results:
"valid", "broken", or "newer".

The stored ledger of a git repository whose ledger is valid is the
sequence of the ledger entries of the lines of its ledger commit, in the
order of their `seq`. The stored ledger is the ledger of the git
repository: a program that gives the states of a git repository gives
the states at the points of its stored ledger. For example, a ledger
commit holds three lines: the `seq` 3 in the first chunk, the `seq` 1
and the `seq` 2 in the second chunk. The line with the `seq` 2 has the
kind `pin`, which is not one of the eight kinds. The stored ledger then
holds two ledger entries: the ledger entry of the `seq` 1, and then the
ledger entry of the `seq` 3.

When another process changes the ledger ref or a git object of the
ledger during a read, what a program gives in that read is not
specified, and each guarantee of section 5 still holds.

### 2.4 Extensions and intact histories

Each commit of the history of a ledger ref, other than the first, has
one parent: the ledger commit before it. A commit d extends a commit c
when d is c, or when d has exactly one parent, that parent extends c,
and the git tree object of d holds each line of the git tree object of
that parent with the same bytes. So when a commit extends another
commit, it holds each of its ledger entries, with the same `seq` and the
same `id`.

The history of the ledger of a git repository is intact when its ledger
ref does not exist, or when the ledger commit extends a commit that has
no parent, and the git tree object of each commit that the ledger commit
reaches is a valid ledger tree. A program that checks the history gives
the result "valid" when the history is intact, and "invalid" when it is
not. For a newer ledger, it gives neither result. The history objects
of a git repository are its ledger objects, and, for each commit that
the ledger commit reaches, the ledger objects of that commit and the git
objects that it names as its parents. A commit that the file `shallow`
names has no parents, so in a shallow clone the history ends at such a
commit.

The states at the points of a ledger depend only on the lines of the
ledger commit. So two clones whose ledger commits hold the same lines
have the same ledger, whatever history each of them holds.

### 2.5 Appends and acceptance

A program appends ledger entries only to a ledger that is valid. It
writes new commits. The first of them has the ledger commit as its
parent, or no parent when the ledger ref does not exist, and each other
has the commit before it as its parent. The git tree object of each new
commit is a valid ledger tree, and it holds each line of the commit
before it with the same bytes. The last new commit holds one new line
for each new ledger entry. When the ledger commit has n lines, the new
ledger entries take the `seq` n + 1, n + 2, and so on, in the order in
which the program appends them. The program then changes the ledger ref
to the last new commit, which extends the ledger commit.

A kind of ledger entry other than `void` can have an acceptance rule:
the condition, which a design gives for that kind, under which a ledger
entry of that kind can stand at a point of a ledger. For example, an
acceptance rule can refuse a ledger entry that the ledger entries before
the point make out of date. A ledger entry is accepted at a point when
the acceptance rule of its kind holds for it at that point. A program
appends a ledger entry only at a point at which it is accepted. A void,
and a ledger entry of a kind for which no design gives an acceptance
rule, are accepted at no point, so a program never appends them. Voids
come only from repairs.

A program gives each ledger entry that it appends the field `by`, and
the field `agent` when an agent runs the program (section 2.8). It can
give the fields `branch` and `ts`.

### 2.6 The shared clone and taking in

Each clone has a ledger ref and a stored ledger of its own. The
parameter `ledger-remote` gives the name of a remote, such as `origin`.
The shared clone of a clone is the git repository that the remote of
that name gives, as the setting `remote.<name>.url` of its git
configuration gives it, such as the git repository on the host of the
project. A clone whose git configuration gives no such remote has no
shared clone. The shared ledger of a clone is the stored ledger of its
shared clone.

A line of the ledger commit of a clone is provisional while the ledger
commit of its shared clone does not account for it. A git tree object
accounts for a line of a chunk when it holds that line, or when it holds
a void whose `dropped` is the `id` of that line. So a line that a repair
of the shared clone replaced with a void is not provisional.

A push makes the shared clone of a clone take in the ledger entries of
the clone: the ledger ref of the shared clone changes to the ledger
commit of the clone. A program pushes only when that ledger commit
extends the ledger commit of the shared clone, when the git tree object
of each commit between them is a valid ledger tree, and when each ledger
entry that the push adds is accepted at its point. So each ledger entry
of the shared ledger keeps its place, and the shared ledger changes only
at its end, other than in a repair.

When another clone pushed first, the ledger commit of a clone does not
extend the ledger commit of its shared clone. The clone then takes in
the ledger entries of its shared clone. The new ledger commit of the
clone is a take-in commit: it holds each line of the shared clone, and,
after them, one new line for each provisional line that stays. The
program takes the provisional lines in the order of their `seq`. For
each of them, the new line has each member of the old line other than
`seq` and `id`, and no other member, with the next `seq`, and so a new
`id`. The provisional line stays when the ledger entry of its new line
is accepted at its new point. Otherwise, it leaves the ledger, and the
next provisional line takes that place. A void that the clone has not
pushed is accepted at no point, so it leaves. When no provisional line
stays, the take-in commit is the ledger commit of the shared clone.

A program makes a clone take in the ledger entries of its shared clone
only when the shared clone has a ledger commit. When the clone has a
provisional line, the program also makes it take in only when the
ledgers of the clone and of its shared clone are both valid, and each
provisional line has a ledger entry. So a line that a newer program
wrote is never lost in a take-in. Taking in is not appending, and a
program that an agent runs can take in ledger entries. A program changes
the ledger ref of a git repository only to append ledger entries, to
make a repair, to make the git repository take in the ledger entries of
its shared clone, or to push to the shared clone.

For example, the shared clone S holds five ledger entries. The clone A
took them in, and then appended a sixth ledger entry, a. Before A
pushes, the clone B pushes its own sixth ledger entry, b. Now the ledger
commit of A does not extend the ledger commit of S. A takes in the
ledger entries of S: its new ledger holds the five ledger entries, then
b with the `seq` 6, then a with the `seq` 7 and a new `id`, when a is
accepted at the point after b. Then the ledger commit of A extends the
ledger commit of S, and A can push.

### 2.7 Repairs and voids

A repair removes one or more ledger entries from a ledger, and puts a
void where each of them was. A person makes a repair, for example to
remove a ledger entry that holds a secret, or to make a broken ledger
valid. No program repairs a newer ledger. The repair gives the git
repository a new ledger commit whose git tree object is a valid ledger
tree and whose history is intact:

- Each line that the repair keeps has the same bytes.
- Each line that the repair removes, and whose JSON value is an object
  with a string `id`, gives its place to one void whose `dropped` is
  that `id`. When that object has a `seq` that no other line of the old
  ledger commit has, the void takes that `seq`. So when the old ledger
  is valid, each void takes the `seq` of the ledger entry that it
  replaces.
- In a broken ledger, other voids, with no `dropped`, can fill the
  values of `seq` that the lines above leave out.
- Each void that the repair puts has the fields `by` and `reason`.

So no ledger entry that stays changes its `seq` or its `id`. Because the
new history is intact, no commit of it holds a ledger entry that the
repair removed: the repair gives the ledger a new history. A repair of
the shared ledger is the one change of the ledger ref of a shared clone
that does not go to a commit that extends its ledger commit.

A void changes no state, and it cancels no other ledger entry: a void
whose `dropped` names a ledger entry that is still in the ledger changes
nothing. After a repair of the shared ledger, each clone takes in the
ledger entries of its shared clone, its voids included. A void accounts
for the line that it replaces, so that line is not provisional, and the
clone does not put it back. Taking in voids is not a repair.

### 2.8 Agents, the job, and trackers

An agent marker is an environment variable that shows that an agent runs
a program, such as a variable that the program that runs an agent sets
for it. The parameter `agent-markers` gives the names of the agent
markers. An agent runs a program when the environment of a process of
that program holds an agent marker, whatever its value. A program that
an agent runs appends no ledger entry other than a definition entry,
and it makes no repair. It can still take in ledger entries and push.

Only the job appends ledger entries of the kind `delivered`.

A ledger entry can name an external item by its external id, such as
`gh/42`. It holds no other data that a program took from a tracker, such
as the title or the state of an issue.

## 3. Parameters

### 3.1 `agent-markers`

The parameter `agent-markers` gives the names of the agent markers. A
binding of it is a finite set of texts, each the name of an environment
variable.

### 3.2 `ledger-remote`

The parameter `ledger-remote` gives the remote by which a clone names
its shared clone. A binding of it is a text: the name of a remote, such
as `origin`.

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
        whole-number=v1, character=v1, byte=v1, utf-8-encoding=v1,
        code-span=v1,
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
2. The name of none of its entries, at any depth, holds the byte 0x2F,
   the byte of `/`.
3. Its entries, at any depth, are exactly these: its chunks, each with
   the mode that 100644 writes in base 8; for each of its chunks, the
   tree entry whose byte path is the UTF-8 encoding of the first 10
   characters of the chunk path of that chunk; and, when it has at least
   one chunk, the tree entry whose byte path is the UTF-8 encoding of
   `entries`.
4. The content of each of its chunks has at least one line, and each
   line of each of its chunks is the canonical line of a line object.
5. The object of each of its lines has the member `id` with a string,
   the member `kind` with a string, the member `v` with the integer 1,
   and the member `seq` with an integer of 1 or more.
6. The value of `id` of the object of each of its lines is the entry id
   of that object.
7. After its first 11 characters, the chunk path of each of its chunks
   is the value of `id` of the object of the first line of that chunk,
   then `.jsonl`.
8. No two of its lines have objects with the same value of `id`.
9. For the number n of its lines, the values of `seq` of the objects of
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
not exist. The ledger of a git repository, as a state input, is its
stored ledger.

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

### 4.13 Shared clones

@term shared-clone=v1
@cites {
    gitdoc/git-config,
    ontology#{parameter=v1},
    changes#{git-configuration=v1},
    text#{text=v1, code-span=v1},
    #{stored-ledger=v1},
}

The shared clone of a git repository is the git repository that the
setting `remote.<name>.url` of its git configuration gives, as the page
git-config gives it, when `<name>` is the text of the binding of the
parameter `ledger-remote`. A git repository whose git configuration
gives no value for that setting has no shared clone. The shared ledger
of a git repository is the stored ledger of its shared clone.

### 4.14 Take-in commits

@term take-in-commit=v1
@cites {
    changes#{commit=v1, ancestry=v1},
    data-forms#{json-value-of-a-byte-sequence=v1, canonical-line=v1},
    text#{whole-number=v1, code-span=v1},
    #{
        ledger-ref=v1, chunk=v1, entry-id=v1, ledger-validity=v1,
        stored-ledger=v1, ledger-extension=v1, accepted-entry=v1,
        shared-clone=v1,
    },
}

A git tree object accounts for a line of a chunk when, and only when,
one of its lines is that line, or the object of one of its lines has the
member `kind` with the value `void` and the member `dropped` with the
value of the member `id` of the JSON value of that line.

For a git repository A whose shared clone B has a ledger commit b, let n
be the number of the lines of the git tree object of b, and let l1, l2,
and so on to lm be the lines of the git tree object of the ledger commit
of A for which the git tree object of b does not account, in increasing
order of the `seq` of their objects. The line that comes from a line l
at the place p is the canonical line of the object that has each member
of the object of l other than `seq` and `id`, the member `seq` with the
value p, and the member `id` with its entry id, and no other member.
The lines that stay are these: for each i from 1 to m, in turn, with k
the number of lines that stay before li, li stays when the line that
comes from li at the place n + k + 1 has a ledger entry, and that ledger
entry is accepted at the end of the ledger of the ledger entries of the
lines of b and of the lines that come from the lines that stay before
li, each at its place.

A commit d is the take-in commit of B into A when, and only when, no
line stays and d is b, or at least one line stays and each of these is
true:

1. d extends b, and the git tree object of each commit that d reaches
   and that b does not reach is a valid ledger tree.
2. The lines of the git tree object of d are the lines of the git tree
   object of b, and, for each line li that stays, the line that comes
   from li at the place n + k + 1, with k the number of lines that stay
   before li.

A git repository takes in the ledger entries of its shared clone when
its ledger ref changes to a take-in commit of its shared clone into it.
The shared clone of a git repository takes in the ledger entries of that
git repository when the ledger ref of the shared clone changes to the
ledger commit of that git repository.

### 4.15 Agent markers

@term agent-marker=v1
@cites {ontology#{parameter=v1, agent=v1}, text#{text=v1, code-span=v1}}

An agent marker of a process is an environment variable of the process
whose name is a text of the binding of the parameter `agent-markers`,
whatever the value of that variable. An agent runs a program when, and
only when, the environment of a process of that program holds an agent
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
repository, in an undisturbed repository read, a conforming program
must give exactly the ledger entries of that stored ledger, in their
order, when the git repository holds its ledger objects and its ledger
is valid, and no ledger entry otherwise.

### 5.2 The validation of ledgers

@req validate-ledgers=v1
@cites {
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1, result=v1},
    #{ledger-validity=v1, ledger-object=v1},
}

When it gives a result for whether the ledger of a git repository is
valid, in an undisturbed repository read, a conforming program must give
exactly one result when the git repository holds its ledger objects:
"valid" when that ledger is valid, "broken" when it is broken, and
"newer" when it is newer. It must give no result when the git repository
does not hold its ledger objects.

### 5.3 The validation of histories

@req validate-histories=v1
@cites {
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1, result=v1},
    #{intact-history=v1, ledger-validity=v1, ledger-object=v1},
}

When it gives a result for whether the history of the ledger of a git
repository is intact, in an undisturbed repository read, a conforming
program must give exactly one result when the git repository holds its
history objects and its ledger is not newer: "valid" when that history
is intact, and "invalid" when it is not. It must give neither result
when that ledger is newer, or when the git repository does not hold its
history objects.

### 5.4 No state from a ledger that a program cannot read

@req give-no-states-from-unreadable-ledgers=v1
@cites {
    ontology#{state=v1, ledger=v1},
    text#{conforming-program=v1},
    #{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
}

A conforming program must give no state at a point of the ledger of a
git repository whose ledger is broken or newer, or that does not hold
its ledger objects.

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
    changes#{commit=v1, ancestry=v1},
    text#{conforming-program=v1, whole-number=v1, code-span=v1},
    #{ledger-ref=v1, chunk=v1, ledger-validity=v1, ledger-extension=v1},
}

A conforming program must append ledger entries only to the ledger of a
git repository whose ledger is valid. When it appends ledger entries to
that ledger, it must change the ledger ref of the git repository, from
its commit c or from not existing, to a commit d such that each of these
is true:

1. d extends c, or, when the ledger ref did not exist, d extends a
   commit that has no parent.
2. The git tree object of each commit that d reaches, and that c does
   not reach, is a valid ledger tree.
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
    #{entry-field=v1},
}

A conforming program must append only ledger entries whose objects have
the member `by` with a string, and whose members `agent`, `branch`, and
`ts`, each when they have it, hold a value of the form of that common
field.

### 5.9 The agents that write ledger entries

@req record-agent-writers=v1
@cites {
    ontology#{ledger-entry=v1},
    text#{conforming-program=v1, code-span=v1},
    #{entry-field=v1, agent-marker=v1},
}

When an agent runs it, a conforming program must append only ledger
entries whose objects have the member `agent`.

### 5.10 The ways in which a ledger ref changes

@req limit-ledger-ref-changes=v1
@cites {
    ontology#{repair=v1},
    text#{conforming-program=v1},
    #{ledger-ref=v1, shared-clone=v1, take-in-commit=v1},
}

A conforming program must change the ledger ref of a git repository only
to append ledger entries, to make a repair, to make the git repository
take in the ledger entries of its shared clone, or to make the git
repository, as the shared clone of another git repository, take in the
ledger entries of that git repository.

### 5.11 Pushes to the shared clone

@req push-only-extensions=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1, repair=v1},
    changes#{commit=v1, ancestry=v1},
    text#{conforming-program=v1},
    #{
        ledger-ref=v1, chunk=v1, shared-clone=v1, ledger-validity=v1,
        stored-ledger=v1, ledger-extension=v1, intact-history=v1,
        accepted-entry=v1, take-in-commit=v1,
    },
}

Other than in a repair, a conforming program must make the shared clone
S of a git repository take in the ledger entries of that git repository
only when the ledger ref of S does not exist, or has a commit, and it
must change the ledger ref of S, from its commit c or from not existing,
only to a commit d such that each of these is true:

1. d extends c, or, when the ledger ref of S did not exist, the history
   of the ledger of S is intact after the change.
2. The git tree object of each commit that d reaches, and that c does
   not reach, is a valid ledger tree.
3. Each line of the git tree object of d that is not a line of the git
   tree object of c has a ledger entry, and that ledger entry is
   accepted at its point.

### 5.12 Taking in

@req take-in-ledgers=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1},
    #{ledger-ref=v1, shared-clone=v1, take-in-commit=v1},
}

When a conforming program makes a git repository A take in the ledger
entries of its shared clone B, it must change the ledger ref of A to the
take-in commit of B into A.

### 5.13 The take-ins that a program refuses

@req refuse-unsafe-take-ins=v1
@cites {
    text#{conforming-program=v1},
    #{
        ledger-ref=v1, chunk=v1, shared-clone=v1, ledger-validity=v1,
        stored-ledger=v1, take-in-commit=v1,
    },
}

A conforming program must make a git repository A take in the ledger
entries of its shared clone B only when the ledger ref of B has a
commit b, and when either the git tree object of b accounts for each
line of the git tree object of the ledger commit of A, or the ledgers of
A and of B are valid and each line of the git tree object of the ledger
commit of A for which the git tree object of b does not account has a
ledger entry.

### 5.14 Repairs in place

@req repair-ledgers-in-place=v1
@cites {
    ontology#{repair=v1},
    data-forms#{json-value-of-a-byte-sequence=v1},
    text#{conforming-program=v1, code-span=v1},
    #{
        ledger-ref=v1, chunk=v1, entry-field=v1, ledger-validity=v1,
        intact-history=v1,
    },
}

A conforming program must make no repair of a ledger that is newer.
When it makes a repair of the ledger of a git repository, it must change
the ledger ref of that git repository, from its commit c, or from a
ledger ref that has no commit, for which c then stands for a commit
with no lines, to a commit d such that each of these is true:

1. The git tree object of d is a valid ledger tree, and the history of
   the ledger of the git repository is intact after the change.
2. Each line of the git tree object of c that the repair keeps is a line
   of the git tree object of d.
3. For each line of the git tree object of c that the repair removes,
   and whose JSON value is an object with the member `id` with a string,
   the git tree object of d has exactly one line whose object has the
   member `kind` with the value `void` and the member `dropped` with
   that string. When the JSON value of the removed line has the member
   `seq` with an integer of 1 or more that the JSON value of no other
   line of c has as its `seq`, the object of that void has that `seq`.
4. The object of each other line of the git tree object of d has the
   member `kind` with the value `void` and no member `dropped`, and its
   `seq` is less than the `seq` of the object of a line that item 2 or
   item 3 gives.
5. The object of each line of the git tree object of d that is not a
   line of c has the member `by` with a string and the member `reason`
   with a string.

### 5.15 The ledger entries that agents write

@req limit-agents-to-definitions=v1
@cites {
    ontology#{definition-entry=v1, repair=v1, ledger=v1},
    text#{conforming-program=v1},
    #{agent-marker=v1},
}

When an agent runs it, a conforming program must append to a ledger no
ledger entry other than a definition entry, and must make no repair.

### 5.16 The writer of `delivered` ledger entries

@req leave-delivered-entries-to-job=v1
@cites {
    ontology#{job=v1, job-record=v1, ledger=v1},
    text#{conforming-program=v1},
}

A conforming program must append a ledger entry of the kind `delivered`
to a ledger only in an execution that is the job.

### 5.17 No data from trackers

@req keep-tracker-data-out=v1
@cites {
    ontology#{external-item=v1, ledger-entry=v1},
    text#{conforming-program=v1},
}

A conforming program must append to a ledger no ledger entry that holds
data, other than an external id, that the program took from a service
that holds external items, such as the title or the state of an issue.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`ledger.test-vectors.jsonl`](ledger.test-vectors.jsonl), in the same
folder as this design. A vector is an input and what a conforming
program gives for it. Each vector follows from the requirements and adds
nothing to them. The vectors are in three groups, `histories`,
`ledgers`, and `take-ins`, and each group has a subsection below. The
subsection names the requirements that the vectors of the group follow
from, and it describes their inputs, results, and values. No vector
follows from the requirements `give-no-states-from-unreadable-ledgers`,
`ignore-unknown-members`, `append-entries-at-end`,
`append-only-accepted-entries`, `write-entry-fields`,
`record-agent-writers`, `limit-ledger-ref-changes`,
`push-only-extensions`, `repair-ledgers-in-place`,
`limit-agents-to-definitions`, `leave-delivered-entries-to-job`, and
`keep-tracker-data-out`.

Each requirement from which vectors follow applies only when a program
gives the thing that it names, such as a result for whether a ledger is
valid, or makes the change that it names, such as a take-in. So a vector
holds a program only to what the program gives or makes for the input.
The input of each vector of the groups `histories` and `ledgers` stands
for a git repository that holds its ledger objects, or its history
objects for the group `histories`, and for an undisturbed repository
read of it.

The file is a [test-vector set](sinter:data-forms#test-vector-set=v1).
Each line of the file is the
[canonical byte sequence](sinter:data-forms#canonical-byte-sequence=v1)
of one JSON object, then the byte 0x0A, so each line is a JSON text, as
RFC 8259 defines it. The file has three kinds of line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `histories`,
   `ledgers`, `take-ins`. Its JSON object has two members: `group`, the
   name of the group, as a JSON string, and `rev`, the revision of the
   group.
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
- `values`: a JSON object that holds what a conforming program gives or
  makes for the input, other than the result. The subsection of the
  group says which of these things a conforming program gives or makes
  in each case.
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
object, a list of lines, or a sequence has this form:

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
- A list of lines is a JSON array of JSON objects, each of which stands
  for a line object: the lines of the git tree object of a ledger commit
  that lays out its chunks in the form of a valid ledger tree, which are
  the canonical lines of these line objects. Its ledger is valid when
  these lines meet conditions 5, 6, 8, and 9 of a valid ledger tree, and
  no line is a newer line, and it is newer when a line is a newer line.
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

### 6.3 Take-ins

The group `take-ins` holds the vectors of the requirements
`take-in-ledgers` and `refuse-unsafe-take-ins`. Each vector gives the
lines of the ledger commit of a git repository A, the lines of the
ledger commit of its shared clone B, and the ledger entries that the
acceptance rules of their kinds do not accept, and it gives the lines of
the take-in commit of B into A, or that a conforming program does not
make A take in the ledger entries of B.

- `input`: a JSON object with three members. `clone` is the lines of the
  ledger commit of A, a list of lines. `shared` is the lines of the
  ledger commit of B, a list of lines. `refused` is a JSON array of
  texts: the values of `id` of the objects of the lines of A for which
  the acceptance rule of the kind of the ledger entry of the line that
  comes from that line does not accept that ledger entry at its point;
  the acceptance rules accept each other ledger entry of a line that
  comes from a line of A, other than a void, at its point.
- `result`: no vector of the group has this member.
- `values`: when a conforming program can make A take in the ledger
  entries of B, a JSON object with one member, `lines`: the lines of the
  git tree object of the take-in commit of B into A, as a sequence in
  the order of the `seq` of their objects, in which each line is the
  value of `id` of its object. When a conforming program does not make A
  take in the ledger entries of B, the empty JSON object, `{}`.

When a conforming program makes A take in the ledger entries of B, the
lines of the git tree object of the new ledger commit of A are those
that `lines` names, in the order of their `seq`, and no other lines. It
does not make A take in the ledger entries of B when `values` is `{}`.

```
{"group":"take-ins","input":{"clone":[{"by":"Ada Lovelace <ada@example.com>","id":"e-375ba17af01d","kind":"task","name":"t1","seq":1,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-a0a6c96226e1","kind":"task","name":"t2","seq":2,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-1ffc8aea3614","kind":"task","name":"t3","seq":3,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-504f23998c18","kind":"task","name":"t4","seq":4,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-3ab978f3adc1","kind":"task","name":"t5","seq":5,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-0b9425768148","kind":"approval","seq":6,"subject":"billing#limit","v":1}],"refused":[],"shared":[{"by":"Ada Lovelace <ada@example.com>","id":"e-375ba17af01d","kind":"task","name":"t1","seq":1,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-a0a6c96226e1","kind":"task","name":"t2","seq":2,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-1ffc8aea3614","kind":"task","name":"t3","seq":3,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-504f23998c18","kind":"task","name":"t4","seq":4,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-3ab978f3adc1","kind":"task","name":"t5","seq":5,"v":1},{"by":"Ada Lovelace <ada@example.com>","id":"e-4891f1b18c5e","kind":"decline","seq":6,"subject":"billing#fee","v":1}]},"n":57,"note":"the provisional ledger entry stays, after the ledger entry that the shared clone took in first","rev":"v1","values":{"lines":["e-375ba17af01d","e-a0a6c96226e1","e-1ffc8aea3614","e-504f23998c18","e-3ab978f3adc1","e-4891f1b18c5e","e-bdd7d3d6e47c"]}}
```
