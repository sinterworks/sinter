<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
Specifies the kinds of items that Sinter traces, with their names, texts, revisions, and edges, and the conditions of a valid tree; work items, changes, the ledger, and the actors that write it; the names and meanings of states; and requirements for conforming programs that limit the use of statements of agents and of declared tasks, and that show the definition entries of each change.

Sinter traces the items of a repository: designs with their
specifications, requirements, and terms, decision records, tests, tasks
and plans, and the items outside the repository that external ids name.
A citation, such as `@verifies packs#size-limit=v2` in a comment on a
test, states an edge: a relation from its source, here the test, to its
cited item, here the requirement `packs#size-limit` with the text that
the label `v2` names. The ledger of a repository records events, such
as the approval that a person gave to one text. Each state, such as in
force, approved, suspect, or done, follows from the trees and the
messages of the commits of the repository, from its ledger entries, and
from test evidence.

From Identifiers, the design takes the tag words and the kind words;
names, labels, and revisions; external ids; the citation entries
and the every-part target; the forms of the `@ack` and `@extern` lines;
and inline citations. From Text and notation, it takes texts, lines,
and whole numbers, and what a design, a requirement, a conforming
program, an input, and a result are.

## 1. Glossary

| term | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that a project made |
| [item](sinter:#item=v1) | a thing that Sinter traces, such as a requirement, a test, or a task |
| [kind of item](sinter:#item=v1) | one of the fourteen sorts of item, such as design or task; each item has one |
| repository | a git repository |
| commit, message of a commit, branch, file, path, working tree, clone, push, squash commit | the thing of git that has this name |
| [tree](sinter:#tree=v1) | the set of the files of a repository, with their contents, at one commit or in one working tree |
| [default branch](sinter:#default-branch=v1) | the branch into which work on a repository merges |
| actor | a person, an agent, or the job |
| [person](sinter:#person=v1) | a human who works on a repository |
| [agent](sinter:#agent=v1) | a program that uses a language model to write texts for a person, such as code |
| [continuous integration](sinter:#job=v1) | a service that runs checks on the commits of a repository |
| [job](sinter:#job=v1) | the execution of a conforming program, such as Sinter, that continuous integration starts at each push to the default branch |
| [declared item](sinter:#declared-item=v1) | an item that a declaration declares: a design, a specification, a requirement, a term, a decision record, or a declared finding class |
| [text of a declared item](sinter:#item-text=v1) | the part of the files of a tree that a declared item takes up, its declaration included |
| [containment](sinter:#containment=v1) | the relation in which a design holds specifications, requirements, and terms, and a specification holds requirements and terms |
| [hold](sinter:#containment=v1), [belong to](sinter:#containment=v1) | a design holds each of its specifications, requirements, and terms, and each of them belongs to the design; a specification holds its requirements and its terms in the same way |
| [hold directly](sinter:#containment=v1) | a design holds a requirement or a term directly when the requirement or the term belongs to the design and to no specification |
| [design](sinter:text#design=v1) | a declared item that specifies one part of a system: a document that declares, each under a name, obligations and the definitions that these obligations use |
| [own text](sinter:#own-text=v1) | the part of the text of a design that is in the text of none of its specifications, requirements, and terms |
| [specification](sinter:#specification=v1) | a declared item that specifies one thing of the part of a system that its design specifies, such as a format |
| [requirement](sinter:text#requirement=v1) | a declared item that states, with the word must, one obligation of each conforming program of its design |
| [term](sinter:#term=v1) | a declared item that states the meaning of one word or one fixed phrase, and states no obligation |
| normative | stating what a word or a fixed phrase means, or what a conforming program must do; only the texts of terms and of requirements are normative |
| [decision record](sinter:#decision-record=v1) | a declared item that records one standing practice of a project, or one choice with its reason |
| [finding](sinter:#declared-finding-class=v1) | a report of one condition about one part of a repository |
| [finding class](sinter:#declared-finding-class=v1) | the sort of condition that a finding reports, which a slug names |
| [declared finding class](sinter:#declared-finding-class=v1) | a finding class that a repository declares for itself; it is a declared item |
| [finding-class file](sinter:#declared-finding-class=v1) | the file whose whole text is the text of one declared finding class |
| [file of a design](sinter:#mark=v1) | the file in which the declaration of a design stands |
| [mark](sinter:#mark=v1) | what an `@extern` line in the own text of a design states: the design holds an item of the kind that the kind word of the line states, with the part name of the line, whose declaration is in another file |
| [value](sinter:identifiers#value=v1) | a text or a fact that a conforming program gives together with a result |
| [conformance vector](sinter:#conformance-vector=v1) | an item that has one input of a conforming program of a design, the result that the program gives for it, and the values that it gives with that result |
| [vector set](sinter:#vector-set=v1) | the conformance vectors of one specification, or of one design for the requirements that it holds directly |
| [number of a vector](sinter:#vector-set=v1) | the whole number of 0 or more that names a conformance vector in its vector set |
| [group](sinter:#group=v1) | a named set of the conformance vectors of one vector set; each conformance vector is in one group |
| [selection](sinter:#selection=v1) | the set of conformance vectors that one citation entry names: one vector, every vector of a group, or every vector of a vector set |
| [test](sinter:#test=v1) | a unit of code that a test framework runs and reports as passed or failed, or a set of such units |
| [test evidence](sinter:#test-evidence=v1) | the reports that tests gave in one execution: which tests ran, and which of them passed or failed |
| [site](sinter:#site=v1) | an item with no name: a block of text with citations or inline citations in it, which is neither a declared item nor a test |
| [external item](sinter:#external-item=v1) | an item outside the repository that an external id names, such as an issue or a standard |
| [standard](sinter:#standard=v1) | an external item that is a published standard, or a part of one |
| hash | a short text that a fixed function computes from a text, so that two different texts almost never have the same hash |
| [revised content](sinter:#revised-content=v1) | the part of an item that a revision of the item names, such as the own text of a design |
| [revision of an item](sinter:#item-revision=v1) | a label that names one revised content of the item |
| [current revision](sinter:#item-revision=v1) | the label that names the revised content of an item in a given tree |
| [edge](sinter:#edge=v1) | a relation of one kind of edge from a source to a cited item, which a citation entry or the target of an inline citation states |
| [kind of edge](sinter:#edge=v1) | one of `cites`, `satisfies`, `verifies`, `refines`, and `supersedes` |
| [stand in](sinter:#edge-source=v1) | a citation stands in a declared item or a site when it is in its text, and in a test when it is in a comment on the code of the test |
| [source](sinter:#edge-source=v1) | the declared item, the test, or the site in which the citation or the inline citation of an edge stands |
| [cited item](sinter:#edge=v1) | the item that the citation entry or the target of an edge names |
| [pinned edge](sinter:#pinned-edge=v1) | an edge whose citation entry or target carries a label |
| [status tag of a declared item](sinter:#item-status-tag=v1) | a status tag that stands in the text of the declared item; each such status tag is a status tag of exactly one declared item |
| [ack](sinter:#ack=v1) | what an `@ack` line states: a person or an agent accepts one finding for one block of text |
| [valid edge](sinter:#valid-edge=v1) | an edge that has a cited item, whose kind word states what its cited item is, and whose source and cited item fit its kind of edge |
| [valid mark](sinter:#valid-mark=v1) | a mark whose kind word is `spec`, `req`, or `term`, for which the design holds such an item with the part name of the mark, directly for `req` and `term`, declared in another file |
| [valid status tag](sinter:#valid-status-tag=v1) | a status tag of a declared item whose status word fits the kind of item of that declared item |
| [valid tree](sinter:#valid-tree=v1) | a tree in which each edge, each mark, and each status tag is valid, each specification, requirement, and term belongs to exactly one design, each item that needs a mark has one, and each name names at most one declared item |
| [work item](sinter:#work-item=v1) | a task or a plan |
| [work item id](sinter:#work-item=v1) | the id of a work item, which never changes |
| [display name](sinter:#work-item=v1) | the name of a work item that a person reads, which can change |
| [task](sinter:#task=v1) | a work item for one piece of work that one person or one agent can finish alone |
| [paths of a task](sinter:#task=v1) | the set of the paths of the files that the work of a task can add, change, or remove |
| [promise](sinter:#promise=v1) | a pair of a kind of edge, `satisfies` or `verifies`, and a requirement, which states what the work of a task puts into the tree |
| [plan](sinter:#plan=v1) | a work item that says how a set of tasks gets done |
| [plan of a work item](sinter:#work-item-definition=v1) | the plan that the definition of a work item names |
| [part of a plan](sinter:#plan-state=v1) | a work item whose current definition names the plan as its plan, unless an abandonment ended that |
| [under a plan](sinter:#plan-state=v1) | a part of the plan, or under a part of the plan |
| [wait](sinter:#wait=v1) | a relation from a work item to another work item that it waits for |
| [carry out](sinter:#carried-out-item=v1) | a plan carries out the requirements, specifications, and designs that its work is for |
| [definition of a work item](sinter:#work-item-definition=v1) | what a definition entry records about a work item, such as the paths of a task |
| [current definition](sinter:#current-definition=v1) | the definition that the latest accepted definition entry of a work item records |
| [change](sinter:#change=v1) | a set of commits on a branch that a person merges into the default branch as one unit |
| [diff of a change](sinter:#change=v1) | the lines that differ between the tree where a change starts and the tree of its last commit |
| [lines of a change](sinter:#change=v1) | the lines of the diff of a change, and the lines of the messages of its commits |
| [delivery line](sinter:#delivery-line=v1) | a line of the message of a commit that states that the commit completes the work of a task |
| [finishing commit](sinter:#delivery-line=v1) | the commit in whose message a delivery line is |
| [delivery](sinter:#delivery-line=v1) | the arrival of the finishing commit of a delivery line on the default branch |
| [task line](sinter:#task-line=v1) | a line of the message of a commit that names a task on which the commit does part of the work |
| tasks of a change | the tasks that the delivery lines and the task lines of a change name |
| [ledger](sinter:#ledger=v1) | the sequence of the ledger entries of a repository, in the order in which they were appended |
| [ledger entry](sinter:#ledger-entry=v1) | a record of one event in the ledger, such as one approval |
| [point of the ledger](sinter:#ledger=v1) | a point between two ledger entries, before the first, or after the last |
| [provisional](sinter:#ledger=v1) | a ledger entry is provisional while a clone has it and has not pushed it yet |
| [repair](sinter:#repair=v1) | the one write to the ledger that is not an append: it removes ledger entries, and only a person makes one |
| [void](sinter:#repair=v1) | a ledger entry that stands where a ledger entry stood that a repair removed |
| [definition entry](sinter:#definition-entry=v1) | a ledger entry that records one definition of one work item |
| [accepted](sinter:#current-definition=v1) | a definition entry is accepted when it gives its work item the definition that it records |
| [judgment](sinter:#judgment=v1) | a ledger entry that records a decision of a person |
| [record of the job](sinter:#job-record=v1) | a ledger entry that records what the job observed |
| [state](sinter:#state=v1) | a named condition of an item, an edge, or a subject of approval at one time, such as in force or done |
| [retired](sinter:#retired-item=v1) | a declared item is retired when it has a status tag, when an effective `supersedes` edge has it as its cited item, or when it belongs to a retired design or a retired specification |
| [in force](sinter:#in-force-item=v1) | a declared item is in force when it is not retired |
| [effective](sinter:#effective-supersedes-edge=v1) | a `supersedes` edge is effective when its source is a declared item with no status tag, approved when the repository needs approval for its kind of item |
| [deprecated](sinter:#deprecated-item=v1), [rejected](sinter:#rejected-record=v1), [deferred](sinter:#deferred-record=v1) | the states that the three status words state |
| [subject of approval](sinter:#subject-of-approval=v1) | a unit that a person approves or declines as a whole |
| [approved](sinter:#approved-item=v1), [declined](sinter:#declined-item=v1) | the states of a subject of approval after a person approved or declined its revised content |
| [draft](sinter:#draft-design=v1) | a design is a draft while it is not approved |
| [suspect](sinter:#suspect-edge=v1) | a pinned edge is suspect when its label is not the current revision of its cited item |
| [open, delivered, done, abandoned](sinter:#task-state=v1) | the four states of a task |
| [open, done, abandoned](sinter:#plan-state=v1) | the three states of a plan |
| [unfinished](sinter:#task-state=v1) | a task is unfinished while it is open or delivered |
| final | a state that a work item keeps for good |
| [met](sinter:#met-wait=v1) | a wait is met when the work item that it waits for is done |
| [ready](sinter:#ready-task=v1) | a task is ready when it is open and its waits, and the waits of each plan that it is under, are met |
| [accounted for](sinter:#requirement-accounted-for=v1) | a requirement is accounted for when work for it is under way, or was finished at its current revision |
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
| requirement | a declared item that states one obligation | a full name, such as `packs#size-limit` | yes |
| term | a declared item that states the meaning of one word or one fixed phrase | a full name, such as `packs#size` | yes |
| decision record | a declared item that records one practice or one choice | a slug, such as `code-comments` | yes |
| declared finding class | a finding class that a repository declares for itself | a slug, such as `late-fee` | yes |
| conformance vector | one input of a conforming program, with its result and its values | its vector set and its number | yes |
| group | a named set of the conformance vectors of one vector set | its vector set and its name | yes |
| vector set | the conformance vectors of one specification or of one design | its specification or its design | yes |
| task | one piece of work | a work item id | no |
| plan | how a set of tasks gets done | a work item id | no |
| test | a unit of code that a test framework runs | the code names it | no |
| site | a block of text with citations or inline citations in it | no name | no |
| external item | a thing outside the repository | an external id, such as `gh/42` | no |

A declared item is an item that a declaration declares. The declaration
word gives its kind of item: `@design` declares a design, `@spec` a
specification, `@req` a requirement, `@term` a term, `@decision` a
decision record, and `@finding-class` a declared finding class.

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

### 2.3 Designs, specifications, requirements, and terms

A design specifies one part of a system. A specification specifies one
thing of that part, such as a format, a protocol, or a set of
behaviors. A requirement states one obligation of each conforming
program of its design. A term states the meaning of one word or one
fixed phrase, which requirements, terms, and other items can use, and
it states no obligation.

Containment is the relation in which a design holds specifications,
requirements, and terms, and a specification holds requirements and
terms. Each declared item that a design or a specification holds
belongs to it:

- A design holds only specifications, requirements, and terms. A
  specification holds only requirements and terms. No other declared
  item holds a declared item.
- A specification belongs to at most one design.
- A requirement or a term belongs to at most one design and to at most
  one specification. A requirement or a term that belongs to a
  specification belongs to the design of that specification, when that
  specification belongs to a design.
- A design holds a requirement or a term directly when the requirement
  or the term belongs to the design and to no specification.

Example: a design `packs` with one specification `descriptor`, which
holds one term `size` and one requirement `size-limit`.

```markdown
# Language packs
@design packs=v4
Specifies the language packs that give Sinter the grammar of a language.

## The pack descriptor
@spec descriptor=v2
The descriptor names the files of a pack.

### Size
@term size=v1
The size of a descriptor is the number of bytes of its file.

### Size limit
@req size-limit=v1
@cites #{size=v1}
A conforming program must reject a descriptor whose size is more than 1 MiB.
```

The text of a declared item is a part of the files of a tree. Its
declaration is in it. The text of each specification, each
requirement, and each term of a design is in the text of the design.
The text of each requirement and each term of a specification is in the
text of the specification. No part of a file is in the texts of two
different requirements, of two different terms, or of a requirement and
a term. The own text of a design is the part of its text that is in the
text of none of its specifications, requirements, and terms. In the
example, the own text of `packs` is its heading, its tag line, and its
first sentence.

Only the texts of terms and of requirements are normative: a term
states what a word or a fixed phrase means, and a requirement states
what each conforming program of the design must do. The rest of the
text of a design and of its specifications explains the terms and the
requirements and gives examples.

The name of a design is a slug, such as `packs`. The name of a
specification, a requirement, or a term that belongs to a design is a
full name: the slug of the design, `#`, and its part name, such as
`packs#descriptor`, `packs#size`, and `packs#size-limit`. A
specification, a requirement, or a term that belongs to no design is
still a specification, a requirement, or a term, and its name is a
slug. Names come in sets:

- Designs, decision records, and the specifications, the requirements,
  and the terms that belong to no design share one set of slugs.
- Declared finding classes have a set of slugs of their own.
- The specifications, the requirements, and the terms of one design
  share one set of part names.

The file of a design is the file in which the declaration of the design
stands. A design can hold a specification, or hold directly a
requirement or a term, whose declaration is in another file. An
`@extern` line in the own text of the design states a mark for such an
item, such as `@extern spec:descriptor`. The kind word of the line
gives the kind of item, and the part name of the line gives the part
name of the item. A requirement or a term of such a specification has
no mark of its own: the mark of its specification covers it.

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
is about. The block of text is the block in which the `@ack` line
stands. The hash prefix `3f2a9c1d` is the start of the hash of that
block, as the block was when the ack was written. A hash is a short text that a fixed function computes from
a text, so that two different texts almost never have the same hash.

### 2.5 Conformance vectors

A conformance vector is one example of an input of a conforming program
of a design, with the result that a conforming program of that design
gives for that input and the values that it gives together with that
result. A value is a text or a fact that a conforming program gives with
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

A citation entry can name one conformance vector, one group, or
one vector set. The selection of the citation entry is the set of the vectors
that it names in this way:

| citation entry | cited item | selection |
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
as a comment in code or a section of a markdown file, with citations or
inline citations in it, which is neither a declared item nor a test.

An external item is an item outside the repository that an external id
names, such as the issue `gh/42` or the standard `rfc/8259`. An
external id with `#` and a part name, such as `rfc/8259#section-6`,
names a part of such an item, and that part is an external item too.
An external item has no revision. An external item can be a standard:
a published standard, or a part of one. An external item can also
state the meaning of one word or one fixed phrase, such as the external
item `rfc/8259#value`.

### 2.7 Kind words

A kind word at the start of a citation entry, of the target of an
inline citation, or of the target of an `@extern` line states what the
citation entry or the target names:

| kind word | what the citation entry or the target names |
|---|---|
| `design` | a design |
| `spec` | a specification, or an external item that is a standard |
| `req` | a requirement |
| `term` | a term, or an external item that states the meaning of one word or one fixed phrase |
| `decision` | a decision record |
| `finding-class` | a declared finding class |

So `spec:rfc/8259` states that the external item `rfc/8259` is a
standard, and `req:packs#size-limit=v2` states that `packs#size-limit`
is a requirement. The citation entry `term:rfc/8259#value` states that the
external item `rfc/8259#value` states the meaning of one word or one
fixed phrase.

### 2.8 Revisions and pins

Each item of the first nine kinds of item has a revised content: the
part of the item that a revision of the item names.

| item | revised content |
|---|---|
| design | its own text |
| specification | its text, with the texts of its requirements and its terms in it, without the labels of the declarations of those requirements and terms |
| requirement, term, decision record, declared finding class | its text |
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

So an edit of a requirement or a term inside a specification changes
the revised content of that requirement or term and of the
specification. An edit of the own text of a design changes the revised
content of the design alone. An edit of one vector changes the revised
content of its group and of its vector set.

An edge is pinned when the citation entry or the target that states it carries
a label. A pinned edge states its relation to the revised content of
its cited item that the label names. So `@cites packs#size-limit=v2`
rests on the text of `packs#size-limit` that has the label `v2`. An
edge whose citation entry carries `*`, such as `@cites packs=*`, is not pinned:
it rests on the cited item at each of its revisions. An edge whose
cited item is an external item is not pinned, because an external id
carries no label.

### 2.9 Edges

An edge is a relation of one kind of edge from a source to a cited
item. Each citation entry states one edge. The kind of edge is the
citation word without its `@`. The cited item of the edge is the item
that the citation entry names. An inline citation, such as
`[the limit](sinter:packs#size-limit=v2)`, states one edge of the kind
`cites`, and its target names the cited item. When no item has the
name that a citation entry or a target gives, the edge has no cited item.

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
another. A `supersedes` edge from a design whose citation entry is an every-part
target, such as `@supersedes docs=v3#*` in the tag lines of a design
`media`, states two things. The design `media` is to replace the design
`docs`, which the label `v3` pins. And each specification, each
requirement, and each term `docs#x` is to be replaced by the
specification, the requirement, or the term `media#x` of the same kind
of item, when `media` holds one.

### 2.10 Valid trees

The meanings of the sections above apply in every tree. A tree is valid
when it also meets each of these conditions:

| condition | a tree that breaks it |
|---|---|
| each edge is valid: it has a cited item, its kind word states what its cited item is, and the kinds of its source and of its cited item fit its kind of edge | `@verifies packs#size-limit=v2` in a section of a markdown file, whose source is a site and not a test |
| each mark is valid: its kind word is `spec`, `req`, or `term`, and the design holds such an item with its part name, directly for `req` and `term`, declared in another file | `@extern design:docs` |
| each status tag of a declared item fits the kind of item of that declared item | `@rejected` in the tag lines of a requirement |
| each specification, each requirement, and each term belongs to exactly one design | a `@req` line outside every design |
| each specification, and each requirement and each term held directly, whose declaration is outside the file of its design has a mark | a specification in a file of its own, with no `@extern` line in the design |
| each name of a set of names names at most one declared item | two declarations `@decision cache=v1` |

The kinds of source and of cited item fit each kind of edge in this
way:

| kind of edge | its source | its cited item |
|---|---|---|
| `cites` | a declared item, a test, or a site | a declared item or an external item |
| `satisfies` | a declared item, a test, or a site | a requirement |
| `verifies` | a test | a requirement, a conformance vector, a group, or a vector set |
| `refines` | a requirement, a specification, or a design | a requirement, a specification, or a design |
| `supersedes` | a declared item; a design when the citation entry is an every-part target | a declared item of the same kind of item; a design when the citation entry is an every-part target |

So in a valid tree, no `satisfies` edge and no `verifies` edge has a
term as its cited item: a term states no obligation.

A status word fits these kinds of item: `@deprecated` a requirement, a
term, a specification, a design, and a decision record; `@rejected` and
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
plan. No work item is under itself.

A wait goes from a work item, the waiting item, to another work item,
the item that it waits for. A wait is met when the item that it waits
for is done, so a wait for an abandoned work item is never met. A task
is ready when it is open, each of its waits is met, and each wait of
each plan that it is under is met. So a task is ready for work only
after each work item that it waits for, itself or through a plan, is
done.

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

The ledger of a repository is a sequence of ledger entries. A person,
an agent, or the job appends each ledger entry, after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to the ledger, the one that was appended later comes later in
the ledger, whatever times the ledger entries record. A point of the
ledger is a point between two ledger entries, before the first one, or
after the last one. A ledger entry that a clone of the repository has
and has not pushed yet is provisional: it can still come later in the
ledger than ledger entries that other clones push first.

A repair is the one write to the ledger that is not an append, and
only a person makes one. It removes one or more ledger entries from the
ledger. For each ledger entry that it removes, it puts one void where
the removed ledger entry stood: a ledger entry that records the removal
and its reason. A removed ledger entry is no longer in the ledger, so
no state follows from it.

A ledger entry records one event, such as one approval that a person
gave, or one observation of the job. No ledger entry records a state.
Each ledger entry also records the person, the agent, or the job that
wrote it, the person for whom the agent acts when an agent wrote it,
and the branch from which it was written, when there was one. Each
ledger entry has one of eight kinds of ledger entry, in four classes:

| class | kinds of ledger entry | what a ledger entry records | who writes it |
|---|---|---|---|
| definition entries | `task`, `plan` | one whole definition of one work item | a person or an agent |
| judgments | `approval`, `decline`, `done`, `abandoned` | a decision of a person about a subject of approval, a task, or a plan | a person only |
| records of the job | `delivered` | what the job observed about one delivery line | the job only |
| voids | `void` | that a repair removed one ledger entry, and the reason | a person, in a repair |

A definition entry records no judgment: it makes no task done, abandons
nothing, and approves or declines nothing. Each definition entry of a
work item records the first definition of the work item, or an edit of
one earlier definition. A definition entry is accepted when it gives its
work item the definition that it records. The current definition of a
work item is the definition that its latest accepted definition entry
records. A definition entry that is not accepted changes nothing.

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
| deprecated | a requirement, a term, a specification, a design, or a decision record | a `@deprecated` status tag of the item states that it no longer applies and that nothing replaces it |
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
declared item with no status tag and, in a repository that needs
approval for declared items of the kind of item of that source, is also
approved. So a `supersedes` edge whose source waits for approval
retires nothing yet.

A subject of approval is a unit that a person approves or declines as a
whole: the own text of a design, a specification with its requirements
and its terms, a requirement that a design holds directly, a term that
a design holds directly, or a decision record. A requirement or a term
that a specification holds is approved when that specification is
approved, and declined when it is declined. A design is approved when
its own text, each of its specifications, and each requirement and each
term that it holds directly are approved.

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

## 3. Definitions

### 3.1 Items

@term item=v1
@cites text#{design=v1, requirement=v1}

An item is a thing of one of these fourteen kinds of item: design,
specification, requirement, term, decision record, declared finding
class, conformance vector, group, vector set, task, plan, test, site,
and external item. Each item has exactly one kind of item.

### 3.2 Trees

@term tree=v1

A tree of a git repository is the set of the files of the repository,
with their contents, at one commit or in one working tree of the
repository. The tree of a commit is the tree at that commit.

### 3.3 Default branches

@term default-branch=v1

The default branch of a git repository is the branch into which work
on the repository merges.

### 3.4 People

@term person=v1

A person is a human who works on a repository.

### 3.5 Agents

@term agent=v1
@cites {text#{text=v1}, #{person=v1}}

An agent is a program that uses a language model to write texts for a
person, such as code. Each agent acts for one person: the person who
runs it.

### 3.6 The job

@term job=v1
@cites {text#{conforming-program=v1}, #{default-branch=v1}}

Continuous integration is a service that runs checks on the commits of
a repository. The job is an execution of a conforming program that
continuous integration starts at each push to the default branch of a
repository.

### 3.7 Declared items

@term declared-item=v1
@cites {
    identifiers#{tag-word=v1},
    text#{design=v1, requirement=v1},
    #{item=v1},
}

A declared item is an item that a declaration declares. The declaration
word of the declaration gives the kind of item: `@design` declares a
design, `@spec` a specification, `@req` a requirement, `@term` a term,
`@decision` a decision record, and `@finding-class` a declared finding
class. Each design specifies one part of a system.

### 3.8 Containment

@term containment=v1
@cites {text#{design=v1, requirement=v1}, #{declared-item=v1}}

Containment is a relation in which one declared item holds another, and
the other belongs to it. A design holds only specifications,
requirements, and terms. A specification holds only requirements and
terms. No other declared item holds a declared item. A specification
belongs to at most one design. Each requirement and each term belongs
to at most one design and to at most one specification. A requirement
or a term that belongs to a specification belongs to the design to
which that specification belongs, and to no design when that
specification belongs to none. A design holds a requirement or a term
directly when the requirement or the term belongs to the design and to
no specification.

### 3.9 Texts of declared items

@term item-text=v1
@cites {
    text#{design=v1, requirement=v1},
    #{declared-item=v1, containment=v1, specification=v1, tree=v1},
}

The text of a declared item in a tree is a part of the files of that
tree. In each tree, these are true:

- The declaration of each declared item is in the text of the item.
- The text of each specification, each requirement, and each term that
  a design holds is in the text of the design.
- The text of each requirement and each term that a specification holds
  is in the text of the specification.
- No part of a file is in the texts of two different requirements, of
  two different terms, or of a requirement and a term.

### 3.10 Own texts

@term own-text=v1
@cites {
    text#{design=v1, requirement=v1},
    #{containment=v1, item-text=v1, specification=v1, term=v1},
}

The own text of a design is the part of the text of the design that is
in the text of none of the specifications, none of the requirements,
and none of the terms that the design holds.

### 3.11 Specifications

@term specification=v1
@cites {text#{design=v1}, #{declared-item=v1, containment=v1}}

A specification is a declared item that specifies one thing, such as a
format, a protocol, or a set of behaviors, of the part of a system that
the design that holds it specifies.

### 3.12 Terms

@term term=v1
@cites {
    text#{requirement=v1},
    #{item=v1, declared-item=v1, item-text=v1},
}

A term is a declared item whose text states the meaning of one word or
one fixed phrase, which requirements, terms, and other items can use.
The text of a term states no obligation.

### 3.13 Decision records

@term decision-record=v1
@cites #{declared-item=v1}

A decision record is a declared item that records one standing practice
of a project, or one choice with its reason.

### 3.14 Findings and declared finding classes

@term declared-finding-class=v1
@cites {
    identifiers#{segment=v1},
    text#{conforming-program=v1},
    #{item=v1, declared-item=v1, item-text=v1, tree=v1},
}

A finding is a report of one condition about one part of a repository.
Each finding is of one finding class: the sort of condition that the
finding reports, which a slug names. A declared finding class is a
finding class that a repository declares for itself with a
declaration. In a tree, the text of a declared finding class is the
whole of one file of that tree: its finding-class file. A finding class
that a conforming program has built in is not an item.

### 3.15 Names

@term item-name=v1
@cites {
    identifiers#{segment=v1},
    text#{design=v1, requirement=v1},
    #{
        containment=v1, specification=v1, term=v1, decision-record=v1,
        declared-finding-class=v1,
    },
}

The name of a design, of a decision record, and of a declared finding
class is a slug. The name of a specification, a requirement, or a term
that belongs to a design is a full name: the slug of that design, `#`,
and the part name of the specification, the requirement, or the term.
The name of a specification, a requirement, or a term that belongs to
no design is a slug. These are the sets of names:

- The designs, the decision records, and the specifications, the
  requirements, and the terms that belong to no design share one set of
  slugs.
- The declared finding classes have a set of slugs of their own.
- The specifications, the requirements, and the terms of one design
  share one set of part names.

### 3.16 Kinds that kind words state

@term stated-kind=v1
@cites {
    identifiers#{
        kind-word=v1, citation-entry=v1, destination=v1, external-target=v1,
        extern-line=v1,
    },
    text#{design=v1, requirement=v1},
    #{
        specification=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, external-item=v1, standard=v1,
    },
}

A kind word at the start of a citation entry, of the target of
an inline citation, or of the target of an `@extern` line states what
the citation entry or the target names. `design` states a design. `spec` states
a specification, or an external item that is a standard. `req` states
a requirement. `term` states a term, or an external item that states
the meaning of one word or one fixed phrase. `decision` states a
decision record. `finding-class` states a declared finding class.

### 3.17 Marks

@term mark=v1
@cites {
    identifiers#{tag-word=v1, extern-line=v1, segment=v1},
    text#{design=v1},
    #{
        item=v1, declared-item=v1, own-text=v1, containment=v1,
        item-text=v1, item-name=v1, stated-kind=v1,
    },
}

The file of a design is the file in which the declaration of the design
stands. A mark is what an `@extern` line in the own text of a design
states: the design holds an item that is what the kind word of the line
states, whose part name is the part name of the line, and whose
declaration is in a file other than the file of the design.

### 3.18 Conformance vectors

@term conformance-vector=v1
@cites {
    identifiers#{value=v1},
    text#{
        conforming-program=v1, input=v1, result=v1, design=v1,
        requirement=v1,
    },
    #{item=v1, containment=v1},
}

A conformance vector is an item that has an input of a conforming
program of one design, the design of the vector; the result that a conforming program of that design gives
for that input; and the values that it gives together with that
result. The result and the values of a conformance vector follow from
the requirements that its design holds.

### 3.19 Vector sets

@term vector-set=v1
@cites {
    text#{whole-number=v1, design=v1, requirement=v1},
    #{conformance-vector=v1, specification=v1, containment=v1, tree=v1},
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

### 3.20 Groups

@term group=v1
@cites #{item=v1, vector-set=v1, conformance-vector=v1}

A group is an item: a named set of conformance vectors of one vector
set. Each conformance vector is in exactly one group of its vector set.
No two groups of one vector set have the same name.

### 3.21 Selections

@term selection=v1
@cites {
    identifiers#{citation-entry=v1, vector-selection=v1, name=v1},
    text#{decimal-numeral=v1, design=v1},
    #{
        conformance-vector=v1, vector-set=v1, group=v1,
        specification=v1,
    },
}

A citation entry whose vector selection is not empty names one
conformance vector, one group, or one vector set. The vector set is the
vector set of the specification or of the design that the name of the
citation entry names. The citation entry names the conformance vector
of that vector set whose number its `vector-number` writes, when its
vector selection holds a `vector-number`. It names the group of that
vector set whose name is its `group-name`, when its vector selection
holds a `group-name`. Otherwise it names that vector set. The selection
of the citation entry is the set of the conformance vectors that it
names: the one vector, every vector of the group, or every vector of
the vector set.

### 3.22 Tests

@term test=v1
@cites {identifiers#{tag-word=v1}, #{item=v1, tree=v1}}

A test is an item: a unit of code that a test framework runs and
reports as passed or failed, such as a test function, or a set of such
units, such as the tests of one `describe` block. The code in the files
of a tree names each test, and no declaration declares one.

### 3.23 Test evidence

@term test-evidence=v1
@cites #{test=v1}

Test evidence is the set of the reports that tests gave in one
execution of their test frameworks: which tests ran, and which of them
passed and which failed.

### 3.24 Sites

@term site=v1
@cites {
    identifiers#{tag-word=v1, destination=v1},
    #{item=v1, declared-item=v1, test=v1, tree=v1},
}

A site is an item with no name: a block of text in a file of a tree,
such as a comment in code or a section of a markdown file, with
citations or inline citations in it, which is neither a declared item
nor a test.

### 3.25 External items

@term external-item=v1
@cites {identifiers#{external-id=v1, segment=v1}, #{item=v1}}

An external item is an item outside the repository that an external id
names, such as an issue or a published standard. An external id with
`#` and a part name names a part of such an item, and that part is an
external item too.

### 3.26 Standards

@term standard=v1
@cites #{external-item=v1}

A standard is an external item that is a published standard, or a part
of one.

### 3.27 Revised content

@term revised-content=v1
@cites {
    identifiers#{revision=v1},
    text#{design=v1, requirement=v1},
    #{
        item=v1, declared-item=v1, own-text=v1, specification=v1,
        term=v1, decision-record=v1, declared-finding-class=v1,
        item-text=v1, containment=v1, conformance-vector=v1,
        vector-set=v1, group=v1, task=v1, plan=v1, test=v1, site=v1,
        external-item=v1,
    },
}

The revised content of an item is this:

- of a design, its own text;
- of a specification, its text, without the labels of the declarations
  of the requirements and the terms that it holds;
- of a requirement, of a term, of a decision record, and of a declared
  finding class, its text;
- of a conformance vector, its input, its result, and its values;
- of a group, which conformance vectors are in it, and the revised
  content of each;
- of a vector set, which conformance vectors are in it, and the revised
  content of each.

A task, a plan, a test, a site, and an external item have no revised
content.

### 3.28 Revisions of items

@term item-revision=v1
@cites {
    identifiers#{revision=v1, tag-word=v1},
    #{item=v1, revised-content=v1, declared-item=v1, tree=v1},
}

A revision of an item is a label that names one revised content of the
item. No label names two different revised contents of one item, in
one tree or in two trees of a repository. The current revision of an
item in a tree is the label that names the revised content that the
item has in that tree. The current revision of a declared item in a
tree is the label of its declaration in that tree. An item with no
revised content has no revision.

### 3.29 Edges

@term edge=v1
@cites {
    identifiers#{tag-word=v1, citation-entry=v1, destination=v1},
    #{
        item=v1, item-name=v1, external-item=v1, selection=v1,
        work-item=v1, tree=v1,
    },
}

An edge is a relation of one kind of edge from an item, its source, to
an item, its cited item. Each citation entry states one edge,
whose kind of edge is the citation word of the citation without its
`@`. The target of each inline citation states one edge, whose kind of
edge is `cites`. The kinds of edge are these five: `cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`. The cited item of
an edge in a tree is the item that the citation entry or the target that states
the edge names in that tree. When no item of that tree and no external
item has that name, the edge has no cited item in that tree. No edge
has a work item as its cited item.

### 3.30 Sources of edges

@term edge-source=v1
@cites {
    identifiers#{tag-word=v1, destination=v1},
    #{edge=v1, declared-item=v1, item-text=v1, test=v1, site=v1},
}

A citation or an inline citation stands in a declared item when it is
in the text of the item, in a site when it is in the block of text of
the site, and in a test when it is in a comment on the code of the
test. Each edge has exactly one source: a declared item, a test, or a
site in which the citation or the inline citation that states the edge
stands.

### 3.31 Pinned edges

@term pinned-edge=v1
@cites {
    identifiers#{revision=v1, citation-entry=v1, destination=v1},
    #{edge=v1, item-revision=v1, revised-content=v1},
}

An edge is pinned when the citation entry or the target that states it carries
a label, and that label is the label of the edge. A pinned edge states
its relation to the revised content of its cited item that its label
names. An edge whose citation entry or target carries `*` is not pinned, and it
states its relation to its cited item at each revision of the cited
item.

### 3.32 Edges of the kind `cites`

@term cites-edge=v1
@cites #{edge=v1}

A `cites` edge states that its source refers to its cited item and
rests on what the cited item says.

### 3.33 Edges of the kind `satisfies`

@term satisfies-edge=v1
@cites #{edge=v1}

A `satisfies` edge states that its source does what its cited item
states.

### 3.34 Edges of the kind `verifies`

@term verifies-edge=v1
@cites {
    text#{conforming-program=v1, input=v1, result=v1, requirement=v1},
    #{
        edge=v1, conformance-vector=v1, group=v1, vector-set=v1,
        selection=v1,
    },
}

A `verifies` edge states that its source checks code. When its cited
item is a requirement, the edge states that the code that the source
runs meets that requirement. When its cited item is a conformance
vector, a group, or a vector set, the edge states that the code that
the source runs gives, for the input of each conformance vector of the
selection of the citation entry of the edge, the result and the values of that
vector.

### 3.35 Edges of the kind `refines`

@term refines-edge=v1
@cites #{edge=v1}

A `refines` edge states that its source states all or part of its
cited item in more detail.

### 3.36 Edges of the kind `supersedes`

@term supersedes-edge=v1
@cites {
    identifiers#{citation=v1, segment=v1},
    text#{design=v1, requirement=v1},
    #{
        item=v1, edge=v1, declared-item=v1, specification=v1, term=v1,
        containment=v1, item-name=v1,
    },
}

A `supersedes` edge states that its source is to replace its cited
item. When the citation entry of a `supersedes` edge is an every-part target,
and its source and its cited item are designs, the edge also states
that each specification, each requirement, and each term that the
cited design holds is to be replaced by the specification, the
requirement, or the term that the source design holds with the same
kind of item and the same part name, when the source design holds one.
Only a `supersedes` edge states that one declared item is to replace
another.

### 3.37 Status tags of declared items

@term item-status-tag=v1
@cites {identifiers#{tag-word=v1}, #{declared-item=v1, item-text=v1}}

A status tag stands in a declared item when it is in the text of the
item. Each status tag that stands in a declared item is a status tag of
exactly one declared item in which it stands, and no other status tag
is a status tag of a declared item.

### 3.38 Acks

@term ack=v1
@cites {
    identifiers#{tag-word=v1, ack-line=v1, segment=v1},
    #{declared-finding-class=v1, person=v1, agent=v1},
}

An ack is what an `@ack` line states: a person or an agent accepts one
finding for one block of text. The finding is of the finding class
that the slug of the line names, and it is about what the subject of
the line names. The block of text is the block in which the `@ack` line
stands. The hash prefix of the line is the start of the hash of that
block, as the block was when the ack was written.

### 3.39 Valid edges

@term valid-edge=v1
@cites {
    identifiers#{
        kind-word=v1, citation-entry=v1, destination=v1, external-target=v1,
        citation=v1,
    },
    text#{design=v1, requirement=v1},
    #{
        item=v1, edge=v1, edge-source=v1, stated-kind=v1,
        declared-item=v1, external-item=v1, specification=v1, test=v1,
        conformance-vector=v1, group=v1, vector-set=v1, tree=v1,
    },
}

An edge is valid in a tree when, and only when, each of these is true
in that tree:

- The edge has a cited item.
- When the citation entry or the target that states the edge starts with a kind
  word, its cited item is what that kind word states.
- The kinds of its source and of its cited item fit its kind of edge:
  - for `cites`, the cited item is a declared item or an external item;
  - for `satisfies`, the cited item is a requirement;
  - for `verifies`, the source is a test, and the cited item is a
    requirement, a conformance vector, a group, or a vector set;
  - for `refines`, the source and the cited item are each a
    requirement, a specification, or a design;
  - for `supersedes`, the source is a declared item, and the cited item
    is a declared item of the same kind of item; when the citation entry is an
    every-part target, the source and the cited item are designs.

### 3.40 Valid marks

@term valid-mark=v1
@cites {
    identifiers#{tag-word=v1, extern-line=v1, segment=v1},
    text#{design=v1, requirement=v1},
    #{
        mark=v1, declared-item=v1, containment=v1, specification=v1,
        term=v1, item-name=v1,
    },
}

A mark of a design is valid when, and only when, one of these is true:

- The kind word of its `@extern` line is `spec`, and the design holds a
  specification whose part name is the part name of the line and whose
  declaration is in a file other than the file of the design.
- The kind word of its `@extern` line is `req`, and the design holds
  directly a requirement whose part name is the part name of the line
  and whose declaration is in a file other than the file of the design.
- The kind word of its `@extern` line is `term`, and the design holds
  directly a term whose part name is the part name of the line and
  whose declaration is in a file other than the file of the design.

### 3.41 Valid status tags

@term valid-status-tag=v1
@cites {
    identifiers#{tag-word=v1},
    text#{design=v1, requirement=v1},
    #{
        item=v1, declared-item=v1, item-status-tag=v1, specification=v1,
        term=v1, decision-record=v1,
    },
}

A status tag of a declared item is valid when, and only when, the kind
of item of that declared item fits the status word of the status tag.
`@deprecated` fits a requirement, a term, a specification, a design,
and a decision record. `@rejected` and `@deferred` fit only a decision
record.

### 3.42 Valid trees

@term valid-tree=v1
@cites {
    identifiers#{tag-word=v1, extern-line=v1, segment=v1},
    text#{design=v1, requirement=v1},
    #{
        tree=v1, edge=v1, valid-edge=v1, valid-mark=v1,
        valid-status-tag=v1, item-status-tag=v1, mark=v1,
        containment=v1, specification=v1, term=v1, item-name=v1,
        declared-item=v1,
    },
}

A tree is valid when, and only when, each of these is true in it:

- Each edge is valid.
- Each mark of each design is valid.
- Each status tag of each declared item is valid.
- Each specification, each requirement, and each term belongs to
  exactly one design.
- For each specification that a design holds, and for each requirement
  and each term that a design holds directly, whose declaration is in a
  file other than the file of the design, the design has a mark whose
  `@extern` line has the kind word of that item, `spec`, `req`, or
  `term`, and its part name.
- Each name of each set of names names at most one declared item.

### 3.43 Work items

@term work-item=v1
@cites #{item=v1, tree=v1}

A work item is a task or a plan. No work item is in a file of a tree.
Each work item has a work item id, which never changes, and a display
name, which can change.

### 3.44 Tasks

@term task=v1
@cites #{work-item=v1, external-item=v1, person=v1, agent=v1}

A task is a work item for one piece of work that one person or one
agent can finish alone. The paths of a task are a set of paths: the
work of the task can add, change, or remove a file only when the path
of the file is in that set. A task names at most one external item,
which can say what the work is, and several tasks can name one external
item. A task that names an external item can have an empty display
name. A task has no description of its own and no branch.

### 3.45 Promises

@term promise=v1
@cites {
    text#{requirement=v1},
    #{task=v1, edge=v1, edge-source=v1, tree=v1, default-branch=v1},
}

A promise of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and a requirement. It states that the work of the task puts
into the tree of the default branch an edge of that kind of edge whose
cited item is that requirement, from a source in a file whose path is
in the paths of the task.

### 3.46 Plans

@term plan=v1
@cites #{work-item=v1, task=v1}

A plan is a work item that says how a set of tasks gets done.

### 3.47 Waits

@term wait=v1
@cites #{work-item=v1}

A wait is a relation from one work item, the waiting item, to another
work item, the item that it waits for.

### 3.48 What a plan carries out

@term carried-out-item=v1
@cites {text#{requirement=v1, design=v1}, #{plan=v1, specification=v1}}

A plan carries out a set of requirements, specifications, and designs:
its work is for them.

### 3.49 Definitions of work items

@term work-item-definition=v1
@cites {
    text#{requirement=v1, design=v1},
    #{
        work-item=v1, task=v1, promise=v1, plan=v1, wait=v1,
        carried-out-item=v1, external-item=v1, specification=v1,
    },
}

The definition of a task is its display name, its paths, its promises,
its external item, its plan, and its waits. The definition of a plan is
its display name, its plan, its waits, and the requirements,
specifications, and designs that it carries out. The plan of a work
item is the one plan, or none, that its definition names. The waits of
a work item are the waits from it that its definition names. The work
item id of a work item is not part of its definition.

### 3.50 Changes

@term change=v1
@cites {text#{line=v1}, #{tree=v1, default-branch=v1, person=v1}}

A change is a set of commits on a branch, the branch of the change,
that a person merges into the default branch as one unit, such as the
commits of a pull request. The person who merges a change brings its
work to the default branch, as its commits or as one squash commit. The
diff of a change is the set of the lines that differ between the tree
of the commit from which the branch of the change starts and the tree
of the last commit of the change: the lines that the change adds and
the lines that it removes. The lines of a change are the lines of its
diff and the lines of the messages of its commits.

### 3.51 Delivery lines

@term delivery-line=v1
@cites {
    text#{line=v1},
    #{
        task=v1, promise=v1, work-item=v1, work-item-definition=v1,
        default-branch=v1,
    },
}

A delivery line is a line of the message of a commit that states that
the commit completes the work of one task. It names the task by its
work item id, and it names one definition of the task by the start of
a hash of the paths and the promises of that definition. The finishing
commit of a delivery line is the commit in whose message the line is. A
delivery of a task is the arrival of the finishing commit of a delivery
line of the task on the default branch.

### 3.52 Task lines

@term task-line=v1
@cites {text#{line=v1}, #{task=v1, work-item=v1}}

A task line is a line of the message of a commit that names one task by
its work item id, and that states that the commit does part of the work
of the task without finishing it.

### 3.53 Ledger entries

@term ledger-entry=v1
@cites #{person=v1, agent=v1, job=v1, task=v1, plan=v1}

A ledger entry is a record of one event, such as one approval that a
person gave, or one observation of the job. Each ledger entry has one
of these eight kinds of ledger entry: `task`, `plan`, `approval`,
`decline`, `done`, `abandoned`, `delivered`, and `void`. Each ledger
entry records the person, the agent, or the job that wrote it. When an
agent wrote a ledger entry, the ledger entry also records the person for
whom that agent acts. Each ledger entry also records the branch from
which it was written, when there was one.

### 3.54 The ledger

@term ledger=v1
@cites {
    text#{whole-number=v1},
    #{ledger-entry=v1, person=v1, agent=v1, job=v1},
}

The ledger of a repository is a sequence of ledger entries. A person,
an agent, or the job appends each ledger entry, after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to the ledger, the one that was appended later comes later in
the ledger, whatever times the two ledger entries record. A point of
the ledger is given by the ledger entries before it: the first n ledger
entries of the ledger, for a whole number n of 0 or more. A ledger
entry that a clone of the repository has and has not pushed yet is
provisional: it can still come later in the ledger than ledger entries
that other clones push first.

### 3.55 Repairs and voids

@term repair=v1
@cites #{ledger=v1, ledger-entry=v1, person=v1}

A repair is the one write to the ledger that is not an append, and
only a person makes one. A repair removes one or more ledger entries
from the ledger. For each ledger entry that it removes, it puts one
`void` ledger entry, a void, in the ledger where the removed ledger
entry stood: after each ledger entry that came before the removed one,
and before each ledger entry that came after it. A void records that a
repair removed one ledger entry, and the reason for the removal. A
repair makes no other ledger entry different.

### 3.56 Definition entries

@term definition-entry=v1
@cites #{
    ledger-entry=v1, work-item=v1, task=v1, plan=v1,
    work-item-definition=v1, person=v1, agent=v1, judgment=v1,
}

A definition entry is a ledger entry that records one whole definition
of one work item: a `task` ledger entry records a definition of a task,
and a `plan` ledger entry records a definition of a plan. A person or
an agent writes a definition entry. A definition entry records no
judgment.

### 3.57 Current definitions

@term current-definition=v1
@cites #{
    definition-entry=v1, ledger=v1, work-item=v1,
    work-item-definition=v1, state=v1,
}

Each definition entry of a work item records either the first
definition of the work item, or an edit of one earlier definition of
the work item. An accepted definition entry is a definition entry that
gives its work item the definition that it records. The current
definition of a work item at a point of the ledger is the definition
that the latest accepted definition entry of the work item before that
point records. A definition entry that is not accepted changes no
definition and no state. A work item exists from its first accepted
definition entry.

### 3.58 Subjects of approval

@term subject-of-approval=v1
@cites {
    text#{design=v1, requirement=v1},
    #{
        person=v1, own-text=v1, specification=v1, term=v1,
        decision-record=v1, containment=v1, revised-content=v1,
    },
}

A subject of approval is a unit that a person approves or declines as a
whole. The subjects of approval are these five: the own text of a
design; a specification, with its requirements and its terms; a
requirement that a design holds directly; a term that a design holds
directly; and a decision record. The revised content of the own text of
a design is that own text. The revised content of each other subject of
approval is the revised content of its specification, its requirement,
its term, or its decision record.

### 3.59 Judgments

@term judgment=v1
@cites {
    text#{requirement=v1},
    #{
        ledger-entry=v1, person=v1, subject-of-approval=v1, task=v1,
        plan=v1, promise=v1, revised-content=v1, item-revision=v1,
    },
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

### 3.60 Records of the job

@term job-record=v1
@cites {
    text#{requirement=v1},
    #{
        ledger-entry=v1, job=v1, delivery-line=v1, promise=v1, task=v1,
        test-evidence=v1, item-revision=v1, tree=v1,
    },
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

### 3.61 States

@term state=v1
@cites #{
    item=v1, edge=v1, subject-of-approval=v1, ledger-entry=v1,
    ledger=v1, test-evidence=v1, tree=v1,
}

A state is a named condition that an item, an edge, or a subject of
approval is in at one time. Each state follows from the trees and the
messages of the commits of a repository, from the ledger entries of its
ledger, and from test evidence. No ledger entry records a state.

### 3.62 Deprecated

@term deprecated-item=v1
@cites {
    identifiers#{tag-word=v1},
    #{declared-item=v1, item-status-tag=v1, tree=v1},
}

A declared item is deprecated in a tree when a `@deprecated` status tag
of the item in that tree states that the item no longer applies and
that nothing replaces it.

### 3.63 Rejected

@term rejected-record=v1
@cites {
    identifiers#{tag-word=v1},
    #{decision-record=v1, item-status-tag=v1, tree=v1},
}

A decision record is rejected in a tree when a `@rejected` status tag
of the record in that tree states that the choice of the record was
considered and not made.

### 3.64 Deferred

@term deferred-record=v1
@cites {
    identifiers#{tag-word=v1},
    #{decision-record=v1, item-status-tag=v1, tree=v1},
}

A decision record is deferred in a tree when a `@deferred` status tag
of the record in that tree states that the choice of the record is not
made yet.

### 3.65 Effective edges of the kind `supersedes`

@term effective-supersedes-edge=v1
@cites #{
    item=v1, edge=v1, edge-source=v1, declared-item=v1,
    item-status-tag=v1, approved-item=v1, tree=v1,
}

A `supersedes` edge is effective in a tree when, and only when, each of
these is true in that tree: its source is a declared item; its source
has no status tag; and, when the repository needs approval for declared
items of the kind of item of its source, its source is approved.

### 3.66 Retired

@term retired-item=v1
@cites {
    text#{design=v1},
    #{
        declared-item=v1, specification=v1, edge=v1, item-status-tag=v1,
        effective-supersedes-edge=v1, containment=v1, tree=v1,
    },
}

A declared item is retired in a tree when, and only when, one of these
is true in that tree:

- the item has a status tag;
- an effective `supersedes` edge has the item as its cited item;
- the item belongs to a retired design or to a retired specification.

### 3.67 In force

@term in-force-item=v1
@cites #{declared-item=v1, retired-item=v1, tree=v1}

A declared item is in force in a tree when, and only when, it is not
retired in that tree.

### 3.68 Approved

@term approved-item=v1
@cites {
    text#{design=v1, requirement=v1},
    #{
        subject-of-approval=v1, person=v1, ledger-entry=v1, judgment=v1,
        ledger=v1, revised-content=v1, containment=v1, own-text=v1,
        specification=v1, term=v1, tree=v1,
    },
}

A subject of approval is approved in a tree when, and only when, an
`approval` ledger entry records that a person approved the revised
content that the subject has in that tree, and no later `decline` ledger
entry records that a person declined that revised content. A
requirement or a term that a specification holds is approved in a tree
when that specification is approved in that tree. A design is approved
in a tree when its own text, each of its specifications, and each
requirement and each term that it holds directly are approved in that
tree.

### 3.69 Declined

@term declined-item=v1
@cites {
    text#{requirement=v1},
    #{
        subject-of-approval=v1, person=v1, ledger-entry=v1, judgment=v1,
        ledger=v1, revised-content=v1, containment=v1, specification=v1,
        term=v1, tree=v1,
    },
}

A subject of approval is declined in a tree when, and only when, a
`decline` ledger entry records that a person declined the revised
content that the subject has in that tree, and no later `approval`
ledger entry records that a person approved that revised content. A
requirement or a term that a specification holds is declined in a tree
when that specification is declined in that tree.

### 3.70 Drafts

@term draft-design=v1
@cites {text#{design=v1}, #{approved-item=v1, tree=v1}}

A design is a draft in a tree when it is not approved in that tree.

### 3.71 Suspect

@term suspect-edge=v1
@cites #{pinned-edge=v1, edge=v1, item-revision=v1, tree=v1}

An edge is suspect in a tree when, and only when, it is pinned, its
cited item is in that tree, and its label is not the current revision
of its cited item in that tree.

### 3.72 The states of a task

@term task-state=v1
@cites #{
    task=v1, promise=v1, state=v1, ledger=v1, ledger-entry=v1,
    judgment=v1, job-record=v1, current-definition=v1,
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

### 3.73 The parts and the states of a plan

@term plan-state=v1
@cites #{
    plan=v1, task=v1, work-item=v1, work-item-definition=v1,
    current-definition=v1, task-state=v1, ledger-entry=v1, judgment=v1,
    ledger=v1, state=v1,
}

At a point of the ledger, the parts of a plan, the work items under
it, and its state are these, from the ledger entries before that point:

- A work item is a part of a plan when its current definition names
  that plan as its plan, with two exceptions. An abandoned task is a
  part of no plan. The parts of an abandoned plan are only the work
  items that were parts of it, and done, at the point just before the
  first `abandoned` ledger entry of the plan.
- A work item is under a plan when it is a part of the plan, or under a
  part of the plan. No work item is under itself.
- The state of a plan is exactly one of these three: abandoned, when an
  `abandoned` ledger entry of the plan is in the ledger; done, when the
  plan is not abandoned, has at least one part, and each of its parts is
  done; and open, when the plan is neither abandoned nor done.

### 3.74 Met waits

@term met-wait=v1
@cites #{wait=v1, work-item=v1, task-state=v1, plan-state=v1}

A wait is met when the work item that it waits for is done.

### 3.75 Ready tasks

@term ready-task=v1
@cites #{
    task=v1, plan=v1, met-wait=v1, wait=v1, task-state=v1,
    plan-state=v1, work-item-definition=v1, current-definition=v1,
}

A task is ready when it is open, each wait in its current definition is
met, and each wait in the current definition of each plan that the task
is under is met.

### 3.76 Requirements accounted for

@term requirement-accounted-for=v1
@cites {
    text#{requirement=v1, design=v1},
    #{
        specification=v1, containment=v1, task=v1, plan=v1, promise=v1,
        carried-out-item=v1, work-item-definition=v1,
        current-definition=v1, task-state=v1, plan-state=v1, ledger=v1,
        ledger-entry=v1, judgment=v1, job-record=v1, item-revision=v1,
        tree=v1,
    },
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

## 4. Requirements

### 4.1 The states that statements of agents change

@req limit-agent-statements=v1
@cites {
    text#{text=v1, line=v1, conforming-program=v1},
    #{
        agent=v1, ledger-entry=v1, person=v1, state=v1, change=v1,
        definition-entry=v1, item-revision=v1, work-item=v1,
    },
}

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, a ledger entry, or a
message to a person. A conforming program must compute no state from a
statement of an agent, other than from these two:

1. a line of a change that names what it is about by a hash, a revision
   of an item, or a work item id;
2. a definition entry.

### 4.2 The summary of a change

@req show-change-definitions=v1
@cites {
    text#{conforming-program=v1},
    #{
        change=v1, delivery-line=v1, task-line=v1, task=v1,
        definition-entry=v1, ledger-entry=v1, person=v1, agent=v1,
    },
}

The tasks of a change are the tasks that the delivery lines and the
task lines in the messages of the commits of the change name. For each
change, a conforming program must give a summary of the change that
shows every definition entry of each task of the change, and every
definition entry that was written from the branch of the change. The
summary must show each of these definition entries with the person who
wrote it or for whom an agent wrote it, the agent that wrote it when an
agent did, and the branch from which it was written when there was one.

### 4.3 The use of declared tasks

@req limit-declared-tasks=v1
@cites {text#{text=v1, conforming-program=v1}, #{agent=v1, task=v1}}

A session is one execution of an agent on its work. The declared task
of a session is the task that the agent declares as the work of that
session. The brief of a session is the text about its work that a
conforming program gives the agent of the session for that session. A
conforming program must use the declared task of a session only to
narrow the brief of that session.

## 5. Conformance

A program, or a part of a program, conforms to the design Ontology when
it meets every requirement of section 4. No requirement of section 4
gives a result for an input, so there are no conformance vectors.
