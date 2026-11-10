<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
Specifies the kinds of items that Sinter traces, with their names, texts, revisions, and edges, and the conditions of a valid tree; work items, changes, the ledger, and the actors that write it; the names and meanings of states; and the limits on the use of statements of agents and of declared tasks.

Sinter traces the items of a repository: designs with their
specifications and requirements, decision records, tests, tasks and
plans, and the items outside the repository that external ids name. A
citation, such as `@verifies packs#size-limit=v2` in a comment on a
test, states an edge: a relation from its source, here the test, to its
cited item, here the requirement `packs#size-limit` with the text that
the label `v2` names. The ledger of a repository records events, such
as the approval that a person gave to one text. Each state, such as in
force, approved, suspect, or done, follows from the trees and the
messages of the commits of the repository, from its ledger entries, and
from test evidence.

From Identifiers, the design takes the tag words and the kind words;
names, labels, and revisions; external ids; the entries of a citation
and the every-part target; the forms of the `@ack` and `@extern` lines;
and inline citations. From Text and notation, it takes texts, lines,
and whole numbers, and what a design, a requirement, a conforming
program, an input, and a result are.

## 1. Terms

| term | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that a project made |
| item | a thing that Sinter traces, such as a requirement, a test, or a task |
| kind of item | one of the thirteen sorts of item, such as design or task; each item has one |
| repository | a git repository |
| tree | the set of the files of a repository, with their contents, at one commit or in one working tree |
| default branch | the branch into which work on a repository merges |
| actor | a person, an agent, or the job |
| person | a human who works on a repository |
| agent | a program that uses a language model to write texts for a person, such as code |
| continuous integration | a service that runs checks on the commits of a repository |
| job | the execution of Sinter that continuous integration starts at each push to the default branch |
| declared item | an item that a declaration declares: a design, a specification, a requirement, a decision record, or a declared finding class |
| text of a declared item | the part of the files of a tree that a declared item takes up, its declaration included |
| containment | the relation in which a design holds specifications and requirements, and a specification holds requirements |
| hold, belong to | a design holds each of its specifications and requirements, and each of them belongs to the design; a specification holds its requirements in the same way |
| hold directly | a design holds a requirement directly when the requirement belongs to the design and to no specification |
| design | a declared item that specifies one part of a system |
| own text | the part of the text of a design that is in the text of none of its specifications and none of its requirements |
| specification | a declared item that specifies one thing of the part of a system that its design specifies, such as a format |
| requirement | a declared item whose text states one definition, or one obligation of each conforming program of its design |
| normative | stating what a conforming program is or does; only the text of requirements is normative |
| decision record | a declared item that records one standing practice of a project, or one choice with its reason |
| finding | a report of one condition about one part of a repository |
| finding class | the sort of condition that a finding reports, which a slug names |
| declared finding class | a finding class that a repository declares for itself; it is a declared item |
| finding-class file | the file whose whole text is the text of one declared finding class |
| file of a design | the file in which the declaration of a design stands |
| mark | what an `@extern` line states: a design holds a specification, or holds directly a requirement, whose declaration is in another file |
| value | a thing, such as a text, that a conforming program gives together with a result |
| conformance vector | an item that has one input of a conforming program of a design, the result that the program gives for it, and the values that it gives with that result |
| vector set | the conformance vectors of one specification, or of one design for the requirements that it holds directly |
| number of a vector | the whole number of 0 or more that names a conformance vector in its vector set |
| group | a named set of the conformance vectors of one vector set; each conformance vector is in one group |
| selection | the set of conformance vectors that one entry names: one vector, every vector of a group, or every vector of a vector set |
| test | a unit of code that a test framework runs and reports as passed or failed, or a set of such units |
| test evidence | the reports that tests gave in one execution: which tests ran, and which of them passed or failed |
| site | an item with no name: a block of text in which citations or inline citations stand, and that is neither a declared item nor a test |
| external item | an item outside the repository that an external id names, such as an issue or a standard |
| standard | an external item that is a published standard, or a part of one |
| term | a word or a fixed phrase to which a document gives one meaning; an external item can be a term of a published document |
| hash | a short text that a fixed function computes from a text, so that two different texts almost never have the same hash |
| revised content | the part of an item that a revision of the item names, such as the own text of a design |
| revision of an item | a label that names one revised content of the item |
| current revision | the label that names the revised content of an item in a given tree |
| edge | a relation of one kind of edge from a source to a cited item, which an entry of a citation or the target of an inline citation states |
| kind of edge | one of `cites`, `satisfies`, `verifies`, `refines`, and `supersedes` |
| stand in | a citation stands in a declared item or a site when it is in its text, and in a test when it is in a comment on the code of the test |
| source | the declared item, the test, or the site in which the citation or the inline citation of an edge stands |
| cited item | the item that the entry or the target of an edge names |
| pinned edge | an edge whose entry or target carries a label |
| status tag of a declared item | a status tag that stands in the text of the declared item |
| ack | what an `@ack` line states: a person or an agent accepts one finding for one block of text |
| valid | an edge, a mark, a status tag, or a tree is valid when it meets the conditions that its meaning needs |
| work item | a task or a plan |
| work item id | the id of a work item, which never changes |
| display name | the name of a work item that a person reads, which can change |
| task | a work item for one piece of work that one person or one agent can finish alone |
| paths of a task | the set of the paths of the files that the work of a task can add, change, or remove |
| promise | a pair of a kind of edge, `satisfies` or `verifies`, and a requirement, which states what the work of a task puts into the tree |
| plan | a work item that says how a set of tasks gets done |
| plan of a work item | the plan that the definition of a work item names |
| part of a plan | a work item whose current definition names the plan as its plan, unless an abandonment ended that |
| under a plan | a part of the plan, or under a part of the plan |
| wait | a relation from a work item to another work item that it waits for |
| carry out | a plan carries out the requirements, specifications, and designs that its work is for |
| definition of a work item | what a definition entry records about a work item, such as the paths of a task |
| current definition | the definition that the latest accepted definition entry of a work item records |
| change | a set of commits on a branch that a person merges into the default branch as one unit |
| diff of a change | the lines that differ between the tree where a change starts and the tree of its last commit |
| lines of a change | the lines of the diff of a change, and the lines of the messages of its commits |
| delivery line | a line of the message of a commit that states that the commit completes the work of a task |
| finishing commit | the commit in whose message a delivery line is |
| delivery | the arrival of the finishing commit of a delivery line on the default branch |
| task line | a line of the message of a commit that names a task on which the commit does part of the work |
| tasks of a change | the tasks that the delivery lines and the task lines of a change name |
| ledger | the sequence of the ledger entries of a repository, in the order in which actors appended them |
| ledger entry | a record of one event in the ledger, such as one approval |
| point of the ledger | a point between two ledger entries, before the first, or after the last |
| provisional | a ledger entry is provisional while a clone has it and has not pushed it yet |
| repair | the one write to the ledger that is not an append: it removes ledger entries, and only a person makes one |
| void | a ledger entry that stands where a ledger entry stood that a repair removed |
| definition entry | a ledger entry that records one definition of one work item |
| accepted | a definition entry is accepted when its definition becomes the current definition of its work item |
| judgment | a ledger entry that records a decision of a person |
| record of the job | a ledger entry that records what the job observed |
| state | a named condition of an item, an edge, or a subject of approval at one time, such as in force or done |
| in force, retired | a declared item is in force when it applies, and retired when it does not |
| effective | a `supersedes` edge is effective when it retires its cited item |
| deprecated, rejected, deferred | the states that the three status words state |
| subject of approval | a unit that a person approves or declines as a whole |
| approved, declined | the states of a subject of approval after a person approved or declined its revised content |
| draft | a design is a draft while it is not approved |
| suspect | a pinned edge is suspect when its label is not the current revision of its cited item |
| open, delivered, done, abandoned | the four states of a task; a plan is open, done, or abandoned |
| unfinished | a task is unfinished while it is open or delivered |
| final | a state that a work item keeps for good |
| met | a wait is met when the work item that it waits for is done |
| ready | a task is ready when it is open and its waits, and the waits of each plan that it is under, are met |
| accounted for | a requirement is accounted for when work for it is under way, or was finished at its current revision |
| statement of an agent | a text that an agent writes |
| session | one execution of an agent on its work |
| declared task | the task that an agent declares as the work of its session |
| brief of a session | the text that Sinter gives an agent about its work for one session |

## 2. The items, their relations, and their states

### 2.1 Items and their kinds

An item is a thing that Sinter traces. Each item has one kind of item:

| kind of item | what it is | how it is named | has revisions |
|---|---|---|---|
| design | a declared item that specifies one part of a system | a slug, such as `packs` | yes |
| specification | a declared item that specifies one thing of its design | a full name, such as `packs#descriptor` | yes |
| requirement | a declared item whose text states one definition or one obligation | a full name, such as `packs#size-limit` | yes |
| decision record | a declared item that records one practice or one choice | a slug, such as `code-comments` | yes |
| declared finding class | a finding class that a repository declares for itself | a slug, such as `late-fee` | yes |
| conformance vector | one input of a conforming program, with its result and its values | its vector set and its number | yes |
| group | a named set of the conformance vectors of one vector set | its vector set and its name | yes |
| vector set | the conformance vectors of one specification or of one design | its specification or its design | yes |
| task | one piece of work | a work item id | no |
| plan | how a set of tasks gets done | a work item id | no |
| test | a unit of code that a test framework runs | the code names it | no |
| site | a block of text in which citations or inline citations stand | no name | no |
| external item | a thing outside the repository | an external id, such as `gh/42` | no |

A declared item is an item that a declaration declares. The declaration
word gives its kind of item: `@design` declares a design, `@spec` a
specification, `@req` a requirement, `@decision` a decision record, and
`@finding-class` a declared finding class.

A work item is a task or a plan. No work item is in a file of a tree:
the ledger entries of the ledger define each one.

### 2.2 Repositories, changes, and actors

A repository is a git repository. A tree is the set of the files of the
repository, with their contents, at one commit or in one working tree.
The tree of a commit is the tree at that commit. The default branch is
the branch into which work on the repository merges.

A change is a set of commits on a branch that a person merges into the
default branch as one unit, such as the commits of a pull request. The
person who merges the change brings its work to the default branch, as
its commits or as one squash commit. The diff of a change is the set of
the lines that differ between the tree of the commit from which its
branch starts and the tree of its last commit: the lines that the
change adds, and the lines that it removes. The lines of a change are
the lines of its diff and the lines of the messages of its commits.

An actor is a person, an agent, or the job. Actors write the ledger
entries that Sinter reads:

- A person is a human who works on a repository.
- An agent is a program that uses a language model to write texts for a
  person, such as code, a commit message, or a ledger entry. A coding
  agent is an example. Each agent acts for one person: the person who
  runs it.
- The job is the execution of Sinter that continuous integration starts
  at each push to the default branch. Continuous integration is a
  service that runs checks on the commits of a repository. The job
  reads test evidence during its execution, and that test evidence
  exists only during that execution.

### 2.3 Designs, specifications, and requirements

A design specifies one part of a system. A specification specifies one
thing of that part, such as a format, a protocol, or a set of
behaviors. The text of a requirement states one definition, or one
obligation of each conforming program of its design.

Containment is the relation in which a design holds specifications and
requirements, and a specification holds requirements. Each declared
item that a design or a specification holds belongs to it:

- A design holds only specifications and requirements. A specification
  holds only requirements. No other declared item holds a declared
  item.
- A specification belongs to at most one design.
- A requirement belongs to at most one design and to at most one
  specification. A requirement that belongs to a specification belongs
  to the design of that specification, when that specification belongs
  to a design.
- A design holds a requirement directly when the requirement belongs to
  the design and to no specification.

Example: a design `packs` with one specification `descriptor`, which
holds one requirement `size-limit`.

```markdown
# Language packs
@design packs=v4
A language pack gives Sinter the grammar of one language.

## The pack descriptor
@spec descriptor=v2
The descriptor names the files of a pack.

### Size limit
@req size-limit=v1
A descriptor has at most 1 MiB.
```

The text of a declared item is a part of the files of a tree. Its
declaration is in it. The text of each specification and of each
requirement of a design is in the text of the design. The text of each
requirement of a specification is in the text of the specification. No
part of a file is in the texts of two different requirements. The own
text of a design is the part of its text that is in the text of none of
its specifications and none of its requirements. In the example, the
own text of `packs` is its heading, its tag line, and its first
sentence.

Only the text of requirements is normative: it states what a conforming
program of the design is or does. The rest of the text of a design and
of its specifications explains the requirements and gives examples.

The name of a design is a slug, such as `packs`. The name of a
specification or of a requirement that belongs to a design is a full
name: the slug of the design, `#`, and its part name, such as
`packs#descriptor` and `packs#size-limit`. A specification or a
requirement that belongs to no design is still a specification or a
requirement, and its name is a slug. Names come in sets:

- Designs, decision records, and the specifications and the
  requirements that belong to no design share one set of slugs.
- Declared finding classes have a set of slugs of their own.
- The specifications and the requirements of one design share one set
  of part names.

The file of a design is the file in which the declaration of the design
stands. A design can hold a specification, or hold directly a
requirement, whose declaration is in another file. An `@extern` line in
the own text of the design states a mark for such an item, such as
`@extern spec:descriptor`. The kind word of the line gives the kind of
item, and the part name of the line gives the part name of the item. A
requirement of such a specification has no mark of its own: the mark of
its specification covers it.

### 2.4 Decision records, finding classes, and acks

A decision record records one standing practice of a project, or one
choice with its reason, such as the record `code-comments`.

A finding is a report of one condition about one part of a repository.
Each finding is of one finding class: the sort of condition that the
finding reports, which a slug names. A repository can declare finding
classes of its own. Each such declared finding class is a declared
item, and its text is the whole of one file, its finding-class file. A
finding class that a conforming program has built in is not an item.

An ack is what an `@ack` line states: a person or an agent accepts one
finding for one block of text. In the line
`@ack late-fee billing#fee=v2 3f2a9c1d`, the slug `late-fee` names the
finding class, and the subject `billing#fee=v2` names what the finding
is about. The block of text is
the block in which the `@ack` line stands. The hash prefix `3f2a9c1d`
is the start of the hash of that block, as the block was when the ack
was written. A hash is a short text that a fixed function computes from
a text, so that two different texts almost never have the same hash.

### 2.5 Conformance vectors

A conformance vector is one example of an input of a conforming program
of a design, with the result that a conforming program of that design
gives for that input and the values that it gives together with that
result. A value is a thing that a conforming program gives together with
a result, such as the slug of a target that a parser gives. The result
and the values of a conformance vector follow from the requirements of
its design, and the vector states no requirement of its own.

Each conformance vector is given for one specification of its design,
or for the requirements that its design holds directly. The conformance
vectors given for a specification form its vector set. The conformance
vectors given for the requirements that a design holds directly form
the vector set of the design. Each conformance vector has a number, a
whole number of 0 or more, which names it in its vector set. A number
names one vector for the whole life of the vector set: no other vector
of the set ever takes it. Each conformance vector is in exactly one
group, a named set of the conformance vectors of its vector set.

An entry of a citation can name one conformance vector, one group, or
one vector set. The selection of the entry is the set of the vectors
that it names in this way:

| entry | cited item | selection |
|---|---|---|
| `data-forms#toml[12]=v1` | the vector 12 of the vector set of the specification `data-forms#toml` | that one vector |
| `data-forms#toml[offsets][*]=v2` | the group `offsets` of that vector set | every vector of the group |
| `data-forms#toml[*]=v3` | the vector set of `data-forms#toml` | every vector of the vector set |
| `identifiers[37]=v1` | the vector 37 of the vector set of the design `identifiers` | that one vector |

A test that checks code against the vectors of a selection names them
with `@verifies`:

```python
# @verifies data-forms#toml[offsets][*]=v2
def test_offsets(vector):
    ...
```

### 2.6 Tests, sites, and external items

A test is a unit of code that a test framework runs and reports as
passed or failed, such as a test function. A set of such units, such as
the tests of one `describe` block, is a test too. The code names each
test, so a test has no declaration. Test evidence is the set of the
reports that tests gave in one execution of their test frameworks:
which tests ran, and which of them passed and which failed.

A site is an item with no name. It is a block of text in a file, such
as a comment in code or a section of a markdown file, in which
citations or inline citations stand, and that is neither a declared
item nor a test.

An external item is an item outside the repository that an external id
names, such as the issue `gh/42` or the standard `rfc/8259`. An
external id with `#` and a part name, such as `rfc/8259#section-6`,
names a part of such an item, and that part is an external item too.
An external item has no revision. An external item can be a standard:
a published standard, or a part of one. An external item can also be a
term: a word or a fixed phrase to which a published document gives one
meaning, such as `term:rfc/8259#value`.

### 2.7 Kind words

A kind word at the start of an entry of a citation, of the target of an
inline citation, or of the target of an `@extern` line states what the
entry or the target names:

| kind word | what the entry or the target names |
|---|---|
| `design` | a design |
| `spec` | a specification, or an external item that is a standard |
| `req` | a requirement |
| `decision` | a decision record |
| `finding-class` | a declared finding class |
| `term` | an external item that is a term |

So `spec:rfc/8259` states that the external item `rfc/8259` is a
standard, and `req:packs#size-limit=v2` states that `packs#size-limit`
is a requirement.

### 2.8 Revisions and pins

Each item of the first eight kinds of item has a revised content: the
part of the item that a revision of the item names.

| item | revised content |
|---|---|
| design | its own text |
| specification | its text, with the texts of its requirements in it, without the labels of the declarations of those requirements |
| requirement, decision record, declared finding class | its text |
| conformance vector | its input, its result, and its values |
| group | which conformance vectors are in it, and the revised content of each |
| vector set | which conformance vectors are in it, and the revised content of each |
| task, plan, test, site, external item | none: the item has no revision |

A revision of an item is a label that names one revised content of that
item. No label names two different revised contents of one item, in
one tree or in two trees of a repository. The current revision of an
item in a tree is the label that names the revised content that the
item has in that tree. For a declared item, it is the label of its
declaration.

So an edit of a requirement inside a specification changes the revised
content of the requirement and of the specification. An edit of the
own text of a design changes the revised content of the design alone.
An edit of one vector changes the revised content of its group and of
its vector set.

An edge is pinned when the entry or the target that states it carries
a label. A pinned edge states its relation to the revised content of
its cited item that the label names. So `@cites packs#size-limit=v2`
rests on the text of `packs#size-limit` that has the label `v2`. An
edge whose entry carries `*`, such as `@cites packs=*`, is not pinned:
it rests on the cited item at each of its revisions. An edge whose
cited item is an external item is not pinned, because an external id
carries no label.

### 2.9 Edges

An edge is a relation of one kind of edge from a source to a cited
item. Each entry of a citation states one edge. The kind of edge is the
citation word without its `@`. The cited item of the edge is the item
that the entry names. An inline citation, such as
`[the limit](sinter:packs#size-limit=v2)`, states one edge of the kind
`cites`, and its target names the cited item. When no item has the
name that an entry or a target gives, the edge has no cited item.

A citation or an inline citation stands in a declared item when it is
in the text of the item, in a site when it is in the block of text of
the site, and in a test when it is in a comment on the code of the
test. Each edge has exactly one source: a declared item, a test, or a
site in which its citation or its inline citation stands.

| kind of edge | what it states |
|---|---|
| `cites` | the source refers to the cited item and rests on what the cited item says |
| `satisfies` | the source does what the cited item states |
| `verifies` | the source checks that the code it runs meets the cited requirement, or gives the result and the values of each vector of the selection |
| `refines` | the source states all or part of the cited item in more detail |
| `supersedes` | the source is to replace the cited item |

No edge has a work item as its cited item. Work points at text in the
other direction: a task promises requirements, and a plan carries out
requirements, specifications, and designs.

Only a `supersedes` edge states that one declared item is to replace
another. A `supersedes` edge from a design whose entry is an every-part
target, such as `@supersedes docs=v3#*` in the tag lines of a design
`media`, states two things. The design `media` is to replace the design
`docs`, which the label `v3` pins. And each specification and each
requirement `docs#x` is to be replaced by the specification or the
requirement `media#x` of the same kind of item, when `media` holds one.

### 2.10 Valid trees

The meanings of the sections above apply in every tree. A tree is valid
when it also meets each of these conditions:

| condition | a tree that breaks it |
|---|---|
| each edge is valid: it has a cited item, its kind word states what its cited item is, and the kinds of its source and of its cited item fit its kind of edge | `@verifies packs#size-limit=v2` in a section of a markdown file, whose source is a site and not a test |
| each mark is valid: its kind word is `spec` or `req`, and the design holds such an item with its part name, directly for `req`, declared in another file | `@extern design:docs` |
| each status tag of a declared item fits the kind of item of that declared item | `@rejected` in the tag lines of a requirement |
| each specification and each requirement belongs to exactly one design | a `@req` line outside every design |
| each specification and each requirement held directly whose declaration is outside the file of its design has a mark | a specification in a file of its own, with no `@extern` line in the design |
| each name of a set of names names at most one declared item | two declarations `@decision cache=v1` |

The kinds of source and of cited item fit each kind of edge in this
way:

| kind of edge | its source | its cited item |
|---|---|---|
| `cites` | a declared item, a test, or a site | a declared item or an external item |
| `satisfies` | a declared item, a test, or a site | a requirement |
| `verifies` | a test | a requirement, a conformance vector, a group, or a vector set |
| `refines` | a requirement, a specification, or a design | a requirement, a specification, or a design |
| `supersedes` | a declared item; a design when the entry is an every-part target | a declared item of the same kind of item; a design when the entry is an every-part target |

A status word fits these kinds of item: `@deprecated` a requirement, a
specification, a design, and a decision record; `@rejected` and
`@deferred` only a decision record.

A tree that is not valid still has its items, its edges, and their
states. So a requirement outside every design is still a requirement,
and its name is a slug in the set of designs and decision records.

### 2.11 Tasks and plans

A task is a work item for one piece of work that one person or one
agent can finish alone. A plan is a work item that says how a set of
tasks gets done. Each work item has a work item id, which never
changes, and a display name, which can change.

A task has:

- its paths: a set of paths; the work of the task can add, change, or
  remove a file only when the path of the file is in that set, so the
  work of a task whose paths are the empty set changes no file;
- its promises: each a pair of a kind of edge, `satisfies` or
  `verifies`, and a requirement, such as `verifies ledger#id-form`,
  which states that the work of the task puts into the tree of the
  default branch an edge of that kind of edge to that requirement, from a
  source in a file whose path is in the paths of the task;
- at most one external item, such as an issue, which can say what the
  work is; several tasks can name one external item, and a task that
  names one can have an empty display name;
- at most one plan, its plan;
- its waits.

A task has no description of its own: the requirements that it
promises, or its external item, say what to build. A task has no
branch.

A plan has at most one plan, its plan; its waits; and the requirements,
specifications, and designs that it carries out. What a plan carries
out gives context to the work under it, and it changes the state of no
work item. No person approves a plan.

The definition of a task is its display name, its paths, its promises,
its external item, its plan, and its waits. The definition of a plan
is its display name, its plan, its waits, and what it carries out. The
work item id is not part of the definition. Each edit of a definition
gives a new definition, which a new definition entry records.

A work item is a part of a plan when its current definition names the
plan as its plan. Two exceptions apply. An abandoned task is a part of
no plan. And when a person abandons a plan, each of its parts that is
not done stops being a part of it, and its done parts stay. A work item
is under a plan when it is a part of the plan, or under a part of the
plan.

A wait goes from a work item, the waiting item, to another work item,
the item that it waits for. A wait is met when the item that it waits
for is done, so a wait for an abandoned work item is never met. A task
is ready when it is open, each of its waits is met,
and each wait of each plan that it is under is met. So a task is ready
for work only after each work item that it waits for, itself or through
a plan, is done.

The current definitions never form a cycle. No work item reaches
itself through its plan, the plan of that plan, and so on. No work
item reaches itself through waits. And no work item reaches itself
through the combined relation: from a plan to each work item whose plan
it is, and from a task to each work item that it waits for, or that a
plan waits for that the task reaches through its plan, the plan of that
plan, and so on.

A commit states its link to a task in a line of its message:

- A delivery line, such as `Delivers: t-3f2a9c1d7e0b 05ef56`, states
  that the commit completes the work of the task. It names the task by
  its work item id. It names one definition of the task by the start of
  a hash of the paths and the promises of that definition. The
  finishing commit of the line is the commit in whose message the line
  is. A delivery of the task is the arrival of that commit on the
  default branch.
- A task line, such as `Task: t-3f2a9c1d7e0b`, states that the commit
  does part of the work of the task, without finishing it.

The tasks of a change are the tasks that its delivery lines and its
task lines name.

### 2.12 The ledger

The ledger of a repository is a sequence of ledger entries, in the order
in which actors appended them. An actor appends a ledger entry after
each ledger entry that is in the ledger at that time. Of two ledger
entries that actors appended, the one that was appended later comes
later in the ledger, whatever times the ledger entries record. A point
of the ledger is a point between two ledger entries, before the first
one, or after the last one. A ledger entry that a clone of the
repository has and has not pushed yet is provisional: it can still come
later in the ledger than ledger entries that other clones push first.

A repair is the one write to the ledger that is not an append, and
only a person makes one. It removes one or more ledger entries from the
ledger. For each ledger
entry that it removes, it puts one void where the removed ledger entry
stood: a ledger entry that records the removal and its reason. A
removed ledger entry is no longer in the ledger, so no state follows
from it.

A ledger entry records one event, such as one approval that a person
gave, or one observation of the job. No ledger entry records a state.
Each ledger entry also records the actor that wrote it, the person for
whom that actor acts when the actor is an agent, and the branch from
which it was written, when there was one. Each ledger entry has one of
eight kinds of ledger entry, in four classes:

| class | kinds of ledger entry | what a ledger entry records | who writes it |
|---|---|---|---|
| definition entries | `task`, `plan` | one whole definition of one work item | a person or an agent |
| judgments | `approval`, `decline`, `done`, `abandoned` | a decision of a person about a subject of approval, a task, or a plan | a person only |
| records of the job | `delivered` | what the job observed about one delivery line | the job only |
| voids | `void` | that a repair removed one ledger entry, and the reason | a person, in a repair |

A definition entry records no judgment: it makes no task done, abandons
nothing, and approves or declines nothing. A definition entry is
accepted when the definition that it records becomes the current
definition of its work item. The current definition of a work item is
the definition that its latest accepted definition entry records. A
definition entry is accepted only when it records the first definition
of a new work item or an edit of the definition that is current just
before it, and only when the current definitions with its definition
form no cycle. For example, two agents edit the same
definition of a task at the same time. The definition entry that is
appended first is accepted. The other one is not accepted, because the
definition that it edits is no longer the current definition. A
definition entry that is not accepted changes nothing.

A `done` ledger entry and a `delivered` ledger entry each record the
revision of each requirement that the task promises. A `delivered`
ledger entry records what the job observed in the tree that it read,
with the test evidence of its execution. That test evidence exists
only during the execution, so no later reader can observe it again.

### 2.13 States

A state is a named condition that an item, an edge, or a subject of
approval is in at one time. Each state follows from the trees and the
messages of the commits of a repository, from its ledger entries, and
from test evidence.

| state | of | meaning |
|---|---|---|
| in force | a declared item | the item applies: its authors stand behind it, no other declared item replaces it, and the design or the specification that holds it is in force |
| retired | a declared item | the item is not in force |
| effective | a `supersedes` edge | the edge retires its cited item |
| deprecated | a requirement, a specification, a design, or a decision record | a `@deprecated` status tag of the item states that it no longer applies and that nothing replaces it |
| rejected | a decision record | a `@rejected` status tag of the record states that its choice was considered and not made; the record stays |
| deferred | a decision record | a `@deferred` status tag of the record states that its choice is not made yet; its text says what would settle it |
| approved | a subject of approval | a person approved the revised content that it has in the tree, and no later decline of that revised content ended that approval |
| declined | a subject of approval | a person declined the revised content that it has in the tree, and no later approval of that revised content ended that decline |
| draft | a design | the design is not approved |
| suspect | a pinned edge | the label of the edge is not the current revision of its cited item |
| open | a task | the task exists, no ledger entry has ended it, and the job has recorded no delivery of it |
| delivered | a task | the job recorded a delivery of the task, and no ledger entry has ended the task; a person looks at the task |
| done | a task | the work of the task is finished, by what the job observed at a delivery of it, or by a `done` ledger entry |
| abandoned | a task | a person ended the task without finishing its work |
| ready | a task | the task is open, and each work item that it waits for, itself or through a plan, is done |
| done | a plan | the plan is not abandoned, has at least one part, and each of its parts is done |
| abandoned | a plan | a person ended the plan |
| open | a plan | the plan is neither done nor abandoned |
| accounted for | a requirement | work for the requirement is under way, or was finished at its current revision |

A declared item is retired when one of these is true: it has a status
tag, such as `@deprecated`; an effective `supersedes` edge has it as its
cited item; or it belongs to a retired design or a retired
specification. A `supersedes` edge is effective when its source is a
declared item with no status tag. In a repository that needs approval
for items of the kind of item of that source, the source must also be
approved.
So a `supersedes` edge whose source waits for approval retires nothing
yet.

A subject of approval is a unit that a person approves or declines as a
whole: the own text of a design, a specification with its
requirements, a requirement that a design holds directly, or a decision
record. A requirement that a specification holds is approved when that
specification is approved, and declined when it is declined. A design
is approved when its own text, each of its specifications, and each
requirement that it holds directly are approved.

The label of a suspect edge is no longer the current revision of its
cited item: the cited item has a new revision, so the source may no
longer agree with it. Only a cited item that is in the tree makes an
edge suspect.

A task is in exactly one of the states open, delivered, done, and
abandoned. The first ledger entry that ends the task decides between
done and abandoned: a `done` ledger entry, a `delivered` ledger entry
that shows that the work kept each promise of the task, or an
`abandoned` ledger entry. A task is unfinished while it is open or
delivered. The states done and abandoned of a task are final: the task
keeps the state, and more work on it is a new task. The state abandoned
of a plan is final too. The state done of a plan is not final: a done
plan is open again while it has a part that is not done. The state of a
task records work that happened, and it does not state that the code
stays correct.

A requirement is accounted for when one of these is true:

- an unfinished task promises it;
- an open plan carries out the requirement, its specification, or its
  design;
- the ledger entry that made a task done records, for the requirement,
  the revision that is its current revision.

### 2.14 Statements of agents

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, a ledger entry, or a
message to a person. Sinter computes a state from a statement of an
agent in one of two ways only:

1. as a line of a change that names what it is about by a hash, a
   revision of an item, or a work item id, such as a line of the diff,
   a delivery line, or a task line;
2. as a definition entry, which names work and records no judgment.

The person who merges a change can see both: the lines in the change
itself, and, in the summary of the change, every definition entry of
the tasks of the change and every definition entry that was written
from its branch. A statement that exists only outside these, such as a
message of an agent that its work is done, changes no state.

A session is one execution of an agent on its work. The agent can
declare a task as the work of its session. The declared task changes
no state. Sinter uses it only to narrow the brief of the session: the
text that Sinter gives the agent about its work for that session.

## 3. Requirements

### 3.1 Items

@req items=v1

An item is a thing of one of these thirteen kinds of item: design,
specification, requirement, decision record, declared finding class,
conformance vector, group, vector set, task, plan, test, site, and
external item. Each item has exactly one kind of item.

### 3.2 Repositories

@req repositories=v1

A repository is a git repository. A commit, the message of a commit, a
branch, a file, the path of a file, a working tree, a clone, a push,
and a squash commit are those of git. A tree of a repository is the set
of the files of the repository, with their contents, at one commit or
in one working tree. The tree of a commit is the tree at that commit.
The default branch of a repository is the branch into which work on the
repository merges. A push to a branch brings commits to that branch.

### 3.3 People

@req people=v1
@cites #{repositories=v1}

A person is a human who works on a repository.

### 3.4 Agents

@req agents=v1
@cites {text#{texts=v1}, #{people=v1}}

An agent is a program that uses a language model to write texts for a
person, such as code. Each agent acts for one person: the person who
runs it.

### 3.5 Continuous integration

@req continuous-integration=v1
@cites #{repositories=v1}

Continuous integration is a service that runs checks on the commits of
a repository.

### 3.6 The job

@req job=v1
@cites {
    text#{conforming-programs=v1},
    #{repositories=v1, continuous-integration=v1},
}

The job is an execution of a conforming program that continuous
integration starts at each push to the default branch of a repository.

### 3.7 Actors

@req actors=v1
@cites #{people=v1, agents=v1, job=v1}

An actor is a person, an agent, or the job.

### 3.8 Declared items

@req declared-items=v1
@cites {identifiers#{tag-words=v1}, #{items=v1}}

A declared item is an item that a declaration declares. The declaration
word of the declaration gives the kind of item: `@design` gives a
design, `@spec` a specification, `@req` a requirement, `@decision` a
decision record, and `@finding-class` a declared finding class.

### 3.9 Containment

@req containment=v1
@cites #{declared-items=v1}

Containment is a relation in which one declared item holds another, and
the other belongs to it. A design holds only specifications and
requirements. A specification holds only requirements. No other
declared item holds a declared item. A specification belongs to at
most one design. A requirement belongs to at most one design and to at
most one specification. A requirement that belongs to a specification
belongs to the design to which that specification belongs, and to no
design when that specification belongs to none. A design holds a
requirement directly when the requirement belongs to the design and to
no specification.

### 3.10 Texts of declared items

@req item-texts=v1
@cites #{declared-items=v1, containment=v1, repositories=v1}

The text of a declared item in a tree is a part of the files of that
tree. In each tree, these are true:

- The declaration of each declared item is in the text of the item.
- The text of each specification and of each requirement that a design
  holds is in the text of the design.
- The text of each requirement that a specification holds is in the
  text of the specification.
- No part of a file is in the texts of two different requirements.

### 3.11 Designs

@req designs=v1
@cites {text#{conforming-programs=v1}, #{declared-items=v1}}

Each design is a declared item that specifies one part of a system.

### 3.12 Own texts

@req own-texts=v1
@cites #{designs=v1, containment=v1, item-texts=v1}

The own text of a design is the part of the text of the design that is
in the text of none of the specifications and none of the requirements
that the design holds.

### 3.13 Specifications

@req specifications=v1
@cites #{declared-items=v1, designs=v1, containment=v1}

Each specification is a declared item that specifies one thing, such
as a format, a protocol, or a set of behaviors, of the part of a system
that the design that holds it specifies.

### 3.14 Requirements

@req requirements=v1
@cites {
    text#{conforming-programs=v1},
    #{declared-items=v1, containment=v1, item-texts=v1, designs=v1},
}

Each requirement is a declared item whose text states one definition,
or one obligation of each conforming program of the design that holds
the requirement.

### 3.15 Normative text

@req normative-text=v1
@cites {
    text#{conforming-programs=v1},
    #{
        designs=v1, specifications=v1, requirements=v1, item-texts=v1,
        containment=v1,
    },
}

The text of each requirement is normative: it states what a conforming
program of the design that holds the requirement is or does. The rest
of the text of a design and of each specification that it holds is not
normative.

### 3.16 Decision records

@req decision-records=v1
@cites #{declared-items=v1}

Each decision record is a declared item that records one standing
practice of a project, or one choice with its reason.

### 3.17 Findings

@req findings=v1
@cites {identifiers#{segments=v1}, #{repositories=v1}}

A finding is a report of one condition about one part of a repository.
Each finding is of one finding class: the sort of condition that the
finding reports, which a slug names.

### 3.18 Declared finding classes

@req declared-finding-classes=v1
@cites #{findings=v1, declared-items=v1, item-texts=v1, repositories=v1}

A declared finding class is a finding class that a repository declares
for itself with a declaration. Its text is the whole of one file of the
tree, its finding-class file. A finding class that a conforming program
has built in is not an item.

### 3.19 Names

@req names=v1
@cites {
    identifiers#{segments=v1},
    #{
        containment=v1, designs=v1, specifications=v1, requirements=v1,
        decision-records=v1, declared-finding-classes=v1,
    },
}

The name of a design, of a decision record, and of a declared finding
class is a slug. The name of a specification or of a requirement that
belongs to a design is a full name: the slug of that design, `#`, and
the part name of the specification or the requirement. The name of a
specification or of a requirement that belongs to no design is a slug.
These are the sets of names:

- The designs, the decision records, and the specifications and the
  requirements that belong to no design share one set of slugs.
- The declared finding classes have a set of slugs of their own.
- The specifications and the requirements of one design share one set
  of part names.

### 3.20 Kinds that kind words state

@req stated-kinds=v1
@cites {
    identifiers#{
        kind-words=v1, entries=v1, destinations=v1, external-targets=v1,
        extern-grammar=v1,
    },
    #{
        designs=v1, specifications=v1, requirements=v1,
        decision-records=v1, declared-finding-classes=v1,
        external-items=v1,
    },
}

A kind word at the start of an entry of a citation, of the target of
an inline citation, or of the target of an `@extern` line states what
the entry or the target names. `design` states a design. `spec` states
a specification, or an external item that is a standard. `req` states
a requirement. `decision` states a decision record. `finding-class`
states a declared finding class. `term` states an external item that
is a term.

### 3.21 Marks

@req extern-marks=v1
@cites {
    identifiers#{tag-words=v1, extern-grammar=v1, segments=v1},
    #{
        items=v1, designs=v1, declared-items=v1, own-texts=v1,
        containment=v1, item-texts=v1, names=v1, stated-kinds=v1,
        repositories=v1,
    },
}

The file of a design is the file in which the declaration of the design
stands. A mark is what an `@extern` line in the own text of a design
states: the design holds an item that is what the kind word of the line
states, whose part name is the part name of the line, and whose
declaration is in a file other than the file of the design.

### 3.22 Values

@req values=v1
@cites text#{conforming-programs=v1, results=v1, texts=v1}

A value is a thing, such as a text, that a conforming program of a
design gives together with a result.

### 3.23 Conformance vectors

@req conformance-vectors=v1
@cites {
    text#{conforming-programs=v1, inputs=v1, results=v1},
    #{items=v1, values=v1, designs=v1, requirements=v1, containment=v1},
}

A conformance vector is an item that has an input of a conforming
program of one design, the design of the vector; the result that a
conforming program of that design gives for that input; and the values
that it gives together with that result. The result and the values of
a conformance vector follow from the requirements that its design
holds.

### 3.24 Vector sets

@req vector-sets=v1
@cites {
    text#{whole-numbers=v1},
    #{
        conformance-vectors=v1, specifications=v1, designs=v1,
        requirements=v1, containment=v1, repositories=v1,
    },
}

Each conformance vector is given for one specification of its design,
or for the requirements that its design holds directly. The vector set
of a specification is the set of the conformance vectors given for it.
The vector set of a design is the set of the conformance vectors given
for the requirements that it holds directly. Each conformance vector
has a number: a whole number of 0 or more that names it in its vector
set. No two conformance vectors of one vector set have the same number,
and a number that a conformance vector of a vector set has in one tree
of a repository names no other conformance vector of that vector set
in any tree of that repository.

### 3.25 Groups

@req groups=v1
@cites #{items=v1, vector-sets=v1, conformance-vectors=v1}

A group is an item: a named set of conformance vectors of one vector
set. Each conformance vector is in exactly one group of its vector set.
No two groups of one vector set have the same name.

### 3.26 Selections

@req vector-selections=v1
@cites {
    identifiers#{entries=v1},
    #{conformance-vectors=v1, vector-sets=v1, groups=v1},
}

An entry of a citation can name one conformance vector, one group, or
one vector set. The selection of such an entry is a set of conformance
vectors: the one vector, when the entry names a conformance vector;
every vector of the group, when the entry names a group; and every
vector of the vector set, when the entry names a vector set.

### 3.27 Tests

@req tests=v1
@cites {identifiers#{tag-words=v1}, #{items=v1, repositories=v1}}

A test is an item: a unit of code that a test framework runs and
reports as passed or failed, such as a test function, or a set of such
units, such as the tests of one `describe` block. The code in the files
of a tree names each test, and no declaration declares one.

### 3.28 Test evidence

@req test-evidence=v1
@cites #{tests=v1}

Test evidence is the set of the reports that tests gave in one
execution of their test frameworks: which tests ran, and which of them
passed and which failed.

### 3.29 Sites

@req sites=v1
@cites {
    identifiers#{tag-words=v1, destinations=v1},
    #{items=v1, declared-items=v1, tests=v1, repositories=v1},
}

A site is an item with no name: a block of text in a file of a tree,
such as a comment in code or a section of a markdown file, in which
citations or inline citations stand, and that is neither a declared
item nor a test.

### 3.30 External items

@req external-items=v1
@cites {
    identifiers#{external-ids=v1, segments=v1},
    #{items=v1, repositories=v1},
}

An external item is an item outside the repository that an external id
names, such as an issue or a published standard. An external id with
`#` and a part name names a part of such an item, and that part is an
external item too. An external item can be a standard: a published
standard, or a part of one. An external item can be a term: a word or
a fixed phrase to which a published document gives one meaning.

### 3.31 Revised content

@req revised-content=v1
@cites {
    identifiers#{revisions=v1},
    #{
        items=v1, declared-items=v1, designs=v1, own-texts=v1,
        specifications=v1, requirements=v1, decision-records=v1,
        declared-finding-classes=v1, item-texts=v1, containment=v1,
        conformance-vectors=v1, values=v1, vector-sets=v1, groups=v1,
    },
}

The revised content of an item is this:

- of a design, its own text;
- of a specification, its text, without the labels of the declarations
  of the requirements that it holds;
- of a requirement, of a decision record, and of a declared finding
  class, its text;
- of a conformance vector, its input, its result, and its values;
- of a group, which conformance vectors are in it, and the revised
  content of each;
- of a vector set, which conformance vectors are in it, and the revised
  content of each.

A task, a plan, a test, a site, and an external item have no revised
content.

### 3.32 Revisions of items

@req item-revisions=v1
@cites {
    identifiers#{revisions=v1, tag-words=v1},
    #{items=v1, revised-content=v1, declared-items=v1, repositories=v1},
}

A revision of an item is a label that names one revised content of the
item. No label names two different revised contents of one item, in
one tree or in two trees of a repository. The current revision of an
item in a tree is the label that names the revised content that the
item has in that tree. The current revision of a declared item in a
tree is the label of its declaration in that tree. An item with no
revised content has no revision.

### 3.33 Edges

@req edges=v1
@cites {
    identifiers#{tag-words=v1, entries=v1, destinations=v1},
    #{
        items=v1, names=v1, external-items=v1, vector-selections=v1,
        work-items=v1, repositories=v1,
    },
}

An edge is a relation of one kind of edge from an item, its source, to
an item, its cited item. Each entry of a citation states one edge,
whose kind of edge is the citation word of the citation without its
`@`. The target of each inline citation states one edge, whose kind of
edge is `cites`. The kinds of edge are these five: `cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`. The cited item of
an edge in a tree is the item that the entry or the target that states
the edge names in that tree. When no item of that tree and no external
item has that name, the edge has no cited item in that tree. No edge
has a work item as its cited item.

### 3.34 Sources of edges

@req edge-sources=v1
@cites {
    identifiers#{tag-words=v1, destinations=v1},
    #{edges=v1, declared-items=v1, item-texts=v1, tests=v1, sites=v1},
}

A citation or an inline citation stands in a declared item when it is
in the text of the item, in a site when it is in the block of text of
the site, and in a test when it is in a comment on the code of the
test. Each edge has exactly one source: a declared item, a test, or a
site in which the citation or the inline citation that states the edge
stands.

### 3.35 Pinned edges

@req pinned-edges=v1
@cites {
    identifiers#{revisions=v1, entries=v1, destinations=v1},
    #{edges=v1, item-revisions=v1, revised-content=v1},
}

An edge is pinned when the entry or the target that states it carries
a label, and that label is the label of the edge. A pinned edge states
its relation to the revised content of its cited item that its label
names. An edge whose entry or target carries `*` is not pinned, and it
states its relation to its cited item at each revision of the cited
item.

### 3.36 Edges of the kind `cites`

@req cites-edges=v1
@cites #{edges=v1}

A `cites` edge states that its source refers to its cited item and
rests on what the cited item says.

### 3.37 Edges of the kind `satisfies`

@req satisfies-edges=v1
@cites #{edges=v1}

A `satisfies` edge states that its source does what its cited item
states.

### 3.38 Edges of the kind `verifies`

@req verifies-edges=v1
@cites {
    text#{conforming-programs=v1, inputs=v1, results=v1},
    #{
        edges=v1, requirements=v1, conformance-vectors=v1, groups=v1,
        vector-sets=v1, vector-selections=v1, values=v1,
    },
}

A `verifies` edge states that its source checks code. When its cited
item is a requirement, the edge states that the code that the source
runs meets that requirement. When its cited item is a conformance
vector, a group, or a vector set, the edge states that the code that
the source runs gives, for the input of each conformance vector of the
selection of the entry of the edge, the result and the values of that
vector.

### 3.39 Edges of the kind `refines`

@req refines-edges=v1
@cites #{edges=v1}

A `refines` edge states that its source states all or part of its
cited item in more detail.

### 3.40 Edges of the kind `supersedes`

@req supersedes-edges=v1
@cites {
    identifiers#{citation-grammar=v1, segments=v1},
    #{
        items=v1, edges=v1, declared-items=v1, designs=v1,
        specifications=v1, requirements=v1, containment=v1, names=v1,
    },
}

A `supersedes` edge states that its source is to replace its cited
item. When the entry of a `supersedes` edge is an every-part target,
and its source and its cited item are designs, the edge also states
that each specification and each requirement that the cited design
holds is to be replaced by the specification or the requirement that
the source design holds with the same kind of item and the same part
name, when the source design holds one. Only a `supersedes` edge
states that one declared item is to replace another.

### 3.41 Status tags of declared items

@req item-status-tags=v1
@cites {identifiers#{tag-words=v1}, #{declared-items=v1, item-texts=v1}}

A status tag stands in a declared item when it is in the text of the
item. Each status tag that stands in a declared item is a status tag of
exactly one declared item in which it stands, and no other status tag
is a status tag of a declared item.

### 3.42 Acks

@req acks=v1
@cites {
    identifiers#{tag-words=v1, ack-grammar=v1, segments=v1},
    #{findings=v1, people=v1, agents=v1},
}

An ack is what an `@ack` line states: a person or an agent accepts one
finding for one block of text. The finding is of the finding class
that the slug of the line names, and it is about what the subject of
the line names. The block of text is the block in which the `@ack` line
stands. The hash prefix of the line is the start of the hash of that
block, as the block was when the ack was written.

### 3.43 Valid edges

@req valid-edges=v1
@cites {
    identifiers#{
        kind-words=v1, entries=v1, destinations=v1, external-targets=v1,
        citation-grammar=v1,
    },
    #{
        items=v1, edges=v1, edge-sources=v1, stated-kinds=v1,
        declared-items=v1, external-items=v1, requirements=v1,
        specifications=v1, designs=v1, tests=v1, conformance-vectors=v1,
        groups=v1, vector-sets=v1, repositories=v1,
    },
}

An edge is valid in a tree when, and only when, each of these is true
in that tree:

- The edge has a cited item.
- When the entry or the target that states the edge starts with a kind
  word, its cited item is what that kind word states.
- The kinds of its source and of its cited item fit its kind of edge:
  - for `cites`, the cited item is a declared item or an external item;
  - for `satisfies`, the cited item is a requirement;
  - for `verifies`, the source is a test, and the cited item is a
    requirement, a conformance vector, a group, or a vector set;
  - for `refines`, the source and the cited item are each a
    requirement, a specification, or a design;
  - for `supersedes`, the source is a declared item, and the cited item
    is a declared item of the same kind of item; when the entry is an
    every-part target, the source and the cited item are designs.

### 3.44 Valid marks

@req valid-marks=v1
@cites {
    identifiers#{tag-words=v1, extern-grammar=v1, segments=v1},
    #{
        extern-marks=v1, containment=v1, designs=v1, specifications=v1,
        requirements=v1, names=v1, repositories=v1,
    },
}

A mark of a design is valid when, and only when, one of these is true:

- The kind word of its `@extern` line is `spec`, and the design holds a
  specification whose part name is the part name of the line and whose
  declaration is in a file other than the file of the design.
- The kind word of its `@extern` line is `req`, and the design holds
  directly a requirement whose part name is the part name of the line
  and whose declaration is in a file other than the file of the design.

### 3.45 Valid status tags

@req valid-status-tags=v1
@cites {
    identifiers#{tag-words=v1},
    #{
        items=v1, declared-items=v1, item-status-tags=v1, requirements=v1,
        specifications=v1, designs=v1, decision-records=v1,
    },
}

A status tag of a declared item is valid when, and only when, the kind
of item of that declared item fits the status word of the status tag.
`@deprecated` fits a requirement, a specification, a design, and a
decision record. `@rejected` and `@deferred` fit only a decision
record.

### 3.46 Valid trees

@req valid-trees=v1
@cites {
    identifiers#{tag-words=v1, extern-grammar=v1, segments=v1},
    #{
        repositories=v1, edges=v1, valid-edges=v1, valid-marks=v1,
        valid-status-tags=v1, item-status-tags=v1, extern-marks=v1,
        containment=v1, specifications=v1, requirements=v1, designs=v1,
        names=v1, declared-items=v1,
    },
}

A tree is valid when, and only when, each of these is true in it:

- Each edge is valid.
- Each mark of each design is valid.
- Each status tag of each declared item is valid.
- Each specification and each requirement belongs to exactly one
  design.
- For each specification that a design holds, and for each requirement
  that a design holds directly, whose declaration is in a file other
  than the file of the design, the design has a mark whose `@extern`
  line has the kind word of that item, `spec` or `req`, and its part
  name.
- Each name of each set of names names at most one declared item.

### 3.47 Work items

@req work-items=v1
@cites #{items=v1, repositories=v1}

A work item is a task or a plan. No work item is in a file of a tree.
Each work item has a work item id, which never changes, and a display
name, which can change.

### 3.48 Tasks

@req tasks=v1
@cites #{
    work-items=v1, repositories=v1, external-items=v1, people=v1,
    agents=v1,
}

A task is a work item for one piece of work that one person or one
agent can finish alone. The paths of a task are a set of paths: the
work of the task can add, change, or remove a file only when the path
of the file is in that set. A task names at most one external item,
which can say what the work is, and several tasks can name one external
item. A task that names an external item can have an empty display
name. A task has no description of its own and no branch.

### 3.49 Promises

@req promises=v1
@cites #{
    tasks=v1, edges=v1, edge-sources=v1, requirements=v1,
    repositories=v1,
}

A promise of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and a requirement. It states that the work of the task puts
into the tree of the default branch an edge of that kind of edge whose
cited item is that requirement, from a source in a file whose path is
in the paths of the task.

### 3.50 Plans

@req plans=v1
@cites #{work-items=v1, tasks=v1}

A plan is a work item that says how a set of tasks gets done.

### 3.51 Waits

@req waits=v1
@cites #{work-items=v1}

A wait is a relation from one work item, the waiting item, to another
work item, the item that it waits for.

### 3.52 What a plan carries out

@req carried-out-items=v1
@cites #{plans=v1, requirements=v1, specifications=v1, designs=v1}

A plan carries out a set of requirements, specifications, and designs:
its work is for them.

### 3.53 Definitions of work items

@req definitions-of-work-items=v1
@cites #{
    work-items=v1, tasks=v1, promises=v1, plans=v1, waits=v1,
    carried-out-items=v1, external-items=v1, requirements=v1,
    specifications=v1, designs=v1,
}

The definition of a task is its display name, its paths, its promises,
its external item, its plan, and its waits. The definition of a plan is
its display name, its plan, its waits, and the requirements,
specifications, and designs that it carries out. The plan of a work
item is the one plan, or none, that its definition names. The waits of
a work item are the waits from it that its definition names. The work
item id of a work item is not part of its definition.

### 3.54 Cycles of definitions

@req definition-cycles=v1
@cites #{
    definitions-of-work-items=v1, work-items=v1, tasks=v1, plans=v1,
    waits=v1,
}

A set of definitions of work items, at most one for each work item,
forms a cycle when a work item can reach itself in one or more steps
along one of these three relations, in which each work item has the
definition that the set gives it:

1. from a work item to its plan;
2. from a work item to each work item that it waits for;
3. from a plan to each work item whose plan it is, and from a task to
   each work item that the task waits for and to each work item that a
   plan waits for when the task reaches that plan along relation 1.

### 3.55 Changes

@req changes=v1
@cites {text#{lines=v1}, #{repositories=v1, people=v1}}

A change is a set of commits on a branch, the branch of the change,
that a person merges into the default branch as one unit, such as the
commits of a pull request. The person who merges a change brings its
work to the default branch, as its commits or as one squash commit. The
diff of a change is the set of the lines that differ between the tree
of the commit from which the branch of the change starts and the tree
of the last commit of the change: the lines that the change adds and
the lines that it removes. The lines of a change are the lines of its
diff and the lines of the messages of its commits.

### 3.56 Delivery lines

@req delivery-lines=v1
@cites {
    text#{lines=v1},
    #{
        repositories=v1, tasks=v1, promises=v1, work-items=v1,
        definitions-of-work-items=v1,
    },
}

A delivery line is a line of the message of a commit that states that
the commit completes the work of one task. It names the task by its
work item id, and it names one definition of the task by the start of
a hash of the paths and the promises of that definition. The finishing
commit of a delivery line is the commit in whose message the line is. A
delivery of a task is the arrival of the finishing commit of a delivery
line of the task on the default branch.

### 3.57 Task lines

@req task-lines=v1
@cites {text#{lines=v1}, #{repositories=v1, tasks=v1, work-items=v1}}

A task line is a line of the message of a commit that names one task by
its work item id, and that states that the commit does part of the work
of the task without finishing it.

### 3.58 Tasks of a change

@req change-tasks=v1
@cites #{
    changes=v1, delivery-lines=v1, task-lines=v1, tasks=v1,
    repositories=v1,
}

The tasks of a change are the tasks that the delivery lines and the
task lines in the messages of the commits of the change name.

### 3.59 Ledger entries

@req ledger-entries=v1
@cites #{actors=v1, people=v1, agents=v1, job=v1, repositories=v1}

A ledger entry is a record of one event, such as one approval that a
person gave, or one observation of the job. Each ledger entry has one
of these eight kinds of ledger entry: `task`, `plan`, `approval`,
`decline`, `done`, `abandoned`, `delivered`, and `void`. Each ledger
entry records the actor that wrote it, the person for whom that actor
acts when the actor is an agent, and the branch from which it was
written, when there was one.

### 3.60 The ledger

@req ledger=v1
@cites {
    text#{whole-numbers=v1},
    #{ledger-entries=v1, actors=v1, repositories=v1},
}

The ledger of a repository is a sequence of ledger entries, in the
order in which actors appended them. An actor appends a ledger entry
after each ledger entry that is in the ledger at that time. Of two
ledger entries that actors appended to the ledger, the one that was
appended later comes later in the ledger, whatever times the two ledger
entries record. A point of the ledger is given by the ledger
entries before it: the first n ledger entries of the ledger, for a
whole number n of 0 or more. A ledger entry that a clone of the
repository has and has not pushed yet is provisional: it can still come
later in the ledger than ledger entries that other clones push first.

### 3.61 Repairs and voids

@req repairs=v1
@cites #{ledger=v1, ledger-entries=v1, people=v1}

A repair is the one write to the ledger that is not an append, and
only a person makes one. A repair removes one or more ledger entries
from the ledger. For each
ledger entry that it removes, it puts one `void` ledger entry, a void,
in the ledger where the removed ledger entry stood: after each ledger
entry that came before the removed one, and before each ledger entry
that came after it. A void records that a repair removed one ledger
entry, and the reason for the removal. A repair makes no other ledger
entry different.

### 3.62 Definition entries

@req definition-entries=v1
@cites #{
    ledger-entries=v1, work-items=v1, tasks=v1, plans=v1,
    definitions-of-work-items=v1, people=v1, agents=v1, judgments=v1,
}

A definition entry is a ledger entry that records one whole definition
of one work item: a `task` ledger entry records a definition of a task,
and a `plan` ledger entry records a definition of a plan. A person or
an agent writes a definition entry. A definition entry records no
judgment.

### 3.63 Current definitions

@req current-definitions=v1
@cites #{
    definition-entries=v1, ledger=v1, work-items=v1,
    definitions-of-work-items=v1, definition-cycles=v1, states=v1,
}

Each definition entry of a work item records either the first
definition of the work item, or an edit of one earlier definition of
the work item. The current definition of a work item at a point of the
ledger is the definition that the latest accepted definition entry of
the work item before that point records. A definition entry is accepted
only when both of these are true:

1. It records an edit of the current definition of its work item at the
   point just before it, or it records the first definition of its work
   item and no accepted definition entry of that work item comes before
   it.
2. The current definitions of the work items at the point just before
   it form no cycle when its definition is used instead of the current
   definition of its work item.

A definition entry that is not accepted changes no definition and no
state. A work item exists from its first accepted definition entry.

### 3.64 Subjects of approval

@req subjects-of-approval=v1
@cites #{
    people=v1, designs=v1, own-texts=v1, specifications=v1,
    requirements=v1, decision-records=v1, containment=v1,
    revised-content=v1,
}

A subject of approval is a unit that a person approves or declines as a
whole. The subjects of approval are these four: the own text of a
design; a specification, with its requirements; a requirement that a
design holds directly; and a decision record. The revised content of
the own text of a design is that own text. The revised content of each
other subject of approval is the revised content of its specification,
its requirement, or its decision record.

### 3.65 Judgments

@req judgments=v1
@cites #{
    ledger-entries=v1, people=v1, subjects-of-approval=v1, tasks=v1,
    plans=v1, promises=v1, requirements=v1, revised-content=v1,
    item-revisions=v1,
}

A judgment is a ledger entry that records a decision of a person. Only
a person writes a judgment. A judgment is one of these four kinds of
ledger entry:

- An `approval` ledger entry records that a person approved one revised
  content of one subject of approval.
- A `decline` ledger entry records that a person declined one revised
  content of one subject of approval.
- A `done` ledger entry records that a person judged the work of one
  task finished, and, for each requirement that the task promises, the
  revision of that requirement at which the person judged the work
  finished.
- An `abandoned` ledger entry records that a person ended one task or
  one plan without finishing its work, and the reason.

### 3.66 Records of the job

@req job-records=v1
@cites #{
    ledger-entries=v1, job=v1, delivery-lines=v1, promises=v1, tasks=v1,
    test-evidence=v1, requirements=v1, item-revisions=v1,
    repositories=v1,
}

A record of the job is a ledger entry that records what the job
observed. Only the job writes a record of the job. A `delivered` ledger
entry is a record of the job, and no other kind of ledger entry is one.
A `delivered` ledger entry records that the job read one delivery line
in the commits that the job read, and it is a `delivered` ledger entry
of the task that the line names. For each promise of that task, it
records what the job observed about the promise in the tree that the
job read, with the test evidence that the job read during its
execution, and the revision that the promised requirement has in that
tree.

### 3.67 States

@req states=v1
@cites #{
    items=v1, edges=v1, subjects-of-approval=v1, ledger-entries=v1,
    ledger=v1, test-evidence=v1, repositories=v1,
}

A state is a named condition that an item, an edge, or a subject of
approval is in at one time. Each state follows from the trees and the
messages of the commits of a repository, from the ledger entries of its
ledger, and from test evidence. No ledger entry records a state.

### 3.68 Deprecated

@req deprecated-items=v1
@cites {
    identifiers#{tag-words=v1},
    #{declared-items=v1, item-status-tags=v1, repositories=v1},
}

A declared item is deprecated in a tree when a `@deprecated` status tag
of the item in that tree states that the item no longer applies and
that nothing replaces it.

### 3.69 Rejected

@req rejected-records=v1
@cites {
    identifiers#{tag-words=v1},
    #{decision-records=v1, item-status-tags=v1, repositories=v1},
}

A decision record is rejected in a tree when a `@rejected` status tag
of the record in that tree states that the choice of the record was
considered and not made.

### 3.70 Deferred

@req deferred-records=v1
@cites {
    identifiers#{tag-words=v1},
    #{decision-records=v1, item-status-tags=v1, repositories=v1},
}

A decision record is deferred in a tree when a `@deferred` status tag
of the record in that tree states that the choice of the record is not
made yet.

### 3.71 Effective edges of the kind `supersedes`

@req effective-supersedes-edges=v1
@cites #{
    items=v1, edges=v1, edge-sources=v1, declared-items=v1,
    item-status-tags=v1, approval-states=v1, repositories=v1,
}

A `supersedes` edge is effective in a tree when, and only when, each of
these is true in that tree: its source is a declared item; its source
has no status tag; and, when the repository needs approval for declared
items of the kind of item of its source, its source is approved.

### 3.72 In force and retired

@req retired-items=v1
@cites #{
    declared-items=v1, designs=v1, specifications=v1, edges=v1,
    item-status-tags=v1, effective-supersedes-edges=v1, containment=v1,
    repositories=v1,
}

A declared item is retired in a tree when, and only when, one of these
is true in that tree:

- the item has a status tag;
- an effective `supersedes` edge has the item as its cited item;
- the item belongs to a retired design or to a retired specification.

A declared item is in force in a tree when it is not retired in that
tree.

### 3.73 Approved and declined

@req approval-states=v1
@cites #{
    subjects-of-approval=v1, people=v1, ledger-entries=v1, judgments=v1,
    ledger=v1, revised-content=v1, containment=v1, designs=v1,
    own-texts=v1, specifications=v1, requirements=v1, repositories=v1,
}

A subject of approval is approved in a tree when, and only when, an
`approval` ledger entry records that a person approved the revised
content that the subject has in that tree, and no later `decline` ledger
entry records that a person declined that revised content. A subject of
approval is declined in a tree when, and only when, a `decline` ledger
entry records that a person declined the revised content that the
subject has in that tree, and no later `approval` ledger entry records
that a person approved that revised content. A requirement that a
specification holds is approved in a tree when that specification is
approved in that tree, and declined in a tree when that specification is
declined in that tree. A design is approved in a tree when its own text,
each of its specifications, and each requirement that it holds directly
are approved in that tree.

### 3.74 Drafts

@req draft-designs=v1
@cites #{designs=v1, approval-states=v1, repositories=v1}

A design is a draft in a tree when it is not approved in that tree.

### 3.75 Suspect

@req suspect-edges=v1
@cites #{pinned-edges=v1, edges=v1, item-revisions=v1, repositories=v1}

An edge is suspect in a tree when, and only when, it is pinned, its
cited item is in that tree, and its label is not the current revision
of its cited item in that tree.

### 3.76 The states of a task

@req task-states=v1
@cites #{
    tasks=v1, promises=v1, states=v1, ledger=v1, ledger-entries=v1,
    judgments=v1, job-records=v1, current-definitions=v1,
}

A ledger entry ends a task when it is an `abandoned` ledger entry of
the task, a `done` ledger entry of the task, or a `delivered` ledger
entry of the task whose observations show that the work of the task
kept each promise of the task. The state of a task at a point of the
ledger follows from the ledger entries before that point, and it is
exactly one of these four:

- done: the first ledger entry that ends the task is a `done` ledger
  entry or a `delivered` ledger entry;
- abandoned: the first ledger entry that ends the task is an
  `abandoned` ledger entry;
- delivered: no ledger entry ends the task, and a `delivered` ledger
  entry of the task is in the ledger;
- open: the task exists, no ledger entry ends the task, and no
  `delivered` ledger entry of the task is in the ledger.

A task is unfinished while it is open or delivered.

### 3.77 The parts and the states of a plan

@req plan-states=v1
@cites #{
    plans=v1, tasks=v1, work-items=v1, definitions-of-work-items=v1,
    current-definitions=v1, task-states=v1, ledger-entries=v1,
    judgments=v1, ledger=v1, states=v1,
}

At a point of the ledger, the parts of a plan, the work items under
it, and its state are these, from the ledger entries before that point:

- A work item is a part of a plan when its current definition names
  that plan as its plan, with two exceptions. An abandoned task is a
  part of no plan. The parts of an abandoned plan are only the work
  items that were parts of it, and done, at the point just before the
  first `abandoned` ledger entry of the plan.
- A work item is under a plan when it is a part of the plan, or under a
  part of the plan.
- The state of a plan is exactly one of these three: abandoned, when an
  `abandoned` ledger entry of the plan is in the ledger; done, when the
  plan is not abandoned, has at least one part, and each of its parts is
  done; and open, when the plan is neither abandoned nor done.

### 3.78 Met waits

@req met-waits=v1
@cites #{waits=v1, work-items=v1, task-states=v1, plan-states=v1}

A wait is met when the work item that it waits for is done.

### 3.79 Ready tasks

@req ready-tasks=v1
@cites #{
    tasks=v1, plans=v1, met-waits=v1, waits=v1, task-states=v1,
    plan-states=v1, definitions-of-work-items=v1, current-definitions=v1,
}

A task is ready when it is open, each wait in its current definition is
met, and each wait in the current definition of each plan that the task
is under is met.

### 3.80 Requirements accounted for

@req requirements-accounted-for=v1
@cites #{
    requirements=v1, specifications=v1, designs=v1, containment=v1,
    tasks=v1, plans=v1, promises=v1, carried-out-items=v1,
    definitions-of-work-items=v1, current-definitions=v1, task-states=v1,
    plan-states=v1, ledger=v1, ledger-entries=v1, judgments=v1,
    job-records=v1, item-revisions=v1, repositories=v1,
}

A requirement is accounted for in a tree, at a point of the ledger,
when, and only when, one of these is true:

- the current definition of an unfinished task has a promise of the
  requirement;
- the current definition of an open plan names, as carried out, the
  requirement, the specification that holds it, or the design that
  holds it;
- for a done task, the first ledger entry that ends the task records,
  for the requirement, a revision that is the current revision of the
  requirement in that tree.

### 3.81 Statements of agents

@req agent-statements=v1
@cites {
    text#{texts=v1, lines=v1},
    #{agents=v1, repositories=v1, ledger-entries=v1, people=v1},
}

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, a ledger entry, or a
message to a person.

### 3.82 The states that statements of agents change

@req limit-agent-statements=v1
@cites #{
    agent-statements=v1, states=v1, changes=v1, definition-entries=v1,
    item-revisions=v1, work-items=v1,
}

A conforming program must compute no state from a statement of an
agent, other than from these two:

1. a line of a change that names what it is about by a hash, a revision
   of an item, or a work item id;
2. a definition entry.

### 3.83 The summary of a change

@req show-change-definitions=v1
@cites #{
    changes=v1, change-tasks=v1, tasks=v1, definition-entries=v1,
    ledger-entries=v1, people=v1, agents=v1, repositories=v1,
}

For each change, a conforming program must give a summary of the change
that shows every definition entry of each task of the change, and every
definition entry that was written from the branch of the change. The
summary must show each of these definition entries with the person who
wrote it or for whom an agent wrote it, the agent that wrote it when an
agent did, and the branch from which it was written when there was one.

### 3.84 Sessions

@req sessions=v1
@cites #{agents=v1, tasks=v1}

A session is one execution of an agent on its work. The declared task
of a session is the task that the agent declares as the work of that
session.

### 3.85 Briefs of sessions

@req session-briefs=v1
@cites {
    text#{texts=v1, conforming-programs=v1},
    #{agents=v1, sessions=v1},
}

The brief of a session is the text about its work that a conforming
program gives the agent of the session for that session.

### 3.86 The use of declared tasks

@req limit-declared-tasks=v1
@cites #{sessions=v1, session-briefs=v1}

A conforming program must use the declared task of a session only to
narrow the brief of that session.

## 4. Conformance

A program conforms to the design when it meets every requirement of
section 3. A program meets a requirement in one of two ways, by what
the requirement states:

- a definition: each item, relation, ledger entry, and state that the
  program reads, records, or reports under the term that the
  requirement defines has the meaning that the requirement gives it;
- an obligation: the program does what the obligation states.

No requirement of section 3 gives a result for an input, so the design
has no conformance vectors.
