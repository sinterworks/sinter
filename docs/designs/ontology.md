<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
Specifies the kinds of items that Sinter traces, the relations between them, the ledger and its entries, the actors, the names and meanings of the states of items, and the rule for the statements of agents.

Sinter traces the items of a repository: designs and their
requirements, decision records, tests, tasks and plans, and the items
outside the repository that external ids name. A citation, such as
`@verifies packs#size-limit=v2` in a comment of a test, states an edge:
a relation from its source, here the test, to the item that it names,
here the requirement `packs#size-limit` at its revision `v2`. The
ledger of a repository records facts, such as the approval that a
person gave to one text. Each state of an item, such as in force,
approved, suspect, or done, follows from such facts.

From Identifiers, the design takes the tag words and the kind words,
names, labels and revisions, external ids, the entries of a citation,
and inline citations. It gives each tag word and each kind word its
meaning. From Text and notation, the design takes what a design, a
requirement, a conforming program, an input, and a result are.

## 1. Terms

| term | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that a project made |
| item | a thing that Sinter traces, such as a requirement, a test, or a task |
| kind | the sort of an item, such as design or task; each item has one kind |
| declared item | an item that a declaration declares: a design, a specification, a requirement, a decision record, or a finding class |
| text of a declared item | the part of the files of a tree that a declared item consists of, its declaration included |
| containment | the relation in which a design holds its specifications and its requirements, and a specification holds its requirements |
| hold, belong to | a design holds each of its specifications, and each specification belongs to its design; the same for requirements |
| hold directly | a design holds a requirement directly when the requirement belongs to no specification |
| design | a declared item that specifies one part of a system |
| own text | the part of the text of a design that none of its specifications and none of its requirements holds |
| specification | a declared item that specifies one thing of its design, such as a format or a protocol |
| requirement | a declared item that states one definition, or one obligation of a conforming program |
| normative | stating what a conforming program is or does; only the text of requirements is normative |
| decision record | a declared item that records one standing practice of a project, or one choice with its reason |
| finding | a report of one condition at one place of a repository |
| finding class | a kind of finding, which a slug names; one that a repository declares for itself is a declared item |
| finding-class file | the file of the repository that holds one declared finding class |
| mark | what an `@extern` line states: a design holds a specification or a requirement that is declared outside the file of the design |
| ack | what an `@ack` line states: a person or an agent accepts one finding for one text |
| conformance vector | an item that holds one input of a conforming program, the result that it gives, and the values that it gives with that result |
| value | a text or a fact that a conforming program gives together with a result |
| vector set | the set of the conformance vectors of one specification, or of one design for the requirements that it holds directly |
| number of a vector | the whole number that names a conformance vector in its vector set |
| group | a named part of a vector set; each conformance vector belongs to one group |
| selection | the set of conformance vectors that one entry names: one vector, every vector of a group, or every vector of a vector set |
| test | a unit of code that a test framework runs and reports with a result, or a group of such units |
| test evidence | the results that the runs of the tests of a tree reported |
| site | an item with no name: a block of text that holds citations and that is neither a declared item nor a test |
| external item | an item outside the repository that an external id names, such as an issue or a standard |
| term | a word or a fixed phrase to which a document gives one meaning |
| revised content | the part of an item that its revision covers, such as the own text of a design |
| revision of an item | a label that names one revised content of the item |
| current revision | the label that names the revised content of an item in a given tree |
| edge | a relation of one kind from a source to a cited item, which a citation or an inline citation states |
| source | the item from which an edge goes: a declared item, a test, or a site |
| cited item | the item that the entry of an edge names |
| pinned edge | an edge whose entry carries a label; it states its relation to the revised content that the label names |
| repository | a git repository |
| tree | the set of the files of a repository at one commit |
| default branch | the branch into which work on a repository merges |
| change | a set of commits on a branch that a person merges into the default branch as one unit |
| lines of a change | the lines of the diff of a change, and the lines of the messages of its commits |
| work item | a task or a plan |
| task | a work item for one piece of work that one person or one agent can finish alone |
| paths of a task | the paths of the files that the work of a task can change |
| promise | a pair of an edge kind, `satisfies` or `verifies`, and a requirement, which states what the work of a task puts into the tree |
| plan | a work item that says how a set of tasks gets done |
| part of a plan | a task or a plan that belongs to a plan |
| under a plan | a part of the plan, or under a part of the plan |
| wait | a relation from a work item to another work item: the work of the first starts only after the second is done |
| carry out | a plan carries out the requirements, specifications, and designs that its work is for |
| definition of a work item | the parts of a work item that its definition entries record, such as the paths of a task |
| current definition | the definition that the latest accepted definition entry of a work item records |
| delivery line | a line of the message of a commit that states that the commit completes the work of a task |
| finishing commit | the commit whose message holds a delivery line |
| delivery | the arrival of the finishing commit of a delivery line on the default branch |
| task line | a line of the message of a commit that names a task on which the commit does part of the work |
| tasks of a change | the tasks that the delivery lines and the task lines of a change name |
| ledger | the sequence of the entries of a repository, in the order in which writers appended them |
| entry | a record of one fact in the ledger |
| definition entry | an entry that records one definition of one work item |
| accepted | a definition entry is accepted when it gives its work item the definition that it records |
| judgment | an entry that records a decision of a person |
| record of the job | an entry that records what the job observed |
| void | an entry that records that a person dropped an earlier entry |
| actor | a person, an agent, or the job |
| person | a human who works on a repository |
| agent | a program that writes code for a person with a language model |
| job | the run of Sinter that continuous integration starts at each push to the default branch |
| continuous integration | a service that runs checks on the commits of a repository |
| state | a named condition of an item at one time, such as in force or done |
| in force, retired | a declared item is in force when it applies, and retired when it does not |
| deprecated, rejected, deferred | the states that the three status words state |
| subject of approval | a unit that a person approves or declines as a whole |
| approved, declined | the states of a subject of approval after a person approved or declined its revised content |
| suspect | a pinned edge is suspect when its cited item no longer has the revision that it pins |
| open, delivered, done, abandoned | the four states of a task; a plan is open, done, or abandoned |
| unfinished | a task is unfinished while it is open or delivered |
| final | a state that a work item keeps for good |
| accounted for | a requirement is accounted for when work for it is under way, or was finished at its current revision |
| statement of an agent | a text that an agent writes |
| session | one run of an agent on its work |
| declared task | the task that an agent declares as the work of its session |
| brief | the text that Sinter gives an agent about its work for one session |

## 2. The items, their relations, and their states

### 2.1 Items and their kinds

An item is a thing that Sinter traces. Each item has one kind:

| kind | what it is | how it is named | revision |
|---|---|---|---|
| design | a declared item that specifies one part of a system | a slug, such as `packs` | yes |
| specification | a declared item that specifies one thing of its design | a full name, such as `packs#descriptor` | yes |
| requirement | a declared item that states one definition or one obligation | a full name, such as `packs#size-limit` | yes |
| decision record | a declared item that records one practice or one choice | a slug, such as `agent-statements` | yes |
| finding class | a kind of finding that a repository declares for itself | a slug | yes |
| conformance vector | one input of a conforming program, with its result and its values | its vector set and its number | yes |
| group | a named part of a vector set | its vector set and its name | yes |
| vector set | the conformance vectors of one specification or of one design | its specification or its design | yes |
| task | one piece of work | an id | no |
| plan | how a set of tasks gets done | an id | no |
| test | a unit of code that a test framework runs | the code names it | no |
| site | a block of text that holds citations | no name | no |
| external item | a thing outside the repository | an external id, such as `gh/42` | no |

A declared item is an item that a declaration declares. The
declaration word gives its kind: `@design` declares a design, `@spec` a
specification, `@req` a requirement, `@decision` a decision record, and
`@finding-class` a finding class. The text of a declared item is the
part of the files of a tree that the item consists of, its declaration
included.

A work item is a task or a plan. No file of the tree holds a work item:
the entries of the ledger define each one.

### 2.2 Repositories, changes, and actors

A repository is a git repository. The tree of a commit is the set of
the files of the repository, with their contents, at that commit. The
default branch is the branch into which work on the repository merges.

A change is a set of commits on a branch that a person merges into the
default branch as one unit, such as the commits of a pull request. The
lines of a change are the lines of its diff and the lines of the
messages of its commits. The diff of a change holds the lines that its
commits add to the tree and the lines that they remove from it.

Three kinds of actor write the facts that Sinter reads:

- A person is a human who works on a repository.
- An agent is a program that writes code for a person with a language
  model, such as a coding agent. Each agent acts for one person: the
  person who runs it.
- The job is the run of Sinter that continuous integration starts at
  each push to the default branch. Continuous integration is a service
  that runs checks on the commits of a repository. The job observes
  facts that exist only during its run, such as the test evidence of
  the run.

### 2.3 Designs, specifications, and requirements

A design specifies one part of a system. It holds specifications and
requirements. A specification specifies one thing of its design, such
as a format, a protocol, or a set of behaviors, and it holds
requirements. A requirement states one definition, or one obligation of
a conforming program. This relation is containment:

- Each specification belongs to exactly one design.
- Each requirement belongs to exactly one design, and to at most one
  specification of that design.
- A design holds a requirement directly when the requirement belongs to
  no specification.
- No design holds a design, and no specification holds a specification.
  A requirement, a decision record, and a finding class hold no
  declared item.

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
A descriptor holds at most 1 MiB.
```

The own text of a design is the part of its text that none of its
specifications and none of its requirements holds. In the example, the
own text of `packs` is its heading, its two tag lines, and its first
sentence.

Only the text of requirements is normative: it states what a conforming
program is or does. The rest of the text of a design and of its
specifications explains the requirements and gives examples.

The name of a design is a slug, such as `packs`. The name of a
specification or of a requirement is a full name: the slug of its
design, `#`, and its part name, such as `packs#descriptor` and
`packs#size-limit`. Names come in sets, and in one tree each name of a
set names at most one item:

- Designs and decision records share one set of slugs.
- Finding classes have a set of slugs of their own.
- The specifications and the requirements of one design share one set
  of part names.

A design can hold a specification or a requirement whose declaration
stands outside the file of the design. An `@extern` line in the own
text of the design states a mark for each such item, such as
`@extern spec:descriptor`. The kind word of the line gives the kind of
the item, and the part name gives its part name. A mark is part of the
own text of its design.

### 2.4 Decision records, finding classes, and acks

A decision record records one standing practice of a project, or one
choice with its reason, such as the record `agent-statements`.

A finding is a report of one condition at one place of a repository. A
finding class is a kind of finding, and a slug names it. A repository
can declare finding classes of its own. Each such finding class is a
declared item, and its text is its finding-class file: a file of the
repository that holds that one finding class.

An ack is what an `@ack` line states: a person or an agent accepts one
finding for one text. In `@ack retired docs#size=v2 3f2a9c1d`, the slug
`retired` names the finding class, the subject `docs#size=v2` says what
the finding is about, and the hash prefix `3f2a9c1d` is the start of the
hash of the text for which the person or the agent accepts the finding.

### 2.5 Conformance vectors

A conformance vector is one example of an input of a conforming
program, with the result that a conforming program gives for that input
and the values that it gives together with that result. A value is a
text or a fact that the program gives together with a result, such as
the slug of a target. A conformance vector follows from the
requirements, and it states no requirement of its own.

The conformance vectors of a specification form its vector set. The
conformance vectors that a design gives for the requirements that it
holds directly form the vector set of the design. Each conformance
vector has a number, which names it in its vector set. A number names
one vector for the whole life of the vector set: no other vector of the
set ever takes it. Each conformance vector belongs to exactly one
group, a named part of its vector set.

An entry of a citation can name one conformance vector, one group, or
one vector set. The selection of the entry is the set of the vectors
that it names in this way:

| entry | cited item | selection |
|---|---|---|
| `data-forms#toml[12]=v1` | the vector 12 of the vector set of the specification `data-forms#toml` | that one vector |
| `data-forms#toml[offsets][*]=v2` | the group `offsets` of that vector set | every vector of the group |
| `data-forms#toml[*]=v3` | the vector set of `data-forms#toml` | every vector of the vector set |
| `identifiers[37]=v1` | the vector 37 of the vector set of the design `identifiers` | that one vector |

A test that checks code against the vectors of a selection cites them
with `@verifies`:

```python
# @verifies data-forms#toml[offsets][*]=v2
def test_offsets(vector):
    ...
```

### 2.6 Tests, sites, and external items

A test is a unit of code that a test framework runs and reports with a
result, such as a test function. A group of such units, such as the
tests of one `describe` block, is a test too. The code names each
test, so a test has no declaration. The test evidence of a tree is the
set of the results that the runs of the tests of that tree reported:
which tests ran, and which of them passed or failed.

A site is an item with no name. It is a block of text in a file, such
as a comment in code or a section of a markdown file, that holds
citations and that is neither a declared item nor a test. A site is the
source of the edges of such citations.

An external item is an item outside the repository that an external id
names, such as the issue `gh/42` or the standard `rfc/8259`. An
external id with `#` and a part name, such as `rfc/8259#section-6`,
names a part of such an item, and that part is an external item too.
An external item has no revision. An external item can be a
specification: a published standard, or a part of one, that specifies
a thing. It can be a term: a word or a fixed phrase to which a
published document gives one meaning, such as `term:rfc/8259#value`.

### 2.7 Kind words

A kind word at the start of an entry of a citation, or of the target of
an inline citation, states what the entry or the target names:

| kind word | what the entry names |
|---|---|
| `design` | a design |
| `spec` | a specification, or an external item that is a specification |
| `req` | a requirement |
| `decision` | a decision record |
| `finding-class` | a finding class |
| `term` | an external item that is a term |

So `spec:rfc/8259` states that the standard `rfc/8259` is a
specification, and `req:packs#size-limit=v2` states that
`packs#size-limit` is a requirement.

### 2.8 Revisions and pins

The revision of an item covers a part of the item, its revised content.
A revision of an item is a label that names one revised content of that
item. The current revision of an item in a tree is the label that names
its revised content in that tree. For a declared item, it is the label
of its declaration.

| item | revised content |
|---|---|
| design | its own text |
| specification | its text, which holds the text of each of its requirements, without the labels of the declarations of those requirements |
| requirement, decision record, finding class | its text |
| conformance vector | the vector, without its number and its revision |
| group | its conformance vectors, with the revised content of each |
| vector set | its conformance vectors, with the revised content of each |
| task, plan, test, site, external item | none: the item has no revision |

So an edit of a requirement inside a specification changes the revised
content of the requirement and of the specification. An edit of the
own text of a design changes the revised content of the design alone.
A change of one vector changes the revised content of its group and of
its vector set.

An edge is pinned when its entry carries a label. A pinned edge states
its relation to the revised content of its cited item that the label
names. So `@cites packs#size-limit=v2` rests on the text of
`packs#size-limit` that has the label `v2`. An edge whose entry carries
`*`, such as `@cites packs=*`, is not pinned: it rests on the cited
item at each of its revisions. An edge whose cited item is an external
item is not pinned.

### 2.9 Edges

An edge is a relation of one kind from a source to a cited item. Each
entry of a citation states one edge. The kind of the edge is the
citation word without its `@`. The cited item of the edge is the item
that the entry names. An inline citation, such as
`[the limit](sinter:packs#size-limit=v2)`, states one edge of the kind
`cites`. The source of an edge is the declared item, the test, or the
site to which its citation or its inline citation belongs.

| edge | its source | its cited item | what it states |
|---|---|---|---|
| `cites` | a declared item or a site | a declared item or an external item | the source refers to the cited item and rests on what the cited item says |
| `satisfies` | a declared item or a site | a requirement | the source does what the requirement states |
| `verifies` | a test | a requirement, a conformance vector, a group, or a vector set | the test checks that the code it runs meets the requirement, or gives the result and the values of each vector of the selection |
| `refines` | a requirement, a specification, or a design | a requirement, a specification, or a design | the source states all or part of the cited item in more detail |
| `supersedes` | a declared item | a declared item of the same kind | the source replaces the cited item |

No edge has a task or a plan as its cited item. Work points at text in
the other direction: a task promises requirements, and a plan carries
out requirements, specifications, and designs.

A `supersedes` edge from a design whose entry is an every-part target,
such as `@supersedes docs=v3#*` in the tag lines of a design `media`,
states two things. The design `media` replaces the design `docs`, which
the label `v3` pins. And each specification and each requirement
`docs#x` is replaced by the specification or the requirement `media#x`
of the same kind, when `media` holds one.

### 2.10 Tasks and plans

A task is a work item for one piece of work that one person or one
agent can finish alone. A plan is a work item that says how a set of
tasks gets done. Each work item has an id, which never changes, and a
display name, which can change.

A task has:

- its paths: the paths of the files of the repository that its work can
  change; the work of a task with no paths can change no file;
- its promises: each a pair of an edge kind, `satisfies` or `verifies`,
  and a requirement, such as `verifies ledger#id-form`, which states that
  the work of the task puts into the tree of the default branch an edge
  of that kind, from a source inside the paths of the task, to that
  requirement;
- at most one external item, such as an issue, which can say what the
  work is; several tasks can name one external item, and a task that
  names one can have an empty display name;
- at most one plan, to which it belongs;
- its waits.

A task has no description of its own: the design that it carries out,
or its external item, says what to build. A task belongs to no branch.

A plan has a plan to which it belongs, when it belongs to one, its
waits, and the requirements, specifications, and designs that it
carries out. The parts of a plan are the tasks and the plans that
belong to it. A task belongs to at most one plan, and a plan belongs to
at most one other plan. A work item is under a plan when it is a part
of the plan, or under a part of the plan. No person approves a plan.

A wait goes from a work item, the waiting item, to another work item.
The work of the waiting item starts only after the other work item is
done. A wait of a plan applies to each task under the plan too. What a
plan carries out gives context to the work under it, and it changes
the state of no work item.

The definition of a task is its display name, its paths, its promises,
its external item, its plan, and its waits. The definition of a plan is
its display name, its plan, its waits, and what it carries out. The id
is not part of the definition. Each change of a definition is a new
definition, which a new entry records.

A commit states its link to a task in a line of its message:

- A delivery line, such as `Delivers: t-3f2a9c1d7e0b 05ef56`, states
  that the commit completes the work of the task. It names the task by
  its id, and the paths and the promises of one definition of the task
  by the start of a hash of them. The commit whose message holds the
  line is its finishing commit. A delivery of the task is the arrival
  of that commit on the default branch.
- A task line, such as `Task: t-3f2a9c1d7e0b`, states that the commit
  does part of the work of the task, without finishing it.

The tasks of a change are the tasks that its delivery lines and its
task lines name.

### 2.11 The ledger

The ledger of a repository is the sequence of its entries, in the
order in which writers appended them. Writers only append: no write
changes an entry or removes one. Of two entries, the one that was
appended later comes later in the ledger, whatever times the entries
record.

An entry records one fact: one event, such as one approval that a
person gave, or one observation of the job. No entry records a state.
Each entry also records who wrote it, and the branch from which it was
written, when there was one. Entries fall into four classes:

| class | kinds of entry | what an entry records | who writes it |
|---|---|---|---|
| definition entries | `task`, `plan` | one whole definition of one work item | a person or an agent |
| judgments | `approval`, `decline`, `done`, `abandoned` | a decision of a person about a subject of approval, a task, or a plan | a person only |
| records of the job | `delivered` | what the job observed about one delivery line | the job only |
| voids | `void` | that a person dropped one earlier entry | a person only |

A definition entry records no judgment: it makes no task done,
abandons nothing, and approves or declines nothing. A definition entry
is accepted when it gives its work item the definition that it records.
A definition entry that is not accepted changes nothing. The current
definition of a work item is the definition that its latest accepted
definition entry records.

### 2.12 States

A state of an item is a named condition that the item is in at one
time. Each state follows from facts, and no entry records a state.

| state | of | meaning |
|---|---|---|
| in force | a declared item | the item applies: its authors stand behind it, and no other declared item replaces it |
| retired | a declared item | the item is not in force |
| deprecated | a requirement, a specification, a design, or a decision record | a `@deprecated` status tag of the item states that it no longer applies and that nothing replaces it |
| rejected | a decision record | a `@rejected` status tag of the record states that its choice was considered and not made; the record stays |
| deferred | a decision record | a `@deferred` status tag of the record states that its choice is not made yet; its text says what would settle it |
| approved | a subject of approval | a person approved its revised content in the tree, and no later decline ended that approval |
| declined | a subject of approval | a person declined its revised content in the tree, and no later approval ended that decline |
| suspect | a pinned edge | the label that the edge pins is not the current revision of its cited item |
| open | a task | the task is defined, and no delivery and no judgment has ended that state yet |
| delivered | a task | a delivery of the task reached the default branch, and the facts that the job observed at it do not show the work finished; a person looks at the task |
| done | a task | the work of the task is finished, by the facts that the job observed at a delivery of it, or by a `done` entry |
| abandoned | a task | a person ended the task without finishing its work |
| done | a plan | the plan has at least one part, and every part of it is done |
| abandoned | a plan | a person ended the plan |
| open | a plan | the plan is neither done nor abandoned |
| accounted for | a requirement | work for the requirement is under way, or was finished at its current revision |

A deprecated, a rejected, or a deferred declared item is retired. A
subject of approval is a unit that a person approves or declines as a
whole: the own text of a design, a specification with its
requirements, a requirement that a design holds directly, or a
decision record. A requirement that a specification holds is approved
when that specification is approved. A design is approved when its
own text, each of its specifications, and each requirement that it
holds directly are approved.

A task is unfinished while it is open or delivered. The states done and
abandoned of a task are final: the task keeps the state, and more work
on it is a new task. The state abandoned of a plan is final too. The
state done of a plan is not final: a done plan is open again while it
has a part that is not done. The state of a task records work that
happened, and it does not state that the code stays correct.

A requirement is accounted for when one of these is true:

- an unfinished task promises it;
- an open plan carries out the requirement, its specification, or its
  design;
- a done task promised it, and its current revision is the revision
  that it had when that task became done.

### 2.13 Statements of agents

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, an entry of the ledger,
or a message to a person. A statement of an agent changes a state in
one of two ways only:

1. as a line of a change that names what it is about by a hash, a
   revision, or an id, such as a line of the diff, a delivery line, or
   a task line;
2. as a definition entry, which names work and records no judgment.

The person who merges a change can see both: the lines in the change
itself, and, in the summary of the change, every definition entry of
the tasks of the change and every definition entry that was written
from its branch. A statement that exists only outside these, such as a
message of an agent that its work is done, changes no state.

A session is one run of an agent on its work. The agent can declare a
task as the work of its session. The declared task changes no state.
Sinter uses it only to narrow the brief of the session: the text that
Sinter gives the agent about its work.

## 3. Requirements

### 3.1 Items

@req items=v1

An item is a thing that Sinter traces. Each item has exactly one kind.
The kinds of item are these thirteen: design, specification,
requirement, decision record, finding class, conformance vector, group,
vector set, task, plan, test, site, and external item.

### 3.2 Repositories

@req repositories=v1

A repository is a git repository. A commit, the message of a commit,
and a branch are those of git. The tree of a commit is the set of the
files of the repository, with their contents, at that commit. The
default branch of a repository is the branch into which work on the
repository merges. A push to a branch brings commits to that branch.

### 3.3 People

@req people=v1
@cites #{repositories=v1}

A person is a human who works on a repository.

### 3.4 Agents

@req agents=v1
@cites #{people=v1}

An agent is a program that writes code for a person with a language
model, such as a coding agent. Each agent acts for one person: the
person who runs it.

### 3.5 The job

@req job=v1
@cites #{repositories=v1, tests=v1}

The job is the run of Sinter that continuous integration starts at each
push to the default branch of a repository. Continuous integration is a
service that runs checks on the commits of a repository. The job reads
the commits that the push brings to the default branch, and it observes
facts that exist only during its run, such as the test evidence of its
run.

### 3.6 Actors

@req actors=v1
@cites #{people=v1, agents=v1, job=v1}

An actor is a person, an agent, or the job.

### 3.7 Declared items

@req declared-items=v1
@cites {identifiers#{tag-words=v1}, #{items=v1, repositories=v1}}

A declared item is an item that a declaration declares. The declaration
word of the declaration gives the kind of the item: `@design` gives a
design, `@spec` a specification, `@req` a requirement, `@decision` a
decision record, and `@finding-class` a finding class. The text of a
declared item is the part of the files of a tree that the item consists
of, its declaration included.

### 3.8 Containment

@req containment=v1
@cites #{declared-items=v1}

Containment is a relation in which one declared item holds another, and
the other belongs to it. Each specification belongs to exactly one
design, which holds it. Each requirement belongs to exactly one design,
which holds it, and to at most one specification of that design, which
holds it too. A design holds a requirement directly when the
requirement belongs to no specification. No other declared item holds a
declared item, and no design holds a design.

### 3.9 Designs

@req designs=v1
@cites {text#{conforming-programs=v1}, #{declared-items=v1, containment=v1}}

A design is a declared item that specifies one part of a system: it is
the document that holds the requirements of that part. The own text of
a design is the part of the text of the design that none of its
specifications and none of its requirements holds.

### 3.10 Specifications

@req specifications=v1
@cites #{declared-items=v1, containment=v1, designs=v1}

A specification is a declared item that specifies one thing of the part
of a system that its design specifies, such as a format, a protocol, or
a set of behaviors. The text of a specification holds the text of each
of its requirements.

### 3.11 Requirements

@req requirements=v1
@cites {text#{conforming-programs=v1}, #{declared-items=v1, containment=v1}}

A requirement is a declared item that states one definition, or one
obligation of a conforming program.

### 3.12 Normative text

@req normative-text=v1
@cites {
    text#{conforming-programs=v1},
    #{designs=v1, specifications=v1, requirements=v1},
}

The text of each requirement is normative: it states what a conforming
program is or does. The rest of the text of a design and of each of its
specifications is not normative: it explains the requirements and gives
examples.

### 3.13 Decision records

@req decision-records=v1
@cites #{declared-items=v1}

A decision record is a declared item that records one standing practice
of a project, or one choice with its reason.

### 3.14 Finding classes

@req finding-classes=v1
@cites {identifiers#{segments=v1}, #{declared-items=v1, repositories=v1}}

A finding is a report of one condition at one place of a repository. A
finding class is a kind of finding, and a slug names it. A finding
class that a repository declares for itself is a declared item. Its
text is its finding-class file: a file of the repository that holds
that one finding class.

### 3.15 Names

@req names=v1
@cites {
    identifiers#{segments=v1},
    #{
        declared-items=v1, containment=v1, designs=v1, specifications=v1,
        requirements=v1, decision-records=v1, finding-classes=v1,
        repositories=v1,
    },
}

The name of a design, of a decision record, and of a finding class is a
slug. The name of a specification and of a requirement is a full name:
the slug of its design, `#`, and its part name. Designs and decision
records share one set of slugs. Finding classes have a set of slugs of
their own. The specifications and the requirements of one design share
one set of part names. In one tree, each name of one of these sets
names at most one item.

### 3.16 Marks

@req extern-marks=v1
@cites {
    identifiers#{tag-words=v1, extern-grammar=v1, kind-words=v1, segments=v1},
    #{designs=v1, specifications=v1, requirements=v1, containment=v1},
}

A mark is what an `@extern` line in the own text of a design states:
the design holds a specification or a requirement whose declaration
stands outside the file that holds the declaration of the design. The
kind word of the line states the kind of that item, and the part name
of the line is the part name of that item. A mark is part of the own
text of its design.

### 3.17 Conformance vectors

@req conformance-vectors=v1
@cites {
    text#{conforming-programs=v1, inputs=v1, results=v1, texts=v1},
    #{items=v1, normative-text=v1},
}

A conformance vector is an item that holds one input of a conforming
program, the result that a conforming program gives for that input, and
the values that it gives together with that result. A value is a text
or a fact that a conforming program gives together with a result. A
conformance vector is not normative: its result and its values follow
from requirements.

### 3.18 Vector sets

@req vector-sets=v1
@cites {
    text#{whole-numbers=v1},
    #{
        conformance-vectors=v1, specifications=v1, designs=v1,
        containment=v1,
    },
}

The vector set of a specification is the set of its conformance
vectors. The vector set of a design is the set of the conformance
vectors that the design gives for the requirements that it holds
directly. Each conformance vector belongs to exactly one vector set.
Each conformance vector has a number: a whole number that names it in
its vector set. No two conformance vectors of one vector set have the
same number, and a number that one vector of a vector set had never
names another vector of that vector set.

### 3.19 Groups

@req groups=v1
@cites #{items=v1, vector-sets=v1, conformance-vectors=v1}

A group is an item: a named part of a vector set. Each conformance
vector belongs to exactly one group of its vector set. No two groups of
one vector set have the same name.

### 3.20 Selections

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

### 3.21 Tests

@req tests=v1
@cites #{items=v1, repositories=v1}

A test is an item: a unit of code that a test framework runs and
reports with a result, such as a test function, or a group of such
units, such as the tests of one `describe` block. The code of a tree
names each test, and no declaration declares one. The test evidence of
a tree is the set of the results that the runs of the tests of that
tree reported: which tests ran, and which of them passed or failed.

### 3.22 Sites

@req sites=v1
@cites #{items=v1, declared-items=v1, tests=v1, repositories=v1}

A site is an item with no name: a block of text in a file of a tree,
such as a comment in code or a section of a markdown file, that holds
citations and that is neither a declared item nor a test.

### 3.23 External items

@req external-items=v1
@cites {identifiers#{external-ids=v1, segments=v1}, #{items=v1, repositories=v1}}

An external item is an item outside the repository that an external id
names, such as an issue or a published standard. An external id with
`#` and a part name names a part of such an item, and that part is an
external item too. An external item can be a specification: a published standard, or a part of one, that
specifies a thing. An external item can be a term: a word or a fixed
phrase to which a published document gives one meaning.

### 3.24 Stated kinds

@req stated-kinds=v1
@cites {
    identifiers#{kind-words=v1, entries=v1, destinations=v1},
    #{
        designs=v1, specifications=v1, requirements=v1,
        decision-records=v1, finding-classes=v1, external-items=v1,
    },
}

A kind word at the start of an entry of a citation, or at the start of
the target of an inline citation, states what the entry or the target
names. `design` states a design. `spec` states a specification, or an
external item that is a specification. `req` states a requirement.
`decision` states a decision record. `finding-class` states a finding
class. `term` states an external item that is a term.

### 3.25 Revised content

@req revised-content=v1
@cites #{
    items=v1, declared-items=v1, designs=v1, specifications=v1,
    requirements=v1, decision-records=v1, finding-classes=v1,
    conformance-vectors=v1, vector-sets=v1, groups=v1,
}

The revised content of an item is the part of the item that its
revision covers:

- of a design, its own text;
- of a specification, its text, without the labels of the declarations
  of its requirements;
- of a requirement, of a decision record, and of a finding class, its
  text;
- of a conformance vector, all that the vector holds, other than its
  number and its revision;
- of a group, the conformance vectors that belong to it, with the
  revised content of each;
- of a vector set, its conformance vectors, with the revised content of
  each.

A task, a plan, a test, a site, and an external item have no revised
content.

### 3.26 Revisions of items

@req item-revisions=v1
@cites {
    identifiers#{revisions=v1, tag-words=v1},
    #{items=v1, revised-content=v1, declared-items=v1, repositories=v1},
}

A revision of an item is a label that names one revised content of
that item. The current revision of an item in a tree is the label that
names the revised content of the item in that tree. The current
revision of a declared item in a tree is the label of its declaration
in that tree. An item with no revised content has no revision.

### 3.27 Edges

@req edges=v1
@cites {
    identifiers#{tag-words=v1, entries=v1, destinations=v1},
    #{items=v1, declared-items=v1, tests=v1, sites=v1},
}

An edge is a relation of one kind from an item, its source, to an item,
its cited item. Each entry of a citation states one edge. The kind of
the edge is the citation word of the citation without its `@`, and the
cited item of the edge is the item that the entry names. An inline
citation states one edge of the kind `cites`, whose cited item is the
item that the target of the inline citation names. The source of an
edge is the declared item, the test, or the site to which its citation
or its inline citation belongs. The kinds of edge are these five:
`cites`, `satisfies`, `verifies`, `refines`, and `supersedes`. No edge
has a task or a plan as its cited item.

### 3.28 Pins

@req pins=v1
@cites {
    identifiers#{revisions=v1, entries=v1, destinations=v1},
    #{edges=v1, item-revisions=v1, revised-content=v1, external-items=v1},
}

An edge is pinned when its entry, or the target of its inline citation,
carries a label. A pinned edge states its relation to the revised
content of its cited item that its label names. An edge whose entry or
target carries `*` is not pinned: it states its relation to the cited
item at each revision of the cited item. An edge whose cited item is an
external item is not pinned.

### 3.29 Edges of the kind `cites`

@req cites-edges=v1
@cites #{edges=v1, declared-items=v1, sites=v1, external-items=v1}

A `cites` edge states that its source refers to its cited item and
rests on what the cited item says. The source of a `cites` edge is a
declared item or a site. Its cited item is a declared item or an
external item.

### 3.30 Edges of the kind `satisfies`

@req satisfies-edges=v1
@cites #{edges=v1, declared-items=v1, sites=v1, requirements=v1}

A `satisfies` edge states that its source does what its cited item
states. The source of a `satisfies` edge is a declared item or a site.
Its cited item is a requirement.

### 3.31 Edges of the kind `verifies`

@req verifies-edges=v1
@cites #{
    edges=v1, tests=v1, requirements=v1, conformance-vectors=v1,
    groups=v1, vector-sets=v1, vector-selections=v1,
}

A `verifies` edge states that its source checks the code that the
source runs. The source of a `verifies` edge is a test. Its cited item
is a requirement, a conformance vector, a group, or a vector set. When
its cited item is a requirement, the edge states that the test checks
that the code meets that requirement. Otherwise the edge states that
the test checks that the code gives, for the input of each conformance
vector of the selection of the entry of the edge, the result and the
values of that vector.

### 3.32 Edges of the kind `refines`

@req refines-edges=v1
@cites #{edges=v1, requirements=v1, specifications=v1, designs=v1}

A `refines` edge states that its source states all or part of its
cited item in more detail. The source of a `refines` edge is a
requirement, a specification, or a design, and so is its cited item.

### 3.33 Edges of the kind `supersedes`

@req supersedes-edges=v1
@cites {
    identifiers#{citation-grammar=v1, segments=v1},
    #{
        edges=v1, declared-items=v1, designs=v1, specifications=v1,
        requirements=v1, containment=v1, names=v1,
    },
}

A `supersedes` edge states that its source replaces its cited item. The
source of a `supersedes` edge is a declared item, and its cited item is
a declared item of the same kind. When the entry of a `supersedes` edge
is an every-part target, its source and its cited item are designs, and
the edge also states this: each specification and each requirement of
the cited design is replaced by the specification or the requirement of
the source design that has the same kind and the same part name, when
the source design holds one.

### 3.34 Acks

@req acks=v1
@cites {
    identifiers#{tag-words=v1, ack-grammar=v1, give-values=v1, segments=v1},
    #{finding-classes=v1, people=v1, agents=v1},
}

An ack is what an `@ack` line states: a person or an agent accepts one
finding. The finding is of the finding class whose name is the slug of
the line, and it is about what the subject of the line states. The
person or the agent accepts it for one text: the text whose hash starts
with the hash prefix of the line.

### 3.35 Work items

@req work-items=v1
@cites #{items=v1, repositories=v1}

A work item is a task or a plan. No file of a tree holds a work item.
Each work item has an id, which never changes, and a display name,
which can change.

### 3.36 Tasks

@req tasks=v1
@cites #{
    work-items=v1, repositories=v1, external-items=v1, people=v1,
    agents=v1,
}

A task is a work item for one piece of work that one person or one
agent can finish alone. The paths of a task are the paths of the files
of the repository that the work of the task can change; the work of a
task with no paths can change no file. A task names at most one
external item, which can say what the work is, and several tasks can
name one external item. A task that names an external item can have
an empty display name. A task has no description of its own. A task
belongs to no branch.

### 3.37 Promises

@req promises=v1
@cites #{
    tasks=v1, edges=v1, requirements=v1, repositories=v1,
    satisfies-edges=v1, verifies-edges=v1,
}

A promise of a task is a pair of an edge kind, `satisfies` or
`verifies`, and a requirement. It states that the work of the task puts
into the tree of the default branch an edge of that kind, from a source
inside the paths of the task, whose cited item is that requirement.

### 3.38 Plans

@req plans=v1
@cites #{work-items=v1, tasks=v1}

A plan is a work item that says how a set of tasks gets done. The parts
of a plan are the tasks and the plans that belong to it. A task belongs
to at most one plan, and a plan belongs to at most one other plan. A
work item is under a plan when it is a part of the plan, or under a
part of the plan.

### 3.39 Waits

@req waits=v1
@cites #{work-items=v1, tasks=v1, plans=v1, task-states=v1, plan-states=v1}

A wait is a relation from a work item, the waiting item, to another
work item: the work of the waiting item starts only after the other
work item is done. A wait is met when the work item that it waits for
is done. A wait of a plan applies to each task under the plan too.

### 3.40 What a plan carries out

@req carried-out-items=v1
@cites #{
    plans=v1, requirements=v1, specifications=v1, designs=v1,
    states=v1,
}

A plan carries out a set of requirements, specifications, and designs:
its work is for them. What a plan carries out gives context to the work
under it, and it changes the state of no work item.

### 3.41 Definitions of work items

@req definitions-of-work-items=v1
@cites #{
    work-items=v1, tasks=v1, promises=v1, plans=v1, waits=v1,
    carried-out-items=v1, external-items=v1,
}

The definition of a task is its display name, its paths, its promises,
its external item, the plan to which it belongs, and its waits. The
definition of a plan is its display name, the plan to which it belongs,
its waits, and what it carries out. The id of a work item is not part
of its definition.

### 3.42 Changes

@req changes=v1
@cites #{repositories=v1, people=v1}

A change is a set of commits on a branch, the branch of the change,
that a person merges into the default branch as one unit, such as the
commits of a pull request. The person who merges a change is the
person who brings its commits to the default branch. The diff of a
change is the set of the lines that its commits add to the tree and
the lines that they remove from it. The lines of a change are the lines
of its diff and the lines of the messages of its commits.

### 3.43 Delivery lines

@req delivery-lines=v1
@cites #{
    repositories=v1, tasks=v1, promises=v1,
    definitions-of-work-items=v1,
}

A delivery line is a line of the message of a commit that states that
the commit completes the work of one task. It names the task by its id,
and the paths and the promises of one definition of the task by a hash
of them. The finishing commit of a delivery line is the commit whose
message holds the line. A delivery of a task is the arrival of the
finishing commit of a delivery line of the task on the default branch.

### 3.44 Task lines

@req task-lines=v1
@cites #{repositories=v1, tasks=v1, changes=v1, delivery-lines=v1}

A task line is a line of the message of a commit that names one task by
its id, and that states that the commit does part of the work of the
task without finishing it. The tasks of a change are the tasks that the
delivery lines and the task lines of the change name.

### 3.45 Entries

@req entries=v1
@cites #{people=v1, agents=v1, job=v1, repositories=v1}

An entry is a record of one fact: one event, such as an approval that a
person gave, or an observation of the job. Each entry also records who
wrote it, and the branch from which it was written, when there was one.

### 3.46 The ledger

@req ledger=v1
@cites #{repositories=v1, entries=v1}

The ledger of a repository is the sequence of the entries that writers
appended to it, in the order in which they appended them. Writers only
append entries to the ledger: no write changes an entry or removes one.
Of two entries, the one that was appended later comes later in the
ledger, whatever times the entries record.

### 3.47 Definition entries

@req definition-entries=v1
@cites #{
    entries=v1, ledger=v1, work-items=v1, definitions-of-work-items=v1,
    people=v1, agents=v1, judgments=v1,
}

A definition entry is an entry that records one whole definition of one
work item: a `task` entry records a definition of a task, and a `plan`
entry records a definition of a plan. A person or an agent writes a
definition entry. A definition entry records no judgment.

### 3.48 Current definitions

@req current-definitions=v1
@cites #{definition-entries=v1, ledger=v1, work-items=v1}

A definition entry is accepted when it gives its work item the
definition that it records. A definition entry that is not accepted
changes nothing. The current definition of a work item is the
definition that its latest accepted definition entry records. A work
item exists from its first accepted definition entry.

### 3.49 Subjects of approval

@req subjects-of-approval=v1
@cites #{
    designs=v1, specifications=v1, requirements=v1,
    decision-records=v1, containment=v1, revised-content=v1,
}

A subject of approval is a unit that a person approves or declines as a
whole. The subjects of approval are these four: the own text of a
design; a specification, with its requirements; a requirement that a
design holds directly; and a decision record. The revised content of
the own text of a design is that own text. The revised content of each
other subject of approval is the revised content of its specification,
its requirement, or its decision record.

### 3.50 Judgments

@req judgments=v1
@cites #{
    entries=v1, ledger=v1, people=v1, subjects-of-approval=v1, tasks=v1,
    plans=v1, revised-content=v1, work-items=v1,
}

A judgment is an entry that records a decision of a person. Only a
person makes a judgment. The kinds of judgment are these four:

- an `approval` entry records that a person approved one revised
  content of one subject of approval;
- a `decline` entry records that a person declined one revised content
  of one subject of approval;
- a `done` entry records that a person judged the work of a task
  finished;
- an `abandoned` entry records that a person ended a task or a plan
  without finishing its work, and the reason.

### 3.51 Records of the job

@req job-records=v1
@cites #{
    entries=v1, job=v1, delivery-lines=v1, promises=v1, tests=v1,
    repositories=v1,
}

A record of the job is an entry that records what the job observed.
Only the job writes a record of the job. A `delivered` entry is a
record of the job. It records that the job read one delivery line in
the commits that a push brought to the default branch, and it records
what the job observed about each promise of the task of that line, in
the tree of that push and with the test evidence of its run.

### 3.52 Voids

@req voids=v1
@cites #{entries=v1, ledger=v1, people=v1}

A void is an entry that records that a person dropped one earlier entry
of the ledger. Only a person writes a void. An entry that a void drops
records no fact.

### 3.53 States

@req states=v1
@cites #{items=v1, entries=v1}

A state of an item is a named condition that the item is in at one
time, such as in force or done. Each state follows from facts. No entry
records a state.

### 3.54 In force

@req in-force-items=v1
@cites #{declared-items=v1, states=v1, supersedes-edges=v1}

A declared item is in force when it applies: its authors stand behind
it, and no other declared item replaces it.

### 3.55 Retired

@req retired-items=v1
@cites #{
    declared-items=v1, states=v1, in-force-items=v1,
    deprecated-items=v1, rejected-records=v1, deferred-records=v1,
}

A declared item is retired when it is not in force. A deprecated, a
rejected, or a deferred declared item is retired.

### 3.56 Deprecated

@req deprecated-items=v1
@cites {
    identifiers#{tag-words=v1},
    #{
        declared-items=v1, states=v1, requirements=v1, specifications=v1,
        designs=v1, decision-records=v1,
    },
}

A declared item is deprecated when a `@deprecated` status tag of the
item states so: the item no longer applies, and nothing replaces it. A
requirement, a specification, a design, and a decision record can be
deprecated.

### 3.57 Rejected

@req rejected-records=v1
@cites {identifiers#{tag-words=v1}, #{decision-records=v1, states=v1}}

A decision record is rejected when a `@rejected` status tag of the
record states so: its choice was considered and not made, and the
record stays. Only a decision record can be rejected.

### 3.58 Deferred

@req deferred-records=v1
@cites {identifiers#{tag-words=v1}, #{decision-records=v1, states=v1}}

A decision record is deferred when a `@deferred` status tag of the
record states so: its choice is not made yet, and its text says what
would settle it. Only a decision record can be deferred.

### 3.59 Approved

@req approved-items=v1
@cites #{
    subjects-of-approval=v1, states=v1, revised-content=v1,
    specifications=v1, requirements=v1, designs=v1, containment=v1,
    judgments=v1, repositories=v1,
}

A subject of approval is approved in a tree when a person approved its
revised content in that tree, and no later decline of that revised
content ended that approval. A requirement that a specification holds
is approved in a tree when that specification is approved in that tree.
A design is approved in a tree when its own text, each of its
specifications, and each requirement that it holds directly are
approved in that tree.

### 3.60 Declined

@req declined-subjects=v1
@cites #{
    subjects-of-approval=v1, states=v1, revised-content=v1,
    judgments=v1, repositories=v1,
}

A subject of approval is declined in a tree when a person declined its
revised content in that tree, and no later approval of that revised
content ended that decline.

### 3.61 Suspect

@req suspect-edges=v1
@cites #{pins=v1, edges=v1, item-revisions=v1, states=v1, repositories=v1}

A pinned edge is suspect in a tree when the label that it pins is not
the current revision of its cited item in that tree: the cited item
changed after the edge pinned it, so the source may no longer agree
with it. An edge that is not pinned is never suspect.

### 3.62 The states of a task

@req task-states=v1
@cites #{
    tasks=v1, states=v1, delivery-lines=v1, judgments=v1, job=v1,
    people=v1, repositories=v1, current-definitions=v1,
}

The state of a task is one of these four:

- open: the task has a current definition, and no delivery of it and
  no judgment has ended that state yet;
- delivered: a delivery of the task reached the default branch, and the
  facts that the job observed at it do not show the work of the task
  finished, so a person looks at the task;
- done: the work of the task is finished, by the facts that the job
  observed at a delivery of it, or by a `done` entry;
- abandoned: a person ended the task by an `abandoned` entry, without
  finishing its work.

A task is unfinished while it is open or delivered. The states done and
abandoned of a task are final: a task in one of them keeps it, and more
work on the task is a new task. The state of a task records work that
happened, and it does not state that the code stays correct.

### 3.63 The states of a plan

@req plan-states=v1
@cites #{plans=v1, states=v1, task-states=v1, judgments=v1}

The state of a plan is one of these three:

- done: the plan has at least one part, and every part of it is done;
- abandoned: a person ended the plan by an `abandoned` entry;
- open: the plan is neither done nor abandoned.

The state abandoned of a plan is final: an abandoned plan keeps it. The
state done of a plan is not final: a done plan is open again while it
has a part that is not done.

### 3.64 Requirements accounted for

@req requirements-accounted-for=v1
@cites #{
    requirements=v1, states=v1, task-states=v1, plan-states=v1,
    promises=v1, carried-out-items=v1, item-revisions=v1,
    containment=v1, tasks=v1, plans=v1,
}

A requirement is accounted for when work for it is under way, or was
finished at its current revision. That is so when one of these is
true:

- an unfinished task promises it;
- an open plan carries out the requirement, its specification, or its
  design;
- a done task promised it, and its current revision is the revision
  that it had when that task became done.

### 3.65 Statements of agents

@req agent-statements=v1
@cites #{agents=v1, repositories=v1, entries=v1, ledger=v1, people=v1}

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, an entry of the ledger,
or a message to a person.

### 3.66 The states that statements of agents change

@req limit-agent-statements=v1
@cites #{
    agent-statements=v1, states=v1, changes=v1, definition-entries=v1,
    judgments=v1, work-items=v1,
}

A conforming program must change no state for a statement of an agent,
unless the statement is one of these:

1. a line of a change that names what it is about by a hash, a
   revision, or an id;
2. a definition entry, which names work and records no judgment.

So a statement of an agent that exists only outside these, such as a
message of an agent that its work is done, changes no state.

### 3.67 The summary of a change

@req show-change-definitions=v1
@cites #{changes=v1, task-lines=v1, definition-entries=v1, entries=v1}

For each change, a conforming program must give the person who merges
the change a summary of the change that shows every definition entry of
each task of the change and every definition entry that was written
from the branch of the change.

### 3.68 Declared tasks

@req declared-tasks=v1
@cites #{agents=v1, tasks=v1}

A session of an agent is one run of the agent on its work. The declared
task of a session is the task that the agent declares as the work of
that session. The brief of a session is the text about its work that
Sinter gives the agent for that session.

### 3.69 The use of declared tasks

@req limit-declared-tasks=v1
@cites #{declared-tasks=v1, states=v1}

A conforming program must use the declared task of a session only to
narrow the brief of that session.

## 4. Conformance

A program conforms to the design when it meets every requirement of
section 3. A program meets a requirement in one of two ways, by what
the requirement states:

- a definition: each item, relation, entry, and state that the program
  reads, records, or reports under the term that the requirement
  defines has the meaning that the requirement gives it;
- an obligation: the program does what the obligation states.

No requirement of section 3 gives a result for an input, so the design
has no conformance vectors.
