<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites text=v1
@cites files=v1
@cites data-forms=v1
Specifies the kinds of items that Sinter traces, with their names, regions, extents, revisions, and edges, and the conditions of a valid tree; work items, changes, the ledger, and the actors that write it; the names and meanings of states; the parameters `approval-kinds`, `read-texts`, and `built-in-finding-classes`; and requirements for conforming programs on what they compute states and the validity of trees from, on the treatment of ledger entries and of bindings, on the ledger entries that they append and the repairs that they make when an agent runs them, on the summary of a change, and on the use of declared tasks.

Sinter traces the items of a repository: designs with their
specifications, requirements, and terms, decision records, tests, tasks
and plans, and the items outside the repository that external ids name.
A citation, such as `@verifies packs#limit-size=v2` in a comment on a
test, states an edge: a relation from its source, here the test, to its
cited item, here the requirement `packs#limit-size` with the text that
the label `v2` names. The ledger of a repository records events, such
as the approval that a person gave to one text. Each state, such as in
force, approved, suspect, or done, follows only from the inputs that
section 5.1 lists, such as the trees of the repository, its ledger, and
test evidence.

From Identifiers, the design takes tag lines, tag words, and kind
words; names, labels, and revisions; external ids; citation entries,
their entry names, and their vector selections; the forms of the `@ack`
and `@extern` lines; inline citations and markdown documents; the
matches of inputs by productions; and which tag lines and inline
citations a conforming program gives the result "valid" under a binding
of the parameter `external-namespaces`. From
Text and notation, it takes texts, characters, places, runs, lines, line
feeds, whole numbers, decimal numerals, hex digits, the texts of byte
sequences, and the UTF-8 encodings of texts, and what a design, a
specification, a requirement, a conforming program, an input, and a
result are. From Files and paths, it takes valid paths with their file
names, path sets, valid path sets, and the set of the valid paths that a
path set gives. From Data forms, it takes the hash of a byte sequence:
its SHA-256 digest as 64 hex digits. From the specification
`test-vectors` of Data forms, it takes test-vector file names,
test-vector sets with their set lines, group lines, and vector lines,
and the meaning of a vector.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that a project made |
| [item](sinter:#item=v1) | a thing that Sinter traces, such as a requirement, a test, or a task |
| [kind of item](sinter:#item=v1) | one of the fourteen kinds of item, such as design or task; each item has one |
| repository | a git repository |
| commit, message of a commit, branch, file, path, working tree, clone, push, squash commit, merge base, parent, first parent, pull request | the thing of git, or of a host of git repositories, that has this name |
| [tree](sinter:#tree=v1) | the set of the files of a repository, with their contents, at one commit or in one working tree |
| [text of a file](sinter:#tree=v1) | the text of the byte sequence that is the content of a file, when that byte sequence is valid UTF-8 |
| [valid path of a file](sinter:#tree=v1) | the text of the path of a file, when that path is valid UTF-8 and that text is a valid path, such as `docs/designs/packs.md` |
| [binding of `read-texts`](sinter:#read-text-binding=v1) | for each tree, and for each file of the tree that has a text: whether the file is a markdown file; the read texts of the file, and, in a file that is not a markdown file, the code to which each read text is attached and whether code of the file comes before it; and the tests of the file, each with its name, its code, and the comments on it |
| [read text](sinter:#read-text-binding=v1) | a text that the binding of `read-texts` gives for a file, with the runs of the text of the file that it comes from, one character from each place of those runs, such as a comment without its comment markers |
| [markdown file](sinter:#markdown-file=v1) | a file that the binding of `read-texts` gives as a markdown file, such as a file whose name ends in `.md`; its headings are the headings of the markdown document of its text |
| [default branch](sinter:#default-branch=v1) | the branch into which work on a repository merges |
| actor | a person, an agent, or the job |
| [person](sinter:#person=v1) | a human who works on a repository |
| [agent](sinter:#agent=v1) | a program that uses a language model to write texts for a person, such as code |
| continuous integration | a service that runs checks on the commits of a repository |
| [job](sinter:#job=v1) | an execution of a conforming program that continuous integration starts at each push to the default branch of a repository |
| [accepted input](sinter:#accepted-input=v1) | under a binding of `read-texts` and a binding of `external-namespaces`, a tag line or an inline citation of a read text of a file of a tree, to which a conforming program of Identifiers gives the result "valid" under that binding of `external-namespaces` |
| [declared item](sinter:#declared-item=v1) | what a declaration that is an accepted input declares: an item of the kind design, specification, requirement, term, decision record, or declared finding class |
| [item of the kind design](sinter:#declared-item=v1) | a declared item whose declaration word is `@design` |
| [item of the kind requirement](sinter:#declared-item=v1) | a declared item whose declaration word is `@req` |
| [design](sinter:text#design=v1) | a document that declares, each under a name, obligations and definitions |
| [requirement](sinter:text#requirement=v1) | an obligation that a design declares under a name and states with the word must |
| [specification](sinter:text#specification=v1) | a part of a design that has a name of its own and that declares some of the obligations and definitions of the design |
| [term](sinter:#term=v1) | a declared item whose declaration word is `@term`; its region states the meaning of one word or one fixed phrase |
| normative | stating what a word or a fixed phrase means, or what a conforming program must do; only the regions of terms and of requirements are normative |
| [decision record](sinter:#decision-record=v1) | a declared item whose declaration word is `@decision`; it records one standing practice of a project, or one choice with its reason |
| [finding](sinter:#finding-class=v1) | a report of one condition at one part of a repository |
| [subject of a finding](sinter:#finding-class=v1) | the text that a finding gives to say what it is about |
| [finding class](sinter:#finding-class=v1) | a kind of finding, which a slug names |
| [declared finding class](sinter:#declared-finding-class=v1) | a declared item whose declaration word is `@finding-class`: a finding class that a repository declares for itself |
| [finding-class file](sinter:#declared-finding-class=v1) | the file of a declared finding class: its region is the whole of that file when that file is a markdown file, and otherwise the places of that file that its read texts come from |
| [binding of `built-in-finding-classes`](sinter:#built-in-finding-class=v1) | a finite set of slugs |
| [built-in finding class](sinter:#built-in-finding-class=v1) | a finding class whose slug is in the binding of `built-in-finding-classes`: a finding class that a conforming program has built in; it is not an item and not a declared finding class |
| [part of a file](sinter:#region=v1) | a set of places of the text of a file, which is not empty |
| [share a place](sinter:#region=v1) | two parts of a file share a place when a place is in both |
| [region of a declared item](sinter:#region=v1) | the part of one file that a declared item takes up, its declaration included; when that file is not a markdown file, a read text of the file comes from each place of that part |
| [characters of a part of a file](sinter:#region=v1) | the characters of the runs of that part, in their order in the text of the file, with one line feed between each two runs that follow each other when the first of the two does not end in a line feed; they form one text |
| [innermost](sinter:#region=v1) | of the declared items in whose regions a part of a file is, the one whose region is in the region of each of the others, when exactly one is |
| [file of a declared item](sinter:#item-file=v1) | the file in which the declaration of a declared item is |
| [region of a specification in code](sinter:#specification-region=v1) | for an item of the kind specification whose declaration is in a file that is not a markdown file, the places that the characters of the read text of its declaration that it takes up come from, with the places of the regions of the items of the kind requirement and of the terms that belong to it |
| [scope of a specification](sinter:#specification-scope=v1) | a part of the file of a specification: when its declaration is in a markdown file, its region; otherwise, the places that the read text that its declaration is in comes from, with the places of the code to which that read text is attached, or, when that read text is attached to no code and no code of the file comes before it, each place of the file |
| [home design](sinter:#home-design=v1) | of a tag line or an inline citation: the innermost item of the kind design in whose region it is; otherwise, when the declaration of the innermost item of the kind specification in whose scope it is has a part name, the item of the kind design whose declaration has the slug of that declaration, when the tree has exactly one such item; otherwise, none |
| [containment](sinter:#containment=v1) | the relation in which a design holds specifications, requirements, and terms, and a specification holds requirements and terms |
| [hold](sinter:#containment=v1), [belong to](sinter:#containment=v1) | a design holds each of its specifications, requirements, and terms, and each of them belongs to the design; a specification holds its requirements and its terms in the same way |
| [hold directly](sinter:#containment=v1) | a design holds a requirement or a term directly when the requirement or the term belongs to the design and to no specification |
| [extent of a declared item](sinter:#extent=v1) | for a design, the part of its region that is in the region of no other declared item whose region is in its region; for each other declared item, its region |
| [name of a declared item](sinter:#item-name=v1) | a slug, such as `packs`; for an item that belongs to a design, the name of the design, `#`, and the part name of the item, such as `packs#size`; for an item of the kind specification, requirement, or term that belongs to no design, which only a tree that is not valid has, the slug or the full name in the target of its declaration |
| [set of names](sinter:#item-name=v1) | a set of names in which, in a valid tree, no two declared items have the same name: the shared set of slugs, the set of slugs of the declared finding classes, and the set of part names of each design |
| [entry name](sinter:identifiers#citation-entry=v1) | the part of a citation entry that names its item: a name, an external id with or without a part name, or the slug of a citation entry that `every-part` matches |
| [same item](sinter:#same-item=v1) | of two items of two trees: two declared items with the same kind of item and the same name; two conformance vectors with the same number in vector sets that are the same item; two groups with the same name in vector sets that are the same item; two vector sets of specifications, or of items of the kind design, that are the same item; or two tests whose files have the same path and to which the binding of `read-texts` gives the same name |
| [mark](sinter:#mark=v1) | what an `@extern` line in the extent of a design states: the design holds an item of the kind that the kind word of the line states, with the part name of the line, whose declaration is in another file |
| [value](sinter:identifiers#value=v1) | a text or a fact that a conforming program gives together with a result |
| [conformance vector](sinter:#conformance-vector=v1) | a vector line of a vector set: it states one input of a conforming program of the specification or the design of the vector set, and what that program gives for that input |
| [vector set](sinter:#vector-set=v1) | the test-vector set in the vector file of one specification, or of one design for the requirements that it holds directly; when there is no such file, or its content is not a test-vector set, the empty vector set: no set line, no group, and no conformance vector |
| [vector file](sinter:#vector-set=v1) | the file whose valid path is the valid path of the file of a design with its last file name replaced by the test-vector file name of the name of the design and the part name of one of its specifications, such as `packs.descriptor.test-vectors.jsonl`, or of the name of the design alone, such as `packs.test-vectors.jsonl`; it is in the folder of the file of the design, or in a subfolder of that folder when the name of the design holds `/` |
| [number of a vector](sinter:#conformance-vector=v1) | the number of the vector line of a conformance vector: the value of its member `n`, a whole number of 1 or more |
| [group](sinter:#group=v1) | the conformance vectors of one vector set whose vector lines have one value of the member `group`, with that value as its name |
| [selection](sinter:#selection=v1) | the set of conformance vectors that one citation entry names: one vector, every vector of a group, or every vector of a vector set |
| [test](sinter:#test=v1) | a unit of code that a test framework runs and reports as passed or failed, or a set of such units, which the binding of `read-texts` gives with its name |
| [code of a test](sinter:#test=v1) | the part of its file that the binding of `read-texts` gives as the code of a test |
| [comment on a test](sinter:#test=v1) | a part of its file that the binding of `read-texts` gives as a comment on a test, such as the comment right before a test function |
| [test evidence](sinter:#test-evidence=v1) | the reports that tests gave in one execution, each of which names one test by the path of its file and its name, and says whether the test passed or failed |
| [site](sinter:#site=v1) | a part of a file that holds each place that a citation, an inline citation, or an `@ack` line comes from, and whose places are places of read texts outside the region of every declared item and every comment on a test: in a markdown file, those in the lines from one heading to the next; in another file, those of one read text |
| [external item](sinter:#external-item=v1) | a thing outside the repository that an external id names, such as an issue or a published standard |
| [hash](sinter:data-forms#hash=v1) | the hash of a byte sequence: the 64 hex digits of the digest that SHA-256 gives for it, so that two different byte sequences almost never have the same hash |
| [revised content](sinter:#revised-content=v1) | the part of an item that a revision of the item names, such as the content characters of the extent of a design |
| [content characters](sinter:#revised-content=v1) | the lines of the text that the characters of a part of a file form, other than the `@ack` lines that are accepted inputs, joined with one line feed between each two of them, without the revisions of the citation entries of the citations, and of the targets of the inline citations, that are accepted inputs |
| [revision of an item](sinter:#item-revision=v1) | a label that an item has, which names the revised content that the item has with that label in a given tree |
| [current revision](sinter:#item-revision=v1) | the label that an item has in a given tree: for a declared item, the label of its declaration; for a conformance vector, the revision of its vector line; for a group, the revision of the group line whose `group` value is the name of the group; for a vector set, the revision of its set line |
| [edge](sinter:#edge=v1) | a relation of one kind of edge from a source, or from none, to a cited item, or to none, which a citation entry or an inline citation states |
| [kind of edge](sinter:#edge=v1) | one of `cites`, `satisfies`, `verifies`, `refines`, and `supersedes` |
| [stand in](sinter:#edge-source=v1) | a line of a read text, a citation, or an inline citation stands in the innermost declared item in whose region it is; otherwise in the innermost test that it is in a comment on; otherwise in its site |
| [source](sinter:#edge-source=v1) | the item in which the citation or the inline citation of an edge stands |
| [cited item](sinter:#edge=v1) | the item that the citation entry or the inline citation of an edge names |
| [pinned edge](sinter:#pinned-edge=v1) | an edge whose citation entry or inline citation has a label as its revision |
| [cycle of `supersedes` edges](sinter:#supersedes-cycle=v1) | a sequence of `supersedes` edges along which a declared item leads back to itself: the item is the source of the first edge and the cited item of the last edge, and the cited item of each other edge is the source of the next edge |
| [status tag of a declared item](sinter:#item-status-tag=v1) | a status tag that is an accepted input and that is among the tag lines of the declaration of exactly one declared item, of that declared item |
| [ack](sinter:#ack=v1) | what an `@ack` line states: the findings of one finding class in one part of a file are acknowledged |
| [subject of an `@ack` line](sinter:#ack=v1) | the text that `subject` matches in the match of an `@ack` line, or the empty text when that match uses no `subject` |
| [valid edge](sinter:#valid-edge=v1) | an edge that has a cited item, whose kind word fits its cited item, and whose source and cited item fit its kind of edge |
| [valid mark](sinter:#valid-mark=v1) | a mark whose kind word is `spec`, `req`, or `term`, for which the design holds such an item with the part name of the mark, directly for `req` and `term`, declared in another file |
| [valid status tag](sinter:#valid-status-tag=v1) | a status tag of a declared item whose status word fits the kind of item of that declared item |
| [valid tree](sinter:#valid-tree=v1) | a tree that meets each condition of validity, such as that each edge is valid and that each specification, requirement, and term belongs to exactly one item of the kind design |
| [work item](sinter:#work-item=v1) | a task or a plan |
| [work item id](sinter:#work-item=v1) | the id of a work item, which never changes and which names exactly one work item |
| [display name](sinter:#work-item=v1) | the name of a work item that a person reads, which can change |
| [task](sinter:#task=v1) | one piece of work that one person or one agent can finish alone |
| [work of a task](sinter:#task=v1) | what people and agents change in the files of a repository to finish a task |
| [paths of a task](sinter:#task=v1) | the path set whose set holds the files that the work of a task adds, changes, or removes |
| [path set](sinter:files#path-set=v1) | a finite sequence of texts, its path set members, such as `docs/` followed by `!docs/old/` |
| [set of a path set](sinter:files#path-set-membership=v1) | the paths that a path set gives: for `docs/` followed by `!docs/old/`, `docs/a.md` and not `docs/old/a.md` |
| [file in the set of a path set](sinter:#task=v1) | a file whose valid path is in the set of the path set; a file with no valid path is in the set of no path set |
| [promise](sinter:#promise=v1) | a pair of a kind of edge, `satisfies` or `verifies`, and the name of a requirement, which a task has |
| [keep a promise](sinter:#promise=v1) | a promise is kept in a tree, with test evidence and a path set, when the tree has a valid edge of its kind to its requirement that is not suspect, from a citation in a file that is in the set of that path set, and, for `verifies`, the test evidence reports as passed the test with the path of the file and the name of the source of that edge |
| [plan](sinter:#plan=v1) | a work item that says how a set of tasks and plans gets done |
| [plan of a work item](sinter:#work-item-definition=v1) | the plan that the definition of a work item names |
| [wait](sinter:#wait=v1) | a relation from a work item to another work item that it waits for |
| [carry out](sinter:#carried-out-item=v1) | a plan carries out the requirements, specifications, and designs that its work is for, which it names by their names |
| [definition of a work item](sinter:#work-item-definition=v1) | what a definition entry records about a work item, such as the paths of a task |
| [definition number](sinter:#definition-entry=v1) | the number that a definition entry records: 1 for the first definition of its work item, and one more for each later definition |
| [change](sinter:#change=v1) | a set of commits that is to merge into the default branch as one unit: the commits that its branch reaches and the default branch does not reach |
| [diff of a change](sinter:#change-diff=v1) | the lines that differ between the tree of the merge base of the branch of a change and the default branch, and the tree of the last commit of the change |
| [delivery line](sinter:#delivery-line=v1) | a line of the message of a commit that states that the commit completes the work of a task |
| [finishing commit](sinter:#delivery-line=v1) | the commit in whose message a delivery line is |
| [reach](sinter:#first-parent-line=v1) | a commit reaches itself and each of its ancestors; a branch reaches each commit that the commit to which it points reaches |
| [first-parent line](sinter:#first-parent-line=v1) | the commit to which the default branch points, its first parent, the first parent of that commit, and so on, up to a commit that has no parent |
| [merge commit](sinter:#merge-commit=v1) | of a delivery line, the commit of the first-parent line of the default branch that brought the finishing commit of the line to the default branch; when the finishing commit is itself on the first-parent line, such as a squash commit, the finishing commit itself |
| [task line](sinter:#task-line=v1) | a line of the message of a commit that names a task on which the commit does part of the work |
| tasks of a change | the tasks that the delivery lines and the task lines of a change name |
| [summary of a change](sinter:#show-change-definitions=v1) | the list of the definition entries of the tasks of a change and of the plans that they are under, and of the definition entries that record the branch of the change, which a conforming program gives |
| [ledger](sinter:#ledger=v1) | the sequence of the ledger entries of a repository, in the order in which they were appended |
| [ledger of a clone](sinter:#ledger=v1) | the ledger entries that a clone has: those of the ledger of the repository, and after them its provisional ones |
| [provisional](sinter:#ledger=v1) | a ledger entry is provisional while a clone has it and has not pushed it yet |
| [point of a ledger](sinter:#ledger=v1) | a point between two ledger entries, before the first, or after the last |
| [ledger entry](sinter:#ledger-entry=v1) | a record of one event in the ledger, such as one approval |
| [writer of a ledger entry](sinter:#ledger-entry=v1) | the person, the agent, or the job that a ledger entry records as the one that wrote it |
| [repair](sinter:#repair=v1) | a write that removes ledger entries from the ledger of a repository and puts a void in the place of each |
| [void](sinter:#repair=v1) | a ledger entry that takes the place of a ledger entry that a repair removed |
| [definition entry](sinter:#definition-entry=v1) | a ledger entry that records one definition of one work item |
| [accepted definition entry](sinter:#work-item-state=v1) | a definition entry that gives its work item the definition that it records, because it meets each condition for that at its point |
| [current definition](sinter:#work-item-state=v1) | the definition that the latest accepted definition entry of a work item records |
| [exist](sinter:#work-item-state=v1) | a work item exists at a point of a ledger when it has a current definition at that point |
| [part of a plan](sinter:#work-item-state=v1) | a work item whose current definition names the plan as its plan, unless an abandonment ended that |
| [under a plan](sinter:#work-item-state=v1) | a part of the plan, or under a part of the plan |
| [combined relation](sinter:#work-item-state=v1) | the relation from each plan to its parts, from each work item to the work items that it waits for, and from each task to the work items that the plans that it is under wait for |
| [subject of approval](sinter:#subject-of-approval=v1) | a unit that a person approves or declines as a whole |
| [kind of subject of approval](sinter:#subject-of-approval=v1) | which of five units a subject of approval is: the extent of a design, a specification, a requirement that a design holds directly, a term that a design holds directly, or a decision record |
| [subject of approval of a declared item](sinter:#subject-of-approval=v1) | for a design, its extent; for a specification, a requirement or a term that a design holds directly, or a decision record, the subject of approval that it is; for a requirement or a term that a specification holds, the subject of approval of that specification |
| parameter | a word, such as `approval-kinds`, for which a conforming program takes a binding |
| [binding of `approval-kinds`](sinter:#approval-binding=v1) | a set of kinds of subject of approval |
| [need approval](sinter:#approval-binding=v1) | a subject of approval needs approval when its kind is in the binding of `approval-kinds` |
| [judgment](sinter:#judgment=v1) | a ledger entry that records a decision of a person; an `approval` or a `decline` ledger entry names its subject of approval by the kind of item and the name of its declared item, and the revised content that it judges by a hash |
| [record of the job](sinter:#job-record=v1) | a ledger entry that records what the job observed |
| [state](sinter:#state=v1) | a named condition of an item, an edge, or a subject of approval, in a tree, at a point of a ledger, or both, such as in force or done |
| [retired](sinter:#retired-item=v1) | a declared item is retired when it has a valid status tag, when an effective `supersedes` edge has it as its cited item and it is on no cycle of `supersedes` edges, or when it belongs to a retired design or a retired specification |
| [in force](sinter:#in-force-item=v1) | a declared item is in force when it is not retired |
| [effective](sinter:#effective-supersedes-edge=v1) | a `supersedes` edge is effective when it is valid, its source has no valid status tag, and its source is a declared finding class or is approved |
| [deprecated](sinter:#deprecated-item=v1), [rejected](sinter:#rejected-record=v1), [deferred](sinter:#deferred-record=v1) | the states that the three status words state, through a valid status tag |
| [approved, declined](sinter:#approval-state=v1) | a subject of approval that needs approval is approved, or declined, when, of the `approval` and `decline` ledger entries that judge it and the revised content that it has in the tree, the latest is an `approval`, or a `decline`; a subject of approval that does not need approval is approved when a commit of the first-parent line of the default branch has a tree in which it has the same revised content, and it is never declined; a requirement or a term that a specification holds is approved, or declined, when that specification is; a design is approved when its extent, each of its specifications, and each requirement and each term that it holds directly are approved |
| [draft](sinter:#draft-design=v1) | a design is a draft while it is not approved |
| [suspect](sinter:#suspect-edge=v1) | a pinned edge is suspect when its label is not the current revision of its cited item |
| [open, delivered, done, abandoned](sinter:#work-item-state=v1) | the four states of a task |
| [open, done, abandoned](sinter:#work-item-state=v1) | the three states of a plan |
| [unfinished](sinter:#work-item-state=v1) | a task is unfinished while it is open or delivered |
| final | a state of a work item that no later ledger entry of the ledger ends |
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
| term | a declared item whose declaration word is `@term`, whose region states the meaning of one word or one fixed phrase | a full name, such as `packs#size` | yes |
| decision record | a declared item whose declaration word is `@decision`, which records one practice or one choice | a slug, such as `code-comments` | yes |
| declared finding class | a declared item whose declaration word is `@finding-class`, a finding class that a repository declares for itself | a slug, such as `late-fee` | yes |
| conformance vector | a vector line of a vector set, which states one input of a conforming program and what the program gives for it | its vector set and its number | yes |
| group | the conformance vectors of one vector set whose vector lines have one value of `group` | its vector set and its name | yes |
| vector set | the test-vector set in the vector file of one specification or of one design | its specification or its design | yes |
| task | one piece of work | a work item id | no |
| plan | how a set of tasks and plans gets done | a work item id | no |
| test | a unit of code that a test framework runs | its file and the name that the binding of `read-texts` gives it | no |
| site | a part of a file that holds each place that a citation, an inline citation, or an `@ack` line comes from, and whose places are places of read texts outside the region of every declared item and every comment on a test | no name | no |
| external item | a thing outside the repository | an external id, such as `gh/42` | no |

A conforming program reads some texts of the files of a tree, the read
texts, which a binding of the parameter `read-texts` gives (section
3.2). For example, a binding can give the comments of code, each
without its comment markers, and the paragraphs and the headings of
markdown files outside their code blocks. A conforming program reads the
read texts under one binding of the parameter `external-namespaces` of
Identifiers. An accepted input is a tag line or an inline citation of a
read text to which a conforming program of Identifiers gives the result
"valid" under that binding. Only an accepted input declares an item,
states an edge, a mark, or an ack, or is the status tag of an item. So
`@req limit-size` declares nothing, because its target carries no label.
`@deprecated.` is the status tag of no item, and
`[](sinter:packs#limit-size=v2)` states no edge. A tag line in a code
block of a markdown file, such as `@design packs=v4` in the example of
section 2.3, is in no text that Sinter reads, so for Sinter it declares
nothing.

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

The content of a file is a byte sequence. The text of a file is the
text of that byte sequence, when the byte sequence is valid UTF-8, and a
file whose content is not valid UTF-8 has no text. The path of a file
is a byte sequence too. The valid path of a file is the text of its
path, such as `docs/designs/packs.md`, when its path is valid UTF-8 and
that text is a valid path. The binding of `read-texts` also gives which
files are markdown files, such as the files whose names end in `.md`.

A change is a set of commits that is to merge into the default branch
as one unit, such as the commits of a pull request. It merges from a
branch, the branch of the change. The commits of the change are the
commits that the branch of the change reaches and the default branch
does not reach: a branch reaches the commit to which it points and each
ancestor of that commit. So a merge of the default branch into the
branch of a change adds no commit of the default branch to the change.
The last commit of the change is the commit to which its branch points.
The person who merges the change brings its work to the default branch,
as its commits or as one squash commit. The diff of a change is the set
of the lines that differ between the tree of the merge base of the
branch of the change and the default branch, and the tree of the last
commit of the change: the lines that the change adds, and the lines
that it removes.

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
  the commits of a repository. The job reads test evidence, and that
  test evidence is available only during the job. For each delivery line
  in the commits that it reads, the job observes the promises of the
  task that the line names in the tree of the merge commit of the line
  (section 2.12).

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

- When the declaration has a part name, such as
  `@req packs#limit-size=v1`, the item belongs to the design whose name
  is the slug of the declaration, here `packs`, wherever the declaration
  is.
- When the declaration has no part name and its slug is one segment,
  such as `@spec descriptor=v2` or `@term size=v1`, the item belongs to
  the home design of the declaration: the innermost design in whose
  region the declaration is; otherwise, when the declaration of the
  innermost specification in whose scope the declaration is has a part
  name, the one design whose name is the slug of that declaration.
- Otherwise, the item belongs to no design.

An item of the kind requirement or a term belongs to the innermost
specification in whose scope its declaration is, when the two belong to
the same design, or both to no design. A design holds a requirement or
a term directly when the requirement or the term belongs to the design
and to no specification.

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

A part of a file is a set of places of the text of the file, which is
not empty. The region of a declared item is a part of one file: the part
of that file that the item takes up. Its declaration is in it. In a file
that is not a markdown file, a read text of the file comes from each
place of the region of a declared item, so the region holds no comment
marker. When the regions of two declared items share a place, one of the
two regions is in the other. No place of a file is in the regions of two
different items that are each of the kind requirement or of the kind
term. Of the declared items in whose regions a part of a file is, the
innermost is the one whose region is in the region of each of the
others, when exactly one of them is. The runs of a part of a file are
the longest runs of the text of the file whose places are in the part.
The characters of a part of a file are the characters of its runs, in
their order in the text of the file, with one line feed between each two
runs that follow each other when the first of the two does not end in a
line feed, and they form one text. The extent of a design is the part of
its region that is in the region of no other declared item whose region
is in its region. The extent of each other declared item is its region.
In the example, the extent of `packs` is the part of its region that is
in the region of none of `descriptor`, `size`, and `limit-size`.

The file of a declared item is the file in which its declaration is. A
design can hold a specification, or hold directly a requirement or a
term, whose declaration is in another file. An `@extern` line in the
extent of the design states a mark for such an item, such as
`@extern spec:descriptor`. The kind word of the line gives the kind of
item, and the part name of the line gives the part name of the item. A
requirement or a term of such a specification has no mark of its own:
the mark of its specification covers it.

A specification whose declaration is in another file names its design by
a full name. In a markdown file of its own, it is declared as
`@spec packs#descriptor=v2`. In code, it is declared in a comment, such
as `(* @spec ledger#entry-ids=v2 *)` before an OCaml module. The scope
of a specification is a part of its file:

- for a specification declared in a markdown file, its region;
- for a specification declared in a read text of another file, such as
  a comment, that read text with the code to which the read text is
  attached, such as a module or a function; or the whole file, when the
  read text is attached to no code and no code of the file comes before
  it. The binding of `read-texts` gives this code, and whether code of
  the file comes before the read text.

The home design of a tag line or an inline citation is the innermost
design in whose region it is. When it is in the region of no design, and
the declaration of the innermost specification in whose scope it is has
a part name, its home design is the one design whose name is the slug of
that declaration. So a `@req id-form=v1` in a comment in the module of
the example above belongs to the design `ledger` and to the
specification `ledger#entry-ids`, and `#id-form` names it there. The
region of a specification declared in code is the set of the places
that the characters of the read text of its declaration that it takes
up come from, with the places of the regions of the requirements and
the terms that belong to it. The rest of the code in its scope is not
in its region, and neither is a requirement of another design whose
declaration is in its scope.

Only the regions of terms and of requirements are normative: a term
states what a word or a fixed phrase means, and a requirement states
what each conforming program of the design must do. The rest of the
region of a design and of the regions of its specifications explains the
terms and the requirements and gives examples.

### 2.4 Names

The name of a design, of a decision record, and of a declared finding
class is the slug of its declaration, such as `packs`. The name of a
specification, a requirement, or a term that belongs to a design is a
full name: the name of the design, `#`, and the part name of the item,
such as `packs#descriptor`, `packs#size`, and `packs#limit-size`. Only
a tree that is not valid has an item of the kind specification, an item
of the kind requirement, or a term that belongs to no design (section
2.11). The name of such an item is the name in the target of its
declaration: a slug, such as `limit-size` of `@req limit-size=v1`
outside every design, or a full name, such as `docs#x` of
`@req docs#x=v1` in a tree with no design `docs`. Names come in sets:

- The names of the designs, of the decision records, and of the
  specifications, the items of the kind requirement, and the terms that
  belong to no design and whose names are slugs make one set of slugs,
  the shared set of slugs.
- The declared finding classes have a set of slugs of their own.
- The specifications, the requirements, and the terms of one design
  share one set of part names.

The entry name of a citation entry, and the name or the external id in
the target of an inline citation, name an item in this way:

- When the match of the citation entry, or the match of the destination
  of the inline citation, uses `external-ref`, the text that
  `external-ref` matches, an external id with or without `#` and a part
  name, names an external item (section 2.7). So, when `gh` is the
  namespace name of an external namespace and `billing` is not,
  `@cites gh/42` names the external item `gh/42`, and
  `@cites billing/auth=v1` names the item whose name is the slug
  `billing/auth`.
- Otherwise, a slug, such as `packs`, names the item of the shared set
  of slugs that has it as its name. After the kind word
  `finding-class`, as in `finding-class:late-fee`, a slug names the
  declared finding class that has it as its name.
- A full name, such as `packs#size`, names the specification, the
  requirement, or the term of the design that its slug names, whose
  part name is its part name. When its slug names no design, it names
  nothing. So `docs#x` names nothing in a tree with no design `docs`,
  and no citation can name the item `docs#x` above.
- `#` and a part name, such as `#size` in the example of section 2.3,
  names the specification, the requirement, or the term with that part
  name of the home design of the citation or of the inline citation.
  With no home design, it names nothing.

A name that two or more declared items of one set of names have names
none of them.

An item of one tree and an item of another tree are the same item when
they are declared items with the same kind of item and the same name,
such as the requirement `packs#limit-size` of two commits. Two
conformance vectors are the same item when they have the same number in
vector sets that are the same item. Two groups are the same item when
they have the same name in vector sets that are the same item. Two
vector sets are the same item when their specifications, or their
designs, are the same item. Two tests are the same item when their files
have the same path and the binding of `read-texts` gives them the same
name (section 2.7). So a requirement that moves to another place in its
design, or to another file, stays the same item.

### 2.5 Decision records, finding classes, and acks

A decision record records one standing practice of a project, or one
choice with its reason, such as the record `code-comments`.

A finding is a report of one condition at one part of a repository.
Each finding gives its subject: a text that says what the finding is
about, such as the name of a requirement. A finding class is a kind of
finding, which a slug names. A repository can declare finding classes
of its own. Each such declared finding class is a declared item, and its
file is its finding-class file. In a valid tree, that file is a
markdown file, and the region of the declared finding class is the
whole of that file. A binding of the parameter
`built-in-finding-classes` (section 3.3) gives the slugs of the finding
classes that a conforming program has built in. Each finding class whose
slug is in that binding is a built-in finding class, and it is not an
item and not a declared finding class.

An ack is what an `@ack` line states: the findings of one finding class
in one part of a file are acknowledged. In the line `@ack late-fee
billing#fee=v2 3f2a9c1d`, the slug `late-fee` names the finding class: a
built-in finding class, or a declared finding class. The subject of the
line, `billing#fee=v2`, is the subject of the findings that the line
acknowledges, in the form in which each finding gives its subject. An
`@ack` line with an empty subject acknowledges every finding of its
finding class in that part of a file. An `@ack` line whose slug is the
slug of no built-in finding class and of no declared finding class
states no ack. The part of a file depends on the item in which the
`@ack` line stands (section 2.10):

- for a declared item, the region of that declared item;
- for a test, the comment on that test that the line is in;
- for a site, that site.

The hash of a byte sequence is the 64 hex digits of the digest that
SHA-256 gives for it, so that two different byte sequences almost never
have the same hash. The hash prefix `3f2a9c1d` is the start of the hash
of the UTF-8 encoding of the content characters of that part of a file
(section 2.9), as the part was when the ack was written. So an `@ack`
line that is added or removed, with its line ending, changes no hash of
an ack, and neither does a new pin of a citation.

### 2.6 Conformance vectors

A conformance vector states one example of an input of a conforming
program of a design, and what a conforming program gives for that input:
a result, the values that come with that result, or both. A value is a
text or a fact that a conforming program gives with a result, such as
the slug of a target that a parser gives. What a conformance vector
states follows from the requirements of its design, and the vector
states no requirement of its own.

Each conformance vector is given for one specification of its design,
or for the requirements that its design holds directly. The conformance
vectors of a specification are in one file, its vector file, in the
folder of the file of its design. The name of the vector file is the
test-vector file name of the name of the design and the part name of the
specification. So for the specification `descriptor` of the design
`packs`, whose file is `docs/designs/packs.md`, the vector file is
`docs/designs/packs.descriptor.test-vectors.jsonl`. The vector file of
the design itself, for the requirements that it holds directly, is
`docs/designs/packs.test-vectors.jsonl`. A specification declared in
code has its vector file in the folder of the file of its design too.
When the name of the design holds `/`, so does the test-vector file
name, and the vector file is in a subfolder of the folder of the file
of the design. So for the specification `ids` of a design `ledger/core`
whose file is `docs/designs/core.md`, the vector file is
`docs/designs/ledger/core.ids.test-vectors.jsonl`. In a valid tree, no
file is the vector file of two specifications or designs (section
2.11).

The content of a vector file is a test-vector set, as the specification
`test-vectors` of Data forms gives it: a set line, then a group line for
each group, then a vector line for each vector. That test-vector set is
the vector set of the specification or of the design, and each of its
vector lines is one conformance vector. The member `n` of a vector line
gives the number of the conformance vector, a whole number of 1 or more.
A group is the set of the conformance vectors of one vector set whose
vector lines have the same value of the member `group`, with that value
as its name. The member `rev` of each line gives the current revision of
the conformance vector, of the group, or of the vector set (section
2.9). When a tree has no vector file for a specification or a design, or
when the content of its vector file is not a test-vector set, its vector
set is the empty vector set: no set line, no group, and no conformance
vector. A test-vector set that has a set line and no vector line is not
the empty vector set.

A citation entry of `@cites` or `@verifies` can name one conformance
vector, one group, or one vector set. The selection of the citation
entry is the set of the vectors that it names in this way:

| citation entry | cited item | selection |
|---|---|---|
| `data-forms#toml[12]=v1` | the vector 12 of the vector set of the specification `data-forms#toml` | that one vector |
| `data-forms#toml[offsets][*]=v2` | the group `offsets` of that vector set | every vector of the group |
| `data-forms#toml[*]=v3` | the vector set of `data-forms#toml` | every vector of the vector set |
| `identifiers[37]=v1` | the vector 37 of the vector set of the design `identifiers` | that one vector |

The entry name of such a citation entry names a specification or a
design. A citation entry whose entry name names another item, such as a
requirement, names nothing and selects nothing. A citation entry also
names nothing when no vector or group of the vector set has its number
or its group name, or when two or more have it.

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
the tests of one `describe` block, is a test too. The binding of
`read-texts` gives the tests of each file of a tree: for each test, its
name, its code, and each comment on it. The code of a test is the part
of its file that the test takes up. A comment on a test is a comment
that is attached to the code of the test, such as the comment right
before a test function. The code names each test, so a test has no
declaration. Test evidence is the set of the reports that tests gave
in one execution of their test frameworks. Each report names one test,
by the path of its file and the name that the binding of `read-texts`
gives it, and it says whether the test passed or failed. Test evidence
reports a test as passed when it has at least one report that the test
passed and no report that the test failed.

A site is an item with no name. It is a part of a file that holds each
place that a citation, an inline citation, or an `@ack` line comes
from, and whose places are places of read texts outside the region of
every declared item and every comment on a test. In a markdown file, the
site of a line is made of the places of the read texts in the lines of
the file from the last heading at or before the line, or from the start
of the file, to the line before the next heading, or to the end of the
file: the innermost section of the line, without the sections in that
section. In another file, the site of a line is made of the places of
the read text that the line is in, such as one comment. A site holds no
place of the region of a declared item and no place of a comment on a
test. So no two sites of one file share a place, and a section or a
comment whose only tag lines are `@ack` lines can be a site.

An external item is an item outside the repository that an external id
names, such as the issue `gh/42` or the standard `rfc/8259`. Each text
that `external-id` matches in the match of an accepted input is an
external id, and it names an external item, even when nothing outside
the repository has that external id. A text that `external-ref` matches,
with `#` and a part name after the external id, such as
`rfc/8259#section-6`, names a part of such an item, and that part is an
external item too. An external item has no revision. An external item
can be a published standard, or a part of one. It can also state the
meaning of one word or one fixed phrase, such as the external item
`rfc/8259#value`.

### 2.8 Kind words

A kind word at the start of a citation entry, of the target of an
inline citation, or of the target of an `@extern` line states what the
citation entry or the target names:

| kind word | what the citation entry or the target names |
|---|---|
| `design` | an item of the kind design |
| `spec` | an item of the kind specification, or an external item that is a published standard or a part of one |
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

Each design, specification, requirement, term, decision record,
declared finding class, conformance vector, group, and vector set has a
revised content: the part of the item that a revision of the item
names.

| item | revised content |
|---|---|
| design | the content characters of its extent |
| specification | the content characters of its extent, with the regions of its requirements and its terms in it, without the characters of the labels of the declarations of those requirements and terms |
| requirement, term, decision record, declared finding class | the content characters of its extent |
| conformance vector | the members `group`, `input`, `result`, and `values` that the object of its vector line has |
| group | which conformance vectors are in it, and the revised content of each |
| vector set | which conformance vectors are in it, and the revised content of each |
| task, plan, test, site, external item | none: the item has no revision |

The current revision of an item in a tree is the label that the item
has in that tree, whatever its revised content. For a declared item, it
is the label of its declaration. For a conformance vector, it is the
revision of its vector line; for a group, the revision of the group
line whose `group` value is the name of the group; and for a vector
set, the revision of its set line. A declared item whose declaration has
no label, such as `@term invoice`, has no current revision, and neither
has the empty vector set. A revision of an item is a label that the item
has, and it names the revised content that the item has with that label
in a given tree. The revised content of a declared item is a text, so
two revised contents of declared items are the same when they are the
same text, wherever their characters are in the files.

The content characters of a part of a file are the lines of the text
that its characters form, other than the `@ack` lines that are accepted
inputs, joined with one line feed between each two of them, without the
revision of each citation entry of a citation that is an accepted input
and the revision in the target of each inline citation that is an
accepted input. So a new ack, or a new pin of a citation, in the region
of an item does not change its revised content. An `@ack` line in a
code block of a markdown file is not an accepted input, so it stays in
the content characters.

So an edit of a requirement or a term inside a specification changes
the revised content of that requirement or term and of the
specification. An edit of the extent of a design changes the revised
content of the design alone. An edit of one vector changes the revised
content of its group and of its vector set.

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

### 2.10 Edges

An edge is a relation of one kind of edge from a source, or from none,
to a cited item, or to none. Each citation entry of a citation that is
an accepted input states one edge. The kind of edge is the citation word
without its `@`. The cited item of the edge is the item that the
citation entry names: by its selection when it has a vector selection,
and by its entry name otherwise. An inline citation that is an accepted
input, such as `[the limit](sinter:packs#limit-size=v2)`, states one
edge of the kind `cites`, and the name or the external id in its target
names the cited item. When the citation entry or the target names no
item, the edge has no cited item.

A line of a read text, a citation, or an inline citation stands in one
item, or in none:

1. when it is in the region of a declared item, in the innermost of the
   declared items in whose regions it is;
2. otherwise, when it is in a comment on a test, in the innermost of the
   tests that it is in a comment on: the test whose code is in the code
   of each of the others;
3. otherwise, in its site.

The source of an edge is the item in which its citation or its inline
citation stands, or none when the citation or the inline citation stands
in no item. So `@supersedes packs#old=v1` in the region of a
requirement `packs#new` has that requirement as its source, and not the
design `packs`. A `@verifies` line in a comment on a test has that test
as its source.

| kind of edge | what it states |
|---|---|
| `cites` | the source refers to the cited item and rests on what the cited item says |
| `satisfies` | the source does what the cited item states |
| `verifies` | the source checks that the code it runs meets the cited requirement, or gives the result and the values of each vector of the selection |
| `refines` | the source states all or part of the cited item in more detail |
| `supersedes` | the source is to replace the cited item |

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
term `media#x` of the same kind of item, when `media` holds one. A
declared item is on a cycle of `supersedes` edges when it leads back to
itself along `supersedes` edges, effective or not: when the item is the
source of the first edge of a sequence of `supersedes` edges and the
cited item of its last edge, and the cited item of each other edge of
the sequence is the source of the next edge.

### 2.11 Valid trees

The meanings of the sections above apply in every tree. A tree is valid
when it also meets each of these conditions:

| condition | a tree that breaks it |
|---|---|
| each edge is valid: it has a cited item; a kind word at its start is `spec` or `term` for an external item, and states what its cited item is for each other item; and the kinds of its source and of its cited item fit its kind of edge | `@verifies packs#limit-size=v2` in a section of a markdown file, whose source is a site and not a test |
| each mark is valid: its kind word is `spec`, `req`, or `term`, and the design holds such an item with its part name, directly for `req` and `term`, declared in another file | `@extern design:docs` |
| each `@extern` line is in the extent of an item of the kind design | `@extern spec:descriptor` in the region of a requirement |
| each status tag is among the tag lines of the declaration of exactly one declared item | `@deprecated` in a paragraph with no declaration |
| each status tag of a declared item fits the kind of item of that declared item | `@rejected` in the tag lines of a requirement |
| the declaration of each item of the kind design is in a markdown file | `@design ledger=v1` in a comment in code |
| each item of the kind specification, requirement, or term belongs to exactly one item of the kind design | a `@req` line outside every design |
| each item of the kind specification, requirement, or term whose declaration is in the region of an item of the kind design belongs to that item | `@spec docs#x=v1` in the region of the design `packs` |
| each item of the kind requirement or term whose declaration is in the region of a specification belongs to that specification | `@req docs#y=v1` in the region of the specification `packs#descriptor` |
| the region of no item of the kind design is in the region of another one, and the declaration of no specification is in the scope of another specification | `@design docs=v1` in a section of the design `packs` |
| each specification, and each requirement and each term held directly, whose declaration is outside the file of its design has a mark | a specification in a file of its own, with no `@extern` line in the design |
| each requirement and each term whose declaration has a part name, and is in a markdown file, is declared in the file of its design or in the file of its specification | `@req docs#x=v1` in a markdown file of its own |
| each term has a label | `@term invoice` |
| the declaration of each declared finding class is in a markdown file | `@finding-class late-fee=v1` in a comment in code |
| no two declared finding classes have the same file | two `@finding-class` declarations in one file |
| no declared finding class has the slug of a built-in finding class | `@finding-class x=v1`, when `x` is in the binding of `built-in-finding-classes` |
| no two declared items of one set of names have the same name | two declarations `@decision cache=v1` |
| no file is the vector file of two items | a design `a` with a specification `b`, and a design `a.b`, whose files are in one folder |
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
of that design. In a valid tree, a specification whose declaration is
in a markdown file other than the file of its design is in the region of
no design. A tree that is not valid still has its items, its edges, and
their states. So an item of the kind requirement outside every design
whose declaration has a slug, such as `@req limit-size=v1`, has that
slug as its name, in the shared set of slugs, and edges can cite it. An
item whose declaration has a full name, such as `@req docs#x=v1` in a
tree with no design `docs`, has that full name as its name, and no
citation names it (section 2.4).

### 2.12 Tasks and plans

A task is one piece of work that one person or one agent can finish
alone. The work of a task is what people and agents change in the files
of the repository to finish the task. A plan says how a set of tasks and
plans gets done. Each work item has a work item id, which never changes
and which names exactly one work item, and a display name, which can
change.

A task has:

- its paths: a path set, whose set holds the files that the work of the
  task adds, changes, or removes, so the work of a task whose paths are
  the empty path set changes no file;
- its promises: each a pair of a kind of edge, `satisfies` or
  `verifies`, and the name of a requirement, such as
  `verifies ledger#check-ids`;
- at most one external item, such as an issue, which can say what the
  work is; several tasks can name one external item;
- at most one plan, its plan;
- its waits.

A file is in the set of a path set when its valid path is in that set.
So a file whose path is not valid UTF-8, or whose path is not a valid
path, is in the set of no path set.

A promise is kept in a tree, with test evidence and a path set, when
that tree has an edge of the kind of edge of the promise whose cited
item is the requirement that the promise names, and when that edge is
valid, is not suspect, and has its citation in a file that is in the set
of that path set. For a `verifies` promise, that test evidence also
reports as passed the test with the path of the file and the name of
the source of that edge. The job judges each promise of a definition
of a task with the paths of that definition (section 2.13). An edge that
was in the tree before the work on the task started keeps the promise
too.

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
gives a new definition, which a new definition entry records with its
definition number: 1 for the first definition of the work item, and one
more for each later definition. So the definition entry with the
definition number n records an edit of the definition with the
definition number n − 1, and a definition with the same parts as an
earlier one is still a new definition.

At each point of a ledger (section 2.13), each work item that exists has
a current definition. A work item is a part of a plan when its current
definition names the plan as its plan. Two exceptions apply. An
abandoned task, or an abandoned plan, is a part of no plan. And when a
person abandons a plan, each of its parts that is not done stops being a
part of it. Each of its done parts stays a part of it only while it
stays done: once that part is not done, it is no longer a part of the
abandoned plan, even when it is done again later. So a done plan that
is open again, such as after it gets a new part, is no longer a part of
the abandoned plan, and work under it is never again under the abandoned
plan. A work item is under a plan when it is a part of the plan, or
under a part of the plan.

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
cycle is not an accepted definition entry (section 2.13). No other
ledger entry adds a relation to the combined relation. So the combined
relation never has a cycle: no work item is under itself, and no work
item waits for itself, directly or through a plan. For example, a task
that waits for the plan that it is under would make a cycle: the plan is
done only when the task is done, and the task waits until the plan is
done.

A commit states its link to a task in a line of its message:

- A delivery line, such as `Delivers: t-3f2a9c1d7e0b 05ef56`, states
  that the commit completes the work of the task. It names the task by
  its work item id. Its last six characters, here `05ef56`, are the
  start of the hash of a byte sequence that encodes the paths and the
  promises of a definition of the task. The line names each definition
  of the task for which that hash has that start. The finishing commit
  of the line is the commit in whose message the line is.
- A task line, such as `Task: t-3f2a9c1d7e0b`, states that the commit
  does part of the work of the task, without finishing it.

The tasks of a change are the tasks that its delivery lines and its
task lines name.

A commit reaches itself and each of its ancestors. The first-parent line
of the default branch is the commit to which the default branch points,
its first parent, the first parent of that commit, and so on, up to a
commit that has no parent. The merge commit of a delivery line is the
commit of the first-parent line that brought the finishing commit of the
line to the default branch: the commit of the first-parent line that
reaches the finishing commit, and that has no parent or whose first
parent does not reach the finishing commit. So when a person merges a
change with a commit whose first parent is the commit to which the
default branch pointed before and whose second parent is the last commit
of the change, the merge commit of each delivery line in the commits of
the change is that commit. When a person brings the work of a change to
the default branch as one squash commit, the finishing commit of a
delivery line in the message of the squash commit is that squash commit,
which is on the first-parent line, so the merge commit of that line is
its finishing commit. A delivery line whose finishing commit no commit
of the first-parent line reaches has no merge commit.

### 2.13 The ledger

The ledger of a repository is a sequence of ledger entries. Ledger
entries are appended at the end of the ledger: after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to one ledger, the one that was appended later comes later in
the ledger, whatever times the ledger entries record. Each clone of the
repository has a ledger of its own: the ledger entries that the clone
has, in their order. First come the ledger entries of the ledger of the
repository that the clone has, and after them its provisional ledger
entries, which it has appended and not pushed to the ledger of the
repository yet. A push can drop a provisional ledger entry, or give it
a later place, after ledger entries that other clones pushed first.

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
work item id, and it records a definition number. A `task` ledger entry
records a definition of a task, and a `plan` ledger entry records a
definition of a plan. The first accepted definition entry of a work
item decides whether the work item is a task or a plan. A definition
entry is an accepted definition entry when each of these is true at its
point:

1. Its definition number is 1, and its work item does not exist yet; or
   its definition number is one more than that of the latest accepted
   definition entry of its work item, and it is a `task` ledger entry
   for a task or a `plan` ledger entry for a plan.
2. Its work item is not a task that is done or abandoned, and not a plan
   that is abandoned.
3. The plan that its definition names, when it names one, exists, is a
   plan, and is not abandoned.
4. Each work item that a wait of its definition waits for exists.
5. When its definition is the current definition of its work item, the
   combined relation has no cycle.
6. When it is a `task` ledger entry, the paths of its definition are a
   valid path set.

The current definition of a work item at a point is the definition that
the latest accepted definition entry of the work item before that point
records. A work item exists at a point when it has a current definition
at that point. A definition entry that is not an accepted definition
entry changes no definition and no state.

A `done` ledger entry records, for each requirement that the task
promises, the revision of that requirement at which a person judged the
work of the task finished. A `delivered` ledger entry records, for each
definition of the task that its delivery line names, and for each
promise of that definition, the revision that the promised requirement
has in the tree of the merge commit of the delivery line, and whether
the promise was kept in that tree, with the test evidence that the job
read and with the paths of that definition. That test evidence is
available only during the job, so no later reader can observe it again.
A `done`, an `abandoned`, or a `delivered` ledger entry counts only when
the work item that it names exists at the point of that ledger entry.
A ledger entry that does not count changes no state.

### 2.14 States

A state is a named condition of an item, an edge, or a subject of
approval, in a tree, at a point of a ledger, or both. A conforming
program computes each state, and the validity of each tree, only from
the inputs that section 5.1 lists. It gives the same states for two
ledgers whose ledger entries differ only in the writers, the persons,
and the branches that they record (section 5.2). It computes the states
of one tree, of one point of a ledger, or of one tree at one point of a
ledger, and the validity of a tree, under one binding of each parameter
that section 5.3 names, such as `approval-kinds` (section 3.1). No
ledger entry records a state.

| state | of | meaning |
|---|---|---|
| in force | a declared item | the item applies: its authors still agree with it, no other declared item replaces it, and the design or the specification that holds it is in force |
| retired | a declared item | the item is not in force |
| effective | a `supersedes` edge | the edge retires its cited item, unless that item is on a cycle of `supersedes` edges |
| deprecated | a requirement, a term, a specification, a design, or a decision record | a valid `@deprecated` status tag of the item states that it no longer applies and that nothing replaces it |
| rejected | a decision record | a valid `@rejected` status tag of the record states that its choice was considered and not made |
| deferred | a decision record | a valid `@deferred` status tag of the record states that its choice is not made yet |
| approved | a subject of approval, or a design, a specification, a requirement, a term, or a decision record | for a subject of approval that needs approval, the latest judgment of it and of the revised content that it has in the tree is an approval; for another subject of approval, a commit of the first-parent line of the default branch has a tree that gives it the revised content that it has in the tree; a design is approved when its extent, its specifications, and the requirements and the terms that it holds directly are approved |
| declined | a subject of approval, or a specification, a requirement, a term, or a decision record | the subject of approval needs approval, and the latest judgment of it and of the revised content that it has in the tree is a decline |
| draft | a design | the design is not approved |
| suspect | a pinned edge | the label of the edge is not the current revision of its cited item |
| open | a task | the task exists, and it is neither delivered, done, nor abandoned |
| delivered | a task | the job recorded a delivery line of the task, and the task is neither done nor abandoned |
| done | a task | a `done` ledger entry of the task, or a `delivered` ledger entry of the task whose delivery line names the definition of the task that was current at its point and which records that each promise of that definition was kept in the tree of the merge commit of that line, is before the point, and the task was not abandoned at the point of that ledger entry |
| abandoned | a task | a person ended the task before it was done |
| ready | a task | the task is open, and each work item that it waits for, itself or through a plan, is done |
| done | a plan | the plan is not abandoned, has at least one part, and each of its parts is done |
| abandoned | a plan | a person ended the plan |
| open | a plan | the plan exists and is neither done nor abandoned |
| accounted for | a requirement | work for the requirement is under way, or was finished at its current revision |

A subject of approval is a unit that a person approves or declines as a
whole: the extent of a design, a specification with its requirements
and its terms, a requirement that a design holds directly, a term that a
design holds directly, or a decision record. These five are the kinds of
subject of approval. A subject of approval of one tree and a subject of
approval of another tree are the same subject of approval when their
declared items are the same item. The subject of approval of a design
is its extent. The subject of approval of a specification, of a
requirement or a term that a design holds directly, and of a decision
record is the subject of approval that it is. The subject of approval of
a requirement or a term that a specification holds is the subject of
approval of that specification. A subject of approval needs approval
when its kind is in the binding of the parameter `approval-kinds`
(section 3.1).

For a subject of approval that needs approval, the latest judgment of
it, and of the revised content that it has in the tree, decides: the
subject of approval is approved when that judgment is an `approval`
ledger entry, and declined when it is a `decline` ledger entry. A
subject of approval that does not need approval is approved in a tree
when a commit of the first-parent line of the default branch has a tree
in which the same subject of approval has the same revised content: the
merge into the default branch is its approval. A subject of approval
that does not need approval is never declined. A requirement or a term
that a specification holds is approved when that specification is
approved, and declined when it is declined. A design is approved when
its extent, each of its specifications, and each requirement and each
term that it holds directly are approved.

An `approval` or a `decline` ledger entry records the kind of item and
the name of the declared item of its subject of approval, and the hash
of the UTF-8 encoding of the revised content that it judges. It judges
each subject of approval whose declared item has that kind of item and
that name, in each tree, and each revised content with that hash. So
an edit of the revised content of a subject of approval makes each
earlier judgment of it no longer a judgment of the revised content that
it has, and an edit back makes that judgment count again.

A declared item is retired when one of these is true: it has a valid
status tag, such as `@deprecated`; an effective `supersedes` edge has it
as its cited item, and it is on no cycle of `supersedes` edges; or it
belongs to a retired design or a retired specification. A `supersedes`
edge is effective when it is valid, its source has no valid status tag,
and its source is a declared finding class, which has no subject of
approval, or is approved. So a `supersedes` edge whose source waits
for a judgment, or for its merge into the default branch, retires
nothing yet, and a `supersedes` edge from a design retires nothing until
the whole design is approved. An effective `supersedes` edge does not
retire a declared item that is on a cycle of `supersedes` edges.

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
  current at the point of that ledger entry, and which records that each
  promise of that definition was kept in the tree of the merge commit of
  its delivery line.
- A task is delivered when it is neither done nor abandoned, and a
  `delivered` ledger entry of the task is before the point.
- A task is open when it is in none of these three states.

So a `delivered` ledger entry for a delivery line that names only an
earlier definition of the task, and not the current one, makes the task
delivered and not done. A task is unfinished while it is open or
delivered. The states done and abandoned of a task are final: no later
ledger entry ends them, so the task keeps the state at each later point
of the ledger, and more work on it is a new task. A repair that removes
the ledger entry that gave the state ends it. The state
abandoned of a plan is final too. The state
done of a plan is not final: a done plan is open again while it has a
part that is not done. The state of a task records work that happened,
and it does not state that the code stays correct.

A requirement is accounted for when one of these is true:

- an unfinished task has a promise that names it;
- an open plan names, as carried out, the requirement, its
  specification, or its design;
- the ledger entry that made a task done records, for the requirement,
  the revision that is its current revision.

A promise and a plan name a requirement by its name, so they name the
same requirement in each tree in which that requirement has that name.

### 2.15 Statements of agents

A statement of an agent is a text that an agent writes, such as a line
of a file, a line of the message of a commit, a ledger entry, or a
message to a person. A conforming program computes each state only from
the inputs that section 5.1 lists, and it gives the same states for two
ledgers whose ledger entries differ only in the writers, the persons,
and the branches that they record (section 5.2). When its input states
that an agent runs it, a conforming program appends to the ledger no
ledger entry other than a definition entry, and it makes no repair
(section 5.4). A statement of an agent changes a state in one of
two ways only:

1. as a line of the diff of a change, which is about the item in which
   it stands; or as a line of the message of one of the commits of a
   change that names what it is about by a hash, a revision of an item,
   or a work item id, such as a delivery line or a task line;
2. as a definition entry.

The person who merges a change can see both: the lines in the change
itself, and, in the summary of the change (section 5.5), every
definition entry of the tasks of the change and of the plans that they
are under, and every definition entry that records its branch.
A statement of an agent outside these two ways, such as a message of an
agent that its work is done, changes no state.

A session is one execution of an agent on its work. The agent can
declare a task as the work of its session. The declared task changes
no state. Sinter uses it only to narrow the brief of the session: the
text that Sinter gives the agent about its work for that session.

## 3. Parameters

### 3.1 `approval-kinds`

The parameter `approval-kinds` gives the kinds of subject of approval
that need approval. A binding of it is a set of kinds of subject of
approval, so each of its members is one of these five: the extent of
a design, a specification, a requirement that a design holds directly,
a term that a design holds directly, and a decision record. The binding
can be the empty set, and then no subject of approval needs approval.
The judgments of people decide whether a subject of approval that needs
approval is approved or declined, and the merge into the default branch
approves each other subject of approval (section 2.14).

### 3.2 `read-texts`

The parameter `read-texts` gives the texts that a conforming program
reads in the files of a tree, and the tests in those files. A binding of
it gives, for each tree, and for each file of the tree that has a text,
whether the file is a markdown file, the read texts of the file, and the
tests of the file. Each read text is a text, with the runs of the text
of the file that it comes from: each character of the read text comes
from one place of those runs, in their order, and no two read texts of
one file come from one place. In a file that is not a markdown file,
the binding also gives, for each read text, the code to which the read
text is attached, or none, and whether code of the file comes before the
read text. Each test has a name, and its code and each comment on it are
each a set of runs of the text of the file. For example, a binding can
give the comments of code, each without its comment markers, and the
paragraphs and the headings of markdown files outside their code blocks.

### 3.3 `built-in-finding-classes`

The parameter `built-in-finding-classes` gives the finding classes that
a conforming program has built in. A binding of it is a finite set of
slugs, the slugs of those finding classes. The binding can be the empty
set, and then no finding class is built in.

## 4. Definitions

### 4.1 Items

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

### 4.2 Trees

@term tree=v1
@cites {
    text#{
        byte-sequence=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1,
        text=v1,
    },
    files#{path=v1},
}

A tree of a git repository is the set of the files of the repository,
with their contents, at one commit or in one working tree of the
repository. The tree of a commit is the tree at that commit. The content
of a file is a byte sequence. The text of a file of a tree is the text
of its content in that tree, when that content is valid UTF-8. A file
whose content in a tree is not valid UTF-8 has no text in that tree. The
path of a file is a byte sequence. The valid path of a file is the text
of its path, when its path is valid UTF-8 and that text is a valid path.
A file whose path is not valid UTF-8, or whose path has a text that is
not a valid path, has no valid path.

### 4.3 Bindings of `read-texts`

@term read-text-binding=v1
@cites {
    text#{
        text=v1, run=v1, character=v1, place=v1, line=v1,
        whole-number=v1,
    },
    #{tree=v1},
}

A binding of the parameter `read-texts` gives, for each tree, and for
each file of that tree that has a text in that tree:

- whether the file is a markdown file;
- the read texts of the file: each a text, with the runs of the text of
  the file that it comes from;
- when the file is not a markdown file, for each read text of the file:
  the runs of the text of the file that are the code to which the read
  text is attached, or no runs when the read text is attached to no
  code; and whether code of the file comes before the read text;
- the tests of the file: each with a name, which is a text; with the
  runs of the text of the file that are its code; and with the runs of
  the text of the file that are each comment on it.

No place is a place of two runs of one read text, and no place of the
text of a file is a place of a run of two different read texts of that
file. A read text has one character for each place of its runs. For
each whole number k from 1 to the number of the characters of a read
text, the k-th character of the read text is the character at the k-th
of the places of its runs, in their order in the text of the file, and
it comes from that place. A read text comes from each place of its
runs. A line or another run of a read text is in a set of places of the
text of the file when each of its characters comes from a place of that
set.

### 4.4 Markdown files

@term markdown-file=v1
@cites {
    identifiers#{link=v1},
    text#{text=v1},
    #{tree=v1, read-text-binding=v1},
}

Under a binding of `read-texts`, a markdown file of a tree is a file of
the tree that the binding gives as a markdown file. A heading of a
markdown file is a heading of the markdown document of the text of the
file.

### 4.5 Default branches

@term default-branch=v1

The default branch of a git repository is the branch into which work
on the repository merges.

### 4.6 People

@term person=v1

A person is a human who works on a repository.

### 4.7 Agents

@term agent=v1
@cites {text#{text=v1}, #{person=v1}}

An agent is a program that uses a language model to write texts for a
person, such as code. Each agent acts for one person: the person who
runs it.

### 4.8 The job

@term job=v1
@cites {text#{conforming-program=v1}, #{default-branch=v1}}

The job is an execution of a conforming program that continuous
integration starts at each push to the default branch of a repository.

### 4.9 Accepted inputs

@term accepted-input=v1
@cites {
    identifiers#{tag-line=v1, inline-citation=v1, binding=v1, input=v1},
    text#{conforming-program=v1, result=v1, design=v1, text=v1},
    #{tree=v1, read-text-binding=v1},
}

Under a binding of `read-texts` and a binding of the parameter
`external-namespaces` of the design Identifiers, an accepted input of a
tree is a tag line or an inline citation of a read text of a file of the
tree, to which a conforming program of the design Identifiers gives the
result "valid" under that binding of `external-namespaces`.

### 4.10 Declared items

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
whose declaration word is `@design`, an item of the kind specification
is a declared item whose declaration word is `@spec`, and an item of the
kind requirement is a declared item whose declaration word is `@req`.
The slug of a declaration is the slug in its target, and the part name
of a declaration is the part name in its target, when its target starts
with a full name.

### 4.11 Regions of declared items

@term region=v1
@cites {
    text#{
        text=v1, run=v1, place=v1, character=v1, line=v1, line-feed=v1,
    },
    #{
        declared-item=v1, tree=v1, markdown-file=v1,
        read-text-binding=v1,
    },
}

A part of a file of a tree is a set of places of the text of that file,
which is not empty. A run or a line of the text of the file, or another
part of the file, is in a part of the file when each of its places is
in that part. Two parts of a file share a place when a place is in both.
The runs of a part of a file are the runs of the text of the file that
are not empty, whose places are each in the part, and that have no place
of the part right before their first place or right after their last
place. The characters of a part of a file are the characters of its
runs, in their order in the text of the file, with one line feed
between each two runs that follow each other when the last character of
the first of the two is not a line feed. They form one text.

The region of a declared item in a tree is a part of one file of that
tree: the part of that file that the item takes up. The declaration of
the item is in its region. When that file is not a markdown file, a
read text of that file comes from each place of the region. When the
regions of two declared items share a place, one of the two regions is
in the other. No place of a file is in the regions of two different
declared items that are each of the kind requirement or of the kind
term. Of the declared items in whose regions a part of a file is, the
innermost is the one whose region is in the region of each of the
others, when exactly one of them is.

### 4.12 Files of declared items

@term item-file=v1
@cites #{declared-item=v1, tree=v1}

The file of a declared item in a tree is the file of that tree in which
the declaration of the item is.

### 4.13 Scopes of specifications

@term specification-scope=v1
@cites {
    text#{specification=v1, place=v1, run=v1},
    #{
        declared-item=v1, region=v1, item-file=v1, markdown-file=v1,
        tree=v1, read-text-binding=v1,
    },
}

The scope of an item of the kind specification in a tree is a part of
the file of the specification:

- when its declaration is in a markdown file, its region;
- otherwise, for the read text that its declaration is in:
  - when the binding of `read-texts` gives code to which the read text
    is attached, such as a module or a function, the places that the
    read text comes from, with the places of the runs of that code;
  - otherwise, when the binding of `read-texts` gives that no code of
    the file comes before the read text, each place of the text of the
    file;
  - otherwise, the places that the read text comes from.

Of the items of the kind specification in whose scopes a part of a file
is, the innermost is the one whose scope is in the scope of each of the
others, when exactly one of them is.

### 4.14 Home designs

@term home-design=v1
@cites {
    identifiers#{tag-line=v1, inline-citation=v1},
    text#{specification=v1},
    #{
        declared-item=v1, region=v1, specification-scope=v1, tree=v1,
        read-text-binding=v1,
    },
}

The home design of a tag line or an inline citation in a tree is one
item of the kind design, or none:

- When the tag line or the inline citation is in the region of an item
  of the kind design, its home design is the innermost of the items of
  the kind design in whose regions it is.
- Otherwise, when it is in the scope of an item of the kind
  specification, and the declaration of the innermost such item has a
  part name, its home design is the item of the kind design whose
  declaration has the slug of the declaration of that item, when the
  tree has exactly one such item.
- Otherwise, it has no home design.

### 4.15 Containment

@term containment=v1
@cites {
    identifiers#{segment=v1, slug=v1},
    text#{specification=v1},
    #{
        declared-item=v1, home-design=v1, specification-scope=v1,
        term=v1, tree=v1, read-text-binding=v1,
    },
}

Containment is a relation in which one declared item holds another, and
the other belongs to it. Only items of the kind design and items of the
kind specification hold declared items, and they hold only the items
that belong to them in these ways:

- An item of the kind specification, an item of the kind requirement, or
  a term whose declaration has a part name belongs to the item of the
  kind design whose declaration has the same slug, when the tree has
  exactly one such item.
- An item of the kind specification, an item of the kind requirement, or
  a term whose declaration has no part name and has a slug of one
  segment belongs to the home design of its declaration, when the
  declaration has one.
- An item of the kind requirement or a term belongs to the innermost
  item of the kind specification in whose scope its declaration is, when
  there is one, and when the two belong to the same item of the kind
  design or both belong to none.

An item of the kind specification, an item of the kind requirement, or a
term belongs to no other declared item. An item of the kind design holds
directly an item of the kind requirement or a term when that item
belongs to it and to no item of the kind specification.

### 4.16 Regions of specifications in code

@term specification-region=v1
@cites {
    text#{character=v1, place=v1},
    #{
        declared-item=v1, region=v1, containment=v1, markdown-file=v1,
        read-text-binding=v1, term=v1, tree=v1,
    },
}

When the declaration of an item of the kind specification is in a file
that is not a markdown file, the region of the item in a tree is the set
of these places: each place that a character of the read text of its
declaration that the item takes up comes from; and each place of the
region of each item of the kind requirement and of each term that
belongs to the item. The read text of its declaration is the read text
that its declaration is in.

### 4.17 Extents of declared items

@term extent=v1
@cites #{declared-item=v1, region=v1, specification-region=v1}

The extent of an item of the kind design is the part of its region that
is in the region of no other declared item whose region is in its
region. The extent of each other declared item is its region.

### 4.18 Terms

@term term=v1
@cites #{declared-item=v1, region=v1}

A term is a declared item whose declaration word is `@term`. Its region
states the meaning of one word or one fixed phrase, which other items
can use.

### 4.19 Decision records

@term decision-record=v1
@cites #{declared-item=v1}

A decision record is a declared item whose declaration word is
`@decision`. It records one standing practice of a project, or one
choice with its reason.

### 4.20 Findings and finding classes

@term finding-class=v1
@cites {identifiers#{slug=v1}, text#{text=v1}}

A finding is a report of one condition at one part of a repository.
Each finding gives its subject: a text that says what the finding is
about. A finding class is a kind of finding, which a slug names.

### 4.21 Declared finding classes

@term declared-finding-class=v1
@cites {
    text#{place=v1},
    #{
        declared-item=v1, finding-class=v1, region=v1, tree=v1,
        item-file=v1, markdown-file=v1, read-text-binding=v1,
    },
}

A declared finding class is a declared item whose declaration word is
`@finding-class`: a finding class that a repository declares for
itself. In a tree, its finding-class file is its file. Its region is
the set of all the places of the text of that file when that file is a
markdown file, and otherwise the set of the places of that file that the
read texts of that file come from.

### 4.22 Built-in finding classes

@term built-in-finding-class=v1
@cites {
    identifiers#{slug=v1},
    #{finding-class=v1, item=v1, declared-finding-class=v1},
}

A binding of the parameter `built-in-finding-classes` is a finite set of
slugs. Under a binding of `built-in-finding-classes`, a built-in finding
class is a finding class whose slug is in that binding. A built-in
finding class is not an item, and it is not a declared finding class.

### 4.23 Names

@term item-name=v1
@cites {
    identifiers#{
        slug=v1, part-name=v1, full-name=v1, name=v1, kind-word=v1,
        citation-entry=v1, inline-citation=v1, destination=v1,
        external-id=v1, match=v1, input-match=v1,
    },
    text#{text=v1, specification=v1},
    #{
        declared-item=v1, containment=v1, home-design=v1, term=v1,
        decision-record=v1, declared-finding-class=v1, tree=v1,
        finding-class=v1, external-item=v1,
    },
}

The name of a declared item in a tree is this:

- of an item of the kind design, a decision record, and a declared
  finding class: the slug of its declaration;
- of an item of the kind specification, an item of the kind requirement,
  and a term that belongs to an item of the kind design: the name of
  that item of the kind design, `#`, and the part name of the item,
  which is the part name of its declaration, or the slug of its
  declaration when its declaration has no part name;
- of an item of the kind specification, an item of the kind requirement,
  and a term that belongs to no item of the kind design: the slug of its
  declaration, with `#` and the part name of its declaration after it
  when its declaration has a part name.

These are the sets of names:

- The items of the kind design, the decision records, and the items of
  the kind specification, the items of the kind requirement, and the
  terms that belong to no item of the kind design and whose names are
  slugs share one set of slugs, the shared set of slugs.
- The declared finding classes have a set of slugs of their own.
- The items of the kind specification, the items of the kind
  requirement, and the terms that belong to one item of the kind design
  share one set of part names.

In a tree, the entry name of a citation entry, and the text that `name`
or `external-ref` matches in the match of the destination of an inline
citation, each name one item or nothing. When the match of the citation
entry, or the match of the destination of the inline citation, uses
`external-ref`, that text names an external item. Otherwise, that text
is a name, and it names an item, or nothing, in this way:

- A slug names the item of the shared set of slugs that has it as its
  name. After the kind word `finding-class`, a slug names the declared
  finding class that has it as its name.
- A full name names the item of the kind specification, the item of the
  kind requirement, or the term whose part name is the part name of the
  full name, of the item of the kind design that the slug of the full
  name names. When the slug of the full name names no item of the kind
  design, the full name names nothing.
- `#` and a part name names the item of the kind specification, the item
  of the kind requirement, or the term whose part name is that part
  name, of the home design of the citation or of the inline citation.
  With no home design, it names nothing.
- A name that two or more declared items of one set of names have names
  none of them.

### 4.24 Kinds that kind words state

@term stated-kind=v1
@cites {
    identifiers#{
        kind-word=v1, citation-entry=v1, target=v1, inline-citation=v1,
        extern-line=v1,
    },
    #{
        declared-item=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, external-item=v1, finding-class=v1,
    },
}

A kind word at the start of a citation entry, of the target of an
inline citation, or of the target of an `@extern` line states what the
citation entry or the target names. `design` states an item of the kind
design. `spec` states an item of the kind specification, or an external
item that is a published standard or a part of one. `req` states an
item of the kind requirement. `term` states a term, or an external item
that states the meaning of one word or one fixed phrase. `decision`
states a decision record. `finding-class` states a declared finding
class. No kind word states an item of another kind of item.

### 4.25 Marks

@term mark=v1
@cites {
    identifiers#{extern-line=v1, kind-word=v1, part-name=v1},
    #{
        accepted-input=v1, declared-item=v1, extent=v1,
        containment=v1, item-file=v1, item-name=v1, stated-kind=v1,
        read-text-binding=v1,
    },
}

A mark is what an `@extern` line states, when the line is an accepted
input and is in the extent of an item of the kind design: that item of
the kind design holds an item that is what the kind word of the line
states, whose part name is the part name of the line, and whose file is
not the file of the item of the kind design.

### 4.26 Vector sets

@term vector-set=v1
@cites {
    files#{path=v1},
    data-forms#{
        test-vector-file-name=v1, test-vector-set=v1,
        test-vector-line=v1,
    },
    #{
        declared-item=v1, containment=v1, item-file=v1, item-name=v1,
        tree=v1,
    },
}

In a tree, each item of the kind design and each item of the kind
specification has one vector file, or none, and one vector set:

- The vector file of an item of the kind design is the file of the tree
  whose valid path is the valid path of the file of the item, with its
  last file name, the file name with the highest number, replaced by the
  test-vector file name of the name of the item alone.
- The vector file of an item of the kind specification that belongs to
  an item of the kind design is the file of the tree whose valid path is
  the valid path of the file of that item of the kind design, with its
  last file name replaced by the test-vector file name of the name of
  that item of the kind design and the part name of the item of the kind
  specification.
- When the name of an item of the kind design holds `/`, so do these
  test-vector file names, and the valid path of each of these vector
  files has more file names than the valid path of the file of that
  item of the kind design. So for an item of the kind design with the
  name `ledger/core` whose file has the valid path
  `docs/designs/core.md`, the valid path of its vector file is
  `docs/designs/ledger/core.test-vectors.jsonl`.
- An item of the kind specification that belongs to no item of the kind
  design has no vector file. An item of the kind design whose file has
  no valid path has no vector file, and neither has an item of the kind
  specification that belongs to it.
- The vector set of an item is the test-vector set that is the content
  of its vector file, when the tree has that file and its content is a
  test-vector set. Otherwise, the vector set of the item is the empty
  vector set: it has no set line, no group line, and no vector line. A
  test-vector set that has a set line and no vector line is not the
  empty vector set.

### 4.27 Conformance vectors

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
of the specification, or of the design. The empty vector set has no
conformance vector. The number of a conformance vector is the number of
its vector line.

### 4.28 Groups

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

### 4.29 Selections

@term selection=v1
@cites {
    identifiers#{citation-entry=v1, vector-selection=v1},
    text#{decimal-numeral=v1, whole-number=v1, specification=v1},
    #{
        item-name=v1, declared-item=v1, conformance-vector=v1,
        vector-set=v1, group=v1,
    },
}

A citation entry whose vector selection is not empty names one
conformance vector, one group, one vector set, or nothing. When the
entry name of the citation entry names neither a specification nor an
item of the kind design, the citation entry names nothing. Otherwise,
take the vector set of the specification or of the item of the kind
design that its entry name names:

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

### 4.30 Identity of items across trees

@term same-item=v1
@cites {
    text#{specification=v1},
    #{
        item=v1, declared-item=v1, item-name=v1, conformance-vector=v1,
        vector-set=v1, group=v1, test=v1, read-text-binding=v1, tree=v1,
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
- both are tests, their files have the same path, and the binding of
  `read-texts` gives them the same name.

### 4.31 Tests

@term test=v1
@cites {
    identifiers#{declaration=v1},
    text#{place=v1, run=v1},
    #{tree=v1, read-text-binding=v1, region=v1},
}

Under a binding of `read-texts`, the tests of a file of a tree are the
tests that the binding gives for that file, and that file is the file
of each of them. A test is a unit of code that a test framework runs
and reports as passed or failed, such as a test function, or a set of
such units, such as the tests of one `describe` block. No declaration
declares a test. The name of a test is the name that the binding gives
it. The code of a test is the part of its file whose places are the
places of the runs that the binding gives as its code. A comment on a
test is a part of its file whose places are the places of the runs that
the binding gives as one comment on that test, such as the comment right
before a test function.

### 4.32 Test evidence

@term test-evidence=v1
@cites #{test=v1, tree=v1, read-text-binding=v1}

Test evidence is the set of the reports that tests gave in one
execution of their test frameworks. Each report names one test, by the
path of its file and the name that the binding of `read-texts` gives
it, and it says that the test passed or that it failed. Test evidence
reports a test as passed when, and only when, it has at least one
report that the test passed and no report that the test failed.

### 4.33 Sites

@term site=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1, directive=v1},
    text#{line=v1, place=v1, run=v1},
    #{
        declared-item=v1, region=v1, specification-region=v1, test=v1,
        tree=v1, markdown-file=v1, read-text-binding=v1,
    },
}

Under a binding of `read-texts`, the site of a run of a read text of a
file of a tree, such as a line, a citation, or an inline citation, is a
part of that file, or none. The places of the site are the places of
the text of the file that meet each of these conditions:

- in a markdown file, a read text of the file comes from the place, and
  the place is in the lines of the file from the last heading of the
  file that starts at or before the run, or from the first line of the
  file when no heading starts at or before the run, to the line before
  the next heading of the file after the run, or to the last line of
  the file when no heading follows the run;
- in a file that is not a markdown file, the read text that the run is
  in comes from the place;
- the place is in the region of no declared item, and in no comment on a
  test.

When no place meets these conditions, the run has no site. A site is a
part of a file that is the site of a citation, of an inline citation,
or of an `@ack` line, and that holds each place that this citation,
inline citation, or `@ack` line comes from. A site has no name.

### 4.34 External items

@term external-item=v1
@cites {
    identifiers#{
        external-id=v1, part-name=v1, match=v1, input-match=v1,
    },
    text#{text=v1, run=v1},
    #{accepted-input=v1},
}

An external item is a thing outside the repository that an external id
names. Each text that `external-id` matches in the match of an accepted
input is an external id, and it names one external item, even when
nothing outside the repository has that external id. When a run that
`external-ref` matches in that match holds that external id and then `#`
and a part name, the text of that run names a part of that external
item, and that part is an external item too.

### 4.35 Revised content

@term revised-content=v1
@cites {
    identifiers#{
        label=v1, revision=v1, citation=v1, citation-entry=v1,
        inline-citation=v1, target=v1, ack-line=v1, directive=v1,
    },
    text#{
        text=v1, character=v1, line=v1, line-feed=v1, place=v1,
        specification=v1,
    },
    data-forms#{test-vector-line=v1, vector-object=v1},
    #{
        declared-item=v1, extent=v1, term=v1, decision-record=v1,
        declared-finding-class=v1, region=v1, specification-region=v1,
        containment=v1, conformance-vector=v1, vector-set=v1, group=v1,
        task=v1, plan=v1, test=v1, site=v1, external-item=v1, item=v1,
        accepted-input=v1, read-text-binding=v1,
    },
}

The content characters of a part of a file are the text that these
steps give:

1. Take the lines of the text that the characters of the part form.
2. Leave out each of those lines that holds an `@ack` line that is an
   accepted input: a line holds it when each character of that `@ack`
   line comes from the place of a character of the line.
3. In each other line, leave out each character that is at a place from
   which a character of one of these comes: the revision of a citation
   entry of a citation that is an accepted input; the revision in the
   target of an inline citation that is an accepted input.
4. Join the lines that remain, in their order, with one line feed
   between each two of them.

The revised content of an item is this:

- of an item of the kind design, the content characters of its extent;
- of an item of the kind specification, the content characters of its
  extent, where step 3 also leaves out each character that is at a
  place from which a character of the label of the declaration of an
  item of the kind requirement or of a term that it holds comes;
- of an item of the kind requirement, of a term, of a decision record,
  and of a declared finding class, the content characters of its extent;
- of a conformance vector, the members `group`, `input`, `result`, and
  `values` that the object of its vector line has;
- of a group and of a vector set, which conformance vectors are in it,
  and the revised content of each.

So the revised content of a declared item is a text, and two revised
contents of declared items are the same when they are the same text. A
task, a plan, a test, a site, and an external item have no revised
content.

### 4.36 Revisions of items

@term item-revision=v1
@cites {
    identifiers#{label=v1, declaration=v1},
    data-forms#{test-vector-line=v1},
    #{
        declared-item=v1, revised-content=v1, conformance-vector=v1,
        group=v1, vector-set=v1, tree=v1, item=v1,
    },
}

A revision of an item is a label that the item has, and it names the
revised content that the item has with that label in a given tree. The
current revision of an item in a tree is the label that the item has in
that tree, whatever its revised content:

- for a declared item, the label of its declaration;
- for a conformance vector, the revision of its vector line;
- for a group, the revision of the group line of its vector set whose
  `group` value is the name of the group;
- for a vector set, the revision of its set line.

A declared item whose declaration has no label has no current revision,
and neither has the empty vector set. An item that has no revised
content has no revision.

### 4.37 Edges

@term edge=v1
@cites {
    identifiers#{
        citation=v1, citation-entry=v1, sinter-tag-word=v1,
        inline-citation=v1, destination=v1, vector-selection=v1,
        name=v1, external-id=v1, match=v1, input-match=v1,
    },
    text#{text=v1},
    #{item=v1, accepted-input=v1, item-name=v1, selection=v1, tree=v1},
}

An edge is a relation of one kind of edge from an item, its source, or
from none, to an item, its cited item, or to none. The kinds of edge are
these five: `cites`, `satisfies`, `verifies`, `refines`, and
`supersedes`. Each citation entry of a citation that is an accepted
input states one edge, whose kind of edge is the citation word of the
citation without its `@`. Each inline citation that is an accepted input
states one edge, whose kind of edge is `cites`. The cited item of an
edge in a tree is this item, or none:

- when the vector selection of its citation entry is not empty, the item
  that the citation entry names in that tree;
- otherwise, the item that the entry name of its citation entry, or the
  text that `name` or `external-ref` matches in the match of the
  destination of its inline citation, names in that tree.

When the citation entry or the inline citation names no item in that
tree, the edge has no cited item in that tree.

### 4.38 Sources of edges

@term edge-source=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1},
    text#{line=v1},
    #{
        edge=v1, declared-item=v1, region=v1, test=v1, site=v1,
        tree=v1, item=v1, specification-region=v1, read-text-binding=v1,
    },
}

A line of a read text of a file of a tree, a citation, or an inline
citation stands in one item, or in none:

- when it is in the region of a declared item, it stands in the
  innermost of the declared items in whose regions it is, when there
  is one;
- otherwise, when it is in a comment on a test, it stands in the
  innermost of the tests that it is in a comment on: the test whose code
  is in the code of each of the others, when exactly one of them is;
- otherwise, it stands in its site, when it has one.

The source of an edge is the item in which the citation or the inline
citation that states the edge stands, or none when that citation or
that inline citation stands in no item.

### 4.39 Pinned edges

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

### 4.40 Edges of the kind `cites`

@term cites-edge=v1
@cites #{edge=v1, edge-source=v1}

A `cites` edge states that its source refers to its cited item and
rests on what the cited item says.

### 4.41 Edges of the kind `satisfies`

@term satisfies-edge=v1
@cites #{edge=v1, edge-source=v1}

A `satisfies` edge states that its source does what its cited item
states.

### 4.42 Edges of the kind `verifies`

@term verifies-edge=v1
@cites {
    identifiers#{citation-entry=v1},
    text#{input=v1, conforming-program=v1},
    data-forms#{vector-meaning=v1},
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
vector of the selection of the citation entry of the edge, what that
conformance vector states that a conforming program gives.

### 4.43 Edges of the kind `refines`

@term refines-edge=v1
@cites #{edge=v1, edge-source=v1}

A `refines` edge states that its source states all or part of its
cited item in more detail.

### 4.44 Edges of the kind `supersedes`

@term supersedes-edge=v1
@cites {
    identifiers#{citation-entry=v1, citation-line=v1},
    #{
        item=v1, edge=v1, declared-item=v1, containment=v1,
        item-name=v1, term=v1, edge-source=v1,
    },
}

A `supersedes` edge states that its source is to replace its cited
item. When the production `every-part` matches the citation entry of a
`supersedes` edge, and its source and its cited item are items of the
kind design, the edge also states this: each item of the kind
specification, each item of the kind requirement, and each term that
the cited item holds is to be replaced by the declared item with the
same kind of item and the same part name that the source holds, when the
source holds one. Only a `supersedes` edge states that one declared item
is to replace another.

### 4.45 Cycles of edges of the kind `supersedes`

@term supersedes-cycle=v1
@cites #{edge=v1, supersedes-edge=v1, declared-item=v1, tree=v1}

A declared item is on a cycle of `supersedes` edges in a tree when, and
only when, it leads back to itself along `supersedes` edges of that
tree: when a sequence of one or more `supersedes` edges of that tree
has the item as the source of its first edge and as the cited item of
its last edge, and has the cited item of each other edge as the source
of the next edge.

### 4.46 Status tags of declared items

@term item-status-tag=v1
@cites {
    identifiers#{
        status-tag=v1, declaration=v1, tag-line=v1,
        continuation-line=v1,
    },
    text#{text=v1, line=v1},
    #{accepted-input=v1, declared-item=v1},
}

A status tag is among the tag lines of a declaration when the status
tag and the declaration are in one sequence of consecutive lines of one
text, each of which is a tag line or a continuation line. A status tag
that is an accepted input, and that is among the tag lines of the
declaration of exactly one declared item, is a status tag of that
declared item. Each other status tag is a status tag of no declared
item.

### 4.47 Acks

@term ack=v1
@cites {
    identifiers#{
        ack-line=v1, directive=v1, slug=v1, match=v1, input-match=v1,
    },
    text#{text=v1, utf-8-encoding=v1},
    data-forms#{hash=v1},
    #{
        accepted-input=v1, finding-class=v1, declared-finding-class=v1,
        built-in-finding-class=v1, edge-source=v1, declared-item=v1,
        region=v1, specification-region=v1, test=v1, site=v1, item=v1,
        read-text-binding=v1, revised-content=v1,
    },
}

An ack is what an `@ack` line that is an accepted input states: the
findings of one finding class in one part of a file are acknowledged.
The finding class is the finding class whose slug is the slug of the
line: a built-in finding class, or a declared finding class. The part
of a file is this:

- when the line stands in a declared item, the region of that declared
  item;
- when the line stands in a test, the comment on that test that the
  line is in;
- when the line stands in a site, that site.

An `@ack` line that stands in no item states no ack, and neither does
an `@ack` line whose slug is the slug of no built-in finding class and
of no declared finding class. The hash prefix of the line is the start
of the hash of the UTF-8 encoding of the content characters of that
part of a file, as the part was when the ack was written. The subject
of the line is the text that `subject` matches in the match of the
line, or the empty text when that match uses no `subject`. When the
subject of the line is not empty, the ack is for each finding
of that finding class in that part of a file whose subject, in the form
in which the finding gives it, is the same text as the subject of the
line. When the subject of the line is empty, the ack is for every
finding of that finding class in that part of a file.

### 4.48 Valid edges

@term valid-edge=v1
@cites {
    identifiers#{
        kind-word=v1, citation-entry=v1, target=v1, inline-citation=v1,
        citation-line=v1,
    },
    #{
        item=v1, edge=v1, edge-source=v1, stated-kind=v1,
        declared-item=v1, external-item=v1, test=v1,
        conformance-vector=v1, group=v1, vector-set=v1, tree=v1,
        term=v1,
    },
}

An edge is valid in a tree when, and only when, each of these is true
in that tree:

- The edge has a source and a cited item.
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
    the kind requirement, an item of the kind specification, or an item
    of the kind design;
  - for `supersedes`, the source is a declared item, and the cited item
    is a declared item of the same kind of item; when the production
    `every-part` matches the citation entry, the source and the cited
    item are items of the kind design.

### 4.49 Valid marks

@term valid-mark=v1
@cites {
    identifiers#{extern-line=v1, kind-word=v1, part-name=v1},
    text#{specification=v1},
    #{
        mark=v1, declared-item=v1, containment=v1, term=v1,
        item-name=v1, item-file=v1,
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

### 4.50 Valid status tags

@term valid-status-tag=v1
@cites {
    identifiers#{status-tag=v1, sinter-tag-word=v1},
    text#{specification=v1},
    #{
        item=v1, declared-item=v1, item-status-tag=v1, term=v1,
        decision-record=v1,
    },
}

A status tag of a declared item is valid when, and only when, its status
word fits the kind of item of that declared item. `@deprecated` fits the
kinds design, specification, requirement, term, and decision record.
`@rejected` and `@deferred` fit only the kind decision record.

### 4.51 Valid trees

@term valid-tree=v1
@cites {
    identifiers#{extern-line=v1, part-name=v1, label=v1, kind-word=v1},
    text#{design=v1, requirement=v1, specification=v1},
    #{
        tree=v1, item=v1, edge=v1, valid-edge=v1, mark=v1,
        valid-mark=v1, accepted-input=v1, extent=v1,
        item-status-tag=v1, valid-status-tag=v1, declared-item=v1,
        containment=v1, region=v1, item-file=v1,
        specification-scope=v1, term=v1, item-name=v1,
        supersedes-cycle=v1, markdown-file=v1, finding-class=v1,
        declared-finding-class=v1, built-in-finding-class=v1,
        specification-region=v1, read-text-binding=v1, vector-set=v1,
    },
}

A tree is valid when, and only when, each of these is true in it:

- Each edge is valid.
- Each mark of each item of the kind design is valid.
- Each `@extern` line that is an accepted input is in the extent of an
  item of the kind design.
- Each status tag that is an accepted input is among the tag lines of
  the declaration of exactly one declared item.
- Each status tag of each declared item is valid.
- The declaration of each item of the kind design is in a markdown file.
- Each item of the kind specification, each item of the kind
  requirement, and each term belongs to exactly one item of the kind
  design.
- Each item of the kind specification, each item of the kind
  requirement, and each term whose declaration is in the region of an
  item of the kind design belongs to that item of the kind design.
- Each item of the kind requirement and each term whose declaration is
  in the region of a specification belongs to that specification.
- The region of no item of the kind design is in the region of another
  item of the kind design, and the declaration of no specification is in
  the scope of another specification.
- For each specification that an item of the kind design holds, and for
  each item of the kind requirement and each term that it holds
  directly, whose file is not the file of the item of the kind design,
  that item of the kind design has a mark whose `@extern` line has the
  kind word of that item, `spec`, `req`, or `term`, and its part name.
- The declaration of each item of the kind requirement and of each term
  whose declaration has a part name, when it is in a markdown file, is
  in the file of the item of the kind design to which the item belongs,
  or in the file of the specification to which it belongs.
- The declaration of each term has a label.
- The declaration of each declared finding class is in a markdown file.
- No two declared finding classes have the same file.
- No declared finding class has the slug of a built-in finding class.
- No two declared items of one set of names have the same name.
- No file is the vector file of two items.
- No declared item is on a cycle of `supersedes` edges.

In a valid tree, each item of the kind design is a design, each item of
the kind specification belongs to an item of the kind design and is a
specification of that design, and each item of the kind requirement
belongs to an item of the kind design and is a requirement of that
design. A tree that is not valid still has its
items, its edges, and their states.

### 4.52 Work items

@term work-item=v1
@cites #{task=v1, plan=v1, tree=v1}

A work item is a task or a plan. No work item is in a file of a tree.
Each work item has a work item id, which never changes and which names
exactly one work item, and a display name, which can change.

### 4.53 Tasks

@term task=v1
@cites {
    files#{path=v1, path-set=v1, path-set-membership=v1},
    #{person=v1, agent=v1, external-item=v1, tree=v1},
}

A task is one piece of work that one person or one agent can finish
alone. The work of a task is what people and agents change in the files
of the repository to finish the task. A file is in the set of a path set
when its valid path is in the set of that path set, so a file that has
no valid path is in the set of no path set. The paths of a task are a
path set, whose set holds the files that the work of the task adds,
changes, or removes. A task names at most one
external item, which can say what the work is, and several tasks can
name one external item. A task has no description of its own and no
branch.

### 4.54 Promises

@term promise=v1
@cites {
    identifiers#{citation=v1},
    text#{requirement=v1},
    files#{path-set=v1, path-set-membership=v1},
    #{
        task=v1, edge=v1, edge-source=v1, valid-edge=v1,
        suspect-edge=v1, declared-item=v1, item-name=v1, test=v1,
        test-evidence=v1, tree=v1,
    },
}

A promise of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and the name of a requirement. The promise is kept in a
tree, with test evidence and a path set, when, and only when, that tree
has an edge of that kind of edge that meets each of these conditions:

- its cited item is an item of the kind requirement whose name in that
  tree is the name of the promise;
- it is valid in that tree, and it is not suspect in that tree;
- the citation that states it is in a file that is in the set of that
  path set;
- when its kind of edge is `verifies`, that test evidence reports as
  passed the test with the path of the file of its source and with the
  name of its source.

### 4.55 Plans

@term plan=v1
@cites #{task=v1}

A plan says how a set of tasks and plans gets done.

### 4.56 Waits

@term wait=v1
@cites #{work-item=v1}

A wait is a relation from one work item, the waiting item, to another
work item, the item that it waits for.

### 4.57 What a plan carries out

@term carried-out-item=v1
@cites {
    text#{requirement=v1, design=v1, specification=v1},
    #{plan=v1, item-name=v1},
}

A plan carries out a set of requirements, specifications, and designs:
its work is for them. The plan names each of them by its name.

### 4.58 Definitions of work items

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

### 4.59 First-parent lines

@term first-parent-line=v1
@cites #{default-branch=v1}

A commit reaches itself and each of its ancestors. A branch reaches each
commit that the commit to which it points reaches. The first-parent
line of the default branch is the commit to which the default branch
points, its first parent, the first parent of that commit, and so on,
up to a commit that has no parent.

### 4.60 Changes

@term change=v1
@cites #{default-branch=v1, first-parent-line=v1}

A change is a set of commits that is to merge into the default branch
as one unit, such as the commits of a pull request. The branch of the
change is the branch from which it merges. The commits of the change
are the commits that the branch of the change reaches and the default
branch does not reach. The last commit of the change is the commit to
which the branch of the change points.

### 4.61 Diffs of changes

@term change-diff=v1
@cites {text#{line=v1}, #{change=v1, tree=v1, default-branch=v1}}

The diff of a change is the set of the lines that differ between the
tree of the merge base of the branch of the change and the default
branch, and the tree of the last commit of the change: the lines that
the change adds and the lines that it removes.

### 4.62 Delivery lines

@term delivery-line=v1
@cites {
    text#{line=v1, text=v1, byte-sequence=v1},
    data-forms#{hash=v1},
    #{task=v1, promise=v1, work-item=v1, work-item-definition=v1},
}

A delivery line is a line of the message of a commit that states that
the commit completes the work of one task. It names the task by its work
item id. It gives a text, and it names each definition of the task for
which that text is the start of the hash of a byte sequence that encodes
the paths and the promises of that definition. The finishing commit of a
delivery line is the commit in whose message the line is.

### 4.63 Merge commits

@term merge-commit=v1
@cites #{default-branch=v1, first-parent-line=v1, delivery-line=v1}

The merge commit of a delivery line is the commit of the first-parent
line of the default branch that reaches the finishing commit of the
line, and that has no parent or whose first parent does not reach the
finishing commit. A delivery line whose finishing commit no commit of
the first-parent line reaches has no merge commit.

### 4.64 Task lines

@term task-line=v1
@cites {text#{line=v1}, #{task=v1, work-item=v1}}

A task line is a line of the message of a commit that names one task by
its work item id, and that states that the commit does part of the work
of the task without finishing it.

### 4.65 Ledger entries

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

### 4.66 The ledger

@term ledger=v1
@cites {text#{whole-number=v1}, #{ledger-entry=v1}}

The ledger of a repository is a sequence of ledger entries. Ledger
entries are appended at the end of the ledger: after each ledger entry
that is in the ledger at that time. Of two ledger entries that were
appended to one ledger, the one that was appended later comes later in
the ledger, whatever times the two ledger entries record. The ledger of
a clone of the repository is the ledger entries that the clone has, in
their order: first the ledger entries of the ledger of the repository
that the clone has, and after them its provisional ledger entries,
which the clone has appended and not pushed to the ledger of the
repository yet. A push can drop a provisional ledger entry, or give it a
later place, after ledger entries that other clones pushed first. A
point of a ledger is given by the ledger entries before it: the first n
ledger entries of the ledger, for a whole number n of 0 or more. The
point of a ledger entry is the point right before it, and the end of a
ledger is the point after its last ledger entry.

### 4.67 Repairs and voids

@term repair=v1
@cites #{ledger=v1, ledger-entry=v1}

A repair is a write that removes one or more ledger entries from the
ledger of a repository, and that puts one `void` ledger entry, a void,
in the place of each ledger entry that it removes: after each ledger
entry that came before the removed one, and before each ledger entry
that came after it. A void records that a repair removed one ledger
entry, and the reason for the removal.

### 4.68 Definition entries

@term definition-entry=v1
@cites {
    text#{whole-number=v1},
    #{
        ledger-entry=v1, work-item=v1, task=v1, plan=v1,
        work-item-definition=v1, judgment=v1,
    },
}

A definition entry is a ledger entry of the kind `task` or `plan`. It
names one work item, its work item, by its work item id. It records one
whole definition of its work item and a definition number, a whole
number of 1 or more: 1 for the first definition of the work item, and
one more for each later definition. A definition entry with the
definition number n, of 2 or more, records an edit of the definition
with the definition number n − 1 of its work item. A `task` ledger entry
records a definition of a task, and a `plan` ledger entry records a
definition of a plan. A definition entry records no judgment.

### 4.69 Subjects of approval

@term subject-of-approval=v1
@cites {
    text#{specification=v1},
    #{
        person=v1, declared-item=v1, extent=v1, term=v1,
        decision-record=v1, containment=v1, revised-content=v1,
        same-item=v1, tree=v1,
    },
}

A subject of approval is a unit that a person approves or declines as a
whole. Each subject of approval is one of these: the extent of an item
of the kind design; a specification, with the items of the kind
requirement and the terms that it holds; an item of the kind requirement
that an item of the kind design holds directly; a term that an item of
the kind design holds directly; or a decision record. These five are the
kinds of subject of approval, and the kind of a subject of approval is
the one of the five that it is. The declared item of a subject of
approval is the item of the kind design, for its extent, and otherwise
the specification, the item of the kind requirement, the term, or the
decision record that the subject of approval is. The subject of approval
of a declared item is the subject of approval whose declared item it is,
when there is one. The subject of approval of an item of the kind
requirement or of a term that a specification holds is the subject of
approval of that specification. Each other declared item has no subject
of approval. The revised content of a subject of approval is the revised
content of its declared item. A subject of approval of one tree and a
subject of approval of another tree are the same subject of approval
when their declared items are the same item.

### 4.70 Bindings of `approval-kinds`

@term approval-binding=v1
@cites #{subject-of-approval=v1}

A binding of the parameter `approval-kinds` is a set of kinds of
subject of approval. Under a binding of `approval-kinds`, a subject of
approval needs approval when, and only when, its kind is in that
binding.

### 4.71 Judgments

@term judgment=v1
@cites {
    text#{requirement=v1, utf-8-encoding=v1},
    data-forms#{hash=v1},
    #{
        ledger-entry=v1, person=v1, subject-of-approval=v1,
        declared-item=v1, item-name=v1, task=v1, plan=v1, promise=v1,
        revised-content=v1, item-revision=v1, item=v1,
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

An `approval` or a `decline` ledger entry records the kind of item and
the name of the declared item of its subject of approval, and the hash
of the UTF-8 encoding of the revised content that it judges. It is a
judgment of each subject of approval whose declared item has that kind
of item and that name, and of each revised content whose UTF-8 encoding
has that hash.

### 4.72 Records of the job

@term job-record=v1
@cites {
    text#{requirement=v1},
    #{
        ledger-entry=v1, job=v1, delivery-line=v1, promise=v1, task=v1,
        work-item-definition=v1, test-evidence=v1, item-revision=v1,
        tree=v1, merge-commit=v1,
    },
}

A record of the job is a ledger entry of the kind `delivered`: it
records what the job observed. A `delivered` ledger entry records that
the job read one delivery line in the commits that the job read, and it
is a `delivered` ledger entry of the task that the line names. For each
definition of that task that the line names, and for each promise of
that definition, it records the revision that the promised requirement
has in the tree of the merge commit of the line, and whether the promise
was kept in that tree, with the test evidence that the job read and with
the paths of that definition.

### 4.73 The states of work items

@term work-item-state=v1
@cites {
    files#{valid-path-set=v1},
    #{
        ledger=v1, ledger-entry=v1, definition-entry=v1, work-item=v1,
        task=v1, plan=v1, work-item-definition=v1, wait=v1, promise=v1,
        delivery-line=v1, judgment=v1, job-record=v1, state=v1,
        merge-commit=v1, tree=v1,
    },
}

At each point of a ledger, the ledger entries before that point give
the accepted definition entries, the current definition of each work
item, the work items that exist, the parts of each plan, and the state
of each task and each plan, by these rules:

1. A `done`, an `abandoned`, or a `delivered` ledger entry of a work
   item is a ledger entry of that kind that names the work item, at
   whose point the work item exists. Each other `done`, `abandoned`, or
   `delivered` ledger entry changes no state.
2. A definition entry is an accepted definition entry when, and only
   when, each of these is true at the point of the definition entry:
   - its definition number is 1, and its work item does not exist; or
     its definition number is one more than the definition number of
     the latest accepted definition entry of its work item, and it is a
     `task` ledger entry when its work item is a task, and a `plan`
     ledger entry when its work item is a plan;
   - its work item is not a task that is done or abandoned, and not a
     plan that is abandoned;
   - the plan that the definition that it records names, when that
     definition names one, exists, is a plan, and is not abandoned;
   - each work item that a wait of that definition waits for exists;
   - the combined relation has no cycle when that definition is the
     current definition of its work item, and each other work item has
     its current definition;
   - when it is a `task` ledger entry, the paths of the definition that
     it records are a valid path set.
3. The current definition of a work item at a point is the definition
   that the latest accepted definition entry of the work item before
   that point records. A work item exists at a point when, and only
   when, it has a current definition at that point. A work item is a
   task when its first accepted definition entry is a `task` ledger
   entry, and a plan when that ledger entry is a `plan` ledger entry.
4. A work item is a part of a plan at a point when, and only when, it
   exists at that point, its current definition names that plan as its
   plan, and one of these is true:
   - the plan is not abandoned at that point, and the work item is not
     abandoned at that point;
   - the plan is abandoned at that point; the work item was a part of
     the plan at the point of the first `abandoned` ledger entry of the
     plan; and the work item is done, and not abandoned, at each point
     from the point of that ledger entry to that point.
5. A work item is under a plan at a point when, and only when, it is a
   part of the plan, or under a part of the plan, at that point.
6. The combined relation at a point goes from each plan to each of its
   parts, from each work item to each work item that a wait of its
   current definition waits for, and from each task to each work item
   that a wait of the current definition of a plan that the task is
   under waits for. The combined relation has a cycle when, and only
   when, a work item leads back to itself along it: when a sequence of
   one or more of its relations has that work item as the work item
   from which the first relation goes and as the work item to which the
   last relation goes, and each relation after the first goes from the
   work item to which the relation before it goes.
7. Each task that exists at a point is in exactly one of these four
   states at that point:
   - abandoned, when, and only when, an `abandoned` ledger entry of the
     task is before that point, and the task is not done at the point
     of that ledger entry;
   - done, when, and only when, one of these ledger entries is before
     that point, and the task is not abandoned at the point of that
     ledger entry: a `done` ledger entry of the task; or a `delivered`
     ledger entry of the task whose delivery line names the current
     definition of the task at the point of that ledger entry, and
     which records that each promise of that definition was kept in the
     tree of the merge commit of its delivery line; the first of these
     ledger entries is the ledger entry that makes the task done;
   - delivered, when, and only when, it is neither done nor abandoned,
     and a `delivered` ledger entry of the task is before that point;
   - open, when, and only when, it is none of abandoned, done, and
     delivered.
8. A task is unfinished at a point when, and only when, it is open or
   delivered at that point.
9. Each plan that exists at a point is in exactly one of these three
   states at that point:
   - abandoned, when, and only when, an `abandoned` ledger entry of the
     plan is before that point;
   - done, when, and only when, it is not abandoned, it has at least
     one part, and each of its parts is done at that point;
   - open, when, and only when, it is neither abandoned nor done.

### 4.74 States

@term state=v1
@cites #{item=v1, edge=v1, subject-of-approval=v1, tree=v1, ledger=v1}

A state is a named condition of an item, an edge, or a subject of
approval, in a tree, at a point of a ledger, or in a tree at a point of
a ledger.

### 4.75 Deprecated

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

### 4.76 Rejected

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

### 4.77 Deferred

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

### 4.78 Approved and declined

@term approval-state=v1
@cites {
    text#{design=v1, requirement=v1, specification=v1},
    #{
        subject-of-approval=v1, judgment=v1, ledger=v1, ledger-entry=v1,
        revised-content=v1, containment=v1, extent=v1, term=v1,
        decision-record=v1, tree=v1, item=v1, approval-binding=v1,
        default-branch=v1, first-parent-line=v1,
    },
}

Under a binding of `approval-kinds`, in a tree, at a point of a ledger,
these are the states approved and declined:

- A subject of approval that needs approval under that binding is
  approved when, and only when, of the `approval` and `decline` ledger
  entries before that point that record a judgment of that subject of
  approval and of the revised content that the subject of approval has
  in that tree, the latest is an `approval` ledger entry. It is declined
  when, and only when, the latest of them is a `decline` ledger entry.
- A subject of approval that does not need approval under that binding
  is approved when, and only when, a commit of the first-parent line of
  the default branch has a tree in which the same subject of approval
  has the revised content that the subject of approval has in that tree.
  It is not declined.
- A specification, a requirement or a term that a design holds directly,
  and a decision record are each approved when, and only when, the
  subject of approval that is that item, or that is that specification
  with its requirements and its terms, is approved. Each of them is
  declined when, and only when, that subject of approval is declined.
- A requirement or a term that a specification holds is approved when,
  and only when, that specification is approved. It is declined when,
  and only when, that specification is declined.
- A design is approved when, and only when, its extent, each of its
  specifications, and each requirement and each term that it holds
  directly are approved.

### 4.79 Drafts

@term draft-design=v1
@cites {
    text#{design=v1},
    #{approval-state=v1, tree=v1, ledger=v1, approval-binding=v1},
}

Under a binding of `approval-kinds`, a design is a draft in a tree, at a
point of a ledger, when, and only when, it is not approved in that tree
at that point under that binding.

### 4.80 Effective edges of the kind `supersedes`

@term effective-supersedes-edge=v1
@cites #{
    edge=v1, edge-source=v1, valid-edge=v1, item-status-tag=v1,
    valid-status-tag=v1, approval-state=v1, tree=v1, ledger=v1,
    approval-binding=v1, declared-finding-class=v1,
}

Under a binding of `approval-kinds`, a `supersedes` edge is effective in
a tree, at a point of a ledger, when, and only when, each of these is
true: it is valid in that tree; its source has no valid status tag in
that tree; and its source is a declared finding class, or is approved
in that tree at that point under that binding.

### 4.81 Retired

@term retired-item=v1
@cites #{
    declared-item=v1, edge=v1, item-status-tag=v1, valid-status-tag=v1,
    effective-supersedes-edge=v1, supersedes-cycle=v1, containment=v1,
    tree=v1, ledger=v1, approval-binding=v1,
}

Under a binding of `approval-kinds`, a declared item is retired in a
tree, at a point of a ledger, when, and only when, one of these is true
in that tree at that point under that binding:

- the item has a valid status tag;
- an effective `supersedes` edge has the item as its cited item, and the
  item is on no cycle of `supersedes` edges;
- the item belongs to a retired item of the kind design or to a retired
  item of the kind specification.

### 4.82 In force

@term in-force-item=v1
@cites #{
    declared-item=v1, retired-item=v1, tree=v1, ledger=v1,
    approval-binding=v1,
}

Under a binding of `approval-kinds`, a declared item is in force in a
tree, at a point of a ledger, when, and only when, it is not retired in
that tree at that point under that binding.

### 4.83 Suspect

@term suspect-edge=v1
@cites #{pinned-edge=v1, edge=v1, item-revision=v1, tree=v1}

An edge is suspect in a tree when, and only when, it is pinned, it has a
cited item in that tree, and that cited item has no current revision in
that tree, or a current revision other than the label of the edge.

### 4.84 Met waits

@term met-wait=v1
@cites #{wait=v1, work-item=v1, work-item-state=v1, ledger=v1}

A wait is met at a point of a ledger when, and only when, the work item
that it waits for is done at that point.

### 4.85 Ready tasks

@term ready-task=v1
@cites #{
    task=v1, plan=v1, met-wait=v1, wait=v1, work-item-definition=v1,
    work-item-state=v1, ledger=v1,
}

A task is ready at a point of a ledger when, and only when, it is open
at that point, each wait of its current definition is met at that
point, and each wait of the current definition of each plan that the
task is under at that point is met at that point.

### 4.86 Requirements accounted for

@term requirement-accounted-for=v1
@cites {
    text#{requirement=v1, design=v1, specification=v1},
    #{
        containment=v1, task=v1, plan=v1, promise=v1,
        carried-out-item=v1, work-item-definition=v1,
        work-item-state=v1, ledger=v1, ledger-entry=v1, judgment=v1,
        job-record=v1, item-revision=v1, item-name=v1, tree=v1,
    },
}

A requirement is accounted for in a tree, at a point of a ledger, when,
and only when, one of these is true at that point:

- the current definition of an unfinished task has a promise whose name
  is the name of the requirement in that tree;
- the current definition of an open plan names, as carried out, the
  name that the requirement, the specification that holds it, or the
  design that holds it has in that tree;
- the ledger entry that makes a done task done records, for the name of
  the requirement in that tree, a revision that is the current revision
  of the requirement in that tree.

## 5. Requirements

### 5.1 The sources of states

@req compute-states-from-artifacts=v1
@cites {
    identifiers#{binding=v1},
    text#{conforming-program=v1, input=v1},
    #{
        state=v1, tree=v1, default-branch=v1, delivery-line=v1,
        task-line=v1, ledger=v1, test-evidence=v1, read-text-binding=v1,
        approval-binding=v1, built-in-finding-class=v1, valid-tree=v1,
    },
}

A conforming program must compute each state, and the validity of each
tree, only from these inputs: the commits of the repository with their
parents; the commit to which each branch points, and which branch is the
default branch; the paths and the contents of the files of trees; the
delivery lines and the task lines of the messages of commits; the
ledger, in its order; test evidence; and the bindings of
`external-namespaces`, `read-texts`, `approval-kinds`, and
`built-in-finding-classes`.

### 5.2 The same treatment of each ledger entry

@req treat-ledger-entries-alike=v1
@cites {
    text#{conforming-program=v1},
    #{state=v1, ledger=v1, ledger-entry=v1, person=v1},
}

A conforming program must give the same states for two ledgers whose
ledger entries differ only in the writers, the persons, and the
branches that they record.

### 5.3 One binding of each parameter

@req use-one-binding-for-states=v1
@cites {
    identifiers#{binding=v1},
    text#{conforming-program=v1},
    #{
        state=v1, tree=v1, ledger=v1, read-text-binding=v1,
        approval-binding=v1, built-in-finding-class=v1, valid-tree=v1,
    },
}

A conforming program must compute, under one binding of each of the
parameters `external-namespaces`, `read-texts`, `approval-kinds`, and
`built-in-finding-classes`, each state that it computes for one tree,
for one point of a ledger, or for one tree at one point of a ledger,
and the validity of a tree.

### 5.4 The ledger entries that agents write

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

### 5.5 The summary of a change

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
task lines in the messages of the commits of the change name. For each
change, a conforming program must be able to give the summary of the
change: the list, in the order of the ledger that the program reads, of
every definition entry of each task of the change and of each plan that
a task of the change is under at the end of that ledger, and of every
definition entry that records the branch of the change, with each
definition entry once, and each with the writer that it records, with
the person that it records for an agent when its writer is an agent,
and with the branch that it records, when it records one.

### 5.6 The use of declared tasks

@req use-declared-tasks-only-for-briefs=v1
@cites {text#{text=v1, conforming-program=v1}, #{agent=v1, task=v1}}

A session is one execution of an agent on its work. The declared task
of a session is the task that the agent declares as the work of that
session. The brief of a session is the text about its work that a
conforming program gives the agent of the session for that session. A
conforming program must use the declared task of a session only to
narrow the brief of that session.

## 6. Conformance

A program, or a part of a program, conforms to the design Ontology when
it meets every requirement of section 5. No requirement of section 5
gives a result for an input, so there are no conformance vectors.
