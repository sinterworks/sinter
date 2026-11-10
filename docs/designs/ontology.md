<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
Specifies the kinds of items that Sinter traces, with their names, texts, revisions, and edges, and the conditions of a valid tree; work items, changes, the ledger, and the actors that write it; the names and meanings of states; and requirements for conforming programs that limit the use of statements of agents and of declared tasks, and that show the definition entries of a change.

Sinter traces the items of a repository: designs with their
specifications, requirements, and terms, decision records, tests, tasks
and plans, and the items outside the repository that external ids name.
A citation, such as `@verifies packs#limit-size=v2` in a comment on a
test, states an edge: a relation from its source, here the test, to its
cited item, here the requirement `packs#limit-size` with the text that
the label `v2` names. The ledger of a repository records events, such
as the approval that a person gave to one text. Each state, such as in
force, approved, suspect, or done, follows from the trees and the
messages of the commits of the repository, from its ledger entries, and
from test evidence.

From Identifiers, the design takes tag lines, tag words, and kind
words; names, labels, and revisions; external ids; citation entries and
vector selections; the forms of the `@ack` and `@extern` lines; inline
citations; and which tag lines and inline citations a conforming
program gives the result "valid". From Text and notation, it takes
texts, lines, and whole numbers, and what a design, a requirement, a
conforming program, an input, and a result are.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that a project made |
| [item](sinter:#item=v1) | a thing that Sinter traces, such as a requirement, a test, or a task |
| [kind of item](sinter:#item=v1) | one of the fourteen kinds of item, such as design or task; each item has one |
| repository | a git repository |
| commit, message of a commit, branch, file, path, working tree, clone, push, squash commit, pull request | the thing of git, or of a host of git repositories, that has this name |
| markdown file | a file of markdown text, such as a file whose name ends in `.md` |
| [tree](sinter:#tree=v1) | the set of the files of a repository, with their contents, at one commit or in one working tree |
| [default branch](sinter:#default-branch=v1) | the branch into which work on a repository merges |
| actor | a person, an agent, or the job |
| [person](sinter:#person=v1) | a human who works on a repository |
| [agent](sinter:#agent=v1) | a program that uses a language model to write texts for a person, such as code |
| continuous integration | a service that runs checks on the commits of a repository |
| [job](sinter:#job=v1) | an execution of Sinter that continuous integration starts at each push to the default branch of a repository |
| [accepted input](sinter:#accepted-input=v1) | a tag line or an inline citation of a text that Sinter reads from a tree, to which a conforming program of Identifiers gives the result "valid" |
| [declared item](sinter:#declared-item=v1) | what a declaration that is an accepted input declares: an item of the kind design, specification, requirement, term, decision record, or declared finding class |
| [item of the kind design](sinter:#declared-item=v1) | a declared item whose declaration word is `@design`; in a valid tree, it is a design |
| [item of the kind requirement](sinter:#declared-item=v1) | a declared item whose declaration word is `@req`; in a valid tree, it is a requirement of the design to which it belongs |
| [design](sinter:text#design=v1) | a document that declares, each under a name, obligations and definitions |
| [requirement](sinter:text#requirement=v1) | an obligation that a design declares under a name and states with the word must |
| [specification](sinter:#specification=v1) | a declared item whose declaration word is `@spec`; it specifies one thing of a system, such as a format |
| [term](sinter:#term=v1) | a declared item whose declaration word is `@term`; its text states the meaning of one word or one fixed phrase |
| normative | stating what a word or a fixed phrase means, or what a conforming program must do; only the texts of terms and of requirements are normative |
| [decision record](sinter:#decision-record=v1) | a declared item whose declaration word is `@decision`; it records one standing practice of a project, or one choice with its reason |
| [finding](sinter:#finding-class=v1) | a report of one condition at one part of a repository |
| [finding class](sinter:#finding-class=v1) | a kind of finding, which a slug names |
| [declared finding class](sinter:#declared-finding-class=v1) | a declared item whose declaration word is `@finding-class`: a finding class that a repository declares for itself |
| [finding-class file](sinter:#declared-finding-class=v1) | the file whose whole text is the text of one declared finding class |
| [text of a declared item](sinter:#item-text=v1) | the part of the files of a tree that a declared item takes up, its declaration included |
| [innermost](sinter:#item-text=v1) | of the declared items in whose texts a part of a file is, the one whose text is in the text of each of the others |
| [file of a declared item](sinter:#item-file=v1) | the file in which the declaration of a declared item is |
| [home design](sinter:#home-design=v1) | the innermost item of the kind design in whose text a tag line or an inline citation is; for a tag line or an inline citation in a specification in a file of its own, the design that the declaration of the specification names |
| [containment](sinter:#containment=v1) | the relation in which a design holds specifications, requirements, and terms, and a specification holds requirements and terms |
| [hold](sinter:#containment=v1), [belong to](sinter:#containment=v1) | a design holds each of its specifications, requirements, and terms, and each of them belongs to the design; a specification holds its requirements and its terms in the same way |
| [hold directly](sinter:#containment=v1) | a design holds a requirement or a term directly when the requirement or the term belongs to the design and to no specification |
| [own text](sinter:#own-text=v1) | the part of the text of a design that is in the text of none of its specifications, requirements, and terms |
| [name of a declared item](sinter:#item-name=v1) | a slug, such as `packs`, or for an item that belongs to a design, the name of the design, `#`, and the part name of the item, such as `packs#size` |
| [set of names](sinter:#item-name=v1) | a set of names in which, in a valid tree, no two declared items have the same name: the shared set of slugs, the set of slugs of the declared finding classes, and the set of part names of each design |
| [mark](sinter:#mark=v1) | what an `@extern` line in the own text of a design states: the design holds an item of the kind that the kind word of the line states, with the part name of the line, whose declaration is in another file |
| [value](sinter:identifiers#value=v1) | a text or a fact that a conforming program gives together with a result |
| [conformance vector](sinter:#conformance-vector=v1) | a statement of one input of a conforming program of a design, of one result for that input, and of the values that come with that result |
| [vector set](sinter:#vector-set=v1) | the conformance vectors of one specification, or of one design for the requirements that it holds directly |
| [number of a vector](sinter:#vector-set=v1) | the whole number of 1 or more that a conformance vector has in its vector set |
| [group](sinter:#group=v1) | a set of the conformance vectors of one vector set, with a name |
| [selection](sinter:#selection=v1) | the set of conformance vectors that one citation entry names: one vector, every vector of a group, or every vector of a vector set |
| [test](sinter:#test=v1) | a unit of code that a test framework runs and reports as passed or failed, or a set of such units |
| [test evidence](sinter:#test-evidence=v1) | the reports that tests gave in one execution: which tests ran, and which of them passed or failed |
| [site](sinter:#site=v1) | a part of a file with citations or inline citations in it, which is in the text of no declared item and in no comment on the code of a test |
| [external item](sinter:#external-item=v1) | a thing outside the repository that an external id names, such as an issue or a published standard |
| hash | a short text that a fixed function computes from a text, so that two different texts almost never have the same hash |
| [revised content](sinter:#revised-content=v1) | the part of an item that a revision of the item names, such as the own text of a design |
| [revision of an item](sinter:#item-revision=v1) | a label that an item has, which names the revised content that the item has with that label |
| [current revision](sinter:#item-revision=v1) | the label that an item has in a given tree |
| [reused label](sinter:#reused-label=v1) | a label that an item has in a tree, and that another tree of the repository gives the item with a different revised content |
| [edge](sinter:#edge=v1) | a relation of one kind of edge from a source to a cited item, which a citation entry or an inline citation states |
| [kind of edge](sinter:#edge=v1) | one of `cites`, `satisfies`, `verifies`, `refines`, and `supersedes` |
| [stand in](sinter:#edge-source=v1) | a line, a citation, or an inline citation stands in the innermost declared item in whose text it is; otherwise in the innermost test on whose code a comment that it is in is; otherwise in the site that it is in |
| [source](sinter:#edge-source=v1) | the item in which the citation or the inline citation of an edge stands |
| [cited item](sinter:#edge=v1) | the item that the citation entry or the inline citation of an edge names |
| [pinned edge](sinter:#pinned-edge=v1) | an edge whose citation entry or inline citation has a label as its revision |
| [cycle of `supersedes` edges](sinter:#supersedes-cycle=v1) | a sequence of `supersedes` edges along which a declared item reaches itself, each edge from its source to its cited item |
| [status tag of a declared item](sinter:#item-status-tag=v1) | a status tag that is an accepted input, of the innermost of the declared items among the tag lines of whose declarations it is |
| [ack](sinter:#ack=v1) | what an `@ack` line states: a person or an agent acknowledges the findings of one finding class in one text |
| [valid edge](sinter:#valid-edge=v1) | an edge that has a cited item, whose kind word fits its cited item, and whose source and cited item fit its kind of edge |
| [valid mark](sinter:#valid-mark=v1) | a mark whose kind word is `spec`, `req`, or `term`, for which the design holds such an item with the part name of the mark, directly for `req` and `term`, declared in another file |
| [valid status tag](sinter:#valid-status-tag=v1) | a status tag of a declared item whose status word fits the kind of item of that declared item |
| [valid tree](sinter:#valid-tree=v1) | a tree that meets each condition of validity, such as that each edge is valid and that each specification, requirement, and term belongs to exactly one design |
| [work item](sinter:#work-item=v1) | a task or a plan |
| [work item id](sinter:#work-item=v1) | the id of a work item, which never changes |
| [display name](sinter:#work-item=v1) | the name of a work item that a person reads, which can change |
| [task](sinter:#task=v1) | one piece of work that one person or one agent can finish alone |
| [paths of a task](sinter:#task=v1) | the set of the paths of the files that the work of a task can add, change, or remove |
| [promise](sinter:#promise=v1) | a pair of a kind of edge, `satisfies` or `verifies`, and a requirement, which states what the work of a task puts into the tree |
| [keep a promise](sinter:#promise=v1) | to do what the promise states |
| [plan](sinter:#plan=v1) | a work item that says how a set of tasks and plans gets done |
| [plan of a work item](sinter:#work-item-definition=v1) | the plan that the definition of a work item names |
| [wait](sinter:#wait=v1) | a relation from a work item to another work item that it waits for |
| [carry out](sinter:#carried-out-item=v1) | a plan carries out the requirements, specifications, and designs that its work is for |
| [definition of a work item](sinter:#work-item-definition=v1) | what a definition entry records about a work item, such as the paths of a task |
| [change](sinter:#change=v1) | a set of commits on a branch that is to merge into the default branch as one unit |
| [diff of a change](sinter:#change-diff=v1) | the lines that differ between the tree where a change starts and the tree of its last commit |
| [delivery line](sinter:#delivery-line=v1) | a line of the message of a commit that states that the commit completes the work of a task |
| [finishing commit](sinter:#delivery-line=v1) | the commit in whose message a delivery line is |
| [task line](sinter:#task-line=v1) | a line of the message of a commit that names a task on which the commit does part of the work |
| tasks of a change | the tasks that the delivery lines and the task lines of a change name |
| [ledger](sinter:#ledger=v1) | the sequence of the ledger entries of a repository, in the order in which they were appended |
| [ledger of a clone](sinter:#ledger=v1) | the ledger entries that a clone has: the pushed ones, and after them its provisional ones |
| [provisional](sinter:#ledger=v1) | a ledger entry is provisional while a clone has it and has not pushed it yet |
| [point of a ledger](sinter:#ledger=v1) | a point between two ledger entries, before the first, or after the last |
| [ledger entry](sinter:#ledger-entry=v1) | a record of one event in the ledger, such as one approval |
| [repair](sinter:#repair=v1) | the one write to the ledger that is not an append at its end: it removes ledger entries and puts a void in the place of each |
| [void](sinter:#repair=v1) | a ledger entry that takes the place of a ledger entry that a repair removed |
| [definition entry](sinter:#definition-entry=v1) | a ledger entry that records one definition of one work item |
| [accepted definition entry](sinter:#work-item-state=v1) | a definition entry that gives its work item the definition that it records, because it meets each condition for that at its point |
| [current definition](sinter:#work-item-state=v1) | the definition that the latest accepted definition entry of a work item records |
| [exist](sinter:#work-item-state=v1) | a work item exists at a point of a ledger when it has a current definition at that point |
| [part of a plan](sinter:#work-item-state=v1) | a work item whose current definition names the plan as its plan, unless an abandonment ended that |
| [under a plan](sinter:#work-item-state=v1) | a part of the plan, or under a part of the plan |
| [combined relation](sinter:#work-item-state=v1) | the relation from each plan to its parts, from each work item to the work items that it waits for, and from each task to the work items that the plans that it is under wait for |
| [subject of approval](sinter:#subject-of-approval=v1) | a unit that a person approves or declines as a whole |
| [judgment](sinter:#judgment=v1) | a ledger entry that records a decision of a person |
| [record of the job](sinter:#job-record=v1) | a ledger entry that records what the job observed |
| [state](sinter:#state=v1) | a named condition of an item, an edge, or a subject of approval, in a tree, at a point of a ledger, or both, such as in force or done |
| [retired](sinter:#retired-item=v1) | a declared item is retired when it has a valid status tag, when an effective `supersedes` edge has it as its cited item and it is on no cycle of `supersedes` edges, or when it belongs to a retired design or a retired specification |
| [in force](sinter:#in-force-item=v1) | a declared item is in force when it is not retired |
| [effective](sinter:#effective-supersedes-edge=v1) | a `supersedes` edge is effective when it is valid, its source has no valid status tag, and its source is approved when the repository needs approval for its kind of item |
| [deprecated](sinter:#deprecated-item=v1), [rejected](sinter:#rejected-record=v1), [deferred](sinter:#deferred-record=v1) | the states that the three status words state, through a valid status tag |
| [approved, declined](sinter:#approval-state=v1) | a subject of approval is approved, or declined, when the latest judgment of the revised content that it has in the tree is an approval, or a decline; a design is approved when each subject of approval of it is approved |
| [draft](sinter:#draft-design=v1) | a design is a draft while it is not approved |
| [suspect](sinter:#suspect-edge=v1) | a pinned edge is suspect when its label is not the current revision of its cited item |
| [open, delivered, done, abandoned](sinter:#work-item-state=v1) | the four states of a task |
| [open, done, abandoned](sinter:#work-item-state=v1) | the three states of a plan |
| [unfinished](sinter:#work-item-state=v1) | a task is unfinished while it is open or delivered |
| final | a state that a work item keeps at each later point of the ledger |
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
| term | a declared item whose declaration word is `@term`, whose text states the meaning of one word or one fixed phrase | a full name, such as `packs#size` | yes |
| decision record | a declared item whose declaration word is `@decision`, which records one practice or one choice | a slug, such as `code-comments` | yes |
| declared finding class | a declared item whose declaration word is `@finding-class`, a finding class that a repository declares for itself | a slug, such as `late-fee` | yes |
| conformance vector | a statement of one input of a conforming program, of one result, and of its values | its vector set and its number | yes |
| group | a set of the conformance vectors of one vector set, with a name | its vector set and its name | yes |
| vector set | the conformance vectors of one specification or of one design | its specification or its design | yes |
| task | one piece of work | a work item id | no |
| plan | how a set of tasks and plans gets done | a work item id | no |
| test | a unit of code that a test framework runs | the code names it | no |
| site | a part of a file with citations or inline citations in it, outside every declared item and every comment on the code of a test | no name | no |
| external item | a thing outside the repository | an external id, such as `gh/42` | no |

Sinter reads some texts of the files of a tree, such as the comments in
code and the paragraphs of markdown files, under one binding of the
parameter `external-namespaces` of Identifiers. An accepted input is a
tag line or an inline citation of such a text to which a conforming
program of Identifiers gives the result "valid" under that binding. Only
an accepted input declares an item, states an edge, a mark, or an ack,
or is the status tag of an item. So `@req limit-size` declares nothing,
because its target carries no label. `@deprecated.` is the status tag of
no item, and `[](sinter:packs#limit-size=v2)` states no edge.

A declared item is what a declaration that is an accepted input
declares. The declaration word alone gives the kind of the declared
item: `@design` gives the kind design, `@spec` the kind specification,
`@req` the kind requirement, `@term` the kind term, `@decision` the
kind decision record, and `@finding-class` the kind declared finding
class. In a valid tree (section 2.11), each item of the kind design is a
design, and each item of the kind requirement belongs to a design and is
a requirement of that design.

A work item is a task or a plan. No work item is in a file of a tree:
the definition entries of the ledger define each one.

### 2.2 Repositories, changes, and actors

A repository is a git repository. A tree is the set of the files of the
repository, with their contents, at one commit or in one working tree.
The tree of a commit is the tree at that commit. The default branch is
the branch into which work on the repository merges.

A change is a set of commits on a branch, the branch of the change, that
is to merge into the default branch as one unit, such as the commits of
a pull request. The person who merges the change brings its work to the
default branch, as its commits or as one squash commit. The diff of a
change is the set of the lines that differ between the tree of the
commit from which its branch starts and the tree of its last commit:
the lines that the change adds, and the lines that it removes.

An actor is a person, an agent, or the job. Actors write the ledger
entries that Sinter reads:

- A person is a human who works on a repository.
- An agent is a program that uses a language model to write texts for a
  person, such as code, a commit message, or a ledger entry. A coding
  agent is an example. Each agent acts for one person: the person who
  runs it.
- The job is an execution of Sinter that continuous integration starts
  at each push to the default branch of a repository. Continuous
  integration is a service that runs checks on the commits of a
  repository. The job reads test evidence during its execution, and
  that test evidence is available only during that execution.

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
belongs to it. The declaration of an item of the kind specification,
requirement, or term decides the design to which the item belongs:

- When the target of the declaration starts with a full name, such as
  `@req packs#limit-size=v1`, the item belongs to the design whose name
  is the slug of that full name, here `packs`, wherever the declaration
  is.
- When the target of the declaration starts with a slug of one segment,
  such as
  `@spec descriptor=v2` or `@term size=v1`, the item belongs to the home
  design of the declaration: the design in whose text the declaration
  is.
- Otherwise, the item belongs to no design.

A requirement or a term belongs to the innermost specification in whose
text its declaration is, when the two belong to the same design, or
both to no design. A design holds a requirement or a term directly when
the requirement or the term belongs to the design and to no
specification.

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

The text of a declared item is a part of the files of a tree. Its
declaration is in it. When the texts of two declared items have a part
in common, one of the two texts is in the other. No part of a file is in
the texts of two different requirements, of two different terms, or of
a requirement and a term. Of the declared items in whose texts a part
of a file is, the innermost is the one whose text is in the text of each
of the others. The own text of a design is the part of its text that is
in the text of none of its specifications, requirements, and terms. In
the example, the own text of `packs` is its heading, its tag line, and
its first sentence.

The file of a declared item is the file in which its declaration is. A
design can hold a specification, or hold directly a requirement or a
term, whose declaration is in another file. An `@extern` line in the own
text of the design states a mark for such an item, such as
`@extern spec:descriptor`. The kind word of the line gives the kind of
item, and the part name of the line gives the part name of the item. A
requirement or a term of such a specification has no mark of its own:
the mark of its specification covers it. A specification in a file of
its own names its design by a full name, such as
`@spec packs#descriptor=v2`. The home design of each tag line and each
inline citation in the text of that specification is that design.

Only the texts of terms and of requirements are normative: a term
states what a word or a fixed phrase means, and a requirement states
what each conforming program of the design must do. The rest of the
text of a design and of its specifications explains the terms and the
requirements and gives examples.

### 2.4 Names

The name of a design, of a decision record, and of a declared finding
class is the slug of its declaration, such as `packs`. The name of a
specification, a requirement, or a term that belongs to a design is a
full name: the name of the design, `#`, and the part name of the item,
such as `packs#descriptor`, `packs#size`, and `packs#limit-size`. The
name of a specification, a requirement, or a term that belongs to no
design is the name in the target of its declaration, such as the slug
`limit-size` of `@req limit-size=v1` outside every design. Names come
in sets:

- The shared set of slugs holds the names of the designs, of the
  decision records, and of the specifications, the requirements, and
  the terms that belong to no design and whose names are slugs.
- The declared finding classes have a set of slugs of their own.
- The specifications, the requirements, and the terms of one design
  share one set of part names.

A name in a citation entry or in the target of an inline citation names
an item in this way:

- A slug, such as `packs`, names the item of the shared set of slugs
  that has it as its name. After the kind word `finding-class`, as in
  `finding-class:late-fee`, a slug names the declared finding class
  that has it as its name.
- A full name, such as `packs#size`, names the specification, the
  requirement, or the term of the design that its slug names, whose
  part name is its part name.
- `#` and a part name, such as `#size` in the example of section 2.3,
  names the specification, the requirement, or the term with that part
  name of the home design of the citation or of the inline citation.
  With no home design, it names nothing.
- An external id names an external item (section 2.7).

A name that two or more declared items of one set of names have names
none of them.

### 2.5 Decision records, finding classes, and acks

A decision record records one standing practice of a project, or one
choice with its reason, such as the record `code-comments`.

A finding is a report of one condition at one part of a repository. A
finding class is a kind of finding, which a slug names. A repository can
declare finding classes of its own. Each such declared finding class is
a declared item, and its text is the whole of one file, its
finding-class file. A finding class that a conforming program has built
in is not an item.

An ack is what an `@ack` line states: a person or an agent acknowledges
the findings of one finding class in one text. In the line
`@ack late-fee billing#fee=v2 3f2a9c1d`, the slug `late-fee` names the
finding class, and the subject `billing#fee=v2` names what the findings
are about. An `@ack` line with an empty subject acknowledges every
finding of its finding class in that text. The text is the text of the
item in which the `@ack` line stands (section 2.10): of a declared item,
of a comment on the code of a test, or of a site. The hash prefix
`3f2a9c1d` is the start of the hash of that text, as the text was when
the ack was written. A hash is a short text that a fixed function
computes from a text, so that two different texts almost never have the
same hash.

### 2.6 Conformance vectors

A conformance vector states one example of an input of a conforming
program of a design, one result for that input, and the values that
come with that result. A value is a text or a fact that a conforming
program gives with a result, such as the slug of a target that a parser
gives. The result and the values of a conformance vector follow from
the requirements of its design, and the vector states no requirement of
its own.

Each conformance vector is given for one specification of its design,
or for the requirements that its design holds directly. The conformance
vectors given for a specification form its vector set. The conformance
vectors given for the requirements that a design holds directly form
the vector set of the design. Each conformance vector has a number, a
whole number of 1 or more, in its vector set. A group is a set of the
conformance vectors of one vector set, with a name.

A citation entry of `@cites` or `@verifies` can name one conformance
vector, one group, or one vector set. The selection of the citation
entry is the set of the vectors that it names in this way:

| citation entry | cited item | selection |
|---|---|---|
| `data-forms#toml[12]=v1` | the vector 12 of the vector set of the specification `data-forms#toml` | that one vector |
| `data-forms#toml[offsets][*]=v2` | the group `offsets` of that vector set | every vector of the group |
| `data-forms#toml[*]=v3` | the vector set of `data-forms#toml` | every vector of the vector set |
| `identifiers[37]=v1` | the vector 37 of the vector set of the design `identifiers` | that one vector |

The name of such a citation entry names a specification or a design. A
citation entry whose name names another item, such as a requirement,
names nothing and selects nothing. A citation entry also names nothing
when no vector or group of the vector set has its number or its group
name, or when two or more have it.

A test that checks code against the vectors of a selection names them
with `@verifies`:

```python
# @verifies data-forms#toml[offsets][*]=v2
def test_offsets(vector):
    ...
```

### 2.7 Tests, sites, and external items

A test is a unit of code that a test framework runs and reports as
passed or failed, such as a test function. A set of such units, such as
the tests of one `describe` block, is a test too. The code names each
test, so a test has no declaration. Test evidence is the set of the
reports that tests gave in one execution of their test frameworks:
which tests ran, and which of them passed and which failed.

A site is an item with no name. It is a part of a file, such as a
comment in code or a section of a markdown file, with citations or
inline citations in it, which is in the text of no declared item and in
no comment on the code of a test.

An external item is an item outside the repository that an external id
names, such as the issue `gh/42` or the standard `rfc/8259`. Each
external id in an accepted input names an external item, even when
nothing outside the repository has that external id. An external id
with `#` and a part name, such as `rfc/8259#section-6`, names a part of
such an item, and that part is an external item too. An external item
has no revision. An external item can be a published standard, or a
part of one. It can also state the meaning of one word or one fixed
phrase, such as the external item `rfc/8259#value`.

### 2.8 Kind words

A kind word at the start of a citation entry, of the target of an
inline citation, or of the target of an `@extern` line states what the
citation entry or the target names:

| kind word | what the citation entry or the target names |
|---|---|
| `design` | an item of the kind design |
| `spec` | a specification, or an external item that is a published standard or a part of one |
| `req` | an item of the kind requirement |
| `term` | a term, or an external item that states the meaning of one word or one fixed phrase |
| `decision` | a decision record |
| `finding-class` | a declared finding class |

So `req:packs#limit-size=v2` states that `packs#limit-size` is an item
of the kind requirement, and `spec:rfc/8259` states that the external
item `rfc/8259` is a standard. The citation entry `term:rfc/8259#value`
states that the external item `rfc/8259#value` states the meaning of
one word or one fixed phrase. What a kind word states about an external
item cannot be checked: with an external item, the kind words `spec`
and `term` fit, and the others do not. No kind word states a
conformance vector, a group, or a vector set. So a citation entry with
both a kind word and a vector selection, such as
`spec:data-forms#toml[12]=v1`, states an edge that is not valid.

### 2.9 Revisions and pins

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

The current revision of an item in a tree is the label that the item
has in that tree, whatever its revised content. For a declared item, it
is the label of its declaration. For a conformance vector, a group, and
a vector set, it is the label that the tree gives it. A declared item
whose declaration has no label, such as `@term invoice`, has no current
revision. A revision of an item is a label that the item has, and it
names the revised content that the item has with that label. A label
that an item has in a tree is a reused label when another tree of the
repository gives the item the same label with a different revised
content.

So an edit of a requirement or a term inside a specification changes
the revised content of that requirement or term and of the
specification. An edit of the own text of a design changes the revised
content of the design alone. An edit of one vector changes the revised
content of its group and of its vector set.

An edge is pinned when the revision of the citation entry or of the
inline citation that states it is a label: the label of the edge. A
pinned edge states its relation to the revised content of its cited
item that its label names. So `@cites packs#limit-size=v2` rests on the
text of `packs#limit-size` that has the label `v2`. The edges of
`@supersedes docs=v3#*` and of `@verifies data-forms#toml[*]=v3` are
pinned too, each with the label `v3`. An edge whose citation entry has
the revision `*`, such as `@cites packs=*`, is not pinned: it rests on
the cited item at each of its revisions. An edge whose cited item is an
external item is not pinned, because an external id carries no
revision.

### 2.10 Edges

An edge is a relation of one kind of edge from a source to a cited
item. Each citation entry of a citation that is an accepted input
states one edge. The kind of edge is the citation word without its `@`.
The cited item of the edge is the item that the citation entry names:
by its selection when it has a vector selection, and by its name
otherwise. An inline citation that is an accepted input, such as
`[the limit](sinter:packs#limit-size=v2)`, states one edge of the kind
`cites`, and the name or the external id in its target names the cited
item. When the citation entry or the target names no item, the edge has
no cited item.

A line, a citation, or an inline citation stands in one item:

1. in the innermost declared item in whose text it is, when it is in the
   text of a declared item;
2. otherwise, in the innermost test on whose code a comment that it is
   in is, when there is one;
3. otherwise, in the site that it is in.

The source of an edge is the item in which its citation or its inline
citation stands. So `@supersedes packs#old=v1` in the text of a
requirement `packs#new` has that requirement as its source, and not the
design `packs`. A `@verifies` line in a comment on the code of a test
has that test as its source.

| kind of edge | what it states |
|---|---|
| `cites` | the source refers to the cited item and rests on what the cited item says |
| `satisfies` | the source does what the cited item states |
| `verifies` | the source checks that the code it runs meets the cited requirement, or gives the result and the values of each vector of the selection |
| `refines` | the source states all or part of the cited item in more detail |
| `supersedes` | the source is to replace the cited item |

No name names a work item, so no edge has a work item as its cited
item. Work points at text in the other direction: a task promises
requirements, and a plan carries out requirements, specifications, and
designs.

Only a `supersedes` edge states that one declared item is to replace
another. A `supersedes` edge from a design whose citation entry the
production `every-part` of Identifiers matches, such as
`@supersedes docs=v3#*` in the tag lines of a design `media`, states two
things. The design `media` is to replace the design `docs`, which the
label `v3` pins. And each specification, each requirement, and each term
`docs#x` is to be replaced by the specification, the requirement, or the
term `media#x` of the same kind of item, when `media` holds one. A
declared item is on a cycle of `supersedes` edges when it reaches itself
along `supersedes` edges, effective or not, each from its source to its
cited item.

### 2.11 Valid trees

The meanings of the sections above apply in every tree. A tree is valid
when it also meets each of these conditions:

| condition | a tree that breaks it |
|---|---|
| each edge is valid: it has a cited item; a kind word at its start is `spec` or `term` for an external item, and states what its cited item is for each other item; and the kinds of its source and of its cited item fit its kind of edge | `@verifies packs#limit-size=v2` in a section of a markdown file, whose source is a site and not a test |
| each mark is valid: its kind word is `spec`, `req`, or `term`, and the design holds such an item with its part name, directly for `req` and `term`, declared in another file | `@extern design:docs` |
| each `@extern` line is in the own text of an item of the kind design | `@extern spec:descriptor` in the text of a requirement |
| each status tag of a declared item fits the kind of item of that declared item | `@rejected` in the tag lines of a requirement |
| each item of the kind specification, requirement, or term belongs to exactly one item of the kind design | a `@req` line outside every design |
| the text of no item of the kind design is in the text of another one, and the text of no specification is in the text of another specification | `@design docs=v1` in a section of the design `packs` |
| each specification, and each requirement and each term held directly, whose declaration is outside the file of its design has a mark | a specification in a file of its own, with no `@extern` line in the design |
| each requirement and each term whose declaration has a full name as its target, and is in a markdown file, is declared in the file of its design or in the file of its specification | `@req docs#x=v1` in the file of the design `packs` |
| each term that belongs to a design has a label | `@term invoice` in a design |
| no two declared items of one set of names have the same name | two declarations `@decision cache=v1` |
| no declared item is on a cycle of `supersedes` edges | `a` supersedes `b`, and `b` supersedes `a` |

The kinds of source and of cited item fit each kind of edge in this
way:

| kind of edge | its source | its cited item |
|---|---|---|
| `cites` | a declared item, a test, or a site | a declared item, an external item, a conformance vector, a group, or a vector set |
| `satisfies` | a declared item, a test, or a site | an item of the kind requirement |
| `verifies` | a test | an item of the kind requirement, a conformance vector, a group, or a vector set |
| `refines` | an item of the kind requirement, specification, or design | an item of the kind requirement, specification, or design |
| `supersedes` | a declared item; an item of the kind design when `every-part` matches the citation entry | a declared item of the same kind of item; an item of the kind design when `every-part` matches the citation entry |

So in a valid tree, no `satisfies` edge and no `verifies` edge has a
term as its cited item: a term states no obligation.

A status word fits these kinds of item: `@deprecated` the kinds
requirement, term, specification, design, and decision record;
`@rejected` and `@deferred` only the kind decision record.

In a valid tree, each item of the kind design is a design, and each
item of the kind requirement belongs to a design and is a requirement
of that design. A tree that is not valid still has its items, its
edges, and their states. So an item of the kind requirement outside
every design has a slug of the shared set of slugs as its name, and
edges can cite it.

### 2.12 Tasks and plans

A task is one piece of work that one person or one agent can finish
alone. A plan says how a set of tasks and plans gets done. Each work
item has a work item id, which never changes, and a display name, which
can change.

A task has:

- its paths: a set of paths; the work of the task can add, change, or
  remove a file only when the path of the file is in that set, so the
  work of a task whose paths are the empty set changes no file;
- its promises: each a pair of a kind of edge, `satisfies` or
  `verifies`, and a requirement, such as `verifies ledger#check-ids`,
  which states that the work of the task puts into the tree of the
  default branch an edge of that kind of edge to that requirement, from
  a source in a file whose path is in the paths of the task; the work of
  the task keeps the promise when it does so;
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

At each point of a ledger (section 2.13), each work item that exists
has a current definition. A work item is a part of a plan when its
current definition names the plan as its plan. Two exceptions apply. An
abandoned task is a part of no plan. And when a person abandons a plan,
each of its parts that is not done stops being a part of it, and its
done parts stay. A work item is under a plan when it is a part of the
plan, or under a part of the plan.

A wait goes from a work item, the waiting item, to another work item,
the item that it waits for. A wait is met when the item that it waits
for is done, so a wait for an abandoned work item is never met. A task
is ready when it is open, each of its waits is met, and each wait of
each plan that it is under is met. So a task is ready for work only
after each work item that it waits for, itself or through a plan, is
done.

The combined relation goes from each plan to each of its parts, from
each work item to each work item that it waits for, and from each task
to each work item that a plan waits for when the task is under that
plan. A definition entry after which the combined relation would have a
cycle is not an accepted definition entry (section 2.13). So no work
item is under itself, and no work item waits for itself, directly or
through a plan. For example, a task that waits for the plan that it is
under would make a cycle: the plan is done only when the task is done,
and the task waits until the plan is done.

A commit states its link to a task in a line of its message:

- A delivery line, such as `Delivers: t-3f2a9c1d7e0b 05ef56`, states
  that the commit completes the work of the task. It names the task by
  its work item id. Its last six characters, here `05ef56`, are the
  start of a hash of the paths and the promises of a definition of the
  task. The line names each definition of the task whose paths and
  promises have a hash with that start. The finishing commit of the
  line is the commit in whose message the line is.
- A task line, such as `Task: t-3f2a9c1d7e0b`, states that the commit
  does part of the work of the task, without finishing it.

The tasks of a change are the tasks that its delivery lines and its
task lines name.

### 2.13 The ledger

The ledger of a repository is a sequence of ledger entries. Ledger
entries are appended at the end of the ledger: after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to one ledger, the one that was appended later comes later in
the ledger, whatever times the ledger entries record. Each clone of the
repository has a ledger of its own: the ledger entries that the clone
has, in their order. First come the pushed ledger entries that the
clone has, and after them its provisional ledger entries, which it has
appended and not pushed yet. A push can drop a provisional ledger
entry, or give it a later place, after ledger entries that other clones
pushed first.

A point of a ledger is given by the ledger entries before it: the first
n ledger entries of the ledger, for a whole number n of 0 or more. The
point of a ledger entry is the point right before it. The end of a
ledger is the point after its last ledger entry. A state that depends
on ledger entries is a state at a point of a ledger.

A repair is the one write to a ledger that is not an append at its end.
It removes one or more ledger entries from the ledger. For each ledger
entry that it removes, it puts one void in the place of the removed
ledger entry: a ledger entry that records the removal and its reason. A
removed ledger entry is no longer in the ledger, so no state follows
from it.

A ledger entry records one event, such as one approval that a person
gave, or one observation of the job. Each ledger entry also records the
person, the agent, or the job that wrote it, the person for whom the
agent acts when an agent wrote it, and the branch from which it was
written, when there was one. Each ledger entry has one of eight kinds
of ledger entry, in four classes:

| class | kinds of ledger entry | what a ledger entry records |
|---|---|---|
| definition entries | `task`, `plan` | one whole definition of one work item |
| judgments | `approval`, `decline`, `done`, `abandoned` | a decision of a person about a subject of approval, a task, or a plan |
| records of the job | `delivered` | what the job observed about one delivery line |
| voids | `void` | that a repair removed one ledger entry, and the reason |

A definition entry records no judgment: it makes no task done, abandons
nothing, and approves or declines nothing. Each definition entry of a
work item records the first definition of the work item, or an edit of
one earlier definition, which it names. A definition entry is an
accepted definition entry when each of these is true at its point:

1. It records the first definition of its work item, and the work item
   does not exist yet; or it records an edit of the current definition
   of its work item.
2. Its work item is not a task that is done or abandoned, and not a plan
   that is abandoned.
3. The plan that its definition names, when it names one, exists and is
   not abandoned.
4. Each work item that a wait of its definition waits for exists.
5. When its definition is the current definition of its work item, the
   combined relation has no cycle.

The current definition of a work item at a point is the definition that
the latest accepted definition entry of the work item before that point
records. A work item exists at a point when it has a current definition
at that point. A definition entry that is not an accepted definition
entry changes no definition and no state.

A `done` ledger entry and a `delivered` ledger entry each record the
revision of each requirement that the task promises. A `delivered`
ledger entry records what the job observed in the tree that it read,
with the test evidence of its execution. That test evidence is
available only during the execution, so no later reader can observe it
again.

### 2.14 States

A state is a named condition of an item, an edge, or a subject of
approval, in a tree, at a point of a ledger, or both. Each state follows
from the trees and the messages of the commits of a repository, from
its ledger entries, and from test evidence. No ledger entry records a
state.

| state | of | meaning |
|---|---|---|
| in force | a declared item | the item applies: its authors still agree with it, no other declared item replaces it, and the design or the specification that holds it is in force |
| retired | a declared item | the item is not in force |
| effective | a `supersedes` edge | the edge retires its cited item |
| deprecated | a requirement, a term, a specification, a design, or a decision record | a valid `@deprecated` status tag of the item states that it no longer applies and that nothing replaces it |
| rejected | a decision record | a valid `@rejected` status tag of the record states that its choice was considered and not made |
| deferred | a decision record | a valid `@deferred` status tag of the record states that its choice is not made yet |
| approved | a subject of approval, or a design, a specification, a requirement, a term, or a decision record | the latest judgment of the revised content that the subject has in the tree is an approval; a design is approved when its own text, its specifications, and the requirements and the terms that it holds directly are approved |
| declined | a subject of approval, or a specification, a requirement, a term, or a decision record | the latest judgment of the revised content that the subject has in the tree is a decline |
| draft | a design | the design is not approved |
| suspect | a pinned edge | the label of the edge is not the current revision of its cited item |
| open | a task | the task exists, and it is neither delivered, done, nor abandoned |
| delivered | a task | the job recorded a delivery line of the task, and the task is neither done nor abandoned |
| done | a task | before the task was abandoned, a person recorded it as done, or the job observed, for a delivery line that names the current definition of the task, that the work kept each promise of that definition |
| abandoned | a task | a person ended the task before it was done |
| ready | a task | the task is open, and each work item that it waits for, itself or through a plan, is done |
| done | a plan | the plan is not abandoned, has at least one part, and each of its parts is done |
| abandoned | a plan | a person ended the plan |
| open | a plan | the plan exists and is neither done nor abandoned |
| accounted for | a requirement | work for the requirement is under way, or was finished at its current revision |

A declared item is retired when one of these is true: it has a valid
status tag, such as `@deprecated`; an effective `supersedes` edge has it
as its cited item, and it is on no cycle of `supersedes` edges; or it
belongs to a retired design or a retired specification. A `supersedes`
edge is effective when it is valid, its source has no valid status tag,
and, in a repository that needs approval for declared items of the kind
of item of that source, its source is also approved. So a `supersedes`
edge whose source waits for approval retires nothing yet. A declared
item on a cycle of `supersedes` edges that has no valid status tag stays
in force, even when an effective `supersedes` edge has it as its cited
item.

A subject of approval is a unit that a person approves or declines as a
whole: the own text of a design, a specification with its requirements
and its terms, a requirement that a design holds directly, a term that a
design holds directly, or a decision record. The latest judgment of the
revised content that a subject of approval has in the tree decides: the
subject is approved when it is an `approval` ledger entry, and declined
when it is a `decline` ledger entry. A requirement or a term that a
specification holds is approved when that specification is approved,
and declined when it is declined. A design is approved when its own
text, each of its specifications, and each requirement and each term
that it holds directly are approved.

The label of a suspect edge is no longer the current revision of its
cited item: the cited item has a new revision, or none, so the source
may no longer agree with it. Only an edge that has a cited item in the
tree is suspect.

At each point of a ledger, each task that exists is in one of the states
open, delivered, done, and abandoned:

- A task is abandoned when an `abandoned` ledger entry of the task is
  before the point, and the task was not done at the point of that
  ledger entry.
- A task is done when one of these ledger entries is before the point,
  and the task was not abandoned at the point of that ledger entry: a
  `done` ledger entry of the task; or a `delivered` ledger entry of the
  task whose delivery line names the definition of the task that was
  current at the point of that ledger entry, and which records that the
  work kept each promise of that definition.
- A task is delivered when it is neither done nor abandoned, and a
  `delivered` ledger entry of the task is before the point.
- A task is open when it is in none of these three states.

So a `delivered` ledger entry for a delivery line that names only an
earlier definition of the task, and not the current one, makes the task
delivered and not done. A task is unfinished while it is open or
delivered. The states done and abandoned of a task are final: the task
keeps the state at each later point of the ledger, and more work on it
is a new task. The state abandoned of a plan is final too. The state
done of a plan is not final: a done plan is open again while it has a
part that is not done. The state of a task records work that happened,
and it does not state that the code stays correct.

A requirement is accounted for when one of these is true:

- an unfinished task promises it;
- an open plan carries out the requirement, its specification, or its
  design;
- the ledger entry that made a task done records, for the requirement,
  the revision that is its current revision.

### 2.15 Statements of agents

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, a ledger entry, or a
message to a person. Sinter computes a state from a statement of an
agent in one of two ways only:

1. as a line of the diff of a change, which is about the item in which
   it stands; or as a line of the message of one of the commits of a
   change that names what it is about by a hash, a revision of an item,
   or a work item id, such as a delivery line or a task line;
2. as a definition entry.

The person who merges a change can see both: the lines in the change
itself, and, in the summary of the change, every definition entry of
the tasks of the change and of the plans that they are under, and every
definition entry that was written from its branch. A statement of an
agent outside these two ways, such as a message of an agent that its
work is done, changes no state.

A session is one execution of an agent on its work. The agent can
declare a task as the work of its session. The declared task changes
no state. Sinter uses it only to narrow the brief of the session: the
text that Sinter gives the agent about its work for that session.

## 3. Definitions

### 3.1 Items

@term item=v1
@cites #{
    declared-item=v1, specification=v1, term=v1, decision-record=v1,
    declared-finding-class=v1, conformance-vector=v1, group=v1,
    vector-set=v1, task=v1, plan=v1, test=v1, site=v1, external-item=v1,
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
@cites #{default-branch=v1}

The job is an execution of Sinter that continuous integration starts at
each push to the default branch of a repository.

### 3.7 Accepted inputs

@term accepted-input=v1
@cites {
    identifiers#{tag-line=v1, inline-citation=v1, binding=v1, input=v1},
    text#{conforming-program=v1, result=v1, design=v1, text=v1},
    #{tree=v1},
}

An accepted input of a tree is a tag line or an inline citation of a
text that Sinter reads from the files of the tree, to which a
conforming program of the design Identifiers gives the result "valid"
under the binding of the parameter `external-namespaces` under which
Sinter reads the tree.

### 3.8 Declared items

@term declared-item=v1
@cites {
    identifiers#{
        declaration=v1, sinter-tag-word=v1, target=v1, slug=v1,
        part-name=v1, full-name=v1,
    },
    #{accepted-input=v1},
}

A declared item is what a declaration that is an accepted input
declares. The declaration word of that declaration alone gives the kind
of the declared item: `@design` gives the kind design, `@spec` the kind
specification, `@req` the kind requirement, `@term` the kind term,
`@decision` the kind decision record, and `@finding-class` the kind
declared finding class. So an item of the kind design is a declared item
whose declaration word is `@design`, and an item of the kind requirement
is a declared item whose declaration word is `@req`. The slug of a
declaration is the slug in its target, and the part name of a
declaration is the part name in its target, when its target starts with
a full name.

### 3.9 Texts of declared items

@term item-text=v1
@cites #{declared-item=v1, tree=v1}

The text of a declared item in a tree is the part of the files of that
tree that the item takes up. The declaration of the item is in its text.
When the texts of two declared items have a part in common, one of the
two texts is in the other. No part of a file is in the texts of two
different declared items that are each of the kind requirement or of the
kind term. Of the declared items in whose texts a part of a file is, the
innermost is the one whose text is in the text of each of the others.

### 3.10 Files of declared items

@term item-file=v1
@cites #{declared-item=v1, tree=v1}

The file of a declared item in a tree is the file of that tree in which
the declaration of the item is.

### 3.11 Home designs

@term home-design=v1
@cites {
    identifiers#{tag-line=v1, inline-citation=v1},
    #{declared-item=v1, item-text=v1, specification=v1, tree=v1},
}

The home design of a tag line or an inline citation in a tree is one
item of the kind design, or none:

- When the tag line or the inline citation is in the text of an item of
  the kind design, its home design is the innermost of the items of the
  kind design in whose texts it is.
- Otherwise, when it is in the text of a specification, and the
  declaration of the innermost such specification has a part name, its
  home design is the item of the kind design whose declaration has the
  slug of the declaration of that specification, when the tree has
  exactly one such item.
- Otherwise, it has no home design.

### 3.12 Containment

@term containment=v1
@cites {
    identifiers#{segment=v1, slug=v1},
    #{
        declared-item=v1, item-text=v1, home-design=v1,
        specification=v1, term=v1, tree=v1,
    },
}

Containment is a relation in which one declared item holds another, and
the other belongs to it. Only items of the kind design and
specifications hold declared items, and they hold only the items that
belong to them in these ways:

- A specification, an item of the kind requirement, or a term whose
  declaration has a part name belongs to the item of the kind design
  whose declaration has the same slug, when the tree has exactly one
  such item.
- A specification, an item of the kind requirement, or a term whose
  declaration has no part name and has a slug of one segment belongs to
  the home design of its declaration, when the declaration has one.
- An item of the kind requirement or a term belongs to the innermost
  specification in whose text its declaration is, when there is one,
  and when the two belong to the same item of the kind design or both
  belong to none.

A specification, an item of the kind requirement, or a term belongs to
no other declared item. An item of the kind design holds directly an
item of the kind requirement or a term when that item belongs to it and
to no specification.

### 3.13 Own texts

@term own-text=v1
@cites #{
    declared-item=v1, item-text=v1, containment=v1, specification=v1,
    term=v1,
}

The own text of an item of the kind design is the part of its text that
is in the text of none of the specifications, none of the items of the
kind requirement, and none of the terms that it holds.

### 3.14 Specifications

@term specification=v1
@cites #{declared-item=v1}

A specification is a declared item whose declaration word is `@spec`.
It specifies one thing of a system, such as a format, a protocol, or a
set of behaviors.

### 3.15 Terms

@term term=v1
@cites #{declared-item=v1, item-text=v1}

A term is a declared item whose declaration word is `@term`. Its text
states the meaning of one word or one fixed phrase, which other items
can use.

### 3.16 Decision records

@term decision-record=v1
@cites #{declared-item=v1}

A decision record is a declared item whose declaration word is
`@decision`. It records one standing practice of a project, or one
choice with its reason.

### 3.17 Findings and finding classes

@term finding-class=v1
@cites identifiers#{slug=v1}

A finding is a report of one condition at one part of a repository. A
finding class is a kind of finding, which a slug names.

### 3.18 Declared finding classes

@term declared-finding-class=v1
@cites #{declared-item=v1, finding-class=v1, item-text=v1, tree=v1}

A declared finding class is a declared item whose declaration word is
`@finding-class`: a finding class that a repository declares for
itself. In a tree, the text of a declared finding class is the whole of
one file of that tree, its finding-class file.

### 3.19 Names

@term item-name=v1
@cites {
    identifiers#{
        slug=v1, part-name=v1, full-name=v1, name=v1, kind-word=v1,
        citation-entry=v1, target=v1, inline-citation=v1,
    },
    #{
        declared-item=v1, containment=v1, home-design=v1,
        specification=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, tree=v1, finding-class=v1,
        external-item=v1,
    },
}

The name of a declared item in a tree is this:

- of an item of the kind design, a decision record, and a declared
  finding class: the slug of its declaration;
- of a specification, an item of the kind requirement, and a term that
  belongs to an item of the kind design: the name of that item of the
  kind design, `#`, and the part name of the item, which is the part
  name of its declaration, or the slug of its declaration when its
  declaration has no part name;
- of a specification, an item of the kind requirement, and a term that
  belongs to no item of the kind design: the slug of its declaration,
  with `#` and the part name of its declaration after it when its
  declaration has a part name.

These are the sets of names:

- The items of the kind design, the decision records, and the
  specifications, the items of the kind requirement, and the terms that
  belong to no item of the kind design and whose names are slugs share
  one set of slugs, the shared set of slugs.
- The declared finding classes have a set of slugs of their own.
- The specifications, the items of the kind requirement, and the terms
  that belong to one item of the kind design share one set of part
  names.

In a tree, the name of a citation entry, or the name in the target of
an inline citation, names one item or nothing:

- A slug names the item of the shared set of slugs that has it as its
  name. After the kind word `finding-class`, a slug names the declared
  finding class that has it as its name.
- A full name names the specification, the item of the kind
  requirement, or the term whose part name is the part name of the full
  name, of the item of the kind design that the slug of the full name
  names.
- `#` and a part name names the specification, the item of the kind
  requirement, or the term whose part name is that part name, of the
  home design of the citation or of the inline citation. With no home
  design, it names nothing.
- An external id names an external item.
- A name that two or more declared items of one set of names have
  names none of them.

### 3.20 Kinds that kind words state

@term stated-kind=v1
@cites {
    identifiers#{
        kind-word=v1, citation-entry=v1, target=v1, inline-citation=v1,
        extern-line=v1,
    },
    #{
        declared-item=v1, specification=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, external-item=v1, finding-class=v1,
    },
}

A kind word at the start of a citation entry, of the target of an
inline citation, or of the target of an `@extern` line states what the
citation entry or the target names. `design` states an item of the kind
design. `spec` states a specification, or an external item that is a
published standard or a part of one. `req` states an item of the kind
requirement. `term` states a term, or an external item that states the
meaning of one word or one fixed phrase. `decision` states a decision
record. `finding-class` states a declared finding class. No kind word
states an item of another kind of item.

### 3.21 Marks

@term mark=v1
@cites {
    identifiers#{extern-line=v1, kind-word=v1, part-name=v1},
    #{
        accepted-input=v1, declared-item=v1, own-text=v1,
        containment=v1, item-file=v1, item-name=v1, stated-kind=v1,
    },
}

A mark is what an `@extern` line states, when the line is an accepted
input and is in the own text of an item of the kind design: that item of
the kind design holds an item that is what the kind word of the line
states, whose part name is the part name of the line, and whose file is
not the file of the item of the kind design.

### 3.22 Conformance vectors

@term conformance-vector=v1
@cites {
    identifiers#{value=v1},
    text#{conforming-program=v1, input=v1, result=v1, design=v1},
}

A conformance vector states one input of a conforming program of one
design, the design of the vector; one result for that input; and the
values that come with that result.

### 3.23 Vector sets

@term vector-set=v1
@cites {
    text#{whole-number=v1, design=v1, requirement=v1},
    #{conformance-vector=v1, specification=v1, containment=v1},
}

Each conformance vector is given for one specification of its design,
or for the requirements that its design holds directly. The vector set
of a specification is the set of the conformance vectors given for it.
The vector set of a design is the set of the conformance vectors given
for the requirements that it holds directly. Each conformance vector
has a number in its vector set: a whole number of 1 or more.

### 3.24 Groups

@term group=v1
@cites #{vector-set=v1, conformance-vector=v1}

A group is a set of conformance vectors of one vector set, with a name.

### 3.25 Selections

@term selection=v1
@cites {
    identifiers#{citation-entry=v1, vector-selection=v1},
    text#{decimal-numeral=v1, whole-number=v1},
    #{
        item-name=v1, declared-item=v1, specification=v1,
        conformance-vector=v1, vector-set=v1, group=v1,
    },
}

A citation entry whose vector selection is not empty names one
conformance vector, one group, one vector set, or nothing. When the
name of the citation entry names neither a specification nor an item of
the kind design, the citation entry names nothing. Otherwise, take the
vector set of the specification or of the item of the kind design that
its name names:

- When its vector selection has a vector number, the citation entry
  names the conformance vector of that vector set whose number is the
  whole number that the decimal numeral of the vector number writes.
- When its vector selection has a group name, the citation entry names
  the group of that vector set whose name is that group name.
- Otherwise, its vector selection is `[*]`, and the citation entry
  names that vector set.

When no conformance vector or group of that vector set has that number
or that name, or when two or more have it, the citation entry names
nothing. The selection of the citation entry is the set of the
conformance vectors that it names: the one vector, every vector of the
group, every vector of the vector set, or no vector when it names
nothing.

### 3.26 Tests

@term test=v1
@cites {identifiers#{declaration=v1}, #{tree=v1}}

A test is a unit of code that a test framework runs and reports as
passed or failed, such as a test function, or a set of such units, such
as the tests of one `describe` block. The code in the files of a tree
names each test, and no declaration declares one.

### 3.27 Test evidence

@term test-evidence=v1
@cites #{test=v1}

Test evidence is the set of the reports that tests gave in one
execution of their test frameworks: which tests ran, and which of them
passed and which failed.

### 3.28 Sites

@term site=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1},
    #{declared-item=v1, item-text=v1, test=v1, tree=v1},
}

A site is a part of a file of a tree, with citations or inline
citations in it, that is in the text of no declared item and in no
comment on the code of a test. A site has no name.

### 3.29 External items

@term external-item=v1
@cites {
    identifiers#{external-id=v1, part-name=v1},
    #{accepted-input=v1},
}

An external item is a thing outside the repository that an external id
names. Each external id in an accepted input names one external item,
even when nothing outside the repository has that external id. An
external id with `#` and a part name names a part of such an item, and
that part is an external item too.

### 3.30 Revised content

@term revised-content=v1
@cites {
    identifiers#{label=v1},
    text#{input=v1, result=v1},
    #{
        declared-item=v1, own-text=v1, specification=v1, term=v1,
        decision-record=v1, declared-finding-class=v1, item-text=v1,
        containment=v1, conformance-vector=v1, vector-set=v1, group=v1,
        task=v1, plan=v1, test=v1, site=v1, external-item=v1, item=v1,
    },
}

The revised content of an item is this:

- of an item of the kind design, its own text;
- of a specification, its text, without the labels of the declarations
  of the items of the kind requirement and of the terms that it holds;
- of an item of the kind requirement, of a term, of a decision record,
  and of a declared finding class, its text;
- of a conformance vector, its input, its result, and its values;
- of a group and of a vector set, which conformance vectors are in it,
  and the revised content of each.

A task, a plan, a test, a site, and an external item have no revised
content.

### 3.31 Revisions of items

@term item-revision=v1
@cites {
    identifiers#{label=v1, declaration=v1},
    #{
        declared-item=v1, revised-content=v1, conformance-vector=v1,
        group=v1, vector-set=v1, tree=v1, item=v1,
    },
}

A revision of an item is a label that the item has, and it names the
revised content that the item has with that label. The current
revision of an item in a tree is the label that the item has in that
tree, whatever its revised content: for a declared item, the label of
its declaration; for a conformance vector, a group, and a vector set,
the label that the tree gives it. A declared item whose declaration has
no label has no current revision, and an item that has no revised
content has no revision.

### 3.32 Reused labels

@term reused-label=v1
@cites {
    identifiers#{label=v1},
    #{item-revision=v1, revised-content=v1, tree=v1, item=v1},
}

A label that an item has in a tree is a reused label in that tree when,
and only when, another tree of the same repository gives the item the
same label with a different revised content.

### 3.33 Edges

@term edge=v1
@cites {
    identifiers#{
        citation=v1, citation-entry=v1, sinter-tag-word=v1,
        inline-citation=v1, target=v1, vector-selection=v1,
        external-id=v1,
    },
    #{
        item=v1, accepted-input=v1, item-name=v1, external-item=v1,
        selection=v1, tree=v1,
    },
}

An edge is a relation of one kind of edge from an item, its source, to
an item, its cited item. The kinds of edge are these five: `cites`,
`satisfies`, `verifies`, `refines`, and `supersedes`. Each citation
entry of a citation that is an accepted input states one edge, whose
kind of edge is the citation word of the citation without its `@`. Each
inline citation that is an accepted input states one edge, whose kind
of edge is `cites`. The cited item of an edge in a tree is this item, or
none:

- when the vector selection of its citation entry is not empty, the item
  that the citation entry names in that tree;
- otherwise, the item that the name of its citation entry, or the name
  or the external id in the target of its inline citation, names in
  that tree.

When the citation entry or the target names no item in that tree, the
edge has no cited item in that tree.

### 3.34 Sources of edges

@term edge-source=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1},
    text#{line=v1},
    #{
        edge=v1, declared-item=v1, item-text=v1, test=v1, site=v1,
        tree=v1, item=v1,
    },
}

A line of a file of a tree, a citation, or an inline citation stands in
one item, or in none:

- when it is in the text of a declared item, it stands in the innermost
  of the declared items in whose texts it is;
- otherwise, when it is in a comment on the code of a test, it stands in
  the innermost of the tests on whose code that comment is;
- otherwise, when it is in a site, it stands in that site.

The source of an edge is the item in which the citation or the inline
citation that states the edge stands.

### 3.35 Pinned edges

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

### 3.36 Edges of the kind `cites`

@term cites-edge=v1
@cites #{edge=v1, edge-source=v1}

A `cites` edge states that its source refers to its cited item and
rests on what the cited item says.

### 3.37 Edges of the kind `satisfies`

@term satisfies-edge=v1
@cites #{edge=v1, edge-source=v1}

A `satisfies` edge states that its source does what its cited item
states.

### 3.38 Edges of the kind `verifies`

@term verifies-edge=v1
@cites {
    identifiers#{citation-entry=v1, value=v1},
    text#{input=v1, result=v1},
    #{
        edge=v1, declared-item=v1, conformance-vector=v1, group=v1,
        vector-set=v1, selection=v1, edge-source=v1,
    },
}

A `verifies` edge states that its source checks code. When its cited
item is an item of the kind requirement, the edge states that the code
that the source runs meets that item. When its cited item is a
conformance vector, a group, or a vector set, the edge states that the
code that the source runs gives, for the input of each conformance
vector of the selection of the citation entry of the edge, the result
and the values of that vector.

### 3.39 Edges of the kind `refines`

@term refines-edge=v1
@cites #{edge=v1, edge-source=v1}

A `refines` edge states that its source states all or part of its
cited item in more detail.

### 3.40 Edges of the kind `supersedes`

@term supersedes-edge=v1
@cites {
    identifiers#{citation-entry=v1, citation-line=v1},
    #{
        item=v1, edge=v1, declared-item=v1, containment=v1,
        item-name=v1, specification=v1, term=v1, edge-source=v1,
    },
}

A `supersedes` edge states that its source is to replace its cited
item. When the production `every-part` matches the citation entry of a
`supersedes` edge, and its source and its cited item are items of the
kind design, the edge also states this: each specification, each item
of the kind requirement, and each term that the cited item holds is to
be replaced by the declared item with the same kind of item and the same
part name that the source holds, when the source holds one. Only a
`supersedes` edge states that one declared item is to replace another.

### 3.41 Cycles of edges of the kind `supersedes`

@term supersedes-cycle=v1
@cites #{edge=v1, supersedes-edge=v1, declared-item=v1, tree=v1}

A declared item is on a cycle of `supersedes` edges in a tree when, and
only when, it reaches itself in that tree along one or more `supersedes`
edges of that tree, each from its source to its cited item.

### 3.42 Status tags of declared items

@term item-status-tag=v1
@cites {
    identifiers#{
        status-tag=v1, declaration=v1, tag-line=v1,
        continuation-line=v1,
    },
    text#{text=v1, line=v1},
    #{accepted-input=v1, declared-item=v1, item-text=v1},
}

A status tag is among the tag lines of a declaration when the status
tag and the declaration are in one sequence of consecutive lines of one
text, each of which is a tag line or a continuation line. A status tag
that is an accepted input is a status tag of the innermost of the
declared items among the tag lines of whose declarations it is. A
status tag that is among the tag lines of the declaration of no
declared item is a status tag of no declared item.

### 3.43 Acks

@term ack=v1
@cites {
    identifiers#{ack-line=v1, slug=v1},
    text#{text=v1},
    #{
        accepted-input=v1, finding-class=v1, person=v1, agent=v1,
        edge-source=v1, declared-item=v1, item-text=v1, test=v1,
        site=v1, item=v1,
    },
}

An ack is what an `@ack` line that is an accepted input states: a person
or an agent acknowledges the findings of one finding class in one text.
The finding class is the one that the slug of the line names. The text
is the text of the item in which the line stands: the text of a
declared item, the text of the comment on the code of a test that the
line is in, or the part of a file that is a site. The ack is for that
text as it was when the ack was written, and the hash prefix of the
line is the start of the hash of that text. When the subject of the
line is not empty, the ack acknowledges only the findings about what the
subject names. When the subject is empty, it acknowledges every finding
of that finding class in that text.

### 3.44 Valid edges

@term valid-edge=v1
@cites {
    identifiers#{
        kind-word=v1, citation-entry=v1, target=v1, inline-citation=v1,
        citation-line=v1,
    },
    #{
        item=v1, edge=v1, edge-source=v1, stated-kind=v1,
        declared-item=v1, external-item=v1, specification=v1, test=v1,
        conformance-vector=v1, group=v1, vector-set=v1, tree=v1,
        term=v1,
    },
}

An edge is valid in a tree when, and only when, each of these is true
in that tree:

- The edge has a cited item.
- When the citation entry or the target that states the edge starts with
  a kind word: that kind word is `spec` or `term`, when the cited item
  is an external item; and the cited item is what that kind word states,
  when the cited item is not an external item.
- The kinds of item of its source and of its cited item fit its kind of
  edge:
  - for `cites`, the cited item is a declared item, an external item, a
    conformance vector, a group, or a vector set;
  - for `satisfies`, the cited item is an item of the kind requirement;
  - for `verifies`, the source is a test, and the cited item is an item
    of the kind requirement, a conformance vector, a group, or a vector
    set;
  - for `refines`, the source and the cited item are each an item of
    the kind requirement, a specification, or an item of the kind
    design;
  - for `supersedes`, the source is a declared item, and the cited item
    is a declared item of the same kind of item; when the production
    `every-part` matches the citation entry, the source and the cited
    item are items of the kind design.

### 3.45 Valid marks

@term valid-mark=v1
@cites {
    identifiers#{extern-line=v1, kind-word=v1, part-name=v1},
    #{
        mark=v1, declared-item=v1, containment=v1, specification=v1,
        term=v1, item-name=v1, item-file=v1,
    },
}

A mark of an item of the kind design is valid when, and only when, one
of these is true:

- The kind word of its `@extern` line is `spec`, and the item of the
  kind design holds a specification whose part name is the part name of
  the line and whose file is not the file of the item of the kind
  design.
- The kind word of its `@extern` line is `req`, and the item of the kind
  design holds directly an item of the kind requirement whose part name
  is the part name of the line and whose file is not the file of the
  item of the kind design.
- The kind word of its `@extern` line is `term`, and the item of the
  kind design holds directly a term whose part name is the part name of
  the line and whose file is not the file of the item of the kind
  design.

### 3.46 Valid status tags

@term valid-status-tag=v1
@cites {
    identifiers#{status-tag=v1, sinter-tag-word=v1},
    #{
        item=v1, declared-item=v1, item-status-tag=v1, specification=v1,
        term=v1, decision-record=v1,
    },
}

A status tag of a declared item is valid when, and only when, its status
word fits the kind of item of that declared item. `@deprecated` fits the
kinds design, specification, requirement, term, and decision record.
`@rejected` and `@deferred` fit only the kind decision record.

### 3.47 Valid trees

@term valid-tree=v1
@cites {
    identifiers#{extern-line=v1, part-name=v1, label=v1, kind-word=v1},
    text#{design=v1, requirement=v1},
    #{
        tree=v1, item=v1, edge=v1, valid-edge=v1, mark=v1,
        valid-mark=v1, accepted-input=v1, own-text=v1,
        item-status-tag=v1, valid-status-tag=v1, declared-item=v1,
        containment=v1, item-text=v1, item-file=v1, specification=v1,
        term=v1, item-name=v1, supersedes-cycle=v1,
    },
}

A tree is valid when, and only when, each of these is true in it:

- Each edge is valid.
- Each mark of each item of the kind design is valid.
- Each `@extern` line that is an accepted input is in the own text of an
  item of the kind design.
- Each status tag of each declared item is valid.
- Each specification, each item of the kind requirement, and each term
  belongs to exactly one item of the kind design.
- The text of no item of the kind design is in the text of another item
  of the kind design, and the text of no specification is in the text
  of another specification.
- For each specification that an item of the kind design holds, and for
  each item of the kind requirement and each term that it holds
  directly, whose file is not the file of the item of the kind design,
  that item of the kind design has a mark whose `@extern` line has the
  kind word of that item, `spec`, `req`, or `term`, and its part name.
- The declaration of each item of the kind requirement and of each term
  whose declaration has a part name, when it is in a markdown file, is
  in the file of the item of the kind design to which the item belongs,
  or in the file of the specification to which it belongs.
- The declaration of each term that belongs to an item of the kind
  design has a label.
- No two declared items of one set of names have the same name.
- No declared item is on a cycle of `supersedes` edges.

In a valid tree, each item of the kind design is a design, and each item
of the kind requirement belongs to an item of the kind design and is a
requirement of that design. A tree that is not valid still has its
items, its edges, and their states.

### 3.48 Work items

@term work-item=v1
@cites #{task=v1, plan=v1, tree=v1, external-item=v1}

A work item is a task or a plan. No work item is in a file of a tree.
Each work item has a work item id, which never changes, and a display
name, which can change. The display name of a task that names an
external item can be empty.

### 3.49 Tasks

@term task=v1
@cites #{person=v1, agent=v1, external-item=v1}

A task is one piece of work that one person or one agent can finish
alone. The paths of a task are a set of paths: the work of the task can
add, change, or remove a file only when the path of the file is in that
set. A task names at most one external item, which can say what the
work is, and several tasks can name one external item. A task has no
description of its own and no branch.

### 3.50 Promises

@term promise=v1
@cites {
    text#{requirement=v1},
    #{task=v1, edge=v1, edge-source=v1, tree=v1, default-branch=v1},
}

A promise of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and a requirement. It states that the work of the task puts
into the tree of the default branch an edge of that kind of edge whose
cited item is that requirement, from a source in a file whose path is
in the paths of the task. The work of the task keeps the promise when
it does what the promise states.

### 3.51 Plans

@term plan=v1
@cites #{task=v1}

A plan says how a set of tasks and plans gets done.

### 3.52 Waits

@term wait=v1
@cites #{work-item=v1}

A wait is a relation from one work item, the waiting item, to another
work item, the item that it waits for.

### 3.53 What a plan carries out

@term carried-out-item=v1
@cites {text#{requirement=v1, design=v1}, #{plan=v1, specification=v1}}

A plan carries out a set of requirements, specifications, and designs:
its work is for them.

### 3.54 Definitions of work items

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

### 3.55 Changes

@term change=v1
@cites #{default-branch=v1}

A change is a set of commits on a branch, the branch of the change, that
is to merge into the default branch as one unit, such as the commits of
a pull request.

### 3.56 Diffs of changes

@term change-diff=v1
@cites {text#{line=v1}, #{change=v1, tree=v1}}

The diff of a change is the set of the lines that differ between the
tree of the commit from which the branch of the change starts and the
tree of the last commit of the change: the lines that the change adds
and the lines that it removes.

### 3.57 Delivery lines

@term delivery-line=v1
@cites {
    text#{line=v1},
    #{task=v1, promise=v1, work-item=v1, work-item-definition=v1},
}

A delivery line is a line of the message of a commit that states that
the commit completes the work of one task. It names the task by its work
item id. It gives the start of a hash of the paths and the promises of a
definition of the task, and it names each definition of the task whose
paths and promises have a hash with that start. The finishing commit of
a delivery line is the commit in whose message the line is.

### 3.58 Task lines

@term task-line=v1
@cites {text#{line=v1}, #{task=v1, work-item=v1}}

A task line is a line of the message of a commit that names one task by
its work item id, and that states that the commit does part of the work
of the task without finishing it.

### 3.59 Ledger entries

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

### 3.60 The ledger

@term ledger=v1
@cites {text#{whole-number=v1}, #{ledger-entry=v1}}

The ledger of a repository is a sequence of ledger entries. Ledger
entries are appended at the end of the ledger: after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to one ledger, the one that was appended later comes later in
the ledger, whatever times the two ledger entries record. The ledger of
a clone of the repository is the ledger entries that the clone has, in
their order: first the pushed ledger entries that it has, and after
them its provisional ledger entries, which it has appended and not
pushed yet. A push can drop a provisional ledger entry, or give it a
later place, after ledger entries that other clones pushed first. A
point of a ledger is given by the ledger entries before it: the first n
ledger entries of the ledger, for a whole number n of 0 or more. The
point of a ledger entry is the point right before it, and the end of a
ledger is the point after its last ledger entry.

### 3.61 Repairs and voids

@term repair=v1
@cites #{ledger=v1, ledger-entry=v1}

A repair is the one write to a ledger that is not an append at its end.
A repair removes one or more ledger entries from the ledger. For each
ledger entry that it removes, it puts one `void` ledger entry, a void,
in the place of the removed ledger entry: after each ledger entry that
came before the removed one, and before each ledger entry that came
after it. A void records that a repair removed one ledger
entry, and the reason for the removal. A repair makes no other ledger
entry different.

### 3.62 Definition entries

@term definition-entry=v1
@cites #{
    ledger-entry=v1, work-item=v1, task=v1, plan=v1,
    work-item-definition=v1, judgment=v1,
}

A definition entry is a ledger entry of the kind `task` or `plan`. A
`task` ledger entry records one whole definition of one task, and a
`plan` ledger entry records one whole definition of one plan. Each
definition entry records either the first definition of its work item,
or an edit of one earlier definition of the work item, which it names.
A definition entry records no judgment.

### 3.63 Subjects of approval

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

### 3.64 Judgments

@term judgment=v1
@cites {
    text#{requirement=v1},
    #{
        ledger-entry=v1, person=v1, subject-of-approval=v1, task=v1,
        plan=v1, promise=v1, revised-content=v1, item-revision=v1,
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
  one plan without finishing its work, and the reason.

### 3.65 Records of the job

@term job-record=v1
@cites {
    text#{requirement=v1},
    #{
        ledger-entry=v1, job=v1, delivery-line=v1, promise=v1, task=v1,
        work-item-definition=v1, test-evidence=v1, item-revision=v1,
        tree=v1,
    },
}

A record of the job is a ledger entry of the kind `delivered`: it
records what the job observed. A `delivered` ledger entry records that
the job read one delivery line in the commits that the job read, and it
is a `delivered` ledger entry of the task that the line names. For each
promise of the definitions of that task that the line names, it records
the revision that the promised requirement has in the tree that the job
read, and whether the job observed, in that tree, with the test
evidence that it read during its execution, that the work of the task
kept the promise.

### 3.66 The states of work items

@term work-item-state=v1
@cites #{
    ledger=v1, ledger-entry=v1, definition-entry=v1, work-item=v1,
    task=v1, plan=v1, work-item-definition=v1, wait=v1, promise=v1,
    delivery-line=v1, judgment=v1, job-record=v1, state=v1,
}

At each point of a ledger, the ledger entries before that point give
the accepted definition entries, the current definition of each work
item, the work items that exist, the parts of each plan, and the state
of each task and each plan, by these rules:

1. A definition entry is an accepted definition entry when, and only
   when, each of these is true at the point of the definition entry:
   - it records the first definition of its work item, and its work
     item does not exist; or it records an edit of the current
     definition of its work item;
   - its work item is not a task that is done or abandoned, and not a
     plan that is abandoned;
   - the plan that the definition that it records names, when that
     definition names one, exists and is not abandoned;
   - each work item that a wait of that definition waits for exists;
   - the combined relation has no cycle when that definition is the
     current definition of its work item, and each other work item has
     its current definition.
2. The current definition of a work item at a point is the definition
   that the latest accepted definition entry of the work item before
   that point records. A work item exists at a point when, and only
   when, it has a current definition at that point.
3. A work item is a part of a plan at a point when, and only when, it
   exists at that point, its current definition names that plan as its
   plan, and one of these is true:
   - the plan is not abandoned at that point, and the work item is not
     a task that is abandoned at that point;
   - the plan is abandoned at that point, and the work item was a part
     of the plan, and done, at the point of the first `abandoned` ledger
     entry of the plan.
4. A work item is under a plan at a point when, and only when, it is a
   part of the plan, or under a part of the plan, at that point.
5. The combined relation at a point goes from each plan to each of its
   parts, from each work item to each work item that a wait of its
   current definition waits for, and from each task to each work item
   that a wait of the current definition of a plan that the task is
   under waits for. The combined relation has a cycle when, and only
   when, a work item reaches itself along it.
6. Each task that exists at a point is in exactly one of these four
   states at that point:
   - abandoned, when, and only when, an `abandoned` ledger entry of the
     task is before that point, and the task is not done at the point
     of that ledger entry;
   - done, when, and only when, one of these ledger entries is before
     that point, and the task is not abandoned at the point of that
     ledger entry: a `done` ledger entry of the task; or a `delivered`
     ledger entry of the task whose delivery line names the current
     definition of the task at the point of that ledger entry, and
     which records that the work of the task kept each promise of that
     definition; the first of these ledger entries is the ledger entry
     that makes the task done;
   - delivered, when, and only when, it is neither done nor abandoned,
     and a `delivered` ledger entry of the task is before that point;
   - open, when, and only when, it is none of abandoned, done, and
     delivered.
7. A task is unfinished at a point when, and only when, it is open or
   delivered at that point.
8. Each plan that exists at a point is in exactly one of these three
   states at that point:
   - abandoned, when, and only when, an `abandoned` ledger entry of the
     plan is before that point;
   - done, when, and only when, it is not abandoned, it has at least
     one part, and each of its parts is done at that point;
   - open, when, and only when, it is neither abandoned nor done.

### 3.67 States

@term state=v1
@cites #{item=v1, edge=v1, subject-of-approval=v1, tree=v1, ledger=v1}

A state is a named condition of an item, an edge, or a subject of
approval, in a tree, at a point of a ledger, or in a tree at a point of
a ledger.

### 3.68 Deprecated

@term deprecated-item=v1
@cites {
    identifiers#{status-tag=v1},
    #{
        declared-item=v1, item-status-tag=v1, valid-status-tag=v1,
        tree=v1,
    },
}

A declared item is deprecated in a tree when, and only when, it has a
valid `@deprecated` status tag in that tree. That status tag states
that the item no longer applies and that nothing replaces it.

### 3.69 Rejected

@term rejected-record=v1
@cites {
    identifiers#{status-tag=v1},
    #{
        decision-record=v1, item-status-tag=v1, valid-status-tag=v1,
        tree=v1,
    },
}

A decision record is rejected in a tree when, and only when, it has a
valid `@rejected` status tag in that tree. That status tag states that
the choice of the record was considered and not made.

### 3.70 Deferred

@term deferred-record=v1
@cites {
    identifiers#{status-tag=v1},
    #{
        decision-record=v1, item-status-tag=v1, valid-status-tag=v1,
        tree=v1,
    },
}

A decision record is deferred in a tree when, and only when, it has a
valid `@deferred` status tag in that tree. That status tag states that
the choice of the record is not made yet.

### 3.71 Approved and declined

@term approval-state=v1
@cites {
    text#{design=v1, requirement=v1},
    #{
        subject-of-approval=v1, judgment=v1, ledger=v1, ledger-entry=v1,
        revised-content=v1, containment=v1, own-text=v1,
        specification=v1, term=v1, decision-record=v1, tree=v1, item=v1,
    },
}

In a tree, at a point of a ledger, these are the states approved and
declined:

- A subject of approval is approved when, and only when, of the
  `approval` and `decline` ledger entries before that point that record
  a judgment of the revised content that the subject has in that tree,
  the latest is an `approval` ledger entry. It is declined when, and
  only when, the latest of them is a `decline` ledger entry.
- A specification, a requirement or a term that a design holds
  directly, and a decision record are each approved when, and only
  when, the subject of approval that is that item, or that is that
  specification with its requirements and its terms, is approved. Each
  of them is declined when, and only when, that subject of approval is
  declined.
- A requirement or a term that a specification holds is approved when,
  and only when, that specification is approved. It is declined when,
  and only when, that specification is declined.
- A design is approved when, and only when, its own text, each of its
  specifications, and each requirement and each term that it holds
  directly are approved.

### 3.72 Drafts

@term draft-design=v1
@cites {text#{design=v1}, #{approval-state=v1, tree=v1, ledger=v1}}

A design is a draft in a tree, at a point of a ledger, when, and only
when, it is not approved in that tree at that point.

### 3.73 Effective edges of the kind `supersedes`

@term effective-supersedes-edge=v1
@cites #{
    item=v1, edge=v1, edge-source=v1, valid-edge=v1, declared-item=v1,
    item-status-tag=v1, valid-status-tag=v1, approval-state=v1, tree=v1,
    ledger=v1,
}

A `supersedes` edge is effective in a tree, at a point of a ledger,
when, and only when, each of these is true: it is valid in that tree;
its source has no valid status tag in that tree; and, when the
repository needs approval for declared items of the kind of item of its
source, its source is approved in that tree at that point.

### 3.74 Retired

@term retired-item=v1
@cites {
    text#{design=v1},
    #{
        declared-item=v1, specification=v1, edge=v1, item-status-tag=v1,
        valid-status-tag=v1, effective-supersedes-edge=v1,
        supersedes-cycle=v1, containment=v1, tree=v1, ledger=v1,
    },
}

A declared item is retired in a tree, at a point of a ledger, when, and
only when, one of these is true in that tree at that point:

- the item has a valid status tag;
- an effective `supersedes` edge has the item as its cited item, and the
  item is on no cycle of `supersedes` edges;
- the item belongs to a retired item of the kind design or to a retired
  specification.

### 3.75 In force

@term in-force-item=v1
@cites #{declared-item=v1, retired-item=v1, tree=v1, ledger=v1}

A declared item is in force in a tree, at a point of a ledger, when, and
only when, it is not retired in that tree at that point.

### 3.76 Suspect

@term suspect-edge=v1
@cites #{pinned-edge=v1, edge=v1, item-revision=v1, tree=v1}

An edge is suspect in a tree when, and only when, it is pinned, it has a
cited item in that tree, and that cited item has no current revision in
that tree, or a current revision other than the label of the edge.

### 3.77 Met waits

@term met-wait=v1
@cites #{wait=v1, work-item=v1, work-item-state=v1, ledger=v1}

A wait is met at a point of a ledger when, and only when, the work item
that it waits for is done at that point.

### 3.78 Ready tasks

@term ready-task=v1
@cites #{
    task=v1, plan=v1, met-wait=v1, wait=v1, work-item-definition=v1,
    work-item-state=v1, ledger=v1,
}

A task is ready at a point of a ledger when, and only when, it is open
at that point, each wait of its current definition is met at that
point, and each wait of the current definition of each plan that the
task is under at that point is met at that point.

### 3.79 Requirements accounted for

@term requirement-accounted-for=v1
@cites {
    text#{requirement=v1, design=v1},
    #{
        specification=v1, containment=v1, task=v1, plan=v1, promise=v1,
        carried-out-item=v1, work-item-definition=v1,
        work-item-state=v1, ledger=v1, ledger-entry=v1, judgment=v1,
        job-record=v1, item-revision=v1, tree=v1,
    },
}

A requirement is accounted for in a tree, at a point of a ledger, when,
and only when, one of these is true at that point:

- the current definition of an unfinished task has a promise of the
  requirement;
- the current definition of an open plan names, as carried out, the
  requirement, the specification that holds it, or the design that
  holds it;
- the ledger entry that makes a done task done records, for the
  requirement, a revision that is the current revision of the
  requirement in that tree.

## 4. Requirements

### 4.1 The states that statements of agents change

@req limit-agent-statements=v1
@cites {
    text#{text=v1, line=v1, conforming-program=v1},
    #{
        agent=v1, ledger-entry=v1, person=v1, state=v1, change=v1,
        change-diff=v1, edge-source=v1, definition-entry=v1,
        item-revision=v1, work-item=v1, item=v1,
    },
}

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, a ledger entry, or a
message to a person. A conforming program must compute no state from a
statement of an agent, other than from these two:

1. a line of the diff of a change, which is about the item in which it
   stands, when it stands in one; or a line of the message of one of
   the commits of a change that names what it is about by a hash, a
   revision of an item, or a work item id;
2. a definition entry.

### 4.2 The summary of a change

@req show-change-definitions=v1
@cites {
    text#{conforming-program=v1},
    #{
        change=v1, delivery-line=v1, task-line=v1, task=v1, plan=v1,
        work-item-state=v1, definition-entry=v1, ledger=v1,
        ledger-entry=v1, person=v1, agent=v1,
    },
}

The tasks of a change are the tasks that the delivery lines and the
task lines in the messages of the commits of the change name. When a
conforming program gives a summary of a change, the summary must show
every definition entry of each task of the change and of each plan that
a task of the change is under at the end of the ledger that the program
reads, and every definition entry that was written from the branch of
the change, in the order of the ledger, each with the person and the
agent that it records as its writer and with the branch from which it
was written, when there was one.

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
