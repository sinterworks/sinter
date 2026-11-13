<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
@cites files=v1
@cites data-forms=v1
Specifies the kinds of item that Sinter traces, with their names, revisions, and edges; trees and the default branch; containment; work items and their relations; the ledger and the actors that write it; the names and meanings of states; parameters and their bindings; and requirements for conforming programs on the inputs on which states depend, on the treatment of ledger entries, on the changes that they make to the ledger when an agent runs them, on the judgments that they append, and on the use of declared tasks.

Sinter traces the items of a repository, such as items of the kind
design, specification, and requirement, terms, decision records, tests,
tasks, plans, and the items outside it that external ids name. A
citation, such as `@verifies billing#limit-amount=v2` in a comment on a
test, gives an edge: a relation from its source, here the test, to its
cited item, here the item of the kind requirement
`billing#limit-amount`. The label `v2` pins the edge to one revised
content of that item. The ledger of a repository records events, such as
the approval that a person gave to one revised content. Each state, such
as in force, approved, suspect, or done, depends only on the things that
section 2.12 lists, the state inputs, such as the trees of the commits
of the repository, its ledger, test evidence, and the bindings of the
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
| repository | a git repository |
| commit, message of a commit, parent, branch, working tree, push, pull request | the thing of git, or of a host of git repositories, that has this name |
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
| [same item](sinter:#same-item=v1) | of two items of two trees: two declared items with the same kind of item and the same name; two conformance vectors with the same number in vector sets that are the same item; two groups of conformance vectors with the same name in vector sets that are the same item; two vector sets of items of the kind specification, or of items of the kind design, that are the same item; or two tests such that the file of the one test and the file of the other test have the same valid path, and the names of the two tests are equal |
| [conformance vector](sinter:#conformance-vector=v1) | the vector that one vector line of a vector set states by the forms of its group: an input, or several inputs, of a conforming program of the specification or the design of the vector set, and what the requirements of that specification, or the requirements that the design holds directly, oblige that program to give for them |
| [vector line of a conformance vector](sinter:#conformance-vector=v1) | the vector line that states the conformance vector |
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
| [test evidence](sinter:#test-evidence=v1) | the test results of one execution of test runners that say that their test passed or that it failed |
| [test result](sinter:#test-evidence=v1) | what a test runner gives for one test that it runs; each test result names its test |
| [site](sinter:#site=v1) | a part of a file of a tree that is outside every declared item and every comment on a test, and that has a citation, an inline citation, or an `@ack` line, such as one section of a file of a tree in markdown, or one comment in code; no two sites of a file of a tree have a line in common |
| [external item](sinter:#external-item=v1) | a thing outside the repository that an external id names, such as an issue or a published standard |
| [label of an item](sinter:#revised-content=v1), [current revision](sinter:#item-revision=v1) | the label that an item has in a given tree: for a declared item, the text that `label` matches in its declaration, when its declaration has one, such as `v2` in the declaration `@req limit-amount=v2`; for a conformance vector, a group of conformance vectors, or a vector set, the revision of its vector line, its group line, or its set line |
| [revised content](sinter:#revised-content=v1) | the part of an item that its label covers, such as the text of an item of the kind requirement; for each declared item, without the `=` and the label of its own declaration; also, for an item of the kind design, the item of the kind design without the declared items that it holds; for an item of the kind specification, that item with the declared items that it holds, without the `=` and the label of the declaration of each of those declared items that has a label; for a conformance vector, the conformance vector with the forms of its group |
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
| [keep a promise](sinter:#promise=v1) | a promise is kept in a tree when the tree has the edge that it promises (for `verifies`, also an edge to conformance vectors when the group of one of them names the requirement), from a citation in a file of that tree whose valid path is in the set of the paths of its task, the edge says what its kind of edge says, the edge is not suspect in that tree, and, for `verifies`, test evidence of an execution of test runners on the code of that tree has a test result that names the test that is the source of that edge and says that it passed, and none that says that it failed |
| [plan](sinter:#plan=v1) | one piece of work that is made up of tasks and plans |
| [plan of a work item in a definition](sinter:#work-item-definition=v1) | the plan, or none, that the definition names |
| [wait](sinter:#wait=v1) | a relation from a work item, the waiting item, to another work item, the work item that it waits for |
| [carry out](sinter:#carried-out-item=v1) | a plan carries out the items of the kind requirement, specification, and design that the work of the tasks that make up the plan, directly or through other plans, is for; it names them by their names |
| [definition of a work item](sinter:#work-item-definition=v1) | for a task, a display name, paths, promises, at most one external item, at most one plan, and waits; for a plan, a display name, at most one plan, waits, and the items that the plan carries out; each alteration of a definition gives a new definition |
| change | a set of commits whose work is to merge into the default branch as one unit, such as the commits of a pull request |
| merge (verb) | to bring the work of a change into the default branch, in any way, such as with a commit that has two or more parents, with a squash merge, which adds one commit that brings in all the work of the change, or with a fast-forward merge, which moves the default branch to a commit of the change and adds no commit; work, or a revised content, merges into the default branch when a merge brings it in |
| merge (noun) | one act that brings the work of a change into the default branch, in any way, such as with a commit that has two or more parents, with a squash merge, or with a fast-forward merge |
| [delivery line](sinter:#delivery-line=v1) | a line of the message of a commit that says that the commit completes the work of a task |
| [task line](sinter:#task-line=v1) | a line of the message of a commit that names a task on which the commit does part of the work |
| [ledger](sinter:#ledger=v1) | the sequence of the ledger entries of a repository; each ledger entry other than a void is appended at the end of it |
| [point of a ledger](sinter:#ledger=v1) | a point between two ledger entries, before the first, or after the last |
| [ledger entry](sinter:#ledger-entry=v1) | a record of one event in the ledger, such as one approval |
| [writer of a ledger entry](sinter:#ledger-entry=v1) | the person, the agent, or the job that a ledger entry records as the one that wrote it |
| [repair](sinter:#repair=v1) | a write that removes ledger entries from the ledger of a repository and puts a void in the place of each |
| [void](sinter:#repair=v1) | a ledger entry that takes the place of a ledger entry that a repair removed |
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
| [judgment](sinter:#judgment=v1) | a ledger entry that records a decision of a person, such as an approval |
| [record of the job](sinter:#job-record=v1) | a ledger entry that records what the job observed |
| [state](sinter:#state=v1) | a named condition of an item, an edge, a wait, or a subject of approval, in a tree, at a point of a ledger, or both, such as in force or done |
| [state input](sinter:#state-input=v1) | one of the things on which states depend: which commits the repository has, each with its parents and its tree; the commit to which each branch points; the commit of the default branch; the tree of each working tree; the delivery lines and the task lines of the messages of commits; the ledger, in its order; test evidence; or the bindings of the parameters that designs name |
| [retired](sinter:#retired-item=v1) | a declared item is retired when it is deprecated, rejected, or deferred, when it is the cited item of an effective `supersedes` edge, or when it belongs to a retired item of the kind design or a retired item of the kind specification |
| [in force](sinter:#in-force-item=v1) | a declared item is in force when it is not retired |
| [effective](sinter:#effective-supersedes-edge=v1) | a `supersedes` edge is effective when its replacement has taken effect: the edge says what its kind of edge says, neither its source nor an item that holds its source is deprecated, rejected, or deferred, and its source is a declared finding class or is approved |
| [deprecated](sinter:#deprecated-item=v1), [rejected](sinter:#rejected-record=v1), [deferred](sinter:#deferred-record=v1) | the states that the three status words give, through a status tag that stands in the item |
| [approved, declined](sinter:#approval-state=v1) | a binding of a parameter that a design names gives the kinds of subject of approval that need approval by a person; a subject of approval of such a kind is approved, or declined, only when an `approval`, or a `decline`, ledger entry before the point records that a person approved, or declined, the revised content that it has in the tree, and it is never both approved and declined; a subject of approval of another kind is approved when the revised content that it has in the tree has merged into the default branch, and it is never declined; an item of the kind specification, an item of the kind requirement or a term that an item of the kind design holds directly, and a decision record are each approved, or declined, when their subject of approval is; an item of the kind requirement or a term that an item of the kind specification holds is approved, or declined, when that item of the kind specification is; an item of the kind design is approved when that item of the kind design without the declared items that it holds, each item of the kind specification that it holds, and each item of the kind requirement and each term that it holds directly are approved |
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

An item is a thing that Sinter traces. Each item has one kind of item:

| kind of item | what it is | how it is named | has revisions |
|---|---|---|---|
| design | a declared item whose declaration word is `@design` | a slug, such as `billing` | yes |
| specification | a declared item whose declaration word is `@spec`, which specifies one thing of the part of a system that its design specifies | a full name, such as `billing#invoice`, or a slug (section 2.4) | yes |
| requirement | a declared item whose declaration word is `@req` | a full name, such as `billing#limit-amount`, or a slug (section 2.4) | yes |
| term | a declared item whose declaration word is `@term`, which says what one word or one fixed phrase means | a full name, such as `billing#amount`, or a slug (section 2.4) | when it has a label |
| decision record | a declared item whose declaration word is `@decision`, which records one practice or one choice | a slug, such as `code-comments` | yes |
| declared finding class | a declared item whose declaration word is `@finding-class`, a finding class that a repository declares for itself | a slug, such as `late-fee` | yes |
| conformance vector | the vector that one vector line of a vector set states: an input, or several inputs, of a conforming program of its specification or its design, and what the requirements oblige that program to give for them | its vector set and its number | yes |
| group of conformance vectors | the conformance vectors of one vector set whose vector lines have one group as the value of the member `group` | its vector set and its name | yes |
| vector set | the test-vector set of one item of the kind specification or of one item of the kind design | its item of the kind specification or design | yes |
| task | one piece of work | a work item id | no |
| plan | one piece of work that is made up of tasks and plans | a work item id | no |
| test | a unit of code that a test runner runs | the file of the test and its name | no |
| site | a part of a file of a tree that is outside every declared item and every comment on a test, and that has a citation, an inline citation, or an `@ack` line | no name | no |
| external item | a thing outside the repository | an external id, such as `gh/42` | no |

A declared item is what a declaration declares, such as the requirement
that `@req limit-amount=v2` declares. A declared item takes up a part of
one file of a tree, and that part has its declaration. The declaration
word alone gives the kind of the declared item: `@design` gives the kind
design, `@spec` the kind specification, `@req` the kind requirement,
`@term` the kind term, `@decision` the kind decision record, and
`@finding-class` the kind declared finding class. An item of the kind
design is a design. An item of the kind specification declares one
specification of the design of which it is a part, and an item of the
kind requirement declares one requirement of the design of which it is a
part.

A work item is a task or a plan. No work item is in a file of a tree:
the definition entries of the ledger define each one.

### 2.2 Repositories and actors

A repository is a git repository. A tree is a set whose members are the
files of the tree. A file of a tree is a valid path with a content,
which is a byte sequence, and no two files of a tree have the same valid
path. A commit gives one tree, the tree of the commit, and a working
tree gives one tree, the tree of the working tree. The default branch is
the branch into which the people who work on the repository bring their
work. A change is a set of commits whose work is to merge into the
default branch as one unit, such as the commits of a pull request.

An actor is a person, an agent, or the job. Actors write the ledger
entries that Sinter reads:

- A person is a human who works on a repository.
- An agent is a program that uses a language model to write texts, such
  as code, the message of a commit, or a ledger entry, as one person
  runs it.
  Several people can run one program, and each of them then runs a
  different agent. A coding agent is an example. Each agent acts for one
  person: the person who runs it.
- The job is an execution of a conforming program, such as Sinter, that
  continuous integration starts at each push to the default branch of a
  repository. Continuous integration is a service that runs checks on
  the commits of a repository. The job reads test evidence, and it
  records what it observes about the delivery lines of the commits
  (section 2.10).

### 2.3 Designs, specifications, requirements, and terms

A design is a document that declares, each under a name, obligations and
definitions. Each design specifies one part of a system. A specification
specifies one thing of that part, such as a format, a protocol, or a set
of behaviors. A requirement is an obligation that a design declares
under a name and states with the word must. A term says what one word or
one fixed phrase means. Items of the kind requirement, terms, and other
items can use that word or that phrase. A term puts an obligation on
nothing.

Containment is the relation in which an item of the kind design holds
items of the kind specification, items of the kind requirement, and
terms, and an item of the kind specification holds items of the kind
requirement and terms. Each declared item that an item of the kind
design or an item of the kind specification holds belongs to it. An item
of the kind requirement or a term that an item of the kind specification
holds belongs to the item of the kind design of that item of the kind
specification too. An item of the kind design holds an item of the kind
requirement or a term directly when that item belongs to it and to no
item of the kind specification.

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

Only terms and requirements are normative: a term says what a word or a
fixed phrase means, and a requirement says what each conforming program
of the design must do. The rest of a design and of its
specifications explains the terms and the requirements and gives
examples.

### 2.4 Names and identity

The name of an item of the kind design, of a decision record, and of a
declared finding class is the name in the target of its declaration,
which is a slug, such as `billing`. The name of an item of the kind
specification, of an item of the kind requirement, and of a term
depends on the name in the target of its declaration:

- When the name in the target of its declaration is a full name, such
  as `billing#limit-amount`, its name is that full name.
- When the name in the target of its declaration is one segment, such
  as `limit-amount`, and the item belongs to an item of the kind design,
  its name is the name of that item of the kind design, `#`, and that
  segment, such as `billing#invoice`, `billing#amount`, and
  `billing#limit-amount` in the example of section 2.3.
- Otherwise, its name is the name in the target of its declaration.

A citation entry names an item, such as `billing#limit-amount` in
`@cites billing#limit-amount=v2`, or the external item `gh/42` in
`@cites gh/42`.

An item of one tree and an item of another tree are the same item when
they are declared items with the same kind of item and the same name,
such as the item of the kind requirement `billing#limit-amount` of two
commits. Two conformance vectors are the same item when they have the
same number in vector sets that are the same item. Two groups of
conformance vectors are the same item when they have the same name in
vector sets that are the same item. Two vector sets are the same item
when their items of the kind specification, or their items of the kind
design, are the same item. Two tests are the same item when the files
of the two tests have the same valid path and the names of the two tests
are equal. So an item of the kind requirement that moves to another
part of the same file of a tree, or to another file of a tree, stays
the same item when its name stays the same.

### 2.5 Decision records and finding classes

A decision record records one standing practice of a repository, or
one choice with its reason, such as the record `code-comments`.

A finding is a report of one condition at one part of a repository. A
finding class is a kind of finding, which a slug names. A repository can
declare finding classes of its own. Each such declared finding class is
a declared item.

### 2.6 Conformance vectors

A conformance vector gives an input, or several inputs, of a conforming
program of its specification or its design, and what the requirements
oblige that program to give for them. What a conformance vector gives
follows from the requirements of its specification or its design, and
the conformance vector adds no requirement of its own.

Each conformance vector is given for one item of the kind specification,
or for the items of the kind requirement that one item of the kind
design holds directly. The vector set of an item of the kind
specification, or of an item of the kind design, is its test-vector set
in a tree, as the specification `test-vectors` of Data forms gives it: a
set line, then a group line for each group, then a vector line for each
conformance vector. Each of its vector lines states one conformance
vector by the forms of its group, as Data forms gives them, and that
line is the vector line of the conformance vector. The value of the
member `n` of the object of a vector line is the number of its
conformance vector, a whole number of 1 or more. A group of conformance
vectors is the set of the conformance vectors of one vector set whose
vector lines have one group as the value of the member `group`, and that
group is its name.

A citation entry can name one conformance vector, one group of
conformance vectors, or one vector set. A test that checks code against
the conformance vectors of a group of conformance vectors can cite that
group of conformance vectors with `@verifies`:

```python
# @verifies data-forms#toml[offsets][*]=v2
def test_offsets(vector):
    ...
```

### 2.7 Tests, sites, and external items

A test is a unit of code that a test runner runs and that can pass or
fail, such as a test function. A set of such units that the code groups
under one name, such as the tests of one `describe` block, is a test
too. Each test is in one file of a tree, the file of the test, and it
has its own name, such as `t` for the test function `t`. The name of a
test is a sequence of own names: the own names of the tests of which the
test is a part, from the outermost to the innermost, and then the own
name of the test. So the test function `t` in the `describe` block `a`
and the test function `t` in the `describe` block `b` of one file of a
tree have different names. The code of a test is the part of the file of
the test that the test takes up. A comment on a test is a comment that
is attached to the code of the test, such as the comment right before a
test function. The code names each test, so a test has no declaration. A
test result is what a test runner gives for one test that it runs. Each
test result names its test. The test evidence of one execution of test
runners is the set of the test results of that execution that say that
their test passed or that it failed.

A site is an item with no name. It is a part of a file of a tree that
is outside every declared item and every comment on a test, and that has
a citation, an inline citation, or an `@ack` line, such as one section
of a file of a tree in markdown, or one comment in code. No two sites of
a file of a tree have a line in common.

An external item is an item outside the repository that an external id
names, such as the issue `gh/42` or the standard `rfc/8259`. An external
id names an external item even when nothing outside the repository has
that external id. An external id with `#` and a part name after it, such
as `rfc/8259#section-6`, names a part of such an item, and that part is
an external item too. An external item has no revision.

### 2.8 Edges

An edge is a relation of one kind of edge from its source to its cited
item, and an edge has at most one source and at most one cited item.
A citation or an inline citation gives edges only when a conforming
program of the design Identifiers gives the result "valid" for it under
the binding of `external-namespaces` that is a state input. Each
citation entry of such a citation gives one edge, whatever the kinds of
item of its source and its cited item. The kind of edge is the citation
word without its `@`. The cited item of the edge is the item that the
citation entry names. Each such inline citation, for example
`[the limit](sinter:billing#limit-amount=v2)`, gives one edge of the
kind `cites`, and the name or the external id in its target names the
cited item. When the citation entry or the target names no item, the
edge has no cited item.

A line of a file of a tree, a citation, or an inline citation stands in
one item, or in none: in the innermost declared item of which it is a
part (the one of which it is a part and that has no other such declared
item in its part of the file of the tree); otherwise, in the innermost
test such that a comment on that test has it (the one such test that has
no other such test in its code); otherwise, in the site that has it;
otherwise, in no item. The source of an edge is the item in which its
citation or its inline citation stands. When that citation or inline
citation stands in no item, the edge has no source. So the edge of a
`@verifies` line in a comment on a test has that test as its source, and
the edge of a citation in an item of the kind requirement has that item,
not the item of the kind design that holds it, as its source.

Each kind of edge says one thing, and it is for some kinds of item as
its source and as its cited item. An edge says what its kind of edge
says when, and only when, its source and its cited item are of those
kinds; another edge of that kind says nothing. This table gives what
each kind of edge says and the kinds of item that it is for:

| kind of edge | what it says | its source | its cited item |
|---|---|---|---|
| `cites` | the source refers to the cited item and rests on what the cited item says | a declared item, a test, or a site | a declared item, an external item, a conformance vector, a group of conformance vectors, or a vector set |
| `satisfies` | the source does what the cited item says | a declared item, a test, or a site | an item of the kind requirement |
| `verifies` | the source checks that the code that it runs meets the cited item of the kind requirement, or gives what the cited conformance vector, or each conformance vector in the cited item, says that a conforming program of its specification or its design gives for its input or inputs | a test | an item of the kind requirement, a conformance vector, a group of conformance vectors, or a vector set |
| `refines` | the source says all or part of the cited item in more detail | an item of the kind requirement, specification, or design | an item of the kind requirement, specification, or design |
| `supersedes` | the source is to replace the cited item | a declared item; an item of the kind design when `every-part` matches the citation entry | a declared item of the same kind of item; an item of the kind design when `every-part` matches the citation entry |

The kinds of edge `satisfies` and `verifies` are not for a term as cited
item, because a term puts an obligation on nothing.

No citation entry and no inline citation names a work item, so no edge
has a work item as its cited item. Work items refer to declared items in
the other direction: a task promises items of the kind requirement, and
a plan carries out items of the kind requirement, specification, and
design.

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

Each declared item, conformance vector, group of conformance vectors,
and vector set has a revised content: the part of the item that its
label covers, such as the text of an item of the kind requirement. The
label of a declared item is the text that `label` matches in the match
of its declaration by the production `declaration-line` of Identifiers,
when that match uses `label`, such as `v2` in `@req limit-amount=v2`.
The label of a conformance vector is the revision of its vector line,
the label of a group of conformance vectors is the revision of its group
line, and the label of a vector set is the revision of its set line. The
revised content of a declared item leaves out the `=` and the label of
its own declaration, when its declaration has a label. The revised
content of an item of the kind design is the item of the kind design
without the declared items that it holds. The revised content of an item
of the kind specification is that item with the declared items that it
holds, without the `=` and the label of the declaration of each of those
declared items that has a label. So an alteration of an item
of the kind requirement that an item of the kind specification holds
changes the revised content of that item of the kind specification too.
The revised content of a conformance vector is that conformance vector
with the forms of its group, and the revised content of a group of
conformance vectors or of a vector set is its conformance vectors, each
with the forms of its group. A term with no label has a revised content
and no revision. A task, a plan, a test, a site, and an external item
have no revised content and no revision.

A revision of an item is a label that the item has, and it names the
revised content that the item has with that label in a given tree. The
current revision of an item in a tree is the label that the item has in
that tree, whatever its revised content, such as `v2` for the
declaration `@req limit-amount=v2`.

An edge is pinned when the revision of the citation entry or of the
inline citation that gives it is a label: the label of the edge. A
pinned edge is a relation to the revised content of its cited item that
its label names. So `@cites billing#limit-amount=v2` rests on the
revised content that `billing#limit-amount` has with the label `v2`. The
edges of `@supersedes docs=v3#*` and of `@verifies
data-forms#toml[*]=v3` are pinned too, each with the label `v3`. An edge
whose citation entry has the revision `*`, such as `@cites billing=*`,
is not pinned: it rests on the cited item at each of its revisions. An
edge whose cited item is an external item is not pinned, because an
external id carries no revision.

### 2.10 Tasks and plans

A task is one piece of work that one person or one agent can finish
alone. The work of a task is what people and agents change in the trees
of the repository to finish the task. A plan is one piece of work that
is made up of tasks and plans. Each work item has a work item id, which
never changes and which names exactly one work item, and a display name,
which can change.

A task has:

- its paths: a path set, whose set has the valid paths of the files of a
  tree that the work of the task is to add, change, or remove, so the
  work of a task whose paths are the empty path set is to change no file
  of a tree;
- its promises: each a pair of a kind of edge, `satisfies` or
  `verifies`, and the name of an item of the kind requirement, such as
  `verifies billing#limit-amount`;
- at most one external item, such as an issue, which can say what the
  work is; several tasks can name one external item;
- at most one plan, its plan;
- its waits.

A promise links a task to an item of the kind requirement: the task
promises an edge of the kind of edge of the promise to that item, from a
citation in a file of a tree whose valid path is in the set of its
paths. For a `verifies` promise, a `verifies` edge to a conformance
vector, a group of conformance vectors, or a vector set is such an edge
too, when the group of the cited conformance vector, or of one of the
conformance vectors in the cited item, names the requirement that the
item of the kind requirement declares, so a test that cites a group of
conformance vectors keeps the `verifies` promises of the requirements of
that group. The promise is kept in a tree when the tree has such an
edge, the edge says what its kind of edge says, the edge is not suspect
in that tree, and, for a `verifies` promise, test evidence of an
execution of test runners on the code of that tree has a test result
that names the test that is the source of that edge and says that it
passed, and none that says that it failed.

A task has no description of its own: the items of the kind requirement
that it promises, or its external item, say what to build. A task has no
branch.

A plan has at most one plan, its plan; its waits; and the items of the
kind requirement, specification, and design that it carries out, which
it names by their names. What a plan carries out gives context to the
work under it, and it changes the state of no work item. No person
approves a plan.

A definition of a task is a display name, paths, promises, at most one
external item, at most one plan, and waits. A definition of a plan is a
display name, at most one plan, waits, and the items that the plan
carries out. The work item id is not part of a definition. Each
definition entry records one definition of its work item, and each
alteration of a definition gives a new definition. The plan of a work
item in a definition is the plan, or none, that the definition names,
and the waits of a work item in a definition are the waits that the
definition names.

At each point of a ledger (section 2.11), each work item that exists has
a current definition. A work item is a part of a plan when its current
definition names the plan as its plan, unless the work item is
abandoned, or the plan was abandoned while the work item was not done.
A work item is under a plan when it is a part of the plan, or under a
part of the plan.

A wait goes from a work item, the waiting item, to another work item,
the work item that it waits for. A wait says that the work of the
waiting item is to start only after the work item that it waits for is
done. A wait is met when the work item that it waits for is done, so a
wait for an abandoned work item is never met. A task is ready when it is
open, each of its waits is met, and each wait of each plan that it is
under is met. So a task is ready for work only after each work item that
it waits for, itself or through a plan, is done.

A commit gives its link to a task in a line of its message:

- A delivery line says that the commit completes the work of the task.
  It names the task by its work item id, and it names definitions of the
  task.
- A task line says that the commit does part of the work of the task,
  without finishing it.

### 2.11 The ledger

The ledger of a repository is a sequence of ledger entries. Each ledger
entry other than a void is appended at the end of the ledger: after each
ledger entry that is in the ledger at that time. Of two ledger entries
that were appended to one ledger, the one that was appended later comes
later in the order of the ledger, whatever times the ledger entries
record. A void takes the place of a ledger entry that a repair removes.

A point of a ledger is given by the ledger entries before it: the first
n ledger entries of the ledger, for a whole number n of 0 or more. The
point of a ledger entry is the point right before it. A state that
depends on ledger entries is a state at a point of a ledger.

A repair is a write that removes ledger entries from the ledger of a
repository. For each ledger entry that it removes, it puts one void in
the place of the removed ledger entry: a ledger entry that records the
removal and its reason. A removed ledger entry is no longer in the
ledger, so no state follows from it.

A ledger entry records one event, such as one approval that a person
gave, or one observation of the job. Each ledger entry also records its
writer: the person, the agent, or the job that, as the ledger entry
says, wrote it. When its writer is an agent, the ledger entry also
records the person for whom that agent acts. A ledger entry can also
record the branch from which it was written, and a time. Each ledger
entry has one of these eight kinds of ledger entry:

| ledger entries | kinds of ledger entry | what a ledger entry records |
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
the last accepted definition entry of the work item before that point,
in the order of the ledger, records. A work item exists at a point when
it has a current definition at that point.

A `done` ledger entry records, for each item of the kind requirement
that the task promises, the revision of that item at which a person
judged the work of the task finished. A `delivered` ledger entry
records, for each definition of the task that its delivery line names,
and for each promise of that definition, the revision of the promised
item of the kind requirement and whether the promise was kept.

### 2.12 States

A state is a named condition of an item, an edge, a wait, or a subject
of approval, in a tree, at a point of a ledger, or both. The state
inputs of a repository are the things on which states depend: which
commits the repository has, each with its parents and its tree; the
commit to which each branch points; the commit of the default branch;
the tree of each working tree; the delivery lines and the task lines of
the messages of commits; the ledger, in its order; test evidence; and
the bindings of the parameters that designs name. States follow from the
state inputs alone (section 4.1), and the writers, persons, branches,
and times that ledger entries record change no state (section 4.2).
What a program gives while another process changes a state input is a
matter of the quality of an implementation. No ledger entry records a
state.

| state | of | meaning |
|---|---|---|
| in force | a declared item | the item is not retired |
| retired | a declared item | the item no longer applies: it is deprecated, rejected, or deferred, it is the cited item of an effective `supersedes` edge, or it belongs to a retired item of the kind design or of the kind specification |
| effective | a `supersedes` edge | the replacement of the edge has taken effect, and the edge retires its cited item |
| deprecated | an item of the kind design, specification, or requirement, a term, a decision record, or a declared finding class | a `@deprecated` status tag stands in the item and says that it no longer applies and that nothing replaces it |
| rejected | a decision record | a `@rejected` status tag stands in the record and says that its choice was considered and not made |
| deferred | a decision record | a `@deferred` status tag stands in the record and says that its choice is not made yet |
| approved | a subject of approval, or an item of the kind design, specification, or requirement, a term, or a decision record | a binding of a parameter that a design names gives the kinds of subject of approval that need approval by a person; for such a kind, the subject of approval is approved only when an `approval` ledger entry before the point records that a person approved the revised content that it has in the tree; for another kind, it is approved when the revised content that it has in the tree has merged into the default branch; an item of the kind design is approved when that item of the kind design without the declared items that it holds, its items of the kind specification, and the items of the kind requirement and the terms that it holds directly are approved; an item of the kind requirement or a term that belongs to no item of the kind design and to no item of the kind specification has no subject of approval, so it is never approved |
| declined | a subject of approval, or an item of the kind specification or requirement, a term, or a decision record | the kind of the subject of approval needs approval by a person, and the subject of approval is declined only when a `decline` ledger entry before the point records that a person declined the revised content that it has in the tree; nothing is both approved and declined |
| draft | an item of the kind design | the item is not approved |
| suspect | a pinned edge | the edge has a cited item, and that item has no current revision or a current revision other than the label of the edge |
| open | a task | the task exists, and it is neither delivered, done, nor abandoned |
| delivered | a task | the job observed, in a `delivered` ledger entry, a delivery line of the task, and the task is neither done nor abandoned |
| done | a task | while the task was not abandoned, a person judged the work of the task finished, or the job observed that a delivery line of the task named the definition of the task that was current at the point of the `delivered` ledger entry, and that each promise of that definition was kept |
| abandoned | a task | a person ended the task before it was done |
| unfinished | a task | the task is open or delivered |
| ready | a task | the task is open, and each work item that it waits for, itself or through a plan, is done |
| done | a plan | the plan is not abandoned, has at least one part, and each of its parts is done |
| abandoned | a plan | a person ended the plan |
| open | a plan | the plan exists and is neither done nor abandoned |
| met | a wait | the work item that its waiting item waits for is done |
| accounted for | an item of the kind requirement | work for the item is under way, or was finished at its current revision |

A subject of approval is a unit that a person approves, or that the
merge approves, as a whole: an item of the kind design without the
declared items that it holds, an item of the kind specification with its
items of the kind requirement and its terms, an item of the kind
requirement that an item of the kind design holds directly, a term that
an item of the kind design holds directly, or a decision record. These
five are the kinds of subject of approval. A subject of approval of one
tree and a subject of approval of another tree are the same subject of
approval when their declared items are the same item. The subject of
approval of an item of the kind design, of an item of the kind
specification, of an item of the kind requirement or a term that an item
of the kind design holds directly, and of a decision record is the
subject of approval whose declared item it is. The subject of approval
of an item of the kind requirement or a term that an item of the kind
specification holds is the subject of approval of that item of the kind
specification. The revised content of a subject of approval is the
revised content of its declared item.

A binding of a parameter that a design names gives the kinds of subject
of approval that need approval by a person. At a point of a ledger, a
subject of approval of such a kind is approved only when an `approval`
ledger entry before that point records that a person approved the
revised content that the subject of approval has in the tree. It is
declined only when a `decline` ledger entry before that point records
that a person declined that revised content. It is never both approved
and declined. For each other kind, the merge into the default branch is
the approval: a subject of approval of that kind is approved when the
revised content that it has in the tree has merged into the default
branch, and it is never declined. An item of the kind requirement or a
term that an item of the kind specification holds is approved when that
item of the kind specification is approved, and declined when it is
declined. An item of the kind design is approved when that item of the
kind design without the declared items that it holds, each item of the
kind specification that it holds, and each item of the kind requirement
and each term that it holds directly are approved.

A declared item is retired when it is deprecated, rejected, or deferred;
when it is the cited item of an effective `supersedes` edge; or when it
belongs to a retired item of the kind design or a retired item of the
kind specification. A `supersedes` edge is effective when its
replacement has taken effect: the edge says what its kind of edge says,
neither its source nor an item that holds its source is deprecated,
rejected, or deferred, and its source is a declared finding class, which
has no subject of approval, or is approved. So a `supersedes` edge whose
source is not approved yet retires nothing, and a `supersedes` edge from
an item of the kind design retires nothing until the whole item of the
kind design is approved.

A suspect edge has a cited item that has no current revision, or a
current revision other than the label of the edge, for example because
the cited item has a new revision, so the source may no longer agree
with the cited item.

At each point of a ledger, each task that exists is in one of the states
open, delivered, done, and abandoned:

- A task is abandoned when a person ended it before it was done.
- A task is done when, while the task was not abandoned, a person
  judged its work finished, or the job observed that a delivery line of
  the task named the definition of the task that was current at the
  point of the `delivered` ledger entry of that observation, and that
  each promise of that definition was kept.
- A task is delivered when the job observed, in a `delivered` ledger
  entry, a delivery line of the task, and the task is neither done nor
  abandoned.
- A task is open when it is in none of these three states.

A task is unfinished while it is open or delivered. The state of a task
says that work happened, and it does not say that the code stays
correct.

An item of the kind requirement is accounted for when one of these is
true:

- an unfinished task has a promise that names it;
- an open plan names, as carried out, the item, the item of the kind
  specification that holds it, or the item of the kind design that
  holds it;
- a done task promised it, and the work of that task was finished at
  its current revision.

A promise and a plan name an item of the kind requirement by its name,
so they name the same item in each tree in which that item has that
name.

### 2.13 Statements of agents

A statement of an agent is a text that an agent writes, such as a line
of a file of a tree, a line of the message of a commit, a ledger entry,
or a message to a person. When its input says that an agent runs it, a
conforming program appends to the ledger no ledger entry other than a
definition entry, and makes no repair (section 4.3). A conforming
program appends a judgment only to record a decision that a person gives
it by a confirmation that the standard input, the arguments, and the
environment of the program cannot give (section 4.4). Taking in the
ledger entries that another clone appended is not appending. So when an
agent changes the ledger only through a conforming program whose input
says that an agent runs it, a statement of the agent changes a state
only in one of these two ways (sections 4.1, 4.3, and 4.4):

1. through a state input, other than the ledger, that the statement
   alters, such as the tree of a working tree or of a commit, the
   delivery lines and the task lines of the messages of commits, which
   commits the repository has, the commit to which a branch points, or
   the bindings of the parameters that designs name;
2. as a definition entry.

Under that condition, a statement of an agent that alters no state input
other than the ledger and is not a definition entry, such as a message
to a person that says that the work of the agent is done, changes no
state.

A session is one execution of an agent on its work. The agent can
declare a task as the work of its session: the declared task of the
session. The brief of a session is the text about the work of the
session that a conforming program gives the agent of that session, in
no state input. A conforming program uses the declared task of a session
for nothing other than the brief of that session (section 4.5).

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
    data-forms#{test-vector-set=v1, vector-meaning=v1},
    #{declared-item=v1, tree=v1},
}

In a tree, each item of the kind design and each item of the kind
specification has at most one vector set: the test-vector set of that
item in that tree, when the tree has one.

### 3.15 Conformance vectors

@term conformance-vector=v1
@cites {
    data-forms#{
        vector-line=v1, vector-meaning=v1, group-form-list=v1,
    },
    text#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, input=v1,
    },
    #{vector-set=v1, declared-item=v1, containment=v1},
}

Each vector line of a vector set gives one conformance vector of that
vector set: the vector that the vector line states by the forms of its
group. That vector line is the vector line of the conformance vector. A
conformance vector of the vector set of an item of the kind
specification is an input, or several inputs, of a conforming program of
the specification that the item declares, and what the requirements of
that specification oblige that program to give for them. A conformance
vector of the vector set of an item of the kind design is an input, or
several inputs, of a conforming program of that design, and what the
items of the kind requirement that the design holds directly oblige that
program to give for them. The number of a conformance vector is the
number of its vector line.

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
Each test result names its test. The test evidence of one execution of
test runners is the set of the test results of that execution that say
that their test passed or that it failed.

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
    data-forms#{vector-line=v1, group-form-list=v1},
    text#{text=v1},
    #{
        item=v1, declared-item=v1, containment=v1, term=v1,
        conformance-vector=v1, conformance-vector-group=v1,
        vector-set=v1, task=v1, plan=v1, test=v1, site=v1,
        external-item=v1,
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
declared items that has a label. The revised content
of a conformance vector is that conformance vector with the forms of its
group, and the revised content of a group of conformance vectors or of a
vector set is its conformance vectors, each with the forms of its group.
Each declared item, each conformance vector, each group of conformance
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
that a conforming program of its specification or its design gives for
its input or inputs. When its cited item is a group of conformance
vectors or a vector set, the edge says this of each conformance vector
in it.

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
    text#{requirement=v1},
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
its cited item is a conformance vector or has at least one conformance
vector in it, and the requirement that that item of the kind requirement
declares is among the requirements of the group of that conformance
vector, or of one of the conformance vectors in its cited item. The
promise is kept in a tree when, and only when, that tree has such an
edge, and the edge says what its kind of edge says, and the edge is not
suspect in that tree, and, for a `verifies` promise, test evidence of an
execution of test runners on the code of that tree has a test result
that names the test that is the source of that edge and says that it
passed, and none that says that it failed.

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
`decline`, `done`, `abandoned`, `delivered`, and `void`. Each ledger
entry records a writer: the person, the agent, or the job that, as the
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
ledger: after each ledger entry that is in the ledger at that time. Of
two ledger entries that were appended to one ledger, the one that was
appended later comes later in the order of the ledger, whatever times
the two ledger entries record. A point of a ledger is given by the
ledger entries before it: the first n ledger entries of the ledger, for
a whole number n of 0 or more. The point of a ledger entry is the point
right before it.

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
  approved when, and only when, the revised content that it has in that
  tree has merged into the default branch. It is not declined.
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

### 4.3 The ledger entries that agents write

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

### 4.4 The judgments that persons give

@req write-judgments-only-for-persons=v1
@cites {
    text#{conforming-program=v1},
    #{judgment=v1, person=v1, ledger=v1},
}

A conforming program must append a judgment to the ledger only to record
a decision that a person gives it by a confirmation that the standard
input, the arguments, and the environment of the program cannot give.

### 4.5 The use of declared tasks

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
