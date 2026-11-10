<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
@cites files=v1
@cites data-forms=v1
Specifies the kinds of items that Sinter traces, with their names, revisions, and edges; containment; work items and their relations; the ledger and the actors that write it; the names and meanings of states; and requirements for conforming programs on what they compute states from, on the treatment of ledger entries, on the ledger entries that they append and the repairs that they make when an agent runs them, and on the use of declared tasks.

Sinter traces the items of a repository: designs with their
specifications, requirements, and terms, decision records, tests, tasks
and plans, and the items outside the repository that external ids name.
A citation, such as `@verifies packs#limit-size=v2` in a comment on a
test, states an edge: a relation from its source, here the test, to its
cited item, here the requirement `packs#limit-size` with the text that
the label `v2` names. The ledger of a repository records events, such
as the approval that a person gave to one text. Each state, such as in
force, approved, suspect, or done, follows only from the inputs that
section 4.1 lists, such as the trees of the repository, its ledger, and
test evidence.

From Identifiers, the design takes tag lines and Sinter tag words;
declarations, citations with their citation entries, status tags, and
`@ack` lines; inline citations and their targets; slugs, part names,
full names, labels, and revisions; external ids; values; the production
`every-part`; and the bindings of the parameter `external-namespaces`.
From Text and notation, it takes texts, lines, and whole numbers, and
what a design, a specification, a requirement, a conforming program, and
an input are. From Files and paths, it takes valid paths, path sets, and
the set of the valid paths that a path set gives. From the specification
`test-vectors` of Data forms, it takes test-vector sets with their
vector lines and the objects of those lines, and the meaning of a
vector.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that a project made |
| [item](sinter:#item=v1) | a thing that Sinter traces, such as a requirement, a test, or a task |
| [kind of item](sinter:#item=v1) | one of the fourteen kinds of item, such as design or task; each item has one |
| repository | a git repository |
| commit, message of a commit, parent, branch, file, path, working tree, push, pull request | the thing of git, or of a host of git repositories, that has this name |
| [tree](sinter:#tree=v1) | the set of the files of a repository, with their contents, at one commit or in one working tree |
| [default branch](sinter:#default-branch=v1) | the branch into which work on a repository merges |
| actor | a person, an agent, or the job |
| [person](sinter:#person=v1) | a human who works on a repository |
| [agent](sinter:#agent=v1) | a program that uses a language model to write texts for a person, such as code |
| continuous integration | a service that runs checks on the commits of a repository |
| [job](sinter:#job=v1) | an execution of a conforming program that continuous integration starts at each push to the default branch of a repository |
| [declared item](sinter:#declared-item=v1) | what a declaration declares: an item of the kind design, specification, requirement, term, decision record, or declared finding class |
| [item of the kind design](sinter:#declared-item=v1) | a declared item whose declaration word is `@design` |
| [item of the kind requirement](sinter:#declared-item=v1) | a declared item whose declaration word is `@req` |
| [design](sinter:text#design=v1) | a document that declares, each under a name, obligations and definitions |
| [requirement](sinter:text#requirement=v1) | an obligation that a design declares under a name and states with the word must |
| [specification](sinter:text#specification=v1) | a part of a design that has a name of its own and that declares some of the obligations and definitions of the design |
| [term](sinter:#term=v1) | a declared item whose declaration word is `@term`; it states the meaning of one word or one fixed phrase |
| normative | stating what a word or a fixed phrase means, or what a conforming program must do; only terms and requirements are normative |
| [decision record](sinter:#decision-record=v1) | a declared item whose declaration word is `@decision`; it records one standing practice of a project, or one choice with its reason |
| [finding](sinter:#finding-class=v1) | a report of one condition at one part of a repository |
| [finding class](sinter:#finding-class=v1) | a kind of finding, which a slug names |
| [declared finding class](sinter:#declared-finding-class=v1) | a declared item whose declaration word is `@finding-class`: a finding class that a repository declares for itself |
| [containment](sinter:#containment=v1) | the relation in which a design holds specifications, requirements, and terms, and a specification holds requirements and terms |
| [hold](sinter:#containment=v1), [belong to](sinter:#containment=v1) | a design holds each of its specifications, requirements, and terms, and each of them belongs to the design; a specification holds its requirements and its terms in the same way |
| [hold directly](sinter:#containment=v1) | a design holds a requirement or a term directly when the requirement or the term belongs to the design and to no specification |
| [name of a declared item](sinter:#item-name=v1) | the name that its declaration gives it: a slug, such as `packs`; for an item that belongs to a design, the name of the design, `#`, and the part name of the item, such as `packs#size` |
| [same item](sinter:#same-item=v1) | of two items of two trees: two declared items with the same kind of item and the same name; two conformance vectors with the same number in vector sets that are the same item; two groups with the same name in vector sets that are the same item; two vector sets of specifications, or of items of the kind design, that are the same item; or two tests with the same name whose files have the same path |
| [value](sinter:identifiers#value=v1) | a text or a fact that a conforming program gives together with a result |
| [conformance vector](sinter:#conformance-vector=v1) | a vector line of a vector set: it states one input of a conforming program of the specification or the design of the vector set, and what that program gives for that input |
| [vector set](sinter:#vector-set=v1) | the test-vector set of one specification, or of one design for the requirements that it holds directly |
| [number of a vector](sinter:#conformance-vector=v1) | the number of the vector line of a conformance vector: the value of its member `n`, a whole number of 1 or more |
| [group](sinter:#group=v1) | the conformance vectors of one vector set whose vector lines have one value of the member `group`, with that value as its name |
| [test](sinter:#test=v1) | a unit of code that a test framework runs and reports as passed or failed, or a set of such units, with a name |
| [code of a test](sinter:#test=v1) | the part of its file that a test takes up |
| [comment on a test](sinter:#test=v1) | a comment that is attached to the code of a test, such as the comment right before a test function |
| [test evidence](sinter:#test-evidence=v1) | the reports that tests gave in one execution, each of which names one test and says whether the test passed or failed |
| [site](sinter:#site=v1) | a part of a file outside every declared item and every comment on a test that holds a citation, an inline citation, or an `@ack` line, such as one section of a markdown file or one comment in code |
| [external item](sinter:#external-item=v1) | a thing outside the repository that an external id names, such as an issue or a published standard |
| [revised content](sinter:#revised-content=v1) | the part of an item that its label covers, such as the text of a requirement |
| [revision of an item](sinter:#item-revision=v1) | a label that an item has, which names the revised content that the item has with that label in a given tree |
| [current revision](sinter:#item-revision=v1) | the label that an item has in a given tree, such as `v2` for the declaration `@req limit-size=v2` |
| [edge](sinter:#edge=v1) | a relation of one kind of edge from a source to a cited item, which a citation entry or an inline citation states |
| [kind of edge](sinter:#edge=v1) | one of `cites`, `satisfies`, `verifies`, `refines`, and `supersedes` |
| [stand in](sinter:#edge-source=v1) | a tag line or an inline citation stands in a declared item of which it is a part; otherwise in a test, when it is in a comment on that test; otherwise in the site that holds it |
| [source](sinter:#edge-source=v1) | the item in which the citation or the inline citation of an edge stands |
| [cited item](sinter:#edge=v1) | the item that the citation entry or the inline citation of an edge names |
| [pinned edge](sinter:#pinned-edge=v1) | an edge whose citation entry or inline citation has a label as its revision |
| [work item](sinter:#work-item=v1) | a task or a plan |
| [work item id](sinter:#work-item=v1) | the id of a work item, which never changes and which names exactly one work item |
| [display name](sinter:#work-item=v1) | the name of a work item that a person reads, which can change |
| [task](sinter:#task=v1) | one piece of work that one person or one agent can finish alone |
| [work of a task](sinter:#task=v1) | what people and agents change in the files of a repository to finish a task |
| [paths of a task](sinter:#task=v1) | the path set whose set holds the paths of the files that the work of a task adds, changes, or removes |
| [path set](sinter:files#path-set=v1) | a finite sequence of texts, its path set members, such as `docs/` followed by `!docs/old/` |
| [set of a path set](sinter:files#path-set-membership=v1) | the paths that a path set gives: for `docs/` followed by `!docs/old/`, `docs/a.md` and not `docs/old/a.md` |
| [promise](sinter:#promise=v1) | a pair of a kind of edge, `satisfies` or `verifies`, and the name of a requirement, which a task has |
| [keep a promise](sinter:#promise=v1) | a promise is kept when the tree has the edge that it promises, from a citation in a file in the paths of its task, and, for `verifies`, the test that is the source of that edge passed |
| [plan](sinter:#plan=v1) | a work item that says how a set of tasks and plans gets done |
| [plan of a work item](sinter:#work-item-definition=v1) | the plan that the definition of a work item names |
| [wait](sinter:#wait=v1) | a relation from a work item to another work item that it waits for |
| [carry out](sinter:#carried-out-item=v1) | a plan carries out the requirements, specifications, and designs that its work is for, which it names by their names |
| [definition of a work item](sinter:#work-item-definition=v1) | what a definition entry records about a work item, such as the paths of a task |
| change | a set of commits that is to merge into the default branch as one unit, such as the commits of a pull request |
| [delivery line](sinter:#delivery-line=v1) | a line of the message of a commit that states that the commit completes the work of a task |
| [task line](sinter:#task-line=v1) | a line of the message of a commit that names a task on which the commit does part of the work |
| [ledger](sinter:#ledger=v1) | the sequence of the ledger entries of a repository, in the order in which they were appended |
| [point of a ledger](sinter:#ledger=v1) | a point between two ledger entries, before the first, or after the last |
| [ledger entry](sinter:#ledger-entry=v1) | a record of one event in the ledger, such as one approval |
| [writer of a ledger entry](sinter:#ledger-entry=v1) | the person, the agent, or the job that a ledger entry records as the one that wrote it |
| [repair](sinter:#repair=v1) | a write that removes ledger entries from the ledger of a repository and puts a void in the place of each |
| [void](sinter:#repair=v1) | a ledger entry that takes the place of a ledger entry that a repair removed |
| [definition entry](sinter:#definition-entry=v1) | a ledger entry that records one definition of one work item |
| [accepted definition entry](sinter:#work-item-state=v1) | a definition entry that gives its work item the definition that it records |
| [current definition](sinter:#work-item-state=v1) | the definition that the latest accepted definition entry of a work item records |
| [exist](sinter:#work-item-state=v1) | a work item exists at a point of a ledger when it has a current definition at that point |
| [part of a plan](sinter:#work-item-state=v1) | a work item whose current definition names the plan as its plan, unless an abandonment ended that |
| [under a plan](sinter:#work-item-state=v1) | a part of the plan, or under a part of the plan |
| [subject of approval](sinter:#subject-of-approval=v1) | a unit that a person approves or declines as a whole |
| [kind of subject of approval](sinter:#subject-of-approval=v1) | which of five units a subject of approval is: a design without the declared items in it, a specification, a requirement that a design holds directly, a term that a design holds directly, or a decision record |
| [subject of approval of a declared item](sinter:#subject-of-approval=v1) | for a design, the design without the declared items in it; for a specification, a requirement or a term that a design holds directly, or a decision record, the subject of approval that it is; for a requirement or a term that a specification holds, the subject of approval of that specification |
| parameter | a word, such as `external-namespaces`, for which a conforming program takes a binding: a value that comes from configuration |
| [judgment](sinter:#judgment=v1) | a ledger entry that records a decision of a person, such as an approval |
| [record of the job](sinter:#job-record=v1) | a ledger entry that records what the job observed |
| [state](sinter:#state=v1) | a named condition of an item, an edge, or a subject of approval, in a tree, at a point of a ledger, or both, such as in force or done |
| [retired](sinter:#retired-item=v1) | a declared item is retired when it is deprecated, rejected, or deferred, when an effective `supersedes` edge replaces it, or when it belongs to a retired design or a retired specification |
| [in force](sinter:#in-force-item=v1) | a declared item is in force when it is not retired |
| [effective](sinter:#effective-supersedes-edge=v1) | a `supersedes` edge is effective when the replacement that it states has taken effect: it links the kinds of item that a `supersedes` edge links, its source is not deprecated, rejected, or deferred, and its source is a declared finding class or is approved |
| [deprecated](sinter:#deprecated-item=v1), [rejected](sinter:#rejected-record=v1), [deferred](sinter:#deferred-record=v1) | the states that the three status words state, through a status tag of the item |
| [approved, declined](sinter:#approval-state=v1) | a subject of approval of a kind that needs approval by a person is approved, or declined, when a person approved, or declined, the revised content that it has in the tree; a subject of approval of another kind is approved when that revised content has merged into the default branch, and it is never declined; a requirement or a term that a specification holds is approved, or declined, when that specification is; a design is approved when the design without the declared items in it, each of its specifications, and each requirement and each term that it holds directly are approved |
| [draft](sinter:#draft-design=v1) | a design is a draft while it is not approved |
| [suspect](sinter:#suspect-edge=v1) | a pinned edge is suspect when its label is not the current revision of its cited item |
| [open, delivered, done, abandoned](sinter:#work-item-state=v1) | the four states of a task |
| [open, done, abandoned](sinter:#work-item-state=v1) | the three states of a plan |
| [unfinished](sinter:#work-item-state=v1) | a task is unfinished while it is open or delivered |
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
| design | a declared item whose declaration word is `@design` | a slug, such as `packs` | yes |
| specification | a declared item whose declaration word is `@spec`, which specifies one thing of a system | a full name, such as `packs#descriptor` | yes |
| requirement | a declared item whose declaration word is `@req` | a full name, such as `packs#limit-size` | yes |
| term | a declared item whose declaration word is `@term`, which states the meaning of one word or one fixed phrase | a full name, such as `packs#size` | yes |
| decision record | a declared item whose declaration word is `@decision`, which records one practice or one choice | a slug, such as `code-comments` | yes |
| declared finding class | a declared item whose declaration word is `@finding-class`, a finding class that a repository declares for itself | a slug, such as `late-fee` | yes |
| conformance vector | a vector line of a vector set, which states one input of a conforming program and what the program gives for it | its vector set and its number | yes |
| group | the conformance vectors of one vector set whose vector lines have one value of `group` | its vector set and its name | yes |
| vector set | the test-vector set of one specification or of one design | its specification or its design | yes |
| task | one piece of work | a work item id | no |
| plan | how a set of tasks and plans gets done | a work item id | no |
| test | a unit of code that a test framework runs | its file and its name | no |
| site | a part of a file outside every declared item and every comment on a test that holds a citation, an inline citation, or an `@ack` line | no name | no |
| external item | a thing outside the repository | an external id, such as `gh/42` | no |

A declared item is what a declaration declares, such as the requirement
that `@req limit-size=v1` declares. The declaration word alone gives the
kind of the declared item: `@design` gives the kind design, `@spec` the
kind specification, `@req` the kind requirement, `@term` the kind term,
`@decision` the kind decision record, and `@finding-class` the kind
declared finding class.

A work item is a task or a plan. No work item is in a file of a tree:
the definition entries of the ledger define each one.

### 2.2 Repositories and actors

A repository is a git repository. A tree is the set of the files of the
repository, with their contents, at one commit or in one working tree.
The tree of a commit is the tree at that commit. The default branch is
the branch into which work on the repository merges. A change is a set
of commits that is to merge into the default branch as one unit, such
as the commits of a pull request.

An actor is a person, an agent, or the job. Actors write the ledger
entries that Sinter reads:

- A person is a human who works on a repository.
- An agent is a program that uses a language model to write texts for a
  person, such as code, a commit message, or a ledger entry. A coding
  agent is an example. Each agent acts for one person: the person who
  runs it.
- The job is an execution of a conforming program, such as Sinter, that
  continuous integration starts at each push to the default branch of a
  repository. Continuous integration is a service that runs checks on
  the commits of a repository. The job reads test evidence, and it
  records what it observes about the delivery lines of the commits
  (section 2.10).

### 2.3 Designs, specifications, requirements, and terms

A design is a document that declares, each under a name, obligations
and definitions. Each design specifies one part of a system. A
specification specifies one thing of that part, such as a format, a
protocol, or a set of behaviors. A requirement is an obligation that a
design declares under a name and states with the word must. A term
states the meaning of one word or one fixed phrase, which requirements,
terms, and other items can use, and it states no obligation.

Containment is the relation in which a design holds specifications,
requirements, and terms, and a specification holds requirements and
terms. Each declared item that a design or a specification holds
belongs to it. A requirement or a term that a specification holds
belongs to the design of that specification too. A design holds a
requirement or a term directly when the requirement or the term belongs
to the design and to no specification.

Example: a design `packs` with one specification `descriptor`, which
holds one term `size` and one requirement `limit-size`.

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
@req limit-size=v1
@cites #{size=v1}
A conforming program must reject a descriptor whose size is more than 1 MiB.
```

Only terms and requirements are normative: a term states what a word or
a fixed phrase means, and a requirement states what each conforming
program of the design must do. The rest of a design and of its
specifications explains the terms and the requirements and gives
examples.

### 2.4 Names and identity

The name of a design, of a decision record, and of a declared finding
class is a slug that its declaration gives, such as `packs`. The name of
a specification, a requirement, or a term that belongs to a design is a
full name: the name of the design, `#`, and the part name of the item,
such as `packs#descriptor`, `packs#size`, and `packs#limit-size`. A
citation entry names an item by its name, such as `packs#limit-size` in
`@cites packs#limit-size=v2`, or an external item by its external id,
such as `gh/42` in `@cites gh/42`.

An item of one tree and an item of another tree are the same item when
they are declared items with the same kind of item and the same name,
such as the requirement `packs#limit-size` of two commits. Two
conformance vectors are the same item when they have the same number in
vector sets that are the same item. Two groups are the same item when
they have the same name in vector sets that are the same item. Two
vector sets are the same item when their specifications, or their
designs, are the same item. Two tests are the same item when they have
the same name and their files have the same path. So a requirement that
moves to another place in its design, or to another file, stays the
same item.

### 2.5 Decision records and finding classes

A decision record records one standing practice of a project, or one
choice with its reason, such as the record `code-comments`.

A finding is a report of one condition at one part of a repository. A
finding class is a kind of finding, which a slug names. A repository can
declare finding classes of its own. Each such declared finding class is
a declared item.

### 2.6 Conformance vectors

A conformance vector states one example of an input of a conforming
program of a design, and what a conforming program gives for that input:
a result, the values that come with that result, or both. A value is a
text or a fact that a conforming program gives with a result, such as
the slug of a target that a parser gives. What a conformance vector
states follows from the requirements of its design, and the vector
states no requirement of its own.

Each conformance vector is given for one specification of its design,
or for the requirements that its design holds directly. The vector set
of a specification, or of a design, is a test-vector set, as the
specification `test-vectors` of Data forms gives it: a set line, then a
group line for each group, then a vector line for each vector. Each of
its vector lines is one conformance vector. The member `n` of a vector
line gives the number of the conformance vector, a whole number of 1 or
more. A group is the set of the conformance vectors of one vector set
whose vector lines have the same value of the member `group`, with that
value as its name.

A citation entry can name one conformance vector, one group, or one
vector set. A test that checks code against the vectors of a group cites
the group with `@verifies`:

```python
# @verifies data-forms#toml[offsets][*]=v2
def test_offsets(vector):
    ...
```

### 2.7 Tests, sites, and external items

A test is a unit of code that a test framework runs and reports as
passed or failed, such as a test function. A set of such units, such as
the tests of one `describe` block, is a test too. Each test has a name
and a file. The code of a test is the part of its file that the test
takes up. A comment on a test is a comment that is attached to the code
of the test, such as the comment right before a test function. The code
names each test, so a test has no declaration. Test evidence is the set
of the reports that tests gave in one execution of their test
frameworks. Each report names one test, and it says whether the test
passed or failed.

A site is an item with no name. It is a part of a file outside every
declared item and every comment on a test that holds a citation, an
inline citation, or an `@ack` line, such as one section of a markdown
file or one comment in code.

An external item is an item outside the repository that an external id
names, such as the issue `gh/42` or the standard `rfc/8259`. An external
id names an external item even when nothing outside the repository has
that external id. An external id with `#` and a part name after it, such
as `rfc/8259#section-6`, names a part of such an item, and that part is
an external item too. An external item has no revision. An external item
can be a published standard, or a part of one. It can also state the
meaning of one word or one fixed phrase, such as the external item
`rfc/8259#value`.

### 2.8 Edges

An edge is a relation of one kind of edge from one item, its source, to
another item, its cited item. Each citation entry of a citation states
one edge. The kind of edge is the citation word without its `@`. The
cited item of the edge is the item that the citation entry names. An
inline citation, such as `[the limit](sinter:packs#limit-size=v2)`,
states one edge of the kind `cites`, and the name or the external id in
its target names the cited item. When the citation entry or the target
names no item, the edge has no cited item.

A citation or an inline citation stands in one item: in a declared item
of which it is a part; otherwise, in a test, when it is in a comment on
that test; otherwise, in the site that holds it. The source of an edge
is the item in which its citation or its inline citation stands. So a
`@verifies` line in a comment on a test has that test as its source.

Each kind of edge states one relation, and it links the kinds of item
in this table:

| kind of edge | what it states | its source | its cited item |
|---|---|---|---|
| `cites` | the source refers to the cited item and rests on what the cited item says | a declared item, a test, or a site | a declared item, an external item, a conformance vector, a group, or a vector set |
| `satisfies` | the source does what the cited item states | a declared item, a test, or a site | an item of the kind requirement |
| `verifies` | the source checks that the code it runs meets the cited requirement, or gives what each conformance vector of the cited item states | a test | an item of the kind requirement, a conformance vector, a group, or a vector set |
| `refines` | the source states all or part of the cited item in more detail | an item of the kind requirement, specification, or design | an item of the kind requirement, specification, or design |
| `supersedes` | the source is to replace the cited item | a declared item; an item of the kind design when `every-part` matches the citation entry | a declared item of the same kind of item; an item of the kind design when `every-part` matches the citation entry |

So no `satisfies` edge and no `verifies` edge has a term as its cited
item: a term states no obligation.

No citation entry and no inline citation names a work item, so no edge
has a work item as its cited item. Work points at declared items in the
other direction: a task promises requirements, and a plan carries out
requirements, specifications, and designs.

Only a `supersedes` edge states that one declared item is to replace
another. A `supersedes` edge from a design whose citation entry the
production `every-part` of Identifiers matches, such as
`@supersedes docs=v3#*` in the tag lines of a design `media`, states two
things. The design `media` is to replace the design `docs`, which the
label `v3` pins. And each specification, each requirement, and each term
`docs#x` is to be replaced by the specification, the requirement, or the
term `media#x` of the same kind of item, when `media` holds one.

### 2.9 Revisions and pins

Each design, specification, requirement, term, decision record,
declared finding class, conformance vector, group, and vector set has a
revised content: the part of the item that its label covers, such as
the text of a requirement, or what a conformance vector states. A task,
a plan, a test, a site, and an external item have no revised content and
no revision.

A revision of an item is a label that the item has, and it names the
revised content that the item has with that label in a given tree. The
current revision of an item in a tree is the label that the item has in
that tree, whatever its revised content, such as `v2` for the
declaration `@req limit-size=v2`.

An edge is pinned when the revision of the citation entry or of the
inline citation that states it is a label: the label of the edge. A
pinned edge states its relation to the revised content of its cited
item that its label names. So `@cites packs#limit-size=v2` rests on the
revised content that `packs#limit-size` has with the label `v2`. The
edges of `@supersedes docs=v3#*` and of
`@verifies data-forms#toml[*]=v3` are pinned too, each with the label
`v3`. An edge whose citation entry has the revision `*`, such as
`@cites packs=*`, is not pinned: it rests on the cited item at each of
its revisions. An edge whose cited item is an external item is not
pinned, because an external id carries no revision.

### 2.10 Tasks and plans

A task is one piece of work that one person or one agent can finish
alone. The work of a task is what people and agents change in the files
of the repository to finish the task. A plan says how a set of tasks and
plans gets done. Each work item has a work item id, which never changes
and which names exactly one work item, and a display name, which can
change.

A task has:

- its paths: a path set, whose set holds the paths of the files that
  the work of the task adds, changes, or removes, so the work of a task
  whose paths are the empty path set changes no file;
- its promises: each a pair of a kind of edge, `satisfies` or
  `verifies`, and the name of a requirement, such as
  `verifies ledger#check-ids`;
- at most one external item, such as an issue, which can say what the
  work is; several tasks can name one external item;
- at most one plan, its plan;
- its waits.

A promise links a task to a requirement: the task promises an edge of
the kind of edge of the promise to that requirement, from a citation in
a file in its paths. The promise is kept when the tree has that edge,
and, for a `verifies` promise, when the test that is the source of that
edge passed.

A task has no description of its own: the requirements that it
promises, or its external item, say what to build. A task has no
branch.

A plan has at most one plan, its plan; its waits; and the requirements,
specifications, and designs that it carries out, which it names by their
names. What a plan carries out gives context to the work under it, and
it changes the state of no work item. No person approves a plan.

The definition of a task is its display name, its paths, its promises,
its external item, its plan, and its waits. The definition of a plan
is its display name, its plan, its waits, and what it carries out. The
work item id is not part of the definition. Each edit of a definition
gives a new definition, which a new definition entry records.

At each point of a ledger (section 2.11), each work item that exists has
a current definition. A work item is a part of a plan when its current
definition names the plan as its plan, unless an abandonment ended that.
A work item is under a plan when it is a part of the plan, or under a
part of the plan.

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
  its work item id, and it names definitions of the task.
- A task line, such as `Task: t-3f2a9c1d7e0b`, states that the commit
  does part of the work of the task, without finishing it.

### 2.11 The ledger

The ledger of a repository is a sequence of ledger entries. Ledger
entries are appended at the end of the ledger: after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to one ledger, the one that was appended later comes later in
the ledger, whatever times the ledger entries record.

A point of a ledger is given by the ledger entries before it: the first
n ledger entries of the ledger, for a whole number n of 0 or more. The
point of a ledger entry is the point right before it. The end of a
ledger is the point after its last ledger entry. A state that depends
on ledger entries is a state at a point of a ledger.

A repair is a write that removes ledger entries from the ledger of a
repository. For each ledger entry that it removes, it puts one void in
the place of the removed ledger entry: a ledger entry that records the
removal and its reason. A removed ledger entry is no longer in the
ledger, so no state follows from it.

A ledger entry records one event, such as one approval that a person
gave, or one observation of the job. Each ledger entry also records its
writer: the person, the agent, or the job that, as the ledger entry
states, wrote it. When its writer is an agent, the ledger entry also
records the person for whom that agent acts. A ledger entry can also
record the branch from which it was written. Each ledger entry has one
of eight kinds of ledger entry, in four classes:

| class | kinds of ledger entry | what a ledger entry records |
|---|---|---|
| definition entries | `task`, `plan` | one whole definition of one work item |
| judgments | `approval`, `decline`, `done`, `abandoned` | a decision of a person about a subject of approval, a task, or a plan |
| records of the job | `delivered` | what the job observed about one delivery line |
| voids | `void` | that a repair removed one ledger entry, and the reason |

A definition entry records no judgment: it makes no task done, abandons
nothing, and approves or declines nothing. It names its work item by its
work item id. A `task` ledger entry records a definition of a task, and
a `plan` ledger entry records a definition of a plan. An accepted
definition entry is a definition entry that gives its work item the
definition that it records. A definition entry that is not an accepted
definition entry changes no definition and no state.

The current definition of a work item at a point is the definition that
the latest accepted definition entry of the work item before that point
records. A work item exists at a point when it has a current definition
at that point.

A `done` ledger entry records, for each requirement that the task
promises, the revision of that requirement at which a person judged the
work of the task finished. A `delivered` ledger entry records, for each
definition of the task that its delivery line names, and for each
promise of that definition, the revision of the promised requirement
and whether the promise was kept.

### 2.12 States

A state is a named condition of an item, an edge, or a subject of
approval, in a tree, at a point of a ledger, or both. A conforming
program computes each state only from the inputs that section 4.1
lists. It gives the same states for two ledgers whose ledger entries
differ only in the writers, the persons, and the branches that they
record (section 4.2). No ledger entry records a state.

| state | of | meaning |
|---|---|---|
| in force | a declared item | the item applies: its authors still agree with it, no other declared item replaces it, and the design or the specification that holds it is in force |
| retired | a declared item | the item is not in force |
| effective | a `supersedes` edge | the replacement that the edge states has taken effect, and the edge retires its cited item |
| deprecated | a requirement, a term, a specification, a design, or a decision record | a `@deprecated` status tag of the item states that it no longer applies and that nothing replaces it |
| rejected | a decision record | a `@rejected` status tag of the record states that its choice was considered and not made |
| deferred | a decision record | a `@deferred` status tag of the record states that its choice is not made yet |
| approved | a subject of approval, or a design, a specification, a requirement, a term, or a decision record | for a kind of subject of approval that needs approval by a person, a person approved the revised content that the subject of approval has in the tree; for another kind, that revised content has merged into the default branch; a design is approved when the design without the declared items in it, its specifications, and the requirements and the terms that it holds directly are approved |
| declined | a subject of approval, or a specification, a requirement, a term, or a decision record | the kind of the subject of approval needs approval by a person, and a person declined the revised content that the subject of approval has in the tree |
| draft | a design | the design is not approved |
| suspect | a pinned edge | the label of the edge is not the current revision of its cited item |
| open | a task | the task exists, and it is neither delivered, done, nor abandoned |
| delivered | a task | the job recorded a delivery line of the task, and the task is neither done nor abandoned |
| done | a task | while the task was not abandoned, a person judged the work of the task finished, or the job observed that a delivery line of the task named its current definition and that each promise of that definition was kept |
| abandoned | a task | a person ended the task before it was done |
| ready | a task | the task is open, and each work item that it waits for, itself or through a plan, is done |
| done | a plan | the plan is not abandoned, has at least one part, and each of its parts is done |
| abandoned | a plan | a person ended the plan |
| open | a plan | the plan exists and is neither done nor abandoned |
| accounted for | a requirement | work for the requirement is under way, or was finished at its current revision |

A subject of approval is a unit that a person approves or declines as a
whole: a design without the declared items in it, a specification with
its requirements and its terms, a requirement that a design holds
directly, a term that a design holds directly, or a decision record.
These five are the kinds of subject of approval. A subject of approval
of one tree and a subject of approval of another tree are the same
subject of approval when their declared items are the same item. The
subject of approval of a design is the design without the declared
items in it. The subject of approval of a specification, of a
requirement or a term that a design holds directly, and of a decision
record is the subject of approval that it is. The subject of approval of
a requirement or a term that a specification holds is the subject of
approval of that specification.

A project can choose the kinds of subject of approval that need
approval by a person. A subject of approval of such a kind is approved
when a person approved the revised content that it has in the tree, and
declined when a person declined that revised content. For each other
kind, the merge into the default branch is the approval: a subject of
approval of that kind is approved when the revised content that it has
in the tree has merged into the default branch, and it is never
declined. A requirement or a term that a specification holds is
approved when that specification is approved, and declined when it is
declined. A design is approved when the design without the declared
items in it, each of its specifications, and each requirement and each
term that it holds directly are approved.

A declared item is retired when it is deprecated, rejected, or
deferred; when an effective `supersedes` edge replaces it; or when it
belongs to a retired design or a retired specification. A `supersedes`
edge is effective when the replacement that it states has taken effect:
it links the kinds of item that a `supersedes` edge links, its source is
not deprecated, rejected, or deferred, and its source is a declared
finding class, which no person approves, or is approved. So a
`supersedes` edge whose source waits for approval retires nothing yet,
and a `supersedes` edge from a design retires nothing until the whole
design is approved.

The label of a suspect edge is no longer the current revision of its
cited item: the cited item has a new revision, so the source may no
longer agree with it.

At each point of a ledger, each task that exists is in one of the states
open, delivered, done, and abandoned:

- A task is abandoned when a person ended it before it was done.
- A task is done when, while the task was not abandoned, a person
  judged its work finished, or the job observed that a delivery line of
  the task named its current definition and that each promise of that
  definition was kept.
- A task is delivered when the job observed a delivery line of the
  task, and the task is neither done nor abandoned.
- A task is open when it is in none of these three states.

A task is unfinished while it is open or delivered. The state of a task
records work that happened, and it does not state that the code stays
correct.

A requirement is accounted for when one of these is true:

- an unfinished task has a promise that names it;
- an open plan names, as carried out, the requirement, its
  specification, or its design;
- a done task promised it, and the ledger entry that made the task done
  records its current revision for it.

A promise and a plan name a requirement by its name, so they name the
same requirement in each tree in which that requirement has that name.

### 2.13 Statements of agents

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, a ledger entry, or a
message to a person. A conforming program computes each state only from
the inputs that section 4.1 lists, and it gives the same states for two
ledgers whose ledger entries differ only in the writers, the persons,
and the branches that they record (section 4.2). When its input states
that an agent runs it, a conforming program appends to the ledger no
ledger entry other than a definition entry, and it makes no repair
(section 4.3). A statement of an agent changes a state in one of two
ways only:

1. as a line that a change adds to a file or removes from it, which is
   about the item in which it stands; or as a delivery line or a task
   line in the message of one of the commits of a change;
2. as a definition entry.

The person who merges a change can see the lines in the change itself.
A statement of an agent outside these two ways, such as a message of an
agent that its work is done, changes no state.

A session is one execution of an agent on its work. The agent can
declare a task as the work of its session. The declared task changes
no state. Sinter uses it only to narrow the brief of the session: the
text that Sinter gives the agent about its work for that session.

## 3. Definitions

### 3.1 Items

@term item=v1
@cites {
    text#{specification=v1},
    #{
        declared-item=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, conformance-vector=v1, group=v1,
        vector-set=v1, task=v1, plan=v1, test=v1, site=v1,
        external-item=v1,
    },
}

An item is a thing that Sinter traces. Each item has exactly one of
these fourteen kinds of item: the six kinds of a declared item, which
are design, specification, requirement, term, decision record, and
declared finding class; and conformance vector, group, vector set,
task, plan, test, site, and external item.

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

The job is an execution of a conforming program that continuous
integration starts at each push to the default branch of a repository.

### 3.7 Declared items

@term declared-item=v1
@cites identifiers#{declaration=v1, sinter-tag-word=v1}

A declared item is what a declaration declares. The declaration word of
that declaration alone gives the kind of the declared item: `@design`
gives the kind design, `@spec` the kind specification, `@req` the kind
requirement, `@term` the kind term, `@decision` the kind decision
record, and `@finding-class` the kind declared finding class. So an item
of the kind design is a declared item whose declaration word is
`@design`, an item of the kind specification is a declared item whose
declaration word is `@spec`, and an item of the kind requirement is a
declared item whose declaration word is `@req`.

### 3.8 Containment

@term containment=v1
@cites #{declared-item=v1, term=v1}

Containment is a relation in which one declared item holds another, and
the other belongs to it. It links these kinds of item: an item of the
kind design holds items of the kind specification, items of the kind
requirement, and terms; and an item of the kind specification holds
items of the kind requirement and terms. No other declared item holds a
declared item. Each declared item belongs to at most one item of the
kind design and to at most one item of the kind specification. An item
of the kind requirement or a term that belongs to an item of the kind
specification belongs to the item of the kind design to which that item
of the kind specification belongs, and to none when that item of the
kind specification belongs to none. An item of the kind design holds
directly an item of the kind requirement or a term when that item
belongs to it and to no item of the kind specification.

### 3.9 Terms

@term term=v1
@cites #{declared-item=v1}

A term is a declared item whose declaration word is `@term`. It states
the meaning of one word or one fixed phrase, which other items can use.

### 3.10 Decision records

@term decision-record=v1
@cites #{declared-item=v1}

A decision record is a declared item whose declaration word is
`@decision`. It records one standing practice of a project, or one
choice with its reason.

### 3.11 Findings and finding classes

@term finding-class=v1
@cites identifiers#{slug=v1}

A finding is a report of one condition at one part of a repository. A
finding class is a kind of finding, which a slug names.

### 3.12 Declared finding classes

@term declared-finding-class=v1
@cites #{declared-item=v1, finding-class=v1}

A declared finding class is a declared item whose declaration word is
`@finding-class`: a finding class that a repository declares for
itself.

### 3.13 Names

@term item-name=v1
@cites {
    identifiers#{slug=v1, part-name=v1, full-name=v1, declaration=v1},
    #{
        declared-item=v1, containment=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, tree=v1,
    },
}

The name of a declared item in a tree is the name that its declaration
gives it. The name of an item of the kind design, of a decision record,
and of a declared finding class is a slug, such as `packs`. The name of
an item of the kind specification, of an item of the kind requirement,
and of a term that belongs to an item of the kind design is a full name:
the name of that item of the kind design, `#`, and the part name that
the declaration of the item gives it, such as `packs#size`.

### 3.14 Vector sets

@term vector-set=v1
@cites {
    text#{design=v1, specification=v1, requirement=v1},
    data-forms#{test-vector-set=v1, vector-meaning=v1},
    #{declared-item=v1, containment=v1, tree=v1},
}

In a tree, each item of the kind design and each item of the kind
specification has one vector set. The vector set of an item of the kind
specification is the test-vector set of that specification in that
tree. The vector set of an item of the kind design is the test-vector
set of that design in that tree, for the requirements that it holds
directly.

### 3.15 Conformance vectors

@term conformance-vector=v1
@cites {
    data-forms#{
        test-vector-line=v1, vector-meaning=v1, test-vector-set=v1,
    },
    text#{design=v1, specification=v1},
    #{vector-set=v1, declared-item=v1},
}

Each vector line of the vector set of an item of the kind specification,
or of an item of the kind design, is a conformance vector of that vector
set. That vector set is a test-vector set of the specification, or of
the design, so the object of each of its vector lines states one vector
of the specification, or of the design. The number of a conformance
vector is the number of its vector line.

### 3.16 Groups

@term group=v1
@cites {
    data-forms#{test-vector-line=v1, vector-object=v1},
    text#{text=v1},
    #{vector-set=v1, conformance-vector=v1},
}

A group of a vector set is a set of the conformance vectors of that
vector set, with a name. For each text that is the value of `group` of
the object of a vector line of the vector set, the conformance vectors
whose vector lines have that value of `group` form one group of the
vector set, with that text as its name. A vector set has no other group.

### 3.17 Identity of items across trees

@term same-item=v1
@cites {
    text#{specification=v1},
    #{
        item=v1, declared-item=v1, item-name=v1, conformance-vector=v1,
        vector-set=v1, group=v1, test=v1, tree=v1,
    },
}

An item of one tree and an item of another tree are the same item
when, and only when, one of these is true:

- both are declared items, with the same kind of item and the same
  name;
- both are conformance vectors, with the same number, and their vector
  sets are the same item;
- both are groups, with the same name, and their vector sets are the
  same item;
- both are vector sets, of specifications that are the same item, or of
  items of the kind design that are the same item;
- both are tests, with the same name, and their files have the same
  path.

### 3.18 Tests

@term test=v1
@cites {identifiers#{declaration=v1}, #{tree=v1}}

A test is a unit of code that a test framework runs and reports as
passed or failed, such as a test function, or a set of such units, such
as the tests of one `describe` block. No declaration declares a test.
Each test is in one file of a tree, its file, and it has a name, such as
the name of a test function. The code of a test is the part of its file
that the test takes up. A comment on a test is a comment that is
attached to the code of the test, such as the comment right before a
test function.

### 3.19 Test evidence

@term test-evidence=v1
@cites #{test=v1}

Test evidence is the set of the reports that tests gave in one
execution of their test frameworks. Each report names one test, and it
says that the test passed or that it failed.

### 3.20 Sites

@term site=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1, ack-line=v1},
    #{declared-item=v1, test=v1, tree=v1},
}

A site is a part of a file of a tree that is outside every declared
item and every comment on a test, and that holds a citation, an inline
citation, or an `@ack` line, such as one section of a markdown file or
one comment in code. A site has no name.

### 3.21 External items

@term external-item=v1
@cites identifiers#{external-id=v1, part-name=v1}

An external item is a thing outside the repository that an external id
names, even when nothing outside the repository has that external id.
An external id with `#` and a part name after it, such as
`rfc/8259#section-6`, names a part of such an item, and that part is an
external item too.

### 3.22 Revised content

@term revised-content=v1
@cites {
    identifiers#{label=v1},
    text#{text=v1, requirement=v1},
    #{
        item=v1, declared-item=v1, conformance-vector=v1, group=v1,
        vector-set=v1, task=v1, plan=v1, test=v1, site=v1,
        external-item=v1,
    },
}

The revised content of an item is the part of the item that its label
covers, such as the text of a requirement, or what a conformance vector
states. Each declared item, each conformance vector, each group, and
each vector set has a revised content. A task, a plan, a test, a site,
and an external item have no revised content.

### 3.23 Revisions of items

@term item-revision=v1
@cites {
    identifiers#{label=v1, declaration=v1},
    #{revised-content=v1, tree=v1, item=v1},
}

A revision of an item is a label that the item has, and it names the
revised content that the item has with that label in a given tree. The
current revision of an item in a tree is the label that the item has in
that tree, whatever its revised content, such as the label `v2` of the
declaration `@req limit-size=v2`. An item that has no revised content
has no revision.

### 3.24 Edges

@term edge=v1
@cites {
    identifiers#{
        citation=v1, citation-entry=v1, sinter-tag-word=v1,
        inline-citation=v1,
    },
    #{item=v1, tree=v1},
}

An edge is a relation of one kind of edge from an item, its source, to
an item, its cited item. The kinds of edge are these five: `cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`. Each citation
entry of a citation states one edge, whose kind of edge is the citation
word of the citation without its `@`. Each inline citation states one
edge, whose kind of edge is `cites`. The cited item of an edge in a tree
is the item that its citation entry, or its inline citation, names in
that tree. When the citation entry or the inline citation names no item
in that tree, the edge has no cited item in that tree.

### 3.25 Sources of edges

@term edge-source=v1
@cites {
    identifiers#{tag-line=v1, citation=v1, inline-citation=v1},
    #{edge=v1, declared-item=v1, test=v1, site=v1, tree=v1, item=v1},
}

A tag line or an inline citation in a file of a tree stands in one item:
in a declared item of which it is a part; otherwise, in a test, when it
is in a comment on that test; otherwise, in the site that holds it. The
source of an edge is the item in which the citation or the inline
citation that states the edge stands.

### 3.26 Pinned edges

@term pinned-edge=v1
@cites {
    identifiers#{
        revision=v1, label=v1, citation-entry=v1, inline-citation=v1,
        target=v1,
    },
    #{edge=v1, item-revision=v1, revised-content=v1},
}

An edge is pinned when, and only when, the revision of its citation
entry, or the revision in the target of its inline citation, is a
label. That label is the label of the edge. A pinned edge states its
relation to the revised content of its cited item that its label names.
An edge that is not pinned states its relation to its cited item at
each revision of the cited item.

### 3.27 Edges of the kind `cites`

@term cites-edge=v1
@cites #{
    edge=v1, edge-source=v1, declared-item=v1, test=v1, site=v1,
    external-item=v1, conformance-vector=v1, group=v1, vector-set=v1,
}

A `cites` edge states that its source refers to its cited item and
rests on what the cited item says. It links a declared item, a test, or
a site, its source, to a declared item, an external item, a conformance
vector, a group, or a vector set, its cited item.

### 3.28 Edges of the kind `satisfies`

@term satisfies-edge=v1
@cites #{edge=v1, edge-source=v1, declared-item=v1, test=v1, site=v1}

A `satisfies` edge states that its source does what its cited item
states. It links a declared item, a test, or a site, its source, to an
item of the kind requirement, its cited item.

### 3.29 Edges of the kind `verifies`

@term verifies-edge=v1
@cites {
    text#{input=v1, conforming-program=v1},
    data-forms#{vector-meaning=v1},
    #{
        edge=v1, edge-source=v1, declared-item=v1, test=v1,
        conformance-vector=v1, group=v1, vector-set=v1,
    },
}

A `verifies` edge states that its source checks code. It links a test,
its source, to an item of the kind requirement, a conformance vector, a
group, or a vector set, its cited item. When its cited item is an item
of the kind requirement, the edge states that the code that the source
runs meets that item. When its cited item is a conformance vector, a
group, or a vector set, the edge states that the code that the source
runs gives, for the input of that conformance vector, or of each
conformance vector of that group or of that vector set, what that
conformance vector states that a conforming program gives.

### 3.30 Edges of the kind `refines`

@term refines-edge=v1
@cites #{edge=v1, edge-source=v1, declared-item=v1}

A `refines` edge states that its source states all or part of its
cited item in more detail. It links an item of the kind requirement,
specification, or design, its source, to an item of the kind
requirement, specification, or design, its cited item.

### 3.31 Edges of the kind `supersedes`

@term supersedes-edge=v1
@cites {
    identifiers#{citation-entry=v1, citation-line=v1},
    #{
        item=v1, edge=v1, declared-item=v1, containment=v1,
        item-name=v1, term=v1, edge-source=v1,
    },
}

A `supersedes` edge states that its source is to replace its cited
item. It links a declared item, its source, to a declared item of the
same kind of item, its cited item. When the production `every-part`
matches the citation entry of a `supersedes` edge, the edge links an
item of the kind design to an item of the kind design, and it also
states this: each item of the kind specification, each item of the kind
requirement, and each term that the cited item holds is to be replaced
by the declared item with the same kind of item and the same part name
that the source holds, when the source holds one. Only a `supersedes`
edge states that one declared item is to replace another.

### 3.32 Work items

@term work-item=v1
@cites #{task=v1, plan=v1, tree=v1}

A work item is a task or a plan. No work item is in a file of a tree.
Each work item has a work item id, which never changes and which names
exactly one work item, and a display name, which can change.

### 3.33 Tasks

@term task=v1
@cites {
    files#{path=v1, path-set=v1, path-set-membership=v1},
    #{person=v1, agent=v1, external-item=v1},
}

A task is one piece of work that one person or one agent can finish
alone. The work of a task is what people and agents change in the files
of the repository to finish the task. The paths of a task are a path
set, whose set holds the paths of the files that the work of the task
adds, changes, or removes. A task names at most one external item, which
can say what the work is, and several tasks can name one external item.
A task has no description of its own and no branch.

### 3.34 Promises

@term promise=v1
@cites {
    identifiers#{citation=v1},
    text#{requirement=v1},
    #{
        task=v1, edge=v1, edge-source=v1, declared-item=v1,
        item-name=v1, test=v1, tree=v1,
    },
}

A promise of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and the name of a requirement. It links the task to the item
of the kind requirement that has that name: the task promises an edge of
that kind of edge to that item, from a citation in a file in the paths
of the task. The promise is kept in a tree when that tree has that edge,
and, for a `verifies` promise, when the test that is the source of that
edge passed.

### 3.35 Plans

@term plan=v1
@cites #{task=v1}

A plan says how a set of tasks and plans gets done.

### 3.36 Waits

@term wait=v1
@cites #{work-item=v1}

A wait is a relation from one work item, the waiting item, to another
work item, the item that it waits for.

### 3.37 What a plan carries out

@term carried-out-item=v1
@cites {
    text#{requirement=v1, design=v1, specification=v1},
    #{plan=v1, item-name=v1},
}

A plan carries out a set of requirements, specifications, and designs:
its work is for them. The plan names each of them by its name.

### 3.38 Definitions of work items

@term work-item-definition=v1
@cites {
    text#{requirement=v1, design=v1, specification=v1},
    #{
        work-item=v1, task=v1, promise=v1, plan=v1, wait=v1,
        carried-out-item=v1, external-item=v1,
    },
}

The definition of a task is its display name, its paths, its promises,
its external item, its plan, and its waits. The definition of a plan is
its display name, its plan, its waits, and the requirements,
specifications, and designs that it carries out. The plan of a work
item is the one plan, or none, that its definition names. The waits of
a work item are the waits from it that its definition names. The work
item id of a work item is not part of its definition.

### 3.39 Delivery lines

@term delivery-line=v1
@cites {
    text#{line=v1},
    #{task=v1, work-item=v1, work-item-definition=v1},
}

A delivery line is a line of the message of a commit that states that
the commit completes the work of one task. It names the task by its work
item id, and it names definitions of the task.

### 3.40 Task lines

@term task-line=v1
@cites {text#{line=v1}, #{task=v1, work-item=v1}}

A task line is a line of the message of a commit that names one task by
its work item id, and that states that the commit does part of the work
of the task without finishing it.

### 3.41 Ledger entries

@term ledger-entry=v1
@cites #{person=v1, agent=v1, job=v1, task=v1, plan=v1}

A ledger entry is a record of one event, such as one approval that a
person gave, or one observation of the job. Each ledger entry has one
of these eight kinds of ledger entry: `task`, `plan`, `approval`,
`decline`, `done`, `abandoned`, `delivered`, and `void`. Each ledger
entry records a writer: the person, the agent, or the job that, as the
ledger entry states, wrote it. When the writer that a ledger entry
records is an agent, the ledger entry also records a person: the person
for whom, as the ledger entry states, that agent acts. A ledger entry
can also record a branch: the branch from which, as the ledger entry
states, it was written.

### 3.42 The ledger

@term ledger=v1
@cites {text#{whole-number=v1}, #{ledger-entry=v1}}

The ledger of a repository is a sequence of ledger entries. Ledger
entries are appended at the end of the ledger: after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to one ledger, the one that was appended later comes later in
the ledger, whatever times the two ledger entries record. A point of a
ledger is given by the ledger entries before it: the first n ledger
entries of the ledger, for a whole number n of 0 or more. The point of a
ledger entry is the point right before it, and the end of a ledger is
the point after its last ledger entry.

### 3.43 Repairs and voids

@term repair=v1
@cites #{ledger=v1, ledger-entry=v1}

A repair is a write that removes one or more ledger entries from the
ledger of a repository, and that puts one `void` ledger entry, a void,
in the place of each ledger entry that it removes: after each ledger
entry that came before the removed one, and before each ledger entry
that came after it. A void records that a repair removed one ledger
entry, and the reason for the removal.

### 3.44 Definition entries

@term definition-entry=v1
@cites #{
    ledger-entry=v1, work-item=v1, task=v1, plan=v1,
    work-item-definition=v1, judgment=v1,
}

A definition entry is a ledger entry of the kind `task` or `plan`. It
names one work item, its work item, by its work item id. It records one
whole definition of its work item: the first definition of the work
item, or an edit of its definition. A `task` ledger entry records a
definition of a task, and a `plan` ledger entry records a definition of
a plan. A definition entry records no judgment.

### 3.45 Subjects of approval

@term subject-of-approval=v1
@cites {
    text#{specification=v1},
    #{
        person=v1, declared-item=v1, term=v1, decision-record=v1,
        containment=v1, revised-content=v1, same-item=v1, tree=v1,
    },
}

A subject of approval is a unit that a person approves or declines as a
whole. Each subject of approval is one of these: an item of the kind
design, without the declared items in it; a specification, with the
items of the kind requirement and the terms that it holds; an item of
the kind requirement that an item of the kind design holds directly; a
term that an item of the kind design holds directly; or a decision
record. These five are the kinds of subject of approval, and the kind of
a subject of approval is the one of the five that it is. The declared
item of a subject of approval is the item of the kind design, for the
first kind, and otherwise the specification, the item of the kind
requirement, the term, or the decision record that the subject of
approval is. The subject of approval of a declared item is the subject
of approval whose declared item it is, when there is one. The subject
of approval of an item of the kind requirement or of a term that a
specification holds is the subject of approval of that specification.
Each other declared item has no subject of approval. The revised
content of a subject of approval is the revised content of its declared
item. A subject of approval of one tree and a subject of approval of
another tree are the same subject of approval when their declared items
are the same item.

### 3.46 Judgments

@term judgment=v1
@cites {
    text#{requirement=v1},
    #{
        ledger-entry=v1, person=v1, subject-of-approval=v1,
        revised-content=v1, task=v1, plan=v1, promise=v1,
        item-revision=v1,
    },
}

A judgment is a ledger entry that records a decision of a person. A
judgment is one of these four kinds of ledger entry:

- An `approval` ledger entry records that a person approved one revised
  content of one subject of approval.
- A `decline` ledger entry records that a person declined one revised
  content of one subject of approval.
- A `done` ledger entry records that a person judged the work of one
  task finished, and, for each requirement that the task promises, the
  revision of that requirement at which the person judged the work
  finished.
- An `abandoned` ledger entry records that a person ended one task or
  one plan, and the reason.

### 3.47 Records of the job

@term job-record=v1
@cites {
    text#{requirement=v1},
    #{
        ledger-entry=v1, job=v1, delivery-line=v1, promise=v1, task=v1,
        work-item-definition=v1, item-revision=v1,
    },
}

A record of the job is a ledger entry of the kind `delivered`: it
records what the job observed about one delivery line, and it is a
`delivered` ledger entry of the task that the line names. For each
definition of that task that the line names, and for each promise of
that definition, it records the revision of the promised requirement,
and whether the promise was kept.

### 3.48 The states of work items

@term work-item-state=v1
@cites #{
    ledger=v1, ledger-entry=v1, definition-entry=v1, work-item=v1,
    task=v1, plan=v1, work-item-definition=v1, promise=v1, person=v1,
    job=v1, delivery-line=v1, state=v1,
}

At each point of a ledger, the ledger entries before that point give
the current definition of each work item, the work items that exist,
the parts of each plan, and the state of each task and each plan:

1. An accepted definition entry is a definition entry that gives its
   work item the definition that it records. The current definition of
   a work item at a point is the definition that the latest accepted
   definition entry of the work item before that point records. A work
   item exists at a point when, and only when, it has a current
   definition at that point.
2. A work item is a part of a plan at a point when its current
   definition names that plan as its plan, unless an abandonment ended
   that. A part of a plan is a task or a plan. A work item is under a
   plan at a point when it is a part of the plan, or under a part of
   the plan, at that point.
3. Each task that exists at a point is in one of these four states at
   that point:
   - abandoned, when a person ended the task before it was done;
   - done, when, while the task was not abandoned, a person judged the
     work of the task finished, or the job observed that a delivery line
     of the task named its current definition and that each promise of
     that definition was kept;
   - delivered, when the job observed a delivery line of the task, and
     the task is neither done nor abandoned;
   - open, when it is none of abandoned, done, and delivered.
4. A task is unfinished at a point when, and only when, it is open or
   delivered at that point.
5. Each plan that exists at a point is in one of these three states at
   that point:
   - abandoned, when a person ended the plan;
   - done, when it is not abandoned, it has at least one part, and each
     of its parts is done at that point;
   - open, when it is neither abandoned nor done.

### 3.49 States

@term state=v1
@cites #{item=v1, edge=v1, subject-of-approval=v1, tree=v1, ledger=v1}

A state is a named condition of an item, an edge, or a subject of
approval, in a tree, at a point of a ledger, or in a tree at a point of
a ledger.

### 3.50 Deprecated

@term deprecated-item=v1
@cites {
    identifiers#{status-tag=v1},
    #{declared-item=v1, term=v1, decision-record=v1, tree=v1},
}

An item of the kind design, specification, or requirement, a term, or a
decision record is deprecated in a tree when, and only when, it has a
`@deprecated` status tag in that tree. That status tag states that the
item no longer applies and that nothing replaces it.

### 3.51 Rejected

@term rejected-record=v1
@cites {identifiers#{status-tag=v1}, #{decision-record=v1, tree=v1}}

A decision record is rejected in a tree when, and only when, it has a
`@rejected` status tag in that tree. That status tag states that the
choice of the record was considered and not made.

### 3.52 Deferred

@term deferred-record=v1
@cites {identifiers#{status-tag=v1}, #{decision-record=v1, tree=v1}}

A decision record is deferred in a tree when, and only when, it has a
`@deferred` status tag in that tree. That status tag states that the
choice of the record is not made yet.

### 3.53 Approved and declined

@term approval-state=v1
@cites {
    text#{design=v1, requirement=v1, specification=v1},
    #{
        subject-of-approval=v1, person=v1, revised-content=v1,
        containment=v1, term=v1, decision-record=v1, declared-item=v1,
        default-branch=v1, tree=v1, ledger=v1,
    },
}

In a tree, at a point of a ledger, these are the states approved and
declined:

- A subject of approval of a kind that needs approval by a person in the
  project is approved when a person approved the revised content that
  the subject of approval has in that tree. It is declined when a person
  declined that revised content.
- A subject of approval of a kind that needs no approval by a person in
  the project is approved when the revised content that it has in that
  tree has merged into the default branch. It is not declined.
- A specification, a requirement or a term that a design holds directly,
  and a decision record are each approved when, and only when, the
  subject of approval that is that item, or that is that specification
  with its requirements and its terms, is approved. Each of them is
  declined when, and only when, that subject of approval is declined.
- A requirement or a term that a specification holds is approved when,
  and only when, that specification is approved. It is declined when,
  and only when, that specification is declined.
- A design is approved when, and only when, the design without the
  declared items in it, each of its specifications, and each
  requirement and each term that it holds directly are approved.

### 3.54 Drafts

@term draft-design=v1
@cites {text#{design=v1}, #{approval-state=v1, tree=v1, ledger=v1}}

A design is a draft in a tree, at a point of a ledger, when, and only
when, it is not approved in that tree at that point.

### 3.55 Effective edges of the kind `supersedes`

@term effective-supersedes-edge=v1
@cites #{
    edge=v1, edge-source=v1, supersedes-edge=v1, deprecated-item=v1,
    rejected-record=v1, deferred-record=v1, approval-state=v1,
    declared-finding-class=v1, tree=v1, ledger=v1, person=v1,
}

A `supersedes` edge is effective in a tree, at a point of a ledger,
when the replacement that it states has taken effect: its source and
its cited item are of the kinds of item that a `supersedes` edge links;
its source is not deprecated, rejected, or deferred in that tree; and
its source is a declared finding class, which no person approves, or is
approved in that tree at that point.

### 3.56 Retired

@term retired-item=v1
@cites #{
    declared-item=v1, deprecated-item=v1, rejected-record=v1,
    deferred-record=v1, effective-supersedes-edge=v1, edge=v1,
    containment=v1, tree=v1, ledger=v1,
}

A declared item is retired in a tree, at a point of a ledger, when it no
longer applies in that tree at that point: when it is deprecated,
rejected, or deferred; when an effective `supersedes` edge replaces it;
or when it belongs to a retired item of the kind design or to a retired
item of the kind specification.

### 3.57 In force

@term in-force-item=v1
@cites #{declared-item=v1, retired-item=v1, tree=v1, ledger=v1}

A declared item is in force in a tree, at a point of a ledger, when,
and only when, it is not retired in that tree at that point.

### 3.58 Suspect

@term suspect-edge=v1
@cites #{pinned-edge=v1, edge=v1, item-revision=v1, tree=v1}

An edge is suspect in a tree when, and only when, it is pinned and its
label is not the current revision of its cited item in that tree.

### 3.59 Met waits

@term met-wait=v1
@cites #{wait=v1, work-item=v1, work-item-state=v1, ledger=v1}

A wait is met at a point of a ledger when, and only when, the work item
that it waits for is done at that point.

### 3.60 Ready tasks

@term ready-task=v1
@cites #{
    task=v1, plan=v1, met-wait=v1, wait=v1, work-item-definition=v1,
    work-item-state=v1, ledger=v1,
}

A task is ready at a point of a ledger when, and only when, it is open
at that point, each wait of its current definition is met at that
point, and each wait of the current definition of each plan that the
task is under at that point is met at that point.

### 3.61 Requirements accounted for

@term requirement-accounted-for=v1
@cites {
    text#{requirement=v1, design=v1, specification=v1},
    #{
        containment=v1, task=v1, plan=v1, promise=v1,
        carried-out-item=v1, work-item-definition=v1,
        work-item-state=v1, ledger=v1, ledger-entry=v1,
        item-revision=v1, item-name=v1, tree=v1,
    },
}

A requirement is accounted for in a tree, at a point of a ledger, when,
and only when, one of these is true at that point:

- the current definition of an unfinished task has a promise whose
  name is the name of the requirement in that tree;
- the current definition of an open plan names, as carried out,
  the name that the requirement, the specification that holds it, or
  the design that holds it has in that tree;
- a done task promised the requirement, and the ledger entry that
  made the task done records, for the requirement, its current revision
  in that tree.

## 4. Requirements

### 4.1 The sources of states

@req compute-states-from-artifacts=v1
@cites {
    identifiers#{binding=v1},
    text#{conforming-program=v1, input=v1},
    #{
        state=v1, tree=v1, default-branch=v1, delivery-line=v1,
        task-line=v1, ledger=v1, test-evidence=v1,
    },
}

A conforming program must compute each state only from these inputs:
the commits of the repository with their parents; the commit to which
each branch points, and which branch is the default branch; the paths
and the contents of the files of trees; the delivery lines and the task
lines of the messages of commits; the ledger, in its order; test
evidence; the binding of `external-namespaces`; and the bindings of the
other parameters, the values that come from configuration.

### 4.2 The same treatment of each ledger entry

@req treat-ledger-entries-alike=v1
@cites {
    text#{conforming-program=v1},
    #{state=v1, ledger=v1, ledger-entry=v1, person=v1},
}

A conforming program must give the same states for two ledgers whose
ledger entries differ only in the writers, the persons, and the
branches that they record.

### 4.3 The ledger entries that agents write

@req write-only-definitions-for-agents=v1
@cites {
    text#{conforming-program=v1, input=v1},
    #{
        agent=v1, ledger=v1, ledger-entry=v1, definition-entry=v1,
        repair=v1,
    },
}

When its input states that an agent runs it, a conforming program must
append to the ledger no ledger entry other than a definition entry, and
must make no repair.

### 4.4 The use of declared tasks

@req use-declared-tasks-only-for-briefs=v1
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
