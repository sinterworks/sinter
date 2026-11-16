<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
@cites files=v1
@cites data-forms=v1
Specifies the kinds of item that Sinter traces, with their names, revisions, and edges; trees and the default branch; containment; work items and their relations; the ledger and the actors that write it; the names and meanings of states; parameters and their bindings; and requirements for conforming programs on the inputs on which states depend, on the treatment of ledger entries, on how they change the ledger, on what they append to the ledger and the repairs that they make when an agent runs them, on the judgments that they append and the repairs that they make, and on the use of declared tasks.

Sinter traces the items of a repository, such as items of the kind
design, specification, and requirement, terms, decision records, tests,
tasks, plans, and the items outside it that external ids name. A
citation, such as `@verifies billing#limit-amount=v2` in a comment on a
test, gives an edge: a relation from its source, here the test, to its
cited item, here the item of the kind requirement
`billing#limit-amount`. The label `v2` pins the edge to one revised
content of that item. The ledger of a repository records events, such as
the approval that a person gave to one revised content. Each state, such
as in force, approved, suspect, or done, depends only on the state
inputs (term `state-input`), such as the trees of the commits of the
repository, its ledger, test evidence, and the bindings of the
parameters that designs name. For example, a binding of a parameter that
a design names gives the kinds of subject of approval that need approval
by a person.

From Identifiers, the design takes tag lines and Sinter tag words;
declarations, citations with their citation entries, status tags, and
`@ack` lines; inline citations, their destinations, and their targets;
segments, slugs, part names, full names, labels, and revisions; external
ids; the productions `declaration-line`, `citation-line`, `every-part`,
and `inline-destination`, and the matches of texts by productions; the
parameter `external-namespaces` with its bindings; and the result
"valid" that a conforming program of Identifiers gives for an input.
From Text and notation, it takes texts, lines, and whole numbers; byte
sequences, valid UTF-8, and the text of a byte sequence; and what a
design, a specification, a requirement, a conforming program, an input,
and a result are. From Files and paths, it takes valid paths, path sets,
and the set of the valid paths that a path set gives. From the
specification `test-vectors` of Data forms, it takes test-vector sets
with their set lines, group lines, and vector lines; the objects, the
groups, and the revisions of those lines; the forms of a group; and the
meaning of a vector.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that the people who work on the repository made |
| [item](sinter:#item=v1) | a thing that Sinter traces, such as an item of the kind requirement, a test, or a task |
| [kind of item](sinter:#item=v1) | one of the fourteen kinds of item, such as design or task; each item has one |
| repository, commit, message of a commit, parent, branch, working tree, clone, push, pull request, merge | the thing of git, or of a host of git repositories, that has this name |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [tree](sinter:#tree=v1) | a set whose members are the files of the tree, in which no two files of the tree have the same valid path, such as the tree of a commit or the tree of a working tree |
| [file of a tree](sinter:#tree=v1) | a member of a tree: a valid path with a content, which is a byte sequence |
| [text of a file of a tree](sinter:#tree=v1), [line of a file of a tree](sinter:#tree=v1) | the text of the content of a file of a tree, when that content is valid UTF-8; a line of that text |
| [tree of a commit](sinter:#tree=v1), [tree of a working tree](sinter:#tree=v1) | the one tree that a commit gives, and the one tree that a working tree gives |
| [default branch](sinter:#default-branch=v1) | the branch into which the people who work on a repository bring their work |
| actor | a person, an agent, or the job |
| [person](sinter:#person=v1) | a human who works on a repository |
| [agent](sinter:#agent=v1) | a program that uses a language model to write texts, such as code, as one person runs it; it acts for that person |
| continuous integration | a service that runs checks on the commits of a repository |
| [job](sinter:#job=v1) | an execution of a conforming program that continuous integration starts at each push to the default branch of a repository |
| [tag line](sinter:identifiers#tag-line=v1), [tag word](sinter:identifiers#tag-word=v1) | a line whose first character, after the spaces and tabs at its start, is `@`; its tag word is that `@` with the longest run of ASCII letters, ASCII digits, and `-` right after it, such as `@req` |
| [declaration](sinter:identifiers#declaration=v1) | a tag line whose tag word is a declaration word, such as `@req limit-amount=v2` |
| [declaration word](sinter:identifiers#sinter-tag-word=v1) | one of the tag words `@decision`, `@design`, `@finding-class`, `@req`, `@spec`, and `@term` |
| [citation](sinter:identifiers#citation=v1) | a tag line whose tag word is a citation word, such as `@cites billing#limit-amount=v2` |
| [citation word](sinter:identifiers#sinter-tag-word=v1) | one of the tag words `@cites`, `@refines`, `@satisfies`, `@supersedes`, and `@verifies` |
| [citation entry](sinter:identifiers#citation-entry=v1) | one entry of the target of a citation, with one name or one external id, such as `billing#limit-amount=v2` in `@cites billing#limit-amount=v2`; in `@cites #{amount=v1}`, the part `amount=v1` stands for the citation entry `#amount=v1` |
| [inline citation](sinter:identifiers#inline-citation=v1) | a markdown link whose destination starts with `sinter:`, such as `[the limit](sinter:billing#limit-amount=v2)` |
| [target](sinter:identifiers#target=v1) | the text that follows the tag word of a declaration or a citation, up to the first space or tab outside braces, such as `limit-amount=v2` in `@req limit-amount=v2`; for an inline citation, its destination after `sinter:`, such as `billing#limit-amount=v2` |
| [status tag](sinter:identifiers#status-tag=v1) | a tag line whose tag word is a status word, such as `@deprecated` |
| [status word](sinter:identifiers#sinter-tag-word=v1) | one of the tag words `@deferred`, `@deprecated`, and `@rejected` |
| [`@ack` line](sinter:identifiers#directive=v1) | a tag line whose tag word is `@ack`, such as `@ack retired docs#size=v2 3f2a9c1d` |
| [slug](sinter:identifiers#slug=v1) | one segment, or several segments joined by `/`, such as `billing` or `billing/auth`; a segment is a text of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them |
| [part name](sinter:identifiers#part-name=v1) | a segment, such as `limit-amount` in `billing#limit-amount` |
| [full name](sinter:identifiers#full-name=v1) | a slug, `#`, and a part name, such as `billing#limit-amount` |
| [label](sinter:identifiers#label=v1) | a text of the characters from `!` to `~`, other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, `}`, `[`, and `]`, such as `v2` |
| [revision of a citation entry](sinter:#pinned-edge=v1), [revision of an inline citation](sinter:#pinned-edge=v1) | the label, or `*`, that a citation entry, or the destination of an inline citation, carries after `=`, such as `v2` in `billing#limit-amount=v2` and `v3` in `docs=v3#*`; `*` stands for any label |
| [external id](sinter:identifiers#external-id=v1) | a namespace name, such as `gh`, `/`, and an id, such as `42`, as in `gh/42`; a binding of the parameter `external-namespaces` gives the namespace names; an external id names an external item |
| [`every-part`](sinter:identifiers#citation-line=v1) | the production that matches a slug, `=`, a label, and `#*`, such as `docs=v3#*` |
| [declared item](sinter:#declared-item=v1) | what a declaration declares, for a declaration that Identifiers accepts: an item of the kind design, specification, requirement, term, decision record, or declared finding class; it takes up a part of one file of a tree, and that part has its declaration |
| [item of the kind design](sinter:#declared-item=v1) | a declared item whose declaration word is `@design`; it is a design |
| [item of the kind specification](sinter:#declared-item=v1) | a declared item whose declaration word is `@spec`; it declares one specification of the design of which it is a part |
| [item of the kind requirement](sinter:#declared-item=v1) | a declared item whose declaration word is `@req`; it declares one requirement of the design of which it is a part |
| [design](sinter:text#design=v1) | a document that declares, each under a name, obligations and definitions |
| [requirement](sinter:text#requirement=v1) | an obligation that a design declares under a name and states with the word must |
| [specification](sinter:text#specification=v1) | a part of a design that has a name of its own and that declares some of the obligations and definitions of the design |
| [term](sinter:#term=v1) | a declared item whose declaration word is `@term`; it says what one word or one fixed phrase means |
| normative | saying what a word or a fixed phrase means, or what a conforming program must do; only terms and requirements are normative |
| [decision record](sinter:#decision-record=v1) | a declared item whose declaration word is `@decision`; it records one standing practice of a repository, or one choice with its reason |
| [finding](sinter:#finding-class=v1) | a report of one condition at one part of a repository |
| [finding class](sinter:#finding-class=v1) | a kind of finding, which a slug names |
| [declared finding class](sinter:#declared-finding-class=v1) | a declared item whose declaration word is `@finding-class`: a finding class that a repository declares for itself |
| [containment](sinter:#containment=v1) | the relation in which an item of the kind design holds items of the kind specification, items of the kind requirement, and terms, and an item of the kind specification holds items of the kind requirement and terms |
| [hold](sinter:#containment=v1), [belong to](sinter:#containment=v1) | an item of the kind design holds each of its items of the kind specification, its items of the kind requirement, and its terms, and each of them belongs to that item of the kind design; an item of the kind specification holds its items of the kind requirement and its terms in the same way |
| [hold directly](sinter:#containment=v1) | an item of the kind design holds an item of the kind requirement or a term directly when that item belongs to it and to no item of the kind specification |
| [name of a declared item](sinter:#item-name=v1) | for an item of the kind design, a decision record, or a declared finding class, the name in the target of its declaration, which is a slug, such as `billing`; for an item of the kind specification, an item of the kind requirement, or a term, the name in the target of its declaration, except when that name is one segment and the item belongs to an item of the kind design: then the name of that item of the kind design, `#`, and that segment, such as `billing#amount` |
| [same item](sinter:#same-item=v1) | of two items of two trees: they are one item, such as two declared items with the same kind of item and the same name |
| [conformance vector](sinter:#conformance-vector=v1) | the item whose vector line is one vector line of a vector set, with the number of that line; when the object of its vector line states a vector of the specification or the design of the vector set by the forms of its group, it says that vector: an input, or several inputs, of a conforming program of the specification or the design of the vector set, and what the requirements of that specification, or the requirements that the design holds directly, oblige that program to give for them; otherwise it says no vector |
| [vector line of a conformance vector](sinter:#conformance-vector=v1) | one vector line of a vector set; each vector line of a vector set is the vector line of one conformance vector, and a vector set has no other conformance vector |
| [vector set](sinter:#vector-set=v1) | the test-vector set of an item of the kind specification, or of an item of the kind design, in a tree, when the tree has one |
| [number of a conformance vector](sinter:#conformance-vector=v1) | the number of the vector line of a conformance vector: the value of the member `n` of its object, a whole number of 1 or more |
| [group of a vector line](sinter:data-forms#vector-line=v1) | the value of the member `group` of the object of a vector line, or of a group line, which is a group name such as `offsets` |
| [group of conformance vectors](sinter:#conformance-vector-group=v1) | the set of the conformance vectors of one vector set whose vector lines have one group as the value of the member `group`; its name is that group |
| [test](sinter:#test=v1) | a unit of code that a test runner runs and that can pass or fail, or a set of such units that the code groups under one name, such as the tests of one `describe` block |
| test runner | a program that runs tests and gives a test result for each test that it runs |
| [name of a test](sinter:#test=v1) | a sequence of own names: the own names of the tests of which the test is a part, from the outermost to the innermost, and then the own name of the test; for example, the own name of the test function `t` is `t` |
| [file of a test](sinter:#test=v1) | the file of a tree in which a test is |
| [code of a test](sinter:#test=v1) | the part of the file of a test that the test takes up |
| [comment on a test](sinter:#test=v1) | a comment that is attached to the code of a test, such as the comment right before a test function |
| [test evidence](sinter:#test-evidence=v1) | the test results of one execution of test runners that say that the tests that they name passed or that those tests failed |
| [test result](sinter:#test-evidence=v1) | what a test runner gives for one test that it runs; each test result names no test, one test, or more than one test, and it says the same of each test that it names |
| [site](sinter:#site=v1) | a part of a file of a tree that is outside every declared item and every comment on a test, and that has a citation, an inline citation, or an `@ack` line, such as one section of a file of a tree in markdown, or one comment in code; no two sites of a file of a tree have a line in common |
| [external item](sinter:#external-item=v1) | a thing outside the repository that an external id names, such as an issue or a published standard |
| [label of an item](sinter:#revised-content=v1), [current revision](sinter:#item-revision=v1) | the label that an item has in a given tree: for a declared item, the text that `label` matches in its declaration, when its declaration has one, such as `v2` in the declaration `@req limit-amount=v2`; for a conformance vector, a group of conformance vectors, or a vector set, the revision of its vector line, its group line, or its set line |
| [revised content](sinter:#revised-content=v1) | the part of an item that its label covers, such as the text of an item of the kind requirement |
| [revision of an item](sinter:#item-revision=v1) | a label that an item has, which names the revised content that the item has with that label in a given tree |
| [edge](sinter:#edge=v1) | a relation of one kind of edge from its source to its cited item, which a citation entry or an inline citation gives; an edge has at most one source and at most one cited item |
| [kind of edge](sinter:#edge=v1) | one of `cites`, `satisfies`, `verifies`, `refines`, and `supersedes` |
| [be for](sinter:#edge=v1) | a kind of edge is for some kinds of item as its source and as its cited item; an edge says what its kind of edge says when, and only when, its source and its cited item are of those kinds |
| [stand in](sinter:#edge-source=v1) | a line of a file of a tree, a citation, or an inline citation stands in the innermost declared item of which it is a part; otherwise in the innermost test such that a comment on that test has it; otherwise in the site that has it; otherwise in no item |
| [source](sinter:#edge=v1) | the item in which the citation or the inline citation of an edge stands; an edge whose citation or inline citation stands in no item has no source |
| [cited item](sinter:#edge=v1) | the item that the citation entry or the inline citation of an edge names |
| [pinned edge](sinter:#pinned-edge=v1) | an edge whose citation entry or inline citation has a label as its revision |
| [work item](sinter:#work-item=v1) | a task or a plan |
| [work item id](sinter:#work-item=v1) | the id of a work item, which never changes and which names exactly one work item |
| [display name](sinter:#work-item=v1) | the name of a work item that a person reads, which can change |
| [task](sinter:#task=v1) | one piece of work that one person or one agent can finish alone |
| [work of a task](sinter:#task=v1) | what people and agents change in the trees of a repository to finish a task |
| [paths of a task](sinter:#task=v1) | the path set whose set has the valid paths of the files of a tree that the work of a task is to add, change, or remove |
| [path set](sinter:files#path-set=v1) | a finite sequence of texts, its path set members, such as `docs/` followed by `!docs/old/` |
| [set of a path set](sinter:files#path-set-membership=v1) | the paths that a path set gives: for `docs/` followed by `!docs/old/`, `docs/a.md` and not `docs/old/a.md` |
| [promise](sinter:#promise=v1) | a pair of a kind of edge, `satisfies` or `verifies`, and the name of an item of the kind requirement, which a task has |
| [keep a promise](sinter:#promise=v1) | a promise is kept in a tree when the tree has an edge that it promises, from a file in the paths of its task, that is not suspect, and, for `verifies`, test evidence shows that the source of that edge passed |
| [plan](sinter:#plan=v1) | one piece of work that is made up of tasks and plans |
| [plan of a work item in a definition](sinter:#work-item-definition=v1) | the plan, or none, that the definition names |
| [wait](sinter:#wait=v1) | a relation from a work item, the waiting item, to another work item, the work item that it waits for |
| [carry out](sinter:#carried-out-item=v1) | a plan carries out the items of the kind requirement, specification, and design that the work of the tasks that make up the plan, directly or through other plans, is for; it names them by their names |
| [definition of a work item](sinter:#work-item-definition=v1) | for a task, a display name, paths, promises, at most one external item, at most one plan, and waits; for a plan, a display name, at most one plan, waits, and the items that the plan carries out; each alteration of a definition gives a new definition |
| [delivery line](sinter:#delivery-line=v1) | a line of the message of a commit that says that the commit completes the work of a task |
| [task line](sinter:#task-line=v1) | a line of the message of a commit that names a task on which the commit does part of the work |
| [ledger](sinter:#ledger=v1) | the sequence of the ledger entries of a repository; each ledger entry other than a void is appended at the end of the ledger of one clone; a pull of ledger entries is a write that a clone makes to its own ledger: it takes the ledger entries, voids included, of another clone and puts them first, and a push of ledger entries puts ledger entries of a clone after the ledger entries of another clone; neither is appending |
| [point of a ledger](sinter:#ledger=v1) | a point between two ledger entries, before the first, or after the last |
| [ledger entry](sinter:#ledger-entry=v1) | a record of one event in the ledger, such as one approval |
| [writer of a ledger entry](sinter:#ledger-entry=v1) | the person, the agent, or the job that a ledger entry records as the one that wrote it |
| [repair](sinter:#repair=v1) | a write to the ledger of a repository, other than an append, a pull of ledger entries, or a push of ledger entries, that removes zero or more ledger entries and puts one void where each of them was |
| [void](sinter:#repair=v1) | a ledger entry that stands where a ledger entry that a repair removed was |
| [definition entry](sinter:#definition-entry=v1) | a ledger entry that records one definition of one work item |
| [accepted definition entry](sinter:#work-item-state=v1) | a definition entry that gives its work item the definition that it records |
| [current definition](sinter:#work-item-state=v1) | the definition that the last accepted definition entry of a work item, in the order of the ledger, records |
| [exist](sinter:#work-item-state=v1) | a work item exists at a point of a ledger when it has a current definition at that point |
| [part of a plan](sinter:#work-item-state=v1) | a work item whose current definition names the plan as its plan, unless the work item is abandoned, or the plan was abandoned while the work item was not done |
| [under a plan](sinter:#work-item-state=v1) | a part of the plan, or under a part of the plan |
| [subject of approval](sinter:#subject-of-approval=v1) | a unit that a person approves, or that the merge approves, as a whole |
| [kind of subject of approval](sinter:#subject-of-approval=v1) | which of five units a subject of approval is: an item of the kind design without the declared items that it holds, an item of the kind specification with the items of the kind requirement and the terms that it holds, an item of the kind requirement that an item of the kind design holds directly, a term that an item of the kind design holds directly, or a decision record |
| [subject of approval of a declared item](sinter:#subject-of-approval=v1) | for an item of the kind design, an item of the kind specification, an item of the kind requirement or a term that an item of the kind design holds directly, or a decision record, the subject of approval whose declared item it is; for an item of the kind requirement or a term that an item of the kind specification holds, the subject of approval of that item of the kind specification |
| [parameter](sinter:#parameter=v1), [binding of a parameter](sinter:#parameter=v1) | a parameter is a word, such as `external-namespaces`, whose value a design leaves open; a binding of a parameter is a value that configuration gives for the parameter; a binding of the parameter `external-namespaces` is a [binding](sinter:identifiers#binding=v1) as Identifiers defines it |
| process | one execution of a program |
| standard input, arguments, environment | the standard input, the command-line arguments, and the environment variables of a process |
| [judgment](sinter:#judgment=v1) | a ledger entry that records a decision of a person, such as an approval |
| [record of the job](sinter:#job-record=v1) | a ledger entry that records what the job observed |
| [state](sinter:#state=v1) | a named condition of an item, an edge, a wait, or a subject of approval, in a tree, at a point of a ledger, or both, such as in force or done |
| [state input](sinter:#state-input=v1) | one of the things on which states depend: which commits the repository has, each with its parents and its tree; the commit to which each branch points; the commit of the default branch; the tree of each working tree; the delivery lines and the task lines of the messages of commits; the ledger, in its order; test evidence; or the bindings of the parameters that designs name |
| [retired](sinter:#retired-item=v1) | a declared item is retired when it is deprecated, rejected, or deferred, when it is the cited item of an effective `supersedes` edge, or when it belongs to a retired item of the kind design or a retired item of the kind specification |
| [in force](sinter:#in-force-item=v1) | a declared item is in force when it is not retired |
| [effective](sinter:#effective-supersedes-edge=v1) | a `supersedes` edge is effective when its replacement has taken effect: the edge says what its kind of edge says, neither its source nor an item that holds its source is deprecated, rejected, or deferred, and its source is a declared finding class or is approved |
| [deprecated](sinter:#deprecated-item=v1), [rejected](sinter:#rejected-record=v1), [deferred](sinter:#deferred-record=v1) | the states that the three status words give, through a status tag that stands in the item |
| [approved, declined](sinter:#approval-state=v1) | the states of a subject of approval whose revised content a person approved or declined, or, for a kind of subject of approval that needs no approval by a person, whose revised content merged into the default branch |
| [draft](sinter:#draft-design=v1) | an item of the kind design is a draft while it is not approved |
| [suspect](sinter:#suspect-edge=v1) | a pinned edge is suspect when it has a cited item, and that item has no current revision or a current revision other than the label of the edge |
| [open, delivered, done, abandoned](sinter:#work-item-state=v1) | the four states of a task |
| [open, done, abandoned](sinter:#work-item-state=v1) | the three states of a plan |
| [unfinished](sinter:#work-item-state=v1) | a task is unfinished while it is open or delivered |
| [met](sinter:#met-wait=v1) | a wait says that the work of the waiting item is to start only after the work item that it waits for is done; a wait is met when the work item that it waits for is done |
| [ready](sinter:#ready-task=v1) | a task is ready when it is open and its waits, and the waits of each plan that it is under, are met |
| [accounted for](sinter:#requirement-accounted-for=v1) | an item of the kind requirement is accounted for when work for it is under way, or was finished at its current revision |
| statement of an agent | a text that an agent writes |
| session | one execution of an agent on its work |
| declared task | the task that an agent declares as the work of its session |
| brief of a session | the text about the work of the session that a conforming program gives the agent of that session, in no state input |

## 2. The items, their relations, and their states

### 2.1 Items and their kinds

Sinter traces items of fourteen kinds of item, such as the declared item
of the kind requirement that `@req limit-amount=v2` declares, a test,
and a task (terms `item` and `declared-item`).

### 2.2 Repositories and actors

A repository has trees, such as the tree of a commit and the tree of a
working tree, and a default branch, and persons, agents, and the job
write its ledger entries (terms `tree`, `default-branch`, `person`,
`agent`, and `job`).

### 2.3 Designs, specifications, requirements, and terms

An item of the kind design holds items of the kind specification, items
of the kind requirement, and terms, and an item of the kind
specification holds items of the kind requirement and terms (terms
`containment` and `term`).

Example: an item of the kind design `billing` that holds one item of the
kind specification `invoice`, which holds one term `amount` and one item
of the kind requirement `limit-amount`. This table gives the lines of
its file in their order, without the blank lines:

| line |
|---|
| `# Billing` |
| `@design billing=v4` |
| `Specifies the invoices that a billing service sends.` |
| `## Invoices` |
| `@spec invoice=v2` |
| `An invoice asks a customer to pay a sum of money.` |
| `### Amount` |
| `@term amount=v1` |
| `The amount of an invoice is the sum of money that the invoice asks for.` |
| `### Amount limit` |
| `@req limit-amount=v2` |
| `@cites #{amount=v1}` |
| `A conforming program must reject an invoice whose amount is more than 10,000 euros.` |

### 2.4 Names and identity

Each declared item has a name, such as `billing#limit-amount` for the
item of the kind requirement of the example of section 2.3, and an item
of one tree can be the same item as an item of another tree, such as
that item of the kind requirement in two commits (terms `item-name` and
`same-item`).

### 2.5 Decision records and finding classes

A decision record, such as the record `code-comments`, records one
standing practice of a repository or one choice with its reason, and a
repository can declare finding classes of its own (terms
`decision-record`, `finding-class`, and `declared-finding-class`).

### 2.6 Conformance vectors

Each conformance vector belongs to the vector set of one item of the
kind specification or of one item of the kind design, and to one group
of conformance vectors of that vector set (terms `conformance-vector`,
`conformance-vector-group`, and `vector-set`).

A test that checks code against the conformance vectors of a group of
conformance vectors can cite that group of conformance vectors with
`@verifies`:

```python
# @verifies data-forms#toml[offsets][*]=v2
def test_offsets(vector):
    ...
```

### 2.7 Tests, sites, and external items

Tests, such as a test function, sites, such as one comment in code that
has a citation, and external items, such as the issue `gh/42`, are items
that no declaration declares, and the test evidence of an execution of
test runners says which tests passed and which failed (terms `test`,
`test-evidence`, `site`, and `external-item`).

### 2.8 Edges

A citation entry or an inline citation gives an edge of one kind of
edge, such as `verifies`, from the item in which it stands to the item
that it names (terms `edge`, `edge-source`, `cites-edge`,
`satisfies-edge`, `verifies-edge`, `refines-edge`, and
`supersedes-edge`).

Only a `supersedes` edge says that one declared item is to replace
another. A `supersedes` edge from an item of the kind design whose
citation entry the production `every-part` of Identifiers matches, such
as `@supersedes docs=v3#*` in the tag lines of the design `media`, says
two things. The item of the kind design `media` is to replace the item
of the kind design `docs`, which the label `v3` pins. And each item of
the kind specification, each item of the kind requirement, and each
term whose name is `docs`, `#`, and a part name p, such as `docs#x`, is
to be replaced by the declared item of the same kind of item that
`media` holds and whose name is `media`, `#`, and p, such as `media#x`,
when `media` holds one.

### 2.9 Revisions and pins

The revised content of an item is the part of the item that its label
covers, such as the text of an item of the kind requirement, and the
edge of `@cites billing#limit-amount=v2` rests on the revised content
that `billing#limit-amount` has with the label `v2` (terms
`revised-content`, `item-revision`, and `pinned-edge`).

### 2.10 Tasks and plans

A task is one piece of work that one person or one agent can finish
alone, with promises such as `verifies billing#limit-amount`, and a plan
is one piece of work that is made up of tasks and plans (terms
`work-item`, `task`, `promise`, `plan`, `wait`, `carried-out-item`,
`work-item-definition`, `delivery-line`, and `task-line`).

### 2.11 The ledger

The ledger of a repository is the sequence of its ledger entries, each a
record of one event, such as one approval that a person gave (terms
`ledger`, `ledger-entry`, `repair`, `definition-entry`, `judgment`, and
`job-record`).

### 2.12 States

A state, such as in force, approved, suspect, or done, is a named
condition of an item, an edge, a wait, or a subject of approval, and it
follows from the state inputs alone (terms `state`, `state-input`, and
`subject-of-approval`, the terms of sections 3.48 and 3.50 to 3.61, and
requirement `compute-states-from-artifacts`).

What a program gives while another process changes a state input is a
matter of the quality of an implementation.

### 2.13 Statements of agents

A statement of an agent is a text that an agent writes, such as a line
of a file of a tree, a line of the message of a commit, a ledger entry,
or a message to a person. When its input says that an agent runs it, a
conforming program appends to the ledger no ledger entry other than a
definition entry, and makes no repair (section 4.4). A conforming
program appends a judgment, or makes a repair, only to record a decision
that a person gives it by a confirmation that the standard input, the
arguments, and the environment of the program cannot give (section 4.5).

A session is one execution of an agent on its work. The agent can
declare a task as the work of its session: the declared task of the
session. The brief of a session is the text about the work of the
session that a conforming program gives the agent of that session, in
no state input. A conforming program uses the declared task of a session
for nothing other than the brief of that session (section 4.6).

## 3. Definitions

### 3.1 Items

@term item=v1
@cites #{
    declared-item=v1, term=v1, decision-record=v1,
    declared-finding-class=v1, conformance-vector=v1,
    conformance-vector-group=v1, vector-set=v1, task=v1, plan=v1,
    test=v1, site=v1, external-item=v1,
}

An item is a thing that Sinter traces. Each item has exactly one of
these fourteen kinds of item: the six kinds of a declared item, which
are design, specification, requirement, term, decision record, and
declared finding class; and conformance vector, group of conformance
vectors, vector set, task, plan, test, site, and external item.

### 3.2 Trees

@term tree=v1
@cites {
    files#{path=v1},
    text#{
        byte-sequence=v1, text-of-a-byte-sequence=v1, valid-utf-8=v1,
        line=v1, text=v1,
    },
}

A tree is a set whose members are the files of the tree. A file of a
tree is a valid path with a content, which is a byte sequence. No two
files of a tree have the same valid path. A commit of a git repository
gives one tree, the tree of the commit, and a working tree of a git
repository gives one tree, the tree of the working tree. The text of a
file of a tree is the text of its content, when its content is valid
UTF-8. A line of a file of a tree is a line of that text.

### 3.3 Default branches

@term default-branch=v1
@cites #{person=v1}

The default branch of a git repository is the branch into which the
people who work on the repository bring their work.

### 3.4 People

@term person=v1

A person is a human who works on a repository.

### 3.5 Agents

@term agent=v1
@cites {text#{text=v1}, #{person=v1}}

An agent is a program that uses a language model to write texts, such as
code, as one person runs it. Several people can run one program, and
each of them then runs a different agent. Each agent acts for one
person: the person who runs it.

### 3.6 The job

@term job=v1
@cites {text#{conforming-program=v1}, #{default-branch=v1}}

The job is an execution of a conforming program that continuous
integration starts at each push to the default branch of a repository.

### 3.7 Declared items

@term declared-item=v1
@cites {
    identifiers#{declaration=v1, sinter-tag-word=v1, accept-inputs=v1},
    text#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, result=v1,
    },
    #{tree=v1, parameter=v1},
}

A declared item is what a declaration declares. A declared item takes up
a part of one file of a tree; that part has its declaration. The
declaration word of that declaration alone gives the kind of the
declared item: `@design` gives the kind design, `@spec` the kind
specification, `@req` the kind requirement, `@term` the kind term,
`@decision` the kind decision record, and `@finding-class` the kind
declared finding class. So an item of the kind design is a declared item
whose declaration word is `@design`, an item of the kind specification
is a declared item whose declaration word is `@spec`, and an item of the
kind requirement is a declared item whose declaration word is `@req`. An
item of the kind design is a design. An item of the kind specification
declares one specification of the design of which it is a part, and an
item of the kind requirement declares one requirement of the design of
which it is a part. Only a declaration for which a conforming program of
the design Identifiers gives the result "valid" under the binding of
`external-namespaces` declares a declared item.

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

A term is a declared item whose declaration word is `@term`. It says
what one word or one fixed phrase means. Other items can use that word
or that phrase.

### 3.10 Decision records

@term decision-record=v1
@cites #{declared-item=v1}

A decision record is a declared item whose declaration word is
`@decision`. It records one standing practice of a repository, or one
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
    identifiers#{
        slug=v1, full-name=v1, declaration=v1, segment=v1,
        declaration-line=v1, target=v1,
    },
    #{
        declared-item=v1, containment=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, tree=v1,
    },
}

The name of an item of the kind design, of a decision record, or of a
declared finding class in a tree is the name in the target of its
declaration, which is a slug, such as `billing`. The name of an item of
the kind specification, of an item of the kind requirement, or of a term
in a tree is this:

- when the name in the target of its declaration is a full name, that
  full name;
- when the name in the target of its declaration is one segment and the
  item belongs to an item of the kind design in that tree, the name of
  that item of the kind design, `#`, and that segment, such as
  `billing#amount`;
- otherwise, the name in the target of its declaration.

### 3.14 Vector sets

@term vector-set=v1
@cites {
    data-forms#{test-vector-set=v1, group-form-list=v1},
    #{declared-item=v1, tree=v1},
}

In a tree, each item of the kind design and each item of the kind
specification has at most one vector set: the test-vector set of that
item in that tree, when the tree has one, whether or not the Conformance
section or part of the item gives the forms of a group for each of its
groups.

### 3.15 Conformance vectors

@term conformance-vector=v1
@cites {
    data-forms#{
        vector-line=v1, vector-object=v1, vector-meaning=v1,
        group-form-list=v1,
    },
    text#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, input=v1,
    },
    #{vector-set=v1, declared-item=v1, containment=v1},
}

Each vector line of a vector set is the vector line of one conformance
vector of that vector set, and the vector set has no other conformance
vector. The number of a conformance vector is the number of its vector
line. When the object of its vector line states a vector of the
specification that the item of its vector set declares, or of the design
that is that item, by the forms of its group, the conformance vector
says that vector: for the vector set of an item of the kind
specification, an input, or several inputs, of a
conforming program of the specification that the item declares, and what
the requirements of that specification oblige that program to give for
them; for the vector set of an item of the kind design, an input, or
several inputs, of a conforming program of that design, and what the
items of the kind requirement that the design holds directly oblige that
program to give for them. Otherwise, the conformance vector says no
vector.

### 3.16 Groups of conformance vectors

@term conformance-vector-group=v1
@cites {
    data-forms#{vector-line=v1, vector-object=v1},
    #{vector-set=v1, conformance-vector=v1},
}

For each group that a vector line of a vector set has as the value of
the member `group`, the set of the conformance vectors of that vector
set whose vector lines have that group as the value of the member
`group` is a group of conformance vectors of that vector set, and its
name is that group. A vector set has no other group of conformance
vectors.

### 3.17 Identity of items across trees

@term same-item=v1
@cites {
    files#{path=v1},
    #{
        item=v1, declared-item=v1, item-name=v1, conformance-vector=v1,
        vector-set=v1, conformance-vector-group=v1, test=v1, tree=v1,
    },
}

An item of one tree and an item of another tree are the same item
when, and only when, one of these is true:

- both are declared items, with the same kind of item and the same
  name;
- both are conformance vectors, with the same number, and their vector
  sets are the same item;
- both are groups of conformance vectors, with the same name, and their
  vector sets are the same item;
- both are vector sets, of items of the kind specification that are the
  same item, or of items of the kind design that are the same item;
- both are tests, the files of the two tests have the same valid path,
  and the names of the two tests are equal.

### 3.18 Tests

@term test=v1
@cites {identifiers#{declaration=v1}, #{tree=v1}}

A test is a unit of code that a test runner runs and that can pass or
fail, such as a test function, or a set of such units that the code
groups under one name, such as the tests of one `describe` block. No
declaration declares a test. Each test is in one file of a tree, the
file of the test. Each test has its own name, such as `t` for the test
function `t`. The name of a test is a sequence of own names: the own
names of the tests of which the test is a part, from the outermost to
the innermost, and then the own name of the test. So the test function
`t` in the `describe` block `a` and the test function `t` in the
`describe` block `b` of one file of a tree have different names. The
code of a test is the part of the file of the test that the test takes
up. A comment on a test is a comment that is attached to the code of the
test, such as the comment right before a test function.

### 3.19 Test evidence

@term test-evidence=v1
@cites #{test=v1}

A test result is what a test runner gives for one test that it runs.
Each test result names no test, one test, or more than one test, and it
says the same of each test that it names. The test evidence of one
execution of test runners is the set of the test results of that
execution that say that the tests that they name passed or that those
tests failed.

### 3.20 Sites

@term site=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1, directive=v1},
    text#{line=v1},
    #{declared-item=v1, test=v1, tree=v1},
}

A site is a part of a file of a tree that is outside every declared item
and every comment on a test, and that has a citation, an inline
citation, or an `@ack` line, such as one section of a file of a tree in
markdown, or one comment in code. No two sites of a file of a tree have
a line in common. A site has no name.

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
    identifiers#{
        label=v1, declaration=v1, declaration-line=v1, match=v1,
    },
    data-forms#{vector-line=v1, vector-object=v1, group-form-list=v1},
    text#{text=v1, design=v1},
    #{
        item=v1, declared-item=v1, containment=v1, term=v1,
        conformance-vector=v1, conformance-vector-group=v1,
        vector-set=v1, task=v1, plan=v1, test=v1, site=v1,
        external-item=v1, same-item=v1, tree=v1,
    },
}

The label of a declared item is the text that `label` matches in the
match of its declaration by `declaration-line`, when that match uses
`label`. The label of a conformance vector is the revision of its vector
line, the label of a group of conformance vectors is the revision of the
group line of its vector set whose group is its name, and the label of a
vector set is the revision of its set line. The revised content of an
item is the part of the item that its label covers, or would cover for a
term with no label, such as the text of an item of the kind requirement.
The revised content of a declared item leaves out the `=` and the label
of its own declaration, when its declaration has a label. The revised
content of an item of the kind design is the item of the kind design
without the declared items that it holds. The revised content of an item
of the kind specification is that item with the declared items that it
holds, without the `=` and the label of the declaration of each of those
declared items that has a label. Two revised contents of the same
declared item in two trees are the same revised content when, and only
when, the measure of revised content that a design names gives the same
value for that declared item in the two trees. The revised content of a
conformance vector is the members `group`, `input`, `result`, and
`values` of the object of its vector line, with the text of the forms of
its group, and the revised content of a group of conformance vectors or
of a vector set is the revised contents of its conformance vectors. Each
declared item, each conformance vector, each group of conformance
vectors, and each vector set has a revised content. A task, a plan, a
test, a site, and an external item have no revised content.

### 3.23 Revisions of items

@term item-revision=v1
@cites {
    identifiers#{
        label=v1, declaration=v1, declaration-line=v1, match=v1,
    },
    text#{text=v1},
    #{revised-content=v1, tree=v1, item=v1, term=v1},
}

A revision of an item is a label that the item has, and it names the
revised content that the item has with that label in a given tree. The
current revision of an item in a tree is the label that the item has in
that tree, whatever its revised content, such as `v2`, the text that
`label` matches in the match of the declaration `@req limit-amount=v2`
by `declaration-line`. A term with no label has a revised content and no
revision. An item that has no revised content has no revision.

### 3.24 Edges

@term edge=v1
@cites {
    identifiers#{
        citation=v1, citation-entry=v1, sinter-tag-word=v1,
        inline-citation=v1, accept-inputs=v1,
    },
    text#{design=v1, conforming-program=v1, result=v1},
    #{
        item=v1, tree=v1, edge-source=v1, item-name=v1,
        external-item=v1, parameter=v1,
    },
}

An edge is a relation of one kind of edge from its source to its cited
item; an edge has at most one source and at most one cited item. The
kinds of edge are these five: `cites`, `satisfies`, `verifies`,
`refines`, and `supersedes`. A citation or an inline citation gives
edges only when a conforming program of the design Identifiers gives the
result "valid" for it under the binding of `external-namespaces`. Each
citation entry of such a citation gives one edge, whatever the kinds of
item of its source and its cited item, and the kind of edge of that edge
is the citation word of the citation without its `@`. Each such inline
citation gives one edge, whose kind of edge is `cites`. The source of an
edge in a tree is the item in which the citation or the inline citation
that gives the edge stands in that tree. When that citation or inline
citation stands in no item in that tree, the edge has no source in that
tree. The cited item of an edge in a tree is the item that its citation
entry, or its inline citation, names in that tree. When the citation
entry or the inline citation names no item in that tree, the edge has no
cited item in that tree. A kind of edge is for some kinds of item as its
source and as its cited item. An edge says what its kind of edge says
when, and only when, its source and its cited item are of those kinds;
another edge of that kind says nothing.

### 3.25 Where lines and citations stand

@term edge-source=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1},
    text#{line=v1},
    #{declared-item=v1, test=v1, site=v1, tree=v1, item=v1},
}

A line of a file of a tree, a citation, or an inline citation stands in
one item, or in none: in the innermost declared item of which it is a
part (the one of which it is a part and that has no other such declared
item in its part of the file of the tree); otherwise, in the innermost
test such that a comment on that test has it (the one such test that has
no other such test in its code); otherwise, in the site that has it;
otherwise, in no item.

### 3.26 Pinned edges

@term pinned-edge=v1
@cites {
    identifiers#{
        revision=v1, label=v1, citation-entry=v1, inline-citation=v1,
        citation-line=v1, inline-destination=v1, destination=v1,
        match=v1,
    },
    text#{text=v1},
    #{edge=v1, item-revision=v1, revised-content=v1},
}

The revision of a citation entry is the text that `revision` matches in
the match of the citation entry, when that match uses `revision`;
otherwise, it is the text that `label` matches in that match, when that
match uses `label`. A citation entry whose match uses neither `revision`
nor `label` has no revision. The revision of an inline citation is the
text that `revision` matches in the match of its destination by
`inline-destination`. An inline citation whose match does not use
`revision` has no revision. An edge is pinned when, and only when, the
revision of its citation entry, or the revision of its inline citation,
is a label. That label is the label of the edge. A pinned edge is a
relation to the revised content of its cited item that its label names.
An edge that is not pinned is a relation to its cited item at each
revision of the cited item.

### 3.27 Edges of the kind `cites`

@term cites-edge=v1
@cites #{
    edge=v1, declared-item=v1, test=v1, site=v1, external-item=v1,
    conformance-vector=v1, conformance-vector-group=v1, vector-set=v1,
}

A `cites` edge says that its source refers to its cited item and rests
on what the cited item says. The kind of edge `cites` is for a declared
item, a test, or a site as its source, and for a declared item, an
external item, a conformance vector, a group of conformance vectors, or
a vector set as its cited item.

### 3.28 Edges of the kind `satisfies`

@term satisfies-edge=v1
@cites #{edge=v1, declared-item=v1, test=v1, site=v1}

A `satisfies` edge says that its source does what its cited item says.
The kind of edge `satisfies` is for a declared item, a test, or a site
as its source, and for an item of the kind requirement as its cited
item.

### 3.29 Edges of the kind `verifies`

@term verifies-edge=v1
@cites {
    text#{input=v1, conforming-program=v1, design=v1, specification=v1},
    #{
        edge=v1, declared-item=v1, test=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1,
    },
}

A `verifies` edge says that its source checks code. The kind of edge
`verifies` is for a test as its source, and for an item of the kind
requirement, a conformance vector, a group of conformance vectors, or a
vector set as its cited item. When its cited item is an item of the kind
requirement, the edge says that the code that the source runs meets that
item. When its cited item is a conformance vector, the edge says that
the code that the source runs gives what that conformance vector says
that a conforming program of its specification or its design gives,
which is nothing when that conformance vector says no vector. When its
cited item is a group of conformance vectors or a vector set, the edge
says this of each conformance vector in it.

### 3.30 Edges of the kind `refines`

@term refines-edge=v1
@cites #{edge=v1, declared-item=v1}

A `refines` edge says that its source says all or part of its cited item
in more detail. The kind of edge `refines` is for an item of the kind
requirement, specification, or design as its source, and for an item of
the kind requirement, specification, or design as its cited item.

### 3.31 Edges of the kind `supersedes`

@term supersedes-edge=v1
@cites {
    identifiers#{citation-entry=v1, citation-line=v1, part-name=v1},
    #{
        item=v1, edge=v1, declared-item=v1, containment=v1,
        item-name=v1, term=v1,
    },
}

A `supersedes` edge says that its source is to replace its cited item.
The kind of edge `supersedes` is for a declared item as its source, and
for a declared item of the same kind of item as its cited item. When the
production `every-part` matches the citation entry of a `supersedes`
edge, the kind of edge is for an item of the kind design as its source
and as its cited item, and the edge also says this: each item of the
kind specification, each item of the kind requirement, and each term
whose name is the name of the cited item, `#`, and a part name p is to
be replaced by the declared item of the same kind of item that the
source holds and whose name is the name of the source, `#`, and p, when
the source holds one. Only a `supersedes` edge says that one declared
item is to replace another.

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
    #{person=v1, agent=v1, external-item=v1, tree=v1},
}

A task is one piece of work that one person or one agent can finish
alone. The work of a task is what people and agents change in the trees
of the repository to finish the task. The paths of a task are a path
set, whose set has the valid paths of the files of a tree that the work
of the task is to add, change, or remove. A task names at most one
external item, which can say what the work is, and several tasks can
name one external item. A task has no description of its own and no
branch.

### 3.34 Promises

@term promise=v1
@cites {
    identifiers#{citation=v1},
    files#{path=v1, path-set-membership=v1},
    data-forms#{group-form-list=v1},
    text#{requirement=v1, design=v1},
    #{
        task=v1, edge=v1, declared-item=v1, item-name=v1, test=v1,
        tree=v1, test-evidence=v1, satisfies-edge=v1, verifies-edge=v1,
        suspect-edge=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1,
    },
}

A promise of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and the name of an item of the kind requirement. It links
the task to the item of the kind requirement that has that name: the
task promises an edge of that kind of edge to that item, from a citation
in a file of a tree whose valid path is in the set of the paths of the
task. A `verifies` edge from such a citation to a conformance vector, a
group of conformance vectors, or a vector set is such an edge too, when
its cited item is, or has in it, a conformance vector that says a
vector, and among the requirements of whose group is the requirement
that that item of the kind requirement declares. The
promise is kept in a tree when, and only when, that tree has such an
edge, and the edge says what its kind of edge says, and the edge is not
suspect in that tree, and, for a `verifies` promise, test evidence of an
execution of test runners on the code of that tree shows that the test
that is the source of that edge passed. Test evidence shows that a test
of which no other test is a part passed when, and only when, that test
evidence has a test result that names that test and says that it
passed, and none that says that it failed. Test evidence shows that a
test of which one or more other tests are a part passed when, and only
when, the rule that a design names for such a test gives that that test
passed, from the test results that name that test or one of those other
tests.

### 3.35 Plans

@term plan=v1
@cites #{task=v1}

A plan is one piece of work that is made up of tasks and plans.

### 3.36 Waits

@term wait=v1
@cites #{work-item=v1}

A wait is a relation from one work item, the waiting item, to another
work item, the work item that it waits for.

### 3.37 What a plan carries out

@term carried-out-item=v1
@cites #{plan=v1, item-name=v1, declared-item=v1, task=v1}

A plan carries out a set of items of the kind requirement,
specification, or design: the work of the tasks that make up the plan,
directly or through other plans, is for them. The plan names each of
them by its name.

### 3.38 Definitions of work items

@term work-item-definition=v1
@cites #{
    work-item=v1, task=v1, promise=v1, plan=v1, wait=v1,
    carried-out-item=v1, external-item=v1, declared-item=v1,
}

A definition of a task is a display name, paths, promises, at most one
external item, at most one plan, and waits. A definition of a plan is a
display name, at most one plan, waits, and the items of the kind
requirement, specification, and design that the plan carries out. Each
alteration of a definition gives a new definition. The plan of a work
item in a definition is the plan, or none, that the definition names.
The waits of a work item in a definition are the waits from the work
item that the definition names. The work item id of a work item is not
part of a definition.

### 3.39 Delivery lines

@term delivery-line=v1
@cites {
    text#{line=v1},
    #{task=v1, work-item=v1, work-item-definition=v1},
}

A delivery line is a line of the message of a commit that says that the
commit completes the work of one task. It names the task by its work
item id, and it names definitions of the task.

### 3.40 Task lines

@term task-line=v1
@cites {text#{line=v1}, #{task=v1, work-item=v1}}

A task line is a line of the message of a commit that names one task by
its work item id, and that says that the commit does part of the work of
the task without finishing it.

### 3.41 Ledger entries

@term ledger-entry=v1
@cites #{person=v1, agent=v1, job=v1, task=v1, plan=v1}

A ledger entry is a record of one event, such as one approval that a
person gave, or one observation of the job. Each ledger entry has one
of these eight kinds of ledger entry: `task`, `plan`, `approval`,
`decline`, `done`, `abandoned`, `delivered`, and `void`. A ledger entry
can record a writer: the person, the agent, or the job that, as the
ledger entry says, wrote it. When the writer that a ledger entry records
is an agent, the ledger entry also records a person: the person for
whom, as the ledger entry says, that agent acts. A ledger entry can also
record a branch: the branch from which, as the ledger entry says, it was
written. A ledger entry can also record a time.

### 3.42 The ledger

@term ledger=v1
@cites {text#{whole-number=v1}, #{ledger-entry=v1}}

The ledger of a repository is a sequence of ledger entries. Each ledger
entry other than a `void` ledger entry is appended at the end of the
ledger of one clone of the repository: after each ledger entry that is
in that ledger at that time. Of two ledger entries that were appended to
one ledger, the one that was appended later comes later in the order of
the ledger, whatever times the two ledger entries record. A point of a
ledger is given by the ledger entries before it: the first n ledger
entries of the ledger, for a whole number n of 0 or more. The point of a
ledger entry is the point right before it. A pull of ledger entries is a
write that a clone of the repository makes to its own ledger: it takes
the ledger entries, `void` ledger entries included, that the ledger of
another clone has, and puts them first in its ledger. In a push of
ledger entries, a clone puts ledger entries of its ledger after the
ledger entries of the ledger of another clone. Pulls of ledger entries
and pushes of ledger entries are not appending.

### 3.43 Repairs and voids

@term repair=v1
@cites #{ledger=v1, ledger-entry=v1}

A repair is a write to the ledger of a repository, other than an append,
a pull of ledger entries, or a push of ledger entries, that removes zero
or more ledger entries from that ledger, and that puts one `void` ledger
entry, a void, for each ledger entry that it removes, where that ledger
entry was: after each ledger entry that came before the removed one, and
before each ledger entry that came after it. A void records that a
repair removed one ledger entry, and the reason for the removal.

### 3.44 Definition entries

@term definition-entry=v1
@cites #{
    ledger-entry=v1, work-item=v1, task=v1, plan=v1,
    work-item-definition=v1, judgment=v1,
}

A definition entry is a ledger entry of the kind `task` or `plan`. It
names one work item, its work item, by its work item id. Each definition
entry records one whole definition of its work item: the first
definition of the work item, or the new definition that an alteration of
a definition gives. A `task` ledger entry records a definition of a
task, and a `plan` ledger entry records a definition of a plan. A
definition entry records no judgment.

### 3.45 Subjects of approval

@term subject-of-approval=v1
@cites #{
    person=v1, declared-item=v1, term=v1, decision-record=v1,
    containment=v1, revised-content=v1, same-item=v1, tree=v1,
}

A subject of approval is a unit that a person approves, or that the
merge approves, as a whole. Each subject of approval is one of these: an
item of the kind design, without the declared items that it holds; an
item of the kind specification, with the items of the kind requirement
and the terms that it holds; an item of the kind requirement that an
item of the kind design holds directly; a term that an item of the kind
design holds directly; or a decision record. These five are the kinds of
subject of approval, and the kind of a subject of approval is the one of
the five that it is. The declared item of a subject of approval is the
item of the kind design, for the first kind, and otherwise the item of
the kind specification, the item of the kind requirement, the term, or
the decision record that the subject of approval is. The subject of
approval of a declared item is the subject of approval whose declared
item it is, when there is one. The subject of approval of an item of the
kind requirement or of a term that an item of the kind specification
holds is the subject of approval of that item of the kind specification.
Each other declared item has no subject of approval. The revised content
of a subject of approval is the revised content of its declared item. A
subject of approval of one tree and a subject of approval of another
tree are the same subject of approval when, and only when, their
declared items are the same item.

### 3.46 Judgments

@term judgment=v1
@cites #{
    ledger-entry=v1, person=v1, subject-of-approval=v1,
    revised-content=v1, task=v1, plan=v1, promise=v1, item-revision=v1,
    declared-item=v1,
}

A judgment is a ledger entry that records a decision of a person. A
judgment is one of these four kinds of ledger entry:

- An `approval` ledger entry records that a person approved one revised
  content of one subject of approval.
- A `decline` ledger entry records that a person declined one revised
  content of one subject of approval.
- A `done` ledger entry records that a person judged the work of one
  task finished, and, for each item of the kind requirement that the
  task promises, the revision of that item at which the person judged
  the work finished.
- An `abandoned` ledger entry records that a person ended one task or
  one plan, and the reason.

### 3.47 Records of the job

@term job-record=v1
@cites #{
    ledger-entry=v1, job=v1, delivery-line=v1, promise=v1, task=v1,
    work-item-definition=v1, item-revision=v1, declared-item=v1,
}

A record of the job is a ledger entry of the kind `delivered`: it
records what the job observed about one delivery line, and it is a
`delivered` ledger entry of the task that the line names. For each
definition of that task that the line names, and for each promise of
that definition, it records the revision of the promised item of the
kind requirement, and whether the promise was kept.

### 3.48 The states of work items

@term work-item-state=v1
@cites #{
    ledger=v1, ledger-entry=v1, definition-entry=v1, work-item=v1,
    task=v1, plan=v1, work-item-definition=v1, promise=v1, person=v1,
    job=v1, job-record=v1, delivery-line=v1, state=v1, judgment=v1,
}

At each point of a ledger, the ledger entries before that point give
the current definition of each work item, the work items that exist,
the parts of each plan, and the state of each task and each plan:

1. An accepted definition entry is a definition entry that gives its
   work item the definition that it records. The current definition of a
   work item at a point is the definition that the last accepted
   definition entry of the work item before that point, in the order of
   the ledger, records. A work item exists at a point when, and only
   when, it has a current definition at that point.
2. A work item is a part of a plan at a point when, and only when, its
   current definition names that plan as its plan, unless the work item
   is abandoned at that point, or the plan was abandoned, before that
   point, while the work item was not done. A part of a plan is a task
   or a plan. A work item is under a plan at a point when, and only
   when, it is a part of the plan, or under a part of the plan, at that
   point.
3. Each task that exists at a point is in one of these four states at
   that point:
   - abandoned, when a person ended the task before it was done;
   - done, when, while the task was not abandoned, a person judged the
     work of the task finished, or the job observed, in a `delivered`
     ledger entry, that a delivery line of the task named the definition
     of the task that was current at the point of that `delivered`
     ledger entry, and that each promise of that definition was kept;
   - delivered, when the job observed, in a `delivered` ledger entry, a
     delivery line of the task, and the task is neither done nor
     abandoned;
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
@cites #{
    item=v1, edge=v1, wait=v1, subject-of-approval=v1, tree=v1,
    ledger=v1,
}

A state is a named condition of an item, an edge, a wait, or a subject
of approval, in a tree, at a point of a ledger, or in a tree at a point
of a ledger.

### 3.50 Deprecated

@term deprecated-item=v1
@cites {
    identifiers#{status-tag=v1, accept-inputs=v1},
    text#{design=v1, conforming-program=v1, result=v1},
    #{
        declared-item=v1, term=v1, decision-record=v1, tree=v1,
        edge-source=v1, declared-finding-class=v1, parameter=v1,
    },
}

An item of the kind design, specification, or requirement, a term, a
decision record, or a declared finding class is deprecated in a tree
when, and only when, a `@deprecated` status tag for which a conforming
program of the design Identifiers gives the result "valid" under the
binding of `external-namespaces` stands in it in that tree. That status
tag says that the item no longer applies and that nothing replaces it.

### 3.51 Rejected

@term rejected-record=v1
@cites {
    identifiers#{status-tag=v1, accept-inputs=v1},
    text#{design=v1, conforming-program=v1, result=v1},
    #{decision-record=v1, tree=v1, edge-source=v1, parameter=v1},
}

A decision record is rejected in a tree when, and only when, a
`@rejected` status tag for which a conforming program of the design
Identifiers gives the result "valid" under the binding of
`external-namespaces` stands in it in that tree. That status tag says
that the choice of the record was considered and not made.

### 3.52 Deferred

@term deferred-record=v1
@cites {
    identifiers#{status-tag=v1, accept-inputs=v1},
    text#{design=v1, conforming-program=v1, result=v1},
    #{decision-record=v1, tree=v1, edge-source=v1, parameter=v1},
}

A decision record is deferred in a tree when, and only when, a
`@deferred` status tag for which a conforming program of the design
Identifiers gives the result "valid" under the binding of
`external-namespaces` stands in it in that tree. That status tag says
that the choice of the record is not made yet.

### 3.53 Approved and declined

@term approval-state=v1
@cites {
    text#{design=v1},
    #{
        subject-of-approval=v1, person=v1, revised-content=v1,
        containment=v1, term=v1, declared-item=v1, default-branch=v1,
        tree=v1, ledger=v1, state=v1, ledger-entry=v1, judgment=v1,
        parameter=v1,
    },
}

In a repository, a binding of a parameter that a design names gives the
kinds of subject of approval that need approval by a person. Each other
kind of subject of approval needs no approval by a person. In a tree, at
a point of a ledger, these are the states approved and declined:

- A subject of approval of a kind that needs approval by a person is
  approved only when an `approval` ledger entry before that point
  records that a person approved the revised content that the subject
  of approval has in that tree. It is declined only when a `decline`
  ledger entry before that point records that a person declined that
  revised content. It is never both approved and declined.
- A subject of approval of a kind that needs no approval by a person is
  not declined. It is approved when, and only when, the rule that a
  design names for merges gives that the revised content that it has in
  that tree has merged into the default branch.
- A declared item other than an item of the kind design is approved,
  or declined, when, and only when, its subject of approval is approved,
  or declined.
- An item of the kind design is approved when, and only when, that item
  of the kind design without the declared items that it holds, each item
  of the kind specification that it holds, and each item of the kind
  requirement and each term that it holds directly are approved.

### 3.54 Drafts

@term draft-design=v1
@cites #{declared-item=v1, approval-state=v1, tree=v1, ledger=v1}

An item of the kind design is a draft in a tree, at a point of a ledger,
when, and only when, it is not approved in that tree at that point.

### 3.55 Effective edges of the kind `supersedes`

@term effective-supersedes-edge=v1
@cites #{
    edge=v1, supersedes-edge=v1, deprecated-item=v1, rejected-record=v1,
    deferred-record=v1, approval-state=v1, declared-finding-class=v1,
    tree=v1, ledger=v1, item=v1, containment=v1, subject-of-approval=v1,
}

A `supersedes` edge is effective in a tree, at a point of a ledger,
when, and only when, the edge says what the kind of edge `supersedes`
says in that tree (its source and its cited item are of the kinds of
item for which that kind of edge is); neither its source nor an item
that holds its source is deprecated, rejected, or deferred in that tree;
and its source is a declared finding class, which has no subject of
approval, or is approved in that tree at that point. An effective
`supersedes` edge is one whose replacement has taken effect.

### 3.56 Retired

@term retired-item=v1
@cites #{
    declared-item=v1, deprecated-item=v1, rejected-record=v1,
    deferred-record=v1, effective-supersedes-edge=v1, edge=v1,
    containment=v1, tree=v1, ledger=v1,
}

A declared item is retired in a tree, at a point of a ledger, when, and
only when, it is deprecated, rejected, or deferred in that tree; it is
the cited item of an effective `supersedes` edge in that tree at that
point; or it belongs to a retired item of the kind design or to a
retired item of the kind specification in that tree at that point. A
retired item no longer applies in that tree at that point.

### 3.57 In force

@term in-force-item=v1
@cites #{declared-item=v1, retired-item=v1, tree=v1, ledger=v1}

A declared item is in force in a tree, at a point of a ledger, when,
and only when, it is not retired in that tree at that point.

### 3.58 Suspect

@term suspect-edge=v1
@cites #{pinned-edge=v1, edge=v1, item-revision=v1, tree=v1}

An edge is suspect in a tree when, and only when, it is pinned, it has a
cited item in that tree, and that item has no current revision in that
tree or a current revision other than the label of the edge.

### 3.59 Met waits

@term met-wait=v1
@cites #{wait=v1, work-item=v1, work-item-state=v1, ledger=v1}

A wait says that the work of the waiting item is to start only after the
work item that it waits for is done. A wait is met at a point of a
ledger when, and only when, the work item that it waits for is done at
that point.

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
@cites #{
    declared-item=v1, containment=v1, task=v1, plan=v1, promise=v1,
    carried-out-item=v1, work-item-definition=v1, work-item-state=v1,
    ledger=v1, item-revision=v1, item-name=v1, tree=v1, judgment=v1,
    job-record=v1,
}

An item of the kind requirement is accounted for in a tree, at a point
of a ledger, when, and only when, one of these is true at that point:

- the current definition of an unfinished task has a promise whose
  name is the name of the item in that tree;
- the current definition of an open plan names, as carried out, the
  name that the item, the item of the kind specification that holds it,
  or the item of the kind design that holds it has in that tree;
- a done task promised the item, and the work of that task was finished
  at the current revision of the item in that tree.

### 3.62 Parameters

@term parameter=v1
@cites {text#{design=v1}, identifiers#{binding=v1}}

A parameter is a word, such as `external-namespaces`, whose value a
design leaves open. A binding of a parameter is a value that
configuration gives for the parameter. A binding of the parameter
`external-namespaces` is a binding as Identifiers defines it.

### 3.63 State inputs

@term state-input=v1
@cites {
    text#{design=v1},
    #{
        tree=v1, default-branch=v1, delivery-line=v1, task-line=v1,
        ledger=v1, test-evidence=v1, parameter=v1,
    },
}

A state input of a repository is one of these things: which commits the
repository has, each with its parents and its tree; the commit to which
each branch points; the commit of the default branch; the tree of each
working tree; the delivery lines and the task lines of the messages of
commits; the ledger, in its order; test evidence; or the bindings of the
parameters that designs name.

## 4. Requirements

### 4.1 The sources of states

@req compute-states-from-artifacts=v1
@cites {
    text#{conforming-program=v1, input=v1},
    #{
        state=v1, state-input=v1, item=v1, edge=v1, wait=v1,
        subject-of-approval=v1,
    },
}

A conforming program must give the same states to each item, edge, wait,
and subject of approval for which it gives them, for two inputs that
agree in each state input, as each state input is when the program gives
the states, and that no other process changes while the program runs.

### 4.2 The same treatment of each ledger entry

@req treat-ledger-entries-alike=v1
@cites {
    text#{conforming-program=v1, input=v1},
    #{
        state=v1, item=v1, edge=v1, wait=v1, subject-of-approval=v1,
        ledger-entry=v1, person=v1,
    },
}

A conforming program must give the same states to each item, edge, wait,
and subject of approval for which it gives them, for two inputs that
differ only in the writers, the persons, the branches, and the times
that their ledger entries record, and that no other process changes
while the program runs.

### 4.3 The ways in which a ledger changes

@req change-ledger-only-by-appends=v1
@cites {
    text#{conforming-program=v1},
    #{ledger=v1, ledger-entry=v1, repair=v1},
}

A conforming program must change the ledger only by appending ledger
entries, by making repairs, and by pulls of ledger entries and pushes of
ledger entries between clones of the repository.

### 4.4 The ledger entries that agents write

@req write-only-definitions-for-agents=v1
@cites {
    text#{conforming-program=v1, input=v1},
    #{
        agent=v1, ledger=v1, definition-entry=v1, repair=v1,
        ledger-entry=v1,
    },
}

When its input says that an agent runs it, a conforming program must
append to the ledger no ledger entry other than a definition entry, and
make no repair.

### 4.5 The judgments and repairs that persons give

@req write-judgments-only-for-persons=v1
@cites {
    text#{conforming-program=v1},
    #{judgment=v1, person=v1, ledger=v1, repair=v1},
}

A conforming program must append a judgment to the ledger, or make a
repair, only to record a decision that a person gives it by a
confirmation that the standard input, the arguments, and the environment
of the program cannot give.

### 4.6 The use of declared tasks

@req use-declared-tasks-only-for-briefs=v1
@cites {
    text#{text=v1, conforming-program=v1},
    #{agent=v1, task=v1, state-input=v1},
}

A session is one execution of an agent on its work. The declared task of
a session is the task that the agent declares as the work of that
session. The brief of a session is the text about the work of the
session that a conforming program gives the agent of that session, in
no state input. A conforming program must use the declared task of a
session for nothing other than the brief of that session.

## 5. Conformance

A program, or a part of a program, conforms to the design Ontology when
it meets every requirement of section 4. No requirement of section 4
names a result for an input, so there are no conformance vectors.
