<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ontology
@design ontology=v1
@cites identifiers=v1
@cites conformance=v1
@cites text=v1
@cites files=v1
@cites data-forms=v1
Specifies the objects, encodings, content hashes, content ids, and schema table of object kinds of Sinter; the kinds of item, their names, revisions, and edges; computed identity objects, scope objects, trees, and the default branch; containment; work items and their relations; the ledger, records, voids, the log branch, and the actors that write them; things, latest statements, agreement, and conflicts; the names and meanings of states; parameters and their bindings; and requirements for conforming programs on the inputs on which states depend, on the treatment of records, on how conforming programs change the ledger, on what conforming programs write when an agent runs them, on the judgments and voids that persons give, and on the use of declared tasks.

Sinter traces objects and items in a git repository, such as designs,
specifications, requirements, terms, decision records, vector sets,
groups of conformance vectors, external items, work items, scope
objects, computed identity objects, tests, sites, and records. Each
object has one canonical form, a line object without an `id` member,
and one content hash and content id computed from the canonical byte
sequence of that canonical object. Two encodings store objects at rest
in a tree: text in files of the tree, and canonical byte sequences in
files under `.sinter/`. Every link of every object lives in its member
`edges`, as a set of `{"kind","to"}` flat objects whose `to` value is a
content id. Claims from code (citations in tests and sites) keep their
file and line beside the edge in the results. The ledger of a
repository consists of statements stored as fixed files in `.sinter/`
and observations and kept objects on the log branch. States, such as in
force, approved, suspect, or done, depend only on canonical objects and
the state inputs (term `state-input`), with no dependence on the order
of records. For example, bindings of parameters that designs name give
the kinds of subject of approval that need approval by a person, and
optionally the persons whose judgments count.

From Identifiers, the Ontology takes tag lines and Sinter tag words;
declarations, citations with their citation entries, status tags, and
`@ack` lines; inline citations, their destinations, and their targets;
segments, slugs, part names, full names, labels, and revisions;
external ids; the productions `declaration-line`, `citation-line`, and
`inline-destination`, and the matches of texts by productions; the
parameter `external-namespaces` with its bindings; and the result
"valid" that a conforming program of Identifiers gives for an input.
From Conformance (`conformance`), the Ontology takes designs,
specifications, requirements, objects, encodings, valid program's own
stores, conforming programs, inputs, and the general requirements that
bind every conforming program. From Text and notation, the Ontology
takes texts, lines, characters, hex digits, code point order, and whole
numbers; byte sequences, valid UTF-8, and the text of a byte sequence;
and what a result is. From Files and paths, the Ontology takes valid
paths, path sets, and the set of the valid paths that a path set gives.
From Data forms, the Ontology takes JSON values, canonical forms,
canonical byte sequences, hashes, line objects, id prefixes, hash ids,
and the hash-id form; and from its specification `test-vectors`,
test-vector sets with their vector lines, the objects, the forms, and
the groups of those lines, form pins with their schema part names and
schema labels, the forms of a group, and the meaning of a vector.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| Sinter | the tool that traces the items of a repository and checks the agreements that the people who work on the repository made |
| [object](sinter:#object=v1) | an entity of one of the twenty-five kinds in [object kind](sinter:#object-kind=v1), with one canonical form as a line object without an `id` member; findings, tests, sites, persons, agents, and commits are not objects |
| [object kind](sinter:#object-kind=v1) | one of the twenty-five kinds in the schema table of kinds, each with one kind word, one category, its members and types, whether it carries `by`, its allowed edge kinds and target kinds, whether a file of `.sinter/` may hold it, and whether a line of the log branch may hold it |
| [encoding](sinter:#encoding=v1) | a form in which objects are stored at rest: the text encoding in files of a tree, or the `.sinter/` encoding as canonical byte sequences in files under `.sinter/` outside `.sinter/local/` |
| [content hash](sinter:#content-hash=v1) | the SHA-256 hash of the canonical byte sequence of an object, with no member `id` and no final line feed |
| [content id](sinter:#content-id=v1) | the kind word of an object, `:`, and the first 32 lowercase hexadecimal digits of its content hash, such as `req:0dc878fd2dc3c179e4b8fa1829666011` |
| [computed identity](sinter:#computed-identity=v1) | an object of one of the five kinds `name`, `pin`, `ext`, `vector-set`, and `vector-group`, holding only `kind`, `v` (1), and its key, with no `edges`, `by`, or `ts` |
| [item](sinter:#item=v1) | an entity that Sinter traces, such as an item of the kind requirement, a test, or a task |
| [kind of item](sinter:#item=v1) | one of the fourteen kinds of item, such as design or task; each item has one |
| repository, commit, message of a commit, parent, branch, working tree, clone, push, pull request, merge | what git, or a host of git repositories, calls by this name |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [tree](sinter:#tree=v1) | a set whose members are the files of the tree, in which no two files of the tree have the same valid path, such as the tree of a commit or the tree of a working tree |
| [file of a tree](sinter:#tree=v1) | a member of a tree: a valid path with a content, which is a byte sequence |
| [text of a file of a tree](sinter:#tree=v1), [line of a file of a tree](sinter:#tree=v1) | the text of the content of a file of a tree, when that content is valid UTF-8; a line of that text |
| [tree of a commit](sinter:#tree=v1), [tree of a working tree](sinter:#tree=v1) | the one tree that a commit gives, and the one tree that a working tree gives; a working tree also has a folder tree |
| [default branch](sinter:#default-branch=v1) | the branch into which the people who work on a repository bring their work |
| actor | a person, an agent, or the job |
| [person](sinter:#person=v1) | a human who works on a repository |
| [agent](sinter:#agent=v1) | a program that uses a language model to write texts, such as code, as one person runs the program; the agent acts for that person |
| continuous integration | a service that runs checks on the commits of a repository |
| [job](sinter:#job=v1) | an execution of a conforming program that runs after a merge into the default branch of a repository, started by continuous integration or run by a person's hand, to write observations and kept objects on the log branch |
| [tag line](sinter:identifiers#tag-line=v1), [tag word](sinter:identifiers#tag-word=v1) | a line whose first character, after the spaces and tabs at its start, is `@`; its tag word is that `@` with the longest run of ASCII letters, ASCII digits, and `-` right after that `@`, such as `@req` |
| [declaration](sinter:identifiers#declaration=v1) | a tag line whose tag word is a declaration word, such as `@req limit-amount=v2` |
| [declaration word](sinter:identifiers#sinter-tag-word=v1) | one of the tag words `@atom`, `@decision`, `@design`, `@req`, `@schema`, `@spec`, and `@term` |
| [citation](sinter:identifiers#citation=v1) | a tag line whose tag word is a citation word, such as `@cites billing#limit-amount=v2` |
| [citation word](sinter:identifiers#sinter-tag-word=v1) | one of the tag words `@cites`, `@refines`, `@satisfies`, `@supersedes`, and `@verifies` |
| [citation entry](sinter:identifiers#citation-entry=v1) | one entry of the target of a citation, with one name, external id, vector selection, or content id, such as `billing#limit-amount=v2` in `@cites billing#limit-amount=v2`; in `@cites #{amount=v1}`, the part `amount=v1` stands for the citation entry `#amount=v1` |
| [inline citation](sinter:identifiers#inline-citation=v1) | a markdown link whose destination starts with `sinter:`, such as `[the limit](sinter:billing#limit-amount=v2)` |
| [target](sinter:identifiers#target=v1) | the text that follows the tag word of a declaration or a citation, up to the first space or tab outside braces, such as `limit-amount=v2` in `@req limit-amount=v2`; for an inline citation, its destination after `sinter:`, such as `billing#limit-amount=v2` |
| [status tag](sinter:identifiers#status-tag=v1) | a tag line whose tag word is a status word, such as `@deprecated` |
| [status word](sinter:identifiers#sinter-tag-word=v1) | the tag word `@deprecated` |
| [`@ack` line](sinter:identifiers#directive=v1) | a tag line whose tag word is `@ack`, such as `@ack retired docs#size=v2 3f2a9c1d` |
| [slug](sinter:identifiers#slug=v1) | one segment, or several segments joined by `/`, such as `billing` or `billing/auth`; a segment is a text of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them |
| [part name](sinter:identifiers#part-name=v1) | a segment, such as `limit-amount` in `billing#limit-amount` |
| [full name](sinter:identifiers#full-name=v1) | a slug, `#`, and a part name, such as `billing#limit-amount` |
| [label](sinter:identifiers#label=v1) | a text of the characters from `!` to `~`, other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, `}`, `[`, and `]`, such as `v2` |
| [revision of a citation entry](sinter:#pinned-edge=v1), [revision of an inline citation](sinter:#pinned-edge=v1) | the label, or `*`, that a citation entry, or the destination of an inline citation, carries after `=`, such as `v2` in `billing#limit-amount=v2`; `*` stands for any label |
| [external id](sinter:identifiers#external-id=v1) | a namespace name, such as `gh`, `/`, and an id, such as `42`, as in `gh/42`; a binding of the parameter `external-namespaces` gives the namespace names; an external id names an external item |
| [declared item](sinter:#declared-item=v1) | an object of one of the seven declared-item kinds (`design`, `spec`, `schema`, `req`, `atom`, `term`, `decision`), in either the text encoding (declared by a declaration for which a conforming program of Identifiers gives "valid") or the `.sinter/` encoding |
| [item of the kind design](sinter:#declared-item=v1) | a declared item of the kind `design` (in the text encoding, declared with `@design`); it is a design |
| [item of the kind specification](sinter:#declared-item=v1) | a declared item of the kind `spec` (in the text encoding, declared with `@spec`); it declares one specification of the design of which it is a part |
| [item of the kind requirement](sinter:#declared-item=v1) | a declared item of the kind `req` (in the text encoding, declared with `@req`); it declares one requirement of the design of which it is a part |
| [design](sinter:conformance#design=v1) | a document that declares, each under a name, obligations and definitions |
| [requirement](sinter:conformance#requirement=v1) | an obligation that a design declares under a name and states with the word must |
| [specification](sinter:conformance#specification=v1) | a part of a design that has a name of its own and that declares some of the obligations and definitions of the design |
| [schema](sinter:#schema=v1) | a declared item of the kind `schema` (in the text encoding, declared with `@schema`); it gives the form of an input or output that crosses the edge of a conforming program, or the form of a file of test cases for a design: its layout and every constraint that is a property of it alone |
| [atom](sinter:#atom=v1) | a declared item of the kind `atom` (in the text encoding, declared with `@atom`); it defines a named result that a conforming program gives, with the condition under which the conforming program gives that name |
| [term](sinter:#term=v1) | a declared item of the kind `term` (in the text encoding, declared with `@term`); it says what one word or one fixed phrase means, gives a grammar rule that other rules use, gives a form, or defines a computed value |
| normative | giving the form of an input or output, saying what a conforming program must do, defining a named result with its condition, or saying what one word or one fixed phrase means, giving a grammar rule, giving a form, or defining a computed value; only schemas, requirements, atoms, and terms are normative |
| [decision record](sinter:#decision-record=v1) | a declared item of the kind `decision` (in the text encoding, declared with `@decision`); it records one standing practice of a repository, or one choice with its reason |
| [finding](sinter:#finding-class=v1) | a report of one condition at one part of a repository; a finding is a result and not an object |
| [finding class](sinter:#finding-class=v1) | a kind of finding, which a slug names |
| [containment](sinter:#containment=v1) | the relation in which an item of the kind design holds items of the kind specification, schemas, items of the kind requirement, atoms, and terms, and an item of the kind specification holds schemas, items of the kind requirement, atoms, and terms |
| [hold](sinter:#containment=v1), [belong to](sinter:#containment=v1) | an item of the kind design holds each of its items of the kind specification, its schemas, its items of the kind requirement, its atoms, and its terms, and each of them belongs to that item of the kind design; an item of the kind specification holds its schemas, its items of the kind requirement, its atoms, and its terms in the same way, and names each in canonical form with an `items` edge |
| [hold directly](sinter:#containment=v1) | an item of the kind design holds a schema, an item of the kind requirement, an atom, or a term directly when that item belongs to that item of the kind design and to no item of the kind specification |
| [name of a declared item](sinter:#item-name=v1) | the name of a declared item, held in its canonical member `name`; in the text encoding, for an item of the kind design or a decision record, the slug in its declaration target, and for any other declared item, its full name (combining its design's name and its segment when declared by one segment inside a design) |
| [same item](sinter:#same-item=v1) | of two items of two trees: they are one item, such as two declared items with the same name, whatever their kinds |
| [conformance vector](sinter:#conformance-vector=v1) | a test case whose vector line is one vector line of a vector set; when the object of that vector line states a vector of the specification or the design of the vector set, the conformance vector says that vector; otherwise the conformance vector says no vector |
| [vector line of a conformance vector](sinter:#conformance-vector=v1) | one vector line of a vector set; each vector line of a vector set is the vector line of one conformance vector, and a vector set has no other conformance vector |
| [vector set](sinter:#vector-set=v1) | the test-vector set of an item of the kind specification, or of an item of the kind design, in a tree, when the tree has one; its computed identity object has the kind `vector-set` |
| [form pin](sinter:data-forms#form-pin=v1) | `#`, a schema part name, `=`, and a schema label, such as `#offsets-vector=v1`, which names a schema and a label of it |
| [form of a vector line](sinter:data-forms#vector-line=v1) | the value of the member `form` of the object of a vector line, which is a form pin |
| [group of a vector line](sinter:data-forms#vector-line=v1) | the value of the member `group` of the object of a vector line, which is a group name such as `offsets` |
| [group of conformance vectors](sinter:#conformance-vector-group=v1) | the set of the conformance vectors of one vector set whose vector lines have one group as the value of the member `group`; its computed identity object has the kind `vector-group` and its description object has the kind `vector-group-def` |
| [test](sinter:#test=v1) | a unit of code that a test runner runs and that can pass or fail, or a set of such units that the code groups under one name, such as the tests of one `describe` block; a test is an item and not an object |
| test runner | a program that runs tests and gives a test result for each test that it runs |
| [name of a test](sinter:#test=v1) | a sequence of own names: the own names of the tests of which the test is a part, from the outermost to the innermost, and then the own name of the test; for example, the own name of the test function `t` is `t` |
| [file of a test](sinter:#test=v1) | the file of a tree in which a test is |
| [code of a test](sinter:#test=v1) | the part of the file of a test that the test takes up |
| [comment on a test](sinter:#test=v1) | a comment that is attached to the code of a test, such as the comment right before a test function |
| [test evidence](sinter:#test-evidence=v1) | for one execution of test runners, the test results of that execution that say that the tests that those test results name passed or that those tests failed |
| [test result](sinter:#test-evidence=v1) | what a test runner gives for one test that the test runner runs; each test result names no test, one test, or more than one test, and the test result says the same of each test that the test result names |
| [site](sinter:#site=v1) | a part of a file of a tree that is outside every declared item and every comment on a test, and that has a citation, an inline citation, or an `@ack` line, such as one section of a file of a tree in markdown, or one comment in code; a site is an item and not an object |
| [external item](sinter:#external-item=v1) | an entity outside the repository that an external id names, such as an issue or a published standard; its computed identity object has the kind `ext` |
| [label of an item](sinter:#revised-content=v1), [current revision](sinter:#item-revision=v1) | the label that a declared item has in a given tree, held in its canonical member `label` when present |
| [revised content](sinter:#revised-content=v1) | the content that a declared item's canonical object represents, identified by its content hash |
| [revision of an item](sinter:#item-revision=v1) | a label that an item has, which names a revised content (canonical object) of the item with that label |
| [edge](sinter:#edge=v1) | a relation of one of the twenty-one kinds of edge from a source to a target; in every object, every edge stands in the member `edges` as `{"kind","to"}` with a content id in `to` |
| [kind of edge](sinter:#edge=v1) | one of the twenty-one kinds of edge: the five citation kinds (`cites`, `satisfies`, `verifies`, `refines`, `supersedes`) and the sixteen structural, scope, and record kinds (`items`, `revises`, `withdraws`, `about`, `part-of`, `waits-for`, `promises-satisfies`, `promises-verifies`, `carries-out`, `tracks`, `judges`, `observes`, `records`, `kept-satisfies`, `kept-verifies`, `scoped-by`) |
| [claim from code](sinter:#edge=v1) | a claim in the results produced from a citation or inline citation standing in a test or a site, holding its edge (`kind` and `to`) and, beside the edge, its location (file and line) |
| [be for](sinter:#edge=v1) | a citation kind of edge is for some kinds of item or object as its source and as its target; an edge of that kind says what its kind of edge says when, and only when, its source and its target are of those kinds |
| [stand in](sinter:#edge-source=v1) | a line of a file of a tree, a citation, or an inline citation stands in the innermost declared item of which it is a part; otherwise in the innermost test such that a comment on that test has it; otherwise in the site that has it; otherwise in no item |
| [source](sinter:#edge=v1) | the object or item from which an edge runs |
| [cited item](sinter:#edge=v1) | the item or object that a citation edge names |
| [pinned edge](sinter:#pinned-edge=v1) | a citation edge whose canonical target is an exact declared-item object or a `pin` object |
| [work item](sinter:#work-item=v1) | a task or a plan, stored as a small nonce object of the kind `task` or `plan` in `.sinter/` |
| [work item id](sinter:#work-item=v1) | the content id of a work item object (`task:<32 hex>` or `plan:<32 hex>`), which never changes and names exactly one work item |
| [display name](sinter:#work-item=v1) | the name of a work item that a person reads, held in its definitions, which can change |
| [task](sinter:#task=v1) | one piece of work that one person or one agent can finish alone |
| [work of a task](sinter:#task=v1) | what people and agents change in the trees of a repository to finish a task |
| [paths of a task](sinter:#task=v1) | the path set (stored as a set in the task's scope object) whose set has the valid paths of the files of a tree that the work of a task is to add, change, or remove |
| [path set](sinter:files#path-set=v1) | a finite sequence of texts, its path set members, such as `docs/` followed by `!docs/old/` |
| [set of a path set](sinter:files#path-set-membership=v1) | the paths that a path set gives: for `docs/` followed by `!docs/old/`, `docs/a.md` and not `docs/old/a.md` |
| [scope object](sinter:#scope-object=v1) | a non-record object of the kind `scope` holding a task's `paths` set, its promise edges, and an `about` edge naming its task |
| [promise](sinter:#promise=v1) | a pair of a kind of edge, `satisfies` or `verifies`, and the name of an item of the kind requirement, held on a task's scope object |
| [keep a promise](sinter:#promise=v1) | a promise is kept in a tree when the tree has an edge that the promise promises, from a citation in a text file in the paths of the task, and that edge is not suspect, and, for a `verifies` promise, test evidence shows that the source of that edge passed |
| [plan](sinter:#plan=v1) | one piece of work that is made up of tasks and plans |
| [plan of a work item in a definition](sinter:#work-item-definition=v1) | the plan, or none, that the definition names with `part-of` |
| [wait](sinter:#wait=v1) | a relation from a work item, the waiting item, to another work item, the work item that the waiting item waits for |
| [carry out](sinter:#carried-out-item=v1) | a plan carries out the items of the kind requirement, specification, and design that its definition names with `carries-out` |
| [definition of a work item](sinter:#work-item-definition=v1) | for a task, a display name, a scope object named with `scoped-by` (giving its paths and promises), at most one external item, at most one plan, and waits; for a plan, a display name, at most one plan, waits, and the items that the plan carries out |
| [delivery line](sinter:#delivery-line=v1) | a line of the message of a commit that says that the commit completes the work of a task, naming the task by its work item id and its scope by the first six lowercase hexadecimal digits of the scope object's content hash |
| [task line](sinter:#task-line=v1) | a line of the message of a commit that names a task by its work item id and says that the commit does part of the work |
| [ledger](sinter:#ledger=v1) | the statements stored as fixed object files in `.sinter/` of a tree together with the observations and kept objects on the log branch |
| [record](sinter:#ledger-entry=v1), [ledger entry](sinter:#ledger-entry=v1) | an object of one of the nine record kinds: one of the seven statement kinds or one of the two observation kinds; every record carries `by` |
| [statement](sinter:#statement=v1) | a record of one of the seven statement kinds in `object-kind` (a definition, a judgment, or a void) that a person or an agent writes in `.sinter/` |
| [void](sinter:#void-statement=v1), [void statement](sinter:#void-statement=v1) | a statement of the kind `void` with which a person withdraws one withdrawable object (never a `void`, a work item object, a computed identity object, or a `vector-group-def`) |
| [log branch](sinter:#log-branch=v1) | a dedicated branch of a repository, named by a parameter, that holds only the observations and kept objects written by the job and that only grows |
| [kept object](sinter:#log-branch=v1) | a copy of a merged declared item, or of a computed identity object named by a kept declared item (other than its own `name`), stored on the log branch without `seq` or `by` and deduplicated by content id |
| [definition statement](sinter:#definition-entry=v1), [definition entry](sinter:#definition-entry=v1) | a statement of the kind `task-def` or `plan-def` that records one whole definition of one work item |
| [thing](sinter:#thing=v1) | the object that the `about` edge of a definition, a judgment, a declared item, a `scope` object, a `vector-group-def`, or a `delivered` observation names; a `void`, a `progress` observation, a work item object, and a computed identity object have no thing |
| [accepted](sinter:#thing=v1), [counting statement](sinter:#thing=v1) | a statement is accepted when a design gives an acceptance rule for its kind and that rule holds; a statement counts when it is accepted, is withdrawn by no counting void, carries no `agent` when it is a judgment or void, and has a writer in the bound list of persons when it is a judgment |
| [latest statement](sinter:#thing=v1) | a counting statement of a group of statements of a thing that no other counting statement of that group replaces through `revises` edges (directly or through a counting void's copied edges) |
| [agree](sinter:#conflict=v1), [conflict](sinter:#conflict=v1) | latest statements of one group of statements of a thing agree when they give their thing the same state; latest statements of one group that neither agree nor judge different definitions of a work item, or a completing `delivered` observation that decides a state with a latest `abandoned` judgment of the same definition, are a conflict, which decides nothing |
| [current definition](sinter:#work-item-state=v1) | the definition recorded by the latest counting definition statements of a work item when at least one exists and all agree |
| [exist](sinter:#work-item-state=v1) | a work item exists in a tree when its `task` or `plan` object is in `.sinter/` of that tree, even when it has no current definition |
| [part of a plan](sinter:#work-item-state=v1) | a work item whose current definition names the plan with `part-of` and that is not abandoned |
| [under a plan](sinter:#work-item-state=v1) | a part of the plan, or linked to the plan by a finite chain of work items each a part of the next |
| [subject of approval](sinter:#subject-of-approval=v1) | a unit that a person approves, or that the merge approves, as a whole |
| [kind of subject of approval](sinter:#subject-of-approval=v1) | which of seven units a subject of approval is: an item of the kind design without the declared items that it holds; an item of the kind specification with the schemas, the items of the kind requirement, the atoms, and the terms that it holds; a schema, an item of the kind requirement, an atom, or a term that an item of the kind design holds directly; or a decision record |
| [subject of approval of a declared item](sinter:#subject-of-approval=v1) | for a declared item that is the declared item of a subject of approval, that subject of approval; for a schema, an item of the kind requirement, an atom, or a term that an item of the kind specification holds, the subject of approval of that item of the kind specification |
| [parameter](sinter:#parameter=v1), [binding of a parameter](sinter:#parameter=v1) | a parameter is a word, such as `external-namespaces`, whose value a design leaves open; a binding of a parameter is a value that configuration gives for the parameter; when a design declares a schema whose part name is the name of a parameter, a binding of that parameter is valid when, and only when, it meets that schema |
| process | one execution of a program |
| standard input, arguments, environment | the standard input, the command-line arguments, and the environment variables of a process |
| [judgment](sinter:#judgment=v1) | a statement of one of the four judgment kinds in `object-kind` that records a decision of a person |
| [record of the job](sinter:#job-record=v1), [observation](sinter:#job-record=v1) | a record of the kind `delivered` or `progress` on the log branch that records what the job observed |
| [state](sinter:#state=v1) | a named condition of an item, an edge, a wait, or a subject of approval in a tree, such as in force or done |
| [state input](sinter:#state-input=v1) | one of the inputs on which states depend: the commits with their parents and trees; the commit of each branch and of the default branch; the tree of each working tree; delivery lines and task lines in commit messages; the observations and kept objects on the log branch; test evidence; and parameter bindings |
| [retired](sinter:#retired-item=v1) | a declared item is retired when it is deprecated, when it is the cited item of an effective `supersedes` edge and is on no cycle of `supersedes` edges, or when it belongs to a retired item of the kind design or a retired item of the kind specification |
| [in force](sinter:#in-force-item=v1) | a declared item is in force when it is not retired |
| [effective](sinter:#effective-supersedes-edge=v1) | a `supersedes` edge is effective when the edge says what its kind of edge says, neither its source nor an item that holds its source is deprecated, and its source is approved |
| [cycle of `supersedes` edges](sinter:#supersedes-cycle=v1), [on a cycle of `supersedes` edges](sinter:#supersedes-cycle=v1) | a finite sequence of one or more pairs (x, y) of declared items in a tree in which each pair comes from a `supersedes` edge that says what `supersedes` says, the second item of each pair before the last is the first item of the next, and the second item of the last is the first item of the first |
| [deprecated](sinter:#deprecated-item=v1) | the state that a deprecation status tag gives to a declared item |
| [approved, declined](sinter:#approval-state=v1) | the states of a subject of approval whose current object a person approved or declined, or, for a kind of subject of approval that needs no approval by a person, whose current object merged into the default branch |
| [draft](sinter:#draft-design=v1) | an item of the kind design is a draft while it is not approved |
| [suspect](sinter:#suspect-edge=v1) | a pinned edge is suspect when the declared item that it names exists in the tree and either the edge names an exact object other than the item's current object in the tree or the edge names a `pin` object whose label differs from the item's current revision in the tree |
| [open, delivered, done, abandoned](sinter:#work-item-state=v1) | the four states of a task |
| [open, done, abandoned](sinter:#work-item-state=v1) | the three states of a plan |
| [unfinished](sinter:#work-item-state=v1) | a task is unfinished while it is open or delivered |
| [met](sinter:#met-wait=v1) | a wait says that the work of the waiting item is to start only after the work item that it waits for is done; a wait is met when the work item that it waits for is done |
| [ready](sinter:#ready-task=v1) | a task is ready when it is open and its waits, and the waits of each plan that it is under, are met |
| [accounted for](sinter:#requirement-accounted-for=v1) | an item of the kind requirement is accounted for when work for it is under way, or was finished at the exact object that it has in the tree |
| session | one execution of an agent on its work |
| declared task | the task that an agent declares as the work of its session |
| brief of a session | the text about the work of the session that a conforming program gives the agent of that session, in no state input |

## 2. The objects, items, relations, and states

### 2.1 Objects, encodings, content hashes, and regularity

Every object of Sinter belongs to one of twenty-five object kinds,
organized in one schema table of kinds (terms `object-kind`, `object`,
and `encoding`). Each object has one canonical form: a line object of
Data forms without a member `id`. Five rules of regularity govern every
canonical object:

1. One word names each kind: the member `kind` and the kind word of the
   content id are the same short word, such as `req` or `task-def`.
2. Every array that a schema does not declare a sequence is a set,
   sorted in code point order of each element's canonical form with no
   duplicates (`edges` and `paths` are sets).
3. One thing edge (`about`) names the thing of every definition,
   judgment, declared-item description, `delivered` observation, group
   description object (`vector-group-def`), and scope object (`scope`).
4. One schema table (`object-kind`) states the members, types, `by`
   presence, allowed edge kinds, target kinds, `.sinter/` storage, and
   log-branch storage of all twenty-five kinds.
5. Every record carries `by`, and no item, work item object, computed
   identity object, group description object, scope object, or kept copy
   carries `by`.

The content hash of an object is the SHA-256 hash of its canonical byte
sequence with no `id` and no final line feed, and its content id is its
kind word, `:`, and the first 32 hex digits of that hash (terms
`content-hash` and `content-id`). Two encodings store objects at rest in
a tree: text in files of the tree (mutable, edited in place) and
canonical byte sequences in fixed files under `.sinter/` outside
`.sinter/local/`.

### 2.2 Items and their kinds

Sinter traces items of fourteen kinds of item, such as the declared item
of the kind requirement that `@req limit-amount=v2` declares, a test,
and a task (terms `item` and `declared-item`). Twelve of the fourteen
kinds are objects; tests and sites are items that are not objects, and a
claim from code keeps its file and line beside the edge in the results.
Computed identity objects (`name`, `pin`, `ext`, `vector-set`,
`vector-group`), group description objects (`vector-group-def`), and
scope objects (`scope`) are non-record objects carrying no `by`.

### 2.3 Repositories and actors

A repository has trees, such as the tree of a commit and the tree of a
working tree (which also has a folder tree), and a default branch (terms
`tree` and `default-branch`). Persons, agents, and the job write the
records of the repository (terms `person`, `agent`, and `job`).

### 2.4 Designs, specifications, schemas, requirements, atoms, and terms

An item of the kind design holds items of the kind specification,
schemas, items of the kind requirement, atoms, and terms, and an item of
the kind specification holds schemas, items of the kind requirement,
atoms, and terms (terms `containment`, `schema`, `atom`, and `term`).
In canonical form, a specification names each declared item that it
holds with an `items` edge, whereas a design holds no edges to its
parts.

In this example in the text encoding, an item of the kind design
`billing` holds one item of the kind specification `invoice`. That item
of the kind specification holds one term `amount` and one item of the
kind requirement `limit-amount`. This table gives the lines of the file
of the design `billing` in their order, without the blank lines:

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

### 2.5 Names, identity, and computed identity objects

Each declared item has a name, such as `billing#limit-amount` for the
item of the kind requirement of the example of section 2.4 (term
`item-name`). Two declared items in two trees are the same item when
they have the same name, whatever their kinds (term `same-item`).
Declared-item names (`name`), unresolved pins (`pin`), external items
(`ext`), vector sets (`vector-set`), and groups of conformance vectors
(`vector-group`) each have a computed identity object holding only
`kind`, `v` (1), and its key, with no `edges`, `by`, or `ts` (term
`computed-identity`).

### 2.6 Decision records and finding classes

A decision record, such as the record `code-comments`, is a declared
item of the kind `decision` in either encoding that records one standing
practice of a repository or one choice with its reason (term
`decision-record`). A finding is a report of one condition at one part
of a repository; findings are results and not objects (term
`finding-class`).

### 2.7 Conformance vectors

Each conformance vector belongs to the vector set of one item of the
kind specification or of one item of the kind design, and to one group
of conformance vectors of that vector set (terms `conformance-vector`,
`conformance-vector-group`, and `vector-set`). Each group has a computed
identity object `vector-group` (with `owner` and `group`) and a group
description object `vector-group-def` (naming `vector-group` with
`about` and holding the `cites` edges from the `form` members of its
vector lines).

A test that checks code against the conformance vectors of a group of
conformance vectors can cite that group of conformance vectors with
`@verifies`:

```python
# @verifies data-forms#toml[offsets]
def test_offsets(vector):
    ...
```

### 2.8 Tests, sites, and external items

Tests, such as a test function, sites, such as one comment in code that
has a citation, and external items, such as the issue `gh/42`, are items
that no declaration declares, and the test evidence of an execution of
test runners says which tests passed and which failed (terms `test`,
`test-evidence`, `site`, and `external-item`).

### 2.9 Edges

Every link of every object lives in its member `edges` (absent when
empty) as a set of `{"kind","to"}` flat objects whose `to` value is a
content id, across twenty-one kinds of edge (terms `edge`,
`edge-source`, `pinned-edge`, `cites-edge`, `satisfies-edge`,
`verifies-edge`, `refines-edge`, and `supersedes-edge`).

For example, `@supersedes billing#old-limit=v1` on a requirement
`billing#limit-amount=v2` gives a `supersedes` edge saying that
`billing#limit-amount` is to replace the different declared item
`billing#old-limit`. By contrast, replacement within one thing — a new
revision of a declared item in `.sinter/`, a new work item definition,
or a new judgment settling other judgments — uses a `revises` edge.

### 2.10 Revisions and pins

The revised content of a declared item is its canonical object,
identified by its content hash, and an exact pin such as
`@cites billing#limit-amount=v2` resolves to the exact object of that
revision in the tree (including one replaced, unwithdrawn revision that
`.sinter/` still holds) or among the unwithdrawn kept objects on the log
branch, when the pin lies on no cycle of the tree's own objects (terms
`revised-content`, `item-revision`, and `pinned-edge`). Otherwise — on a
cycle of pins in the tree's own objects, on a dangling pinned citation
of an undeclared name, or on an ambiguous pin matching two or more
replaced, unwithdrawn objects in `.sinter/` or two or more unwithdrawn
kept objects on the log branch of one label — the canonical edge names a
`pin` computed identity object. An ambiguous pin gives no exact target,
and withdrawing matching copies with counting voids until one remains
settles the ambiguity. A pin to a revision that never merged, or to a
withdrawn kept object, is a missing part.

### 2.11 Tasks, plans, and scopes

A work item is a task or a plan, stored as a small nonce object (`task`
or `plan`) in `.sinter/` whose content id is its work item id (terms
`work-item`, `task`, `plan`, `scope-object`, `promise`, `wait`,
`carried-out-item`, `work-item-definition`, `delivery-line`, and
`task-line`). A task's paths and promises live in a `scope` object that
names the task with `about`; each `task-def` names its `scope` object
with `scoped-by`. A promise is kept only by an edge from a citation in a
text file inside the paths of the task. A delivery line in a commit
message names the task by its work item id (`task:<32 hex>`) and its
scope by the first six lowercase hex digits of the scope object's
content hash.

### 2.12 The ledger

The ledger of a repository consists of statements stored as fixed object
files in `.sinter/` of a tree (forming a Merkle graph with the other
objects of `.sinter/`) and observations and kept objects on the log
branch (terms `ledger`, `ledger-entry`, `statement`, `void-statement`,
`log-branch`, `definition-entry`, `judgment`, `job-record`, `thing`, and
`conflict`). Persons and agents write definitions (and non-record
objects) in `.sinter/`; only persons write judgments and voids in
`.sinter/`; only the job writes observations and kept objects on the log
branch.

### 2.13 States

A state, such as in force, approved, suspect, or done, is a named
condition of an item, an edge, a wait, or a subject of approval in a
tree, and it follows from canonical objects and the state inputs alone,
with no dependence on the order of records (terms `state`,
`state-input`, `subject-of-approval`, `approval-state`, and
`supersedes-cycle`, atoms `work-item-state`, `deprecated-item`,
`draft-design`, `effective-supersedes-edge`, `retired-item`,
`in-force-item`, `suspect-edge`, `met-wait`, `ready-task`, and
`requirement-accounted-for`, and requirement
`compute-states-from-artifacts`). A conflict decides nothing, a
statement that does not count takes no part in the graph of its thing,
and no state holds only by resting on itself through a cycle.

What a program gives while another process changes a state input is a
matter of the quality of an implementation.

### 2.14 Texts that agents write

A text that an agent writes can be a line of a file of a tree, a line of
the message of a commit, a definition statement in `.sinter/`, or a
message to a person. When the input of a conforming program says that an
agent runs the conforming program, the conforming program writes no
judgment, no void, and no observation, and writes nothing to the log
branch (section 4.4). A conforming program writes a judgment or a void
only to record a decision that a person gives the program by a
confirmation that the standard input, the arguments, and the environment
of the program cannot give (section 4.5).

A session is one execution of an agent on its work. The agent can
declare a task as the work of its session: the declared task of the
session. The brief of a session is the text about the work of the
session that a conforming program gives the agent of that session, in
no state input. A conforming program uses the declared task of a session
for nothing other than the brief of that session (section 4.6).

## 3. Definitions

### 3.1 Trees

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
gives one tree, the tree of the commit. A working tree of a git
repository gives one tree, the tree of the working tree. A working tree
of a git repository also has a folder tree, holding folders and files,
in which the files of the tree of the working tree stand. The text of a
file of a tree is the text of the content of that file, when that
content is valid UTF-8. A line of a file of a tree is a line of that
text.

### 3.2 Default branches

@term default-branch=v1
@cites #{person=v1}

The default branch of a git repository is the branch into which the
people who work on the repository bring their work.

### 3.3 People

@term person=v1

A person is a human who works on a repository.

### 3.4 Agents

@term agent=v1
@cites {text#{text=v1}, #{person=v1}}

An agent is a program that uses a language model to write texts, such as
code, as one person runs the program. Several people can run one
program, and each of them then runs a different agent. Each agent acts
for one person: the person who runs it.

### 3.5 The job

@term job=v1
@cites {
    conformance#{conforming-program=v1},
    #{default-branch=v1, person=v1},
}

The job is an execution of a conforming program that runs after a merge
into the default branch of a repository — started by continuous
integration on a push to the default branch or on a merged pull request
with the workflow of the default branch, or run by a person's hand — to
write observations and kept objects on the log branch.

### 3.6 Declared items

@term declared-item=v1
@cites {
    identifiers#{
        declaration=v1, sinter-tag-word=v1, external-namespaces=v1,
        give-line-results=v1, line-result=v1,
    },
    conformance#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1,
    },
    text#{result=v1},
    #{tree=v1, agent=v1},
}

A declared item is an item of one of these seven kinds of item: design,
specification, schema, requirement, atom, term, and decision record. A
declared item may stand in the text encoding or in the `.sinter/`
encoding.

In the text encoding, a declared item is what a declaration declares,
taking up a part of one file of a tree that holds that declaration. The
declaration word of that declaration alone gives the kind of the
declared item: `@design` gives the kind design, `@spec` gives the kind
specification, `@schema` gives the kind schema, `@req` gives the kind
requirement, `@atom` gives the kind atom, `@term` gives the kind term,
and `@decision` gives the kind decision record. Only a declaration for
which a conforming program of the design Identifiers gives the result
"valid" under the binding of `external-namespaces` declares a declared
item in the text encoding.

In the `.sinter/` encoding, a valid object of one of the seven
declared-item kinds in a file of `.sinter/` of a tree (whose member
`kind` gives its kind) is a declared-item object in that tree. Such an
object is withdrawn in a tree when a valid `void` object in `.sinter/`
of that tree that carries no `agent` and meets an acceptance rule that a
design gives for `void` names it with a `withdraws` edge. An object of a
name in `.sinter/` is replaced in a tree when, and only when, one of
these is true: a declared-item object of that name in `.sinter/` of that
tree that is not withdrawn names it with a `revises` edge; or a valid
`void` object in `.sinter/` of that tree that carries no `agent`, meets
an acceptance rule that a design gives for `void`, and has a
declared-item kind as its member `withdrawn-kind` holds a `revises` edge
that names it. A declared item in the `.sinter/` encoding is a
declared-item object in `.sinter/` of that tree that is neither
withdrawn nor replaced.

An item of the kind design is a design. An item of the kind
specification declares one specification of the design of which that
item of the kind specification is a part. An item of the kind
requirement declares one requirement of the design of which that item of
the kind requirement is a part.

### 3.7 Containment

@term containment=v1
@cites #{declared-item=v1, schema=v1, atom=v1, term=v1}

Containment is a relation in which one declared item holds another
declared item, and that other declared item belongs to the first
declared item. Containment links these kinds of item. An item of the
kind design holds items of the kind specification, schemas, items of the
kind requirement, atoms, and terms. An item of the kind specification
holds schemas, items of the kind requirement, atoms, and terms. No other
declared item holds a declared item. Each declared item belongs to at
most one item of the kind design and to at most one item of the kind
specification. When an item of the kind specification belongs to an item
of the kind design, a schema, an item of the kind requirement, an atom,
or a term that belongs to that item of the kind specification belongs to
that item of the kind design. When an item of the kind specification
belongs to no item of the kind design, a schema, an item of the kind
requirement, an atom, or a term that belongs to that item of the kind
specification belongs to no item of the kind design. An item of the kind
design holds directly a schema, an item of the kind requirement, an
atom, or a term when that schema, that item of the kind requirement,
that atom, or that term belongs to that item of the kind design and
belongs to no item of the kind specification. In canonical form, an
item of the kind specification names each declared item that it holds
with an `items` edge carrying no position or order, and an item of the
kind design holds no edges to the declared items that it holds.

### 3.8 Schemas

@term schema=v1
@cites {conformance#{conforming-program=v1}, #{declared-item=v1}}

A schema is a declared item of the kind `schema` (in the text encoding,
a declared item whose declaration word is `@schema`). A schema gives the
form of an input or output that crosses the edge of a conforming
program, or the form of a file of test cases for a design: its layout
and every constraint that is a property of it alone.

### 3.9 Atoms

@term atom=v1
@cites {conformance#{conforming-program=v1}, #{declared-item=v1}}

An atom is a declared item of the kind `atom` (in the text encoding, a
declared item whose declaration word is `@atom`). An atom defines a
named result that a conforming program gives, with the condition under
which the conforming program gives that name.

### 3.10 Terms

@term term=v1
@cites #{declared-item=v1}

A term is a declared item of the kind `term` (in the text encoding, a
declared item whose declaration word is `@term`). A term says what one
word or one fixed phrase means, gives a grammar rule that other rules
use, gives a form, or defines a computed value. Other items can use what
the term defines.

### 3.11 Decision records

@term decision-record=v1
@cites #{declared-item=v1}

A decision record is a declared item of the kind `decision` (in the text
encoding, a declared item whose declaration word is `@decision`). A
decision record records one standing practice of a repository, or one
choice with the reason for that choice.

### 3.12 Findings and finding classes

@term finding-class=v1
@cites identifiers#{slug=v1}

A finding is a report of one condition at one part of a repository. A
finding is a result and not an object. A finding class is a kind of
finding, which a slug names.

### 3.13 Names

@term item-name=v1
@cites {
    identifiers#{
        slug=v1, full-name=v1, declaration=v1, segment=v1,
        declaration-line=v1, target=v1,
    },
    #{
        declared-item=v1, containment=v1, schema=v1, atom=v1, term=v1,
        decision-record=v1, tree=v1,
    },
}

In a tree, the canonical member `name` of a declared item holds its
name. In the text encoding, the name of an item of the kind design or of
a decision record is the name in the target of its declaration, which is
a slug such as `billing`, and the name of an item of the kind
specification, of a schema, of an item of the kind requirement, of an
atom, or of a term is this:

- when the name in the target of its declaration is a full name, that
  full name;
- when the name in the target of its declaration is one segment and the
  item belongs to an item of the kind design in that tree, the name of
  that item of the kind design, `#`, and that segment, such as
  `billing#amount`;
- otherwise, the name in the target of its declaration.

In the `.sinter/` encoding, the name of a declared item is the value of
its member `name`.

### 3.14 Vector sets

@term vector-set=v1
@cites {
    data-forms#{test-vector-set=v1, group-form-list=v1},
    #{declared-item=v1, schema=v1, tree=v1},
}

In a tree, each item of the kind design and each item of the kind
specification has at most one vector set: the test-vector set of that
item in that tree, when the tree has one, whether or not a schema that
the item declares gives the forms of a group for each of its groups.

### 3.15 Conformance vectors

@term conformance-vector=v1
@cites {
    data-forms#{
        vector-line=v1, vector-object=v1, vector-meaning=v1,
    },
    conformance#{
        design=v1, specification=v1, requirement=v1,
        conforming-program=v1, input=v1,
    },
    #{vector-set=v1, declared-item=v1, containment=v1},
}

Each vector line of a vector set is the vector line of one conformance
vector of that vector set. That vector set has no other conformance
vector. When the object of its vector line states a vector of the
specification that the item of its vector set declares, or of the design
that is that item, the conformance vector says that vector: for the
vector set of an item of the kind specification, an input, or several
inputs, of a conforming program of the specification that the item
declares, and what the requirements of that specification oblige that
program to give for them; for the vector set of an item of the kind
design, an input, or several inputs, of a conforming program of that
design, and what the items of the kind requirement that the design holds
directly oblige that program to give for them. Otherwise, the
conformance vector says no vector.

### 3.16 Groups of conformance vectors

@term conformance-vector-group=v1
@cites {
    data-forms#{vector-line=v1, vector-object=v1},
    #{vector-set=v1, conformance-vector=v1},
}

For each group that a vector line of a vector set has as the value of
the member `group`, the set of the conformance vectors of that vector
set whose vector lines have that group as the value of the member
`group` is a group of conformance vectors of that vector set. The name
of that group of conformance vectors is that group. A vector set has no
other group of conformance vectors.

### 3.17 Tests

@term test=v1
@cites {identifiers#{declaration=v1}, #{tree=v1}}

A test is a unit of code that a test runner runs and that can pass or
fail, such as a test function, or a set of such units that the code
groups under one name, such as the tests of one `describe` block. No
declaration declares a test. A test is an item and not an object. Each
test is in one file of a tree, the file of the test. Each test has its
own name, such as `t` for the test function `t`. The name of a test is a
sequence of own names: the own names of the tests of which the test is a
part, from the outermost to the innermost, and then the own name of the
test. So the test function `t` in the `describe` block `a` and the test
function `t` in the `describe` block `b` of one file of a tree have
different names. The code of a test is the part of the file of the test
that the test takes up. A comment on a test is a comment that is
attached to the code of the test, such as the comment right before a
test function.

### 3.18 Test evidence

@term test-evidence=v1
@cites #{test=v1}

A test result is what a test runner gives for one test that the test
runner runs. Each test result names no test, one test, or more than one
test. Each test result says the same of each test that the test result
names. The test evidence of one execution of test runners is the set of
the test results of that execution that say that the tests that those
test results name passed or that those tests failed.

### 3.19 Sites

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
a line in common. A site has no name. A site is an item and not an
object.

### 3.20 External items

@term external-item=v1
@cites identifiers#{external-id=v1, part-name=v1}

An external item is an entity outside the repository that an external id
names, even when nothing outside the repository has that external id. An
external id with `#` and a part name after that external id, such as
`rfc/8259#section-6`, names a part of such an item. That part is an
external item too.

### 3.21 Work items

@term work-item=v1
@cites #{task=v1, plan=v1, tree=v1}

A work item is a task or a plan. Each work item is represented at rest
by one small nonce object of the kind `task` or `plan` in `.sinter/` of
a tree, holding only `kind`, `v` (1), and `nonce` (32 lowercase hex
digits), with no `edges`, no `by`, and no `ts`. The work item id of a
work item is the content id of that work item object (`task:<32 hex>` or
`plan:<32 hex>`), which never changes and which names exactly one work
item. Each work item has a display name in its definitions, which can
change.

### 3.22 Tasks

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
external item, which can say what the work is. Several tasks can name
one external item. A task has no prose body of its own and no branch of
its own.

### 3.23 Plans

@term plan=v1
@cites #{task=v1}

A plan is one piece of work that is made up of tasks and plans.

### 3.24 Waits

@term wait=v1
@cites #{work-item=v1}

A wait is a relation from one work item, the waiting item, to another
work item, the work item that it waits for.

### 3.25 What a plan carries out

@term carried-out-item=v1
@cites #{plan=v1, item-name=v1, declared-item=v1, task=v1}

A plan carries out a set of items of the kind requirement,
specification, or design: the work of the tasks that make up the plan,
directly or through other plans, is for the items in that set. A plan
definition names each item in that set with a `carries-out` edge (by the
content id of its `name` identity object, or by the content id of an
exact `design`, `spec`, or `req` object).

### 3.26 Items

@term item=v1
@cites #{
    declared-item=v1, schema=v1, atom=v1, term=v1, decision-record=v1,
    conformance-vector-group=v1, vector-set=v1, task=v1, plan=v1,
    test=v1, site=v1, external-item=v1,
}

An item is an entity that Sinter traces. Each item has exactly one of
these fourteen kinds of item: the seven kinds of a declared item, which
are design, specification, schema, requirement, atom, term, and decision
record; and group of conformance vectors, vector set, task, plan, test,
site, and external item.

### 3.27 Identity of items across trees

@term same-item=v1
@cites {
    files#{path=v1},
    #{
        item=v1, declared-item=v1, item-name=v1, vector-set=v1,
        conformance-vector-group=v1, work-item=v1, external-item=v1,
        test=v1, tree=v1,
    },
}

An item of one tree and an item of another tree are the same item
when, and only when, one of these is true:

- both are declared items with the same name, whatever their kinds of
  item and their encodings;
- both are groups of conformance vectors, with the same name, and their
  vector sets are the same item;
- both are vector sets, of items of the kind specification that are the
  same item, or of items of the kind design that are the same item;
- both are work items, with the same work item id;
- both are external items, with the same external id;
- both are tests, the files of the two tests have the same valid path,
  and the names of the two tests are equal.

### 3.28 Object kinds and the schema table

@term object-kind=v1
@cites {
    data-forms#{
        json-value=v1, line-object=v1, canonical-form=v1, id-prefix=v1,
        hash-id-form=v1,
    },
    text#{text=v1, hex-digit=v1, whole-number=v1, code-point-order=v1},
    files#{path-set=v1},
    identifiers#{
        slug=v1, full-name=v1, label=v1, external-id=v1, part-name=v1,
    },
    #{
        schema=v1, atom=v1, term=v1, vector-set=v1, task=v1, plan=v1,
        agent=v1,
    },
}

Sinter defines twenty-five object kinds. Each object kind has one short
kind word (which is both the value of the object's member `kind` and the
kind word of its content id), one object category, a set of members and
types, a boolean stating whether objects of the kind carry `by`, a set
of allowed edge kinds with their allowed target kinds, a boolean stating
whether a file of `.sinter/` may hold an object of the kind, and a
boolean stating whether a line of the log branch may hold an object of
the kind.

Every canonical object holds the required members `kind` (the string
equal to its row's kind word) and `v` (the integer 1; frozen at 1 for
computed identity objects), and holds no member `id`. Every array member
not declared a sequence is a set with no duplicates, sorted in code
point order of each element's canonical form (`edges` and `paths` are
sets). A text fits the content-id form for a kind word k from
`object-kind` when, and only when, it fits the hash-id form with id
prefix `k:` and length 32. For any kind whose row allows edges, the
member `edges` is optional and is absent when empty (`"edges":[]` is not
a valid canonical form); each element of `edges` is a flat object
holding exactly `kind` (a string naming an edge kind allowed by the row)
and `to` (a string in content-id form whose kind word is among the
target kinds allowed by the row for that edge kind). For any kind whose
row lists "none" for edges, the member `edges` is absent.

In the following table, "any declared-item kind" means any of `design`,
`spec`, `schema`, `req`, `atom`, `term`, and `decision`; "any computed
identity kind" means any of `name`, `pin`, `ext`, `vector-set`, and
`vector-group`; "any object kind" means any of the twenty-five kinds in
the table; "citation edges" means `cites`, `satisfies`, `verifies`,
`refines`, and `supersedes`, each targeting any object kind; "subject
judgment kind" means the approval kind or the decline kind; and
"withdrawable kind" means any of the sixteen kinds other than `void`,
`task`, `plan`, any computed identity kind, and `vector-group-def`. In
the column of edges, "(1: …)" means exactly one edge of that kind,
"(0 or 1: …)" means at most one, and an edge kind with no count may
occur any number of times.

| kind | category | members (beyond `kind`, `v`, and optional `edges`) | `by` | allowed edges and target kinds | in `.sinter/` | on log branch |
|---|---|---|---|---|---|---|
| `design` | declared item | `name` (string, required), `label` (string, required), `text` (string, required) | no | `about` (1: `name`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `spec` | declared item | `name` (string, required), `label` (string, required), `text` (string, required) | no | `about` (1: `name`, matching member `name`); `items` (`schema`, `req`, `atom`, `term`); `revises` (any declared-item kind); citation edges | yes | yes |
| `schema` | declared item | `name` (string, required), `label` (string, required), `text` (string, required) | no | `about` (1: `name`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `req` | declared item | `name` (string, required), `label` (string, required), `text` (string, required) | no | `about` (1: `name`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `atom` | declared item | `name` (string, required), `label` (string, required), `text` (string, required) | no | `about` (1: `name`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `term` | declared item | `name` (string, required), `label` (string, optional), `text` (string, required) | no | `about` (1: `name`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `decision` | declared item | `name` (string, required), `label` (string, required), `text` (string, required) | no | `about` (1: `name`, matching member `name`); `revises` (any declared-item kind); citation edges | yes | yes |
| `task` | work item object | `nonce` (string of 32 lowercase hex digits, required) | no | none | yes | no |
| `plan` | work item object | `nonce` (string of 32 lowercase hex digits, required) | no | none | yes | no |
| `name` | computed identity | `name` (string, required) | no | none | yes | yes |
| `pin` | computed identity | `name` (string, required), `label` (string, required) | no | none | yes | yes |
| `ext` | computed identity | `external-ref` (string, required) | no | none | yes | yes |
| `vector-set` | computed identity | `owner` (string, required) | no | none | yes | yes |
| `vector-group` | computed identity | `owner` (string, required), `group` (string, required) | no | none | yes | yes |
| `vector-group-def` | group description | `owner` (string, required), `group` (string, required) | no | `about` (1: `vector-group`, matching `owner` and `group`); `cites` (any declared-item kind or `pin`) | no | no |
| `scope` | scope object | `paths` (set of path set member strings, required) | no | `about` (1: `task`); `promises-satisfies` (`name`, `req`); `promises-verifies` (`name`, `req`) | yes | no |
| `task-def` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `name` (string, required) | yes | `about` (1: `task`); `scoped-by` (1: `scope`); `revises` (`task-def`); `part-of` (0 or 1: `plan`); `waits-for` (`task`, `plan`); `tracks` (0 or 1: `ext`) | yes | no |
| `plan-def` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `name` (string, required) | yes | `about` (1: `plan`); `revises` (`plan-def`); `part-of` (0 or 1: `plan`); `waits-for` (`task`, `plan`); `carries-out` (`name`, `design`, `spec`, `req`) | yes | no |
| `approval` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional) | yes | `about` (1: any declared-item kind); `judges` (1: same content id as `about`); `revises` (subject judgment kind) | yes | no |
| `decline` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `reason` (string, optional) | yes | `about` (1: any declared-item kind); `judges` (1: same content id as `about`); `revises` (subject judgment kind) | yes | no |
| `done` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional) | yes | `about` (1: `task`); `judges` (1: `task-def`); `revises` (`done`, `abandoned`); `records` (`req`) | yes | no |
| `abandoned` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `reason` (string, required) | yes | `about` (1: `task` or `plan`); `judges` (1: `task-def` when `about` targets `task`, `plan-def` when `about` targets `plan`); `revises` (`done`, `abandoned`) | yes | no |
| `void` | record | `by` (string, required), `agent` (string, optional), `ts` (string, optional), `withdrawn-kind` (string, required), `reason` (string, required) | yes | `withdraws` (1: any withdrawable kind); copies of edges that an object of a withdrawable kind may hold, each with a target of a kind other than a computed identity kind (see the table rule on `void`) | yes | no |
| `delivered` | record | `by` (string, required), `seq` (integer >= 1, required), `ts` (string, optional), `commit` (string, required), `merge` (string, required), `head` (string, required), `hash` (string of 6 lowercase hex digits, required) | yes | `about` (1: `task`); `observes` (0 or 1: `task-def`); `kept-satisfies` (`req`); `kept-verifies` (`req`) | no | yes |
| `progress` | record | `by` (string, required), `seq` (integer >= 1, required), `ts` (string, optional), `head` (string, required) | yes | none | no | yes |

These table rules bind every row:

- A `design` holds no `items` edge and no other edge to its parts.
- An `items` edge on a `spec` carries no position or order.
- A `judges` edge names a description (a declared-item object, a
  `task-def`, or a `plan-def`), never a work item object or a computed
  identity object.
- A `withdraws` edge on a `void` names no `void`, no work item object
  (`task` or `plan`), no computed identity object (`name`, `pin`, `ext`,
  `vector-set`, `vector-group`), and no `vector-group-def`; the member
  `withdrawn-kind` of the `void` equals the kind word of the content id
  in its `withdraws` edge.
- A `void` has no thing and holds no edge to a computed identity object.
  Each edge of a `void` other than its one `withdraws` edge is a copy of
  an edge of the withdrawn object: for a withdrawn declared item, a copy
  of each of its `revises` edges; for each other withdrawn object, a
  copy of each of its edges whose target is not a computed identity
  object (including any `about` edge).

These four cross-object rules bind definitions and judgments:

- The `scope` object that a `task-def` names with `scoped-by` names,
  with its `about` edge, the task that the `task-def` names with
  `about`.
- The definition that a `done` or `abandoned` judgment names with
  `judges` names, with its `about` edge, the work item that the
  judgment names with `about`.
- Each `revises` edge of a definition names a definition of the same
  work item.
- Each `revises` edge of a judgment names a judgment whose `about` edge
  names the same object.

These four rules read two objects, so the acceptance rule of each of
those record kinds applies them; a record that breaks one is not
accepted.

An object meets its row of `object-kind` when, and only when, all of
these hold:

- its member `kind` names one of the twenty-five rows;
- its member `v` is the integer 1 and it holds no member `id`;
- every required member of that row is present with its declared type;
- `by` is present when, and only when, the row marks `by` as "yes";
- every array member not declared a sequence stands in code point order
  of its elements' canonical forms with no duplicates;
- `edges` is absent when empty, and otherwise holds only `{"kind","to"}`
  flat objects permitted by the row's allowed edges and target kinds;
- every agreement and cardinality rule of the row that reads only that
  object holds, and the parts of the five table rules of this term that
  read only that object hold.

### 3.29 Objects

@term object=v1
@cites {
    conformance#{object=v1, design=v1},
    data-forms#{line-object=v1, canonical-form=v1, json-value=v1},
    text#{code-point-order=v1},
    #{
        object-kind=v1, item=v1, finding-class=v1, person=v1, agent=v1,
        test=v1, site=v1, task=v1, plan=v1, vector-set=v1,
    },
}

Entities of each of the twenty-five kinds in `object-kind` are objects
in the sense of `conformance#object`. Findings, tests, sites, persons,
agents, and git commits are not objects (commit object names are scalar
values).

The canonical form of an object is a line object of Data forms with no
member `id` that conforms to its row of `object-kind` and meets all five
rules of regularity:

1. **One word for each kind:** the member `kind` and the kind word of
   the object's content id are the same kind word from `object-kind`.
2. **Every list is a set unless declared a sequence:** every array
   member not declared a sequence holds no duplicates and stands in code
   point order of each element's canonical form (`edges` and `paths` are
   sets).
3. **One thing edge:** every declared item, group description object,
   scope object, definition, judgment, and `delivered` observation names
   its thing with an `about` edge (and each judgment of a subject of
   approval holds both `about` and `judges` naming the same object).
4. **One schema table:** every object conforms to its row of
   `object-kind`.
5. **Authorship by a fixed rule:** every record carries `by`, and no
   declared item, work item object, computed identity object, group
   description object, scope object, or kept copy carries `by`.

Every object belongs to one of six categories: declared items (seven
kinds, also items), work item objects (`task` and `plan`, also items),
computed identity objects (`name`, `pin`, `ext`, `vector-set`, and
`vector-group`, of which the last three are also items), group
description objects (`vector-group-def`), scope objects (`scope`), and
records (nine kinds: seven statement kinds and two observation kinds).
Records, `name`, `pin`, `vector-group-def`, and `scope` are objects and
not items.

### 3.30 Content hashes

@term content-hash=v1
@cites {
    data-forms#{canonical-byte-sequence=v1, hash=v1},
    #{object=v1},
}

The content hash of an object is the hash (64 lowercase hexadecimal
digits from SHA-256) of the canonical byte sequence of its canonical
object, with no member `id` and no final line feed.

### 3.31 Content ids

@term content-id=v1
@cites {
    data-forms#{
        canonical-byte-sequence=v1, id-prefix=v1, hash-id=v1,
    },
    text#{text=v1, whole-number=v1},
    #{object=v1, object-kind=v1, content-hash=v1},
}

The content id of an object is the hash id of the canonical byte
sequence of its canonical object with the id prefix made of the object's
kind word from `object-kind` followed by `:` and with length 32: that
is, `<kind>:<first 32 lowercase hex digits of its content hash>`. The
kind word never enters the content hash.

### 3.32 Computed identity objects

@term computed-identity=v1
@cites {
    conformance#{design=v1},
    #{
        object=v1, object-kind=v1, content-id=v1, declared-item=v1,
        item-name=v1, external-item=v1, vector-set=v1,
        conformance-vector-group=v1, finding-class=v1, agent=v1,
        tree=v1,
    },
}

A computed identity object is an object of one of the five kinds `name`,
`pin`, `ext`, `vector-set`, and `vector-group`. Each computed identity
object holds only `kind`, `v` (frozen at 1), and its key, with no
`edges`, no `by`, and no `ts`. Any program computes a computed identity
object from its key alone, so two computed identity objects with the
same kind and key have equal canonical byte sequences and one content
id:

- A `name` object (`{"kind":"name","name":<name>,"v":1}`) stands for the
  identity of a declared item's name across revisions and across kinds.
  Unpinned citations (`=*`), declared-item `about` edges, and promises
  and `carries-out` edges that are not written by the content id of an
  exact object name a `name` object. Because a `name` object holds no
  item kind, a change of a cited declared item's kind changes neither
  the canonical object nor the content id of an item holding an unpinned
  edge to it. The presence of a `name` object never implies that a
  current description of that name exists in a tree.
- A `pin` object (`{"kind":"pin","label":<label>,"name":<name>,"v":1}`)
  stands for a pinned citation of a name and label in these three cases
  only: on a cycle of pins among the tree's own objects (`items` edges
  keep their exact targets); on a dangling pinned citation of an
  undeclared name; or on an ambiguous pin matching two or more replaced,
  unwithdrawn declared-item objects of that name and label in `.sinter/`
  of the tree, or (when the tree holds no current and no replaced,
  unwithdrawn declared-item object of that name and label) two or more
  unwithdrawn kept objects of that name and label on the log branch.
  Wherever one exact object exists (including one replaced, unwithdrawn
  declared-item object that `.sinter/` still holds) and the pin lies on
  no cycle of the tree's own objects, an exact pin names that exact
  object's content id. A pin to a revision that never merged, or to a
  kept object that a valid `void` object in `.sinter/` of that tree
  (carrying no `agent` and meeting an acceptance rule that a design
  gives for `void`) withdraws, names no `pin` object; its citation is a
  missing part. An ambiguous pin gives no exact target (so each result
  that needs its target lacks that target, and the ambiguity is a
  condition for a finding), and withdrawing matching copies with such
  `void` objects until one remains settles the ambiguity.
- An `ext` object (`{"external-ref":<ref>,"kind":"ext","v":1}`) stands
  for an external item; it carries no written kind word.
- A `vector-set` object (`{"kind":"vector-set","owner":<owner>,"v":1}`)
  stands for the vector set of the design or specification named by
  `owner`.
- A `vector-group` object
  (`{"group":<group>,"kind":"vector-group","owner":<owner>,"v":1}`)
  stands for one group of conformance vectors of the vector set of
  `owner`. The `cites` edges from the `form` members of its vector lines
  live on its group description object `vector-group-def` (holding
  `owner`, `group`, `about` naming the `vector-group` object, and those
  `cites` edges).

### 3.33 Revised content

@term revised-content=v1
@cites {
    identifiers#{
        label=v1, declaration=v1, declaration-line=v1, match=v1,
    },
    conformance#{design=v1},
    text#{text=v1},
    #{
        object=v1, content-hash=v1, content-id=v1, item=v1,
        declared-item=v1, containment=v1, term=v1,
        conformance-vector-group=v1, vector-set=v1, task=v1, plan=v1,
        test=v1, site=v1, external-item=v1, same-item=v1, tree=v1,
    },
}

In the text encoding, the label of a declared item is the text that
`label` matches in the match of its declaration by `declaration-line`,
when that match uses `label`. In the `.sinter/` encoding and in
canonical form, the label of a declared item is the value of its member
`label`, when present.

The revised content of a declared item is the content that its canonical
object represents (including its `v`, its `label` when present, its
status tags, its `text`, and its `edges`, which for an item of the kind
specification include `items` edges to the exact objects of its held
items, and for an item of the kind design exclude its held items). Two
revised contents of the same declared item (in two trees or in either
encoding) are the same revised content when, and only when, their
canonical objects have the same content hash (and thus the same content
id). Each declared item has a revised content. A group of conformance
vectors, a vector set, a task, a plan, a test, a site, and an external
item have no revised content.

### 3.34 Revisions of items

@term item-revision=v1
@cites {
    identifiers#{
        label=v1, declaration=v1, declaration-line=v1, match=v1,
    },
    text#{text=v1},
    #{revised-content=v1, declared-item=v1, tree=v1, item=v1, term=v1},
}

A revision of a declared item is a label that the item has, naming a
revised content (canonical object) of the item with that label. The
current revision of a declared item in a tree is the label of its
current declared-item object in that tree, whatever its revised content
is. In the text encoding, an example of such a label is `v2` in
`@req limit-amount=v2`. In the `.sinter/` encoding, the current
declared-item object of a name is the one declared item of that name in
`.sinter/` (term `declared-item`), when exactly one exists; two current
descriptions of one name in a tree (including one in text and one in
`.sinter/`) are duplicates, not revisions of each other. A term with no
label has a revised content and no revision. An item that has no revised
content has no revision.

### 3.35 Where lines and citations stand

@term edge-source=v1
@cites {
    identifiers#{citation=v1, inline-citation=v1},
    text#{line=v1},
    #{declared-item=v1, test=v1, site=v1, tree=v1, item=v1},
}

A line of a file of a tree, a citation, or an inline citation stands in
one item, or in none. When a line of a file of a tree, a citation, or an
inline citation is a part of a declared item, that line, citation, or
inline citation stands in the innermost declared item of which that
line, citation, or inline citation is a part. That innermost declared
item is the one declared item of which that line, citation, or inline
citation is a part and that has no other such declared item in the part
of the file of the tree that that declared item takes up. When a line of
a file of a tree, a citation, or an inline citation is a part of no
declared item and a comment on a test has that line, citation, or inline
citation, that line, citation, or inline citation stands in the
innermost test such that a comment on that test has that line, citation,
or inline citation. That innermost test is the one such test that has no
other such test in the code of that test. When a line of a file of a
tree, a citation, or an inline citation is a part of no declared item,
no comment on a test has that line, citation, or inline citation, and a
site has that line, citation, or inline citation, that line, citation,
or inline citation stands in that site. When a line of a file of a tree,
a citation, or an inline citation is a part of no declared item, no
comment on a test has that line, citation, or inline citation, and no
site has that line, citation, or inline citation, that line, citation,
or inline citation stands in no item.

### 3.36 Edges

@term edge=v1
@cites {
    identifiers#{
        citation=v1, citation-entry=v1, sinter-tag-word=v1,
        inline-citation=v1, external-namespaces=v1,
        give-line-results=v1, give-link-results=v1, line-result=v1,
        link-result=v1,
    },
    data-forms#{vector-line=v1, form-pin=v1},
    conformance#{
        design=v1, conforming-program=v1,
        give-results-over-canonical-objects=v1,
    },
    text#{result=v1},
    #{
        object=v1, object-kind=v1, content-id=v1, computed-identity=v1,
        item=v1, tree=v1, edge-source=v1, item-name=v1,
        external-item=v1, vector-set=v1, conformance-vector-group=v1,
        declared-item=v1, schema=v1, atom=v1, term=v1, containment=v1,
        finding-class=v1, task=v1, plan=v1, test=v1, site=v1, agent=v1,
    },
}

An edge is a relation of one kind of edge from its source to its target.
The kinds of edge are these twenty-one:

- the five citation kinds: `cites`, `satisfies`, `verifies`, `refines`,
  and `supersedes`;
- the sixteen structural, scope, and record kinds: `items`, `revises`,
  `withdraws`, `about`, `part-of`, `waits-for`, `promises-satisfies`,
  `promises-verifies`, `carries-out`, `tracks`, `judges`, `observes`,
  `records`, `kept-satisfies`, `kept-verifies`, and `scoped-by`.

On every object, every edge lives in its member `edges` (absent when
empty) as a flat object holding exactly `kind` (one of the twenty-one
edge kinds) and `to` (a content id). The source of each edge in an
object's `edges` is that object (for a `vector-group-def`, its `cites`
edges are the `cites` edges of its group of conformance vectors).

In the text encoding, a citation or an inline citation gives edges only
when a conforming program of the design Identifiers gives the result
"valid" for that citation or inline citation under the binding of
`external-namespaces`. Each citation entry of such a citation gives one
edge whose kind of edge is the citation word without `@`, whatever the
kinds of its source and target are; each such inline citation gives one
`cites` edge. The source of an edge that a citation or inline citation
gives is the item in which it stands (or none when it stands in no
item). When a citation or inline citation stands in a test or a site
(neither of which is an object), it gives a claim from code in the
results: the edge (`kind` and `to`) together with its location (file and
line) beside the edge, never inside the edge.

In canonical form, each target of a citation edge is a content id:

- an exact pin to a declared item names the exact object of that name
  and label when one exists and the pin lies on no cycle of the tree's
  own objects: the current declared-item object of that name and label
  in the tree; otherwise a declared-item object of that name and label
  that `.sinter/` of the tree still holds (replaced in the sense of
  `declared-item`, and not withdrawn) when exactly one exists;
  otherwise, when the tree holds no current and no replaced, unwithdrawn
  declared-item object of that name and label, the one unwithdrawn kept
  object of that name and label on the log branch. Otherwise, the pin
  names a `pin` computed identity object in these three cases only: the
  pin lies on a cycle of the tree's own objects (`items` edges keep
  their exact targets); the pin is a dangling pinned citation of an
  undeclared name; or the pin is ambiguous because it matches two or
  more replaced, unwithdrawn declared-item objects of that name and
  label in `.sinter/` of the tree, or (when the tree holds no current
  and no replaced, unwithdrawn declared-item object of that name and
  label) two or more unwithdrawn kept objects of that name and label on
  the log branch. An ambiguous pin gives no exact target (so each result
  that needs its target lacks that target, and the ambiguity is a
  condition for a finding), and withdrawing matching copies with valid
  `void` objects in `.sinter/` of that tree (each carrying no `agent`
  and meeting an acceptance rule that a design gives for `void`) until
  one remains settles the ambiguity. In every other case, such as a pin
  to a revision that never merged or to a kept object that such a `void`
  object withdraws, the pin names no object, and its citation is a
  missing part;
- an unpinned citation (`=*`) names the target's `name` computed
  identity object (and a citation written by the content id `name:…`
  means what `=*` of that name means);
- an external target names its `ext` computed identity object (dropping
  any written kind word), and a vector selection names its `vector-set`
  or `vector-group` computed identity object; a citation written by the
  content id of an `ext`, `vector-set`, or `vector-group` object gives
  the same canonical edge and the same results as citing its key;
- a citation written by the content id of a non-identity object names
  that content id directly and resolves first in the tree (including a
  replaced declared-item object that `.sinter/` still holds and that is
  not withdrawn) and then against unwithdrawn kept objects on the log
  branch.

Each vector line of a vector set in a tree also gives one `cites` edge
from the group of conformance vectors of that vector line (held on its
`vector-group-def`). An item x is the cited item of that edge in that
tree when each of these three conditions holds:

- the vector set is of an item of the kind specification S that belongs
  to an item of the kind design D in that tree, or the vector set is of
  an item of the kind design D;
- the name n, which is the name of D, `#`, and the schema part name of
  the form of that vector line, names x in that tree, as a citation
  entry with the name n names an item in that tree;
- the vector set is of S and S holds x in that tree, or the vector set
  is of D and D holds x directly in that tree.

In every other case, that edge has no cited item in that tree.

For the five citation kinds of edge, a kind of edge is for some kinds of
item or object as its source and as its cited item (target), which can
depend on whether a declared item, a test, a site, or a vector line
gives the edge. An edge of a citation kind says what its kind of edge
says when, and only when, its source and its cited item are of those
kinds. Another edge of that kind says nothing.

The sixteen structural, scope, and record kinds of edge have these
meanings:

- `items`: from a `spec` to each declared item (`schema`, `req`, `atom`,
  `term`) that it holds, by exact object, with no position or order.
- `revises`: replacement within one thing — from a declared item in
  `.sinter/` to another revision of the same name, from a `task-def`
  or `plan-def` to another definition of the same work item, or from
  a judgment to another judgment of the same thing.
- `withdraws`: from a `void` to the one withdrawable object that the
  void withdraws.
- `about`: from a declared item, a `vector-group-def`, a `scope`, a
  definition, a judgment, or a `delivered` observation to the thing that
  it is about.
- `part-of`: from a `task-def` or `plan-def` to the `plan` that the work
  item belongs to.
- `waits-for`: from a `task-def` or `plan-def` to a work item (`task` or
  `plan`) that it waits for.
- `promises-satisfies` and `promises-verifies`: from a `scope` to a
  promised requirement (`name` or `req`).
- `carries-out`: from a `plan-def` to an item (`name`, `design`, `spec`,
  or `req`) that the plan carries out.
- `tracks`: from a `task-def` to an `ext` object (at most one external
  item).
- `judges`: from a judgment of a subject of approval to the judged
  declared-item object (matching `about`), or from a `done` or
  `abandoned` judgment to the judged `task-def` or `plan-def`; never to
  an identity object.
- `observes`: from a `delivered` observation to the `task-def` that was
  current at the landing commit (absent when the task had no current
  definition at that commit).
- `records`: from a `done` judgment to each promised `req` object that
  the tree declares once.
- `kept-satisfies` and `kept-verifies`: from a `delivered` observation
  to the `req` object at which the job found a promise kept (present
  only for kept promises).
- `scoped-by`: from a `task-def` to its `scope` object.

### 3.37 Pinned edges

@term pinned-edge=v1
@cites {
    identifiers#{
        revision=v1, label=v1, citation-entry=v1, inline-citation=v1,
        citation-line=v1, inline-destination=v1, destination=v1,
        match=v1,
    },
    data-forms#{vector-line=v1, form-pin=v1},
    text#{text=v1},
    #{
        edge=v1, computed-identity=v1, content-id=v1, declared-item=v1,
        schema=v1, atom=v1, term=v1, item-revision=v1,
        revised-content=v1,
    },
}

In the text encoding, when the match of a citation entry uses
`revision`, the revision of that citation entry is the text that
`revision` matches in that match; otherwise that citation entry has no
revision. The revision of an inline citation is the text that `revision`
matches in the match of the destination of that inline citation by
`inline-destination`; otherwise that inline citation has no revision.

Over canonical objects, a citation edge is pinned when, and only when,
its target content id names a declared-item object (an exact object of
kind `design`, `spec`, `schema`, `req`, `atom`, `term`, or `decision`)
or a `pin` object. (In the text encoding, a citation entry or inline
citation whose revision is a label, a citation by the content id of a
declared-item object, and an edge that a vector line gives all yield
pinned edges.) A citation edge targeting a `name` object (from `=*` or
from citing `name:…`) is not pinned and is a relation to its cited item
at each revision of that item. A pinned edge is a relation to the
specific revised content (exact object) that it names, or, for a `pin`
object, to the revised content named by that `pin` object's `name` and
`label`.

### 3.38 Edges of the kind `cites`

@term cites-edge=v1
@cites {
    identifiers#{citation-entry=v1, inline-citation=v1},
    data-forms#{vector-line=v1},
    #{
        object=v1, edge=v1, declared-item=v1, schema=v1, test=v1,
        site=v1, external-item=v1, conformance-vector-group=v1,
        vector-set=v1, computed-identity=v1,
    },
}

A `cites` edge says that its source refers to its cited item (target)
and rests on what the target says. For an edge from a declared item (in
either encoding), a test, or a site, the kind of edge `cites` is for a
declared item, a test, or a site as its source, and for a declared item
(pinned by exact object or `pin`, or unpinned by `name`), an external
item (`ext`), a group of conformance vectors (`vector-group`), a vector
set (`vector-set`), or any other object named by its content id as its
target. For an edge that a vector line gives (held on
`vector-group-def`), the kind of edge `cites` is for a group of
conformance vectors as its source, and for a schema as its cited item.

### 3.39 Edges of the kind `satisfies`

@term satisfies-edge=v1
@cites #{edge=v1, declared-item=v1, schema=v1, test=v1, site=v1}

A `satisfies` edge says that its source does what its cited item says.
The kind of edge `satisfies` is for a declared item (in either
encoding), a test, or a site as its source, and for an item of the kind
requirement or a schema as its cited item.

### 3.40 Edges of the kind `verifies`

@term verifies-edge=v1
@cites {
    conformance#{
        input=v1, conforming-program=v1, design=v1, specification=v1,
    },
    #{
        edge=v1, declared-item=v1, schema=v1, test=v1,
        conformance-vector=v1, conformance-vector-group=v1,
        vector-set=v1,
    },
}

A `verifies` edge says that its source checks code. The kind of edge
`verifies` is for a test as its source, and for an item of the kind
requirement, a schema, a group of conformance vectors, or a vector set
as its cited item. When the cited item of a `verifies` edge is an item
of the kind requirement, the edge says that the code that the source
runs meets that item. When its cited item is a group of conformance
vectors or a vector set, the edge says, of each conformance vector in
it, that the code that the source runs gives what that conformance
vector says that a conforming program of its specification or its design
gives, which is nothing when that conformance vector says no vector.

### 3.41 Edges of the kind `refines`

@term refines-edge=v1
@cites #{
    edge=v1, item=v1, declared-item=v1, schema=v1, atom=v1, term=v1,
    decision-record=v1,
}

A `refines` edge says that its source says all or part of its cited item
in more detail. The kind of edge `refines` is for a declared item (in
either encoding) as its source, and for a declared item as its cited
item, when the kind of item of its source and the kind of item of its
cited item are in the same one of these three groups:

- design, specification, and requirement;
- schema, atom, and term;
- decision record.

### 3.42 Edges of the kind `supersedes`

@term supersedes-edge=v1
@cites #{
    item=v1, edge=v1, declared-item=v1, schema=v1, atom=v1, term=v1,
}

A `supersedes` edge says that its source is to replace a different
declared item (its cited item). The kind of edge `supersedes` is for a
declared item (in either encoding) as its source, and for a declared
item of the same kind of item as its cited item. Only a `supersedes`
edge says that one declared item is to replace another declared item;
replacement within one thing uses `revises` and never `supersedes`.

### 3.43 Suspect

@atom suspect-edge=v1
@cites #{
    pinned-edge=v1, edge=v1, computed-identity=v1, declared-item=v1,
    item-revision=v1, revised-content=v1, tree=v1,
}

An edge is suspect in a tree when, and only when, each of these three
conditions holds:

- the edge is pinned;
- the declared item that the edge names exists in that tree;
- either the edge names an exact declared-item object other than the
  current object of that declared item in that tree, or the edge names a
  `pin` object whose label differs from the current revision of that
  declared item in that tree (or that declared item has no current
  revision in that tree).

### 3.44 Promises

@term promise=v1
@cites {
    identifiers#{citation=v1},
    files#{path=v1, path-set-membership=v1},
    data-forms#{group-form-list=v1},
    conformance#{requirement=v1, design=v1},
    #{
        task=v1, edge=v1, declared-item=v1, item-name=v1, test=v1,
        tree=v1, test-evidence=v1, satisfies-edge=v1, verifies-edge=v1,
        suspect-edge=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1,
        computed-identity=v1,
    },
}

A promise of a task is a pair of a kind of edge, `satisfies` or
`verifies`, and the name of an item of the kind requirement (held on a
scope object of the task as a `promises-satisfies` or
`promises-verifies` edge naming the requirement's `name` object or an
exact `req` object). The promise links the task to the item of the kind
requirement that has that name: the task promises an edge of that kind
of edge to that item, from a citation in a text file of a tree whose
valid path is in the set of the paths of the task. An edge of an item
stored in `.sinter/` keeps no promise. A `verifies` edge from a citation
in such a text file to a group of conformance vectors or a vector set is
such an edge too, when there is a conformance vector in the cited item
of that edge that meets both of these conditions: that conformance
vector says a vector, and the requirement that that item of the kind
requirement declares is among the requirements of the group of that
conformance vector (the items of the kind requirement that the
specification or the design of the group's schema declares and that the
schema cites).

The promise is kept in a tree when, and only when, that tree has such an
edge from a citation in a text file whose valid path is in the set of
the paths of the task, and the edge says what its kind of edge says, and
the edge is not suspect in that tree, and, for a `verifies` promise,
test evidence of an execution of test runners on the code of that tree
shows that the test that is the source of that edge passed. Test
evidence shows that a test of which no other test is a part passed when,
and only when, that test evidence has a test result that names that test
and says that it passed, and none that says that it failed. Test
evidence shows that a test of which one or more other tests are a part
passed when, and only when, the rule that a design names for such a test
gives that that test passed, from the test results that name that test
or one of those other tests.

### 3.45 Scope objects

@term scope-object=v1
@cites {
    files#{path-set=v1},
    #{
        object=v1, object-kind=v1, content-hash=v1, task=v1,
        promise=v1, edge=v1,
    },
}

A scope object is a non-record object of the kind `scope` carrying no
`by` and no `ts` that holds the `paths` (as a set of path set members),
the promise edges (`promises-satisfies` and `promises-verifies`), and an
`about` edge naming one `task` object. Its content hash identifies the
scope of that task. Two task definitions of one task with equal paths
and promises share one scope object, and two distinct tasks have
distinct scope objects because each scope object names its own task with
`about`.

### 3.46 Definitions of work items

@term work-item-definition=v1
@cites #{
    work-item=v1, task=v1, plan=v1, scope-object=v1, promise=v1,
    wait=v1, carried-out-item=v1, external-item=v1, declared-item=v1,
    edge=v1,
}

A definition of a task is a display name, a scope object named with
`scoped-by` (giving the paths and the promises of the task in that
definition), at most one external item (`tracks`), at most one plan
(`part-of`), and waits (`waits-for`). The paths of a task in a
definition are the `paths` of the scope object that the definition names
with `scoped-by`, and the promises of a task in a definition are the
promises that the `promises-satisfies` and `promises-verifies` edges of
that scope object give. A definition of a plan is a display name, at
most one plan (`part-of`), waits (`waits-for`), and the items of the
kind requirement, specification, and design that the plan carries out
(`carries-out`). Each alteration of a definition gives a new definition.
The plan of a work item in a definition is the plan, or none, that the
definition names with `part-of`. The waits of a work item in a
definition are the waits from the work item that the definition names
with `waits-for`. The work item id of a work item is not part of a
definition.

### 3.47 Delivery lines

@term delivery-line=v1
@cites {
    text#{line=v1, hex-digit=v1},
    #{
        task=v1, work-item=v1, scope-object=v1, content-hash=v1,
        content-id=v1,
    },
}

A delivery line is a line of the message of a commit that says that the
commit completes the work of one task. The delivery line names the task
by the work item id of the task (the content id of its `task` object,
`task:<32 hex>`) and names a scope of the task by the first six
lowercase hexadecimal digits of the content hash of a `scope` object of
the task, with no kind word on that six-digit prefix.

### 3.48 Task lines

@term task-line=v1
@cites {text#{line=v1}, #{task=v1, work-item=v1}}

A task line is a line of the message of a commit that names one task by
its work item id, and that says that the commit does part of the work of
the task without finishing it.

### 3.49 Records

@term ledger-entry=v1
@cites #{
    object=v1, object-kind=v1, content-id=v1, edge=v1, person=v1,
    agent=v1, job=v1, task=v1, plan=v1,
}

A record (also called a ledger entry) is an object of one of the nine
record kinds in `object-kind`: the seven statement kinds (two definition
kinds, four judgment kinds, and `void`) and the two observation kinds
(`delivered` and `progress`). Every record has a content id, holds its
links in `edges`, and carries the member `by`, which records its writer
(a person, the person for whom an agent acts, or the job). A statement
may carry `agent` (when an agent wrote it) and `ts` (a time), and
carries no `seq`. An observation carries `seq` (a whole number of 1 or
more) and may carry `ts`.

These actors write the kinds of record:

- a person or an agent writes definitions (`task-def` and `plan-def`),
  along with non-record objects (work item objects, scope objects,
  computed identity objects, and declared items), in `.sinter/`;
- only a person writes judgments and voids in `.sinter/`;
- only the job writes observations (`delivered` and `progress`), along
  with kept copies of declared items and their referenced computed
  identity objects, on the log branch.

### 3.50 Statements

@term statement=v1
@cites #{ledger-entry=v1, object-kind=v1, person=v1, agent=v1, tree=v1}

A statement is a record of one of the seven statement kinds in
`object-kind` (a definition, a judgment, or a void) that a person or an
agent writes as a fixed object file in `.sinter/` of a tree. No
statement uses the text encoding, and no statement carries `seq`.

### 3.51 Voids

@term void-statement=v1
@cites {
    conformance#{design=v1},
    #{
        statement=v1, object-kind=v1, edge=v1, content-id=v1,
        computed-identity=v1, task=v1, plan=v1, vector-set=v1,
        person=v1, agent=v1, tree=v1,
    },
}

A void (also called a void statement) is a statement of the kind `void`
with which a person withdraws one withdrawable object: a statement in
`.sinter/`, a `scope` object, a declared item in `.sinter/`, an
observation on the log branch, or a kept declared item on the log
branch. No void withdraws a `void`, a work item object (`task` or
`plan`), a computed identity object (`name`, `pin`, `ext`, `vector-set`,
or `vector-group`), or a `vector-group-def`. A void counts in a tree (is
a counting void in that tree) when, and only when, a design gives an
acceptance rule for `void` that holds for that void in that tree and the
void does not carry the member `agent`. A void that does not count
withdraws nothing.

A counting void takes the place of the object that its `withdraws` edge
names: the withdrawn object decides nothing (and a withdrawn kept
declared item counts as absent for pin and content-id resolution while
remaining on the log branch), objects that the withdrawn object replaced
stay replaced through the void's copied `revises` edges, and an edge to
a withdrawn object whose file is deleted leads to a counting void whose
`withdraws` edge names that content id. For a withdrawn declared item, a
void copies only its `revises` edges; for each other withdrawn object, a
void copies no edge targeting a computed identity object. A void has no
thing, although its copies can include an `about` edge.

### 3.52 Definition statements

@term definition-entry=v1
@cites #{
    statement=v1, work-item=v1, task=v1, plan=v1, scope-object=v1,
    work-item-definition=v1, edge=v1,
}

A definition statement (also called a definition entry) is a statement
of the kind `task-def` or `plan-def`. A definition statement names one
work item (`task` or `plan`) with an `about` edge, names zero or more
definitions of that work item that it replaces with `revises` edges, and
records one whole definition of its work item. A `task-def` records a
definition of a task and names its `scope` object with a `scoped-by`
edge. A `plan-def` records a definition of a plan. A definition
statement records no judgment.

### 3.53 Subjects of approval

@term subject-of-approval=v1
@cites #{
    person=v1, declared-item=v1, schema=v1, atom=v1, term=v1,
    decision-record=v1, containment=v1, revised-content=v1,
    same-item=v1, tree=v1,
}

A subject of approval is a unit that a person approves, or that the
merge approves, as a whole. Each subject of approval is one of these: an
item of the kind design, without the declared items that it holds; an
item of the kind specification, with the schemas, the items of the kind
requirement, the atoms, and the terms that it holds; a schema that an
item of the kind design holds directly; an item of the kind requirement
that an item of the kind design holds directly; an atom that an item of
the kind design holds directly; a term that an item of the kind design
holds directly; or a decision record. These seven are the kinds of
subject of approval. The kind of a subject of approval is the one of
these seven that the subject of approval is. For a subject of approval
of the first kind, the declared item of the subject of approval is the
item of the kind design. For a subject of approval of any other kind,
the declared item of the subject of approval is the item of the kind
specification, the schema, the item of the kind requirement, the atom,
the term, or the decision record that the subject of approval is. When a
declared item is the declared item of a subject of approval, the subject
of approval of that declared item is that subject of approval. The
subject of approval of a schema, of an item of the kind requirement, of
an atom, or of a term that an item of the kind specification holds is
the subject of approval of that item of the kind specification. Each
other declared item has no subject of approval. The revised content of a
subject of approval is the revised content of its declared item. A
subject of approval of one tree and a subject of approval of another
tree are the same subject of approval when, and only when, their
declared items are the same item.

### 3.54 Judgments

@term judgment=v1
@cites #{
    statement=v1, person=v1, subject-of-approval=v1,
    revised-content=v1, task=v1, plan=v1, work-item-definition=v1,
    promise=v1, declared-item=v1, item-name=v1, tree=v1, edge=v1,
    content-id=v1,
}

A judgment is a statement that records a decision of a person. Every
judgment names its thing with `about`, names the exact judged
description (never an identity object) with `judges`, and names zero or
more judgments of its thing that it replaces with `revises`. A judgment
is one of these four kinds of statement:

- An `approval` judgment records that a person approved one revised
  content (exact declared-item object, named by both `about` and
  `judges`) of one subject of approval.
- A `decline` judgment records that a person declined one revised
  content (exact declared-item object, named by both `about` and
  `judges`) of one subject of approval, with an optional `reason`.
- A `done` judgment records that a person judged the work of one task
  (`about` naming `task`) finished under one task definition (`judges`
  naming `task-def`) in a tree. For each promised requirement of that
  definition, when that tree declares exactly one item of the kind
  requirement with that name, that `done` judgment holds a `records`
  edge naming the content id of that requirement's object in that tree;
  when that tree declares no such requirement, or declares two or more
  such requirements, that `done` judgment holds no `records` edge for
  that name.
- An `abandoned` judgment records that a person ended one task or one
  plan (`about` naming `task` or `plan`) under one definition (`judges`
  naming `task-def` or `plan-def`), with a `reason`.

### 3.55 Records of the job

@term job-record=v1
@cites {
    conformance#{design=v1},
    #{
        ledger-entry=v1, job=v1, delivery-line=v1, promise=v1, task=v1,
        scope-object=v1, work-item-definition=v1, declared-item=v1,
        item-name=v1, tree=v1, edge=v1, content-hash=v1, content-id=v1,
        void-statement=v1,
    },
}

A record of the job (also called an observation) is a record of the kind
`delivered` or `progress` on the log branch.

A `delivered` observation records what the job observed about one
delivery line of one task (`about` naming `task`), holding the
six-digit scope hash prefix of that delivery line in its member `hash`
and the commit object names (`commit`, `merge`, `head`). When the task
had a current definition D at the landing commit, the `delivered`
observation holds an `observes` edge naming D, and for each promise of D
that the job found kept in the tree of the head of the run (with a
unique requirement object in that tree), the `delivered` observation
holds a `kept-satisfies` or `kept-verifies` edge naming the content id
of that requirement object; a promise that was not kept, or whose
requirement was absent or duplicated in that tree, gets no edge. When
the task had no current definition at the landing commit, the
`delivered` observation holds no `observes` edge and no `kept-satisfies`
or `kept-verifies` edge.

A `delivered` observation completes a task definition D in a tree (is a
completing `delivered` observation of D in that tree) when, and only
when, all four of these conditions hold:

- the `delivered` observation decides a state in that tree;
- the `delivered` observation holds an `observes` edge naming D;
- the member `hash` of the `delivered` observation is the first six
  lowercase hexadecimal digits of the content hash of the `scope` object
  that D names with `scoped-by`;
- for each promise of D, the `delivered` observation holds a matching
  `kept-satisfies` or `kept-verifies` edge to a requirement object whose
  name is the name of that promise.

A `progress` observation holds the commit object name `head` of the last
commit on the default branch that a run of the job covered, and holds no
edges.

An observation decides a state in a tree when, and only when, a design
gives an acceptance rule for its kind of observation, that rule holds
for the observation, no counting void in that tree withdraws it, and,
for a `delivered` observation with an `observes` edge, that tree holds
the definition that the edge names or a counting void in that tree names
that definition with its `withdraws` edge.

### 3.56 Parameters

@term parameter=v1
@cites {
    conformance#{design=v1},
    identifiers#{external-namespaces=v1, part-name=v1},
    #{schema=v1},
}

A parameter is a word, such as `external-namespaces`, whose value a
design leaves open. A binding of a parameter is a value that
configuration gives for the parameter. When a design declares a schema
whose part name is the name of a parameter, a binding of that parameter
is valid when, and only when, that binding meets that schema. A binding
of the parameter `external-namespaces` is a binding as Identifiers
defines it.

### 3.57 Log branches

@term log-branch=v1
@cites #{
    object=v1, object-kind=v1, job=v1, job-record=v1,
    declared-item=v1, computed-identity=v1, content-id=v1,
    parameter=v1,
}

The log branch of a repository is a dedicated branch, named by a binding
of a parameter that a design names, that holds only the observations
(`delivered` and `progress`) and the kept objects that the job writes. A
kept object is a copy of a merged declared item, or a copy of a computed
identity object named by an edge of a kept declared item (other than the
kept declared item's own `name` identity object), stored on the log
branch with no `seq` and no `by` and deduplicated by content id. Every
line of the log branch holds an object of one of the fourteen kinds that
`object-kind` marks as allowed on the log branch. Only the job writes
the log branch, and the log branch only grows: each commit adds lines
and removes or changes none.

### 3.58 The ledger

@term ledger=v1
@cites #{
    object=v1, statement=v1, job-record=v1, log-branch=v1,
    declared-item=v1, computed-identity=v1, content-id=v1, edge=v1,
    tree=v1,
}

The ledger of a repository consists of two parts:

- the statements stored as fixed object files in `.sinter/` of a tree,
  which form a Merkle graph with the other objects of `.sinter/` because
  every edge names its target by content id;
- the observations and kept objects on the log branch.

No state of an item, an edge, a wait, or a subject of approval depends
on the order of records (`seq` on observations serves only the job's
bookkeeping and the growth check of the log branch).

### 3.59 Encodings

@term encoding=v1
@cites {
    conformance#{encoding=v1, own-store=v1},
    #{
        object=v1, object-kind=v1, content-hash=v1, declared-item=v1,
        vector-set=v1, computed-identity=v1, tree=v1, log-branch=v1,
        ledger=v1,
    },
}

Sinter defines two encodings at rest in a tree in the sense of
`conformance#encoding`:

- **the text encoding:** text in files of a tree, holding declared items
  (as tag blocks and prose), test-vector sets (giving `vector-set`,
  `vector-group`, and `vector-group-def` objects), and keys from which
  computed identity objects derive. No record uses the text encoding.
- **the `.sinter/` encoding:** fixed object files under `.sinter/`
  (outside `.sinter/local/`), each holding the canonical byte sequence
  of one object with no `id` and no final line feed, for any of the
  twenty-two kinds that `object-kind` marks as allowed in `.sinter/`.

A declared item may use either encoding and has the same canonical object
and content hash in either encoding. Moving a declared item between text
and `.sinter/` adds no `revises` edge. Objects can also come from a
valid program's own store (`conformance#own-store`).

### 3.60 Things and latest statements

@term thing=v1
@cites {
    conformance#{design=v1},
    #{
        object-kind=v1, computed-identity=v1, scope-object=v1,
        statement=v1, definition-entry=v1, judgment=v1,
        void-statement=v1, job-record=v1, declared-item=v1,
        work-item=v1, subject-of-approval=v1, edge=v1, parameter=v1,
        person=v1, agent=v1, tree=v1,
    },
}

The thing of a declared item, a `vector-group-def`, a `scope` object, a
definition statement, a judgment, or a `delivered` observation is the
object that its own `about` edge names: a work item for a definition
statement, a `done` judgment, an `abandoned` judgment, a `scope` object,
and a `delivered` observation; the judged declared-item object for an
approval judgment and a decline judgment; a `name` object for a declared
item; and a `vector-group` object for a `vector-group-def`. A `void`, a
`progress` observation, a work item object, and a computed identity
object have no thing; a `void` has none even when it holds a copy of an
`about` edge of the object that it withdraws. The statements of a thing
fall into separate groups: for a work item, one group holds its
definition statements (`task-def` or `plan-def`), and a separate group
holds its work-item judgments (`done` and `abandoned`); for a
declared-item object, one group holds its approval and decline
judgments. A `delivered` observation is not a statement of its thing.

A statement is accepted in a tree when, and only when, a design gives an
acceptance rule for its kind of statement and that rule holds for that
statement in that tree. A statement counts in a tree when, and only
when, all four of these conditions hold:

1. the statement is accepted in that tree;
2. no counting void in that tree withdraws the statement (names the
   statement's content id with its `withdraws` edge);
3. when the statement is a judgment or a void, the statement does not
   carry the member `agent`;
4. when the statement is a judgment, and a binding of a parameter that a
   design names gives the persons whose judgments count, the statement's
   `by` value is equal to a text in that list (an empty list means that
   no person's judgments count; when no list is bound, every person's
   judgments count).

A statement that does not count takes no part in the graph of `revises`
and `judges` edges of its thing: it replaces nothing, is never a latest
statement, and an edge naming it replaces nothing. Because no void
withdraws a void, whether a void counts depends only on conditions 1
and 3; a void that does not count withdraws nothing.

Within one group of statements of a thing, a counting statement replaces
each counting statement of that group that it names with a `revises`
edge, and each statement that a withdrawn statement replaced stays
replaced through the copied `revises` edges of the counting void that
withdrew it. A latest statement of a group is a counting statement of
that group that no other counting statement of that group replaces
(directly or through a counting void's copied edges). When a counting
void withdraws the only latest statement of a group, that group has no
latest statement.

### 3.61 Agreement and conflicts

@term conflict=v1
@cites #{
    thing=v1, statement=v1, definition-entry=v1, judgment=v1,
    void-statement=v1, job-record=v1, work-item-definition=v1,
    edge=v1, tree=v1,
}

Two or more latest statements of one group of statements of a thing
agree when they give their thing the same state:

- two approval judgments of the same declared-item object agree;
- two decline judgments of the same declared-item object agree;
- two definition statements of one work item agree when they record the
  same definition (equal display name, equal scope object or carried-out
  items, equal plan, equal waits, and equal external item), whoever
  wrote them;
- two `done` judgments that judge the same task definition agree;
- two `abandoned` judgments that judge the same work item definition
  agree.

Latest `done` and `abandoned` judgments of one work item that judge
different definitions neither agree nor conflict; each decides only for
the definition that it judges.

A conflict exists in either of these two cases:

- two or more latest statements of one group of statements of a thing
  neither agree nor fall under the rule for judgments of different
  definitions (an approval judgment and a decline judgment of the same
  declared-item object; two latest definition statements of one work
  item that record different definitions; or a `done` judgment and an
  `abandoned` judgment that are both latest for the same task
  definition);
- a completing `delivered` observation of a task definition D that
  decides a state in that tree and any latest counting `abandoned`
  judgment that judges D both exist (whether or not a `done` judgment
  also judges D).

A conflict decides nothing: no latest statement that takes part in a
conflict decides a state. One new counting statement of the group whose
`revises` edges name every latest statement that takes part in the
conflict settles a conflict of statements. For a conflict between a
completing `delivered` observation of D and one or more latest
`abandoned` judgments of D, a `done` judgment replacing every latest
`abandoned` judgment with `revises`, a counting void of every latest
`abandoned` judgment, or a counting void of the `delivered` observation
settles the conflict.

### 3.62 States

@term state=v1
@cites #{
    item=v1, edge=v1, wait=v1, subject-of-approval=v1, tree=v1,
    ledger=v1,
}

A state is a named condition of an item, an edge, a wait, or a subject
of approval in a tree.

### 3.63 The states of work items

@atom work-item-state=v1
@cites {
    conformance#{design=v1},
    #{
        work-item=v1, task=v1, plan=v1, work-item-definition=v1,
        definition-entry=v1, judgment=v1, job-record=v1,
        void-statement=v1, thing=v1, conflict=v1, state=v1, tree=v1,
        ledger=v1, edge=v1,
    },
}

In a tree, the counting statements in `.sinter/` and the observations on
the log branch that decide a state in that tree give the work items that
exist, the current definition of each work item, the parts of each plan,
and the state of each task and each plan:

1. A work item exists in a tree when, and only when, its `task` or
   `plan` object is in `.sinter/` of that tree. The current definition
   of a work item is the definition recorded by its latest counting
   definition statements when at least one latest counting definition
   statement exists and all latest counting definition statements agree.
   When a work item has no latest counting definition statement, or its
   latest counting definition statements conflict, the work item exists
   and has no current definition (so each result that needs its current
   definition lacks that definition).
2. A work item is a part of a plan when, and only when, the current
   definition of the work item names that plan with `part-of` and the
   work item is not abandoned. An unfinished work item stays a part of
   its plan when the plan is abandoned. A part of a plan is a task or a
   plan. A work item is under a plan when, and only when, it is a part
   of the plan, or there is a finite chain of one or more work items
   from it to the plan in which each work item is a part of the next.
3. Each task with a current definition D is in one of these four states
   (judgments whose `judges` edge names a replaced definition other than
   D do not decide the state of the task under D):
   - **abandoned**, when at least one latest counting judgment of the
     task judges D, every latest counting judgment of the task that
     judges D is an `abandoned` judgment, and no completing `delivered`
     observation that decides a state in that tree observes D;
   - **done**, when either at least one latest counting judgment of the
     task judges D and every latest counting judgment of the task that
     judges D is a `done` judgment, or a completing `delivered`
     observation that decides a state in that tree observes D and no
     latest counting judgment of the task that judges D is an
     `abandoned` judgment;
   - **delivered**, when the task is neither abandoned nor done, and a
     `delivered` observation of the task that decides a state in that
     tree exists (including when a completing `delivered` observation
     that decides a state in that tree observes D and a latest counting
     `abandoned` judgment judges D, or when a `done` judgment and an
     `abandoned` judgment conflict and a `delivered` observation of the
     task that decides a state in that tree exists);
   - **open**, when it is none of abandoned, done, and delivered.
4. A task is unfinished when, and only when, it is open or delivered.
5. Each plan with a current definition D is in one of these three states
   (judgments whose `judges` edge names a replaced definition other than
   D do not decide the state of the plan under D):
   - **abandoned**, when at least one latest counting judgment of the
     plan judges D and every latest counting judgment of the plan that
     judges D is an `abandoned` judgment;
   - **done**, when it is not abandoned, it has at least one part, every
     part of it is done, and neither the plan nor any plan under it lies
     on a cycle of plans (a finite sequence of one or more plans in
     which each is a part of the next and the last is a part of the
     first);
   - **open**, when it is neither abandoned nor done.

### 3.64 Deprecated

@atom deprecated-item=v1
@cites {
    identifiers#{
        status-tag=v1, external-namespaces=v1, give-line-results=v1,
        line-result=v1,
    },
    conformance#{design=v1, conforming-program=v1},
    text#{result=v1},
    #{
        declared-item=v1, schema=v1, atom=v1, term=v1,
        decision-record=v1, tree=v1, edge-source=v1, encoding=v1,
    },
}

An item of the kind design, specification, or requirement, a schema, an
atom, a term, or a decision record is deprecated in a tree when, and
only when, its canonical object holds the deprecation status tag (in the
text encoding, when a `@deprecated` status tag stands in that item in
that tree and a conforming program of the design Identifiers gives the
result "valid" for that status tag under the binding of
`external-namespaces`). That status tag says that the item no longer
applies and that nothing replaces the item.

### 3.65 Approved and declined

@term approval-state=v1
@cites {
    conformance#{design=v1},
    #{
        subject-of-approval=v1, person=v1, revised-content=v1,
        containment=v1, schema=v1, atom=v1, term=v1, declared-item=v1,
        default-branch=v1, tree=v1, ledger=v1, state=v1, judgment=v1,
        thing=v1, conflict=v1, parameter=v1, edge=v1,
    },
}

In a repository, a binding of a parameter that a design names gives the
kinds of subject of approval that need approval by a person. Each other
kind of subject of approval needs no approval by a person. Whether a
judgment counts follows `thing` (including the persons that a binding of
a parameter that a design names gives, when bound). In a tree, these are
the states approved, declined, and neither:

- For a subject of approval of a kind that needs approval by a person,
  consider the latest counting judgments whose `about` and `judges`
  edges name the current declared-item object (revised content) of that
  subject of approval in that tree:
  - the subject of approval is **approved** when at least one such
    latest counting judgment exists and every such latest counting
    judgment is an `approval` judgment;
  - the subject of approval is **declined** when at least one such
    latest counting judgment exists and every such latest counting
    judgment is a `decline` judgment;
  - the subject of approval is **neither** (neither approved nor
    declined) when no such latest counting judgment exists, or when
    those latest counting judgments conflict (at least one approval
    judgment and at least one decline judgment).
- A subject of approval of a kind that needs no approval by a person is
  not declined. It is approved when, and only when, the rule that a
  design names for merges gives that the current declared-item object
  (revised content) that it has in that tree merged into the default
  branch.
- A declared item other than an item of the kind design is approved
  when, and only when, its subject of approval is approved. A declared
  item other than an item of the kind design is declined when, and only
  when, its subject of approval is declined.
- An item of the kind design is approved when, and only when, each of
  these three conditions holds:
  - the item of the kind design without the declared items that it holds
    is approved;
  - each item of the kind specification that the item of the kind design
    holds is approved;
  - each schema, each item of the kind requirement, each atom, and each
    term that the item of the kind design holds directly is approved.

### 3.66 Drafts

@atom draft-design=v1
@cites #{declared-item=v1, approval-state=v1, tree=v1, ledger=v1}

An item of the kind design is a draft in a tree when, and only when, it
is not approved in that tree.

### 3.67 Effective edges of the kind `supersedes`

@atom effective-supersedes-edge=v1
@cites #{
    edge=v1, supersedes-edge=v1, deprecated-item=v1, approval-state=v1,
    tree=v1, ledger=v1, item=v1, containment=v1,
}

A `supersedes` edge is effective in a tree when, and only when, each of
these three conditions holds:

- the edge says what the kind of edge `supersedes` says in that tree
  (its source and its cited item are declared items of the same kind of
  item);
- neither the source of the edge nor an item that holds that source is
  deprecated in that tree;
- the source of the edge is approved in that tree.

### 3.68 Cycles of edges of the kind `supersedes`

@term supersedes-cycle=v1
@cites #{edge=v1, supersedes-edge=v1, declared-item=v1, tree=v1}

A cycle of `supersedes` edges in a tree is a finite sequence of one or
more pairs (x, y) of declared items in that tree that meets both of
these conditions:

- for each pair (x, y) of the sequence, some `supersedes` edge in that
  tree says what the kind of edge `supersedes` says in that tree, with x
  as its source and y as its cited item;
- for each pair before the last, its second item is the first item of
  the next pair, and the second item of the last pair is the first item
  of the first pair.

A declared item is on a cycle of `supersedes` edges in a tree when, and
only when, it is the first item of a pair of a cycle of `supersedes`
edges in that tree.

### 3.69 Retired

@atom retired-item=v1
@cites #{
    declared-item=v1, deprecated-item=v1, effective-supersedes-edge=v1,
    supersedes-cycle=v1, edge=v1, containment=v1, tree=v1, ledger=v1,
}

A declared item is retired in a tree when, and only when, one of these
is true:

- it is deprecated in that tree;
- it is the cited item of an effective `supersedes` edge in that tree,
  and it is on no cycle of `supersedes` edges in that tree;
- it belongs to a retired item of the kind design or to a retired item
  of the kind specification in that tree.

A retired item no longer applies in that tree.

### 3.70 In force

@atom in-force-item=v1
@cites #{declared-item=v1, retired-item=v1, tree=v1, ledger=v1}

A declared item is in force in a tree when, and only when, it is not
retired in that tree.

### 3.71 Met waits

@atom met-wait=v1
@cites #{wait=v1, work-item=v1, work-item-state=v1, tree=v1, ledger=v1}

A wait says that the work of the waiting item is to start only after the
work item that it waits for is done. A wait is met in a tree when, and
only when, the work item that it waits for is done in that tree.

### 3.72 Ready tasks

@atom ready-task=v1
@cites #{
    task=v1, plan=v1, met-wait=v1, wait=v1, work-item-definition=v1,
    work-item-state=v1, tree=v1, ledger=v1,
}

A task is ready in a tree when, and only when, each of these three
conditions holds:

- the task is open in that tree;
- each wait of the current definition of the task is met in that tree;
- each wait of the current definition of each plan that the task is
  under is met in that tree.

### 3.73 Requirements accounted for

@atom requirement-accounted-for=v1
@cites #{
    declared-item=v1, containment=v1, task=v1, plan=v1, promise=v1,
    carried-out-item=v1, work-item-definition=v1, work-item-state=v1,
    ledger=v1, judgment=v1, job-record=v1, thing=v1, item-name=v1,
    revised-content=v1, content-id=v1, edge=v1, tree=v1,
}

An item of the kind requirement, with current declared-item object O and
name N in a tree, is accounted for in that tree when, and only when, one
of these is true:

- the current definition of an unfinished task has a promise whose name
  is N;
- the current definition of an open plan names, as carried out, the name
  N, the name of the item of the kind specification that holds that item
  in that tree, or the name of the item of the kind design that holds
  that item in that tree;
- for a task that is done in that tree with current definition D, either
  any latest counting `done` judgment of that task that judges D holds a
  `records` edge naming the content id of O, or a completing `delivered`
  observation of D that decides a state in that tree holds a
  `kept-satisfies` or `kept-verifies` edge naming the content id of O.

### 3.74 State inputs

@term state-input=v1
@cites {
    conformance#{design=v1, own-store=v1},
    #{
        tree=v1, default-branch=v1, delivery-line=v1, task-line=v1,
        log-branch=v1, test-evidence=v1, parameter=v1, object=v1,
    },
}

A state input of a repository is one of these:

- which commits the repository has, each with its parents and its tree;
- the commit to which each branch points;
- the commit of the default branch;
- the tree of each working tree;
- the delivery lines and the task lines of the messages of commits;
- the observations and kept objects on the log branch (without regard to
  their order);
- test evidence;
- the bindings of the parameters that designs name.

When a program takes objects from a valid program's own store in place
of inputs in encodings, the canonical objects that those inputs hold
determine the states.

## 4. Requirements

### 4.1 The sources of states

@req compute-states-from-artifacts=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    #{
        state=v1, state-input=v1, item=v1, edge=v1, wait=v1,
        subject-of-approval=v1, work-item-state=v1, deprecated-item=v1,
        approval-state=v1, draft-design=v1,
        effective-supersedes-edge=v1, retired-item=v1,
        in-force-item=v1, suspect-edge=v1, met-wait=v1, ready-task=v1,
        requirement-accounted-for=v1,
    },
}

A conforming program must give the same states to each item, edge, wait,
and subject of approval for which the program gives states, for two
inputs that meet both of these conditions:

- the two inputs agree in each state input, as each state input is when
  the program gives the states;
- no other process changes either input while the program runs.

### 4.2 The same treatment of each record

@req treat-ledger-entries-alike=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    #{
        state=v1, item=v1, edge=v1, wait=v1, subject-of-approval=v1,
        ledger-entry=v1, object-kind=v1, content-id=v1, judgment=v1,
        definition-entry=v1, job-record=v1, void-statement=v1,
        thing=v1, person=v1, agent=v1, parameter=v1,
    },
}

A conforming program must give the same states to each item, edge, wait,
and subject of approval for which the program gives states, for two
inputs that meet both of these conditions:

- one input turns into the other by changing only one or more of the
  following on records, together with the matching update of every
  content id (in edges, object file paths, and log-branch lines, and
  transitively for every record whose edges change) that names each
  changed record:
  - the `ts` values of records;
  - members of records that no row of `object-kind` names;
  - the `seq` values of observations;
  - the `by` values of records that are not judgments, or the `by`
    values of judgments where each changed `by` remains either inside
    the bound list of persons whose judgments count or outside that list
    (or any `by` when no list is bound);
  - the `agent` member of definition statements, or changing one `agent`
    string to another `agent` string on a judgment or a void without
    adding or removing `agent`;
- no other process changes either input while the program runs.

### 4.3 The ways in which a ledger changes

@req change-ledger-only-by-appends=v1
@cites {
    conformance#{conforming-program=v1},
    #{ledger=v1, ledger-entry=v1, log-branch=v1, job=v1, object=v1},
}

A conforming program must change no byte of an existing object file in
`.sinter/`, and must write to the log branch only in a run of the job,
only by appending observations and kept objects, and without removing or
changing any existing line of the log branch.

### 4.4 The records that agents write

@req write-only-definitions-for-agents=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    #{
        agent=v1, ledger=v1, judgment=v1, void-statement=v1,
        job-record=v1, log-branch=v1,
    },
}

When the input of a conforming program says that an agent runs the
program, the program must write no judgment, no void, and no
observation, and must write nothing to the log branch.

### 4.5 The judgments and voids that persons give

@req write-judgments-only-for-persons=v1
@cites {
    conformance#{conforming-program=v1},
    #{judgment=v1, void-statement=v1, person=v1},
}

A conforming program must write a judgment or a void only to record a
decision that a person gives the program by a confirmation that the
standard input, the arguments, and the environment of the program cannot
give.

### 4.6 The use of declared tasks

@req use-declared-tasks-only-for-briefs=v1
@cites {
    conformance#{conforming-program=v1},
    text#{text=v1},
    #{agent=v1, task=v1, state-input=v1},
}

A session is one execution of an agent on its work. The declared task of
a session is the task that the agent declares as the work of that
session. The brief of a session is the text about the work of the
session that a conforming program gives the agent of that session, in
no state input. A conforming program must use the declared task of a
session for nothing other than the brief of that session.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this design.
No requirement of section 4 names a result for an input, so there are no
conformance vectors.
